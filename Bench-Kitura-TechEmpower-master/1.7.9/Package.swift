import PackageDescription

var dependencies: [Package.Dependency] = []

#if os(Linux)
dependencies += [
    .Package(url: "https://github.com/IBM-Swift/CEpoll.git", Version(0, 1, 1)),
    .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", Version(0, 9, 49)),
    .Package(url: "https://github.com/IBM-Swift/OpenSSL.git", Version(0, 3, 7)),
    .Package(url: "https://github.com/PerfectlySoft/Perfect-libpq-linux.git", Version(2, 0, 1))
]
#else
dependencies += [
    .Package(url: "https://github.com/PerfectlySoft/Perfect-libpq.git", Version(2, 0, 0))
]
#endif

dependencies += [
    // self-contained dependencies
    .Package(url: "https://github.com/IBM-Swift/CCurl.git", Version(0, 4, 1)),
    .Package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", Version(1, 7, 2)),
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", Version(1, 7, 1)),
    .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", Version(0, 12, 67)),
    .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", Version(17, 0, 0)),
    .Package(url: "https://github.com/IBM-Swift/Swift-Kuery.git", Version(0, 13, 3)),
    .Package(url: "https://github.com/kylef/Spectre.git", Version(0, 7, 2)),
    .Package(url: "https://github.com/IBM-Swift/CLibpq.git", Version(0, 1, 2)),
    // self-contained dependencies (MongoKitten)
    .Package(url: "https://github.com/OpenKitten/BSON.git", Version(5, 2, 3)),
    .Package(url: "https://github.com/OpenKitten/Cheetah.git", Version(2, 0, 2)),
    .Package(url: "https://github.com/OpenKitten/CryptoKitten.git", Version(0, 2, 3)),
    .Package(url: "https://github.com/OpenKitten/Schrodinger.git", Version(1, 0, 1)),
    .Package(url: "https://github.com/OpenKitten/KittenCTLS.git", Version(1, 0, 1)),

    // depends on Perfect-libpq or Perfect-libpq-linux
    .Package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", Version(2, 0, 2)),

    // depends on LoggerAPI
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", Version(1, 7, 1)),
    .Package(url: "https://github.com/IBM-Swift/Configuration.git", Version(1, 0, 4)),

    // depends on BlueSocket
    .Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", Version(0, 12, 54)),

    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", Version(1, 7, 16)),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", Version(1, 7, 9)),

    // depends on Spectre
    .Package(url: "https://github.com/kylef/PathKit.git", Version(0, 8, 0)),

    // depends on PathKit, Spectre
    .Package(url: "https://github.com/kylef/Stencil", Version(0, 10, 1)),

    // depends on Kitura-TemplateEngine, Stencil
    .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", Version(1, 8, 4)),

    // depends on HeliumLogger, Kitura-net, SwiftyJSON
    .Package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", Version(1, 7, 2)),

    // depends on SwiftKuery, CLibpq
    .Package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL.git", Version(0, 12, 3)),

    // depends on BSON, Cheetah, CryptoKitten, Schrodinger and KittenCTLS
    .Package(url: "https://github.com/OpenKitten/MongoKitten.git", Version(4, 1, 2)),
]

let package = Package(
    name: "Bench-Kitura-TechEmpower",
    dependencies: dependencies
)
