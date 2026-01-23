//
//  SmartAccountTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class SmartAccountTest: XCTestCase {

    // MARK: - Test Vectors (from specification)

    func testVector1_HighSNormalization() throws {
        // Test Vector 1: High-S normalization
        // Input DER hex: 30450220010203040506070809101112131415161718192021222324252627282930313202210​0ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632550
        let inputDER = "304502200102030405060708091011121314151617181920212223242526272829303132022100ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632550"
        guard let derData = try? Data(base16Encoded: inputDER) else {
            XCTFail("Failed to decode DER hex")
            return
        }

        // Expected output hex: 01020304050607080910111213141516171819202122232425262728293031320000000000000000000000000000000000000000000000000000000000000001
        let expectedHex = "01020304050607080910111213141516171819202122232425262728293031320000000000000000000000000000000000000000000000000000000000000001"

        let normalized = try SmartAccountUtils.normalizeSignature(derData)
        let normalizedHex = normalized.map { String(format: "%02x", $0) }.joined()

        print("TEST VECTOR 1 OUTPUT: \(normalizedHex)")
        XCTAssertEqual(normalizedHex, expectedHex, "High-S normalization should convert s to n - s")
        XCTAssertEqual(normalized.count, 64, "Normalized signature should be 64 bytes")
    }

    func testVector1b_LowSPassthrough() throws {
        // Test Vector 1b: Low-S, no normalization needed
        // Input DER hex: 30440220010203040506070809101112131415161718192021222324252627282930313202200000000000000000000000000000000000000000000000000000000000000005
        let inputDER = "30440220010203040506070809101112131415161718192021222324252627282930313202200000000000000000000000000000000000000000000000000000000000000005"
        guard let derData = try? Data(base16Encoded: inputDER) else {
            XCTFail("Failed to decode DER hex")
            return
        }

        // Expected output hex: 01020304050607080910111213141516171819202122232425262728293031320000000000000000000000000000000000000000000000000000000000000005
        let expectedHex = "01020304050607080910111213141516171819202122232425262728293031320000000000000000000000000000000000000000000000000000000000000005"

        let normalized = try SmartAccountUtils.normalizeSignature(derData)
        let normalizedHex = normalized.map { String(format: "%02x", $0) }.joined()

        print("TEST VECTOR 1b OUTPUT: \(normalizedHex)")
        XCTAssertEqual(normalizedHex, expectedHex, "Low-S should pass through unchanged")
        XCTAssertEqual(normalized.count, 64, "Normalized signature should be 64 bytes")
    }

    func testVector2_WebAuthnSignatureScVal() throws {
        // Test Vector 2: WebAuthn Signature ScVal
        // authenticator_data hex: 49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763050000000d
        // client_data hex: 7b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a225a47567459513d3d227d
        // signature hex: 01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364

        let authenticatorDataHex = "49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763050000000d"
        let clientDataHex = "7b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a225a47567459513d3d227d"
        let signatureHex = "01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364"

        guard let authenticatorData = try? Data(base16Encoded: authenticatorDataHex),
              let clientData = try? Data(base16Encoded: clientDataHex),
              let signature = try? Data(base16Encoded: signatureHex) else {
            XCTFail("Failed to decode test vector hex data")
            return
        }

        let webAuthnSig = WebAuthnSignature(
            authenticatorData: authenticatorData,
            clientData: clientData,
            signature: signature
        )

        let scVal = try webAuthnSig.toScVal()
        let xdrBytes = try XDREncoder.encode(scVal)
        let xdrHex = xdrBytes.map { String(format: "%02x", $0) }.joined()

        print("TEST VECTOR 2 OUTPUT: \(xdrHex)")

        // Verify structure
        XCTAssertFalse(xdrHex.isEmpty, "XDR encoding should produce non-empty output")

        // Verify it's a map
        guard case .map(let entries?) = scVal else {
            XCTFail("WebAuthn signature should be a non-nil map")
            return
        }

        // Verify 3 entries in alphabetical order
        XCTAssertEqual(entries.count, 3, "WebAuthn signature should have 3 map entries")

        // Verify keys are in alphabetical order
        guard case .symbol(let key1) = entries[0].key,
              case .symbol(let key2) = entries[1].key,
              case .symbol(let key3) = entries[2].key else {
            XCTFail("Map keys should be symbols")
            return
        }

        XCTAssertEqual(key1, "authenticator_data")
        XCTAssertEqual(key2, "client_data")
        XCTAssertEqual(key3, "signature")
    }

    func testVector3_SignerKeyScVal() throws {
        // Test Vector 3: Signer Key ScVal
        // verifier: CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM
        // public_key: 65 bytes all zeros (0x04 prefix + 64 zero bytes)
        // credential_id: 0102030405060708090a0b0c0d0e0f10 (16 bytes)

        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        var publicKey = Data([0x04]) // Uncompressed prefix
        publicKey.append(Data(repeating: 0x00, count: 64)) // 64 zero bytes

        let credentialIdHex = "0102030405060708090a0b0c0d0e0f10"
        guard let credentialId = try? Data(base16Encoded: credentialIdHex) else {
            XCTFail("Failed to decode credential ID hex")
            return
        }

        let signer = try ExternalSigner.webAuthn(
            verifierAddress: verifier,
            publicKey: publicKey,
            credentialId: credentialId
        )

        let scVal = try signer.toScVal()
        let xdrBytes = try XDREncoder.encode(scVal)
        let xdrHex = xdrBytes.map { String(format: "%02x", $0) }.joined()

        print("TEST VECTOR 3 OUTPUT: \(xdrHex)")

        // Verify structure
        XCTAssertFalse(xdrHex.isEmpty, "XDR encoding should produce non-empty output")

        // Verify it's a vec with 3 elements
        guard case .vec(let elements?) = scVal else {
            XCTFail("External signer should be a non-nil vec")
            return
        }

        XCTAssertEqual(elements.count, 3, "External signer should have 3 elements")

        // Verify first element is "External" symbol
        guard case .symbol(let symbol) = elements[0] else {
            XCTFail("First element should be a symbol")
            return
        }
        XCTAssertEqual(symbol, "External")

        // Verify second element is address
        guard case .address(_) = elements[1] else {
            XCTFail("Second element should be an address")
            return
        }

        // Verify third element is bytes
        guard case .bytes(let keyData) = elements[2] else {
            XCTFail("Third element should be bytes")
            return
        }

        // Verify key data is public key + credential ID
        XCTAssertEqual(keyData.count, 65 + 16, "Key data should be public key (65) + credential ID (16)")
    }

    func testVector4_AuthPayloadHash() throws {
        // Test Vector 4: Auth Payload Hash
        // network_passphrase: "Test SDF Network ; September 2015"
        // nonce: 12345 (Int64)
        // expiration_ledger: 1000000 (UInt32)
        // contract_address: CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM
        // function_name: "transfer"
        // args: empty

        let networkPassphrase = "Test SDF Network ; September 2015"
        let nonce: Int64 = 12345
        let expirationLedger: UInt32 = 1000000
        let contractAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let functionName = "transfer"

        // Build authorization entry
        let scAddress = try SCAddressXDR(contractId: contractAddress)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(
                InvokeContractArgsXDR(
                    contractAddress: scAddress,
                    functionName: functionName,
                    args: []
                )
            ),
            subInvocations: []
        )

        let credentials = SorobanAddressCredentialsXDR(
            address: scAddress,
            nonce: nonce,
            signatureExpirationLedger: 0, // Will be set during signing
            signature: .void
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        // Build payload hash
        let hash = try SmartAccountAuth.buildAuthPayloadHash(
            entry: authEntry,
            expirationLedger: expirationLedger,
            networkPassphrase: networkPassphrase
        )

        let hashHex = hash.map { String(format: "%02x", $0) }.joined()
        print("TEST VECTOR 4 OUTPUT: \(hashHex)")

        XCTAssertEqual(hash.count, 32, "Hash should be 32 bytes")
    }

    func testVector5_DoubleXDREncoding() throws {
        // Test Vector 5: Double XDR Encoding
        // Take the WebAuthn ScVal from Test Vector 2
        let authenticatorDataHex = "49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763050000000d"
        let clientDataHex = "7b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a225a47567459513d3d227d"
        let signatureHex = "01020304050607080910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364"

        guard let authenticatorData = try? Data(base16Encoded: authenticatorDataHex),
              let clientData = try? Data(base16Encoded: clientDataHex),
              let signature = try? Data(base16Encoded: signatureHex) else {
            XCTFail("Failed to decode test vector hex data")
            return
        }

        let webAuthnSig = WebAuthnSignature(
            authenticatorData: authenticatorData,
            clientData: clientData,
            signature: signature
        )

        let scVal = try webAuthnSig.toScVal()

        // Step 2: XDR-encode the ScVal
        let step2Bytes = try XDREncoder.encode(scVal)
        let step2Hex = step2Bytes.map { String(format: "%02x", $0) }.joined()
        print("TEST VECTOR 5 STEP 2 OUTPUT: \(step2Hex)")

        // Step 3: Wrap in ScVal::Bytes
        let wrappedScVal = SCValXDR.bytes(Data(step2Bytes))

        // Step 4: XDR-encode again
        let step4Bytes = try XDREncoder.encode(wrappedScVal)
        let step4Hex = step4Bytes.map { String(format: "%02x", $0) }.joined()
        print("TEST VECTOR 5 STEP 4 OUTPUT: \(step4Hex)")

        XCTAssertFalse(step2Hex.isEmpty, "Step 2 XDR encoding should produce output")
        XCTAssertFalse(step4Hex.isEmpty, "Step 4 XDR encoding should produce output")
        XCTAssertNotEqual(step2Hex, step4Hex, "Step 2 and Step 4 outputs should differ")
    }

    // MARK: - Error Types Tests

    func testErrorCodes_RawValues() {
        XCTAssertEqual(SmartAccountErrorCode.invalidConfig.rawValue, 1001)
        XCTAssertEqual(SmartAccountErrorCode.missingConfig.rawValue, 1002)
        XCTAssertEqual(SmartAccountErrorCode.walletNotConnected.rawValue, 2001)
        XCTAssertEqual(SmartAccountErrorCode.walletAlreadyExists.rawValue, 2002)
        XCTAssertEqual(SmartAccountErrorCode.walletNotFound.rawValue, 2003)
        XCTAssertEqual(SmartAccountErrorCode.credentialNotFound.rawValue, 3001)
        XCTAssertEqual(SmartAccountErrorCode.credentialAlreadyExists.rawValue, 3002)
        XCTAssertEqual(SmartAccountErrorCode.credentialInvalid.rawValue, 3003)
        XCTAssertEqual(SmartAccountErrorCode.credentialDeploymentFailed.rawValue, 3004)
        XCTAssertEqual(SmartAccountErrorCode.webAuthnRegistrationFailed.rawValue, 4001)
        XCTAssertEqual(SmartAccountErrorCode.webAuthnAuthenticationFailed.rawValue, 4002)
        XCTAssertEqual(SmartAccountErrorCode.webAuthnNotSupported.rawValue, 4003)
        XCTAssertEqual(SmartAccountErrorCode.webAuthnCancelled.rawValue, 4004)
        XCTAssertEqual(SmartAccountErrorCode.transactionSimulationFailed.rawValue, 5001)
        XCTAssertEqual(SmartAccountErrorCode.transactionSigningFailed.rawValue, 5002)
        XCTAssertEqual(SmartAccountErrorCode.transactionSubmissionFailed.rawValue, 5003)
        XCTAssertEqual(SmartAccountErrorCode.transactionTimeout.rawValue, 5004)
        XCTAssertEqual(SmartAccountErrorCode.signerNotFound.rawValue, 6001)
        XCTAssertEqual(SmartAccountErrorCode.signerInvalid.rawValue, 6002)
        XCTAssertEqual(SmartAccountErrorCode.invalidAddress.rawValue, 7001)
        XCTAssertEqual(SmartAccountErrorCode.invalidAmount.rawValue, 7002)
        XCTAssertEqual(SmartAccountErrorCode.invalidInput.rawValue, 7003)
        XCTAssertEqual(SmartAccountErrorCode.storageReadFailed.rawValue, 8001)
        XCTAssertEqual(SmartAccountErrorCode.storageWriteFailed.rawValue, 8002)
        XCTAssertEqual(SmartAccountErrorCode.sessionExpired.rawValue, 9001)
        XCTAssertEqual(SmartAccountErrorCode.sessionInvalid.rawValue, 9002)
    }

    func testSmartAccountError_Structure() {
        let error = SmartAccountError(
            code: .invalidAddress,
            message: "Test message",
            cause: nil
        )

        XCTAssertEqual(error.code, .invalidAddress)
        XCTAssertEqual(error.message, "Test message")
        XCTAssertNil(error.cause)
    }

    func testSmartAccountError_FactoryMethods() {
        let error1 = SmartAccountError.invalidConfig("Invalid config")
        XCTAssertEqual(error1.code, .invalidConfig)

        let error2 = SmartAccountError.walletNotConnected()
        XCTAssertEqual(error2.code, .walletNotConnected)

        let error3 = SmartAccountError.credentialInvalid("Bad credential")
        XCTAssertEqual(error3.code, .credentialInvalid)

        let error4 = SmartAccountError.webAuthnCancelled()
        XCTAssertEqual(error4.code, .webAuthnCancelled)
    }

    func testSmartAccountError_LocalizedDescription() {
        let error = SmartAccountError.invalidAddress("Invalid G-address format")
        let description = error.localizedDescription

        XCTAssertTrue(description.contains("7001"))
        XCTAssertTrue(description.contains("Invalid G-address format"))
    }

    // MARK: - Signer Types Tests

    func testDelegatedSigner_ValidGAddress() throws {
        let address = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let signer = try DelegatedSigner(address: address)

        XCTAssertEqual(signer.address, address)
        XCTAssertEqual(signer.signerType, .delegated)

        let scVal = try signer.toScVal()
        guard case .vec(let elements?) = scVal else {
            XCTFail("Delegated signer should be a non-nil vec")
            return
        }

        XCTAssertEqual(elements.count, 2)
        guard case .symbol(let symbol) = elements[0] else {
            XCTFail("First element should be symbol")
            return
        }
        XCTAssertEqual(symbol, "Delegated")

        guard case .address(_) = elements[1] else {
            XCTFail("Second element should be address")
            return
        }
    }

    func testDelegatedSigner_ValidCAddress() throws {
        let address = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let signer = try DelegatedSigner(address: address)

        XCTAssertEqual(signer.address, address)

        let scVal = try signer.toScVal()
        guard case .vec(let elements?) = scVal else {
            XCTFail("Delegated signer should be a non-nil vec")
            return
        }

        XCTAssertEqual(elements.count, 2)
    }

    func testDelegatedSigner_InvalidPrefix() {
        XCTAssertThrowsError(try DelegatedSigner(address: "MABCD1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ234567890ABC")) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidAddress)
        }
    }

    func testDelegatedSigner_InvalidLength() {
        XCTAssertThrowsError(try DelegatedSigner(address: "GA7Q")) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidAddress)
        }
    }

    func testExternalSigner_ValidData() throws {
        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let keyData = Data(repeating: 0x42, count: 65)

        let signer = try ExternalSigner(verifierAddress: verifier, keyData: keyData)

        XCTAssertEqual(signer.verifierAddress, verifier)
        XCTAssertEqual(signer.keyData, keyData)
        XCTAssertEqual(signer.signerType, .external)

        let scVal = try signer.toScVal()
        guard case .vec(let elements?) = scVal else {
            XCTFail("External signer should be a non-nil vec")
            return
        }

        XCTAssertEqual(elements.count, 3)
    }

    func testExternalSigner_WebAuthnFactory_Valid() throws {
        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        var publicKey = Data([0x04]) // Uncompressed prefix
        publicKey.append(Data(repeating: 0xAA, count: 64))
        let credentialId = Data(repeating: 0xBB, count: 16)

        let signer = try ExternalSigner.webAuthn(
            verifierAddress: verifier,
            publicKey: publicKey,
            credentialId: credentialId
        )

        XCTAssertEqual(signer.keyData.count, 65 + 16) // public key + credential ID
    }

    func testExternalSigner_WebAuthnFactory_InvalidKeySize() {
        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let publicKey = Data(repeating: 0x04, count: 33) // Wrong size
        let credentialId = Data(repeating: 0xBB, count: 16)

        XCTAssertThrowsError(try ExternalSigner.webAuthn(
            verifierAddress: verifier,
            publicKey: publicKey,
            credentialId: credentialId
        )) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("65 bytes"))
        }
    }

    func testExternalSigner_WebAuthnFactory_WrongPrefix() {
        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        var publicKey = Data([0x03]) // Wrong prefix (compressed)
        publicKey.append(Data(repeating: 0xAA, count: 64))
        let credentialId = Data(repeating: 0xBB, count: 16)

        XCTAssertThrowsError(try ExternalSigner.webAuthn(
            verifierAddress: verifier,
            publicKey: publicKey,
            credentialId: credentialId
        )) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("0x04"))
        }
    }

    func testExternalSigner_WebAuthnFactory_EmptyCredentialId() {
        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        var publicKey = Data([0x04])
        publicKey.append(Data(repeating: 0xAA, count: 64))
        let credentialId = Data()

        XCTAssertThrowsError(try ExternalSigner.webAuthn(
            verifierAddress: verifier,
            publicKey: publicKey,
            credentialId: credentialId
        )) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("credential ID"))
        }
    }

    func testExternalSigner_Ed25519Factory_Valid() throws {
        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let publicKey = Data(repeating: 0xCC, count: 32)

        let signer = try ExternalSigner.ed25519(
            verifierAddress: verifier,
            publicKey: publicKey
        )

        XCTAssertEqual(signer.keyData.count, 32)
    }

    func testExternalSigner_Ed25519Factory_InvalidKeySize() {
        let verifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let publicKey = Data(repeating: 0xCC, count: 33) // Wrong size

        XCTAssertThrowsError(try ExternalSigner.ed25519(
            verifierAddress: verifier,
            publicKey: publicKey
        )) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("32 bytes"))
        }
    }

    // MARK: - Signature Types Tests

    func testWebAuthnSignature_Valid() throws {
        let authenticatorData = Data(repeating: 0x11, count: 37)
        let clientData = Data(repeating: 0x22, count: 80)
        let signature = Data(repeating: 0x33, count: 64)

        let webAuthnSig = WebAuthnSignature(
            authenticatorData: authenticatorData,
            clientData: clientData,
            signature: signature
        )

        let scVal = try webAuthnSig.toScVal()

        guard case .map(let entries?) = scVal else {
            XCTFail("Should be a non-nil map")
            return
        }

        XCTAssertEqual(entries.count, 3)
    }

    func testWebAuthnSignature_InvalidSize() {
        let authenticatorData = Data(repeating: 0x11, count: 37)
        let clientData = Data(repeating: 0x22, count: 80)
        let signature = Data(repeating: 0x33, count: 63) // Wrong size

        let webAuthnSig = WebAuthnSignature(
            authenticatorData: authenticatorData,
            clientData: clientData,
            signature: signature
        )

        XCTAssertThrowsError(try webAuthnSig.toScVal()) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("64 bytes"))
        }
    }

    func testEd25519Signature_Valid() throws {
        let signature = Data(repeating: 0x44, count: 64)

        let ed25519Sig = Ed25519Signature(signature: signature)
        let scVal = try ed25519Sig.toScVal()

        guard case .map(let entries?) = scVal else {
            XCTFail("Should be a non-nil map")
            return
        }

        XCTAssertEqual(entries.count, 1)
        guard case .symbol(let key) = entries[0].key else {
            XCTFail("Key should be symbol")
            return
        }
        XCTAssertEqual(key, "signature")
    }

    func testEd25519Signature_InvalidSize() {
        let signature = Data(repeating: 0x44, count: 63) // Wrong size

        let ed25519Sig = Ed25519Signature(signature: signature)

        XCTAssertThrowsError(try ed25519Sig.toScVal()) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("64 bytes"))
        }
    }

    func testPolicySignature_ProducesEmptyMap() throws {
        let policySig = PolicySignature()
        let scVal = try policySig.toScVal()

        guard case .map(let entries?) = scVal else {
            XCTFail("Should be a non-nil map")
            return
        }

        XCTAssertEqual(entries.count, 0, "Policy signature should be an empty map")
    }

    // MARK: - Signature Normalization Tests

    func testNormalizeSignature_InvalidDERPrefix() {
        let invalidDER = Data([0x31, 0x44, 0x02, 0x20]) // Wrong prefix

        XCTAssertThrowsError(try SmartAccountUtils.normalizeSignature(invalidDER)) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .signerInvalid)
        }
    }

    func testNormalizeSignature_TruncatedData() {
        let truncated = Data([0x30, 0x44, 0x02]) // Not enough data

        XCTAssertThrowsError(try SmartAccountUtils.normalizeSignature(truncated)) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .signerInvalid)
        }
    }

    func testNormalizeSignature_ShortRComponent() throws {
        // DER with short r component (needs padding)
        // 0x30 [total_len] 0x02 [r_len] [r_bytes] 0x02 [s_len] [s_bytes]
        // Using a 2-byte r value: 0x0102 and a 32-byte s value
        // Total structure: 30 24 02 02 0102 02 20 [32 bytes for s]
        let shortRHex = "30240202010202200405060708091011121314151617181920212223242526272829303132333435"
        guard let derData = try? Data(base16Encoded: shortRHex) else {
            XCTFail("Failed to decode DER hex")
            return
        }

        let normalized = try SmartAccountUtils.normalizeSignature(derData)

        XCTAssertEqual(normalized.count, 64, "Should pad short components to 32 bytes each")

        // Verify first bytes are zero-padded (r component should be 0x00000...0102)
        XCTAssertEqual(normalized[30], 0x01, "Second to last byte of r should be 0x01")
        XCTAssertEqual(normalized[31], 0x02, "Last byte of r should be 0x02")
    }

    // MARK: - Public Key Extraction Tests

    func testExtractPublicKey_ValidCOSE() throws {
        // Create a valid COSE attestation structure
        let cosePrefix = Data([0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        let xCoord = Data(repeating: 0xAA, count: 32)
        let separator = Data([0x22, 0x58, 0x20])
        let yCoord = Data(repeating: 0xBB, count: 32)

        var attestationData = Data()
        attestationData.append(Data(repeating: 0x00, count: 10)) // Some prefix data
        attestationData.append(cosePrefix)
        attestationData.append(xCoord)
        attestationData.append(separator)
        attestationData.append(yCoord)
        attestationData.append(Data(repeating: 0x00, count: 10)) // Some suffix data

        let publicKey = try SmartAccountUtils.extractPublicKey(fromAttestationObject: attestationData)

        XCTAssertEqual(publicKey.count, 65)
        XCTAssertEqual(publicKey[0], 0x04) // Uncompressed prefix
        XCTAssertEqual(publicKey.subdata(in: 1..<33), xCoord)
        XCTAssertEqual(publicKey.subdata(in: 33..<65), yCoord)
    }

    func testExtractPublicKey_MissingCOSEPrefix() {
        let attestationData = Data(repeating: 0xFF, count: 100)

        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKey(fromAttestationObject: attestationData)) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("COSE key prefix"))
        }
    }

    func testExtractPublicKey_TruncatedData() {
        let cosePrefix = Data([0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        var attestationData = Data()
        attestationData.append(cosePrefix)
        attestationData.append(Data(repeating: 0xAA, count: 10)) // Not enough data

        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKey(fromAttestationObject: attestationData)) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
            XCTAssertTrue(smartError.message.contains("Insufficient data"))
        }
    }

    func testExtractPublicKeyFromAuthenticatorData_Valid() throws {
        // Build valid authenticator data structure
        var authData = Data()
        authData.append(Data(repeating: 0x00, count: 32)) // RP ID hash
        authData.append(Data([0x01])) // Flags
        authData.append(Data([0x00, 0x00, 0x00, 0x01])) // Counter
        authData.append(Data(repeating: 0x00, count: 16)) // AAGUID

        // Credential ID length (big-endian UInt16)
        let credIdLength: UInt16 = 16
        authData.append(Data([UInt8(credIdLength >> 8), UInt8(credIdLength & 0xFF)]))

        // Credential ID
        authData.append(Data(repeating: 0xCC, count: 16))

        // Offset (10 bytes)
        authData.append(Data(repeating: 0x00, count: 10))

        // X coordinate
        let xCoord = Data(repeating: 0xAA, count: 32)
        authData.append(xCoord)

        // Separator
        authData.append(Data([0x22, 0x58, 0x20]))

        // Y coordinate
        let yCoord = Data(repeating: 0xBB, count: 32)
        authData.append(yCoord)

        let publicKey = try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(authData)

        XCTAssertEqual(publicKey.count, 65)
        XCTAssertEqual(publicKey[0], 0x04)
        XCTAssertEqual(publicKey.subdata(in: 1..<33), xCoord)
        XCTAssertEqual(publicKey.subdata(in: 33..<65), yCoord)
    }

    func testExtractPublicKeyFromAuthenticatorData_TooShort() {
        let authData = Data(repeating: 0x00, count: 50) // Too short

        XCTAssertThrowsError(try SmartAccountUtils.extractPublicKeyFromAuthenticatorData(authData)) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidInput)
        }
    }

    // MARK: - Contract Derivation Tests

    func testGetContractSalt_ReturnsCorrectHash() {
        let credentialId = Data(repeating: 0x42, count: 16)
        let salt = SmartAccountUtils.getContractSalt(credentialId: credentialId)

        XCTAssertEqual(salt.count, 32, "Salt should be SHA-256 hash (32 bytes)")
        XCTAssertEqual(salt, credentialId.sha256Hash)
    }

    func testDeriveContractAddress_ValidInputs() throws {
        let credentialId = Data(repeating: 0x42, count: 16)
        let deployerKey = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let networkPassphrase = "Test SDF Network ; September 2015"

        let contractAddress = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialId,
            deployerPublicKey: deployerKey,
            networkPassphrase: networkPassphrase
        )

        XCTAssertTrue(contractAddress.hasPrefix("C"), "Contract address should start with C")
        XCTAssertEqual(contractAddress.count, 56, "Contract address should be 56 characters")
    }

    func testDeriveContractAddress_InvalidDeployerKey() {
        let credentialId = Data(repeating: 0x42, count: 16)
        let invalidKey = "INVALID_KEY"
        let networkPassphrase = "Test SDF Network ; September 2015"

        XCTAssertThrowsError(try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialId,
            deployerPublicKey: invalidKey,
            networkPassphrase: networkPassphrase
        )) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .invalidAddress)
        }
    }

    // MARK: - Auth Entry Signing Tests

    func testSignAuthEntry_WebAuthnSignature() throws {
        // Setup
        let networkPassphrase = "Test SDF Network ; September 2015"
        let contractAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let expirationLedger: UInt32 = 1000000
        let nonce: Int64 = 12345

        // Create signer
        var publicKey = Data([0x04])
        publicKey.append(Data(repeating: 0xAA, count: 64))
        let credentialId = Data(repeating: 0xBB, count: 16)
        let signer = try ExternalSigner.webAuthn(
            verifierAddress: contractAddress,
            publicKey: publicKey,
            credentialId: credentialId
        )

        // Create signature
        let webAuthnSig = WebAuthnSignature(
            authenticatorData: Data(repeating: 0x11, count: 37),
            clientData: Data(repeating: 0x22, count: 80),
            signature: Data(repeating: 0x33, count: 64)
        )
        let signatureScVal = try webAuthnSig.toScVal()

        // Create auth entry
        let scAddress = try SCAddressXDR(contractId: contractAddress)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(
                InvokeContractArgsXDR(
                    contractAddress: scAddress,
                    functionName: "test_fn",
                    args: []
                )
            ),
            subInvocations: []
        )

        let credentials = SorobanAddressCredentialsXDR(
            address: scAddress,
            nonce: nonce,
            signatureExpirationLedger: 0,
            signature: .void
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        // Sign the entry
        let signedEntry = try SmartAccountAuth.signAuthEntry(
            entry: authEntry,
            signer: signer,
            signatureScVal: signatureScVal,
            expirationLedger: expirationLedger,
            networkPassphrase: networkPassphrase
        )

        // Verify structure
        guard let signedCredentials = signedEntry.credentials.address else {
            XCTFail("Credentials should be address type")
            return
        }

        XCTAssertEqual(signedCredentials.signatureExpirationLedger, expirationLedger)

        // Verify signature map
        guard case .vec(let sigVec?) = signedCredentials.signature,
              !sigVec.isEmpty,
              case .map(let sigMap?) = sigVec[0] else {
            XCTFail("Signature should be Vec([Map([...])])")
            return
        }

        XCTAssertEqual(sigMap.count, 1, "Should have one signature entry")

        // Verify signature value is double XDR-encoded
        let sigValue = sigMap[0].val
        guard case .bytes(let xdrBytes) = sigValue else {
            XCTFail("Signature value should be bytes")
            return
        }

        // Try to decode to verify it's valid XDR
        XCTAssertNoThrow(try XDRDecoder.decode(SCValXDR.self, data: Array(xdrBytes)))
    }

    func testSignAuthEntry_NonAddressCredentials_Throws() throws {
        let networkPassphrase = "Test SDF Network ; September 2015"
        let contractAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let expirationLedger: UInt32 = 1000000

        // Create signer
        var publicKey = Data([0x04])
        publicKey.append(Data(repeating: 0xAA, count: 64))
        let credentialId = Data(repeating: 0xBB, count: 16)
        let signer = try ExternalSigner.webAuthn(
            verifierAddress: contractAddress,
            publicKey: publicKey,
            credentialId: credentialId
        )

        // Create signature
        let webAuthnSig = WebAuthnSignature(
            authenticatorData: Data(repeating: 0x11, count: 37),
            clientData: Data(repeating: 0x22, count: 80),
            signature: Data(repeating: 0x33, count: 64)
        )
        let signatureScVal = try webAuthnSig.toScVal()

        // Create auth entry with non-address credentials
        let scAddress = try SCAddressXDR(contractId: contractAddress)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(
                InvokeContractArgsXDR(
                    contractAddress: scAddress,
                    functionName: "test_fn",
                    args: []
                )
            ),
            subInvocations: []
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount, // Wrong type
            rootInvocation: invocation
        )

        // Should throw
        XCTAssertThrowsError(try SmartAccountAuth.signAuthEntry(
            entry: authEntry,
            signer: signer,
            signatureScVal: signatureScVal,
            expirationLedger: expirationLedger,
            networkPassphrase: networkPassphrase
        )) { error in
            guard let smartError = error as? SmartAccountError else {
                XCTFail("Should throw SmartAccountError")
                return
            }
            XCTAssertEqual(smartError.code, .transactionSigningFailed)
        }
    }

    func testBuildAuthPayloadHash_ProducesCorrectHash() throws {
        let networkPassphrase = "Test SDF Network ; September 2015"
        let contractAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let expirationLedger: UInt32 = 1000000
        let nonce: Int64 = 12345

        let scAddress = try SCAddressXDR(contractId: contractAddress)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(
                InvokeContractArgsXDR(
                    contractAddress: scAddress,
                    functionName: "transfer",
                    args: []
                )
            ),
            subInvocations: []
        )

        let credentials = SorobanAddressCredentialsXDR(
            address: scAddress,
            nonce: nonce,
            signatureExpirationLedger: 0,
            signature: .void
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        let hash = try SmartAccountAuth.buildAuthPayloadHash(
            entry: authEntry,
            expirationLedger: expirationLedger,
            networkPassphrase: networkPassphrase
        )

        XCTAssertEqual(hash.count, 32, "Hash should be 32 bytes (SHA-256)")
    }

    func testSignAuthEntry_MultipleSigners_SortCorrectly() throws {
        // This test verifies that multiple signers are sorted by XDR-encoded key bytes
        let networkPassphrase = "Test SDF Network ; September 2015"
        let contractAddress = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let expirationLedger: UInt32 = 1000000
        let nonce: Int64 = 12345

        // Create two signers
        var publicKey1 = Data([0x04])
        publicKey1.append(Data(repeating: 0xAA, count: 64))
        let credentialId1 = Data(repeating: 0xBB, count: 16)
        let signer1 = try ExternalSigner.webAuthn(
            verifierAddress: contractAddress,
            publicKey: publicKey1,
            credentialId: credentialId1
        )

        var publicKey2 = Data([0x04])
        publicKey2.append(Data(repeating: 0xCC, count: 64))
        let credentialId2 = Data(repeating: 0xDD, count: 16)
        let signer2 = try ExternalSigner.webAuthn(
            verifierAddress: contractAddress,
            publicKey: publicKey2,
            credentialId: credentialId2
        )

        // Create signatures
        let sig1 = WebAuthnSignature(
            authenticatorData: Data(repeating: 0x11, count: 37),
            clientData: Data(repeating: 0x22, count: 80),
            signature: Data(repeating: 0x33, count: 64)
        )
        let sigScVal1 = try sig1.toScVal()

        let sig2 = WebAuthnSignature(
            authenticatorData: Data(repeating: 0x44, count: 37),
            clientData: Data(repeating: 0x55, count: 80),
            signature: Data(repeating: 0x66, count: 64)
        )
        let sigScVal2 = try sig2.toScVal()

        // Create auth entry
        let scAddress = try SCAddressXDR(contractId: contractAddress)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: SorobanAuthorizedFunctionXDR.contractFn(
                InvokeContractArgsXDR(
                    contractAddress: scAddress,
                    functionName: "test_fn",
                    args: []
                )
            ),
            subInvocations: []
        )

        let credentials = SorobanAddressCredentialsXDR(
            address: scAddress,
            nonce: nonce,
            signatureExpirationLedger: 0,
            signature: .void
        )

        let authEntry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        // Sign with first signer
        let signedEntry1 = try SmartAccountAuth.signAuthEntry(
            entry: authEntry,
            signer: signer1,
            signatureScVal: sigScVal1,
            expirationLedger: expirationLedger,
            networkPassphrase: networkPassphrase
        )

        // Sign with second signer
        let signedEntry2 = try SmartAccountAuth.signAuthEntry(
            entry: signedEntry1,
            signer: signer2,
            signatureScVal: sigScVal2,
            expirationLedger: expirationLedger,
            networkPassphrase: networkPassphrase
        )

        // Verify we have 2 signatures and they are sorted
        guard let credentials2 = signedEntry2.credentials.address,
              case .vec(let sigVec?) = credentials2.signature,
              !sigVec.isEmpty,
              case .map(let sigMap?) = sigVec[0] else {
            XCTFail("Signature should be Vec([Map([...])])")
            return
        }

        XCTAssertEqual(sigMap.count, 2, "Should have two signature entries")

        // Verify they are sorted by XDR-encoded key bytes
        let key1Bytes = try XDREncoder.encode(sigMap[0].key)
        let key2Bytes = try XDREncoder.encode(sigMap[1].key)
        let key1Hex = key1Bytes.map { String(format: "%02x", $0) }.joined()
        let key2Hex = key2Bytes.map { String(format: "%02x", $0) }.joined()

        XCTAssertLessThan(key1Hex, key2Hex, "Map entries should be sorted lexicographically by XDR-encoded key hex")
    }
}
