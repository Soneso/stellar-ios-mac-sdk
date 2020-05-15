//
//  MuxedAccountXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct CryptoKeyType {
    static let KEY_TYPE_ED25519: Int32 = 0
    static let KEY_TYPE_PRE_AUTH_TX: Int32 = 1
    static let KEY_TYPE_HASH_X: Int32 = 2
    static let KEY_TYPE_MUXED_ED25519: Int32 = 0x100
}

public enum MuxedAccountXDR: XDRCodable {
    case ed25519([UInt8])
    case med25519 (UInt64, [UInt8])
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case CryptoKeyType.KEY_TYPE_MUXED_ED25519:
            let id = try container.decode(UInt64.self)
            let wrappedData = try container.decode(WrappedData32.self)
            let sourceAccountEd25519 = wrappedData.wrapped.withUnsafeBytes {
                [UInt8](UnsafeBufferPointer(start: $0, count: wrappedData.wrapped.count))
            }
            self = .med25519(id, sourceAccountEd25519)
        default:
            let wrappedData = try container.decode(WrappedData32.self)
            let sourceAccountEd25519 = wrappedData.wrapped.withUnsafeBytes {
                [UInt8](UnsafeBufferPointer(start: $0, count: wrappedData.wrapped.count))
            }
            self = .ed25519(sourceAccountEd25519)
        }
    }
    
    /// Human readable Stellar account ID.
    public var accountId: String {
        get {
            var versionByte = VersionByte.accountId.rawValue
            let versionByteData = Data(bytes: &versionByte, count: MemoryLayout.size(ofValue: versionByte))
            let payload = NSMutableData(data: versionByteData)
            
            switch self {
            case .ed25519(let sourceAccountEd25519):
                payload.append(Data(bytes: sourceAccountEd25519))
            case .med25519(let id, let sourceAccountEd25519):
                payload.append(Data(bytes: sourceAccountEd25519))
            }
            let checksumedData = (payload as Data).crc16Data()
            return checksumedData.base32EncodedString
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .ed25519: return CryptoKeyType.KEY_TYPE_ED25519
        case .med25519: return CryptoKeyType.KEY_TYPE_MUXED_ED25519
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .ed25519(let sourceAccountEd25519):
            var bytesArray = sourceAccountEd25519
            let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
            try container.encode(wrapped)
        case .med25519(let id, let sourceAccountEd25519):
            try container.encode(id)
            var bytesArray = sourceAccountEd25519
            let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
            try container.encode(wrapped)
        }
    }
}
