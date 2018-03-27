import PackageDescription

var dependencies: [Package.Dependency] = []

#if os(Linux)
dependencies += [
    .Package(url: "https://github.com/IBM-Swift/CEpoll.git", Version(0, 1, 1)),
    .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", Version(0, 9, 49)),
    .Package(url: "https://github.com/IBM-Swift/OpenSSL.git", Version(0, 3, 7))
]
#else
dependencies.append(.Package(url: "https://github.com/IBM-Swift/CommonCrypto.git", Version(0, 1, 5)))
#endif

dependencies += [
    // self-contained dependencies
    .Package(url: "https://github.com/IBM-Swift/CCurl.git", Version(0, 4, 1)),
    .Package(url: "https://github.com/IBM-Swift/CZlib.git", Version(0, 1, 2)),
    .Package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", Version(1, 7, 2)),
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", Version(1, 7, 1)),
    .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", Version(0, 12, 67)),
    .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", Version(17, 0, 0)),

    // depends on CommonCrypto (Darwin) or OpenSSL (Linux)
    .Package(url: "https://github.com/IBM-Swift/BlueCryptor.git", Version(0, 8, 16)),

    // depends on LoggerAPI
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", Version(1, 7, 1)),

    // depends on BlueSocket
    .Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", Version(0, 12, 54)),

    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", Version(1, 7, 16)),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", Version(1, 7, 9)),

    // depends on BlueCryptor and Kitura
    .Package(url: "https://github.com/IBM-Swift/Kitura-Session.git", Version(1, 7, 0)),

    // depends on CZlib and Kitura
    .Package(url: "https://github.com/IBM-Swift/Kitura-Compression.git", Version(1, 7, 1))
]

let package = Package(
    name: "Bench-Kitura-Core",
    dependencies: dependencies
)
