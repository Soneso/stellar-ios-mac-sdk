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
    Convert an input string of TOML to a stream of tokens
*/
class Lexer {
    let input: String
    var grammar: [String: [Evaluator]]

    init(input: String, grammar: [String: [Evaluator]]) {
        self.input = input
        self.grammar = grammar
    }

    func tokenize() throws -> [Token] {
        var tokens = [Token]()
        var content = input
        var stack = [String]()

        stack.append("root")

        while content.count > 0 {
            var matched = false

            // check content against evaluators to produce tokens
            for evaluator in grammar[stack.last!]! {
                if let e = try evaluator.evaluate(content) {
                    if let t = e.token {
                        tokens.append(t)
                    }

                    // should we pop the stack?
                    if evaluator.pop {
                        stack.removeLast()
                    }

                    // should we push onto the stack?
                    if let pushItmes = evaluator.push {
                        stack = stack + pushItmes
                    }
                    
                    content = String(content[e.index...])
                    matched = true
                    break
                }
            }

            if !matched {
                throw TomlError.SyntaxError(content)
            }
        }
        return tokens
    }
    
}
