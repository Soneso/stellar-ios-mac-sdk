//
//  TransactionXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `TransactionXDR` (V1 inner transaction).
///
/// The SEP-0011 key layout is flat:
/// ```
/// <prefix>.sourceAccount: G…
/// <prefix>.fee: 100
/// <prefix>.seqNum: 123457
/// <prefix>.cond.type: PRECOND_NONE
/// <prefix>.memo.type: MEMO_NONE
/// <prefix>.operations.len: 1
/// <prefix>.operations[0]…
/// <prefix>.ext.v: 0          (or 1 + sorobanData.* when Soroban)
/// ```
///
/// Note: The `prefix` passed by the envelope layer already includes the
/// trailing dot, e.g. `"tx"` or `"feeBump.tx.innerTx.tx"`. Keys are formed
/// as `"\(prefix).\(field)"`.
extension TransactionXDR {

    /// Emit TxRep lines for this V1 transaction.
    ///
    /// - Parameters:
    ///   - prefix: Key prefix without trailing dot, e.g. `"tx"`.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        // Source account — G-address or M-address.
        lines.append("\(prefix).sourceAccount: \(try TxRepHelper.formatMuxedAccount(self.sourceAccount))")
        // Fee as a plain integer.
        lines.append("\(prefix).fee: \(self.fee)")
        // Sequence number as stored in XDR (account sequence + 1).
        lines.append("\(prefix).seqNum: \(self.seqNum)")
        // Preconditions.
        try self.cond.toTxRep(prefix: "\(prefix).cond", lines: &lines)
        // Memo — MEMO_TEXT uses JSON-compatible legacy encoding.
        try emitMemo(self.memo, prefix: prefix, lines: &lines)
        // Operations array.
        lines.append("\(prefix).operations.len: \(self.operations.count)")
        for (i, op) in self.operations.enumerated() {
            try op.toTxRep(prefix: "\(prefix).operations[\(i)]", lines: &lines)
        }
        // Transaction extension.  SEP-0011 flattens: ext.v + sorobanData.* (not ext.sorobanData.*).
        try emitTransactionExt(self.ext, prefix: prefix, lines: &lines)
    }

    /// Parse TxRep lines into a `TransactionXDR` value.
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Key prefix without trailing dot, e.g. `"tx"`.
    /// - Returns: Decoded `TransactionXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> TransactionXDR {
        let sourceAccountKey = "\(prefix).sourceAccount"
        let sourceAccountStr = try requireValue(map, sourceAccountKey)
        let sourceAccount: MuxedAccountXDR
        do {
            sourceAccount = try TxRepHelper.parseMuxedAccount(sourceAccountStr)
        } catch {
            throw TxRepError.invalidValue(key: sourceAccountKey)
        }

        let feeStr = try requireValue(map, "\(prefix).fee")
        guard let fee = UInt32(feeStr) else {
            throw TxRepError.invalidValue(key: "\(prefix).fee")
        }

        let seqNumStr = try requireValue(map, "\(prefix).seqNum")
        guard let seqNum = Int64(seqNumStr) else {
            throw TxRepError.invalidValue(key: "\(prefix).seqNum")
        }

        // Preconditions — with legacy fallback: if cond.type is absent but
        // timeBounds._present exists, synthesise a PRECOND_TIME / PRECOND_NONE.
        let cond: PreconditionsXDR
        if TxRepHelper.getValue(map, "\(prefix).cond.type") != nil {
            cond = try PreconditionsXDR.fromTxRep(map, prefix: "\(prefix).cond")
        } else {
            cond = try legacyPreconditions(map, prefix: prefix)
        }

        let memo = try parseMemo(map, prefix: prefix)

        let opLenKey = "\(prefix).operations.len"
        let opLenStr = try requireValue(map, opLenKey)
        guard let opLen = Int(opLenStr), opLen >= 0 else {
            throw TxRepError.invalidValue(key: opLenKey)
        }
        guard opLen <= 100 else {
            throw TxRepError.invalidValue(key: "\(opLenKey) > 100")
        }
        var operations = [OperationXDR]()
        operations.reserveCapacity(opLen)
        for i in 0..<opLen {
            let op = try OperationXDR.fromTxRep(map, prefix: "\(prefix).operations[\(i)]")
            operations.append(op)
        }

        let ext = try parseTransactionExt(map, prefix: prefix)

        return TransactionXDR(
            sourceAccount: sourceAccount,
            seqNum: seqNum,
            cond: cond,
            memo: memo,
            operations: operations,
            maxOperationFee: operations.isEmpty ? fee : fee / UInt32(max(1, operations.count)),
            ext: ext
        )
    }
}

// MARK: - Internal helpers shared across transaction envelope types

/// Emit MEMO_TEXT using JSON-compatible legacy encoding; delegate all other
/// memo types to the generated `MemoXDR.toTxRep`.
internal func emitMemo(_ memo: MemoXDR, prefix: String, lines: inout [String]) throws {
    switch memo {
    case .text(let s):
        lines.append("\(prefix).memo.type: MEMO_TEXT")
        lines.append("\(prefix).memo.text: \(TxRepHelper.encodeMemoText(s))")
    default:
        try memo.toTxRep(prefix: "\(prefix).memo", lines: &lines)
    }
}

/// Parse memo from TxRep map, throwing on missing or invalid values.
///
/// Handles all memo types inline to ensure correct error keys:
/// - Missing `memo.type` throws `missingValue`
/// - Missing/invalid sub-fields throw `missingValue`/`invalidValue` with the field key
internal func parseMemo(_ map: [String: String], prefix: String) throws -> MemoXDR {
    let typeKey = "\(prefix).memo.type"
    guard let memoType = TxRepHelper.getValue(map, typeKey) else {
        throw TxRepError.missingValue(key: typeKey)
    }
    switch memoType {
    case "MEMO_NONE":
        return .none
    case "MEMO_TEXT":
        let textKey = "\(prefix).memo.text"
        guard let raw = TxRepHelper.getValue(map, textKey) else {
            throw TxRepError.missingValue(key: textKey)
        }
        let decoded = try TxRepHelper.decodeMemoText(raw)
        return .text(decoded)
    case "MEMO_ID":
        return .id(try TxRepHelper.requireUInt64(map, "\(prefix).memo.id"))
    case "MEMO_HASH":
        let hash = try TxRepHelper.requireWrappedData32(map, "\(prefix).memo.hash")
        return .hash(hash)
    case "MEMO_RETURN":
        let retHash = try TxRepHelper.requireWrappedData32(map, "\(prefix).memo.retHash")
        return .returnHash(retHash)
    default:
        throw TxRepError.invalidValue(key: typeKey)
    }
}

/// Emit `ext.v: 0` or `ext.v: 1` plus the flattened `sorobanData.*` keys.
///
/// SEP-0011 maps `TransactionExtXDR.sorobanTransactionData` to:
///   `<prefix>.ext.v: 1`
///   `<prefix>.sorobanData.ext.v: …`
///   `<prefix>.sorobanData.resources.…`
///   `<prefix>.sorobanData.resourceFee: …`
/// NOT `<prefix>.ext.sorobanData.*` — so we cannot delegate to the generated
/// `TransactionExtXDR.toTxRep` which uses the wrong prefix.
internal func emitTransactionExt(_ ext: TransactionExtXDR, prefix: String, lines: inout [String]) throws {
    switch ext {
    case .void:
        lines.append("\(prefix).ext.v: 0")
    case .sorobanTransactionData(let data):
        lines.append("\(prefix).ext.v: 1")
        try data.toTxRep(prefix: "\(prefix).sorobanData", lines: &lines)
    }
}

/// Parse the `ext.v` discriminant and optional sorobanData block.
internal func parseTransactionExt(_ map: [String: String], prefix: String) throws -> TransactionExtXDR {
    let vKey = "\(prefix).ext.v"
    let vStr = TxRepHelper.getValue(map, vKey) ?? "0"
    guard let v = Int(vStr) else {
        throw TxRepError.invalidValue(key: vKey)
    }
    switch v {
    case 0:
        return .void
    case 1:
        let data = try SorobanTransactionDataXDR.fromTxRep(map, prefix: "\(prefix).sorobanData")
        return .sorobanTransactionData(data)
    default:
        throw TxRepError.invalidValue(key: vKey)
    }
}

/// Emit an array of `DecoratedSignatureXDR` values at the given prefix.
///
/// Produces:
/// ```
/// <sigPrefix>signatures.len: N
/// <sigPrefix>signatures[0].hint: …
/// <sigPrefix>signatures[0].signature: …
/// …
/// ```
internal func emitSignatures(_ signatures: [DecoratedSignatureXDR], sigPrefix: String, lines: inout [String]) throws {
    lines.append("\(sigPrefix)signatures.len: \(signatures.count)")
    for (i, sig) in signatures.enumerated() {
        try sig.toTxRep(prefix: "\(sigPrefix)signatures[\(i)]", lines: &lines)
    }
}

/// Parse `signatures.len` + indexed entries.
/// Missing `signatures.len` is treated as an unsigned (pre-signature) transaction — returns `[]`.
/// A present but non-integer or negative value throws `invalidValue`.
/// count > 20 throws `invalidValue` with the key suffix `"> 20"` so callers can detect the over-limit case.
internal func parseSignatures(_ map: [String: String], sigPrefix: String) throws -> [DecoratedSignatureXDR] {
    let lenKey = "\(sigPrefix)signatures.len"
    guard let lenStr = TxRepHelper.getValue(map, lenKey) else {
        // Absent signatures.len is valid — unsigned transactions omit it.
        return []
    }
    guard let count = Int(lenStr), count >= 0 else {
        throw TxRepError.invalidValue(key: lenKey)
    }
    guard count <= 20 else {
        throw TxRepError.invalidValue(key: "\(lenKey) > 20")
    }
    var signatures = [DecoratedSignatureXDR]()
    signatures.reserveCapacity(count)
    for i in 0..<count {
        let sig = try DecoratedSignatureXDR.fromTxRep(map, prefix: "\(sigPrefix)signatures[\(i)]")
        signatures.append(sig)
    }
    return signatures
}

/// Synthesise `PreconditionsXDR` from the legacy V0 `timeBounds._present` key.
///
/// Used when `cond.type` is absent in the TxRep map (pre-PRECOND support).
internal func legacyPreconditions(_ map: [String: String], prefix: String) throws -> PreconditionsXDR {
    let presentKey = "\(prefix).timeBounds._present"
    if let present = TxRepHelper.getValue(map, presentKey), present == "true" {
        let minStr = TxRepHelper.getValue(map, "\(prefix).timeBounds.minTime") ?? "0"
        let maxStr = TxRepHelper.getValue(map, "\(prefix).timeBounds.maxTime") ?? "0"
        guard let minTime = UInt64(minStr) else {
            throw TxRepError.invalidValue(key: "\(prefix).timeBounds.minTime")
        }
        guard let maxTime = UInt64(maxStr) else {
            throw TxRepError.invalidValue(key: "\(prefix).timeBounds.maxTime")
        }
        return .time(TimeBoundsXDR(minTime: minTime, maxTime: maxTime))
    }
    return .none
}

/// Require a value from the map, throwing `missingValue` if absent.
private func requireValue(_ map: [String: String], _ key: String) throws -> String {
    guard let val = TxRepHelper.getValue(map, key) else {
        throw TxRepError.missingValue(key: key)
    }
    return val
}
