//
//  AssembledTransactionError.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 07.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Errors that occur during Soroban assembled transaction lifecycle operations.
public enum AssembledTransactionError: Error {
    /// Transaction builder has not yet assembled the transaction from provided operations.
    case notYetAssembled(message: String)
    /// Transaction has not yet been simulated against the Soroban network.
    case notYetSimulated(message: String)
    /// Transaction requires signature but has not yet been signed by required signers.
    case notYetSigned(message: String)
    /// Required private key for signing is missing or not available.
    case missingPrivateKey(message: String)
    /// Simulation against Soroban network failed with errors.
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
