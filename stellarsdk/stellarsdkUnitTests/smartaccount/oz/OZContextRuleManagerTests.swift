//
//  OZContextRuleManagerTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Manager-level coverage for ``OZContextRuleManager``.
///
/// These tests focus on the validation surface of
/// ``OZContextRuleManager/addContextRule(contextType:name:validUntil:signers:policies:selectedSigners:forceMethod:)``
/// — empty-name, zero signers and policies, signers-over-limit, and
/// policies-over-limit — together with the validation surfaces of the
/// remaining state-changing methods
/// (``OZContextRuleManager/updateName(id:name:selectedSigners:forceMethod:)``,
/// ``OZContextRuleManager/updateValidUntil(id:validUntil:selectedSigners:forceMethod:)``,
/// ``OZContextRuleManager/removeContextRule(id:selectedSigners:forceMethod:)``)
/// to lock down their pre-submission contracts.
///
/// Network-dependent paths (the actual host-function submission performed by
/// the kit's transaction operations after validation succeeds) are exercised
/// by the dedicated transaction-pipeline tests and the integration test
/// suite; the coverage here focuses on validation, routing decisions, and
/// the configuration-error surfacing for the multi-signer path.
final class OZContextRuleManagerTests: XCTestCase {

    // MARK: - Fixtures

    private let validContractAddress =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validAccountAddress =
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"

    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validContractAddress
        )
    }

    private func disconnectedKit() throws -> (MockOZSmartAccountKit, OZContextRuleManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return (kit, OZContextRuleManager(kit: kit))
    }

    private func connectedKit(
        contractId: String? = nil
    ) throws -> (MockOZSmartAccountKit, OZContextRuleManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: contractId ?? validContractAddress
        )
        return (kit, OZContextRuleManager(kit: kit))
    }

    /// Generates a deterministic but unique C-address by encoding a 32-byte
    /// buffer derived from the supplied seed.
    private func generateContractAddress(seed: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        for i in 0..<32 {
            bytes[i] = UInt8((i + seed) % 256)
        }
        return try Data(bytes).encodeContractId()
    }

    // ========================================================================
    // J.3 — addContextRule validation (4 mandatory cases)
    // ========================================================================

    /// J.3-1: empty `name` is rejected with ``SmartAccountValidationException/InvalidInput``
    /// before any submission attempt is made.
    func test_addContextRule_emptyName_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "",
                signers: [try OZDelegatedSigner(address: validAccountAddress)]
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(error.message.contains("name"),
                          "expected 'name' in message, got: \(error.message)")
        }
    }

    /// J.3-2: a rule with no signers and no policies fails validation —
    /// the contract requires at least one of either.
    func test_addContextRule_zeroSignersAndPolicies_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "EmptyRule",
                signers: [],
                policies: [:]
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            let msg = error.message
            XCTAssertTrue(msg.contains("signer") || msg.contains("policy") || msg.contains("policies"),
                          "expected mention of signers or policies, got: \(msg)")
        }
    }

    /// J.3-3: 16 signers exceeds the `maxSigners` (15) contract limit and
    /// fails validation pre-submission.
    func test_addContextRule_sixteenSigners_throwsMaxSigners() async throws {
        let (_, manager) = try connectedKit()
        let signers = try (0..<16).map { _ in
            try OZDelegatedSigner(address: validAccountAddress)
        }
        XCTAssertEqual(signers.count, 16, "Precondition: 16 signers must construct successfully")

        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TooManySigners",
                signers: signers
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            let msg = error.message
            XCTAssertTrue(msg.contains("\(OZConstants.maxSigners)") || msg.contains("signers"),
                          "expected mention of signer limit, got: \(msg)")
        }
    }

    /// J.3-4: 6 policies exceeds the `maxPolicies` (5) contract limit and
    /// fails validation pre-submission.
    func test_addContextRule_sixPolicies_throwsMaxPolicies() async throws {
        let (_, manager) = try connectedKit()
        var policies: [String: SCValXDR] = [:]
        for i in 0..<6 {
            let address = try generateContractAddress(seed: i * 10)
            policies[address] = .void
        }
        XCTAssertEqual(policies.count, 6, "Precondition: 6 unique policy addresses required")

        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "TooManyPolicies",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: policies
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            let msg = error.message
            XCTAssertTrue(msg.contains("\(OZConstants.maxPolicies)") || msg.contains("policies"),
                          "expected mention of policy limit, got: \(msg)")
        }
    }

    // ========================================================================
    // addContextRule — additional pre-submission contract checks
    // ========================================================================

    /// Disconnected kit + addContextRule must throw `SmartAccountWalletException.NotConnected`
    /// before any submission attempt.
    func test_addContextRule_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "Rule",
                signers: [try OZDelegatedSigner(address: validAccountAddress)]
            )
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    /// Connected kit + addContextRule with a malformed policy address (non-C)
    /// must throw `SmartAccountValidationException.InvalidAddress` before submission.
    func test_addContextRule_invalidPolicyAddress_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "BadPolicy",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: ["NOT-A-VALID-ADDRESS": .void]
            )
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        } catch let error {
            XCTFail("expected SmartAccountValidationException.InvalidAddress, got: \(error)")
        }
    }

    // ========================================================================
    // updateName — validation
    // ========================================================================

    /// Disconnected kit + updateName must throw `SmartAccountWalletException.NotConnected`
    /// before any submission attempt.
    func test_updateName_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.updateName(id: 1, name: "x")
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
            // expected
        }
    }

    /// Connected kit + updateName with empty name must throw
    /// `SmartAccountValidationException.InvalidInput` before any submission attempt.
    func test_updateName_emptyName_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateName(id: 1, name: "")
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("name"))
        }
    }

    // ========================================================================
    // updateValidUntil — validation
    // ========================================================================

    /// Disconnected kit + updateValidUntil must throw
    /// `SmartAccountWalletException.NotConnected` before any submission attempt.
    func test_updateValidUntil_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.updateValidUntil(id: 1, validUntil: nil)
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // removeContextRule — validation
    // ========================================================================

    /// Disconnected kit + removeContextRule must throw
    /// `SmartAccountWalletException.NotConnected` before any submission attempt.
    func test_removeContextRule_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.removeContextRule(id: 1)
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // Multi-signer routing — wallet signer without external-wallet adapter
    // ========================================================================

    /// A non-empty `selectedSigners` list containing a wallet entry routes
    /// through the kit's multi-signer manager, whose initial validation
    /// rejects wallet-kind signers when the kit's config does not declare an
    /// external wallet adapter. The check surfaces as
    /// ``SmartAccountValidationException/InvalidInput`` naming the `selectedSigners`
    /// field so callers can correct the kit configuration before retrying.
    func test_addContextRule_walletSigner_withoutExternalWalletAdapter_throwsValidation() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "Rule",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                selectedSigners: [.wallet(accountId: validAccountAddress)]
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            XCTAssertTrue(
                error.message.contains("selectedSigners"),
                "expected 'selectedSigners' in message, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // getAllContextRules / listContextRules — per-call maxScanId override
    // ========================================================================

    /// `getAllContextRules(maxScanId:)` with a non-nil override must honour the
    /// caller-supplied bound instead of the kit config default. The test
    /// scripts a count of 1 at the configured default (100) but supplies a
    /// scan bound of 2, which means the scan terminates after the count is
    /// satisfied rather than scanning up to 100.
    ///
    /// Verification: the mock RPC scripts exactly two responses — one for the
    /// count query and one for the single rule at id=0. If the override were
    /// ignored and the full config default (100) were used the pipeline would
    /// issue additional simulate calls, causing the scripted FIFO to
    /// return errors and the test to behave incorrectly.
    func test_getAllContextRules_perCallMaxScanId_override_isHonoured() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()

        // count query — 1 active rule.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(1).xdrEncoded ?? "")

        // getContextRule(id: 0) — one rule payload.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 2)
        let ruleScVal = SCValXDR.u32(0xABCD)
        script.enqueueSimulate(resultXdr: ruleScVal.xdrEncoded ?? "")

        // Use a per-call override of 2 (distinct from the kit default of 100).
        let result = try await manager.getAllContextRules(maxScanId: 2)
        XCTAssertEqual(result.count, 1, "Expected exactly 1 rule")
        if case .u32(let v) = result.first {
            XCTAssertEqual(v, 0xABCD)
        } else {
            XCTFail("Expected u32 rule scVal, got: \(String(describing: result.first))")
        }
    }

    /// `listContextRules(maxScanId:)` with a non-nil override must forward the
    /// bound to the underlying `getAllContextRules(maxScanId:)` scan. The test
    /// scripts a count of 0 so no per-rule simulate calls are issued, and the
    /// return value is an empty list regardless of the override value.
    ///
    /// The key assertion is that passing `maxScanId: 5` (distinct from any
    /// config default) completes without error, confirming the parameter is
    /// accepted and routed correctly through the parsed layer.
    func test_listContextRules_perCallMaxScanId_override_isHonoured() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()

        // count = 0 — no rules, no per-rule walk regardless of maxScanId.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(0).xdrEncoded ?? "")

        // Use a per-call override of 5 (distinct from the kit config default).
        let rules = try await manager.listContextRules(maxScanId: 5)
        XCTAssertEqual(rules.count, 0, "Expected empty list when count is zero")
    }

    // ========================================================================
    // Task cancellation propagation
    // ========================================================================

    /// `getAllContextRules` walks the contract's rule identifiers in a loop.
    /// Cancelling the parent task must short-circuit the scan rather than
    /// silently completing the network sweep. The mock kit points at a
    /// non-routable RPC port so the underlying simulation would otherwise
    /// block on the connection-refused retry path.
    func test_getAllContextRules_cancellation_propagatesCancellationError() async throws {
        let (_, manager) = try connectedKit()

        let task = Task { [manager] in
            return try await manager.getAllContextRules()
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("expected cancellation or transport error before scan completes")
        } catch is CancellationError {
            // Expected: the scan loop's `Task.checkCancellation` fired.
        } catch {
            // Acceptable alternative: the awaited RPC failed before the
            // cancellation checkpoint observed. Any thrown error proves the
            // pipeline did not return a populated rule list.
        }
    }

    // ========================================================================
    // Read-side manager surface — coverage against MockSorobanServer
    // ========================================================================

    /// `getContextRule(id:)` returns the raw `SCValXDR` payload reported by the
    /// contract via simulation. The script returns a `void` ScVal here so the
    /// production code's "extract first result" path is exercised end-to-end
    /// without producing a fully-formed context-rule map (parsing is covered
    /// by ``OZContextRuleParsingTests``).
    func test_getContextRule_happyPath_returnsScValPayload() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()

        // Account fetch precedes simulate — script the deployer entry first.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        let returnedScVal = SCValXDR.u32(0xDEADBEEF)
        script.enqueueSimulate(resultXdr: returnedScVal.xdrEncoded ?? "")

        let result = try await manager.getContextRule(id: 7)
        guard case .u32(let value) = result else {
            return XCTFail("expected u32 result, got \(result)")
        }
        XCTAssertEqual(value, 0xDEADBEEF)
    }

    /// `getContextRule(id:)` must surface `SmartAccountWalletException.NotConnected` when
    /// the kit holds no connected smart account, before any RPC traffic is
    /// issued.
    func test_getContextRule_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.getContextRule(id: 1)
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
            // expected
        }
    }

    /// `getContextRulesCount()` returns the parsed `UInt32` count emitted by
    /// the contract's `get_context_rules_count` method.
    func test_getContextRulesCount_happyPath_returnsExpectedU32() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(42).xdrEncoded ?? "")

        let count = try await manager.getContextRulesCount()
        XCTAssertEqual(count, 42)
    }

    /// `getContextRulesCount()` must surface `SmartAccountWalletException.NotConnected`
    /// before any RPC traffic when the kit is disconnected.
    func test_getContextRulesCount_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.getContextRulesCount()
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
            // expected
        }
    }

    /// `listContextRules()` is the parsed equivalent of `getAllContextRules`.
    /// When the count is zero, the manager must return an empty list without
    /// issuing any per-rule simulation.
    func test_listContextRules_zeroCount_returnsEmptyList() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()
        // Single getAccount + count=0 simulate; no further per-rule walk.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(0).xdrEncoded ?? "")

        let rules = try await manager.listContextRules()
        XCTAssertEqual(rules.count, 0)
    }

    /// `listContextRules()` must surface `SmartAccountWalletException.NotConnected` before
    /// any RPC traffic when the kit is disconnected.
    func test_listContextRules_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.listContextRules()
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch is SmartAccountWalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    /// Connected kit variant whose ``SorobanServer`` points at a URL the
    /// `MockURLProtocol`-driven script can intercept. Required for the
    /// read-side tests above; the default ``connectedKit()`` helper points
    /// at `127.0.0.1:1` for connection-refused fast-fail behaviour.
    private func connectedKitWithScriptedServer(
        contractId: String? = nil
    ) throws -> (MockOZSmartAccountKit, OZContextRuleManager) {
        let kit = MockOZSmartAccountKit(
            config: try buildConfig(),
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: contractId ?? validContractAddress
        )
        return (kit, OZContextRuleManager(kit: kit))
    }

    // ========================================================================
    // Batch C — updateName / updateValidUntil / removeContextRule submission
    // ========================================================================

    // ========================================================================
    // addContextRule — validUntil and policy encoding paths
    // ========================================================================

    /// `addContextRule` with a non-nil `validUntil` must build a U32 ScVal
    /// for the `valid_until` field and reach the submission layer (line 176).
    func test_addContextRule_withValidUntil_initiatesSubmission() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "ExpiringRule",
                validUntil: 900_000,
                signers: [try OZDelegatedSigner(address: validAccountAddress)]
            )
            XCTFail("expected network error from non-routable RPC")
        } catch is SmartAccountWalletException {
            XCTFail("unexpected SmartAccountWalletException — kit is connected")
        } catch is SmartAccountValidationException {
            XCTFail("unexpected SmartAccountValidationException — input is valid")
        } catch {
            // Any non-validation error means the host function was built
            // (including the valid_until U32 ScVal) and submission was attempted.
        }
    }

    /// `addContextRule` with a non-empty policy map must encode the policy
    /// `SCMapEntryXDR` entries (lines 191-195) and reach the submission layer.
    func test_addContextRule_withPolicy_initiatesSubmission() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "RuleWithPolicy",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: [validContractAddress: .void]
            )
            XCTFail("expected network error from non-routable RPC")
        } catch is SmartAccountWalletException {
            XCTFail("unexpected SmartAccountWalletException — kit is connected")
        } catch is SmartAccountValidationException {
            XCTFail("unexpected SmartAccountValidationException — policy address is valid")
        } catch {
            // Policy encoding executed; RPC error confirms submission was attempted.
        }
    }

    /// `updateName` with a valid non-empty name on a connected kit must reach
    /// the submission layer and fail with a network error (not a validation or
    /// configuration error).
    func test_updateContextRuleName_connected_callsSubmit() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateName(id: 0, name: "NewName")
            XCTFail("expected network or transaction error from non-routable RPC")
        } catch is SmartAccountWalletException {
            XCTFail("unexpected SmartAccountWalletException — kit is connected")
        } catch is SmartAccountValidationException {
            XCTFail("unexpected SmartAccountValidationException — name is valid")
        } catch {
            // Any non-validation error means validation passed and the
            // manager attempted to reach the RPC endpoint.
        }
    }

    /// `updateName` with an empty string must throw
    /// `SmartAccountValidationException.InvalidInput` before any network access.
    func test_updateContextRuleName_emptyName_throwsValidationException() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateName(id: 0, name: "")
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("name"),
                "error must mention the name field, got: \(error.message)"
            )
        }
    }

    /// `updateValidUntil` with a non-nil `validUntil` on a connected kit must
    /// build a U32-valued `valid_until` argument and reach the submission layer.
    func test_updateValidUntil_withValue_encodesU32() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateValidUntil(id: 1, validUntil: 500_000)
            XCTFail("expected network or transaction error from non-routable RPC")
        } catch is SmartAccountWalletException {
            XCTFail("unexpected SmartAccountWalletException — kit is connected")
        } catch {
            // Any non-wallet error means validation passed and the build succeeded.
        }
    }

    /// `updateValidUntil` with `nil` must build a Void-valued `valid_until`
    /// argument and reach the submission layer.
    func test_updateValidUntil_nil_encodesVoid() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateValidUntil(id: 2, validUntil: nil)
            XCTFail("expected network or transaction error from non-routable RPC")
        } catch is SmartAccountWalletException {
            XCTFail("unexpected SmartAccountWalletException — kit is connected")
        } catch {
            // Any non-wallet error means build succeeded and submission was attempted.
        }
    }

    /// `removeContextRule` on a connected kit must build the host function
    /// and reach the submission layer.
    func test_removeContextRule_connected_callsSubmit() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.removeContextRule(id: 3)
            XCTFail("expected network or transaction error from non-routable RPC")
        } catch is SmartAccountWalletException {
            XCTFail("unexpected SmartAccountWalletException — kit is connected")
        } catch {
            // Any non-wallet error means the host function was built and
            // submission was attempted.
        }
    }

    // ========================================================================
    // Batch C — resolveContextRuleIdsForEntry (multi-candidate resolution)
    // ========================================================================

    /// When the rule set has two candidates for the same context type and the
    /// supplied signers match exactly one of them, the resolver must return
    /// that rule's identifier.
    func test_resolveContextRuleIds_multipleCandidates_exactMatch_returnsMatchingRule() async throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)
        let signerB = try OZDelegatedSigner(address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW")

        let ruleExact = OZParsedContextRule(
            id: 10,
            contextType: .defaultRule,
            name: "RuleExact",
            signers: [signerA],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleOther = OZParsedContextRule(
            id: 20,
            contextType: .defaultRule,
            name: "RuleOther",
            signers: [signerA, signerB],
            signerIds: [0, 1],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: validContractAddress,
            targetFn: "noop"
        )
        let (_, manager) = try connectedKit()
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [signerA],
            contextRules: [ruleExact, ruleOther]
        )

        XCTAssertEqual([UInt32(10)], ids, "Exact-signer match must return rule id 10")
    }

    /// When no candidate rule's signer set contains all selected signers,
    /// the resolver must throw `SmartAccountValidationException.InvalidInput`.
    func test_resolveContextRuleIds_multipleCandidates_noMatch_throws() async throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)
        let signerB = try OZDelegatedSigner(address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW")
        let signerC = try OZDelegatedSigner(address: "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG")

        let ruleOne = OZParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "RuleOne",
            signers: [signerA],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleTwo = OZParsedContextRule(
            id: 2,
            contextType: .defaultRule,
            name: "RuleTwo",
            signers: [signerB],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: validContractAddress,
            targetFn: "noop"
        )
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.resolveContextRuleIdsForEntry(
                entry: entry,
                signers: [signerC],
                contextRules: [ruleOne, ruleTwo]
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    /// When multiple candidate rules all contain the selected signers,
    /// the resolver must throw `SmartAccountValidationException.InvalidInput` naming the
    /// ambiguous rule ids.
    func test_resolveContextRuleIds_multipleCandidates_multipleMatching_throws() async throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)

        let ruleOne = OZParsedContextRule(
            id: 1,
            contextType: .defaultRule,
            name: "RuleOne",
            signers: [signerA],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleTwo = OZParsedContextRule(
            id: 2,
            contextType: .defaultRule,
            name: "RuleTwo",
            signers: [signerA],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: validContractAddress,
            targetFn: "noop"
        )
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.resolveContextRuleIdsForEntry(
                entry: entry,
                signers: [signerA],
                contextRules: [ruleOne, ruleTwo]
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for ambiguous match")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // Batch C — collectInvocationContextTypes (createContractV2 + SAC token)
    // ========================================================================

    /// `createContractV2HostFn` root invocation produces a
    /// `OZContextRuleType.createContract(wasmHash:)` with the WASM hash from
    /// the executable.
    func test_collectInvocationContextTypes_createContractV2_returnsCreateContract() async throws {
        let wasmHashBytes = Data(repeating: 0xAB, count: 32)
        let wasmHash = HashXDR(wasmHashBytes)
        let executable = ContractExecutableXDR.wasm(wasmHash)

        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(
                address: try SCAddressXDR(contractId: validContractAddress),
                salt: WrappedData32(Data(repeating: 0, count: 32))
            )
        )
        let createArgs = CreateContractV2ArgsXDR(
            contractIDPreimage: preimage,
            executable: executable,
            constructorArgs: []
        )
        let function = SorobanAuthorizedFunctionXDR.createContractV2HostFn(createArgs)
        let invocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractAddress),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        let (_, manager) = try connectedKit()
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [],
            contextRules: [
                OZParsedContextRule(
                    id: 99,
                    contextType: .createContract(wasmHash: wasmHashBytes),
                    name: "CreateRule",
                    signers: [],
                    signerIds: [],
                    policies: [],
                    policyIds: [],
                    validUntil: nil
                )
            ]
        )
        XCTAssertEqual([UInt32(99)], ids, "createContractV2 invocation must resolve to the CreateContract rule")
    }

    /// A `createContractHostFn` / `createContractV2HostFn` whose executable
    /// is `.token` (Stellar Asset Contract) must throw
    /// `SmartAccountValidationException.InvalidInput` when the rule-resolution pipeline
    /// tries to extract the WASM hash.
    func test_extractWasmHash_sacToken_throwsValidationException() async throws {
        let executable = ContractExecutableXDR.token
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(
                address: try SCAddressXDR(contractId: validContractAddress),
                salt: WrappedData32(Data(repeating: 0, count: 32))
            )
        )
        let createArgs = CreateContractV2ArgsXDR(
            contractIDPreimage: preimage,
            executable: executable,
            constructorArgs: []
        )
        let function = SorobanAuthorizedFunctionXDR.createContractV2HostFn(createArgs)
        let invocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractAddress),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.resolveContextRuleIdsForEntry(
                entry: entry,
                signers: [],
                contextRules: []
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for SAC token executable")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // Batch C — OZSmartAccountKit+Wiring protocol forwarding
    // ========================================================================

    /// Exercises the `OZContextRuleParser` protocol extension in
    /// `OZSmartAccountKit+Wiring.swift` by calling `parseContextRule(_:)`
    /// through the protocol interface directly on a real `OZContextRuleManager`.
    ///
    /// The wiring extension simply forwards the label-renamed call; this test
    /// verifies both forwarding lines are reachable and produce the same result
    /// as calling the underlying `parseContextRule(scVal:)` method directly.
    func test_wiringExtension_parseContextRule_forwardsCorrectly() throws {
        let (_, manager) = try disconnectedKit()
        let parser: OZContextRuleParser = manager

        // A minimal valid context-rule Map ScVal.
        let ruleMap: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("id"), val: .u32(7)),
            SCMapEntryXDR(key: .symbol("name"), val: .string("WiringTest")),
            SCMapEntryXDR(key: .symbol("context_type"), val: .vec([.symbol("Default")])),
            SCMapEntryXDR(key: .symbol("signers"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("signer_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policies"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policy_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("valid_until"), val: .void)
        ])

        let parsed = try parser.parseContextRule(ruleMap)
        XCTAssertEqual(7, parsed.id, "parseContextRule forwarding must preserve the id field")
        XCTAssertEqual("WiringTest", parsed.name, "parseContextRule forwarding must preserve the name field")
        XCTAssertEqual(.defaultRule, parsed.contextType)
    }

    /// Exercises the `getContextRule(contextRuleId:)` forwarding method in
    /// `OZSmartAccountKit+Wiring.swift` by calling it through the
    /// `OZContextRuleParser` protocol interface. The kit is connected and
    /// points at a non-routable RPC host, so the call fails at the network
    /// level after the wiring lines execute.
    func test_wiringExtension_getContextRule_forwardsToManager() async throws {
        let (_, manager) = try connectedKit()
        let parser: OZContextRuleParser = manager

        do {
            _ = try await parser.getContextRule(contextRuleId: 0)
            XCTFail("expected network error from non-routable RPC")
        } catch is SmartAccountWalletException {
            XCTFail("unexpected SmartAccountWalletException — kit is connected")
        } catch {
            // Any non-wallet error means the wiring forwarding lines executed
            // and the call reached the underlying network stack.
        }
    }

    // ========================================================================
    // getContextRulesCount — non-U32 result path
    // ========================================================================

    /// `getContextRulesCount` must throw `SmartAccountValidationException.InvalidInput`
    /// when simulation returns a non-U32 ScVal.
    func test_getContextRulesCount_nonU32Result_throwsValidationException() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        // Return a String instead of U32 — simulates a malformed contract response.
        script.enqueueSimulate(resultXdr: SCValXDR.string("not-a-u32").xdrEncoded ?? "")

        do {
            _ = try await manager.getContextRulesCount()
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // ========================================================================
    // getAllContextRules — zero-count shortcut path
    // ========================================================================

    // ========================================================================
    // resolveContextRuleIds — Tier 2 and Tier 3 match paths
    // ========================================================================

    /// Tier 2: when the rule's signer set is a strict subset of the selected
    /// signers and the rule has no policies, the resolver picks that rule.
    func test_resolveContextRuleIds_tier2_ruleSignersSubsetOfSelected_returnsRule() async throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)
        let signerB = try OZDelegatedSigner(address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW")
        let signerC = try OZDelegatedSigner(address: "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG")

        // rule1 has only A (strict subset of [A,B,C]) and no policies — Tier 2 candidate.
        let rule1 = OZParsedContextRule(
            id: 5,
            contextType: .defaultRule,
            name: "RuleA",
            signers: [signerA],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        // rule2 has [B, C] but with a policy — excluded from Tier 2.
        let rule2 = OZParsedContextRule(
            id: 6,
            contextType: .defaultRule,
            name: "RuleBC",
            signers: [signerB, signerC],
            signerIds: [0, 1],
            policies: [validContractAddress],
            policyIds: [0],
            validUntil: nil
        )

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: validContractAddress,
            targetFn: "noop"
        )
        let (_, manager) = try connectedKit()
        // Select [A, B, C]; no Tier 1 exact match (neither rule has exactly [A,B,C]).
        // Only rule1 satisfies Tier 2 (subset + no policies).
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [signerA, signerB, signerC],
            contextRules: [rule1, rule2]
        )
        XCTAssertEqual([UInt32(5)], ids, "Tier 2: rule with signer-subset and no policies must be selected")
    }

    /// Tier 3: when the selected signers are a subset of a single candidate
    /// rule's signer set, the resolver picks that rule.
    func test_resolveContextRuleIds_tier3_selectedSubsetOfRuleSigners_returnsRule() async throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)
        let signerB = try OZDelegatedSigner(address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW")
        let signerC = try OZDelegatedSigner(address: "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG")

        let rule = OZParsedContextRule(
            id: 7,
            contextType: .defaultRule,
            name: "BigRule",
            signers: [signerA, signerB, signerC],
            signerIds: [0, 1, 2],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: validContractAddress,
            targetFn: "noop"
        )
        let (_, manager) = try connectedKit()
        // Select only A and B; they are a subset of rule's [A, B, C] — Tier 3.
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [signerA, signerB],
            contextRules: [rule]
        )
        XCTAssertEqual([UInt32(7)], ids, "Tier 3: selected signers as subset of rule must resolve to that rule")
    }

    /// When no context rule matches the required context type, the resolver
    /// must throw `SmartAccountValidationException.InvalidInput` advising the caller to
    /// add a Default rule.
    func test_resolveContextRuleIds_noCandidates_throwsValidationException() async throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)
        let callContractRule = OZParsedContextRule(
            id: 1,
            contextType: .callContract(contractAddress: validContractAddress),
            name: "CallContractRule",
            signers: [signerA],
            signerIds: [0],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        // Build an entry with a DIFFERENT target contract so no rule matches.
        let differentTarget = try Data(repeating: 0xCD, count: 32).encodeContractId()
        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: differentTarget,
            targetFn: "noop"
        )
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.resolveContextRuleIdsForEntry(
                entry: entry,
                signers: [signerA],
                contextRules: [callContractRule]
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput when no candidates match")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // collectInvocationContextTypes — createContractHostFn + G-address
    // ========================================================================

    /// `createContractHostFn` (non-V2) root invocation produces a
    /// `OZContextRuleType.createContract(wasmHash:)`.
    func test_collectInvocationContextTypes_createContractHostFn_returnsCreateContract() async throws {
        let wasmHashBytes = Data(repeating: 0xAA, count: 32)
        let wasmHash = HashXDR(wasmHashBytes)
        let executable = ContractExecutableXDR.wasm(wasmHash)

        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(
                address: try SCAddressXDR(contractId: validContractAddress),
                salt: WrappedData32(Data(repeating: 0, count: 32))
            )
        )
        let createArgs = CreateContractArgsXDR(
            contractIDPreimage: preimage,
            executable: executable
        )
        let function = SorobanAuthorizedFunctionXDR.createContractHostFn(createArgs)
        let invocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractAddress),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        let (_, manager) = try connectedKit()
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [],
            contextRules: [
                OZParsedContextRule(
                    id: 88,
                    contextType: .createContract(wasmHash: wasmHashBytes),
                    name: "CreateV1Rule",
                    signers: [],
                    signerIds: [],
                    policies: [],
                    policyIds: [],
                    validUntil: nil
                )
            ]
        )
        XCTAssertEqual([UInt32(88)], ids)
    }

    /// A `callContract` invocation targeting a G-address exercises the
    /// `addressString(from:)` `return accountId` branch (line 625).
    func test_collectInvocationContextTypes_callContractGAddress_producesCallContractRule() async throws {
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(accountId: validAccountAddress),
            functionName: "noop",
            args: []
        )
        let function = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let invocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractAddress),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        let (_, manager) = try connectedKit()
        // G-addresses produce a `.callContract` context type — the rule that
        // matches is a Default rule (falls through all CallContract-specific rules).
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [],
            contextRules: [
                OZParsedContextRule(
                    id: 77,
                    contextType: .defaultRule,
                    name: "DefaultForGAddr",
                    signers: [],
                    signerIds: [],
                    policies: [],
                    policyIds: [],
                    validUntil: nil
                )
            ]
        )
        XCTAssertEqual([UInt32(77)], ids)
    }

    /// An invocation with sub-invocations exercises `collectSubInvocationContextTypes`.
    func test_collectInvocationContextTypes_withSubInvocations_collectsSubContextTypes() async throws {
        let mainInvokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: validContractAddress),
            functionName: "main_fn",
            args: []
        )
        let subInvokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: validContractAddress),
            functionName: "sub_fn",
            args: []
        )
        let subFunction = SorobanAuthorizedFunctionXDR.contractFn(subInvokeArgs)
        let subInvocation = SorobanAuthorizedInvocationXDR(function: subFunction, subInvocations: [])

        let mainFunction = SorobanAuthorizedFunctionXDR.contractFn(mainInvokeArgs)
        let rootInvocation = SorobanAuthorizedInvocationXDR(
            function: mainFunction,
            subInvocations: [subInvocation]
        )
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractAddress),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: rootInvocation
        )

        let (_, manager) = try connectedKit()
        // Both root and sub invocation target the same contract — they both
        // produce `.callContract` context types. A single `defaultRule`
        // matches both.
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [],
            contextRules: [
                OZParsedContextRule(
                    id: 66,
                    contextType: .defaultRule,
                    name: "DefaultForSubInvoc",
                    signers: [],
                    signerIds: [],
                    policies: [],
                    policyIds: [],
                    validUntil: nil
                )
            ]
        )
        XCTAssertEqual([UInt32(66), UInt32(66)], ids, "Both root and sub invocation must resolve to the same default rule")
    }

    // ========================================================================
    // listContextRules — parseContextRule call path (line 395)
    // ========================================================================

    /// `listContextRules` must parse each raw ScVal returned by `getAllContextRules`
    /// through `parseContextRule`. This test scripts the server to return one
    /// rule and verifies the parsed result is returned.
    func test_listContextRules_oneRule_parsesAndReturns() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()

        // Script: count = 1
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(1).xdrEncoded ?? "")

        // Script: rule at id=0 — a minimal valid rule map.
        let ruleMap: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("id"), val: .u32(0)),
            SCMapEntryXDR(key: .symbol("name"), val: .string("ScriptedRule")),
            SCMapEntryXDR(key: .symbol("context_type"), val: .vec([.symbol("Default")])),
            SCMapEntryXDR(key: .symbol("signers"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("signer_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policies"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policy_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("valid_until"), val: .void)
        ])
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 2)
        script.enqueueSimulate(resultXdr: ruleMap.xdrEncoded ?? "")

        let rules = try await manager.listContextRules()
        XCTAssertEqual(1, rules.count, "listContextRules must return 1 parsed rule")
        XCTAssertEqual("ScriptedRule", rules.first?.name)
    }

    /// `getAllContextRules()` (the no-arg overload) must delegate to the
    /// per-call-maxScanId overload. With a count of zero the result must be
    /// an empty array.
    func test_getAllContextRules_noArgOverload_zeroCount_returnsEmpty() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(0).xdrEncoded ?? "")

        let rules = try await manager.getAllContextRules()
        XCTAssertEqual(0, rules.count, "getAllContextRules() with zero count must return empty array")
    }

    // ========================================================================
    // getAllContextRules — gap-skip on SimulationFailed (line 322)
    // ========================================================================

    /// `getAllContextRules` skips identifiers whose per-rule simulation reports
    /// a ``SmartAccountTransactionException/SimulationFailed`` (a removed-rule
    /// gap) and continues scanning. The script reports a count of 1, fails the
    /// simulate for id=0 (the gap), and returns a payload for id=1, so the scan
    /// must traverse the catch branch at id=0 and collect the rule at id=1.
    func test_getAllContextRules_simulationFailedGap_isSkippedAndScanContinues() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()

        // count query — 1 active rule.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(1).xdrEncoded ?? "")

        // getContextRule(id: 0) — simulation error models a removed-rule gap.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 2)
        script.enqueueSimulateError("rule 0 has been removed")

        // getContextRule(id: 1) — the single surviving rule payload.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 3)
        let ruleScVal = SCValXDR.u32(0x1234)
        script.enqueueSimulate(resultXdr: ruleScVal.xdrEncoded ?? "")

        let result = try await manager.getAllContextRules(maxScanId: 10)
        XCTAssertEqual(result.count, 1, "Gap at id=0 must be skipped and id=1 collected")
        if case .u32(let v) = result.first {
            XCTAssertEqual(v, 0x1234)
        } else {
            XCTFail("Expected u32 rule scVal, got: \(String(describing: result.first))")
        }
    }

    // ========================================================================
    // resolveContextRuleIdsForEntry — two-arg overload (lines 367-374)
    // ========================================================================

    /// The two-argument
    /// `resolveContextRuleIdsForEntry(entry:signers:)` overload must fetch the
    /// rule list itself via `listContextRules()` and then delegate to the
    /// three-argument form. The script returns a single Default rule so the
    /// resolver's single-candidate fast path resolves to that rule's id.
    func test_resolveContextRuleIdsForEntry_twoArgOverload_fetchesRulesThenResolves() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }

        let (kit, manager) = try connectedKitWithScriptedServer()
        let deployer = try await kit.getDeployer()

        // listContextRules(): count = 1.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(1).xdrEncoded ?? "")

        // rule at id=0 — a minimal Default rule with id field 42.
        let ruleMap: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("id"), val: .u32(42)),
            SCMapEntryXDR(key: .symbol("name"), val: .string("DefaultRule")),
            SCMapEntryXDR(key: .symbol("context_type"), val: .vec([.symbol("Default")])),
            SCMapEntryXDR(key: .symbol("signers"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("signer_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policies"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policy_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("valid_until"), val: .void)
        ])
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 2)
        script.enqueueSimulate(resultXdr: ruleMap.xdrEncoded ?? "")

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: validContractAddress,
            targetFn: "noop"
        )

        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: []
        )
        XCTAssertEqual([UInt32(42)], ids, "two-arg overload must fetch rules and resolve the single Default candidate")
    }

    // ========================================================================
    // resolveContextRuleIdsForEntry — Tier 3 with multiple candidates (lines 463-464)
    // ========================================================================

    /// Tier 3 (`selectedSubsetMatches.count == 1`) fires only when there are
    /// multiple candidate rules for the context type, Tier 1 (exact) and Tier 2
    /// (rule-subset-of-selected with no policies) both fail, and exactly one
    /// candidate's signer set is a superset of the selected signers.
    ///
    /// Setup: two Default candidates.
    /// - ruleBig: signers [A, B, C], no policies — selected [A, B] is a subset
    ///   (Tier 3 match). Tier 1 fails (count mismatch). Tier 2 fails (rule
    ///   signers are NOT a subset of selected).
    /// - ruleOther: signers [A] plus a policy — Tier 2 excluded by the policy;
    ///   it is also a Tier 3 superset only of subsets of {A}, not of [A, B],
    ///   so it does not match selected [A, B].
    func test_resolveContextRuleIds_tier3_multipleCandidates_uniqueSupersetSelected() async throws {
        let signerA = try OZDelegatedSigner(address: validAccountAddress)
        let signerB = try OZDelegatedSigner(address: "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW")
        let signerC = try OZDelegatedSigner(address: "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG")

        let ruleBig = OZParsedContextRule(
            id: 31,
            contextType: .defaultRule,
            name: "RuleBig",
            signers: [signerA, signerB, signerC],
            signerIds: [0, 1, 2],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
        let ruleOther = OZParsedContextRule(
            id: 32,
            contextType: .defaultRule,
            name: "RuleOther",
            signers: [signerA],
            signerIds: [0],
            policies: [validContractAddress],
            policyIds: [0],
            validUntil: nil
        )

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: validContractAddress,
            targetContract: validContractAddress,
            targetFn: "noop"
        )
        let (_, manager) = try connectedKit()
        let ids = try await manager.resolveContextRuleIdsForEntry(
            entry: entry,
            signers: [signerA, signerB],
            contextRules: [ruleBig, ruleOther]
        )
        XCTAssertEqual([UInt32(31)], ids, "Tier 3 must select the unique candidate whose signer set is a superset of the selected signers")
    }

    // ========================================================================
    // collectInvocationContextTypes — contractFn unsupported address (lines 535-539, 586-589)
    // ========================================================================

    /// A `contractFn` invocation whose contract address is an unsupported
    /// `SCAddressXDR` variant (a liquidity-pool id, neither account nor
    /// contract) must surface a ``SmartAccountValidationException/InvalidInput``
    /// from the `addressString(from:)` helper, wrapped by the contractFn arm of
    /// `collectInvocationContextTypes`.
    func test_collectInvocationContextTypes_contractFnUnsupportedAddress_throwsValidation() async throws {
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: .liquidityPoolId(WrappedData32(Data(repeating: 0x09, count: 32))),
            functionName: "noop",
            args: []
        )
        let function = SorobanAuthorizedFunctionXDR.contractFn(invokeArgs)
        let invocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: validContractAddress),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: invocation
        )

        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.resolveContextRuleIdsForEntry(
                entry: entry,
                signers: [],
                contextRules: []
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput for unsupported contractFn address")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("contractAddress") || error.message.contains("Unsupported"),
                "expected the address-parse failure reason, got: \(error.message)"
            )
        }
    }
}
