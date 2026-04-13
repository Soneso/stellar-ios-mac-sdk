//
//  FeeBumpTransactionXDRInnerTxXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `FeeBumpTransactionXDRInnerTxXDR`.
///
/// This union wraps only the `.v1(TransactionV1EnvelopeXDR)` arm. SEP-0011
/// flattens the inner envelope as:
/// ```
/// <prefix>.type: ENVELOPE_TYPE_TX
/// <prefix>.tx.sourceAccount: G…
/// …(full V1 transaction fields)…
/// <prefix>.signatures.len: N
/// <prefix>.signatures[0].hint: …
/// ```
///
/// The `prefix` here is e.g. `"feeBump.tx.innerTx"` (no trailing dot).
extension FeeBumpTransactionXDRInnerTxXDR {

    /// Emit TxRep lines for the inner transaction union.
    ///
    /// - Parameters:
    ///   - prefix: Key prefix without trailing dot, e.g. `"feeBump.tx.innerTx"`.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        switch self {
        case .v1(let envelope):
            lines.append("\(prefix).type: ENVELOPE_TYPE_TX")
            // Transaction fields use "<prefix>.tx" as their prefix.
            // Signatures use "<prefix>." as sigPrefix.
            let txPrefix = "\(prefix).tx"
            let sigPrefix = "\(prefix)."
            try envelope.toTxRep(txPrefix: txPrefix, sigPrefix: sigPrefix, lines: &lines)
        }
    }

    /// Parse the inner transaction union from the TxRep map.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Key prefix without trailing dot, e.g. `"feeBump.tx.innerTx"`.
    /// - Returns: Decoded `FeeBumpTransactionXDRInnerTxXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> FeeBumpTransactionXDRInnerTxXDR {
        let typeKey = "\(prefix).type"
        guard let typeStr = TxRepHelper.getValue(map, typeKey) else {
            throw TxRepError.missingValue(key: typeKey)
        }
        switch typeStr {
        case "ENVELOPE_TYPE_TX":
            let txPrefix = "\(prefix).tx"
            let sigPrefix = "\(prefix)."
            let envelope = try TransactionV1EnvelopeXDR.fromTxRep(map, txPrefix: txPrefix, sigPrefix: sigPrefix)
            return .v1(envelope)
        default:
            throw TxRepError.invalidValue(key: typeKey)
        }
    }
}
