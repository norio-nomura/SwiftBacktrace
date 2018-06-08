import Clibunwind
import CSwiftBacktrace

public typealias Symbol = (module: String, name: String, offset: UInt64, address: UnsafeRawPointer?)

public func callStackSymbols<T>(_ maxSize: Int = 32, transform: (Symbol) -> T) -> [T] {
    let symbols = CallStackSymbols()
    _ = unw_getcontext(symbols.context)
    _ = unw_init_local(symbols.cursor, symbols.context)
    return symbols.prefix(maxSize).map(transform)
}

class CallStackSymbols: Sequence, IteratorProtocol {
    var context = UnsafeMutablePointer<unw_context_t>.allocate(capacity: 1)
    var cursor = UnsafeMutablePointer<unw_cursor_t>.allocate(capacity: 1)
    var ended = false

    deinit {
#if swift(>=4.1)
        cursor.deallocate()
        context.deallocate()
#else
        cursor.deallocate(capacity: 1)
        context.deallocate(capacity: 1)
#endif
    }

    func next() -> Symbol? {
        return symbol()
    }

    func symbol() -> Symbol? {
        guard !ended else { return nil }
        let (name, offset) = nameAndOffset()
        let address = self.address()
        let module = dli_fname(address).map(String.init(cString:)) ?? CommandLine.arguments[0]
        ended = !(step() > 0)
        return (module: module, name: name, offset: offset, address: address)
    }

    func address() -> UnsafeRawPointer? {
        var addressNumber = unw_word_t()
#if os(macOS)
        _ = unw_get_reg(cursor, unw_regnum_t(UNW_REG_IP), &addressNumber)
#elseif os(Linux)
        _ = unw_get_reg(cursor, unw_regnum_t(UNW_TDEP_IP.rawValue), &addressNumber)
#endif
        return UnsafeRawPointer(bitPattern: UInt(addressNumber))
    }

    func nameAndOffset() -> (name: String, offset: UInt64) {
        var buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
#if swift(>=4.1)
        defer { buffer.deallocate() }
#else
        defer { buffer.deallocate(capacity: 1024) }
#endif
        var offset = unw_word_t()
        _ = unw_get_proc_name(cursor, buffer, 1024, &offset)
        return (String(cString: buffer), offset)
    }

    func step() -> Int32 {
        return unw_step(cursor)
    }
}

// swiftlint:disable identifier_name

// MARK: - Dynamic loading `libunwind`

#if os(macOS)
let libunwind = Loader(searchPaths: ["/usr/lib/system"]).load(path: "libunwind.dylib")
#elseif os(Linux)
let libunwind = Loader(searchPaths: []).load(path: "libunwind.so.8")
#endif

#if arch(x86_64)
let UNW_TARGET = "x86_64"
#elseif arch(i386)
let UNW_TARGET = "x86"
#else

#endif

func UNW_ARCH_OBJ<T>(_ fn: String) -> T {
    return libunwind.load(symbols: ["unw_" + fn, "_U\(UNW_TARGET)_\(fn)"])
}
func UNW_OBJ<T>(_ fn: String) -> T {
    return libunwind.load(symbols: ["unw_" + fn, "_UL\(UNW_TARGET)_\(fn)"])
}

let unw_getcontext: @convention(c) (
    _ ucp: UnsafeMutablePointer<unw_context_t>) -> Int32 = UNW_ARCH_OBJ("getcontext")

let unw_init_local: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ ucp: UnsafeMutablePointer<unw_context_t>?) -> Int32 = UNW_OBJ("init_local")

let unw_step: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?) -> Int32 = UNW_OBJ("step")

let unw_get_reg: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ reg: unw_regnum_t,
    _ valp: UnsafeMutablePointer<unw_word_t>?) -> Int32 = UNW_OBJ("get_reg")

let unw_get_fpreg: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ reg: unw_regnum_t,
    _ valp: UnsafeMutablePointer<unw_fpreg_t>?) -> Int32 = UNW_OBJ("get_fpreg")

let unw_set_reg: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ reg: unw_regnum_t,
    _ val: unw_word_t) -> Int32 = UNW_OBJ("set_reg")

let unw_set_fpreg: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ reg: unw_regnum_t,
    _ val: unw_fpreg_t) -> Int32 = UNW_OBJ("set_fpreg")

let unw_resume: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?) -> Int32 = UNW_OBJ("resume")

let unw_regname: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ reg: unw_regnum_t) -> UnsafePointer<Int8>? = UNW_ARCH_OBJ("regname")

let unw_get_proc_info: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ pip: UnsafeMutablePointer<unw_proc_info_t>?) -> Int32 = UNW_OBJ("get_proc_info")

let unw_is_fpreg: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?, _ reg: unw_regnum_t) -> Int32 = UNW_ARCH_OBJ("is_fpreg")

let unw_is_signal_frame: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?) -> Int32 = UNW_OBJ("is_signal_frame")

let unw_get_proc_name: @convention(c) (
    _ cp: UnsafeMutablePointer<unw_cursor_t>?,
    _ bufp: UnsafeMutablePointer<Int8>?,
    _ len: Int,
    _ offp: UnsafeMutablePointer<unw_word_t>?) -> Int32 = UNW_OBJ("get_proc_name")
