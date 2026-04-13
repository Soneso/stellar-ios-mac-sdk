//
//  TxRepHelper.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Shared utility functions for TxRep encoding and decoding.
///
/// Used by both generated and wrapper TxRep code to provide consistent
/// parsing, formatting, and Stellar type conversion.
///
/// All methods are static; this class is never instantiated.
public final class TxRepHelper: Sendable {

    // MARK: - Parser utilities

    /// Parse TxRep text into a key-value map.
    ///
    /// Handles blank lines, comment lines (starting with `:`), CRLF line endings,
    /// and lines with no colon (skipped). Splits on the first `:` only and trims
    /// value whitespace. Duplicate keys use the last-write-wins rule.
    ///
    /// - Parameter txRep: Human-readable TxRep string.
    /// - Returns: Dictionary mapping keys to raw (unprocessed) value strings.
    public static func parse(_ txRep: String) -> [String: String] {
        var map = [String: String]()
        // Normalize CRLF to LF.
        let lines = txRep.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false)
        for rawLine in lines {
            let line = String(rawLine)
            // Skip blank lines.
            if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            // Skip comment-only lines (leading colon, no key).
            if line.trimmingCharacters(in: .whitespaces).hasPrefix(":") { continue }

            guard let colonIdx = line.firstIndex(of: ":") else { continue }

            let key = line[line.startIndex..<colonIdx].trimmingCharacters(in: .whitespaces)
            if key.isEmpty { continue }

            let afterColon = line.index(after: colonIdx)
            let value = afterColon <= line.endIndex
                ? String(line[afterColon...]).trimmingCharacters(in: .whitespaces)
                : ""
            map[key] = value
        }
        return map
    }

    /// Get a value from the map, stripping inline comments via ``removeComment(_:)``.
    ///
    /// - Parameters:
    ///   - map: The key-value map returned by ``parse(_:)``.
    ///   - key: The key to look up.
    /// - Returns: The trimmed value with any inline comment removed, or `nil` if the key is absent.
    public static func getValue(_ map: [String: String], _ key: String) -> String? {
        guard let raw = map[key] else { return nil }
        return removeComment(raw)
    }

    /// Remove an inline comment from a TxRep value string.
    ///
    /// If the value begins with a double-quote, the method finds the closing quote
    /// (respecting backslash escapes) and returns everything up to and including it.
    /// For unquoted values, any ` (…)` suffix is stripped and the result is trimmed.
    ///
    /// - Parameter value: Raw value string, possibly containing a trailing comment.
    /// - Returns: Value with any inline comment removed.
    public static func removeComment(_ value: String) -> String {
        if value.hasPrefix("\"") {
            var i = value.index(after: value.startIndex)
            while i < value.endIndex {
                if value[i] == "\\" {
                    // Skip the escaped character.
                    let next = value.index(after: i)
                    if next < value.endIndex {
                        i = value.index(after: next)
                    } else {
                        i = next
                    }
                    continue
                }
                if value[i] == "\"" {
                    // Found the closing quote — return through it.
                    return String(value[value.startIndex...i])
                }
                i = value.index(after: i)
            }
            // No closing quote — return as-is.
            return value
        }

        // Unquoted — look for `(` as comment start.
        if let parenIdx = value.firstIndex(of: "(") {
            return String(value[value.startIndex..<parenIdx]).trimmingCharacters(in: .whitespaces)
        }
        return value.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Byte / hex conversion

    /// Encode bytes as a lowercase hex string.
    ///
    /// Returns `"0"` for empty input to match the SEP-0011 convention for zero-length
    /// opaque fields.
    ///
    /// - Parameter bytes: Binary data to encode.
    /// - Returns: Lowercase hex string, or `"0"` for empty data.
    public static func bytesToHex(_ bytes: Data) -> String {
        if bytes.isEmpty { return "0" }
        return bytes.base16EncodedString()
    }

    /// Decode a hex string to bytes.
    ///
    /// `"0"` decodes to empty `Data`. Odd-length hex strings are left-padded with a
    /// zero digit (e.g., `"f"` becomes `"0f"`). Non-hex characters cause a throw.
    ///
    /// - Parameter hex: Hex string to decode. May be `"0"` or any valid hex string.
    /// - Returns: Decoded `Data`.
    /// - Throws: `TxRepError.invalidValue(key:)` if `hex` contains non-hex characters.
    public static func hexToBytes(_ hex: String) throws -> Data {
        if hex == "0" { return Data() }
        var h = hex
        if h.count % 2 != 0 {
            h = "0" + h
        }
        // Validate all characters before converting.
        let validHex = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        for ch in h.unicodeScalars {
            guard validHex.contains(ch) else {
                throw TxRepError.invalidValue(key: hex)
            }
        }
        guard let data = h.data(using: .hexadecimal) else {
            throw TxRepError.invalidValue(key: hex)
        }
        return data
    }

    // MARK: - String escaping

    /// Escape a string for the TxRep double-quoted format.
    ///
    /// The output is wrapped in double quotes. Inside the quotes:
    /// - `\` is encoded as `\\`
    /// - `"` is encoded as `\"`
    /// - `\n` (LF) is encoded as `\n`
    /// - `\r` (CR) is encoded as `\r`
    /// - `\t` (HT) is encoded as `\t`
    /// - Bytes 0x00–0x1F (excluding the above), 0x7F, and 0x80–0xFF are encoded
    ///   as `\xNN` where NN is two lowercase hex digits per UTF-8 byte.
    /// - Printable ASCII 0x20–0x7E (excluding `\` and `"`) is passed through.
    ///
    /// - Parameter s: The string to escape.
    /// - Returns: Escaped, double-quoted string.
    public static func escapeString(_ s: String) -> String {
        var buf = "\""
        let utf8Bytes = Array(s.utf8)
        var i = 0
        while i < utf8Bytes.count {
            let byte = utf8Bytes[i]
            switch byte {
            case 0x5C: // backslash
                buf += "\\\\"
                i += 1
            case 0x22: // double quote
                buf += "\\\""
                i += 1
            case 0x0A: // newline LF
                buf += "\\n"
                i += 1
            case 0x0D: // carriage return CR
                buf += "\\r"
                i += 1
            case 0x09: // horizontal tab HT
                buf += "\\t"
                i += 1
            case 0x20...0x7E: // printable ASCII
                buf += String(UnicodeScalar(byte))
                i += 1
            default:
                // Non-printable or non-ASCII — encode as \xNN per byte.
                buf += "\\x" + String(format: "%02x", byte)
                i += 1
            }
        }
        buf += "\""
        return buf
    }

    /// Unescape a TxRep string value.
    ///
    /// If the input is enclosed in double quotes they are stripped first. Handles
    /// `\"`, `\\`, `\n`, `\r`, `\t`, `\xNN` (hex), and `\NNN` (octal) escape sequences.
    /// If the input is not quoted it is returned as-is (no unescaping is attempted).
    ///
    /// - Parameter s: The possibly-quoted string to unescape.
    /// - Returns: Unescaped string.
    /// - Throws: `TxRepError.invalidValue(key:)` if the string is quoted but unterminated,
    ///           or if a `\xNN` sequence contains invalid hex digits.
    public static func unescapeString(_ s: String) throws -> String {
        guard s.hasPrefix("\"") else {
            // Not quoted — return as-is per SEP-0011.
            return s
        }
        // Quoted string — strip surrounding quotes and unescape.
        guard s.hasSuffix("\""), s.count >= 2 else {
            throw TxRepError.invalidValue(key: s)
        }
        let inner = String(s.dropFirst().dropLast())
        let bytes = Array(inner.utf8)
        var result = [UInt8]()
        var i = 0
        while i < bytes.count {
            if bytes[i] == UInt8(ascii: "\\"), i + 1 < bytes.count {
                let next = bytes[i + 1]
                switch next {
                case UInt8(ascii: "\""):
                    result.append(UInt8(ascii: "\""))
                    i += 2
                case UInt8(ascii: "\\"):
                    result.append(UInt8(ascii: "\\"))
                    i += 2
                case UInt8(ascii: "n"):
                    result.append(UInt8(ascii: "\n"))
                    i += 2
                case UInt8(ascii: "r"):
                    result.append(UInt8(ascii: "\r"))
                    i += 2
                case UInt8(ascii: "t"):
                    result.append(UInt8(ascii: "\t"))
                    i += 2
                case UInt8(ascii: "x"):
                    // \xNN — two hex digits.
                    guard i + 3 < bytes.count else {
                        // Incomplete \x sequence — treat literally.
                        result.append(bytes[i])
                        i += 1
                        continue
                    }
                    let hi = bytes[i + 2]
                    let lo = bytes[i + 3]
                    guard let hiNibble = hexNibble(hi), let loNibble = hexNibble(lo) else {
                        throw TxRepError.invalidValue(key: s)
                    }
                    result.append(UInt8(hiNibble << 4 | loNibble))
                    i += 4
                case UInt8(ascii: "0")...UInt8(ascii: "7"):
                    // Octal escape \NNN (up to three octal digits) — for Flutter compat.
                    var octalValue: UInt32 = 0
                    var j = i + 1
                    var digits = 0
                    while j < bytes.count, digits < 3,
                          bytes[j] >= UInt8(ascii: "0"), bytes[j] <= UInt8(ascii: "7") {
                        octalValue = octalValue * 8 + UInt32(bytes[j] - UInt8(ascii: "0"))
                        j += 1
                        digits += 1
                    }
                    if digits > 0, let scalar = Unicode.Scalar(octalValue) {
                        let ch = Character(scalar)
                        result += Array(String(ch).utf8)
                        i = j
                    } else {
                        result.append(bytes[i])
                        i += 1
                    }
                default:
                    // Unknown escape — pass through literally.
                    result.append(bytes[i])
                    i += 1
                }
            } else {
                result.append(bytes[i])
                i += 1
            }
        }
        guard let str = String(bytes: result, encoding: .utf8) else {
            throw TxRepError.invalidValue(key: s)
        }
        return str
    }

    // MARK: - Numeric parsing

    /// Parse a string to `Int32`, supporting decimal and `0x`/`0X` hex prefixes.
    ///
    /// Leading `-` is accepted for negative values. Hex input may also be negative
    /// (e.g., `-0x1`). Throws on overflow or invalid characters.
    ///
    /// - Parameter s: String to parse.
    /// - Returns: Parsed `Int32` value.
    /// - Throws: `TxRepError.invalidValue(key:)` on parse failure or overflow.
    public static func parseInt(_ s: String) throws -> Int32 {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        var work = trimmed
        let negative = work.hasPrefix("-")
        if negative { work = String(work.dropFirst()) }

        let raw: Int64
        if work.hasPrefix("0x") || work.hasPrefix("0X") {
            guard let val = UInt64(work.dropFirst(2), radix: 16) else {
                throw TxRepError.invalidValue(key: s)
            }
            raw = negative ? -Int64(val) : Int64(val)
        } else {
            guard let val = Int64(work) else {
                throw TxRepError.invalidValue(key: s)
            }
            raw = negative ? -val : val
        }
        guard raw >= Int64(Int32.min), raw <= Int64(Int32.max) else {
            throw TxRepError.invalidValue(key: s)
        }
        return Int32(raw)
    }

    /// Parse a string to `Int64`, supporting decimal and `0x`/`0X` hex prefixes.
    ///
    /// Leading `-` is accepted for negative values. Throws on overflow or invalid characters.
    ///
    /// - Parameter s: String to parse.
    /// - Returns: Parsed `Int64` value.
    /// - Throws: `TxRepError.invalidValue(key:)` on parse failure or overflow.
    public static func parseInt64(_ s: String) throws -> Int64 {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        var work = trimmed
        let negative = work.hasPrefix("-")
        if negative { work = String(work.dropFirst()) }

        if work.hasPrefix("0x") || work.hasPrefix("0X") {
            guard let val = UInt64(work.dropFirst(2), radix: 16) else {
                throw TxRepError.invalidValue(key: s)
            }
            if negative {
                // Two's complement: -val for UInt64 that fits in Int64.
                guard val <= UInt64(Int64.max) + 1 else {
                    throw TxRepError.invalidValue(key: s)
                }
                return val == UInt64(Int64.max) + 1 ? Int64.min : -Int64(val)
            } else {
                guard val <= UInt64(Int64.max) else {
                    throw TxRepError.invalidValue(key: s)
                }
                return Int64(val)
            }
        } else {
            if let val = Int64(work) {
                return negative ? (val == 0 ? 0 : -val) : val
            }
            // Int64.min edge case: absolute value (9223372036854775808) overflows Int64
            // but fits in UInt64. Handle only when negative.
            if negative, let uval = UInt64(work), uval == UInt64(Int64.max) + 1 {
                return Int64.min
            }
            throw TxRepError.invalidValue(key: s)
        }
    }

    /// Parse a string to `UInt64`, supporting decimal and `0x`/`0X` hex prefixes.
    ///
    /// Does not accept a leading `-`. Throws on invalid characters or if the value
    /// exceeds `UInt64.max`.
    ///
    /// - Parameter s: String to parse.
    /// - Returns: Parsed `UInt64` value.
    /// - Throws: `TxRepError.invalidValue(key:)` on parse failure.
    public static func parseUInt64(_ s: String) throws -> UInt64 {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("-") {
            throw TxRepError.invalidValue(key: s)
        }
        if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            guard let val = UInt64(trimmed.dropFirst(2), radix: 16) else {
                throw TxRepError.invalidValue(key: s)
            }
            return val
        }
        guard let val = UInt64(trimmed) else {
            throw TxRepError.invalidValue(key: s)
        }
        return val
    }

    // MARK: - Stellar type formatters

    /// Convert a `PublicKey` to its G-address StrKey string.
    ///
    /// - Parameter key: The Stellar Ed25519 public key.
    /// - Returns: G-address (e.g., `GBZX...`).
    public static func formatAccountId(_ key: PublicKey) -> String {
        return key.accountId
    }

    /// Parse a G-address StrKey string to a `PublicKey`.
    ///
    /// - Parameter strKey: G-address string.
    /// - Returns: `PublicKey` value.
    /// - Throws: `TxRepError.invalidValue(key:)` if the address is not a valid G-address.
    public static func parseAccountId(_ strKey: String) throws -> PublicKey {
        do {
            return try PublicKey(accountId: strKey)
        } catch {
            throw TxRepError.invalidValue(key: strKey)
        }
    }

    /// Convert a `MuxedAccountXDR` to its canonical StrKey string.
    ///
    /// Returns a G-address for plain Ed25519 accounts and an M-address for muxed accounts.
    ///
    /// - Parameter mux: The muxed account XDR value.
    /// - Returns: G- or M-address string.
    /// - Throws: `TxRepError.invalidValue(key:)` if encoding fails.
    public static func formatMuxedAccount(_ mux: MuxedAccountXDR) throws -> String {
        let accountId = mux.accountId
        if accountId.isEmpty {
            throw TxRepError.invalidValue(key: "muxedAccount")
        }
        return accountId
    }

    /// Parse a G- or M-address StrKey string to a `MuxedAccountXDR`.
    ///
    /// - Parameter strKey: G-address or M-address string.
    /// - Returns: `MuxedAccountXDR` value.
    /// - Throws: `TxRepError.invalidValue(key:)` if the string is not a valid account address.
    public static func parseMuxedAccount(_ strKey: String) throws -> MuxedAccountXDR {
        do {
            return try strKey.decodeMuxedAccount()
        } catch {
            throw TxRepError.invalidValue(key: strKey)
        }
    }

    /// Format an `AssetXDR` as a TxRep asset string.
    ///
    /// Returns `"XLM"` for native assets and `"CODE:ISSUER"` for credit assets.
    ///
    /// - Parameter asset: The asset XDR value.
    /// - Returns: TxRep asset string.
    public static func formatAsset(_ asset: AssetXDR) -> String {
        switch asset {
        case .native:
            return "XLM"
        case .alphanum4(let a):
            let code = assetCodeFromData(a.assetCode.wrapped)
            let issuer = formatAccountId(a.issuer)
            return "\(code):\(issuer)"
        case .alphanum12(let a):
            let code = assetCodeFromData(a.assetCode.wrapped)
            let issuer = formatAccountId(a.issuer)
            return "\(code):\(issuer)"
        }
    }

    /// Parse a TxRep asset string to an `AssetXDR`.
    ///
    /// Accepts `"XLM"` or `"native"` for native, and `"CODE:ISSUER"` for credit assets.
    /// Asset codes of 1–4 characters produce `alphanum4`; 5–12 produce `alphanum12`.
    ///
    /// - Parameter value: TxRep asset string.
    /// - Returns: `AssetXDR` value.
    /// - Throws: `TxRepError.invalidValue(key:)` if the string cannot be parsed.
    public static func parseAsset(_ value: String) throws -> AssetXDR {
        if value == "XLM" || value == "native" {
            return .native
        }
        let parts = value.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            throw TxRepError.invalidValue(key: value)
        }
        let code = parts[0].trimmingCharacters(in: .whitespaces)
        let issuerStr = parts[1].trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, code.count <= 12 else {
            throw TxRepError.invalidValue(key: value)
        }
        let issuer = try parseAccountId(issuerStr)
        if code.count <= 4 {
            return .alphanum4(Alpha4XDR(assetCode: assetCodeToData4(code), issuer: issuer))
        } else {
            return .alphanum12(Alpha12XDR(assetCode: assetCodeToData12(code), issuer: issuer))
        }
    }

    /// Format a `ChangeTrustAssetXDR` as a TxRep string.
    ///
    /// Returns `"XLM"` for native, `"CODE:ISSUER"` for credit assets. Pool-share assets
    /// cannot be represented as a single compact string (they are serialized field-by-field
    /// by the caller) and cause a throw.
    ///
    /// - Parameter asset: The change-trust asset XDR value.
    /// - Returns: TxRep asset string.
    /// - Throws: `TxRepError.invalidValue(key:)` for pool-share or unknown asset types.
    public static func formatChangeTrustAsset(_ asset: ChangeTrustAssetXDR) throws -> String {
        switch asset {
        case .native:
            return "XLM"
        case .alphanum4(let a):
            let code = assetCodeFromData(a.assetCode.wrapped)
            let issuer = formatAccountId(a.issuer)
            return "\(code):\(issuer)"
        case .alphanum12(let a):
            let code = assetCodeFromData(a.assetCode.wrapped)
            let issuer = formatAccountId(a.issuer)
            return "\(code):\(issuer)"
        case .poolShare:
            throw TxRepError.invalidValue(key: "poolShareChangeTrustAsset")
        }
    }

    /// Parse a TxRep string to a `ChangeTrustAssetXDR`.
    ///
    /// Handles `"XLM"` / `"native"` and `"CODE:ISSUER"` formats. Pool-share assets must be
    /// constructed separately from their constituent fields.
    ///
    /// - Parameter value: TxRep asset string.
    /// - Returns: `ChangeTrustAssetXDR` value.
    /// - Throws: `TxRepError.invalidValue(key:)` if the string cannot be parsed.
    public static func parseChangeTrustAsset(_ value: String) throws -> ChangeTrustAssetXDR {
        if value == "XLM" || value == "native" {
            return .native
        }
        let parts = value.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            throw TxRepError.invalidValue(key: value)
        }
        let code = parts[0].trimmingCharacters(in: .whitespaces)
        let issuerStr = parts[1].trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, code.count <= 12 else {
            throw TxRepError.invalidValue(key: value)
        }
        let issuer = try parseAccountId(issuerStr)
        if code.count <= 4 {
            return .alphanum4(Alpha4XDR(assetCode: assetCodeToData4(code), issuer: issuer))
        } else {
            return .alphanum12(Alpha12XDR(assetCode: assetCodeToData12(code), issuer: issuer))
        }
    }

    /// Format a `TrustlineAssetXDR` as a TxRep string.
    ///
    /// Returns `"XLM"` for native, `"CODE:ISSUER"` for credit assets, and a 64-character
    /// lowercase hex string for pool-share assets (the 32-byte liquidity pool ID).
    ///
    /// - Parameter asset: The trustline asset XDR value.
    /// - Returns: TxRep asset string.
    /// - Throws: `TxRepError.invalidValue(key:)` for unknown asset types.
    public static func formatTrustlineAsset(_ asset: TrustlineAssetXDR) throws -> String {
        switch asset {
        case .native:
            return "XLM"
        case .alphanum4(let a):
            let code = assetCodeFromData(a.assetCode.wrapped)
            let issuer = formatAccountId(a.issuer)
            return "\(code):\(issuer)"
        case .alphanum12(let a):
            let code = assetCodeFromData(a.assetCode.wrapped)
            let issuer = formatAccountId(a.issuer)
            return "\(code):\(issuer)"
        case .poolShare(let poolId):
            // Pool ID is a 32-byte hash encoded as 64 lowercase hex characters.
            return poolId.wrapped.base16EncodedString()
        }
    }

    /// Parse a TxRep string to a `TrustlineAssetXDR`.
    ///
    /// Accepts `"XLM"` / `"native"`, `"CODE:ISSUER"`, and a 64-character hex string
    /// (pool-share liquidity pool ID).
    ///
    /// - Parameter value: TxRep asset string.
    /// - Returns: `TrustlineAssetXDR` value.
    /// - Throws: `TxRepError.invalidValue(key:)` if the string cannot be parsed.
    public static func parseTrustlineAsset(_ value: String) throws -> TrustlineAssetXDR {
        if value == "XLM" || value == "native" {
            return .native
        }
        // 64-char hex without a colon → pool share.
        if value.count == 64, !value.contains(":") {
            guard let poolData = value.data(using: .hexadecimal) else {
                throw TxRepError.invalidValue(key: value)
            }
            return .poolShare(WrappedData32(poolData))
        }
        let parts = value.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            throw TxRepError.invalidValue(key: value)
        }
        let code = parts[0].trimmingCharacters(in: .whitespaces)
        let issuerStr = parts[1].trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, code.count <= 12 else {
            throw TxRepError.invalidValue(key: value)
        }
        let issuer = try parseAccountId(issuerStr)
        if code.count <= 4 {
            return .alphanum4(Alpha4XDR(assetCode: assetCodeToData4(code), issuer: issuer))
        } else {
            return .alphanum12(Alpha12XDR(assetCode: assetCodeToData12(code), issuer: issuer))
        }
    }

    /// Format a `SignerKeyXDR` as its canonical StrKey string.
    ///
    /// - `ed25519` → G-address
    /// - `preAuthTx` → T-address
    /// - `hashX` → X-address
    /// - `signedPayload` → P-address
    ///
    /// - Parameter key: The signer key XDR value.
    /// - Returns: StrKey-encoded signer key.
    /// - Throws: `TxRepError.invalidValue(key:)` if encoding fails.
    public static func formatSignerKey(_ key: SignerKeyXDR) throws -> String {
        switch key {
        case .ed25519(let uint256):
            do {
                return try uint256.wrapped.encodeEd25519PublicKey()
            } catch {
                throw TxRepError.invalidValue(key: "signerKeyEd25519")
            }
        case .preAuthTx(let uint256):
            do {
                return try uint256.wrapped.encodePreAuthTx()
            } catch {
                throw TxRepError.invalidValue(key: "signerKeyPreAuthTx")
            }
        case .hashX(let uint256):
            do {
                return try uint256.wrapped.encodeSha256Hash()
            } catch {
                throw TxRepError.invalidValue(key: "signerKeyHashX")
            }
        case .signedPayload(let payload):
            do {
                return try payload.encodeSignedPayload()
            } catch {
                throw TxRepError.invalidValue(key: "signerKeySignedPayload")
            }
        }
    }

    /// Parse a StrKey string to a `SignerKeyXDR`.
    ///
    /// The key type is inferred from the leading character:
    /// - `G` → ed25519
    /// - `T` → preAuthTx
    /// - `X` → hashX
    /// - `P` → signedPayload
    ///
    /// - Parameter value: StrKey-encoded signer key string.
    /// - Returns: `SignerKeyXDR` value.
    /// - Throws: `TxRepError.invalidValue(key:)` if the string cannot be decoded.
    public static func parseSignerKey(_ value: String) throws -> SignerKeyXDR {
        if value.hasPrefix("G") {
            do {
                let data = try value.decodeEd25519PublicKey()
                return .ed25519(Uint256XDR(data))
            } catch {
                throw TxRepError.invalidValue(key: value)
            }
        } else if value.hasPrefix("T") {
            do {
                let data = try value.decodePreAuthTx()
                return .preAuthTx(Uint256XDR(data))
            } catch {
                throw TxRepError.invalidValue(key: value)
            }
        } else if value.hasPrefix("X") {
            do {
                let data = try value.decodeSha256Hash()
                return .hashX(Uint256XDR(data))
            } catch {
                throw TxRepError.invalidValue(key: value)
            }
        } else if value.hasPrefix("P") {
            do {
                let payload = try value.decodeSignedPayload()
                return .signedPayload(payload)
            } catch {
                throw TxRepError.invalidValue(key: value)
            }
        } else {
            throw TxRepError.invalidValue(key: value)
        }
    }

    /// Format an `AllowTrustOpAssetXDR` as a compact asset code string.
    ///
    /// Trailing null bytes are stripped from the fixed-length code arrays.
    ///
    /// - Parameter asset: The allow-trust asset XDR value.
    /// - Returns: Asset code string (e.g., `"USDC"`).
    /// - Throws: `TxRepError.invalidValue(key:)` for unknown asset types.
    public static func formatAllowTrustAsset(_ asset: AllowTrustOpAssetXDR) throws -> String {
        switch asset {
        case .alphanum4(let code):
            return assetCodeFromData(code.wrapped)
        case .alphanum12(let code):
            return assetCodeFromData(code.wrapped)
        }
    }

    /// Parse an asset code string to an `AllowTrustOpAssetXDR`.
    ///
    /// Codes of 1–4 characters produce `alphanum4`; 5–12 produce `alphanum12`.
    ///
    /// - Parameter code: Asset code string.
    /// - Returns: `AllowTrustOpAssetXDR` value.
    /// - Throws: `TxRepError.invalidValue(key:)` if the code is empty or longer than 12 characters.
    public static func parseAllowTrustAsset(_ code: String) throws -> AllowTrustOpAssetXDR {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count <= 12 else {
            throw TxRepError.invalidValue(key: code)
        }
        if trimmed.count <= 4 {
            return .alphanum4(assetCodeToData4(trimmed))
        } else {
            return .alphanum12(assetCodeToData12(trimmed))
        }
    }

    // MARK: - Memo text legacy encoding

    /// Encode a MEMO_TEXT string in SEP-0011 C-style escape format.
    ///
    /// Per SEP-0011 (and the reference `stc` implementation), non-printable
    /// and non-ASCII bytes are escaped as `\xNN` over the raw UTF-8 byte
    /// sequence — NOT as `\uNNNN` Unicode code points. Delegates to
    /// ``escapeString(_:)`` which implements that format.
    ///
    /// `decodeMemoText(_:)` accepts both the SEP-0011 `\xNN` format and the
    /// legacy JSON `\uNNNN` format produced by older iOS SDK builds (and
    /// other SDKs that have the same historical bug), so previously written
    /// TxRep data continues to parse.
    ///
    /// - Parameter s: The raw memo text string (at most 28 bytes in UTF-8).
    /// - Returns: Quoted SEP-0011-escaped string, e.g. `"Hello"` or `"caf\xc3\xa9"`.
    public static func encodeMemoText(_ s: String) -> String {
        return escapeString(s)
    }

    /// Decode a MEMO_TEXT value from TxRep, supporting both the legacy
    /// JSON-encoded format and the newer `\xNN` escape format.
    ///
    /// Tries JSON decoding first (for interoperability with older iOS SDK
    /// output and other SDKs that write JSON string literals). Falls back to
    /// `unescapeString(_:)` for `\xNN`-escaped strings.
    ///
    /// - Parameter s: Raw value string from the TxRep key-value map.
    /// - Returns: The decoded memo text.
    /// - Throws: `TxRepError.invalidValue(key:)` if neither decoder succeeds.
    public static func decodeMemoText(_ s: String) throws -> String {
        // Attempt JSON decode if the value looks like a JSON string literal.
        // `.fragmentsAllowed` is required because a bare quoted string is a
        // top-level JSON scalar, not an object or array.
        if s.hasPrefix("\""), s.hasSuffix("\""), s.count >= 2 {
            if let data = s.data(using: .utf8),
               let decoded = try? JSONSerialization.jsonObject(
                   with: data,
                   options: [.fragmentsAllowed]
               ) as? String {
                return decoded
            }
        }
        // Fallback to TxRep \xNN escape format.
        return try unescapeString(s)
    }

    // MARK: - Private helpers

    /// Extract an asset code string from raw fixed-size data, stripping trailing null bytes.
    private static func assetCodeFromData(_ data: Data) -> String {
        var bytes = Array(data)
        while let last = bytes.last, last == 0 {
            bytes.removeLast()
        }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }

    /// Convert an asset code string to null-padded 4-byte `AssetCode4XDR` (`WrappedData4`).
    private static func assetCodeToData4(_ code: String) -> AssetCode4XDR {
        var data = Data(count: 4)
        let encoded = Array(code.utf8)
        for i in 0..<min(encoded.count, 4) {
            data[i] = encoded[i]
        }
        return WrappedData4(data)
    }

    /// Convert an asset code string to null-padded 12-byte `AssetCode12XDR` (`WrappedData12`).
    private static func assetCodeToData12(_ code: String) -> AssetCode12XDR {
        var data = Data(count: 12)
        let encoded = Array(code.utf8)
        for i in 0..<min(encoded.count, 12) {
            data[i] = encoded[i]
        }
        return WrappedData12(data)
    }

    // MARK: - Required-field helpers (throw missingValue when absent)

    /// Require a hex-encoded binary field from the map.
    ///
    /// Throws `missingValue` when the key is absent. Re-throws any hex-decoding
    /// error as `invalidValue(key:)` using the **field key**, not the raw value
    /// string, so that error messages contain the TxRep field name.
    ///
    /// - Parameters:
    ///   - map: Key-value map from `parse(_:)`.
    ///   - key: The TxRep field key, e.g. `"signatures[0].hint"`.
    /// - Returns: Decoded binary `Data`.
    /// - Throws: `TxRepError.missingValue(key:)` / `TxRepError.invalidValue(key:)`.
    public static func requireHex(_ map: [String: String], _ key: String) throws -> Data {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try hexToBytes(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require a hex-encoded field and wrap the result in a `WrappedData4`.
    public static func requireWrappedData4(_ map: [String: String], _ key: String) throws -> WrappedData4 {
        return WrappedData4(try requireHex(map, key))
    }

    /// Require a hex-encoded field and wrap the result in a `WrappedData12`.
    public static func requireWrappedData12(_ map: [String: String], _ key: String) throws -> WrappedData12 {
        return WrappedData12(try requireHex(map, key))
    }

    /// Require a hex-encoded field and wrap the result in a `WrappedData32`.
    public static func requireWrappedData32(_ map: [String: String], _ key: String) throws -> WrappedData32 {
        return WrappedData32(try requireHex(map, key))
    }

    /// Require a quoted/escaped string field from the map.
    ///
    /// Throws `missingValue` when absent, `invalidValue` (with the field key) when
    /// the string cannot be unescaped.
    public static func requireString(_ map: [String: String], _ key: String) throws -> String {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try unescapeString(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require an `Int64` field from the map.
    public static func requireInt64(_ map: [String: String], _ key: String) throws -> Int64 {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try parseInt64(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require a `UInt64` field from the map.
    public static func requireUInt64(_ map: [String: String], _ key: String) throws -> UInt64 {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try parseUInt64(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require a `MuxedAccountXDR` field from the map.
    ///
    /// Throws `missingValue` when absent, `invalidValue(key: <field key>)` when invalid.
    public static func requireMuxedAccount(_ map: [String: String], _ key: String) throws -> MuxedAccountXDR {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try raw.decodeMuxedAccount()
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require a `PublicKey` (account ID) field from the map.
    public static func requireAccountId(_ map: [String: String], _ key: String) throws -> PublicKey {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try PublicKey(accountId: raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require an `AssetXDR` field from the map (compact single-line format).
    public static func requireAsset(_ map: [String: String], _ key: String) throws -> AssetXDR {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try parseAsset(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require a `SignerKeyXDR` field from the map.
    public static func requireSignerKey(_ map: [String: String], _ key: String) throws -> SignerKeyXDR {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try parseSignerKey(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require an `AllowTrustOpAssetXDR` field from the map.
    public static func requireAllowTrustAsset(_ map: [String: String], _ key: String) throws -> AllowTrustOpAssetXDR {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try parseAllowTrustAsset(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Require a liquidity pool ID field from the map, accepting either a 64-character
    /// lowercase hex string or an L-address StrKey (as used by SEP-0011 and the
    /// original hand-written TxRep serialiser).
    ///
    /// - Parameters:
    ///   - map: Key-value map from `parse(_:)`.
    ///   - key: The TxRep field key.
    /// - Returns: The liquidity pool ID as a `WrappedData32`.
    /// - Throws: `TxRepError.missingValue(key:)` if the key is absent,
    ///           `TxRepError.invalidValue(key:)` if the value is neither valid hex nor a valid L-address.
    public static func requireLiquidityPoolId(_ map: [String: String], _ key: String) throws -> WrappedData32 {
        guard let raw = getValue(map, key) else {
            throw TxRepError.missingValue(key: key)
        }
        do {
            return try parseLiquidityPoolId(raw)
        } catch {
            throw TxRepError.invalidValue(key: key)
        }
    }

    /// Parse a liquidity pool ID from a string, accepting either a 64-character
    /// hex string or an L-address StrKey.
    ///
    /// - Parameter value: Hex-64 or L-address StrKey string.
    /// - Returns: Decoded `WrappedData32`.
    /// - Throws: `TxRepError.invalidValue(key:)` if the value cannot be parsed.
    public static func parseLiquidityPoolId(_ value: String) throws -> WrappedData32 {
        if value.count == 64 && isAllHex(value) {
            guard let data = value.data(using: .hexadecimal), data.count == 32 else {
                throw TxRepError.invalidValue(key: value)
            }
            return WrappedData32(data)
        }
        if value.hasPrefix("L") {
            do {
                let data = try value.decodeLiquidityPoolId()
                guard data.count == 32 else {
                    throw TxRepError.invalidValue(key: value)
                }
                return WrappedData32(data)
            } catch {
                throw TxRepError.invalidValue(key: value)
            }
        }
        throw TxRepError.invalidValue(key: value)
    }

    // MARK: - Private helpers

    /// Returns `true` if every character in the string is a valid hexadecimal digit.
    private static func isAllHex(_ s: String) -> Bool {
        let validHex = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return s.unicodeScalars.allSatisfy { validHex.contains($0) }
    }

    /// Decode a single hex ASCII byte to its nibble value (0–15), or `nil` on failure.
    private static func hexNibble(_ byte: UInt8) -> UInt8? {
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return byte - UInt8(ascii: "0")
        case UInt8(ascii: "a")...UInt8(ascii: "f"):
            return byte - UInt8(ascii: "a") + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"):
            return byte - UInt8(ascii: "A") + 10
        default:
            return nil
        }
    }
}
