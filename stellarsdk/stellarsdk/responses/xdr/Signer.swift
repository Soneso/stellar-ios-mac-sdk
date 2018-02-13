//
//  Signer.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 12.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum SignerKeyType: Int32 {
    case ed25519 = 0
    case preAuthTx = 1
    case hashX = 2
}

public struct Signer: XDRCodable {
    public let key: SignerKey;
    public let weight: UInt32
    
    public init(key: SignerKey, weight:UInt32) {
        self.key = key
        self.weight = weight
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        key = try container.decode(SignerKey.self)
        weight = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(key)
        try container.encode(weight)
    }
}

public enum SignerKey: XDRCodable {
    case ed25519 (WrappedData32)
    case preAuthTx (WrappedData32)
    case hashX (WrappedData32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case SignerKeyType.ed25519.rawValue:
                self = .ed25519(try container.decode(WrappedData32.self))
            case SignerKeyType.preAuthTx.rawValue:
                self = .preAuthTx(try container.decode(WrappedData32.self))
            case SignerKeyType.hashX.rawValue:
                self = .hashX(try container.decode(WrappedData32.self))
            default:
                self = .ed25519(try container.decode(WrappedData32.self))
        }
    }
    
    private func type() -> Int32 {
        switch self {
            case .ed25519: return SignerKeyType.ed25519.rawValue
            case .preAuthTx: return SignerKeyType.preAuthTx.rawValue
            case .hashX: return SignerKeyType.hashX.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
            case .ed25519 (let op):
                try container.encode(op)
            
            case .preAuthTx (let op):
                try container.encode(op)
            
            case .hashX (let op):
                try container.encode(op)
        }
    }
}
