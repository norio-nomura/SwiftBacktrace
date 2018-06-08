import Foundation
import Clibunwind
import CSwiftBacktrace

/// Produce backtrace
public func backtrace(_ maxSize: Int = 32, formatter: BacktraceFormatter = BacktraceFormatter()) -> [String] {
    return formatter.postProcessor.handler(callStackSymbols(maxSize, transform: formatter.symbolFormatter.handler))
}

public func demangledBacktrace(_ maxSize: Int = 32) -> [String] {
    return backtrace(maxSize, formatter: .demangled)
}

#if os(macOS) || (os(Linux) && swift(>=4.1))
public func simplifiedDemangledBacktrace(_ maxSize: Int = 32) -> [String] {
    return backtrace(maxSize, formatter: .simplifiedDemangled)
}
#endif // os(macOS) || (os(Linux) && swift(>=4.1))

// MARK: - BacktraceFormatter

public struct BacktraceFormatter {
    let symbolFormatter: SymbolFormatter
    let postProcessor: PostProcessor

    public init(_ symbolFormatter: SymbolFormatter = .default, _ postProcessor: PostProcessor = .default) {
        self.symbolFormatter = symbolFormatter
        self.postProcessor = postProcessor
    }

    // MARK: - Predefined formatter
    public static let demangled = BacktraceFormatter(.demangledDefault)
#if os(macOS) || (os(Linux) && swift(>=4.1))
    public static let simplifiedDemangled = BacktraceFormatter(.simplifiedDemangledDefault)
#endif // os(macOS) || (os(Linux) && swift(>=4.1))
}

// MARK: - Converter

public struct Converter<Input, Output> {
    public typealias Handler = (Input) -> Output
    let handler: Handler

    public init(_ handler: @escaping Handler) {
        self.handler = handler
    }

    public func compose<V>(_ other: Converter<V, Input>) -> Converter<V, Output> {
        return .init { self.handler(other.handler($0)) }
    }
}

// MARK: - Demangler

/// Demangler = (Symbol) -> Symbol
public typealias Demangler = Converter<Symbol, Symbol>

extension Converter where Input == Symbol, Output == Symbol {
#if os(macOS) || (os(Linux) && swift(>=4.1))
    public static let `default` = simplified
#else
    public static let `default` = demangle
#endif

    /// Demangle `Symbol.name` as Swift function names.
    public static let demangle = Converter { symbol -> Symbol in
        var symbol = symbol
        symbol.name = swiftDemangleName(symbol.name)
        return symbol
    }

#if os(macOS) || (os(Linux) && swift(>=4.1))
    /// Demangle `Symbol.name` as Swift function names with module names and implicit self
    /// and metatype type names in function signatures stripped.
    public static let simplified = Converter { symbol -> Symbol in
        var symbol = symbol
        symbol.name = swiftSimplifiedDemangleName(symbol.name)
        return symbol
    }
#endif // os(macOS) || (os(Linux) && swift(>=4.1))
}

// MARK: - SymbolFormatter

/// Convert `Symbol` to `String`
public typealias SymbolFormatter = Converter<Symbol, String>

extension Converter where Input == Symbol, Output == String {
    // Swift 4.0.3 or earlier can't infer types of `default` without type annotation
    public static let `default`: SymbolFormatter = defaultStyle.compose(.default)

    public static let demangledDefault = defaultStyle.compose(.demangle)
#if os(macOS) || (os(Linux) && swift(>=4.1))
    public static let simplifiedDemangledDefault = defaultStyle.compose(.simplified)
#endif // os(macOS) || (os(Linux) && swift(>=4.1))

#if os(macOS)
    public static let defaultStyle = darwinStyleFormat
#elseif os(Linux)
    public static let defaultStyle = linuxStyleFormat
#endif

    /// Format `Symbol` into darwin style backtrace
    public static let darwinStyleFormat = Converter { symbol -> String in
        let (module, name, offset, address) = symbol
        let basename = URL(fileURLWithPath: module).lastPathComponent.ljust(35)
        return "\(basename) \(address?.debugDescription ?? "") \(name) + \(offset)"
    }

    /// Format `Symbol` into linux style backtrace
    public static let linuxStyleFormat = Converter { symbol -> String in
        let (module, name, offset, address) = symbol
        func hex<T: FixedWidthInteger & UnsignedInteger>(_ int: T) -> String {
            return "0x" + .init(int, radix: 16, uppercase: false)
        }
        return "\(module)(\(name)+\(hex(offset))) [\(address?.debugDescription ?? "0x0")]"
    }
}

// MARK: - PostProcessor

/// Convert `[String]` to `[String]`
public typealias PostProcessor = Converter<[String], [String]>

extension Converter where Input == [String], Output == [String] {
#if os(macOS)
    public static let `default` = prefixNumber
#elseif os(Linux)
    public static let `default` = Converter { $0 }
#endif

    /// Prefix line number to each lines in `[String]`
    public static let prefixNumber = Converter { lines -> [String] in
        let countStringLength = max(String(lines.count).count + 1, 4)
        return lines.enumerated().map { String($0.offset).ljust(countStringLength) + $0.element }
    }
}
