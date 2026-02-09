//
//  TrustlineEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct TrustLineFlags {
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

public enum TrustlineEntryExtXDR: XDRCodable, Sendable {
    case void
    case trustlineEntryExtensionV1 (TrustlineEntryExtensionV1)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .trustlineEntryExtensionV1(try TrustlineEntryExtensionV1(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .trustlineEntryExtensionV1: return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .trustlineEntryExtensionV1(let trustlineEntryExtV1):
            try container.encode(trustlineEntryExtV1)
        }
    }
    
}

public struct TrustlineEntryExtensionV1: XDRCodable, Sendable {
    public let liabilities: LiabilitiesXDR
    public let reserved: TrustlineEntryExtV1XDR
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        liabilities = try container.decode(LiabilitiesXDR.self)
        reserved = try container.decode(TrustlineEntryExtV1XDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liabilities)
        try container.encode(reserved)
    }
}

public enum TrustlineEntryExtV1XDR: XDRCodable, Sendable {
    case void
    case trustlineEntryExtensionV2 (TrustlineEntryExtensionV2)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 2:
            self = .trustlineEntryExtensionV2(try TrustlineEntryExtensionV2(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .trustlineEntryExtensionV2: return 2
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .trustlineEntryExtensionV2(let trustlineEntryV2):
            try container.encode(trustlineEntryV2)
        }
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
