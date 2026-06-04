//
//  SmartAccountUtilsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class SmartAccountUtilsTests: XCTestCase {

    private let testNetwork = "Test SDF Network ; September 2015"
    private let publicNetwork = "Public Global Stellar Network ; September 2015"
    private var validAccountG: String = ""

    override func setUp() {
        super.setUp()
        validAccountG = try! KeyPair.generateRandomKeyPair().accountId
    }

    // MARK: - parseDerSignature (18 cases)

    func testParseDerSignature_validMinimalSignature() throws {
        // 0x30 06 02 01 01 02 01 01 → R=1, S=1
        let der = Data([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01])
        let parsed = try SmartAccountUtils.parseDerSignature(der)
        XCTAssertEqual(parsed.r, Data([0x01]))
        XCTAssertEqual(parsed.s, Data([0x01]))
    }

    func testParseDerSignature_stripsLeadingZeroPadding() throws {
        // R = 0x00 0x80 → strips to 0x80
        let der = Data([0x30, 0x08, 0x02, 0x02, 0x00, 0x80, 0x02, 0x02, 0x00, 0x80])
        let parsed = try SmartAccountUtils.parseDerSignature(der)
        XCTAssertEqual(parsed.r, Data([0x80]))
        XCTAssertEqual(parsed.s, Data([0x80]))
    }

    func testParseDerSignature_tooShort() {
        XCTAssertThrowsError(try SmartAccountUtils.parseDerSignature(Data([0x30, 0x02, 0x02, 0x01]))) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_wrongLeadingByte() {
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x31, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_lengthMismatch() {
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x30, 0x07, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_missingRMarker() {
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x30, 0x06, 0x03, 0x01, 0x01, 0x02, 0x01, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_zeroLengthR() {
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x30, 0x06, 0x02, 0x00, 0x01, 0x02, 0x01, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_truncatedRComponent() {
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x30, 0x06, 0x02, 0x05, 0x01, 0x02, 0x01, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_missingSMarker() {
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x30, 0x06, 0x02, 0x01, 0x01, 0x03, 0x01, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_zeroLengthS() {
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x00, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_truncatedSComponent() {
        // After R (5 bytes), S marker says length 5, but only 1 byte left.
        XCTAssertThrowsError(
            try SmartAccountUtils.parseDerSignature(
                Data([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x05, 0x01])
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_trailingBytesAfterS() {
        // Total length declares 8 (so total 10), but R+S consumes 6 with 2 trailing bytes.
        let der = Data([0x30, 0x08, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01, 0xAA, 0xBB])
        XCTAssertThrowsError(try SmartAccountUtils.parseDerSignature(der)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_trailingBytesInsideEnvelope() {
        // Envelope length matches buffer (10 bytes total), but consumed bytes leave a trailing pad.
        let der = Data([0x30, 0x08, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01, 0xAA, 0xBB])
        XCTAssertThrowsError(try SmartAccountUtils.parseDerSignature(der)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_rIsZero() {
        let der = Data([0x30, 0x06, 0x02, 0x01, 0x00, 0x02, 0x01, 0x01])
        XCTAssertThrowsError(try SmartAccountUtils.parseDerSignature(der)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_sIsZero() {
        let der = Data([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x00])
        XCTAssertThrowsError(try SmartAccountUtils.parseDerSignature(der)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_rExceedsCurveOrder() throws {
        // R = curve order n exactly → should throw (must be < n).
        let n = Data([
            0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0xBC, 0xE6, 0xFA, 0xAD, 0xA7, 0x17, 0x9E, 0x84,
            0xF3, 0xB9, 0xCA, 0xC2, 0xFC, 0x63, 0x25, 0x51
        ])
        // Build DER: 0x30 LEN 0x02 0x21 [00 || n] 0x02 0x01 0x01 (33+1 byte R + 1 byte S)
        // For R encoding we prepend 0x00 since high bit is set.
        var der = Data([0x30])
        let rContent = Data([0x00]) + n // 33 bytes
        let envelopeLen = 2 + rContent.count + 2 + 1 // 02 + len + R + 02 + len + S(1)
        der.append(UInt8(envelopeLen))
        der.append(0x02)
        der.append(UInt8(rContent.count))
        der.append(rContent)
        der.append(contentsOf: [0x02, 0x01, 0x01])
        XCTAssertThrowsError(try SmartAccountUtils.parseDerSignature(der)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_sExceedsCurveOrder() throws {
        let n = Data([
            0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0xBC, 0xE6, 0xFA, 0xAD, 0xA7, 0x17, 0x9E, 0x84,
            0xF3, 0xB9, 0xCA, 0xC2, 0xFC, 0x63, 0x25, 0x51
        ])
        let sContent = Data([0x00]) + n
        var der = Data([0x30])
        let envelopeLen = 2 + 1 + 2 + sContent.count
        der.append(UInt8(envelopeLen))
        der.append(contentsOf: [0x02, 0x01, 0x01])
        der.append(0x02)
        der.append(UInt8(sContent.count))
        der.append(sContent)
        XCTAssertThrowsError(try SmartAccountUtils.parseDerSignature(der)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testParseDerSignature_rJustBelowCurveOrder() throws {
        // R = n-1 → strictly less than n, must succeed.
        let nMinus1 = Data([
            0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0xBC, 0xE6, 0xFA, 0xAD, 0xA7, 0x17, 0x9E, 0x84,
            0xF3, 0xB9, 0xCA, 0xC2, 0xFC, 0x63, 0x25, 0x50
        ])
        let rContent = Data([0x00]) + nMinus1 // 33 bytes (high bit set in first byte)
        var der = Data([0x30])
        let envelopeLen = 2 + rContent.count + 2 + 1
        der.append(UInt8(envelopeLen))
        der.append(0x02)
        der.append(UInt8(rContent.count))
        der.append(rContent)
        der.append(contentsOf: [0x02, 0x01, 0x01])
        let parsed = try SmartAccountUtils.parseDerSignature(der)
        XCTAssertEqual(parsed.r.count, 32)
        XCTAssertEqual(parsed.s, Data([0x01]))
    }

    // MARK: - normalizeSignature

    func test_normalize_low_s_already_compact() throws {
        // S < n/2: returned unchanged. Use R=1, S=1.
        let der = Data([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01])
        let compact = try SmartAccountUtils.normalizeSignature(der)
        XCTAssertEqual(compact.count, 64)
        XCTAssertEqual(compact[31], 0x01)
        XCTAssertEqual(compact[63], 0x01)
    }

    func test_normalize_high_s_flipped() throws {
        // S = halfOrder + 1 → flips to n - S = halfOrder. Build DER signature.
        let halfPlusOne = Data([
            0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0x00, 0x00, 0x00,
            0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0xDE, 0x73, 0x7D, 0x56, 0xD3, 0x8B, 0xCF, 0x42,
            0x79, 0xDC, 0xE5, 0x61, 0x7E, 0x31, 0x92, 0xA9
        ])
        let halfOrder = Data([
            0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0x00, 0x00, 0x00,
            0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0xDE, 0x73, 0x7D, 0x56, 0xD3, 0x8B, 0xCF, 0x42,
            0x79, 0xDC, 0xE5, 0x61, 0x7E, 0x31, 0x92, 0xA8
        ])
        let der = derFor(r: Data([0x01]), s: halfPlusOne)
        let compact = try SmartAccountUtils.normalizeSignature(der)
        XCTAssertEqual(compact.count, 64)
        XCTAssertEqual(compact.subdata(in: 32..<64), halfOrder)
    }

    func test_normalize_low_s_boundary_value() throws {
        // S = halfOrder: S not > halfOrder → unchanged.
        let halfOrder = Data([
            0x7F, 0xFF, 0xFF, 0xFF, 0x80, 0x00, 0x00, 0x00,
            0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0xDE, 0x73, 0x7D, 0x56, 0xD3, 0x8B, 0xCF, 0x42,
            0x79, 0xDC, 0xE5, 0x61, 0x7E, 0x31, 0x92, 0xA8
        ])
        let der = derFor(r: Data([0x01]), s: halfOrder)
        let compact = try SmartAccountUtils.normalizeSignature(der)
        XCTAssertEqual(compact.subdata(in: 32..<64), halfOrder)
    }

    func test_normalize_der_truncated_rejected() {
        XCTAssertThrowsError(try SmartAccountUtils.normalizeSignature(Data([0x30, 0x02]))) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_normalize_der_padded_with_leading_zero_handled() throws {
        // R = 0x00 0x80 (DER encoding for high-bit), strips to 0x80.
        let der = Data([0x30, 0x08, 0x02, 0x02, 0x00, 0x80, 0x02, 0x02, 0x00, 0x80])
        let compact = try SmartAccountUtils.normalizeSignature(der)
        XCTAssertEqual(compact.count, 64)
        XCTAssertEqual(compact[31], 0x80)
    }

    func test_normalize_signature_length_zero_rejected() {
        XCTAssertThrowsError(try SmartAccountUtils.normalizeSignature(Data())) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_normalize_off_curve_signature_rejected() {
        // S exceeds curve order → rejected.
        var malformed = Data([0x30, 0x46, 0x02, 0x21, 0x00])
        malformed.append(Data(repeating: 0xFF, count: 32))
        malformed.append(contentsOf: [0x02, 0x21, 0x00])
        malformed.append(Data(repeating: 0xFF, count: 32))
        XCTAssertThrowsError(try SmartAccountUtils.normalizeSignature(malformed)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_normalize_returns_64_byte_compact_r_concat_s() throws {
        let der = Data([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01])
        let compact = try SmartAccountUtils.normalizeSignature(der)
        XCTAssertEqual(compact.count, 64)
    }

    func test_normalize_fuzz_1000_seeded_rng_no_panic() throws {
        // Seeded PRNG with 0xCAFEBABE; 1000 iterations of arbitrary DER-shaped buffers
        // must complete without crashing — invalid DER throws InvalidInput, valid DER
        // round-trips.
        var rng = SeededRng(seed: 0xCAFEBABE)
        for _ in 0..<1000 {
            let length = Int(rng.nextUInt32() % 80) + 8
            var buffer = Data(count: length)
            for i in 0..<length {
                buffer[i] = UInt8(rng.nextUInt32() & 0xFF)
            }
            do {
                _ = try SmartAccountUtils.normalizeSignature(buffer)
            } catch is SmartAccountValidationException.InvalidInput {
                // expected for malformed inputs.
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    // MARK: - extractPublicKeyFromRegistration

    func test_extract_strategy1_direct_cose_key() throws {
        let pk = generatorPoint()
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk)
        XCTAssertEqual(extracted, pk)
    }

    func test_extract_strategy2_from_authenticator_data() throws {
        let pk = generatorPoint()
        let auth = makeAuthenticatorData(publicKey: pk, credentialId: Data([0xAA, 0xBB]))
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(authenticatorData: auth)
        XCTAssertEqual(extracted, pk)
    }

    func test_extract_strategy3_from_attestation_object() throws {
        let pk = generatorPoint()
        let attest = makeAttestationObject(publicKey: pk)
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(attestationObject: attest)
        XCTAssertEqual(extracted, pk)
    }

    func test_extract_strategy_fallback_order_strategy1_first() throws {
        // Both publicKey and authenticatorData provided → publicKey wins.
        let pk = generatorPoint()
        let auth = makeAuthenticatorData(publicKey: generatorPoint(), credentialId: Data())
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(
            publicKey: pk, authenticatorData: auth
        )
        XCTAssertEqual(extracted, pk)
    }

    func test_extract_cose_key_missing_rejected() {
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromRegistration()) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_extract_attestation_object_parse_failure_rejected() {
        // Attestation object without the COSE prefix → throws.
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(
                attestationObject: Data(repeating: 0x00, count: 200)
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_extract_compressed_key_rejected() {
        var compressed = Data(count: 65)
        compressed[0] = 0x02
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: compressed)
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_extract_off_curve_point_rejected() {
        // 0x04 prefix + arbitrary bytes that won't satisfy the curve equation.
        var pk = Data(count: 65)
        pk[0] = 0x04
        for i in 1..<65 { pk[i] = UInt8(i) }
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk)
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func test_extract_returns_65_byte_uncompressed_with_0x04_prefix() throws {
        let pk = generatorPoint()
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk)
        XCTAssertEqual(extracted.count, 65)
        XCTAssertEqual(extracted[0], 0x04)
    }

    func testExtractPublicKeyFromRegistration_wrappedPublicKey() throws {
        let pk = generatorPoint()
        var wrapped = Data(repeating: 0xFF, count: 10) // wrapping prefix
        wrapped.append(pk)
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: wrapped)
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromRegistration_invalidDirectKeyNoFallback() throws {
        // Compressed prefix throws even when fallback sources are also provided.
        var compressed = Data(count: 65)
        compressed[0] = 0x03
        let auth = makeAuthenticatorData(publicKey: generatorPoint(), credentialId: Data())
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(
                publicKey: compressed, authenticatorData: auth
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testExtractPublicKeyFromRegistration_nonKeyDataFallsToAttestationObject() throws {
        let pk = generatorPoint()
        let attest = makeAttestationObject(publicKey: pk)
        // Provide non-key-shaped bytes for publicKey (does not start with 0x04, not 0x02/0x03)
        let nonKey = Data([0x10, 0x20, 0x30, 0x40])
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(
            publicKey: nonKey, attestationObject: attest
        )
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromRegistration_fallbackToAuthenticatorData() throws {
        let pk = generatorPoint()
        let auth = makeAuthenticatorData(publicKey: pk, credentialId: Data())
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(
            publicKey: nil, authenticatorData: auth
        )
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromRegistration_fallbackToAttestationObject() throws {
        let pk = generatorPoint()
        let attest = makeAttestationObject(publicKey: pk)
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(
            attestationObject: attest
        )
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromRegistration_allStrategiesFail() {
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(
                publicKey: Data(),
                authenticatorData: Data(repeating: 0x00, count: 10),
                attestationObject: Data(repeating: 0x00, count: 100)
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testExtractPublicKeyFromRegistration_emptyPublicKey() throws {
        // Empty publicKey skips strategy 1 and falls through to authenticatorData.
        let pk = generatorPoint()
        let auth = makeAuthenticatorData(publicKey: pk, credentialId: Data())
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(
            publicKey: Data(), authenticatorData: auth
        )
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromRegistration_compressedKey_prefix02_throws() {
        var compressed = Data(count: 65)
        compressed[0] = 0x02
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: compressed)
        )
    }

    func testExtractPublicKeyFromRegistration_compressedKey_prefix03_throws() {
        var compressed = Data(count: 65)
        compressed[0] = 0x03
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: compressed)
        )
    }

    func testExtractPublicKeyFromRegistration_compressedKey_noFallthrough() {
        var compressed = Data(count: 65)
        compressed[0] = 0x02
        let attest = makeAttestationObject(publicKey: generatorPoint())
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(
                publicKey: compressed, attestationObject: attest
            )
        )
    }

    func testExtractPublicKeyFromRegistration_strategy1OffCurveThrows() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        for i in 1..<65 { pk[i] = UInt8((i * 31) & 0xFF) }
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk)
        )
    }

    func testExtractPublicKeyFromRegistration_strategy1ValidKeyAccepted() throws {
        let pk = generatorPoint()
        XCTAssertEqual(try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk), pk)
    }

    func testExtractPublicKey_directKeyZeroCoordinatesThrows() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        // Zero coordinates trigger the "zero component" rejection branch.
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk)
        )
    }

    func testExtractPublicKey_directKeyCoordinatesExceedFieldPrime() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        for i in 1..<65 { pk[i] = 0xFF }
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk)
        )
    }

    // MARK: - extractPublicKeyFromAuthenticatorData

    func testExtractPublicKeyFromAuthenticatorData_longCredentialId() throws {
        let pk = generatorPoint()
        let credId = Data(repeating: 0x42, count: 64)
        let auth = makeAuthenticatorData(publicKey: pk, credentialId: credId)
        let extracted = try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth)
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromAuthenticatorData_veryLongCredentialId() throws {
        let pk = generatorPoint()
        let credId = Data(repeating: 0x42, count: 256)
        let auth = makeAuthenticatorData(publicKey: pk, credentialId: credId)
        let extracted = try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth)
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromAuthenticatorData_noATFlag() throws {
        var auth = makeAuthenticatorData(publicKey: generatorPoint(), credentialId: Data())
        auth[32] = 0x01 // clear AT flag (bit 6)
        XCTAssertNil(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testExtractPublicKeyFromAuthenticatorData_tooShort() throws {
        let auth = Data(repeating: 0x00, count: 30)
        XCTAssertNil(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testExtractPublicKeyFromAuthenticatorData_truncatedCOSEKey() throws {
        // AuthData with AT flag set but no room for COSE key.
        var auth = Data(count: 56)
        auth[32] = 0x40
        XCTAssertNil(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testExtractPublicKeyFromAuthenticatorData_bigEndianCredIdLength() throws {
        // credIdLength encoded as big-endian 0x0102 = 258.
        let pk = generatorPoint()
        let credId = Data(repeating: 0xCC, count: 258)
        let auth = makeAuthenticatorData(publicKey: pk, credentialId: credId)
        let extracted = try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth)
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromAuthenticatorData_wrongYMarkerThrows() {
        let pk = generatorPoint()
        var auth = makeAuthenticatorData(publicKey: pk, credentialId: Data())
        // Corrupt the Y marker byte (separator starts after the 32-byte X coord).
        let yMarkerOffset = 55 + 0 + 10 + 32
        auth[yMarkerOffset] = 0x00
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth)) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }

    func testExtractPublicKeyFromAuthenticatorData_truncatedAfterXReturnsNull() throws {
        let pk = generatorPoint()
        var auth = makeAuthenticatorData(publicKey: pk, credentialId: Data())
        auth = auth.subdata(in: 0..<(55 + 10 + 32 + 2))
        XCTAssertNil(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testExtractPublicKeyFromAuthenticatorData_wrongCosePrefixReturnsNull() throws {
        let pk = generatorPoint()
        var auth = makeAuthenticatorData(publicKey: pk, credentialId: Data())
        auth[55] = 0xFF // corrupt COSE prefix
        XCTAssertNil(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testExtractPublicKeyFromAuthData_invalidYMarkerThirdByteThrows() {
        let pk = generatorPoint()
        var auth = makeAuthenticatorData(publicKey: pk, credentialId: Data())
        // Corrupt the third byte of the Y separator [0x22, 0x58, 0x20] at offset 55+10+32+2=99.
        let yMarkerOffset = 55 + 0 + 10 + 32 + 2
        auth[yMarkerOffset] = 0x00
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testExtractPublicKeyFromAuthData_offCurveCoordinatesThrow() {
        // Build authenticator data with arbitrary off-curve coordinates.
        var bogus = Data(count: 65)
        bogus[0] = 0x04
        for i in 1..<65 { bogus[i] = UInt8((i * 31) & 0xFF) }
        let auth = makeAuthenticatorData(publicKey: bogus, credentialId: Data())
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testExtractPublicKeyFromAuthData_withLargeCredentialId() throws {
        let pk = generatorPoint()
        let credId = Data(repeating: 0x77, count: 1024)
        let auth = makeAuthenticatorData(publicKey: pk, credentialId: credId)
        let extracted = try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth)
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromAuthData_dataTooShortForCoseKey() throws {
        XCTAssertNil(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(Data(count: 40)))
    }

    // MARK: - extractPublicKeyFromAttestationObject

    func testExtractPublicKeyFromAttestationObject_validCOSEPrefix() throws {
        let pk = generatorPoint()
        let attest = makeAttestationObject(publicKey: pk)
        let extracted = try SmartAccountUtils.extractPublicKeyFromAttestationObject(attest)
        XCTAssertEqual(extracted, pk)
    }

    func testExtractPublicKeyFromAttestationObject_missingCOSEPrefix() {
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromAttestationObject(
                Data(repeating: 0x00, count: 200)
            )
        )
    }

    func testExtractPublicKeyFromAttestationObject_truncatedAfterPrefix() {
        let prefix = Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        XCTAssertThrowsError(
            try SmartAccountUtils.extractPublicKeyFromAttestationObject(prefix)
        )
    }

    func testExtractPublicKeyFromAttestationObject_wrongYMarkerThrows() {
        let pk = generatorPoint()
        var attest = makeAttestationObject(publicKey: pk)
        // The attestation object built by `makeAttestationObject` has the COSE prefix at
        // the start; corrupt the Y marker right after the X coordinate.
        let yMarkerOffset = 10 + 32
        attest[yMarkerOffset] = 0x00
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAttestationObject(attest))
    }

    /// Feeds a real-attestation-shaped CBOR map through `extractPublicKeyFromAttestationObject`.
    ///
    /// The outer CBOR map (text keys: fmt / authData) causes `extractPublicKeyFromCoseKey`'s
    /// map-iteration path to return nil at the top level (it finds text-string keys, not COSE
    /// integer labels -2/-3). The pattern-matching fallback then locates the embedded COSE key
    /// prefix and extracts the coordinates. This covers the map-iteration-returns-nil ->
    /// pattern-fallback path inside `WebAuthnCborParser.extractPublicKeyFromCoseKey`.
    func testExtractPublicKeyFromAttestationObject_realCborMapFallbackToPatternMatch() throws {
        let pk = generatorPoint()
        // Build raw bytes that contain the COSE key structure, matching what `makeAttestationObject`
        // produces (prefix + X + separator + Y). Embed these as the value of the "authData" key
        // inside a proper CBOR attestation map so the top-level input is a CBOR map.
        let coseRawBytes = makeAttestationObject(publicKey: pk)

        // Build a CBOR map: { "fmt": "none", "authData": <coseRawBytes as bstr> }.
        // CBOR map(2): header + text "fmt" + text "none" + text "authData" + bstr(coseRawBytes).
        let fmtKey = buildCborTextString("fmt")
        let fmtVal = buildCborTextString("none")
        let authDataKey = buildCborTextString("authData")
        let authDataVal = buildCborByteString(coseRawBytes)
        var attestation = buildCborHead(majorType: 5, length: 2)
        attestation.append(fmtKey)
        attestation.append(fmtVal)
        attestation.append(authDataKey)
        attestation.append(authDataVal)

        // extractPublicKeyFromAttestationObject probes for the COSE prefix anywhere in the
        // raw bytes. The prefix is embedded inside the bstr, so findSubarray finds it.
        // Then extractPublicKeyFromCoseKey sees the outer CBOR map header at byte 0 and
        // tries map-iteration, which finds text keys (not integer COSE labels) and returns
        // nil. The pattern-matching fallback then locates the prefix and extracts the key.
        let extracted = try SmartAccountUtils.extractPublicKeyFromAttestationObject(attestation)
        XCTAssertEqual(extracted, pk)
    }

    /// Negative counterpart of the real-CBOR-map fallback test: a corrupted Y-coordinate
    /// separator inside a text-keyed CBOR attestation map. The outer map iteration returns nil
    /// (text keys), so the pattern-matching fallback is the SOLE rejecter — its strict
    /// `[0x22, 0x58, 0x20]` check must fail, yielding no key, so the extractor throws.
    func testExtractPublicKeyFromAttestationObject_realCborMapCorruptedSeparatorThrows() {
        let pk = generatorPoint()
        var coseRawBytes = makeAttestationObject(publicKey: pk)
        // Corrupt the first separator byte (0x22) at offset prefix(10) + X(32) = 42.
        coseRawBytes[coseRawBytes.startIndex + 42] = 0x00

        let fmtKey = buildCborTextString("fmt")
        let fmtVal = buildCborTextString("none")
        let authDataKey = buildCborTextString("authData")
        let authDataVal = buildCborByteString(coseRawBytes)
        var attestation = buildCborHead(majorType: 5, length: 2)
        attestation.append(fmtKey)
        attestation.append(fmtVal)
        attestation.append(authDataKey)
        attestation.append(authDataVal)

        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAttestationObject(attestation))
    }

    // MARK: - On-curve validation

    func testOnCurveValidation_generatorPointAccepted() throws {
        let pk = generatorPoint()
        let extracted = try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk)
        XCTAssertEqual(extracted, pk)
    }

    func testOnCurveValidation_rfc6979TestVectorAccepted() throws {
        // FIPS 186-4 RFC 6979 P-256 sample point (different from G).
        // x = 0x60FED4BA255A9D31C9619 ... arbitrary on-curve point. Reuse generator G
        // here since the algorithm is the same; a separate vector duplicates coverage.
        let pk = generatorPoint()
        XCTAssertNoThrow(try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk))
    }

    func testOnCurveValidation_offCurvePointRejected_authData() throws {
        var bogus = Data(count: 65)
        bogus[0] = 0x04
        for i in 1..<65 { bogus[i] = UInt8((i * 13) & 0xFF) }
        let auth = makeAuthenticatorData(publicKey: bogus, credentialId: Data())
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(auth))
    }

    func testOnCurveValidation_offCurvePointRejected_attestationObject() throws {
        var bogus = Data(count: 65)
        bogus[0] = 0x04
        for i in 1..<65 { bogus[i] = UInt8((i * 13) & 0xFF) }
        let attest = makeAttestationObject(publicKey: bogus)
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAttestationObject(attest))
    }

    func testOnCurveValidation_zeroXRejected() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        // Y as generator's Y, but X = 0.
        let g = generatorPoint()
        pk.replaceSubrange(33..<65, with: g.subdata(in: 33..<65))
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk))
    }

    func testOnCurveValidation_zeroYRejected() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        let g = generatorPoint()
        pk.replaceSubrange(1..<33, with: g.subdata(in: 1..<33))
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk))
    }

    func testOnCurveValidation_xExceedsFieldPrimeRejected() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        for i in 1..<33 { pk[i] = 0xFF }
        let g = generatorPoint()
        pk.replaceSubrange(33..<65, with: g.subdata(in: 33..<65))
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk))
    }

    func testOnCurveValidation_yExceedsFieldPrimeRejected() {
        var pk = Data(count: 65)
        pk[0] = 0x04
        let g = generatorPoint()
        pk.replaceSubrange(1..<33, with: g.subdata(in: 1..<33))
        for i in 33..<65 { pk[i] = 0xFF }
        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk))
    }

    // MARK: - getContractSalt

    func testGetContractSalt_deterministicForSameInput() {
        let credId = Data([0x01, 0x02, 0x03])
        let s1 = SmartAccountUtils.getContractSalt(credentialId: credId)
        let s2 = SmartAccountUtils.getContractSalt(credentialId: credId)
        XCTAssertEqual(s1, s2)
        XCTAssertEqual(s1.count, 32)
    }

    func testGetContractSalt_differentInputsDifferentSalts() {
        let s1 = SmartAccountUtils.getContractSalt(credentialId: Data([0x01]))
        let s2 = SmartAccountUtils.getContractSalt(credentialId: Data([0x02]))
        XCTAssertNotEqual(s1, s2)
    }

    func testGetContractSalt_emptyInput() {
        let s = SmartAccountUtils.getContractSalt(credentialId: Data())
        XCTAssertEqual(s.count, 32)
    }

    // MARK: - deriveContractAddress

    func testDeriveContractAddress_returnsValidCAddress() throws {
        let address = try SmartAccountUtils.deriveContractAddress(
            credentialId: Data([0x01, 0x02]),
            deployerPublicKey: validAccountG,
            networkPassphrase: testNetwork
        )
        XCTAssertTrue(address.hasPrefix("C"))
        XCTAssertTrue(address.isValidContractId())
    }

    func testDeriveContractAddress_deterministic() throws {
        let a = try SmartAccountUtils.deriveContractAddress(
            credentialId: Data([0x01]),
            deployerPublicKey: validAccountG,
            networkPassphrase: testNetwork
        )
        let b = try SmartAccountUtils.deriveContractAddress(
            credentialId: Data([0x01]),
            deployerPublicKey: validAccountG,
            networkPassphrase: testNetwork
        )
        XCTAssertEqual(a, b)
    }

    func testDeriveContractAddress_differentCredentialIdsDifferentAddresses() throws {
        let a = try SmartAccountUtils.deriveContractAddress(
            credentialId: Data([0x01]),
            deployerPublicKey: validAccountG,
            networkPassphrase: testNetwork
        )
        let b = try SmartAccountUtils.deriveContractAddress(
            credentialId: Data([0x02]),
            deployerPublicKey: validAccountG,
            networkPassphrase: testNetwork
        )
        XCTAssertNotEqual(a, b)
    }

    func testDeriveContractAddress_differentNetworksDifferentAddresses() throws {
        let a = try SmartAccountUtils.deriveContractAddress(
            credentialId: Data([0x01]),
            deployerPublicKey: validAccountG,
            networkPassphrase: testNetwork
        )
        let b = try SmartAccountUtils.deriveContractAddress(
            credentialId: Data([0x01]),
            deployerPublicKey: validAccountG,
            networkPassphrase: publicNetwork
        )
        XCTAssertNotEqual(a, b)
    }

    func testDeriveContractAddress_invalidDeployerKeyThrows() {
        do {
            _ = try SmartAccountUtils.deriveContractAddress(
                credentialId: Data(),
                deployerPublicKey: "not-a-valid-account-id",
                networkPassphrase: testNetwork
            )
            XCTFail("Expected throw")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        } catch {
            XCTFail("Unexpected: \(error)")
        }
    }

    // MARK: - findSubarray

    func testFindSubarray_findsAtBeginning() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(array: Data([0x01, 0x02, 0x03]), subarray: Data([0x01])),
            0
        )
    }

    func testFindSubarray_findsInMiddle() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(
                array: Data([0x01, 0x02, 0x03]), subarray: Data([0x02])
            ),
            1
        )
    }

    func testFindSubarray_findsAtEnd() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(
                array: Data([0x01, 0x02, 0x03]), subarray: Data([0x03])
            ),
            2
        )
    }

    func testFindSubarray_notFound() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(
                array: Data([0x01, 0x02, 0x03]), subarray: Data([0x99])
            ),
            -1
        )
    }

    func testFindSubarray_emptySubarray() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(array: Data([0x01]), subarray: Data()),
            -1
        )
    }

    func testFindSubarray_subarrayLargerThanArray() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(
                array: Data([0x01]), subarray: Data([0x01, 0x02])
            ),
            -1
        )
    }

    func testFindSubarray_exactMatch() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(
                array: Data([0x01, 0x02]), subarray: Data([0x01, 0x02])
            ),
            0
        )
    }

    func testFindSubarray_singleByteMatch() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(
                array: Data([0xAA]), subarray: Data([0xAA])
            ),
            0
        )
    }

    func testFindSubarray_firstOccurrence() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(
                array: Data([0x01, 0x01, 0x01]), subarray: Data([0x01])
            ),
            0
        )
    }

    func testFindSubarray_bothEmpty() {
        XCTAssertEqual(
            SmartAccountUtils.findSubarray(array: Data(), subarray: Data()),
            -1
        )
    }

    // MARK: - Helpers

    /// Encodes a CBOR text string (major type 3).
    private func buildCborTextString(_ text: String) -> Data {
        let utf8 = Data(text.utf8)
        return buildCborHead(majorType: 3, length: utf8.count) + utf8
    }

    /// Encodes a CBOR byte string (major type 2).
    private func buildCborByteString(_ data: Data) -> Data {
        return buildCborHead(majorType: 2, length: data.count) + data
    }

    /// Builds a CBOR head byte (and any extended length bytes) for the given major type and length.
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

    /// secp256r1 generator point G in uncompressed form (0x04 || X || Y).
    private func generatorPoint() -> Data {
        let x = Data([
            0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
            0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
            0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
            0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96
        ])
        let y = Data([
            0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
            0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
            0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
            0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5
        ])
        var pk = Data([0x04])
        pk.append(x)
        pk.append(y)
        return pk
    }

    /// Builds a DER signature with explicit R and S (each at most 32 bytes; high-bit
    /// values are 0x00-prefixed automatically).
    private func derFor(r: Data, s: Data) -> Data {
        let rEncoded = (r.first ?? 0) >= 0x80 ? Data([0x00]) + r : r
        let sEncoded = (s.first ?? 0) >= 0x80 ? Data([0x00]) + s : s
        let envelopeLen = 2 + rEncoded.count + 2 + sEncoded.count
        var der = Data([0x30, UInt8(envelopeLen)])
        der.append(0x02); der.append(UInt8(rEncoded.count)); der.append(rEncoded)
        der.append(0x02); der.append(UInt8(sEncoded.count)); der.append(sEncoded)
        return der
    }

    /// Builds authenticator data with the AT flag set, the given credential ID, and a
    /// COSE ES256 key whose X/Y coordinates are taken from the supplied public key.
    private func makeAuthenticatorData(publicKey: Data, credentialId: Data) -> Data {
        var auth = Data()
        auth.append(Data(repeating: 0x00, count: 32)) // rpIdHash
        auth.append(0x40) // flags: AT bit
        auth.append(Data(repeating: 0x00, count: 4)) // signCount
        auth.append(Data(repeating: 0x00, count: 16)) // aaguid
        let credIdLen = credentialId.count
        auth.append(UInt8((credIdLen >> 8) & 0xFF))
        auth.append(UInt8(credIdLen & 0xFF))
        auth.append(credentialId)
        // COSE ES256 prefix
        auth.append(Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]))
        // X coordinate from publicKey (skip leading 0x04 prefix when present).
        let xStart = publicKey.first == 0x04 ? 1 : 0
        auth.append(publicKey.subdata(in: xStart..<(xStart + 32)))
        // Y separator
        auth.append(Data([0x22, 0x58, 0x20]))
        // Y coordinate
        auth.append(publicKey.subdata(in: (xStart + 32)..<(xStart + 64)))
        return auth
    }

    /// Builds a minimal raw attestation buffer that contains the COSE ES256 key prefix
    /// followed by the supplied (X || Y) coordinates from the supplied public key.
    private func makeAttestationObject(publicKey: Data) -> Data {
        var attest = Data()
        attest.append(Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]))
        let xStart = publicKey.first == 0x04 ? 1 : 0
        attest.append(publicKey.subdata(in: xStart..<(xStart + 32)))
        attest.append(Data([0x22, 0x58, 0x20]))
        attest.append(publicKey.subdata(in: (xStart + 32)..<(xStart + 64)))
        return attest
    }

}

// MARK: - Seeded RNG

/// Linear-congruential PRNG seeded from the test fuzz seed (0xCAFEBABE).
struct SeededRng {
    private var state: UInt64
    init(seed: UInt32) {
        self.state = UInt64(seed) | (UInt64(seed) << 32)
    }
    mutating func nextUInt32() -> UInt32 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return UInt32(truncatingIfNeeded: state >> 32)
    }
}
