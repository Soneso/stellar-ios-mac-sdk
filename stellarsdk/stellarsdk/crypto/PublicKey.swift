//
//  PublicKey.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import ed25519C

public class PublicKey: XDRCodable {
    private let buffer: [UInt8]
    
    public convenience init(_ bytes: [UInt8]) throws {
        guard bytes.count == 32 else {
            throw Ed25519Error.invalidPublicKeyLength
        }
        
        self.init(unchecked: bytes)
    }
    
    init(unchecked buffer: [UInt8]) {
        self.buffer = buffer
    }
    
    public init(key: String) throws {
        if let data = key.base32DecodedData {
            self.buffer = [UInt8](data)
        } else {
            throw Ed25519Error.invalidPublicKey
        }
    }
    
    public convenience init(accountId:String) throws {
        if let data = accountId.base32DecodedData {
            try self.init(Array(([UInt8](data))[1...data.count - 3]))
        } else {
            throw Ed25519Error.invalidPublicKey
        }
    }
    
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        _ = try container.decode(Int32.self)
        
        //self.buffer = try container.decode([UInt8].self)
        let wrappedData = try container.decode(WrappedData32.self)
        self.buffer = wrappedData.wrapped.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: wrappedData.wrapped.count))
        }
        
    }
    
    public var bytes: [UInt8] {
        return buffer
    }
    
    public var key: String {
        var bytes = buffer
        return Data(bytes: &bytes, count: bytes.count).base32EncodedString!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(Int32(0))
        var bytesArray = bytes
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
    }

    public func verify(signature: [UInt8], message: [UInt8]) throws -> Bool {
        guard signature.count == 64 else {
            throw Ed25519Error.invalidSignatureLength
        }

        return signature.withUnsafeBufferPointer { signature in
            message.withUnsafeBufferPointer { msg in
                buffer.withUnsafeBufferPointer { pub in
                    ed25519_verify(signature.baseAddress,
                                   msg.baseAddress,
                                   message.count,
                                   pub.baseAddress) == 1
                }
            }
        }
    }

    public func add(scalar: [UInt8]) throws -> PublicKey {
        guard scalar.count == 32 else {
            throw Ed25519Error.invalidScalarLength
        }
        
        var pub = buffer
        
        pub.withUnsafeMutableBufferPointer { pub in
            scalar.withUnsafeBufferPointer { scalar in
                ed25519_add_scalar(pub.baseAddress,
                                   nil,
                                   scalar.baseAddress)
            }
        }
        
        return PublicKey(unchecked: pub)
    }
}
