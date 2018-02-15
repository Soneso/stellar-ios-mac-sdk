//
//  ClaimOfferAtomXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct ClaimOfferAtomXDR: XDRCodable {
    public let sellerId: PublicKey
    public let offerId:Int64
    public let assetSold: AssetXDR
    public let amountSold:Int64
    public let assetBought: AssetXDR
    public let amountBought:Int64
    
    public init(sellerId: PublicKey, offerId:Int64, assetSold: AssetXDR, amountSold:Int64, assetBought: AssetXDR, amountBought:Int64) {
        self.sellerId = sellerId
        self.offerId = offerId
        self.assetSold = assetSold
        self.amountSold = amountSold
        self.assetBought = assetBought
        self.amountBought = amountBought
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sellerId = try container.decode(PublicKey.self)
        offerId = try container.decode(Int64.self)
        assetSold = try container.decode(AssetXDR.self)
        amountSold = try container.decode(Int64.self)
        assetBought = try container.decode(AssetXDR.self)
        amountBought = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sellerId)
        try container.encode(offerId)
        try container.encode(assetSold)
        try container.encode(amountSold)
        try container.encode(assetBought)
        try container.encode(amountBought)
    }
}

