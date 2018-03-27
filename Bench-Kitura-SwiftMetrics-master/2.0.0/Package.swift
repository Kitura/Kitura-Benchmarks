// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var dependencies: [Package.Dependency] = [
    // self-contained dependencies
    .package(url: "https://github.com/IBM-Swift/CCurl.git", .exact("0.4.1")),
    .package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", .exact("1.7.2")),
    .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", .exact("1.7.1")),
    .package(url: "https://github.com/IBM-Swift/BlueSocket.git", .exact("0.12.76")),
    .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .exact("17.0.0")),

    // depends on BlueSocket
    .package(url: "https://github.com/IBM-Swift/BlueSSLService.git", .exact("0.12.64")),

    // depends on CommonCrypto (Darwin) or OpenSSL (Linux)
    .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", .exact("0.8.21")),

    // depends on LoggerAPI
    .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .exact("1.7.1")),
    .package(url: "https://github.com/IBM-Swift/Configuration.git", .exact("1.0.4")),

    // depends on LoggerAPI and Configuration
    .package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", .exact("4.1.0")),

    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .package(url: "https://github.com/IBM-Swift/Kitura-net.git", .exact("1.7.19")),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .package(url: "https://github.com/IBM-Swift/Kitura.git", .exact("2.0.0")),

    // depends on Kitura-net
    .package(url: "https://github.com/IBM-Swift/Kitura-Request.git", .exact("0.8.2")),

    // depends on Kitura-net and BlueCryptor
    .package(url: "https://github.com/IBM-Swift/Kitura-WebSocket.git", .exact("0.9.1")),

    // depends on Kitura, Kitura-WebSocket, Kitura-Request and Swift-cfenv
    .package(url: "https://github.com/RuntimeTools/omr-agentcore", .exact("3.2.4-swift4")),
    .package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", .exact("2.0.1")),
]

// Platform-specific dependencies
#if os(Linux)
dependencies.append(contentsOf: [
    .package(url: "https://github.com/IBM-Swift/CEpoll.git", .exact("0.1.1")),
    .package(url: "https://github.com/IBM-Swift/BlueSignals.git", .exact("0.9.50")),
    .package(url: "https://github.com/IBM-Swift/OpenSSL.git", .exact("0.3.7")),
])
#else
dependencies.append(contentsOf: [
    .package(url: "https://github.com/IBM-Swift/CommonCrypto.git", .exact("0.1.5")),
])
#endif

let package = Package(
    name: "Bench-Kitura-SwiftMetrics",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Bench-Kitura-SwiftMetrics",
            targets: ["HelloWorld", "HelloWorldSwiftMetrics", "HelloWorldSwiftMetricsHTTP"]),
    ],
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "HelloWorld",
            dependencies: ["Kitura", "HeliumLogger"]),
        .target(name: "HelloWorldSwiftMetrics",
            dependencies: ["Kitura", "HeliumLogger", "SwiftMetrics"]),
        .target(name: "HelloWorldSwiftMetricsHTTP",
            dependencies: ["Kitura", "HeliumLogger", "SwiftMetrics"]),
    ]
)
