import PackageDescription

var dependencies: [Package.Dependency] = []

#if os(Linux)
dependencies += [
    .Package(url: "https://github.com/IBM-Swift/CEpoll.git", Version(0, 1, 0)),
    .Package(url: "https://github.com/IBM-Swift/OpenSSL.git", Version(0, 3, 1))
]
#else
dependencies.append(.Package(url: "https://github.com/IBM-Swift/CommonCrypto.git", Version(0, 1, 4)))
#endif

dependencies += [
    // self-contained dependencies
    .Package(url: "https://github.com/IBM-Swift/CCurl.git", Version(0, 2, 3)),
    .Package(url: "https://github.com/IBM-Swift/CZlib.git", Version(0, 1, 1)),
    .Package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", Version(1, 7, 0)),
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", Version(1, 7, 0)),
    .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", Version(0, 12, 42)),
    .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", Version(16, 0, 0)),

    // depends on CommonCrypto (Darwin) or OpenSSL (Linux)
    .Package(url: "https://github.com/IBM-Swift/BlueCryptor.git", Version(0, 8, 9)),

    // depends on LoggerAPI
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", Version(1, 7, 0)),

    // depends on BlueSocket
    .Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", Version(0, 12, 32)),

    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", Version(1, 7, 0)),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", Version(1, 7, 0)),

    // depends on BlueCryptor and Kitura
    .Package(url: "https://github.com/IBM-Swift/Kitura-Session.git", Version(1, 7, 0)),

    // depends on CZlib and Kitura
    .Package(url: "https://github.com/IBM-Swift/Kitura-Compression.git", Version(1, 7, 0))
]

let package = Package(
    name: "Kitura-Bench",
    dependencies: dependencies
)
