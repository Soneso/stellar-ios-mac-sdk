//
//  LiquidityPoolRevokedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolRevokedEffectResponse: EffectResponse {
    
    public var liquidityPool:LiquidityPoolRevokedResponse
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPool = "liquidity_pool"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPool = try values.decode(LiquidityPoolRevokedResponse.self, forKey: .liquidityPool)
        try super.init(from: decoder)
    }
}

public class LiquidityPoolRevokedResponse: NSObject, Decodable {
    
    public var poolId:String
    public var fee:Int64
    public var type:String
    public var totalTrustlines:String
    public var totalShares:String
    public var reserves:[ReserveResponse]
    public var reservesRevoked:[ReserveResponse]
    public var sharesRevoked:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case poolId = "id"
        case fee = "fee_bp"
        case type
        case totalTrustlines = "total_trustlines"
        case totalShares = "total_shares"
        case reserves
        case reservesRevoked = "reserves_revoked"
        case sharesRevoked = "shares_revoked"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        poolId = try values.decode(String.self, forKey: .poolId)
        fee = try values.decode(Int64.self, forKey: .fee)
        type = try values.decode(String.self, forKey: .type)
        totalTrustlines = try values.decode(String.self, forKey: .totalTrustlines)
        totalShares = try values.decode(String.self, forKey: .totalShares)
        reserves = try values.decode([ReserveResponse].self, forKey: .reserves)
        reservesRevoked = try values.decode([ReserveResponse].self, forKey: .reservesRevoked)
        sharesRevoked = try values.decode(String.self, forKey: .sharesRevoked)
    }
}
