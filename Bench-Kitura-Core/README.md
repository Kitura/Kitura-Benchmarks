# Bench-Kitura-Core
Performance tests for core Kitura components.

## Descriptions of benchmarks (targets)

### HelloWorld

A simple benchmark which responds to:
- http://localhost:8080/plaintext with `Hello, World!`
- http://localhost:8080/json with `{ "message": "Hello, World!" }`

HeliumLogger is enabled (`.info` level).

### HelloLogging

A similar workload to HelloWorld, but with HeliumLogger enabled (`.info` level).  

Responds to:
- http://localhost:8080/plaintext with `Hello, World!`
- http://localhost:8080/log with `Hello, World!`, but additionally logs this message via `Log.info()` (one log entry per request).
- http://localhost:8080/plaintext2 with  `Hello, World!`, but additionally logs a String which interpolates an expensive function call via `Log.debug()`. The intention is to test the effectiveness of autoclosures for delaying String evaluation when a message will not be logged.

### HelloSSL

The same benchmark as HelloWorld, but with SSL enabled. 
HeliumLogger is enabled (`.info` level). 

Responds to:
- https://localhost:8443/plaintext with `Hello, World!`
- https://localhost:8443/json with `{ "message": "Hello, World!" }`

The SSL certificate used by this benchmark is stored within `/ssl`, generated following the [SSL tutorial on kitura.io](http://www.kitura.io/en/resources/tutorials/ssl.html). The certificate is self-signed (ie. not trusted). If using `curl` to access the server, you will need to pass the `-k` / `--insecure` flag.

When driving this benchmark on a Mac, a custom keychain should be created before executing, to avoid password prompts to unlock the keychain. The keychain should be cleared before another executable is used with the same certificate.  A script to do this is provided at `/scripts/ssl_setup.sh`.

### HelloMiddleware

Similar to HelloWorld, but enables the Session, Compression and BodyParser middlewares. 
HeliumLogger is enabled (`.info` level). 

Responds to:
- http://localhost:8080/plaintext with `Hello, World!`
- Serves static files stored in `/public` from `http://localhost:8080/`

The main purpose of this benchmark is to measure memory utilization in the presence of common middlewares.

This benchmark can be driven using JMeter, and a suitable script is provided at `/jmeter/Browser.jmx`.

### StaticFile

Serves static files stored in `/public` from http://localhost:8080/file/. 
HeliumLogger is enabled (`.info` level).

The primary purpose of this benchmark is to measure memory utilization when serving files of different sizes:
- A trivial file containing just the text `Hello World File!` is provided in `/public/hello.txt`
- Larger payloads can be generated on the fly, for example: `dd if=/dev/zero of=public/test16M bs=1024 count=16384` to generate a 16mb test file

A copy of the Kitura.io website is at `/public/index.html` and the associated files in the `assets` and `Kitura_files` subdirectories.  Simple workload drivers such as `wrk` do not request the embedded page resources like a real browser would, however `jmeter` has this capability and can be used as a simple browser simulation.

### JSON and JSONSwifty

The `JSONSwifty` benchmark has been removed for Kitura 2.0 onwards, as Kitura no longer uses the `SwiftyJSON` package. As of Kitura 2.0, `application/raw` and `application/json` essentially do the same thing, with the JSON deserialization occuring once the JSON has been posted to the server for `/json`  and in the benchmark code for `/raw`.

Benchmarks for JSON parsing and serialization.

The `JSON` benchmark uses an API introduced in Kitura 1.7 to send a dictionary as JSON without invoking SwiftyJSON, instead invoking JSONSerialization to convert the dictionary directly to a `Data`.

The `SwiftyJSON` benchmark is the equivalent implementation using the previous API that expects a SwiftyJSON `JSON` type.

LUA scripts for JSON parsing are stored in `/payloads`, for use with the `/post/Double` route of the `JSON` benchmark. The 'raw' payload describes the payload as `application/raw` and is decoded directly using NSJSONSerialization. The other is described as `application/JSON` and is decoded using SwiftyJSON.

### Codable, CodableLarge and CodableSmall

Three benchmarks covering the `JSONEncoder` and `JSONDecoder` facilities added to Foundation in Swift 4.0:

- `Codable`: provides routes:
  - `/json/Double`, `/json/Int` and so on which serialize a `Dictionary` containing values of that type, using `JSONEncoder.encode`
  - `/post/Double`, `/post/Int` and `/post/String` which use `JSONDecoder.decode` to deserialize a JSON payload to a `Dictionary` of the appropriate type.  Sample payloads for `curl` and `wrk` are provided in `/payloads`.
- `CodableLarge`: Tests Codable using a large (6.8mb) JSON document. Routes `/json/Large` and `/post/largeJson` allow a GET or POST of the large json document.  The document itself is under `/Sources/CodableLarge/large.json`.
- `CodableSmall`: Tests Codable using a small JSON document mapped to a struct containing a mixture of Swift numeric types. `/json/Small` and `/post/smallJson` are the corresponding GET and POST routes.  The document itself is under `/Sources/CodableSmall/small.json`. A POST payload for `wrk` is provided at `/payloads/jsonRawSmall.lua`.

To drive the `POST` routes, the `Content-type` header must be set to `application/raw` (or at least, must **not** be set to `application/json` because this invokes Kitura's SwiftJSON decoder).  For example:
`curl -H 'Content-type: application/raw' -d@dblPayload.json http://localhost:8080/post/Double`
`wrk -c1 -t1 -d10s http://localhost:8080/post/Double --script dblPayload.lua --`

Due to the size of the document, a wrk payload is not provided for `CodableLarge`, but could be easily assembled: `cat payloads/rawheader.txt latest/Sources/CodableLarge/large.json payloads/rawfooter.txt > payloads/jsonRawLarge.lua`

### CodableRouting

This benchmark covers the Codable Routing functionality added in Kitura 2.0. It allows for structs to be sent and received and provides the following routes:

- `/getHelloId/:id` which returns a single struct when an ID is provided. For example `curl http://localhost:8080/getHelloId/1`
- `/getAllHellos` which returns an array of structs.
- `/postHello` which returns the ID of the Codable instance in the location HTTP header.

To drive the `POST` route, the `Content-Type` header must be set to `application/json` and the data provided in a struct with a single `value` key and String value. An example request is `curl -X POST http://localhost:8080/postHello -d '{"value":"Hello World!"}' -H "Content-Type: application/json"` or using the sample payload:  `wrk -c1 -t1 -d10s http://localhost:8080/postHello --script payloads/simpleStructPayload.lua`

