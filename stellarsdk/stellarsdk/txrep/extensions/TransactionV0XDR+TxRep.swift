//
//  TransactionV0XDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `TransactionV0XDR` (legacy V0 inner transaction).
///
/// V0 transactions are output using the same flat SEP-0011 field layout as V1
/// transactions. The V0 source account (raw 32-byte Ed25519 key) is converted
/// to a G-address for the `sourceAccount` field. The V0 `timeBounds` optional
/// is normalised to a `PRECOND_TIME` / `PRECOND_NONE` preconditions value so
/// the output is indistinguishable from a V1 transaction at the field level.
///
/// SEP-0011 does NOT define a distinct key for V0 vs V1; the enclosing
/// envelope type (`ENVELOPE_TYPE_TX_V0`) is the discriminant.
extension TransactionV0XDR {

    /// Emit TxRep lines for this V0 transaction, normalised to V1 key layout.
    ///
    /// - Parameters:
    ///   - prefix: Key prefix without trailing dot, e.g. `"tx"`.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        // Convert raw Ed25519 bytes to a G-address string.
        let pk = PublicKey(unchecked: self.sourceAccountEd25519)
        lines.append("\(prefix).sourceAccount: \(pk.accountId)")
        lines.append("\(prefix).fee: \(self.fee)")
        lines.append("\(prefix).seqNum: \(self.seqNum)")
        // Normalise V0 timeBounds to PRECOND_TIME / PRECOND_NONE.
        let cond: PreconditionsXDR = self.timeBounds.map { .time($0) } ?? .none
        try cond.toTxRep(prefix: "\(prefix).cond", lines: &lines)
        // Memo.
        try emitMemo(self.memo, prefix: prefix, lines: &lines)
        // Operations.
        lines.append("\(prefix).operations.len: \(self.operations.count)")
        for (i, op) in self.operations.enumerated() {
            try op.toTxRep(prefix: "\(prefix).operations[\(i)]", lines: &lines)
        }
        // V0 has no extension; always emit ext.v: 0.
        lines.append("\(prefix).ext.v: 0")
    }

    /// Parse TxRep lines into a `TransactionV0XDR` value.
    ///
    /// The returned value uses V0 representation (raw Ed25519 source key,
    /// optional timeBounds). Any preconditions beyond PRECOND_TIME are silently
    /// reduced to just the time bounds, since V0 cannot express PRECOND_V2.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Key prefix without trailing dot, e.g. `"tx"`.
    /// - Returns: Decoded `TransactionV0XDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> TransactionV0XDR {
        let sourceAccountKey = "\(prefix).sourceAccount"
        guard let sourceAccountStr = TxRepHelper.getValue(map, sourceAccountKey) else {
            throw TxRepError.missingValue(key: sourceAccountKey)
        }
        let pk: PublicKey
        do {
            pk = try TxRepHelper.parseAccountId(sourceAccountStr)
        } catch {
            throw TxRepError.invalidValue(key: sourceAccountKey)
        }

        let feeStr: String
        if let v = TxRepHelper.getValue(map, "\(prefix).fee") {
            feeStr = v
        } else {
            throw TxRepError.missingValue(key: "\(prefix).fee")
        }
        guard let fee = UInt32(feeStr) else {
            throw TxRepError.invalidValue(key: "\(prefix).fee")
        }

        let seqNumStr: String
        if let v = TxRepHelper.getValue(map, "\(prefix).seqNum") {
            seqNumStr = v
        } else {
            throw TxRepError.missingValue(key: "\(prefix).seqNum")
        }
        guard let seqNum = Int64(seqNumStr) else {
            throw TxRepError.invalidValue(key: "\(prefix).seqNum")
        }

        // Extract optional timeBounds from preconditions / legacy fields.
        let timeBounds: TimeBoundsXDR?
        if let condTypeStr = TxRepHelper.getValue(map, "\(prefix).cond.type") {
            switch condTypeStr {
            case "PRECOND_TIME":
                timeBounds = try TimeBoundsXDR.fromTxRep(map, prefix: "\(prefix).cond.timeBounds")
            case "PRECOND_V2":
                // V2 may embed timeBounds; extract it if present.
                let tbPresent = TxRepHelper.getValue(map, "\(prefix).cond.v2.timeBounds._present")
                if tbPresent == "true" {
                    timeBounds = try TimeBoundsXDR.fromTxRep(map, prefix: "\(prefix).cond.v2.timeBounds")
                } else {
                    timeBounds = nil
                }
            default:
                timeBounds = nil
            }
        } else {
            // Legacy: try timeBounds._present.
            let presentKey = "\(prefix).timeBounds._present"
            if TxRepHelper.getValue(map, presentKey) == "true" {
                timeBounds = try TimeBoundsXDR.fromTxRep(map, prefix: "\(prefix).timeBounds")
            } else {
                timeBounds = nil
            }
        }

        let memo = try parseMemo(map, prefix: prefix)

        let opLenStr: String
        if let v = TxRepHelper.getValue(map, "\(prefix).operations.len") {
            opLenStr = v
        } else {
            throw TxRepError.missingValue(key: "\(prefix).operations.len")
        }
        guard let opLen = Int(opLenStr), opLen >= 0, opLen <= 100 else {
            throw TxRepError.invalidValue(key: "\(prefix).operations.len")
        }
        var operations = [OperationXDR]()
        operations.reserveCapacity(opLen)
        for i in 0..<opLen {
            let op = try OperationXDR.fromTxRep(map, prefix: "\(prefix).operations[\(i)]")
            operations.append(op)
        }

        return TransactionV0XDR(
            sourceAccount: pk,
            seqNum: seqNum,
            timeBounds: timeBounds,
            memo: memo,
            operations: operations,
            maxOperationFee: operations.isEmpty ? fee : fee / UInt32(max(1, operations.count))
        )
    }
}
