//
//  OrderbookResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/12/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents a orderbook response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/orderbook.html "Orderbook")
public class OrderbookResponse: NSObject, Decodable {
    
    /// An array of prices and amounts accounts are willing to buy for the given selling and buying pair.
    public var bids:[OrderbookOfferResponse]
    
    /// An array of prices and amounts accounts are willing to sell for the given selling and buying pair.
    public var asks:[OrderbookOfferResponse]
    
    /// The Asset this offer wants to sell.
    public var selling:OfferAssetResponse
    
    /// The Asset this offer wants to buy.
    public var buying:OfferAssetResponse
    
    private enum CodingKeys: String, CodingKey {
        
        case bids
        case asks
        case selling = "base"
        case buying = "counter"
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bids = try values.decode(Array.self, forKey: .bids)
        asks = try values.decode(Array.self, forKey: .asks)
        selling = try values.decode(OfferAssetResponse.self, forKey: .selling)
        buying = try values.decode(OfferAssetResponse.self, forKey: .buying)

    }
}
