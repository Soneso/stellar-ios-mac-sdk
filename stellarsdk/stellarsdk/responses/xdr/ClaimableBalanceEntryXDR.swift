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

public struct ClaimableBalanceFlags {
    
    // If set, the issuer account of the asset held by the claimable balance may
    // clawback the claimable balance
    public static let CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG: UInt32 = 1
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
    
    public init(claimableBalanceId:String) throws {
        var claimableBalanceIdHex = claimableBalanceId
        if claimableBalanceId.hasPrefix("B") {
            claimableBalanceIdHex = try claimableBalanceId.decodeClaimableBalanceIdToHex()
        }
        if let data = claimableBalanceIdHex.data(using: .hexadecimal) {
            if data.count == 33 { // contains the discriminant in the first byte
                let type = data.first.map { Int32($0) } ?? 0
                if type == ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue {
                    self = .claimableBalanceIDTypeV0(claimableBalanceIdHex.wrappedData32FromHex())
                } else {
                    throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, unknown discriminant: \(type)")
                }
            } else {
                self = .claimableBalanceIDTypeV0(claimableBalanceIdHex.wrappedData32FromHex())
            }
        } else {
            throw StellarSDKError.encodingError(message: "error creating ClaimableBalanceIDXDR, invalid claimable balance id")
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
    
    public var claimableBalanceIdString: String {
        switch self {
        case .claimableBalanceIDTypeV0(let data):
            let type = UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue) // put the type into the first byte
            var result = Data([type])
            result.append(data.wrapped)
            return result.hexEncodedString()
        }
    }
}

public struct ClaimableBalanceEntryXDR: XDRCodable {
    public let claimableBalanceID: ClaimableBalanceIDXDR
    public let claimants:[ClaimantXDR]
    public let asset:AssetXDR
    public let amount:Int64
    public let ext: ClaimableBalanceEntryExtXDR
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        claimableBalanceID = try container.decode(ClaimableBalanceIDXDR.self)
        self.claimants =  try decodeArray(type: ClaimantXDR.self, dec: decoder)
        asset = try container.decode(AssetXDR.self)
        amount = try container.decode(Int64.self)
        ext  = try container.decode(ClaimableBalanceEntryExtXDR.self)
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

public enum ClaimableBalanceEntryExtXDR: XDRCodable {
    case void
    case claimableBalanceEntryExtensionV1 (ClaimableBalanceEntryExtensionV1)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .claimableBalanceEntryExtensionV1(try ClaimableBalanceEntryExtensionV1(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .claimableBalanceEntryExtensionV1: return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .claimableBalanceEntryExtensionV1(let claimableBalnceEntryExtV1):
            try container.encode(claimableBalnceEntryExtV1)
        }
    }
}

public struct ClaimableBalanceEntryExtensionV1: XDRCodable {
    public var reserved: Int32 = 0
    public let flags:UInt32 // see ClaimableBalanceFlags
    
    public init(flags: UInt32) {
        self.flags = flags
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        reserved = try container.decode(Int32.self)
        flags = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(reserved)
        try container.encode(flags)
    }
}
