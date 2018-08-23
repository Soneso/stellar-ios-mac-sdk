/*
 * Copyright 2016-2018 JD Fergason
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/**
    Class to evaluate input text with a regular expression and return tokens
*/
class Evaluator {
    let regex: String
    let generator: TokenGenerator
    let push: [String]?
    let pop: Bool
    let multiline: Bool

    init (regex: String, generator: @escaping TokenGenerator,
          push: [String]? = nil, pop: Bool = false, multiline: Bool = false) {
        self.regex = regex
        self.generator = generator
        self.push = push
        self.pop = pop
        self.multiline = multiline
    }

    func evaluate (_ content: String) throws ->
        (token: Token?, index: String.Index)? {
        var token: Token?
        var index: String.Index

        var options: NSRegularExpression.Options = []

        if multiline {
            options = [.dotMatchesLineSeparators]
        }

        if let m = content.match(self.regex, options: options) {
            token = try self.generator(m)
            index = content.index(content.startIndex, offsetBy: m.count)
            return (token, index)
        }

        return nil
    }
}
