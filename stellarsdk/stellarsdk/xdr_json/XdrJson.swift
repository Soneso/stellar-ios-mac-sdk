//
//  XdrJson.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// The shared runtime behind every XDR type's XDR-JSON conversion.
///
/// All validation, escaping, hex, integer parsing and error construction live here, so a
/// per-type conversion is one call per field rather than an inlined rule. Every rule is
/// therefore written once and tested once, and the strictness of the whole codec can be
/// read in a single file.
///
/// The rules follow
/// [SEP-0051](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md).
/// Where this SDK is deliberately stricter than the specification requires — rejecting
/// uppercase hex, uppercase `\xNN` escapes, and integer literals written `1.0` or `1e10` —
/// the narrowing is noted on the member that applies it. Everything this SDK emits stays
/// inside what a conforming reader accepts.
internal enum XdrJson {

    /// Maximum container nesting, matching `XDRDecoder.maxDecodingDepth`. Only arrays and
    /// objects count towards it.
    static let maxDepth = 128

    /// The optional property SEP-0051 §JSON Schema allows on any object. It is accepted on
    /// input, stripped, and never emitted.
    static let schemaKey = "$schema"

    /// Longest untrusted text reproduced in an error message.
    static let previewLimit = 80

    // MARK: - Emission: numbers and booleans

    static func int32(_ value: Int32) -> XdrJsonValue { .number(String(value)) }

    static func uint32(_ value: UInt32) -> XdrJsonValue { .number(String(value)) }

    /// A 64-bit integer renders as a base-10 string, not a number: JSON numbers are not
    /// required to carry 64 bits of precision.
    static func int64(_ value: Int64) -> XdrJsonValue { .string(String(value)) }

    static func uint64(_ value: UInt64) -> XdrJsonValue { .string(String(value)) }

    static func bool(_ value: Bool) -> XdrJsonValue { .bool(value) }

    // MARK: - Emission: opaque data

    /// Variable-length opaque data as lowercase hex. Empty data renders as `""`.
    static func hex(_ data: Data) -> XdrJsonValue {
        .string(hexString(data))
    }

    /// Fixed-length opaque data as lowercase hex, checked against its declared width.
    ///
    /// The check is not redundant: `WrappedDataN.init(_:)` silently zero-pads short input
    /// and keeps over-long input verbatim, so a fixed-width wrapper can hold the wrong
    /// number of bytes.
    static func hex(_ data: Data, expectedLength: Int, type: String, key: String? = nil) throws -> XdrJsonValue {
        guard data.count == expectedLength else {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "expected \(expectedLength) bytes, got \(data.count)")
        }
        return .string(hexString(data))
    }

    /// Formats bytes as lowercase hex.
    ///
    /// `Data.base16EncodedString()` produces the same text but allocates one `String` per
    /// byte through `String(format:)`. This runs for every opaque field of every type
    /// converted, so the digits are indexed directly instead.
    static func hexString(_ data: Data) -> String {
        var text = ""
        text.reserveCapacity(data.count * 2)
        for byte in data {
            text.append(hexDigits[Int(byte >> 4)])
            text.append(hexDigits[Int(byte & 0x0F)])
        }
        return text
    }

    private static let hexDigits = Array("0123456789abcdef")

    // MARK: - Emission: strings

    /// Applies the SEP-0051 §String escape ladder to raw bytes.
    ///
    /// Byte by byte, first match wins: `0x00` becomes `\0`, `0x09` `\t`, `0x0A` `\n`,
    /// `0x0D` `\r`, `0x5C` `\\`, printable `0x20` to `0x7E` stay verbatim, and every other
    /// byte becomes `\xNN` with two lowercase hexadecimal digits. The result is ordinary
    /// text, which the JSON writer then escapes a second time.
    static func escapedString(_ data: Data) -> XdrJsonValue {
        .string(escapedText(data))
    }

    /// Applies the escape ladder to a string's UTF-8 bytes.
    static func escapedString(_ text: String) -> XdrJsonValue {
        .string(escapedText(Data(text.utf8)))
    }

    static func escapedText(_ data: Data) -> String {
        var text = ""
        text.reserveCapacity(data.count)
        for byte in data {
            switch byte {
            case 0x00: text += "\\0"
            case 0x09: text += "\\t"
            case 0x0A: text += "\\n"
            case 0x0D: text += "\\r"
            case 0x5C: text += "\\\\"
            case 0x20...0x7E: text.unicodeScalars.append(UnicodeScalar(byte))
            default:
                text += "\\x"
                text.append(hexDigits[Int(byte >> 4)])
                text.append(hexDigits[Int(byte & 0x0F)])
            }
        }
        return text
    }

    // MARK: - Emission: containers

    static func array(_ values: [XdrJsonValue]) -> XdrJsonValue { .array(values) }

    /// An absent optional renders as `null`; its key stays present in the parent object.
    static func optional(_ value: XdrJsonValue?) -> XdrJsonValue { value ?? .null }

    // MARK: - Reading: containers

    /// A field key a type declares, together with the alternate spelling it also accepts on
    /// input.
    ///
    /// The one alias in the XDR set is the field named `type`, which releases of the
    /// reference implementation before 28.0.0 wrote as `type_`. Both spellings name the same
    /// declared key, so supplying both is a duplicate rather than two fields.
    struct DeclaredKey: Sendable, Equatable, ExpressibleByStringLiteral {
        let name: String
        let alias: String?

        init(_ name: String, alias: String? = nil) {
            self.name = name
            self.alias = alias
        }

        init(stringLiteral value: String) {
            self.init(value)
        }

        func matches(_ key: String) -> Bool {
            key == name || key == alias
        }
    }

    /// Reads a struct's members, with `$schema` stripped, rejecting any key the type does
    /// not declare.
    ///
    /// SEP-0051 §JSON Schema makes `$schema` acceptable on any object; nothing else is.
    /// The reference implementation refuses every unrecognised field, so accepting one here
    /// would admit documents it rejects, and would silently swallow a misspelled field name
    /// rather than reporting it.
    ///
    /// Also rejects a key appearing twice, which has no canonical meaning, and an object
    /// left with no members at all. Every XDR struct declares at least one field, so an
    /// object empty after stripping was missing its payload.
    static func object(_ value: XdrJsonValue, type: String,
                       keys: [DeclaredKey]) throws -> [XdrJsonMember] {
        let members = try objectMembers(value, type: type)

        for key in keys where key.alias != nil {
            let hasName = members.contains { $0.key == key.name }
            let hasAlias = members.contains { $0.key == key.alias }
            guard !(hasName && hasAlias) else {
                throw XdrJsonError.duplicateKey(type: type, key: key.name)
            }
        }

        let unknown = members.map(\.key).filter { candidate in
            !keys.contains { $0.matches(candidate) }
        }
        guard unknown.isEmpty else {
            throw XdrJsonError.unknownField(type: type, keys: unknown, declared: keys.map(\.name))
        }

        return members
    }

    /// The part of object reading a union shares with a struct: the value is an object, no
    /// key repeats, `$schema` is stripped, and something is left.
    ///
    /// A union's keys are its arm names, which the union itself validates, so this stops
    /// short of the declared-key check.
    static func objectMembers(_ value: XdrJsonValue, type: String) throws -> [XdrJsonMember] {
        guard case .object(let members) = value else {
            throw XdrJsonError.unexpectedType(
                type: type, key: nil, expected: "object", got: value.typeName)
        }

        var seen: Set<String> = []
        for member in members {
            guard seen.insert(member.key).inserted else {
                throw XdrJsonError.duplicateKey(type: type, key: member.key)
            }
        }

        let stripped = stripSchema(members)
        guard !stripped.isEmpty else {
            let carriedSchema = stripped.count != members.count
            throw XdrJsonError.invalidValue(
                type: type, key: nil,
                message: carriedSchema
                    ? "object carries no members beyond \"\(schemaKey)\""
                    : "object carries no members")
        }
        return stripped
    }

    /// Removes the optional `$schema` property SEP-0051 allows on any object.
    static func stripSchema(_ members: [XdrJsonMember]) -> [XdrJsonMember] {
        members.filter { $0.key != schemaKey }
    }

    /// Reads the single key and value a non-void union arm is written as.
    ///
    /// The key is the arm name, which the union matches against its own arms, so no
    /// declared-key list applies here.
    static func singleKeyObject(_ value: XdrJsonValue, type: String) throws -> XdrJsonMember {
        let members = try objectMembers(value, type: type)
        guard members.count == 1 else {
            let keys = members.map { "\"\($0.key)\"" }.joined(separator: ", ")
            throw XdrJsonError.invalidValue(
                type: type, key: nil,
                message: "a union arm is a single-key object, got \(members.count) keys: \(keys)")
        }
        return members[0]
    }

    /// Reads a required key. An optional XDR field may be `null`, but its key must exist.
    ///
    /// The key carries its own alternate spelling, so a field's accepted spellings are
    /// declared once and used both here and by the declared-key check in
    /// ``object(_:type:keys:)``. SEP-0051 §Struct requires `type` on output and both
    /// spellings on input.
    static func field(_ members: [XdrJsonMember], key: DeclaredKey,
                      type: String) throws -> XdrJsonValue {
        if let member = members.first(where: { $0.key == key.name }) {
            return member.value
        }
        if let alias = key.alias, let member = members.first(where: { $0.key == alias }) {
            return member.value
        }
        throw XdrJsonError.missingField(type: type, key: key.name)
    }

    /// Reads an array's elements.
    static func array(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> [XdrJsonValue] {
        guard case .array(let elements) = value else {
            throw XdrJsonError.unexpectedType(
                type: type, key: key, expected: "array", got: value.typeName)
        }
        return elements
    }

    // MARK: - Reading: scalars

    static func bool(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> Bool {
        guard case .bool(let flag) = value else {
            throw XdrJsonError.unexpectedType(
                type: type, key: key, expected: "boolean", got: value.typeName)
        }
        return flag
    }

    /// Reads the bare string a void union arm or an enumeration renders as.
    static func string(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> String {
        guard case .string(let text) = value else {
            throw XdrJsonError.unexpectedType(
                type: type, key: key, expected: "string", got: value.typeName)
        }
        return text
    }

    static func int32(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> Int32 {
        try fixedWidth(value, type: type, key: key, allowStringForm: false)
    }

    static func uint32(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> UInt32 {
        try fixedWidth(value, type: type, key: key, allowStringForm: false)
    }

    /// A 64-bit integer is written as a string. A JSON number is also accepted, which is
    /// the compatibility allowance SEP-0051 makes for XDR-JSON version 1 documents.
    static func int64(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> Int64 {
        try fixedWidth(value, type: type, key: key, allowStringForm: true)
    }

    static func uint64(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> UInt64 {
        try fixedWidth(value, type: type, key: key, allowStringForm: true)
    }

    private static func fixedWidth<T: FixedWidthInteger>(
        _ value: XdrJsonValue, type: String, key: String?, allowStringForm: Bool
    ) throws -> T {
        let literal: String
        switch value {
        case .number(let text):
            literal = text
        case .string(let text) where allowStringForm:
            literal = text
        default:
            throw XdrJsonError.unexpectedType(
                type: type, key: key,
                expected: allowStringForm ? "string or number" : "number",
                got: value.typeName)
        }

        guard isDecimalInteger(literal) else {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "not a base-10 integer: \(preview(literal))")
        }
        guard let parsed = T(literal) else {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "out of range for \(T.isSigned ? "int" : "uint")\(T.bitWidth): \(preview(literal))")
        }
        return parsed
    }

    /// An optional minus followed by ASCII digits, and nothing else.
    ///
    /// Deliberately narrower than the JSON number grammar: `1.0`, `1e10`, `+1`, `0x10` and
    /// any surrounding whitespace are rejected even though some of them denote an integer,
    /// because none of them is a form this SDK or the reference implementation ever emits.
    ///
    /// One predicate serves both the fixed-width and the 128/256-bit paths, so the two
    /// cannot disagree about what counts as a digit.
    static func isDecimalInteger(_ literal: String) -> Bool {
        XdrWideInteger.isDecimalInteger(literal)
    }

    // MARK: - Reading: opaque data

    /// Reads lowercase hex into bytes.
    ///
    /// Uppercase and mixed-case hex are rejected. The reference implementation accepts
    /// them; this SDK accepts a strict subset of what it accepts and emits exactly what it
    /// emits, so every value produced here stays valid for it.
    ///
    /// - Parameter expectedLength: the exact byte count a fixed-width field requires, or
    ///   `nil` for variable-length data.
    static func hex(_ value: XdrJsonValue, expectedLength: Int? = nil,
                    type: String, key: String? = nil) throws -> Data {
        let text = try string(value, type: type, key: key)
        let bytes = Array(text.utf8)

        guard bytes.count % 2 == 0 else {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "hex string has an odd number of digits: \(preview(text))")
        }

        var data = Data(capacity: bytes.count / 2)
        var index = 0
        while index < bytes.count {
            guard let high = lowercaseHexDigit(bytes[index]),
                  let low = lowercaseHexDigit(bytes[index + 1]) else {
                throw XdrJsonError.invalidValue(
                    type: type, key: key,
                    message: "hex string is not lowercase hexadecimal: \(preview(text))")
            }
            data.append(high << 4 | low)
            index += 2
        }

        if let expectedLength, data.count != expectedLength {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "expected \(expectedLength) bytes, got \(data.count)")
        }
        return data
    }

    private static func lowercaseHexDigit(_ byte: UInt8) -> UInt8? {
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): return byte - UInt8(ascii: "0")
        case UInt8(ascii: "a")...UInt8(ascii: "f"): return byte - UInt8(ascii: "a") + 10
        default: return nil
        }
    }

    // MARK: - Emission and reading: strkeys

    /// Encodes bytes as a strkey, checking the width the type declares first.
    ///
    /// The width check is the caller's only protection: none of the `encode…` helpers
    /// validates its input length, so a `WrappedData32` holding the wrong number of bytes
    /// would produce a strkey the ecosystem cannot read back.
    ///
    /// - Parameter encode: the strkey encoder for this type's version byte.
    static func strKey(_ data: Data, expectedLength: Int, type: String, key: String?,
                       encode: (Data) throws -> String) throws -> String {
        guard data.count == expectedLength else {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "expected \(expectedLength) bytes, got \(data.count)")
        }
        do {
            return try encode(data)
        } catch {
            throw XdrJsonError.invalidValue(
                type: type, key: key, message: "value has no strkey encoding")
        }
    }

    /// Decodes a strkey to bytes, checking the width the type declares.
    ///
    /// A decoding failure is reported as a domain violation of the XDR type rather than as
    /// the strkey library's own error, so a caller sees one error type across the codec.
    ///
    /// - Parameter decode: the strkey decoder for this type's version byte.
    static func strKeyBytes(_ text: String, expectedLength: Int, type: String, key: String?,
                            decode: (String) throws -> Data) throws -> Data {
        let raw: Data
        do {
            raw = try decode(text)
        } catch {
            throw XdrJsonError.invalidValue(
                type: type, key: key, message: "not a valid strkey: \(preview(text))")
        }
        guard raw.count == expectedLength else {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "strkey holds \(raw.count) bytes, expected \(expectedLength)")
        }
        return raw
    }

    // MARK: - Emission and reading: asset codes

    /// Removes trailing NUL bytes, stopping at `keepingAtLeast` bytes.
    ///
    /// The twelve-character asset code keeps a floor of five bytes, which is what lets the
    /// `AssetCode` union recover its discriminant from a bare string; the four-character
    /// code has no floor, so an all-NUL code renders as the empty string.
    static func trimTrailingNulls(_ data: Data, keepingAtLeast floor: Int) -> Data {
        var trimmed = Data(data)
        while trimmed.count > floor, trimmed.last == 0 {
            trimmed.removeLast()
        }
        return trimmed
    }

    /// Right-pads with NUL bytes to a fixed width, which is how a trimmed asset code
    /// returns to the width its XDR type declares.
    static func rightPad(_ data: Data, to width: Int) -> Data {
        var padded = Data(data)
        if padded.count < width {
            padded.append(Data(count: width - padded.count))
        }
        return padded
    }

    // MARK: - Reading: strings

    /// Reverses the SEP-0051 §String escape ladder, yielding the original bytes.
    ///
    /// Only the five escapes the ladder produces are recognised, and `\xNN` must use
    /// lowercase hexadecimal, because that is all the ladder ever emits. A raw byte outside
    /// printable ASCII is rejected for the same reason: the ladder would have written it as
    /// `\xNN`, so its presence means the text did not come from a conforming producer.
    static func unescapeString(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> Data {
        let text = try string(value, type: type, key: key)
        let bytes = Array(text.utf8)
        var data = Data(capacity: bytes.count)
        var index = 0

        while index < bytes.count {
            let byte = bytes[index]

            guard byte != UInt8(ascii: "\\") else {
                guard index + 1 < bytes.count else {
                    throw XdrJsonError.invalidValue(
                        type: type, key: key,
                        message: "string ends with a trailing backslash: \(preview(text))")
                }
                switch bytes[index + 1] {
                case UInt8(ascii: "0"): data.append(0x00); index += 2
                case UInt8(ascii: "t"): data.append(0x09); index += 2
                case UInt8(ascii: "n"): data.append(0x0A); index += 2
                case UInt8(ascii: "r"): data.append(0x0D); index += 2
                case UInt8(ascii: "\\"): data.append(0x5C); index += 2
                case UInt8(ascii: "x"):
                    guard index + 3 < bytes.count,
                          let high = lowercaseHexDigit(bytes[index + 2]),
                          let low = lowercaseHexDigit(bytes[index + 3]) else {
                        throw XdrJsonError.invalidValue(
                            type: type, key: key,
                            message: "\\x must be followed by two lowercase hexadecimal digits: \(preview(text))")
                    }
                    data.append(high << 4 | low)
                    index += 4
                default:
                    let escape = Character(UnicodeScalar(bytes[index + 1]))
                    throw XdrJsonError.invalidValue(
                        type: type, key: key,
                        message: "unrecognised escape sequence \\\(escape) in \(preview(text))")
                }
                continue
            }

            guard byte >= 0x20, byte <= 0x7E else {
                throw XdrJsonError.invalidValue(
                    type: type, key: key,
                    message: "byte outside printable ASCII must be written \\xNN: \(preview(text))")
            }
            data.append(byte)
            index += 1
        }

        return data
    }

    /// Reverses the escape ladder and requires the result to be valid UTF-8.
    ///
    /// This is the form the SDK's `string<>` fields need, since it stores them as Swift
    /// strings. Byte-exact fields are opaque and go through ``unescapeString(_:type:key:)``.
    static func unescapedText(_ value: XdrJsonValue, type: String, key: String? = nil) throws -> String {
        let data = try unescapeString(value, type: type, key: key)
        guard let text = String(data: data, encoding: .utf8) else {
            throw XdrJsonError.invalidValue(
                type: type, key: key, message: "string is not valid UTF-8")
        }
        return text
    }

    // MARK: - Wide integers

    /// Renders a 128-bit or 256-bit two's-complement value as the single decimal string
    /// SEP-0051 requires for the integer-parts types.
    static func wideDecimal(_ data: Data, signed: Bool) -> XdrJsonValue {
        .string(XdrWideInteger.decimalString(from: data, signed: signed))
    }

    /// Reads the decimal string of an integer-parts type into fixed-width bytes.
    static func wideDecimal(_ value: XdrJsonValue, bitSize: Int, signed: Bool,
                            type: String, key: String? = nil) throws -> Data {
        let text = try string(value, type: type, key: key)
        guard isDecimalInteger(text) else {
            throw XdrJsonError.invalidValue(
                type: type, key: key, message: "not a base-10 integer: \(preview(text))")
        }
        do {
            return try XdrWideInteger.bytes(fromDecimalString: text, bitSize: bitSize, signed: signed)
        } catch {
            throw XdrJsonError.invalidValue(
                type: type, key: key,
                message: "out of range for \(signed ? "int" : "uint")\(bitSize): \(preview(text))")
        }
    }

    // MARK: - Depth

    /// Rejects a tree that nests more than ``maxDepth`` containers.
    ///
    /// The walk is iterative rather than recursive, so checking an over-deep tree cannot
    /// itself exhaust the stack. Conversions that descend a tree run this at their entry
    /// point, which bounds every recursion below them.
    static func validateDepth(_ value: XdrJsonValue) throws {
        var stack: [(value: XdrJsonValue, depth: Int)] = [(value, 0)]

        while let (current, depth) = stack.popLast() {
            switch current {
            case .array(let elements):
                let inner = depth + 1
                guard inner <= maxDepth else {
                    throw XdrJsonError.recursionLimitExceeded(limit: maxDepth)
                }
                for element in elements { stack.append((element, inner)) }
            case .object(let members):
                let inner = depth + 1
                guard inner <= maxDepth else {
                    throw XdrJsonError.recursionLimitExceeded(limit: maxDepth)
                }
                for member in members { stack.append((member.value, inner)) }
            default:
                continue
            }
        }
    }

    // MARK: - Diagnostics

    /// Shortens and neutralises untrusted text before it is interpolated into an error.
    ///
    /// Control bytes are escaped so a value echoed into a terminal or a log cannot carry
    /// escape sequences of its own, and the result is capped so one oversized field cannot
    /// dominate a message.
    static func preview(_ text: String) -> String {
        var preview = ""
        var count = 0
        var truncated = false

        for scalar in text.unicodeScalars {
            if count >= previewLimit {
                truncated = true
                break
            }
            if scalar.value < 0x20 || scalar.value == 0x7F {
                preview += String(format: "\\x%02x", scalar.value)
            } else {
                preview.unicodeScalars.append(scalar)
            }
            count += 1
        }

        return truncated ? preview + "..." : preview
    }

    /// Reports a value the caller has already found to be wrong.
    ///
    /// Declared as returning `Never` so a `switch` arm that calls it needs no unreachable
    /// return of its own.
    static func fail(type: String, key: String? = nil, detail: String) throws -> Never {
        throw XdrJsonError.invalidValue(type: type, key: key, message: detail)
    }
}
