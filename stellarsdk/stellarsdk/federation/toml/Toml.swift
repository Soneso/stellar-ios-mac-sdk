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
    Error thrown when a TOML syntax error is encountered

    - DuplicateKey: Document contains a duplicate key
    - InvalidDateFormat: Date string is not a supported format
    - InvalidEscapeSequence: Unsupported escape sequence used in string
    - InvalidUnicodeCharacter: Non-existant unicode character specified
    - MixedArrayType: Array is composed of multiple types, members must all be the same type
    - SyntaxError: Document cannot be parsed due to a syntax error
*/
public enum TomlError: Error {
    case DuplicateKey(String)
    case InvalidDateFormat(String)
    case InvalidEscapeSequence(String)
    case InvalidUnicodeCharacter(Int)
    case MixedArrayType(String)
    case SyntaxError(String)
}

protocol SetValueProtocol {
    mutating func set(value: Any, for key: [String])
}

/**
    Data parsed from a TOML document
*/
public class Toml: CustomStringConvertible, SetValueProtocol {
    private var data: [Path: Any]
    private(set) public var keyNames: Set<Path>
    private(set) public var prefixPath: Path?
    private(set) public var tableNames: Set<Path>

    public init() {
        data = [Path: Any]()
        keyNames = Set<Path>()
        tableNames = Set<Path>()
    }

    /**
        Read the specified TOML file from disk.

        - Parameter contentsOfFile: Path of file to read
        - Parameter encoding: Encoding of file

        - Throws: `TomlError.SyntaxError` if the file is invalid
        - Throws: `NSError` if the file does not exist

        - Returns: A dictionary with parsed results
    */
    public convenience init(contentsOfFile path: String,
        encoding: String.Encoding = String.Encoding.utf8) throws {
        self.init()
        let source = try String(contentsOfFile: path, encoding: encoding)
        let parser = Parser(toml: self)
        try parser.parse(string: source)
    }

    /**
        Parse the string `withString` as TOML.

        - Parameter withString: A string with TOML document

        - Throws: `TomlError.SyntaxError` if the file is invalid

        - Returns: A dictionary with parsed results
    */
    public convenience init(withString string: String) throws {
        self.init()
        let parser = Parser(toml: self)
        try parser.parse(string: string)
    }

    /**
        Create an empty Toml object with the specified prefix path

        - Parameter prefixPath: The path to prefix all tables with
    */
    private convenience init(prefixPath: Path) {
        self.init()
        self.prefixPath = prefixPath
    }

    /**
        Set the value for the the given key path

        - Parameter key: Array of strings
        - Parameter value: Value to set
    */
    public func set(value: Any, for key: [String]) {
        let path = Path(key)
        keyNames.insert(path)
        data[path] = value
    }

    /**
        Add a sub-table

        - Parameter key: Array of strings indicating table path
    */
    public func setTable(key: [String]) {
        tableNames.insert(Path(key))
    }

    /**
        Check if the TOML document contains the specified key.

        - Parameter key: Key path to check
        - Parameter includeTables: Include tables and inline tables in key path check

        - Returns: True if key exists; false otherwise
    */
    public func hasKey(key: [String], includeTables: Bool = true) -> Bool {
        var keyExists = data[Path(key)] != nil
        if includeTables {
            keyExists = keyExists || hasTable(key)
        }
        return keyExists
    }

    /**
        Check if the TOML document contains the specified key.

        - Parameter key: Key path to check

        - Returns: True if key exists; false otherwise
    */
    public func hasKey(_ key: String...) -> Bool {
        return hasKey(key: key)
    }

    /**
        Check if the TOML document contains the specified table.

        - Parameter key: Key path to check

        - Returns: True if table exists; false otherwise
    */
    public func hasTable(_ key: [String]) -> Bool {
        return tableNames.contains(Path(key))
    }

    /**
        Check if the TOML document contains the specified table.

        - Parameter key: Key path to check

        - Returns: True if key exists; false otherwise
    */
    public func hasTable(_ key: String...) -> Bool {
        return hasTable(key)
    }

    /**
        Get an array of type T from the TOML document

        - Parameter path: Key path of array

        - Returns: An array of type [T]
    */
    public func array<T>(_ path: [String]) -> [T]? {
        if let val = data[Path(path)] {
            return val as? [T]
        }

        return nil
    }

    /**
        Get an array of type T from the TOML document

        - Parameter path: Key path of array

        - Returns: An array of type [T]
    */
    public func array<T>(_ path: String...) -> [T]? {
        return array(path)
    }

    /**
        Get a boolean value from the specified key path.

        - Parameter path: Key path of value

        - Returns: boolean value of key path
    */
    public func bool(_ path: [String]) -> Bool? {
        return value(path)
    }

    /**
        Get a boolean value from the specified key path.

        - Parameter path: Key path of value

        - Returns: boolean value of key path
    */
    public func bool(_ path: String...) -> Bool? {
        return value(path)
    }

    /**
        Get a date value from the specified key path.

        - Parameter path: Key path of value

        - Returns: date value of key path
    */
    public func date(_ path: [String]) -> Date? {
        return value(path)
    }

    /**
        Get a date value from the specified key path.

        - Parameter path: Key path of value

        - Returns: date value of key path
    */
    public func date(_ path: String...) -> Date? {
        return value(path)
    }

    /**
        Get a double value from the specified key path.

        - Parameter path: Key path of value

        - Returns: double value of key path
    */
    public func double(_ path: [String]) -> Double? {
        return value(path)
    }

    /**
        Get a double value from the specified key path.

        - Parameter path: Key path of value

        - Returns: double value of key path
    */
    public func double(_ path: String...) -> Double? {
        return double(path)
    }

    /**
        Get a int value from the specified key path.

        - Parameter path: Key path of value

        - Returns: int value of key path
    */
    public func int(_ path: [String]) -> Int? {
        return value(path)
    }

    /**
        Get a int value from the specified key path.

        - Parameter path: Key path of value

        - Returns: int value of key path
    */
    public func int(_ path: String...) -> Int? {
        return value(path)
    }

    /**
        Get a string value from the specified key path.

        - Parameter path: Key path of value

        - Returns: string value of key path
    */
    public func string(_ path: [String]) -> String? {
        return value(path)
    }

    /**
        Get a string value from the specified key path.

        - Parameter path: Key path of value

        - Returns: string value of key path
    */
    public func string(_ path: String...) -> String? {
        return value(path)
    }

    /**
        Get a dictionary of all tables 1-level down from the given key
        path.  To get all tables at the root level call with no parameters.

        - Parameter parent: Root key path

        - Returns: Dictionary of key names and tables
    */
    public func tables(_ parent: [String]) -> [String: Toml] {
        var result = [String: Toml]()
        for tableName in tableNames {
            var tableParent = tableName
            var myTableName = tableName
            if let tablePrefix = prefixPath {
                myTableName = tablePrefix + tableName
            }

            tableParent.components.removeLast()
            if parent == tableParent.components {
                // this is a table to include
                result[myTableName.components.map(quoted).joined(separator: ".")] = table(from: tableName.components)
            }
        }
        return result
    }

    /**
        Get a dictionary of all tables 1-level down from the given key
        path.  To get all tables at the root level call with no parameters.

        - Parameter parent: Root key path

        - Returns: Dictionary of key names and tables
    */
    public func tables(_ parent: String...) -> [String: Toml] {
        return tables(parent)
    }

    /**
        Return a TOML table that contains everything beneath the specified
        path.

        - Parameter from: Key path to create table from

        - Returns: `Toml` table of all keys beneath the specified path
    */
    public func table(from path: [String]) -> Toml {
        var fullTablePrefix = Path(path)
        if let tablePrefix = prefixPath {
            fullTablePrefix = tablePrefix + Path(path)
        }

        let constructedTable = Toml(prefixPath: fullTablePrefix)

        // add values
        for keyName in keyNames {
            var keyArray = keyName.components
            if keyName.begins(with: path) {
                keyArray.removeSubrange(0..<path.count)
                constructedTable.set(value: self.value(keyName.components)!, for: keyArray)
            }
        }

        // add tables
        for tableName in tableNames {
            var tableArray = tableName.components
            if tableName.begins(with: path) {
                tableArray.removeSubrange(0..<path.count)
                if !tableArray.isEmpty {
                    constructedTable.setTable(key: tableArray)
                }
            }
        }

        return constructedTable
    }

    /**
        Get a TOML table from the document

        - Parameter path: Key path of value

        - Returns: Table of name `path`
    */
    public func table(_ path: String...) -> Toml? {
        return table(from: path)
    }

    /**
        Get a value of type T from the specified key path.

        - Parameter path: Key path of value

        - Returns: value of key path
    */
    public func value<T>(_ path: [String]) -> T? {
        if let val = data[Path(path)] {
            return val as? T
        }

        return nil
    }

    /**
        Get a value of type T from the specified key path.

        - Parameter path: Key path of value

        - Returns: value of key path
    */
    public func value<T>(_ path: String...) throws -> T? {
        return value(path)
    }

    /**
        Get the value specified by path as a string

        - Parameter path: Key path of value

        - Returns: value of key path as a string
    */
    public func valueDescription(_ path: [String]) -> String? {
        if let check = data[Path(path)] {
            if let intVal = check as? Int {
                return String(describing: intVal)
            } else if let doubleVal = check as? Double {
                return String(describing: doubleVal)
            } else if let stringVal = check as? String {
                return "\"\(escape(string: stringVal))\""
            } else if let boolVal = check as? Bool {
                return String(describing: boolVal)
            } else if let dateVal = check as? Date {
                return dateVal.rfc3339String()
            } else if let tableArray = check as? [Toml] {
                return serializeArrayOfTables(tables: tableArray)
            }

            return String(describing: check)
        }

        return nil
    }

    /**
        Get a string representation of the TOML document

        - Returns: String version of TOML document
    */
    public var description: String {
        return serialize(toml: self)
    }
}
