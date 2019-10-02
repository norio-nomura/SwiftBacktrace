# SwiftBacktrace
[![SwiftPM](https://github.com/norio-nomura/SwiftBacktrace/workflows/SwiftPM/badge.svg)](https://launch-editor.github.com/actions?workflowID=SwiftPM&event=pull_request&nwo=norio-nomura%2FSwiftBacktrace)
[![Nightly](https://github.com/norio-nomura/SwiftBacktrace/workflows/Nightly/badge.svg)](https://launch-editor.github.com/actions?workflowID=Nightly&event=pull_request&nwo=norio-nomura%2FSwiftBacktrace)

Stack traces for Swift on Mac and Linux using `libunwind`.

## Installation

`SwiftBacktrace` depends on `libunwind`.

### On macOS
compatible with pre-installed `/usr/lib/system/libunwind.dylib`.

### On Linux
`libunwind8` installaion is required.
```
apt-get update && apt-get install -y libunwind8
```

## Getting started
```swift
import SwiftBacktrace

print(backtrace().joined(separator: "\n"))          // backtrace()
print(demangledBacktrace().joined(separator: "\n")) // demangled backtrace
```

[Output example on Linux CI](https://circleci.com/gh/norio-nomura/SwiftBacktrace/16):
```
/root/project/.build/x86_64-unknown-linux/debug/SwiftBacktracePackageTests.xctest(SwiftBacktrace.callStackSymbols<A>(_: Swift.Int, transform: ((module: Swift.String, name: Swift.String, offset: Swift.UInt64, address: Swift.Optional<Swift.UnsafeRawPointer>)) -> A) -> Swift.Array<A>+0x87) [0x55f78f85c0b7]
/root/project/.build/x86_64-unknown-linux/debug/SwiftBacktracePackageTests.xctest(SwiftBacktrace.demangledBacktrace(Swift.Int) -> Swift.Array<Swift.String>+0x80) [0x55f78f85ae10]
/root/project/.build/x86_64-unknown-linux/debug/SwiftBacktracePackageTests.xctest(SwiftBacktraceTests.SwiftBacktraceTests.test_backtrace() -> ()+0x4a5) [0x55f78f8608d5]
/root/project/.build/x86_64-unknown-linux/debug/SwiftBacktracePackageTests.xctest(partial apply forwarder for SwiftBacktraceTests.SwiftBacktraceTests.test_backtrace() -> ()+0x9) [0x55f78f861119]
```

## Author

Norio Nomura

## License

This package is available under the MIT license. See the LICENSE file for more info.
