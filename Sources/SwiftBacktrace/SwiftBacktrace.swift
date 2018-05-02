import Foundation
import Clibunwind
import CSwiftBacktrace

public func backtrace(_ maxSize: Int = 32) -> [String] {
#if os(macOS)
    let symbols = callStackSymbols(maxSize, transform: darwinStyleFormat)
    let countStringLength = max(String(symbols.count).count + 1, 4)
    return symbols.enumerated().map { String($0.offset).ljust(countStringLength) + $0.element }
#elseif os(Linux)
    return callStackSymbols(maxSize, transform: linuxStyleFormat)
#endif
}

public func demangledBacktrace(_ maxSize: Int = 32) -> [String] {
#if os(macOS)
    let symbols = callStackSymbols(maxSize, transform: demangle).map(darwinStyleFormat)
    let countStringLength = max(String(symbols.count).count + 1, 4)
    return symbols.enumerated().map { String($0.offset).ljust(countStringLength) + $0.element }
#elseif os(Linux)
    return callStackSymbols(maxSize, transform: demangle).map(linuxStyleFormat)
#endif
}

func darwinStyleFormat(_ symbol: Symbol) -> String {
    let (module, name, offset, address) = symbol
    let basename = URL(fileURLWithPath: module).lastPathComponent.ljust(35)
    return "\(basename) \(address?.debugDescription ?? "") \(name) + \(offset)"
}

func linuxStyleFormat(_ symbol: Symbol) -> String {
    let (module, name, offset, address) = symbol
    func hex<T: FixedWidthInteger & UnsignedInteger>(_ int: T) -> String {
        return "0x" + .init(int, radix: 16, uppercase: false)
    }
    return "\(module)(\(name)+\(hex(offset))) [\(hex(UInt(address?.hashValue ?? 0)))]"
}

func demangle(_ symbol: Symbol) -> Symbol {
    var symbol = symbol
    symbol.name = swiftDemangleName(symbol.name)
    return symbol
}

func swiftDemangleName(_ mangledName: String) -> String {
    let utf8CString = mangledName.utf8CString
    return utf8CString.withUnsafeBufferPointer { buffer in
        guard let demangled = swift_demangle(buffer.baseAddress!, buffer.count - 1, nil, nil, 0) else { return nil }
        defer { free(demangled) }
        return String(cString: demangled)
    } ?? mangledName
}
