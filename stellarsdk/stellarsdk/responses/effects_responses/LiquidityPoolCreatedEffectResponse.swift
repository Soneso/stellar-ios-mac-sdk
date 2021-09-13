//
//  LiquidityPoolCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolCreatedEffectResponse: EffectResponse {
    
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
