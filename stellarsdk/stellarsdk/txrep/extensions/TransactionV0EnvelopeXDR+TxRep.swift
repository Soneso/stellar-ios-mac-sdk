//
//  TransactionV0EnvelopeXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `TransactionV0EnvelopeXDR` (V0 envelope = tx + signatures).
///
/// V0 envelopes output the same field layout as V1 envelopes — the source
/// account raw bytes are normalised to a G-address. The enclosing
/// `TransactionEnvelopeXDR.toTxRep` emits `type: ENVELOPE_TYPE_TX_V0` before
/// calling this.
extension TransactionV0EnvelopeXDR {

    /// Emit TxRep lines for this V0 envelope.
    ///
    /// - Parameters:
    ///   - txPrefix: Prefix for transaction fields, e.g. `"tx"`.
    ///   - sigPrefix: Bare prefix for the signatures array (with trailing dot
    ///                if non-empty).
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(txPrefix: String, sigPrefix: String, lines: inout [String]) throws {
        try self.tx.toTxRep(prefix: txPrefix, lines: &lines)
        try emitSignatures(self.signatures, sigPrefix: sigPrefix, lines: &lines)
    }

    /// Parse a V0 envelope from the TxRep map.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - txPrefix: Prefix for transaction fields, e.g. `"tx"`.
    ///   - sigPrefix: Bare prefix for the signatures array.
    /// - Returns: Decoded `TransactionV0EnvelopeXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], txPrefix: String, sigPrefix: String) throws -> TransactionV0EnvelopeXDR {
        let tx = try TransactionV0XDR.fromTxRep(map, prefix: txPrefix)
        let signatures = try parseSignatures(map, sigPrefix: sigPrefix)
        return TransactionV0EnvelopeXDR(tx: tx, signatures: signatures)
    }

    // MARK: - Protocol-compatible single-prefix overloads

    /// Emit using the standard `toTxRep(prefix:lines:)` signature.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        try toTxRep(txPrefix: prefix, sigPrefix: "", lines: &lines)
    }

    /// Parse using the standard `fromTxRep(_:prefix:)` signature.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> TransactionV0EnvelopeXDR {
        return try fromTxRep(map, txPrefix: prefix, sigPrefix: "")
    }
}
