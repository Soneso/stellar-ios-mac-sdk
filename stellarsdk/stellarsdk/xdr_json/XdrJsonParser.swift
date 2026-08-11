//
//  XdrJsonParser.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Parses XDR-JSON text into an ``XdrJsonValue``.
///
/// A recursive-descent parser over the UTF-8 bytes rather than a Foundation call, because
/// four properties the conversion depends on are not otherwise available: object key order
/// has to survive into the tree, a duplicate key has to be rejected rather than resolved,
/// nesting has to be capped, and a number has to keep its source literal so a 64-bit value
/// accepted under the specification's version 1 compatibility rule cannot be rounded on its
/// way through a binary floating-point type.
///
/// The grammar accepted is RFC 8259 JSON. Narrower rules that belong to individual XDR
/// types — an integer that must not be written `1.0`, hex that must be lowercase — are
/// enforced by ``XdrJson`` when the value is read, not here.
internal struct XdrJsonParser {
    private let bytes: [UInt8]
    private var index: Int = 0

    /// Parses one complete JSON document.
    ///
    /// - Throws: ``XdrJsonError/malformedJson(message:)`` for any grammar violation, a
    ///   duplicate key or trailing content, and
    ///   ``XdrJsonError/recursionLimitExceeded(limit:)`` beyond ``XdrJson/maxDepth``.
    static func parse(_ text: String) throws -> XdrJsonValue {
        var parser = XdrJsonParser(bytes: Array(text.utf8))
        let value = try parser.parseValue(depth: 0)
        parser.skipWhitespace()
        guard parser.index == parser.bytes.count else {
            throw parser.malformed("unexpected content after the top-level value")
        }
        return value
    }

    private init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    // MARK: - Values

    private mutating func parseValue(depth: Int) throws -> XdrJsonValue {
        skipWhitespace()
        guard let byte = peek() else {
            throw malformed("unexpected end of input, expected a value")
        }

        switch byte {
        case UInt8(ascii: "{"):
            return try parseObject(depth: try descend(from: depth))
        case UInt8(ascii: "["):
            return try parseArray(depth: try descend(from: depth))
        case UInt8(ascii: "\""):
            return .string(try parseString())
        case UInt8(ascii: "t"):
            try expect(literal: "true")
            return .bool(true)
        case UInt8(ascii: "f"):
            try expect(literal: "false")
            return .bool(false)
        case UInt8(ascii: "n"):
            try expect(literal: "null")
            return .null
        default:
            return .number(try parseNumber())
        }
    }

    private mutating func parseObject(depth: Int) throws -> XdrJsonValue {
        index += 1
        var members: [XdrJsonMember] = []
        var seen: Set<String> = []

        skipWhitespace()
        if peek() == UInt8(ascii: "}") {
            index += 1
            return .object(members)
        }

        while true {
            skipWhitespace()
            guard peek() == UInt8(ascii: "\"") else {
                throw malformed("expected a quoted object key")
            }
            let key = try parseString()
            guard seen.insert(key).inserted else {
                throw XdrJsonError.malformedJson(
                    message: "duplicate object key \"\(XdrJson.preview(key))\"")
            }

            skipWhitespace()
            guard peek() == UInt8(ascii: ":") else {
                throw malformed("expected ':' after an object key")
            }
            index += 1

            members.append(XdrJsonMember(key: key, value: try parseValue(depth: depth)))

            skipWhitespace()
            switch peek() {
            case UInt8(ascii: ","):
                index += 1
            case UInt8(ascii: "}"):
                index += 1
                return .object(members)
            default:
                throw malformed("expected ',' or '}' in an object")
            }
        }
    }

    private mutating func parseArray(depth: Int) throws -> XdrJsonValue {
        index += 1
        var elements: [XdrJsonValue] = []

        skipWhitespace()
        if peek() == UInt8(ascii: "]") {
            index += 1
            return .array(elements)
        }

        while true {
            elements.append(try parseValue(depth: depth))

            skipWhitespace()
            switch peek() {
            case UInt8(ascii: ","):
                index += 1
            case UInt8(ascii: "]"):
                index += 1
                return .array(elements)
            default:
                throw malformed("expected ',' or ']' in an array")
            }
        }
    }

    private mutating func parseNumber() throws -> String {
        let start = index
        if peek() == UInt8(ascii: "-") { index += 1 }
        while let byte = peek(), Self.isNumberBody(byte) { index += 1 }

        guard start < index, let literal = String(bytes: bytes[start..<index], encoding: .utf8),
              XdrJsonWriter.isJsonNumber(literal) else {
            throw malformed("expected a JSON number")
        }
        return literal
    }

    private static func isNumberBody(_ byte: UInt8) -> Bool {
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"),
             UInt8(ascii: "."), UInt8(ascii: "e"), UInt8(ascii: "E"),
             UInt8(ascii: "+"), UInt8(ascii: "-"):
            return true
        default:
            return false
        }
    }

    // MARK: - Strings

    private mutating func parseString() throws -> String {
        index += 1
        var scalars = String.UnicodeScalarView()

        while true {
            guard let byte = peek() else {
                throw malformed("unterminated string")
            }

            if byte == UInt8(ascii: "\"") {
                index += 1
                return String(scalars)
            }

            if byte == UInt8(ascii: "\\") {
                index += 1
                try appendEscape(to: &scalars)
                continue
            }

            guard byte >= 0x20 else {
                throw malformed(String(format: "unescaped control byte 0x%02x in a string", Int(byte)))
            }

            // Multi-byte UTF-8 sequences pass through untouched; the input came from a
            // Swift String and is therefore already well-formed.
            let start = index
            index += 1
            while let continuation = peek(), continuation & 0xC0 == 0x80 { index += 1 }
            guard let text = String(bytes: bytes[start..<index], encoding: .utf8) else {
                throw malformed("invalid UTF-8 in a string")
            }
            scalars.append(contentsOf: text.unicodeScalars)
        }
    }

    private mutating func appendEscape(to scalars: inout String.UnicodeScalarView) throws {
        guard let byte = peek() else {
            throw malformed("unterminated escape sequence")
        }
        index += 1

        switch byte {
        case UInt8(ascii: "\""): scalars.append("\"")
        case UInt8(ascii: "\\"): scalars.append("\\")
        case UInt8(ascii: "/"): scalars.append("/")
        case UInt8(ascii: "b"): scalars.append(UnicodeScalar(0x08))
        case UInt8(ascii: "f"): scalars.append(UnicodeScalar(0x0C))
        case UInt8(ascii: "n"): scalars.append("\n")
        case UInt8(ascii: "r"): scalars.append("\r")
        case UInt8(ascii: "t"): scalars.append("\t")
        case UInt8(ascii: "u"): scalars.append(try parseUnicodeEscape())
        default:
            throw malformed("unrecognised escape sequence \\\(Character(UnicodeScalar(byte)))")
        }
    }

    private mutating func parseUnicodeEscape() throws -> UnicodeScalar {
        let first = try parseHexQuad()

        // A code point above the basic plane is written as a surrogate pair; a surrogate
        // on its own is not a character and cannot be carried by a Swift string.
        if first >= 0xD800 && first <= 0xDBFF {
            guard peek() == UInt8(ascii: "\\"), peekAhead(1) == UInt8(ascii: "u") else {
                throw malformed("high surrogate is not followed by a low surrogate")
            }
            index += 2
            let second = try parseHexQuad()
            guard second >= 0xDC00 && second <= 0xDFFF else {
                throw malformed("high surrogate is not followed by a low surrogate")
            }
            let combined = 0x10000 + ((first - 0xD800) << 10) + (second - 0xDC00)
            guard let scalar = UnicodeScalar(combined) else {
                throw malformed("escape sequence does not name a Unicode scalar")
            }
            return scalar
        }

        guard first < 0xD800 || first > 0xDFFF, let scalar = UnicodeScalar(first) else {
            throw malformed("escape sequence names an unpaired surrogate")
        }
        return scalar
    }

    private mutating func parseHexQuad() throws -> UInt32 {
        var value: UInt32 = 0
        for _ in 0..<4 {
            guard let byte = peek(), let digit = Self.hexDigit(byte) else {
                throw malformed("expected four hexadecimal digits after \\u")
            }
            value = value << 4 | UInt32(digit)
            index += 1
        }
        return value
    }

    private static func hexDigit(_ byte: UInt8) -> UInt8? {
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): return byte - UInt8(ascii: "0")
        case UInt8(ascii: "a")...UInt8(ascii: "f"): return byte - UInt8(ascii: "a") + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"): return byte - UInt8(ascii: "A") + 10
        default: return nil
        }
    }

    // MARK: - Cursor

    private func peek() -> UInt8? {
        index < bytes.count ? bytes[index] : nil
    }

    private func peekAhead(_ offset: Int) -> UInt8? {
        let position = index + offset
        return position < bytes.count ? bytes[position] : nil
    }

    private mutating func skipWhitespace() {
        while let byte = peek() {
            switch byte {
            case 0x20, 0x09, 0x0A, 0x0D: index += 1
            default: return
            }
        }
    }

    private mutating func expect(literal: String) throws {
        let expected = Array(literal.utf8)
        guard index + expected.count <= bytes.count,
              Array(bytes[index..<(index + expected.count)]) == expected else {
            throw malformed("expected \(literal)")
        }
        index += expected.count
    }

    /// Only containers count towards the limit, matching the writer and `XDRDecoder`.
    private func descend(from depth: Int) throws -> Int {
        let inner = depth + 1
        guard inner <= XdrJson.maxDepth else {
            throw XdrJsonError.recursionLimitExceeded(limit: XdrJson.maxDepth)
        }
        return inner
    }

    private func malformed(_ reason: String) -> XdrJsonError {
        .malformedJson(message: "\(reason) at byte \(index)")
    }
}
