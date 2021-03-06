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

    func test_cxxDemangle() {
        XCTAssertEqual(cxxDemangleName("_ZN10sourcekitd13handleRequestEPvSt8functionIFvS0_EE"),
                       "sourcekitd::handleRequest(void*, std::function<void (void*)>)")
    }

    func test_enablePrettyStackTrace() {
        enablePrettyStackTrace()
        raise(SIGABRT)
    }

    func test_setInterruptFunction() {
        setInterruptFunction { _ in
            print("interrupted")
        }
        // we can't test interrupt function yet.
//        raise(SIGTERM)
    }

    static var allTests = [
        ("test_backtrace", test_backtrace),
        ("test_cxxDemangle", test_cxxDemangle),
        ("test_enablePrettyStackTrace", test_enablePrettyStackTrace),
        ("test_setInterruptFunction", test_setInterruptFunction)
    ]
}
