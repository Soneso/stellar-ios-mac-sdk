//
//  OZSmartAccountBuildersTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSmartAccountBuildersTests: XCTestCase {

    private var validAccountG: String = ""
    private var validAccountG2: String = ""
    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    override func setUp() {
        super.setUp()
        validAccountG = try! KeyPair.generateRandomKeyPair().accountId
        validAccountG2 = try! KeyPair.generateRandomKeyPair().accountId
    }

    // MARK: - getSignerKey

    func testGetSignerKey_delegatedSigner_returnsUniqueKeyWithDelegatedPrefix() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let key = OZSmartAccountBuilders.getSignerKey(signer: signer)
        XCTAssertEqual(key, "delegated:\(validAccountG)")
    }

    func testGetSignerKey_externalSigner_returnsUniqueKeyWithExternalPrefixAndHexKeyData() throws {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let signer = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: publicKey)
        let key = OZSmartAccountBuilders.getSignerKey(signer: signer)
        XCTAssertTrue(key.hasPrefix("external:\(validContractC):"))
        XCTAssertTrue(key.contains(publicKey.base16EncodedString()))
    }

    func testGetSignerKey_matchesDelegatedSignerUniqueKey() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertEqual(OZSmartAccountBuilders.getSignerKey(signer: signer), signer.uniqueKey)
    }

    func testGetSignerKey_matchesExternalSignerUniqueKey() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertEqual(OZSmartAccountBuilders.getSignerKey(signer: signer), signer.uniqueKey)
    }

    // MARK: - collectUniqueSigners

    func testCollectUniqueSigners_emptyList_returnsEmpty() {
        let result = OZSmartAccountBuilders.collectUniqueSigners(signers: [])
        XCTAssertEqual(result.count, 0)
    }

    func testCollectUniqueSigners_singleSigner_returnsSameSigner() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = OZSmartAccountBuilders.collectUniqueSigners(signers: [signer])
        XCTAssertEqual(result.count, 1)
    }

    func testCollectUniqueSigners_duplicateDelegatedSigners_deduplicatesToOne() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZDelegatedSigner(address: validAccountG)
        let result = OZSmartAccountBuilders.collectUniqueSigners(signers: [s1, s2])
        XCTAssertEqual(result.count, 1)
    }

    func testCollectUniqueSigners_duplicateExternalSigners_deduplicatesToOne() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let result = OZSmartAccountBuilders.collectUniqueSigners(signers: [s1, s2])
        XCTAssertEqual(result.count, 1)
    }

    func testCollectUniqueSigners_differentSigners_allKept() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZDelegatedSigner(address: validAccountG2)
        let s3 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let result = OZSmartAccountBuilders.collectUniqueSigners(signers: [s1, s2, s3])
        XCTAssertEqual(result.count, 3)
    }

    func testCollectUniqueSigners_preservesOrderFirstOccurrence() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZDelegatedSigner(address: validAccountG2)
        let dup = try OZDelegatedSigner(address: validAccountG)
        let result = OZSmartAccountBuilders.collectUniqueSigners(signers: [s1, s2, dup])
        XCTAssertEqual(result.count, 2)
        if let first = result[0] as? OZDelegatedSigner {
            XCTAssertEqual(first.address, validAccountG)
        }
    }

    func testCollectUniqueSigners_mixedDuplicates_preservesInsertionOrder() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let s3 = try OZDelegatedSigner(address: validAccountG2)
        let dupS1 = try OZDelegatedSigner(address: validAccountG)
        let result = OZSmartAccountBuilders.collectUniqueSigners(signers: [s1, s2, s3, dupS1])
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - describeSignerType

    func testDescribeSignerType_delegatedSigner_returnsStellarAccount() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertEqual(OZSmartAccountBuilders.describeSignerType(signer: signer), "Stellar Account")
    }

    func testDescribeSignerType_webAuthnSigner_returnsPasskeyWebAuthn() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: Data([0xAA, 0xBB])
        )
        XCTAssertEqual(OZSmartAccountBuilders.describeSignerType(signer: signer), "Passkey (WebAuthn)")
    }

    func testDescribeSignerType_externalSignerWithOtherKeySize_returnsExternalVerifier() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data(repeating: 0xAA, count: 16))
        XCTAssertEqual(OZSmartAccountBuilders.describeSignerType(signer: signer), "External Verifier")
    }

    func testDescribeSignerType_ed25519Signer_returnsEd25519() throws {
        let signer = try OZExternalSigner.ed25519(
            verifierAddress: validContractC,
            publicKey: Data(repeating: 0xAA, count: 32)
        )
        XCTAssertEqual(OZSmartAccountBuilders.describeSignerType(signer: signer), "Ed25519")
    }

    // MARK: - signersEqual

    func testSignersEqual_sameDelegatedSigner_returnsTrue() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZDelegatedSigner(address: validAccountG)
        XCTAssertTrue(OZSmartAccountBuilders.signersEqual(s1, s2))
    }

    func testSignersEqual_differentDelegatedSigners_returnsFalse() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZDelegatedSigner(address: validAccountG2)
        XCTAssertFalse(OZSmartAccountBuilders.signersEqual(s1, s2))
    }

    func testSignersEqual_sameExternalSigner_returnsTrue() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertTrue(OZSmartAccountBuilders.signersEqual(s1, s2))
    }

    func testSignersEqual_externalSignersDifferentVerifier_returnsFalse() throws {
        let alt = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let s2 = try OZExternalSigner(verifierAddress: alt, keyData: Data([0xAA]))
        XCTAssertFalse(OZSmartAccountBuilders.signersEqual(s1, s2))
    }

    func testSignersEqual_externalSignersDifferentKeyData_returnsFalse() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xBB]))
        XCTAssertFalse(OZSmartAccountBuilders.signersEqual(s1, s2))
    }

    func testSignersEqual_delegatedVsExternal_returnsFalse() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertFalse(OZSmartAccountBuilders.signersEqual(s1, s2))
    }

    func testSignersEqual_externalVsDelegated_returnsFalse() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let s2 = try OZDelegatedSigner(address: validAccountG)
        XCTAssertFalse(OZSmartAccountBuilders.signersEqual(s1, s2))
    }

    // MARK: - signerMatchesCredentialId

    func testSignerMatchesCredentialId_matchingCredentialId_returnsTrue() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let credId = Data([0xAA, 0xBB])
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: credId
        )
        let credIdString = credId.base64URLEncodedString()
        XCTAssertTrue(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: credIdString)
        )
    }

    func testSignerMatchesCredentialId_nonMatchingCredentialId_returnsFalse() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: Data([0xAA])
        )
        XCTAssertFalse(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: "not-a-match")
        )
    }

    func testSignerMatchesCredentialId_delegatedSigner_returnsFalse() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertFalse(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: "anything")
        )
    }

    func testSignerMatchesCredentialId_emptyCredentialIdString_returnsFalse() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertFalse(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: "")
        )
    }

    func testSignerMatchesCredentialId_acceptsPaddedAndUnpaddedBase64UrlInputs() throws {
        // Credential id whose canonical Base64URL encoding requires one `=`
        // pad character: a single byte yields a 2-char unpadded encoding plus
        // `==` padding under standard Base64. A 2-byte id maps to `kqs` /
        // `kqs=` (1-char pad). Use a 2-byte fixture so we can compare against
        // both spellings without ambiguity.
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let credId = Data([0x92, 0xAB])
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: credId
        )
        let unpadded = credId.base64URLEncodedString()
        // Sanity-check the fixture: the SDK encoder strips padding, so
        // re-padding by hand for the assertion below is well-defined.
        XCTAssertFalse(unpadded.contains("="))
        let paddedOnce = unpadded + "="
        let paddedTwice = unpadded + "=="

        XCTAssertTrue(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: unpadded)
        )
        XCTAssertTrue(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: paddedOnce),
            "padded Base64URL input must match the unpadded signer-derived id"
        )
        XCTAssertTrue(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: paddedTwice),
            "double-padded Base64URL input must match the unpadded signer-derived id"
        )
    }

    func testGetCredentialIdStringFromSigner_outputIsUnpadded() throws {
        // Cover credential-id byte lengths whose Base64URL encoding would
        // produce 1- and 2-char `=` padding under standard Base64. The SDK
        // helper must strip both.
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let oneBytePaddingId = Data([0x92, 0xAB])  // → "kqs", padded form "kqs="
        let twoBytePaddingId = Data([0xCC])         // → "zA", padded form "zA=="

        let signer1 = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: oneBytePaddingId
        )
        let signer2 = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: twoBytePaddingId
        )

        let out1 = OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer1)
        let out2 = OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer2)
        XCTAssertNotNil(out1)
        XCTAssertNotNil(out2)
        XCTAssertFalse(out1!.hasSuffix("="), "credential id string must not carry trailing padding")
        XCTAssertFalse(out2!.hasSuffix("="), "credential id string must not carry trailing padding")
    }

    // MARK: - signerMatchesAddress

    func testSignerMatchesAddress_delegatedSignerMatchingAddress_returnsTrue() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertTrue(OZSmartAccountBuilders.signerMatchesAddress(signer: signer, address: validAccountG))
    }

    func testSignerMatchesAddress_delegatedSignerDifferentAddress_returnsFalse() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertFalse(OZSmartAccountBuilders.signerMatchesAddress(signer: signer, address: validAccountG2))
    }

    func testSignerMatchesAddress_externalSigner_returnsFalse() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertFalse(OZSmartAccountBuilders.signerMatchesAddress(signer: signer, address: validAccountG))
    }

    func testSignerMatchesAddress_webAuthnSigner_returnsFalse() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: Data([0xAA])
        )
        XCTAssertFalse(OZSmartAccountBuilders.signerMatchesAddress(signer: signer, address: validAccountG))
    }

    // MARK: - is{Delegated,External}Signer

    func testIsDelegatedSigner_withDelegatedSigner_returnsTrue() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertTrue(OZSmartAccountBuilders.isDelegatedSigner(signer: signer))
    }

    func testIsDelegatedSigner_withExternalSigner_returnsFalse() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertFalse(OZSmartAccountBuilders.isDelegatedSigner(signer: signer))
    }

    func testIsExternalSigner_withExternalSigner_returnsTrue() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertTrue(OZSmartAccountBuilders.isExternalSigner(signer: signer))
    }

    func testIsExternalSigner_withDelegatedSigner_returnsFalse() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertFalse(OZSmartAccountBuilders.isExternalSigner(signer: signer))
    }

    func testIsDelegatedSigner_webAuthnSigner_returnsFalse() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: Data([0xAA])
        )
        XCTAssertFalse(OZSmartAccountBuilders.isDelegatedSigner(signer: signer))
    }

    func testIsExternalSigner_webAuthnSigner_returnsTrue() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: Data([0xAA])
        )
        XCTAssertTrue(OZSmartAccountBuilders.isExternalSigner(signer: signer))
    }

    // MARK: - signerMatchesCredential (raw bytes)

    func testSignerMatchesCredential_matchingCredentialBytes_returnsTrue() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let credId = Data([0xAA, 0xBB])
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: credId
        )
        XCTAssertTrue(OZSmartAccountBuilders.signerMatchesCredential(signer: signer, credentialId: credId))
    }

    func testSignerMatchesCredential_nonMatchingCredentialBytes_returnsFalse() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: Data([0xAA])
        )
        XCTAssertFalse(
            OZSmartAccountBuilders.signerMatchesCredential(signer: signer, credentialId: Data([0xCC]))
        )
    }

    func testSignerMatchesCredential_delegatedSigner_returnsFalse() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertFalse(
            OZSmartAccountBuilders.signerMatchesCredential(signer: signer, credentialId: Data([0xAA]))
        )
    }

    // MARK: - getCredentialId{,String}FromSigner

    func testGetCredentialIdFromSigner_delegatedSigner_returnsNull() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertNil(OZSmartAccountBuilders.getCredentialIdFromSigner(signer: signer))
    }

    func testGetCredentialIdFromSigner_webAuthnSigner_returnsCredentialIdBytes() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let credId = Data([0xAA, 0xBB])
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: credId
        )
        XCTAssertEqual(OZSmartAccountBuilders.getCredentialIdFromSigner(signer: signer), credId)
    }

    func testGetCredentialIdFromSigner_webAuthnSigner_returnsOnlyCredentialIdPortion() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let credId = Data([0xCC, 0xDD, 0xEE])
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: credId
        )
        let extracted = OZSmartAccountBuilders.getCredentialIdFromSigner(signer: signer)
        XCTAssertEqual(extracted, credId)
    }

    func testGetCredentialIdStringFromSigner_delegatedSigner_returnsNull() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertNil(OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer))
    }

    func testGetCredentialIdStringFromSigner_webAuthnSigner_roundTripsWithMatchFunction() throws {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let credId = Data([0xAA, 0xBB])
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: pubkey,
            credentialId: credId
        )
        let credString = OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: signer)
        XCTAssertNotNil(credString)
        XCTAssertTrue(
            OZSmartAccountBuilders.signerMatchesCredentialId(signer: signer, credentialId: credString!)
        )
    }

    // MARK: - Builder validation (signer builders)

    func testCreateExternalSigner_invalidCAddress_throwsInvalidAddress() {
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createExternalSigner(
                verifierAddress: "not-a-c-address",
                keyData: Data([0x01])
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidAddress)
        }
    }

    func testCreateWebAuthnSigner_invalidCAddress_throwsInvalidAddress() {
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createWebAuthnSigner(
                webauthnVerifierAddress: "not-a-c-address",
                publicKey: pubkey,
                credentialId: Data([0xAA])
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidAddress)
        }
    }

    func testCreateEd25519Signer_invalidCAddress_throwsInvalidAddress() {
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createEd25519Signer(
                ed25519VerifierAddress: "not-a-c-address",
                publicKey: Data(repeating: 0x42, count: 32)
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidAddress)
        }
    }

    func testCreateDelegatedSigner_validAddress_returnsSigner() throws {
        let signer = try OZSmartAccountBuilders.createDelegatedSigner(publicKey: validAccountG)
        XCTAssertEqual(signer.address, validAccountG)
    }

    func testCreateExternalSigner_validInputs_returnsSigner() throws {
        let signer = try OZSmartAccountBuilders.createExternalSigner(
            verifierAddress: validContractC,
            keyData: Data([0xAA])
        )
        XCTAssertEqual(signer.verifierAddress, validContractC)
    }

    // MARK: - createThresholdParams

    func testCreateThresholdParams_thresholdZero_throwsInvalidInput() {
        XCTAssertThrowsError(try OZSmartAccountBuilders.createThresholdParams(threshold: 0)) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testCreateThresholdParams_thresholdNegative_throwsInvalidInput() {
        XCTAssertThrowsError(try OZSmartAccountBuilders.createThresholdParams(threshold: -3)) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testCreateThresholdParams_validThreshold_returnsParams() throws {
        let params = try OZSmartAccountBuilders.createThresholdParams(threshold: 2)
        XCTAssertEqual(params.threshold, 2)
    }

    func testCreateThresholdParams_minimumThreshold_returnsParams() throws {
        let params = try OZSmartAccountBuilders.createThresholdParams(threshold: 1)
        XCTAssertEqual(params.threshold, 1)
    }

    // MARK: - createWeightedThresholdParams

    func testCreateWeightedThresholdParams_emptySignerWeights_throwsInvalidInput() {
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createWeightedThresholdParams(threshold: 1, signerWeights: [])
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testCreateWeightedThresholdParams_zeroWeight_throwsInvalidInput() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createWeightedThresholdParams(
                threshold: 1,
                signerWeights: [OZSignerWeight(signer: signer, weight: 0)]
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testCreateWeightedThresholdParams_totalWeightLessThanThreshold_throwsInvalidInput() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createWeightedThresholdParams(
                threshold: 10,
                signerWeights: [OZSignerWeight(signer: signer, weight: 1)]
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testCreateWeightedThresholdParams_thresholdZero_throwsInvalidInput() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createWeightedThresholdParams(
                threshold: 0,
                signerWeights: [OZSignerWeight(signer: signer, weight: 1)]
            )
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testCreateWeightedThresholdParams_validInputs_returnsParams() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let params = try OZSmartAccountBuilders.createWeightedThresholdParams(
            threshold: 2,
            signerWeights: [OZSignerWeight(signer: signer, weight: 5)]
        )
        XCTAssertEqual(params.threshold, 2)
        XCTAssertEqual(params.signerWeights.count, 1)
    }

    func testCreateWeightedThresholdParams_multipleSigners_totalWeightMeetsThreshold() throws {
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let params = try OZSmartAccountBuilders.createWeightedThresholdParams(
            threshold: 3,
            signerWeights: [
                OZSignerWeight(signer: s1, weight: 2),
                OZSignerWeight(signer: s2, weight: 2)
            ]
        )
        XCTAssertEqual(params.threshold, 3)
        XCTAssertEqual(params.signerWeights.count, 2)
    }

    // MARK: - createSpendingLimitParams

    func testCreateSpendingLimitParams_periodLedgersZero_throwsInvalidInput() {
        XCTAssertThrowsError(
            try OZSmartAccountBuilders.createSpendingLimitParams(spendingLimit: "1", periodLedgers: 0)
        ) { error in
            XCTAssertTrue(error is ValidationException.InvalidInput)
        }
    }

    func testCreateSpendingLimitParams_validInputs_returnsParams() throws {
        let params = try OZSmartAccountBuilders.createSpendingLimitParams(
            spendingLimit: "100",
            periodLedgers: StellarProtocolConstants.ledgersPerDay
        )
        XCTAssertEqual(params.spendingLimit, 1_000_000_000)
        XCTAssertEqual(params.periodLedgers, StellarProtocolConstants.ledgersPerDay)
    }

    func testCreateSpendingLimitParams_minimumPeriod_returnsParams() throws {
        let params = try OZSmartAccountBuilders.createSpendingLimitParams(
            spendingLimit: "10",
            periodLedgers: 1
        )
        XCTAssertEqual(params.periodLedgers, 1)
    }

    func testCreateSpendingLimitParams_hourPeriod_returnsParams() throws {
        let params = try OZSmartAccountBuilders.createSpendingLimitParams(
            spendingLimit: "50",
            periodLedgers: StellarProtocolConstants.ledgersPerHour
        )
        XCTAssertEqual(params.periodLedgers, StellarProtocolConstants.ledgersPerHour)
    }

    // MARK: - OZSignerWeight

    func testOZSignerWeight_storesSignerAndWeight() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let weight = OZSignerWeight(signer: signer, weight: 3)
        XCTAssertEqual(weight.weight, 3)
        XCTAssertTrue(weight.signer is OZDelegatedSigner)
    }

    // MARK: - OZSimpleThresholdParams

    func testOZSimpleThresholdParams_storesThreshold() {
        let params = OZSimpleThresholdParams(threshold: 5)
        XCTAssertEqual(params.threshold, 5)
    }

    // MARK: - OZWeightedThresholdParams

    func testOZWeightedThresholdParams_storesThresholdAndWeights() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let weights = [OZSignerWeight(signer: signer, weight: 2)]
        let params = OZWeightedThresholdParams(threshold: 2, signerWeights: weights)
        XCTAssertEqual(params.threshold, 2)
        XCTAssertEqual(params.signerWeights.count, 1)
    }
}
