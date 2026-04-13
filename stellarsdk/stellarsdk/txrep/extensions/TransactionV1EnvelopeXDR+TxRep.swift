//
//  TransactionV1EnvelopeXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `TransactionV1EnvelopeXDR` (V1 envelope = tx + signatures).
///
/// The envelope itself does not emit an `ENVELOPE_TYPE_TX` line — that is the
/// responsibility of the enclosing `TransactionEnvelopeXDR.toTxRep`. The
/// envelope adds:
///
/// ```
/// <txPrefix>.sourceAccount: G…
/// … (full transaction fields via TransactionXDR.toTxRep)
/// <sigPrefix>signatures.len: N
/// <sigPrefix>signatures[0].hint: …
/// <sigPrefix>signatures[0].signature: …
/// ```
///
/// `txPrefix` is the prefix for transaction fields (e.g. `"tx"`).
/// `sigPrefix` is the *bare* prefix with no trailing separator for the
/// signatures array (e.g. `""` gives `"signatures.len"`,
/// `"feeBump.tx.innerTx."` gives `"feeBump.tx.innerTx.signatures.len"`).
extension TransactionV1EnvelopeXDR {

    /// Emit TxRep lines for this V1 envelope.
    ///
    /// - Parameters:
    ///   - txPrefix: Prefix for transaction fields, e.g. `"tx"`.
    ///   - sigPrefix: Prefix for the signatures array (with trailing dot if non-empty),
    ///                e.g. `""` or `"feeBump.tx.innerTx."`.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(txPrefix: String, sigPrefix: String, lines: inout [String]) throws {
        try self.tx.toTxRep(prefix: txPrefix, lines: &lines)
        try emitSignatures(self.signatures, sigPrefix: sigPrefix, lines: &lines)
    }

    /// Parse a V1 envelope from the TxRep map.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - txPrefix: Prefix for transaction fields, e.g. `"tx"`.
    ///   - sigPrefix: Prefix for the signatures array, e.g. `""` or `"feeBump.tx.innerTx."`.
    /// - Returns: Decoded `TransactionV1EnvelopeXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], txPrefix: String, sigPrefix: String) throws -> TransactionV1EnvelopeXDR {
        let tx = try TransactionXDR.fromTxRep(map, prefix: txPrefix)
        let signatures = try parseSignatures(map, sigPrefix: sigPrefix)
        return TransactionV1EnvelopeXDR(tx: tx, signatures: signatures)
    }

    // MARK: - Protocol-compatible overloads (single prefix)

    /// Emit using the standard `toTxRep(prefix:lines:)` signature.
    ///
    /// `prefix` is used as both the `txPrefix` and the signature prefix is
    /// derived as the parent of `prefix` — this overload exists for protocol
    /// conformance and is not called by the envelope dispatch code.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        // Derive sigPrefix: strip the last component and add dot.
        let sigPrefix = deriveSigPrefix(from: prefix)
        try toTxRep(txPrefix: prefix, sigPrefix: sigPrefix, lines: &lines)
    }

    /// Parse using the standard `fromTxRep(_:prefix:)` signature.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> TransactionV1EnvelopeXDR {
        let sigPrefix = deriveSigPrefix(from: prefix)
        return try fromTxRep(map, txPrefix: prefix, sigPrefix: sigPrefix)
    }
}

/// Derive the signature prefix from a `tx…` prefix.
///
/// Examples:
///   - `"tx"`                    → `""`         (signatures.len is at root)
///   - `"feeBump.tx.innerTx.tx"` → `"feeBump.tx.innerTx."`
private func deriveSigPrefix(from txPrefix: String) -> String {
    guard let dotIdx = txPrefix.lastIndex(of: ".") else {
        // No dot — prefix is "tx"; signatures are at root ("signatures.len").
        return ""
    }
    // Everything up to and including the dot becomes the sig prefix.
    return String(txPrefix[txPrefix.startIndex...dotIdx])
}
