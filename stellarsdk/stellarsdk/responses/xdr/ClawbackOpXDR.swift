//
//  ClawbackOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public struct ClawbackOpXDR: XDRCodable, Sendable {
    public let asset: AssetXDR
    public let from: MuxedAccountXDR
    public let amount: Int64
    
    public init(asset: AssetXDR, from: MuxedAccountXDR, amount: Int64) {
        self.asset = asset
        self.from = from
        self.amount = amount
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        asset = try container.decode(AssetXDR.self)
        from = try container.decode(MuxedAccountXDR.self)
        amount = try container.decode(Int64.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(asset)
        try container.encode(from)
        try container.encode(amount)
    }
}
