import Dispatch
import Foundation

// swiftlint:disable identifier_name

// MARK: - enablePrettyStackTrace

let _enablePrettyStackTrace: Void = {
    addSignalHandler {
        fputs(backtrace().joined(separator: "\n"), stderr)
    }
}()

// MARK: - Signals

let intSignals = [SIGHUP, SIGINT, SIGPIPE, SIGTERM, SIGUSR1, SIGUSR2]
let killSignals: [Int32] = {
    var signals = [SIGILL, SIGTRAP, SIGABRT, SIGFPE, SIGBUS, SIGSEGV, SIGQUIT]
#if os(macOS) || os(Linux)
    signals.append(SIGSYS)
    signals.append(SIGXCPU)
    signals.append(SIGXFSZ)
#endif
#if os(macOS)
    signals.append(SIGEMT)
#endif
    return signals
}()

// MARK: - Alt Stack
extension stack_t {
    static func allocate(size: Int) -> stack_t {
        var stack = stack_t()
    #if swift(>=4.1)
        stack.ss_sp = UnsafeMutableRawPointer.allocate(byteCount: numericCast(size), alignment: 1)
    #else
        stack.ss_sp = UnsafeMutableRawPointer.allocate(bytes: numericCast(size), alignedTo: 1)
    #endif
        stack.ss_size = numericCast(size)
        return stack
    }

    func deallocate() {
    #if swift(>=4.1)
        ss_sp.deallocate()
    #else
        ss_sp.deallocate(bytes: numericCast(ss_size), alignedTo: 1)
    #endif
    }
}

private func createAltStack() {
    let altStackSize = MINSIGSTKSZ + 64 * 1024
    var oldAltStack = stack_t()

    guard sigaltstack(nil, &oldAltStack) == 0 &&
        oldAltStack.ss_flags & numericCast(SS_ONSTACK) == 0 && // Thread is not currently executing on oldAltStack
        !(oldAltStack.ss_sp != nil && oldAltStack.ss_size > altStackSize) // oldAltStack does not have sufficient size
        else { return }

    var altStack = stack_t.allocate(size: numericCast(altStackSize))
    if sigaltstack(&altStack, &oldAltStack) != 0 {
        altStack.deallocate()
    }
}

// MARK: - Register Handlers

extension sigaction {
    init(_ action: @escaping @convention(c) (Int32) -> Void, _ sa_flags: Int32 = 0) {
    #if _runtime(_ObjC)
        self.init()
        self.__sigaction_u.__sa_handler = action
    #elseif os(Linux)
        self.init()
        self.__sigaction_handler.sa_handler = action
    #else
        self.init()
        #if swift(>=4.1.50)
            #warning("unsupported platform")
        #endif
    #endif
    }
}

private struct SignalInfo {
    var oldAction = sigaction()
    var signal: Int32
    init(_ signal: Int32) {
        self.signal = signal
    }
}

private var registeredSignalInfo = [SignalInfo]()
private let queue = DispatchQueue(label: "registerHandlers()")

private func registerHandlers() {
    queue.sync {
        // If the handlers are already registered, we're done.
        guard registeredSignalInfo.isEmpty else { return }

        // Create an alternate stack for signal handling. This is necessary for us to
        // be able to reliably handle signals due to stack overflow.
        createAltStack()

        (intSignals + killSignals).forEach { signal in
            let sa_flags = Int32(SA_NODEFER) | Int32(bitPattern: UInt32(SA_RESETHAND)) | Int32(SA_ONSTACK)
            var newAction = sigaction(signalHandler, sa_flags)
            var signalInfo = SignalInfo(signal)
            // Install the new handler, save the old one in RegisteredSignalInfo.
            sigaction(signal, &newAction, &signalInfo.oldAction)
            registeredSignalInfo.append(signalInfo)
        }
    }
}

private func unregisterhandlers() {
    queue.sync {
        // Restore all of the signal handlers to how they were before we showed up.
        registeredSignalInfo.forEach { signalInfo in
            var signalInfo = signalInfo
            sigaction(signalInfo.signal, &signalInfo.oldAction, nil)
        }
        registeredSignalInfo.removeAll(keepingCapacity: true)
    }
}

private func signalHandler(signal: Int32) {
    // Restore the signal behavior to default, so that the program actually
    // crashes when we return and the signal reissues.  This also ensures that if
    // we crash in our signal handler that the program will terminate immediately
    // instead of recursing in the signal handler.
    unregisterhandlers()

    // Unmask all potentially blocked kill signals.
    var sigMask = sigset_t()
    sigfillset(&sigMask)
    sigprocmask(SIG_UNBLOCK, &sigMask, nil)

    if intSignals.contains(signal) {
        if let oldInterruptFunction = removeInterruptFunction() {
            oldInterruptFunction(signal)
        }
        raise(signal)   // Execute the default handler.
        return
    }

    runSignalHandlers()
}

// MARK: - addSignalHandler

/// AddSignalHandler - Add a function to be called when an abort/kill signal
/// is delivered to the process.
public func addSignalHandler(_ callback: @escaping () -> Void) {
    insertSignalHandler(callback)
    registerHandlers()
}

final class Callback {
    enum State: Int { case empty, initializing, initialized, executing }
    var state = _stdlib_AtomicInt(State.empty.rawValue)
    var callback: (() -> Void)?

    private var _valuePtr: UnsafeMutablePointer<Int> {
        return _getUnsafePointerToStoredProperties(self).assumingMemoryBound(
            to: Int.self)
    }

    func storeState(_ desired: State) {
        return state.store(desired.rawValue)
    }

    func compareExchangeState(expected: inout State, desired: State) -> Bool {
        var expectedVar = expected.rawValue
        let result = state.compareExchange(expected: &expectedVar, desired: desired.rawValue)
        expected = State(rawValue: expectedVar)!
        return result
    }
}

let maxSignalHandlerCallbacks = 8
var callbacksToRun = Array(repeating: Callback(), count: maxSignalHandlerCallbacks)

private func runSignalHandlers() {
    for index in callbacksToRun.indices {
        var expected = Callback.State.initialized
        if !callbacksToRun[index].compareExchangeState(expected: &expected, desired: .executing) {
            continue
        }
        callbacksToRun[index].callback?()
        callbacksToRun[index].callback = nil
        callbacksToRun[index].storeState(.empty)
    }
}

private func insertSignalHandler(_ callback: @escaping () -> Void) {
    for index in callbacksToRun.indices {
        var expected = Callback.State.empty
        if !callbacksToRun[index].compareExchangeState(expected: &expected, desired: .initializing) {
            continue
        }
        callbacksToRun[index].callback = callback
        callbacksToRun[index].storeState(.initialized)
        return
    }
    fatalError("too many signal callbacks already registered")
}

//// Interrupt Function
public typealias InterruptFunction = @convention(c) (Int32) -> Void
var interruptFunctionPtr = _stdlib_AtomicInt(0)

extension _stdlib_AtomicInt {
    func exchange(desired: Int) -> Int {
        var expected: Int
        repeat {
            expected = load()
        } while !compareExchange(expected: &expected, desired: desired)
        return expected
    }
}

public func setInterruptFunction(_ desired: InterruptFunction?) {
    interruptFunctionPtr.store(unsafeBitCast(desired, to: Int.self))
    registerHandlers()
}

func removeInterruptFunction() -> InterruptFunction? {
    let result = interruptFunctionPtr.exchange(desired: 0)
    return unsafeBitCast(result, to: InterruptFunction?.self)
}
