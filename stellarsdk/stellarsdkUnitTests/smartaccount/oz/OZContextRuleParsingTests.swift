//
//  OZContextRuleParsingTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for ``OZContextRuleManager/parseContextRule(scVal:)``,
/// ``ContextRuleType/toScVal()``, the ``ParsedContextRule`` data shape, and
/// ``OZContextRuleManager/addContextRule(contextType:name:validUntil:signers:policies:selectedSigners:forceMethod:)``
/// input validation.
///
/// These tests exercise the parser, encoder, and validation paths without
/// requiring a connected kit or live RPC traffic. Validation tests connect
/// the kit but rely on the validation pass throwing before the underlying
/// transaction-operations submission can be reached.
final class OZContextRuleParsingTests: XCTestCase {

    // MARK: - Fixtures

    private let validContractAddress =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validContractAddress2 =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let validAccountAddress =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"

    /// Generates a deterministic but unique contract address by encoding a
    /// 32-byte buffer derived from the supplied seed. Used by the
    /// "too many policies" test to produce six distinct C-addresses.
    private func generateContractAddress(seed: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        for i in 0..<32 {
            bytes[i] = UInt8((i + seed) % 256)
        }
        return try Data(bytes).encodeContractId()
    }

    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validContractAddress
        )
    }

    private func disconnectedManager() throws -> OZContextRuleManager {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return OZContextRuleManager(kit: kit)
    }

    private func connectedManager() throws -> OZContextRuleManager {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: validContractAddress
        )
        return OZContextRuleManager(kit: kit)
    }

    // MARK: - Map / Vec / Discriminant builders

    /// Builds an `SCValXDR.map` from a list of (Symbol-key, value) pairs.
    private func buildMapScVal(_ entries: [(String, SCValXDR)]) -> SCValXDR {
        let mapEntries = entries.map { key, val in
            SCMapEntryXDR(key: .symbol(key), val: val)
        }
        return .map(mapEntries)
    }

    /// Wraps a contract address into an `SCValXDR.address`.
    private func addressScVal(_ contractAddress: String) throws -> SCValXDR {
        return .address(try SCAddressXDR(contractId: contractAddress))
    }

    /// Builds a Delegated signer Vec ScVal: `Vec([Symbol("Delegated"), Address])`.
    private func delegatedSignerScVal(_ address: String) throws -> SCValXDR {
        let scAddress: SCAddressXDR
        if address.hasPrefix("G") {
            scAddress = try SCAddressXDR(accountId: address)
        } else {
            scAddress = try SCAddressXDR(contractId: address)
        }
        return .vec([
            .symbol("Delegated"),
            .address(scAddress)
        ])
    }

    /// Builds an External signer Vec ScVal: `Vec([Symbol("External"), Address, Bytes])`.
    private func externalSignerScVal(verifierAddress: String, keyData: Data) throws -> SCValXDR {
        return .vec([
            .symbol("External"),
            .address(try SCAddressXDR(contractId: verifierAddress)),
            .bytes(keyData)
        ])
    }

    /// Default context_type Vec: `Vec([Symbol("Default")])`.
    private func defaultContextTypeScVal() -> SCValXDR {
        return .vec([.symbol("Default")])
    }

    /// CallContract context_type Vec: `Vec([Symbol("CallContract"), Address])`.
    private func callContractContextTypeScVal(_ contractAddress: String) throws -> SCValXDR {
        return .vec([
            .symbol("CallContract"),
            .address(try SCAddressXDR(contractId: contractAddress))
        ])
    }

    /// CreateContract context_type Vec: `Vec([Symbol("CreateContract"), Bytes])`.
    private func createContractContextTypeScVal(wasmHash: Data) -> SCValXDR {
        return .vec([
            .symbol("CreateContract"),
            .bytes(wasmHash)
        ])
    }

    /// Builds a complete, valid context-rule map ScVal with all eight fields
    /// populated using the supplied (or sensible default) values.
    private func buildFullRuleMap(
        id: UInt32 = 1,
        name: String = "TestRule",
        contextType: SCValXDR? = nil,
        signers: [SCValXDR] = [],
        signerIds: [UInt32] = [],
        policies: [SCValXDR] = [],
        policyIds: [UInt32] = [],
        validUntil: SCValXDR = .void
    ) -> SCValXDR {
        return buildMapScVal([
            ("id", .u32(id)),
            ("name", .string(name)),
            ("context_type", contextType ?? defaultContextTypeScVal()),
            ("signers", .vec(signers)),
            ("signer_ids", .vec(signerIds.map { .u32($0) })),
            ("policies", .vec(policies)),
            ("policy_ids", .vec(policyIds.map { .u32($0) })),
            ("valid_until", validUntil)
        ])
    }

    /// Generates a 65-byte uncompressed secp256r1 public key fixture suitable
    /// for the External signer's `keyData` field.
    private func secp256r1Key() -> Data {
        var bytes = [UInt8](repeating: 0, count: SmartAccountConstants.secp256r1PublicKeySize)
        bytes[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        for i in 1..<SmartAccountConstants.secp256r1PublicKeySize {
            bytes[i] = UInt8(i % 256)
        }
        return Data(bytes)
    }

    // ========================================================================
    // parseContextRule — Valid rules (10 cases)
    // ========================================================================

    func testParseContextRule_validRuleWithAllFields() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(
            id: 42,
            name: "MyRule",
            contextType: defaultContextTypeScVal(),
            signers: [try delegatedSignerScVal(validAccountAddress)],
            signerIds: [10],
            policies: [try addressScVal(validContractAddress2)],
            policyIds: [20],
            validUntil: .u32(999_999)
        )
        let result = try manager.parseContextRule(scVal: ruleMap)

        XCTAssertEqual(result.id, 42)
        XCTAssertEqual(result.name, "MyRule")
        XCTAssertEqual(result.contextType, .defaultRule)
        XCTAssertEqual(result.signers.count, 1)
        XCTAssertTrue(result.signers[0] is OZDelegatedSigner)
        XCTAssertEqual((result.signers[0] as? OZDelegatedSigner)?.address, validAccountAddress)
        XCTAssertEqual(result.signerIds, [10])
        XCTAssertEqual(result.policies, [validContractAddress2])
        XCTAssertEqual(result.policyIds, [20])
        XCTAssertEqual(result.validUntil, 999_999)
    }

    func testParseContextRule_defaultContextType() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(contextType: defaultContextTypeScVal())
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(result.contextType, .defaultRule)
    }

    func testParseContextRule_callContractContextType() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(
            contextType: try callContractContextTypeScVal(validContractAddress2)
        )
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(result.contextType, .callContract(contractAddress: validContractAddress2))
    }

    func testParseContextRule_createContractContextType() throws {
        let manager = try disconnectedManager()
        let wasmHash = Data((0..<32).map { UInt8(($0 + 5) % 256) })
        let ruleMap = buildFullRuleMap(
            contextType: createContractContextTypeScVal(wasmHash: wasmHash)
        )
        let result = try manager.parseContextRule(scVal: ruleMap)
        guard case .createContract(let parsedHash) = result.contextType else {
            return XCTFail("expected CreateContract")
        }
        XCTAssertEqual(parsedHash, wasmHash)
    }

    func testParseContextRule_emptySignersAndPolicies() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(
            signers: [],
            signerIds: [],
            policies: [],
            policyIds: []
        )
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertTrue(result.signers.isEmpty)
        XCTAssertTrue(result.signerIds.isEmpty)
        XCTAssertTrue(result.policies.isEmpty)
        XCTAssertTrue(result.policyIds.isEmpty)
    }

    func testParseContextRule_multipleSigners_delegatedAndExternal() throws {
        let manager = try disconnectedManager()
        let keyData = secp256r1Key()
        let ruleMap = buildFullRuleMap(
            signers: [
                try delegatedSignerScVal(validAccountAddress),
                try externalSignerScVal(verifierAddress: validContractAddress2, keyData: keyData)
            ],
            signerIds: [1, 2]
        )
        let result = try manager.parseContextRule(scVal: ruleMap)

        XCTAssertEqual(result.signers.count, 2)
        XCTAssertTrue(result.signers[0] is OZDelegatedSigner)
        XCTAssertTrue(result.signers[1] is OZExternalSigner)
        XCTAssertEqual((result.signers[0] as? OZDelegatedSigner)?.address, validAccountAddress)
        XCTAssertEqual((result.signers[1] as? OZExternalSigner)?.verifierAddress, validContractAddress2)
        XCTAssertEqual((result.signers[1] as? OZExternalSigner)?.keyData, keyData)
    }

    func testParseContextRule_validUntilVoid_noExpiration() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(validUntil: .void)
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertNil(result.validUntil)
    }

    func testParseContextRule_validUntilU32_hasExpiration() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(validUntil: .u32(12_345_678))
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(result.validUntil, 12_345_678)
    }

    func testParseContextRule_validUntilFieldMissing_returnsNil() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("NoExpiry")),
            ("context_type", defaultContextTypeScVal()),
            ("signers", .vec([])),
            ("signer_ids", .vec([])),
            ("policies", .vec([])),
            ("policy_ids", .vec([]))
        ])
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertNil(result.validUntil)
    }

    func testParseContextRule_multiplePolicies() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(
            policies: [
                try addressScVal(validContractAddress),
                try addressScVal(validContractAddress2)
            ],
            policyIds: [10, 20]
        )
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(result.policies.count, 2)
        XCTAssertEqual(result.policyIds.count, 2)
        XCTAssertEqual(result.policyIds[0], 10)
        XCTAssertEqual(result.policyIds[1], 20)
    }

    // ========================================================================
    // parseContextRule — Missing required fields (3 cases)
    // ========================================================================

    func testParseContextRule_missingId_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("name", .string("TestRule")),
            ("context_type", defaultContextTypeScVal())
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException, got: \(error)")
            }
            XCTAssertTrue(validation.message.contains("id"),
                          "Exception message should mention 'id'")
        }
    }

    func testParseContextRule_missingName_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("context_type", defaultContextTypeScVal())
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException, got: \(error)")
            }
            XCTAssertTrue(validation.message.contains("name"),
                          "Exception message should mention 'name'")
        }
    }

    func testParseContextRule_missingContextType_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("TestRule"))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException, got: \(error)")
            }
            XCTAssertTrue(validation.message.contains("context_type"),
                          "Exception message should mention 'context_type'")
        }
    }

    // ========================================================================
    // parseContextRule — Invalid field types (6 cases)
    // ========================================================================

    func testParseContextRule_idNotU32_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .string("not-a-number")),
            ("name", .string("TestRule")),
            ("context_type", defaultContextTypeScVal())
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("id"))
        }
    }

    func testParseContextRule_nameNotString_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .u32(42)),
            ("context_type", defaultContextTypeScVal())
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("name"))
        }
    }

    func testParseContextRule_contextTypeNotVec_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("TestRule")),
            ("context_type", .string("Default"))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("context_type"))
        }
    }

    func testParseContextRule_signersNotVec_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("TestRule")),
            ("context_type", defaultContextTypeScVal()),
            ("signers", .string("not-a-vec"))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("signers"))
        }
    }

    func testParseContextRule_signerIdsEntryNotU32_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("TestRule")),
            ("context_type", defaultContextTypeScVal()),
            ("signer_ids", .vec([.string("not-a-u32")]))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("signer_ids"))
        }
    }

    func testParseContextRule_validUntilInvalidType_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(validUntil: .string("not-a-u32"))
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("valid_until"))
        }
    }

    // ========================================================================
    // parseContextRule — Non-Map input (3 cases)
    // ========================================================================

    func testParseContextRule_nonMapInput_throwsValidationException() throws {
        let manager = try disconnectedManager()
        XCTAssertThrowsError(try manager.parseContextRule(scVal: .vec([]))) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("Map"),
                          "Exception message should mention 'Map'")
        }
    }

    func testParseContextRule_voidInput_throwsValidationException() throws {
        let manager = try disconnectedManager()
        XCTAssertThrowsError(try manager.parseContextRule(scVal: .void)) { error in
            XCTAssertTrue(error is ValidationException)
        }
    }

    func testParseContextRule_stringInput_throwsValidationException() throws {
        let manager = try disconnectedManager()
        XCTAssertThrowsError(try manager.parseContextRule(scVal: .string("not-a-map"))) { error in
            XCTAssertTrue(error is ValidationException)
        }
    }

    // ========================================================================
    // parseContextRule — Context type edge cases (4 cases)
    // ========================================================================

    func testParseContextRule_emptyContextTypeVec_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildFullRuleMap(contextType: .vec([]))
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("context_type"))
        }
    }

    func testParseContextRule_unknownContextTypeDiscriminant_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let unknownType: SCValXDR = .vec([.symbol("Unknown")])
        let ruleMap = buildFullRuleMap(contextType: unknownType)
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("Unknown"),
                          "Exception message should contain the unknown discriminant")
        }
    }

    func testParseContextRule_callContractMissingAddress_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let badCallContract: SCValXDR = .vec([.symbol("CallContract")])
        let ruleMap = buildFullRuleMap(contextType: badCallContract)
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("CallContract"),
                          "Exception message should mention 'CallContract'")
        }
    }

    func testParseContextRule_createContractMissingHash_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let badCreateContract: SCValXDR = .vec([.symbol("CreateContract")])
        let ruleMap = buildFullRuleMap(contextType: badCreateContract)
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("CreateContract"),
                          "Exception message should mention 'CreateContract'")
        }
    }

    // ========================================================================
    // parseContextRule — Signer parsing edge cases (4 cases)
    // ========================================================================

    func testParseContextRule_unknownSignerDiscriminant_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let unknownSigner: SCValXDR = .vec([.symbol("UnknownType")])
        let ruleMap = buildFullRuleMap(
            signers: [unknownSigner],
            signerIds: [1]
        )
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("UnknownType"),
                          "Exception message should contain the unknown discriminant")
        }
    }

    func testParseContextRule_emptySignerVec_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let emptySigner: SCValXDR = .vec([])
        let ruleMap = buildFullRuleMap(
            signers: [emptySigner],
            signerIds: [1]
        )
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("signer"),
                          "Exception message should mention 'signer'")
        }
    }

    func testParseContextRule_delegatedSignerMissingAddress_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let badDelegated: SCValXDR = .vec([.symbol("Delegated")])
        let ruleMap = buildFullRuleMap(
            signers: [badDelegated],
            signerIds: [1]
        )
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("Delegated"),
                          "Exception message should mention 'Delegated'")
        }
    }

    func testParseContextRule_externalSignerMissingKeyData_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let badExternal: SCValXDR = .vec([
            .symbol("External"),
            .address(try SCAddressXDR(contractId: validContractAddress))
        ])
        let ruleMap = buildFullRuleMap(
            signers: [badExternal],
            signerIds: [1]
        )
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("External"),
                          "Exception message should mention 'External'")
        }
    }

    // ========================================================================
    // ContextRuleType.toScVal() (4 cases)
    // ========================================================================

    func testContextRuleType_defaultToScVal() throws {
        let scVal = try ContextRuleType.defaultRule.toScVal()
        guard case .vec(let elements) = scVal, let elements = elements else {
            return XCTFail("expected vec")
        }
        XCTAssertEqual(elements.count, 1)
        guard case .symbol(let discriminant) = elements[0] else {
            return XCTFail("expected symbol")
        }
        XCTAssertEqual(discriminant, "Default")
    }

    func testContextRuleType_callContractToScVal() throws {
        let scVal = try ContextRuleType.callContract(contractAddress: validContractAddress2).toScVal()
        guard case .vec(let elements) = scVal, let elements = elements else {
            return XCTFail("expected vec")
        }
        XCTAssertEqual(elements.count, 2)
        guard case .symbol(let discriminant) = elements[0] else {
            return XCTFail("expected symbol")
        }
        XCTAssertEqual(discriminant, "CallContract")
        guard case .address(let scAddress) = elements[1] else {
            return XCTFail("expected address")
        }
        let parsedAddress: String?
        if case .contract(let wrapped) = scAddress {
            parsedAddress = try? wrapped.wrapped.encodeContractId()
        } else {
            parsedAddress = nil
        }
        XCTAssertEqual(parsedAddress, validContractAddress2)
    }

    func testContextRuleType_createContractToScVal() throws {
        let wasmHash = Data((0..<32).map { UInt8(($0 * 3) % 256) })
        let scVal = try ContextRuleType.createContract(wasmHash: wasmHash).toScVal()
        guard case .vec(let elements) = scVal, let elements = elements else {
            return XCTFail("expected vec")
        }
        XCTAssertEqual(elements.count, 2)
        guard case .symbol(let discriminant) = elements[0] else {
            return XCTFail("expected symbol")
        }
        XCTAssertEqual(discriminant, "CreateContract")
        guard case .bytes(let parsedHash) = elements[1] else {
            return XCTFail("expected bytes")
        }
        XCTAssertEqual(parsedHash, wasmHash)
    }

    func testContextRuleType_callContractInvalidAddress_throws() throws {
        XCTAssertThrowsError(
            try ContextRuleType.callContract(contractAddress: "INVALID_ADDRESS").toScVal()
        ) { error in
            XCTAssertTrue(error is ValidationException)
        }
    }

    // ========================================================================
    // ContextRuleType equality and hashCode (3 cases)
    // ========================================================================

    func testContextRuleType_defaultEquality() {
        XCTAssertEqual(ContextRuleType.defaultRule, ContextRuleType.defaultRule)
    }

    func testContextRuleType_callContractEquality() {
        let a = ContextRuleType.callContract(contractAddress: validContractAddress)
        let b = ContextRuleType.callContract(contractAddress: validContractAddress)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testContextRuleType_createContractEquality() {
        let hash = Data((0..<32).map { UInt8($0) })
        let a = ContextRuleType.createContract(wasmHash: hash)
        let b = ContextRuleType.createContract(wasmHash: hash)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    // ========================================================================
    // ParsedContextRule data shape (3 cases)
    // ========================================================================

    func testParsedContextRule_constructionAndFieldAccess() throws {
        let signer = try OZDelegatedSigner(address: validAccountAddress)
        let rule = ParsedContextRule(
            id: 5,
            contextType: .defaultRule,
            name: "TestRule",
            signers: [signer],
            signerIds: [10],
            policies: [validContractAddress2],
            policyIds: [20],
            validUntil: 100
        )
        XCTAssertEqual(rule.id, 5)
        XCTAssertEqual(rule.contextType, .defaultRule)
        XCTAssertEqual(rule.name, "TestRule")
        XCTAssertEqual(rule.signers.count, 1)
        XCTAssertEqual(rule.signerIds, [10])
        XCTAssertEqual(rule.policies, [validContractAddress2])
        XCTAssertEqual(rule.policyIds, [20])
        XCTAssertEqual(rule.validUntil, 100)
    }

    func testParsedContextRule_nullValidUntil() {
        let rule = ParsedContextRule(
            id: 0,
            contextType: .defaultRule,
            name: "NoExpiry",
            signers: [],
            signerIds: [],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        XCTAssertNil(rule.validUntil)
    }

    func testParsedContextRule_equalityAndHashing() throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)
        let signerB = try OZDelegatedSigner(address: validAccountAddress)
        let a = ParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "X",
            signers: [signerA],
            signerIds: [1],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let b = ParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "X",
            signers: [signerB],
            signerIds: [1],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    // ========================================================================
    // addContextRule — Input validation (without network) (8 cases)
    // ========================================================================

    func testAddContextRule_notConnected_throwsWalletNotConnected() async throws {
        let manager = try disconnectedManager()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "Rule",
                signers: [try OZDelegatedSigner(address: validAccountAddress)]
            )
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    func testAddContextRule_emptyName_throwsValidationException() async throws {
        let manager = try connectedManager()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "",
                signers: [try OZDelegatedSigner(address: validAccountAddress)]
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("name"))
        }
    }

    func testAddContextRule_emptySignersAndPolicies_throwsValidationException() async throws {
        let manager = try connectedManager()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "EmptyRule",
                signers: [],
                policies: [:]
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            let msg = error.message
            XCTAssertTrue(msg.contains("signer") || msg.contains("policy") || msg.contains("policies"))
        }
    }

    func testAddContextRule_tooManySigners_throwsValidationException() async throws {
        let manager = try connectedManager()
        let signers = try (0..<16).map { _ in
            try OZDelegatedSigner(address: validAccountAddress)
        }
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TooManySigners",
                signers: signers
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            let msg = error.message
            XCTAssertTrue(msg.contains("15") || msg.contains("signers"))
        }
    }

    func testAddContextRule_tooManyPolicies_throwsValidationException() async throws {
        let manager = try connectedManager()
        var policies: [String: SCValXDR] = [:]
        for i in 0..<6 {
            let address = try generateContractAddress(seed: i * 10)
            policies[address] = .void
        }
        XCTAssertEqual(policies.count, 6, "Precondition: must have 6 unique policy addresses")

        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TooManyPolicies",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: policies
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            let msg = error.message
            XCTAssertTrue(msg.contains("5") || msg.contains("policies"))
        }
    }

    func testAddContextRule_invalidPolicyAddress_throwsValidationException() async throws {
        let manager = try connectedManager()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "BadPolicy",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: ["INVALID_ADDRESS": .void]
            )
            XCTFail("expected ValidationException")
        } catch let error as ValidationException {
            let msg = error.message
            XCTAssertTrue(msg.lowercased().contains("address"),
                          "Expected message to mention address validation, got: \(msg)")
        }
    }

    func testAddContextRule_gAddressAsPolicy_throwsValidationException() async throws {
        let manager = try connectedManager()
        // Policy addresses must be C-addresses (contracts), not G-addresses.
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "GAddressPolicy",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: [validAccountAddress: .void]
            )
            XCTFail("expected ValidationException")
        } catch let error as ValidationException {
            XCTAssertNotNil(error.message)
        }
    }

    // ========================================================================
    // parseContextRule — Round-trip: toScVal then parse back (3 cases)
    // ========================================================================

    func testRoundTrip_defaultContextType() throws {
        let manager = try disconnectedManager()
        let originalType = ContextRuleType.defaultRule
        let scVal = try originalType.toScVal()
        let ruleMap = buildFullRuleMap(contextType: scVal)
        let parsed = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(parsed.contextType, .defaultRule)
    }

    func testRoundTrip_callContractContextType() throws {
        let manager = try disconnectedManager()
        let originalType = ContextRuleType.callContract(contractAddress: validContractAddress2)
        let scVal = try originalType.toScVal()
        let ruleMap = buildFullRuleMap(contextType: scVal)
        let parsed = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(parsed.contextType, originalType)
    }

    func testRoundTrip_createContractContextType() throws {
        let manager = try disconnectedManager()
        let wasmHash = Data((0..<32).map { UInt8(($0 * 7) % 256) })
        let originalType = ContextRuleType.createContract(wasmHash: wasmHash)
        let scVal = try originalType.toScVal()
        let ruleMap = buildFullRuleMap(contextType: scVal)
        let parsed = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(parsed.contextType, originalType)
    }

    // ========================================================================
    // parseContextRule — Field ordering and lookup-by-name (1 case)
    // ========================================================================

    func testParseContextRule_fieldsInNonAlphabeticalOrder() throws {
        let manager = try disconnectedManager()
        // Reverse alphabetical insertion to verify the parser looks up fields
        // by Symbol-key name, not by positional index.
        let ruleMap = buildMapScVal([
            ("valid_until", .void),
            ("signers", .vec([])),
            ("signer_ids", .vec([])),
            ("policies", .vec([])),
            ("policy_ids", .vec([])),
            ("name", .string("ReversedFields")),
            ("id", .u32(99)),
            ("context_type", defaultContextTypeScVal())
        ])
        let result = try manager.parseContextRule(scVal: ruleMap)
        XCTAssertEqual(result.id, 99)
        XCTAssertEqual(result.name, "ReversedFields")
        XCTAssertEqual(result.contextType, .defaultRule)
    }

    // ========================================================================
    // parseContextRule — Non-symbol keys silently skipped (1 case)
    // ========================================================================

    func testParseContextRule_nonSymbolKeysIgnored() throws {
        let manager = try disconnectedManager()
        // Mix non-Symbol keys (U32, Bytes) alongside the valid Symbol keys to
        // confirm the parser ignores non-Symbol keys silently.
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .u32(0), val: .string("ignored")),
            SCMapEntryXDR(key: .symbol("id"), val: .u32(7)),
            SCMapEntryXDR(key: .symbol("name"), val: .string("WithExtra")),
            SCMapEntryXDR(key: .symbol("context_type"), val: defaultContextTypeScVal()),
            SCMapEntryXDR(key: .bytes(Data([0, 1, 2, 3])), val: .void)
        ]
        let result = try manager.parseContextRule(scVal: .map(entries))
        XCTAssertEqual(result.id, 7)
        XCTAssertEqual(result.name, "WithExtra")
    }

    // ========================================================================
    // parseContextRule — Policy address parsing errors (3 cases)
    // ========================================================================

    func testParseContextRule_policiesEntryNotAddress_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("BadPolicies")),
            ("context_type", defaultContextTypeScVal()),
            ("policies", .vec([.string("not-an-address")]))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            // Inner failure tagged with "address"; let the implementation be
            // free to choose whether the outer field is reported too.
            let msg = validation.message
            XCTAssertTrue(msg.contains("address") || msg.contains("policies"),
                          "Expected mention of address or policies in: \(msg)")
        }
    }

    func testParseContextRule_policyIdsNotVec_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("BadPolicyIds")),
            ("context_type", defaultContextTypeScVal()),
            ("policy_ids", .string("not-a-vec"))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("policy_ids"))
        }
    }

    func testParseContextRule_policyIdsEntryNotU32_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("BadPolicyIdEntry")),
            ("context_type", defaultContextTypeScVal()),
            ("policy_ids", .vec([.string("not-a-u32")]))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("policy_ids"))
        }
    }

    // ========================================================================
    // parseContextRule — Signer not a Vec (1 case)
    // ========================================================================

    func testParseContextRule_signerEntryNotVec_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let ruleMap = buildMapScVal([
            ("id", .u32(1)),
            ("name", .string("BadSigner")),
            ("context_type", defaultContextTypeScVal()),
            ("signers", .vec([.string("not-a-signer-vec")]))
        ])
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("signer"))
        }
    }

    // ========================================================================
    // parseContextRule — Context-type discriminant not a Symbol (1 case)
    // ========================================================================

    func testParseContextRule_contextTypeDiscriminantNotSymbol_throwsValidationException() throws {
        let manager = try disconnectedManager()
        let badType: SCValXDR = .vec([.u32(42)])
        let ruleMap = buildFullRuleMap(contextType: badType)
        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException")
            }
            XCTAssertTrue(validation.message.contains("context_type"))
        }
    }

    // ========================================================================
    // MARK: - External signer verifier address validation
    // ========================================================================

    /// An ``External`` signer's verifier address must be a contract (`C…`)
    /// strkey. Permissive parsing that accepts an account (`G…`) address would
    /// silently construct a signer whose on-chain dispatch must fail because
    /// account addresses cannot host a verifier method. The strict parser
    /// surfaces a clear validation error here so malformed on-chain records
    /// do not propagate into downstream signing flows.
    func testParseContextRule_externalSignerVerifierIsGAddress_throwsValidationException() throws {
        let manager = try disconnectedManager()

        // Build an External signer with a G-address in the verifier slot.
        let invalidExternalSigner: SCValXDR = .vec([
            .symbol("External"),
            .address(try SCAddressXDR(accountId: validAccountAddress)),
            .bytes(secp256r1Key())
        ])
        let ruleMap = buildFullRuleMap(
            signers: [invalidExternalSigner],
            signerIds: [1]
        )

        XCTAssertThrowsError(try manager.parseContextRule(scVal: ruleMap)) { error in
            guard let validation = error as? ValidationException else {
                return XCTFail("expected ValidationException, got \(error)")
            }
            // The error message must clearly identify the problem so callers
            // can diagnose a malformed on-chain record without inspecting the
            // raw ScVal bytes.
            let message = validation.message.lowercased()
            XCTAssertTrue(
                message.contains("contract") || message.contains("verifier") || message.contains("external"),
                "error message should mention the verifier / contract-address constraint, got: \(validation.message)"
            )
        }
    }
}
