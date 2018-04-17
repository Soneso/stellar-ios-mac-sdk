//
//  PublicKey.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import ed25519C

/// Holds a Stellar public key.
public class PublicKey: XDRCodable {
    private let buffer: [UInt8]
    
    /// Human readable Stellar account ID.
    public var accountId: String {
        get {
            var versionByte = VersionByte.accountId.rawValue
            let versionByteData = Data(bytes: &versionByte, count: MemoryLayout.size(ofValue: versionByte))
            let payload = NSMutableData(data: versionByteData)
            payload.append(Data(bytes: self.bytes))
            let checksumedData = (payload as Data).crc16Data()
            
            return checksumedData.base32EncodedString
        }
    }
    
    init(unchecked buffer: [UInt8]) {
        self.buffer = buffer
    }
    
    /// Creates a new Stellar public key from the given bytes
    ///
    /// - Parameter bytes: the byte array of the key. The length of the byte array must be 32
    ///
    /// - Throws Ed25519Error.invalidPublicKeyLength if the lenght of the given byte array != 32
    ///
    public convenience init(_ bytes: [UInt8]) throws {
        guard bytes.count == 32 else {
            throw Ed25519Error.invalidPublicKeyLength
        }
        
        self.init(unchecked: bytes)
    }
    
    /*public init(key: String) throws {
        if let data = key.base32DecodedData {
            self.buffer = [UInt8](data)
        } else {
            throw Ed25519Error.invalidPublicKey
        }
    }*/
    
    /// Creates a new Stellar public key from the Stellar account ID
    ///
    /// - Parameter accountId: The Stellar account ID
    ///
    /// - Throws Ed25519Error.invalidPublicKey if the accountId is invalid
    ///
    public convenience init(accountId: String) throws {
        if let data = accountId.base32DecodedData {
            try self.init(Array(([UInt8](data))[1...data.count - 3]))
        } else {
            throw Ed25519Error.invalidPublicKey
        }
    }
    
    /// Creates a new Stellar public key the given XDR Decoder
    ///
    /// - Parameter decoder: The decoder
    ///
    /// - Throws errors if the key could not be created from the given decoder
    ///
    public required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        _ = try container.decode(Int32.self)
        
        let wrappedData = try container.decode(WrappedData32.self)
        self.buffer = wrappedData.wrapped.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: wrappedData.wrapped.count))
        }
        
    }
    
    /// Byte array representation of the public key.
    public var bytes: [UInt8] {
        return buffer
    }
    
    /*public var key: String {
        var bytes = buffer
        return Data(bytes: &bytes, count: bytes.count).base32EncodedString!
    }*/
    
    /// Encodes the public key to the given XDR Encoder
    ///
    /// - Parameter encoder: the xdr encoder
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(Int32(0))
        var bytesArray = bytes
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
    }

    /// Verify the provided data and signature match this public key.
    ///
    /// - Parameter signature: The signature. Byte array must have a lenght of 64.
    /// - Parameter message: The data that was signed.
    ///
    /// - Returns: True if they match, false otherwise.
    ///
    /// - Throws: Ed25519Error.invalidSignatureLength if the signature length is not 64
    ///
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
}
