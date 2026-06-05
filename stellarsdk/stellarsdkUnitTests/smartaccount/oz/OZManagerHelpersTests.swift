//
//  OZManagerHelpersTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Unit tests for the shared ``OZManagerHelpers`` protocol extension.
///
/// The helpers are protocol-extension methods consumed by every OZ
/// smart-account manager. Coverage here exercises the transport-error
/// formatting (`rpcErrorMessage`), the transaction-build failure mapping
/// (`buildTransaction`), the RPC-fetch failure lifting (`fetchLatestLedger`),
/// and the best-effort credential lookup (`safeGetCredential`).
///
/// ``OZSignerManager`` conforms to ``OZManagerHelpers`` and is used as a
/// concrete carrier so the extension methods can be invoked directly. The
/// helpers are protocol-agnostic, so the choice of conformer is incidental.
final class OZManagerHelpersTests: XCTestCase {

    // MARK: - Fixtures

    private let validVerifier =
        "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    private func buildConfig() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "http://127.0.0.1:1",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: validVerifier
        )
    }

    /// Builds a kit (with a default non-routable RPC endpoint) and a signer
    /// manager that carries the ``OZManagerHelpers`` extension.
    private func makeHelpers() throws -> (MockOZSmartAccountKit, OZSignerManager) {
        let kit = MockOZSmartAccountKit(config: try buildConfig())
        return (kit, OZSignerManager(kit: kit))
    }

    // ========================================================================
    // MARK: - rpcErrorMessage
    // ========================================================================

    /// `.requestFailed` returns the carried message verbatim.
    func test_rpcErrorMessage_requestFailed_returnsMessage() throws {
        let (_, manager) = try makeHelpers()
        let message = manager.rpcErrorMessage(.requestFailed(message: "connection refused"))
        XCTAssertEqual(message, "connection refused")
    }

    /// `.errorResponse` with a non-empty message returns `"<code>: <message>"`.
    func test_rpcErrorMessage_errorResponseWithMessage_returnsCodeAndMessage() throws {
        let (_, manager) = try makeHelpers()
        let rpcError = SorobanRpcError(code: -32000, message: "boom")
        let message = manager.rpcErrorMessage(.errorResponse(error: rpcError))
        XCTAssertEqual(message, "-32000: boom")
    }

    /// `.errorResponse` whose message is `nil` falls back to `"RPC error <code>"`
    /// (line 32).
    func test_rpcErrorMessage_errorResponseNilMessage_returnsRpcErrorCode() throws {
        let (_, manager) = try makeHelpers()
        let rpcError = SorobanRpcError(code: -32601, message: nil)
        let message = manager.rpcErrorMessage(.errorResponse(error: rpcError))
        XCTAssertEqual(message, "RPC error -32601")
    }

    /// `.errorResponse` whose message is the empty string also falls back to
    /// `"RPC error <code>"` (line 32 — the `!message.isEmpty` guard).
    func test_rpcErrorMessage_errorResponseEmptyMessage_returnsRpcErrorCode() throws {
        let (_, manager) = try makeHelpers()
        let rpcError = SorobanRpcError(code: -1, message: "")
        let message = manager.rpcErrorMessage(.errorResponse(error: rpcError))
        XCTAssertEqual(message, "RPC error -1")
    }

    /// `.parsingResponseFailed` returns `"Parse failure: <message>"` (line 34).
    func test_rpcErrorMessage_parsingResponseFailed_returnsParseFailure() throws {
        let (_, manager) = try makeHelpers()
        let message = manager.rpcErrorMessage(
            .parsingResponseFailed(message: "unexpected token", responseData: Data([0x7B]))
        )
        XCTAssertEqual(message, "Parse failure: unexpected token")
    }

    // ========================================================================
    // MARK: - buildTransaction
    // ========================================================================

    /// A well-formed call builds a transaction whose preconditions carry the
    /// computed time-bounds upper limit.
    func test_buildTransaction_validInput_returnsTransaction() throws {
        let (_, manager) = try makeHelpers()
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 5)
        let op = ManageDataOperation(sourceAccountId: nil, name: "k", data: Data([0x01]))

        let tx = try manager.buildTransaction(
            sourceAccount: account,
            operations: [op],
            timeoutSeconds: 30
        )
        XCTAssertEqual(tx.operations.count, 1)
        let maxTime = tx.preconditions?.timeBounds?.maxTime
        XCTAssertNotNil(maxTime)
        XCTAssertGreaterThan(maxTime ?? 0, 0, "non-zero timeout must produce a non-zero max_time")
    }

    /// A `timeoutSeconds` of zero yields `max_time == 0` (the Stellar sentinel
    /// for no upper bound).
    func test_buildTransaction_zeroTimeout_producesUnboundedMaxTime() throws {
        let (_, manager) = try makeHelpers()
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1)
        let op = ManageDataOperation(sourceAccountId: nil, name: "k", data: Data([0x01]))

        let tx = try manager.buildTransaction(
            sourceAccount: account,
            operations: [op],
            timeoutSeconds: 0
        )
        XCTAssertEqual(tx.preconditions?.timeBounds?.maxTime, 0)
    }

    /// An empty operation list makes the `Transaction` initializer throw; the
    /// helper must catch it and surface a
    /// ``SmartAccountTransactionException/SigningFailed`` naming the build
    /// failure (lines 65-69).
    func test_buildTransaction_emptyOperations_throwsSigningFailed() throws {
        let (_, manager) = try makeHelpers()
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1)

        XCTAssertThrowsError(
            try manager.buildTransaction(
                sourceAccount: account,
                operations: [],
                timeoutSeconds: 30
            )
        ) { error in
            guard let signingFailed = error as? SmartAccountTransactionException.SigningFailed else {
                return XCTFail("expected SmartAccountTransactionException.SigningFailed, got: \(error)")
            }
            XCTAssertTrue(
                signingFailed.message.contains("Failed to build transaction"),
                "expected the build-failure reason, got: \(signingFailed.message)"
            )
        }
    }

    // ========================================================================
    // MARK: - fetchLatestLedger
    // ========================================================================

    /// When the underlying RPC `getLatestLedger` fails (the kit points at a
    /// non-routable endpoint), the helper must lift the transport failure into
    /// ``SmartAccountTransactionException/SubmissionFailed`` naming the
    /// latest-ledger fetch (lines 121-124).
    func test_fetchLatestLedger_transportFailure_throwsSubmissionFailed() async throws {
        let (_, manager) = try makeHelpers()
        do {
            _ = try await manager.fetchLatestLedger()
            XCTFail("expected SmartAccountTransactionException.SubmissionFailed")
        } catch let error as SmartAccountTransactionException.SubmissionFailed {
            XCTAssertTrue(
                error.message.contains("latest ledger"),
                "expected the latest-ledger fetch reason, got: \(error.message)"
            )
        }
    }

    // ========================================================================
    // MARK: - safeGetCredential
    // ========================================================================

    /// `safeGetCredential` returns `nil` rather than throwing when the
    /// underlying credential manager throws (lines 135-136).
    func test_safeGetCredential_credentialManagerThrows_returnsNil() async throws {
        let storage = OZInMemoryStorageAdapter()
        let credentialManager = MockCredentialManager(storage: storage)
        credentialManager.throwOnGetCredential = SmartAccountStorageException.readFailed(key: "boom")

        let kit = MockOZSmartAccountKit(
            config: try buildConfig(),
            credentialManager: credentialManager
        )
        let manager = OZSignerManager(kit: kit)

        let result = await manager.safeGetCredential(credentialId: "missing")
        XCTAssertNil(result, "safeGetCredential must swallow the error and return nil")
    }

    /// `safeGetCredential` returns the credential when the lookup succeeds.
    func test_safeGetCredential_credentialPresent_returnsCredential() async throws {
        let storage = OZInMemoryStorageAdapter()
        let credentialManager = MockCredentialManager(storage: storage)
        _ = try await credentialManager.createPendingCredential(
            credentialId: "cred-1",
            publicKey: Data(repeating: 0x04, count: 65),
            contractId: validVerifier,
            nickname: nil,
            transports: nil,
            deviceType: nil,
            backedUp: nil
        )

        let kit = MockOZSmartAccountKit(
            config: try buildConfig(),
            credentialManager: credentialManager
        )
        let manager = OZSignerManager(kit: kit)

        let result = await manager.safeGetCredential(credentialId: "cred-1")
        XCTAssertEqual(result?.credentialId, "cred-1")
    }
}
