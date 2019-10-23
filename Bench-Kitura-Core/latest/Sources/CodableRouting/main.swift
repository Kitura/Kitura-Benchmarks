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
import KituraContracts
import BSON

Log.logger = HeliumLogger(.info)

let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

//
// Create a Codable struct which can be sent
//
public struct simpleStruct : Codable {
    public var value: String
}

let router = Router()

let helloStruct = simpleStruct(value: "Hello World")

// Support application/bson using OpenKitten/BSON
extension BSONEncoder: BodyEncoder {
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
        let document: Document = try self.encode(value)
        return Data(bytes: document.bytes)
    }
}
extension BSONDecoder: BodyDecoder {
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        let document = Document(data: data)
        return try self.decode(type, from: document)
    }
}
router.encoders[MediaType(type: .application, subType: "bson")] = { return BSONEncoder() }
router.decoders[MediaType(type: .application, subType: "bson")] = { return BSONDecoder() }

// To return a struct, must provide an integer id after the route e.g. "/getHelloId/1"
router.get("/getHelloId") { (id: Int, completion: (simpleStruct?, RequestError?) -> Void) in
    completion(helloStruct, nil)
}


router.get("/getAllHellos") { (completion: ([simpleStruct]?, RequestError?) -> Void ) in
    completion([helloStruct, helloStruct], nil)
}

router.post("/postHello") { (helloStruct: simpleStruct, completion: (Int?, simpleStruct?, RequestError?) -> Void) in
    completion(0, helloStruct, nil)
}


Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()

