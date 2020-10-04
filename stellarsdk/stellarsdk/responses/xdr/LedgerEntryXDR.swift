//
//  LedgerEntryXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerEntryType: Int32 {
    case account = 0
    case trustline = 1
    case offer = 2
    case data = 3
    case claimableBalance = 4
}

public struct LedgerEntryXDR: XDRCodable {
    public let lastModifiedLedgerSeq: UInt32;
    public let data: LedgerEntryDataXDR
    public let reserved: LedgerEntryExtXDR
    
    
    public init(lastModifiedLedgerSeq: UInt32, data:LedgerEntryDataXDR) {
        self.lastModifiedLedgerSeq = lastModifiedLedgerSeq
        self.data = data
        self.reserved = .void
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lastModifiedLedgerSeq = try container.decode(UInt32.self)
        data = try container.decode(LedgerEntryDataXDR.self)
        reserved  = try container.decode(LedgerEntryExtXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lastModifiedLedgerSeq)
        try container.encode(data)
        try container.encode(reserved)
    }
}

public enum LedgerEntryExtXDR: XDRCodable {
    case void
    case ledgerEntryExtensionV1 (LedgerEntryExtensionV1)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .ledgerEntryExtensionV1(try LedgerEntryExtensionV1(from: decoder))
            /*if let val = try decodeArray(type: LedgerEntryExtensionV1.self, dec: decoder).first {
                self = .ledgerEntryExtensionV1(val)
            } else {
                self = .void
            }*/
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .ledgerEntryExtensionV1: return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .ledgerEntryExtensionV1(let ledgerEntryExtV1):
            try container.encode(ledgerEntryExtV1)
        }
    }
}

public struct LedgerEntryExtensionV1: XDRCodable {
    public let signerSponsoringID:PublicKey?
    public var reserved: Int32 = 0
    
    public init(signerSponsoringID: PublicKey) {
        self.signerSponsoringID = signerSponsoringID
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        signerSponsoringID = try decodeArray(type: PublicKey.self, dec: decoder).first
        reserved = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(signerSponsoringID)
        try container.encode(reserved)
    }
}
