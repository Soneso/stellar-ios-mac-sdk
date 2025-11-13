//
//  LiquidityPoolDepositedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool deposit effect.
/// This effect occurs when an account deposits assets into a liquidity pool.
/// The account receives pool shares in exchange for the deposited assets.
/// Triggered by the Liquidity Pool Deposit operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class LiquidityPoolDepositedEffectResponse: EffectResponse {

    /// The liquidity pool details.
    public var liquidityPool:LiquidityPoolEffectResponse

    /// The asset reserves deposited into the pool.
    public var reservesDeposited:[ReserveResponse]

    /// The number of pool shares received for the deposit.
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
