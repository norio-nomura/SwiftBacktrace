// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftBacktrace",
    products: [
        .library(
            name: "SwiftBacktrace",
            targets: ["Clibunwind", "CSwiftBacktrace", "SwiftBacktrace"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.11.0")
    ],
    targets: [
        .target(name: "Clibunwind"),
        .target(name: "CSwiftBacktrace"),
        .target(
            name: "SwiftBacktrace",
            dependencies: ["Clibunwind", "CSwiftBacktrace", "NIOConcurrencyHelpers"]),
        .testTarget(
            name: "SwiftBacktraceTests",
            dependencies: ["SwiftBacktrace"])
    ]
)
