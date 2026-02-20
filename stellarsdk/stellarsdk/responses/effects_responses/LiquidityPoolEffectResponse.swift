//
//  LiquidityPoolEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents liquidity pool details within an effect response.
/// Contains information about the pool's state, including reserves, shares, and fee structure.
/// Used as a nested object in liquidity pool effect responses.
/// See [Stellar developer docs](https://developers.stellar.org)
public struct LiquidityPoolEffectResponse: Decodable, Sendable {

    /// The unique identifier of the liquidity pool.
    public let poolId:String

    /// The fee charged for trades against this pool, in basis points.
    public let fee:Int64

    /// The type of liquidity pool (e.g., constant_product).
    public let type:String

    /// The total number of trustlines established to this pool.
    public let totalTrustlines:String

    /// The total number of pool shares issued.
    public let totalShares:String

    /// The asset reserves held by the pool.
    public let reserves:[ReserveResponse]
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case poolId = "id"
        case fee = "fee_bp"
        case type
        case totalTrustlines = "total_trustlines"
        case totalShares = "total_shares"
        case reserves
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        poolId = try values.decode(String.self, forKey: .poolId)
        fee = try values.decode(Int64.self, forKey: .fee)
        type = try values.decode(String.self, forKey: .type)
        totalTrustlines = try values.decode(String.self, forKey: .totalTrustlines)
        totalShares = try values.decode(String.self, forKey: .totalShares)
        reserves = try values.decode([ReserveResponse].self, forKey: .reserves)
    }
}
