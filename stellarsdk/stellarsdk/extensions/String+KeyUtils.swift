//
//  String+KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Errors that can occur during Stellar key decoding.
public enum KeyUtilsError: Error, Sendable {
    /// The encoded string is invalid or malformed.
    case invalidEncodedString

    /// The version byte in the encoded string is incorrect.
    case invalidVersionByte

    /// The checksum validation failed.
    case invalidChecksum
}

/// Extension providing Stellar key decoding utilities for String.
///
/// This extension allows decoding Stellar's StrKey format (versioned base32 encoding with checksums)
/// back to binary key data. Different version bytes are used for different key types.
///
/// Example:
/// ```swift
/// let address = "GABCD..."
/// let publicKeyData = try address.decodeEd25519PublicKey()
///
/// // Validate before decoding
/// if address.isValidEd25519PublicKey() {
///     let keyData = try address.decodeEd25519PublicKey()
/// }
/// ```
///
/// See: [SEP-0023](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md) for StrKey specification.
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
        return isValid(versionByte: .sha256Hash)
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
        return data.base16EncodedString()
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
        return data.base16EncodedString()
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
        return data.base16EncodedString()
    }
    
    /// Returns true if the string represents a valid strkey liquidity pool id. Must start with "L"
    public func isValidLiquidityPoolId() -> Bool {
        return isValid(versionByte: .liquidityPool)
    }
    
    /// Decodes strkey muxed account id (med25519 public key - "M...") to MuxedAccountXDR.
    public func decodeMuxedAccount() throws -> MuxedAccountXDR {
        switch self.count {
        case StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD:
            let pk = try PublicKey(accountId: self)
            let mux = MuxedAccountXDR.ed25519(pk.bytes)
            return mux
        case StellarProtocolConstants.STRKEY_ENCODED_LENGTH_MUXED:
            let xdr = try decodeCheck(versionByte: .med25519PublicKey)
            let muxEd25519 = try XDRDecoder.decode(MuxedAccountMed25519XDRInverted.self, data:xdr)
            let mux = MuxedAccountXDR.med25519(muxEd25519.toMuxedAccountMed25519XDR())
            return mux
        default:
            throw KeyUtilsError.invalidEncodedString
        }
    }
    
    /// Encodes a contract id from its hex representation into its strkey representation ("C...").
    ///
    /// - Returns: StrKey encoded contract id
    /// - Throws: StellarSDKError.invalidArgument if the string is not valid hexadecimal, or
    /// if it does not hold the 32 bytes a contract id is wide
    public func encodeContractIdHex() throws -> String {
        if let data = data(using: .hexadecimal) {
            return try data.encodeContractId()
        }
        throw StellarSDKError.invalidArgument(message: "Not a hex string \(self)")
    }
    
    /// Encodes a claimable balance id from its hex representation into its strkey representation ("B...").
    ///
    /// - Returns: StrKey encoded claimable balance id
    /// - Throws: StellarSDKError.invalidArgument if the string is not valid hexadecimal, or
    /// if it holds neither the 32 bytes an id is wide, nor the 33 bytes of a body opening
    /// with the claimable balance type discriminant, nor the 36 bytes of the XDR encoding
    /// opening with the four byte union discriminant, the shape Horizon reports
    public func encodeClaimableBalanceIdHex() throws -> String {
        if let data = data(using: .hexadecimal) {
            return try data.encodeClaimableBalanceId()
        }
        throw StellarSDKError.invalidArgument(message: "Not a hex string \(self)")
    }
    
    /// Encodes a liquidity pool id from its hex representation into its strkey representation ("L...").
    ///
    /// - Returns: StrKey encoded liquidity pool id
    /// - Throws: StellarSDKError.invalidArgument if the string is not valid hexadecimal, or
    /// if it does not hold the 32 bytes a liquidity pool id is wide
    public func encodeLiquidityPoolIdHex() throws -> String {
        if let data = data(using: .hexadecimal) {
            return try data.encodeLiquidityPoolId()
        }
        throw StellarSDKError.invalidArgument(message: "Not a hex string \(self)")
    }
    
    /// Checks if the string is a valid hexadecimal representation of data.
    ///
    /// - Returns: True if the string is valid hexadecimal, false otherwise
    public func isHexString() -> Bool {
        if let _ = data(using: .hexadecimal) {
            return true
        }
        return false
    }
    
    private func isValid(versionByte:VersionByte) -> Bool {
        if !versionByte.encodedLengthRange.contains(self.count) {
            return false
        }

        do {
            let data = try decodeCheck(versionByte: versionByte)
            switch versionByte {
            case .ed25519PublicKey, .ed25519SecretSeed, .preAuthTX, .sha256Hash, .contract, .liquidityPool:
                return data.count == StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD
            case .med25519PublicKey:
                return data.count == StellarProtocolConstants.STRKEY_DECODED_SIZE_MUXED
            case .signedPayload:
                // Signer key + payload size field + payload data
                let minSize = StellarProtocolConstants.SIGNED_PAYLOAD_SIGNER_SIZE + StellarProtocolConstants.SIGNED_PAYLOAD_SIZE_FIELD + StellarProtocolConstants.SIGNED_PAYLOAD_MIN_PAYLOAD
                let maxSize = StellarProtocolConstants.SIGNED_PAYLOAD_SIGNER_SIZE + StellarProtocolConstants.SIGNED_PAYLOAD_SIZE_FIELD + StellarProtocolConstants.SIGNED_PAYLOAD_MAX_PAYLOAD
                return data.count >= minSize && data.count <= maxSize
            case .claimableBalance:
                return data.count == StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD + StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_SIZE
            }
        } catch {
            return false
        }
    }
    
    /// Decodes a strkey to its raw payload, verifying the encoded length, the canonical
    /// base32 encoding, the version byte, the CRC-16 checksum and, for a signed payload or a
    /// claimable balance id, the shape of the decoded body.
    ///
    /// - Parameter versionByte: the version byte the strkey must carry
    ///
    /// - Throws: KeyUtilsError.invalidEncodedString if the length is not one the version byte
    /// allows, if the string is not canonical base32, if a signed payload body does not
    /// carry the framing SEP-23 defines, or if a claimable balance id body opens with a type
    /// the XDR union does not define,
    /// KeyUtilsError.invalidVersionByte if it carries a different version byte,
    /// KeyUtilsError.invalidChecksum if the checksum does not match the payload
    ///
    private func decodeCheck(versionByte:VersionByte) throws -> Data {
        // Counting characters bounds the length safely: a character spanning more than one
        // unicode scalar carries one outside the base32 alphabet, which the decode rejects.
        if !versionByte.encodedLengthRange.contains(self.count) {
            throw KeyUtilsError.invalidEncodedString
        }
        if let decoded = base32DecodedData {
            if self != decoded.base32EncodedString.replacingOccurrences(of: "=", with: "") {
                throw KeyUtilsError.invalidEncodedString
            }
            let buffer = decoded.bytes
            if buffer.count < StellarProtocolConstants.STRKEY_MIN_DECODED_SIZE {
                throw KeyUtilsError.invalidEncodedString
            }
            if let byte = buffer.first, let dataVersionByte = VersionByte(rawValue: byte), dataVersionByte == versionByte {
                let payload = Array(buffer[0...buffer.count - StellarProtocolConstants.STRKEY_OVERHEAD_SIZE])
                let data = Array(payload[StellarProtocolConstants.STRKEY_VERSION_BYTE_SIZE...payload.count - 1])
                let checksumBytes = Array(buffer[buffer.count - StellarProtocolConstants.STRKEY_CHECKSUM_SIZE...buffer.count - 1])
                let checksum = Data(bytes: checksumBytes, count: checksumBytes.count)
                var crc = Data(bytes: payload, count: payload.count).crc16()
                let checksumedData = Data(bytes: &crc, count: MemoryLayout.size(ofValue: crc))
                
                if checksum != checksumedData {
                    throw KeyUtilsError.invalidChecksum
                }

                if versionByte == .signedPayload && !SignedPayloadFraming.isValidBody(data) {
                    throw KeyUtilsError.invalidEncodedString
                }

                if versionByte == .claimableBalance
                    && !ClaimableBalanceIdFraming.isValidBody(data) {
                    throw KeyUtilsError.invalidEncodedString
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
