//
//  OfferResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a offer response.
///  See [Stellar developer docs](https://developers.stellar.org)
public struct OfferResponse: Decodable, Sendable {
    
    /// A list of links related to this offer.
    public let links:OfferLinksResponse
    
    /// Unique identifier for this offer.
    public let id:String
    
    /// Paging token suitable for use as a cursor parameter.
    public let pagingToken:String
    
    /// The seller of this offer.
    public let seller:String
    
    /// The Asset this offer wants to sell.
    public let selling:OfferAssetResponse
    
    /// The Asset this offer wants to buy.
    public let buying:OfferAssetResponse
    
    /// The amount of selling the account making this offer is willing to sell.
    public let amount:String
    
    /// An object of a number numerator and number denominator that represent the buy and sell price of the currencies on offer.
    public let priceR:OfferPriceResponse
    
    /// How many units of buying it takes to get 1 unit of selling. A number representing the decimal form of priceR.
    public let price:String

    /// The account ID of the sponsor who is paying the reserves for this offer. Optional, only present if the offer is sponsored.
    public let sponsor:String?

    /// The sequence number of the ledger in which this offer was last modified.
    public let lastModifiedLedger:Int

    /// An ISO 8601 formatted string of when this offer was last modified.
    public let lastModifiedTime:String?
    
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
        case sponsor
        case lastModifiedLedger = "last_modified_ledger"
        case lastModifiedTime = "last_modified_time"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        links = try values.decode(OfferLinksResponse.self, forKey: .links)
        id = try values.decode(String.self, forKey: .id)
        pagingToken = try values.decode(String.self, forKey: .pagingToken)
        seller = try values.decode(String.self, forKey: .seller)
        selling = try values.decode(OfferAssetResponse.self, forKey: .selling)
        buying = try values.decode(OfferAssetResponse.self, forKey: .buying)
        amount = try values.decode(String.self, forKey: .amount)
        priceR = try values.decode(OfferPriceResponse.self, forKey: .priceR)
        price = try values.decode(String.self, forKey: .price)
        sponsor = try values.decodeIfPresent(String.self, forKey: .sponsor)
        lastModifiedLedger = try values.decode(Int.self, forKey: .lastModifiedLedger)
        lastModifiedTime = try values.decodeIfPresent(String.self, forKey: .lastModifiedTime)
    }
}
