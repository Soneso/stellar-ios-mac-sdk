//
//  TradeLinksResponse.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/10/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to a trade response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/trade.html "Trade")
public class TradeLinksResponse: NSObject, Decodable {
    
    /// Link to details about the base account.
    public var base:LinkResponse
    
    /// Link to details about the counter account
    public var counter:LinkResponse
    
    /// Link to the operation of the assets bought and sold.
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

