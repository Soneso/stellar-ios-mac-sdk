//
//  SignerXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class SignerXDRUnitTests: XCTestCase {

    // MARK: - Test Constants

    private let testAccountId1 = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
    private let testAccountId2 = "GBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON"

    // 32-byte test hash for preAuthTx and hashX signers
    private let testHash32Hex = "da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"

    // MARK: - SignerXDR Tests

    func testSignerXDREncodeDecode() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let wrappedKey = WrappedData32(Data(publicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(wrappedKey)
        let signer = SignerXDR(key: signerKey, weight: 1)

        let encoded = try XDREncoder.encode(signer)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(SignerXDR.self, data: encoded)

        XCTAssertEqual(decoded.weight, 1)
        XCTAssertEqual(decoded.key, signerKey)
    }

    func testSignerXDRWithWeight() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let wrappedKey = WrappedData32(Data(publicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(wrappedKey)

        // Test weight 0 (removes signer)
        let signerWeight0 = SignerXDR(key: signerKey, weight: 0)
        let encoded0 = try XDREncoder.encode(signerWeight0)
        let decoded0 = try XDRDecoder.decode(SignerXDR.self, data: encoded0)
        XCTAssertEqual(decoded0.weight, 0)

        // Test weight 1 (low threshold)
        let signerWeight1 = SignerXDR(key: signerKey, weight: 1)
        let encoded1 = try XDREncoder.encode(signerWeight1)
        let decoded1 = try XDRDecoder.decode(SignerXDR.self, data: encoded1)
        XCTAssertEqual(decoded1.weight, 1)

        // Test weight 255 (maximum)
        let signerWeight255 = SignerXDR(key: signerKey, weight: 255)
        let encoded255 = try XDREncoder.encode(signerWeight255)
        let decoded255 = try XDRDecoder.decode(SignerXDR.self, data: encoded255)
        XCTAssertEqual(decoded255.weight, 255)

        // Test weight 10 (common threshold value)
        let signerWeight10 = SignerXDR(key: signerKey, weight: 10)
        let encoded10 = try XDREncoder.encode(signerWeight10)
        let decoded10 = try XDRDecoder.decode(SignerXDR.self, data: encoded10)
        XCTAssertEqual(decoded10.weight, 10)
    }

    func testSignerXDRRoundTrip() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let wrappedKey = WrappedData32(Data(publicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(wrappedKey)
        let signer = SignerXDR(key: signerKey, weight: 50)

        let encoded = try XDREncoder.encode(signer)
        let base64 = Data(encoded).base64EncodedString()

        XCTAssertFalse(base64.isEmpty)

        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(SignerXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.weight, 50)
        XCTAssertEqual(decoded.key, signerKey)
    }

    // MARK: - SignerKeyXDR Tests

    func testSignerKeyXDREd25519() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let wrappedKey = WrappedData32(Data(publicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(wrappedKey)

        let encoded = try XDREncoder.encode(signerKey)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)

        switch decoded {
        case .ed25519(let keyData):
            XCTAssertEqual(keyData.wrapped, wrappedKey.wrapped)
        default:
            XCTFail("Expected ed25519 signer key")
        }
    }

    func testSignerKeyXDRPreAuthTx() throws {
        guard let hashData = testHash32Hex.data(using: .hexadecimal) else {
            XCTFail("Failed to create hash data from hex")
            return
        }
        let wrappedHash = WrappedData32(hashData)
        let signerKey = SignerKeyXDR.preAuthTx(wrappedHash)

        let encoded = try XDREncoder.encode(signerKey)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)

        switch decoded {
        case .preAuthTx(let txHash):
            XCTAssertEqual(txHash.wrapped, wrappedHash.wrapped)
        default:
            XCTFail("Expected preAuthTx signer key")
        }
    }

    func testSignerKeyXDRSha256Hash() throws {
        guard let hashData = testHash32Hex.data(using: .hexadecimal) else {
            XCTFail("Failed to create hash data from hex")
            return
        }
        let wrappedHash = WrappedData32(hashData)
        let signerKey = SignerKeyXDR.hashX(wrappedHash)

        let encoded = try XDREncoder.encode(signerKey)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)

        switch decoded {
        case .hashX(let hashValue):
            XCTAssertEqual(hashValue.wrapped, wrappedHash.wrapped)
        default:
            XCTFail("Expected hashX signer key")
        }
    }

    func testSignerKeyXDREd25519SignedPayload() throws {
        let publicKey = try PublicKey(accountId: testAccountId1)
        let wrappedKey = WrappedData32(Data(publicKey.bytes))
        let payload = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
        let signedPayload = Ed25519SignedPayload(ed25519: wrappedKey, payload: payload)
        let signerKey = SignerKeyXDR.signedPayload(signedPayload)

        let encoded = try XDREncoder.encode(signerKey)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: encoded)

        switch decoded {
        case .signedPayload(let decodedPayload):
            XCTAssertEqual(decodedPayload.ed25519.wrapped, wrappedKey.wrapped)
            XCTAssertEqual(decodedPayload.payload, payload)
        default:
            XCTFail("Expected signedPayload signer key")
        }
    }

    func testSignerKeyXDRRoundTrip() throws {
        let publicKey = try PublicKey(accountId: testAccountId2)
        let wrappedKey = WrappedData32(Data(publicKey.bytes))
        let signerKey = SignerKeyXDR.ed25519(wrappedKey)

        let encoded = try XDREncoder.encode(signerKey)
        let base64 = Data(encoded).base64EncodedString()

        XCTAssertFalse(base64.isEmpty)

        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded, signerKey)
    }

    func testSignerKeyXDRFromBase64() throws {
        // Create a signer key and encode it
        let publicKey = try PublicKey(accountId: testAccountId1)
        let wrappedKey = WrappedData32(Data(publicKey.bytes))
        let originalKey = SignerKeyXDR.ed25519(wrappedKey)

        let encoded = try XDREncoder.encode(originalKey)
        let base64 = Data(encoded).base64EncodedString()

        XCTAssertFalse(base64.isEmpty)

        // Decode from base64
        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(SignerKeyXDR.self, data: [UInt8](decodedData))

        // Verify the decoded key matches
        switch decoded {
        case .ed25519(let keyData):
            XCTAssertEqual(keyData.wrapped, wrappedKey.wrapped)
        default:
            XCTFail("Expected ed25519 signer key after base64 decode")
        }
    }

    // MARK: - DecoratedSignatureXDR Tests

    func testDecoratedSignatureXDREncodeDecode() throws {
        let hintBytes = Data([0xAB, 0xCD, 0xEF, 0x12])
        let hint = WrappedData4(hintBytes)
        let signatureBytes = Data(repeating: 0x42, count: 64)

        let decoratedSignature = DecoratedSignatureXDR(hint: hint, signature: signatureBytes)

        let encoded = try XDREncoder.encode(decoratedSignature)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = try XDRDecoder.decode(DecoratedSignatureXDR.self, data: encoded)

        XCTAssertEqual(decoded.hint.wrapped, hintBytes)
        XCTAssertEqual(decoded.signature, signatureBytes)
    }

    func testDecoratedSignatureXDRWithHint() throws {
        // The hint is typically the last 4 bytes of the public key
        let publicKey = try PublicKey(accountId: testAccountId1)
        let publicKeyBytes = publicKey.bytes
        let hintBytes = Data(publicKeyBytes.suffix(4))
        let hint = WrappedData4(hintBytes)

        let signatureBytes = Data(repeating: 0xAA, count: 64)
        let decoratedSignature = DecoratedSignatureXDR(hint: hint, signature: signatureBytes)

        let encoded = try XDREncoder.encode(decoratedSignature)
        let decoded = try XDRDecoder.decode(DecoratedSignatureXDR.self, data: encoded)

        // Verify hint matches last 4 bytes of public key
        let decodedHintBytes = [UInt8](decoded.hint.wrapped)
        XCTAssertEqual(decodedHintBytes.count, 4)
        XCTAssertEqual(decodedHintBytes, Array(publicKeyBytes.suffix(4)))

        // Verify signature is preserved
        XCTAssertEqual(decoded.signature.count, 64)
        XCTAssertEqual(decoded.signature, signatureBytes)
    }

    func testDecoratedSignatureXDRRoundTrip() throws {
        let hintBytes = Data([0x11, 0x22, 0x33, 0x44])
        let hint = WrappedData4(hintBytes)
        let signatureBytes = Data(repeating: 0x55, count: 64)

        let decoratedSignature = DecoratedSignatureXDR(hint: hint, signature: signatureBytes)

        let encoded = try XDREncoder.encode(decoratedSignature)
        let base64 = Data(encoded).base64EncodedString()

        XCTAssertFalse(base64.isEmpty)

        guard let decodedData = Data(base64Encoded: base64) else {
            XCTFail("Failed to decode base64")
            return
        }

        let decoded = try XDRDecoder.decode(DecoratedSignatureXDR.self, data: [UInt8](decodedData))

        XCTAssertEqual(decoded.hint.wrapped, hintBytes)
        XCTAssertEqual(decoded.signature, signatureBytes)
    }

    // MARK: - SignerKeyXDR Equality Tests

    func testSignerKeyXDREquality() throws {
        let publicKey1 = try PublicKey(accountId: testAccountId1)
        let publicKey2 = try PublicKey(accountId: testAccountId2)

        let wrappedKey1 = WrappedData32(Data(publicKey1.bytes))
        let wrappedKey2 = WrappedData32(Data(publicKey2.bytes))

        let key1a = SignerKeyXDR.ed25519(wrappedKey1)
        let key1b = SignerKeyXDR.ed25519(wrappedKey1)
        let key2 = SignerKeyXDR.ed25519(wrappedKey2)

        // Same keys should be equal
        XCTAssertEqual(key1a, key1b)

        // Different keys should not be equal
        XCTAssertNotEqual(key1a, key2)

        // Different types should not be equal
        guard let hashData = testHash32Hex.data(using: .hexadecimal) else {
            XCTFail("Failed to create hash data from hex")
            return
        }
        let wrappedHash = WrappedData32(hashData)
        let preAuthKey = SignerKeyXDR.preAuthTx(wrappedHash)
        let hashXKey = SignerKeyXDR.hashX(wrappedHash)

        XCTAssertNotEqual(preAuthKey, hashXKey)
    }
}
