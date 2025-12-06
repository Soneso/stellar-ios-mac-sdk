//
//  SimplePaymentResultXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct SimplePaymentResultXDR: XDRCodable, Sendable {

    public let destination: PublicKey
    public let asset:AssetXDR
    public let amount: Int64
    
    public init(destination: PublicKey, asset: AssetXDR, amount:Int64) {
        self.destination = destination
        self.asset = asset
        self.amount = amount
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        destination = try container.decode(PublicKey.self)
        asset = try container.decode(AssetXDR.self)
        amount = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(destination)
        try container.encode(asset)
        try container.encode(amount)
    }
}
