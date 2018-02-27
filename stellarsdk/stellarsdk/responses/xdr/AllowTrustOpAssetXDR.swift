//
//  AllowTrustOpAssetXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum AllowTrustOpAssetXDR: XDRCodable {
    case alphanum4 (AlphaATO4XDR)
    case alphanum12 (AlphaATO12XDR)
    
    public var assetCode: String {
        switch self {
        case .alphanum4(let a4):
            return (String(bytes: a4.assetCode.wrapped, encoding: .utf8) ?? "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        case .alphanum12(let a12):
            return (String(bytes: a12.assetCode.wrapped, encoding: .utf8) ?? "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        }
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case AssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
            let a4 = try container.decode(AlphaATO4XDR.self)
            self = .alphanum4(a4)
        case AssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
            let a12 = try container.decode(AlphaATO12XDR.self)
            self = .alphanum12(a12)
        default:
            let a4 = try container.decode(AlphaATO4XDR.self)
            self = .alphanum4(a4)
        }
    }
    
    public struct AlphaATO4XDR: XDRCodable {
        let assetCode: WrappedData4
        
        init(assetCode: WrappedData4) {
            self.assetCode = assetCode
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(assetCode)
        }
    }
    
    public struct AlphaATO12XDR: XDRCodable {
        let assetCode: WrappedData12
        
        init(assetCode: WrappedData12) {
            self.assetCode = assetCode
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(assetCode)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .alphanum4: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM4
        case .alphanum12: return AssetType.ASSET_TYPE_CREDIT_ALPHANUM12
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .alphanum4 (let alpha4):
            try container.encode(alpha4)
            
        case .alphanum12 (let alpha12):
            try container.encode(alpha12)
        }
    }
}
