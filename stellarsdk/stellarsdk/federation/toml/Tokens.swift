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

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .Identifier:
            hasher.combine(0)
        case .Key:
            hasher.combine(1)
        case .IntegerNumber:
            hasher.combine(2)
        case .DoubleNumber:
            hasher.combine(3)
        case .Boolean:
            hasher.combine(4)
        case .DateTime:
            hasher.combine(5)
        case .ArrayBegin:
            hasher.combine(6)
        case .ArrayEnd:
            hasher.combine(7)
        case .TableArrayBegin:
            hasher.combine(8)
        case .TableArrayEnd:
            hasher.combine(9)
        case .InlineTableBegin:
            hasher.combine(10)
        case .InlineTableEnd:
            hasher.combine(11)
        case .TableBegin:
            hasher.combine(12)
        case .TableSep:
            hasher.combine(13)
        case .TableEnd:
            hasher.combine(14)
        case .Comment:
            hasher.combine(15)
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
