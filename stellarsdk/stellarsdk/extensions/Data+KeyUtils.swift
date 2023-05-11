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
    
    public func encodeMuxedAccount() throws -> String {
        let muxed = try XDRDecoder.decode(MuxedAccountXDR.self, data:self)
        switch muxed {
        case .ed25519(_):
            return muxed.ed25519AccountId
        case .med25519(let mux):
            let muxInverted = mux.toMuxedAccountMed25519XDRInverted()
            let data = try Data(XDREncoder.encode(muxInverted))
            let result = try data.encodeMEd25519AccountId()
            return result.replacingOccurrences(of: "=", with: "")
        }
    }
    
    public func encodeSignedPayload() throws -> String {
        let result = try encodeCheck(versionByte: .signedPayload)
        return result.replacingOccurrences(of: "=", with: "")
    }
    
    public func encodeMEd25519AccountId() throws -> String {
        return try encodeCheck(versionByte: .muxedAccountId)
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
    
    public func encodeContractId() throws -> String {
        return try encodeCheck(versionByte: .contractId)
    }
    
    private func encodeCheck(versionByte:VersionByte) throws -> String {
        var versionByteRaw = versionByte.rawValue
        let versionByteData = Data(bytes: &versionByteRaw, count: MemoryLayout.size(ofValue: versionByte))
        let payload = NSMutableData(data: versionByteData)
        payload.append(Data(self.bytes))
        let checksumedData = (payload as Data).crc16Data()
        
        return checksumedData.base32EncodedString
    }
    
    static func xor (left: Data, right: Data) -> Data {
        var result: Data = Data()
        var smaller: Data, bigger: Data
        if left.count <= right.count {
            smaller = left
            bigger = right
        } else {
            smaller = right
            bigger = left
        }

        let bs:[UInt8] = Array(smaller)
        let bb:[UInt8] = Array (bigger)
        var br = [UInt8] ()
        for i in 0..<bs.count {
            br.append(bs[i] ^ bb[i])
        }
        for j in bs.count..<bb.count {
            br.append(bb[j])
        }
        result = Data(br)
        return result
    }
}
