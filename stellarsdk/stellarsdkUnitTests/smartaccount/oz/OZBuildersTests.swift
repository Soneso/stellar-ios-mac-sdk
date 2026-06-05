//
//  OZBuildersTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZBuildersTests: XCTestCase {

    // MARK: - createDefaultContextType

    func testCreateDefaultContext_returnsDefault() {
        let result = OZBuilders.createDefaultContextType()
        if case .defaultRule = result {} else {
            XCTFail("expected OZContextRuleType.defaultRule, got \(result)")
        }
    }

    // MARK: - createCallContractContextType

    func testCreateCallContractContext_validAddress() throws {
        let address = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let result = try OZBuilders.createCallContractContextType(contractAddress: address)
        guard case let .callContract(contractAddress) = result else {
            return XCTFail("expected OZContextRuleType.callContract, got \(result)")
        }
        XCTAssertEqual(contractAddress, address)
    }

    func testCreateCallContractContext_invalidAddress_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCallContractContextType(contractAddress: "GABC...")
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException, "expected SmartAccountValidationException, got \(type(of: error))")
        }
    }

    func testCreateCallContractContext_emptyAddress_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCallContractContextType(contractAddress: "")
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException, "expected SmartAccountValidationException, got \(type(of: error))")
        }
    }

    // MARK: - createCreateContractContextType (hex)

    func testCreateCreateContractContext_validHex() throws {
        let hex = String(repeating: "a", count: 64)
        let result = try OZBuilders.createCreateContractContextType(wasmHashHex: hex)
        guard case let .createContract(wasmHash) = result else {
            return XCTFail("expected OZContextRuleType.createContract, got \(result)")
        }
        XCTAssertEqual(wasmHash.count, 32)
    }

    func testCreateCreateContractContext_validHexWith0xPrefix() throws {
        let hex = "0x" + String(repeating: "b", count: 64)
        let result = try OZBuilders.createCreateContractContextType(wasmHashHex: hex)
        guard case let .createContract(wasmHash) = result else {
            return XCTFail("expected OZContextRuleType.createContract, got \(result)")
        }
        XCTAssertEqual(wasmHash.count, 32)
    }

    func testCreateCreateContractContext_shortHex_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCreateContractContextType(wasmHashHex: "abc123")
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException, "expected SmartAccountValidationException, got \(type(of: error))")
        }
    }

    func testCreateCreateContractContext_longHex_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCreateContractContextType(wasmHashHex: String(repeating: "a", count: 66))
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException, "expected SmartAccountValidationException, got \(type(of: error))")
        }
    }

    // MARK: - createCreateContractContextType (bytes)

    func testCreateCreateContractContext_validBytes() throws {
        var bytes = Data(count: 32)
        for i in 0..<32 {
            bytes[i] = UInt8(i & 0xff)
        }
        let result = try OZBuilders.createCreateContractContextType(wasmHash: bytes)
        guard case let .createContract(wasmHash) = result else {
            return XCTFail("expected OZContextRuleType.createContract, got \(result)")
        }
        XCTAssertEqual(wasmHash, bytes)
    }

    func testCreateCreateContractContext_wrongSizeBytes_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCreateContractContextType(wasmHash: Data(count: 16))
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException, "expected SmartAccountValidationException, got \(type(of: error))")
        }
    }

    // MARK: - collectUniqueSignersFromRules

    func testCollectUniqueSignersFromRules_emptyRules() {
        let result = OZBuilders.collectUniqueSignersFromRules(rules: [])
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Additional above-floor case

    func test_collectUniqueSignersFromRules_overlappingSignersDeduplicatedAcrossRules() throws {
        let signer1 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)
        let signer2 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)
        let signer3 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)
        let signer4 = try OZDelegatedSigner(address: KeyPair.generateRandomKeyPair().accountId)

        let ruleA = OZParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "rule-A",
            signers: [signer1, signer2],
            signerIds: [101, 102],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleB = OZParsedContextRule(
            id: 2,
            contextType: .defaultRule,
            name: "rule-B",
            signers: [signer2, signer3],
            signerIds: [102, 103],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleC = OZParsedContextRule(
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

    // MARK: - OZContextRuleType equality (default: return false branch)

    /// Comparing a `callContract` type against a `createContract` type must
    /// return `false` (the `default:` branch in `OZContextRuleType.==`).
    func test_contextRuleTypeEquality_callContractVsCreateContract_returnsFalse() {
        let a = OZContextRuleType.callContract(contractAddress: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM")
        let b = OZContextRuleType.createContract(wasmHash: Data(repeating: 0xAB, count: 32))
        XCTAssertNotEqual(a, b)
    }

    /// Comparing `defaultRule` against `callContract` must return `false`.
    func test_contextRuleTypeEquality_defaultVsCallContract_returnsFalse() {
        let a = OZContextRuleType.defaultRule
        let b = OZContextRuleType.callContract(contractAddress: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM")
        XCTAssertNotEqual(a, b)
    }

    // MARK: - OZParsedContextRule equality

    /// Two rules that differ in name must not be equal (exercises the
    /// guard-condition early-exit path in `OZParsedContextRule.==`).
    func test_parsedContextRule_equality_differentName_notEqual() throws {
        let address = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let signer = try OZDelegatedSigner(address: address)
        let ruleA = OZParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "Alpha",
            signers: [signer],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleB = OZParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "Beta",
            signers: [signer],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        XCTAssertNotEqual(ruleA, ruleB)
    }

    /// Two identical rules must compare equal (exercises the `return true`
    /// branch at the end of `OZParsedContextRule.==`).
    func test_parsedContextRule_equality_identicalRules_equal() throws {
        let address = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
        let signer = try OZDelegatedSigner(address: address)
        let rule = OZParsedContextRule(
            id: 2,
            contextType: .defaultRule,
            name: "Same",
            signers: [signer],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleCopy = OZParsedContextRule(
            id: 2,
            contextType: .defaultRule,
            name: "Same",
            signers: [signer],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        XCTAssertEqual(rule, ruleCopy)
    }

    // MARK: - createCreateContractContextType invalid hex characters

    /// `createCreateContractContextType(wasmHashHex:)` with a 64-character string
    /// that contains non-hex characters must throw `SmartAccountValidationException.InvalidInput`.
    func test_createCreateContractContextType_invalidHexChars_throws() {
        XCTAssertThrowsError(
            try OZBuilders.createCreateContractContextType(
                wasmHashHex: String(repeating: "g", count: 64)
            )
        ) { error in
            XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        }
    }
}
