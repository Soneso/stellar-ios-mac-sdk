//
//  FeeBumpTransactionEnvelopeXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `FeeBumpTransactionEnvelopeXDR`.
///
/// The envelope adds the outer fee-bump signature array after all fee-bump
/// transaction fields (including the inner transaction). The enclosing
/// `TransactionEnvelopeXDR.toTxRep` emits `type: ENVELOPE_TYPE_TX_FEE_BUMP`
/// before calling this.
///
/// Output layout:
/// ```
/// feeBump.tx.feeSource: G…
/// feeBump.tx.fee: 200
/// feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
/// feeBump.tx.innerTx.tx.sourceAccount: G…
/// …(inner tx fields)…
/// feeBump.tx.innerTx.signatures.len: N
/// feeBump.tx.innerTx.signatures[0].hint: …
/// feeBump.tx.innerTx.signatures[0].signature: …
/// feeBump.tx.ext.v: 0
/// feeBump.signatures.len: M
/// feeBump.signatures[0].hint: …
/// feeBump.signatures[0].signature: …
/// ```
extension FeeBumpTransactionEnvelopeXDR {

    /// Emit TxRep lines for this fee-bump envelope.
    ///
    /// - Parameters:
    ///   - prefix: Key prefix without trailing dot, e.g. `"feeBump"`.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        // Emit the fee-bump transaction body (includes inner tx + ext.v).
        try self.tx.toTxRep(prefix: "\(prefix).tx", lines: &lines)
        // Outer signatures: prefix is "<prefix>." e.g. "feeBump.".
        try emitSignatures(self.signatures, sigPrefix: "\(prefix).", lines: &lines)
    }

    /// Parse a fee-bump envelope from the TxRep map.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Key prefix without trailing dot, e.g. `"feeBump"`.
    /// - Returns: Decoded `FeeBumpTransactionEnvelopeXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> FeeBumpTransactionEnvelopeXDR {
        let tx = try FeeBumpTransactionXDR.fromTxRep(map, prefix: "\(prefix).tx")
        let signatures = try parseSignatures(map, sigPrefix: "\(prefix).")
        return FeeBumpTransactionEnvelopeXDR(tx: tx, signatures: signatures)
    }
}
