//
//  TrustlineAssetXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `TrustlineAssetXDR`.
///
/// SEP-0011 uses a compact single-line format for native and credit-asset arms,
/// and an expanded multi-line format for the pool-share arm.
///
/// Compact examples:
/// ```
/// ledgerKey.trustLine.asset: XLM
/// ledgerKey.trustLine.asset: USD:GCMUF...
/// ```
///
/// Pool-share example:
/// ```
/// ledgerKey.trustLine.asset.type: ASSET_TYPE_POOL_SHARE
/// ledgerKey.trustLine.asset.liquidityPoolID: <64-char hex>
/// ```
extension TrustlineAssetXDR {

    // MARK: - Encoding

    /// Emit TxRep lines for this trustline asset.
    ///
    /// Native and credit-asset arms emit a single compact line.
    /// Pool-share emits `type: ASSET_TYPE_POOL_SHARE` + the hex pool ID.
    ///
    /// - Parameters:
    ///   - prefix: Key prefix without trailing dot.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        switch self {
        case .native:
            lines.append("\(prefix): XLM")
        case .alphanum4, .alphanum12:
            lines.append("\(prefix): \(try TxRepHelper.formatTrustlineAsset(self))")
        case .poolShare(let poolId):
            lines.append("\(prefix).type: ASSET_TYPE_POOL_SHARE")
            lines.append("\(prefix).liquidityPoolID: \(TxRepHelper.bytesToHex(poolId.wrapped))")
        }
    }

    // MARK: - Decoding

    /// Parse a trustline asset from the TxRep map.
    ///
    /// Attempts compact single-line parsing first (value at `prefix` key).
    /// If absent, falls back to expanded union parsing (`prefix.type` key).
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Key prefix without trailing dot.
    /// - Returns: Decoded `TrustlineAssetXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> TrustlineAssetXDR {
        // Compact path: value directly at the prefix key.
        if let compact = TxRepHelper.getValue(map, prefix) {
            return try TxRepHelper.parseTrustlineAsset(compact)
        }
        // Expanded path: type discriminant + sub-fields.
        let typeKey = "\(prefix).type"
        guard let typeName = TxRepHelper.getValue(map, typeKey) else {
            throw TxRepError.missingValue(key: prefix)
        }
        switch typeName {
        case "ASSET_TYPE_NATIVE":
            return .native
        case "ASSET_TYPE_POOL_SHARE":
            let poolIdKey = "\(prefix).liquidityPoolID"
            let poolId = WrappedData32(try TxRepHelper.requireHex(map, poolIdKey))
            return .poolShare(poolId)
        default:
            throw TxRepError.invalidValue(key: typeKey)
        }
    }
}
