import Foundation
import Clibunwind
import CSwiftBacktrace

public func backtrace(_ maxSize: Int = 32) -> [String] {
    var cursor = unw_cursor_t()
    var context = unw_context_t()
    unw.getcontext(&context)
    unw.init_local(&cursor, &context)

    var results = [String]()
    var count = 0
    var buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
#if swift(>=4.1)
    defer { buffer.deallocate() }
#else
    defer { buffer.deallocate(capacity: 1024) }
#endif
    repeat {
        var offset = unw_word_t()
        unw.get_proc_name(&cursor, buffer, 1024, &offset)
        let procName = String(cString: buffer)

        var pc = unw_word_t()
#if os(macOS)
        unw.get_reg(&cursor, unw_regnum_t(UNW_REG_IP), &pc)
#elseif os(Linux)
        unw.get_reg(&cursor, unw_regnum_t(UNW_TDEP_IP.rawValue), &pc)
#endif
        let pointer = UnsafeRawPointer(bitPattern: UInt(pc))
        let moduleName = dli_fname(pointer).map(String.init(cString:)) ?? CommandLine.arguments[0]

#if os(macOS)
        let basename = URL(fileURLWithPath: moduleName).lastPathComponent.ljust(35)
        results.append("\(basename) \(pointer?.debugDescription ?? "") \(procName) + \(offset)")
#elseif os(Linux)
        func hex<T: FixedWidthInteger & UnsignedInteger>(_ int: T) -> String {
            return "0x" + .init(int, radix: 16, uppercase: false)
        }
        results.append("\(moduleName)(\(procName)+\(hex(offset))) [\(hex(UInt(pointer?.hashValue ?? 0)))]")
#endif
        count += 1
    } while unw.step(&cursor) > 0
#if os(macOS)
    let countStringLength = max(String(results.count).count + 1, 4)
    return results.enumerated().map { String($0.offset).ljust(countStringLength) + $0.element }
#else
    return results
#endif
}

public func demangledBacktrace(_ maxSize: Int = 32) -> [String] {
    return backtrace(maxSize).map(replaceFirstMangledName)
}

func replaceFirstMangledName(in symbol: String) -> String {
#if os(macOS)
    let regex = try! NSRegularExpression(pattern: "^\\d+\\s+\\S+\\s+\\S+\\s+(\\S+)")
#elseif os(Linux)
    let regex = try! NSRegularExpression(pattern: "^.*\\((\\S+)\\+0x\\S+\\)")
#else
    return symbol
#endif
    var symbol = symbol
    guard let matche = regex.firstMatch(in: symbol, range: NSRange(symbol.startIndex..<symbol.endIndex, in: symbol)),
        matche.numberOfRanges == 2,
        let range = Range(matche.range(at: 1), in: symbol) else {
            return symbol
    }
    let mangledName = String(symbol[range])
    let demangledName = swiftDemangleName(mangledName)
    symbol.replaceSubrange(range, with: demangledName)
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

