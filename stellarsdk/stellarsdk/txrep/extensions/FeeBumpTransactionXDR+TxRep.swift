//
//  FeeBumpTransactionXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `FeeBumpTransactionXDR`.
///
/// The fee-bump transaction produces:
/// ```
/// feeBump.tx.feeSource: G…
/// feeBump.tx.fee: 200
/// feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
/// feeBump.tx.innerTx.tx.sourceAccount: G…
/// …(full inner V1 transaction fields)…
/// feeBump.tx.innerTx.signatures.len: N
/// feeBump.tx.innerTx.signatures[0].hint: …
/// feeBump.tx.innerTx.signatures[0].signature: …
/// feeBump.tx.ext.v: 0
/// ```
///
/// The enclosing `FeeBumpTransactionEnvelopeXDR.toTxRep` adds the outer
/// `feeBump.signatures.*` block after this method returns.
extension FeeBumpTransactionXDR {

    /// Emit TxRep lines for this fee-bump transaction.
    ///
    /// - Parameters:
    ///   - prefix: Key prefix without trailing dot, e.g. `"feeBump.tx"`.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        lines.append("\(prefix).feeSource: \(try TxRepHelper.formatMuxedAccount(self.sourceAccount))")
        lines.append("\(prefix).fee: \(self.fee)")
        // Inner transaction.
        try self.innerTx.toTxRep(prefix: "\(prefix).innerTx", lines: &lines)
        // Fee-bump ext — always v=0 per current XDR.
        lines.append("\(prefix).ext.v: 0")
    }

    /// Parse a `FeeBumpTransactionXDR` from the TxRep map.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Key prefix without trailing dot, e.g. `"feeBump.tx"`.
    /// - Returns: Decoded `FeeBumpTransactionXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> FeeBumpTransactionXDR {
        let feeSourceKey = "\(prefix).feeSource"
        guard let feeSourceStr = TxRepHelper.getValue(map, feeSourceKey) else {
            throw TxRepError.missingValue(key: feeSourceKey)
        }
        let feeSource: MuxedAccountXDR
        do {
            feeSource = try TxRepHelper.parseMuxedAccount(feeSourceStr)
        } catch {
            throw TxRepError.invalidValue(key: feeSourceKey)
        }

        let feeStr: String
        if let v = TxRepHelper.getValue(map, "\(prefix).fee") {
            feeStr = v
        } else {
            throw TxRepError.missingValue(key: "\(prefix).fee")
        }
        guard let fee = UInt64(feeStr) else {
            throw TxRepError.invalidValue(key: "\(prefix).fee")
        }

        let innerTx = try FeeBumpTransactionXDRInnerTxXDR.fromTxRep(map, prefix: "\(prefix).innerTx")

        return FeeBumpTransactionXDR(sourceAccount: feeSource, innerTx: innerTx, fee: fee)
    }
}
