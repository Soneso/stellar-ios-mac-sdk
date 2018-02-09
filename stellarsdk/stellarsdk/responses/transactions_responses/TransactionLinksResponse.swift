//
//  TransactionLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links connected to a transaction response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/transaction.html "Transaction")
public class TransactionLinksResponse: NSObject, Decodable {
    
    /// Link to the current transaction respones.
    public var selfLink:LinkResponse
    
    /// Link to the source account for this transaction.
    public var account:LinkResponse
    
    /// Link to the ledger in which this transaction was applied.
    public var ledger:LinkResponse
    
    /// Link to operations included in this transaction.
    public var operations:LinkResponse
    
    /// Link to the effects which resulted by operations in this transaction.
    public var effects:LinkResponse
    
   /// A collection of transactions that occur after this transaction.
    public var precedes:LinkResponse
    
    /// A collection of transactions that occur before this transaction.
    public var succeeds:LinkResponse
    
    
    // Properties to encode and decode.
    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
        case account
        case ledger
        case operations
        case effects
        case transaction
        case precedes
        case succeeds
    }
    
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        selfLink = try values.decode(LinkResponse.self, forKey: .selfLink)
        account = try values.decode(LinkResponse.self, forKey: .account)
        ledger = try values.decode(LinkResponse.self, forKey: .ledger)
        operations = try values.decode(LinkResponse.self, forKey: .operations)
        effects = try values.decode(LinkResponse.self, forKey: .effects)
        precedes = try values.decode(LinkResponse.self, forKey: .precedes)
        succeeds = try values.decode(LinkResponse.self, forKey: .succeeds)
    }
}

