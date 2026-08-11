//
//  XdrJsonValue.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// An XDR-JSON document, as defined by
/// [SEP-0051](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md).
///
/// This is the tree form every XDR type converts to and from. It is deliberately not a
/// Foundation type: SEP-0051 output places object keys in XDR declaration order, and no
/// Foundation container preserves that. `Dictionary` is unordered, and sorting keys
/// alphabetically is a different order. Making the order a property of the data rather
/// than of a serializer setting removes the possibility of a non-canonical rendering.
///
/// A number is carried as its literal decimal text rather than as a numeric type. XDR-JSON
/// renders 64-bit integers as strings, and the specification's version 1 compatibility rule
/// allows a JSON number on input; keeping the literal means such a value cannot lose
/// precision by passing through a binary floating-point type.
///
/// ```swift
/// let tree = XdrJsonValue.object([
///     XdrJsonMember(key: "min_time", value: .string("0")),
///     XdrJsonMember(key: "max_time", value: .string("1"))
/// ])
/// ```
public enum XdrJsonValue: Sendable, Equatable {
    /// A JSON `null`. In XDR-JSON this is an absent optional; the key stays present.
    case null

    /// A JSON boolean.
    case bool(Bool)

    /// A JSON number, held as the literal decimal text that appears in the document.
    case number(String)

    /// A JSON string.
    case string(String)

    /// A JSON array.
    case array([XdrJsonValue])

    /// A JSON object, whose members stay in the order they were added.
    case object([XdrJsonMember])
}

/// One key and value of an ``XdrJsonValue/object(_:)``.
public struct XdrJsonMember: Sendable, Equatable {
    /// The member's key.
    public let key: String

    /// The member's value.
    public let value: XdrJsonValue

    /// Creates a member.
    ///
    /// - Parameters:
    ///   - key: The member's key.
    ///   - value: The member's value.
    public init(key: String, value: XdrJsonValue) {
        self.key = key
        self.value = value
    }
}

public extension XdrJsonValue {
    /// Whether this value is JSON `null`.
    var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    /// The value stored under `key`, or `nil` when this is not an object or has no such
    /// member. The first member with that key wins; a document parsed by
    /// ``XdrJsonParser`` can never contain a duplicate.
    func member(_ key: String) -> XdrJsonValue? {
        guard case .object(let members) = self else { return nil }
        return members.first { $0.key == key }?.value
    }

    /// The name of this value's JSON type, as it appears in error messages.
    var typeName: String {
        switch self {
        case .null: return "null"
        case .bool: return "boolean"
        case .number: return "number"
        case .string: return "string"
        case .array: return "array"
        case .object: return "object"
        }
    }
}
