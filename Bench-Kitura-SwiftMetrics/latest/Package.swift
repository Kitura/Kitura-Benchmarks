// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bench-Kitura-SwiftMetrics",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        //Switch back to the latest release of SwiftMetrics once tagging is done
        //.package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", from: "2.0.0"),
        .package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", .branch("bd5832af20c284093180ba40e4ca5e160d88820c")),
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
