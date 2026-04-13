//
//  ChangeTrustAssetXDR+TxRep.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// TxRep serialisation for `ChangeTrustAssetXDR`.
///
/// SEP-0011 uses a compact single-line format for native and credit-asset arms
/// (identical to the `AssetXDR` compact format), and an expanded multi-line
/// format for the pool-share arm.
///
/// Compact examples:
/// ```
/// changeTrustOp.line: XLM
/// changeTrustOp.line: USD:GCMUF...
/// ```
///
/// Pool-share example:
/// ```
/// changeTrustOp.line.type: ASSET_TYPE_POOL_SHARE
/// changeTrustOp.line.liquidityPool.type: LIQUIDITY_POOL_CONSTANT_PRODUCT
/// changeTrustOp.line.liquidityPool.constantProduct.assetA: ...
/// changeTrustOp.line.liquidityPool.constantProduct.assetB: ...
/// changeTrustOp.line.liquidityPool.constantProduct.fee: ...
/// ```
extension ChangeTrustAssetXDR {

    // MARK: - Encoding

    /// Emit TxRep lines for this change-trust asset.
    ///
    /// Native and credit-asset arms emit a single compact line.
    /// Pool-share emits the expanded `type:` + liquidityPool sub-fields.
    ///
    /// - Parameters:
    ///   - prefix: Key prefix without trailing dot, e.g. `"tx.operations[0].body.changeTrustOp.line"`.
    ///   - lines: Output array; lines are appended in SEP-0011 order.
    /// - Throws: `TxRepError` on encoding failure.
    public func toTxRep(prefix: String, lines: inout [String]) throws {
        switch self {
        case .native:
            lines.append("\(prefix): XLM")
        case .alphanum4, .alphanum12:
            lines.append("\(prefix): \(try TxRepHelper.formatChangeTrustAsset(self))")
        case .poolShare(let params):
            lines.append("\(prefix).type: ASSET_TYPE_POOL_SHARE")
            try params.toTxRep(prefix: "\(prefix).liquidityPool", lines: &lines)
        }
    }

    // MARK: - Decoding

    /// Parse a change-trust asset from the TxRep map.
    ///
    /// Attempts compact single-line parsing first (value at `prefix` key).
    /// If absent, falls back to expanded union parsing (`prefix.type` key).
    ///
    /// - Parameters:
    ///   - map: Key-value map produced by `TxRepHelper.parse(_:)`.
    ///   - prefix: Key prefix without trailing dot.
    /// - Returns: Decoded `ChangeTrustAssetXDR`.
    /// - Throws: `TxRepError` on missing or invalid values.
    public static func fromTxRep(_ map: [String: String], prefix: String) throws -> ChangeTrustAssetXDR {
        // Compact path: value directly at the prefix key.
        if let compact = TxRepHelper.getValue(map, prefix) {
            return try TxRepHelper.parseChangeTrustAsset(compact)
        }
        // Expanded path: type discriminant + sub-fields.
        let typeKey = "\(prefix).type"
        guard let typeName = TxRepHelper.getValue(map, typeKey) else {
            throw TxRepError.missingValue(key: prefix)
        }
        switch typeName {
        case "ASSET_TYPE_NATIVE":
            return .native
        case "ASSET_TYPE_CREDIT_ALPHANUM4", "ASSET_TYPE_CREDIT_ALPHANUM12":
            // If expanded format is used for credit assets, parse via compact helper too.
            throw TxRepError.invalidValue(key: typeKey)
        case "ASSET_TYPE_POOL_SHARE":
            let params = try LiquidityPoolParametersXDR.fromTxRep(map, prefix: "\(prefix).liquidityPool")
            return .poolShare(params)
        default:
            throw TxRepError.invalidValue(key: typeKey)
        }
    }
}
