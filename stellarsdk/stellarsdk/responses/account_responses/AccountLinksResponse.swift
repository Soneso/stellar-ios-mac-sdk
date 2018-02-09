//
//  AccountLinksResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents the links contained within an account response.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html#links "Account Links")
public class AccountLinksResponse: NSObject, Decodable {
    
    /// Link to the account.
    public var selflink:LinkResponse!
    
    /// Link to the transactions related to this account.
    public var transactions:LinkResponse!
    
    /// Link to the operations related to this account.
    public var operations:LinkResponse!
    
    /// Link to the payments related to this account.
    public var payments:LinkResponse!
    
    /// Link to the effects related to this account.
    public var effects:LinkResponse!
    
    /// Link to the offers related to this account.
    public var offers:LinkResponse!
    
    /// Link to the trades related to this account.
    public var trades:LinkResponse!
    
    ///Link to data fields related to this account.
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
