//
//  String+KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum KeyUtilsError: Error {
    case invalidEncodedString
    case invalidVersionByte
    case invalidChecksum
}

extension String {
    
    public func decodeEd25519PublicKey() throws -> Data {
        return try decodeCheck(versionByte: .accountId)
    }
    
    public func decodeEd25519SecretSeed() throws -> Data {
        return try decodeCheck(versionByte: .seed)
    }
    
    public func decodePreAuthTx() throws -> Data {
        return try decodeCheck(versionByte: .preAuthTX)
    }
    
    public func decodeSha256Hash() throws -> Data {
        return try decodeCheck(versionByte: .sha256Hash)
    }
    
    public func isValidEd25519PublicKey() -> Bool {
        return isValid(versionByte: .accountId)
    }
    
    private func isValid(versionByte:VersionByte) -> Bool {
        if self.count != 56 {
            return false
        }
        
        do {
            let data = try decodeCheck(versionByte: versionByte)
            if data.count != 32 {
                return false
            }
        } catch {
            return false
        }
        
        return true
    }
    
    private func decodeCheck(versionByte:VersionByte) throws -> Data {
        if let decoded = base32DecodedData {
            let buffer = decoded.bytes
            if let byte = buffer.first, let dataVersionByte = VersionByte(rawValue: byte), dataVersionByte == versionByte {
                let payload = Array(buffer[0...buffer.count - 3])
                let data = Array(payload[1...payload.count - 1])
                let checksumBytes = Array(buffer[buffer.count - 2...buffer.count - 1])
                let checksum = Data(bytes: checksumBytes, count: checksumBytes.count)
                var crc = Data(bytes: payload, count: payload.count).crc16()
                let checksumedData = Data(bytes: &crc, count: MemoryLayout.size(ofValue: crc))
                
                if checksum != checksumedData {
                    throw KeyUtilsError.invalidChecksum
                }
                
                return Data(bytes: data, count: data.count)
            } else {
                throw KeyUtilsError.invalidVersionByte
            }
        } else {
            throw KeyUtilsError.invalidEncodedString
        }
        
    }
    
}
