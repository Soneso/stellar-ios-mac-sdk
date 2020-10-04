//
//  ClaimantXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum ClaimantType: Int32 {
    case claimantTypeV0 = 0
}

public enum ClaimantXDR: XDRCodable {
    case claimantTypeV0(ClaimantV0XDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case ClaimantType.claimantTypeV0.rawValue:
            let value = try container.decode(ClaimantV0XDR.self)
            self = .claimantTypeV0(value)
        default:
            let value = try container.decode(ClaimantV0XDR.self)
            self = .claimantTypeV0(value)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .claimantTypeV0: return ClaimantType.claimantTypeV0.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .claimantTypeV0(let value):
            try container.encode(value)
        }
    }
}


public struct ClaimantV0XDR: XDRCodable {
    let accountID: PublicKey
    let predicate: ClaimPredicateXDR
    
    init(accountID: PublicKey, predicate:ClaimPredicateXDR) {
        self.accountID = accountID
        self.predicate = predicate
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(accountID)
        try container.encode(predicate)
    }
}
