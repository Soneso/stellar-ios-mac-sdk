//
//  InflationPayoutXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 15.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct InflationPayoutXDR: XDRCodable {
    public let destination: PublicKey
    public let amount:Int64
    
    public init(destination: PublicKey, amount:Int64) {
        self.destination = destination
        self.amount = amount
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        destination = try container.decode(PublicKey.self)
        amount = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(destination)
        try container.encode(amount)
    }
}
