//
//  RevokeSponsorshipOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 03.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum RevokeSponsorshipType: Int32 {
    case revokeSponsorshipLedgerEntry = 0
    case revokeSponsorshipSignerEntry = 1
}

public enum RevokeSponsorshipOpXDR: XDRCodable {
    case revokeSponsorshipLedgerEntry(LedgerKeyXDR)
    case revokeSponsorshipSignerEntry(RevokeSponsorshipSignerXDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue:
            let value = try container.decode(LedgerKeyXDR.self)
            self = .revokeSponsorshipLedgerEntry(value)
        case RevokeSponsorshipType.revokeSponsorshipSignerEntry.rawValue:
            let value = try container.decode(RevokeSponsorshipSignerXDR.self)
            self = .revokeSponsorshipSignerEntry(value)
        default:
            let value = try container.decode(LedgerKeyXDR.self)
            self = .revokeSponsorshipLedgerEntry(value)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .revokeSponsorshipLedgerEntry: return RevokeSponsorshipType.revokeSponsorshipLedgerEntry.rawValue
        case .revokeSponsorshipSignerEntry: return RevokeSponsorshipType.revokeSponsorshipSignerEntry.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .revokeSponsorshipLedgerEntry(let value):
            try container.encode(value)
        case .revokeSponsorshipSignerEntry(let value):
            try container.encode(value)
        }
    }
}

public struct RevokeSponsorshipSignerXDR: XDRCodable {
    let accountID: PublicKey
    let signerKey: SignerKeyXDR
    
    init(accountID: PublicKey, signerKey:SignerKeyXDR) {
        self.accountID = accountID
        self.signerKey = signerKey
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(signerKey)
    }
}
