//
//  TransactionEnvelopeXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `TransactionEnvelopeXDR` — the outermost union.
///
/// This is the top-level entry point for SEP-0011 encoding and decoding.
/// It emits the `type:` discriminant line first and then delegates to the
/// appropriate envelope sub-type.
///
/// Supported envelope types and their key layouts:
///
/// **V1** (`ENVELOPE_TYPE_TX`):
/// ```
/// type: ENVELOPE_TYPE_TX
/// tx.sourceAccount: G…
/// tx.fee: 100
/// tx.seqNum: 123457
/// tx.cond.type: PRECOND_NONE
/// tx.memo.type: MEMO_NONE
/// tx.operations.len: 1
/// tx.operations[0].sourceAccount._present: false
/// tx.operations[0].body.type: …
/// tx.ext.v: 0
/// signatures.len: 1
/// signatures[0].hint: …
/// signatures[0].signature: …
/// ```
///
/// **V0** (`ENVELOPE_TYPE_TX_V0`): same as V1 but with `type: ENVELOPE_TYPE_TX_V0`.
///
/// **Fee-bump** (`ENVELOPE_TYPE_TX_FEE_BUMP`):
/// ```
/// type: ENVELOPE_TYPE_TX_FEE_BUMP
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
extension TransactionEnvelopeXDR {

    // MARK: - Encoding

    /// Emit a complete TxRep document for this envelope.
    ///
    /// The `prefix` parameter is accepted for protocol uniformity but is not
    /// used — TxRep always writes the `type:` key at the document root.
    ///
    /// - Parameters:
    ///   - prefix: Ignored; pass `""` by convention.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        switch self {
        case .v0(let envelope):
            lines.append("type: ENVELOPE_TYPE_TX_V0")
            try envelope.toTxRep(txPrefix: "tx", sigPrefix: "", lines: &lines)

        case .v1(let envelope):
            lines.append("type: ENVELOPE_TYPE_TX")
            // Delegate transaction fields (incl. ext + sorobanData) + signatures.
            try envelope.toTxRep(txPrefix: "tx", sigPrefix: "", lines: &lines)

        case .feeBump(let envelope):
            lines.append("type: ENVELOPE_TYPE_TX_FEE_BUMP")
            // All feeBump.tx.* fields, then feeBump.signatures.*.
            try envelope.toTxRep(prefix: "feeBump", lines: &lines)
        }
    }

    // MARK: - Decoding

    /// Parse a complete TxRep document into a `TransactionEnvelopeXDR`.
    ///
    /// The `prefix` parameter is ignored — the `type:` key is always at the
    /// root of the document.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Ignored; pass `""` by convention.
    /// - Returns: Decoded `TransactionEnvelopeXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> TransactionEnvelopeXDR {
        let typeKey = "type"
        guard let typeStr = TxRepHelper.getValue(map, typeKey) else {
            throw TxRepError.missingValue(key: typeKey)
        }
        switch typeStr {
        case "ENVELOPE_TYPE_TX_V0":
            let envelope = try TransactionV0EnvelopeXDR.fromTxRep(map, txPrefix: "tx", sigPrefix: "")
            return .v0(envelope)

        case "ENVELOPE_TYPE_TX":
            let envelope = try TransactionV1EnvelopeXDR.fromTxRep(map, txPrefix: "tx", sigPrefix: "")
            return .v1(envelope)

        case "ENVELOPE_TYPE_TX_FEE_BUMP":
            let envelope = try FeeBumpTransactionEnvelopeXDR.fromTxRep(map, prefix: "feeBump")
            return .feeBump(envelope)

        default:
            throw TxRepError.invalidValue(key: typeKey)
        }
    }
}
