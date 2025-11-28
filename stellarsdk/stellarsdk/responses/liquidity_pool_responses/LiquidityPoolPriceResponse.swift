//
//  LiquidityPoolPriceResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a price ratio in a liquidity pool.
/// The price is represented as a fraction with a numerator and denominator.
/// See [Stellar developer docs](https://developers.stellar.org)
public struct LiquidityPoolPriceResponse: Decodable, Sendable {

    /// The numerator of the price fraction.
    public let n:Int

    /// The denominator of the price fraction.
    public let d:Int
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case n
        case d
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        n = try values.decode(Int.self, forKey: .n)
        d = try values.decode(Int.self, forKey: .d)
    }
}
