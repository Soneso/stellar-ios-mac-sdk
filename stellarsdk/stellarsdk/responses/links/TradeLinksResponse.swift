//
//  TradeLinksResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/10/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for trade-related resources.
///
/// Provides hypermedia links to resources associated with a trade, including
/// the base and counter accounts involved and the operation that executed the trade.
///
/// See also:
/// - [Trade Links](https://developers.stellar.org/api/horizon/reference/resources/trade)
/// - TradeResponse for complete trade details
/// - LinkResponse for individual link structure
public class TradeLinksResponse: NSObject, Decodable {

    /// Link to the account that provided the base asset in the trade.
    public var base:LinkResponse

    /// Link to the account that provided the counter asset in the trade.
    public var counter:LinkResponse

    /// Link to the operation (Manage Buy Offer, Manage Sell Offer, or Path Payment) that executed this trade.
    public var operation:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case base
        case counter
        case operation
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        base = try values.decode(LinkResponse.self, forKey: .base)
        counter = try values.decode(LinkResponse.self, forKey: .counter)
        operation = try values.decode(LinkResponse.self, forKey: .operation)
    }
}

