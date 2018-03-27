// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kitura-Bench-TechEmpower",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Kitura-Bench-TechEmpower",
            targets: ["TechEmpowerCouch", "TechEmpowerKuery", "TechEmpowerKueryPostgres", "TechEmpowerKueryMustache", "TechEmpowerMongoKitten"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.2.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Configuration.git", from: "3.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", from: "2.0.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL", from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", from: "1.8.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-MustacheTemplateEngine.git", from: "1.7.2"),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "4.0.0"),
    ],
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
            name: "TechEmpowerKueryMustache",
            dependencies: ["Kitura", "HeliumLogger", "Configuration", "SwiftKueryPostgreSQL", "KituraMustache"]),
        .target(
            name: "TechEmpowerMongoKitten",
            dependencies: ["Kitura", "HeliumLogger", "Configuration", "MongoKitten", "KituraStencil"]),
    ]
)
