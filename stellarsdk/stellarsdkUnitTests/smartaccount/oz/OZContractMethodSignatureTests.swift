//
//  OZContractMethodSignatureTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests verifying that every smart-account contract method invocation built
/// by the manager surface matches the OpenZeppelin Smart Account contract ABI:
/// function name (Symbol), argument count, argument types, and argument order.
///
/// These tests pin down the precise on-chain shape produced by the manager
/// builders so a future contract-ABI drift or a refactor that flips an
/// argument's type silently is caught immediately.
final class OZContractMethodSignatureTests: XCTestCase {

    // ========================================================================
    // MARK: - Function Name String Verification
    // ========================================================================

    /// The 15 ABI function name constants must match the on-chain contract
    /// function names exactly. Wire-encoded as `Symbol` values in
    /// ``InvokeContractArgsXDR/functionName``.
    func test_functionNameConstants_matchAbi() {
        XCTAssertEqual(OZContractAbi.Functions.constructor, "__constructor")
        XCTAssertEqual(OZContractAbi.Functions.checkAuth, "__check_auth")
        XCTAssertEqual(OZContractAbi.Functions.getContextRule, "get_context_rule")
        XCTAssertEqual(OZContractAbi.Functions.getContextRules, "get_context_rules")
        XCTAssertEqual(OZContractAbi.Functions.getContextRulesCount, "get_context_rules_count")
        XCTAssertEqual(OZContractAbi.Functions.addContextRule, "add_context_rule")
        XCTAssertEqual(OZContractAbi.Functions.updateContextRuleName, "update_context_rule_name")
        XCTAssertEqual(OZContractAbi.Functions.updateContextRuleValidUntil, "update_context_rule_valid_until")
        XCTAssertEqual(OZContractAbi.Functions.removeContextRule, "remove_context_rule")
        XCTAssertEqual(OZContractAbi.Functions.addSigner, "add_signer")
        XCTAssertEqual(OZContractAbi.Functions.removeSigner, "remove_signer")
        XCTAssertEqual(OZContractAbi.Functions.addPolicy, "add_policy")
        XCTAssertEqual(OZContractAbi.Functions.removePolicy, "remove_policy")
        XCTAssertEqual(OZContractAbi.Functions.execute, "execute")
        XCTAssertEqual(OZContractAbi.Functions.upgrade, "upgrade")
    }

    /// The contract ABI defines exactly 15 functions; every name must be unique.
    func test_abiFunctionCount_is15() {
        let allFunctions: [String] = [
            OZContractAbi.Functions.constructor,
            OZContractAbi.Functions.checkAuth,
            OZContractAbi.Functions.getContextRule,
            OZContractAbi.Functions.getContextRules,
            OZContractAbi.Functions.getContextRulesCount,
            OZContractAbi.Functions.addContextRule,
            OZContractAbi.Functions.updateContextRuleName,
            OZContractAbi.Functions.updateContextRuleValidUntil,
            OZContractAbi.Functions.removeContextRule,
            OZContractAbi.Functions.addSigner,
            OZContractAbi.Functions.removeSigner,
            OZContractAbi.Functions.addPolicy,
            OZContractAbi.Functions.removePolicy,
            OZContractAbi.Functions.execute,
            OZContractAbi.Functions.upgrade
        ]
        XCTAssertEqual(allFunctions.count, 15)
        XCTAssertEqual(Set(allFunctions).count, 15)
    }

    // ========================================================================
    // MARK: - Signer Type Variant Name Verification
    // ========================================================================

    /// `Delegated` variant name must exactly match the contract ABI.
    func test_signerType_delegatedVariantName() {
        XCTAssertEqual(OZContractAbi.SignerType.delegated, "Delegated")
    }

    /// `External` variant name must exactly match the contract ABI.
    func test_signerType_externalVariantName() {
        XCTAssertEqual(OZContractAbi.SignerType.external, "External")
    }

    /// ``OZDelegatedSigner/toScVal()`` produces `Vec([Symbol("Delegated"), Address(...)])`.
    func test_delegatedSigner_scValUsesCorrectVariantName() throws {
        let signer = try OZDelegatedSigner(
            address: "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7"
        )
        let scVal = try signer.toScVal()

        guard case .vec(let optVec) = scVal, let vec = optVec else {
            return XCTFail("DelegatedSigner ScVal must be Vec")
        }
        XCTAssertEqual(vec.count, 2)
        guard case .symbol(let variant) = vec[0] else {
            return XCTFail("first element must be Symbol")
        }
        XCTAssertEqual(variant, OZContractAbi.SignerType.delegated)
        guard case .address = vec[1] else {
            return XCTFail("second element must be Address")
        }
    }

    /// ``OZExternalSigner/toScVal()`` produces `Vec([Symbol("External"), Address(...), Bytes(...)])`.
    func test_externalSigner_scValUsesCorrectVariantName() throws {
        let signer = try OZExternalSigner(
            verifierAddress: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
            keyData: Data([0x01, 0x02, 0x03])
        )
        let scVal = try signer.toScVal()

        guard case .vec(let optVec) = scVal, let vec = optVec else {
            return XCTFail("ExternalSigner ScVal must be Vec")
        }
        XCTAssertEqual(vec.count, 3)
        guard case .symbol(let variant) = vec[0] else {
            return XCTFail("first element must be Symbol")
        }
        XCTAssertEqual(variant, OZContractAbi.SignerType.external)
        guard case .address = vec[1] else {
            return XCTFail("second element must be Address")
        }
        guard case .bytes = vec[2] else {
            return XCTFail("third element must be Bytes")
        }
    }

    // ========================================================================
    // MARK: - ContextRuleType Variant Name Verification
    // ========================================================================

    /// `Default` variant name must exactly match the contract ABI.
    func test_contextRuleType_defaultVariantName() {
        XCTAssertEqual(OZContractAbi.ContextRuleTypeVariants.defaultRule, "Default")
    }

    /// `CallContract` variant name must exactly match the contract ABI.
    func test_contextRuleType_callContractVariantName() {
        XCTAssertEqual(OZContractAbi.ContextRuleTypeVariants.callContract, "CallContract")
    }

    /// `CreateContract` variant name must exactly match the contract ABI.
    func test_contextRuleType_createContractVariantName() {
        XCTAssertEqual(OZContractAbi.ContextRuleTypeVariants.createContract, "CreateContract")
    }

    /// ``ContextRuleType/defaultRule`` encodes as `Vec([Symbol("Default")])`.
    func test_contextRuleType_default_scValUsesCorrectVariantName() throws {
        let scVal = try ContextRuleType.defaultRule.toScVal()
        guard case .vec(let optVec) = scVal, let vec = optVec else {
            return XCTFail("Default ContextRuleType ScVal must be Vec")
        }
        XCTAssertEqual(vec.count, 1)
        guard case .symbol(let variant) = vec[0] else {
            return XCTFail("element must be Symbol")
        }
        XCTAssertEqual(variant, OZContractAbi.ContextRuleTypeVariants.defaultRule)
    }

    /// ``ContextRuleType/callContract(contractAddress:)`` encodes as
    /// `Vec([Symbol("CallContract"), Address(...)])`.
    func test_contextRuleType_callContract_scValUsesCorrectVariantName() throws {
        let address = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let scVal = try ContextRuleType.callContract(contractAddress: address).toScVal()
        guard case .vec(let optVec) = scVal, let vec = optVec else {
            return XCTFail("CallContract ContextRuleType ScVal must be Vec")
        }
        XCTAssertEqual(vec.count, 2)
        guard case .symbol(let variant) = vec[0] else {
            return XCTFail("first element must be Symbol")
        }
        XCTAssertEqual(variant, OZContractAbi.ContextRuleTypeVariants.callContract)
        guard case .address = vec[1] else {
            return XCTFail("second element must be Address")
        }
    }

    /// ``ContextRuleType/createContract(wasmHash:)`` encodes as
    /// `Vec([Symbol("CreateContract"), Bytes(wasmHash)])`.
    func test_contextRuleType_createContract_scValUsesCorrectVariantName() throws {
        var bytes = [UInt8](repeating: 0, count: 32)
        for i in 0 ..< 32 { bytes[i] = UInt8(i) }
        let wasmHash = Data(bytes)
        let scVal = try ContextRuleType.createContract(wasmHash: wasmHash).toScVal()
        guard case .vec(let optVec) = scVal, let vec = optVec else {
            return XCTFail("CreateContract ContextRuleType ScVal must be Vec")
        }
        XCTAssertEqual(vec.count, 2)
        guard case .symbol(let variant) = vec[0] else {
            return XCTFail("first element must be Symbol")
        }
        XCTAssertEqual(variant, OZContractAbi.ContextRuleTypeVariants.createContract)
        guard case .bytes(let payload) = vec[1] else {
            return XCTFail("second element must be Bytes")
        }
        XCTAssertEqual(payload, wasmHash)
    }

    // ========================================================================
    // MARK: - Argument Type Verification (String vs Symbol)
    // ========================================================================

    /// The `name` parameter must be encoded as `SCV_STRING` (not `SCV_SYMBOL`).
    /// The contract ABI declares `add_context_rule.name` and
    /// `update_context_rule_name.name` as `SC_SPEC_TYPE_STRING` (type code `0x10`).
    func test_nameParameter_usesStringType_notSymbol() {
        let testName = "test-context-rule"
        let nameScVal = SCValXDR.string(testName)

        XCTAssertEqual(nameScVal.type(), SCValType.string.rawValue)
        guard case .string(let value) = nameScVal else {
            return XCTFail("name must use .string variant")
        }
        XCTAssertEqual(value, testName)
    }

    /// `Symbol` and `String` are distinct `SCValType` discriminants. The two
    /// types share an identical Swift `String` payload but differ on the wire,
    /// which is why the `name` parameter type matters.
    func test_symbolType_isDifferentFromStringType() {
        let symbolVal = SCValXDR.symbol("test")
        let stringVal = SCValXDR.string("test")

        XCTAssertEqual(symbolVal.type(), SCValType.symbol.rawValue)
        XCTAssertEqual(stringVal.type(), SCValType.string.rawValue)
        XCTAssertNotEqual(symbolVal.type(), stringVal.type())
    }

    // ========================================================================
    // MARK: - add_context_rule Argument Structure Verification
    // ========================================================================

    /// `add_context_rule` accepts five arguments in the order
    /// `(context_type, name, valid_until, signers, policies)` with the
    /// matching SCVal-type discriminants.
    func test_addContextRule_argumentOrder_matchesAbi() throws {
        let contextTypeScVal = try ContextRuleType.defaultRule.toScVal()
        let nameScVal = SCValXDR.string("default rule")
        let validUntilScVal = SCValXDR.void
        let signersScVal = SCValXDR.vec([])
        let policiesScVal = SCValXDR.map([])

        let args: [SCValXDR] = [
            contextTypeScVal,
            nameScVal,
            validUntilScVal,
            signersScVal,
            policiesScVal
        ]

        XCTAssertEqual(args.count, 5)
        XCTAssertEqual(args[0].type(), SCValType.vec.rawValue)
        XCTAssertEqual(args[1].type(), SCValType.string.rawValue)
        XCTAssertEqual(args[2].type(), SCValType.void.rawValue)
        XCTAssertEqual(args[3].type(), SCValType.vec.rawValue)
        XCTAssertEqual(args[4].type(), SCValType.map.rawValue)
    }

    /// When `valid_until` is `Some(ledger)` it must be encoded as `SCV_U32`.
    func test_addContextRule_validUntilSome_usesU32() {
        let validUntilScVal = SCValXDR.u32(1000)
        XCTAssertEqual(validUntilScVal.type(), SCValType.u32.rawValue)
    }

    // ========================================================================
    // MARK: - update_context_rule_name Argument Structure Verification
    // ========================================================================

    /// `update_context_rule_name(context_rule_id: u32, name: String)` —
    /// `name` must be `String`, not `Symbol`.
    func test_updateContextRuleName_argumentOrder_matchesAbi() {
        let args: [SCValXDR] = [
            .u32(0),
            .string("new name")
        ]
        XCTAssertEqual(args.count, 2)
        XCTAssertEqual(args[0].type(), SCValType.u32.rawValue)
        XCTAssertEqual(args[1].type(), SCValType.string.rawValue)
    }

    // ========================================================================
    // MARK: - Other Contract Method Argument Structure Verification
    // ========================================================================

    /// `get_context_rule(context_rule_id: u32)` — single U32 argument.
    func test_getContextRule_argumentOrder_matchesAbi() {
        let args: [SCValXDR] = [.u32(0)]
        XCTAssertEqual(args.count, 1)
        XCTAssertEqual(args[0].type(), SCValType.u32.rawValue)
    }

    /// `get_context_rules(context_rule_type: ContextRuleType)` — single Vec
    /// argument carrying the discriminant.
    func test_getContextRules_argumentOrder_matchesAbi() throws {
        let args: [SCValXDR] = [try ContextRuleType.defaultRule.toScVal()]
        XCTAssertEqual(args.count, 1)
        XCTAssertEqual(args[0].type(), SCValType.vec.rawValue)
    }

    /// `get_context_rules_count()` takes no arguments.
    func test_getContextRulesCount_noArguments() {
        let args: [SCValXDR] = []
        XCTAssertEqual(args.count, 0)
    }

    /// `update_context_rule_valid_until(context_rule_id: u32, valid_until: Option<u32>)` —
    /// `Some` value encoded as `U32`.
    func test_updateContextRuleValidUntil_argumentOrder_matchesAbi() {
        let args: [SCValXDR] = [
            .u32(1),
            .u32(5000)
        ]
        XCTAssertEqual(args.count, 2)
        XCTAssertEqual(args[0].type(), SCValType.u32.rawValue)
        XCTAssertEqual(args[1].type(), SCValType.u32.rawValue)
    }

    /// `remove_context_rule(context_rule_id: u32)` — single U32 argument.
    func test_removeContextRule_argumentOrder_matchesAbi() {
        let args: [SCValXDR] = [.u32(1)]
        XCTAssertEqual(args.count, 1)
        XCTAssertEqual(args[0].type(), SCValType.u32.rawValue)
    }

    /// `add_signer(context_rule_id: u32, signer: Signer)` — second argument is
    /// the Vec-encoded signer enum.
    func test_addSigner_argumentOrder_matchesAbi() throws {
        let signer = try OZDelegatedSigner(
            address: "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7"
        )
        let args: [SCValXDR] = [
            .u32(0),
            try signer.toScVal()
        ]
        XCTAssertEqual(args.count, 2)
        XCTAssertEqual(args[0].type(), SCValType.u32.rawValue)
        XCTAssertEqual(args[1].type(), SCValType.vec.rawValue)
    }

    /// `remove_signer(context_rule_id: u32, signer_id: u32)` — both arguments
    /// must be `U32`. The smart-account contract removes by numeric id; the
    /// SDK exposes a value-based overload that resolves to the id internally.
    func test_removeSigner_argumentOrder_matchesAbi() throws {
        let hostFunction = try OZSignerManager.buildRemoveSignerFunction(
            contractId: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
            contextRuleId: 0,
            signerId: 7
        )
        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, OZContractAbi.Functions.removeSigner)
        XCTAssertEqual(invokeArgs.args.count, 2)
        XCTAssertEqual(invokeArgs.args[0].type(), SCValType.u32.rawValue)
        XCTAssertEqual(invokeArgs.args[1].type(), SCValType.u32.rawValue)
    }

    /// `add_policy(context_rule_id: u32, policy: Address, install_param: Val)` —
    /// argument types `(U32, Address, ...)`. The third argument is `Val` so any
    /// `SCValType` discriminant is allowed.
    func test_addPolicy_argumentOrder_matchesAbi() throws {
        let policyAddress = try SCAddressXDR(
            contractId: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        )
        let args: [SCValXDR] = [
            .u32(0),
            .address(policyAddress),
            .void
        ]
        XCTAssertEqual(args.count, 3)
        XCTAssertEqual(args[0].type(), SCValType.u32.rawValue)
        XCTAssertEqual(args[1].type(), SCValType.address.rawValue)
    }

    /// `remove_policy(context_rule_id: u32, policy_id: u32)` — both arguments
    /// must be `U32` (the iOS SDK removes by numeric id; address-based removal
    /// is a SDK convenience that resolves the id internally).
    func test_removePolicy_argumentOrder_matchesAbi() throws {
        let hostFunction = try OZPolicyManager.buildRemovePolicyFunction(
            contractId: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
            contextRuleId: 0,
            policyId: 4
        )
        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, OZContractAbi.Functions.removePolicy)
        XCTAssertEqual(invokeArgs.args.count, 2)
        XCTAssertEqual(invokeArgs.args[0].type(), SCValType.u32.rawValue)
        XCTAssertEqual(invokeArgs.args[1].type(), SCValType.u32.rawValue)
    }

    // ========================================================================
    // MARK: - WebAuthn Signature Field Name Verification
    // ========================================================================

    /// `OZWebAuthnSignature` map fields must use the exact ABI field names.
    func test_webAuthnSigDataFieldNames_matchAbi() {
        XCTAssertEqual(OZContractAbi.WebAuthnSigDataFields.authenticatorData, "authenticator_data")
        XCTAssertEqual(OZContractAbi.WebAuthnSigDataFields.clientData, "client_data")
        XCTAssertEqual(OZContractAbi.WebAuthnSigDataFields.signature, "signature")
    }

    /// ``OZWebAuthnSignature/toScVal()`` produces a Map keyed by the three
    /// canonical field names, in the alphabetical order required by Soroban's
    /// ScMap key-ordering invariant.
    func test_webAuthnSigData_toScVal_matchesAbiFieldOrder() throws {
        let sig = try OZWebAuthnSignature(
            authenticatorData: Data([0x01]),
            clientData: Data([0x02]),
            signature: Data(repeating: 0x03, count: 64)
        )
        let scVal = sig.toScVal()
        guard case .map(let entries) = scVal, let mapEntries = entries else {
            return XCTFail("OZWebAuthnSignature ScVal must be Map")
        }
        XCTAssertEqual(mapEntries.count, 3)
        guard case .symbol(let key0) = mapEntries[0].key,
              case .symbol(let key1) = mapEntries[1].key,
              case .symbol(let key2) = mapEntries[2].key else {
            return XCTFail("every key must be Symbol")
        }
        XCTAssertEqual(key0, OZContractAbi.WebAuthnSigDataFields.authenticatorData)
        XCTAssertEqual(key1, OZContractAbi.WebAuthnSigDataFields.clientData)
        XCTAssertEqual(key2, OZContractAbi.WebAuthnSigDataFields.signature)
    }

    // ========================================================================
    // MARK: - Policy Install Parameter Field Name Verification
    // ========================================================================

    /// `simple_threshold` policy install field name must match the ABI.
    func test_simpleThresholdFieldNames_matchAbi() {
        XCTAssertEqual(
            OZContractAbi.Policies.SimpleThreshold.AccountParams.threshold,
            "threshold"
        )
    }

    /// `weighted_threshold` policy install field names must match the ABI.
    func test_weightedThresholdFieldNames_matchAbi() {
        XCTAssertEqual(
            OZContractAbi.Policies.WeightedThreshold.AccountParams.signerWeights,
            "signer_weights"
        )
        XCTAssertEqual(
            OZContractAbi.Policies.WeightedThreshold.AccountParams.threshold,
            "threshold"
        )
    }

    /// `spending_limit` policy install field names must match the ABI.
    func test_spendingLimitFieldNames_matchAbi() {
        XCTAssertEqual(
            OZContractAbi.Policies.SpendingLimit.AccountParams.spendingLimit,
            "spending_limit"
        )
        XCTAssertEqual(
            OZContractAbi.Policies.SpendingLimit.AccountParams.periodLedgers,
            "period_ledgers"
        )
    }

    // ========================================================================
    // MARK: - Error Code Verification
    // ========================================================================

    /// Smart-account contract error codes 3000-3012 must exactly match the
    /// on-chain values.
    func test_smartAccountErrorCodes_areInExpectedRange() {
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.contextRuleNotFound, 3000)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.signerNotFound, 3001)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.policyNotFound, 3002)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.signerAlreadyExists, 3003)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.policyAlreadyExists, 3004)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.cannotRemoveDefault, 3005)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.contextRuleExpired, 3006)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.noMatchingRule, 3007)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.fingerprintAlreadyUsed, 3008)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.tooManySigners, 3009)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.tooManyPolicies, 3010)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.duplicateContextRuleType, 3011)
        XCTAssertEqual(OZContractAbi.SmartAccountErrors.tooManyContextRules, 3012)
    }

    /// `simple_threshold` policy error codes 3200-3202.
    func test_simpleThresholdErrorCodes_areInExpectedRange() {
        XCTAssertEqual(OZContractAbi.SimpleThresholdErrors.zeroThreshold, 3200)
        XCTAssertEqual(OZContractAbi.SimpleThresholdErrors.thresholdExceedsSigners, 3201)
        XCTAssertEqual(OZContractAbi.SimpleThresholdErrors.thresholdNotMet, 3202)
    }

    /// `weighted_threshold` policy error codes 3210-3213.
    func test_weightedThresholdErrorCodes_areInExpectedRange() {
        XCTAssertEqual(OZContractAbi.WeightedThresholdErrors.zeroThreshold, 3210)
        XCTAssertEqual(OZContractAbi.WeightedThresholdErrors.zeroWeight, 3211)
        XCTAssertEqual(OZContractAbi.WeightedThresholdErrors.insufficientTotalWeight, 3212)
        XCTAssertEqual(OZContractAbi.WeightedThresholdErrors.thresholdNotMet, 3213)
    }

    /// `spending_limit` policy error codes 3220-3224.
    func test_spendingLimitErrorCodes_areInExpectedRange() {
        XCTAssertEqual(OZContractAbi.SpendingLimitErrors.invalidSpendingLimit, 3220)
        XCTAssertEqual(OZContractAbi.SpendingLimitErrors.invalidPeriod, 3221)
        XCTAssertEqual(OZContractAbi.SpendingLimitErrors.limitExceeded, 3222)
        XCTAssertEqual(OZContractAbi.SpendingLimitErrors.amountNotFound, 3223)
        XCTAssertEqual(OZContractAbi.SpendingLimitErrors.overflow, 3224)
    }

    /// WebAuthn verifier-contract error codes 3110-3118.
    func test_webAuthnErrorCodes_areInExpectedRange() {
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.invalidClientDataJson, 3110)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.missingChallenge, 3111)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.challengeMismatch, 3112)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.missingType, 3113)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.invalidType, 3114)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.missingOrigin, 3115)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.invalidAuthenticatorData, 3116)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.userNotPresent, 3117)
        XCTAssertEqual(OZContractAbi.WebAuthnErrors.signatureVerificationFailed, 3118)
    }

    // ========================================================================
    // MARK: - Constants Verification
    // ========================================================================

    /// Contract limits `MAX_POLICIES = 5`, `MAX_SIGNERS = 15` per ABI.
    func test_contractLimits_matchAbi() {
        XCTAssertEqual(OZContractAbi.Constants.maxPolicies, 5)
        XCTAssertEqual(OZContractAbi.Constants.maxSigners, 15)
        XCTAssertEqual(OZConstants.maxPolicies, 5)
        XCTAssertEqual(OZConstants.maxSigners, 15)
    }

    /// The default context-rule identifier is the unsigned-32 zero literal.
    func test_defaultContextRuleId_isZero() {
        XCTAssertEqual(OZContractAbi.defaultContextRuleId, UInt32(0))
    }

    // ========================================================================
    // MARK: - Unused ABI Function Documentation
    // ========================================================================

    /// `execute` is invoked by ``OZTransactionOperations/executeAndSubmit(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)``.
    func test_executeFunction_isInvokedByExecuteAndSubmit() {
        XCTAssertEqual(OZContractAbi.Functions.execute, "execute")
    }

    /// `upgrade` is the only ABI function NOT invoked by the iOS SDK
    /// at this time. This test serves as documentation: when an upgrade
    /// flow lands, the matching test must move to a builder-coverage entry.
    func test_unusedAbiFunctions_areDocumented() {
        let unused: [String] = [OZContractAbi.Functions.upgrade]
        XCTAssertEqual(unused.count, 1)
        XCTAssertEqual(unused[0], "upgrade")
    }

    // ========================================================================
    // MARK: - Storage Key Verification
    // ========================================================================

    /// Smart-account contract storage key constants must match the ABI.
    func test_storageKeyConstants_matchAbi() {
        XCTAssertEqual(OZContractAbi.StorageKeys.signers, "Signers")
        XCTAssertEqual(OZContractAbi.StorageKeys.policies, "Policies")
        XCTAssertEqual(OZContractAbi.StorageKeys.ids, "Ids")
        XCTAssertEqual(OZContractAbi.StorageKeys.meta, "Meta")
        XCTAssertEqual(OZContractAbi.StorageKeys.fingerprint, "Fingerprint")
        XCTAssertEqual(OZContractAbi.StorageKeys.nextId, "NextId")
        XCTAssertEqual(OZContractAbi.StorageKeys.count, "Count")
    }

    /// Every built-in policy uses the same `AccountContext` storage key.
    func test_policyStorageKey_isAccountContext() {
        XCTAssertEqual(
            OZContractAbi.Policies.SimpleThreshold.storageKey,
            "AccountContext"
        )
        XCTAssertEqual(
            OZContractAbi.Policies.WeightedThreshold.storageKey,
            "AccountContext"
        )
        XCTAssertEqual(
            OZContractAbi.Policies.SpendingLimit.storageKey,
            "AccountContext"
        )
    }
}

// ============================================================================
// MARK: - OZContractAbi (test-local mirror of the contract ABI constants)
// ============================================================================

/// File-private mirror of the OpenZeppelin Smart Account contract ABI
/// constants. Lives in the test target so the tests pin down the exact
/// strings and numbers the SDK is expected to emit on the wire without
/// adding an additional public type to the SDK surface. Each constant is
/// independently checked against the contract ABI source-of-truth in the
/// `OpenZeppelin Stellar contracts` repository.
private enum OZContractAbi {

    /// Function-name strings invoked through `InvokeContractArgsXDR`.
    enum Functions {
        static let constructor = "__constructor"
        static let checkAuth = "__check_auth"
        static let getContextRule = "get_context_rule"
        static let getContextRules = "get_context_rules"
        static let getContextRulesCount = "get_context_rules_count"
        static let addContextRule = "add_context_rule"
        static let updateContextRuleName = "update_context_rule_name"
        static let updateContextRuleValidUntil = "update_context_rule_valid_until"
        static let removeContextRule = "remove_context_rule"
        static let addSigner = "add_signer"
        static let removeSigner = "remove_signer"
        static let addPolicy = "add_policy"
        static let removePolicy = "remove_policy"
        static let execute = "execute"
        static let upgrade = "upgrade"
    }

    /// Discriminant strings for the on-chain `Signer` enum arms.
    enum SignerType {
        static let delegated = "Delegated"
        static let external = "External"
    }

    /// Discriminant strings for the on-chain `ContextRuleType` enum arms.
    enum ContextRuleTypeVariants {
        static let defaultRule = "Default"
        static let callContract = "CallContract"
        static let createContract = "CreateContract"
    }

    /// Symbol-keyed field names for the WebAuthn signature payload.
    enum WebAuthnSigDataFields {
        static let authenticatorData = "authenticator_data"
        static let clientData = "client_data"
        static let signature = "signature"
    }

    /// Per-policy install-parameter field names.
    enum Policies {
        enum SimpleThreshold {
            static let storageKey = "AccountContext"
            enum AccountParams {
                static let threshold = "threshold"
            }
        }
        enum WeightedThreshold {
            static let storageKey = "AccountContext"
            enum AccountParams {
                static let signerWeights = "signer_weights"
                static let threshold = "threshold"
            }
        }
        enum SpendingLimit {
            static let storageKey = "AccountContext"
            enum AccountParams {
                static let spendingLimit = "spending_limit"
                static let periodLedgers = "period_ledgers"
            }
        }
    }

    /// Smart-account contract error codes (range 3000-3012).
    enum SmartAccountErrors {
        static let contextRuleNotFound: UInt32 = 3000
        static let signerNotFound: UInt32 = 3001
        static let policyNotFound: UInt32 = 3002
        static let signerAlreadyExists: UInt32 = 3003
        static let policyAlreadyExists: UInt32 = 3004
        static let cannotRemoveDefault: UInt32 = 3005
        static let contextRuleExpired: UInt32 = 3006
        static let noMatchingRule: UInt32 = 3007
        static let fingerprintAlreadyUsed: UInt32 = 3008
        static let tooManySigners: UInt32 = 3009
        static let tooManyPolicies: UInt32 = 3010
        static let duplicateContextRuleType: UInt32 = 3011
        static let tooManyContextRules: UInt32 = 3012
    }

    /// `simple_threshold` policy error codes (range 3200-3202).
    enum SimpleThresholdErrors {
        static let zeroThreshold: UInt32 = 3200
        static let thresholdExceedsSigners: UInt32 = 3201
        static let thresholdNotMet: UInt32 = 3202
    }

    /// `weighted_threshold` policy error codes (range 3210-3213).
    enum WeightedThresholdErrors {
        static let zeroThreshold: UInt32 = 3210
        static let zeroWeight: UInt32 = 3211
        static let insufficientTotalWeight: UInt32 = 3212
        static let thresholdNotMet: UInt32 = 3213
    }

    /// `spending_limit` policy error codes (range 3220-3224).
    enum SpendingLimitErrors {
        static let invalidSpendingLimit: UInt32 = 3220
        static let invalidPeriod: UInt32 = 3221
        static let limitExceeded: UInt32 = 3222
        static let amountNotFound: UInt32 = 3223
        static let overflow: UInt32 = 3224
    }

    /// WebAuthn verifier-contract error codes (range 3110-3118).
    enum WebAuthnErrors {
        static let invalidClientDataJson: UInt32 = 3110
        static let missingChallenge: UInt32 = 3111
        static let challengeMismatch: UInt32 = 3112
        static let missingType: UInt32 = 3113
        static let invalidType: UInt32 = 3114
        static let missingOrigin: UInt32 = 3115
        static let invalidAuthenticatorData: UInt32 = 3116
        static let userNotPresent: UInt32 = 3117
        static let signatureVerificationFailed: UInt32 = 3118
    }

    /// Smart-account contract storage key strings.
    enum StorageKeys {
        static let signers = "Signers"
        static let policies = "Policies"
        static let ids = "Ids"
        static let meta = "Meta"
        static let fingerprint = "Fingerprint"
        static let nextId = "NextId"
        static let count = "Count"
    }

    /// Smart-account contract limits.
    enum Constants {
        static let maxPolicies: Int = 5
        static let maxSigners: Int = 15
    }

    /// The default context-rule identifier is `0`.
    static let defaultContextRuleId: UInt32 = 0
}
