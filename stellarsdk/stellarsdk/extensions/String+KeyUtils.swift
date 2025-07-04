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

/// Str+KeyUtils is a helper extension that allows decoding Stellar keys
/// from thier StrKey representations (i.e. "GABCD...", etc.) to their binary (Data) representations.
extension String {
    
    /// Decodes strkey ed25519 public key ("G...")  to raw data
    public func decodeEd25519PublicKey() throws -> Data {
        return try decodeCheck(versionByte: .ed25519PublicKey)
    }
    
    /// Returns true if the string represents a valid strkey ed25519 public key. Must start with "G"
    public func isValidEd25519PublicKey() -> Bool {
        return isValid(versionByte: .ed25519PublicKey)
    }
    
    /// Decodes strkey ed25519 seed  ("S...")  to raw data.
    public func decodeEd25519SecretSeed() throws -> Data {
        return try decodeCheck(versionByte: .ed25519SecretSeed)
    }
    
    /// Returns true if the string represents a valid strkey ed25519 seed. Must start with "S"
    public func isValidEd25519SecretSeed() -> Bool {
        return isValid(versionByte: .ed25519SecretSeed)
    }
    
    /// Decodes strkey med25519 public key ("M...") to raw data.
    public func decodeMed25519PublicKey() throws -> Data {
        return try decodeCheck(versionByte: .med25519PublicKey)
    }
    
    /// Returns true if the string represents a valid strkey med25519 public key. Must start with "M"
    public func isValidMed25519PublicKey() -> Bool {
        return isValid(versionByte: .med25519PublicKey)
    }
    
    /// Decodes strkey PreAuthTx ("T...") to raw data.
    public func decodePreAuthTx() throws -> Data {
        return try decodeCheck(versionByte: .preAuthTX)
    }
    
    /// Returns true if the string represents a valid strkey PreAuthTx . Must start with "T"
    public func isValidPreAuthTx() -> Bool {
        return isValid(versionByte: .preAuthTX)
    }
    
    /// Decodes strkey sha256 hash ("X...") to raw data.
    public func decodeSha256Hash() throws -> Data {
        return try decodeCheck(versionByte: .sha256Hash)
    }
    
    /// Returns true if the string represents a valid strkey sha256 hash . Must start with "X"
    public func isValidSha256Hash() -> Bool {
        return isValid(versionByte: .preAuthTX)
    }
    
    /// Decodes strkey signed payload ("P...") to Ed25519SignedPayload.
    public func decodeSignedPayload() throws -> Ed25519SignedPayload {
        let xdr = try decodeCheck(versionByte: .signedPayload)
        return try XDRDecoder.decode(Ed25519SignedPayload.self, data:xdr)
    }
    
    /// Returns true if the string represents a valid strkey signed payload . Must start with "P"
    public func isValidSignedPayload() -> Bool {
        return isValid(versionByte: .signedPayload)
    }
    
    /// Decodes strkey contract id ("C...") to raw data.
    public func decodeContractId() throws -> Data {
        return try decodeCheck(versionByte: .contract)
    }
    
    /// Decodes strkey contract id ("C...") to raw data and then returns the hex encoded string representation of the raw data.
    public func decodeContractIdToHex() throws -> String {
        let data = try decodeCheck(versionByte: .contract)
        return data.hexEncodedString()
    }
    
    /// Returns true if the string represents a valid strkey contract id . Must start with "C"
    public func isValidContractId() -> Bool {
        return isValid(versionByte: .contract)
    }
    
    /// Decodes strkey claimable balance id ("B...") to raw data.
    public func decodeClaimableBalanceId() throws -> Data {
        return try decodeCheck(versionByte: .claimableBalance)
    }
    
    /// Decodes strkey claimable balance id  ("B...") to raw data and then returns the hex encoded string representation of the raw data.
    public func decodeClaimableBalanceIdToHex() throws -> String {
        let data = try decodeCheck(versionByte: .claimableBalance)
        return data.hexEncodedString()
    }
    
    /// Returns true if the string represents a valid strkey claimable balance id. Must start with "B"
    public func isValidClaimableBalanceId() -> Bool {
        return isValid(versionByte: .claimableBalance)
    }
    
    /// Decodes strkey liquidity pool id ("L...") to raw data.
    public func decodeLiquidityPoolId() throws -> Data {
        return try decodeCheck(versionByte: .liquidityPool)
    }
    
    /// Decodes strkey liquidity pool id ("L...") to raw data and then returns the hex encoded string representation of the raw data.
    public func decodeLiquidityPoolIdToHex() throws -> String {
        let data = try decodeCheck(versionByte: .liquidityPool)
        return data.hexEncodedString()
    }
    
    /// Returns true if the string represents a valid strkey liquidity pool id. Must start with "L"
    public func isValidLiquidityPoolId() -> Bool {
        return isValid(versionByte: .liquidityPool)
    }
    
    /// Decodes strkey muxed account id (med25519 public key - "M...") to MuxedAccountXDR.
    public func decodeMuxedAccount() throws -> MuxedAccountXDR {
        switch self.count {
        case 56:
            let pk = try PublicKey(accountId: self)
            let mux = MuxedAccountXDR.ed25519(pk.bytes)
            return mux
        case 69:
            let xdr = try decodeCheck(versionByte: .med25519PublicKey)
            let muxEd25519 = try XDRDecoder.decode(MuxedAccountMed25519XDRInverted.self, data:xdr)
            let mux = MuxedAccountXDR.med25519(muxEd25519.toMuxedAccountMed25519XDR())
            return mux
        default:
            throw KeyUtilsError.invalidEncodedString
        }
    }
    
    // Encodes a contract id from its hex representation into its strkey representation ("C...")
    public func encodeContractIdHex() throws -> String {
        if let data = data(using: .hexadecimal) {
            return try data.encodeContractId()
        }
        throw StellarSDKError.invalidArgument(message: "Not a hex string \(self)")
    }
    
    // Encodes a claimable balance id from its hex representation into its strkey representation ("B...")
    public func encodeClaimableBalanceIdHex() throws -> String {
        if let data = data(using: .hexadecimal) {
            return try data.encodeClaimableBalanceId()
        }
        throw StellarSDKError.invalidArgument(message: "Not a hex string \(self)")
    }
    
    // Encodes a liquidity pool id from its hex representation into its strkey representation ("L...")
    public func encodeLiquidityPoolIdHex() throws -> String {
        if let data = data(using: .hexadecimal) {
            return try data.encodeLiquidityPoolId()
        }
        throw StellarSDKError.invalidArgument(message: "Not a hex string \(self)")
    }
    
    // Checks if the string is a hex representation of data.
    public func isHexString() -> Bool {
        if let _ = data(using: .hexadecimal) {
            return true
        }
        return false
    }
    
    private func isValid(versionByte:VersionByte) -> Bool {
        switch versionByte {
        case .ed25519PublicKey, .ed25519SecretSeed, .preAuthTX, .sha256Hash, .contract, .liquidityPool:
            if self.count != 56 {
                return false
            }
        case .med25519PublicKey:
            if self.count != 69 {
                return false
            }
        case .signedPayload:
            if self.count < 56 || self.count > 165 {
                return false
            }
        case .claimableBalance:
            if self.count != 58 {
                return false
            }
        }
        
        do {
            let data = try decodeCheck(versionByte: versionByte)
            switch versionByte {
            case .ed25519PublicKey, .ed25519SecretSeed, .preAuthTX, .sha256Hash, .contract, .liquidityPool:
                return data.count == 32
            case .med25519PublicKey:
                return data.count == 40 // +8 bytes for the ID
            case .signedPayload:
                // 32 for the signer, +4 for the payload size, then either +4 for the
                // min or +64 for the max payload
                return data.count >= 32 + 4 + 4 && data.count <= 32 + 4 + 64
            case .claimableBalance:
                return data.count == 32 + 1; // +1 byte for discriminant
            }
        } catch {
            return false
        }
    }
    
    private func decodeCheck(versionByte:VersionByte) throws -> Data {
        if let decoded = base32DecodedData {
            if self != decoded.base32EncodedString.replacingOccurrences(of: "=", with: "") {
                throw KeyUtilsError.invalidEncodedString
            }
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
