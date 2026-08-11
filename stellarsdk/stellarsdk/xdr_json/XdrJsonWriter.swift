//
//  XdrJsonWriter.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Renders an ``XdrJsonValue`` as canonical XDR-JSON text.
///
/// Canonical here means: no insignificant whitespace, object keys in the order the tree
/// holds them, `/` left unescaped, and control bytes written as `\u00xx`. Values reach the
/// tree already carrying the SEP-0051 string escapes, so this type applies only the JSON
/// layer of escaping on top.
///
/// The buffer is a `String` mutated in place inside a value type, so no shared state and no
/// concurrency annotation is involved.
internal struct XdrJsonWriter {
    private var buffer: String = ""

    /// Renders `value` as a single line of canonical XDR-JSON.
    ///
    /// - Throws: ``XdrJsonError/recursionLimitExceeded(limit:)`` when the tree nests more
    ///   than ``XdrJson/maxDepth`` containers, and ``XdrJsonError/invalidValue(type:key:message:)``
    ///   when a number member does not hold a JSON number literal.
    static func canonicalString(from value: XdrJsonValue) throws -> String {
        var writer = XdrJsonWriter()
        try writer.write(value, depth: 0)
        return writer.buffer
    }

    private mutating func write(_ value: XdrJsonValue, depth: Int) throws {
        switch value {
        case .null:
            buffer += "null"
        case .bool(let flag):
            buffer += flag ? "true" : "false"
        case .number(let literal):
            guard Self.isJsonNumber(literal) else {
                throw XdrJsonError.invalidValue(
                    type: "XdrJsonValue", key: nil,
                    message: "number member does not hold a JSON number literal: \(XdrJson.preview(literal))")
            }
            buffer += literal
        case .string(let text):
            writeString(text)
        case .array(let elements):
            let inner = try Self.descend(to: depth)
            buffer += "["
            for (index, element) in elements.enumerated() {
                if index > 0 { buffer += "," }
                try write(element, depth: inner)
            }
            buffer += "]"
        case .object(let members):
            let inner = try Self.descend(to: depth)
            buffer += "{"
            for (index, member) in members.enumerated() {
                if index > 0 { buffer += "," }
                writeString(member.key)
                buffer += ":"
                try write(member.value, depth: inner)
            }
            buffer += "}"
        }
    }

    /// Only containers count towards the limit, matching the parser and `XDRDecoder`.
    private static func descend(to depth: Int) throws -> Int {
        let inner = depth + 1
        guard inner <= XdrJson.maxDepth else {
            throw XdrJsonError.recursionLimitExceeded(limit: XdrJson.maxDepth)
        }
        return inner
    }

    private mutating func writeString(_ text: String) {
        buffer += "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"":
                buffer += "\\\""
            case "\\":
                buffer += "\\\\"
            default:
                if scalar.value < 0x20 {
                    buffer += String(format: "\\u%04x", scalar.value)
                } else {
                    buffer.unicodeScalars.append(scalar)
                }
            }
        }
        buffer += "\""
    }

    /// The JSON number grammar: an optional minus, an integer part with no redundant
    /// leading zero, an optional fraction, and an optional exponent.
    static func isJsonNumber(_ literal: String) -> Bool {
        var bytes = Array(literal.utf8)[...]

        func take(_ byte: UInt8) -> Bool {
            guard bytes.first == byte else { return false }
            bytes = bytes.dropFirst()
            return true
        }

        func takeDigits() -> Int {
            var count = 0
            while let byte = bytes.first, byte >= UInt8(ascii: "0"), byte <= UInt8(ascii: "9") {
                bytes = bytes.dropFirst()
                count += 1
            }
            return count
        }

        _ = take(UInt8(ascii: "-"))

        if take(UInt8(ascii: "0")) {
            // A leading zero admits no further integer digits.
            if let byte = bytes.first, byte >= UInt8(ascii: "0"), byte <= UInt8(ascii: "9") {
                return false
            }
        } else if takeDigits() == 0 {
            return false
        }

        if take(UInt8(ascii: ".")), takeDigits() == 0 {
            return false
        }

        if take(UInt8(ascii: "e")) || take(UInt8(ascii: "E")) {
            _ = take(UInt8(ascii: "+")) || take(UInt8(ascii: "-"))
            if takeDigits() == 0 { return false }
        }

        return bytes.isEmpty
    }
}
