//
//  PublicKeyTestCase.swift
//  stellarsdk
//
//  Created by Soneso on 03.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class PublicKeyTestCase: XCTestCase {

    // Test vectors from Stellar test networks
    let testAccountId = "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6"
    let testSecretSeed = "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN"

    // Additional test vector
    let testAccountId2 = "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D"

    // Muxed account test vector (M-address that contains the same public key as testAccountId)
    // M-addresses encode both a public key and an ID field
    let testMuxedAccountId = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Test 1: Create PublicKey from Account ID

    func testPublicKeyFromAccountId() throws {
        let publicKey = try PublicKey(accountId: testAccountId)

        // Verify the account ID round-trips correctly
        XCTAssertEqual(publicKey.accountId, testAccountId)

        // Verify the bytes have the correct length
        XCTAssertEqual(publicKey.bytes.count, StellarProtocolConstants.ED25519_PUBLIC_KEY_SIZE)

        // Verify we can recreate the same public key from the bytes
        let publicKey2 = try PublicKey(publicKey.bytes)
        XCTAssertEqual(publicKey2.accountId, testAccountId)
    }

    // MARK: - Test 2: Create PublicKey from Muxed Account ID

    func testPublicKeyFromMuxedAccountId() throws {
        // The PublicKey initializer only accepts G-addresses, not M-addresses
        // Attempting to create from M-address should throw an error
        XCTAssertThrowsError(try PublicKey(accountId: testMuxedAccountId)) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKey = error {
                // Expected error - PublicKey only accepts G-addresses
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // To work with muxed accounts, you need to use the String extension
        // to decode the muxed account and extract the underlying public key
        let muxedAccountXDR = try testMuxedAccountId.decodeMuxedAccount()

        switch muxedAccountXDR {
        case .ed25519(let bytes):
            let publicKey = try PublicKey(bytes)
            XCTAssertEqual(publicKey.bytes.count, StellarProtocolConstants.ED25519_PUBLIC_KEY_SIZE)
        case .med25519(let muxedData):
            let publicKey = try PublicKey(muxedData.sourceAccountEd25519)
            XCTAssertEqual(publicKey.bytes.count, StellarProtocolConstants.ED25519_PUBLIC_KEY_SIZE)
            // Verify the account ID is in G-format
            XCTAssertTrue(publicKey.accountId.hasPrefix("G"))
            XCTAssertEqual(publicKey.accountId.count, StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD)
        }
    }

    // MARK: - Test 3: Create PublicKey from Raw Bytes

    func testPublicKeyFromBytes() throws {
        // First get the bytes from a known account ID
        let referencePublicKey = try PublicKey(accountId: testAccountId)
        let testBytes = referencePublicKey.bytes

        // Create a new public key from those bytes
        let publicKey = try PublicKey(testBytes)

        // Verify the bytes match
        XCTAssertEqual(publicKey.bytes, testBytes)

        // Verify the account ID is generated correctly
        XCTAssertEqual(publicKey.accountId, testAccountId)

        // Verify the account ID has correct format
        XCTAssertTrue(publicKey.accountId.hasPrefix("G"))
        XCTAssertEqual(publicKey.accountId.count, StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD)
    }

    // MARK: - Test 4: Account ID Encoding

    func testAccountIdEncoding() throws {
        // Create from account ID and get the bytes
        let publicKey1 = try PublicKey(accountId: testAccountId)
        let bytes = publicKey1.bytes

        // Create from bytes and verify encoding
        let publicKey2 = try PublicKey(bytes)
        XCTAssertEqual(publicKey2.accountId, testAccountId)

        // Verify both methods produce the same result
        XCTAssertEqual(publicKey1.accountId, publicKey2.accountId)
        XCTAssertEqual(publicKey1.bytes, publicKey2.bytes)

        // Test with second test vector
        let publicKey3 = try PublicKey(accountId: testAccountId2)
        XCTAssertEqual(publicKey3.accountId, testAccountId2)
        XCTAssertTrue(publicKey3.accountId.hasPrefix("G"))
        XCTAssertEqual(publicKey3.accountId.count, StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD)
    }

    // MARK: - Test 5: Verify Signature

    func testVerifySignature() throws {
        // Create a full keypair to sign a message
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let message = "Test message for signature verification".data(using: .utf8)!
        let messageBytes = [UInt8](message)

        // Sign the message with the keypair
        let signature = keyPair.sign(messageBytes)

        // Create a PublicKey from the account ID
        let publicKey = try PublicKey(accountId: testAccountId)

        // Verify the signature with the public key
        let isValid = try publicKey.verify(signature: signature, message: messageBytes)
        XCTAssertTrue(isValid, "Valid signature should verify successfully")

        // Verify with wrong message should fail
        let wrongMessage = "Different message".data(using: .utf8)!
        let wrongMessageBytes = [UInt8](wrongMessage)
        let isInvalid = try publicKey.verify(signature: signature, message: wrongMessageBytes)
        XCTAssertFalse(isInvalid, "Signature should not verify with wrong message")

        // Verify with all-zero signature should fail
        let invalidSignature = [UInt8](repeating: 0, count: 64)
        let isInvalidSig = try publicKey.verify(signature: invalidSignature, message: messageBytes)
        XCTAssertFalse(isInvalidSig, "All-zero signature should not verify")
    }

    // MARK: - Test 6: Invalid Account ID Throws

    func testInvalidAccountIdThrows() {
        // Invalid prefix (should start with G)
        XCTAssertThrowsError(try PublicKey(accountId: "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN")) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKey = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Invalid base32 encoding
        XCTAssertThrowsError(try PublicKey(accountId: "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Invalid characters
        XCTAssertThrowsError(try PublicKey(accountId: "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Too short
        XCTAssertThrowsError(try PublicKey(accountId: "GAAAAAAAACGC6")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Too long
        XCTAssertThrowsError(try PublicKey(accountId: "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Empty string
        XCTAssertThrowsError(try PublicKey(accountId: "")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Muxed account (M-address) should fail
        XCTAssertThrowsError(try PublicKey(accountId: testMuxedAccountId)) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKey = error {
                // Expected error - PublicKey only accepts G-addresses
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Test 7: Invalid Bytes Length Throws

    func testInvalidBytesLengthThrows() {
        // Too short (31 bytes)
        XCTAssertThrowsError(try PublicKey([UInt8](repeating: 0, count: 31))) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKeyLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Too long (33 bytes)
        XCTAssertThrowsError(try PublicKey([UInt8](repeating: 0, count: 33))) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKeyLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Zero bytes
        XCTAssertThrowsError(try PublicKey([UInt8]())) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKeyLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Wrong common sizes
        for length in [0, 1, 16, 64, 128] {
            XCTAssertThrowsError(try PublicKey([UInt8](repeating: 0, count: length)),
                               "Should throw for \(length) bytes") { error in
                XCTAssertTrue(error is Ed25519Error)
                if case Ed25519Error.invalidPublicKeyLength = error {
                    // Expected error
                } else {
                    XCTFail("Wrong error type for \(length) bytes: \(error)")
                }
            }
        }

        // Verify with invalid signature length throws
        let publicKey = try! PublicKey(accountId: testAccountId)
        let message = [UInt8]("test".data(using: .utf8)!)

        XCTAssertThrowsError(try publicKey.verify(signature: [UInt8](repeating: 0, count: 63),
                                                  message: message)) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidSignatureLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        XCTAssertThrowsError(try publicKey.verify(signature: [UInt8](repeating: 0, count: 65),
                                                  message: message)) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidSignatureLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Additional Tests

    func testPublicKeyBytesImmutable() throws {
        let publicKey = try PublicKey(accountId: testAccountId)
        var bytes = publicKey.bytes

        // Modify the bytes array
        bytes[0] = bytes[0] &+ 1

        // Verify original public key bytes are unchanged
        XCTAssertNotEqual(bytes, publicKey.bytes, "Public key bytes should not be affected by external modifications")
    }

    func testDeterministicEncoding() throws {
        // Get the bytes from a known account ID
        let referencePublicKey = try PublicKey(accountId: testAccountId)
        let testBytes = referencePublicKey.bytes

        // Creating a public key from the same bytes should always produce the same account ID
        let publicKey1 = try PublicKey(testBytes)
        let publicKey2 = try PublicKey(testBytes)

        XCTAssertEqual(publicKey1.accountId, publicKey2.accountId)
        XCTAssertEqual(publicKey1.bytes, publicKey2.bytes)
    }

    func testRoundTripEncoding() throws {
        // Start with account ID
        let publicKey1 = try PublicKey(accountId: testAccountId)

        // Extract bytes
        let bytes = publicKey1.bytes

        // Create new public key from bytes
        let publicKey2 = try PublicKey(bytes)

        // Verify they match
        XCTAssertEqual(publicKey1.accountId, publicKey2.accountId)
        XCTAssertEqual(publicKey1.bytes, publicKey2.bytes)
    }

    func testVerifyEmptyMessage() throws {
        // Test signature verification with empty message
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let emptyMessage: [UInt8] = []

        // Sign empty message
        let signature = keyPair.sign(emptyMessage)

        // Verify with public key
        let publicKey = try PublicKey(accountId: testAccountId)
        let isValid = try publicKey.verify(signature: signature, message: emptyMessage)
        XCTAssertTrue(isValid, "Should verify signature for empty message")
    }

    func testVerifyLongMessage() throws {
        // Test signature verification with a long message
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let longMessage = [UInt8](repeating: 0xFF, count: 10000)

        // Sign the long message
        let signature = keyPair.sign(longMessage)

        // Verify with public key
        let publicKey = try PublicKey(accountId: testAccountId)
        let isValid = try publicKey.verify(signature: signature, message: longMessage)
        XCTAssertTrue(isValid, "Should verify signature for long message")
    }

    func testMultipleTestVectors() throws {
        // Test with multiple known test vectors
        let testVectors = [testAccountId, testAccountId2]

        for accountId in testVectors {
            // Test creating from account ID
            let pk1 = try PublicKey(accountId: accountId)
            XCTAssertEqual(pk1.accountId, accountId, "Account ID mismatch for \(accountId)")
            XCTAssertEqual(pk1.bytes.count, StellarProtocolConstants.ED25519_PUBLIC_KEY_SIZE)

            // Test creating from bytes
            let bytes = pk1.bytes
            let pk2 = try PublicKey(bytes)
            XCTAssertEqual(pk2.accountId, accountId, "Account ID mismatch for bytes")

            // Verify they match
            XCTAssertEqual(pk1.bytes, pk2.bytes, "Bytes mismatch for \(accountId)")
        }
    }
}
