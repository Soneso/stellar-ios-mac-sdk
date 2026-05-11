//
//  OZSmartAccountSignaturesTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSmartAccountSignaturesTests: XCTestCase {

    // MARK: - OZWebAuthnSignature toScVal

    func testWebAuthnToScVal_returnsMapType() throws {
        let signature = try makeWebAuthn()
        let scVal = signature.toScVal()
        XCTAssertTrue(scVal.isMap)
    }

    func testWebAuthnToScVal_hasExactlyThreeEntries() throws {
        let signature = try makeWebAuthn()
        guard case .map(let entries) = signature.toScVal() else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries?.count, 3)
    }

    func testWebAuthnToScVal_keysInAlphabeticalOrder() throws {
        let signature = try makeWebAuthn()
        let entries = mapEntries(of: signature.toScVal())
        let keys = entries.compactMap { entry -> String? in
            if case .symbol(let s) = entry.key { return s }
            return nil
        }
        XCTAssertEqual(keys, ["authenticator_data", "client_data", "signature"])
    }

    func testWebAuthnToScVal_authenticatorDataEntry() throws {
        let signature = try makeWebAuthn(authenticatorData: Data([0xAA, 0xBB]))
        let entries = mapEntries(of: signature.toScVal())
        guard case .bytes(let bytes) = entries[0].val else {
            XCTFail("Expected bytes value")
            return
        }
        XCTAssertEqual(bytes, Data([0xAA, 0xBB]))
    }

    func testWebAuthnToScVal_clientDataEntry() throws {
        let signature = try makeWebAuthn(clientData: Data([0xCC, 0xDD]))
        let entries = mapEntries(of: signature.toScVal())
        guard case .bytes(let bytes) = entries[1].val else {
            XCTFail("Expected bytes value")
            return
        }
        XCTAssertEqual(bytes, Data([0xCC, 0xDD]))
    }

    func testWebAuthnToScVal_signatureEntry() throws {
        let sigBytes = Data((0..<64).map { UInt8($0 & 0xFF) })
        let signature = try makeWebAuthn(signature: sigBytes)
        let entries = mapEntries(of: signature.toScVal())
        guard case .bytes(let bytes) = entries[2].val else {
            XCTFail("Expected bytes value")
            return
        }
        XCTAssertEqual(bytes, sigBytes)
    }

    func testWebAuthnToScVal_allZeroBytes() throws {
        let zeros = Data(repeating: 0x00, count: 64)
        let signature = try OZWebAuthnSignature(
            authenticatorData: Data(repeating: 0x00, count: 16),
            clientData: Data(repeating: 0x00, count: 16),
            signature: zeros
        )
        let entries = mapEntries(of: signature.toScVal())
        XCTAssertEqual(entries.count, 3)
    }

    func testWebAuthnToScVal_emptyAuthenticatorDataAllowed() throws {
        let signature = try makeWebAuthn(authenticatorData: Data())
        let entries = mapEntries(of: signature.toScVal())
        if case .bytes(let bytes) = entries[0].val {
            XCTAssertEqual(bytes, Data())
        } else {
            XCTFail("Expected bytes value")
        }
    }

    func testWebAuthnToScVal_emptyClientDataAllowed() throws {
        let signature = try makeWebAuthn(clientData: Data())
        let entries = mapEntries(of: signature.toScVal())
        if case .bytes(let bytes) = entries[1].val {
            XCTAssertEqual(bytes, Data())
        } else {
            XCTFail("Expected bytes value")
        }
    }

    func testWebAuthnToScVal_largeAuthenticatorData() throws {
        let large = Data(repeating: 0x42, count: 4096)
        let signature = try makeWebAuthn(authenticatorData: large)
        let entries = mapEntries(of: signature.toScVal())
        if case .bytes(let bytes) = entries[0].val {
            XCTAssertEqual(bytes.count, 4096)
        } else {
            XCTFail("Expected bytes value")
        }
    }

    func testWebAuthnToScVal_calledTwiceReturnsSameStructure() throws {
        let signature = try makeWebAuthn()
        let first = mapEntries(of: signature.toScVal())
        let second = mapEntries(of: signature.toScVal())
        XCTAssertEqual(first.count, second.count)
        for i in 0..<first.count {
            XCTAssertEqual(symbolName(first[i].key), symbolName(second[i].key))
        }
    }

    func testWebAuthnToScVal_keyNameIsClientData_notClientDataJson() throws {
        let signature = try makeWebAuthn()
        let entries = mapEntries(of: signature.toScVal())
        let keys = entries.map { symbolName($0.key) }
        XCTAssertTrue(keys.contains("client_data"))
        XCTAssertFalse(keys.contains("client_data_json"))
    }

    func testWebAuthnToScVal_inputMutationDoesNotAffectOriginalFields() throws {
        var authData = Data([0x01, 0x02, 0x03])
        let signature = try OZWebAuthnSignature(
            authenticatorData: authData,
            clientData: Data([0x04]),
            signature: Data(repeating: 0x10, count: 64)
        )
        authData[0] = 0xFF
        // The struct stores its own copy, so mutating the local input has no effect.
        if case .bytes(let stored) = mapEntries(of: signature.toScVal())[0].val {
            XCTAssertEqual(stored, Data([0x01, 0x02, 0x03]))
        }
    }

    func testWebAuthnValidation_errorMessageContainsFieldName() {
        do {
            _ = try OZWebAuthnSignature(
                authenticatorData: Data([0x01]),
                clientData: Data([0x02]),
                signature: Data([0x03])
            )
            XCTFail("Expected throw")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("signature"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testWebAuthnSignature_largeClientData_succeeds() throws {
        let large = Data(repeating: 0xAB, count: 8192)
        let signature = try makeWebAuthn(clientData: large)
        if case .bytes(let bytes) = mapEntries(of: signature.toScVal())[1].val {
            XCTAssertEqual(bytes.count, 8192)
        }
    }

    func testWebAuthnToScVal_allKeysAreSymbols() throws {
        let signature = try makeWebAuthn()
        let entries = mapEntries(of: signature.toScVal())
        for entry in entries {
            if case .symbol = entry.key { } else {
                XCTFail("Key was not a Symbol")
            }
        }
    }

    func testWebAuthnToScVal_allValuesAreBytes() throws {
        let signature = try makeWebAuthn()
        let entries = mapEntries(of: signature.toScVal())
        for entry in entries {
            if case .bytes = entry.val { } else {
                XCTFail("Value was not Bytes")
            }
        }
    }

    func testWebAuthnToScVal_matchesManualScvConstruction() throws {
        let signature = try makeWebAuthn(
            authenticatorData: Data([0x01]),
            clientData: Data([0x02]),
            signature: Data(repeating: 0x10, count: 64)
        )
        let manual: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("authenticator_data"), val: .bytes(Data([0x01]))),
            SCMapEntryXDR(key: .symbol("client_data"), val: .bytes(Data([0x02]))),
            SCMapEntryXDR(key: .symbol("signature"), val: .bytes(Data(repeating: 0x10, count: 64)))
        ])
        let producedHex = try Data(XDREncoder.encode(signature.toScVal())).base16EncodedString()
        let manualHex = try Data(XDREncoder.encode(manual)).base16EncodedString()
        XCTAssertEqual(producedHex, manualHex)
    }

    // MARK: - OZWebAuthnSignature equality / hashing

    func testWebAuthnSignature_identicalFields_equals() throws {
        let a = try makeWebAuthn()
        let b = try makeWebAuthn()
        XCTAssertEqual(a, b)
    }

    func testWebAuthnSignature_sameInstance_equals() throws {
        let a = try makeWebAuthn()
        XCTAssertEqual(a, a)
    }

    func testWebAuthnSignature_differentAuthenticatorData_notEqual() throws {
        let a = try makeWebAuthn(authenticatorData: Data([0x01]))
        let b = try makeWebAuthn(authenticatorData: Data([0x02]))
        XCTAssertNotEqual(a, b)
    }

    func testWebAuthnSignature_differentClientData_notEqual() throws {
        let a = try makeWebAuthn(clientData: Data([0x01]))
        let b = try makeWebAuthn(clientData: Data([0x02]))
        XCTAssertNotEqual(a, b)
    }

    func testWebAuthnSignature_differentSignature_notEqual() throws {
        let sig1 = Data(repeating: 0x01, count: 64)
        let sig2 = Data(repeating: 0x02, count: 64)
        let a = try makeWebAuthn(signature: sig1)
        let b = try makeWebAuthn(signature: sig2)
        XCTAssertNotEqual(a, b)
    }

    func testWebAuthnSignature_hashCodeConsistentAcrossCalls() throws {
        let a = try makeWebAuthn()
        XCTAssertEqual(a.hashValue, a.hashValue)
    }

    func testWebAuthnSignature_equalObjects_sameHashCode() throws {
        let a = try makeWebAuthn()
        let b = try makeWebAuthn()
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testWebAuthnSignature_differentAuthenticatorData_differentHashCode() throws {
        let a = try makeWebAuthn(authenticatorData: Data([0x01]))
        let b = try makeWebAuthn(authenticatorData: Data([0x02, 0x03]))
        XCTAssertNotEqual(a.hashValue, b.hashValue)
    }

    func testWebAuthnSignature_differentSignatureBytes_differentHashCode() throws {
        let sig1 = Data(repeating: 0x01, count: 64)
        let sig2 = Data(repeating: 0x02, count: 64)
        let a = try makeWebAuthn(signature: sig1)
        let b = try makeWebAuthn(signature: sig2)
        XCTAssertNotEqual(a.hashValue, b.hashValue)
    }

    func testWebAuthnSignature_emptySignature_throws() {
        XCTAssertThrowsError(
            try OZWebAuthnSignature(
                authenticatorData: Data([0x01]),
                clientData: Data([0x02]),
                signature: Data()
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testWebAuthnSignature_copyChangesSignature() throws {
        let a = try makeWebAuthn()
        let differentSig = Data(repeating: 0x99, count: 64)
        let b = try OZWebAuthnSignature(
            authenticatorData: a.authenticatorData,
            clientData: a.clientData,
            signature: differentSig
        )
        XCTAssertNotEqual(a, b)
    }

    // MARK: - OZPolicySignature

    func testPolicySignatureToScVal_returnsMapType() {
        XCTAssertTrue(OZPolicySignature.instance.toScVal().isMap)
    }

    func testPolicySignatureToScVal_mapIsEmpty() {
        guard case .map(let entries) = OZPolicySignature.instance.toScVal() else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries?.count, 0)
    }

    func testPolicySignatureToScVal_calledTwiceReturnsSameStructure() {
        let a = OZPolicySignature.instance.toScVal()
        let b = OZPolicySignature.instance.toScVal()
        XCTAssertEqual(try Data(XDREncoder.encode(a)).base16EncodedString(),
                       try Data(XDREncoder.encode(b)).base16EncodedString())
    }

    func testPolicySignature_isSingleton() {
        let a = OZPolicySignature.instance
        let b = OZPolicySignature.instance
        XCTAssertEqual(a, b)
    }

    func testPolicySignature_isOZSmartAccountSignature() {
        let signature: any OZSmartAccountSignature = OZPolicySignature.instance
        XCTAssertNotNil(signature)
    }

    func testWebAuthnSignature_isOZSmartAccountSignature() throws {
        let signature: any OZSmartAccountSignature = try makeWebAuthn()
        XCTAssertNotNil(signature)
    }

    func testSealedClass_whenExhaustive() throws {
        // Exhaustively constructable: WebAuthn + Ed25519 + Policy variants.
        let webauthn: any OZSmartAccountSignature = try makeWebAuthn()
        let ed25519: any OZSmartAccountSignature = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        let policy: any OZSmartAccountSignature = OZPolicySignature.instance
        XCTAssertNotNil(webauthn)
        XCTAssertNotNil(ed25519)
        XCTAssertNotNil(policy)
    }

    func testWebAuthnSignature_notEqualToPolicySignature() throws {
        let webauthn = try makeWebAuthn()
        let webauthnVal = try Data(XDREncoder.encode(webauthn.toScVal()))
        let policyVal = try Data(XDREncoder.encode(OZPolicySignature.instance.toScVal()))
        XCTAssertNotEqual(webauthnVal, policyVal)
    }

    func testPolicySignature_notEqualToWebAuthn() throws {
        let webauthnVal = try Data(XDREncoder.encode(try makeWebAuthn().toScVal()))
        let policyVal = try Data(XDREncoder.encode(OZPolicySignature.instance.toScVal()))
        XCTAssertNotEqual(policyVal, webauthnVal)
    }

    func testPolicySignatureToScVal_matchesManualScvConstruction() {
        let manual: SCValXDR = .map([])
        let manualHex = try? Data(XDREncoder.encode(manual)).base16EncodedString()
        let producedHex = try? Data(XDREncoder.encode(OZPolicySignature.instance.toScVal())).base16EncodedString()
        XCTAssertEqual(producedHex, manualHex)
    }

    func testWebAuthnSignature_notEqualToNull_directConstruction() throws {
        let signature = try makeWebAuthn()
        // Cast through optional to exercise the not-equal-to-nil branch.
        let asOptional: OZWebAuthnSignature? = signature
        XCTAssertNotNil(asOptional)
    }

    func testWebAuthnSignature_notEqualToDifferentType() throws {
        let webauthn = try makeWebAuthn()
        let ed25519 = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        let webHex = try Data(XDREncoder.encode(webauthn.toScVal())).base16EncodedString()
        let edHex = try Data(XDREncoder.encode(ed25519.toScVal())).base16EncodedString()
        XCTAssertNotEqual(webHex, edHex)
    }

    // MARK: - OZEd25519Signature

    func testEd25519Signature_isOZSmartAccountSignature() throws {
        let signature: any OZSmartAccountSignature = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        XCTAssertNotNil(signature)
    }

    func testEd25519Signature_invalidPublicKey_throws() {
        XCTAssertThrowsError(
            try OZEd25519Signature(
                publicKey: Data(repeating: 0x02, count: 31),
                signature: Data(repeating: 0x03, count: 64)
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testEd25519Signature_invalidSignatureSize_throws() {
        XCTAssertThrowsError(
            try OZEd25519Signature(
                publicKey: Data(repeating: 0x02, count: 32),
                signature: Data(repeating: 0x03, count: 63)
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testEd25519Signature_toScVal_alphabeticalKeys() throws {
        let signature = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        let entries = mapEntries(of: signature.toScVal())
        let keys = entries.map { symbolName($0.key) }
        XCTAssertEqual(keys, ["public_key", "signature"])
    }

    func testEd25519Signature_equality_constantTime() throws {
        let key = Data(repeating: 0x02, count: 32)
        let sig = Data(repeating: 0x03, count: 64)
        let a = try OZEd25519Signature(publicKey: key, signature: sig)
        let b = try OZEd25519Signature(publicKey: key, signature: sig)
        XCTAssertEqual(a, b)
        let differentSig = Data(repeating: 0x04, count: 64)
        let c = try OZEd25519Signature(publicKey: key, signature: differentSig)
        XCTAssertNotEqual(a, c)
    }

    func testEd25519Signature_hashCodeConsistent() throws {
        let a = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        let b = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testEd25519Signature_toScVal_returnsMapType() throws {
        let signature = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        XCTAssertTrue(signature.toScVal().isMap)
    }

    func testEd25519Signature_toScVal_hasExactlyTwoEntries() throws {
        let signature = try OZEd25519Signature(
            publicKey: Data(repeating: 0x02, count: 32),
            signature: Data(repeating: 0x03, count: 64)
        )
        guard case .map(let entries) = signature.toScVal() else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries?.count, 2)
    }

    // MARK: - Cross-SDK byte-identity golden vector (WebAuthnSignature)
    //
    // Pins the byte-level XDR encoding of `OZWebAuthnSignature.toScVal()`. The
    // fixture inputs (37 bytes 0xAA, 16 bytes 0xBB, 64 bytes 0xCC) are chosen
    // so any drift in field name (`client_data` vs `client_data_json`),
    // alphabetical key ordering, or value-bytes encoding produces a different
    // hex output and breaks the cross-SDK test in lockstep.

    func test_phase4_goldenVector6_webAuthnSignatureWireShape_matchesFixture() throws {
        let signature = try OZWebAuthnSignature(
            authenticatorData: Data(repeating: 0xAA, count: 37),
            clientData: Data(repeating: 0xBB, count: 16),
            signature: Data(repeating: 0xCC, count: 64)
        )
        let scVal = signature.toScVal()
        let encoded = try Data(XDREncoder.encode(scVal))
        let actualHex = encoded.base16EncodedString().lowercased()
        let expectedHex =
            "0000001100000001000000030000000f0000001261757468656e74696361746f725f6461746100000000000d00000025aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000f0000000b636c69656e745f64617461000000000d00000010bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000f000000097369676e61747572650000000000000d00000040cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
        XCTAssertEqual(actualHex, expectedHex,
                       "Golden vector 6 mismatch — actual: \(actualHex)")
    }

    // MARK: - Helpers

    private func makeWebAuthn(
        authenticatorData: Data = Data([0xAA]),
        clientData: Data = Data([0xBB]),
        signature: Data = Data(repeating: 0xCC, count: 64)
    ) throws -> OZWebAuthnSignature {
        return try OZWebAuthnSignature(
            authenticatorData: authenticatorData,
            clientData: clientData,
            signature: signature
        )
    }

    private func mapEntries(of value: SCValXDR) -> [SCMapEntryXDR] {
        if case .map(let entries) = value, let entries = entries {
            return entries
        }
        return []
    }

    private func symbolName(_ value: SCValXDR) -> String? {
        if case .symbol(let name) = value { return name }
        return nil
    }
}
