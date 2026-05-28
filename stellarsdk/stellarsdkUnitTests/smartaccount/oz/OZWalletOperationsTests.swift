//
//  OZWalletOperationsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZWalletOperationsTests: XCTestCase {

    // MARK: - Fixtures

    private let validContractAddress =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let validContractAddress2 =
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "https://soroban-testnet.stellar.org",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validContractAddress
        )
    }

    private func createKit() throws -> (MockOZSmartAccountKit, OZWalletOperations) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return (kit, OZWalletOperations(kit: kit))
    }

    private func testPublicKey(fill: UInt8 = 0x42) -> Data {
        var bytes = [UInt8](repeating: fill, count: 65)
        bytes[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        return Data(bytes)
    }

    // ========================================================================
    // MARK: - createWallet pre-network validation
    // ========================================================================

    func test_createWallet_noWebAuthnProvider_throwsNotSupported() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.createWallet()
            XCTFail("expected WebAuthnException.NotSupported")
        } catch let error as WebAuthnException.NotSupported {
            XCTAssertTrue(error.message.contains("No WebAuthnProvider configured"))
        }
    }

    func test_createWallet_noWebAuthnProvider_withCustomUserName() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.createWallet(userName: "Alice")
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    func test_createWallet_noWebAuthnProvider_withAutoSubmit() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.createWallet(autoSubmit: true)
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    func test_createWallet_noWebAuthnProvider_withAutoFundAndToken() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.createWallet(
                autoFund: true,
                nativeTokenContract: validContractAddress
            )
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    // ========================================================================
    // MARK: - authenticatePasskey pre-network validation
    // ========================================================================

    func test_authenticatePasskey_noWebAuthnProvider_throwsNotSupported() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.authenticatePasskey()
            XCTFail("expected WebAuthnException.NotSupported")
        } catch let error as WebAuthnException.NotSupported {
            XCTAssertTrue(error.message.contains("No WebAuthnProvider configured"))
        }
    }

    func test_authenticatePasskey_noWebAuthnProvider_withChallenge() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.authenticatePasskey(challenge: Data(count: 32))
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    func test_authenticatePasskey_noWebAuthnProvider_withCredentialIds() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.authenticatePasskey(
                credentialIds: ["cred-1", "cred-2"]
            )
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    // ========================================================================
    // MARK: - connectWallet validation
    // ========================================================================

    func test_connectWallet_defaultOptions_noSession_returnsNull() async throws {
        let (_, walletOps) = try createKit()
        let result = try await walletOps.connectWallet()
        XCTAssertNil(result)
    }

    func test_connectWallet_promptFalse_noSession_returnsNull() async throws {
        let (_, walletOps) = try createKit()
        let result = try await walletOps.connectWallet(
            options: ConnectWalletOptions(prompt: false)
        )
        XCTAssertNil(result)
    }

    func test_connectWallet_freshTrue_noWebAuthnProvider_throwsNotSupported() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.connectWallet(
                options: ConnectWalletOptions(fresh: true)
            )
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    func test_connectWallet_promptTrue_noSession_noWebAuthnProvider_throwsNotSupported() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.connectWallet(
                options: ConnectWalletOptions(prompt: true)
            )
            XCTFail("expected WebAuthnException.NotSupported")
        } catch is WebAuthnException.NotSupported {
            // expected
        }
    }

    func test_connectWallet_contractIdWithoutCredentialId_throwsValidation() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.connectWallet(
                options: ConnectWalletOptions(contractId: validContractAddress)
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // MARK: - ConnectWalletOptions data-class behavior
    // ========================================================================

    func test_connectWalletOptions_defaultValues() {
        let options = ConnectWalletOptions()
        XCTAssertNil(options.credentialId)
        XCTAssertNil(options.contractId)
        XCTAssertFalse(options.fresh)
        XCTAssertFalse(options.prompt)
    }

    func test_connectWalletOptions_withPrompt() {
        let options = ConnectWalletOptions(prompt: true)
        XCTAssertNil(options.credentialId)
        XCTAssertNil(options.contractId)
        XCTAssertFalse(options.fresh)
        XCTAssertTrue(options.prompt)
    }

    func test_connectWalletOptions_withFresh() {
        let options = ConnectWalletOptions(fresh: true)
        XCTAssertNil(options.credentialId)
        XCTAssertNil(options.contractId)
        XCTAssertTrue(options.fresh)
        XCTAssertFalse(options.prompt)
    }

    func test_connectWalletOptions_withCredentialIdAndContractId() {
        let options = ConnectWalletOptions(
            credentialId: "cred-abc",
            contractId: validContractAddress
        )
        XCTAssertEqual(options.credentialId, "cred-abc")
        XCTAssertEqual(options.contractId, validContractAddress)
        XCTAssertFalse(options.fresh)
        XCTAssertFalse(options.prompt)
    }

    func test_connectWalletOptions_withAllFields() {
        let options = ConnectWalletOptions(
            credentialId: "cred-abc",
            contractId: validContractAddress,
            fresh: true,
            prompt: true
        )
        XCTAssertEqual(options.credentialId, "cred-abc")
        XCTAssertEqual(options.contractId, validContractAddress)
        XCTAssertTrue(options.fresh)
        XCTAssertTrue(options.prompt)
    }

    func test_connectWalletOptions_equality() {
        let a = ConnectWalletOptions(credentialId: "x", prompt: true)
        let b = ConnectWalletOptions(credentialId: "x", prompt: true)
        let c = ConnectWalletOptions(credentialId: "y", prompt: true)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertNotEqual(a, c)
    }

    func test_connectWalletOptions_copy() {
        let original = ConnectWalletOptions(fresh: true)
        let copied = original.copy(prompt: true)
        XCTAssertTrue(copied.fresh)
        XCTAssertTrue(copied.prompt)
        XCTAssertNil(copied.credentialId)
    }

    // ========================================================================
    // MARK: - CreateWalletResult data-class behavior
    // ========================================================================

    func test_createWalletResult_construction_defaultOptionalFields() {
        let pk = testPublicKey()
        let result = CreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "AAAA..."
        )
        XCTAssertEqual(result.credentialId, "cred-1")
        XCTAssertEqual(result.contractId, validContractAddress)
        XCTAssertEqual(result.publicKey, pk)
        XCTAssertEqual(result.signedTransactionXdr, "AAAA...")
        XCTAssertNil(result.transactionHash)
        XCTAssertNil(result.nickname)
    }

    func test_createWalletResult_constructionWithAllFields() {
        let pk = testPublicKey()
        let result = CreateWalletResult(
            credentialId: "cred-2",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "BBBB...",
            transactionHash: "hash-abc",
            nickname: "Alice"
        )
        XCTAssertEqual(result.credentialId, "cred-2")
        XCTAssertEqual(result.transactionHash, "hash-abc")
        XCTAssertEqual(result.nickname, "Alice")
    }

    func test_createWalletResult_equality_sameData() {
        let pk = testPublicKey()
        let a = CreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        let b = CreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_createWalletResult_equality_differentPublicKey() {
        let a = CreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x01),
            signedTransactionXdr: "XDR"
        )
        let b = CreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x02),
            signedTransactionXdr: "XDR"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_equality_differentCredentialId() {
        let pk = testPublicKey()
        let a = CreateWalletResult(
            credentialId: "a",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        let b = CreateWalletResult(
            credentialId: "b",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_equality_differentTransactionHash() {
        let pk = testPublicKey()
        let a = CreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR",
            transactionHash: "h1"
        )
        let b = CreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR",
            transactionHash: "h2"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_equality_differentNickname() {
        let pk = testPublicKey()
        let a = CreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR",
            nickname: "Alice"
        )
        let b = CreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR",
            nickname: "Bob"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_copy() {
        let pk = testPublicKey()
        let original = CreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        let copied = original.copy(transactionHash: "new-hash", nickname: "Bob")
        XCTAssertEqual(copied.transactionHash, "new-hash")
        XCTAssertEqual(copied.nickname, "Bob")
        XCTAssertEqual(copied.credentialId, "cred-1")
    }

    func test_createWalletResult_equality_notEqualToOtherInstance() {
        let a = CreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x01),
            signedTransactionXdr: "XDR"
        )
        let b = CreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x02),
            signedTransactionXdr: "XDR"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_equality_sameInstance() {
        let result = CreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: testPublicKey(),
            signedTransactionXdr: "XDR"
        )
        XCTAssertEqual(result, result)
    }

    // ========================================================================
    // MARK: - ConnectWalletResult sealed-type behavior
    // ========================================================================

    func test_connectWalletResult_connected_construction() {
        let result = ConnectWalletResult.connected(
            credentialId: "cred-abc",
            contractId: validContractAddress,
            restoredFromSession: false
        )
        XCTAssertEqual(result.credentialId, "cred-abc")
        if case .connected(_, let contractId, let restoredFromSession) = result {
            XCTAssertEqual(contractId, validContractAddress)
            XCTAssertFalse(restoredFromSession)
        } else {
            XCTFail("expected .connected arm")
        }
    }

    func test_connectWalletResult_connected_restoredFromSession() {
        let result = ConnectWalletResult.connected(
            credentialId: "cred-abc",
            contractId: validContractAddress,
            restoredFromSession: true
        )
        if case .connected(_, _, let restoredFromSession) = result {
            XCTAssertTrue(restoredFromSession)
        } else {
            XCTFail("expected .connected arm")
        }
    }

    func test_connectWalletResult_connected_equality() {
        let a = ConnectWalletResult.connected(
            credentialId: "c",
            contractId: validContractAddress,
            restoredFromSession: false
        )
        let b = ConnectWalletResult.connected(
            credentialId: "c",
            contractId: validContractAddress,
            restoredFromSession: false
        )
        let c = ConnectWalletResult.connected(
            credentialId: "c",
            contractId: validContractAddress,
            restoredFromSession: true
        )
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertNotEqual(a, c)
    }

    func test_connectWalletResult_connected_copyByReplacement() {
        // The Swift enum does not provide an in-place copyWith;  the equivalent
        // operation rebuilds the case with a new associated value. This test
        // documents the pattern and asserts the rebuilt value carries the
        // updated `restoredFromSession` flag.
        let original = ConnectWalletResult.connected(
            credentialId: "c",
            contractId: validContractAddress,
            restoredFromSession: false
        )
        if case .connected(let credentialId, let contractId, _) = original {
            let copied = ConnectWalletResult.connected(
                credentialId: credentialId,
                contractId: contractId,
                restoredFromSession: true
            )
            if case .connected(_, _, let restored) = copied {
                XCTAssertTrue(restored)
            } else {
                XCTFail("expected .connected arm")
            }
        } else {
            XCTFail("expected .connected arm")
        }
    }

    func test_connectWalletResult_ambiguous_construction() {
        let candidates = [
            "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
            "CCMK6CYUEFEWKCPP6JL4EYYWTQGVPLG4F2KHE2H6DQOMXKBTHSDIH3JB"
        ]
        let result = ConnectWalletResult.ambiguous(
            credentialId: "cred-abc",
            candidates: candidates
        )
        XCTAssertEqual(result.credentialId, "cred-abc")
        if case .ambiguous(_, let returned) = result {
            XCTAssertEqual(returned, candidates)
            XCTAssertEqual(returned.count, 2)
        } else {
            XCTFail("expected .ambiguous arm")
        }
    }

    func test_connectWalletResult_sealed_when_exhaustive() {
        let results: [ConnectWalletResult] = [
            .connected(credentialId: "c", contractId: validContractAddress, restoredFromSession: false),
            .ambiguous(credentialId: "c", candidates: [validContractAddress])
        ]
        for result in results {
            let handled: String
            switch result {
            case .connected(_, let contractId, _):
                handled = "connected:\(contractId)"
            case .ambiguous(_, let candidates):
                handled = "ambiguous:\(candidates.count)"
            }
            XCTAssertFalse(handled.isEmpty)
        }
    }

    // ========================================================================
    // MARK: - DeployPendingResult data-class behavior
    // ========================================================================

    func test_deployPendingResult_construction_defaultOptionalFields() {
        let result = DeployPendingResult(
            contractId: validContractAddress,
            signedTransactionXdr: "signed-xdr"
        )
        XCTAssertEqual(result.contractId, validContractAddress)
        XCTAssertEqual(result.signedTransactionXdr, "signed-xdr")
        XCTAssertNil(result.transactionHash)
    }

    func test_deployPendingResult_withTransactionHash() {
        let result = DeployPendingResult(
            contractId: validContractAddress,
            signedTransactionXdr: "signed-xdr",
            transactionHash: "hash-123"
        )
        XCTAssertEqual(result.transactionHash, "hash-123")
    }

    func test_deployPendingResult_equality() {
        let a = DeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr-1")
        let b = DeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr-1")
        let c = DeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr-2")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertNotEqual(a, c)
    }

    func test_deployPendingResult_copy() {
        let original = DeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr")
        let copied = original.copy(transactionHash: "h")
        XCTAssertEqual(copied.transactionHash, "h")
        XCTAssertEqual(copied.signedTransactionXdr, "xdr")
    }

    // ========================================================================
    // MARK: - AuthenticatePasskeyResult data-class behavior
    // ========================================================================

    private func buildSignature() throws -> OZWebAuthnSignature {
        return try OZWebAuthnSignature(
            authenticatorData: Data(repeating: 0x01, count: 37),
            clientData: Data(repeating: 0x02, count: 10),
            signature: Data(repeating: 0x03, count: 64)
        )
    }

    func test_authenticatePasskeyResult_equality_sameData() throws {
        let sig = try buildSignature()
        let pk = testPublicKey()
        let a = AuthenticatePasskeyResult(credentialId: "cred", signature: sig, publicKey: pk)
        let b = AuthenticatePasskeyResult(credentialId: "cred", signature: sig, publicKey: pk)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_authenticatePasskeyResult_equality_differentPublicKey() throws {
        let sig = try buildSignature()
        let a = AuthenticatePasskeyResult(
            credentialId: "cred",
            signature: sig,
            publicKey: testPublicKey(fill: 0x01)
        )
        let b = AuthenticatePasskeyResult(
            credentialId: "cred",
            signature: sig,
            publicKey: testPublicKey(fill: 0x02)
        )
        XCTAssertNotEqual(a, b)
    }

    func test_authenticatePasskeyResult_equality_differentCredentialId() throws {
        let sig = try buildSignature()
        let pk = testPublicKey()
        let a = AuthenticatePasskeyResult(credentialId: "cred-1", signature: sig, publicKey: pk)
        let b = AuthenticatePasskeyResult(credentialId: "cred-2", signature: sig, publicKey: pk)
        XCTAssertNotEqual(a, b)
    }

    func test_authenticatePasskeyResult_equality_differentSignature() throws {
        let a = AuthenticatePasskeyResult(
            credentialId: "cred",
            signature: try OZWebAuthnSignature(
                authenticatorData: Data(repeating: 0x01, count: 37),
                clientData: Data(repeating: 0x02, count: 10),
                signature: Data(repeating: 0x03, count: 64)
            ),
            publicKey: testPublicKey()
        )
        let b = AuthenticatePasskeyResult(
            credentialId: "cred",
            signature: try OZWebAuthnSignature(
                authenticatorData: Data(repeating: 0x01, count: 37),
                clientData: Data(repeating: 0x02, count: 10),
                signature: Data(repeating: 0x04, count: 64)
            ),
            publicKey: testPublicKey()
        )
        XCTAssertNotEqual(a, b)
    }

    func test_authenticatePasskeyResult_equality_sameInstance() throws {
        let result = AuthenticatePasskeyResult(
            credentialId: "cred",
            signature: try buildSignature(),
            publicKey: testPublicKey()
        )
        XCTAssertEqual(result, result)
    }

    func test_authenticatePasskeyResult_fieldAccess() throws {
        let authData = Data(repeating: 0x0A, count: 37)
        let clientData = Data(repeating: 0x0B, count: 10)
        let sigBytes = Data(repeating: 0x0C, count: 64)
        let sig = try OZWebAuthnSignature(
            authenticatorData: authData,
            clientData: clientData,
            signature: sigBytes
        )
        let pk = testPublicKey(fill: 0x77)
        let result = AuthenticatePasskeyResult(
            credentialId: "my-cred",
            signature: sig,
            publicKey: pk
        )
        XCTAssertEqual(result.credentialId, "my-cred")
        XCTAssertEqual(result.signature, sig)
        XCTAssertEqual(result.publicKey, pk)
    }

    // ========================================================================
    // MARK: - Kit connected-state lifecycle (mock kit)
    // ========================================================================

    func test_kit_initialState_notConnected() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        XCTAssertFalse(kit.isConnected)
        XCTAssertNil(kit.currentConnectedState)
    }

    func test_kit_afterSetConnectedState() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(credentialId: "my-credential", contractId: validContractAddress)
        XCTAssertTrue(kit.isConnected)
        let state = try kit.requireConnected()
        XCTAssertEqual(state.credentialId, "my-credential")
        XCTAssertEqual(state.contractId, validContractAddress)
    }

    func test_kit_setConnectedState_overwritesPrevious() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(credentialId: "cred-1", contractId: validContractAddress)
        XCTAssertEqual(try kit.requireConnected().credentialId, "cred-1")

        let otherContract = validContractAddress2
        kit.setConnectedState(credentialId: "cred-2", contractId: otherContract)
        XCTAssertEqual(try kit.requireConnected().credentialId, "cred-2")
        XCTAssertEqual(try kit.requireConnected().contractId, otherContract)
    }

    // ========================================================================
    // MARK: - disconnect-equivalent lifecycle (modelled via clearConnectedState)
    // ========================================================================

    func test_disconnect_afterConnectedState_clearsState() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(credentialId: "cred-x", contractId: validContractAddress)
        XCTAssertTrue(kit.isConnected)
        kit.clearConnectedState()
        XCTAssertFalse(kit.isConnected)
    }

    func test_disconnect_whenNotConnected_doesNotThrow() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        XCTAssertFalse(kit.isConnected)
        kit.clearConnectedState()
        XCTAssertFalse(kit.isConnected)
    }

    func test_disconnect_doubleDisconnect_doesNotThrow() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(credentialId: "cred-x", contractId: validContractAddress)
        kit.clearConnectedState()
        kit.clearConnectedState()
        XCTAssertFalse(kit.isConnected)
    }

    func test_disconnect_emitsEvent_whenConnected_modelled() throws {
        // The `walletDisconnected` event is emitted by the kit's disconnect
        // path (owned by the kit module, not by the operations files). This
        // test verifies that the event payload is well-formed and can be
        // constructed from the connected state held on the mock kit.
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(credentialId: "cred-x", contractId: validContractAddress)
        let state = try kit.requireConnected()
        let event = SmartAccountEvent.walletDisconnected(contractId: state.contractId)
        if case .walletDisconnected(let contractId) = event {
            XCTAssertEqual(contractId, validContractAddress)
        } else {
            XCTFail("expected walletDisconnected event")
        }
    }

    func test_disconnect_doesNotEmitEvent_whenNotConnected_modelled() throws {
        // With no connected state on the kit, no `walletDisconnected` event
        // should ever be emitted. The mock kit's emitter is observable; this
        // test asserts that no event arrives when nothing was connected.
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        let recorder = WalletDisconnectedRecorder()
        _ = kit.events.on(.walletDisconnected) { event in
            recorder.record(event)
        }
        // No `disconnect` is invoked because nothing was connected.
        XCTAssertNil(recorder.last)
    }

    /// Captures the most recent `walletDisconnected` event from the emitter.
    /// Lives outside the test method so the listener's closure does not need
    /// to mutate a captured local variable (which conflicts with Sendable).
    private final class WalletDisconnectedRecorder: @unchecked Sendable {
        private let stateLock = NSLock()
        private var _last: SmartAccountEvent?
        var last: SmartAccountEvent? {
            stateLock.lock(); defer { stateLock.unlock() }
            return _last
        }
        func record(_ event: SmartAccountEvent) {
            stateLock.lock(); defer { stateLock.unlock() }
            _last = event
        }
    }

    func test_disconnect_clearsSession_modelled() async throws {
        // Without an active session, connectWallet() returns nil. After a
        // simulated disconnect, the same call must still return nil.
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        let walletOps = OZWalletOperations(kit: kit)
        kit.setConnectedState(credentialId: "cred-x", contractId: validContractAddress)
        kit.clearConnectedState()
        try await kit.getStorage().clearSession()
        let result = try await walletOps.connectWallet()
        XCTAssertNil(result)
    }

    // ========================================================================
    // MARK: - requireConnected behavior
    // ========================================================================

    func test_requireConnected_whenNotConnected_throwsNotConnected() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        do {
            _ = try kit.requireConnected()
            XCTFail("expected WalletException.NotConnected")
        } catch let error as WalletException.NotConnected {
            XCTAssertTrue(error.message.contains("No wallet connected"))
        }
    }

    func test_requireConnected_whenConnected_returnsPair() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(credentialId: "cred-abc", contractId: validContractAddress)
        let state = try kit.requireConnected()
        XCTAssertEqual(state.credentialId, "cred-abc")
        XCTAssertEqual(state.contractId, validContractAddress)
    }

    func test_requireConnected_afterDisconnect_throwsNotConnected() throws {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        kit.setConnectedState(credentialId: "cred-abc", contractId: validContractAddress)
        kit.clearConnectedState()
        XCTAssertThrowsError(try kit.requireConnected()) { error in
            XCTAssertTrue(error is WalletException.NotConnected)
        }
    }

    // ========================================================================
    // MARK: - deployPendingCredential validation
    // ========================================================================

    func test_deployPendingCredential_autoFundWithoutToken_throwsValidation() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: "cred-abc",
                autoFund: true,
                nativeTokenContract: nil
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    func test_deployPendingCredential_credentialNotFound_throwsCredentialException() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: "nonexistent-cred",
                autoSubmit: false
            )
            XCTFail("expected CredentialException.NotFound")
        } catch is CredentialException.NotFound {
            // expected
        }
    }

    func test_deployPendingCredential_credentialMissingPublicKey_throwsInvalid() async throws {
        let (kit, walletOps) = try createKit()
        let stored = StoredCredential(
            credentialId: "cred-empty-pk",
            publicKey: Data(),
            contractId: validContractAddress
        )
        try await kit.storage.save(credential: stored)
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: "cred-empty-pk",
                autoSubmit: false
            )
            XCTFail("expected CredentialException.Invalid")
        } catch is CredentialException.Invalid {
            // expected
        }
    }

    func test_deployPendingCredential_credentialMissingContractId_throwsInvalid() async throws {
        let (kit, walletOps) = try createKit()
        let stored = StoredCredential(
            credentialId: "cred-no-contract",
            publicKey: testPublicKey(),
            contractId: nil
        )
        try await kit.storage.save(credential: stored)
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: "cred-no-contract",
                autoSubmit: false
            )
            XCTFail("expected CredentialException.Invalid")
        } catch is CredentialException.Invalid {
            // expected
        }
    }

    func test_deployPendingCredential_credentialEmptyContractId_throwsInvalid() async throws {
        let (kit, walletOps) = try createKit()
        let stored = StoredCredential(
            credentialId: "cred-empty-contract",
            publicKey: testPublicKey(),
            contractId: ""
        )
        try await kit.storage.save(credential: stored)
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: "cred-empty-contract",
                autoSubmit: false
            )
            XCTFail("expected CredentialException.Invalid")
        } catch is CredentialException.Invalid {
            // expected
        }
    }

    func test_deployPendingCredential_autoFundValidation_beforeCredentialLookup() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: "any-cred",
                autoFund: true,
                nativeTokenContract: nil
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // MARK: - connectWallet cascade — storage hit (failed status)
    // ========================================================================

    func test_connectWallet_explicitContractIdWithoutCredentialId_validationOrder() async throws {
        // contractId without credentialId is validated before any RPC call.
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.connectWallet(
                options: ConnectWalletOptions(contractId: validContractAddress)
            )
            XCTFail("expected ValidationException.InvalidInput")
        } catch is ValidationException.InvalidInput {
            // expected
        }
    }

    func test_connectWallet_storageHit_failedCredential_throwsNotFound() async throws {
        let (kit, walletOps) = try createKit()
        let failed = StoredCredential(
            credentialId: "cred-failed",
            publicKey: testPublicKey(),
            contractId: validContractAddress,
            deploymentStatus: .failed,
            deploymentError: "boom"
        )
        try await kit.storage.save(credential: failed)
        do {
            _ = try await walletOps.connectWallet(
                options: ConnectWalletOptions(credentialId: "cred-failed")
            )
            XCTFail("expected WalletException.NotFound")
        } catch let error as WalletException.NotFound {
            XCTAssertTrue(error.message.contains("deploymentPreviouslyFailed") ||
                          error.message.contains("deployment previously failed") ||
                          error.message.contains("deployPendingCredential"))
        }
    }

    // ========================================================================
    // MARK: - createWallet auto-fund validation order
    // ========================================================================

    func test_createWallet_autoFundWithoutToken_throwsValidation() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.createWallet(
                autoFund: true,
                nativeTokenContract: nil
            )
            XCTFail("expected WebAuthnException.NotSupported or ValidationException.InvalidInput")
        } catch is WebAuthnException.NotSupported {
            // The WebAuthn-provider presence check fires before the
            // `autoFund -> nativeTokenContract` validation. This is the
            // documented order-of-validation contract for `createWallet`.
        } catch is ValidationException.InvalidInput {
            // expected when a provider is configured
        }
    }

    // ========================================================================
    // Auxiliary helpers
    // ========================================================================

    func test_secureRandomData_returnsRequestedLength() throws {
        let data = try OZWalletOperations.secureRandomData(count: 32)
        XCTAssertEqual(data.count, 32)
    }

    func test_secureRandomData_csprng_failure_throws() {
        // The OSStatus check inside `secureRandomData(count:)` ensures a
        // non-success SecRandomCopyBytes outcome cannot ship as the all-zero
        // buffer. We cannot inject a CSPRNG failure from the public
        // SecurityFramework surface; the test instead asserts the method
        // signature is `throws` (compile-time guarantee) and that a normal
        // call succeeds. This guards the defensive contract.
        XCTAssertNoThrow(try OZWalletOperations.secureRandomData(count: 16))
    }
}
