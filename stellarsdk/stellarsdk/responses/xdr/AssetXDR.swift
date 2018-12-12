//
//  Asset.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 12/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation


public struct AssetType {
    public static let ASSET_TYPE_NATIVE: Int32 = 0
    public static let ASSET_TYPE_CREDIT_ALPHANUM4: Int32 = 1
    public static let ASSET_TYPE_CREDIT_ALPHANUM12: Int32 = 2
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
                return (String(bytes: a4.assetCode.wrapped, encoding: .utf8) ?? "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
            case .alphanum12(let a12):
                return (String(bytes: a12.assetCode.wrapped, encoding: .utf8) ?? "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        }
    }
    
    public var issuer: PublicKey? {
        switch self {
        case .native:
            return nil
        case .alphanum4(let a4):
            return a4.issuer
        case .alphanum12(let a12):
            return a12.issuer
        }
    }
    
    public init(assetCode: String, issuer: KeyPair) throws {
        if assetCode.count <= 4 {
            guard var codeData = assetCode.data(using: .utf8) else {
                throw StellarSDKError.invalidArgument(message: "Invalid asset type")
            }
            
            let extraCount = 4 - assetCode.count
            codeData.append(contentsOf: Array<UInt8>(repeating: 0, count: extraCount))
            
            let a4 = Alpha4XDR(assetCode: WrappedData4(codeData), issuer: issuer.publicKey)
            self = .alphanum4(a4)
            
            return
        }
        else if assetCode.count <= 12 {
            guard var codeData = assetCode.data(using: .utf8) else {
                throw StellarSDKError.invalidArgument(message: "Invalid asset type")
            }
            
            let extraCount = 12 - assetCode.count
            codeData.append(contentsOf: Array<UInt8>(repeating: 0, count: extraCount))
            
            let a12 = Alpha12XDR(assetCode: WrappedData12(codeData), issuer: issuer.publicKey)
            self = .alphanum12(a12)
            
            return
        }
        
        throw StellarSDKError.invalidArgument(message: "Invalid asset type")
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
        
        public init(assetCode: WrappedData4, issuer: PublicKey) {
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
        
        public init(assetCode: WrappedData12, issuer: PublicKey) {
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
