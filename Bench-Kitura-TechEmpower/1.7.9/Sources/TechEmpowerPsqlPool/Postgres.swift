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

import Foundation
import PostgreSQL
import LoggerAPI

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

let dbHost = ProcessInfo.processInfo.environment["DB_HOST"] ?? "localhost"
let dbPort = Int(ProcessInfo.processInfo.environment["DB_PORT"] ?? "5432") ?? 5432
let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"
let connectionString = "host=\(dbHost) port=\(dbPort) dbname=\(dbName) user=\(dbUser) password=\(dbPass)"

let dbRows = 10000
let maxValue = 10000

// Prepare SQL statements
var queryPrep = "PREPARE tfbquery (int) AS SELECT randomNumber FROM World WHERE id=$1"
var updatePrep = "PREPARE tfbupdate (int, int) AS UPDATE World SET randomNumber=$2 WHERE id=$1"

// Create a connection pool suitable for driving high load
let dbConnPool = Pool<PGConnection>(capacity: 20, limit: 50, timeout: 10000) {
  let dbConn = PGConnection()
  let status = dbConn.connectdb(connectionString)
  guard status == .ok else {
    print("DB refused connection, status \(status)")
    exit(1)
  }
  var result = dbConn.exec(statement: queryPrep)
  if result.status() != PGResult.StatusType.commandOK {
    Log.error("Unable to prepare tfbquery - status \(result.status())")
  }
  result = dbConn.exec(statement: updatePrep)
  if result.status() != PGResult.StatusType.commandOK {
    Log.error("Unable to prepare tfbupdate - status \(result.status())")
  }
  return dbConn
}

// Return a random number within the range of rows in the database
func randomNumber(_ maxVal: Int) -> Int {
#if os(Linux)
    return Int(random() % maxVal) + 1
#else
    return Int(arc4random_uniform(UInt32(maxVal))) + 1
#endif
}

// Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
// Convert to object using object-relational mapping (ORM) tool
// Serialize object to JSON - example: {"id":3217,"randomNumber":2149}
func getRandomRow() -> ([String:Int]?, AppError?) {
    var resultDict: [String:Int]? = nil
    var errRes: AppError? = nil
    let rnd = randomNumber(dbRows)
    // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.take() else {
      errRes = AppError.OtherError("Timed out waiting for a DB connection from the pool")
      return (resultDict, errRes)
    }
    // Ensure that when we complete, the connection is returned to the pool
    defer {
      dbConnPool.give(dbConn)
    }
    
    let query = "EXECUTE tfbquery(\(rnd))"
    let result = dbConn.exec(statement: query)

    guard result.status() == PGResult.StatusType.tuplesOK else {
      errRes = AppError.DBError("Query failed - status \(result.status())", query: query)
      return (resultDict, errRes)
    }
    guard result.numTuples() == 1 else {
      errRes = AppError.DBError("Query returned \(result.numTuples()) rows, expected 1", query: query)
      return (resultDict, errRes)
    }
    guard result.numFields() == 1 else {
      errRes = AppError.DBError("Expected single randomNumber field but query returned: \(result.numFields()) fields", query: query)
      return (resultDict, errRes)
    }
    guard let randomStr = result.getFieldString(tupleIndex: 0, fieldIndex: 0) else {
      errRes = AppError.DBError("Error: could not get field as a String", query: query)
      return (resultDict, errRes)
    }
    if let randomNumber = Int(randomStr) {
      resultDict = ["id":rnd, "randomNumber":randomNumber]
    } else {
      errRes = AppError.DataFormatError("Error: could not parse result as a number: \(randomStr)")
    }
    return (resultDict, errRes)
}

// Updates a row of World to a new value.
func updateRow(id: Int) throws {
    // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.take() else {
      throw AppError.OtherError("Timed out waiting for a DB connection from the pool")
    }
    // Ensure that when we complete, the connection is returned to the pool
    defer {
      dbConnPool.give(dbConn)
    }
    let rndValue = randomNumber(maxValue)
    let query = "EXECUTE tfbupdate(\(id), \(rndValue))"
    let result = dbConn.exec(statement: query)
    //Log.info("\(query) => \(result.status())")
    guard result.status() == PGResult.StatusType.commandOK else {
      throw AppError.DBError("Query failed - status \(result.status())", query: query)
    }
}

