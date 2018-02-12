//
//  Asset.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation


struct AssetType {
    static let ASSET_TYPE_NATIVE: Int32 = 0
    static let ASSET_TYPE_CREDIT_ALPHANUM4: Int32 = 1
    static let ASSET_TYPE_CREDIT_ALPHANUM12: Int32 = 2
}

public enum Asset: XDRCodable {
    case native
    case alphanum4 (Alpha4)
    case alphanum12 (Alpha12)
    
    var assetCode: String {
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
        
        let discriminant = try container.decode(Int32.self)
        
        switch discriminant {
        case AssetType.ASSET_TYPE_NATIVE:
            self = .native
        case AssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
            let a4 = try container.decode(Alpha4.self)
            self = .alphanum4(a4)
        case AssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
            let a12 = try container.decode(Alpha12.self)
            self = .alphanum12(a12)
        default:
            self = .native
        }
    }
    
    public struct Alpha4: XDRCodable {
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
    
    public struct Alpha12: XDRCodable {
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
    
    private func discriminant() -> Int32 {
        switch self {
        case .native: return AssetType.ASSET_TYPE_NATIVE
        case .alphanum4: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM4
        case .alphanum12: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(discriminant())
        
        switch self {
        case .native: break
            
        case .alphanum4 (let alpha4):
            try container.encode(alpha4)
            
        case .alphanum12 (let alpha12):
            try container.encode(alpha12)
        }
    }
}
