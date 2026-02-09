//
//  FootprintOpXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class FootprintOpXDRUnitTests: XCTestCase {

    // MARK: - Test Data Helpers

    private func createTestContractAddress() -> SCAddressXDR {
        let contractIdBytes = Data(repeating: 0xAB, count: 32)
        return .contract(WrappedData32(contractIdBytes))
    }

    private func createTestAccountKey() throws -> LedgerKeyXDR {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let accountKey = LedgerKeyAccountXDR(accountID: keyPair.publicKey)
        return .account(accountKey)
    }

    private func createTestContractDataKey() -> LedgerKeyXDR {
        let contractAddress = createTestContractAddress()
        let key = SCValXDR.symbol("balance")
        let contractDataKey = LedgerKeyContractDataXDR(
            contract: contractAddress,
            key: key,
            durability: .persistent
        )
        return .contractData(contractDataKey)
    }

    private func createTestContractCodeKey() -> LedgerKeyXDR {
        let wasmHash = WrappedData32(Data(repeating: 0xCD, count: 32))
        let contractCodeKey = LedgerKeyContractCodeXDR(hash: wasmHash)
        return .contractCode(contractCodeKey)
    }

    // MARK: - ExtendFootprintTTLOpXDR Tests

    func testExtendFootprintTTLOpXDREncodeDecode() throws {
        let extendOp = ExtendFootprintTTLOpXDR(
            ext: .void,
            extendTo: 1000
        )

        let encoded = try XDREncoder.encode(extendOp)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.extendTo, 1000)
    }

    func testExtendFootprintTTLOpXDRWithExtendTo() throws {
        let extendToValue: UInt32 = 518400 // ~30 days in ledgers

        let extendOp = ExtendFootprintTTLOpXDR(
            ext: .void,
            extendTo: extendToValue
        )

        let encoded = try XDREncoder.encode(extendOp)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.extendTo, extendToValue)
    }

    func testExtendFootprintTTLOpXDRWithMaxExtendTo() throws {
        let maxExtendTo: UInt32 = UInt32.max

        let extendOp = ExtendFootprintTTLOpXDR(
            ext: .void,
            extendTo: maxExtendTo
        )

        let encoded = try XDREncoder.encode(extendOp)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLOpXDR.self, data: encoded)

        XCTAssertEqual(decoded.extendTo, maxExtendTo)
    }

    func testExtendFootprintTTLOpXDRRoundTrip() throws {
        let extendOp = ExtendFootprintTTLOpXDR(
            ext: .void,
            extendTo: 2592000
        )

        // Test base64 round-trip
        guard let base64 = extendOp.xdrEncoded else {
            XCTFail("Failed to encode ExtendFootprintTTLOpXDR to base64")
            return
        }
        XCTAssertFalse(base64.isEmpty)

        // Re-encode and verify identical bytes
        let encoded = try XDREncoder.encode(extendOp)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLOpXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)
        XCTAssertEqual(decoded.extendTo, 2592000)
    }

    // MARK: - RestoreFootprintOpXDR Tests

    func testRestoreFootprintOpXDREncodeDecode() throws {
        let restoreOp = RestoreFootprintOpXDR(ext: .void)

        let encoded = try XDREncoder.encode(restoreOp)
        let decoded = try XDRDecoder.decode(RestoreFootprintOpXDR.self, data: encoded)

        XCTAssertNotNil(decoded)
    }

    func testRestoreFootprintOpXDRRoundTrip() throws {
        let restoreOp = RestoreFootprintOpXDR(ext: .void)

        // Test base64 round-trip
        guard let base64 = restoreOp.xdrEncoded else {
            XCTFail("Failed to encode RestoreFootprintOpXDR to base64")
            return
        }
        XCTAssertFalse(base64.isEmpty)

        // Re-encode and verify identical bytes
        let encoded = try XDREncoder.encode(restoreOp)
        let decoded = try XDRDecoder.decode(RestoreFootprintOpXDR.self, data: encoded)
        let reEncoded = try XDREncoder.encode(decoded)
        XCTAssertEqual(encoded, reEncoded)

        // Verify base64 round-trip
        guard let reEncodedBase64 = decoded.xdrEncoded else {
            XCTFail("Failed to re-encode RestoreFootprintOpXDR to base64")
            return
        }
        XCTAssertEqual(base64, reEncodedBase64)
    }

    // MARK: - LedgerFootprintXDR Tests

    func testLedgerFootprintXDREncodeDecode() throws {
        let accountKey = try createTestAccountKey()
        let contractDataKey = createTestContractDataKey()
        let contractCodeKey = createTestContractCodeKey()

        let footprint = LedgerFootprintXDR(
            readOnly: [accountKey, contractDataKey],
            readWrite: [contractCodeKey]
        )

        let encoded = try XDREncoder.encode(footprint)
        let decoded = try XDRDecoder.decode(LedgerFootprintXDR.self, data: encoded)

        XCTAssertEqual(decoded.readOnly.count, 2)
        XCTAssertEqual(decoded.readWrite.count, 1)
        XCTAssertEqual(decoded.readOnly[0].type(), LedgerEntryType.account.rawValue)
        XCTAssertEqual(decoded.readOnly[1].type(), LedgerEntryType.contractData.rawValue)
        XCTAssertEqual(decoded.readWrite[0].type(), LedgerEntryType.contractCode.rawValue)
    }

    func testLedgerFootprintXDREmpty() throws {
        let footprint = LedgerFootprintXDR(readOnly: [], readWrite: [])

        let encoded = try XDREncoder.encode(footprint)
        let decoded = try XDRDecoder.decode(LedgerFootprintXDR.self, data: encoded)

        XCTAssertEqual(decoded.readOnly.count, 0)
        XCTAssertEqual(decoded.readWrite.count, 0)
    }

    func testLedgerFootprintXDRWithContractKeys() throws {
        let contractDataKey1 = createTestContractDataKey()

        // Create a second contract data key with different values
        let contractAddress2 = SCAddressXDR.contract(WrappedData32(Data(repeating: 0xEF, count: 32)))
        let contractDataKey2 = LedgerKeyXDR.contractData(
            LedgerKeyContractDataXDR(
                contract: contractAddress2,
                key: .symbol("total_supply"),
                durability: .persistent
            )
        )

        let contractCodeKey = createTestContractCodeKey()

        let footprint = LedgerFootprintXDR(
            readOnly: [contractDataKey1, contractDataKey2],
            readWrite: [contractCodeKey]
        )

        let encoded = try XDREncoder.encode(footprint)
        let decoded = try XDRDecoder.decode(LedgerFootprintXDR.self, data: encoded)

        XCTAssertEqual(decoded.readOnly.count, 2)
        XCTAssertEqual(decoded.readWrite.count, 1)

        // Verify all keys are contract-related
        for key in decoded.readOnly {
            XCTAssertEqual(key.type(), LedgerEntryType.contractData.rawValue)
        }
        XCTAssertEqual(decoded.readWrite[0].type(), LedgerEntryType.contractCode.rawValue)
    }

    // MARK: - ExtendFootprintTTLResultXDR Tests

    func testExtendFootprintTTLResultXDRSuccess() throws {
        let result = ExtendFootprintTTLResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        if case .success = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected success case but got \(decoded)")
        }
    }

    func testExtendFootprintTTLResultXDRMalformed() throws {
        let result = ExtendFootprintTTLResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        if case .malformed = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected malformed case but got \(decoded)")
        }
    }

    func testExtendFootprintTTLResultXDRResourceLimitExceeded() throws {
        let result = ExtendFootprintTTLResultXDR.resourceLimitExceeded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        if case .resourceLimitExceeded = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected resourceLimitExceeded case but got \(decoded)")
        }
    }

    func testExtendFootprintTTLResultXDRInsufficientRefundableFee() throws {
        let result = ExtendFootprintTTLResultXDR.insufficientRefundableFee

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(ExtendFootprintTTLResultXDR.self, data: encoded)

        if case .insufficientRefundableFee = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected insufficientRefundableFee case but got \(decoded)")
        }
    }

    // MARK: - RestoreFootprintResultXDR Tests

    func testRestoreFootprintResultXDRSuccess() throws {
        let result = RestoreFootprintResultXDR.success

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: encoded)

        if case .success = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected success case but got \(decoded)")
        }
    }

    func testRestoreFootprintResultXDRMalformed() throws {
        let result = RestoreFootprintResultXDR.malformed

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: encoded)

        if case .malformed = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected malformed case but got \(decoded)")
        }
    }

    func testRestoreFootprintResultXDRResourceLimitExceeded() throws {
        let result = RestoreFootprintResultXDR.resourceLimitExceeded

        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(RestoreFootprintResultXDR.self, data: encoded)

        if case .resourceLimitExceeded = decoded {
            // Verify roundtrip produces identical bytes
            let reEncoded = try XDREncoder.encode(decoded)
            XCTAssertEqual(encoded, reEncoded)
        } else {
            XCTFail("Expected resourceLimitExceeded case but got \(decoded)")
        }
    }
}
