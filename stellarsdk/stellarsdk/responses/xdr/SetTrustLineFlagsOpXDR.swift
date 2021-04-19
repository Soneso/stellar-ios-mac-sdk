//
//  SetTrustLineFlagsOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public struct SetTrustLineFlagsOpXDR: XDRCodable {
    public let accountID: PublicKey
    public let asset: AssetXDR
    public let clearFlags:UInt32 // which flags to clear
    public let setFlags:UInt32 // which flags to set
    
    public init(accountID: PublicKey, asset: AssetXDR, setFlags: UInt32, clearFlags: UInt32) {
        self.asset = asset
        self.clearFlags = clearFlags
        self.setFlags = setFlags
        self.accountID = accountID
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        accountID = try container.decode(PublicKey.self)
        asset = try container.decode(AssetXDR.self)
        clearFlags = try container.decode(UInt32.self)
        setFlags = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(asset)
        try container.encode(clearFlags)
        try container.encode(setFlags)
    }
}
