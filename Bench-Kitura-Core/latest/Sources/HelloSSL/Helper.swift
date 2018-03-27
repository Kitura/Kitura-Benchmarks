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
import Foundation

//
// Returns an SSLConfig appropriate for either Linux or Mac.
//
func getSSLConfig() -> SSLConfig {
#if os(Linux)
    guard let myCertPath = getAbsolutePath(relativePath: "ssl/certificate.pem") else {
        print("Error: could not find ssl/certificate.pem")
        exit(1)
    }
    guard let myKeyPath = getAbsolutePath(relativePath: "ssl/key.pem") else {
        print("Error: could not find ssl/key.pem")
        exit(1)
    }
    return SSLConfig(withCACertificateDirectory: nil, usingCertificateFile: myCertPath, withKeyFile: myKeyPath, usingSelfSignedCerts: true)
#else
    guard let myCertPath = getAbsolutePath(relativePath: "ssl/certificate.pfx") else {
        print("Error: could not find ssl/certificate.pfx")
        exit(1)
    }
    return SSLConfig(withChainFilePath: myCertPath, withPassword:"password", usingSelfSignedCerts:true)
#endif
}

//
// Get the absolute path of a file by searching for it in:
// - the current directory first
// - the directory containing this source file
// - each parent directory of this source file, iteratively
// Returns the first matching absolute path, or nil if not found
//
func getAbsolutePath(relativePath: String) -> String? {
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    var filePath = currentPath + "/" + relativePath
    if fileManager.fileExists(atPath: filePath) {
        return filePath
    } else {
        let initialPath = #file
        let components = initialPath.characters.split(separator: "/").map(String.init)
        var searchDepth = 1
        while components.count >= searchDepth {
            let currentDir = components[0..<components.count - searchDepth]
            filePath = "/" + currentDir.joined(separator: "/") + "/" + relativePath
            if fileManager.fileExists(atPath: filePath) {
                return filePath
            }
            searchDepth += 1
        }
        return nil
    }
}
