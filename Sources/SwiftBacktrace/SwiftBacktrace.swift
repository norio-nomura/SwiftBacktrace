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
