//
//  ClaimableBalanceEntryXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum ClaimableBalanceIDType: Int32 {
    case claimableBalanceIDTypeV0 = 0
}

public enum ClaimableBalanceIDXDR: XDRCodable {
    case claimableBalanceIDTypeV0(WrappedData32)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue:
            let value = try container.decode(WrappedData32.self)
            self = .claimableBalanceIDTypeV0(value)
        default:
            let value = try container.decode(WrappedData32.self)
            self = .claimableBalanceIDTypeV0(value)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .claimableBalanceIDTypeV0: return ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .claimableBalanceIDTypeV0(let value):
            try container.encode(value)
        }
    }
}

public struct ClaimableBalanceEntryXDR: XDRCodable {
    public let claimableBalanceID: ClaimableBalanceIDXDR
    public let claimants:[ClaimantXDR]
    public let asset:AssetXDR
    public let amount:Int64
    public let ext: Int32 = 0
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        claimableBalanceID = try container.decode(ClaimableBalanceIDXDR.self)
        self.claimants =  try decodeArray(type: ClaimantXDR.self, dec: decoder)
        asset = try container.decode(AssetXDR.self)
        amount = try container.decode(Int64.self)
        _ = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(claimableBalanceID)
        try container.encode(claimants)
        try container.encode(asset)
        try container.encode(amount)
        try container.encode(ext)
    }
}
