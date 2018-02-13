//
//  CreatePassiveOfferOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct CreatePassiveOfferOperation: XDRCodable {
    public let selling: Asset
    public let buying: Asset
    public let amount: Int64
    public let price: Price
    
    public init(selling: Asset, buying: Asset, amount:Int64, price:Price, offerID:UInt64) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        selling = try container.decode(Asset.self)
        buying = try container.decode(Asset.self)
        amount = try container.decode(Int64.self)
        price = try container.decode(Price.self)
        
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(selling)
        try container.encode(buying)
        try container.encode(amount)
        try container.encode(price)
    }
}
