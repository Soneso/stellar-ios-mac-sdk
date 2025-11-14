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
public class AccountLinksResponse: NSObject, Decodable {

    /// Link to this account resource (self reference).
    public var selflink:LinkResponse!

    /// Templated link to transactions for this account. Supports cursor, order, and limit parameters.
    public var transactions:LinkResponse!

    /// Templated link to operations involving this account. Supports cursor, order, and limit parameters.
    public var operations:LinkResponse!

    /// Templated link to payment operations for this account. Supports cursor, order, and limit parameters.
    public var payments:LinkResponse!

    /// Templated link to effects on this account. Supports cursor, order, and limit parameters.
    public var effects:LinkResponse!

    /// Templated link to open offers by this account. Supports cursor, order, and limit parameters.
    public var offers:LinkResponse!

    /// Templated link to trades executed by this account. Supports cursor, order, and limit parameters.
    public var trades:LinkResponse!

    /// Link to the data entries (key-value store) for this account.
    public var data:LinkResponse!
    
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
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decodeIfPresent(LinkResponse.self, forKey: .selflink)
        transactions = try values.decodeIfPresent(LinkResponse.self, forKey: .transactions)
        operations = try values.decodeIfPresent(LinkResponse.self, forKey: .operations)
        payments = try values.decodeIfPresent(LinkResponse.self, forKey: .payments)
        effects = try values.decodeIfPresent(LinkResponse.self, forKey: .effects)
        offers = try values.decodeIfPresent(LinkResponse.self, forKey: .offers)
        trades = try values.decodeIfPresent(LinkResponse.self, forKey: .trades)
        data = try values.decodeIfPresent(LinkResponse.self, forKey: .data)
    }
}
