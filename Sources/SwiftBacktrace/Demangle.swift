import CSwiftBacktrace
import Foundation

public func swiftDemangleName(_ mangledName: String) -> String {
    let utf8CString = mangledName.utf8CString
    return utf8CString.withUnsafeBufferPointer { buffer in
        guard let demangled = swift_demangle(buffer.baseAddress!, buffer.count - 1, nil, nil, 0) else { return nil }
        defer { free(demangled) }
        return String(cString: demangled)
        } ?? mangledName
}

#if os(macOS) || (os(Linux) && swift(>=4.1))

public func swiftSimplifiedDemangleName(_ mangledName: String) -> String {
    let size = swift_demangle_getSimplifiedDemangledName(mangledName, nil, 0) + 1
    guard size > 1 else { return mangledName }
    let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
#if swift(>=4.1)
    defer { buffer.deallocate() }
#else
    defer { buffer.deallocate(capacity: size) }
#endif
    _ = swift_demangle_getSimplifiedDemangledName(mangledName, buffer, size)
    return String(cString: buffer)
}

#if os(macOS)
let searchPaths: [String] = {
    let process = Process(), pipe = Pipe()
    process.launchPath = "/usr/bin/env"
    process.arguments = ["xcrun", "--find", "swift"]
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()
    let output = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let swiftURL = String(data: output, encoding: .utf8).map(URL.init(fileURLWithPath:)),
        let libPath = URL(string: "../lib", relativeTo: swiftURL)?.path else { return [] }
    return [libPath]
}()
let libswiftDemangle = Loader(searchPaths: searchPaths).load(path: "libswiftDemangle.dylib")
#elseif os(Linux)
let libswiftDemangle = Loader(searchPaths: []).load(path: "libswiftDemangle.so")
#endif

// swiftlint:disable:next identifier_name
let swift_demangle_getSimplifiedDemangledName: @convention(c) (
    _ MangledName: UnsafePointer<Int8>?,
    _ OutputBuffer: UnsafeMutablePointer<Int8>?,
    _ Length: Int) -> Int = libswiftDemangle.load(symbols: ["swift_demangle_getSimplifiedDemangledName"])

#endif // os(macOS) || (os(Linux) && swift(>=4.1))
