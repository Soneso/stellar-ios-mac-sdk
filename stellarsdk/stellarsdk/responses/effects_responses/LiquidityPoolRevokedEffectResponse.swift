//
//  LiquidityPoolRevokedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool revocation effect.
/// This effect occurs when trustline authorization for a liquidity pool is revoked by an asset issuer.
/// The pool shares are revoked and the reserves are returned.
/// Triggered by the Set Trust Line Flags or Allow Trust operations.
/// See [Stellar developer docs](https://developers.stellar.org)
public class LiquidityPoolRevokedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The liquidity pool details.
    public let liquidityPool:LiquidityPoolEffectResponse

    /// The asset reserves revoked from the pool.
    public let reservesRevoked:[ReserveResponse]

    /// The number of pool shares revoked.
    public let sharesRevoked:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPool = "liquidity_pool"
        case reservesRevoked = "reserves_revoked"
        case sharesRevoked = "shares_revoked"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPool = try values.decode(LiquidityPoolEffectResponse.self, forKey: .liquidityPool)
        reservesRevoked = try values.decode([ReserveResponse].self, forKey: .reservesRevoked)
        sharesRevoked = try values.decode(String.self, forKey: .sharesRevoked)
        try super.init(from: decoder)
    }
}
