//
//  LiquidityPoolDepositedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolDepositedEffectResponse: EffectResponse {
    
    public var liquidityPool:LiquidityPoolEffectResponse
    public var reservesDeposited:[ReserveResponse]
    public var sharesReceived:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPool = "liquidity_pool"
        case reservesDeposited = "reserves_deposited"
        case sharesReceived = "shares_received"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPool = try values.decode(LiquidityPoolEffectResponse.self, forKey: .liquidityPool)
        reservesDeposited = try values.decode([ReserveResponse].self, forKey: .reservesDeposited)
        sharesReceived = try values.decode(String.self, forKey: .sharesReceived)
        try super.init(from: decoder)
    }
}
