//
//  Data+KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing Stellar key encoding utilities for Data.
///
/// This extension allows encoding binary key data into Stellar's StrKey format, which uses
/// versioned base32 encoding with checksums. Different version bytes are used for different
/// key types (accounts, seeds, hashes, etc.).
///
/// Example:
/// ```swift
/// let publicKeyData = Data([...]) // 32 bytes
/// let stellarAddress = try publicKeyData.encodeEd25519PublicKey()
/// // Returns "GABCD..." format address
/// ```
///
/// See: [SEP-0023](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md) for StrKey specification.
extension Data {
    
    /// Encodes data to strkey ed25519 public key ("G...").
    public func encodeEd25519PublicKey() throws -> String {
        return try encodeCheck(versionByte: .ed25519PublicKey)
    }
    
    /// Encodes data to strkey ed25519 seed ("S...").
    public func encodeEd25519SecretSeed() throws -> String {
        return try encodeCheck(versionByte: .ed25519SecretSeed)
    }
    
    /// Encodes data to strkey med25519 public key. ("M...")
    public func encodeMEd25519AccountId() throws -> String {
        return try encodeCheck(versionByte: .med25519PublicKey)
    }
    
    /// Encodes data to strkey preAuthTx. ("T...")
    public func encodePreAuthTx() throws -> String {
        return try encodeCheck(versionByte: .preAuthTX)
    }
    
    /// Encodes data to strkey sha256 hash. ("X...")
    public func encodeSha256Hash() throws -> String {
        return try encodeCheck(versionByte: .sha256Hash)
    }
    
    /// Encodes raw data to strkey signed payload ("P...").
    public func encodeSignedPayload() throws -> String {
        return try encodeCheck(versionByte: .signedPayload)
    }
    
    /// Encodes raw data to strkey contract id ("C...").
    public func encodeContractId() throws -> String {
        return try encodeCheck(versionByte: .contract)
    }
    
    /// Encodes raw data to strkey claimable balance ("B...").
    public func encodeClaimableBalanceId() throws -> String {
        if self.count == StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE {
            // type is missing so let's append it
            let type = UInt8(ClaimableBalanceIDType.claimableBalanceIDTypeV0.rawValue) // put the type into the first byte
            var typedData = Data([type])
            typedData.append(self)
            return try typedData.encodeCheck(versionByte: .claimableBalance)
        }
        return try encodeCheck(versionByte: .claimableBalance)
    }
    
    /// Encodes raw data to strkey liquidity pool id ("L...").
    public func encodeLiquidityPoolId() throws -> String {
        return try encodeCheck(versionByte: .liquidityPool)
    }
    
    /// Encodes raw data representing a MuxedAccountXDR to strkey muxed account id ("M...").
    public func encodeMuxedAccount() throws -> String {
        let muxed = try XDRDecoder.decode(MuxedAccountXDR.self, data:self)
        switch muxed {
        case .ed25519(_):
            return muxed.ed25519AccountId
        case .med25519(let mux):
            let muxInverted = mux.toMuxedAccountMed25519XDRInverted()
            let data = try Data(XDREncoder.encode(muxInverted))
            return try data.encodeMEd25519AccountId()
        }
    }

    private func encodeCheck(versionByte:VersionByte) throws -> String {
        var versionByteRaw = versionByte.rawValue
        let versionByteData = Data(bytes: &versionByteRaw, count: MemoryLayout.size(ofValue: versionByte))
        var payload = Data(versionByteData)
        payload.append(Data(self.bytes))
        let checksumedData = payload.crc16Data()

        return checksumedData.base32EncodedString.replacingOccurrences(of: "=", with: "")
    }
    
    /// Performs XOR operation on two Data objects.
    ///
    /// XORs each byte of the two data objects. If one is longer than the other,
    /// the remaining bytes of the longer one are appended unchanged.
    ///
    /// - Parameter left: First data object
    /// - Parameter right: Second data object
    /// - Returns: Result of XOR operation
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
