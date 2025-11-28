//
//  LiquidityPoolWithdrewEffectResponse.swift.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool withdrawal effect.
/// This effect occurs when an account withdraws assets from a liquidity pool.
/// The account redeems pool shares in exchange for a proportional amount of the pool's reserves.
/// Triggered by the Liquidity Pool Withdraw operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class LiquidityPoolWithdrewEffectResponse: EffectResponse, @unchecked Sendable {

    /// The liquidity pool details.
    public let liquidityPool:LiquidityPoolEffectResponse

    /// The asset reserves received from the pool.
    public let reservesReceived:[ReserveResponse]

    /// The number of pool shares redeemed for the withdrawal.
    public let sharesRedeemed:String
    
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
