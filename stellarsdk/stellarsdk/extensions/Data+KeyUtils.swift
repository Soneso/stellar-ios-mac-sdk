//
//  Data+KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

extension Data {
    
    public func encodeEd25519PublicKey() throws -> String {
        return try encodeCheck(versionByte: .accountId)
    }
    
    public func encodeEd25519SecretSeed() throws -> String {
        return try encodeCheck(versionByte: .seed)
    }
    
    public func encodePreAuthTx() throws -> String {
        return try encodeCheck(versionByte: .preAuthTX)
    }
    
    public func encodeSha256Hash() throws -> String {
        return try encodeCheck(versionByte: .sha256Hash)
    }
    
    private func encodeCheck(versionByte:VersionByte) throws -> String {
        var versionByteRaw = versionByte.rawValue
        let versionByteData = Data(bytes: &versionByteRaw, count: MemoryLayout.size(ofValue: versionByte))
        let payload = NSMutableData(data: versionByteData)
        payload.append(Data(bytes: self.bytes))
        let checksumedData = (payload as Data).crc16Data()
        
        return checksumedData.base32EncodedString
    }
    
}
