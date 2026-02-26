//
//  PreconditionsXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

public enum PreconditionType: Int32, Sendable {
    case none = 0
    case time = 1
    case v2 = 2
}

public enum PreconditionsXDR: XDRCodable, Sendable {
    case none
    case time (TimeBoundsXDR)
    case v2 (PreconditionsV2XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case PreconditionType.none.rawValue:
            self = .none
        case PreconditionType.time.rawValue:
            let timeBounds = try container.decode(TimeBoundsXDR.self)
            self = .time(timeBounds)
        case PreconditionType.v2.rawValue:
            let v2 = try container.decode(PreconditionsV2XDR.self)
            self = .v2(v2)
        default:
            self = .none
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .none: return PreconditionType.none.rawValue
        case .time: return PreconditionType.time.rawValue
        case .v2: return PreconditionType.v2.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .none:
            break
        case .time (let timeBounds):
            try container.encode(timeBounds)
        case .v2 (let v2):
            try container.encode(v2)
        }
    }
}

public struct LedgerBoundsXDR: XDRCodable, Sendable {
    public let minLedger:UInt32
    public let maxLedger: UInt32
    
    public init(minLedger:UInt32, maxLedger: UInt32) {
        self.minLedger = minLedger
        self.maxLedger = maxLedger
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        minLedger = try container.decode(UInt32.self)
        maxLedger = try container.decode(UInt32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(minLedger)
        try container.encode(maxLedger)
    }
}

