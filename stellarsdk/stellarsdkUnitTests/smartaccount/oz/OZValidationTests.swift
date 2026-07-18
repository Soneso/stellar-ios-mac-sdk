//
//  OZValidationTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZValidationTests: XCTestCase {

    // MARK: - Test fixtures

    private let validContractC = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validMuxedM = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

    // MARK: - requireContractAddress

    func test_requireContractAddress_validC_address_returnsNoThrow() {
        XCTAssertNoThrow(try requireContractAddress(validContractC, fieldName: "policyAddress"))
    }

    func test_requireContractAddress_invalidAddress_throwsInvalidAddress7001() {
        do {
            try requireContractAddress("not-a-valid-address", fieldName: "policyAddress")
            XCTFail("expected SmartAccountValidationException.InvalidAddress to be thrown")
        } catch let error as SmartAccountValidationException.InvalidAddress {
            XCTAssertEqual(error.code, .invalidAddress)
            XCTAssertEqual(error.code.rawValue, 7001)
            XCTAssertEqual(
                error.message,
                "policyAddress must be a valid contract address (C...), got: not-a-valid-address"
            )
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    // MARK: - requireStellarAddress

    func test_requireStellarAddress_validG_address_returnsNoThrow() throws {
        let validG = try KeyPair.generateRandomKeyPair().accountId
        XCTAssertNoThrow(try requireStellarAddress(validG, fieldName: "recipient"))
    }

    func test_requireStellarAddress_validC_address_returnsNoThrow() {
        XCTAssertNoThrow(try requireStellarAddress(validContractC, fieldName: "recipient"))
    }

    func test_requireStellarAddress_muxedM_address_throwsInvalidAddress7001() {
        do {
            try requireStellarAddress(validMuxedM, fieldName: "recipient")
            XCTFail("expected SmartAccountValidationException.InvalidAddress to be thrown for M-address")
        } catch let error as SmartAccountValidationException.InvalidAddress {
            XCTAssertEqual(error.code, .invalidAddress)
            XCTAssertEqual(error.code.rawValue, 7001)
            XCTAssertEqual(
                error.message,
                "recipient must be a valid Stellar address (G... or C...), got: \(validMuxedM)"
            )
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    // MARK: - isLocalhostUrl

    func test_isLocalhostUrl_localhost_root_localhost_port_localhost_path_accepted_localhostEvilCom_rejected_https_rejected() {
        XCTAssertTrue(isLocalhostUrl("http://localhost"))
        XCTAssertTrue(isLocalhostUrl("http://localhost:8080"))
        XCTAssertTrue(isLocalhostUrl("http://localhost/api"))
        XCTAssertFalse(isLocalhostUrl("http://localhost.evil.com"))
        XCTAssertFalse(isLocalhostUrl("https://localhost"))
        XCTAssertFalse(isLocalhostUrl("http://example.com"))
    }

    func test_isLocalhostUrl_userinfoBypass_rejected() {
        // RFC 3986 parses "localhost:8080" / "localhost" / "localhost:1" before the
        // "@" as userinfo and the segment after as the host; any URL whose effective
        // host is attacker-controlled must be rejected even though it carries the
        // literal "localhost" token.
        XCTAssertFalse(isLocalhostUrl("http://localhost:8080@evil.com"))
        XCTAssertFalse(isLocalhostUrl("http://localhost:8080@evil.com/"))
        XCTAssertFalse(isLocalhostUrl("http://localhost@evil.com"))
        XCTAssertFalse(isLocalhostUrl("http://localhost:1@evil.com/"))
    }

    func test_isLocalhostUrl_loopbackHosts_accepted() {
        XCTAssertTrue(isLocalhostUrl("http://127.0.0.1"))
        XCTAssertTrue(isLocalhostUrl("http://127.0.0.1:8080"))
        XCTAssertTrue(isLocalhostUrl("http://[::1]"))
        XCTAssertTrue(isLocalhostUrl("http://[::1]:8080"))
    }

    // MARK: - ozResponseIsJson

    func test_ozResponseIsJson_rejects_lookalikeJsonSuffixes() {
        // why: a prefix-only check admits unrelated media types such as
        // `application/jsonx` or `application/json5`. The media-type match
        // must use strict equality after stripping `;`-delimited
        // parameters.
        XCTAssertFalse(ozResponseIsJson("application/jsonx"))
        XCTAssertFalse(ozResponseIsJson("application/json5"))
        XCTAssertFalse(ozResponseIsJson("application/json-patch+json"))
    }

    func test_ozResponseIsJson_acceptsParameterizedJsonContentType() {
        // why: real servers commonly suffix the JSON media type with a
        // `;` charset parameter; the equality check must occur on the
        // canonical media type rather than the raw header string.
        XCTAssertTrue(ozResponseIsJson("application/json; charset=utf-8"))
        XCTAssertTrue(ozResponseIsJson("application/json;charset=utf-8"))
        XCTAssertTrue(ozResponseIsJson("  Application/JSON  ; charset=utf-8"))
        XCTAssertTrue(ozResponseIsJson("application/problem+json; charset=utf-8"))
    }

    func test_ozResponseIsJson_nilHeader_treatedAsJson() {
        // why: well-behaved endpoints sometimes omit `Content-Type` on
        // short success responses. The helper must remain permissive in
        // that case so a missing header does not surface as a transport
        // failure.
        XCTAssertTrue(ozResponseIsJson(nil))
    }

    // MARK: - isLocalhostUrl — missing branches

    /// A `http://` URL with user info must be rejected (line 77 coverage).
    func test_isLocalhostUrl_withUserInfo_returnsFalse() throws {
        // A URL with user credentials must be rejected even if the host is
        // localhost, to prevent host-confusion attacks.
        XCTAssertThrowsError(
            try OZIndexerClient(indexerUrl: "http://user:pass@localhost:8080")
        ) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    // MARK: - requireValidContextRuleName

    func test_requireValidContextRuleName_empty_throws() {
        do {
            try requireValidContextRuleName("")
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.message, "Invalid input for name: Context rule name cannot be empty")
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    func test_requireValidContextRuleName_at20Bytes_noThrow() {
        // 20 ASCII characters == 20 UTF-8 bytes: at the limit, accepted.
        XCTAssertNoThrow(try requireValidContextRuleName(String(repeating: "a", count: 20)))
    }

    func test_requireValidContextRuleName_21Bytes_throws() {
        do {
            try requireValidContextRuleName(String(repeating: "a", count: 21))
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Context rule name cannot exceed 20 bytes, got: 21"),
                "unexpected message: \(error.message)"
            )
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    func test_requireValidContextRuleName_multiByteUtf8_measuredInBytesNotCharacters() {
        // "ä" is 2 UTF-8 bytes. 10 characters == 20 bytes: at the limit, accepted.
        XCTAssertNoThrow(try requireValidContextRuleName(String(repeating: "ä", count: 10)))
        // 11 characters == 22 bytes: over the byte limit even though the character
        // count is below 20.
        do {
            try requireValidContextRuleName(String(repeating: "ä", count: 11))
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("got: 22"),
                "expected byte count 22 in message, got: \(error.message)"
            )
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    // MARK: - requireValidSigners

    func test_requireValidSigners_externalAt256Bytes_noThrow() throws {
        let signer = try OZExternalSigner(
            verifierAddress: validContractC,
            keyData: Data(repeating: 0x01, count: OZConstants.maxExternalKeySize)
        )
        XCTAssertNoThrow(try requireValidSigners([signer]))
    }

    func test_requireValidSigners_external257Bytes_throws() throws {
        let signer = try OZExternalSigner(
            verifierAddress: validContractC,
            keyData: Data(repeating: 0x01, count: OZConstants.maxExternalKeySize + 1)
        )
        do {
            try requireValidSigners([signer])
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("External signer key data cannot exceed 256 bytes, got: 257"),
                "unexpected message: \(error.message)"
            )
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    func test_requireValidSigners_delegatedHasNoKeyData_skipped() throws {
        // Delegated signers carry no key data and must never trip the external-key check.
        let validG = try KeyPair.generateRandomKeyPair().accountId
        let delegated = try OZDelegatedSigner(address: validG)
        XCTAssertNoThrow(try requireValidSigners([delegated]))
    }

    func test_requireValidSigners_mixedSigners_oversizedExternal_throws() throws {
        let validG = try KeyPair.generateRandomKeyPair().accountId
        let delegated = try OZDelegatedSigner(address: validG)
        let oversized = try OZExternalSigner(
            verifierAddress: validContractC,
            keyData: Data(repeating: 0x02, count: OZConstants.maxExternalKeySize + 1)
        )
        XCTAssertThrowsError(try requireValidSigners([delegated, oversized])) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }
}
