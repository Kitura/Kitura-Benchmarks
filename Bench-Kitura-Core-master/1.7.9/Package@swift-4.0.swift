// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var dependencies: [Package.Dependency] = [
    // self-contained dependencies
    .package(url: "https://github.com/IBM-Swift/CCurl.git", .exact("0.4.1")),
    .package(url: "https://github.com/IBM-Swift/CZlib.git", .exact("0.1.2")),
    .package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", .exact("1.7.2")),
    .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", .exact("1.7.1")),
    .package(url: "https://github.com/IBM-Swift/BlueSocket.git", .exact("0.12.67")),
    .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .exact("17.0.0")),

    // depends on CommonCrypto (Darwin) or OpenSSL (Linux)
    .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", .exact("0.8.16")),

    // depends on LoggerAPI
    .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .exact("1.7.1")),

    // depends on BlueSocket
    .package(url: "https://github.com/IBM-Swift/BlueSSLService.git", .exact("0.12.54")),

    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .package(url: "https://github.com/IBM-Swift/Kitura-net.git", .exact("1.7.16")),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .package(url: "https://github.com/IBM-Swift/Kitura.git", .exact("1.7.9")),

    // depends on BlueCryptor and Kitura
    .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", .exact("1.7.0")),

    // depends on CZlib and Kitura
    .package(url: "https://github.com/IBM-Swift/Kitura-Compression.git", .exact("1.7.1")),
]

// Platform-specific dependencies
#if os(Linux)
dependencies.append(contentsOf: [
    .package(url: "https://github.com/IBM-Swift/CEpoll.git", .exact("0.1.1")),
    .package(url: "https://github.com/IBM-Swift/BlueSignals.git", .exact("0.9.49")),
    .package(url: "https://github.com/IBM-Swift/OpenSSL.git", .exact("0.3.7")),
])
#else
dependencies.append(contentsOf: [
    .package(url: "https://github.com/IBM-Swift/CommonCrypto.git", .exact("0.1.5")),
])
#endif

var benchmarkDependencies: [Target.Dependency] = [
	.byNameItem(name: "Kitura"),
	.byNameItem(name: "HeliumLogger")
]

let package = Package(
    name: "Bench-Kitura-Core",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Bench-Kitura-Core",
            targets: ["HelloWorld", "HelloMiddleware", "HelloLogging", "HelloSSL", "JSON", "JSONSwifty", "StaticFile", "ThinkTime", "PreCodableRouting"]),
    ],
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "HelloWorld",   dependencies: benchmarkDependencies),
        .target(name: "HelloLogging", dependencies: benchmarkDependencies),
        .target(name: "HelloSSL",     dependencies: benchmarkDependencies),
        .target(name: "JSON",         dependencies: benchmarkDependencies),
        .target(name: "JSONSwifty",   dependencies: benchmarkDependencies),
        .target(name: "StaticFile",   dependencies: benchmarkDependencies),
        .target(name: "ThinkTime",    dependencies: benchmarkDependencies),
        .target(name: "PreCodableRouting",    dependencies: benchmarkDependencies),
        .target(name: "HelloMiddleware",
            dependencies: ["Kitura", "HeliumLogger", "Kitura-Session", "KituraCompression"]),
    ]
)
