//
//  LedgerKey.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerKey: XDRCodable {
    case account (LedgerKeyAccount)
    case trustline (LedgerKeyTrustLine)
    case offer (LedgerKeyOffer)
    case data (LedgerKeyData)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case LedgerEntryType.account.rawValue:
            let acc = try container.decode(LedgerKeyAccount.self)
            self = .account(acc)
        case LedgerEntryType.trustline.rawValue:
            let trus = try container.decode(LedgerKeyTrustLine.self)
            self = .trustline(trus)
        case LedgerEntryType.offer.rawValue:
            let offeru = try container.decode(LedgerKeyOffer.self)
            self = .offer(offeru)
        case LedgerEntryType.data.rawValue:
            let datamu = try container.decode(LedgerKeyData.self)
            self = .data (datamu)
        default:
            let acc = try container.decode(LedgerKeyAccount.self)
            self = .account(acc)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .account: return LedgerEntryType.account.rawValue
        case .trustline: return LedgerEntryType.trustline.rawValue
        case .offer: return LedgerEntryType.offer.rawValue
        case .data: return LedgerEntryType.data.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .account (let acc):
            try container.encode(acc)
        case .trustline (let trust):
            try container.encode(trust)
        case .offer (let offeru):
            try container.encode(offeru)
        case .data (let datamu):
            try container.encode(datamu)
        }
    }
}
