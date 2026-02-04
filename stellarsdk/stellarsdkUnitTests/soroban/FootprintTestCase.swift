//
//  FootprintTestCase.swift
//  stellarsdkTests
//
//  Created by Claude Code
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class FootprintTestCase: XCTestCase {

    // MARK: - Footprint Creation Tests

    func testFootprintCreation() throws {
        // Create empty footprint
        let emptyFootprint = Footprint.empty()

        XCTAssertNotNil(emptyFootprint.xdrFootprint)
        XCTAssertEqual(emptyFootprint.xdrFootprint.readOnly.count, 0)
        XCTAssertEqual(emptyFootprint.xdrFootprint.readWrite.count, 0)

        // Verify XDR encoding works
        let xdrEncoded = emptyFootprint.xdrEncoded
        XCTAssertFalse(xdrEncoded.isEmpty)

        // Verify we can decode it back
        let decoded = try Footprint(fromBase64: xdrEncoded)
        XCTAssertEqual(decoded.xdrFootprint.readOnly.count, 0)
        XCTAssertEqual(decoded.xdrFootprint.readWrite.count, 0)
    }

    func testFootprintXDRRoundtrip() throws {
        // Create a footprint with XDR
        let xdrFootprint = LedgerFootprintXDR(readOnly: [], readWrite: [])
        let footprint = Footprint(xdrFootprint: xdrFootprint)

        // Encode to base64
        let encoded = footprint.xdrEncoded
        XCTAssertFalse(encoded.isEmpty)

        // Decode back
        let decoded = try Footprint(fromBase64: encoded)

        // Verify structure is preserved
        XCTAssertEqual(decoded.xdrFootprint.readOnly.count, footprint.xdrFootprint.readOnly.count)
        XCTAssertEqual(decoded.xdrFootprint.readWrite.count, footprint.xdrFootprint.readWrite.count)
    }

    // MARK: - Footprint with Read-Only Entries Tests

    func testFootprintWithReadOnly() throws {
        // Create a contract code ledger key
        let contractCodeKey = try createContractCodeLedgerKey()

        // Create footprint with read-only entry
        let xdrFootprint = LedgerFootprintXDR(
            readOnly: [contractCodeKey],
            readWrite: []
        )
        let footprint = Footprint(xdrFootprint: xdrFootprint)

        // Verify read-only entries
        XCTAssertEqual(footprint.xdrFootprint.readOnly.count, 1)
        XCTAssertEqual(footprint.xdrFootprint.readWrite.count, 0)

        // Verify contract code key can be extracted
        XCTAssertNotNil(footprint.contractCodeLedgerKey)
        XCTAssertNotNil(footprint.contractCodeLedgerKeyXDR)

        // Test XDR roundtrip
        let encoded = footprint.xdrEncoded
        let decoded = try Footprint(fromBase64: encoded)

        XCTAssertEqual(decoded.xdrFootprint.readOnly.count, 1)
        XCTAssertEqual(decoded.xdrFootprint.readWrite.count, 0)
        XCTAssertNotNil(decoded.contractCodeLedgerKey)
    }

    // MARK: - Footprint with Read-Write Entries Tests

    func testFootprintWithReadWrite() throws {
        // Create a contract data ledger key
        let contractDataKey = try createContractDataLedgerKey()

        // Create footprint with read-write entry
        let xdrFootprint = LedgerFootprintXDR(
            readOnly: [],
            readWrite: [contractDataKey]
        )
        let footprint = Footprint(xdrFootprint: xdrFootprint)

        // Verify read-write entries
        XCTAssertEqual(footprint.xdrFootprint.readOnly.count, 0)
        XCTAssertEqual(footprint.xdrFootprint.readWrite.count, 1)

        // Verify contract data key can be extracted
        XCTAssertNotNil(footprint.contractDataLedgerKey)
        XCTAssertNotNil(footprint.contractDataLedgerKeyXDR)

        // Test XDR roundtrip
        let encoded = footprint.xdrEncoded
        let decoded = try Footprint(fromBase64: encoded)

        XCTAssertEqual(decoded.xdrFootprint.readOnly.count, 0)
        XCTAssertEqual(decoded.xdrFootprint.readWrite.count, 1)
        XCTAssertNotNil(decoded.contractDataLedgerKey)
    }

    func testFootprintWithBothReadOnlyAndReadWrite() throws {
        // Create both types of keys
        let contractCodeKey = try createContractCodeLedgerKey()
        let contractDataKey = try createContractDataLedgerKey()

        // Create footprint with both read-only and read-write entries
        let xdrFootprint = LedgerFootprintXDR(
            readOnly: [contractCodeKey],
            readWrite: [contractDataKey]
        )
        let footprint = Footprint(xdrFootprint: xdrFootprint)

        // Verify both entry types
        XCTAssertEqual(footprint.xdrFootprint.readOnly.count, 1)
        XCTAssertEqual(footprint.xdrFootprint.readWrite.count, 1)

        // Verify both keys can be extracted
        XCTAssertNotNil(footprint.contractCodeLedgerKey)
        XCTAssertNotNil(footprint.contractDataLedgerKey)

        // Test XDR roundtrip
        let encoded = footprint.xdrEncoded
        let decoded = try Footprint(fromBase64: encoded)

        XCTAssertEqual(decoded.xdrFootprint.readOnly.count, 1)
        XCTAssertEqual(decoded.xdrFootprint.readWrite.count, 1)
    }

    // MARK: - Ledger Key Parsing Tests

    func testLedgerKeyParsing() throws {
        // Test contract code key extraction
        let contractCodeKey = try createContractCodeLedgerKey()
        let footprintWithCode = Footprint(xdrFootprint: LedgerFootprintXDR(
            readOnly: [contractCodeKey],
            readWrite: []
        ))

        XCTAssertNotNil(footprintWithCode.contractCodeLedgerKey)
        XCTAssertNil(footprintWithCode.contractDataLedgerKey)

        // Verify the key can be encoded
        let codeKeyString = footprintWithCode.contractCodeLedgerKey!
        XCTAssertFalse(codeKeyString.isEmpty)

        // Test contract data key extraction
        let contractDataKey = try createContractDataLedgerKey()
        let footprintWithData = Footprint(xdrFootprint: LedgerFootprintXDR(
            readOnly: [],
            readWrite: [contractDataKey]
        ))

        XCTAssertNil(footprintWithData.contractCodeLedgerKey)
        XCTAssertNotNil(footprintWithData.contractDataLedgerKey)

        // Verify the key can be encoded
        let dataKeyString = footprintWithData.contractDataLedgerKey!
        XCTAssertFalse(dataKeyString.isEmpty)
    }

    func testLedgerKeyParsingMultipleEntries() throws {
        // Create multiple keys of the same type
        let contractCodeKey1 = try createContractCodeLedgerKey()
        let contractCodeKey2 = try createContractCodeLedgerKey()

        let footprint = Footprint(xdrFootprint: LedgerFootprintXDR(
            readOnly: [contractCodeKey1, contractCodeKey2],
            readWrite: []
        ))

        // Should return the first contract code key
        XCTAssertNotNil(footprint.contractCodeLedgerKey)
        XCTAssertNotNil(footprint.contractCodeLedgerKeyXDR)

        // Verify XDR contains both keys
        XCTAssertEqual(footprint.xdrFootprint.readOnly.count, 2)
    }

    func testLedgerKeyParsingNoMatchingKeys() throws {
        // Create an account ledger key (not contract code or data)
        let accountKey = try createAccountLedgerKey()

        let footprint = Footprint(xdrFootprint: LedgerFootprintXDR(
            readOnly: [accountKey],
            readWrite: []
        ))

        // Should return nil for contract-specific keys
        XCTAssertNil(footprint.contractCodeLedgerKey)
        XCTAssertNil(footprint.contractDataLedgerKey)
        XCTAssertNil(footprint.contractCodeLedgerKeyXDR)
        XCTAssertNil(footprint.contractDataLedgerKeyXDR)
    }

    func testLedgerKeyParsingSearchesBothArrays() throws {
        // Place contract code in read-write instead of read-only
        let contractCodeKey = try createContractCodeLedgerKey()

        let footprint = Footprint(xdrFootprint: LedgerFootprintXDR(
            readOnly: [],
            readWrite: [contractCodeKey]
        ))

        // Should still find it in read-write array
        XCTAssertNotNil(footprint.contractCodeLedgerKey)
        XCTAssertNotNil(footprint.contractCodeLedgerKeyXDR)
    }

    // MARK: - Error Handling Tests

    func testInvalidBase64Decoding() {
        // Test with invalid base64 string
        XCTAssertThrowsError(try Footprint(fromBase64: "invalid base64!@#$%"))
    }

    func testCorruptedXDRData() {
        // Create valid footprint and corrupt its XDR
        let footprint = Footprint.empty()
        var corruptedBase64 = footprint.xdrEncoded

        // Corrupt the base64 string by changing characters
        if corruptedBase64.count > 4 {
            let index = corruptedBase64.index(corruptedBase64.startIndex, offsetBy: 4)
            corruptedBase64.replaceSubrange(index...index, with: "X")
        }

        // Attempt to decode corrupted data
        XCTAssertThrowsError(try Footprint(fromBase64: corruptedBase64))
    }

    // MARK: - Helper Methods

    private func createContractCodeLedgerKey() throws -> LedgerKeyXDR {
        // Create a contract code ledger key with dummy hash
        let hash = WrappedData32(Data(repeating: 0x01, count: 32))
        return LedgerKeyXDR.contractCode(
            LedgerKeyContractCodeXDR(hash: hash)
        )
    }

    private func createContractDataLedgerKey() throws -> LedgerKeyXDR {
        // Create a contract data ledger key
        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let contractAddress = try SCAddressXDR(contractId: contractId)

        let key = SCValXDR.symbol("balance")
        let durability = ContractDataDurability.persistent

        return LedgerKeyXDR.contractData(
            LedgerKeyContractDataXDR(
                contract: contractAddress,
                key: key,
                durability: durability
            )
        )
    }

    private func createAccountLedgerKey() throws -> LedgerKeyXDR {
        // Create an account ledger key
        let accountId = "GBDQ3KSNQ4ZRJFQFYAOBQJF7FCCR5MQUUTF6FJ6OHB4DMFK4YA5KTZLV"
        let publicKey = try PublicKey(accountId: accountId)

        return LedgerKeyXDR.account(
            LedgerKeyAccountXDR(accountID: publicKey)
        )
    }
}
