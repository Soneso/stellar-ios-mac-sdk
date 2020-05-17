//
//  PaymentOperationXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct PaymentOperationXDR: XDRCodable {
    public let destination: MuxedAccountXDR
    public let asset: AssetXDR
    public let amount: Int64
    
    @available(*, deprecated, message: "use init(destination: MuxedAccountXDR, asset: AssetXDR, amount: Int64) instead")
    init(destination: PublicKey, asset: AssetXDR, amount: Int64) {
        let mux = MuxedAccountXDR.ed25519(destination.bytes)
        self.init(destination: mux, asset: asset, amount: amount)
    }
    
    init(destination: MuxedAccountXDR, asset: AssetXDR, amount: Int64) {
        self.destination = destination
        self.asset = asset
        self.amount = amount
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        destination = try container.decode(MuxedAccountXDR.self)
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
