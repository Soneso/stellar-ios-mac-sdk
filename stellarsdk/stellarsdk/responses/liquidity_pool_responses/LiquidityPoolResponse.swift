//
//  LiquidityPoolResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolResponse: NSObject, Decodable {
    
    public var links:LiquidityPoolLinksResponse
    public var poolId:String
    public var fee:Int64
    public var type:String
    public var totalTrustlines:String
    public var totalShares:String
    public var reserves:[ReserveResponse]
    public var pagingToken:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case poolId = "id"
        case fee = "fee_bp"
        case type
        case totalTrustlines = "total_trustlines"
        case totalShares = "total_shares"
        case reserves
        case pagingToken = "paging_token"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(LiquidityPoolLinksResponse.self, forKey: .links)
        poolId = try values.decode(String.self, forKey: .poolId)
        fee = try values.decode(Int64.self, forKey: .fee)
        type = try values.decode(String.self, forKey: .type)
        totalTrustlines = try values.decode(String.self, forKey: .totalTrustlines)
        totalShares = try values.decode(String.self, forKey: .totalShares)
        reserves = try values.decode([ReserveResponse].self, forKey: .reserves)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
    }
}
