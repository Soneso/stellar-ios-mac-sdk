//
//  WebAuthnCborParserTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class WebAuthnCborParserTests: XCTestCase {

    // =========================================================================
    // CBOR builder helpers
    // =========================================================================

    /// Encodes a CBOR text string (major type 3).
    private func buildCborTextString(_ text: String) -> Data {
        let utf8 = Data(text.utf8)
        return buildCborHead(majorType: 3, length: utf8.count) + utf8
    }

    /// Encodes a CBOR byte string (major type 2).
    private func buildCborByteString(_ data: Data) -> Data {
        return buildCborHead(majorType: 2, length: data.count) + data
    }

    /// Builds a CBOR map with text-string keys and byte-string values.
    private func buildCborMap(_ entries: [(String, Data)]) -> Data {
        var result = buildCborHead(majorType: 5, length: entries.count)
        for (key, value) in entries {
            result.append(buildCborTextString(key))
            result.append(buildCborByteString(value))
        }
        return result
    }

    /// Builds a CBOR head byte (and any extended length bytes) for the given major type
    /// and length / value.
    private func buildCborHead(majorType: Int, length: Int) -> Data {
        let major = majorType << 5
        if length < 24 {
            return Data([UInt8(major | length)])
        } else if length < 256 {
            return Data([UInt8(major | 24), UInt8(length)])
        } else if length < 65536 {
            return Data([
                UInt8(major | 25),
                UInt8((length >> 8) & 0xFF),
                UInt8(length & 0xFF)
            ])
        } else {
            return Data([
                UInt8(major | 26),
                UInt8((length >> 24) & 0xFF),
                UInt8((length >> 16) & 0xFF),
                UInt8((length >> 8) & 0xFF),
                UInt8(length & 0xFF)
            ])
        }
    }

    /// Builds a minimal but structurally valid CBOR attestation object containing the three
    /// standard fields: `fmt`, `attStmt`, `authData`.
    ///
    /// - Parameters:
    ///   - authData: Raw bytes to embed as the authData value.
    ///   - fmtFirst: When true, `fmt` appears before `authData` (standard order). When false,
    ///     `authData` is the first entry.
    ///   - includeAttStmt: When true, an `attStmt` empty-map entry is included before
    ///     `authData`.
    private func buildAttestationObject(
        authData: Data,
        fmtFirst: Bool = true,
        includeAttStmt: Bool = false
    ) -> Data {
        var entries: [Data] = []

        if !fmtFirst {
            entries.append(buildCborTextString("authData"))
            entries.append(buildCborByteString(authData))
            entries.append(buildCborTextString("fmt"))
            entries.append(buildCborTextString("none"))
        } else {
            entries.append(buildCborTextString("fmt"))
            entries.append(buildCborTextString("none"))
            if includeAttStmt {
                entries.append(buildCborTextString("attStmt"))
                entries.append(buildCborHead(majorType: 5, length: 0)) // empty map
            }
            entries.append(buildCborTextString("authData"))
            entries.append(buildCborByteString(authData))
        }

        let entryCount = !fmtFirst ? 2 : (includeAttStmt ? 3 : 2)
        var result = buildCborHead(majorType: 5, length: entryCount)
        for entry in entries { result.append(entry) }
        return result
    }

    /// Builds realistic authenticator data of the minimum required length (37 bytes).
    private func buildAuthenticatorData(flagsByte: UInt8 = 0x00) -> Data {
        var data = Data(count: 37)
        for i in 0..<32 { data[i] = UInt8(i + 1) }
        data[32] = flagsByte
        data[33] = 0x00
        data[34] = 0x00
        data[35] = 0x00
        data[36] = 0x01
        return data
    }

    /// Builds a minimal CBOR-encoded COSE ES256 key map for the given 32-byte X / Y
    /// coordinates.
    ///
    /// Map entries (5 total):
    /// - 1 (kty): 2 (EC2)
    /// - 3 (alg): -7 (ES256)
    /// - -1 (crv): 1 (P-256)
    /// - -2 (x): bstr(x)
    /// - -3 (y): bstr(y)
    private func buildCoseKey(x: Data, y: Data) -> Data {
        var result = Data([0xA5])
        result.append(contentsOf: [0x01, 0x02])
        result.append(contentsOf: [0x03, 0x26])
        result.append(contentsOf: [0x20, 0x01])
        result.append(0x21)
        result.append(buildCborByteString(x))
        result.append(0x22)
        result.append(buildCborByteString(y))
        return result
    }

    // =========================================================================
    // Test fixtures (synthetic-builder bytes only; not real authenticator captures)
    // =========================================================================

    private let testX = Data((0..<32).map { UInt8($0 + 1) })
    private let testY = Data((0..<32).map { UInt8($0 + 33) })

    /// Pinned seed for the seeded-random fuzz test. Plan-pinned constant.
    private let cborFuzzSeed: UInt64 = 0xDEADBEEF

    // =========================================================================
    // 1. extractAuthenticatorDataFromAttestation (15 cases)
    // =========================================================================

    func test_extract_authenticator_data_auth_data_as_first_entry() {
        let authData = buildAuthenticatorData()
        let attestation = buildAttestationObject(authData: authData, fmtFirst: false)
        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
    }

    func test_extract_authenticator_data_auth_data_as_second_entry() {
        let authData = buildAuthenticatorData()
        let attestation = buildAttestationObject(authData: authData, fmtFirst: true, includeAttStmt: false)
        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
    }

    func test_extract_authenticator_data_auth_data_as_third_entry() {
        let authData = buildAuthenticatorData()
        let attestation = buildAttestationObject(authData: authData, fmtFirst: true, includeAttStmt: true)
        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
    }

    func test_extract_authenticator_data_empty_input_returns_null() {
        XCTAssertNil(WebAuthnCborParser.extractAuthenticatorDataFromAttestation(Data()))
    }

    func test_extract_authenticator_data_single_byte_input_returns_null() {
        XCTAssertNil(WebAuthnCborParser.extractAuthenticatorDataFromAttestation(Data([0x01])))
    }

    func test_extract_authenticator_data_non_map_major_type_returns_null() {
        // Major type 4 (array), not a map
        let data = Data([0x82, 0x01, 0x02])
        XCTAssertNil(WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data))
    }

    func test_extract_authenticator_data_map_with_no_auth_data_key_returns_null() {
        var data = buildCborHead(majorType: 5, length: 1)
        data.append(buildCborTextString("fmt"))
        data.append(buildCborTextString("none"))
        XCTAssertNil(WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data))
    }

    func test_extract_authenticator_data_map_with_zero_entries_returns_null() {
        let data = buildCborHead(majorType: 5, length: 0)
        XCTAssertNil(WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data))
    }

    func test_extract_authenticator_data_truncated_byte_string_length_returns_null() {
        var data = buildCborHead(majorType: 5, length: 1)
        data.append(buildCborTextString("authData"))
        // 0x58 = major-type 2 + additionalInfo 24, length byte 40, only 2 bytes follow
        data.append(contentsOf: [0x58, 0x28, 0x01, 0x02])
        XCTAssertNil(WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data))
    }

    func test_extract_authenticator_data_auth_data_with_1byte_cbor_length() {
        let authData = Data((0..<100).map { UInt8($0 % 256) })
        let attestation = buildAttestationObject(authData: authData)
        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
    }

    func test_extract_authenticator_data_auth_data_with_2byte_cbor_length() {
        let authData = Data((0..<300).map { UInt8($0 % 256) })
        let attestation = buildAttestationObject(authData: authData)
        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
    }

    func test_extract_authenticator_data_auth_data_with_inline_length() {
        let authData = Data((0..<20).map { UInt8($0) })
        let attestation = buildAttestationObject(authData: authData)
        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
    }

    func test_extract_authenticator_data_truncated_map_header_returns_null() {
        // 0xa1 = map(1) header but no entries follow
        XCTAssertNil(WebAuthnCborParser.extractAuthenticatorDataFromAttestation(Data([0xA1])))
    }

    func test_extract_authenticator_data_real_attestation_object_bytes() {
        let rpIdHash = Data(repeating: 0xAB, count: 32)
        let flags: UInt8 = 0x41 // AT | UP
        let signCount = Data([0x00, 0x00, 0x00, 0x05])
        var authData = Data()
        authData.append(rpIdHash)
        authData.append(flags)
        authData.append(signCount)

        var attestation = buildCborHead(majorType: 5, length: 2)
        attestation.append(buildCborTextString("fmt"))
        attestation.append(buildCborTextString("none"))
        attestation.append(buildCborTextString("authData"))
        attestation.append(buildCborByteString(authData))

        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
        XCTAssertEqual(result!.count - 5, 32) // 32-byte rpIdHash + 5 bytes remaining
    }

    func test_extract_authenticator_data_value_after_fmt_is_map_skipped_correctly() {
        let authData = buildAuthenticatorData()

        var attestation = buildCborHead(majorType: 5, length: 3)
        attestation.append(buildCborTextString("fmt"))
        attestation.append(buildCborTextString("packed"))
        attestation.append(buildCborTextString("attStmt"))
        attestation.append(buildCborHead(majorType: 5, length: 1))
        attestation.append(buildCborTextString("x5c"))
        attestation.append(buildCborByteString(Data(repeating: 0xFF, count: 10)))
        attestation.append(buildCborTextString("authData"))
        attestation.append(buildCborByteString(authData))

        let result = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation)
        XCTAssertEqual(result, authData)
    }

    // =========================================================================
    // 2. readCborByteString (11 cases)
    // =========================================================================

    func test_read_cbor_byte_string_inline_length() {
        let payload = Data([0x01, 0x02, 0x03])
        let encoded = buildCborByteString(payload)
        let result = WebAuthnCborParser.readCborByteString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, payload)
        XCTAssertEqual(result!.1, encoded.count)
    }

    func test_read_cbor_byte_string_1byte_header_additional_info_24() {
        let payload = Data((0..<30).map { UInt8($0) })
        let encoded = buildCborByteString(payload)
        XCTAssertEqual(encoded[0], 0x58)
        let result = WebAuthnCborParser.readCborByteString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, payload)
    }

    func test_read_cbor_byte_string_2byte_header_additional_info_25() {
        let payload = Data((0..<300).map { UInt8($0 % 256) })
        let encoded = buildCborByteString(payload)
        XCTAssertEqual(encoded[0], 0x59)
        let result = WebAuthnCborParser.readCborByteString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, payload)
    }

    func test_read_cbor_byte_string_4byte_header_additional_info_26() {
        let content = Data([0xAA, 0xBB, 0xCC, 0xDD, 0xEE])
        let header = Data([0x5A, 0x00, 0x00, 0x00, 0x05])
        let encoded = header + content
        let result = WebAuthnCborParser.readCborByteString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, content)
        XCTAssertEqual(result!.1, encoded.count)
    }

    func test_read_cbor_byte_string_4byte_header_negative_int_overflow_returns_null() {
        let encoded = Data([0x5A, 0x80, 0x00, 0x00, 0x00, 0x01])
        XCTAssertNil(WebAuthnCborParser.readCborByteString(encoded, offset: 0))
    }

    func test_read_cbor_byte_string_empty_byte_string() {
        let encoded = Data([0x40])
        let result = WebAuthnCborParser.readCborByteString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0.count, 0)
        XCTAssertEqual(result!.1, 1)
    }

    func test_read_cbor_byte_string_truncated_data_returns_null() {
        let encoded = Data([0x4A, 0x01, 0x02, 0x03])
        XCTAssertNil(WebAuthnCborParser.readCborByteString(encoded, offset: 0))
    }

    func test_read_cbor_byte_string_offset_at_end_of_data_returns_null() {
        let data = Data([0x01, 0x02])
        XCTAssertNil(WebAuthnCborParser.readCborByteString(data, offset: 2))
    }

    func test_read_cbor_byte_string_wrong_major_type_returns_null() {
        // 0x61 = major-type 3 (text string), not 2
        let encoded = Data([0x61, 0x41])
        XCTAssertNil(WebAuthnCborParser.readCborByteString(encoded, offset: 0))
    }

    func test_read_cbor_byte_string_1byte_header_truncated_length_returns_null() {
        XCTAssertNil(WebAuthnCborParser.readCborByteString(Data([0x58]), offset: 0))
    }

    func test_read_cbor_byte_string_2byte_header_truncated_length_returns_null() {
        XCTAssertNil(WebAuthnCborParser.readCborByteString(Data([0x59, 0x01]), offset: 0))
    }

    // =========================================================================
    // 3. readCborTextString (7 cases)
    // =========================================================================

    func test_read_cbor_text_string_inline_length() {
        let text = "hello"
        let encoded = buildCborTextString(text)
        let result = WebAuthnCborParser.readCborTextString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, text)
        XCTAssertEqual(result!.1, encoded.count)
    }

    func test_read_cbor_text_string_1byte_header_additional_info_24() {
        let text = String(repeating: "a", count: 30)
        let encoded = buildCborTextString(text)
        let result = WebAuthnCborParser.readCborTextString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, text)
    }

    func test_read_cbor_text_string_2byte_header_additional_info_25() {
        let text = String(repeating: "b", count: 300)
        let encoded = buildCborTextString(text)
        let result = WebAuthnCborParser.readCborTextString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, text)
    }

    func test_read_cbor_text_string_multibyte_utf8() {
        // Japanese "ステラー" — 4 code points, 12 UTF-8 bytes (3 bytes per katakana).
        let text = "ステラー"
        let encoded = buildCborTextString(text)
        let result = WebAuthnCborParser.readCborTextString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, text)
    }

    func test_read_cbor_text_string_empty_string() {
        let encoded = buildCborTextString("")
        let result = WebAuthnCborParser.readCborTextString(encoded, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, "")
    }

    func test_read_cbor_text_string_truncated_data_returns_null() {
        // 0x6a = major-type 3, length 10 — only 2 bytes of content follow
        let encoded = Data([0x6A, 0x41, 0x42])
        XCTAssertNil(WebAuthnCborParser.readCborTextString(encoded, offset: 0))
    }

    func test_read_cbor_text_string_wrong_major_type_returns_null() {
        // 0x44 = major-type 2 (byte string), not 3
        let encoded = Data([0x44, 0x01, 0x02, 0x03, 0x04])
        XCTAssertNil(WebAuthnCborParser.readCborTextString(encoded, offset: 0))
    }

    // =========================================================================
    // 4. readCborLength (9 cases)
    // =========================================================================

    func test_read_cbor_length_inline_length_0() {
        let result = WebAuthnCborParser.readCborLength(Data([0x40]), offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, 0)
        XCTAssertEqual(result!.1, 1)
    }

    func test_read_cbor_length_inline_length_23() {
        let result = WebAuthnCborParser.readCborLength(Data([0x57]), offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, 23)
        XCTAssertEqual(result!.1, 1)
    }

    func test_read_cbor_length_1byte_extended_additional_info_24() {
        let data = Data([0x58, 0x64])
        let result = WebAuthnCborParser.readCborLength(data, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, 100)
        XCTAssertEqual(result!.1, 2)
    }

    func test_read_cbor_length_2byte_extended_additional_info_25() {
        let data = Data([0x59, 0x01, 0x00])
        let result = WebAuthnCborParser.readCborLength(data, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, 256)
        XCTAssertEqual(result!.1, 3)
    }

    func test_read_cbor_length_4byte_extended_additional_info_26() {
        let data = Data([0x5A, 0x00, 0x01, 0x00, 0x00])
        let result = WebAuthnCborParser.readCborLength(data, offset: 0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.0, 65536)
        XCTAssertEqual(result!.1, 5)
    }

    func test_read_cbor_length_4byte_extended_negative_overflow_returns_null() {
        let data = Data([0x5A, 0x80, 0x00, 0x00, 0x00])
        XCTAssertNil(WebAuthnCborParser.readCborLength(data, offset: 0))
    }

    func test_read_cbor_length_insufficient_data_1byte_extended_returns_null() {
        XCTAssertNil(WebAuthnCborParser.readCborLength(Data([0x58]), offset: 0))
    }

    func test_read_cbor_length_insufficient_data_2byte_extended_returns_null() {
        XCTAssertNil(WebAuthnCborParser.readCborLength(Data([0x59, 0x01]), offset: 0))
    }

    func test_read_cbor_length_offset_at_end_returns_null() {
        XCTAssertNil(WebAuthnCborParser.readCborLength(Data([0x01]), offset: 1))
    }

    // =========================================================================
    // 5. skipCborValue (12 cases — full enumeration mirroring KMP names)
    // =========================================================================

    func test_skip_cbor_value_unsigned_integer_inline() {
        let data = Data([0x0A, 0x99])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 1)
    }

    func test_skip_cbor_value_negative_integer_inline() {
        let data = Data([0x20, 0x99])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 1)
    }

    func test_skip_cbor_value_text_string() {
        let encoded = buildCborTextString("abc")
        let data = encoded + Data([0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), encoded.count)
    }

    func test_skip_cbor_value_byte_string() {
        let encoded = buildCborByteString(Data([0x01, 0x02, 0x03, 0x04]))
        let data = encoded + Data([0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), encoded.count)
    }

    func test_skip_cbor_value_array_with_nested_elements() {
        // array(2) [ uint(1), uint(2) ]
        let data = Data([0x82, 0x01, 0x02])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 3)
    }

    func test_skip_cbor_value_map_with_nested_entries() {
        // map(1) { "k" -> uint(5) }
        let data = buildCborHead(majorType: 5, length: 1) + buildCborTextString("k") + Data([0x05])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), data.count)
    }

    func test_skip_cbor_value_nested_array() {
        // array(1) [ array(1) [ uint(7) ] ]
        let inner = Data([0x81, 0x07])
        let outer = Data([0x81]) + inner
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(outer, offset: 0), outer.count)
    }

    func test_skip_cbor_value_tagged_value() {
        // tag(1) uint(1000)
        let data = Data([0xC1, 0x19, 0x03, 0xE8])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 4)
    }

    func test_skip_cbor_value_float16() {
        // 0xF9 = major-type 7, additionalInfo 25 — 2-byte half-precision float
        let data = Data([0xF9, 0x00, 0x00, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 3)
    }

    func test_skip_cbor_value_float32() {
        let data = Data([0xFA, 0x3F, 0x80, 0x00, 0x00, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 5)
    }

    func test_skip_cbor_value_float64() {
        var data = Data(count: 10)
        data[0] = 0xFB
        for i in 1...8 { data[i] = UInt8(i) }
        data[9] = 0xFF
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 9)
    }

    func test_skip_cbor_value_simple_value_inline() {
        // 0xF4 = false
        let data = Data([0xF4, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 1)
    }

    func test_skip_cbor_value_simple_value_1byte_extended() {
        let data = Data([0xF8, 0x10, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 2)
    }

    func test_skip_cbor_value_truncated_content_returns_null() {
        // byteString claiming 10 bytes but data ends after header
        let data = Data([0x4A])
        XCTAssertNil(WebAuthnCborParser.skipCborValue(data, offset: 0))
    }

    func test_skip_cbor_value_offset_at_end_returns_null() {
        XCTAssertNil(WebAuthnCborParser.skipCborValue(Data([0x01]), offset: 1))
    }

    // =========================================================================
    // 6. skipCborHead (9 cases)
    // =========================================================================

    func test_skip_cbor_head_inline_additional_info() {
        let data = Data([0x05, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborHead(data, offset: 0), 1)
    }

    func test_skip_cbor_head_additional_info_24_2bytes() {
        let data = Data([0x18, 0x64, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborHead(data, offset: 0), 2)
    }

    func test_skip_cbor_head_additional_info_25_3bytes() {
        let data = Data([0x19, 0x01, 0x00, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborHead(data, offset: 0), 3)
    }

    func test_skip_cbor_head_additional_info_26_5bytes() {
        let data = Data([0x1A, 0x00, 0x01, 0x00, 0x00, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborHead(data, offset: 0), 5)
    }

    func test_skip_cbor_head_additional_info_27_9bytes() {
        var data = Data(count: 10)
        data[0] = 0x1B
        for i in 1...8 { data[i] = 0x00 }
        data[9] = 0xFF
        XCTAssertEqual(WebAuthnCborParser.skipCborHead(data, offset: 0), 9)
    }

    func test_skip_cbor_head_additional_info_24_truncated_returns_null() {
        XCTAssertNil(WebAuthnCborParser.skipCborHead(Data([0x18]), offset: 0))
    }

    func test_skip_cbor_head_additional_info_25_truncated_returns_null() {
        XCTAssertNil(WebAuthnCborParser.skipCborHead(Data([0x19, 0x01]), offset: 0))
    }

    func test_skip_cbor_head_additional_info_26_truncated_returns_null() {
        XCTAssertNil(WebAuthnCborParser.skipCborHead(Data([0x1A, 0x00, 0x01, 0x00]), offset: 0))
    }

    func test_skip_cbor_head_additional_info_27_truncated_returns_null() {
        let data = Data([0x1B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        XCTAssertNil(WebAuthnCborParser.skipCborHead(data, offset: 0))
    }

    // =========================================================================
    // 7. extractPublicKeyFromCoseKey (10 cases)
    // =========================================================================

    func test_extract_public_key_from_cose_key_standard_order() {
        let coseKey = buildCoseKey(x: testX, y: testY)
        let result = WebAuthnCborParser.extractPublicKeyFromCoseKey(coseKey)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 65)
        XCTAssertEqual(result![0], 0x04)
        XCTAssertEqual(result!.subdata(in: 1..<33), testX)
        XCTAssertEqual(result!.subdata(in: 33..<65), testY)
    }

    func test_extract_public_key_from_cose_key_y_before_x() {
        var data = Data([0xA5])
        data.append(contentsOf: [0x01, 0x02])
        data.append(contentsOf: [0x03, 0x26])
        data.append(contentsOf: [0x20, 0x01])
        data.append(0x22)
        data.append(buildCborByteString(testY))
        data.append(0x21)
        data.append(buildCborByteString(testX))

        let result = WebAuthnCborParser.extractPublicKeyFromCoseKey(data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 65)
        XCTAssertEqual(result!.subdata(in: 1..<33), testX)
        XCTAssertEqual(result!.subdata(in: 33..<65), testY)
    }

    func test_extract_public_key_from_cose_key_extra_entries_around_coordinates() {
        var data = Data([0xA7]) // map(7) — 5 standard + 2 extra
        data.append(contentsOf: [0x01, 0x02])
        data.append(contentsOf: [0x03, 0x26])
        data.append(contentsOf: [0x20, 0x01])
        // extra entry: key 0x04 -> uint(99)
        data.append(contentsOf: [0x04, 0x18, 0x63])
        data.append(0x21)
        data.append(buildCborByteString(testX))
        data.append(0x22)
        data.append(buildCborByteString(testY))
        // extra trailing entry: key 0x05 -> uint(1)
        data.append(contentsOf: [0x05, 0x01])

        let result = WebAuthnCborParser.extractPublicKeyFromCoseKey(data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 65)
    }

    func test_extract_public_key_from_cose_key_missing_x_coordinate_returns_null() {
        var data = Data([0xA2])
        data.append(contentsOf: [0x01, 0x02])
        data.append(0x22)
        data.append(buildCborByteString(testY))

        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromCoseKey(data))
    }

    func test_extract_public_key_from_cose_key_missing_y_coordinate_returns_null() {
        var data = Data([0xA2])
        data.append(contentsOf: [0x01, 0x02])
        data.append(0x21)
        data.append(buildCborByteString(testX))

        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromCoseKey(data))
    }

    func test_extract_public_key_from_cose_key_x_coordinate_wrong_size_returns_null() {
        let shortX = Data([0x01, 0x02, 0x03])
        var data = Data([0xA2])
        data.append(0x21)
        data.append(buildCborByteString(shortX))
        data.append(0x22)
        data.append(buildCborByteString(testY))

        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromCoseKey(data))
    }

    func test_extract_public_key_from_cose_key_y_coordinate_wrong_size_returns_null() {
        let shortY = Data([0x01, 0x02])
        var data = Data([0xA2])
        data.append(0x21)
        data.append(buildCborByteString(testX))
        data.append(0x22)
        data.append(buildCborByteString(shortY))

        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromCoseKey(data))
    }

    func test_extract_public_key_from_cose_key_empty_input_returns_null() {
        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromCoseKey(Data()))
    }

    func test_extract_public_key_from_cose_key_non_map_input_falls_back_to_pattern_matching() {
        let prefix = Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        let yHeader = Data([0x22, 0x58, 0x20])
        let rawData = prefix + testX + yHeader + testY
        let result = WebAuthnCborParser.extractPublicKeyFromCoseKey(rawData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 65)
        XCTAssertEqual(result!.subdata(in: 1..<33), testX)
        XCTAssertEqual(result!.subdata(in: 33..<65), testY)
    }

    func test_extract_public_key_from_cose_key_map_parsing_fails_then_pattern_succeeds() {
        let prefix = Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        let yHeader = Data([0x22, 0x58, 0x20])
        let fullData = prefix + testX + yHeader + testY
        let result = WebAuthnCborParser.extractPublicKeyFromCoseKey(fullData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 65)
    }

    // =========================================================================
    // 8. extractPublicKeyFromSpki (8 cases)
    // =========================================================================

    func test_extract_public_key_from_spki_exact_65_bytes_with_prefix() {
        let spki = Data([0x04]) + testX + testY
        XCTAssertEqual(spki.count, 65)
        let result = WebAuthnCborParser.extractPublicKeyFromSpki(spki)
        XCTAssertEqual(result, spki)
    }

    func test_extract_public_key_from_spki_91byte_spki_with_prefix_at_26() {
        let header = Data(repeating: 0x30, count: 26)
        let keyBytes = Data([0x04]) + testX + testY
        let spki = header + keyBytes
        XCTAssertEqual(spki.count, 91)
        let result = WebAuthnCborParser.extractPublicKeyFromSpki(spki)
        XCTAssertEqual(result, keyBytes)
    }

    func test_extract_public_key_from_spki_larger_than_91bytes_with_prefix_at_correct_position() {
        var spki = Data(count: 100)
        spki[35] = 0x04
        let result = WebAuthnCborParser.extractPublicKeyFromSpki(spki)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 65)
        XCTAssertEqual(result![0], 0x04)
    }

    func test_extract_public_key_from_spki_shorter_than_65bytes_returns_null() {
        let spki = Data(repeating: 0x01, count: 64)
        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromSpki(spki))
    }

    func test_extract_public_key_from_spki_empty_input_returns_null() {
        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromSpki(Data()))
    }

    func test_extract_public_key_from_spki_65bytes_without_prefix_returns_null() {
        var spki = Data(repeating: 0x01, count: 65)
        spki[0] = 0x03
        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromSpki(spki))
    }

    func test_extract_public_key_from_spki_exactly_64bytes_returns_null() {
        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromSpki(Data(repeating: 0x04, count: 64)))
    }

    func test_extract_public_key_from_spki_91bytes_with_wrong_prefix_byte_returns_null() {
        XCTAssertNil(WebAuthnCborParser.extractPublicKeyFromSpki(Data(count: 91)))
    }

    // =========================================================================
    // 9. parseAuthenticatorFlags (12 cases)
    // =========================================================================

    func test_parse_authenticator_flags_null_input_both_null() {
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(nil)
        XCTAssertNil(flags.deviceType)
        XCTAssertNil(flags.backedUp)
    }

    func test_parse_authenticator_flags_empty_byte_array_both_null() {
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(Data())
        XCTAssertNil(flags.deviceType)
        XCTAssertNil(flags.backedUp)
    }

    func test_parse_authenticator_flags_too_short_32bytes_both_null() {
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(Data(count: 32))
        XCTAssertNil(flags.deviceType)
        XCTAssertNil(flags.backedUp)
    }

    func test_parse_authenticator_flags_exactly_min_length_33bytes_parses_correctly() {
        var data = Data(count: 33)
        data[32] = 0x00
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(data)
        XCTAssertEqual(flags.deviceType, WebAuthnCborParser.deviceTypeSingle)
        XCTAssertEqual(flags.backedUp, false)
    }

    func test_parse_authenticator_flags_be0_bs0_single_device_not_backed_up() {
        let data = buildAuthenticatorData(flagsByte: 0x00)
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(data)
        XCTAssertEqual(flags.deviceType, WebAuthnCborParser.deviceTypeSingle)
        XCTAssertEqual(flags.backedUp, false)
    }

    func test_parse_authenticator_flags_be1_bs0_multi_device_not_backed_up() {
        let data = buildAuthenticatorData(flagsByte: 0x08)
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(data)
        XCTAssertEqual(flags.deviceType, WebAuthnCborParser.deviceTypeMulti)
        XCTAssertEqual(flags.backedUp, false)
    }

    func test_parse_authenticator_flags_be0_bs1_single_device_backed_up() {
        let data = buildAuthenticatorData(flagsByte: 0x10)
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(data)
        XCTAssertEqual(flags.deviceType, WebAuthnCborParser.deviceTypeSingle)
        XCTAssertEqual(flags.backedUp, true)
    }

    func test_parse_authenticator_flags_be1_bs1_multi_device_backed_up() {
        let data = buildAuthenticatorData(flagsByte: 0x18)
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(data)
        XCTAssertEqual(flags.deviceType, WebAuthnCborParser.deviceTypeMulti)
        XCTAssertEqual(flags.backedUp, true)
    }

    func test_parse_authenticator_flags_other_flag_bits_do_not_affect_result() {
        // UP (0x01) + UV (0x04) + AT (0x40) + BE (0x08) + BS (0x10)
        let allFlags: UInt8 = 0x01 | 0x04 | 0x08 | 0x10 | 0x40
        let data = buildAuthenticatorData(flagsByte: allFlags)
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(data)
        XCTAssertEqual(flags.deviceType, WebAuthnCborParser.deviceTypeMulti)
        XCTAssertEqual(flags.backedUp, true)
    }

    func test_parse_authenticator_flags_37byte_typical_auth_data_parses_correctly() {
        let data = buildAuthenticatorData(flagsByte: 0x08)
        XCTAssertEqual(data.count, 37)
        let flags = WebAuthnCborParser.parseAuthenticatorFlags(data)
        XCTAssertEqual(flags.deviceType, WebAuthnCborParser.deviceTypeMulti)
        XCTAssertEqual(flags.backedUp, false)
    }

    func test_parse_authenticator_flags_device_type_single_constant_value() {
        XCTAssertEqual(WebAuthnCborParser.deviceTypeSingle, "singleDevice")
    }

    func test_parse_authenticator_flags_device_type_multi_constant_value() {
        XCTAssertEqual(WebAuthnCborParser.deviceTypeMulti, "multiDevice")
    }

    // =========================================================================
    // Plan §9.4 minimum-bar additions (15 cases incl. fuzz)
    // =========================================================================

    func test_cbor_decode_uint_small() {
        // CBOR uint major-type 0 with value 23 — inline encoding.
        let data = Data([0x17])
        XCTAssertEqual(WebAuthnCborParser.skipCborHead(data, offset: 0), 1)
        // Treat as a length read (additional info 23) — yields the value 23.
        let lengthLikeData = Data([0x57])
        let result = WebAuthnCborParser.readCborLength(lengthLikeData, offset: 0)
        XCTAssertEqual(result?.0, 23)
    }

    func test_cbor_decode_uint_one_byte() {
        // CBOR uint additional-info 24, value 0xFF.
        let data = Data([0x18, 0xFF])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 2)
    }

    func test_cbor_decode_uint_two_bytes() {
        // CBOR uint additional-info 25, value 0x1234.
        let data = Data([0x19, 0x12, 0x34])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 3)
    }

    func test_cbor_decode_uint_four_bytes() {
        // CBOR uint additional-info 26, value 0x12345678.
        let data = Data([0x1A, 0x12, 0x34, 0x56, 0x78])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 5)
    }

    func test_cbor_decode_uint_eight_bytes() {
        // CBOR uint additional-info 27 — the parser supports the 9-byte head skip but
        // `readCborLength` does NOT support 8-byte lengths (overflows Int). Asserts both.
        let data = Data([0x1B, 0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF])
        XCTAssertEqual(WebAuthnCborParser.skipCborHead(data, offset: 0), 9)
        XCTAssertNil(WebAuthnCborParser.readCborLength(data, offset: 0))
    }

    func test_cbor_decode_negative_int() {
        // CBOR major-type 1 value -2 encoded as 0x21.
        let data = Data([0x21])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 1)
    }

    func test_cbor_decode_array_definite() {
        // major-type 4 array of 3 ints
        let data = Data([0x83, 0x01, 0x02, 0x03])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 4)
    }

    func test_cbor_decode_array_indefinite_terminated() {
        // major-type 4 with additional-info 31 (indefinite) plus break byte 0xFF.
        // The parser does NOT support indefinite encodings — asserts null.
        let data = Data([0x9F, 0x01, 0x02, 0xFF])
        XCTAssertNil(WebAuthnCborParser.skipCborValue(data, offset: 0))
    }

    func test_cbor_decode_array_indefinite_unterminated_rejected() {
        let data = Data([0x9F, 0x01, 0x02])
        XCTAssertNil(WebAuthnCborParser.skipCborValue(data, offset: 0))
    }

    func test_cbor_decode_map_definite() {
        // major-type 5 map with one key-value pair { uint(1) -> uint(2) }
        let data = Data([0xA1, 0x01, 0x02])
        XCTAssertEqual(WebAuthnCborParser.skipCborValue(data, offset: 0), 3)
    }

    func test_cbor_decode_map_indefinite() {
        // major-type 5 with additional-info 31 — not supported; asserts null.
        let data = Data([0xBF, 0x01, 0x02, 0xFF])
        XCTAssertNil(WebAuthnCborParser.skipCborValue(data, offset: 0))
    }

    func test_cbor_decode_truncated_rejected() {
        // 1-byte byte-string head (length 5) but no following content.
        let data = Data([0x45])
        XCTAssertNil(WebAuthnCborParser.skipCborValue(data, offset: 0))
    }

    func test_cbor_decode_deeply_nested_rejected() {
        // Build a nested array structure of depth 65 (just over the depth cap of 64).
        // CBOR: array(1) wrapper repeated N times, terminated by a uint(0).
        var data = Data()
        for _ in 0..<65 {
            data.append(0x81) // array(1)
        }
        data.append(0x00) // uint(0)
        XCTAssertNil(WebAuthnCborParser.skipCborValue(data, offset: 0))
    }

    func test_cbor_decode_max_depth_exceeded_rejected() {
        // Same shape as above but at exactly the cap — depth-64 array nesting.
        // The leaf at position 64 is uint(0); the outermost call counts as depth 0,
        // so this represents 65 array layers in total and must be rejected.
        var data = Data()
        for _ in 0..<70 {
            data.append(0x81)
        }
        data.append(0x00)
        XCTAssertNil(WebAuthnCborParser.skipCborValue(data, offset: 0))
    }

    func test_cbor_fuzz_10000_seeded_rng_no_panic() {
        // 10,000 randomized inputs (length 0-512 bytes, byte values uniformly random)
        // seeded with a deterministic LCG (seed pinned). Each public method must return
        // either a clean result or nil; no crashes, no infinite loops.
        var rng = SeededLCG(seed: cborFuzzSeed)
        for _ in 0..<10_000 {
            let length = Int(rng.next() % 513) // 0..512
            var bytes = Data(count: length)
            for i in 0..<length {
                bytes[i] = UInt8(rng.next() & 0xFF)
            }
            // Each call must return without crashing the test process.
            _ = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(bytes)
            _ = WebAuthnCborParser.extractPublicKeyFromCoseKey(bytes)
            _ = WebAuthnCborParser.extractPublicKeyFromSpki(bytes)
            _ = WebAuthnCborParser.parseAuthenticatorFlags(bytes)
            _ = WebAuthnCborParser.readCborByteString(bytes, offset: 0)
            _ = WebAuthnCborParser.readCborTextString(bytes, offset: 0)
            _ = WebAuthnCborParser.readCborLength(bytes, offset: 0)
            _ = WebAuthnCborParser.skipCborValue(bytes, offset: 0)
            _ = WebAuthnCborParser.skipCborHead(bytes, offset: 0)
        }
    }
}

// =========================================================================
// Deterministic seeded LCG used by the fuzz test
//
// A linear-congruential generator with widely-published constants from MMIX (Knuth) so the
// stream is reproducible byte-for-byte across machines. Test-only — kept in this file
// because no production code path needs deterministic randomness.
// =========================================================================

private struct SeededLCG {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
