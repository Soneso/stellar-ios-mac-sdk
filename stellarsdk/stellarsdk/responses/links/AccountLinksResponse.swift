//
//  AccountLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Navigation links for account-related resources.
///
/// Provides hypermedia links to all resources associated with an account, enabling
/// easy navigation to transactions, operations, payments, effects, offers, trades,
/// and data entries for the account.
///
/// All links are templated and support filtering, pagination, and ordering parameters.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AccountResponse for complete account details
/// - LinkResponse for individual link structure
public struct AccountLinksResponse: Decodable, Sendable {

    /// Link to this account resource (self reference).
    public let selflink:LinkResponse

    /// Templated link to transactions for this account. Supports cursor, order, and limit parameters.
    public let transactions:LinkResponse

    /// Templated link to operations involving this account. Supports cursor, order, and limit parameters.
    public let operations:LinkResponse

    /// Templated link to payment operations for this account. Supports cursor, order, and limit parameters.
    public let payments:LinkResponse

    /// Templated link to effects on this account. Supports cursor, order, and limit parameters.
    public let effects:LinkResponse

    /// Templated link to open offers by this account. Supports cursor, order, and limit parameters.
    public let offers:LinkResponse

    /// Templated link to trades executed by this account. Supports cursor, order, and limit parameters.
    public let trades:LinkResponse

    /// Link to the data entries (key-value store) for this account.
    public let data:LinkResponse
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case transactions
        case operations
        case payments
        case effects
        case offers
        case trades
        case data
    }

    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(LinkResponse.self, forKey: .selflink)
        transactions = try values.decode(LinkResponse.self, forKey: .transactions)
        operations = try values.decode(LinkResponse.self, forKey: .operations)
        payments = try values.decode(LinkResponse.self, forKey: .payments)
        effects = try values.decode(LinkResponse.self, forKey: .effects)
        offers = try values.decode(LinkResponse.self, forKey: .offers)
        trades = try values.decode(LinkResponse.self, forKey: .trades)
        data = try values.decode(LinkResponse.self, forKey: .data)
    }
}
