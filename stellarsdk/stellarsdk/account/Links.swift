//
//  Links.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public class Links: NSObject, Codable {
    
    public var selflink:Link
    public var transactions:Link
    public var operations:Link
    public var payments:Link
    public var effects:Link
    public var offers:Link
    public var trades:Link
    public var data:Link
    
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
    
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selflink = try values.decode(Link.self, forKey: .selflink)
        transactions = try values.decode(Link.self, forKey: .transactions)
        operations = try values.decode(Link.self, forKey: .operations)
        payments = try values.decode(Link.self, forKey: .payments)
        effects = try values.decode(Link.self, forKey: .effects)
        offers = try values.decode(Link.self, forKey: .offers)
        trades = try values.decode(Link.self, forKey: .trades)
        data = try values.decode(Link.self, forKey: .data)
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
    }
}
