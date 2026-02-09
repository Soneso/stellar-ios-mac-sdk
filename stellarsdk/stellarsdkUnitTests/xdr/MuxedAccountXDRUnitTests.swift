//
//  MuxedAccountXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MuxedAccountXDRUnitTests: XCTestCase {

    // MARK: - Helper Properties

    let testAccountId = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    let testMuxedAccountId = "MCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS67AAAAAAAAAAAAGPQ4"

    // MARK: - Helper Methods

    func createTestPublicKey() throws -> PublicKey {
        return try PublicKey(accountId: testAccountId)
    }

    func createTestEd25519Bytes() throws -> [UInt8] {
        let pk = try createTestPublicKey()
        return pk.bytes
    }

    // MARK: - MuxedAccountXDR Variant Tests

    func testMuxedAccountXDREd25519() throws {
        let bytes = try createTestEd25519Bytes()
        let muxed = MuxedAccountXDR.ed25519(bytes)

        // KEY_TYPE_ED25519 = 0
        XCTAssertEqual(muxed.type(), Int32(0))
        XCTAssertEqual(muxed.ed25519AccountId, testAccountId)
        XCTAssertEqual(muxed.accountId, testAccountId)
        XCTAssertNil(muxed.id)
    }

    func testMuxedAccountXDRMed25519() throws {
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = 12345
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let muxed = MuxedAccountXDR.med25519(med25519)

        // KEY_TYPE_MUXED_ED25519 = 0x100 = 256
        XCTAssertEqual(muxed.type(), Int32(0x100))
        XCTAssertEqual(muxed.ed25519AccountId, testAccountId)
        XCTAssertEqual(muxed.id, muxId)
        XCTAssertNotNil(muxed.accountId)
        XCTAssertTrue(muxed.accountId.hasPrefix("M"))
    }

    func testMuxedAccountXDRMed25519WithZeroId() throws {
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = 0
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let muxed = MuxedAccountXDR.med25519(med25519)

        // KEY_TYPE_MUXED_ED25519 = 0x100 = 256
        XCTAssertEqual(muxed.type(), Int32(0x100))
        XCTAssertEqual(muxed.id, 0)
        XCTAssertEqual(muxed.ed25519AccountId, testAccountId)
        XCTAssertTrue(muxed.accountId.hasPrefix("M"))
    }

    func testMuxedAccountXDRMed25519WithMaxId() throws {
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = UInt64.max
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let muxed = MuxedAccountXDR.med25519(med25519)

        // KEY_TYPE_MUXED_ED25519 = 0x100 = 256
        XCTAssertEqual(muxed.type(), Int32(0x100))
        XCTAssertEqual(muxed.id, UInt64.max)
        XCTAssertEqual(muxed.ed25519AccountId, testAccountId)
        XCTAssertTrue(muxed.accountId.hasPrefix("M"))
    }

    // MARK: - Encode/Decode Tests

    func testMuxedAccountXDREncodeDecode() throws {
        let bytes = try createTestEd25519Bytes()

        // Test Ed25519 case
        let ed25519Muxed = MuxedAccountXDR.ed25519(bytes)
        let encodedEd25519 = try XDREncoder.encode(ed25519Muxed)
        let decodedEd25519 = try XDRDecoder.decode(MuxedAccountXDR.self, data: encodedEd25519)

        switch decodedEd25519 {
        case .ed25519(let decodedBytes):
            XCTAssertEqual(decodedBytes, bytes)
        case .med25519:
            XCTFail("Expected ed25519 case")
        }

        // Test Med25519 case
        let muxId: UInt64 = 9876543210
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let med25519Muxed = MuxedAccountXDR.med25519(med25519)
        let encodedMed25519 = try XDREncoder.encode(med25519Muxed)
        let decodedMed25519 = try XDRDecoder.decode(MuxedAccountXDR.self, data: encodedMed25519)

        switch decodedMed25519 {
        case .ed25519:
            XCTFail("Expected med25519 case")
        case .med25519(let decodedMed):
            XCTAssertEqual(decodedMed.id, muxId)
            XCTAssertEqual(decodedMed.sourceAccountEd25519, bytes)
        }
    }

    func testMuxedAccountXDRRoundTrip() throws {
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = 555666777888
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let original = MuxedAccountXDR.med25519(med25519)

        // Encode to bytes
        let encoded = try XDREncoder.encode(original)

        // Convert to base64
        let base64 = Data(encoded).base64EncodedString()
        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(MuxedAccountXDR.self, data: [UInt8](decodedData))

        switch decoded {
        case .ed25519:
            XCTFail("Expected med25519 case")
        case .med25519(let decodedMed):
            XCTAssertEqual(decodedMed.id, muxId)
            XCTAssertEqual(decodedMed.sourceAccountEd25519, bytes)
        }
    }

    func testMuxedAccountXDRFromBase64() throws {
        let bytes = try createTestEd25519Bytes()
        let ed25519Muxed = MuxedAccountXDR.ed25519(bytes)

        // First encode to get valid base64
        let encoded = try XDREncoder.encode(ed25519Muxed)
        let base64 = Data(encoded).base64EncodedString()

        // Now decode from that base64
        guard let data = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(MuxedAccountXDR.self, data: [UInt8](data))

        switch decoded {
        case .ed25519(let decodedBytes):
            XCTAssertEqual(decodedBytes, bytes)
        case .med25519:
            XCTFail("Expected ed25519 case")
        }
    }

    // MARK: - Accessor/Property Tests

    func testMuxedAccountXDRAccountId() throws {
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = 99
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let muxed = MuxedAccountXDR.med25519(med25519)

        // ed25519AccountId should always return G... address
        let ed25519AccountId = muxed.ed25519AccountId
        XCTAssertTrue(ed25519AccountId.hasPrefix("G"))
        XCTAssertEqual(ed25519AccountId, testAccountId)

        // accountId should return M... address for med25519
        let accountId = muxed.accountId
        XCTAssertTrue(accountId.hasPrefix("M"))
        XCTAssertNotEqual(accountId, ed25519AccountId)
    }

    func testMuxedAccountXDRMuxId() throws {
        let bytes = try createTestEd25519Bytes()

        // Ed25519 case should return nil
        let ed25519Muxed = MuxedAccountXDR.ed25519(bytes)
        XCTAssertNil(ed25519Muxed.id)

        // Med25519 case should return the id
        let muxId: UInt64 = 1234567890123456789
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let med25519Muxed = MuxedAccountXDR.med25519(med25519)
        XCTAssertEqual(med25519Muxed.id, muxId)
    }

    func testMuxedAccountXDRDiscriminants() throws {
        // Verify type() returns expected discriminant values
        let bytes = try createTestEd25519Bytes()

        // Ed25519 case should return KEY_TYPE_ED25519 = 0
        let ed25519Muxed = MuxedAccountXDR.ed25519(bytes)
        XCTAssertEqual(ed25519Muxed.type(), Int32(0))

        // Med25519 case should return KEY_TYPE_MUXED_ED25519 = 0x100 = 256
        let med25519 = MuxedAccountMed25519XDR(id: 1, sourceAccountEd25519: bytes)
        let med25519Muxed = MuxedAccountXDR.med25519(med25519)
        XCTAssertEqual(med25519Muxed.type(), Int32(0x100))
    }

    // MARK: - MuxedAccountMed25519XDR Tests

    func testMuxedAccountMed25519XDRFields() throws {
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = 42
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)

        // Verify fields
        XCTAssertEqual(med25519.id, muxId)
        XCTAssertEqual(med25519.sourceAccountEd25519, bytes)
        XCTAssertEqual(med25519.sourceAccountEd25519.count, 32)

        // Verify accountId property returns M... address
        let accountId = med25519.accountId
        XCTAssertTrue(accountId.hasPrefix("M"))

        // Test encode/decode
        let encoded = try XDREncoder.encode(med25519)
        let decoded = try XDRDecoder.decode(MuxedAccountMed25519XDR.self, data: encoded)

        XCTAssertEqual(decoded.id, muxId)
        XCTAssertEqual(decoded.sourceAccountEd25519, bytes)
    }

    func testMuxedAccountMed25519XDRInvertedConversion() throws {
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = 777888999
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)

        // Convert to inverted form
        let inverted = med25519.toMuxedAccountMed25519XDRInverted()

        XCTAssertEqual(inverted.id, muxId)
        XCTAssertEqual(inverted.sourceAccountEd25519, bytes)

        // Convert back
        let convertedBack = inverted.toMuxedAccountMed25519XDR()

        XCTAssertEqual(convertedBack.id, muxId)
        XCTAssertEqual(convertedBack.sourceAccountEd25519, bytes)
    }

    // MARK: - String Extension Tests

    func testDecodeMuxedAccountFromGAddress() throws {
        let muxed = try testAccountId.decodeMuxedAccount()

        switch muxed {
        case .ed25519(let bytes):
            XCTAssertEqual(bytes.count, 32)
            let pk = try createTestPublicKey()
            XCTAssertEqual(bytes, pk.bytes)
        case .med25519:
            XCTFail("Expected ed25519 case for G address")
        }
    }

    func testDecodeMuxedAccountFromMAddress() throws {
        // Create a valid M address first
        let bytes = try createTestEd25519Bytes()
        let muxId: UInt64 = 123
        let med25519 = MuxedAccountMed25519XDR(id: muxId, sourceAccountEd25519: bytes)
        let muxed = MuxedAccountXDR.med25519(med25519)
        let mAddress = muxed.accountId

        XCTAssertTrue(mAddress.hasPrefix("M"))

        // Now decode it
        let decoded = try mAddress.decodeMuxedAccount()

        switch decoded {
        case .ed25519:
            XCTFail("Expected med25519 case for M address")
        case .med25519(let decodedMed):
            XCTAssertEqual(decodedMed.id, muxId)
            XCTAssertEqual(decodedMed.sourceAccountEd25519, bytes)
        }
    }
}
