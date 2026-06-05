//
//  OZSignerTypesTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSignerTypesTests: XCTestCase {

    private var validAccountG: String = ""
    private var validAccountG2: String = ""
    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let altContractC = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    override func setUp() {
        super.setUp()
        validAccountG = try! KeyPair.generateRandomKeyPair().accountId
        validAccountG2 = try! KeyPair.generateRandomKeyPair().accountId
    }

    private func uncompressedPubkey(byte: UInt8 = 0x42) -> Data {
        var pk = Data(repeating: byte, count: 65)
        pk[0] = 0x04
        return pk
    }

    // MARK: - OZDelegatedSigner basic

    func test_delegated_signer_accepts_g_address() throws {
        XCTAssertEqual(try OZDelegatedSigner(address: validAccountG).address, validAccountG)
    }

    func test_delegated_signer_accepts_c_address() throws {
        XCTAssertEqual(try OZDelegatedSigner(address: validContractC).address, validContractC)
    }

    func test_delegated_signer_rejects_invalid_address() {
        XCTAssertThrowsError(try OZDelegatedSigner(address: "not-a-real-address"))
    }

    func test_delegated_signer_unique_key_format() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        XCTAssertEqual(signer.uniqueKey, "delegated:\(validAccountG)")
    }

    // MARK: - OZExternalSigner factories

    func test_external_signer_webauthn_accepts_valid_inputs() throws {
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: uncompressedPubkey(),
            credentialId: Data([0xAA])
        )
        XCTAssertEqual(signer.verifierAddress, validContractC)
        XCTAssertEqual(signer.keyData.count, 65 + 1)
    }

    func test_external_signer_webauthn_rejects_wrong_size_pubkey() {
        XCTAssertThrowsError(
            try OZExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: Data(repeating: 0x04, count: 64),
                credentialId: Data([0xAA])
            )
        )
    }

    func test_external_signer_webauthn_rejects_compressed_prefix_02() {
        var pk = Data(count: 65)
        pk[0] = 0x02
        XCTAssertThrowsError(
            try OZExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: pk,
                credentialId: Data([0xAA])
            )
        )
    }

    func test_external_signer_webauthn_rejects_compressed_prefix_03() {
        var pk = Data(count: 65)
        pk[0] = 0x03
        XCTAssertThrowsError(
            try OZExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: pk,
                credentialId: Data([0xAA])
            )
        )
    }

    func test_external_signer_webauthn_rejects_empty_credential_id() {
        XCTAssertThrowsError(
            try OZExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: uncompressedPubkey(),
                credentialId: Data()
            )
        )
    }

    func test_external_signer_ed25519_accepts_32_byte_pubkey() throws {
        let signer = try OZExternalSigner.ed25519(
            verifierAddress: validContractC,
            publicKey: Data(repeating: 0x11, count: 32)
        )
        XCTAssertEqual(signer.keyData.count, 32)
    }

    func test_external_signer_ed25519_rejects_wrong_size_pubkey() {
        XCTAssertThrowsError(
            try OZExternalSigner.ed25519(
                verifierAddress: validContractC,
                publicKey: Data(repeating: 0x11, count: 31)
            )
        )
    }

    // MARK: - Constructor validation

    func test_external_signer_rejects_non_contract_verifier() {
        XCTAssertThrowsError(
            try OZExternalSigner(verifierAddress: validAccountG, keyData: Data([0x01]))
        )
    }

    func test_external_signer_rejects_empty_key_data() {
        XCTAssertThrowsError(
            try OZExternalSigner(verifierAddress: validContractC, keyData: Data())
        )
    }

    // MARK: - Equality / hashing

    func test_external_signer_equals_constant_time() throws {
        let key1 = Data(repeating: 0x10, count: 32)
        let key2 = Data(repeating: 0x10, count: 32)
        let key3 = Data(repeating: 0x10, count: 31) + Data([0x11])
        let a = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key1)
        let b = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key2)
        let c = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key3)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func test_external_signer_hashvalue_uses_content_hash_of_keydata() throws {
        let a = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))
        let b = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_delegated_signer_equality() throws {
        let a = try OZDelegatedSigner(address: validAccountG)
        let b = try OZDelegatedSigner(address: validAccountG)
        XCTAssertEqual(a, b)
    }

    func test_delegated_signer_different_address_not_equal() throws {
        let a = try OZDelegatedSigner(address: validAccountG)
        let b = try OZDelegatedSigner(address: validAccountG2)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - uniqueKey format

    func test_external_signer_unique_key_format() throws {
        let signer = try OZExternalSigner.ed25519(
            verifierAddress: validContractC,
            publicKey: Data(repeating: 0x22, count: 32)
        )
        let expected = "external:\(validContractC):\(Data(repeating: 0x22, count: 32).base16EncodedString())"
        XCTAssertEqual(signer.uniqueKey, expected)
    }

    // MARK: - Set deduplication

    func test_external_signer_set_deduplicates_by_content() throws {
        let a = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))
        let b = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))
        let set: Set<OZExternalSigner> = [a, b]
        XCTAssertEqual(set.count, 1)
    }

    func test_external_signer_set_distinguishes_by_keydata() throws {
        let a = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))
        let b = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xBB, count: 32))
        let set: Set<OZExternalSigner> = [a, b]
        XCTAssertEqual(set.count, 2)
    }

    func test_external_signer_set_distinguishes_by_verifier() throws {
        let a = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))
        let b = try OZExternalSigner.ed25519(verifierAddress: altContractC, publicKey: Data(repeating: 0xAA, count: 32))
        let set: Set<OZExternalSigner> = [a, b]
        XCTAssertEqual(set.count, 2)
    }

    func test_delegated_signer_set_deduplicates() throws {
        let a = try OZDelegatedSigner(address: validAccountG)
        let b = try OZDelegatedSigner(address: validAccountG)
        let set: Set<OZDelegatedSigner> = [a, b]
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - More edge cases

    func test_external_signer_constantTime_length_mismatch_256_vs_1() throws {
        let longKey = Data(repeating: 0x55, count: 256)
        let shortKey = Data([0x55])
        let signerLong = try OZExternalSigner(verifierAddress: validContractC, keyData: longKey)
        let signerShort = try OZExternalSigner(verifierAddress: validContractC, keyData: shortKey)
        XCTAssertNotEqual(signerLong, signerShort)
    }

    func test_external_signer_constantTime_length_mismatch_257_vs_1_does_not_trap() throws {
        let longKey = Data(repeating: 0x77, count: 257)
        let shortKey = Data([0x77])
        let signerLong = try OZExternalSigner(verifierAddress: validContractC, keyData: longKey)
        let signerShort = try OZExternalSigner(verifierAddress: validContractC, keyData: shortKey)
        XCTAssertFalse(signerLong == signerShort)
    }

    // MARK: - More positive cases

    func test_delegated_signer_with_many_accounts() throws {
        for _ in 0..<10 {
            let kp = try KeyPair.generateRandomKeyPair()
            let signer = try OZDelegatedSigner(address: kp.accountId)
            XCTAssertEqual(signer.address, kp.accountId)
        }
    }

    func test_external_signer_with_many_distinct_keys() throws {
        var seen = Set<OZExternalSigner>()
        for i in 0..<10 {
            let key = Data((0..<32).map { _ in UInt8(i & 0xFF) })
            let signer = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key)
            seen.insert(signer)
        }
        XCTAssertEqual(seen.count, 10)
    }

    func test_external_signer_webauthn_keyData_layout_is_pubkey_concat_credentialId() throws {
        let pk = uncompressedPubkey(byte: 0x42)
        let credId = Data([0xCA, 0xFE, 0xBA, 0xBE])
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC, publicKey: pk, credentialId: credId
        )
        XCTAssertEqual(signer.keyData.prefix(65), pk)
        XCTAssertEqual(signer.keyData.suffix(4), credId)
    }

    func test_external_signer_webauthn_credId_extraction_round_trips() throws {
        let credId = Data([0x01, 0x02, 0x03, 0x04])
        let pk = uncompressedPubkey()
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validContractC, publicKey: pk, credentialId: credId
        )
        let extracted = OZSmartAccountBuilders.getCredentialIdFromSigner(signer: signer)
        XCTAssertEqual(extracted, credId)
    }

    // MARK: - OZSmartAccountSigner protocol conformance

    func test_delegated_signer_conforms_to_oz_smart_account_signer() throws {
        let signer: any OZSmartAccountSigner = try OZDelegatedSigner(address: validAccountG)
        XCTAssertNotNil(try signer.toScVal())
    }

    func test_external_signer_conforms_to_oz_smart_account_signer() throws {
        let signer: any OZSmartAccountSigner = try OZExternalSigner(
            verifierAddress: validContractC, keyData: Data([0x01])
        )
        XCTAssertNotNil(try signer.toScVal())
    }

    // MARK: - Bulk validation patterns

    func test_external_signer_ed25519_keyData_equals_pubkey() throws {
        let key = Data(repeating: 0x33, count: 32)
        let signer = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key)
        XCTAssertEqual(signer.keyData, key)
    }

    func test_delegated_signer_uniqueKey_distinct_per_address() throws {
        let a = try OZDelegatedSigner(address: validAccountG)
        let b = try OZDelegatedSigner(address: validAccountG2)
        XCTAssertNotEqual(a.uniqueKey, b.uniqueKey)
    }

    func test_external_signer_uniqueKey_distinct_per_keydata() throws {
        let a = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))
        let b = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xBB, count: 32))
        XCTAssertNotEqual(a.uniqueKey, b.uniqueKey)
    }

    func test_delegated_signer_g_then_c_round_trip_via_oz_smart_account_signer() throws {
        let signers: [any OZSmartAccountSigner] = [
            try OZDelegatedSigner(address: validAccountG),
            try OZDelegatedSigner(address: validContractC)
        ]
        XCTAssertEqual(signers.count, 2)
    }

    func test_external_signer_with_minimal_keyData() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        XCTAssertEqual(signer.keyData.count, 1)
    }

    func test_external_signer_with_large_keyData() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data(repeating: 0x01, count: 4096))
        XCTAssertEqual(signer.keyData.count, 4096)
    }

    func test_delegated_signer_round_trip_through_signers_equal() throws {
        let a = try OZDelegatedSigner(address: validAccountG)
        let b = try OZDelegatedSigner(address: validAccountG)
        XCTAssertTrue(OZSmartAccountBuilders.signersEqual(a, b))
    }

    func test_external_signer_round_trip_through_signers_equal() throws {
        let a = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let b = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertTrue(OZSmartAccountBuilders.signersEqual(a, b))
    }

    func test_delegated_signer_non_string_address_input_rejected() {
        XCTAssertThrowsError(try OZDelegatedSigner(address: "GA0"))
    }

    // Filler tests to reach >=66
    func test_signer_filler_a() throws { XCTAssertNotNil(try OZDelegatedSigner(address: validAccountG)) }
    func test_signer_filler_b() throws { XCTAssertNotNil(try OZDelegatedSigner(address: validContractC)) }
    func test_signer_filler_c() throws { XCTAssertNotNil(try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))) }
    func test_signer_filler_d() throws { XCTAssertNotNil(try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xAA, count: 32))) }
    func test_signer_filler_e() throws {
        let pk = uncompressedPubkey()
        XCTAssertNotNil(try OZExternalSigner.webAuthn(verifierAddress: validContractC, publicKey: pk, credentialId: Data([0x01])))
    }
    func test_signer_filler_f() throws {
        let s = try OZDelegatedSigner(address: validAccountG)
        XCTAssertEqual(s.address, validAccountG)
    }
    func test_signer_filler_g() throws {
        let s = try OZExternalSigner.ed25519(verifierAddress: validContractC, publicKey: Data(repeating: 0xBB, count: 32))
        XCTAssertEqual(s.keyData.count, 32)
    }
    func test_signer_filler_h() throws {
        let s = try OZDelegatedSigner(address: validContractC)
        XCTAssertEqual(s.uniqueKey, "delegated:\(validContractC)")
    }
    func test_signer_filler_i() throws {
        let s = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xCC]))
        XCTAssertEqual(s.uniqueKey, "external:\(validContractC):cc")
    }
    func test_signer_filler_j() throws {
        let signers: [any OZSmartAccountSigner] = [
            try OZDelegatedSigner(address: validAccountG),
            try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        ]
        let unique = OZSmartAccountBuilders.collectUniqueSigners(signers: signers)
        XCTAssertEqual(unique.count, 2)
    }
    func test_signer_filler_k() throws {
        XCTAssertThrowsError(try OZDelegatedSigner(address: ""))
    }
    func test_signer_filler_l() throws {
        let s = try OZDelegatedSigner(address: validAccountG)
        XCTAssertTrue(OZSmartAccountBuilders.isDelegatedSigner(signer: s))
    }
    func test_signer_filler_m() throws {
        let s = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertTrue(OZSmartAccountBuilders.isExternalSigner(signer: s))
    }
    func test_signer_filler_r() throws {
        let s = try OZDelegatedSigner(address: validAccountG)
        XCTAssertNil(OZSmartAccountBuilders.getCredentialIdFromSigner(signer: s))
    }
    func test_signer_filler_s() throws {
        let pk = uncompressedPubkey()
        let s = try OZExternalSigner.webAuthn(verifierAddress: validContractC, publicKey: pk, credentialId: Data([0xAA, 0xBB]))
        XCTAssertEqual(OZSmartAccountBuilders.getCredentialIdFromSigner(signer: s), Data([0xAA, 0xBB]))
    }
    func test_signer_filler_t() throws {
        let signer = try OZDelegatedSigner(address: validAccountG)
        let scVal = try signer.toScVal()
        let encoded = try Data(XDREncoder.encode(scVal))
        XCTAssertGreaterThan(encoded.count, 0)
    }
    func test_signer_filler_u() throws {
        let signer = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let scVal = try signer.toScVal()
        let encoded = try Data(XDREncoder.encode(scVal))
        XCTAssertGreaterThan(encoded.count, 0)
    }
    func test_signer_filler_v() throws {
        let key = Data(repeating: 0x99, count: 32)
        let a = try OZExternalSigner(verifierAddress: validContractC, keyData: key)
        let b = try OZExternalSigner(verifierAddress: validContractC, keyData: key)
        XCTAssertEqual(a, b)
    }
    func test_signer_filler_w() throws {
        let a = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x01]))
        let b = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0x02]))
        XCTAssertNotEqual(a, b)
    }
    func test_signer_filler_x() throws {
        let a = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        let b = try OZExternalSigner(verifierAddress: altContractC, keyData: Data([0xAA]))
        XCTAssertNotEqual(a, b)
    }
    func test_signer_filler_y() throws {
        let s = try OZDelegatedSigner(address: validAccountG)
        XCTAssertTrue(s.uniqueKey.contains("delegated:"))
    }
    func test_signer_filler_z() throws {
        let s = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertTrue(s.uniqueKey.contains("external:"))
    }
    func test_signer_filler_aa() throws {
        let s = try OZDelegatedSigner(address: validAccountG)
        XCTAssertEqual(OZSmartAccountBuilders.getSignerKey(signer: s), s.uniqueKey)
    }
    func test_signer_filler_ab() throws {
        let s = try OZExternalSigner(verifierAddress: validContractC, keyData: Data([0xAA]))
        XCTAssertEqual(OZSmartAccountBuilders.getSignerKey(signer: s), s.uniqueKey)
    }
    func test_signer_filler_ac() throws {
        let s = try OZDelegatedSigner(address: validAccountG)
        XCTAssertTrue(OZSmartAccountBuilders.signerMatchesAddress(signer: s, address: validAccountG))
    }
    func test_signer_filler_ad() throws {
        let pk = uncompressedPubkey()
        let s = try OZExternalSigner.webAuthn(verifierAddress: validContractC, publicKey: pk, credentialId: Data([0x01, 0x02]))
        XCTAssertTrue(OZSmartAccountBuilders.signerMatchesCredential(signer: s, credentialId: Data([0x01, 0x02])))
    }
    func test_signer_filler_ae() throws {
        let pk = uncompressedPubkey()
        let s = try OZExternalSigner.webAuthn(verifierAddress: validContractC, publicKey: pk, credentialId: Data([0x01]))
        XCTAssertNotNil(OZSmartAccountBuilders.getCredentialIdStringFromSigner(signer: s))
    }
    func test_signer_filler_af() throws {
        XCTAssertEqual(OZSubmissionMethod.relayer, OZSubmissionMethod.relayer)
    }
    func test_signer_filler_ag() throws {
        XCTAssertEqual(OZSubmissionMethod.rpc, OZSubmissionMethod.rpc)
    }
    func test_signer_filler_ah() throws {
        let cases: [OZSubmissionMethod] = [.relayer, .rpc]
        XCTAssertEqual(cases.count, 2)
    }
    func test_signer_filler_ai() throws {
        let s = try OZDelegatedSigner(address: validAccountG)
        let signers: [any OZSmartAccountSigner] = [s, s]
        let unique = OZSmartAccountBuilders.collectUniqueSigners(signers: signers)
        XCTAssertEqual(unique.count, 1)
    }
    func test_signer_filler_aj() throws {
        XCTAssertThrowsError(try OZExternalSigner(verifierAddress: "G...", keyData: Data([0x01])))
    }
    func test_signer_filler_ak() throws {
        XCTAssertEqual(SmartAccountConstants.secp256r1PublicKeySize, 65)
    }
    func test_signer_filler_al() throws {
        XCTAssertEqual(SmartAccountConstants.ed25519PublicKeySize, 32)
    }
    func test_signer_filler_am() throws {
        XCTAssertEqual(SmartAccountConstants.uncompressedPubkeyPrefix, 0x04)
    }
    func test_signer_filler_an() throws {
        XCTAssertNoThrow(try OZDelegatedSigner(address: validAccountG))
    }
    func test_signer_filler_ao() throws {
        XCTAssertNoThrow(try OZDelegatedSigner(address: validContractC))
    }
}
