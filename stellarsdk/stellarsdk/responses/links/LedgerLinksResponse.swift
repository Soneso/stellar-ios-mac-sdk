//
//  LedgerLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for ledger-related resources.
///
/// Provides hypermedia links to resources contained within a ledger, including
/// transactions, operations, payments, and effects that occurred in this ledger.
///
/// See also:
/// - [Ledger Links](https://developers.stellar.org/api/horizon/reference/resources/ledger)
/// - LedgerResponse for complete ledger details
/// - LinkResponse for individual link structure
public class LedgerLinksResponse: NSObject, Decodable {

    /// Link to this ledger resource (self reference).
    public var selflink:LinkResponse

    /// Templated link to effects that occurred in this ledger. Supports cursor, order, and limit.
    public var effects:LinkResponse

    /// Templated link to operations included in this ledger. Supports cursor, order, and limit.
    public var operations:LinkResponse

    /// Templated link to payment operations in this ledger. Supports cursor, order, and limit.
    public var payments:LinkResponse

    /// Templated link to transactions included in this ledger. Supports cursor, order, and limit.
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

