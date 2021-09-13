//
//  LiquidityPoolRevokedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolRevokedEffectResponse: EffectResponse {
    
    public var liquidityPool:LiquidityPoolEffectResponse
    public var reservesRevoked:[ReserveResponse]
    public var sharesRevoked:String
    
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
