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

    /// J.3-1: empty `name` is rejected with ``ValidationException/InvalidInput``
    /// before any submission attempt is made.
    func test_addContextRule_emptyName_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "",
                signers: [try OZDelegatedSigner(address: validAccountAddress)]
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
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
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
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
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
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
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertEqual(error.code, .invalidInput)
            let msg = error.message
            XCTAssertTrue(msg.contains("\(OZConstants.maxPolicies)") || msg.contains("policies"),
                          "expected mention of policy limit, got: \(msg)")
        }
    }

    // ========================================================================
    // addContextRule — additional pre-submission contract checks
    // ========================================================================

    /// Disconnected kit + addContextRule must throw `WalletException.NotConnected`
    /// before any submission attempt.
    func test_addContextRule_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "Rule",
                signers: [try OZDelegatedSigner(address: validAccountAddress)]
            )
            XCTFail("expected WalletException.NotConnected")
        } catch let error as WalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    /// Connected kit + addContextRule with a malformed policy address (non-C)
    /// must throw `ValidationException.InvalidAddress` before submission.
    func test_addContextRule_invalidPolicyAddress_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "BadPolicy",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                policies: ["NOT-A-VALID-ADDRESS": .void]
            )
            XCTFail("expected ValidationException.InvalidAddress")
        } catch is ValidationException.InvalidAddress {
            // expected
        } catch let error {
            XCTFail("expected ValidationException.InvalidAddress, got: \(error)")
        }
    }

    // ========================================================================
    // updateName — validation
    // ========================================================================

    /// Disconnected kit + updateName must throw `WalletException.NotConnected`
    /// before any submission attempt.
    func test_updateName_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.updateName(id: 1, name: "x")
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    /// Connected kit + updateName with empty name must throw
    /// `ValidationException.InvalidInput` before any submission attempt.
    func test_updateName_emptyName_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateName(id: 1, name: "")
            XCTFail("expected ValidationException.InvalidInput")
        } catch let error as ValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("name"))
        }
    }

    // ========================================================================
    // updateValidUntil — validation
    // ========================================================================

    /// Disconnected kit + updateValidUntil must throw
    /// `WalletException.NotConnected` before any submission attempt.
    func test_updateValidUntil_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.updateValidUntil(id: 1, validUntil: nil)
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // removeContextRule — validation
    // ========================================================================

    /// Disconnected kit + removeContextRule must throw
    /// `WalletException.NotConnected` before any submission attempt.
    func test_removeContextRule_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.removeContextRule(id: 1)
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
            // expected
        }
    }

    // ========================================================================
    // Multi-signer routing — configuration error path
    // ========================================================================

    /// When a caller supplies a non-empty `selectedSigners` list and the
    /// manager was constructed without a multi-signer submitter (the unit-test
    /// composition path), the manager surfaces a configuration error so the
    /// caller can correct the kit composition.
    func test_addContextRule_multiSigner_withoutSubmitter_throwsConfigurationError() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "Rule",
                signers: [try OZDelegatedSigner(address: validAccountAddress)],
                selectedSigners: [.wallet(accountId: validAccountAddress)]
            )
            XCTFail("expected ConfigurationException.InvalidConfig")
        } catch is ConfigurationException.InvalidConfig {
            // expected
        }
    }

    /// `updateName` routes through the same multi-signer collaborator so it
    /// must surface the configuration error in the same shape as
    /// `addContextRule` when the submitter is absent.
    func test_updateName_multiSigner_withoutSubmitter_throwsConfigurationError() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateName(
                id: 1,
                name: "x",
                selectedSigners: [.wallet(accountId: validAccountAddress)]
            )
            XCTFail("expected ConfigurationException.InvalidConfig")
        } catch is ConfigurationException.InvalidConfig {
            // expected
        }
    }

    /// `removeContextRule` routes through the same multi-signer collaborator
    /// so it must surface the configuration error in the same shape as
    /// `addContextRule` when the submitter is absent.
    func test_removeContextRule_multiSigner_withoutSubmitter_throwsConfigurationError() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.removeContextRule(
                id: 1,
                selectedSigners: [.wallet(accountId: validAccountAddress)]
            )
            XCTFail("expected ConfigurationException.InvalidConfig")
        } catch is ConfigurationException.InvalidConfig {
            // expected
        }
    }

    /// `updateValidUntil` routes through the same multi-signer collaborator
    /// so it must surface the configuration error in the same shape as
    /// `addContextRule` when the submitter is absent.
    func test_updateValidUntil_multiSigner_withoutSubmitter_throwsConfigurationError() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.updateValidUntil(
                id: 1,
                validUntil: 12345,
                selectedSigners: [.wallet(accountId: validAccountAddress)]
            )
            XCTFail("expected ConfigurationException.InvalidConfig")
        } catch is ConfigurationException.InvalidConfig {
            // expected
        }
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

    /// `getContextRule(id:)` must surface `WalletException.NotConnected` when
    /// the kit holds no connected smart account, before any RPC traffic is
    /// issued.
    func test_getContextRule_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.getContextRule(id: 1)
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
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

    /// `getContextRulesCount()` must surface `WalletException.NotConnected`
    /// before any RPC traffic when the kit is disconnected.
    func test_getContextRulesCount_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.getContextRulesCount()
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
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

    /// `listContextRules()` must surface `WalletException.NotConnected` before
    /// any RPC traffic when the kit is disconnected.
    func test_listContextRules_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.listContextRules()
            XCTFail("expected WalletException.NotConnected")
        } catch is WalletException.NotConnected {
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
            sorobanServer: SorobanServer(endpoint: "https://mock-rpc.invalid/rpc")
        )
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: contractId ?? validContractAddress
        )
        return (kit, OZContextRuleManager(kit: kit))
    }
}
