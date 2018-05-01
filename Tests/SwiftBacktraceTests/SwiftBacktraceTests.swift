import Foundation
import XCTest
import SwiftBacktrace

final class SwiftBacktraceTests: XCTestCase {
    func test_backtrace() {
    #if os(macOS) || os(Linux) && swift(>=4.1)
        print("--- Thread.callStackSymbols")
        print(Thread.callStackSymbols.joined(separator: "\n"))
    #endif
        print("--- backtrace()")
        print(backtrace().joined(separator: "\n"))
        print("--- demangledBacktrace()")
        print(demangledBacktrace().joined(separator: "\n"))
    }

    static var allTests = [
        ("test_backtrace", test_backtrace),
    ]
}
