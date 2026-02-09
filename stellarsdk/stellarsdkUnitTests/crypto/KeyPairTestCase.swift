//
//  KeyPairTestCase.swift
//  stellarsdk
//
//  Created by Soneso on 03.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class KeyPairTestCase: XCTestCase {

    // Test vectors from Stellar documentation and test networks
    let testSecretSeed = "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN"
    let testAccountId = "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6"

    let testSecretSeed2 = "SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7"
    let testAccountId2 = "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Test 1: Generate Random KeyPair

    func testGenerateRandomKeyPair() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()

        // Verify accountId is valid G-address
        XCTAssertTrue(keyPair.accountId.hasPrefix("G"))
        XCTAssertTrue(keyPair.accountId.isValidEd25519PublicKey())
        XCTAssertEqual(keyPair.accountId.count, 56)

        // Verify secretSeed is valid S-address
        XCTAssertNotNil(keyPair.secretSeed)
        let secretSeed = try XCTUnwrap(keyPair.secretSeed)
        XCTAssertTrue(secretSeed.hasPrefix("S"))
        XCTAssertTrue(secretSeed.isValidEd25519SecretSeed())
        XCTAssertEqual(secretSeed.count, 56)

        // Verify keypair has both public and private keys
        XCTAssertNotNil(keyPair.privateKey)
        XCTAssertNotNil(keyPair.seed)
        XCTAssertEqual(keyPair.publicKey.bytes.count, 32)
        XCTAssertEqual(keyPair.privateKey?.bytes.count, 64)

        // Generate another keypair and verify they're different
        let keyPair2 = try KeyPair.generateRandomKeyPair()
        XCTAssertNotEqual(keyPair.accountId, keyPair2.accountId)
        XCTAssertNotEqual(keyPair.secretSeed, keyPair2.secretSeed)
    }

    // MARK: - Test 2: Create KeyPair from Secret Seed

    func testKeyPairFromSecretSeed() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)

        // Verify the keypair generates the correct account ID
        XCTAssertEqual(keyPair.accountId, testAccountId)
        XCTAssertEqual(keyPair.secretSeed, testSecretSeed)

        // Verify keypair has both public and private keys
        XCTAssertNotNil(keyPair.privateKey)
        XCTAssertNotNil(keyPair.seed)
        XCTAssertEqual(keyPair.publicKey.bytes.count, 32)
        XCTAssertEqual(keyPair.privateKey?.bytes.count, 64)

        // Test with second test vector
        let keyPair2 = try KeyPair(secretSeed: testSecretSeed2)
        XCTAssertEqual(keyPair2.accountId, testAccountId2)
        XCTAssertEqual(keyPair2.secretSeed, testSecretSeed2)
    }

    // MARK: - Test 3: Create KeyPair from Account ID

    func testKeyPairFromAccountId() throws {
        let keyPair = try KeyPair(accountId: testAccountId)

        // Verify the accountId matches
        XCTAssertEqual(keyPair.accountId, testAccountId)

        // Verify this is a public-only keypair
        XCTAssertNil(keyPair.privateKey)
        XCTAssertNil(keyPair.seed)
        XCTAssertNil(keyPair.secretSeed)

        // Verify public key exists
        XCTAssertEqual(keyPair.publicKey.bytes.count, 32)

        // Test with second test vector
        let keyPair2 = try KeyPair(accountId: testAccountId2)
        XCTAssertEqual(keyPair2.accountId, testAccountId2)
        XCTAssertNil(keyPair2.privateKey)
    }

    // MARK: - Test 4: Create KeyPair from Seed Object

    func testKeyPairFromSeed() throws {
        let seed = try Seed(secret: testSecretSeed)
        let keyPair = KeyPair(seed: seed)

        // Verify the keypair generates the correct account ID
        XCTAssertEqual(keyPair.accountId, testAccountId)
        XCTAssertEqual(keyPair.secretSeed, testSecretSeed)

        // Verify keypair has both public and private keys
        XCTAssertNotNil(keyPair.privateKey)
        XCTAssertNotNil(keyPair.seed)
        XCTAssertEqual(keyPair.publicKey.bytes.count, 32)
        XCTAssertEqual(keyPair.privateKey?.bytes.count, 64)

        // Verify the seed bytes match
        XCTAssertEqual(keyPair.seed?.bytes, seed.bytes)
    }

    // MARK: - Test 5: Create KeyPair from Raw Keys

    func testKeyPairFromRawKeys() throws {
        // First create a keypair from secret seed to get the raw keys
        let referenceKeyPair = try KeyPair(secretSeed: testSecretSeed)
        let publicKeyBytes = referenceKeyPair.publicKey.bytes
        let privateKeyBytes = try XCTUnwrap(referenceKeyPair.privateKey?.bytes)

        // Create a new keypair from the raw keys
        let keyPair = try KeyPair(publicKey: publicKeyBytes, privateKey: privateKeyBytes)

        // Verify the keypair generates the correct account ID
        XCTAssertEqual(keyPair.accountId, testAccountId)

        // Verify keypair has both public and private keys
        XCTAssertNotNil(keyPair.privateKey)
        XCTAssertEqual(keyPair.publicKey.bytes.count, 32)
        XCTAssertEqual(keyPair.privateKey?.bytes.count, 64)

        // Note: seed will be nil when created from raw keys
        XCTAssertNil(keyPair.seed)
        XCTAssertNil(keyPair.secretSeed)
    }

    // MARK: - Test 6: Sign Message

    func testSignMessage() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let message = "Test message".data(using: .utf8)!

        let signature = keyPair.sign([UInt8](message))

        // Verify signature has correct length
        XCTAssertEqual(signature.count, 64)

        // Verify signature is not all zeros
        let isAllZeros = signature.allSatisfy { $0 == 0 }
        XCTAssertFalse(isAllZeros)
    }

    // MARK: - Test 7: Sign Empty Message

    func testSignEmptyMessage() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let emptyMessage: [UInt8] = []

        let signature = keyPair.sign(emptyMessage)

        // Verify signature has correct length
        XCTAssertEqual(signature.count, 64)

        // Verify signature is not all zeros
        let isAllZeros = signature.allSatisfy { $0 == 0 }
        XCTAssertFalse(isAllZeros)
    }

    // MARK: - Test 8: Verify Signature

    func testVerifySignature() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let message = "Test message for signature verification".data(using: .utf8)!
        let messageBytes = [UInt8](message)

        // Sign the message
        let signature = keyPair.sign(messageBytes)

        // Verify with the signing keypair
        let isValid = try keyPair.verify(signature: signature, message: messageBytes)
        XCTAssertTrue(isValid)

        // Verify with a public-only keypair created from account ID
        let publicKeyPair = try KeyPair(accountId: keyPair.accountId)
        let isValidPublic = try publicKeyPair.verify(signature: signature, message: messageBytes)
        XCTAssertTrue(isValidPublic)
    }

    // MARK: - Test 9: Verify Invalid Signature

    func testVerifyInvalidSignature() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let message = "Test message".data(using: .utf8)!
        let messageBytes = [UInt8](message)

        // Create an invalid signature (all zeros)
        let invalidSignature = [UInt8](repeating: 0, count: 64)

        // Verify should return false for invalid signature
        let isValid = try keyPair.verify(signature: invalidSignature, message: messageBytes)
        XCTAssertFalse(isValid)
    }

    // MARK: - Test 10: Verify Wrong Message

    func testVerifyWrongMessage() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let message1 = "Original message".data(using: .utf8)!
        let message2 = "Different message".data(using: .utf8)!

        // Sign the first message
        let signature = keyPair.sign([UInt8](message1))

        // Verify with the wrong message should return false
        let isValid = try keyPair.verify(signature: signature, message: [UInt8](message2))
        XCTAssertFalse(isValid)
    }

    // MARK: - Test 11: Sign Decorated Signature

    func testSignDecoratedSignature() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let message = "Test message for decorated signature".data(using: .utf8)!
        let messageBytes = [UInt8](message)

        let decoratedSignature = keyPair.signDecorated(messageBytes)

        // Verify signature length
        XCTAssertEqual(decoratedSignature.signature.count, 64)

        // Verify hint length (should be 4 bytes)
        XCTAssertEqual(decoratedSignature.hint.wrapped.count, 4)

        // Verify the hint is the last 4 bytes of the public key
        let publicKeyBytes = keyPair.publicKey.bytes
        let expectedHint = Data(publicKeyBytes.suffix(4))
        XCTAssertEqual(decoratedSignature.hint.wrapped, expectedHint)

        // Verify the signature is valid
        let signatureBytes = [UInt8](decoratedSignature.signature)
        let isValid = try keyPair.verify(signature: signatureBytes, message: messageBytes)
        XCTAssertTrue(isValid)
    }

    // MARK: - Test 12: Sign Payload Decorated (CAP-40)

    func testSignPayloadDecorated() throws {
        let keyPair = try KeyPair(secretSeed: testSecretSeed)
        let payload = "Test payload for CAP-40 signing".data(using: .utf8)!
        let payloadBytes = [UInt8](payload)

        let decoratedSignature = keyPair.signPayloadDecorated(payloadBytes)

        // Verify signature length
        XCTAssertEqual(decoratedSignature.signature.count, 64)

        // Verify hint length (should be 4 bytes)
        XCTAssertEqual(decoratedSignature.hint.wrapped.count, 4)

        // For CAP-40, the hint should be XOR-ed with the last 4 bytes of the payload
        // So it should NOT match the last 4 bytes of the public key directly
        let publicKeyBytes = keyPair.publicKey.bytes
        let publicKeyHint = Data(publicKeyBytes.suffix(4))
        XCTAssertNotEqual(decoratedSignature.hint.wrapped, publicKeyHint)

        // Verify the signature is valid for the payload
        let signatureBytes = [UInt8](decoratedSignature.signature)
        let isValid = try keyPair.verify(signature: signatureBytes, message: payloadBytes)
        XCTAssertTrue(isValid)
    }

    // MARK: - Test 13: Invalid Secret Seed Throws

    func testInvalidSecretSeedThrows() {
        // Invalid prefix (should start with S)
        XCTAssertThrowsError(try KeyPair(secretSeed: "GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4")) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidSeed = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Invalid base32 encoding (contains invalid character '0')
        XCTAssertThrowsError(try KeyPair(secretSeed: "SB0WKTN3OKOK5JXZXOAJCGRZGVQQR4EWIVPS52PON2GGKDHUOWDAIZNQ")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Note: The SDK's Seed initializer uses base32DecodedData which may not validate checksums
        // properly. This is a potential SDK issue. We test what actually throws errors.
        // Invalid base32 decoding (missing characters)
        XCTAssertThrowsError(try KeyPair(secretSeed: "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36X")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Too short
        XCTAssertThrowsError(try KeyPair(secretSeed: "SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEV")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Too long
        XCTAssertThrowsError(try KeyPair(secretSeed: "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMNT")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }
    }

    // MARK: - Test 14: Invalid Account ID Throws

    func testInvalidAccountIdThrows() {
        // Invalid prefix (should start with G)
        XCTAssertThrowsError(try KeyPair(accountId: "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN")) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKey = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Invalid base32 encoding
        XCTAssertThrowsError(try KeyPair(accountId: "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Invalid characters
        XCTAssertThrowsError(try KeyPair(accountId: "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Too short
        XCTAssertThrowsError(try KeyPair(accountId: "GAAAAAAAACGC6")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }

        // Too long
        XCTAssertThrowsError(try KeyPair(accountId: "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T")) { error in
            XCTAssertTrue(error is Ed25519Error)
        }
    }

    // MARK: - Test 15: Invalid Key Length Throws

    func testInvalidKeyLengthThrows() {
        // Public key too short
        XCTAssertThrowsError(try KeyPair(publicKey: [UInt8](repeating: 0, count: 31),
                                        privateKey: [UInt8](repeating: 0, count: 64))) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKeyLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Public key too long
        XCTAssertThrowsError(try KeyPair(publicKey: [UInt8](repeating: 0, count: 33),
                                        privateKey: [UInt8](repeating: 0, count: 64))) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPublicKeyLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Private key too short
        XCTAssertThrowsError(try KeyPair(publicKey: [UInt8](repeating: 0, count: 32),
                                        privateKey: [UInt8](repeating: 0, count: 63))) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPrivateKeyLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Private key too long
        XCTAssertThrowsError(try KeyPair(publicKey: [UInt8](repeating: 0, count: 32),
                                        privateKey: [UInt8](repeating: 0, count: 65))) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidPrivateKeyLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Verify with invalid signature length
        let keyPair = try! KeyPair(secretSeed: testSecretSeed)
        let message = [UInt8]("test".data(using: .utf8)!)

        XCTAssertThrowsError(try keyPair.verify(signature: [UInt8](repeating: 0, count: 63),
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

    func testPublicOnlyKeyPairCannotSign() throws {
        // Create a public-only keypair
        let publicKeyPair = try KeyPair(accountId: testAccountId)
        let message = "Test message".data(using: .utf8)!

        // Signing with a public-only keypair should return all zeros
        let signature = publicKeyPair.sign([UInt8](message))

        // Verify signature is all zeros
        let isAllZeros = signature.allSatisfy { $0 == 0 }
        XCTAssertTrue(isAllZeros)
    }

    func testDeterministicKeyGeneration() throws {
        // Creating a keypair from the same secret seed should always produce the same keys
        let keyPair1 = try KeyPair(secretSeed: testSecretSeed)
        let keyPair2 = try KeyPair(secretSeed: testSecretSeed)

        XCTAssertEqual(keyPair1.accountId, keyPair2.accountId)
        XCTAssertEqual(keyPair1.secretSeed, keyPair2.secretSeed)
        XCTAssertEqual(keyPair1.publicKey.bytes, keyPair2.publicKey.bytes)
        XCTAssertEqual(keyPair1.privateKey?.bytes, keyPair2.privateKey?.bytes)
    }

    func testRoundTripEncoding() throws {
        // Generate a keypair
        let originalKeyPair = try KeyPair.generateRandomKeyPair()

        // Get the secret seed
        let secretSeed = try XCTUnwrap(originalKeyPair.secretSeed)

        // Create a new keypair from the secret seed
        let restoredKeyPair = try KeyPair(secretSeed: secretSeed)

        // Verify they match
        XCTAssertEqual(originalKeyPair.accountId, restoredKeyPair.accountId)
        XCTAssertEqual(originalKeyPair.publicKey.bytes, restoredKeyPair.publicKey.bytes)
    }
}
