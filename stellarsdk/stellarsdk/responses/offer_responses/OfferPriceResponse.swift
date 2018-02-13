//
//  OfferPriceResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation


///  Represents an offer price_r attribute.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/offer.html "offer")
public class OfferPriceResponse: NSObject, Decodable {
    
    /// represent the buy price of the currencies on offer.
    public var numerator:Int
    
    /// represent the sell price of the currencies on offer.
    public var denominator:Int
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case numerator = "n"
        case denominator = "d"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        numerator = try values.decode(Int.self, forKey: .numerator)
        denominator = try values.decode(Int.self, forKey: .denominator)
    }
}
