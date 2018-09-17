//
//  TrustlineEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct TrustlineEntryXDR: XDRCodable {
    public let accountID: PublicKey
    public let asset: AssetXDR
    public let balance: Int64
    public let limit: Int64
    public let flags: UInt32
    public let reserved: LedgerEntryExtXDR
    
    
    public init(accountID: PublicKey, asset:AssetXDR, balance:Int64, limit:Int64, flags:UInt32) {
        self.accountID = accountID
        self.asset = asset
        self.balance = balance
        self.limit = limit
        self.flags = flags
        self.reserved = .void
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        accountID = try container.decode(PublicKey.self)
        asset = try container.decode(AssetXDR.self)
        balance = try container.decode(Int64.self)
        limit = try container.decode(Int64.self)
        flags = try container.decode(UInt32.self)
        reserved = try container.decode(LedgerEntryExtXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(asset)
        try container.encode(balance)
        try container.encode(limit)
        try container.encode(flags)
        try container.encode(reserved)
    }
}
