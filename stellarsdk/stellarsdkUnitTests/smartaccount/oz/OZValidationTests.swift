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
}
