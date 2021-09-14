//
//  LiquidityPoolRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolRemovedEffectResponse: EffectResponse {
    
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
