//
//  Seed.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import ed25519C

/// Holds a Stellar seed.
public class Seed {
    private let buffer: [UInt8]

    init(unchecked bytes: [UInt8]) {
        self.buffer = bytes
    }
    
    public init(bytes: [UInt8]) throws {
        guard bytes.count == StellarProtocolConstants.ED25519_SEED_SIZE else {
            throw Ed25519Error.invalidSeedLength
        }
        
        buffer = bytes
    }

    public convenience init() throws {
        var buffer = [UInt8](repeating: 0, count: StellarProtocolConstants.ED25519_SEED_SIZE)
        
        let result = buffer.withUnsafeMutableBufferPointer {
            ed25519_create_seed($0.baseAddress)
        }
        
        guard result == 0 else {
            throw Ed25519Error.seedGenerationFailed
        }
        
        self.init(unchecked: buffer)
    }
    
    public convenience init(secret: String) throws {
        
        if !secret.hasPrefix("S") {
            throw Ed25519Error.invalidSeed
        }
        
        if let data = secret.base32DecodedData {
            if data.count - StellarProtocolConstants.STRKEY_OVERHEAD_SIZE <= StellarProtocolConstants.STRKEY_VERSION_BYTE_SIZE {
                throw Ed25519Error.invalidSeed
            }
            try self.init(bytes:Array(([UInt8](data))[StellarProtocolConstants.STRKEY_VERSION_BYTE_SIZE...data.count - StellarProtocolConstants.STRKEY_OVERHEAD_SIZE]))
        } else {
            throw Ed25519Error.invalidSeed
        }
    }

    public var bytes: [UInt8] {
        return buffer
    }
    
    public var secret: String {
        get {
            var versionByte = VersionByte.ed25519SecretSeed.rawValue
            let versionByteData = Data(bytes: &versionByte, count: MemoryLayout.size(ofValue: versionByte))
            let payload = NSMutableData(data: versionByteData)
            payload.append(Data(bytes))
            let checksumedData = (payload as Data).crc16Data()
            
            return checksumedData.base32EncodedString
        }
    }
}
