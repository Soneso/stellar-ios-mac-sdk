//
//  OfferResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a offer response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/offer.html "offer")
public class OfferResponse: NSObject, Decodable {
    
    /// A list of links related to this offer.
    public var links:OfferLinksResponse
    
    /// Unique identifier for this offer.
    public var id:Int
    
    /// Paging token suitable for use as a cursor parameter.
    public var pagingToken:String
    
    /// The Asset this offer wants to sell.
    public var seller:String
    
    /// The Asset this offer wants to sell.
    public var selling:OfferAssetResponse
    
    /// The Asset this offer wants to buy.
    public var buying:OfferAssetResponse
    
    /// The amount of selling the account making this offer is willing to sell.
    public var amount:String
    
    /// An object of a number numerator and number denominator that represent the buy and sell price of the currencies on offer.
    public var priceR:OfferPriceResponse
    
    /// How many units of buying it takes to get 1 unit of selling. A number representing the decimal form of priceR.
    public var price:String
    
    private enum CodingKeys: String, CodingKey {
        
        case links = "_links"
        case id
        case pagingToken = "paging_token"
        case seller
        case selling
        case buying
        case amount
        case priceR = "price_r"
        case price
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(OfferLinksResponse.self, forKey: .links)
        id = try values.decode(Int.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        seller = try values.decode(String.self, forKey: .seller)
        selling = try values.decode(OfferAssetResponse.self, forKey: .selling)
        buying = try values.decode(OfferAssetResponse.self, forKey: .buying)
        amount = try values.decode(String.self, forKey: .amount)
        priceR = try values.decode(OfferPriceResponse.self, forKey: .priceR)
        price = try values.decode(String.self, forKey: .price)
        
    }
}
