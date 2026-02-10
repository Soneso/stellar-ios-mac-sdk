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

    // MARK: - SEP-53: Sign and Verify Messages

    // SEP-53 test keypair constants
    private let sep53Seed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW"
    private let sep53AccountId = "GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L"

    private func hexToBytes(_ hex: String) -> [UInt8] {
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            bytes.append(UInt8(byteString, radix: 16)!)
            index = nextIndex
        }
        return bytes
    }

    private func bytesToHex(_ bytes: [UInt8]) -> String {
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    // Test 1: Sign an ASCII string message and verify the expected signature
    func testSEP53SignMessageASCII() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        XCTAssertEqual(keyPair.accountId, sep53AccountId)

        let signature = try keyPair.signMessage("Hello, World!")
        XCTAssertEqual(
            bytesToHex(signature),
            "7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04"
        )
    }

    // Test 2: Sign a UTF-8 string message with multibyte characters
    func testSEP53SignMessageUTF8() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)

        let signature = try keyPair.signMessage("こんにちは、世界！")
        XCTAssertEqual(
            bytesToHex(signature),
            "083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604"
        )
    }

    // Test 3: Sign a binary message (raw bytes)
    func testSEP53SignMessageBinary() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let binaryData = Data(base64Encoded: "2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=")!
        let binaryBytes = [UInt8](binaryData)

        let signature = try keyPair.signMessage(binaryBytes)
        XCTAssertEqual(
            bytesToHex(signature),
            "540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d"
        )
    }

    // Test 4: Verify an ASCII string message with a known-good signature
    func testSEP53VerifyMessageASCII() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let sig = hexToBytes("7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04")

        let isValid = try keyPair.verifyMessage("Hello, World!", signature: sig)
        XCTAssertTrue(isValid)
    }

    // Test 5: Verify a UTF-8 string message with a known-good signature
    func testSEP53VerifyMessageUTF8() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let sig = hexToBytes("083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604")

        let isValid = try keyPair.verifyMessage("こんにちは、世界！", signature: sig)
        XCTAssertTrue(isValid)
    }

    // Test 6: Verify a binary message with a known-good signature
    func testSEP53VerifyMessageBinary() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let binaryData = Data(base64Encoded: "2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=")!
        let binaryBytes = [UInt8](binaryData)
        let sig = hexToBytes("540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d")

        let isValid = try keyPair.verifyMessage(binaryBytes, signature: sig)
        XCTAssertTrue(isValid)
    }

    // Test 7: Verify a message using a public-key-only keypair
    func testSEP53VerifyWithPublicKeyOnly() throws {
        let fullKeyPair = try KeyPair(secretSeed: sep53Seed)
        let signature = try fullKeyPair.signMessage("Hello, World!")

        let publicKeyPair = try KeyPair(accountId: sep53AccountId)
        let isValid = try publicKeyPair.verifyMessage("Hello, World!", signature: signature)
        XCTAssertTrue(isValid)
    }

    // Test 8: Verify returns false for an invalid (all-zeros) signature
    func testSEP53VerifyInvalidSignature() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let invalidSig = [UInt8](repeating: 0, count: 64)

        let isValid = try keyPair.verifyMessage("Hello, World!", signature: invalidSig)
        XCTAssertFalse(isValid)
    }

    // Test 9: Verify returns false when the message does not match the signature
    func testSEP53VerifyWrongMessage() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let signature = try keyPair.signMessage("message A")

        let isValid = try keyPair.verifyMessage("message B", signature: signature)
        XCTAssertFalse(isValid)
    }

    // Test 10: Verify returns false when using a different key
    func testSEP53VerifyWrongKey() throws {
        let signingKeyPair = try KeyPair(secretSeed: sep53Seed)
        let signature = try signingKeyPair.signMessage("Hello, World!")

        let wrongKeyPair = try KeyPair(accountId: testAccountId)
        let isValid = try wrongKeyPair.verifyMessage("Hello, World!", signature: signature)
        XCTAssertFalse(isValid)
    }

    // Test 11: Verify throws for a signature that is too short (63 bytes)
    func testSEP53VerifyInvalidSignatureLength() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let shortSig = [UInt8](repeating: 0, count: 63)

        XCTAssertThrowsError(try keyPair.verifyMessage("Hello, World!", signature: shortSig)) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidSignatureLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // Test 12: Signing with a public-key-only keypair throws missingPrivateKey
    func testSEP53SignWithPublicKeyOnlyThrows() throws {
        let publicKeyPair = try KeyPair(accountId: sep53AccountId)

        XCTAssertThrowsError(try publicKeyPair.signMessage("test")) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.missingPrivateKey = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Also test binary variant
        XCTAssertThrowsError(try publicKeyPair.signMessage([UInt8]("test".utf8))) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.missingPrivateKey = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // Test 13: Sign and verify an empty string message (round-trip)
    func testSEP53SignEmptyStringMessage() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)

        let signature = try keyPair.signMessage("")
        let isValid = try keyPair.verifyMessage("", signature: signature)
        XCTAssertTrue(isValid)
    }

    // Test 14: Sign and verify an empty binary message (round-trip)
    func testSEP53SignEmptyBinaryMessage() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let emptyBytes: [UInt8] = []

        let signature = try keyPair.signMessage(emptyBytes)
        let isValid = try keyPair.verifyMessage(emptyBytes, signature: signature)
        XCTAssertTrue(isValid)
    }

    // Test 15: Round-trip sign and verify a string message with a random keypair
    func testSEP53RoundTripStringMessage() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()

        let signature = try keyPair.signMessage("arbitrary test message for round trip")
        let isValid = try keyPair.verifyMessage("arbitrary test message for round trip", signature: signature)
        XCTAssertTrue(isValid)
    }

    // Test 16: Round-trip sign and verify a binary message with a random keypair
    func testSEP53RoundTripBinaryMessage() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let binaryMessage = [UInt8](repeating: 0xAB, count: 256)

        let signature = try keyPair.signMessage(binaryMessage)
        let isValid = try keyPair.verifyMessage(binaryMessage, signature: signature)
        XCTAssertTrue(isValid)
    }

    // Test 17: String and binary sign/verify paths produce equivalent results
    func testSEP53CrossVerifyStringAndBinary() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)

        let signatureFromString = try keyPair.signMessage("Hello, World!")
        let isValid = try keyPair.verifyMessage([UInt8]("Hello, World!".utf8), signature: signatureFromString)
        XCTAssertTrue(isValid)
    }

    // Test 18: Ed25519 signatures are deterministic
    func testSEP53DeterministicSignature() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)

        let sig1 = try keyPair.signMessage("deterministic test")
        let sig2 = try keyPair.signMessage("deterministic test")
        XCTAssertEqual(sig1, sig2)
    }

    // Test 19: Verify throws for a signature that is too long (65 bytes)
    func testSEP53VerifyOversizedSignatureLength() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let longSig = [UInt8](repeating: 0, count: 65)

        XCTAssertThrowsError(try keyPair.verifyMessage("Hello, World!", signature: longSig)) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.invalidSignatureLength = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // Test 20: Sign and verify a large (~100KB) binary message
    func testSEP53SignAndVerifyLargeMessage() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let largeMessage = [UInt8](repeating: 0x42, count: 100_000)

        let signature = try keyPair.signMessage(largeMessage)
        let isValid = try keyPair.verifyMessage(largeMessage, signature: signature)
        XCTAssertTrue(isValid)
    }

    // Test 21: Sign and verify binary data containing null bytes
    func testSEP53SignAndVerifyBinaryWithNullBytes() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)
        let messageWithNulls: [UInt8] = [0x00, 0x01, 0x00, 0xFF, 0x00]

        let signature = try keyPair.signMessage(messageWithNulls)
        let isValid = try keyPair.verifyMessage(messageWithNulls, signature: signature)
        XCTAssertTrue(isValid)
    }

    // Test 22: Sign and verify via base64-encoded signature round-trip
    func testSEP53Base64EncodingRoundTrip() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)

        let signature = try keyPair.signMessage("Hello, World!")
        let base64Signature = Data(signature).base64EncodedString()

        // Decode and verify
        let decodedSignature = [UInt8](Data(base64Encoded: base64Signature)!)
        let isValid = try keyPair.verifyMessage("Hello, World!", signature: decodedSignature)
        XCTAssertTrue(isValid)

        // Verify known base64 value for spec vector
        XCTAssertEqual(
            base64Signature,
            "fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA=="
        )
    }

    // Test 23: Sign and verify via hex-encoded signature round-trip
    func testSEP53HexEncodingRoundTrip() throws {
        let keyPair = try KeyPair(secretSeed: sep53Seed)

        let signature = try keyPair.signMessage("こんにちは、世界！")
        let hexSignature = bytesToHex(signature)

        // Decode and verify
        let decodedSignature = hexToBytes(hexSignature)
        let isValid = try keyPair.verifyMessage("こんにちは、世界！", signature: decodedSignature)
        XCTAssertTrue(isValid)

        // Verify known hex value for spec vector
        XCTAssertEqual(
            hexSignature,
            "083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604"
        )
    }

    // Test 24: Cross-construction round-trip (sign with seed, verify with account ID)
    func testSEP53CrossConstructionRoundTrip() throws {
        let signerKeyPair = try KeyPair(secretSeed: sep53Seed)
        let signature = try signerKeyPair.signMessage("cross-construction test")

        // Create a verification-only keypair from the account ID
        let verifierKeyPair = try KeyPair(accountId: sep53AccountId)
        XCTAssertNil(verifierKeyPair.privateKey)

        let isValid = try verifierKeyPair.verifyMessage("cross-construction test", signature: signature)
        XCTAssertTrue(isValid)

        // Verify wrong message fails with the verifier keypair
        let isInvalid = try verifierKeyPair.verifyMessage("wrong message", signature: signature)
        XCTAssertFalse(isInvalid)
    }
}
