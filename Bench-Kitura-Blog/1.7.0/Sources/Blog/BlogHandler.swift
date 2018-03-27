/*
 * Copyright (C) 2016 Ryan M. Collins.
 * 
 * Missing copyright header added by David Jones on 2016/12/20.
 *
 * This source file is part of the KituraPress project:
 * https://github.com/rymcol/Linux-Server-Side-Swift-Benchmarking
 *
 * Additional changes Copyright IBM Corporation 2016
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

#if os(Linux)
import Glibc
#else
import Darwin
#endif

struct BlogHandler {

    func loadPageContent() -> String {

        var finalContent = "<section id=\"content\"><div class=\"container\">"

        let randomContent = ContentGenerator().generate()

        for _ in 1...5 {

            let index: Int = Int(arc4random_uniform(UInt32(randomContent.count)))
            let value = Array(randomContent.values)[index]
            let imageNumber = Int(arc4random_uniform(25) + 1)

            finalContent += "<div class=\"row blog-post\"><div class=\"col-xs-12\"><h1>"
            finalContent += "Test Post \(index)"
            finalContent += "</h1><img src=\""
            finalContent += "/img/random/random-\(imageNumber).jpg\" alt=\"Random Image \(imageNumber)\" class=\"alignleft feature-image img-responsive\" />"
            finalContent += "<div class=\"content\">\(value)</div>"
        }

        finalContent += "</div></div</div></section>"

        return finalContent
    }

}
