//
//  CreatePassiveOfferOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct CreatePassiveOfferOperationXDR: XDRCodable {
    public let selling: AssetXDR
    public let buying: AssetXDR
    public let amount: Int64
    public let price: PriceXDR
    
    public init(selling: AssetXDR, buying: AssetXDR, amount:Int64, price:PriceXDR) {
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        selling = try container.decode(AssetXDR.self)
        buying = try container.decode(AssetXDR.self)
        amount = try container.decode(Int64.self)
        price = try container.decode(PriceXDR.self)
        
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(selling)
        try container.encode(buying)
        try container.encode(amount)
        try container.encode(price)
    }
}
