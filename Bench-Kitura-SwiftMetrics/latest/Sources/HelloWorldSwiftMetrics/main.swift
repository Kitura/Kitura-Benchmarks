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
import SwiftMetrics

let sm = try SwiftMetrics()
let monitoring = sm.monitor()

Log.logger = HeliumLogger(.info)

let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

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
    response.status(.OK).send(json: result)
    try response.end()
}

Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()
