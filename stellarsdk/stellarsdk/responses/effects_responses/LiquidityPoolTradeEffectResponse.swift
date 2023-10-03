//
//  LiquidityPoolTradeEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolTradeEffectResponse: EffectResponse {
    
    public var liquidityPool:LiquidityPoolEffectResponse
    public var sold:ReserveResponse
    public var bought:ReserveResponse
    
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
