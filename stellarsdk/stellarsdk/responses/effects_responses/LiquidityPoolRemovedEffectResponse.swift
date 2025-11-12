//
//  LiquidityPoolRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool removal effect.
/// This effect occurs when a liquidity pool is removed from the ledger.
/// A pool is removed when all shares have been withdrawn and no reserves remain.
/// Triggered by the Change Trust operation with limit set to zero.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/sdex/liquidity-on-stellar-sdex-liquidity-pools "Liquidity Pools")
public class LiquidityPoolRemovedEffectResponse: EffectResponse {

    /// The unique identifier of the liquidity pool that was removed.
    public var liquidityPoolId:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPoolId = "liquidity_pool_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPoolId = try values.decode(String.self, forKey: .liquidityPoolId)
        try super.init(from: decoder)
    }
}
