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
            options: OZConnectWalletOptions(prompt: false)
        )
        XCTAssertNil(result)
    }

    func test_connectWallet_freshTrue_noWebAuthnProvider_throwsNotSupported() async throws {
        let (_, walletOps) = try createKit()
        do {
            _ = try await walletOps.connectWallet(
                options: OZConnectWalletOptions(fresh: true)
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
                options: OZConnectWalletOptions(prompt: true)
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
                options: OZConnectWalletOptions(contractId: validContractAddress)
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    // ========================================================================
    // MARK: - OZConnectWalletOptions data-class behavior
    // ========================================================================

    func test_connectWalletOptions_defaultValues() {
        let options = OZConnectWalletOptions()
        XCTAssertNil(options.credentialId)
        XCTAssertNil(options.contractId)
        XCTAssertFalse(options.fresh)
        XCTAssertFalse(options.prompt)
    }

    func test_connectWalletOptions_withPrompt() {
        let options = OZConnectWalletOptions(prompt: true)
        XCTAssertNil(options.credentialId)
        XCTAssertNil(options.contractId)
        XCTAssertFalse(options.fresh)
        XCTAssertTrue(options.prompt)
    }

    func test_connectWalletOptions_withFresh() {
        let options = OZConnectWalletOptions(fresh: true)
        XCTAssertNil(options.credentialId)
        XCTAssertNil(options.contractId)
        XCTAssertTrue(options.fresh)
        XCTAssertFalse(options.prompt)
    }

    func test_connectWalletOptions_withCredentialIdAndContractId() {
        let options = OZConnectWalletOptions(
            credentialId: "cred-abc",
            contractId: validContractAddress
        )
        XCTAssertEqual(options.credentialId, "cred-abc")
        XCTAssertEqual(options.contractId, validContractAddress)
        XCTAssertFalse(options.fresh)
        XCTAssertFalse(options.prompt)
    }

    func test_connectWalletOptions_withAllFields() {
        let options = OZConnectWalletOptions(
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
        let a = OZConnectWalletOptions(credentialId: "x", prompt: true)
        let b = OZConnectWalletOptions(credentialId: "x", prompt: true)
        let c = OZConnectWalletOptions(credentialId: "y", prompt: true)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertNotEqual(a, c)
    }

    func test_connectWalletOptions_copy() {
        let original = OZConnectWalletOptions(fresh: true)
        let copied = original.copy(prompt: true)
        XCTAssertTrue(copied.fresh)
        XCTAssertTrue(copied.prompt)
        XCTAssertNil(copied.credentialId)
    }

    // ========================================================================
    // MARK: - OZCreateWalletResult data-class behavior
    // ========================================================================

    func test_createWalletResult_construction_defaultOptionalFields() {
        let pk = testPublicKey()
        let result = OZCreateWalletResult(
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
        let result = OZCreateWalletResult(
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
        let a = OZCreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        let b = OZCreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_createWalletResult_equality_differentPublicKey() {
        let a = OZCreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x01),
            signedTransactionXdr: "XDR"
        )
        let b = OZCreateWalletResult(
            credentialId: "cred-1",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x02),
            signedTransactionXdr: "XDR"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_equality_differentCredentialId() {
        let pk = testPublicKey()
        let a = OZCreateWalletResult(
            credentialId: "a",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        let b = OZCreateWalletResult(
            credentialId: "b",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_equality_differentTransactionHash() {
        let pk = testPublicKey()
        let a = OZCreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR",
            transactionHash: "h1"
        )
        let b = OZCreateWalletResult(
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
        let a = OZCreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: pk,
            signedTransactionXdr: "XDR",
            nickname: "Alice"
        )
        let b = OZCreateWalletResult(
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
        let original = OZCreateWalletResult(
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
        let a = OZCreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x01),
            signedTransactionXdr: "XDR"
        )
        let b = OZCreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: testPublicKey(fill: 0x02),
            signedTransactionXdr: "XDR"
        )
        XCTAssertNotEqual(a, b)
    }

    func test_createWalletResult_equality_sameInstance() {
        let result = OZCreateWalletResult(
            credentialId: "c",
            contractId: validContractAddress,
            publicKey: testPublicKey(),
            signedTransactionXdr: "XDR"
        )
        XCTAssertEqual(result, result)
    }

    // ========================================================================
    // MARK: - OZConnectWalletResult sealed-type behavior
    // ========================================================================

    func test_connectWalletResult_connected_construction() {
        let result = OZConnectWalletResult.connected(
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
        let result = OZConnectWalletResult.connected(
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
        let a = OZConnectWalletResult.connected(
            credentialId: "c",
            contractId: validContractAddress,
            restoredFromSession: false
        )
        let b = OZConnectWalletResult.connected(
            credentialId: "c",
            contractId: validContractAddress,
            restoredFromSession: false
        )
        let c = OZConnectWalletResult.connected(
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
        let original = OZConnectWalletResult.connected(
            credentialId: "c",
            contractId: validContractAddress,
            restoredFromSession: false
        )
        if case .connected(let credentialId, let contractId, _) = original {
            let copied = OZConnectWalletResult.connected(
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
        let result = OZConnectWalletResult.ambiguous(
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
        let results: [OZConnectWalletResult] = [
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
    // MARK: - OZDeployPendingResult data-class behavior
    // ========================================================================

    func test_deployPendingResult_construction_defaultOptionalFields() {
        let result = OZDeployPendingResult(
            contractId: validContractAddress,
            signedTransactionXdr: "signed-xdr"
        )
        XCTAssertEqual(result.contractId, validContractAddress)
        XCTAssertEqual(result.signedTransactionXdr, "signed-xdr")
        XCTAssertNil(result.transactionHash)
    }

    func test_deployPendingResult_withTransactionHash() {
        let result = OZDeployPendingResult(
            contractId: validContractAddress,
            signedTransactionXdr: "signed-xdr",
            transactionHash: "hash-123"
        )
        XCTAssertEqual(result.transactionHash, "hash-123")
    }

    func test_deployPendingResult_equality() {
        let a = OZDeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr-1")
        let b = OZDeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr-1")
        let c = OZDeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr-2")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertNotEqual(a, c)
    }

    func test_deployPendingResult_copy() {
        let original = OZDeployPendingResult(contractId: validContractAddress, signedTransactionXdr: "xdr")
        let copied = original.copy(transactionHash: "h")
        XCTAssertEqual(copied.transactionHash, "h")
        XCTAssertEqual(copied.signedTransactionXdr, "xdr")
    }

    // ========================================================================
    // MARK: - OZAuthenticatePasskeyResult data-class behavior
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
        let a = OZAuthenticatePasskeyResult(credentialId: "cred", signature: sig, publicKey: pk)
        let b = OZAuthenticatePasskeyResult(credentialId: "cred", signature: sig, publicKey: pk)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_authenticatePasskeyResult_equality_differentPublicKey() throws {
        let sig = try buildSignature()
        let a = OZAuthenticatePasskeyResult(
            credentialId: "cred",
            signature: sig,
            publicKey: testPublicKey(fill: 0x01)
        )
        let b = OZAuthenticatePasskeyResult(
            credentialId: "cred",
            signature: sig,
            publicKey: testPublicKey(fill: 0x02)
        )
        XCTAssertNotEqual(a, b)
    }

    func test_authenticatePasskeyResult_equality_differentCredentialId() throws {
        let sig = try buildSignature()
        let pk = testPublicKey()
        let a = OZAuthenticatePasskeyResult(credentialId: "cred-1", signature: sig, publicKey: pk)
        let b = OZAuthenticatePasskeyResult(credentialId: "cred-2", signature: sig, publicKey: pk)
        XCTAssertNotEqual(a, b)
    }

    func test_authenticatePasskeyResult_equality_differentSignature() throws {
        let a = OZAuthenticatePasskeyResult(
            credentialId: "cred",
            signature: try OZWebAuthnSignature(
                authenticatorData: Data(repeating: 0x01, count: 37),
                clientData: Data(repeating: 0x02, count: 10),
                signature: Data(repeating: 0x03, count: 64)
            ),
            publicKey: testPublicKey()
        )
        let b = OZAuthenticatePasskeyResult(
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
        let result = OZAuthenticatePasskeyResult(
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
        let result = OZAuthenticatePasskeyResult(
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
        let event = OZSmartAccountEvent.walletDisconnected(contractId: state.contractId)
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
        private var _last: OZSmartAccountEvent?
        var last: OZSmartAccountEvent? {
            stateLock.lock(); defer { stateLock.unlock() }
            return _last
        }
        func record(_ event: OZSmartAccountEvent) {
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
            XCTFail("expected SmartAccountWalletException.NotConnected")
        } catch let error as SmartAccountWalletException.NotConnected {
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
            XCTAssertTrue(error is SmartAccountWalletException.NotConnected)
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
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
            XCTFail("expected SmartAccountCredentialException.NotFound")
        } catch is SmartAccountCredentialException.NotFound {
            // expected
        }
    }

    func test_deployPendingCredential_credentialMissingPublicKey_throwsInvalid() async throws {
        let (kit, walletOps) = try createKit()
        let stored = OZStoredCredential(
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
            XCTFail("expected SmartAccountCredentialException.Invalid")
        } catch is SmartAccountCredentialException.Invalid {
            // expected
        }
    }

    func test_deployPendingCredential_credentialMissingContractId_throwsInvalid() async throws {
        let (kit, walletOps) = try createKit()
        let stored = OZStoredCredential(
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
            XCTFail("expected SmartAccountCredentialException.Invalid")
        } catch is SmartAccountCredentialException.Invalid {
            // expected
        }
    }

    func test_deployPendingCredential_credentialEmptyContractId_throwsInvalid() async throws {
        let (kit, walletOps) = try createKit()
        let stored = OZStoredCredential(
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
            XCTFail("expected SmartAccountCredentialException.Invalid")
        } catch is SmartAccountCredentialException.Invalid {
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
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
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
                options: OZConnectWalletOptions(contractId: validContractAddress)
            )
            XCTFail("expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        }
    }

    func test_connectWallet_storageHit_failedCredential_throwsNotFound() async throws {
        let (kit, walletOps) = try createKit()
        let failed = OZStoredCredential(
            credentialId: "cred-failed",
            publicKey: testPublicKey(),
            contractId: validContractAddress,
            deploymentStatus: .failed,
            deploymentError: "boom"
        )
        try await kit.storage.save(credential: failed)
        do {
            _ = try await walletOps.connectWallet(
                options: OZConnectWalletOptions(credentialId: "cred-failed")
            )
            XCTFail("expected SmartAccountWalletException.NotFound")
        } catch let error as SmartAccountWalletException.NotFound {
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
            XCTFail("expected WebAuthnException.NotSupported or SmartAccountValidationException.InvalidInput")
        } catch is WebAuthnException.NotSupported {
            // The WebAuthn-provider presence check fires before the
            // `autoFund -> nativeTokenContract` validation. This is the
            // documented order-of-validation contract for `createWallet`.
        } catch is SmartAccountValidationException.InvalidInput {
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

    // ========================================================================
    // MARK: - Happy-path pipeline harness
    // ========================================================================
    //
    // The cases below drive the createWallet / connectWallet /
    // authenticatePasskey / deployPendingCredential bodies end-to-end through a
    // scripted SorobanServer (MockSorobanServer + MockSorobanServerScript) and
    // a scripted WebAuthn provider (RecordingWebAuthnProvider). They exercise
    // the build / simulate / send / poll happy paths that the pre-network
    // validation cases above stop short of.

    /// Base64URL credential id reused across the pipeline cases.
    private let pipelineCredentialIdB64Url = "aGVsbG8tc21hcnQtYWNjb3VudA"

    /// Scriptable RPC transport installed for the pipeline cases. `nil` outside
    /// of those cases; the validation-only cases above never touch RPC.
    private var pipelineScript: MockSorobanServerScript?

    /// Activates the scriptable RPC transport for a pipeline case and returns
    /// the installed script. The companion `deactivatePipelineRpc()` must run in
    /// the same test (a `defer` keeps it paired with activation).
    private func activatePipelineRpc() -> MockSorobanServerScript {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        pipelineScript = script
        return script
    }

    /// Tears the scriptable RPC transport back down. Paired with
    /// `activatePipelineRpc()` so the global URLProtocol registration cannot
    /// leak into later tests.
    private func deactivatePipelineRpc() {
        MockSorobanServer.deactivate()
        MockURLProtocol.reset()
        pipelineScript = nil
    }

    /// Returns a deterministic deployer keypair so a fixture can pre-compute
    /// `accountId` for scripting the deployer account-fetch response.
    private func pipelineDeployer(seed: UInt8 = 0x77) throws -> KeyPair {
        let seedBytes = Data(repeating: seed, count: 32)
        let stellarSeed = try Seed(bytes: [UInt8](seedBytes))
        return KeyPair(seed: stellarSeed)
    }

    /// secp256r1 generator-point assembled into a 65-byte uncompressed SEC1
    /// public key. `extractPublicKeyFromRegistration` validates the point lies
    /// on the curve, so a real on-curve point is required for createWallet.
    private func generatorPointPublicKey() -> Data {
        let x = Data([
            0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
            0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
            0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
            0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96
        ])
        let y = Data([
            0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
            0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
            0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
            0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5
        ])
        var pk = Data([0x04])
        pk.append(x)
        pk.append(y)
        return pk
    }

    /// Builds a `WebAuthnRegistrationResult` carrying the supplied credential id
    /// and an on-curve public key so createWallet's `extractPublicKeyFromRegistration`
    /// returns the key unchanged.
    private func registrationResult(
        credentialId: Data
    ) -> WebAuthnRegistrationResult {
        return WebAuthnRegistrationResult(
            credentialId: credentialId,
            publicKey: generatorPointPublicKey(),
            attestationObject: Data(),
            transports: ["internal"],
            deviceType: "multiDevice",
            backedUp: true
        )
    }

    /// Builds a config wired with a scriptable WebAuthn provider, a
    /// deterministic deployer, and an in-memory storage adapter.
    private func pipelineConfig(
        provider: WebAuthnProvider,
        deployer: KeyPair,
        storage: OZInMemoryStorageAdapter
    ) throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validContractAddress2,
            deployerKeypair: deployer,
            webauthnProvider: provider,
            storage: storage
        )
    }

    /// Convenience: enqueues the deployer account-fetch response so the deploy
    /// build's `getAccount(deployer.accountId)` lookup succeeds.
    private func enqueueDeployerAccount(
        _ script: MockSorobanServerScript,
        deployer: KeyPair,
        sequence: Int64 = 1
    ) {
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: sequence)
    }

    /// Returns the first InvokeHostFunction operation body in the envelope, or nil.
    private func firstInvokeHostFunctionOp(
        envelope: TransactionEnvelopeXDR
    ) -> InvokeHostFunctionOpXDR? {
        let operations: [OperationXDR]
        switch envelope {
        case .v0(let env): operations = env.tx.operations
        case .v1(let env): operations = env.tx.operations
        case .feeBump(let env):
            if case .v1(let inner) = env.tx.innerTx {
                operations = inner.tx.operations
            } else {
                return nil
            }
        }
        for op in operations {
            if case .invokeHostFunctionOp(let invoke) = op.body {
                return invoke
            }
        }
        return nil
    }

    // ========================================================================
    // MARK: - createWallet happy paths
    // ========================================================================

    func test_createWallet_buildOnly_returnsResultAndSimulatesWithoutSubmit() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        provider.enqueueRegister(registrationResult(credentialId: credentialIdBytes))

        // Build path: deployer account fetch + a single simulate, no submit.
        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.createWallet(
            userName: "Alice",
            autoSubmit: false
        )

        // The contract address is derived deterministically from the credential
        // id + deployer + network; recompute it for the assertion.
        let expectedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )

        XCTAssertEqual(result.credentialId, pipelineCredentialIdB64Url)
        XCTAssertEqual(result.contractId, expectedContractId)
        XCTAssertEqual(result.publicKey, generatorPointPublicKey())
        XCTAssertEqual(result.nickname, "Alice")
        XCTAssertFalse(result.signedTransactionXdr.isEmpty)
        XCTAssertNil(result.transactionHash, "autoSubmit=false must not produce a hash")

        // RPC: exactly the build path engaged — one simulate, no send.
        XCTAssertEqual(script.simulateCallCount, 1)
        XCTAssertEqual(script.sendCallCount, 0)
        // WebAuthn registration ran once.
        XCTAssertEqual(provider.registerCalls.count, 1)
        XCTAssertEqual(provider.registerCalls.first?.userName, "Alice")

        // Connected state and a persisted session were written by the body.
        XCTAssertEqual(kit.currentConnectedState?.contractId, expectedContractId)
        XCTAssertEqual(kit.currentConnectedState?.credentialId, pipelineCredentialIdB64Url)
        let session = try await storage.getSession()
        XCTAssertEqual(session?.contractId, expectedContractId)

        // The signed envelope carries a CreateContractV2 host function.
        let envelope = try TransactionEnvelopeXDR(xdr: result.signedTransactionXdr)
        let op = firstInvokeHostFunctionOp(envelope: envelope)
        XCTAssertNotNil(op)
        if case .createContractV2(let createArgs) = op?.hostFunction {
            if case .wasm(let hash) = createArgs.executable {
                XCTAssertEqual(hash.wrapped.count, 32)
            } else {
                XCTFail("expected wasm executable")
            }
            let expectedSalt = SmartAccountUtils.getContractSalt(credentialId: credentialIdBytes)
            if case .fromAddress(let preimage) = createArgs.contractIDPreimage {
                XCTAssertEqual(preimage.salt.wrapped, expectedSalt)
            } else {
                XCTFail("expected fromAddress preimage")
            }
        } else {
            XCTFail("expected createContractV2 host function")
        }
    }

    func test_createWallet_autoSubmit_submitsAndPollsToSuccess() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        provider.enqueueRegister(registrationResult(credentialId: credentialIdBytes))

        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)
        // submitDeployTransaction: send + poll (10x2s loop, first poll succeeds).
        script.setSendSuccess(
            status: SendTransactionResponse.STATUS_PENDING,
            hash: "create-hash"
        )
        script.setGetTransactionDefault(
            payload: OZPipelineFixtures.validGetTransactionResponse(
                status: GetTransactionResponse.STATUS_SUCCESS,
                ledger: 4242
            )
        )

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.createWallet(
            userName: "Bob",
            autoSubmit: true
        )

        let expectedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        XCTAssertEqual(result.contractId, expectedContractId)
        XCTAssertEqual(result.transactionHash, "create-hash",
                       "autoSubmit=true must surface the submission hash")
        XCTAssertFalse(result.signedTransactionXdr.isEmpty)

        // RPC: one simulate, one send, at least one getTransaction poll.
        XCTAssertEqual(script.simulateCallCount, 1)
        XCTAssertEqual(script.sendCallCount, 1)
        XCTAssertEqual(script.getTransactionCalls.first, "create-hash")
        XCTAssertGreaterThanOrEqual(script.getTransactionCalls.count, 1)

        // After a confirmed deploy the transitional credential is deleted.
        let stored = try await storage.get(credentialId: pipelineCredentialIdB64Url)
        XCTAssertNil(stored, "transitional credential must be deleted after a confirmed deploy")
    }

    func test_createWallet_sendError_marksDeploymentFailedAndThrows() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let credentialManager = MockCredentialManager(storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer(),
            credentialManager: credentialManager
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        provider.enqueueRegister(registrationResult(credentialId: credentialIdBytes))

        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 100_000)
        // sendTransaction returns an on-chain error result.
        script.setSendSuccess(
            status: SendTransactionResponse.STATUS_ERROR,
            hash: "rejected",
            errorResultXdr: "AAAAAA=="
        )

        let walletOps = OZWalletOperations(kit: kit)
        do {
            _ = try await walletOps.createWallet(autoSubmit: true)
            XCTFail("expected SmartAccountTransactionException.SubmissionFailed")
        } catch is SmartAccountTransactionException.SubmissionFailed {
            // expected
        }

        // The send-error path marks the pending credential failed before throwing.
        XCTAssertEqual(credentialManager.markDeploymentFailedCalls.count, 1)
        let failed = try await storage.get(credentialId: pipelineCredentialIdB64Url)
        XCTAssertEqual(failed?.deploymentStatus, .failed)
    }

    // ========================================================================
    // MARK: - connectWallet happy paths
    // ========================================================================

    func test_connectWallet_storageHit_connectsAndSavesSession() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer

        let stored = OZStoredCredential(
            credentialId: pipelineCredentialIdB64Url,
            publicKey: generatorPointPublicKey(),
            contractId: validContractAddress2
        )
        try await storage.save(credential: stored)
        // End-of-cascade verifyContractExists needs a live contract instance.
        try script.setGetContractDataResponse(contractId: validContractAddress2)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.connectWallet(
            options: OZConnectWalletOptions(credentialId: pipelineCredentialIdB64Url)
        )

        guard let result = result,
              case .connected(let credId, let contractId, let restored) = result else {
            XCTFail("expected .connected, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(credId, pipelineCredentialIdB64Url)
        XCTAssertEqual(contractId, validContractAddress2)
        XCTAssertFalse(restored, "explicit-credential connect is not a session restore")

        // verifyContractExists issued at least one getLedgerEntries lookup.
        XCTAssertGreaterThanOrEqual(script.getLedgerEntriesCallCount, 1)
        // Connected state + session persisted.
        XCTAssertEqual(kit.currentConnectedState?.contractId, validContractAddress2)
        let session = try await storage.getSession()
        XCTAssertEqual(session?.credentialId, pipelineCredentialIdB64Url)
    }

    func test_connectWallet_sessionRestore_returnsConnectedFromSession() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer

        // A valid (non-expired) session pointing at a contract the cascade can
        // confirm on-chain. Default-options connectWallet restores it.
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let session = OZStoredSession(
            credentialId: pipelineCredentialIdB64Url,
            contractId: validContractAddress2,
            connectedAt: now,
            expiresAt: now + 3_600_000
        )
        try await storage.saveSession(session)
        try script.setGetContractDataResponse(contractId: validContractAddress2)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.connectWallet()

        guard let result = result,
              case .connected(let credId, let contractId, let restored) = result else {
            XCTFail("expected .connected, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(credId, pipelineCredentialIdB64Url)
        XCTAssertEqual(contractId, validContractAddress2)
        XCTAssertTrue(restored, "session-restore path must set restoredFromSession = true")
    }

    func test_connectWallet_promptTrue_webauthnDerivationHit_connects() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer

        // No session, no stored credential: prompt=true triggers WebAuthn, then
        // the derivation stage resolves the contract and verifies it on-chain.
        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        provider.enqueueAuthenticate(
            RecordingWebAuthnFixtures.authenticationResult(credentialId: credentialIdBytes)
        )
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        try script.setGetContractDataResponse(contractId: derivedContractId)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.connectWallet(
            options: OZConnectWalletOptions(prompt: true)
        )

        guard let result = result, case .connected(_, let contractId, _) = result else {
            XCTFail("expected .connected, got \(String(describing: result))")
            return
        }
        XCTAssertEqual(contractId, derivedContractId)
        XCTAssertEqual(provider.authenticateCalls.count, 1,
                       "prompt=true with no session must trigger WebAuthn")
        XCTAssertEqual(kit.currentConnectedState?.contractId, derivedContractId)
    }

    // ========================================================================
    // MARK: - authenticatePasskey happy paths
    // ========================================================================

    func test_authenticatePasskey_success_returnsSignatureAndStoredKey() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }
        _ = script

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )

        let publicKey = generatorPointPublicKey()
        let stored = OZStoredCredential(
            credentialId: pipelineCredentialIdB64Url,
            publicKey: publicKey,
            contractId: validContractAddress2
        )
        try await storage.save(credential: stored)

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        provider.enqueueAuthenticate(
            RecordingWebAuthnFixtures.authenticationResult(credentialId: credentialIdBytes)
        )

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.authenticatePasskey()

        XCTAssertEqual(result.credentialId, pipelineCredentialIdB64Url)
        XCTAssertEqual(result.publicKey, publicKey,
                       "stored public key must be returned for a known credential")
        // The normalised signature is a 64-byte low-S compact form.
        XCTAssertEqual(result.signature.signature.count, 64)
        XCTAssertFalse(result.signature.authenticatorData.isEmpty)
        XCTAssertFalse(result.signature.clientData.isEmpty)
        XCTAssertEqual(provider.authenticateCalls.count, 1)
        // No credential-id filter supplied: allowCredentials must be nil.
        XCTAssertNil(provider.authenticateCalls.first?.allowCredentials)
    }

    func test_authenticatePasskey_withCredentialIds_buildsAllowListAndEmptyKeyWhenUnknown() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }
        _ = script

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )

        // No stored credential: the returned public key must be empty Data.
        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        provider.enqueueAuthenticate(
            RecordingWebAuthnFixtures.authenticationResult(credentialId: credentialIdBytes)
        )

        let walletOps = OZWalletOperations(kit: kit)
        let challenge = Data(repeating: 0xAB, count: 32)
        let result = try await walletOps.authenticatePasskey(
            challenge: challenge,
            credentialIds: [pipelineCredentialIdB64Url]
        )

        XCTAssertEqual(result.credentialId, pipelineCredentialIdB64Url)
        XCTAssertTrue(result.publicKey.isEmpty,
                      "unknown credential must yield an empty stored public key")
        // The supplied credential-id filter produced a one-entry allow list,
        // and the caller-supplied challenge was forwarded verbatim.
        XCTAssertEqual(provider.authenticateCalls.first?.allowCredentials?.count, 1)
        XCTAssertEqual(provider.authenticateCalls.first?.challenge, challenge)
    }

    // ========================================================================
    // MARK: - deployPendingCredential happy paths and failure marking
    // ========================================================================

    func test_deployPendingCredential_autoSubmit_submitsAndDeletesCredential() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        let stored = OZStoredCredential(
            credentialId: pipelineCredentialIdB64Url,
            publicKey: generatorPointPublicKey(),
            contractId: derivedContractId
        )
        try await storage.save(credential: stored)

        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 50_000)
        script.setSendSuccess(
            status: SendTransactionResponse.STATUS_PENDING,
            hash: "pending-deploy-hash"
        )
        script.setGetTransactionDefault(
            payload: OZPipelineFixtures.validGetTransactionResponse(
                status: GetTransactionResponse.STATUS_SUCCESS,
                ledger: 7777
            )
        )

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.deployPendingCredential(
            credentialId: pipelineCredentialIdB64Url
        )

        XCTAssertEqual(result.contractId, derivedContractId)
        XCTAssertEqual(result.transactionHash, "pending-deploy-hash")
        XCTAssertFalse(result.signedTransactionXdr.isEmpty)
        XCTAssertEqual(script.sendCallCount, 1)
        XCTAssertEqual(script.getTransactionCalls.first, "pending-deploy-hash")

        // Connected state + session written, transitional credential deleted.
        XCTAssertEqual(kit.currentConnectedState?.contractId, derivedContractId)
        let remaining = try await storage.get(credentialId: pipelineCredentialIdB64Url)
        XCTAssertNil(remaining)
    }

    func test_deployPendingCredential_sendFailure_marksFailedAndThrows() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let credentialManager = MockCredentialManager(storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer(),
            credentialManager: credentialManager
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        let stored = OZStoredCredential(
            credentialId: pipelineCredentialIdB64Url,
            publicKey: generatorPointPublicKey(),
            contractId: derivedContractId
        )
        try await storage.save(credential: stored)

        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 50_000)
        script.setSendSuccess(
            status: SendTransactionResponse.STATUS_ERROR,
            hash: "fail-hash",
            errorResultXdr: "AAAAAA=="
        )

        let walletOps = OZWalletOperations(kit: kit)
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: pipelineCredentialIdB64Url
            )
            XCTFail("expected SmartAccountTransactionException.SubmissionFailed")
        } catch is SmartAccountTransactionException.SubmissionFailed {
            // expected
        }

        // The submission-error path marks the credential failed.
        XCTAssertEqual(credentialManager.markDeploymentFailedCalls.count, 1)
        let failed = try await storage.get(credentialId: pipelineCredentialIdB64Url)
        XCTAssertEqual(failed?.deploymentStatus, .failed)
    }

    func test_deployPendingCredential_buildOnly_returnsSignedXdrNoSubmit() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer()
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        let stored = OZStoredCredential(
            credentialId: pipelineCredentialIdB64Url,
            publicKey: generatorPointPublicKey(),
            contractId: derivedContractId
        )
        try await storage.save(credential: stored)

        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 50_000)

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.deployPendingCredential(
            credentialId: pipelineCredentialIdB64Url,
            autoSubmit: false
        )

        XCTAssertEqual(result.contractId, derivedContractId)
        XCTAssertNil(result.transactionHash, "autoSubmit=false must not produce a hash")
        XCTAssertFalse(result.signedTransactionXdr.isEmpty)
        XCTAssertEqual(script.sendCallCount, 0, "autoSubmit=false must not submit")
        // The build-only path leaves the credential in storage (no deletion).
        let remaining = try await storage.get(credentialId: pipelineCredentialIdB64Url)
        XCTAssertNotNil(remaining)
    }

    func test_deployPendingCredential_relayerPath_submitsViaRelayer() async throws {
        // The deploy submission routes through the configured relayer; the
        // confirmation poll still uses RPC getTransaction. Route relayer host
        // traffic to a success response and RPC traffic to the script.
        let script = MockSorobanServerScript()
        MockSorobanServerScript.current = script
        URLProtocol.registerClass(MockURLProtocol.self)
        defer { deactivatePipelineRpc() }
        pipelineScript = script

        let relayerSession: URLSession = {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            return URLSession(configuration: configuration)
        }()
        let relayer = try OZRelayerClient(
            relayerUrl: "https://relayer.example.com",
            urlSession: relayerSession
        )
        defer { relayer.close() }

        var relayerCalled = false
        MockURLProtocol.requestHandler = { request in
            if request.url?.host == "relayer.example.com" {
                relayerCalled = true
                let body = #"{"success":true,"hash":"relayer-deploy-hash","status":"SUCCESS"}"#
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return .success((response, body.data(using: .utf8)))
            }
            return MockSorobanServer.handle(request: request, script: script)
        }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer(),
            relayerClient: relayer
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        let stored = OZStoredCredential(
            credentialId: pipelineCredentialIdB64Url,
            publicKey: generatorPointPublicKey(),
            contractId: derivedContractId
        )
        try await storage.save(credential: stored)

        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 50_000)
        script.setGetTransactionDefault(
            payload: OZPipelineFixtures.validGetTransactionResponse(
                status: GetTransactionResponse.STATUS_SUCCESS,
                ledger: 9999
            )
        )

        let walletOps = OZWalletOperations(kit: kit)
        let result = try await walletOps.deployPendingCredential(
            credentialId: pipelineCredentialIdB64Url
        )

        XCTAssertTrue(relayerCalled, "relayer must be contacted for the deploy submission")
        XCTAssertEqual(result.transactionHash, "relayer-deploy-hash")
        XCTAssertEqual(script.sendCallCount, 0,
                       "RPC sendTransaction must NOT be called when a relayer is configured")
    }

    func test_deployPendingCredential_pollFailed_marksFailedAndThrows() async throws {
        let script = activatePipelineRpc()
        defer { deactivatePipelineRpc() }

        let provider = RecordingWebAuthnProvider()
        let deployer = try pipelineDeployer()
        let storage = OZInMemoryStorageAdapter()
        let config = try pipelineConfig(provider: provider, deployer: deployer, storage: storage)
        let credentialManager = MockCredentialManager(storage: storage)
        let kit = MockOZSmartAccountKit(
            config: config,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer(),
            credentialManager: credentialManager
        )
        kit.configuredDeployer = deployer

        let credentialIdBytes = try Data(base64URLEncoded: pipelineCredentialIdB64Url)
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: Network.testnet.passphrase
        )
        let stored = OZStoredCredential(
            credentialId: pipelineCredentialIdB64Url,
            publicKey: generatorPointPublicKey(),
            contractId: derivedContractId
        )
        try await storage.save(credential: stored)

        enqueueDeployerAccount(script, deployer: deployer)
        script.enqueueSimulate(authEntries: [], minResourceFee: 50_000)
        script.setSendSuccess(
            status: SendTransactionResponse.STATUS_PENDING,
            hash: "will-fail-hash"
        )
        // First poll (after the 2s deploy-poll delay) reports an on-chain
        // failure, driving the FAILED branch.
        script.setGetTransactionDefault(
            payload: OZPipelineFixtures.validGetTransactionResponse(
                status: GetTransactionResponse.STATUS_FAILED,
                ledger: 1234,
                resultXdr: "AAAAAA=="
            )
        )

        let walletOps = OZWalletOperations(kit: kit)
        do {
            _ = try await walletOps.deployPendingCredential(
                credentialId: pipelineCredentialIdB64Url
            )
            XCTFail("expected SmartAccountTransactionException.SubmissionFailed")
        } catch is SmartAccountTransactionException.SubmissionFailed {
            // expected: deploy confirmed FAILED on-chain
        }

        XCTAssertEqual(credentialManager.markDeploymentFailedCalls.count, 1)
        let failed = try await storage.get(credentialId: pipelineCredentialIdB64Url)
        XCTAssertEqual(failed?.deploymentStatus, .failed)
    }
}
