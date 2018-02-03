//
//  Links.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Links: NSObject, Codable {
    
    public var selflink:Link!
    public var transactions:Link!
    public var operations:Link!
    public var payments:Link!
    public var effects:Link!
    public var offers:Link!
    public var trades:Link!
    public var data:Link!
    public var toml:Link!
    public var next:Link!
    public var prev:Link!
    
    enum CodingKeys: String, CodingKey {
        case selflink = "self"
        case transactions
        case operations
        case payments
        case effects
        case offers
        case trades
        case data
        case toml
        case next
        case prev
    }
    
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
        toml = try values.decodeIfPresent(Link.self, forKey: .toml)
        next = try values.decodeIfPresent(Link.self, forKey: .next)
        prev = try values.decodeIfPresent(Link.self, forKey: .prev)
    }
    
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
        try container.encode(toml, forKey: .toml)
        try container.encode(next, forKey: .next)
        try container.encode(prev, forKey: .prev)
    }
}
