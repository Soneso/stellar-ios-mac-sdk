//
//  TrustlineEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct TrustLineFlags: Sendable {
    // issuer has authorized account to perform transactions with its credit
    public static let AUTHORIZED_FLAG: UInt32 = 1
    // issuer has authorized account to maintain and reduce liabilities for its
    // credit
    public static let AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG: UInt32 = 2
    // issuer has specified that it may clawback its credit, and that claimable
    // balances created with its credit may also be clawed back
    public static let TRUSTLINE_CLAWBACK_ENABLED_FLAG: UInt32 = 4
}


public struct TrustlineEntryXDR: XDRCodable, Sendable {
    public let accountID: PublicKey
    public let asset: TrustlineAssetXDR
    public let balance: Int64
    public let limit: Int64
    public let flags: UInt32 // see TrustLineFlags
    public let reserved: TrustlineEntryExtXDR
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        accountID = try container.decode(PublicKey.self)
        asset = try container.decode(TrustlineAssetXDR.self)
        balance = try container.decode(Int64.self)
        limit = try container.decode(Int64.self)
        flags = try container.decode(UInt32.self)
        reserved = try container.decode(TrustlineEntryExtXDR.self)
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

public struct TrustlineEntryExtensionV2: XDRCodable, Sendable {
    public let liquidityPoolUseCount: Int32 = 0
    public let reserved: Int32 = 0

    public init() {
        // Default initializer with constant values
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(Int32.self)
        _ = try container.decode(Int32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolUseCount)
        try container.encode(reserved)
    }
}
