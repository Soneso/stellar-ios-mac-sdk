//
//  LedgerLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

/// Represents the links connected to a ledger response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/ledger.html "Ledger")
public class LedgerLinks: NSObject, Codable {
    
    /// Link to the current ledger request URL of this ledger.
    public var selflink:Link
    
    /// Link to the effetcs in this ledger.
    public var effetcs:Link
    
    /// Link to the operations in this ledger.
    public var operations:Link
    
    /// Link to the transactions in this ledger.
    public var transactions:Link
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case effetcs
        case operations
        case transactions
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(Link.self, forKey: .selflink)
        effetcs = try values.decode(Link.self, forKey: .effetcs)
        operations = try values.decode(Link.self, forKey: .operations)
        transactions = try values.decode(Link.self, forKey: .transactions)
    }
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selflink, forKey: .selflink)
        try container.encode(effetcs, forKey: .effetcs)
        try container.encode(operations, forKey: .operations)
        try container.encode(transactions, forKey: .transactions)
    }
}

