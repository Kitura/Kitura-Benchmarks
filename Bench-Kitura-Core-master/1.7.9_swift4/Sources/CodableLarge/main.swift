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

let encoder = JSONEncoder()
let decoder = JSONDecoder()

let largeData: Data = {
    let path = URL(fileURLWithPath: #file).appendingPathComponent("../large.json").standardized.path
    let file = FileHandle(forReadingAtPath: path)!
    let data = file.readDataToEndOfFile()
    file.closeFile()
    return data
}()

let largeStruct = try! decoder.decode(Large.self, from: largeData)

let router = Router()

router.get("/json/Large") { request, response, next in
    try response.status(.OK).send(data: encoder.encode(largeStruct))
    try response.end()
}

router.all("/post", middleware: BodyParser())

router.post("/post/largeJson") { request, response, next in
    guard let parsedBody = request.body else {
        response.status(.badRequest).send("Error reading request body")
        return
    }
    //  In order to use NSJSONSerialiation directly, POST requests should be made with another type
    //  (example: application/foo)
    switch(parsedBody) {
    case .raw(let rawBody):
        do {
            let large = try decoder.decode(Large.self, from: rawBody)
            if large.programList.programs.count == 4710 {
                response.status(.OK).send("The decoded struct's programs count is 4710.")
            } else {
                response.status(.badRequest).send("The decoded struct had an invalid program count.")
            }
        } catch {
            response.status(.badRequest).send("The message body could not be decoded as Large struct.")
        }
    default:
        response.status(.badRequest).send("Body could not be parsed as JSON")
    }
    try response.end()
}

Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()
