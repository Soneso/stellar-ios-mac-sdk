//
//  Sep53DocTest.swift
//  stellarsdkTests
//
//  Tests for SEP-53 documentation code examples.
//  SEP-53: Sign and Verify Messages with Stellar keypairs.
//

import Foundation
import XCTest
import stellarsdk

class Sep53DocTest: XCTestCase {

    let testSeed = "SAKICEVQLYWGSOJS4WW7HZJWAHZVEEBS527LHK5V4MLJALYKICQCJXMW"
    let testAccountId = "GBXFXNDLV4LSWA4VB7YIL5GBD7BVNR22SGBTDKMO2SBZZHDXSKZYCP7L"

    // MARK: - Quick example: sign and verify round-trip

    func testQuickExample() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()

        let signature = try keyPair.signMessage("I agree to the terms of service")

        let isValid = try keyPair.verifyMessage("I agree to the terms of service", signature: signature)
        XCTAssertTrue(isValid)
    }

    // MARK: - Signing messages with base64 and hex encoding

    func testSigningMessages() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)

        let message = "User consent granted at 2025-01-15T12:00:00Z"
        let signature = try keyPair.signMessage(message)

        // Encode as base64
        let base64Signature = Data(signature).base64EncodedString()
        XCTAssertFalse(base64Signature.isEmpty)

        // Encode as hex
        let hexSignature = Data(signature).base16EncodedString()
        XCTAssertFalse(hexSignature.isEmpty)

        // Signature is deterministic
        let signature2 = try keyPair.signMessage(message)
        XCTAssertEqual(signature, signature2)
    }

    // MARK: - Verifying messages with public key only

    func testVerifyWithPublicKeyOnly() throws {
        let signerKeyPair = try KeyPair(secretSeed: testSeed)
        let message = "User consent granted at 2025-01-15T12:00:00Z"

        // Client signs
        let signature = try signerKeyPair.signMessage(message)
        let base64Signature = Data(signature).base64EncodedString()

        // Server verifies using only the public key
        let publicKey = try KeyPair(accountId: signerKeyPair.accountId)
        let decodedSignature = [UInt8](Data(base64Encoded: base64Signature)!)
        let isValid = try publicKey.verifyMessage(message, signature: decodedSignature)
        XCTAssertTrue(isValid)
    }

    // MARK: - Verifying hex-encoded signatures

    func testVerifyHexEncodedSignature() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)
        let message = "Cross-platform message"

        let signature = try keyPair.signMessage(message)
        let hexSignature = Data(signature).base16EncodedString()

        // Decode hex and verify
        let sigBytes = [UInt8](try Data(base16Encoded: hexSignature))
        let isValid = try keyPair.verifyMessage(message, signature: sigBytes)
        XCTAssertTrue(isValid)
    }

    // MARK: - Signing binary data

    func testSignBinaryData() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)

        let binaryData: [UInt8] = [0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD]
        let signature = try keyPair.signMessage(binaryData)

        XCTAssertEqual(signature.count, 64)

        let isValid = try keyPair.verifyMessage(binaryData, signature: signature)
        XCTAssertTrue(isValid)
    }

    // MARK: - Authentication flow

    func testAuthenticationFlow() throws {
        // SERVER: Generate a challenge
        var randomBytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, 16, &randomBytes)
        let challenge = "authenticate:\(Data(randomBytes).base16EncodedString()):\(Int(Date().timeIntervalSince1970))"

        // CLIENT: Sign the challenge
        let clientKeyPair = try KeyPair(secretSeed: testSeed)
        let signature = try clientKeyPair.signMessage(challenge)

        let response: [String: String] = [
            "account_id": clientKeyPair.accountId,
            "signature": Data(signature).base64EncodedString(),
            "challenge": challenge,
        ]

        // SERVER: Verify the response
        let publicKey = try KeyPair(accountId: response["account_id"]!)
        let decodedSignature = [UInt8](Data(base64Encoded: response["signature"]!)!)

        let isValid = try publicKey.verifyMessage(response["challenge"]!, signature: decodedSignature)
        XCTAssertTrue(isValid)
    }

    // MARK: - Error handling: signing without private key

    func testSignWithoutPrivateKey() throws {
        let publicKeyOnly = try KeyPair(accountId: testAccountId)

        XCTAssertThrowsError(try publicKeyOnly.signMessage("test")) { error in
            XCTAssertTrue(error is Ed25519Error)
            if case Ed25519Error.missingPrivateKey = error {
                // Expected
            } else {
                XCTFail("Expected Ed25519Error.missingPrivateKey, got \(error)")
            }
        }
    }

    // MARK: - Checking before signing (privateKey != nil)

    func testCheckBeforeSigning() throws {
        let keyPairWithSecret = try KeyPair(secretSeed: testSeed)
        XCTAssertNotNil(keyPairWithSecret.privateKey)

        let keyPairPublicOnly = try KeyPair(accountId: testAccountId)
        XCTAssertNil(keyPairPublicOnly.privateKey)
    }

    // MARK: - Common verification failures

    func testVerificationFailures() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)
        let signature = try keyPair.signMessage("Original message")

        // Wrong message
        let wrongMessage = try keyPair.verifyMessage("Different message", signature: signature)
        XCTAssertFalse(wrongMessage)

        // Wrong key
        let otherKeyPair = try KeyPair.generateRandomKeyPair()
        let wrongKey = try otherKeyPair.verifyMessage("Original message", signature: signature)
        XCTAssertFalse(wrongKey)

        // All-zero signature (correct length, wrong data)
        let zeroSig = [UInt8](repeating: 0, count: 64)
        let zeroResult = try keyPair.verifyMessage("Hello", signature: zeroSig)
        XCTAssertFalse(zeroResult)
    }

    // MARK: - Test vector: ASCII message

    func testVectorAscii() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)
        XCTAssertEqual(keyPair.accountId, testAccountId)

        let signature = try keyPair.signMessage("Hello, World!")
        let base64Signature = Data(signature).base64EncodedString()
        let hexSignature = Data(signature).base16EncodedString()

        let expectedBase64 = "fO5dbYhXUhBMhe6kId/cuVq/AfEnHRHEvsP8vXh03M1uLpi5e46yO2Q8rEBzu3feXQewcQE5GArp88u6ePK6BA=="
        let expectedHex = "7cee5d6d885752104c85eea421dfdcb95abf01f1271d11c4bec3fcbd7874dccd6e2e98b97b8eb23b643cac4073bb77de5d07b0710139180ae9f3cbba78f2ba04"

        XCTAssertEqual(base64Signature, expectedBase64)
        XCTAssertEqual(hexSignature, expectedHex)

        // Round-trip verification
        let isValid = try keyPair.verifyMessage("Hello, World!", signature: signature)
        XCTAssertTrue(isValid)
    }

    // MARK: - Test vector: Japanese (UTF-8) message

    func testVectorJapanese() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)

        let signature = try keyPair.signMessage("こんにちは、世界！")

        let expectedBase64 = "CDU265Xs8y3OWbB/56H9jPgUss5G9A0qFuTqH2zs2YDgTm+++dIfmAEceFqB7bhfN3am59lCtDXrCtwH2k1GBA=="
        let expectedHex = "083536eb95ecf32dce59b07fe7a1fd8cf814b2ce46f40d2a16e4ea1f6cecd980e04e6fbef9d21f98011c785a81edb85f3776a6e7d942b435eb0adc07da4d4604"

        XCTAssertEqual(Data(signature).base64EncodedString(), expectedBase64)
        XCTAssertEqual(Data(signature).base16EncodedString(), expectedHex)

        // Round-trip verification
        let isValid = try keyPair.verifyMessage("こんにちは、世界！", signature: signature)
        XCTAssertTrue(isValid)
    }

    // MARK: - Test vector: Binary data message

    func testVectorBinary() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)

        let message = [UInt8](Data(base64Encoded: "2zZDP1sa1BVBfLP7TeeMk3sUbaxAkUhBhDiNdrksaFo=")!)
        let signature = try keyPair.signMessage(message)

        let expectedBase64 = "VA1+7hefNwv2NKScH6n+Sljj15kLAge+M2wE7fzFOf+L0MMbssA1mwfJZRyyrhBORQRle10X1Dxpx+UOI4EbDQ=="
        let expectedHex = "540d7eee179f370bf634a49c1fa9fe4a58e3d7990b0207be336c04edfcc539ff8bd0c31bb2c0359b07c9651cb2ae104e4504657b5d17d43c69c7e50e23811b0d"

        XCTAssertEqual(Data(signature).base64EncodedString(), expectedBase64)
        XCTAssertEqual(Data(signature).base16EncodedString(), expectedHex)

        // Round-trip verification
        let isValid = try keyPair.verifyMessage(message, signature: signature)
        XCTAssertTrue(isValid)
    }

    // MARK: - Cross-SDK compatibility (verify external signature)

    func testCrossSdkVerification() throws {
        // Sign with our SDK, then verify from "external" base64
        let keyPair = try KeyPair(secretSeed: testSeed)
        let message = "Cross-platform message"

        let signature = try keyPair.signMessage(message)
        let base64Sig = Data(signature).base64EncodedString()

        // Simulate receiving base64 from another SDK
        let publicKey = try KeyPair(accountId: testAccountId)
        let receivedSig = [UInt8](Data(base64Encoded: base64Sig)!)
        let isValid = try publicKey.verifyMessage(message, signature: receivedSig)
        XCTAssertTrue(isValid)
    }

    // MARK: - Invalid signature length throws

    func testInvalidSignatureLength() throws {
        let keyPair = try KeyPair(secretSeed: testSeed)

        // Signature too short (63 bytes)
        let shortSig = [UInt8](repeating: 0, count: 63)
        XCTAssertThrowsError(try keyPair.verifyMessage("test", signature: shortSig)) { error in
            if case Ed25519Error.invalidSignatureLength = error {
                // Expected
            } else {
                XCTFail("Expected Ed25519Error.invalidSignatureLength, got \(error)")
            }
        }

        // Signature too long (65 bytes)
        let longSig = [UInt8](repeating: 0, count: 65)
        XCTAssertThrowsError(try keyPair.verifyMessage("test", signature: longSig)) { error in
            if case Ed25519Error.invalidSignatureLength = error {
                // Expected
            } else {
                XCTFail("Expected Ed25519Error.invalidSignatureLength, got \(error)")
            }
        }
    }
}
