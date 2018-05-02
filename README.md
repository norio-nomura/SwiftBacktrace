# SwiftBacktrace

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

## Author

Norio Nomura

## License

This package is available under the MIT license. See the LICENSE file for more info.
