//
//  LiquidityPoolCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool creation effect.
/// This effect occurs when a new liquidity pool is created on the Stellar network.
/// Liquidity pools enable automated market making for asset pairs on the decentralized exchange.
/// Triggered by the Change Trust operation with a liquidity pool asset.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/sdex/liquidity-on-stellar-sdex-liquidity-pools "Liquidity Pools")
public class LiquidityPoolCreatedEffectResponse: EffectResponse {

    /// The liquidity pool details.
    public var liquidityPool:LiquidityPoolEffectResponse
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPool = "liquidity_pool"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPool = try values.decode(LiquidityPoolEffectResponse.self, forKey: .liquidityPool)
        try super.init(from: decoder)
    }
}
