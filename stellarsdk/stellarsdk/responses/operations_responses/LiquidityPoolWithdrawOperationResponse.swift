//
//  LiquidityPoolWithdrawOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolWithdrawOperationResponse: OperationResponse {
    
    public var liquidityPoolId:String
    public var reservesMin:[ReserveResponse]
    public var shares:String
    public var reservesReceived:[ReserveResponse]

    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case liquidityPoolId = "liquidity_pool_id"
        case reservesMin = "reserves_min"
        case reservesReceived = "reserves_received"
        case shares = "shares"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liquidityPoolId = try values.decode(String.self, forKey: .liquidityPoolId)
        reservesMin = try values.decode([ReserveResponse].self, forKey: .reservesMin)
        shares = try values.decode(String.self, forKey: .shares)
        reservesReceived = try values.decode([ReserveResponse].self, forKey: .reservesReceived)
        
        try super.init(from: decoder)
    }
}
