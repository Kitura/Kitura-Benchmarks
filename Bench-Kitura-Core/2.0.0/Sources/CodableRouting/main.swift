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

Log.logger = HeliumLogger(.info)

let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

//
// Create a Codable struct which can be sent
//
public struct simpleStruct : Codable {
    public var value: String
    public var id: Int?
}

let router = Router()


// To return a struct, must provide an integer id after the route e.g. "/getHelloId/1"
router.get("/getHelloId") { (id: Int, completion: (simpleStruct?, RequestError?) -> Void) in
    let helloStruct = simpleStruct(value: "Hello World", id: id)
    completion(helloStruct, nil)
}


router.get("/getAllHellos") { (completion: ([simpleStruct]?, RequestError?) -> Void ) in
    let helloStruct1 = simpleStruct(value: "Hello World", id: 1)
    let helloStruct2 = simpleStruct(value: "Hello World", id: 2)
    completion([helloStruct1, helloStruct2], nil)
}

router.post("/postHello") { (helloStruct: simpleStruct, completion: (Int?, simpleStruct?, RequestError?) -> Void) in
    completion(0, helloStruct, nil)
}


Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()

