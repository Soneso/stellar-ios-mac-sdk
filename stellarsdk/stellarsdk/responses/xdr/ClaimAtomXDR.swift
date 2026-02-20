//
//  ClaimAtomXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 14/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ClaimAtomType: Int32, Sendable {
    case v0 = 0
    case orderBook = 1
    case liquidityPool = 2
}

public enum ClaimAtomXDR: XDRCodable, Sendable {
    case v0 (ClaimOfferAtomV0XDR)
    case orderBook (ClaimOfferAtomXDR)
    case liquidityPool (ClaimLiquidityAtomXDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case ClaimAtomType.v0.rawValue:
            let ca = try container.decode(ClaimOfferAtomV0XDR.self)
            self = .v0(ca)
        case ClaimAtomType.orderBook.rawValue:
            let ca = try container.decode(ClaimOfferAtomXDR.self)
            self = .orderBook(ca)
        case ClaimAtomType.liquidityPool.rawValue:
            let ca = try container.decode(ClaimLiquidityAtomXDR.self)
            self = .liquidityPool(ca)
        default:
            let ca = try container.decode(ClaimOfferAtomV0XDR.self)
            self = .v0(ca)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .v0: return ClaimAtomType.v0.rawValue
        case .orderBook: return ClaimAtomType.orderBook.rawValue
        case .liquidityPool: return ClaimAtomType.liquidityPool.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .v0 (let ca):
            try container.encode(ca)
        case .orderBook (let ca):
            try container.encode(ca)
        case .liquidityPool (let ca):
            try container.encode(ca)
        }
    }
}

public struct ClaimOfferAtomXDR: XDRCodable, Sendable {
    public let sellerId: PublicKey
    public let offerId:Int64
    public let assetSold: AssetXDR
    public let amountSold:Int64
    public let assetBought: AssetXDR
    public let amountBought:Int64
    
    public init(sellerId: PublicKey, offerId:Int64, assetSold: AssetXDR, amountSold:Int64, assetBought: AssetXDR, amountBought:Int64) {
        self.sellerId = sellerId
        self.offerId = offerId
        self.assetSold = assetSold
        self.amountSold = amountSold
        self.assetBought = assetBought
        self.amountBought = amountBought
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sellerId = try container.decode(PublicKey.self)
        offerId = try container.decode(Int64.self)
        assetSold = try container.decode(AssetXDR.self)
        amountSold = try container.decode(Int64.self)
        assetBought = try container.decode(AssetXDR.self)
        amountBought = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sellerId)
        try container.encode(offerId)
        try container.encode(assetSold)
        try container.encode(amountSold)
        try container.encode(assetBought)
        try container.encode(amountBought)
    }
}

// ClaimOfferAtomV0 is a ClaimOfferAtom with the AccountID discriminant stripped
// off, leaving a raw ed25519 public key to identify the source account. This is
// used for backwards compatibility starting from the protocol 17/18 boundary.
// If an "old-style" ClaimOfferAtom is parsed with this XDR definition, it will
// be parsed as a "new-style" ClaimAtom containing a ClaimOfferAtomV0.
public struct ClaimOfferAtomV0XDR: XDRCodable, Sendable {
    public let sellerEd25519: [UInt8]
    public let offerId:Int64
    public let assetSold: AssetXDR
    public let amountSold:Int64
    public let assetBought: AssetXDR
    public let amountBought:Int64
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let wrappedData = try container.decode(WrappedData32.self)
        self.sellerEd25519 = wrappedData.wrapped.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            [UInt8](UnsafeBufferPointer(start: rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), count: wrappedData.wrapped.count))
        }
        offerId = try container.decode(Int64.self)
        assetSold = try container.decode(AssetXDR.self)
        amountSold = try container.decode(Int64.self)
        assetBought = try container.decode(AssetXDR.self)
        amountBought = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        var bytesArray = sellerEd25519
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
        try container.encode(offerId)
        try container.encode(assetSold)
        try container.encode(amountSold)
        try container.encode(assetBought)
        try container.encode(amountBought)
    }
}

public struct ClaimLiquidityAtomXDR: XDRCodable, Sendable {
    public let liquidityPoolID: WrappedData32
    public let assetSold: AssetXDR
    public let amountSold:Int64
    public let assetBought: AssetXDR
    public let amountBought:Int64
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        liquidityPoolID = try container.decode(WrappedData32.self)
        assetSold = try container.decode(AssetXDR.self)
        amountSold = try container.decode(Int64.self)
        assetBought = try container.decode(AssetXDR.self)
        amountBought = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolID)
        try container.encode(assetSold)
        try container.encode(amountSold)
        try container.encode(assetBought)
        try container.encode(amountBought)
    }
}
