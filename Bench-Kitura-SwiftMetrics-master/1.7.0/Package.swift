import PackageDescription

var dependencies: [Package.Dependency] = []

#if os(Linux)
dependencies += [
    .Package(url: "https://github.com/IBM-Swift/CEpoll.git", Version(0, 1, 0)),
    .Package(url: "https://github.com/IBM-Swift/OpenSSL.git", Version(0, 3, 1)),
]
#else
dependencies.append(.Package(url: "https://github.com/IBM-Swift/CommonCrypto.git", Version(0, 1, 4)))
#endif

dependencies += [
    // self-contained dependencies
    .Package(url: "https://github.com/IBM-Swift/CCurl.git", Version(0, 2, 3)),
    .Package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", Version(1, 7, 0)),
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", Version(1, 7, 0)),
    .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", Version(0, 12, 42)),
    .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", Version(16, 0, 0)),

    // depends on BlueSocket, and OpenSSL (Linux-only)
    .Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", Version(0, 12, 32)),

    // depends on CommonCrypto (Darwin) or OpenSSL (Linux)
    .Package(url: "https://github.com/IBM-Swift/BlueCryptor.git", Version(0, 8, 9)),

    // depends on LoggerAPI
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", Version(1, 7, 0)),
    .Package(url: "https://github.com/IBM-Swift/Configuration.git", Version(1, 0, 0)),

    // depends on LoggerAPI and Configuration
    .Package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", Version(4, 0, 2)),

    // depends on Swift-cfenv
    .Package(url: "https://github.com/IBM-Swift/CloudConfiguration.git", Version(2, 0, 5)),
    
    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", Version(1, 7, 0)),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", Version(1, 7, 0)),
    
    // depends on Kitura-net
    .Package(url: "https://github.com/IBM-Swift/Kitura-Request.git", Version(0, 8, 0)),

    // depends on Kitura-net and BlueCryptor
    .Package(url: "https://github.com/IBM-Swift/Kitura-WebSocket.git", Version(0, 8, 0)),

    // depends on Kitura, Kitura-WebSocket, Kitura-Request and CloudConfiguration
    .Package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", Version(1, 0, 3)),
]

let package = Package(
    name: "Kitura-Bench-SwiftMetrics",
    dependencies: dependencies
)
