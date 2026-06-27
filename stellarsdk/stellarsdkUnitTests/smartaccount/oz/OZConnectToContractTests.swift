//
//  OZConnectToContractTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Hermetic tests for the headless ``OZWalletOperations/connectToContract(contractId:)``
//  entry point and the matching headless guard on the single-passkey
//  ``OZTransactionOperations/submit(hostFunction:auth:forceMethod:resolveContextRuleIds:)``
//  path. Each case scripts the ``MockSorobanServerScript`` before invoking the
//  production code so the on-chain existence check runs end-to-end without live
//  RPC traffic.
//

import XCTest
@testable import stellarsdk

final class OZConnectToContractTests: XCTestCase {

    // MARK: - Constants

    private let contractA =
        "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
    private let contractB =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    // MARK: - State

    private var script: MockSorobanServerScript!

    override func setUp() {
        super.setUp()
        script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
    }

    override func tearDown() {
        MockSorobanServer.deactivate()
        script = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Harness

    /// Captures the wiring a single test needs: the kit, the wallet-operations
    /// instance under test, the recording credential manager, and the backing
    /// in-memory storage adapter.
    private struct Harness {
        let kit: MockOZSmartAccountKit
        let walletOps: OZWalletOperations
        let credentialManager: MockCredentialManager
        let storage: OZInMemoryStorageAdapter
    }

    /// Builds a kit wired to the scripted mock Soroban server. The credential
    /// manager is the recording ``MockCredentialManager`` so tests can assert it
    /// was never consulted; the storage adapter is shared with the kit so a
    /// test can seed or read sessions through the same instance the production
    /// code writes to.
    private func makeHarness(
        webauthnProvider: WebAuthnProvider? = nil
    ) throws -> Harness {
        let storage = OZInMemoryStorageAdapter()
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA,
            webauthnProvider: webauthnProvider,
            storage: storage
        )
        let credentialManager = MockCredentialManager(storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer(),
            credentialManager: credentialManager
        )
        return Harness(
            kit: kit,
            walletOps: OZWalletOperations(kit: kit),
            credentialManager: credentialManager,
            storage: storage
        )
    }

    /// Deterministic deployer keypair derived from the seed so the scripted
    /// `getAccount` response can be keyed on the same account id.
    private func deterministicDeployer(seed: UInt8) throws -> KeyPair {
        let stellarSeed = try Seed(bytes: [UInt8](Data(repeating: seed, count: 32)))
        return KeyPair(seed: stellarSeed)
    }

    /// A non-expired session bound to an arbitrary passkey credential and
    /// contract, used to prove a headless connect clears pre-existing state.
    private func nonExpiredSession(
        credentialId: String,
        contractId: String
    ) -> OZStoredSession {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return OZStoredSession(
            credentialId: credentialId,
            contractId: contractId,
            connectedAt: now,
            expiresAt: now + OZConstants.defaultSessionExpiryMs
        )
    }

    // MARK: - 1. Connected state

    func test_connectToContract_existingContract_setsConnectedStateToContractId() async throws {
        let h = try makeHarness()
        try script.setGetContractDataResponse(contractId: contractA)

        let result = try await h.walletOps.connectToContract(contractId: contractA)

        XCTAssertEqual(result.contractId, contractA)
        XCTAssertEqual(h.kit.currentConnectedState?.contractId, contractA)
        XCTAssertEqual(h.kit.setConnectedStateInvocations.last?.contractId, contractA)
        XCTAssertEqual(
            h.kit.setConnectedStateInvocations.last?.credentialId,
            "",
            "headless connect must record the empty credential sentinel"
        )
        XCTAssertEqual(
            h.kit.currentConnectedState?.credentialId,
            OZConstants.headlessCredentialIdSentinel
        )
    }

    // MARK: - 2. On-chain existence check

    func test_connectToContract_verifiesContractExistsOnChain() async throws {
        let h = try makeHarness()
        // Drive an empty getLedgerEntries payload through the harness seam so
        // getContractData surfaces .failure(.requestFailed); this proves the
        // existence check actually ran rather than being skipped.
        script.setEmptyGetLedgerEntriesResponse()

        do {
            _ = try await h.walletOps.connectToContract(contractId: contractA)
            XCTFail("expected SmartAccountWalletException.NotFound")
        } catch let error as SmartAccountWalletException.NotFound {
            XCTAssertTrue(
                error.message.contains(contractA),
                "not-found error must identify the supplied contract id"
            )
        }

        XCTAssertTrue(
            h.kit.setConnectedStateInvocations.isEmpty,
            "connected state must not be mutated when the existence check fails"
        )
        XCTAssertEqual(
            script.getLedgerEntriesCallCount,
            1,
            "the existence check must have issued exactly one ledger-entry probe"
        )
    }

    // MARK: - 3. Dedicated headless event

    func test_connectToContract_emitsHeadlessEvent() async throws {
        let h = try makeHarness()
        try script.setGetContractDataResponse(contractId: contractA)

        let headlessRecorder = EventRecorder()
        let walletConnectedRecorder = EventRecorder()
        h.kit.events.on(.walletConnectedHeadless) { event in
            headlessRecorder.append(event)
        }
        h.kit.events.on(.walletConnected) { event in
            walletConnectedRecorder.append(event)
        }

        _ = try await h.walletOps.connectToContract(contractId: contractA)

        let headlessEvents = headlessRecorder.snapshot()
        XCTAssertEqual(headlessEvents.count, 1)
        guard case .walletConnectedHeadless(let emittedContractId)? = headlessEvents.first else {
            return XCTFail("expected a walletConnectedHeadless event")
        }
        XCTAssertEqual(emittedContractId, contractA)
        XCTAssertEqual(
            walletConnectedRecorder.snapshot().count,
            0,
            "headless connect must not leak an empty credential onto walletConnected"
        )
    }

    // MARK: - 4. No session saved

    func test_connectToContract_doesNotSaveSession() async throws {
        let h = try makeHarness()
        try script.setGetContractDataResponse(contractId: contractA)

        _ = try await h.walletOps.connectToContract(contractId: contractA)

        let session = try await h.storage.getSession()
        XCTAssertNil(session, "headless connect must not persist a session")
    }

    // MARK: - 5. Pre-existing session cleared

    func test_connectToContract_clearsExistingSession() async throws {
        let h = try makeHarness()
        try await h.storage.saveSession(
            nonExpiredSession(credentialId: "stale-passkey-cred", contractId: contractB)
        )
        // Sanity: the session is present before the headless connect.
        let seeded = try await h.storage.getSession()
        XCTAssertNotNil(seeded)

        try script.setGetContractDataResponse(contractId: contractA)
        _ = try await h.walletOps.connectToContract(contractId: contractA)

        let session = try await h.storage.getSession()
        XCTAssertNil(
            session,
            "a pre-existing passkey session must be cleared so a later silent " +
                "restore cannot resurrect state contradicting the headless connection"
        )
    }

    // MARK: - 6. Credential manager untouched

    func test_connectToContract_doesNotTouchCredentialManager() async throws {
        let h = try makeHarness()
        try script.setGetContractDataResponse(contractId: contractA)

        _ = try await h.walletOps.connectToContract(contractId: contractA)

        XCTAssertTrue(h.credentialManager.createPendingCalls.isEmpty)
        XCTAssertTrue(h.credentialManager.setPrimaryCalls.isEmpty)
        XCTAssertTrue(h.credentialManager.updateLastUsedCalls.isEmpty)
        XCTAssertTrue(h.credentialManager.deleteCredentialCalls.isEmpty)
        XCTAssertTrue(h.credentialManager.markDeploymentFailedCalls.isEmpty)
    }

    // MARK: - 7. Invalid contract id

    func test_connectToContract_invalidContractId_throwsValidation() async throws {
        let h = try makeHarness()

        do {
            _ = try await h.walletOps.connectToContract(contractId: "not-a-contract")
            XCTFail("expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        }

        XCTAssertTrue(
            h.kit.setConnectedStateInvocations.isEmpty,
            "invalid input must not mutate connected state"
        )
        XCTAssertEqual(
            script.getLedgerEntriesCallCount,
            0,
            "address validation must fail before any contract-data RPC is issued"
        )
    }

    // MARK: - 8. No WebAuthn provider required

    func test_connectToContract_worksWithoutWebAuthnProvider() async throws {
        let h = try makeHarness(webauthnProvider: nil)
        XCTAssertNil(h.kit.config.webauthnProvider)
        try script.setGetContractDataResponse(contractId: contractA)

        let result = try await h.walletOps.connectToContract(contractId: contractA)

        XCTAssertEqual(result.contractId, contractA)
        XCTAssertTrue(h.kit.isConnected)
    }

    // MARK: - 9. Headless guard on the single-passkey path

    func test_connectToContract_thenSinglePasskeySubmit_throwsHeadlessGuard() async throws {
        let h = try makeHarness()
        try script.setGetContractDataResponse(contractId: contractA)
        _ = try await h.walletOps.connectToContract(contractId: contractA)

        // Baseline after the headless connect: exactly one ledger-entry probe
        // from the existence check, no simulate calls. Each guarded call below
        // must leave both unchanged, proving the guard fired before any
        // network traffic, deployer fetch, simulation, decode, or WebAuthn.
        let ledgerEntriesBaseline = script.getLedgerEntriesCallCount
        XCTAssertEqual(ledgerEntriesBaseline, 1)
        XCTAssertEqual(script.simulateCallCount, 0)

        /// Asserts the supplied single-passkey call throws the headless guard
        /// error before issuing any network traffic.
        func assertGuardFires(
            _ label: String,
            _ block: () async throws -> Void,
            line: UInt = #line
        ) async {
            do {
                try await block()
                XCTFail("\(label): expected the headless guard to throw", line: line)
            } catch let error as SmartAccountValidationException.InvalidInput {
                XCTAssertTrue(
                    error.message.contains("selectedSigners"),
                    "\(label): guard error must point at selectedSigners",
                    line: line
                )
                XCTAssertTrue(
                    error.message.contains("headlessly"),
                    "\(label): guard error must explain the headless cause",
                    line: line
                )
            } catch {
                XCTFail("\(label): expected InvalidInput, got \(error)", line: line)
            }
            XCTAssertEqual(
                script.getLedgerEntriesCallCount,
                ledgerEntriesBaseline,
                "\(label): no ledger-entry RPC may run before the guard",
                line: line
            )
            XCTAssertEqual(
                script.simulateCallCount,
                0,
                "\(label): no simulation may run before the guard",
                line: line
            )
            XCTAssertTrue(
                h.credentialManager.updateLastUsedCalls.isEmpty,
                "\(label): updateLastUsed must not be reached before the guard",
                line: line
            )
        }

        let hostFn = HostFunctionXDR.invokeContract(
            InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: contractB),
                functionName: "noop",
                args: []
            )
        )

        await assertGuardFires("submit") {
            _ = try await h.kit.transactionOperations.submit(hostFunction: hostFn, auth: [])
        }
        await assertGuardFires("contractCall") {
            _ = try await h.kit.transactionOperations.contractCall(
                target: contractB,
                targetFn: "noop"
            )
        }
        await assertGuardFires("executeAndSubmit") {
            _ = try await h.kit.transactionOperations.executeAndSubmit(
                target: contractB,
                targetFn: "noop"
            )
        }
        await assertGuardFires("removeSigner-default-empty-selectedSigners") {
            _ = try await h.kit.signerManager.removeSigner(
                contextRuleId: 0,
                signerId: 0
            )
        }
    }

    // MARK: - 10. Routing: a non-empty selectedSigners list bypasses the guard

    /// Routing only. Installs a recording multi-signer manager to observe that a
    /// non-empty `selectedSigners` list on a sibling-manager call routes to
    /// ``OZSmartAccountKitProtocol/multiSignerManager`` and the headless guard
    /// does not fire. The override short-circuits before any real signing runs,
    /// so this test proves routing, not credential-safety; the real-pipeline
    /// credential boundary is proven in
    /// ``test_connectToContract_thenRealMultiSignerPipeline_neverReadsConnectedCredential()``.
    func test_connectToContract_nonEmptySelectedSigners_routesToMultiSignerPipeline() async throws {
        let h = try makeHarness()
        try script.setGetContractDataResponse(contractId: contractA)
        _ = try await h.walletOps.connectToContract(contractId: contractA)

        let recordingSubmitter = MockOZMultiSignerManager(kit: h.kit)
        h.kit.multiSignerManagerOverride = recordingSubmitter

        let ed25519Signer = OZSelectedSigner.ed25519(
            verifierAddress: contractB,
            publicKey: Data(repeating: 0x09, count: 32)
        )

        // The same entry point that trips the headless guard with an empty
        // selectedSigners list (test 9) must instead reach the multi-signer
        // pipeline when a non-empty list is supplied. If routing were broken and
        // the call fell into the guarded single-passkey path, the guard would
        // throw here rather than returning a result.
        let result = try await h.kit.signerManager.removeSigner(
            contextRuleId: 0,
            signerId: 0,
            selectedSigners: [ed25519Signer]
        )

        XCTAssertTrue(result.success)
        XCTAssertEqual(
            recordingSubmitter.invocations.count,
            1,
            "a non-empty selectedSigners list must route through the multi-signer pipeline"
        )
        XCTAssertEqual(recordingSubmitter.invocations[0].selectedSigners, [ed25519Signer])
        XCTAssertEqual(
            script.simulateCallCount,
            0,
            "sanity: the recording submitter short-circuits before the real " +
                "signing pipeline, so no simulate RPC is issued in this routing check"
        )
    }

    // MARK: - 11. Real multi-signer pipeline never reads the connected credential

    /// Credential boundary, proven against the REAL ``OZMultiSignerManager`` with
    /// no recording override. After a headless connect records the empty
    /// credential sentinel, an Ed25519-signed ``multiSignerContractCall`` drives
    /// the production signing pipeline end-to-end to submission against the
    /// scripted Soroban server. The pipeline reads only
    /// ``ConnectedState/contractId`` and never ``ConnectedState/credentialId``,
    /// so a sentinel-credential connection submits cleanly and `updateLastUsed`
    /// (the sole consumer of the connected credential) is never invoked. This is
    /// the practical proof of the boundary that the mocked routing check in
    /// test 10 cannot give.
    func test_connectToContract_thenRealMultiSignerPipeline_neverReadsConnectedCredential() async throws {
        let storage = OZInMemoryStorageAdapter()
        let deployer = try deterministicDeployer(seed: 0x5A)
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: contractA,
            deployerKeypair: deployer,
            webauthnProvider: nil,
            storage: storage
        )
        let credentialManager = MockCredentialManager(storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer(),
            credentialManager: credentialManager
        )
        kit.configuredDeployer = deployer
        let walletOps = OZWalletOperations(kit: kit)

        // 1) Headless connect against contractA. This consumes the contract-data
        //    existence probe (the single getLedgerEntries result).
        try script.setGetContractDataResponse(contractId: contractA)
        _ = try await walletOps.connectToContract(contractId: contractA)
        XCTAssertEqual(
            kit.currentConnectedState?.credentialId,
            OZConstants.headlessCredentialIdSentinel,
            "precondition: the connection must hold the empty credential sentinel"
        )

        // 2) Register an in-memory Ed25519 external signer whose verifier is the
        //    connected smart-account contract.
        let extMgr = OZExternalSignerManager(networkPassphrase: Network.testnet.passphrase)
        kit.externalSignersOverride = extMgr
        let ed25519PublicKey = try await extMgr.addEd25519FromRawKey(
            secretKeyBytes: Data(0x00 ..< 0x20),
            verifierAddress: contractA
        )

        // 3) Script the full submission pipeline. setGetAccountResponse replaces
        //    the contract-data getLedgerEntries result consumed by the connect
        //    above, so the deployer-account fetch now succeeds.
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 17)
        let authEntry = try OZPipelineFixtures.addressCredentialsAuthEntry(
            contractAddress: contractA,
            targetContract: contractB,
            targetFn: "noop"
        )
        script.enqueueSimulate(authEntries: [authEntry])
        script.setGetLatestLedger(sequence: 1000)
        script.enqueueSimulate(authEntries: [], minResourceFee: 200)
        script.setSendSuccess(
            status: SendTransactionResponse.STATUS_PENDING,
            hash: "headless-multisigner-hash"
        )
        script.enqueueGetTransactionResponse(
            status: GetTransactionResponse.STATUS_SUCCESS,
            ledger: 1002
        )

        // 4) Drive the REAL multi-signer manager to submission.
        let result = try await kit.multiSignerManager.multiSignerContractCall(
            target: contractB,
            targetFn: "noop",
            selectedSigners: [
                .ed25519(verifierAddress: contractA, publicKey: ed25519PublicKey)
            ]
        )

        XCTAssertTrue(
            result.success,
            "the multi-signer pipeline must submit cleanly on a sentinel-credential " +
                "connection, got error: \(result.error ?? "nil")"
        )
        XCTAssertEqual(result.hash, "headless-multisigner-hash")
        XCTAssertEqual(
            script.sendCallCount,
            1,
            "the real pipeline must reach submission exactly once"
        )
        XCTAssertTrue(
            credentialManager.updateLastUsedCalls.isEmpty,
            "the real multi-signer pipeline must never read connected.credentialId; " +
                "updateLastUsed is its only consumer and must stay uninvoked for a " +
                "sentinel-credential connection"
        )
        XCTAssertEqual(
            kit.currentConnectedState?.credentialId,
            OZConstants.headlessCredentialIdSentinel,
            "the connection must remain headless throughout the submission"
        )
    }

    // MARK: - Hardening: passkey connect cannot adopt the headless sentinel

    func test_connectWithCredentials_emptyCredentialId_throwsValidation() async throws {
        let h = try makeHarness()

        do {
            _ = try await h.walletOps.connectWallet(
                options: OZConnectWalletOptions(credentialId: "")
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("credentialId"))
        }

        XCTAssertTrue(
            h.kit.setConnectedStateInvocations.isEmpty,
            "a blank credential id must be rejected before any connected-state write"
        )
    }

    func test_connectWithCredentials_purePaddingCredentialId_throwsValidation() async throws {
        let h = try makeHarness()

        // A pure-padding credential id is neither empty nor whitespace, so it
        // clears the blank check, but Base64URL padding stripping collapses it to
        // the empty headless sentinel. It must be rejected so a passkey connect
        // can never adopt the sentinel and trip the headless guard.
        do {
            _ = try await h.walletOps.connectWallet(
                options: OZConnectWalletOptions(credentialId: "==")
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("credentialId"))
        }

        XCTAssertTrue(
            h.kit.setConnectedStateInvocations.isEmpty,
            "a credential id that normalizes to empty must be rejected before any " +
                "connected-state write"
        )
    }
}
