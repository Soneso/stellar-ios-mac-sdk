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
    Get list of top level keys and optionally sort
*/
private func filterKeys(keys: Set<Path>) -> [String] {
    var myKeys = keys.filter({ $0.components.count == 1}).map({ $0.components.first! })
    myKeys.sort()
    return myKeys
}

/**
    Serialize all keys
*/
private func serializeKeys(toml: Toml) -> [String] {
    var result: [String] = []

    // serialize all key/value pairs at the base level
    // only top level keys should be serialized at this time
    // lower levels will be serialized by subsequent calls to this
    // function
    let myKeys = filterKeys(keys: toml.keyNames)

    for key in myKeys {
        result.append("\(quoted(key)) = \(toml.valueDescription([key])!)")
    }

    return result
}

/**
    Serialize all tables
*/
private func serializeTable(toml: Toml) -> [String] {
    var result: [String] = []

    // serialize each table
    let tableNames = filterKeys(keys: toml.tableNames)

    for tableName in tableNames {
        let table = toml.table(tableName)!

        // get table title
        var titleParts = [tableName]
        if let prefixPath = toml.prefixPath {
            titleParts = prefixPath.components + [tableName]
        }
        let title = titleParts.map(quoted).joined(separator: ".")

        // get key value pairs for table
        let tableString = serializeKeys(toml: table).joined(separator: "\n")

        // if it's not an an empty table, add it
        if !tableString.isEmpty {
            result.append("[\(title)]\n" + tableString)
        }

        result += serializeTable(toml: table)
    }

    return result
}

/**
    Serialize inline table
 */
func serializeInlineTable(toml: Toml) -> String {
    let keys = serializeKeys(toml: toml)
    var tables: [String] = []
    for (_, table) in toml.tables() {
        tables.append(serializeInlineTable(toml: table))
    }
    let result = (keys + tables).joined(separator: ", ")
    return "{\(result)}"
}

/**
    Serialize array of tables
*/
func serializeArrayOfTables(tables: [Toml]) -> String {
    var result: [String] = []
    for table in tables {
        result.append(serializeInlineTable(toml: table))
    }
    return "[\(result.joined(separator: ",\n  "))]"
}

/**
    Serialize a toml object to a string.

    Note: If the toml object was constructed from an existing TOML string
    then the string returned by this function will parse to an identical
    hashmap; however, it may not be an identical string.

    In particular, the resulting string will have the following properties:

        * inline tables will no longer be inline
        * arrays of tables will be inline
        * strings will always be single line unicode strings with the minimal
          number of characters escaped
        * no comments will appear in the document
        * whitespace will be standardized to a single space before and after the
          '=' symbol in key/value pairs and each new table will have a preceding
          blank line
        * key pairs and tables will be output in alpha-numeric order

    - Parameter toml: Toml object to serialize

    - Returns: The Toml object serialized to Toml
*/
func serialize(toml: Toml) -> String {
    var result = ""

    result += serializeKeys(toml: toml).joined(separator: "\n")
    result += "\n\n" + serializeTable(toml: toml).joined(separator: "\n\n")

    return result.trim()
}
