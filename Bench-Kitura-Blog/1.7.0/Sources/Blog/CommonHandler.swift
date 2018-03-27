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

struct CommonHandler {

    func getHeader() -> String {
        return "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>KituraPress</title><link rel=\"stylesheet\" href=\"/inc/bootstrap.min.css\"><link rel=\"stylesheet\" type=\"text/css\" href=\"/inc/slick.css\"/><link rel=\"stylesheet\" type=\"text/css\" href=\"/inc/slick-theme.css\"/><link rel=\"stylesheet\" href=\"/style.css\"></head><body><header><div class=\"container\"><div class=\"row\"><div class=\"col-sm-6\"><a href=\"/\"><img src=\"/img/logo@2x.png\" class=\"logo img-responsive\" id=\"header-logo\" /></a></div><div class=\"col-sm-6 text-right\"><nav><ul><li><a href=\"/\">Home</a></li><li><a href=\"/blog\">Blog</a></li></ul></nav></div></div></div></header>"
    }

    func getFooter() -> String {
        return "<footer><script src=\"/inc/bootstrap.min.js\"></script><script type=\"text/javascript\" src=\"/inc/jquery-1.11.0.min.js\"></script><script type=\"text/javascript\" src=\"/inc/jquery-migrate-1.2.1.min.js\"></script><script type=\"text/javascript\" src=\"/inc/slick.min.js\"></script><script src=\"/inc/dynamics.min.js\"></script><script src=\"/inc/animations.js\"></script></footer></body></html>"
    }

}
