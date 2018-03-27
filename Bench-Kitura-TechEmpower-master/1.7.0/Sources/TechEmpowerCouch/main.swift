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
import SwiftyJSON
import Foundation
import CouchDB
import LoggerAPI
import HeliumLogger

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

//Log.logger = HeliumLogger(.warning)

// Connection properties for testing Cloudant or CouchDB instance
let connProperties = ConnectionProperties(
    host: "localhost",         // httpd address
    port: 5984,                // httpd port
    secured: false,            // https or http
    username: nil,             // username
    password: nil              // password
)
let couchDBClient = CouchDBClient(connectionProperties: connProperties)
let dbName = "world"
let dbRows = 100
let maxValue = 10000
let world = couchDBClient.database(dbName)

let router = Router()

// Get a random row
fileprivate func getRandomRow() -> (JSON?, NSError?) {
    var jsonRes: JSON? = nil
    var errRes: NSError? = nil
    #if os(Linux)
        let rnd = Int(random() % dbRows) + 1
    #else
        let rnd = Int(arc4random_uniform(UInt32(dbRows))) + 1
    #endif
    world.retrieve("\(rnd)") {
        (json: JSON?, err: NSError?) in
        if let err = err {
            errRes = err
            print("Error: \(err.localizedDescription) Code: \(err.code), rnd=\(rnd)")
        }
        guard let json = json else {
            print("Error: no result returned for record \(rnd)")
            return
        }
        jsonRes = JSON(["_id":json["_id"], "randomNumber":json["randomNumber"]])
    }
    return (jsonRes, errRes)
}

// TechEmpower test 2: Single database query
router.get("/db") {
request, response, next in
    // Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
    // Convert to object using object-relational mapping (ORM) tool
    // Serialize object to JSON - example: {"id":3217,"randomNumber":2149}

    var result = getRandomRow()
    if let json = result.0 {
      response.status(.OK).send(json: json)
    } else {
        guard let err = result.1 else {
            print("Unknown error")
            return
        }
        response.status(.badRequest).send("Error: \(err.localizedDescription) Code: \(err.code)")
    }
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

// TechEmpower test 3: Multiple database queries
// Get param provides number of queries: /queries?queries=N
// N times { 
//   Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
//   Convert to object using object-relational mapping (ORM) tool
// }
// Serialize objects to JSON - example: [{"id":4174,"randomNumber":331},{"id":51,"randomNumber":6544},{"id":4462,"randomNumber":952},{"id":2221,"randomNumber":532},{"id":9276,"randomNumber":3097},{"id":3056,"randomNumber":7293},{"id":6964,"randomNumber":620},{"id":675,"randomNumber":6601},{"id":8414,"randomNumber":6569},{"id":2753,"randomNumber":4065}]
router.get("/queries") {
request, response, next in
    //var numQueries = 10
    guard let queriesParam = request.queryParameters["queries"] else {
        response.status(.badRequest).send("Error: queries param missing")
        return
    }
    guard let numQueries = Int(queriesParam) else {
        response.status(.badRequest).send("Error: could not parse \(queriesParam) as an integer")
        return
    }
    var results: [JSON] = []
    for i in 1...numQueries {
        var result = getRandomRow()
        if let json = result.0 {
            results.append(json)
        } else {
            guard let err = result.1 else {
                print("Unknown error")
                return
            }
            response.status(.badRequest).send("Error: \(err.localizedDescription) Code: \(err.code)")
            return
        }
    }
    // Return JSON representation of array of results
    response.status(.OK).send(json: JSON(results))
    try response.end()
}

// Create DB
router.get("/create") {
request, response, next in
    couchDBClient.createDB(dbName) {
    (db: Database?, err: NSError?) in
      if let err = err {
          response.status(.badRequest).send("<pre>Error: \(err.localizedDescription) Code: \(err.code)</pre>")
      } else {
          response.status(.OK).send("<pre>OK</pre>")
      }
    }
    response.send("<h3>DB \(dbName) created</h3>")
    next()
}

// Delete DB
router.get("/delete") {
request, response, next in
    couchDBClient.deleteDB(dbName) {
      (err: NSError?) in
      if let err = err {
          response.status(.badRequest).send("<pre>Error: \(err.localizedDescription) Code: \(err.code)</pre>")
      } else {
          response.status(.OK).send("<pre>OK</pre>")
      }
    }
    response.send("<h3>DB \(dbName) deleted</h3>")
    next()
}

// Populate DB with 10k rows
router.get("/populate") {
request, response, next in
    response.status(.OK).send("<h3>Populating database</h3><pre>")
    var keepGoing = true
    populate: for i in 1...dbRows {
#if os(Linux)
        let rnd = Int(random() % maxValue)
#else
        let rnd = Int(arc4random_uniform(UInt32(maxValue)))
#endif
      var document:JSON = JSON(["_id": "\(i)"])
      document["randomNumber"].int = rnd
      world.create(document, callback: {
        (id: String?, rev: String?, document: JSON?, error: NSError?) in
        if let error = error {
          response.status(.badRequest).send("Error: \(error.localizedDescription) Code: \(error.code)")
          keepGoing = false
          return
        }
        guard let myid = id else {
          response.status(.badRequest).send("Error: no id was returned (row \(i) of \(dbRows))")
          keepGoing = false
          return
        }
        response.send("id:\(myid)\n")
      })
      if (!keepGoing) { break populate }
    }
    response.send((keepGoing ? "</pre><p>Done.</p>" : "</pre><p>Failed.</p>"))
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
