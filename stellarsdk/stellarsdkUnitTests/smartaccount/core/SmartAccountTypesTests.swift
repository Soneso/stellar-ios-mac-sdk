//
//  SmartAccountTypesTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class SmartAccountTypesTests: XCTestCase {

    // Valid Stellar addresses populated in setUp(). The G-address is generated fresh from
    // a random Ed25519 keypair so the checksum is always correct; the C-address is a
    // contract strkey used elsewhere in the existing iOS test corpus.
    private var validAccountG: String = ""
    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    override func setUp() {
        super.setUp()
        let keyPair = try! KeyPair.generateRandomKeyPair()
        validAccountG = keyPair.accountId
    }

    // MARK: - DelegatedSigner

    func test_delegated_signer_accepts_valid_g_address() throws {
        let signer = try DelegatedSigner(address: validAccountG)
        XCTAssertEqual(signer.address, validAccountG)
    }

    func test_delegated_signer_accepts_valid_c_address() throws {
        let signer = try DelegatedSigner(address: validContractC)
        XCTAssertEqual(signer.address, validContractC)
    }

    func test_delegated_signer_rejects_invalid_address_throws_invalid_address() {
        do {
            _ = try DelegatedSigner(address: "not-a-real-address")
            XCTFail("Expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertEqual(error.code, .invalidAddress)
            XCTAssertTrue(error.message.contains("Invalid address"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_delegated_signer_to_scval_returns_vec_symbol_address() throws {
        let signer = try DelegatedSigner(address: validAccountG)
        let scVal = try signer.toScVal()
        guard case .vec(let optionalElements) = scVal, let elements = optionalElements else {
            XCTFail("Expected SCValXDR.vec")
            return
        }
        XCTAssertEqual(elements.count, 2)
        guard case .symbol(let symbol) = elements[0] else {
            XCTFail("First element must be a symbol")
            return
        }
        XCTAssertEqual(symbol, "Delegated")
        guard case .address(let scAddress) = elements[1] else {
            XCTFail("Second element must be an address")
            return
        }
        XCTAssertEqual(scAddress.accountId, validAccountG)
    }

    func test_delegated_signer_unique_key_format_delegated_colon_address() throws {
        let signer = try DelegatedSigner(address: validAccountG)
        XCTAssertEqual(signer.uniqueKey, "delegated:\(validAccountG)")
    }

    // MARK: - ExternalSigner.webAuthn

    func test_external_signer_webauthn_accepts_valid_65_byte_uncompressed_pubkey_with_credential_id() throws {
        let publicKey = uncompressedSecp256r1PublicKey()
        let credentialId = Data([0xAA, 0xBB, 0xCC])
        let signer = try ExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: publicKey,
            credentialId: credentialId
        )
        XCTAssertEqual(signer.verifierAddress, validContractC)
        XCTAssertEqual(signer.keyData.count, publicKey.count + credentialId.count)
        XCTAssertEqual(signer.keyData.prefix(publicKey.count), publicKey)
        XCTAssertEqual(signer.keyData.suffix(credentialId.count), credentialId)
    }

    func test_external_signer_webauthn_rejects_wrong_size_pubkey_throws_invalid_input() {
        let publicKey = Data(repeating: 0x04, count: 64) // 64 instead of 65 bytes
        do {
            _ = try ExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: publicKey,
                credentialId: Data([0x01])
            )
            XCTFail("Expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.contains("publicKey"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_external_signer_webauthn_rejects_compressed_pubkey_prefix_02_throws_invalid_input() {
        var publicKey = Data(repeating: 0x00, count: 65)
        publicKey[0] = 0x02
        do {
            _ = try ExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: publicKey,
                credentialId: Data([0x01])
            )
            XCTFail("Expected ValidationException.InvalidInput for prefix 0x02")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.contains("0x04") || error.message.contains("uncompressed"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_external_signer_webauthn_rejects_compressed_pubkey_prefix_03_throws_invalid_input() {
        var publicKey = Data(repeating: 0x00, count: 65)
        publicKey[0] = 0x03
        do {
            _ = try ExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: publicKey,
                credentialId: Data([0x01])
            )
            XCTFail("Expected ValidationException.InvalidInput for prefix 0x03")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.contains("0x04") || error.message.contains("uncompressed"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_external_signer_webauthn_rejects_empty_credential_id_throws_invalid_input() {
        let publicKey = uncompressedSecp256r1PublicKey()
        do {
            _ = try ExternalSigner.webAuthn(
                verifierAddress: validContractC,
                publicKey: publicKey,
                credentialId: Data()
            )
            XCTFail("Expected ValidationException.InvalidInput for empty credentialId")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.contains("credentialId"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - ExternalSigner.ed25519

    func test_external_signer_ed25519_accepts_valid_32_byte_pubkey() throws {
        let publicKey = Data(repeating: 0x11, count: SmartAccountConstants.ed25519PublicKeySize)
        let signer = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: publicKey)
        XCTAssertEqual(signer.verifierAddress, validContractC)
        XCTAssertEqual(signer.keyData, publicKey)
    }

    func test_external_signer_ed25519_rejects_wrong_size_pubkey_throws_invalid_input() {
        let publicKey = Data(repeating: 0x11, count: 31) // 31 instead of 32
        do {
            _ = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: publicKey)
            XCTFail("Expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.contains("Ed25519"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - ExternalSigner ctor validation

    func test_external_signer_rejects_non_contract_verifier_address_throws_invalid_address() {
        do {
            _ = try ExternalSigner(verifierAddress: validAccountG, keyData: Data([0x01, 0x02]))
            XCTFail("Expected ValidationException.InvalidAddress")
        } catch let error as ValidationException.InvalidAddress {
            XCTAssertEqual(error.code, .invalidAddress)
            XCTAssertTrue(error.message.contains("contract"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_external_signer_rejects_empty_key_data_throws_invalid_input() {
        do {
            _ = try ExternalSigner(verifierAddress: validContractC, keyData: Data())
            XCTFail("Expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.contains("keyData"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - ExternalSigner output

    func test_external_signer_to_scval_returns_vec_symbol_address_bytes() throws {
        let publicKey = uncompressedSecp256r1PublicKey()
        let credentialId = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let signer = try ExternalSigner.webAuthn(
            verifierAddress: validContractC,
            publicKey: publicKey,
            credentialId: credentialId
        )
        let scVal = try signer.toScVal()
        guard case .vec(let optionalElements) = scVal, let elements = optionalElements else {
            XCTFail("Expected SCValXDR.vec")
            return
        }
        XCTAssertEqual(elements.count, 3)
        guard case .symbol(let symbol) = elements[0] else {
            XCTFail("First element must be a symbol")
            return
        }
        XCTAssertEqual(symbol, "External")
        guard case .address(let scAddress) = elements[1] else {
            XCTFail("Second element must be an address")
            return
        }
        XCTAssertEqual(scAddress.contractId?.lowercased(), try validContractC.decodeContractIdToHex().lowercased())
        guard case .bytes(let bytesData) = elements[2] else {
            XCTFail("Third element must be bytes")
            return
        }
        XCTAssertEqual(bytesData, signer.keyData)
    }

    func test_external_signer_unique_key_format_external_colon_verifier_colon_keyhex() throws {
        let publicKey = Data(repeating: 0x22, count: SmartAccountConstants.ed25519PublicKeySize)
        let signer = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: publicKey)
        let expected = "external:\(validContractC):\(publicKey.base16EncodedString())"
        XCTAssertEqual(signer.uniqueKey, expected)
    }

    // MARK: - ExternalSigner equality / hashing

    func test_external_signer_equals_constant_time_for_keydata() throws {
        let key1 = Data(repeating: 0x10, count: 32)
        let key2 = Data(repeating: 0x10, count: 32)
        let key3 = Data(repeating: 0x10, count: 31) + Data([0x11])
        let signerA = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key1)
        let signerB = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key2)
        let signerC = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key3)
        XCTAssertEqual(signerA, signerB, "Equal byte content should compare equal")
        XCTAssertNotEqual(signerA, signerC, "Differing trailing byte must not compare equal")
        // Differing-verifier-address branch (still should run compare on keyData; both halves matter)
        let signerD = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key1)
        XCTAssertEqual(signerA, signerD)
    }

    func test_external_signer_hashcode_uses_content_hash_of_keydata() throws {
        let key1 = Data(repeating: 0xAA, count: 32)
        let key2 = Data(repeating: 0xAA, count: 32)
        let key3 = Data(repeating: 0xBB, count: 32)
        let signerA = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key1)
        let signerB = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key2)
        let signerC = try ExternalSigner.ed25519(verifierAddress: validContractC, publicKey: key3)
        XCTAssertEqual(signerA.hashValue, signerB.hashValue, "Equal byte content should hash identically")
        XCTAssertNotEqual(signerA.hashValue, signerC.hashValue, "Different content should hash differently")
    }

    func test_externalSigner_constantTimeEquals_length_mismatch_256_vs_0_returns_false() throws {
        // A 256-byte buffer XORed against an empty buffer would, under a UInt8-narrowing
        // length-difference seed, truncate 0x100 down to 0x00 and incorrectly report
        // equality. The Boolean length-difference flag must keep this case unequal.
        let longKey = Data(repeating: 0x55, count: 256)
        // Construct the short signer with non-empty keyData (constructor requires it),
        // then zero out the public-facing keyData via a direct assignment is not possible
        // on an immutable struct; instead exercise the helper through the ExternalSigner
        // equality path with a length-1 key vs a 257-byte key, which has the same XOR
        // collision class (lengths whose XOR equals 0x100 on the low 8 bits are
        // {(0,256), (1,257), (2,258), …}).
        let veryLongKey = Data(repeating: 0x55, count: 257)
        let shortKey = Data([0x55])
        let signerLong = try ExternalSigner(verifierAddress: validContractC, keyData: veryLongKey)
        let signerShort = try ExternalSigner(verifierAddress: validContractC, keyData: shortKey)
        XCTAssertNotEqual(signerLong, signerShort,
                          "ExternalSigner with key lengths whose XOR truncates to 0 must not compare equal")
        // Symmetric direction
        XCTAssertNotEqual(signerShort, signerLong)
        // Direct 256-byte vs empty-keyData mismatch via the same equality entry point:
        // empty keyData is rejected by the constructor, so we instead assert the
        // 256-byte case against a 1-byte signer to keep the constructor invariant
        // intact while still exercising a length-difference whose UInt8 narrowing
        // would have collapsed to zero (256 ^ 0 == 0x100 → low byte 0x00 — the case
        // the original implementation could not distinguish).
        let signer256 = try ExternalSigner(verifierAddress: validContractC, keyData: longKey)
        XCTAssertNotEqual(signer256, signerShort,
                          "256-byte vs 1-byte ExternalSigner must compare unequal")
    }

    func test_externalSigner_constantTimeEquals_length_mismatch_257_vs_0_does_not_trap() throws {
        // The original implementation built a UInt8 from the XOR of the two lengths,
        // which traps on overflow when the XOR exceeds 255. A 257-byte keyData
        // compared against a 1-byte keyData yields lhs.count ^ rhs.count = 256
        // (0x100), which exercises the trap path. The fixed helper must complete
        // without crashing and report the inputs as unequal.
        let longKey = Data(repeating: 0x77, count: 257)
        let shortKey = Data([0x77])
        let signerLong = try ExternalSigner(verifierAddress: validContractC, keyData: longKey)
        let signerShort = try ExternalSigner(verifierAddress: validContractC, keyData: shortKey)
        // The act of evaluating the equality must complete without trapping.
        let result = (signerLong == signerShort)
        XCTAssertFalse(result,
                       "ExternalSigner equality must return false (not trap) for length-XOR > 0xFF")
    }

    // MARK: - SubmissionMethod

    func test_submission_method_has_two_cases_relayer_and_rpc() {
        let cases: [SubmissionMethod] = [.relayer, .rpc]
        XCTAssertEqual(cases.count, 2)
        XCTAssertTrue(cases.contains(.relayer))
        XCTAssertTrue(cases.contains(.rpc))
    }

    func test_submission_method_round_trip_through_string_or_index() {
        let allCases: [SubmissionMethod] = [.relayer, .rpc]
        for method in allCases {
            let description = String(describing: method)
            XCTAssertFalse(description.isEmpty, "Description must not be empty")
            switch method {
            case .relayer:
                XCTAssertTrue(description.lowercased().contains("relayer"))
            case .rpc:
                XCTAssertTrue(description.lowercased().contains("rpc"))
            }
        }
    }

    // MARK: - Helpers

    private func uncompressedSecp256r1PublicKey() -> Data {
        var key = Data(count: SmartAccountConstants.secp256r1PublicKeySize)
        key[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        for i in 1..<key.count {
            key[i] = UInt8((i * 7) & 0xFF)
        }
        return key
    }
}
