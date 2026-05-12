//
//  OZBuildersTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZBuildersTests: XCTestCase {

    // MARK: - createDefaultContext

    func testCreateDefaultContext_returnsDefault() {
        let result = OZBuilders.createDefaultContext()
        if case .defaultRule = result {} else {
            XCTFail("expected ContextRuleType.defaultRule, got \(result)")
        }
    }

    // MARK: - createCallContractContext

    func testCreateCallContractContext_validAddress() throws {
        let address = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let result = try OZBuilders.createCallContractContext(contractAddress: address)
        guard case let .callContract(contractAddress) = result else {
            return XCTFail("expected ContextRuleType.callContract, got \(result)")
        }
        XCTAssertEqual(contractAddress, address)
    }

    func testCreateCallContractContext_invalidAddress_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCallContractContext(contractAddress: "GABC...")
        ) { error in
            XCTAssertTrue(error is ValidationException, "expected ValidationException, got \(type(of: error))")
        }
    }

    func testCreateCallContractContext_emptyAddress_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCallContractContext(contractAddress: "")
        ) { error in
            XCTAssertTrue(error is ValidationException, "expected ValidationException, got \(type(of: error))")
        }
    }

    // MARK: - createCreateContractContext (hex)

    func testCreateCreateContractContext_validHex() throws {
        let hex = String(repeating: "a", count: 64)
        let result = try OZBuilders.createCreateContractContext(wasmHashHex: hex)
        guard case let .createContract(wasmHash) = result else {
            return XCTFail("expected ContextRuleType.createContract, got \(result)")
        }
        XCTAssertEqual(wasmHash.count, 32)
    }

    func testCreateCreateContractContext_validHexWith0xPrefix() throws {
        let hex = "0x" + String(repeating: "b", count: 64)
        let result = try OZBuilders.createCreateContractContext(wasmHashHex: hex)
        guard case let .createContract(wasmHash) = result else {
            return XCTFail("expected ContextRuleType.createContract, got \(result)")
        }
        XCTAssertEqual(wasmHash.count, 32)
    }

    func testCreateCreateContractContext_shortHex_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCreateContractContext(wasmHashHex: "abc123")
        ) { error in
            XCTAssertTrue(error is ValidationException, "expected ValidationException, got \(type(of: error))")
        }
    }

    func testCreateCreateContractContext_longHex_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCreateContractContext(wasmHashHex: String(repeating: "a", count: 66))
        ) { error in
            XCTAssertTrue(error is ValidationException, "expected ValidationException, got \(type(of: error))")
        }
    }

    // MARK: - createCreateContractContext (bytes)

    func testCreateCreateContractContext_validBytes() throws {
        var bytes = Data(count: 32)
        for i in 0..<32 {
            bytes[i] = UInt8(i & 0xff)
        }
        let result = try OZBuilders.createCreateContractContext(wasmHash: bytes)
        guard case let .createContract(wasmHash) = result else {
            return XCTFail("expected ContextRuleType.createContract, got \(result)")
        }
        XCTAssertEqual(wasmHash, bytes)
    }

    func testCreateCreateContractContext_wrongSizeBytes_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCreateContractContext(wasmHash: Data(count: 16))
        ) { error in
            XCTAssertTrue(error is ValidationException, "expected ValidationException, got \(type(of: error))")
        }
    }

    // MARK: - collectUniqueSignersFromRules

    func testCollectUniqueSignersFromRules_emptyRules() {
        let result = OZBuilders.collectUniqueSignersFromRules(rules: [])
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Group D NEW above-floor case

    func test_collectUniqueSignersFromRules_overlappingSignersDeduplicatedAcrossRules() throws {
        let signer1 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)
        let signer2 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)
        let signer3 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)
        let signer4 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)

        let ruleA = ParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "rule-A",
            signers: [signer1, signer2],
            signerIds: [101, 102],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleB = ParsedContextRule(
            id: 2,
            contextType: .defaultRule,
            name: "rule-B",
            signers: [signer2, signer3],
            signerIds: [102, 103],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleC = ParsedContextRule(
            id: 3,
            contextType: .defaultRule,
            name: "rule-C",
            signers: [signer1, signer4],
            signerIds: [101, 104],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let result = OZBuilders.collectUniqueSignersFromRules(rules: [ruleA, ruleB, ruleC])

        XCTAssertEqual(result.count, 4, "expected 4 unique signers after deduplication across rules")
        XCTAssertEqual(result[0].uniqueKey, signer1.uniqueKey)
        XCTAssertEqual(result[1].uniqueKey, signer2.uniqueKey)
        XCTAssertEqual(result[2].uniqueKey, signer3.uniqueKey)
        XCTAssertEqual(result[3].uniqueKey, signer4.uniqueKey)
    }
}
