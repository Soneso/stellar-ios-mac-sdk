//
//  SignerKeyXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum SignerKeyType: Int32 {
    case ed25519 = 0
    case preAuthTx = 1
    case hashX = 2
    case signedPayload = 3
}

public enum SignerKeyXDR: XDRCodable, Sendable {
    case ed25519 (WrappedData32)
    case preAuthTx (WrappedData32)
    case hashX (WrappedData32)
    case signedPayload (Ed25519SignedPayload)
    
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
        case SignerKeyType.signedPayload.rawValue:
            self = .signedPayload(try container.decode(Ed25519SignedPayload.self))
        default:
            self = .ed25519(try container.decode(WrappedData32.self))
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .ed25519: return SignerKeyType.ed25519.rawValue
        case .preAuthTx: return SignerKeyType.preAuthTx.rawValue
        case .hashX: return SignerKeyType.hashX.rawValue
        case .signedPayload: return SignerKeyType.signedPayload.rawValue
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
            
        case .signedPayload(let payload):
            try container.encode(payload)
        }
    }
}

public struct Ed25519SignedPayload: XDRCodable, Equatable, Sendable {
    public let ed25519: WrappedData32
    public let payload: Data
    
    public init(ed25519:WrappedData32, payload: Data) {
        self.ed25519 = ed25519
        self.payload = payload
    }

    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ed25519 = try container.decode(WrappedData32.self)
        self.payload = try container.decode(Data.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ed25519)
        try container.encode(payload)
    }
    
    public static func ==(lhs: Ed25519SignedPayload, rhs: Ed25519SignedPayload) -> Bool {
        return lhs.ed25519 == rhs.ed25519 && lhs.payload == rhs.payload
    }
    
    public func encodeSignedPayload() throws -> String {
        let data = try Data(XDREncoder.encode(self))
        return try data.encodeSignedPayload()
    }
    
    public func publicKey() throws -> PublicKey {
        return try PublicKey([UInt8](ed25519.wrapped))
    }
}

extension SignerKeyXDR: Equatable {
    public static func ==(lhs: SignerKeyXDR, rhs: SignerKeyXDR) -> Bool {
        switch (lhs, rhs) {
        case let (.ed25519(l), .ed25519(r)): return l == r
        case let (.preAuthTx(l), .preAuthTx(r)): return l == r
        case let (.hashX(l), .hashX(r)): return l == r
        case let (.signedPayload(l), .signedPayload(r)): return l == r
        default: return false
        }
    }
}
