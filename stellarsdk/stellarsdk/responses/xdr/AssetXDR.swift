//
//  Asset.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation


public struct AssetType {
    static let ASSET_TYPE_NATIVE: Int32 = 0
    static let ASSET_TYPE_CREDIT_ALPHANUM4: Int32 = 1
    static let ASSET_TYPE_CREDIT_ALPHANUM12: Int32 = 2
}

public enum AssetXDR: XDRCodable {
    case native
    case alphanum4 (Alpha4XDR)
    case alphanum12 (Alpha12XDR)
    
    public var assetCode: String {
        switch self {
            case .native:
                return "native"
            case .alphanum4(let a4):
                return String(bytes: a4.assetCode.wrapped, encoding: .utf8) ?? ""
            case .alphanum12(let a12):
                return String(bytes: a12.assetCode.wrapped, encoding: .utf8) ?? ""
        }
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
            default:
                self = .native
        }
    }
    
    public struct Alpha4XDR: XDRCodable {
        let assetCode: WrappedData4
        let issuer: PublicKey
        
        init(assetCode: WrappedData4, issuer: PublicKey) {
            self.assetCode = assetCode
            self.issuer = issuer
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(assetCode)
            try container.encode(issuer)
        }
    }
    
    public struct Alpha12XDR: XDRCodable {
        let assetCode: WrappedData12
        let issuer: PublicKey
        
        init(assetCode: WrappedData12, issuer: PublicKey) {
            self.assetCode = assetCode
            self.issuer = issuer
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(assetCode)
            try container.encode(issuer)
        }
    }
    
    public func type() -> Int32 {
        switch self {
            case .native: return AssetType.ASSET_TYPE_NATIVE
            case .alphanum4: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM4
            case .alphanum12: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
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
        }
    }
}
