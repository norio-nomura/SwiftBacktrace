import Foundation
import Clibunwind
import CSwiftBacktrace

/// Produce backtrace
public func backtrace(_ maxSize: Int = 32, formatter: BacktraceFormatter = BacktraceFormatter()) -> [String] {
    return formatter.postProcessor(callStackSymbols(maxSize, transform: formatter.symbolFormatter))
}

public func demangledBacktrace(_ maxSize: Int = 32) -> [String] {
    let formatter = BacktraceFormatter(BacktraceFormatter.defaultStyler ∘ BacktraceFormatter.demangle)
    return backtrace(maxSize, formatter: formatter)
}

#if os(macOS) || (os(Linux) && swift(>=4.1))
public func simplifiedDemangledBacktrace(_ maxSize: Int = 32) -> [String] {
    let formatter = BacktraceFormatter(BacktraceFormatter.defaultStyler ∘ BacktraceFormatter.simplifiedDemangle)
    return backtrace(maxSize, formatter: formatter)
}
#endif // os(macOS) || (os(Linux) && swift(>=4.1))

// MARK: - BacktraceFormatter

public struct BacktraceFormatter {
    let symbolFormatter: SymbolFormatter
    let postProcessor: PostProcessor

    public init(_ symbolFormatter: @escaping SymbolFormatter = defaultSymbolFormatter,
                _ postProcessor: @escaping PostProcessor = defaultPostProcessor) {
        self.symbolFormatter = symbolFormatter
        self.postProcessor = postProcessor
    }

    // MARK: - Predefined formatter
    public static let fullyDemangledFormatter = BacktraceFormatter(BacktraceFormatter.defaultStyler ∘ BacktraceFormatter.demangle)

    // MARK: - Demangler

    /// Demangler = (Symbol) -> Symbol
    public typealias Demangler = (Symbol) -> Symbol

#if os(macOS) || (os(Linux) && swift(>=4.1))
    public static let defaultDemangler: Demangler = simplifiedDemangle
#else
    public static let defaultDemangler: Demangler = demangle
#endif

    /// Demangle `Symbol.name` as Swift function names.
    public static func demangle(_ symbol: Symbol) -> Symbol {
        var symbol = symbol
        symbol.name = swiftDemangleName(symbol.name)
        return symbol
    }

#if os(macOS) || (os(Linux) && swift(>=4.1))
    /// Demangle `Symbol.name` as Swift function names with module names and implicit self
    /// and metatype type names in function signatures stripped.
    public static func simplifiedDemangle(_ symbol: Symbol) -> Symbol {
        var symbol = symbol
        symbol.name = swiftSimplifiedDemangleName(symbol.name)
        return symbol
    }
#endif // os(macOS) || (os(Linux) && swift(>=4.1))

    // MARK: - SymbolFormatter

    /// Convert `Symbol` to `String`
    public typealias SymbolFormatter = (Symbol) -> String

    public static let defaultSymbolFormatter: SymbolFormatter = defaultStyler ∘ defaultDemangler

#if os(macOS)
    public static let defaultStyler: SymbolFormatter = darwinStyleFormat
#elseif os(Linux)
    public static let defaultStyler: SymbolFormatter = linuxStyleFormat
#endif

    /// Format `Symbol` into darwin style backtrace
    public static func darwinStyleFormat(_ symbol: Symbol) -> String {
        let (module, name, offset, address) = symbol
        let basename = URL(fileURLWithPath: module).lastPathComponent.ljust(35)
        return "\(basename) \(address?.debugDescription ?? "") \(name) + \(offset)"
    }

    /// Format `Symbol` into linux style backtrace
    public static func linuxStyleFormat(_ symbol: Symbol) -> String {
        let (module, name, offset, address) = symbol
        func hex<T: FixedWidthInteger & UnsignedInteger>(_ int: T) -> String {
            return "0x" + .init(int, radix: 16, uppercase: false)
        }
        return "\(module)(\(name)+\(hex(offset))) [\(address?.debugDescription ?? "0x0")]"
    }

    // MARK: - PostProcessor

    /// Convert `[String]` to `[String]`
    public typealias PostProcessor = ([String]) -> [String]

#if os(macOS)
    public static let defaultPostProcessor: PostProcessor = prefixNumber
#elseif os(Linux)
    public static let defaultPostProcessor: PostProcessor = { $0 }
#endif

    /// Prefix line number to each lines in `[String]`
    public static func prefixNumber(to lines: [String]) -> [String] {
        let countStringLength = max(String(lines.count).count + 1, 4)
        return lines.enumerated().map { String($0.offset).ljust(countStringLength) + $0.element }
    }
}

// MARK: - Compose functions.
infix operator ∘ : CompositionPrecedence

precedencegroup CompositionPrecedence {
    associativity: left
    higherThan: TernaryPrecedence
}

// swiftlint:disable identifier_name
private func ∘<T, U, V>(g: @escaping (U) -> V, f: @escaping (T) -> U) -> ((T) -> V) {
    return { g(f($0)) }
}
