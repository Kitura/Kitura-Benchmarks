/*
 * Copyright IBM Corporation 2016
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
let uintValue:UInt  = UInt(testValue)
let dblValue:Double = Double(testValue) + 0.1
let fltValue:Float  = Float(testValue) + 0.1

Log.info("TESTCOUNT = \(testCount)")
Log.info("TESTVALUE = \(testValue)")

//
// Generate a dictionary of test data which can be sent as JSON
//
func generateJSON(count: Int, value: Any) -> [String:Any] {
  var result:[String:Any] = [:]
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

let router = Router()

// TechEmpower test 6: plaintext
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    try response.end()
}

// TechEmpower test 1: JSON serialization
// Note: no longer using SwiftyJSON
router.get("/json") {
request, response, next in
    var result = ["message":"Hello, World!"]
    response.headers["Server"] = "Kitura"
    response.status(.OK).send(json: result)
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
    response.status(.OK).send(json: intPayload)
    try response.end()
}

router.get("/json/Double") {
request, response, next in
    response.status(.OK).send(json: dblPayload)
    try response.end()
}

router.get("/json/Bool") {
request, response, next in
    response.status(.OK).send(json: boolPayload)
    try response.end()
}

router.get("/json/UInt") {
request, response, next in
    response.status(.OK).send(json: uintPayload)
    try response.end()
}

router.get("/json/Float") {
request, response, next in
    response.status(.OK).send(json: fltPayload)
    try response.end()
}

router.get("/json/String") {
request, response, next in
    response.status(.OK).send(json: strPayload)
    try response.end()
}

router.all("/post", middleware: BodyParser())

router.post("/post/Double") {
request, response, next in
    guard let parsedBody = request.body else {
        response.status(.badRequest).send("Error reading request body")
        try response.end()
        return
    }
    // Kitura decodes application/json using SwiftyJSON. In order to use NSJSONSerialiation
    // directly, POST requests should be made with another type (example: application/foo)
    switch(parsedBody) {
        case .json(let jsonBody):
	    guard let val1 = jsonBody["1"].double else {
                response.status(.badRequest).send("(Swifty) The first value was not a double")
                try response.end()
                return
            }
            response.status(.OK).send("(Swifty) The first value was \(val1)")
        case .raw(let rawBody):
            let jsonBody = try JSONSerialization.jsonObject(with: rawBody)
            guard let jsonDict = jsonBody as? [String:Any] else {
                response.status(.badRequest).send("(Raw) The jsonBody was not a [String:Any]")
                try response.end()
                return
            }
            guard let val1 = jsonDict["1"] as? Double else {
                response.status(.badRequest).send("(Raw) The first value was not a double")
                try response.end()
                return
            }
            response.status(.OK).send("(Raw) The first value was \(val1)")
        default:
            response.status(.badRequest).send("Body could not be parsed as JSON")
    }
    try response.end()
}

router.post("/post/Int") {
request, response, next in
    guard let parsedBody = request.body else {
        response.status(.badRequest).send("Error reading request body")
        try response.end()
        return
    }
    // Kitura decodes application/json using SwiftyJSON. In order to use NSJSONSerialiation
    // directly, POST requests should be made with another type (example: application/foo)
    switch(parsedBody) {
        case .json(let jsonBody):
	    guard let val1 = jsonBody["1"].int else {
                response.status(.badRequest).send("(Swifty) The first value was not an int")
                try response.end()
                return
            }
            response.status(.OK).send("(Swifty) The first value was \(val1)")
        case .raw(let rawBody):
            let jsonBody = try JSONSerialization.jsonObject(with: rawBody)
            guard let jsonDict = jsonBody as? [String:Any] else {
                response.status(.badRequest).send("(Raw) The jsonBody was not a [String:Any]")
                try response.end()
                return
            }
            guard let val1 = jsonDict["1"] as? Int else {
                response.status(.badRequest).send("(Raw) The first value was not an int")
                try response.end()
                return
            }
            response.status(.OK).send("(Raw) The first value was \(val1)")
        default:
            response.status(.badRequest).send("Body could not be parsed as JSON")
    }
    try response.end()
}

router.post("/post/String") {
request, response, next in
    guard let parsedBody = request.body else {
        response.status(.badRequest).send("Error reading request body")
        try response.end()
        return
    }
    // Kitura decodes application/json using SwiftyJSON. In order to use NSJSONSerialiation
    // directly, POST requests should be made with another type (example: application/foo)
    switch(parsedBody) {
        case .json(let jsonBody):
	    guard let val1 = jsonBody["1"].string else {
                response.status(.badRequest).send("(Swifty) The first value was not a string")
                try response.end()
                return
            }
            response.status(.OK).send("(Swifty) The first value was \(val1)")
        case .raw(let rawBody):
            let jsonBody = try JSONSerialization.jsonObject(with: rawBody)
            guard let jsonDict = jsonBody as? [String:Any] else {
                response.status(.badRequest).send("(Raw) The jsonBody was not a [String:Any]")
                try response.end()
                return
            }
            guard let val1 = jsonDict["1"] as? String else {
                response.status(.badRequest).send("(Raw) The first value was not a string")
                try response.end()
                return
            }
            response.status(.OK).send("(Raw) The first value was \(val1)")
        default:
            response.status(.badRequest).send("Body could not be parsed as JSON")
    }
    try response.end()
}

Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()
