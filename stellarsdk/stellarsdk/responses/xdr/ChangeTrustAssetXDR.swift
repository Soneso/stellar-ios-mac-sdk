//
//  ChangeTrustAssetXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum ChangeTrustAssetXDR: XDRCodable {
    case native
    case alphanum4 (Alpha4XDR)
    case alphanum12 (Alpha12XDR)
    case poolShare (LiquidityPoolParametersXDR)
    

    public init(assetCode: String, issuer: KeyPair) throws {
        if assetCode.count <= 4 {
            let a4 = try Alpha4XDR(assetCodeString: assetCode, issuer: issuer)
            self = .alphanum4(a4)
            return
        }
        else if assetCode.count <= 12 {
            let a12 = try Alpha12XDR(assetCodeString: assetCode, issuer: issuer)
            self = .alphanum12(a12)
            return
        }
        
        throw StellarSDKError.invalidArgument(message: "Invalid asset type")
    }
    
    public init(params:LiquidityPoolConstantProductParametersXDR) {
        let p = LiquidityPoolParametersXDR(params: params)
        self = .poolShare(p)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case AssetType.ASSET_TYPE_NATIVE:
                self = .native
            case AssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
                let a4 = try container.decode(Alpha4XDR.self)
                self = .alphanum4(a4)
            case AssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
                let a12 = try container.decode(Alpha12XDR.self)
                self = .alphanum12(a12)
            case AssetType.ASSET_TYPE_POOL_SHARE:
                let cp = try container.decode(LiquidityPoolParametersXDR.self)
                self = .poolShare(cp)
            default:
                self = .native
        }
    }
    
    public func type() -> Int32 {
        switch self {
            case .native: return AssetType.ASSET_TYPE_NATIVE
            case .alphanum4: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM4
            case .alphanum12: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
            case .poolShare: return AssetType.ASSET_TYPE_POOL_SHARE
        }
    }
    
    public var assetCode: String? {
        switch self {
            case .native:
                return "native"
            case .alphanum4(let a4):
                return a4.assetCodeString
            case .alphanum12(let a12):
                return a12.assetCodeString
            default:
                return nil
        }
    }
    
    public var issuer: PublicKey? {
        switch self {
        case .alphanum4(let a4):
            return a4.issuer
        case .alphanum12(let a12):
            return a12.issuer
        default:
            return nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
            case .native: break
            
            case .alphanum4 (let alpha4):
                try container.encode(alpha4)
            
            case .alphanum12 (let alpha12):
                try container.encode(alpha12)
                
            case .poolShare (let params):
                try container.encode(params)
        }
    }
}

public enum LiquidityPoolParametersXDR: XDRCodable {
    case constantProduct (LiquidityPoolConstantProductParametersXDR)
    
    public init(params:LiquidityPoolConstantProductParametersXDR) {
        self = .constantProduct(params)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case LiquidityPoolType.constantProduct.rawValue:
                self = .constantProduct(try container.decode(LiquidityPoolConstantProductParametersXDR.self))
            default:
                self = .constantProduct(try container.decode(LiquidityPoolConstantProductParametersXDR.self))
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
