// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var benchmarkDependencies: [Target.Dependency] = [
	.byNameItem(name: "Kitura"),
	.byNameItem(name: "HeliumLogger"),
.byNameItem(name: "BSON"),
]

let package = Package(
    name: "Bench-Kitura-Core",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.2.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", from: "3.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-Compression.git", from: "2.1.1"),
	.package(url: "https://github.com/OpenKitten/BSON.git", from: "5.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "HelloWorld",   dependencies: benchmarkDependencies),
        .target(name: "QueryParams",  dependencies: benchmarkDependencies),
        .target(name: "HelloLogging", dependencies: benchmarkDependencies),
        .target(name: "HelloSSL",     dependencies: benchmarkDependencies),
        .target(name: "JSON",         dependencies: benchmarkDependencies),
        .target(name: "StaticFile",   dependencies: benchmarkDependencies),
        .target(name: "ThinkTime",    dependencies: benchmarkDependencies),
        .target(name: "Codable",      dependencies: benchmarkDependencies),
        .target(name: "CodableLarge", dependencies: benchmarkDependencies),
        .target(name: "CodableSmall", dependencies: benchmarkDependencies),
        .target(name: "CodableRouting", dependencies: benchmarkDependencies),
        .target(
            name: "HelloMiddleware",
            dependencies: ["Kitura", "HeliumLogger", "KituraSession", "KituraCompression"]),
    ]
)
