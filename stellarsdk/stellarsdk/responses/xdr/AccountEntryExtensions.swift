//
//  AccountEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AccountFlags: Sendable {
    // Flags set on issuer accounts
    // trust lines are created with authorized set to "false" requiring
    // the issuer to set it for each trust line
    public static let AUTH_REQUIRED_FLAG: UInt32 = 1
    // If set, the authorized flag in trust lines can be cleared
    // otherwise, authorization cannot be revoked
    public static let AUTH_REVOCABLE_FLAG: UInt32 = 2
    // Once set, causes all AUTH_* flags to be read-only
    public static let AUTH_IMMUTABLE_FLAG: UInt32 = 4
    // trust lines are created with clawback enabled set to "true",
    // and claimable balances created from those trustlines are created
    // with clawback enabled set to "true"
    public static let AUTH_CLAWBACK_ENABLED_FLAG: UInt32 = 8
}

public struct AccountEntryExtensionV2: XDRCodable, Sendable {
    public var numSponsored: UInt32 = 0
    public var numSponsoring: UInt32 = 0
    public var signerSponsoringIDs: [PublicKey?]
    public let reserved: AccountEntryExtV2XDR
    
    public init(numSponsored: UInt32, numSponsoring: UInt32, signerSponsoringIDs:[PublicKey?]) {
        self.numSponsored = numSponsored
        self.numSponsoring = numSponsoring
        self.signerSponsoringIDs = signerSponsoringIDs
        self.reserved = .void
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        numSponsored = try container.decode(UInt32.self)
        numSponsoring = try container.decode(UInt32.self)
        signerSponsoringIDs = [PublicKey?]()
        let count = try container.decode(Int32.self)
        for _ in stride(from: count, to: 0, by: -1) { 
            let present = try container.decode(Int32.self) == 1
            if (present) {
                signerSponsoringIDs.append(try container.decode(PublicKey.self))
            } else {
                signerSponsoringIDs.append(nil)
            }
        }
        reserved = try container.decode(AccountEntryExtV2XDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(numSponsored)
        try container.encode(numSponsoring)
        let count = signerSponsoringIDs.count
        try container.encode(Int32(count))
        if (count > 0) {
            for i in 0 ... count - 1 {
                if let next = signerSponsoringIDs[i] {
                    try container.encode(Int32(1))
                    try container.encode(next)
                } else {
                    try container.encode(Int32(0))
                }
            }
        }
        try container.encode(reserved)
    }
}

public enum ExtensionPoint : XDRCodable, Sendable {
    case void
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        }
    }
}

