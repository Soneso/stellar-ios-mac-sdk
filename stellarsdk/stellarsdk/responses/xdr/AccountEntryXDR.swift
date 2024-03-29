//
//  AccountEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AccountFlags {
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

public struct AccountEntryXDR: XDRCodable {
    let accountID: PublicKey
    public let balance: Int64
    public let sequenceNumber: Int64
    public let numSubEntries:UInt32
    public var inflationDest: PublicKey?
    public let flags:UInt32 // see AccountFlags
    public let homeDomain:String
    public let thresholds:WrappedData4
    public let signers: [SignerXDR]
    public let reserved: AccountEntryExtXDR
    

    public init(accountID: PublicKey, balance:Int64, sequenceNumber:Int64, numSubEntries:UInt32, homeDomain:String, inflationDest:PublicKey? = nil, flags:UInt32, thresholds: WrappedData4, signers: [SignerXDR]) {
        self.accountID = accountID
        self.balance = balance
        self.sequenceNumber = sequenceNumber
        self.numSubEntries = numSubEntries
        self.inflationDest = inflationDest
        self.flags = flags
        self.homeDomain = homeDomain
        self.thresholds = thresholds
        self.signers = signers
        self.reserved = .void
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        accountID = try container.decode(PublicKey.self)
        balance = try container.decode(Int64.self)
        sequenceNumber = try container.decode(Int64.self)
        numSubEntries = try container.decode(UInt32.self)
        inflationDest = try decodeArray(type: PublicKey.self, dec: decoder).first
        flags = try container.decode(UInt32.self)
        homeDomain = try container.decode(String.self)
        thresholds = try container.decode(WrappedData4.self)
        signers = try decodeArray(type: SignerXDR.self, dec: decoder)
        reserved  = try container.decode(AccountEntryExtXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(balance)
        try container.encode(sequenceNumber)
        try container.encode(numSubEntries)
        try container.encode(inflationDest)
        try container.encode(flags)
        try container.encode(homeDomain)
        try container.encode(thresholds)
        try container.encode(signers)
        try container.encode(reserved)
    }
}

public enum AccountEntryExtXDR: XDRCodable {
    case void
    case accountEntryExtensionV1 (AccountEntryExtensionV1)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .accountEntryExtensionV1(try AccountEntryExtensionV1(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .accountEntryExtensionV1: return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .accountEntryExtensionV1(let accountEntryExtV1):
            try container.encode(accountEntryExtV1)
        }
    }
    
}

public struct AccountEntryExtensionV1: XDRCodable {
    public let liabilities: LiabilitiesXDR
    public let reserved: AccountEntryExtV1XDR
    
    public init(liabilities: LiabilitiesXDR) {
        self.liabilities = liabilities
        self.reserved = .void
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        liabilities = try container.decode(LiabilitiesXDR.self)
        reserved = try container.decode(AccountEntryExtV1XDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liabilities)
        try container.encode(reserved)
    }
}

public enum AccountEntryExtV1XDR: XDRCodable {
    case void
    case accountEntryExtensionV2 (AccountEntryExtensionV2)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 2:
            self = .accountEntryExtensionV2(try AccountEntryExtensionV2(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .accountEntryExtensionV2: return 2
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .accountEntryExtensionV2(let accountEntryV2):
            try container.encode(accountEntryV2)
        }
    }
    
}

public struct AccountEntryExtensionV2: XDRCodable {
    public var numSponsored: UInt32 = 0
    public var numSponsoring: UInt32 = 0
    public var signerSponsoringIDs:[PublicKey?]
    public var reserved:AccountEntryExtV2XDR
    
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

public enum AccountEntryExtV2XDR : XDRCodable {
    case void
    case accountEntryExtensionV3 (AccountEntryExtensionV3)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 3:
            self = .accountEntryExtensionV3(try AccountEntryExtensionV3(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .accountEntryExtensionV3: return 3
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .accountEntryExtensionV3(let accountEntryV3):
            try container.encode(accountEntryV3)
        }
    }
}

public struct AccountEntryExtensionV3: XDRCodable {
    public var ext: ExtensionPoint
    public var seqLedger: UInt32 = 0
    public var seqTime: UInt64 = 0
    
    public init(seqLedger: UInt32, seqTime: UInt64) {
        self.ext = .void
        self.seqLedger = seqLedger
        self.seqTime = seqTime

    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        seqLedger = try container.decode(UInt32.self)
        seqTime = try container.decode(UInt64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(ext)
        try container.encode(seqLedger)
        try container.encode(seqTime)
    }
}

public enum ExtensionPoint : XDRCodable {
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

