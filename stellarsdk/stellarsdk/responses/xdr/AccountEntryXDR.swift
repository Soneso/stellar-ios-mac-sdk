//
//  AccountEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AccountEntryXDR: XDRCodable {
    let accountID: PublicKey
    public let balance: Int64
    public let sequenceNumber: Int64
    public let numSubEntries:UInt32
    public var inflationDest: PublicKey?
    public let flags:UInt32
    public let homeDomain:String?
    public let thresholds:WrappedData4
    public let signers: [SignerXDR]
    public let reserved: LedgerEntryExtXDR
    

    public init(accountID: PublicKey, balance:Int64, sequenceNumber:Int64, numSubEntries:UInt32, inflationDest:PublicKey? = nil, flags:UInt32, homeDomain:String? = nil, thresholds: WrappedData4, signers: [SignerXDR]) {
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
        reserved  = try container.decode(LedgerEntryExtXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(balance)
        try container.encode(sequenceNumber)
        try container.encode(numSubEntries)
        try container.encode(inflationDest)
        try container.encode(flags)
        try container.encode(thresholds)
        try container.encode(signers)
        try container.encode(reserved)
    }
}

public enum LedgerEntryExtXDR: XDRCodable {
    case void
    case ledgerEntryV1 (LedgerEntryV1)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .ledgerEntryV1(try LedgerEntryV1(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .ledgerEntryV1: return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .ledgerEntryV1(let accountEntryV1):
            try container.encode(accountEntryV1)
        }
    }
    
}

public struct LedgerEntryV1: XDRCodable {
    public let liabilities: LiabilitiesXDR
    public var reserved: Int32 = 0
    
    public init(liabilities: LiabilitiesXDR) {
        self.liabilities = liabilities
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        liabilities = try container.decode(LiabilitiesXDR.self)
        reserved = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(liabilities)
        try container.encode(reserved)
    }
}
