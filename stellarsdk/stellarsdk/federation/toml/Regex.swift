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

var expressions = [String: NSRegularExpression]()

extension String {
    func match(_ regex: String, options: NSRegularExpression.Options = []) -> String? {
        let expression: NSRegularExpression
        
        if let cachedRegexp = expressions[regex] {
            expression = cachedRegexp
        } else {
            expression = try! NSRegularExpression(pattern: "^\(regex)", options: options)
            expressions[regex] = expression
        }
        
        let range = expression.rangeOfFirstMatch(in: self, options: [],
            range: NSMakeRange(0, self.count))
        if range.location != NSNotFound {
            return NSString(string: self).substring(with: range)
        }
        return nil
    }
}
