//
//  KeyedCoding+Collections.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Dynamic coding key for decoding heterogeneous JSON structures.
///
/// Used internally for decoding JSON with unknown or dynamic keys.
struct JSONCodingKeys: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

/// Extension providing decoding support for heterogeneous collections.
///
/// Enables decoding JSON dictionaries and arrays with mixed value types (strings, numbers, booleans, nested structures).
/// This is useful for Horizon API responses that may contain dynamic or polymorphic data.
extension KeyedDecodingContainer {

    /// Decodes a dictionary with Any values from a keyed container.
    ///
    /// - Parameter type: Dictionary type to decode
    /// - Parameter key: Coding key for the dictionary
    /// - Returns: Decoded dictionary with string keys and Any values
    /// - Throws: DecodingError if decoding fails
    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    /// Decodes a dictionary with Any values if present.
    ///
    /// - Parameter type: Dictionary type to decode
    /// - Parameter key: Coding key for the dictionary
    /// - Returns: Decoded dictionary, or nil if not present or null
    /// - Throws: DecodingError if decoding fails
    func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any>? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    /// Decodes an array with Any values from a keyed container.
    ///
    /// - Parameter type: Array type to decode
    /// - Parameter key: Coding key for the array
    /// - Returns: Decoded array with Any values
    /// - Throws: DecodingError if decoding fails
    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    /// Decodes an array with Any values if present.
    ///
    /// - Parameter type: Array type to decode
    /// - Parameter key: Coding key for the array
    /// - Returns: Decoded array, or nil if not present or null
    /// - Throws: DecodingError if decoding fails
    func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any>? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    /// Decodes all keys in the container as a dictionary with Any values.
    ///
    /// Attempts to decode each key as Bool, String, Int, Double, nested Dictionary, or nested Array.
    ///
    /// - Parameter type: Dictionary type to decode
    /// - Returns: Decoded dictionary with all keys and values
    /// - Throws: DecodingError if decoding fails
    func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

/// Extension providing decoding support for heterogeneous arrays.
extension UnkeyedDecodingContainer {

    /// Decodes an array with heterogeneous values.
    ///
    /// Iterates through the array and decodes each element as Bool, Double, String, nested Dictionary, or nested Array.
    ///
    /// - Parameter type: Array type to decode
    /// - Returns: Decoded array with Any values
    /// - Throws: DecodingError if decoding fails
    mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decodeNestedArray() {
                array.append(nestedArray)
            }
        }
        return array
    }

    /// Decodes a nested array from an unkeyed container.
    ///
    /// This helper method creates a nested unkeyed container to properly decode
    /// nested arrays without causing infinite recursion.
    ///
    /// - Returns: Decoded array with Any values
    /// - Throws: DecodingError if decoding fails
    private mutating func decodeNestedArray() throws -> [Any] {
        var nestedContainer = try self.nestedUnkeyedContainer()
        return try nestedContainer.decode([Any].self)
    }
    
    /// Decodes a nested dictionary from an unkeyed container.
    ///
    /// - Parameter type: Dictionary type to decode
    /// - Returns: Decoded dictionary
    /// - Throws: DecodingError if decoding fails
    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {

        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
