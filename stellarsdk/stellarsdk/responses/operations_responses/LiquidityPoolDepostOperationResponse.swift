//
//  LiquidityPoolDepostOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a liquidity pool deposit operation response.
/// This operation deposits assets into a liquidity pool, providing liquidity to the pool in exchange for pool shares.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#liquidity-pool-deposit "Liquidity Pool Deposit Operation")
public class LiquidityPoolDepostOperationResponse: OperationResponse {

    /// ID of the liquidity pool receiving the deposit.
    public var liquidityPoolId:String

    /// Maximum amounts of each reserve asset that can be deposited.
    public var reservesMax:[ReserveResponse]

    /// Minimum price (as decimal).
    public var minPrice:String

    /// Minimum price as a rational number (numerator/denominator).
    public var minPriceR:LiquidityPoolPriceResponse

    /// Maximum price (as decimal).
    public var maxPrice:String

    /// Maximum price as a rational number (numerator/denominator).
    public var maxPriceR:LiquidityPoolPriceResponse

    /// Actual amounts deposited for each reserve.
    public var reservesDeposited:[ReserveResponse]

    /// Amount of pool shares received in exchange for the deposit.
    public var sharesReceived:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPoolId = "liquidity_pool_id"
        case reservesMax = "reserves_max"
        case minPrice = "min_price"
        case minPriceR = "min_price_r"
        case maxPrice = "max_price"
        case maxPriceR = "max_price_r"
        case reservesDeposited = "reserves_deposited"
        case sharesReceived = "shares_received"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPoolId = try values.decode(String.self, forKey: .liquidityPoolId)
        reservesMax = try values.decode([ReserveResponse].self, forKey: .reservesDeposited)
        minPrice = try values.decode(String.self, forKey: .minPrice)
        minPriceR = try values.decode(LiquidityPoolPriceResponse.self, forKey: .minPriceR)
        maxPrice = try values.decode(String.self, forKey: .maxPrice)
        maxPriceR = try values.decode(LiquidityPoolPriceResponse.self, forKey: .maxPriceR)
        reservesDeposited = try values.decode([ReserveResponse].self, forKey: .reservesDeposited)
        sharesReceived = try values.decode(String.self, forKey: .sharesReceived)
        try super.init(from: decoder)
    }
}
