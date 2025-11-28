//
//  OrderbookOfferResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a orderbook offer(bids/asks).
///  See [Stellar developer docs](https://developers.stellar.org)
public struct OrderbookOfferResponse: Decodable, Sendable {
    
    /// An object of a number numerator and number denominator that represent the buy and sell price of the currencies on offer.
    public let priceR:OfferPriceResponse
    
    /// How many units of buying it takes to get 1 unit of selling. A number representing the decimal form of priceR.
    public let price:String
    
    /// The amount of selling the account making this offer is willing to sell.
    public let amount:String
    
    private enum CodingKeys: String, CodingKey {
        
        case priceR = "price_r"
        case price
        case amount
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        priceR = try values.decode(OfferPriceResponse.self, forKey: .priceR)
        price = try values.decode(String.self, forKey: .price)
        amount = try values.decode(String.self, forKey: .amount)
    }
}
