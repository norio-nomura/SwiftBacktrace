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

#if os(macOS) || (os(Linux) && swift(>=4.1))
public func simplifiedDemangledBacktrace(_ maxSize: Int = 32) -> [String] {
#if os(macOS)
    let symbols = callStackSymbols(maxSize, transform: simplifiedDemangle).map(darwinStyleFormat)
    let countStringLength = max(String(symbols.count).count + 1, 4)
    return symbols.enumerated().map { String($0.offset).ljust(countStringLength) + $0.element }
#elseif os(Linux)
    return callStackSymbols(maxSize, transform: simplifiedDemangle).map(linuxStyleFormat)
#endif
}
#endif // os(macOS) || (os(Linux) && swift(>=4.1))

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

#if os(macOS) || (os(Linux) && swift(>=4.1))
func simplifiedDemangle(_ symbol: Symbol) -> Symbol {
    var symbol = symbol
    symbol.name = swiftSimplifiedDemangleName(symbol.name)
    return symbol
}
#endif // os(macOS) || (os(Linux) && swift(>=4.1))
