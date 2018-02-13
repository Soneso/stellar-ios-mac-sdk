//
//  PaymentOperation.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct PaymentOperation: XDRCodable {
    public let destination: PublicKey
    public let asset: Asset
    public let amount: Int64
    
    init(destination: PublicKey, asset: Asset, amount: Int64) {
        self.destination = destination
        self.asset = asset
        self.amount = amount
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        destination = try container.decode(PublicKey.self)
        asset = try container.decode(Asset.self)
        amount = try container.decode(Int64.self)
        
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(destination)
        try container.encode(asset)
        try container.encode(amount)
    }
}
