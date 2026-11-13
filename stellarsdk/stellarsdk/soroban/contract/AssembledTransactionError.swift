//
//  AssembledTransactionError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 07.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Errors that occur during Soroban assembled transaction lifecycle operations.
public enum AssembledTransactionError: Error, Sendable {
    /// Transaction builder has not yet assembled the transaction from provided operations.
    case notYetAssembled(message: String)
    /// Transaction has not yet been simulated against the Soroban network.
    case notYetSimulated(message: String)
    /// Transaction requires signature but has not yet been signed by required signers.
    case notYetSigned(message: String)
    /// Required private key for signing is missing or not available.
    case missingPrivateKey(message: String)
    /// Simulation against Soroban network failed with errors.
    ///
    /// ``reportedContractError`` reads the contract error code the message reports.
    case simulationFailed(message: String)
    /// Contract state needs restoration before transaction can execute successfully.
    case restoreNeeded(message: String)
    /// Transaction is a read-only call and cannot modify ledger state.
    case isReadCall(message: String)
    /// Transaction type does not match expected type for this operation.
    case unexpectedTxType(message: String)
    /// Transaction requires signatures from multiple parties but only one was provided.
    case multipleSignersRequired(message: String)
    /// Polling for transaction status was interrupted before completion.
    case pollInterrupted(message: String)
    /// Automatic restoration of contract state failed during transaction preparation.
    case automaticRestoreFailed(message: String)
    /// Transaction submission to the network failed.
    case sendFailed(message: String)
}

extension AssembledTransactionError {

    /// The contract error code a ``simulationFailed(message:)`` message reports; `nil` for
    /// every other case.
    ///
    /// Reads the message `AssembledTransaction.simulate()` and
    /// `AssembledTransaction.getSimulationData()` write: the host error that follows the
    /// SDK's prefix, when it names `Error(Contract, #N)` (``ReportedContractError/Provenance/hostError``,
    /// no contract ID), or the suffix
    /// ` (contract error in diagnostic events: Error(Contract, #N), contract C...)` the SDK
    /// appends after an `Error(Context, ...)` or `Error(Auth, ...)` host error
    /// (``ReportedContractError/Provenance/diagnosticEvents``, with the contract ID when the
    /// event has one). Only these two positions are read; a textual event log inside the
    /// message is not. A message in neither form and the message
    /// `Transaction simulation failed` give `nil`. A message a caller builds in the same form
    /// reads the same.
    ///
    /// The value equals `SimulateTransactionResponse.reportedContractError()` of the response
    /// that failed. The raw diagnostic events are not part of this error: a caller holding
    /// the assembled transaction reads them from `simulationResponse?.events`, and the smart
    /// account kit's `SmartAccountTransactionException.SimulationFailed` carries them as
    /// `diagnosticEventsXdr`.
    ///
    /// ```swift
    /// do {
    ///     _ = try await client.invokeMethod(name: "transfer", args: args)
    /// } catch let error as AssembledTransactionError {
    ///     if let reported = error.reportedContractError {
    ///         print("Contract error \(reported.code)")
    ///     }
    /// }
    /// ```
    public var reportedContractError: ReportedContractError? {
        guard case .simulationFailed(let message) = self else {
            return nil
        }
        return SimulationFailureMessage.reportedContractError(in: message)
    }
}
