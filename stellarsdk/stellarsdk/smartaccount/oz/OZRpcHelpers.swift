//
//  OZRpcHelpers.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Shared Soroban RPC and transaction helpers used by the OZ smart-account managers.
///
/// Each manager holds a reference to the kit and routes RPC traffic (account fetch,
/// ledger fetch, simulation) and transaction assembly through these helpers so the
/// error-mapping and resource-fee envelopes line up across the single- and
/// multi-signer flows.
protocol OZRpcHelpers {
    var kit: OZSmartAccountKitProtocol { get }
}

extension OZRpcHelpers {

    /// Maps a Soroban RPC transport error into a human-readable message.
    func rpcErrorMessage(_ error: SorobanRpcRequestError) -> String {
        switch error {
        case .requestFailed(let message):
            return message
        case .errorResponse(let rpcError):
            if let message = rpcError.message, !message.isEmpty {
                return "\(rpcError.code): \(message)"
            }
            return "RPC error \(rpcError.code)"
        case .parsingResponseFailed(let message, _):
            return "Parse failure: \(message)"
        }
    }

    /// Builds the unsigned transaction shape used by the simulate / re-simulate passes.
    ///
    /// Applies `MIN_BASE_FEE`, the operation list, a no-op memo, and a
    /// `TransactionPreconditions` carrying a time-bounds upper limit of
    /// `now + timeoutSeconds`. A `timeoutSeconds` of `0` yields `max_time = 0`,
    /// the Stellar sentinel for "no upper bound".
    func buildTransaction(
        sourceAccount: TransactionAccount,
        operations: [Operation],
        timeoutSeconds: Int
    ) throws -> Transaction {
        let nowSeconds = UInt64(Date().timeIntervalSince1970)
        let maxTime: UInt64 = timeoutSeconds <= 0 ? 0 : nowSeconds + UInt64(timeoutSeconds)
        let timeBounds = TimeBounds(
            minTime: 0,
            maxTime: maxTime
        )
        let preconditions = TransactionPreconditions(timeBounds: timeBounds)
        do {
            return try Transaction(
                sourceAccount: sourceAccount,
                operations: operations,
                memo: Memo.none,
                preconditions: preconditions,
                maxOperationFee: StellarProtocolConstants.MIN_BASE_FEE
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to build transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
    }

    /// Wraps the kit's RPC `simulateTransaction` and lifts transport-level and
    /// simulation-error responses into `TransactionException.SimulationFailed`.
    func simulate(
        transaction: Transaction,
        failureMessagePrefix: String
    ) async throws -> SimulateTransactionResponse {
        let request = SimulateTransactionRequest(transaction: transaction)
        let response = await kit.sorobanServer.simulateTransaction(
            simulateTxRequest: request
        )
        switch response {
        case .success(let simulation):
            if let error = simulation.error {
                throw TransactionException.simulationFailed(
                    reason: "\(failureMessagePrefix)\(error)"
                )
            }
            return simulation
        case .failure(let error):
            throw TransactionException.simulationFailed(
                reason: "\(failureMessagePrefix)\(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Wraps `SorobanServer.getAccount(accountId:)` and lifts transport-level
    /// failures into `TransactionException.SubmissionFailed`.
    func fetchAccount(accountId: String) async throws -> Account {
        let response = await kit.sorobanServer.getAccount(accountId: accountId)
        switch response {
        case .success(let account):
            return account
        case .failure(let error):
            throw TransactionException.submissionFailed(
                reason: "Failed to fetch account \(accountId): \(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Wraps `SorobanServer.getLatestLedger()` and lifts transport-level
    /// failures into `TransactionException.SubmissionFailed`.
    func fetchLatestLedger() async throws -> GetLatestLedgerResponse {
        let response = await kit.sorobanServer.getLatestLedger()
        switch response {
        case .success(let ledger):
            return ledger
        case .failure(let error):
            throw TransactionException.submissionFailed(
                reason: "Failed to fetch latest ledger: \(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Best-effort credential lookup that returns `nil` instead of throwing.
    func safeGetCredential(credentialId: String) async -> StoredCredential? {
        do {
            return try await kit.credentialManager.getCredential(
                credentialId: credentialId
            )
        } catch {
            return nil
        }
    }
}
