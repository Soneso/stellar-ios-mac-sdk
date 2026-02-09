//
//  TransactionMetaXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class TransactionMetaXDRUnitTests: XCTestCase {

    // MARK: - Helper Methods

    /// Creates an empty LedgerEntryChangesXDR for testing
    private func createEmptyLedgerEntryChanges() -> LedgerEntryChangesXDR {
        return LedgerEntryChangesXDR(LedgerEntryChanges: [])
    }

    /// Creates a LedgerEntryChangesXDR with a created account entry
    private func createLedgerEntryChangesWithCreatedAccount() throws -> LedgerEntryChangesXDR {
        let accountIdString = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountIdString)
        let thresholds = WrappedData4(Data([1, 2, 3, 4]))

        let accountEntry = AccountEntryXDR(
            accountID: publicKey,
            balance: 10000000000,
            sequenceNumber: 1,
            numSubEntries: 0,
            homeDomain: "",
            flags: 0,
            thresholds: thresholds,
            signers: []
        )

        let ledgerEntry = LedgerEntryXDR(
            lastModifiedLedgerSeq: 12345,
            data: .account(accountEntry)
        )

        let change = LedgerEntryChangeXDR.created(ledgerEntry)
        return LedgerEntryChangesXDR(LedgerEntryChanges: [change])
    }

    /// Creates an OperationMetaXDR with changes
    private func createOperationMeta() throws -> OperationMetaXDR {
        let changes = try createLedgerEntryChangesWithCreatedAccount()
        return OperationMetaXDR(changes: changes)
    }

    // MARK: - TransactionMetaV1XDR Tests

    func testTransactionMetaV1XDREncodeDecode() throws {
        // V1 has: txChanges + operations array
        // Encode manually: txChanges followed by empty operations array
        var encodedData: [UInt8] = []

        // Encode txChanges (empty array: just 0 length)
        encodedData.append(contentsOf: [0, 0, 0, 0]) // empty ledgerEntryChanges array

        // Encode operations array (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0]) // empty operations array

        // Decode as TransactionMetaV1XDR
        let decoded = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: encodedData)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded.txChanges.ledgerEntryChanges.count, 0)
    }

    func testTransactionMetaV1XDRWithOperations() throws {
        // Create operation meta with changes
        let operationMeta = try createOperationMeta()

        // Encode the operation meta first to get its bytes
        let opMetaBytes = try XDREncoder.encode(operationMeta)

        // Build V1 structure: txChanges (empty) + operations array (1 operation)
        var encodedData: [UInt8] = []

        // Encode txChanges (empty array)
        encodedData.append(contentsOf: [0, 0, 0, 0])

        // Encode operations array with 1 element
        encodedData.append(contentsOf: [0, 0, 0, 1]) // array length = 1
        encodedData.append(contentsOf: opMetaBytes)

        // Decode
        let decoded = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: encodedData)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded.txChanges.ledgerEntryChanges.count, 0)
    }

    func testTransactionMetaV1XDRRoundTrip() throws {
        // Build and encode a V1 structure, then decode and re-encode
        var encodedData: [UInt8] = []

        // txChanges (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // operations (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])

        // First decode
        let decoded = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: encodedData)

        // Re-encode
        let reEncoded = try XDREncoder.encode(decoded)

        // Decode again
        let decodedAgain = try XDRDecoder.decode(TransactionMetaV1XDR.self, data: reEncoded)

        XCTAssertEqual(decodedAgain.txChanges.ledgerEntryChanges.count, decoded.txChanges.ledgerEntryChanges.count)
    }

    // MARK: - TransactionMetaV2XDR Tests

    func testTransactionMetaV2XDREncodeDecode() throws {
        // V2 has: txChangesBefore + operations + txChangesAfter
        var encodedData: [UInt8] = []

        // txChangesBefore (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // operations (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // txChangesAfter (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])

        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: encodedData)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded.txChangesBefore.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.txChangesAfter.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.operations.count, 0)
    }

    func testTransactionMetaV2XDRWithTxChangesBefore() throws {
        // Create ledger entry changes for txChangesBefore
        let changes = try createLedgerEntryChangesWithCreatedAccount()
        let changesBytes = try XDREncoder.encode(changes)

        var encodedData: [UInt8] = []

        // txChangesBefore (with changes)
        encodedData.append(contentsOf: changesBytes)
        // operations (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // txChangesAfter (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])

        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: encodedData)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded.txChangesBefore.ledgerEntryChanges.count, 1)
        XCTAssertEqual(decoded.txChangesAfter.ledgerEntryChanges.count, 0)
    }

    func testTransactionMetaV2XDRWithTxChangesAfter() throws {
        // Create ledger entry changes for txChangesAfter
        let changes = try createLedgerEntryChangesWithCreatedAccount()
        let changesBytes = try XDREncoder.encode(changes)

        var encodedData: [UInt8] = []

        // txChangesBefore (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // operations (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // txChangesAfter (with changes)
        encodedData.append(contentsOf: changesBytes)

        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: encodedData)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded.txChangesBefore.ledgerEntryChanges.count, 0)
        XCTAssertEqual(decoded.txChangesAfter.ledgerEntryChanges.count, 1)
    }

    func testTransactionMetaV2XDRRoundTrip() throws {
        var encodedData: [UInt8] = []

        // txChangesBefore (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // operations (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])
        // txChangesAfter (empty)
        encodedData.append(contentsOf: [0, 0, 0, 0])

        // First decode
        let decoded = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: encodedData)

        // Re-encode
        let reEncoded = try XDREncoder.encode(decoded)

        // Decode again
        let decodedAgain = try XDRDecoder.decode(TransactionMetaV2XDR.self, data: reEncoded)

        XCTAssertEqual(decodedAgain.txChangesBefore.ledgerEntryChanges.count, decoded.txChangesBefore.ledgerEntryChanges.count)
        XCTAssertEqual(decodedAgain.txChangesAfter.ledgerEntryChanges.count, decoded.txChangesAfter.ledgerEntryChanges.count)
    }

    // MARK: - TransactionMetaXDR Enum Tests

    func testTransactionMetaXDRAllVersions() throws {
        // Test V0 (operations only)
        var v0Data: [UInt8] = []
        v0Data.append(contentsOf: [0, 0, 0, 0]) // discriminant = 0
        v0Data.append(contentsOf: [0, 0, 0, 0]) // empty operations array

        let v0Decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: v0Data)
        switch v0Decoded {
        case .operations(let ops):
            XCTAssertEqual(ops.count, 0)
        default:
            XCTFail("Expected operations case for V0")
        }

        // Test V1
        var v1Data: [UInt8] = []
        v1Data.append(contentsOf: [0, 0, 0, 1]) // discriminant = 1
        v1Data.append(contentsOf: [0, 0, 0, 0]) // txChanges (empty)
        v1Data.append(contentsOf: [0, 0, 0, 0]) // operations (empty)

        let v1Decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: v1Data)
        switch v1Decoded {
        case .transactionMetaV1(let meta):
            XCTAssertEqual(meta.txChanges.ledgerEntryChanges.count, 0)
        default:
            XCTFail("Expected transactionMetaV1 case")
        }

        // Test V2
        var v2Data: [UInt8] = []
        v2Data.append(contentsOf: [0, 0, 0, 2]) // discriminant = 2
        v2Data.append(contentsOf: [0, 0, 0, 0]) // txChangesBefore (empty)
        v2Data.append(contentsOf: [0, 0, 0, 0]) // operations (empty)
        v2Data.append(contentsOf: [0, 0, 0, 0]) // txChangesAfter (empty)

        let v2Decoded = try XDRDecoder.decode(TransactionMetaXDR.self, data: v2Data)
        switch v2Decoded {
        case .transactionMetaV2(let meta):
            XCTAssertEqual(meta.txChangesBefore.ledgerEntryChanges.count, 0)
            XCTAssertEqual(meta.txChangesAfter.ledgerEntryChanges.count, 0)
        default:
            XCTFail("Expected transactionMetaV2 case")
        }
    }

    func testTransactionMetaXDRDiscriminants() throws {
        // Verify discriminant values match TransactionMetaType enum
        XCTAssertEqual(TransactionMetaType.operations.rawValue, 0)
        XCTAssertEqual(TransactionMetaType.transactionMetaV1.rawValue, 1)
        XCTAssertEqual(TransactionMetaType.transactionMetaV2.rawValue, 2)
        XCTAssertEqual(TransactionMetaType.transactionMetaV3.rawValue, 3)
        XCTAssertEqual(TransactionMetaType.transactionMetaV4.rawValue, 4)
    }

    func testTransactionMetaXDRFromBase64() throws {
        // Create a V0 (operations) meta and encode to base64
        var v0Data: [UInt8] = []
        v0Data.append(contentsOf: [0, 0, 0, 0]) // discriminant = 0
        v0Data.append(contentsOf: [0, 0, 0, 0]) // empty operations array

        let base64 = Data(v0Data).base64EncodedString()

        let decoded = try TransactionMetaXDR(fromBase64: base64)

        switch decoded {
        case .operations(let ops):
            XCTAssertEqual(ops.count, 0)
        default:
            XCTFail("Expected operations case")
        }
    }

    func testTransactionMetaXDRV1RoundTripBase64() throws {
        // Create V1 data
        var v1Data: [UInt8] = []
        v1Data.append(contentsOf: [0, 0, 0, 1]) // discriminant = 1
        v1Data.append(contentsOf: [0, 0, 0, 0]) // txChanges (empty)
        v1Data.append(contentsOf: [0, 0, 0, 0]) // operations (empty)

        let base64 = Data(v1Data).base64EncodedString()

        // Decode from base64
        let decoded = try TransactionMetaXDR(fromBase64: base64)

        // Re-encode
        let reEncoded = try XDREncoder.encode(decoded)
        let reEncodedBase64 = Data(reEncoded).base64EncodedString()

        // Decode again
        let decodedAgain = try TransactionMetaXDR(fromBase64: reEncodedBase64)

        switch decodedAgain {
        case .transactionMetaV1(let meta):
            XCTAssertEqual(meta.txChanges.ledgerEntryChanges.count, 0)
        default:
            XCTFail("Expected transactionMetaV1 case after round trip")
        }
    }

    // MARK: - LedgerEntryChangeXDR Tests

    func testLedgerEntryChangeXDRTypes() throws {
        // Test all LedgerEntryChangeType values
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryCreated.rawValue, 0)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryUpdated.rawValue, 1)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryRemoved.rawValue, 2)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryState.rawValue, 3)
        XCTAssertEqual(LedgerEntryChangeType.ledgerEntryRestore.rawValue, 4)
    }

    func testLedgerEntryChangesXDREncodeDecode() throws {
        let changes = try createLedgerEntryChangesWithCreatedAccount()

        let encoded = try XDREncoder.encode(changes)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(LedgerEntryChangesXDR.self, data: encoded)

        XCTAssertEqual(decoded.ledgerEntryChanges.count, 1)
    }

    func testOperationMetaXDREncodeDecode() throws {
        let operationMeta = try createOperationMeta()

        let encoded = try XDREncoder.encode(operationMeta)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(OperationMetaXDR.self, data: encoded)

        XCTAssertNotNil(decoded.changes)
        XCTAssertEqual(decoded.changes.ledgerEntryChanges.count, 1)
    }
}
