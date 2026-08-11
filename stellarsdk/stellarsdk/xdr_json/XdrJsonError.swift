//
//  XdrJsonError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Errors raised while converting between XDR values and XDR-JSON.
///
/// Every case names the type being converted and, where one applies, the offending key, so
/// a failure deep inside a transaction envelope can be located without re-running the
/// conversion.
///
/// Payloads carry the offending text verbatim, so a caller can act on it. ``message`` is
/// where the four cases whose payload comes from the document -- a duplicate key, an
/// unknown enumeration value, an unknown union arm and an undeclared field -- neutralise it
/// through ``XdrJson/preview(_:)``, so an error echoed into a terminal or a log cannot carry
/// escape sequences of its own.
public enum XdrJsonError: Error, Sendable {
    /// The text is not well-formed JSON.
    case malformedJson(message: String)

    /// A value has the wrong JSON type for the XDR field it maps to.
    case unexpectedType(type: String, key: String?, expected: String, got: String)

    /// A required key is absent. An optional XDR field may be `null`, but its key must
    /// still be present.
    case missingField(type: String, key: String)

    /// An object carries the same key twice, which has no canonical meaning.
    case duplicateKey(type: String, key: String)

    /// A string does not name any member of the enumeration it maps to.
    case unknownEnumValue(type: String, value: String)

    /// An object key does not name any arm of the union it maps to.
    case unknownUnionArm(type: String, key: String)

    /// An object carries keys the type does not declare.
    ///
    /// The structural dual of ``missingField(type:key:)``: one reports a declared key that
    /// is absent, this one a present key that is not declared. `keys` is a list because a
    /// single object can carry several, and both payloads are verbatim so a caller reading a
    /// document from a newer producer can act on them rather than parsing the message.
    case unknownField(type: String, keys: [String], declared: [String])

    /// A value has the right JSON type but is outside the domain the XDR type accepts.
    case invalidValue(type: String, key: String?, message: String)

    /// The document nests containers more deeply than the conversion allows.
    case recursionLimitExceeded(limit: Int)

    /// The XDR value is valid but has no XDR-JSON rendering the ecosystem accepts.
    case unrepresentable(type: String, message: String)
}

public extension XdrJsonError {
    /// A one-line description naming the type, the key and the reason.
    var message: String {
        switch self {
        case .malformedJson(let message):
            return "malformed JSON: \(message)"
        case .unexpectedType(let type, let key, let expected, let got):
            return "\(type)\(Self.at(key)): expected \(expected), got \(got)"
        case .missingField(let type, let key):
            return "\(type): missing key \"\(key)\""
        case .duplicateKey(let type, let key):
            return "\(type): duplicate key \"\(XdrJson.preview(key))\""
        case .unknownEnumValue(let type, let value):
            return "\(type): unknown value \"\(XdrJson.preview(value))\""
        case .unknownUnionArm(let type, let key):
            return "\(type): unknown union arm \"\(XdrJson.preview(key))\""
        case .unknownField(let type, let keys, let declared):
            let offending = keys.map { "\"\(XdrJson.preview($0))\"" }.joined(separator: ", ")
            return "\(type): unknown \(keys.count == 1 ? "key" : "keys") \(offending); " +
                   "declared keys are \(declared.joined(separator: ", "))"
        case .invalidValue(let type, let key, let message):
            return "\(type)\(Self.at(key)): \(message)"
        case .recursionLimitExceeded(let limit):
            return "nesting exceeds the limit of \(limit) containers"
        case .unrepresentable(let type, let message):
            return "\(type): \(message)"
        }
    }

    private static func at(_ key: String?) -> String {
        guard let key else { return "" }
        return ".\(key)"
    }
}
