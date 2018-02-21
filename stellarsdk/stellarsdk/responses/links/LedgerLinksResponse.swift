//
//  LedgerLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to a ledger response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/ledger.html "Ledger")
public class LedgerLinksResponse: NSObject, Decodable {
    
    /// Link to the current ledger request URL of this ledger.
    public var selflink:LinkResponse
    
    /// Link to the effects in this ledger.
    public var effects:LinkResponse
    
    /// Link to the operations in this ledger.
    public var operations:LinkResponse
    
    /// Link to the payments in this ledger.
    public var payments:LinkResponse
    
    /// Link to the transactions in this ledger.
    public var transactions:LinkResponse
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case effects
        case operations
        case payments
        case transactions
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        effects = try values.decode(LinkResponse.self, forKey: .effects)
        operations = try values.decode(LinkResponse.self, forKey: .operations)
        payments = try values.decode(LinkResponse.self, forKey: .payments)
        transactions = try values.decode(LinkResponse.self, forKey: .transactions)
    }
}

