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

enum Token: Hashable {
    case Identifier(String)
    case Key(String)
    case IntegerNumber(Int)
    case DoubleNumber(Double)
    case Boolean(Bool)
    case DateTime(Date)
    case ArrayBegin
    case ArrayEnd
    case TableArrayBegin
    case TableArrayEnd
    case InlineTableBegin
    case InlineTableEnd
    case TableBegin
    case TableSep
    case TableEnd
    case Comment(String)

    var hashValue: Int {
        switch self {
        case .Identifier:
            return 0
        case .Key:
            return 1
        case .IntegerNumber:
            return 2
        case .DoubleNumber:
            return 3
        case .Boolean:
            return 4
        case .DateTime:
            return 5
        case .ArrayBegin:
            return 6
        case .ArrayEnd:
            return 7
        case .TableArrayBegin:
            return 8
        case .TableArrayEnd:
            return 9
        case .InlineTableBegin:
            return 10
        case .InlineTableEnd:
            return 11
        case .TableBegin:
            return 12
        case .TableSep:
            return 13
        case .TableEnd:
            return 14
        case .Comment:
            return 15
        }
    }

    var value : Any? {
        switch self {
        case .Identifier(let val):
            return val
        case .Key(let val):
            return val
        case .IntegerNumber(let val):
            return val
        case .DoubleNumber(let val):
            return val
        case .Boolean(let val):
            return val
        case .DateTime(let val):
            return val
        case .Comment(let val):
            return val
        default:
            return nil
        }
    }
    
    static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
}

typealias TokenGenerator = (String) throws -> Token?
