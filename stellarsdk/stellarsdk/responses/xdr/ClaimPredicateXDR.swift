//
//  ClaimPredicateXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum ClaimPredicateType: Int32 {
    case claimPredicateUnconditional = 0
    case claimPredicateAnd = 1
    case claimPredicateOr = 2
    case claimPredicateNot = 3
    case claimPredicateBeforeAbsTime = 4
    case claimPredicateBeforeRelTime = 5
}

public indirect enum ClaimPredicateXDR: XDRCodable {
    case claimPredicateUnconditional
    case claimPredicateAnd ([ClaimPredicateXDR])
    case claimPredicateOr ([ClaimPredicateXDR])
    case claimPredicateNot (ClaimPredicateXDR?)
    case claimPredicateBeforeAbsTime (Int64)
    case claimPredicateBeforeRelTime (Int64)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case ClaimPredicateType.claimPredicateUnconditional.rawValue:
            self = .claimPredicateUnconditional
        case ClaimPredicateType.claimPredicateAnd.rawValue:
            let value = try decodeArray(type: ClaimPredicateXDR.self, dec: decoder)
            self = .claimPredicateAnd(value)
        case ClaimPredicateType.claimPredicateOr.rawValue:
            let value = try decodeArray(type: ClaimPredicateXDR.self, dec: decoder)
            self = .claimPredicateOr(value)
        case ClaimPredicateType.claimPredicateNot.rawValue:
            let value = try? decodeArray(type: ClaimPredicateXDR.self, dec: decoder).first
            self = .claimPredicateNot(value)
        case ClaimPredicateType.claimPredicateBeforeAbsTime.rawValue:
            let value = try container.decode(Int64.self)
            self = .claimPredicateBeforeAbsTime(value)
        case ClaimPredicateType.claimPredicateBeforeRelTime.rawValue:
            let value = try container.decode(Int64.self)
            self = .claimPredicateBeforeRelTime(value)
        default:
            self = .claimPredicateUnconditional
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .claimPredicateUnconditional: return ClaimPredicateType.claimPredicateUnconditional.rawValue
        case .claimPredicateAnd: return ClaimPredicateType.claimPredicateAnd.rawValue
        case .claimPredicateOr: return ClaimPredicateType.claimPredicateOr.rawValue
        case .claimPredicateNot: return ClaimPredicateType.claimPredicateNot.rawValue
        case .claimPredicateBeforeAbsTime: return ClaimPredicateType.claimPredicateBeforeAbsTime.rawValue
        case .claimPredicateBeforeRelTime: return ClaimPredicateType.claimPredicateBeforeRelTime.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .claimPredicateUnconditional:
            break
        case .claimPredicateAnd (let value):
            try container.encode(value)
        case .claimPredicateOr (let value):
            try container.encode(value)
        case .claimPredicateNot (let value):
            try container.encode(value)
        case .claimPredicateBeforeAbsTime (let value):
            try container.encode(value)
        case .claimPredicateBeforeRelTime (let value):
            try container.encode(value)
        }
    }
}
