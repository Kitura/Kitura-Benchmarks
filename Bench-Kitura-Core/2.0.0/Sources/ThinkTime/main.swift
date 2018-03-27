/*
 * Copyright IBM Corporation 2017
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
import Dispatch

Log.logger = HeliumLogger(.info)

let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

// 'Think' time (ms) of the /think/sync and /think/async routes
let thinkTime:Int      = Int(ProcessInfo.processInfo.environment["THINKTIME"] ?? "5") ?? 5
let thinkTimeUs:UInt32 = UInt32(thinkTime) * 1000

let router = Router()

router.post("/unparsedPost") {
request, response, next in
    response.status(.OK).send("OK")
    try response.end()
}

router.post("/parsedPost", middleware: BodyParser())

router.post("/parsedPost") {
request, response, next in
    guard let parsedBody = request.body else {
        response.status(.badRequest).send("Error reading request body")
        try response.end()
        return
    }
    switch(parsedBody) {
        case .raw(let rawBody):
            let contentLength = rawBody.count
            response.status(.OK).send("Length of POST: \(contentLength) bytes")
        default:
            response.status(.badRequest).send("Expected a raw message body")
    }
    try response.end()
}

router.get("/think/sync") {
request, response, next in
    usleep(thinkTimeUs)
    response.status(.OK).send("OK")
    try response.end()
}

router.get("/think/async") {
request, response, next in
    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(thinkTime)) {
      do {
        response.status(.OK).send("OK")
        try response.end()
      } catch {
        print("Disaster")
      }
    }
}

let oneKBData = Data(repeating: 0x75, count: 1024)
let tenKBData = Data(repeating: 0x76, count: 10240)
let hundredKBData = Data(repeating: 0x77, count: 102400)
let oneMBData = Data(repeating: 0x78, count: 1048576)

router.get("/1k") {
request, response, next in
    response.status(.OK).send(data: oneKBData)
    try response.end()
}

router.get("/10k") {
request, response, next in
    response.status(.OK).send(data: tenKBData)
    try response.end()
}

router.get("/100k") {
request, response, next in
    response.status(.OK).send(data: hundredKBData)
    try response.end()
}

router.get("/1mb") {
request, response, next in
    response.status(.OK).send(data: oneMBData)
    try response.end()
}

Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()
