//
//  AccountLinks.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 08.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

///Represents the links connected to an account.
/// See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html#links "Account Links")
public class AccountLinks: NSObject, Codable {
    
    /// Link to the account.
    public var selflink:Link!
    
    /// Link to the transactions related to this account.
    public var transactions:Link!
    
    /// Link to the operations related to this account.
    public var operations:Link!
    
    /// Link to the payments related to this account.
    public var payments:Link!
    
    /// Link to the effects related to this account.
    public var effects:Link!
    
    /// Link to the offers related to this account.
    public var offers:Link!
    
    /// Link to the trades related to this account.
    public var trades:Link!
    
    ///Link to data fields related to this account.
    public var data:Link!
    
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
        selflink = try values.decodeIfPresent(Link.self, forKey: .selflink)
        transactions = try values.decodeIfPresent(Link.self, forKey: .transactions)
        operations = try values.decodeIfPresent(Link.self, forKey: .operations)
        payments = try values.decodeIfPresent(Link.self, forKey: .payments)
        effects = try values.decodeIfPresent(Link.self, forKey: .effects)
        offers = try values.decodeIfPresent(Link.self, forKey: .offers)
        trades = try values.decodeIfPresent(Link.self, forKey: .trades)
        data = try values.decodeIfPresent(Link.self, forKey: .data)
    }
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selflink, forKey: .selflink)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(operations, forKey: .operations)
        try container.encode(payments, forKey: .payments)
        try container.encode(effects, forKey: .effects)
        try container.encode(offers, forKey: .offers)
        try container.encode(trades, forKey: .trades)
        try container.encode(data, forKey: .data)

    }
}
