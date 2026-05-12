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
            XCTFail("expected ValidationException.InvalidAddress to be thrown")
        } catch let error as ValidationException.InvalidAddress {
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
            XCTFail("expected ValidationException.InvalidAddress to be thrown for M-address")
        } catch let error as ValidationException.InvalidAddress {
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
}
