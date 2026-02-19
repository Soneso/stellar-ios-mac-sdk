//
//  LiquidityPoolEntryXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 07.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum LiquidityPoolType: Int32, Sendable {
    case constantProduct = 0
}

public struct LiquidityPoolEntryXDR: XDRCodable, Sendable {
    public let liquidityPoolID:WrappedData32
    public let body:LiquidityPoolBodyXDR
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        liquidityPoolID = try container.decode(WrappedData32.self)
        body = try container.decode(LiquidityPoolBodyXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolID)
        try container.encode(body)
    }
    
    public var poolIDString: String {
        return liquidityPoolID.wrapped.base16EncodedString()
    }
}

public enum LiquidityPoolBodyXDR: XDRCodable, Sendable {
    case constantProduct (ConstantProductXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case LiquidityPoolType.constantProduct.rawValue:
                self = .constantProduct(try container.decode(ConstantProductXDR.self))
            default:
                self = .constantProduct(try container.decode(ConstantProductXDR.self))
        }
        
    }
    
    public func type() -> Int32 {
        switch self {
            case .constantProduct: return LiquidityPoolType.constantProduct.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .constantProduct (let cp):
            try container.encode(cp)
        }
    }
}

public struct ConstantProductXDR: XDRCodable, Sendable {
    public let params:LiquidityPoolConstantProductParametersXDR
    public let reserveA:Int64
    public let reserveB:Int64
    public let totalPoolShares:Int64
    public let poolSharesTrustLineCount:Int64
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        params = try container.decode(LiquidityPoolConstantProductParametersXDR.self)
        reserveA = try container.decode(Int64.self)
        reserveB = try container.decode(Int64.self)
        totalPoolShares = try container.decode(Int64.self)
        poolSharesTrustLineCount = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(params)
        try container.encode(reserveA)
        try container.encode(reserveB)
        try container.encode(totalPoolShares)
        try container.encode(poolSharesTrustLineCount)
    }
}
    
public struct LiquidityPoolConstantProductParametersXDR: XDRCodable, Sendable {
    public let assetA: AssetXDR
    public let assetB: AssetXDR
    public let fee: Int32
    
    public init(assetA:AssetXDR, assetB:AssetXDR, fee:Int32) {
        self.assetA = assetA
        self.assetB = assetB
        self.fee = fee
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        assetA = try container.decode(AssetXDR.self)
        assetB = try container.decode(AssetXDR.self)
        fee = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(assetA)
        try container.encode(assetB)
        try container.encode(fee)
    }
}
