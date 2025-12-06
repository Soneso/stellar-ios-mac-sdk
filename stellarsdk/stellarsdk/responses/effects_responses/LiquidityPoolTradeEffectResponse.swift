//
//  LiquidityPoolTradeEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool trade effect.
/// This effect occurs when a trade is executed against a liquidity pool.
/// The pool automatically provides liquidity for the trade based on its constant product formula.
/// Triggered by Path Payment operations or trades that match against the pool.
/// See [Stellar developer docs](https://developers.stellar.org)
public class LiquidityPoolTradeEffectResponse: EffectResponse, @unchecked Sendable {

    /// The liquidity pool details.
    public let liquidityPool:LiquidityPoolEffectResponse

    /// The asset reserve sold from the pool.
    public let sold:ReserveResponse

    /// The asset reserve bought from the pool.
    public let bought:ReserveResponse
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPool = "liquidity_pool"
        case sold
        case bought
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPool = try values.decode(LiquidityPoolEffectResponse.self, forKey: .liquidityPool)
        sold = try values.decode(ReserveResponse.self, forKey: .sold)
        bought = try values.decode(ReserveResponse.self, forKey: .bought)
        try super.init(from: decoder)
    }
}
