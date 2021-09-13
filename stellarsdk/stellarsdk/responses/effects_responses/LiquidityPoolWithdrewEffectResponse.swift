//
//  LiquidityPoolWithdrewEffectResponse.swift.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolWithdrewEffectResponse: EffectResponse {
    
    public var liquidityPool:LiquidityPoolEffectResponse
    public var reservesReceived:[ReserveResponse]
    public var sharesRedeemed:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPool = "liquidity_pool"
        case reservesReceived = "reserves_received"
        case sharesRedeemed = "shares_redeemed"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPool = try values.decode(LiquidityPoolEffectResponse.self, forKey: .liquidityPool)
        reservesReceived = try values.decode([ReserveResponse].self, forKey: .reservesReceived)
        sharesRedeemed = try values.decode(String.self, forKey: .sharesRedeemed)
        try super.init(from: decoder)
    }
}
