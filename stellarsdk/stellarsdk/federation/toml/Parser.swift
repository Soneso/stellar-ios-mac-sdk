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

// MARK: Parse

class Parser {
    var keyPath: [String] = []
    var currentKey = "."
    var declaredTables = Set<String>()
    var toml: Toml = Toml()

    // MARK: Initializers

    convenience init(toml: Toml) {
        self.init()
        self.toml = toml
    }

    // MARK: Parsing

    public func parse(string: String) throws {
        // Convert input into tokens
        let lexer = Lexer(input: string, grammar: Grammar().grammar)
        let tokens = try lexer.tokenize()
        try parse(tokens: tokens)
    }

    /**
        Parse a TOML token stream construct a dictionary.

        - Parameter tokens: Token stream describing a TOML data structure
    */
    private func parse(tokens: [Token]) throws {
        // A dispatch table for parsing TOML tables
        let TokenMap: [Token: (Token, inout [Token]) throws -> ()] = [
            .Identifier("1"): setValue,
            .IntegerNumber(1): setValue,
            .DoubleNumber(1.0): setValue,
            .Boolean(true): setValue,
            .DateTime(Date()): setValue,
            .TableBegin: setTable,
            .ArrayBegin: setArray,
            .TableArrayBegin: setTableArray,
            .InlineTableBegin: setInlineTable
        ]

        // Convert tokens to values in the Toml
        var myTokens = tokens

        while !myTokens.isEmpty {
            let token = myTokens.remove(at: 0)
            if case .Key(let val) = token {
                currentKey = val
            } else {
                try TokenMap[token]!(token, &myTokens)
            }
        }
    }

    /**
        Given a TOML token stream construct an array.

        - Parameter tokens: Token stream describing array

        - Returns: Array populated with values from token stream
    */
    private func parse(tokens: inout [Token]) throws -> [Any] {
        var array: [Any] = [Any]()

        while !tokens.isEmpty {
            let token = tokens.remove(at: 0)
            switch token {
                case .Identifier(let val):
                    array.append(val)
                case .IntegerNumber(let val):
                    array.append(val)
                case .DoubleNumber(let val):
                    array.append(val)
                case .Boolean(let val):
                    array.append(val)
                case .DateTime(let val):
                    array.append(val)
                case .InlineTableBegin:
                    array.append(try processInlineTable(tokens: &tokens))
                case .ArrayBegin:
                    var wrap = ArrayWrapper(array: array)
                    try checkAndSetArray(check: parse(tokens: &tokens), key: [""], out: &wrap)
                    array = wrap.array
                default:
                    return array
            }
        }

        return array
    }

    private func processInlineTable(tokens: inout [Token]) throws -> Toml {
        let tableTokens = extractTableTokens(tokens: &tokens, inline: true)
        let tableParser = Parser()
        try tableParser.parse(tokens: tableTokens)
        return tableParser.toml
    }

    /**
        Given a value token set its value in the `table`

        - Parameter currToken: A value token that is currently being parsed
        - Parameter tokens: Array of remaining tokens in the stream
    */
    private func setValue(currToken: Token, tokens: inout [Token]) throws {
        var key = keyPath
        key.append(currentKey)

        if toml.hasKey(key: key) {
            throw TomlError.DuplicateKey(String(describing: key))
        }

        toml.set(value: currToken.value as Any, for: key)
    }

    /**
        Given a table extract all associated tokens from the stream and create
        a new dictionary.

        - Parameter currToken: A `Token.TableBegin` token
        - Parameter table: Parent table to save resulting table to
    */
    private func setTable(currToken: Token, tokens: inout [Token]) throws {
        var tableExists = false
        var emptyTableSep = false
        // clear out the keyPath
        keyPath.removeAll()

        while !tokens.isEmpty {
            let subToken = tokens.remove(at: 0)
            if case .TableEnd = subToken {
                if keyPath.count < 1 {
                    throw TomlError.SyntaxError("Table name must not be blank")
                }

                let keyPathStr = String(describing: keyPath)
                if toml.hasKey(key: keyPath, includeTables: false) || declaredTables.contains(keyPathStr) {
                    throw TomlError.DuplicateKey(String(describing: keyPath))
                }

                declaredTables.insert(keyPathStr)
                let tableTokens = extractTableTokens(tokens: &tokens)
                try parse(tokens: tableTokens)
                tableExists = true
                break
            } else if case .TableSep = subToken {
                if emptyTableSep {
                    throw TomlError.SyntaxError("Must not have un-named implicit tables")
                }
                emptyTableSep = true
            } else if case .Identifier(let val) = subToken {
                emptyTableSep = false
                keyPath.append(val)
                toml.setTable(key: keyPath)
            }
        }

        if !tableExists {
            throw TomlError.SyntaxError("Table must contain at least a closing bracket")
        }
    }

    private func setTableArray(currToken: Token, tokens: inout [Token]) throws {
        // clear out the keyPath
        keyPath.removeAll()

        tableLoop: while !tokens.isEmpty {
            let subToken = tokens.remove(at: 0)
            if case .TableArrayEnd = subToken {
                if keyPath.count < 1 {
                    throw TomlError.SyntaxError("Table array name must not be blank")
                }

                let tableTokens = getTableTokens(keyPath: keyPath, tokens: &tokens)

                if toml.hasKey(key: keyPath) {
                    var arr: [Toml] = toml.array(keyPath)!
                    let tableParser = Parser()
                    try tableParser.parse(tokens: tableTokens)
                    arr.append(tableParser.toml)
                    toml.set(value: arr, for: keyPath)
                } else {
                    let tableParser = Parser()
                    try tableParser.parse(tokens: tableTokens)
                    toml.set(value: [tableParser.toml], for: keyPath)
                }
                break tableLoop
            } else if case .Identifier(let val) = subToken {
                keyPath.append(val)
            }
        }
    }

    /**
        Given an inline table extract all associated tokens from the stream
        and create a new dictionary.

        - Parameter currToken: A `Token.InlineTableBegin` token
        - Parameter table: Parent table to save resulting inline table to
    */
    private func setInlineTable(currToken: Token, tokens: inout [Token]) throws {
        keyPath.append(currentKey)

        let tableTokens = extractTableTokens(tokens: &tokens, inline: true)
        try parse(tokens: tableTokens)

        toml.setTable(key: keyPath)

        // This was an inline table so remove from keyPath
        keyPath.removeLast()
    }

    /**
        Given an array save it to the parent table

        - Parameter currToken: A `Token.ArrayBegin` token
        - Parameter table: Parent table to save resulting inline table to
    */
    private func setArray(currToken: Token, tokens: inout [Token]) throws {
        let arr: [Any] = try parse(tokens: &tokens)

        var myKeyPath = keyPath
        myKeyPath.append(currentKey)

        // allow empty arrays
        if arr.isEmpty {
            toml.set(value: arr, for: myKeyPath)
            return
        }

        try checkAndSetArray(check: arr, key: myKeyPath, out: &toml)
    }
}
