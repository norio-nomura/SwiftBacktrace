// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftBacktrace",
    products: [
        .library(
            name: "SwiftBacktrace",
            targets: ["Clibunwind", "CSwiftBacktrace", "SwiftBacktrace"]),
    ],
    targets: [
        .target(name: "Clibunwind"),
        .target(name: "CSwiftBacktrace"),
        .target(
            name: "SwiftBacktrace",
            dependencies: ["Clibunwind", "CSwiftBacktrace"]),
        .testTarget(
            name: "SwiftBacktraceTests",
            dependencies: ["SwiftBacktrace"]),
    ]
)
