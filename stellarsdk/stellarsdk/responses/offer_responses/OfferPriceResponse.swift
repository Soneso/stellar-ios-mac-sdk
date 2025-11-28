//
//  OfferPriceResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation


/// Represents an offer price_r attribute as a fraction.
/// The price represents how many units of the buying asset are needed to purchase one unit of the selling asset.
/// See [Stellar developer docs](https://developers.stellar.org)
public struct OfferPriceResponse: Decodable, Sendable {

    /// The numerator of the price fraction.
    public let numerator:Int32

    /// The denominator of the price fraction.
    public let denominator:Int32
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case numerator = "n"
        case denominator = "d"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        numerator = try values.decode(Int32.self, forKey: .numerator)
        denominator = try values.decode(Int32.self, forKey: .denominator)
    }
}
