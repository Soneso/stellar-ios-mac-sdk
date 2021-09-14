//
//  LiquidityPoolPriceResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class LiquidityPoolPriceResponse: NSObject, Decodable {
    
    public var n:Int
    public var d:Int
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case n
        case d
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        n = try values.decode(Int.self, forKey: .n)
        d = try values.decode(Int.self, forKey: .d)
    }
}
