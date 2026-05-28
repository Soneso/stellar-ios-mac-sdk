//
//  WebAuthnCborParser.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Pure-Swift CBOR parsing utilities for WebAuthn attestation and authenticator data.
///
/// Consolidates byte-level CBOR parsing logic used by every WebAuthn provider implementation
/// (Apple, Android, browser). Has no platform dependencies.
///
/// Every method is resilient to malformed or truncated input — methods return `nil` instead of
/// throwing when data cannot be parsed, allowing callers to implement graceful fallback
/// strategies and to compose the byte-level primitives with higher-level extractors.
///
/// Authenticator data structure (WebAuthn specification):
/// ```
/// [0..31]      rpIdHash         (32 bytes, SHA-256 of the relying party ID)
/// [32]         flags            (1 byte, bit field)
/// [33..36]     signCount        (4 bytes, big-endian)
/// [37..52]     aaguid           (16 bytes, if AT flag set)
/// [53..54]     credentialIdLen  (2 bytes, big-endian uint16, if AT flag set)
/// [55..55+N-1] credentialId     (N bytes, if AT flag set)
/// [55+N..]     COSE public key  (variable, if AT flag set)
/// ```
///
/// Flag bits at offset 32 (relevant to this parser):
/// - Bit 6 (0x40): AT — Attested credential data included
/// - Bit 3 (0x08): BE — Backup Eligibility (multi-device credential)
/// - Bit 4 (0x10): BS — Backup State (currently backed up)
///
/// Visibility note: this enum has no `public` modifier and is therefore module-internal —
/// external SDK consumers cannot import it. The unit-test target reaches in via
/// `@testable import stellarsdk`. The higher-level smart-account public API exposes the
/// pubkey-extraction and authenticator-flag primitives via dedicated public facade types.
enum WebAuthnCborParser {

    /// Minimum length of valid authenticator data (rpIdHash + flags + signCount).
    static let authDataMinLength: Int = 37

    /// Byte offset of the flags field within authenticator data.
    static let flagsOffset: Int = 32

    /// Flag bit indicating Backup Eligibility (multi-device credential).
    static let flagBE: Int = 0x08

    /// Flag bit indicating Backup State (credential is currently backed up).
    static let flagBS: Int = 0x10

    /// Minimum size of the attested credential data header within authenticator data:
    /// rpIdHash (32) + flags (1) + signCount (4) + aaguid (16) + credentialIdLen (2) = 55.
    static let attestedCredDataHeaderSize: Int = 55

    /// Size in bytes of an uncompressed secp256r1 public key (`0x04` prefix + X + Y).
    static let uncompressedKeySize: Int = 65

    /// Uncompressed EC point prefix byte (SEC 1).
    static let uncompressedKeyPrefix: UInt8 = 0x04

    /// String constant for single-device credential type.
    static let deviceTypeSingle: String = "singleDevice"

    /// String constant for multi-device (cloud-synced) credential type.
    static let deviceTypeMulti: String = "multiDevice"

    /// CBOR-encoded key for the `"authData"` field in a WebAuthn attestation object map.
    ///
    /// Encoding: `0x68` (text string, length 8) followed by ASCII bytes for `"authData"`.
    /// Currently unused by this file's algorithm (the attestation iterator decodes keys via
    /// `readCborTextString` rather than pattern-matching this constant) — preserved verbatim
    /// so future pattern-matching strategies can reuse it without re-encoding.
    private static let authDataCborKey: [UInt8] = [
        0x68,
        0x61, 0x75, 0x74, 0x68, 0x44, 0x61, 0x74, 0x61
    ]

    /// 10-byte CBOR map prefix that begins an ES256 COSE key for secp256r1.
    ///
    /// Encodes the first four CBOR map entries:
    /// - 1 (kty): 2 (EC2)
    /// - 3 (alg): -7 (ES256)
    /// - -1 (crv): 1 (P-256)
    /// - -2 (x): bstr of length 32 (header only)
    private static let coseEs256KeyPrefix: [UInt8] = [
        0xA5, 0x01, 0x02, 0x03, 0x26,
        0x20, 0x01, 0x21, 0x58, 0x20
    ]

    /// Maximum nested depth that `skipCborValue` will recurse to before refusing to descend
    /// further. Prevents stack overflow on adversarially deep CBOR inputs.
    ///
    /// 64 is well above any realistic WebAuthn attestation nesting (typically 2-3 levels
    /// for `fmt`/`attStmt`/`authData` plus an inner attestation-statement map).
    private static let maxSkipDepth: Int = 64

    /// Parsed authenticator flags from WebAuthn authenticator data.
    ///
    /// `deviceType` is `singleDevice` if the credential is device-bound, `multiDevice` if it is
    /// eligible for cloud sync. Both fields are `nil` when the flags byte could not be read,
    /// indicating that device type and backup state are genuinely unknown.
    struct AuthenticatorFlags: Equatable, Sendable {

        /// `singleDevice` if BE bit clear, `multiDevice` if BE bit set, `nil` if unreadable.
        let deviceType: String?

        /// `true` if the BS bit is set (credential currently backed up to cloud), `false` if
        /// clear, `nil` if unreadable.
        let backedUp: Bool?

        /// Memberwise initializer.
        ///
        /// - Parameters:
        ///   - deviceType: `singleDevice` / `multiDevice` / `nil`.
        ///   - backedUp: backup state bit, `nil` when unreadable.
        init(deviceType: String?, backedUp: Bool?) {
            self.deviceType = deviceType
            self.backedUp = backedUp
        }
    }

    /// Extracts the raw authenticator data from a CBOR-encoded WebAuthn attestation object.
    ///
    /// A WebAuthn attestation object is a CBOR map with the following structure:
    /// ```
    /// {
    ///   "fmt":      text string (attestation format, e.g. "none", "packed")
    ///   "attStmt":  map        (attestation statement, may be empty)
    ///   "authData": bstr       (raw authenticator data bytes)
    /// }
    /// ```
    ///
    /// Iterates the CBOR map rather than pattern-matching at a fixed offset, because
    /// preceding entries (e.g., a non-empty attestation statement) may have variable
    /// length and shift the key offset.
    ///
    /// - Parameter attestationObject: Raw CBOR-encoded attestation object bytes.
    /// - Returns: Authenticator data bytes, or `nil` if the attestation object is malformed,
    ///   empty, not a CBOR map, or does not contain an `"authData"` key.
    static func extractAuthenticatorDataFromAttestation(_ attestationObject: Data) -> Data? {
        if attestationObject.isEmpty { return nil }

        var offset = 0
        let firstByte = Int(attestationObject[attestationObject.startIndex + offset])

        // Verify top-level CBOR type is a map (major type 5).
        let majorType = firstByte >> 5
        if majorType != 5 { return nil }

        let additionalInfo = firstByte & 0x1F
        let mapSize: Int

        if additionalInfo < 24 {
            mapSize = additionalInfo
            offset = 1
        } else if additionalInfo == 24 {
            if offset + 1 >= attestationObject.count { return nil }
            mapSize = Int(attestationObject[attestationObject.startIndex + offset + 1])
            offset = 2
        } else {
            // Maps with > 255 entries are not expected in attestation objects.
            return nil
        }

        // Iterate through map key-value pairs looking for "authData".
        for _ in 0..<mapSize {
            if offset >= attestationObject.count { return nil }

            guard let keyResult = readCborTextString(attestationObject, offset: offset) else {
                return nil
            }
            offset = keyResult.1

            if keyResult.0 == "authData" {
                guard let valueResult = readCborByteString(attestationObject, offset: offset) else {
                    return nil
                }
                return valueResult.0
            } else {
                guard let nextOffset = skipCborValue(attestationObject, offset: offset) else {
                    return nil
                }
                offset = nextOffset
            }
        }

        return nil
    }

    /// Extracts the uncompressed secp256r1 public key from a CBOR-encoded COSE key.
    ///
    /// A COSE key for ES256 (secp256r1) is a CBOR map. The relevant entries are:
    /// - Key label -2 (CBOR: `0x21`): X coordinate (32-byte bstr)
    /// - Key label -3 (CBOR: `0x22`): Y coordinate (32-byte bstr)
    ///
    /// CBOR encodes negative integers as `-(n+1)`, so -2 is encoded as major type 1, additional
    /// info 1 (byte `0x21`), and -3 as major type 1, additional info 2 (byte `0x22`).
    ///
    /// If the data does not begin with a CBOR map header, or if either coordinate cannot be
    /// found by map iteration, the method falls back to pattern matching using the well-known
    /// 10-byte ES256 COSE prefix to locate the key structure directly.
    ///
    /// - Parameter coseKeyData: Raw CBOR-encoded COSE key bytes, starting at the first byte of
    ///   the COSE map.
    /// - Returns: Uncompressed secp256r1 public key (65 bytes: `0x04 || X || Y`), or `nil`
    ///   when neither map iteration nor the pattern-matching fallback finds valid coordinates.
    static func extractPublicKeyFromCoseKey(_ coseKeyData: Data) -> Data? {
        if coseKeyData.isEmpty { return nil }

        let firstByte = Int(coseKeyData[coseKeyData.startIndex])
        let majorType = firstByte >> 5

        if majorType == 5 {
            if let result = extractCoseKeyByMapIteration(coseKeyData) {
                return result
            }
        }

        return extractPublicKeyByPattern(coseKeyData)
    }

    /// Iterates the CBOR map in `coseKeyData` to find key labels -2 (X) and -3 (Y) and
    /// assembles them into a 65-byte uncompressed key.
    ///
    /// - Parameter coseKeyData: Raw CBOR data beginning with a map header.
    /// - Returns: Uncompressed 65-byte public key, or `nil` if X or Y are missing, malformed,
    ///   or the map header is unparseable.
    private static func extractCoseKeyByMapIteration(_ coseKeyData: Data) -> Data? {
        let firstByte = Int(coseKeyData[coseKeyData.startIndex])
        let additionalInfo = firstByte & 0x1F

        let mapSize: Int
        var offset: Int

        if additionalInfo < 24 {
            mapSize = additionalInfo
            offset = 1
        } else if additionalInfo == 24 {
            if coseKeyData.count < 2 { return nil }
            mapSize = Int(coseKeyData[coseKeyData.startIndex + 1])
            offset = 2
        } else {
            return nil
        }

        var x: Data? = nil
        var y: Data? = nil

        for _ in 0..<mapSize {
            if offset >= coseKeyData.count { break }

            let keyByte = Int(coseKeyData[coseKeyData.startIndex + offset])
            let keyMajorType = keyByte >> 5
            let keyInfo = keyByte & 0x1F

            if keyMajorType == 1 && keyInfo == 1 {
                // CBOR negative integer 0x21 = -2 → X coordinate.
                offset += 1
                if let result = readCborByteString(coseKeyData, offset: offset) {
                    x = result.0
                    offset = result.1
                } else {
                    guard let nextOffset = skipCborValue(coseKeyData, offset: offset) else {
                        return nil
                    }
                    offset = nextOffset
                }
            } else if keyMajorType == 1 && keyInfo == 2 {
                // CBOR negative integer 0x22 = -3 → Y coordinate.
                offset += 1
                if let result = readCborByteString(coseKeyData, offset: offset) {
                    y = result.0
                    offset = result.1
                } else {
                    guard let nextOffset = skipCborValue(coseKeyData, offset: offset) else {
                        return nil
                    }
                    offset = nextOffset
                }
            } else {
                guard let afterHead = skipCborHead(coseKeyData, offset: offset) else { return nil }
                guard let afterValue = skipCborValue(coseKeyData, offset: afterHead) else { return nil }
                offset = afterValue
            }

            if x != nil && y != nil { break }
        }

        guard let xCoord = x, let yCoord = y else { return nil }
        if xCoord.count != 32 || yCoord.count != 32 { return nil }

        return buildUncompressedKey(x: xCoord, y: yCoord)
    }

    /// Pattern-matching fallback that searches for the 10-byte ES256 COSE key prefix and
    /// extracts X and Y coordinates from the fixed offsets that follow the prefix.
    ///
    /// Searches for the `coseEs256KeyPrefix` (10 bytes) anywhere in `data`. If found:
    /// - X is the 32 bytes immediately after the prefix.
    /// - Y is the 32 bytes starting 3 bytes after X (the 3 bytes are the CBOR-encoded
    ///   map key -3 followed by a 32-byte bstr header: `0x22 0x58 0x20`).
    ///
    /// - Parameter data: Byte array to search within.
    /// - Returns: Uncompressed 65-byte public key, or `nil` if the prefix is absent or there
    ///   is insufficient data following it.
    private static func extractPublicKeyByPattern(_ data: Data) -> Data? {
        let prefix = Data(Self.coseEs256KeyPrefix)
        let prefixIndex = findSubrange(haystack: data, needle: prefix)
        if prefixIndex < 0 { return nil }

        let xStart = prefixIndex + prefix.count
        let yStart = xStart + 32 + 3 // 3 bytes: CBOR key -3 (0x22) + bstr header (0x58 0x20).
        let requiredLength = yStart + 32

        if data.count < requiredLength { return nil }

        let base = data.startIndex
        let x = data.subdata(in: (base + xStart)..<(base + xStart + 32))
        let y = data.subdata(in: (base + yStart)..<(base + yStart + 32))

        return buildUncompressedKey(x: x, y: y)
    }

    /// Extracts an uncompressed secp256r1 public key from SubjectPublicKeyInfo (SPKI) bytes.
    ///
    /// The SPKI structure for a P-256 key (RFC 5480 / SEC 1) is:
    /// ```
    /// SEQUENCE {
    ///   SEQUENCE {
    ///     OID 1.2.840.10045.2.1   (id-ecPublicKey)
    ///     OID 1.2.840.10045.3.1.7 (secp256r1 / prime256v1)
    ///   }
    ///   BIT STRING { 0x04 || X (32 bytes) || Y (32 bytes) }
    /// }
    /// ```
    ///
    /// The total SPKI encoding is typically 91 bytes. The uncompressed public key (65 bytes)
    /// occupies the last 65 bytes of the structure and always starts with the `0x04`
    /// uncompressed-point prefix.
    ///
    /// Pure byte slicing: if `spkiBytes` is at least 65 bytes long and the byte at
    /// `count - 65` equals `0x04`, the last 65 bytes are returned.
    ///
    /// - Parameter spkiBytes: Raw SPKI/DER-encoded public key bytes.
    /// - Returns: Uncompressed 65-byte secp256r1 public key, or `nil` if the input is shorter
    ///   than 65 bytes or does not have the expected `0x04` prefix at the computed offset.
    static func extractPublicKeyFromSpki(_ spkiBytes: Data) -> Data? {
        if spkiBytes.count < uncompressedKeySize { return nil }

        let candidateStart = spkiBytes.count - uncompressedKeySize
        let base = spkiBytes.startIndex
        if spkiBytes[base + candidateStart] != uncompressedKeyPrefix { return nil }

        return spkiBytes.subdata(in: (base + candidateStart)..<(base + spkiBytes.count))
    }

    /// Parses the flags byte from raw authenticator data and extracts device type and backup
    /// state.
    ///
    /// The flags byte is at offset `flagsOffset` (32) within authenticator data. Two bits are
    /// relevant:
    /// - Bit 3 (`flagBE` = `0x08`): Backup Eligibility. When set, the credential is eligible
    ///   for cloud synchronisation across devices (`deviceType = deviceTypeMulti`). When
    ///   clear, the credential is bound to a single device (`deviceTypeSingle`).
    /// - Bit 4 (`flagBS` = `0x10`): Backup State. When set, the credential is currently
    ///   backed up or synced to a cloud provider.
    ///
    /// If `authenticatorData` is `nil` or shorter than `flagsOffset + 1` bytes, both
    /// `deviceType` and `backedUp` are `nil`, indicating that device type and backup state
    /// are genuinely unknown.
    ///
    /// - Parameter authenticatorData: Raw authenticator data bytes (directly from the
    ///   authenticator response, not CBOR-wrapped). May be `nil`.
    /// - Returns: Parsed `AuthenticatorFlags`. Fields are `nil` when the flags byte cannot
    ///   be read.
    static func parseAuthenticatorFlags(_ authenticatorData: Data?) -> AuthenticatorFlags {
        guard let data = authenticatorData, data.count > flagsOffset else {
            return AuthenticatorFlags(deviceType: nil, backedUp: nil)
        }

        let flags = Int(data[data.startIndex + flagsOffset])

        let deviceType = (flags & flagBE) != 0 ? deviceTypeMulti : deviceTypeSingle
        let backedUp = (flags & flagBS) != 0

        return AuthenticatorFlags(deviceType: deviceType, backedUp: backedUp)
    }

    /// Reads a CBOR byte string (major type 2) at the given offset.
    ///
    /// Supports byte strings with lengths encoded as:
    /// - 0 to 23 bytes (inline additional info)
    /// - 1-byte length prefix (additional info 24)
    /// - 2-byte big-endian length prefix (additional info 25)
    /// - 4-byte big-endian length prefix (additional info 26, with overflow guard)
    ///
    /// - Parameters:
    ///   - data: The CBOR-encoded byte array.
    ///   - offset: Byte offset of the CBOR byte string header.
    /// - Returns: A tuple `(decoded bytes, offset after the byte string)`, or `nil` if the
    ///   data is truncated, the major type is not 2, or a 4-byte length overflows
    ///   `Int.max`.
    static func readCborByteString(_ data: Data, offset: Int) -> (Data, Int)? {
        if offset >= data.count { return nil }

        let base = data.startIndex
        let firstByte = Int(data[base + offset])
        let majorType = firstByte >> 5

        if majorType != 2 { return nil }

        let additionalInfo = firstByte & 0x1F
        let length: Int
        let dataStart: Int

        if additionalInfo < 24 {
            length = additionalInfo
            dataStart = offset + 1
        } else if additionalInfo == 24 {
            if offset + 1 >= data.count { return nil }
            length = Int(data[base + offset + 1])
            dataStart = offset + 2
        } else if additionalInfo == 25 {
            if offset + 2 >= data.count { return nil }
            length = (Int(data[base + offset + 1]) << 8) | Int(data[base + offset + 2])
            dataStart = offset + 3
        } else if additionalInfo == 26 {
            if offset + 4 >= data.count { return nil }
            // Compose a 32-bit big-endian unsigned value into a UInt32 first to model
            // the on-the-wire encoding faithfully, then convert to Int with an explicit
            // overflow guard: rejects negative integers because the host signed an unsigned length (per CBOR RFC 8949).
            let raw: UInt32 =
                (UInt32(data[base + offset + 1]) << 24) |
                (UInt32(data[base + offset + 2]) << 16) |
                (UInt32(data[base + offset + 3]) << 8) |
                UInt32(data[base + offset + 4])
            // Only accept values that fit in a signed 32-bit positive range to reproduce
            // the reference parser's "negative Int = overflow" guard.
            if raw > UInt32(Int32.max) { return nil }
            length = Int(raw)
            dataStart = offset + 5
        } else {
            return nil
        }

        if dataStart + length > data.count { return nil }

        let bytes = data.subdata(in: (base + dataStart)..<(base + dataStart + length))
        return (bytes, dataStart + length)
    }

    /// Reads a CBOR text string (major type 3) at the given offset.
    ///
    /// Supports text strings with lengths encoded as:
    /// - 0 to 23 bytes (inline additional info)
    /// - 1-byte length prefix (additional info 24)
    /// - 2-byte big-endian length prefix (additional info 25)
    ///
    /// Bytes are decoded as UTF-8.
    ///
    /// - Parameters:
    ///   - data: The CBOR-encoded byte array.
    ///   - offset: Byte offset of the CBOR text string header.
    /// - Returns: A tuple `(decoded string, offset after the text string)`, or `nil` if the
    ///   data is truncated or the major type is not 3.
    static func readCborTextString(_ data: Data, offset: Int) -> (String, Int)? {
        if offset >= data.count { return nil }

        let base = data.startIndex
        let firstByte = Int(data[base + offset])
        let majorType = firstByte >> 5

        if majorType != 3 { return nil }

        let additionalInfo = firstByte & 0x1F
        let length: Int
        let dataStart: Int

        if additionalInfo < 24 {
            length = additionalInfo
            dataStart = offset + 1
        } else if additionalInfo == 24 {
            if offset + 1 >= data.count { return nil }
            length = Int(data[base + offset + 1])
            dataStart = offset + 2
        } else if additionalInfo == 25 {
            if offset + 2 >= data.count { return nil }
            length = (Int(data[base + offset + 1]) << 8) | Int(data[base + offset + 2])
            dataStart = offset + 3
        } else {
            return nil
        }

        if dataStart + length > data.count { return nil }

        let textBytes = data.subdata(in: (base + dataStart)..<(base + dataStart + length))
        guard let text = String(data: textBytes, encoding: .utf8) else { return nil }
        return (text, dataStart + length)
    }

    /// Reads the length value from a CBOR item head (applicable to major types 2, 3, 4, 5).
    ///
    /// Does not read the actual content — only the length field and the header bytes.
    ///
    /// Supports lengths encoded as:
    /// - Inline (0..23)
    /// - 1-byte (additional info 24)
    /// - 2-byte big-endian (additional info 25)
    /// - 4-byte big-endian (additional info 26, with overflow guard)
    ///
    /// - Parameters:
    ///   - data: The CBOR-encoded byte array.
    ///   - offset: Byte offset of the CBOR item head.
    /// - Returns: A tuple `(length value, offset after the head bytes)`, or `nil` if the data
    ///   is truncated or the additional info encodes an unsupported or overflowing length.
    static func readCborLength(_ data: Data, offset: Int) -> (Int, Int)? {
        if offset >= data.count { return nil }

        let base = data.startIndex
        let firstByte = Int(data[base + offset])
        let additionalInfo = firstByte & 0x1F

        if additionalInfo < 24 {
            return (additionalInfo, offset + 1)
        } else if additionalInfo == 24 {
            if offset + 1 >= data.count { return nil }
            return (Int(data[base + offset + 1]), offset + 2)
        } else if additionalInfo == 25 {
            if offset + 2 >= data.count { return nil }
            let length = (Int(data[base + offset + 1]) << 8) | Int(data[base + offset + 2])
            return (length, offset + 3)
        } else if additionalInfo == 26 {
            if offset + 4 >= data.count { return nil }
            let raw: UInt32 =
                (UInt32(data[base + offset + 1]) << 24) |
                (UInt32(data[base + offset + 2]) << 16) |
                (UInt32(data[base + offset + 3]) << 8) |
                UInt32(data[base + offset + 4])
            if raw > UInt32(Int32.max) { return nil }
            return (Int(raw), offset + 5)
        } else {
            return nil
        }
    }

    /// Skips a single CBOR value at the given offset and returns the offset of the next value.
    ///
    /// Handles all standard CBOR major types:
    /// - 0 (unsigned int): skip head only
    /// - 1 (negative int): skip head only
    /// - 2 (byte string): skip head + content
    /// - 3 (text string): skip head + content
    /// - 4 (array): skip head + N recursively skipped items
    /// - 5 (map): skip head + N recursively skipped key-value pairs
    /// - 6 (tag): skip tag head + 1 recursively skipped tagged value
    /// - 7 (float/simple): skip head only (1, 2, 3, 5, or 9 bytes depending on additional info)
    ///
    /// Bounded by an internal max-depth guard (`maxSkipDepth = 64`) to prevent stack overflow
    /// on adversarially nested inputs; depth exhaustion returns `nil` rather than crashing.
    ///
    /// - Parameters:
    ///   - data: The CBOR-encoded byte array.
    ///   - offset: Byte offset of the CBOR value to skip.
    /// - Returns: The byte offset immediately after the skipped value, or `nil` if the data is
    ///   truncated, an unsupported encoding is encountered, or the depth cap is hit.
    static func skipCborValue(_ data: Data, offset: Int) -> Int? {
        return skipCborValue(data, offset: offset, depth: 0)
    }

    /// Internal recursion-bounded implementation of `skipCborValue`.
    private static func skipCborValue(_ data: Data, offset: Int, depth: Int) -> Int? {
        if depth >= maxSkipDepth { return nil }
        if offset >= data.count { return nil }

        let base = data.startIndex
        let firstByte = Int(data[base + offset])
        let majorType = firstByte >> 5
        let additionalInfo = firstByte & 0x1F

        switch majorType {
        case 0, 1:
            return skipCborHead(data, offset: offset)
        case 2, 3:
            guard let lengthResult = readCborLength(data, offset: offset) else { return nil }
            let length = lengthResult.0
            let contentStart = lengthResult.1
            if contentStart + length > data.count { return nil }
            return contentStart + length
        case 4:
            guard let lengthResult = readCborLength(data, offset: offset) else { return nil }
            let count = lengthResult.0
            var pos = lengthResult.1
            for _ in 0..<count {
                guard let next = skipCborValue(data, offset: pos, depth: depth + 1) else { return nil }
                pos = next
            }
            return pos
        case 5:
            guard let lengthResult = readCborLength(data, offset: offset) else { return nil }
            let count = lengthResult.0
            var pos = lengthResult.1
            for _ in 0..<count {
                guard let afterKey = skipCborValue(data, offset: pos, depth: depth + 1) else { return nil }
                guard let afterValue = skipCborValue(data, offset: afterKey, depth: depth + 1) else { return nil }
                pos = afterValue
            }
            return pos
        case 6:
            guard let headEnd = skipCborHead(data, offset: offset) else { return nil }
            return skipCborValue(data, offset: headEnd, depth: depth + 1)
        case 7:
            switch additionalInfo {
            case 0...23: return offset + 1
            case 24: return offset + 1 < data.count ? offset + 2 : nil
            case 25: return offset + 2 < data.count ? offset + 3 : nil
            case 26: return offset + 4 < data.count ? offset + 5 : nil
            case 27: return offset + 8 < data.count ? offset + 9 : nil
            default: return nil
            }
        default:
            return nil
        }
    }

    /// Skips the initial byte (and any additional info bytes) of a CBOR item head.
    ///
    /// Advances past the type/length header without reading or skipping the content. Used for
    /// integer types (major types 0 and 1) where there is no subsequent content, and
    /// internally within `skipCborValue` for tags.
    ///
    /// - Parameters:
    ///   - data: The CBOR-encoded byte array.
    ///   - offset: Byte offset of the CBOR item head.
    /// - Returns: The byte offset immediately after the head, or `nil` if the data is
    ///   truncated.
    static func skipCborHead(_ data: Data, offset: Int) -> Int? {
        if offset >= data.count { return nil }

        let base = data.startIndex
        let firstByte = Int(data[base + offset])
        let additionalInfo = firstByte & 0x1F

        if additionalInfo < 24 { return offset + 1 }
        if additionalInfo == 24 { return offset + 1 < data.count ? offset + 2 : nil }
        if additionalInfo == 25 { return offset + 2 < data.count ? offset + 3 : nil }
        if additionalInfo == 26 { return offset + 4 < data.count ? offset + 5 : nil }
        if additionalInfo == 27 { return offset + 8 < data.count ? offset + 9 : nil }
        return nil
    }

    /// Constructs an uncompressed secp256r1 public key byte array from X and Y coordinates.
    ///
    /// - Parameters:
    ///   - x: 32-byte X coordinate.
    ///   - y: 32-byte Y coordinate.
    /// - Returns: 65-byte array `uncompressedKeyPrefix || x || y`.
    private static func buildUncompressedKey(x: Data, y: Data) -> Data {
        var publicKey = Data(count: uncompressedKeySize)
        publicKey[0] = uncompressedKeyPrefix
        publicKey.replaceSubrange(1..<33, with: x)
        publicKey.replaceSubrange(33..<65, with: y)
        return publicKey
    }

    /// Searches for the first occurrence of `needle` within `haystack`.
    ///
    /// Naive linear scan. WebAuthn attestation objects are small (typically a few hundred
    /// bytes), so the performance of a naive scan is acceptable.
    ///
    /// - Parameters:
    ///   - haystack: The byte array to search within.
    ///   - needle: The byte array to search for.
    /// - Returns: Index of the first occurrence of `needle` in `haystack`, or `-1` if not
    ///   found or `needle` is longer than `haystack`.
    private static func findSubrange(haystack: Data, needle: Data) -> Int {
        if needle.isEmpty || needle.count > haystack.count { return -1 }

        let hayBase = haystack.startIndex
        let needleBase = needle.startIndex
        let limit = haystack.count - needle.count

        outer: for i in 0...limit {
            for j in 0..<needle.count {
                if haystack[hayBase + i + j] != needle[needleBase + j] {
                    continue outer
                }
            }
            return i
        }
        return -1
    }
}
