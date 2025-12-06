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
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TradeResponse for complete trade details
/// - LinkResponse for individual link structure
public struct TradeLinksResponse: Decodable, Sendable {

    /// Link to the account that provided the base asset in the trade.
    public let base:LinkResponse

    /// Link to the account that provided the counter asset in the trade.
    public let counter:LinkResponse

    /// Link to the operation (Manage Buy Offer, Manage Sell Offer, or Path Payment) that executed this trade.
    public let operation:LinkResponse
    
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
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        base = try values.decode(LinkResponse.self, forKey: .base)
        counter = try values.decode(LinkResponse.self, forKey: .counter)
        operation = try values.decode(LinkResponse.self, forKey: .operation)
    }
}

