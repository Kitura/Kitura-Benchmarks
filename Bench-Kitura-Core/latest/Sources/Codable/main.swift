/*
 * Copyright IBM Corporation 2016, 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Kitura
import LoggerAPI
import HeliumLogger
import Foundation

Log.logger = HeliumLogger(.info)

let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

let testCount:Int   = Int(ProcessInfo.processInfo.environment["TESTCOUNT"] ?? "10") ?? 10
let testValue:Int   = Int(ProcessInfo.processInfo.environment["TESTVALUE"] ?? "1234") ?? 1234
let intValue:Int    = testValue
let uintValue:UInt  = UInt(ProcessInfo.processInfo.environment["TESTVALUE"] ?? "1234") ?? 1234
let dblValue:Double = Double(testValue) + 0.1
let fltValue:Float  = Float(testValue) + 0.1

Log.info("TESTCOUNT = \(testCount)")
Log.info("TESTVALUE = \(testValue) (int) / \(uintValue) (uint) / \(dblValue) (double) / \(fltValue) (float)")

//
// Generate a dictionary of test data which can be sent as JSON
//
func generateJSON<T>(count: Int, value: T) -> [String:T] {
  var result:[String:T] = [:]
  for i in 1...count {
    result["\(i)"] = value
  }
  return result
}

//
// Create some static payloads which will be serialized each time a request is made
//
let intPayload = generateJSON(count: testCount, value: intValue)
let uintPayload = generateJSON(count: testCount, value: uintValue)
let dblPayload = generateJSON(count: testCount, value: dblValue)
let fltPayload = generateJSON(count: testCount, value: fltValue)
let boolPayload = generateJSON(count: testCount, value: false)
let strPayload = generateJSON(count: testCount, value: "Hello World")

let encoder = JSONEncoder()
let decoder = JSONDecoder()

let router = Router()

// TechEmpower test 6: plaintext
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    try response.end()
}

// TechEmpower test 1: JSON serialization
router.get("/json") {
request, response, next in
    let result = ["message":"Hello, World!"]
    response.headers["Server"] = "Kitura"
    try response.status(.OK).send(data: encoder.encode(result))
    try response.end()
}

// Query params for count and value
// - but currently expensive to access query params, so using env vars to control instead
//router.get("/json/Int") {
//request, response, next in
//    let count = Int(request.queryParameters["count"] ?? "10") ?? 10
//    let value = Int(request.queryParameters["value"] ?? "1234") ?? 1234
//    let result = generateJSON(count: count, value: value)
//    response.status(.OK).send(json: result)
//    try response.end()
//}

router.get("/json/Int") {
request, response, next in
    try response.status(.OK).send(data: encoder.encode(intPayload))
    try response.end()
}

router.get("/json/Double") {
request, response, next in
    try response.status(.OK).send(data: encoder.encode(dblPayload))
    try response.end()
}

router.get("/json/Bool") {
request, response, next in
    try response.status(.OK).send(data: encoder.encode(boolPayload))
    try response.end()
}

router.get("/json/UInt") {
request, response, next in
    try response.status(.OK).send(data: encoder.encode(uintPayload))
    try response.end()
}

router.get("/json/Float") {
request, response, next in
    try response.status(.OK).send(data: encoder.encode(fltPayload))
    try response.end()
}

router.get("/json/String") {
request, response, next in
    try response.status(.OK).send(data: encoder.encode(strPayload))
    try response.end()
}

router.all("/post", middleware: BodyParser())

// Process a POST request expecting a dictionary of [String:T]
func processPost<T: Decodable>(_ request: RouterRequest, _ response: RouterResponse, _ type: T) {
    guard let parsedBody = request.body else {
        response.status(.badRequest).send("Error reading request body")
        return
    }
    //  In order to use NSJSONSerialiation directly, POST requests should be made with another type
    //  (example: application/foo)
    switch(parsedBody) {
        case .json:
            response.status(.badRequest).send("To test JSONDecoder, JSON must not be sent with application/json")
        case .raw(let rawBody):
            do {
                let jsonBody = try decoder.decode([String:T].self, from: rawBody)
                if let val1 = jsonBody["1"] {
                    response.status(.OK).send("The first value was \(val1)")
                } else {
                    response.status(.badRequest).send("The first value was not available")
                }
            } catch {
                response.status(.badRequest).send("The message body could not be decoded to [String : \(T.self)]")
            }
        default:
            response.status(.badRequest).send("Body could not be parsed as JSON")
    }
}

router.post("/post/Double") {
request, response, next in
    // Why can't I write Double or Double.self ??
    processPost(request, response, dblValue)
    try response.end()
}

router.post("/post/Int") {
request, response, next in
    processPost(request, response, intValue)
    try response.end()
}

router.post("/post/String") {
request, response, next in
    processPost(request, response, "foo")
    try response.end()
}

Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()
