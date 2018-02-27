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
}

public enum SignerKeyXDR: XDRCodable {
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

extension SignerKeyXDR: Equatable {
    public static func ==(lhs: SignerKeyXDR, rhs: SignerKeyXDR) -> Bool {
        switch (lhs, rhs) {
        case let (.ed25519(l), .ed25519(r)): return l == r
        case let (.preAuthTx(l), .preAuthTx(r)): return l == r
        case let (.hashX(l), .hashX(r)): return l == r
        default: return false
        }
    }
}
