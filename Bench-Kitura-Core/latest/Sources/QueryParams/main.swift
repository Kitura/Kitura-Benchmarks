/*
 * Copyright IBM Corporation 2018
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

let router = Router()

//
// Plaintext echo of 'message' query parameter
//
router.get("/plaintext") {
request, response, next in
    let echo = request.queryParameters["message"] ?? "Supply a message using ?message=foo"
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send(echo)
    try response.end()
}

Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()
