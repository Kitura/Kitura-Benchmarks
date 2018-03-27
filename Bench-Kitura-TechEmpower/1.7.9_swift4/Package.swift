// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var dependencies: [Package.Dependency] = [
    // self-contained dependencies
    .package(url: "https://github.com/IBM-Swift/CCurl.git", .exact("0.4.1")),
    .package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", .exact("1.7.2")),
    .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", .exact("1.7.1")),
    .package(url: "https://github.com/IBM-Swift/BlueSocket.git", .exact("0.12.67")),
    .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", .exact("17.0.0")),
    .package(url: "https://github.com/IBM-Swift/Swift-Kuery.git", .exact("0.13.3")),
    .package(url: "https://github.com/kylef/Spectre.git", .exact("0.7.2")),
    .package(url: "https://github.com/IBM-Swift/CLibpq.git", .exact("0.1.2")),
    .package(url: "https://github.com/IBM-Swift/FileKit.git", .exact("0.0.1")),
    // self-contained dependencies (MongoKitten)
    .package(url: "https://github.com/OpenKitten/BSON.git", .exact("5.2.3")),
    .package(url: "https://github.com/OpenKitten/Cheetah.git", .exact("2.0.2")),
    .package(url: "https://github.com/OpenKitten/CryptoKitten.git", .exact("0.2.3")),
    .package(url: "https://github.com/OpenKitten/Schrodinger.git", .exact("1.0.1")),
    .package(url: "https://github.com/OpenKitten/KittenCTLS.git", .exact("1.0.1")),

    // depends on LoggerAPI
    .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .exact("1.7.1")),

    // depends on LoggerAPI and FileKit
    .package(url: "https://github.com/IBM-Swift/Configuration.git", .exact("3.0.0")),

    // depends on BlueSocket, and OpenSSL (on Linux)
    .package(url: "https://github.com/IBM-Swift/BlueSSLService.git", .exact("0.12.54")),

    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .package(url: "https://github.com/IBM-Swift/Kitura-net.git", .exact("1.7.16")),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .package(url: "https://github.com/IBM-Swift/Kitura.git", .exact("1.7.9")),

    // depends on Spectre
    .package(url: "https://github.com/kylef/PathKit.git", .exact("0.8.0")),

    // depends on PathKit, Spectre
    .package(url: "https://github.com/kylef/Stencil", .exact("0.10.1")),

    // depends on Kitura-TemplateEngine, Stencil
    .package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", .exact("1.8.4")),

    // depends on HeliumLogger, Kitura-net, SwiftyJSON
    .package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", .exact("1.7.2")),

    // depends on SwiftKuery, CLibpq
    .package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL.git", .exact("0.12.3")),

    // depends on BSON, Cheetah, CryptoKitten, Schrodinger and KittenCTLS
    .package(url: "https://github.com/OpenKitten/MongoKitten.git", .exact("4.1.2")),
]

// Platform-specific dependencies
#if os(Linux)
dependencies.append(contentsOf: [
    .package(url: "https://github.com/IBM-Swift/CEpoll.git", .exact("0.1.1")),
    .package(url: "https://github.com/IBM-Swift/BlueSignals.git", .exact("0.9.49")),
    .package(url: "https://github.com/IBM-Swift/OpenSSL.git", .exact("0.3.7")),
])
#endif

let package = Package(
    name: "Bench-Kitura-TechEmpower",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Bench-Kitura-TechEmpower",
            targets: ["TechEmpowerCouch", "TechEmpowerKuery", "TechEmpowerKueryPostgres", "TechEmpowerMongoKitten"]),
    ],
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "TechEmpowerCouch",
            dependencies: ["Kitura", "HeliumLogger", "CouchDB"]),
        .target(
            name: "TechEmpowerKuery",
            dependencies: ["Kitura", "HeliumLogger", "Configuration", "SwiftKueryPostgreSQL", "KituraStencil"]),
        .target(
            name: "TechEmpowerKueryPostgres",
            dependencies: ["Kitura", "HeliumLogger", "Configuration", "SwiftKueryPostgreSQL", "KituraStencil"]),
        .target(
            name: "TechEmpowerMongoKitten",
            dependencies: ["Kitura", "HeliumLogger", "Configuration", "MongoKitten", "KituraStencil"]),
    ]
)
