import Foundation
import XCTest
import SwiftBacktrace

final class SwiftBacktraceTests: XCTestCase {
    func test_backtrace() {
    #if os(macOS) || os(Linux) && swift(>=4.1)
        print("--- Thread.callStackSymbols")
        print(Thread.callStackSymbols.joined(separator: "\n"))
    #endif // os(macOS) || os(Linux) && swift(>=4.1)
        print("--- backtrace()")
        print(backtrace().joined(separator: "\n"))
        print("--- demangledBacktrace()")
        print(demangledBacktrace().joined(separator: "\n"))
    #if os(macOS) || (os(Linux) && swift(>=4.1))
        print("--- simplifiedDemangledBacktrace()")
        print(simplifiedDemangledBacktrace().joined(separator: "\n"))
    #endif // os(macOS) || (os(Linux) && swift(>=4.1))
    }

    static var allTests = [
        ("test_backtrace", test_backtrace)
    ]
}
