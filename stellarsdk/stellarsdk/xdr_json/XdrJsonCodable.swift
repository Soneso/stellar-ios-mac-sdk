//
//  XdrJsonCodable.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Conversion between an XDR type and its XDR-JSON form, as defined by
/// [SEP-0051](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md).
///
/// Only the two tree operations are requirements. The two string-boundary conveniences are
/// derived from them on the extension below, the same way `xdrEncoded` is derived from
/// `xdrEncode(to:)`.
///
/// There is deliberately no default implementation of the requirements. Reflection cannot
/// recover XDR field names, cannot see a void union arm at all, and cannot tell apart types
/// that a `typealias` collapses onto one another, so a default would be wrong rather than
/// merely incomplete. Leaving it out makes a type that has not been given a conversion a
/// compile error instead of wrong output at run time.
///
/// ```swift
/// let bounds = TimeBoundsXDR(minTime: 0, maxTime: 1)
/// let json = try bounds.toXdrJson()          // {"min_time":"0","max_time":"1"}
/// let same = try TimeBoundsXDR.fromXdrJson(json)
/// ```
public protocol XdrJsonCodable {
    /// This value as an XDR-JSON tree, with object keys in XDR declaration order.
    func toXdrJsonValue() throws -> XdrJsonValue

    /// Reads a value from an XDR-JSON tree.
    ///
    /// This is the requirement generated code calls recursively, so it performs no depth
    /// validation of its own: re-walking the tree at every level would be quadratic. A
    /// caller holding a tree it built by hand rather than parsed should use
    /// ``XdrJsonCodable/fromXdrJsonTree(_:)``, which bounds the nesting once and then
    /// delegates here.
    static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> Self
}

public extension XdrJsonCodable {
    /// This value as canonical XDR-JSON text: one line, no insignificant whitespace, keys
    /// in XDR declaration order.
    ///
    /// - Throws: ``XdrJsonError`` when a value has no XDR-JSON rendering, or when the tree
    ///   nests too deeply.
    func toXdrJson() throws -> String {
        try XdrJsonWriter.canonicalString(from: try toXdrJsonValue())
    }

    /// Reads a value from XDR-JSON text.
    ///
    /// - Throws: ``XdrJsonError/malformedJson(message:)`` when the text is not well-formed
    ///   JSON, and the other ``XdrJsonError`` cases when it is well-formed but does not
    ///   describe this type.
    static func fromXdrJson(_ json: String) throws -> Self {
        try fromXdrJsonValue(try XdrJsonParser.parse(json))
    }

    /// Reads a value from an XDR-JSON tree built by hand rather than parsed.
    ///
    /// ``XdrJsonParser`` already bounds the nesting of anything it produces, so this is the
    /// entry point that needs the check; conversions below it recurse no deeper than the
    /// tree does.
    static func fromXdrJsonTree(_ value: XdrJsonValue) throws -> Self {
        try XdrJson.validateDepth(value)
        return try fromXdrJsonValue(value)
    }
}
