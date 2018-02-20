//
//  PrivateKey.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import ed25519C

public final class PrivateKey {
    private let buffer: [UInt8]
    
    public init(_ bytes: [UInt8]) throws {
        guard bytes.count == 64 else {
            throw Ed25519Error.invalidPrivateKeyLength
        }
        
        self.buffer = bytes
    }
    
    init(unchecked buffer: [UInt8]) {
        self.buffer = buffer
    }
    
    
    public init(key: String) throws {
        if let data = key.base32DecodedData {
            self.buffer = [UInt8](data)
        } else {
            throw Ed25519Error.invalidPrivateKey
        }
    }
    
    public var bytes: [UInt8] {
        return buffer
    }
    
    public var key: String {
        var bytes = buffer
        return Data(bytes: &bytes, count: bytes.count).base32EncodedString!
    }
    
    public func add(scalar: [UInt8]) throws -> PrivateKey {
        guard scalar.count == 32 else {
            throw Ed25519Error.invalidScalarLength
        }

        var priv = buffer
        
        priv.withUnsafeMutableBufferPointer { priv in
            scalar.withUnsafeBufferPointer { scalar in
                ed25519_add_scalar(nil,
                                   priv.baseAddress,
                                   scalar.baseAddress)
            }
        }
        
        return PrivateKey(unchecked: priv)
    }
}
