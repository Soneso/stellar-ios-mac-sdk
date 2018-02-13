//
//  OfferEntry.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct OfferEntry: XDRCodable {
    public let sellerID: PublicKey
    public let offerID: UInt64
    public let selling:Asset
    public let buying:Asset
    public let amount:Int64
    public let price:Price
    public let flags:UInt32 // TODO
    public let reserved: Int32 = 0
    
    public init(sellerID: PublicKey, offerID:UInt64, selling:Asset, buying:Asset, amount:Int64, price:Price, flags:UInt32) {
        self.sellerID = sellerID
        self.offerID = offerID
        self.selling = selling
        self.buying = buying
        self.amount = amount
        self.price = price
        self.flags = flags
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sellerID = try container.decode(PublicKey.self)
        offerID = try container.decode(UInt64.self)
        selling = try container.decode(Asset.self)
        buying = try container.decode(Asset.self)
        amount = try container.decode(Int64.self)
        price = try container.decode(Price.self)
        flags = try container.decode(UInt32.self)
        _ = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sellerID)
        try container.encode(offerID)
        try container.encode(selling)
        try container.encode(amount)
        try container.encode(price)
        try container.encode(flags)
        try container.encode(reserved)
    }
}
