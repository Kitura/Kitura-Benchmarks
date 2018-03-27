// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bench-Kitura-SwiftMetrics",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Bench-Kitura-SwiftMetrics",
            targets: ["HelloWorld", "HelloWorldSwiftMetrics", "HelloWorldSwiftMetricsHTTP"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "HelloWorld",
            dependencies: ["Kitura", "HeliumLogger"]),
        .target(
            name: "HelloWorldSwiftMetrics",
            dependencies: ["SwiftMetrics", "Kitura", "HeliumLogger"]),
        .target(
            name: "HelloWorldSwiftMetricsHTTP",
            dependencies: ["SwiftMetrics", "Kitura", "HeliumLogger"])
    ]
)
