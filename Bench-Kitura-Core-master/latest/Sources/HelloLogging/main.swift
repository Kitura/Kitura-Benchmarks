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

// Enable warnings
Log.logger = HeliumLogger(.info)

let router = Router()

// Simple plaintext response
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    try response.end()
}

// Simple plaintext response, generate 1 log message per request
router.get("/log") {
request, response, next in
    Log.info("Hello, World!")
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    try response.end()
}

// Artificially expensive function to call while interpolating a log message
func expensiveFunction() -> String {
    var data = Data()
    for i in 1...20 {
      data.append("Foo Bar \(i) ".data(using: .utf8)!)
    }
    return "Blah"
}

// Simple plaintext response with an expensive debug level log message
router.get("/plaintext2") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    Log.debug("Expensive function says: \(expensiveFunction())")
    try response.end()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
