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
import SwiftyJSON

Log.logger = HeliumLogger(.info)

let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

//
// Create a Codable struct which can be sent
//
public struct simpleStruct {
    public var value: String
    public var id: Int?
    
    public var dictionary: [String: Any] {
        // Ensure id doesn't come out as Optional(n)
        if let id = id {
            return ["value": value,
                    "id": id]
        }
        else {
            return ["value": value]
        }
    }
}

let router = Router()

router.get("/getHelloId/:id") {
    request, response, next in
    response.headers["Server"] = "Kitura"
    let id = Int(request.parameters["id"] ?? "")
    let helloStruct = simpleStruct(value: "Hello World", id: id)
    let result = JSON(helloStruct.dictionary)
    response.status(.OK).send(json: result)
    try response.end()
}


router.get("/getAllHellos") {
    request, response, next in
    response.headers["Server"] = "Kitura"
    let helloStruct1 = simpleStruct(value: "Hello World", id: 1)
    let helloStruct2 = simpleStruct(value: "Hello World", id: 2)
    let result = JSON([helloStruct1.dictionary, helloStruct2.dictionary])
    response.status(.OK).send(json: result)
    try response.end()
}

router.all("/postHello", middleware: BodyParser())

router.post("/postHello") {
    request, response, next in
    
    guard let parsedBody = request.body else {
        response.status(.badRequest).send("Error reading request body")
        try response.end()
        return
    }
    switch(parsedBody) {
        
    case .json(let jsonBody):
        guard let dict = jsonBody.dictionary else {
            response.status(.badRequest).send("The object posted was not a dictionary/struct")
            return
        }
        guard let value = dict["value"] else {
            response.status(.badRequest).send("The object posted did not contain a 'value' key")
            return
        }
        guard let valueString = value.string else {
            response.status(.badRequest).send("The object posted did not contain a String value")
            return
        }
        guard let id = dict["id"] else {
            let helloStruct = simpleStruct(value: valueString, id: nil)
            let result = JSON(helloStruct.dictionary)
            response.status(.OK).send(json: result)
            return
        }
        guard let idInt = id.int else {
            response.status(.badRequest).send("The object posted did not contain a Int ID")
            return
        }
        let helloStruct = simpleStruct(value: valueString, id: idInt)
        let result = JSON(helloStruct.dictionary)
        response.status(.OK).send(json: result)
        
    case .raw(let rawBody):
        let jsonBody = try JSONSerialization.jsonObject(with: rawBody)
        guard let helloJSON = jsonBody as? [String: Any?] else {
            response.status(.badRequest).send("The object posted couldn't be converted to [String : Any?]")
            return
        }
        guard let value = helloJSON["value"] else {
            response.status(.badRequest).send("The object posted did not contain a 'value' key")
            return
        }
        guard let valueString = value as? String else {
            response.status(.badRequest).send("The object posted did not contain a String value")
            return
        }
        
        let id = helloJSON["id"] ?? 1 //Simulate assinging ID
        
        guard let idInt = id as? Int else {
            response.status(.badRequest).send("The object posted did not contain a Int ID")
            return
        }
        let helloStruct = simpleStruct(value: valueString, id: idInt)
        let result = JSON(helloStruct.dictionary)
        response.status(.OK).send(json: result)
        try response.end()
    default:
        response.status(.badRequest).send("Error parsing request body")
        }
    }


Kitura.addHTTPServer(onPort: port, with: router)
Kitura.run()


