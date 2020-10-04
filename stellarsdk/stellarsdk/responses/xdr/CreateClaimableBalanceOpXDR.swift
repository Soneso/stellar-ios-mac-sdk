//
//  CreateClaimableBalanceOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct CreateClaimableBalanceOpXDR: XDRCodable {
    public let asset: AssetXDR
    public let amount: Int64
    public let claimants: [ClaimantXDR]
    
    public init(asset: AssetXDR, amount: Int64, claimants:[ClaimantXDR]) {
        self.asset = asset
        self.amount = amount
        self.claimants = claimants
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        asset = try container.decode(AssetXDR.self)
        amount = try container.decode(Int64.self)
        self.claimants =  try decodeArray(type: ClaimantXDR.self, dec: decoder)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(asset)
        try container.encode(amount)
        try container.encode(claimants)
    }
}
