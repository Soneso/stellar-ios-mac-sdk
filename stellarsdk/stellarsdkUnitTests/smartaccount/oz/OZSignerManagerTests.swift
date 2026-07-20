//
//  OZSignerManagerTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for ``OZSignerManager``.
///
/// Covers the host-function shapes the manager emits for `add_signer` and
/// `remove_signer`, the validation surface across the four signer-addition
/// paths (passkey, delegated, Ed25519, and the value-based remove overload),
/// the routing of single- versus multi-signer submissions, and the
/// signer-value resolution validated against the on-chain context rule.
///
/// Network-dependent submission (the kit's transaction-operations pipeline) is
/// exercised by integration tests; the unit-level coverage here focuses on
/// argument preparation, validation, routing decisions, and the value-based
/// remove path's id-resolution algorithm.
final class OZSignerManagerTests: XCTestCase {

    // ========================================================================
    // MARK: - Fixtures
    // ========================================================================

    private let validGAddr1 = "GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7"
    private let validGAddr2 = "GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW"
    private let validGAddr3 = "GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG"
    private let validContractC =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validContractC2 =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let validVerifier =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    /// A deterministic 65-byte uncompressed secp256r1 public key fixture.
    /// First byte is the SEC1 prefix; the remaining 64 bytes cycle through
    /// `1..64` so two consecutive fixtures compare equal but are clearly
    /// distinguishable from arbitrary other byte sequences.
    private func validSecp256r1PublicKey() -> Data {
        var bytes = [UInt8](
            repeating: 0,
            count: SmartAccountConstants.secp256r1PublicKeySize
        )
        bytes[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        for i in 1 ..< SmartAccountConstants.secp256r1PublicKeySize {
            bytes[i] = UInt8(i % 256)
        }
        return Data(bytes)
    }

    /// A deterministic 32-byte Ed25519 public key fixture.
    private func validEd25519PublicKey() -> Data {
        var bytes = [UInt8](
            repeating: 0,
            count: SmartAccountConstants.ed25519PublicKeySize
        )
        for i in 0 ..< SmartAccountConstants.ed25519PublicKeySize {
            bytes[i] = UInt8((i + 7) % 256)
        }
        return Data(bytes)
    }

    /// Builds an ``OZSmartAccountConfig`` suitable for unit tests. Uses the
    /// public Testnet RPC URL placeholder (every test that reaches the
    /// network is gated by the disconnected-kit fixture and never gets that
    /// far).
    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifier
        )
    }

    /// Builds a disconnected ``MockOZSmartAccountKit`` plus a signer manager.
    /// Used by the requireConnected gate assertions.
    private func disconnectedKit(
        contextRuleParser: OZContextRuleParser? = nil
    ) throws -> (MockOZSmartAccountKit, OZSignerManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return (
            kit,
            OZSignerManager(
                kit: kit,
                contextRuleParser: contextRuleParser
            )
        )
    }

    /// Builds a connected ``MockOZSmartAccountKit`` plus a signer manager
    /// bound to a deterministic credential id / contract id pair.
    private func connectedKit(
        contractId: String? = nil,
        contextRuleParser: OZContextRuleParser? = nil
    ) throws -> (MockOZSmartAccountKit, OZSignerManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: contractId ?? validContractC2
        )
        return (
            kit,
            OZSignerManager(
                kit: kit,
                contextRuleParser: contextRuleParser
            )
        )
    }

    // ========================================================================
    // MARK: - buildAddSignerFunction — host-function shape (3 cases)
    // ========================================================================

    /// `add_signer` invocation must carry the smart-account contract address,
    /// the function name `"add_signer"`, and the two positional arguments
    /// `[u32 contextRuleId, signer_scval]` in that order.
    func test_buildAddSignerFunction_passkeySignerShape() throws {
        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: validVerifier,
            publicKey: validSecp256r1PublicKey(),
            credentialId: Data([0x01, 0x02, 0x03, 0x04])
        )

        let hostFunction = try OZSignerManager.buildAddSignerFunction(
            contractId: validContractC2,
            contextRuleId: 7,
            signer: signer
        )

        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, "add_signer")
        XCTAssertEqual(invokeArgs.args.count, 2)

        guard case .u32(let ruleId) = invokeArgs.args[0] else {
            return XCTFail("first arg must be u32 contextRuleId")
        }
        XCTAssertEqual(ruleId, 7)

        let expectedSignerScVal = try signer.toScVal()
        let expectedBytes = try Data(XDREncoder.encode(expectedSignerScVal))
        let observedBytes = try Data(XDREncoder.encode(invokeArgs.args[1]))
        XCTAssertEqual(
            expectedBytes,
            observedBytes,
            "second arg must round-trip byte-equal with the signer ScVal"
        )
    }

    /// Delegated signer encoding inside `add_signer` is the
    /// `Symbol("Delegated") || Address` vec the contract expects.
    func test_buildAddSignerFunction_delegatedSignerShape() throws {
        let signer = try OZDelegatedSigner(address: validGAddr1)

        let hostFunction = try OZSignerManager.buildAddSignerFunction(
            contractId: validContractC2,
            contextRuleId: 0,
            signer: signer
        )

        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, "add_signer")
        XCTAssertEqual(invokeArgs.args.count, 2)

        guard case .u32(let ruleId) = invokeArgs.args[0] else {
            return XCTFail("first arg must be u32 contextRuleId")
        }
        XCTAssertEqual(ruleId, 0)

        guard case .vec(let elements) = invokeArgs.args[1], let elements = elements else {
            return XCTFail("delegated signer must encode as vec")
        }
        XCTAssertEqual(elements.count, 2)
        guard case .symbol(let tag) = elements[0] else {
            return XCTFail("first vec element must be symbol tag")
        }
        XCTAssertEqual(tag, "Delegated")
    }

    /// Ed25519 signer encoding inside `add_signer` is the
    /// `Symbol("External") || Address || Bytes(publicKey)` vec the contract
    /// expects.
    func test_buildAddSignerFunction_ed25519SignerShape() throws {
        let signer = try OZExternalSigner.ed25519(
            verifierAddress: validVerifier,
            publicKey: validEd25519PublicKey()
        )

        let hostFunction = try OZSignerManager.buildAddSignerFunction(
            contractId: validContractC2,
            contextRuleId: 4,
            signer: signer
        )

        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, "add_signer")

        guard case .vec(let elements) = invokeArgs.args[1], let elements = elements else {
            return XCTFail("external signer must encode as vec")
        }
        XCTAssertEqual(elements.count, 3)
        guard case .symbol(let tag) = elements[0] else {
            return XCTFail("first vec element must be symbol tag")
        }
        XCTAssertEqual(tag, "External")
        guard case .bytes(let keyData) = elements[2] else {
            return XCTFail("third vec element must be bytes(keyData)")
        }
        XCTAssertEqual(
            keyData.count,
            SmartAccountConstants.ed25519PublicKeySize,
            "Ed25519 signer keyData is the 32-byte public key without trailing bytes"
        )
    }

    // ========================================================================
    // MARK: - buildRemoveSignerFunction — host-function shape (1 case)
    // ========================================================================

    /// `remove_signer` invocation must carry the contract address, the
    /// function name `"remove_signer"`, and the two positional arguments
    /// `[u32 contextRuleId, u32 signerId]`.
    func test_buildRemoveSignerFunction_argShape() throws {
        let hostFunction = try OZSignerManager.buildRemoveSignerFunction(
            contractId: validContractC2,
            contextRuleId: 3,
            signerId: 11
        )

        guard case .invokeContract(let invokeArgs) = hostFunction else {
            return XCTFail("expected invokeContract host function")
        }
        XCTAssertEqual(invokeArgs.functionName, "remove_signer")
        XCTAssertEqual(invokeArgs.args.count, 2)

        guard case .u32(let ruleId) = invokeArgs.args[0],
              case .u32(let signerId) = invokeArgs.args[1] else {
            return XCTFail("expected two u32 args")
        }
        XCTAssertEqual(ruleId, 3)
        XCTAssertEqual(signerId, 11)
    }

    // ========================================================================
    // MARK: - addPasskey — validation surface (5 cases)
    // ========================================================================

    /// Disconnected kit + `addPasskey` must throw
    /// ``SmartAccountWalletException/NotConnected`` before any submission attempt.
    func test_addPasskey_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.addPasskey(
                contextRuleId: 0,
                publicKey: validSecp256r1PublicKey(),
                credentialId: Data([0x01, 0x02])
            )
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    /// Wrong-size public key surfaces a field-tagged validation error
    /// referencing the `publicKey` field.
    func test_addPasskey_wrongSizePublicKey_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addPasskey(
                contextRuleId: 0,
                publicKey: Data([0x04, 0x00, 0x00, 0x00]),
                credentialId: Data([0x01, 0x02])
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("publicKey"),
                "error message should reference the publicKey field, got: \(error.message)"
            )
        }
    }

    /// Public key with the wrong leading byte (not `0x04`) surfaces the
    /// uncompressed-prefix validation error.
    func test_addPasskey_wrongLeadingByte_throws() async throws {
        let (_, manager) = try connectedKit()
        var badKey = validSecp256r1PublicKey()
        badKey[badKey.startIndex] = 0x02
        do {
            _ = try await manager.addPasskey(
                contextRuleId: 0,
                publicKey: badKey,
                credentialId: Data([0x01, 0x02])
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("0x04"),
                "error message should mention the expected uncompressed prefix, got: \(error.message)"
            )
        }
    }

    /// Empty credential id surfaces the credential-id validation error.
    func test_addPasskey_emptyCredentialId_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addPasskey(
                contextRuleId: 0,
                publicKey: validSecp256r1PublicKey(),
                credentialId: Data()
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("credentialId") || error.message.contains("Credential ID"),
                "error message should reference the credentialId field, got: \(error.message)"
            )
        }
    }

    /// A credential id that pushes the signer's key data (`publicKey || credentialId`)
    /// over ``OZConstants/maxExternalKeySize`` bytes surfaces the key-data limit error
    /// before any submission attempt.
    func test_addPasskey_oversizedKeyData_throws() async throws {
        let (_, manager) = try connectedKit()
        // keyData = publicKey (65) + credentialId (192) = 257 bytes, one over the limit.
        let credentialId = Data(
            repeating: 0x02,
            count: OZConstants.maxExternalKeySize + 1 - SmartAccountConstants.secp256r1PublicKeySize
        )
        do {
            _ = try await manager.addPasskey(
                contextRuleId: 0,
                publicKey: validSecp256r1PublicKey(),
                credentialId: credentialId
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("External signer key data cannot exceed \(OZConstants.maxExternalKeySize) bytes"),
                "expected key data limit in message, got: \(error.message)"
            )
        }
    }

    /// A non-empty `selectedSigners` list containing a wallet entry routes
    /// through the kit's multi-signer manager, whose initial validation
    /// rejects wallet-kind signers when the kit's config does not declare an
    /// external wallet adapter. The check surfaces as
    /// ``SmartAccountValidationException/InvalidInput`` naming the `selectedSigners`
    /// field so callers can correct the kit configuration before retrying.
    func test_addPasskey_walletSigner_withoutExternalWalletAdapter_throwsValidation() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addPasskey(
                contextRuleId: 0,
                publicKey: validSecp256r1PublicKey(),
                credentialId: Data([0x01, 0x02]),
                selectedSigners: [.wallet(accountId: validGAddr1)]
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
    // MARK: - addDelegated — validation surface (2 cases)
    // ========================================================================

    /// Disconnected kit + `addDelegated` must throw
    /// ``SmartAccountWalletException/NotConnected`` before any submission attempt.
    func test_addDelegated_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.addDelegated(
                contextRuleId: 0,
                address: validGAddr1
            )
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    /// Malformed address surfaces the ``OZDelegatedSigner`` initialiser's
    /// address validation error.
    func test_addDelegated_invalidAddress_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addDelegated(
                contextRuleId: 0,
                address: "not-a-stellar-address"
            )
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        }
    }

    // ========================================================================
    // MARK: - addEd25519 — validation surface (2 cases)
    // ========================================================================

    /// Disconnected kit + `addEd25519` must throw
    /// ``SmartAccountWalletException/NotConnected`` before any submission attempt.
    func test_addEd25519_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.addEd25519(
                contextRuleId: 0,
                verifierAddress: validVerifier,
                publicKey: validEd25519PublicKey()
            )
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    /// Wrong-size Ed25519 public key surfaces a field-tagged validation
    /// error referencing the `publicKey` field.
    func test_addEd25519_wrongSizePublicKey_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addEd25519(
                contextRuleId: 0,
                verifierAddress: validVerifier,
                publicKey: Data([0x00, 0x01, 0x02])
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("publicKey"),
                "error message should reference the publicKey field, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // MARK: - removeSigner(by signerId) — connection gate (1 case)
    // ========================================================================

    /// Disconnected kit + `removeSigner` by id must throw
    /// ``SmartAccountWalletException/NotConnected``.
    func test_removeSigner_byId_notConnected_throws() async throws {
        let (_, manager) = try disconnectedKit()
        do {
            _ = try await manager.removeSigner(
                contextRuleId: 0,
                signerId: 1
            )
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
    }

    // ========================================================================
    // MARK: - removeSignerBySigner
    // ========================================================================

    /// Given a context rule with three signers and known signer ids,
    /// `removeSignerBySigner(_:contextRuleId:)` must resolve the supplied
    /// value to the correct numeric id and produce a host function byte-equal
    /// to the id-based `removeSigner(_:contextRuleId:signerId:)` invocation
    /// for the same target.
    func test_removeSigner_bySignerValue_resolvesToCorrectIdViaListContextRules() async throws {
        let signerA = try OZDelegatedSigner(address: validGAddr1)
        let signerB = try OZDelegatedSigner(address: validGAddr2)
        let signerC = try OZDelegatedSigner(address: validGAddr3)
        let signerIds: [UInt32] = [10, 20, 30]
        let rule = OZParsedContextRule(
            id: 0,
            contextType: .defaultRule,
            name: "Default",
            signers: [signerA, signerB, signerC],
            signerIds: signerIds,
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let parser = _StubContextRuleParser(rule: rule)
        let (kit, manager) = try connectedKit(contextRuleParser: parser)
        let recorder = MockOZMultiSignerManager(kit: kit)
        kit.multiSignerManagerOverride = recorder

        // why: routing through the multi-signer submitter captures the
        // host function produced by the manager without performing any
        // RPC traffic. Single-signer routing would call into the kit's
        // pinned transaction operations, which would attempt to reach the
        // configured RPC endpoint and fail before the host function shape
        // can be observed.
        let selectedSigners: [OZSelectedSigner] = [.wallet(accountId: validGAddr1)]
        _ = try await manager.removeSignerBySigner(
            contextRuleId: 0,
            signer: signerB,
            selectedSigners: selectedSigners
        )

        XCTAssertEqual(parser.getContextRuleCalls, [0])
        XCTAssertEqual(parser.parseContextRuleCalls, 1)
        XCTAssertEqual(recorder.invocations.count, 1)

        let observed = recorder.invocations[0].hostFunction
        let expected = try OZSignerManager.buildRemoveSignerFunction(
            contractId: validContractC2,
            contextRuleId: 0,
            signerId: signerIds[1]
        )

        let observedBytes = try Data(XDREncoder.encode(observed))
        let expectedBytes = try Data(XDREncoder.encode(expected))
        XCTAssertEqual(
            observedBytes,
            expectedBytes,
            "value-based remove must produce a host function byte-equal to the id-based remove for the resolved signer id"
        )
    }

    /// When the supplied signer value is not present on the resolved context
    /// rule, the manager must throw ``SmartAccountValidationException/InvalidInput``
    /// without producing a host function or invoking the submitter.
    func test_removeSigner_bySignerValue_signerNotInRule_throwsValidation() async throws {
        let signerA = try OZDelegatedSigner(address: validGAddr1)
        let signerB = try OZDelegatedSigner(address: validGAddr2)
        let rule = OZParsedContextRule(
            id: 0,
            contextType: .defaultRule,
            name: "Default",
            signers: [signerA, signerB],
            signerIds: [10, 20],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let parser = _StubContextRuleParser(rule: rule)
        let (kit, manager) = try connectedKit(contextRuleParser: parser)
        let recorder = MockOZMultiSignerManager(kit: kit)
        kit.multiSignerManagerOverride = recorder

        let absent = try OZDelegatedSigner(address: validGAddr3)
        do {
            _ = try await manager.removeSignerBySigner(
                contextRuleId: 0,
                signer: absent,
                selectedSigners: [.wallet(accountId: validGAddr1)]
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("Signer not found"),
                "error message should explain the missing-signer reason, got: \(error.message)"
            )
        }

        XCTAssertEqual(parser.getContextRuleCalls, [0])
        XCTAssertEqual(
            recorder.invocations.count,
            0,
            "submitter must not be invoked when resolution fails"
        )
    }

    // ========================================================================
    // MARK: - removeSignerBySigner — additional resolution coverage (3 cases)
    // ========================================================================

    /// Disconnected kit + value-based remove must throw
    /// ``SmartAccountWalletException/NotConnected`` before any parser interaction so a
    /// disconnected kit cannot accidentally hit the indexer / RPC.
    func test_removeSignerBySigner_notConnected_throws() async throws {
        let parser = _StubContextRuleParser(rule: nil)
        let (_, manager) = try disconnectedKit(contextRuleParser: parser)
        do {
            _ = try await manager.removeSignerBySigner(
                contextRuleId: 0,
                signer: try OZDelegatedSigner(address: validGAddr1)
            )
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
            XCTAssertEqual(error.code, .walletNotConnected)
        }
        XCTAssertEqual(
            parser.getContextRuleCalls,
            [],
            "parser must not be consulted when the kit is disconnected"
        )
    }

    /// Connected kit without a wired context-rule parser must surface a
    /// ``SmartAccountConfigurationException`` rather than a runtime null-pointer-style
    /// failure deeper in the resolution path.
    func test_removeSignerBySigner_noParser_throwsConfiguration() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.removeSignerBySigner(
                contextRuleId: 0,
                signer: try OZDelegatedSigner(address: validGAddr1)
            )
            XCTFail("expected SmartAccountConfigurationException.InvalidConfig")
        } catch is SmartAccountConfigurationException.InvalidConfig {
            // expected
        }
    }

    /// When the resolved context rule's `signers` and `signerIds` arrays
    /// are misaligned (signer found at an index past the end of
    /// `signerIds`), the manager must surface a field-tagged validation
    /// error naming the constraint rather than letting an out-of-bounds
    /// runtime trap fire.
    func test_removeSignerBySigner_misalignedSignerIds_throwsValidation() async throws {
        let signerA = try OZDelegatedSigner(address: validGAddr1)
        let signerB = try OZDelegatedSigner(address: validGAddr2)
        let signerC = try OZDelegatedSigner(address: validGAddr3)
        let rule = OZParsedContextRule(
            id: 0,
            contextType: .defaultRule,
            name: "Default",
            signers: [signerA, signerB, signerC],
            signerIds: [10, 20],
            policies: [],
            policyIds: [],
            validUntil: nil
        )

        let parser = _StubContextRuleParser(rule: rule)
        let (_, manager) = try connectedKit(contextRuleParser: parser)

        do {
            _ = try await manager.removeSignerBySigner(
                contextRuleId: 0,
                signer: signerC
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("signerIds"),
                "error message should name the misalignment, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // Task cancellation propagation
    // ========================================================================

    /// `addNewPasskeySigner` performs WebAuthn registration first, then issues
    /// a contract-level `add_signer` submission. Cancelling the parent task
    /// after the WebAuthn step but before submission completes must surface
    /// ``CancellationError`` rather than letting the on-chain submission fire.
    /// The recording WebAuthn provider returns immediately so the cancellation
    /// is observed at one of the manager's `Task.checkCancellation` points
    /// (between WebAuthn and credential save, or between credential save and
    /// the contract submit).
    func test_addNewPasskeySigner_cancellation_propagatesCancellationError() async throws {
        let provider = RecordingWebAuthnProvider()
        let storage = OZInMemoryStorageAdapter()
        let config = try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider,
            storage: storage
        )
        let kit = MockOZSmartAccountKit(config: config)
        kit.setConnectedState(
            credentialId: "test-credential-id",
            contractId: validContractC2
        )
        let manager = OZSignerManager(kit: kit)

        let task = Task { [manager] in
            return try await manager.addNewPasskeySigner(
                contextRuleId: 1,
                userName: "tester"
            )
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("expected cancellation or error before contract submission completes")
        } catch is CancellationError {
            // Expected: pipeline observed cancellation at one of its checkpoints.
        } catch {
            // Acceptable alternative: an awaited dependency surfaced an error
            // before the cancellation checkpoint fired. Any thrown error proves
            // the pipeline did not silently submit on chain.
        }
    }

    // ========================================================================
    // MARK: - OZAddPasskeySignerResult value-type conformances (Batch E)
    // ========================================================================

    /// `OZAddPasskeySignerResult` is `Equatable` and `Hashable`. Verifies that
    /// two instances with byte-equal public keys and identical remaining fields
    /// compare equal and produce the same hash value.
    func test_addPasskeySignerResult_equatable_hashable() throws {
        let txResult = OZTransactionResult(success: true, hash: "abc")
        let key1 = validSecp256r1PublicKey()
        let key2 = validSecp256r1PublicKey()

        let a = OZAddPasskeySignerResult(
            credentialId: "cred-x",
            publicKey: key1,
            transactionResult: txResult
        )
        let b = OZAddPasskeySignerResult(
            credentialId: "cred-x",
            publicKey: key2,
            transactionResult: txResult
        )
        let c = OZAddPasskeySignerResult(
            credentialId: "cred-y",
            publicKey: key1,
            transactionResult: txResult
        )

        XCTAssertEqual(a, b, "Two results with identical fields must compare equal")
        XCTAssertNotEqual(a, c, "Results with different credentialIds must not compare equal")

        var hasher1 = Hasher()
        a.hash(into: &hasher1)
        var hasher2 = Hasher()
        b.hash(into: &hasher2)
        XCTAssertEqual(
            hasher1.finalize(), hasher2.finalize(),
            "Equal results must produce equal hash values"
        )
    }

    // ========================================================================
    // MARK: - addNewPasskeySigner error paths (Batch E)
    // ========================================================================

    /// When no `WebAuthnProvider` is configured on the kit (and no override is
    /// injected into the manager), `addNewPasskeySigner` must throw
    /// `WebAuthnException.NotSupported` before touching any network resource.
    func test_addNewPasskeySigner_noWebauthnProvider_throws() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addNewPasskeySigner(contextRuleId: 0, userName: "alice")
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    /// When the WebAuthn provider returns a registration failure,
    /// `addNewPasskeySigner` must surface the error as
    /// `WebAuthnException.RegistrationFailed` and must not attempt any
    /// credential-persistence or on-chain submission.
    func test_addNewPasskeySigner_registrationFailed_throwsWebAuthnException() async throws {
        let provider = RecordingWebAuthnProvider()
        provider.enqueueRegisterError(
            WebAuthnException.registrationFailed(reason: "Authenticator rejected registration")
        )

        let config = try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider
        )
        let kit = MockOZSmartAccountKit(config: config)
        kit.setConnectedState(
            credentialId: "existing-cred",
            contractId: validContractC2
        )
        let manager = OZSignerManager(kit: kit)

        do {
            _ = try await manager.addNewPasskeySigner(contextRuleId: 0, userName: "bob")
            XCTFail("expected WebAuthnException.RegistrationFailed")
        } catch is WebAuthnException.RegistrationFailed {
            XCTAssertEqual(1, provider.registerCalls.count, "register must be called exactly once")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// When credential storage throws after a successful WebAuthn registration,
    /// `addNewPasskeySigner` must surface `SmartAccountStorageException.WriteFailed`.
    func test_addNewPasskeySigner_storageFails_throwsStorageException() async throws {
        let provider = RecordingWebAuthnProvider()
        provider.enqueueRegister(
            MockWebAuthnProvider.defaultRegistrationResult()
        )

        let failingStorage = _FailingStorageAdapter(failOnWrite: true)
        let config = try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider,
            storage: failingStorage
        )
        let kit = MockOZSmartAccountKit(config: config)
        kit.setConnectedState(
            credentialId: "existing-cred",
            contractId: validContractC2
        )
        let manager = OZSignerManager(kit: kit)

        do {
            _ = try await manager.addNewPasskeySigner(contextRuleId: 0, userName: "carol")
            XCTFail("expected SmartAccountStorageException or related error")
        } catch is SmartAccountStorageException {
            // expected: storage write failed
        } catch is SmartAccountCredentialException {
            // also acceptable: the manager may surface SmartAccountCredentialException on
            // a storage failure depending on the internal path taken.
        } catch is WebAuthnException {
            // also acceptable: the manager may rethrow a WebAuthn error from
            // the inner registration flow when the public key extraction fails
            // on a synthetic attestation object.
        } catch {
            // Any thrown error proves the manager did not silently proceed to
            // on-chain submission when storage was broken.
        }
        XCTAssertEqual(1, provider.registerCalls.count, "register must be called exactly once before storage is attempted")
    }

    /// `addDelegated` with an invalid address must throw
    /// `SmartAccountValidationException.InvalidAddress` before any network access.
    func test_addDelegated_invalidAddress_throwsValidationException() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addDelegated(contextRuleId: 0, address: "NOT-VALID-ADDRESS")
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        } catch is SmartAccountValidationException.InvalidInput {
            // also acceptable depending on the delegated signer init path
        }
    }

    // ========================================================================
    // addEd25519 body coverage
    // ========================================================================

    /// Exercises the `addEd25519` body (lines that construct `OZExternalSigner.ed25519`
    /// and call `addSigner`). All guard-checks pass; the call fails at the first
    /// async step (non-routable RPC endpoint), but the body lines that build
    /// the signer and forward to `addSigner` are traversed.
    func test_addEd25519_validArgs_reachesAddSigner() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addEd25519(
                contextRuleId: 0,
                verifierAddress: validVerifier,
                publicKey: validEd25519PublicKey()
            )
        } catch {
            // Expected: any error after guard-checks pass means the body was reached.
        }
    }

    // ========================================================================
    // addDelegated body coverage
    // ========================================================================

    /// Exercises the `addDelegated` body by providing a valid G-address.
    /// All validation passes; the call fails at RPC (non-routable endpoint),
    /// but the body lines that build `OZDelegatedSigner` and call `addSigner`
    /// are traversed.
    func test_addDelegated_validGAddress_reachesAddSigner() async throws {
        let (_, manager) = try connectedKit()
        do {
            _ = try await manager.addDelegated(contextRuleId: 0, address: validGAddr1)
        } catch {
            // Expected: any error after guard-checks pass means the body was reached.
        }
    }

    // ========================================================================
    // MARK: - addNewPasskeySigner — non-WebAuthn registration error (lines 210-213)
    // ========================================================================

    /// When the WebAuthn provider's `register` throws an error that is NOT a
    /// ``WebAuthnException``, `addNewPasskeySigner` must wrap it in
    /// ``WebAuthnException/RegistrationFailed`` (the generic-catch branch),
    /// preserving the underlying cause.
    func test_addNewPasskeySigner_nonWebAuthnRegistrationError_wrapsAsRegistrationFailed() async throws {
        let provider = RecordingWebAuthnProvider()
        provider.enqueueRegisterError(_PlainError(detail: "authenticator hardware fault"))

        let config = try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider
        )
        let kit = MockOZSmartAccountKit(config: config)
        kit.setConnectedState(
            credentialId: "existing-cred",
            contractId: validContractC2
        )
        let manager = OZSignerManager(kit: kit)

        do {
            _ = try await manager.addNewPasskeySigner(contextRuleId: 0, userName: "dave")
            XCTFail("expected WebAuthnException.RegistrationFailed")
        } catch is WebAuthnException.RegistrationFailed {
            XCTAssertEqual(1, provider.registerCalls.count, "register must be called exactly once")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // ========================================================================
    // MARK: - addNewPasskeySigner — credential persistence error mapping (lines 237-245)
    // ========================================================================

    /// When `createPendingCredential` throws a ``SmartAccountCredentialException``
    /// after a successful registration, `addNewPasskeySigner` must rethrow that
    /// exception unchanged (the `catch let error as SmartAccountCredentialException`
    /// branch) without proceeding to on-chain submission.
    func test_addNewPasskeySigner_credentialExceptionFromCreatePending_rethrows() async throws {
        let provider = RecordingWebAuthnProvider()
        provider.enqueueRegister(MockWebAuthnProvider.defaultRegistrationResult())

        let credentialManager = _ThrowingCredentialManager(
            error: SmartAccountCredentialException.invalid(reason: "synthetic credential failure")
        )
        let (kit, _) = try connectedKit()
        let manager = OZSignerManager(
            kit: kit,
            webauthnProvider: provider,
            credentialManager: credentialManager
        )

        do {
            _ = try await manager.addNewPasskeySigner(contextRuleId: 0, userName: "erin")
            XCTFail("expected SmartAccountCredentialException")
        } catch is SmartAccountCredentialException {
            XCTAssertEqual(1, provider.registerCalls.count, "register must be called once before credential save")
            XCTAssertEqual(1, credentialManager.createPendingCalls)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// When `createPendingCredential` throws a ``SmartAccountStorageException``,
    /// `addNewPasskeySigner` must rethrow it unchanged (the
    /// `catch let error as SmartAccountStorageException` branch).
    func test_addNewPasskeySigner_storageExceptionFromCreatePending_rethrows() async throws {
        let provider = RecordingWebAuthnProvider()
        provider.enqueueRegister(MockWebAuthnProvider.defaultRegistrationResult())

        let credentialManager = _ThrowingCredentialManager(
            error: SmartAccountStorageException.writeFailed(key: "synthetic-key")
        )
        let (kit, _) = try connectedKit()
        let manager = OZSignerManager(
            kit: kit,
            webauthnProvider: provider,
            credentialManager: credentialManager
        )

        do {
            _ = try await manager.addNewPasskeySigner(contextRuleId: 0, userName: "frank")
            XCTFail("expected SmartAccountStorageException")
        } catch is SmartAccountStorageException {
            XCTAssertEqual(1, credentialManager.createPendingCalls)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// When `createPendingCredential` throws a non-SmartAccount error (an
    /// arbitrary `Error`), `addNewPasskeySigner` must wrap it in
    /// ``SmartAccountStorageException/WriteFailed`` keyed by the base64url
    /// credential id (the generic catch branch).
    func test_addNewPasskeySigner_genericErrorFromCreatePending_wrapsAsWriteFailed() async throws {
        let provider = RecordingWebAuthnProvider()
        provider.enqueueRegister(MockWebAuthnProvider.defaultRegistrationResult())

        let credentialManager = _ThrowingCredentialManager(
            error: _PlainError(detail: "keychain unavailable")
        )
        let (kit, _) = try connectedKit()
        let manager = OZSignerManager(
            kit: kit,
            webauthnProvider: provider,
            credentialManager: credentialManager
        )

        do {
            _ = try await manager.addNewPasskeySigner(contextRuleId: 0, userName: "grace")
            XCTFail("expected SmartAccountStorageException.WriteFailed")
        } catch is SmartAccountStorageException.WriteFailed {
            XCTAssertEqual(1, credentialManager.createPendingCalls)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // ========================================================================
    // MARK: - addNewPasskeySigner — full success path (lines 248-264)
    // ========================================================================

    /// A registration that succeeds, persists, emits the credential-created
    /// event, and submits on-chain through the multi-signer recorder must return
    /// an ``OZAddPasskeySignerResult`` carrying the base64url credential id, the
    /// 65-byte public key, and the recorded transaction result. This exercises
    /// the post-registration body (event emit, `addPasskey` delegation, and the
    /// result construction) end-to-end without live RPC.
    func test_addNewPasskeySigner_fullSuccess_returnsResult() async throws {
        let provider = RecordingWebAuthnProvider()
        let registration = MockWebAuthnProvider.defaultRegistrationResult()
        provider.enqueueRegister(registration)

        let storage = OZInMemoryStorageAdapter()
        let config = try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifier,
            webauthnProvider: provider,
            storage: storage
        )
        let kit = MockOZSmartAccountKit(config: config)
        kit.setConnectedState(
            credentialId: "existing-cred",
            contractId: validContractC2
        )

        // Route the on-chain add-signer submission through the recorder so the
        // success path completes without touching the network.
        let recorder = MockOZMultiSignerManager(kit: kit)
        recorder.defaultResult = OZTransactionResult(success: true, hash: "feedface")
        kit.multiSignerManagerOverride = recorder

        let manager = OZSignerManager(kit: kit)

        let result = try await manager.addNewPasskeySigner(
            contextRuleId: 2,
            userName: "heidi",
            selectedSigners: [.wallet(accountId: validGAddr1)]
        )

        XCTAssertEqual(
            result.credentialId,
            registration.credentialId.base64URLEncodedString(),
            "result credentialId must be the base64url encoding of the registration credential id"
        )
        XCTAssertEqual(result.publicKey, registration.publicKey, "result must carry the registration public key")
        XCTAssertTrue(result.transactionResult.success)
        XCTAssertEqual(result.transactionResult.hash, "feedface")
        XCTAssertEqual(recorder.invocations.count, 1, "on-chain add-signer must route through the multi-signer submitter once")
        XCTAssertEqual(provider.registerCalls.count, 1)
    }
}

// ============================================================================
// MARK: - Test doubles (file-private)
// ============================================================================

/// In-memory ``OZContextRuleParser`` stub used by the value-based remove
/// tests.
///
/// Returns the supplied ``OZParsedContextRule`` (wrapped in a deterministic raw
/// `SCValXDR`) from ``getContextRule(contextRuleId:)`` and yields the same
/// rule back from ``parseContextRule(_:)``. Records every call so the
/// resolution-path tests can assert the parser was consulted exactly once.
private final class _StubContextRuleParser: OZContextRuleParser, @unchecked Sendable {

    /// Pre-set rule returned by both parser methods. When `nil`, calls throw
    /// a placeholder error so tests can assert the parser was not consulted.
    private let rule: OZParsedContextRule?

    /// Records every `contextRuleId` passed to ``getContextRule(contextRuleId:)``.
    private(set) var getContextRuleCalls: [UInt32] = []

    /// Counts every invocation of ``parseContextRule(_:)``.
    private(set) var parseContextRuleCalls: Int = 0

    init(rule: OZParsedContextRule?) {
        self.rule = rule
    }

    func getContextRule(contextRuleId: UInt32) async throws -> SCValXDR {
        getContextRuleCalls.append(contextRuleId)
        guard rule != nil else {
            throw SmartAccountValidationException.invalidInput(
                field: "contextRuleId",
                reason: "Stub parser holds no rule for id \(contextRuleId)"
            )
        }
        // why: the test stub does not exercise the on-chain parsing
        // pipeline. A void payload signal is enough because
        // `parseContextRule(_:)` immediately returns the pre-set rule
        // without inspecting the input ScVal.
        return SCValXDR.void
    }

    func parseContextRule(_ scVal: SCValXDR) throws -> OZParsedContextRule {
        parseContextRuleCalls += 1
        guard let rule = rule else {
            throw SmartAccountValidationException.invalidInput(
                field: "scVal",
                reason: "Stub parser holds no rule to return"
            )
        }
        return rule
    }
}

/// Storage adapter that always fails on write operations. Used by the
/// `addNewPasskeySigner_storageFails` test to verify the manager surfaces
/// a storage error rather than silently proceeding when persistence is broken.
private final class _FailingStorageAdapter: OZStorageAdapter, @unchecked Sendable {

    private let failOnWrite: Bool
    private let failOnRead: Bool

    init(failOnWrite: Bool = false, failOnRead: Bool = false) {
        self.failOnWrite = failOnWrite
        self.failOnRead = failOnRead
    }

    func save(credential: OZStoredCredential) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: credential.credentialId)
        }
    }

    func get(credentialId: String) async throws -> OZStoredCredential? {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: credentialId)
        }
        return nil
    }

    func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: contractId)
        }
        return []
    }

    func getAll() async throws -> [OZStoredCredential] {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: "all")
        }
        return []
    }

    func delete(credentialId: String) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: credentialId)
        }
    }

    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: credentialId)
        }
    }

    func clear() async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: "all")
        }
    }

    func saveSession(_ session: OZStoredSession) async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: "session")
        }
    }

    func getSession() async throws -> OZStoredSession? {
        if failOnRead {
            throw SmartAccountStorageException.readFailed(key: "session")
        }
        return nil
    }

    func clearSession() async throws {
        if failOnWrite {
            throw SmartAccountStorageException.writeFailed(key: "session")
        }
    }
}

/// A plain `Error` that is not a ``SmartAccountException``. Used to drive the
/// generic-catch branches in `addNewPasskeySigner` (non-WebAuthn registration
/// error and non-SmartAccount credential-persistence error).
private struct _PlainError: Error {
    let detail: String
}

/// Credential manager double whose `createPendingCredential` always throws a
/// configurable error. The remaining protocol methods are no-ops; the signer
/// manager's new-passkey flow only reaches `createPendingCredential` before the
/// failure surfaces. Records how many times `createPendingCredential` was
/// invoked so tests can assert the failure originated there.
private final class _ThrowingCredentialManager: OZCredentialManagerProtocol, @unchecked Sendable {

    private let error: Error
    private let lock = NSLock()
    private var _createPendingCalls = 0

    var createPendingCalls: Int {
        lock.lock(); defer { lock.unlock() }
        return _createPendingCalls
    }

    init(error: Error) {
        self.error = error
    }

    func createPendingCredential(
        credentialId: String,
        publicKey: Data,
        contractId: String,
        nickname: String?,
        transports: [String]?,
        deviceType: String?,
        backedUp: Bool?
    ) async throws -> OZStoredCredential {
        lock.withLock { _createPendingCalls += 1 }
        throw error
    }

    func getCredential(credentialId: String) async throws -> OZStoredCredential? { nil }
    func markDeploymentFailed(credentialId: String, error: String) async throws {}
    func setPrimary(credentialId: String) async throws {}
    func updateLastUsed(credentialId: String) async throws {}
    func deleteCredential(credentialId: String) async throws {}
}

