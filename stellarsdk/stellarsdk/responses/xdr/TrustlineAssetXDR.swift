//
//  TrustlineAssetXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 08.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public enum TrustlineAssetXDR: XDRCodable {
    case native
    case alphanum4 (Alpha4XDR)
    case alphanum12 (Alpha12XDR)
    case poolShare (WrappedData32)
    

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
    
    public init(poolId: String) {
        self = .poolShare(poolId.wrappedData32FromHex())
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
                let poolId = try container.decode(WrappedData32.self)
                self = .poolShare(poolId)
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
    
    public var poolId: String? {
        switch self {
        case .poolShare(let data):
            return data.wrapped.hexEncodedString()
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
                
            case .poolShare (let poolId):
                try container.encode(poolId)
        }
    }
}
