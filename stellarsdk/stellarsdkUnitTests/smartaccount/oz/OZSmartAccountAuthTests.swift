//
//  OZSmartAccountAuthTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSmartAccountAuthTests: XCTestCase {

    private var validAccountG: String = ""
    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let testNetwork = "Test SDF Network ; September 2015"
    private let publicNetwork = "Public Global Stellar Network ; September 2015"

    override func setUp() {
        super.setUp()
        validAccountG = try! KeyPair.generateRandomKeyPair().accountId
    }

    // MARK: - buildSourceAccountAuthPayloadHash

    func testBuildSourceAccountAuthPayloadHash_differentNoncesProduceDifferentHashes() async throws {
        let entry = try makeEntry()
        let h1 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 1, expirationLedger: 100, networkPassphrase: testNetwork
        )
        let h2 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 2, expirationLedger: 100, networkPassphrase: testNetwork
        )
        XCTAssertNotEqual(h1, h2)
    }

    func testBuildSourceAccountAuthPayloadHash_differentExpirationProducesDifferentHash() async throws {
        let entry = try makeEntry()
        let h1 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 1, expirationLedger: 100, networkPassphrase: testNetwork
        )
        let h2 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 1, expirationLedger: 200, networkPassphrase: testNetwork
        )
        XCTAssertNotEqual(h1, h2)
    }

    func testBuildSourceAccountAuthPayloadHash_differentNetworkPassphraseProducesDifferentHash() async throws {
        let entry = try makeEntry()
        let h1 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 1, expirationLedger: 100, networkPassphrase: testNetwork
        )
        let h2 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 1, expirationLedger: 100, networkPassphrase: publicNetwork
        )
        XCTAssertNotEqual(h1, h2)
    }

    func testBuildSourceAccountAuthPayloadHash_isConsistent() async throws {
        let entry = try makeEntry()
        let h1 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 1, expirationLedger: 100, networkPassphrase: testNetwork
        )
        let h2 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 1, expirationLedger: 100, networkPassphrase: testNetwork
        )
        XCTAssertEqual(h1, h2)
    }

    func testBuildSourceAccountAuthPayloadHash_matchesManualPreimageConstruction() async throws {
        let entry = try makeEntry()
        let h = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 12, expirationLedger: 300, networkPassphrase: testNetwork
        )
        let networkId = testNetwork.sha256Hash
        let preimage = HashIDPreimageXDR.sorobanAuthorization(
            HashIDPreimageSorobanAuthorizationXDR(
                networkID: HashXDR(networkId),
                nonce: 12,
                signatureExpirationLedger: 300,
                invocation: entry.rootInvocation
            )
        )
        let manual = Data(try XDREncoder.encode(preimage)).sha256Hash
        XCTAssertEqual(h, manual)
    }

    func testBuildAuthPayloadHash_throwsOnVoidCredentials() async throws {
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: try makeInvocation()
        )
        do {
            _ = try await OZSmartAccountAuth.buildAuthPayloadHash(
                entry: entry, expirationLedger: 100, networkPassphrase: testNetwork
            )
            XCTFail("Expected throw")
        } catch is SmartAccountTransactionException.SigningFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBuildAuthPayloadHash_andBuildSourceAccountAuthPayloadHash_sameInputsProduceSameHash() async throws {
        let entry = try makeEntry(nonce: 5, expirationLedger: 200)
        let h1 = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry, expirationLedger: 200, networkPassphrase: testNetwork
        )
        let h2 = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
            entry: entry, nonce: 5, expirationLedger: 200, networkPassphrase: testNetwork
        )
        XCTAssertEqual(h1, h2)
    }

    // MARK: - addRawSignatureMapEntry

    func testAddRawSignatureMapEntry_addsEntryToVoidSignatureEntry() throws {
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: try signer.toScVal(),
            signatureValue: .bytes(Data())
        )
        guard case .address(let credentials) = result.credentials,
              case .map(let entries) = credentials.signature, let entries = entries else {
            XCTFail("Expected map signature")
            return
        }
        XCTAssertEqual(entries.count, 2)
    }

    func testAddRawSignatureMapEntry_mapEntryHasCorrectKeyAndValue() throws {
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: try signer.toScVal(),
            signatureValue: .bytes(Data([0xAA, 0xBB]))
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertEqual(payload.signers[0].signatureBytes, Data([0xAA, 0xBB]))
    }

    func testAddRawSignatureMapEntry_secondCallProducesTwoEntries() throws {
        let entry = try makeEntry()
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        var result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry, signerKey: try s1.toScVal(), signatureValue: .bytes(Data([0xAA]))
        )
        result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: result, signerKey: try s2.toScVal(), signatureValue: .bytes(Data([0xBB]))
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.signers.count, 2)
    }

    func testAddRawSignatureMapEntry_mapEntriesAreSortedByXdrEncodedKey() throws {
        let entry = try makeEntry()
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xFF]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        var resultA = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry, signerKey: try s1.toScVal(), signatureValue: .bytes(Data([0xAA]))
        )
        resultA = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: resultA, signerKey: try s2.toScVal(), signatureValue: .bytes(Data([0xBB]))
        )
        var resultB = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry, signerKey: try s2.toScVal(), signatureValue: .bytes(Data([0xBB]))
        )
        resultB = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: resultB, signerKey: try s1.toScVal(), signatureValue: .bytes(Data([0xAA]))
        )
        // Both orders must yield byte-identical encodings due to inner sorting.
        let encA = try Data(XDREncoder.encode(resultA))
        let encB = try Data(XDREncoder.encode(resultB))
        XCTAssertEqual(encA, encB)
    }

    func testAddRawSignatureMapEntry_throwsOnSourceAccountCredentials() throws {
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount, rootInvocation: try makeInvocation()
        )
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertThrowsError(
            try OZSmartAccountAuth.addRawSignatureMapEntry(
                entry: entry, signerKey: try signer.toScVal(), signatureValue: .bytes(Data())
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountTransactionException.SigningFailed)
        }
    }

    func testSignAuthEntry_throwsOnVoidCredentials() async throws {
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount, rootInvocation: try makeInvocation()
        )
        let signer = try OZDelegatedSigner(address: validAccountG)
        do {
            _ = try await OZSmartAccountAuth.signAuthEntry(
                entry: entry,
                signer: signer,
                signature: OZPolicySignature.instance,
                expirationLedger: 100
            )
            XCTFail("Expected throw")
        } catch is SmartAccountTransactionException.SigningFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAddRawSignatureMapEntry_doesNotMutateOriginalEntry() throws {
        let entry = try makeEntry()
        let originalEnc = try Data(XDREncoder.encode(entry))
        let signer = try OZDelegatedSigner(address: validAccountG)
        _ = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry, signerKey: try signer.toScVal(), signatureValue: .bytes(Data([0xAA]))
        )
        let afterEnc = try Data(XDREncoder.encode(entry))
        XCTAssertEqual(originalEnc, afterEnc)
    }

    func testAddRawSignatureMapEntry_rawBytesAreStoredAsScvBytes() throws {
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry, signerKey: try signer.toScVal(), signatureValue: .bytes(Data([0x99]))
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.signers[0].signatureBytes, Data([0x99]))
    }

    // MARK: - signAuthEntry

    func testSignAuthEntry_twoSignersAccumulateCorrectly() async throws {
        let entry = try makeEntry()
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let policy = OZPolicySignature.instance

        var result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry, signer: s1, signature: policy, expirationLedger: 100
        )
        result = try await OZSmartAccountAuth.signAuthEntry(
            entry: result, signer: s2, signature: policy, expirationLedger: 100
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.signers.count, 2)
    }

    func testSignAuthEntry_twoSignersResultIsSortedByXdrEncodedKey() async throws {
        let entry = try makeEntry()
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xFF]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        let policy = OZPolicySignature.instance
        var resultA = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry, signer: s1, signature: policy, expirationLedger: 100
        )
        resultA = try await OZSmartAccountAuth.signAuthEntry(
            entry: resultA, signer: s2, signature: policy, expirationLedger: 100
        )
        var resultB = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry, signer: s2, signature: policy, expirationLedger: 100
        )
        resultB = try await OZSmartAccountAuth.signAuthEntry(
            entry: resultB, signer: s1, signature: policy, expirationLedger: 100
        )
        XCTAssertEqual(try Data(XDREncoder.encode(resultA)), try Data(XDREncoder.encode(resultB)))
    }

    func testSignAuthEntry_followedByAddRawSignatureMapEntry_bothEntriesPresent() async throws {
        let entry = try makeEntry()
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))

        var result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry, signer: s1, signature: OZPolicySignature.instance, expirationLedger: 100
        )
        result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: result, signerKey: try s2.toScVal(), signatureValue: .bytes(Data([0x42]))
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.signers.count, 2)
    }

    func testSignAuthEntry_policySignatureWithOZDelegatedSignerHasCorrectStructure() async throws {
        let entry = try makeEntry()
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry, signer: s1, signature: OZPolicySignature.instance, expirationLedger: 100
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.signers.count, 1)
    }

    func testSignAuthEntry_webAuthnSignatureTypeIsStoredCorrectly() async throws {
        let entry = try makeEntry()
        var pubkey = Data(repeating: 0x42, count: 65)
        pubkey[0] = 0x04
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC, publicKey: pubkey, credentialId: Data([0xAA])
        )
        let signature = try OZWebAuthnSignature(
            authenticatorData: Data([0x01]),
            clientData: Data([0x02]),
            signature: Data(repeating: 0x10, count: 64)
        )
        let result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry, signer: signer, signature: signature, expirationLedger: 100
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.signers.count, 1)
    }

    // MARK: - buildAuthDigest

    func testBuildAuthDigest_changesWithDifferentRuleIds() async throws {
        let payload = Data(repeating: 0xAA, count: 32)
        let d1 = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: payload, contextRuleIds: [1]
        )
        let d2 = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: payload, contextRuleIds: [2]
        )
        XCTAssertNotEqual(d1, d2)
    }

    func testBuildAuthDigest_isConsistent() async throws {
        let payload = Data(repeating: 0xAA, count: 32)
        let d1 = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: payload, contextRuleIds: [1, 2, 3]
        )
        let d2 = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: payload, contextRuleIds: [1, 2, 3]
        )
        XCTAssertEqual(d1, d2)
    }

    func testBuildAuthDigest_emptyRuleIdsProducesDifferentDigestThanNonEmpty() async throws {
        let payload = Data(repeating: 0xAA, count: 32)
        let d1 = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: payload, contextRuleIds: []
        )
        let d2 = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: payload, contextRuleIds: [1]
        )
        XCTAssertNotEqual(d1, d2)
    }

    // MARK: - Golden vectors (auth-digest)
    //
    // These tests pin the byte-level output of the OZ auth-digest formula so a
    // wire-format regression surfaces immediately. The expected hex strings are
    // fixed constants and must be updated whenever the formula changes.

    func test_goldenVector1_emptyRulesMinimalPayload_authDigest_matchesFixture() async throws {
        let signaturePayload = Data("test1".utf8).sha256Hash
        let digest = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: signaturePayload,
            contextRuleIds: []
        )
        let actualHex = digest.base16EncodedString().lowercased()
        let expectedHex = "78946b8d3c459fd2e9d6d786a49c0c37d3d37d2baff912ed4be618dd6a8712bd"
        XCTAssertEqual(actualHex, expectedHex,
                       "Golden vector 1 mismatch — actual: \(actualHex)")
    }

    func test_goldenVector2_singleContextRule_authDigest_matchesFixture() async throws {
        let signaturePayload = Data("test2".utf8).sha256Hash
        let digest = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: signaturePayload,
            contextRuleIds: [42]
        )
        let actualHex = digest.base16EncodedString().lowercased()
        let expectedHex = "7f8310bb95276dd3c34ed9f3cd0a1bca75fea31643758738ba91a3894922a627"
        XCTAssertEqual(actualHex, expectedHex,
                       "Golden vector 2 mismatch — actual: \(actualHex)")
    }

    func test_goldenVector3_unsortedContextRules_authDigest_matchesFixture() async throws {
        // contextRuleIds must be bound in INSERTION order, not sorted. The
        // Vec encoding [3, 1, 2] must NOT silently become [1, 2, 3] — a sort
        // would weaken the digest's binding semantics.
        let signaturePayload = Data("test3".utf8).sha256Hash
        let digest = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: signaturePayload,
            contextRuleIds: [3, 1, 2]
        )
        let actualHex = digest.base16EncodedString().lowercased()
        let expectedHex = "574421ac5094e4b6de31938a52a3c641f61b8504c92c3ee40fc94810f8f9d752"
        XCTAssertEqual(actualHex, expectedHex,
                       "Golden vector 3 mismatch — actual: \(actualHex)")

        // Cross-check: the same payload with [1, 2, 3] must produce a
        // different digest, proving the codec preserves insertion order.
        let sortedDigest = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: signaturePayload,
            contextRuleIds: [1, 2, 3]
        )
        XCTAssertNotEqual(digest, sortedDigest,
                          "Insertion-ordered and sorted contextRuleIds must produce different digests")
    }

    func test_goldenVector4_longSignaturePayload_authDigest_matchesFixture() async throws {
        // 256-byte deterministic signaturePayload built from 8 sha256 chunks
        // exercising the multi-block hashing path.
        var signaturePayload = Data(capacity: 256)
        for tag in ["test4-a", "test4-b", "test4-c", "test4-d",
                    "test4-e", "test4-f", "test4-g", "test4-h"] {
            signaturePayload.append(Data(tag.utf8).sha256Hash)
        }
        XCTAssertEqual(signaturePayload.count, 256)

        let digest = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: signaturePayload,
            contextRuleIds: [100, 200]
        )
        let actualHex = digest.base16EncodedString().lowercased()
        let expectedHex = "3f1b91ae753b805962516838fab26cc1933e01c8750290a852256ab0cba338d9"
        XCTAssertEqual(actualHex, expectedHex,
                       "Golden vector 4 mismatch — actual: \(actualHex)")
    }

    func testSignAuthEntry_contextRuleIdsArePreservedInPayload() async throws {
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: 100,
            contextRuleIds: [7, 8]
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.contextRuleIds, [7, 8])
    }

    func testSignAuthEntry_emptyContextRuleIdsProducesEmptyVec() async throws {
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: 100
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.contextRuleIds, [])
    }

    func testSignAuthEntry_secondSignerPreservesContextRuleIds() async throws {
        let entry = try makeEntry()
        let s1 = try OZDelegatedSigner(address: validAccountG)
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        var result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: s1,
            signature: OZPolicySignature.instance,
            expirationLedger: 100,
            contextRuleIds: [11, 12]
        )
        result = try await OZSmartAccountAuth.signAuthEntry(
            entry: result,
            signer: s2,
            signature: OZPolicySignature.instance,
            expirationLedger: 100
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.contextRuleIds, [11, 12])
    }

    // MARK: - Codec round-trip alias (subset of AuthPayloadTests)

    func testCodecRead_voidReturnsEmptyPayload() throws {
        let payload = try OZSmartAccountAuthPayloadCodec.read(.void)
        XCTAssertTrue(payload.signers.isEmpty)
    }

    func testCodecRead_nonMapThrows() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.read(.bool(true))) { error in
            XCTAssertTrue(error is SmartAccountTransactionException.SigningFailed)
        }
    }

    func testCodecWriteRead_roundTrip() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0xAA]))],
            contextRuleIds: [1]
        )
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertEqual(decoded.signers.count, 1)
        XCTAssertEqual(decoded.contextRuleIds, [1])
    }

    func testCodecWriteRead_emptyPayloadRoundTrip() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        let decoded = try OZSmartAccountAuthPayloadCodec.read(scVal)
        XCTAssertTrue(decoded.signers.isEmpty)
    }

    func testCodecWrite_producesMapWithTwoEntries() throws {
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        let scVal = try OZSmartAccountAuthPayloadCodec.write(payload)
        guard case .map(let entries) = scVal, let entries = entries else {
            XCTFail("Expected map")
            return
        }
        XCTAssertEqual(entries.count, 2)
    }

    func testCodecUpsertSigner_replacesExisting() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(
            signers: [.init(signer: signer, signatureBytes: Data([0x01]))],
            contextRuleIds: []
        )
        let same = try OZDelegatedSigner(address: validAccountG)
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: same, signatureBytes: Data([0x99]))
        XCTAssertEqual(payload.signers.count, 1)
    }

    func testCodecUpsertSigner_addsNewSigner() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let payload = OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        OZSmartAccountAuthPayloadCodec.upsertSigner(payload: payload, signer: signer, signatureBytes: Data([0x01]))
        XCTAssertEqual(payload.signers.count, 1)
    }

    func testCodecSignerFromScVal_parsesDelegated() throws {
        let signer = try OZSmartAccountAuthPayloadCodec.signerFromScVal(
            .vec([.symbol("Delegated"), .address(try SCAddressXDR(accountId: validAccountG))])
        )
        XCTAssertTrue(signer is OZDelegatedSigner)
    }

    func testCodecSignerFromScVal_parsesExternal() throws {
        let signer = try OZSmartAccountAuthPayloadCodec.signerFromScVal(
            .vec([
                .symbol("External"),
                .address(try SCAddressXDR(contractId: validContractC)),
                .bytes(Data([0xAA]))
            ])
        )
        XCTAssertTrue(signer is OZExternalSigner)
    }

    func testCodecSignerFromScVal_throwsOnNonVec() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.signerFromScVal(.symbol("foo")))
    }

    func testCodecSignerFromScVal_throwsOnUnknownTag() {
        XCTAssertThrowsError(
            try OZSmartAccountAuthPayloadCodec.signerFromScVal(.vec([.symbol("Unknown")]))
        )
    }

    func testCodecSignerFromScVal_throwsOnEmptyVec() {
        XCTAssertThrowsError(try OZSmartAccountAuthPayloadCodec.signerFromScVal(.vec([])))
    }

    func testCodecWrite_signersSortedDeterministically() throws {
        let s1 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xFF]))
        let s2 = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        let payloadA = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s1, signatureBytes: Data([0xA])),
                .init(signer: s2, signatureBytes: Data([0xB]))
            ],
            contextRuleIds: []
        )
        let payloadB = OZSmartAccountAuthPayload(
            signers: [
                .init(signer: s2, signatureBytes: Data([0xB])),
                .init(signer: s1, signatureBytes: Data([0xA]))
            ],
            contextRuleIds: []
        )
        let encA = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadA)))
        let encB = try Data(XDREncoder.encode(OZSmartAccountAuthPayloadCodec.write(payloadB)))
        XCTAssertEqual(encA, encB)
    }

    func testSignAuthEntry_setsExpirationWithContextRuleIds() async throws {
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: signer,
            signature: OZPolicySignature.instance,
            expirationLedger: 12345,
            contextRuleIds: [1]
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        XCTAssertEqual(credentials.signatureExpirationLedger, 12345)
    }

    func testAddRawSignatureMapEntry_contextRuleIdsAreSet() throws {
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: try signer.toScVal(),
            signatureValue: .bytes(Data()),
            contextRuleIds: [42]
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        XCTAssertEqual(payload.contextRuleIds, [42])
    }

    // MARK: - signAuthEntry error branches

    func testSignAuthEntry_throwsWhenSignerToScValFails() async throws {
        // A signer whose toScVal() throws drives the "Failed to convert signer to SCVal"
        // branch; signAuthEntry must wrap it in a SigningFailed.
        let entry = try makeEntry()
        let signer = ThrowingSignerStub()
        do {
            _ = try await OZSmartAccountAuth.signAuthEntry(
                entry: entry,
                signer: signer,
                signature: OZPolicySignature.instance,
                expirationLedger: 100
            )
            XCTFail("Expected throw")
        } catch is SmartAccountTransactionException.SigningFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSignAuthEntry_throwsWhenSignatureToAuthPayloadBytesFails() async throws {
        // A valid signer with a signature whose toAuthPayloadBytes() throws drives the
        // "Failed to encode signature bytes for auth payload" branch.
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let signature = ThrowingSignatureStub()
        do {
            _ = try await OZSmartAccountAuth.signAuthEntry(
                entry: entry,
                signer: signer,
                signature: signature,
                expirationLedger: 100
            )
            XCTFail("Expected throw")
        } catch is SmartAccountTransactionException.SigningFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - addRawSignatureMapEntry non-bytes value

    func testAddRawSignatureMapEntry_nonBytesValueIsXdrEncoded() throws {
        // A non-.bytes signatureValue exercises the XDR-encode branch; the encoded bytes
        // of the SCVal are stored as the signer's signature bytes.
        let entry = try makeEntry()
        let signer = try OZDelegatedSigner(address: validAccountG)
        let value = SCValXDR.u32(5)
        let result = try OZSmartAccountAuth.addRawSignatureMapEntry(
            entry: entry,
            signerKey: try signer.toScVal(),
            signatureValue: value
        )
        guard case .address(let credentials) = result.credentials else {
            XCTFail("Expected address credentials")
            return
        }
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        let expected = Data(try XDREncoder.encode(value))
        XCTAssertEqual(payload.signers.count, 1)
        XCTAssertEqual(payload.signers[0].signatureBytes, expected)
    }

    // MARK: - Helpers

    private func makeEntry(nonce: Int64 = 100, expirationLedger: UInt32 = 0) throws -> SorobanAuthorizationEntryXDR {
        let invocation = try makeInvocation()
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractC),
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            signature: .void
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )
    }

    private func makeInvocation() throws -> SorobanAuthorizedInvocationXDR {
        let function = SorobanAuthorizedFunctionXDR.contractFn(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: validContractC),
                functionName: "noop",
                args: []
            )
        )
        return SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
    }
}

// MARK: - Local test doubles

/// Signer whose `toScVal()` always throws, used to drive `signAuthEntry`'s signer-encoding
/// error branch.
private struct ThrowingSignerStub: OZSmartAccountSigner {
    var uniqueKey: String { "throwing-signer-stub" }
    func toScVal() throws -> SCValXDR {
        throw SmartAccountValidationException.invalidInput(
            field: "signer",
            reason: "intentional test failure"
        )
    }
}

/// Signature whose `toAuthPayloadBytes()` always throws, used to drive `signAuthEntry`'s
/// signature-encoding error branch. `toScVal()` is total and returns an empty map.
private struct ThrowingSignatureStub: OZSmartAccountSignature {
    func toScVal() -> SCValXDR {
        return .map([])
    }
    func toAuthPayloadBytes() throws -> Data {
        throw SmartAccountTransactionException.signingFailed(
            reason: "intentional test failure"
        )
    }
}
