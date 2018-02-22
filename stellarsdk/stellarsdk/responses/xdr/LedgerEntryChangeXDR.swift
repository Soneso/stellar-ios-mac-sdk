//
//  LedgerEntryChange.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerEntryChangeType: Int32 {
    case ledgerEntryCreated = 0
    case ledgerEntryUpdated = 1
    case ledgerEntryRemoved = 2
    case ledgerEntryState = 3
}

public enum LedgerEntryChangeXDR: XDRCodable {
    case created (LedgerEntryXDR)
    case updated (LedgerEntryXDR)
    case removed (LedgerKeyXDR)
    case state (LedgerEntryXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case LedgerEntryChangeType.ledgerEntryCreated.rawValue:
                self = .created(try container.decode(LedgerEntryXDR.self))
            case LedgerEntryChangeType.ledgerEntryUpdated.rawValue:
                self = .updated(try container.decode(LedgerEntryXDR.self))
            case LedgerEntryChangeType.ledgerEntryRemoved.rawValue:
                self = .removed(try container.decode(LedgerKeyXDR.self))
            case LedgerEntryChangeType.ledgerEntryState.rawValue:
                self = .state(try container.decode(LedgerEntryXDR.self))
            default:
                self = .created(try container.decode(LedgerEntryXDR.self))
        }
    }
    
    private func type() -> Int32 {
        switch self {
            case .created: return LedgerEntryChangeType.ledgerEntryCreated.rawValue
            case .updated: return LedgerEntryChangeType.ledgerEntryUpdated.rawValue
            case .removed: return LedgerEntryChangeType.ledgerEntryRemoved.rawValue
            case .state: return LedgerEntryChangeType.ledgerEntryState.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
            case .created (let op):
                try container.encode(op)
            
            case .updated (let op):
                try container.encode(op)
            
            case .removed (let op):
                try container.encode(op)
            
            case .state (let op):
                try container.encode(op)
        }
    }
}
