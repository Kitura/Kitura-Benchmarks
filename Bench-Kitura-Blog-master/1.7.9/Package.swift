import PackageDescription

var dependencies: [Package.Dependency] = []

#if os(Linux)
dependencies += [
    .Package(url: "https://github.com/IBM-Swift/CEpoll.git", Version(0, 1, 1)),
    .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", Version(0, 9, 49)),
    .Package(url: "https://github.com/IBM-Swift/OpenSSL.git", Version(0, 3, 7))
]
#endif

dependencies += [
    // self-contained dependencies
    .Package(url: "https://github.com/IBM-Swift/CCurl.git", Version(0, 4, 1)),
    .Package(url: "https://github.com/IBM-Swift/Kitura-TemplateEngine.git", Version(1, 7, 2)),
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", Version(1, 7, 1)),
    .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", Version(0, 12, 67)),
    .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", Version(17, 0, 0)),

    // depends on LoggerAPI
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", Version(1, 7, 1)),

    // depends on BlueSocket and OpenSSL (Linux)
    .Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", Version(0, 12, 54)),

    // depends on LoggerAPI, BlueSocket, CCurl, BlueSSLService, and CEpoll (Linux-only)
    .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", Version(1, 7, 16)),

    // depends on Kitura-net, Kitura-TemplateEngine, and SwiftyJSON
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", Version(1, 7, 9)),
]

let package = Package(
    name: "Bench-Kitura-Blog",
    dependencies: dependencies
)
