//
//  XdrWideInteger.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Conversion between 128-bit and 256-bit two's-complement integers and their base-10
/// decimal text, without a big-integer dependency.
///
/// XDR carries these widths as two or four 64-bit limbs, while both SEP-0051 XDR-JSON and
/// the SDK's `SCValXDR` string accessors render them as a single decimal string. Both paths
/// call this one implementation, so a rounding or range rule cannot hold in one place and
/// not the other.
///
/// Arithmetic is schoolbook base-256 division and multiplication over byte arrays, which is
/// exact at every width and never involves a floating-point type.
internal enum XdrWideInteger {

    // MARK: - Decimal text

    /// Whether `literal` is an optional `-` followed by one or more ASCII digits, and
    /// nothing else.
    ///
    /// The check is byte-level on purpose. `Character.isNumber` is true for every Unicode
    /// character in a numeric category, which includes Arabic-Indic and fullwidth digits,
    /// vulgar fractions and Roman numerals; the base-256 conversion below reads its input as
    /// `utf8` bytes offset from `0x30`, so anything outside `0x30` to `0x39` would be
    /// converted into a value bearing no relation to the text.
    static func isDecimalInteger(_ literal: String) -> Bool {
        var digits = Array(literal.utf8)[...]
        if digits.first == UInt8(ascii: "-") { digits = digits.dropFirst() }
        guard !digits.isEmpty else { return false }
        return digits.allSatisfy { $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") }
    }

    // MARK: - Decimal text to bytes

    /// Parses a decimal integer string into its fixed-width, big-endian, two's-complement
    /// byte representation (`bitSize / 8` bytes).
    ///
    /// - Parameters:
    ///   - string: The decimal text. A single leading `-` is accepted for a signed width.
    ///   - bitSize: The target width in bits.
    ///   - signed: Whether the target width is signed.
    /// - Throws: `StellarSDKError.invalidArgument` when the string is not a valid decimal
    ///   integer, when a negative value is supplied for an unsigned type, or when the value
    ///   does not fit the target width.
    static func bytes(fromDecimalString string: String, bitSize: Int, signed: Bool) throws -> Data {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let isNegative = trimmed.hasPrefix("-")
        let absoluteString = isNegative ? String(trimmed.dropFirst()) : trimmed

        guard isDecimalInteger(trimmed) else {
            throw StellarSDKError.invalidArgument(message: "Invalid number string: \(string)")
        }

        if absoluteString == "0" {
            let byteSize = bitSize / 8
            return Data(repeating: 0, count: byteSize)
        }

        var value = Array(absoluteString.utf8).map { $0 - 48 }
        var bytes: [UInt8] = []

        while !value.isEmpty && !(value.count == 1 && value[0] == 0) {
            var remainder = 0
            var newValue: [UInt8] = []

            for digit in value {
                let temp = remainder * 10 + Int(digit)
                newValue.append(UInt8(temp / 256))
                remainder = temp % 256
            }

            bytes.insert(UInt8(remainder), at: 0)

            while !newValue.isEmpty && newValue[0] == 0 {
                newValue.removeFirst()
            }
            value = newValue
        }

        // Reject values that do not fit the target width. `bytes` here is the
        // big-endian magnitude (absolute value), minimal length, and non-empty
        // (the "0" case returned earlier).
        let byteSize = bitSize / 8
        let fitsWidth: Bool
        if !signed {
            // Unsigned: negatives are invalid; the full width is representable.
            fitsWidth = !isNegative && bytes.count <= byteSize
        } else if bytes.count < byteSize {
            fitsWidth = true
        } else if bytes.count > byteSize {
            fitsWidth = false
        } else {
            // Exactly byteSize magnitude bytes: the top bit decides.
            let topBitSet = (bytes[0] & 0x80) != 0
            if !topBitSet {
                fitsWidth = true
            } else if !isNegative {
                fitsWidth = false
            } else {
                // Negative: only -2^(bitSize-1) is valid (magnitude 0x80 00..00).
                fitsWidth = bytes[0] == 0x80 && bytes.dropFirst().allSatisfy { $0 == 0 }
            }
        }
        guard fitsWidth else {
            throw StellarSDKError.invalidArgument(
                message: "Value out of range for \(signed ? "i" : "u")\(bitSize): \(string)")
        }

        if isNegative && signed {
            bytes = bytes.map { ~$0 }

            var carry = true
            for i in (0..<bytes.count).reversed() {
                if carry {
                    if bytes[i] == 255 {
                        bytes[i] = 0
                    } else {
                        bytes[i] += 1
                        carry = false
                    }
                }
            }
        }

        if bytes.count < byteSize {
            let paddingByte: UInt8 = (isNegative && signed) ? 0xFF : 0x00
            let padding = Array(repeating: paddingByte, count: byteSize - bytes.count)
            bytes = padding + bytes
        }

        return Data(bytes)
    }

    // MARK: - Bytes to decimal text

    /// Renders a big-endian two's-complement byte sequence as base-10 decimal text.
    ///
    /// - Parameters:
    ///   - data: The big-endian bytes.
    ///   - signed: Whether the top bit is a sign bit.
    static func decimalString(from data: Data, signed: Bool) -> String {
        let bytes = [UInt8](data)

        let isNegative = signed && !bytes.isEmpty && (bytes[0] & 0x80) != 0

        var workingBytes = bytes

        if isNegative {
            var borrow = true
            for i in (0..<workingBytes.count).reversed() {
                if borrow {
                    if workingBytes[i] == 0 {
                        workingBytes[i] = 0xFF
                    } else {
                        workingBytes[i] -= 1
                        borrow = false
                    }
                }
            }

            workingBytes = workingBytes.map { ~$0 }
        }

        var result = [0]

        for byte in workingBytes {
            var carry = Int(byte)
            for i in (0..<result.count).reversed() {
                let temp = result[i] * 256 + carry
                result[i] = temp % 10
                carry = temp / 10
            }

            while carry > 0 {
                result.insert(carry % 10, at: 0)
                carry /= 10
            }
        }

        while result.count > 1 && result[0] == 0 {
            result.removeFirst()
        }

        let numberString = result.map { String($0) }.joined()
        return isNegative ? "-" + numberString : numberString
    }

    // MARK: - Width adjustment

    /// Sign-extends or truncates `data` to exactly `targetSize` big-endian bytes.
    static func pad(_ data: Data, targetSize: Int, signed: Bool) -> Data {
        if data.count >= targetSize {
            return data.suffix(targetSize)
        }

        let paddingByte: UInt8
        if signed && !data.isEmpty && (data[0] & 0x80) != 0 {
            paddingByte = 0xFF
        } else {
            paddingByte = 0x00
        }

        let padding = Data(repeating: paddingByte, count: targetSize - data.count)
        return padding + data
    }

    // MARK: - Limbs

    /// Splits 16 big-endian bytes into the two limbs XDR carries a 128-bit value in.
    static func parts128(from data: Data) -> (hi: UInt64, lo: UInt64) {
        let paddedData = pad(data, targetSize: 16, signed: false)
        let bytes = [UInt8](paddedData)

        var hi: UInt64 = 0
        for i in 0..<8 {
            hi = (hi << 8) | UInt64(bytes[i])
        }

        var lo: UInt64 = 0
        for i in 8..<16 {
            lo = (lo << 8) | UInt64(bytes[i])
        }

        return (hi, lo)
    }

    /// Splits 32 big-endian bytes into the four limbs XDR carries a 256-bit value in.
    static func parts256(from data: Data) -> (hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        let paddedData = pad(data, targetSize: 32, signed: false)
        let bytes = [UInt8](paddedData)

        var hiHi: UInt64 = 0
        for i in 0..<8 {
            hiHi = (hiHi << 8) | UInt64(bytes[i])
        }

        var hiLo: UInt64 = 0
        for i in 8..<16 {
            hiLo = (hiLo << 8) | UInt64(bytes[i])
        }

        var loHi: UInt64 = 0
        for i in 16..<24 {
            loHi = (loHi << 8) | UInt64(bytes[i])
        }

        var loLo: UInt64 = 0
        for i in 24..<32 {
            loLo = (loLo << 8) | UInt64(bytes[i])
        }

        return (hiHi, hiLo, loHi, loLo)
    }

    /// Joins the two limbs of a 128-bit value into 16 big-endian bytes.
    static func data128(hi: UInt64, lo: UInt64) -> Data {
        var bytes: [UInt8] = []

        for i in (0..<8).reversed() {
            bytes.append(UInt8((hi >> (i * 8)) & 0xFF))
        }

        for i in (0..<8).reversed() {
            bytes.append(UInt8((lo >> (i * 8)) & 0xFF))
        }

        return Data(bytes)
    }

    /// Joins the four limbs of a 256-bit value into 32 big-endian bytes.
    static func data256(hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) -> Data {
        var bytes: [UInt8] = []

        for value in [hiHi, hiLo, loHi, loLo] {
            for i in (0..<8).reversed() {
                bytes.append(UInt8((value >> (i * 8)) & 0xFF))
            }
        }

        return Data(bytes)
    }

    // MARK: - Decimal text to limbs

    /// Parses decimal text into the two limbs of a 128-bit value.
    static func parts128(fromDecimalString string: String, signed: Bool) throws -> (hi: UInt64, lo: UInt64) {
        parts128(from: try bytes(fromDecimalString: string, bitSize: 128, signed: signed))
    }

    /// Parses decimal text into the four limbs of a 256-bit value.
    static func parts256(fromDecimalString string: String, signed: Bool) throws
        -> (hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        parts256(from: try bytes(fromDecimalString: string, bitSize: 256, signed: signed))
    }
}
