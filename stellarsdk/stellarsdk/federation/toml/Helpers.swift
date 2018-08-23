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

class ArrayWrapper: SetValueProtocol {
    var array: [Any]

    init(array: [Any]) {
        self.array = array
    }

    public func set(value: Any, for: [String]) {
        array.append(value)
    }
}

/**
    Utility function to cast an array to a given type or throw an error

    - Parameter array: Input array to cast to type T
    - Parameter out: Array to store result in

    - Throws: `TomlError.MixedArrayType` if array cannot be cast to appropriate type
*/
func checkAndSetArray<T: SetValueProtocol>(check: [Any], key: [String], out: inout T) throws {
    // allow empty arrays
    if check.isEmpty {
        out.set(value: check, for: key)
        return
    }

    // convert array to proper type
    switch check[0] {
        case is Int:
            if let typedArray = check as? [Int] {
                out.set(value: typedArray, for: key)
            } else {
                throw TomlError.MixedArrayType("Int")
            }
        case is Double:
            if let typedArray = check as? [Double] {
                out.set(value: typedArray, for: key)
            } else {
                throw TomlError.MixedArrayType("Double")
            }
        case is String:
            if let typedArray = check as? [String] {
                out.set(value: typedArray, for: key)
            } else {
                throw TomlError.MixedArrayType("String")
            }
        case is Bool:
            if let typedArray = check as? [Bool] {
                out.set(value: typedArray, for: key)
            } else {
                throw TomlError.MixedArrayType("Bool")
            }
        case is Date:
            if let typedArray = check as? [Date] {
                out.set(value: typedArray, for: key)
            } else {
                throw TomlError.MixedArrayType("Date")
            }
        default:
            // array of arrays leave as any
            out.set(value: check, for: key)
    }
}

/**
    Utility for trimming string identifiers in key/value pairs
*/
func trimStringIdentifier(_ input: String, _ quote: String = "\"") -> String {
    let pattern = quote + "(.+)" + quote + "[ \t]*="
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: input, options: [],
        range: NSMakeRange(0, input.utf16.count))
    let nss = NSString(string: input)
    return nss.substring(with: matches[0].range(at: 1))
}

func getKeyPathFromTable(tokens: [Token]) -> [String] {
    var subKeyPath = [String]()
    subKeyPathLoop: for token in tokens {
        switch token {
            case .Identifier(let val):
                subKeyPath.append(val)
            case .TableSep, .TableArrayBegin, .TableBegin:
                continue
            default:
                break subKeyPathLoop
        }
    }

    return subKeyPath
}

func consumeTableIdentifierTokens(tableTokens: inout [Token], tokens: inout [Token]) {
    while !tokens.isEmpty {
        let nestedToken = tokens[0]
        tableTokens.append(nestedToken)
        tokens.remove(at: 0)
        if case .TableEnd = nestedToken {
            break
        } else if case .TableArrayEnd = nestedToken {
            break
        }
    }
}

func getTableTokens(keyPath: [String], tokens: inout [Token]) -> [Token] {
    var tableTokens = [Token]()
    nestedTableLoop: while tokens.count > 0 {
        let tableToken = tokens[0]

        // need to include sub tables
        switch tableToken {
            case .TableBegin, .TableArrayBegin:
                // get the key path of the new table
                let subKeyPath = getKeyPathFromTable(tokens: tokens)

                // If the new table is nested within the current one
                // include it, otherwise we are finished.
                if subKeyPath.count == 1 {
                    // top-level - break
                    break nestedTableLoop
                }

                if subKeyPath[0] != keyPath[0] {
                    // nested table but not part of this table group
                    break nestedTableLoop
                }

                // this table should be included because it's a
                // nested table

                // .TableBegin || .TableArrayBegin
                tokens.remove(at: 0)
                tableTokens.append(tableToken)

                // skip first name
                tokens.remove(at: 0) // Identifier
                tokens.remove(at: 0) // .TableSep

                consumeTableIdentifierTokens(tableTokens: &tableTokens, tokens: &tokens)
            default:
                tokens.remove(at: 0)
                tableTokens.append(tableToken)
        }
    }

    return tableTokens
}

func extractTableTokens(tokens: inout [Token], inline: Bool = false) -> [Token] {
    var tableTokens = [Token]()
    while !tokens.isEmpty {
        let tableToken = tokens[0]

        if inline {
            tokens.remove(at: 0)
        }

        if case .InlineTableEnd = tableToken {
            if inline {
                break
            }
        } else if case .TableBegin = tableToken {
            break
        } else if case .TableArrayBegin = tableToken {
            break
        }

        if !inline {
            tokens.remove(at: 0)
        }

        tableTokens.append(tableToken)
    }

    return tableTokens
}
