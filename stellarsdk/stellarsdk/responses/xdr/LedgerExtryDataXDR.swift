//
//  LedgerExtryDataXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerEntryDataXDR: XDRCodable {
    case account (AccountEntryXDR)
    case trustline (TrustlineEntryXDR)
    case offer (OfferEntryXDR)
    case data (DataEntryXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case LedgerEntryType.account.rawValue:
                self = .account(try container.decode(AccountEntryXDR.self))
            case LedgerEntryType.trustline.rawValue:
                self = .trustline(try container.decode(TrustlineEntryXDR.self))
            case LedgerEntryType.offer.rawValue:
                self = .offer(try container.decode(OfferEntryXDR.self))
            case LedgerEntryType.data.rawValue:
                self = .data(try container.decode(DataEntryXDR.self))
            default:
                self = .account(try container.decode(AccountEntryXDR.self))
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
        case .account (let op):
            try container.encode(op)
            
        case .trustline (let op):
            try container.encode(op)
            
        case .offer (let op):
            try container.encode(op)
            
        case .data (let op):
            try container.encode(op)
        }
    }
}
