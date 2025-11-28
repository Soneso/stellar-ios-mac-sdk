//
//  TradePrice.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 14.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a trade price as a fraction with numerator and denominator.
public struct TradePrice: Decodable, Sendable {

    /// Numerator of price fraction.
    public let n:String

    /// Denominator of price fraction.
    public let d:String

    /// Creates a trade price from numerator and denominator strings.
    public init(numerator:String, denominator:String) {
        self.n = numerator
        self.d = denominator
    }

    private enum CodingKeys: String, CodingKey {
        case n
        case d
    }

    /**
     Initializer - creates a new instance by decoding from the given decoder.

     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let nInt = try? values.decodeIfPresent(Int32.self, forKey: .n) {
            n = String(nInt)
        } else {
            n = try values.decode(String.self, forKey: .n) 
        }
        if let dInt = try? values.decodeIfPresent(Int32.self, forKey: .d) {
            d = String(dInt)
        } else {
            d = try values.decode(String.self, forKey: .d)
        }
    }
}
