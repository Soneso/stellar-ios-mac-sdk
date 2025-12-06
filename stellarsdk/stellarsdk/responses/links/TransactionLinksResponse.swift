//
//  TransactionLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 09.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for transaction-related resources.
///
/// Provides hypermedia links to resources associated with a transaction, including
/// the source account, containing ledger, operations, effects, and chronologically
/// adjacent transactions.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TransactionResponse for complete transaction details
/// - LinkResponse for individual link structure
public struct TransactionLinksResponse: Decodable, Sendable {

    /// Link to this transaction resource (self reference).
    public let selfLink:LinkResponse

    /// Link to the account that submitted this transaction.
    public let account:LinkResponse

    /// Link to the ledger in which this transaction was included.
    public let ledger:LinkResponse

    /// Templated link to operations contained in this transaction. Supports cursor, order, and limit.
    public let operations:LinkResponse

    /// Templated link to effects produced by operations in this transaction. Supports cursor, order, and limit.
    public let effects:LinkResponse

    /// Templated link to transactions that occurred chronologically after this one.
    public let precedes:LinkResponse

    /// Templated link to transactions that occurred chronologically before this one.
    public let succeeds:LinkResponse
    
    
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
    public init(from decoder: Decoder) throws {
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

