//
//  MuxedAccountTestCase.swift
//  stellarsdk
//
//  Created by Soneso on 03.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class MuxedAccountTestCase: XCTestCase {

    // Test vectors from Stellar protocol (CAP-27)
    // The testAccountId and testSecretSeed are a matching keypair
    let testAccountId = "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6"
    let testSecretSeed = "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN"

    // Muxed account test vector (encodes the public key from above with ID)
    // MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK
    // contains the public key for GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ
    // with ID = 0x8000000000000000 (9223372036854775808)
    let testMuxedAccountId = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
    let testMuxedUnderlyingAccountId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    let testMuxedId: UInt64 = 9223372036854775808

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Test 1: Create MuxedAccount from Account ID (G-address)

    func testMuxedAccountFromAccountId() throws {
        // Create a muxed account from a standard G-address
        let account = try MuxedAccount(accountId: testAccountId, sequenceNumber: 100)

        // Verify basic properties
        XCTAssertEqual(account.accountId, testAccountId, "Account ID should match")
        XCTAssertEqual(account.ed25519AccountId, testAccountId, "Ed25519 account ID should match")
        XCTAssertEqual(account.sequenceNumber, 100, "Sequence number should match")
        XCTAssertNil(account.id, "ID should be nil for standard account")

        // Verify XDR type
        switch account.xdr {
        case .ed25519(let bytes):
            XCTAssertEqual(bytes.count, StellarProtocolConstants.ED25519_PUBLIC_KEY_SIZE)
        case .med25519:
            XCTFail("Should be ed25519 type, not med25519")
        }
    }

    // MARK: - Test 2: Create MuxedAccount from M-address

    func testMuxedAccountFromMAddress() throws {
        // Create a muxed account from an M-address
        let account = try MuxedAccount(accountId: testMuxedAccountId, sequenceNumber: 200)

        // Verify the muxed account ID is returned as M-address
        XCTAssertEqual(account.accountId, testMuxedAccountId, "Account ID should be M-address")
        XCTAssertEqual(account.ed25519AccountId, testMuxedUnderlyingAccountId, "Ed25519 account ID should be G-address")
        XCTAssertEqual(account.sequenceNumber, 200, "Sequence number should match")
        XCTAssertEqual(account.id, testMuxedId, "ID should match")

        // Verify XDR type
        switch account.xdr {
        case .ed25519:
            XCTFail("Should be med25519 type, not ed25519")
        case .med25519(let muxed):
            XCTAssertEqual(muxed.id, testMuxedId)
            XCTAssertEqual(muxed.sourceAccountEd25519.count, StellarProtocolConstants.ED25519_PUBLIC_KEY_SIZE)
        }
    }

    // MARK: - Test 3: Create MuxedAccount with ID

    func testMuxedAccountWithId() throws {
        // Create a muxed account with explicit ID
        let keyPair = try KeyPair(accountId: testAccountId)
        let account = MuxedAccount(keyPair: keyPair, sequenceNumber: 300, id: 12345)

        // Verify the account has muxed properties
        XCTAssertNotEqual(account.accountId, testAccountId, "Account ID should be M-address")
        XCTAssertTrue(account.accountId.hasPrefix("M"), "Account ID should start with M")
        XCTAssertEqual(account.accountId.count, StellarProtocolConstants.STRKEY_ENCODED_LENGTH_MUXED)
        XCTAssertEqual(account.ed25519AccountId, testAccountId, "Ed25519 account ID should be G-address")
        XCTAssertEqual(account.sequenceNumber, 300, "Sequence number should match")
        XCTAssertEqual(account.id, 12345, "ID should match")

        // Verify XDR type
        switch account.xdr {
        case .ed25519:
            XCTFail("Should be med25519 type when ID is provided")
        case .med25519(let muxed):
            XCTAssertEqual(muxed.id, 12345)
        }
    }

    // MARK: - Test 4: MuxedAccount Encoding

    func testMuxedAccountEncoding() throws {
        // Create muxed account with ID from the underlying account
        let keyPair = try KeyPair(accountId: testMuxedUnderlyingAccountId)
        let account = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: testMuxedId)

        // Verify encoding produces M-address
        let encodedId = account.accountId
        XCTAssertTrue(encodedId.hasPrefix("M"), "Muxed account should start with M")
        XCTAssertEqual(encodedId.count, StellarProtocolConstants.STRKEY_ENCODED_LENGTH_MUXED)
        XCTAssertEqual(encodedId, testMuxedAccountId, "Encoded address should match test vector")

        // Verify ed25519AccountId returns G-address
        XCTAssertTrue(account.ed25519AccountId.hasPrefix("G"), "Ed25519 account should start with G")
        XCTAssertEqual(account.ed25519AccountId, testMuxedUnderlyingAccountId, "Ed25519 address should match")
    }

    // MARK: - Test 5: MuxedAccount Decoding

    func testMuxedAccountDecoding() throws {
        // Decode M-address to muxed account
        let account = try MuxedAccount(accountId: testMuxedAccountId, sequenceNumber: 0)

        // Verify decoding extracts correct properties
        XCTAssertEqual(account.accountId, testMuxedAccountId)
        XCTAssertEqual(account.ed25519AccountId, testMuxedUnderlyingAccountId)
        XCTAssertEqual(account.id, testMuxedId)
    }

    // MARK: - Test 6: Invalid MuxedAccount Input Throws

    func testInvalidMuxedAccountThrows() {
        // Invalid base32 encoding
        XCTAssertThrowsError(try MuxedAccount(accountId: "MBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL", sequenceNumber: 0)) { error in
            // Should throw KeyUtilsError or Ed25519Error
            XCTAssertTrue(error is KeyUtilsError || error is Ed25519Error)
        }

        // Invalid characters
        XCTAssertThrowsError(try MuxedAccount(accountId: "MCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++", sequenceNumber: 0)) { error in
            XCTAssertTrue(error is KeyUtilsError || error is Ed25519Error)
        }

        // Secret seed should not work
        XCTAssertThrowsError(try MuxedAccount(accountId: testSecretSeed, sequenceNumber: 0)) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Empty string
        XCTAssertThrowsError(try MuxedAccount(accountId: "", sequenceNumber: 0)) { error in
            XCTAssertTrue(error is KeyUtilsError || error is Ed25519Error)
        }

        // Invalid length
        XCTAssertThrowsError(try MuxedAccount(accountId: "GAAAAAAAACGC6", sequenceNumber: 0)) { error in
            XCTAssertTrue(error is KeyUtilsError || error is Ed25519Error)
        }
    }

    // MARK: - Test 7: MuxedAccount XDR Roundtrip

    func testMuxedAccountXDRRoundtrip() throws {
        // Test with standard account (no ID) - use testMuxedUnderlyingAccountId
        let keyPair1 = try KeyPair(accountId: testMuxedUnderlyingAccountId)
        let account1 = MuxedAccount(keyPair: keyPair1, sequenceNumber: 100, id: nil)

        // Encode to XDR
        var xdr1 = try XDREncoder.encode(account1.xdr)
        let xdrData1 = Data(bytes: &xdr1, count: xdr1.count)

        // Decode from XDR
        let decodedXdr1 = try XDRDecoder.decode(MuxedAccountXDR.self, data: xdrData1)

        // Verify roundtrip
        XCTAssertEqual(decodedXdr1.ed25519AccountId, testMuxedUnderlyingAccountId)
        XCTAssertEqual(decodedXdr1.accountId, testMuxedUnderlyingAccountId)
        XCTAssertNil(decodedXdr1.id)

        // Test with muxed account (with ID)
        let keyPair2 = try KeyPair(accountId: testMuxedUnderlyingAccountId)
        let account2 = MuxedAccount(keyPair: keyPair2, sequenceNumber: 200, id: 99999)

        // Encode to XDR
        var xdr2 = try XDREncoder.encode(account2.xdr)
        let xdrData2 = Data(bytes: &xdr2, count: xdr2.count)

        // Decode from XDR
        let decodedXdr2 = try XDRDecoder.decode(MuxedAccountXDR.self, data: xdrData2)

        // Verify roundtrip
        XCTAssertEqual(decodedXdr2.ed25519AccountId, testMuxedUnderlyingAccountId)
        XCTAssertNotEqual(decodedXdr2.accountId, testMuxedUnderlyingAccountId, "Should be M-address")
        XCTAssertTrue(decodedXdr2.accountId.hasPrefix("M"))
        XCTAssertEqual(decodedXdr2.id, 99999)
    }

    // MARK: - Additional Tests

    func testMuxedAccountWithSecretSeed() throws {
        // Create muxed account from secret seed
        let account1 = try MuxedAccount(secretSeed: testSecretSeed, sequenceNumber: 500)

        // Should create standard account without ID
        XCTAssertEqual(account1.accountId, testAccountId)
        XCTAssertNil(account1.id)

        // Create muxed account from secret seed with ID
        let account2 = try MuxedAccount(secretSeed: testSecretSeed, sequenceNumber: 600, id: 777)

        // Should create muxed account with ID
        XCTAssertTrue(account2.accountId.hasPrefix("M"))
        XCTAssertEqual(account2.ed25519AccountId, testAccountId)
        XCTAssertEqual(account2.id, 777)
    }

    func testMuxedAccountIdParameterIgnoredWithMAddress() throws {
        // When providing M-address, the id parameter should be ignored
        let account = try MuxedAccount(accountId: testMuxedAccountId, sequenceNumber: 0, id: 99999)

        // Should use ID from M-address, not from parameter
        XCTAssertEqual(account.id, testMuxedId, "Should use ID from M-address")
        XCTAssertNotEqual(account.id, 99999, "Should ignore id parameter")
    }

    func testMuxedAccountSequenceNumberManipulation() throws {
        let keyPair = try KeyPair(accountId: testAccountId)
        let account = MuxedAccount(keyPair: keyPair, sequenceNumber: 100, id: 123)

        // Test sequence number methods
        XCTAssertEqual(account.sequenceNumber, 100)
        XCTAssertEqual(account.incrementedSequenceNumber(), 101)
        XCTAssertEqual(account.sequenceNumber, 100, "Should not modify internal counter")

        account.incrementSequenceNumber()
        XCTAssertEqual(account.sequenceNumber, 101)

        account.decrementSequenceNumber()
        XCTAssertEqual(account.sequenceNumber, 100)
    }

    func testMuxedAccountDefaultSequenceNumber() throws {
        // When sequence number is not provided, it should default to 0
        let account = try MuxedAccount(accountId: testAccountId)
        XCTAssertEqual(account.sequenceNumber, 0)

        let account2 = try MuxedAccount(accountId: testMuxedAccountId)
        XCTAssertEqual(account2.sequenceNumber, 0)
    }

    func testMuxedAccountMaxId() throws {
        // Test with maximum UInt64 value
        let maxId: UInt64 = UInt64.max
        let keyPair = try KeyPair(accountId: testMuxedUnderlyingAccountId)
        let account = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: maxId)

        XCTAssertEqual(account.id, maxId)
        XCTAssertTrue(account.accountId.hasPrefix("M"))

        // Verify XDR encoding works with max ID
        switch account.xdr {
        case .med25519(let muxed):
            XCTAssertEqual(muxed.id, maxId)
        case .ed25519:
            XCTFail("Should be med25519 type")
        }
    }

    func testMuxedAccountEqualityOfUnderlyingPublicKey() throws {
        // Create accounts with different IDs but same underlying public key
        let keyPair = try KeyPair(accountId: testMuxedUnderlyingAccountId)
        let account1 = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: 111)
        let account2 = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: 222)
        let account3 = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: nil)

        // All should have same ed25519 account ID
        XCTAssertEqual(account1.ed25519AccountId, testMuxedUnderlyingAccountId)
        XCTAssertEqual(account2.ed25519AccountId, testMuxedUnderlyingAccountId)
        XCTAssertEqual(account3.ed25519AccountId, testMuxedUnderlyingAccountId)

        // But different accountId for muxed accounts
        XCTAssertNotEqual(account1.accountId, account2.accountId)
        XCTAssertNotEqual(account1.accountId, account3.accountId)
        XCTAssertNotEqual(account2.accountId, account3.accountId)

        // IDs should be different
        XCTAssertNotEqual(account1.id, account2.id)
        XCTAssertNil(account3.id)
    }

    func testMuxedAccountKeyPairAccess() throws {
        let keyPair = try KeyPair(accountId: testMuxedUnderlyingAccountId)
        let account = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: 456)

        // Verify keyPair property is accessible
        XCTAssertEqual(account.keyPair.accountId, testMuxedUnderlyingAccountId)
        XCTAssertNotNil(account.keyPair.publicKey)
    }

    func testMuxedAccountFromAccountIdWithSecretSeed() throws {
        // Test the initializer that accepts both accountId and secretSeed
        // testAccountId and testSecretSeed are a matching keypair
        let account1 = try MuxedAccount(accountId: testAccountId, secretSeed: testSecretSeed, sequenceNumber: 100)
        XCTAssertEqual(account1.accountId, testAccountId)
        XCTAssertNil(account1.id)

        // Create an M-address from testAccountId with an ID
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let muxedAccount = MuxedAccount(keyPair: keyPair, sequenceNumber: 0, id: testMuxedId)
        let muxedAddress = muxedAccount.accountId

        // Test with M-address and matching secret seed
        let account2 = try MuxedAccount(accountId: muxedAddress, secretSeed: testSecretSeed, sequenceNumber: 200)
        XCTAssertEqual(account2.accountId, muxedAddress)
        XCTAssertEqual(account2.id, testMuxedId)
        XCTAssertEqual(account2.ed25519AccountId, testAccountId)
    }

    func testMultipleMuxedAccountTestVectors() throws {
        // Test with multiple known test vectors
        let testVectors: [(String, UInt64?)] = [
            (testAccountId, nil),
            (testMuxedAccountId, testMuxedId),
            (testMuxedUnderlyingAccountId, nil)
        ]

        for (accountId, expectedId) in testVectors {
            let account = try MuxedAccount(accountId: accountId, sequenceNumber: 0)
            XCTAssertEqual(account.accountId, accountId, "Account ID mismatch for \(accountId)")
            XCTAssertEqual(account.id, expectedId, "ID mismatch for \(accountId)")

            // Verify ed25519AccountId is always G-address
            XCTAssertTrue(account.ed25519AccountId.hasPrefix("G"))
            XCTAssertEqual(account.ed25519AccountId.count, StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD)
        }
    }
}
