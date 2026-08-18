//
//  Data+KeyUtils.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/11/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Extension providing base64 decoding for byte arrays.
extension Array where Element == UInt8 {
    /// Creates a byte array from a base64-encoded string.
    ///
    /// - Parameter base64: Base64-encoded string
    /// - Returns: Array of decoded bytes, or empty array if decoding fails
    init(base64: String) {
        guard let data = Data(base64Encoded: base64) else {
            self = []
            return
        }
        self = Array(data)
    }

    /// Creates a byte array from a hexadecimal string.
    ///
    /// - Parameter hex: Hexadecimal string (with or without 0x prefix)
    /// - Returns: Array of decoded bytes
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "0x", with: "")

        var byteArray = [UInt8]()
        var index = hexSanitized.startIndex

        while index < hexSanitized.endIndex {
            let nextIndex = hexSanitized.index(index, offsetBy: 2, limitedBy: hexSanitized.endIndex) ?? hexSanitized.endIndex
            let byteString = hexSanitized[index..<nextIndex]

            if let byte = UInt8(byteString, radix: 16) {
                byteArray.append(byte)
            }
            index = nextIndex
        }

        self = byteArray
    }
}

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

    /// Creates Data from a hexadecimal string.
    ///
    /// - Parameter hex: Hexadecimal string (with or without 0x prefix)
    init(hex: String) {
        self = Data(Array<UInt8>(hex: hex))
    }

    /// Converts Data to an array of UInt8 bytes.
    var bytes: [UInt8] {
        return Array(self)
    }

    /// Encodes data to strkey ed25519 public key ("G...").
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is not the 32 bytes an ed25519
    /// public key is wide
    public func encodeEd25519PublicKey() throws -> String {
        try requireSize(StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD, "ed25519 public key")
        return try encodeCheck(versionByte: .ed25519PublicKey)
    }
    
    /// Encodes data to strkey ed25519 seed ("S...").
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is not the 32 bytes an ed25519
    /// seed is wide
    public func encodeEd25519SecretSeed() throws -> String {
        try requireSize(StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD, "ed25519 secret seed")
        return try encodeCheck(versionByte: .ed25519SecretSeed)
    }
    
    /// Encodes data to strkey med25519 public key. ("M...")
    ///
    /// The data is the ed25519 key followed by the muxed account id.
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is not the 40 bytes the 32 byte
    /// ed25519 key and the 8 byte muxed account id occupy
    public func encodeMEd25519AccountId() throws -> String {
        try requireSize(StellarProtocolConstants.STRKEY_DECODED_SIZE_MUXED, "med25519 public key")
        return try encodeCheck(versionByte: .med25519PublicKey)
    }
    
    /// Encodes data to strkey preAuthTx. ("T...")
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is not the 32 bytes a pre
    /// authorized transaction hash is wide
    public func encodePreAuthTx() throws -> String {
        try requireSize(StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD, "pre authorized transaction hash")
        return try encodeCheck(versionByte: .preAuthTX)
    }
    
    /// Encodes data to strkey sha256 hash. ("X...")
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is not the 32 bytes a sha256
    /// hash is wide
    public func encodeSha256Hash() throws -> String {
        try requireSize(StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD, "sha256 hash")
        return try encodeCheck(versionByte: .sha256Hash)
    }
    
    /// Encodes raw data to strkey signed payload ("P...").
    ///
    /// The data is the signed payload signer body: the signer key, the length of the signed
    /// data, the signed data itself and zero padding to a multiple of four bytes.
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data does not carry that framing:
    /// if it is too narrow to hold the 32 byte signer key and the 4 byte length field, if
    /// the length field does not name a length of 1 to 64 bytes, if the data is not as wide
    /// as that length padded to a multiple of four bytes, or if the padding is not zero bytes
    public func encodeSignedPayload() throws -> String {
        guard SignedPayloadFraming.isValidBody(self.bytes) else {
            let allowed = SignedPayloadFraming.payloadLengthRange
            throw StellarSDKError.invalidArgument(message: "invalid signed payload body, must carry the signer key, the length of the signed data, the signed data itself and zero padding to a multiple of four bytes, with signed data of \(allowed.lowerBound) to \(allowed.upperBound) bytes")
        }
        return try encodeCheck(versionByte: .signedPayload)
    }
    
    /// Encodes raw data to strkey contract id ("C...").
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is not the 32 bytes a contract
    /// id is wide
    public func encodeContractId() throws -> String {
        try requireSize(StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD, "contract id")
        return try encodeCheck(versionByte: .contract)
    }
    
    /// Encodes raw data to strkey claimable balance ("B...").
    ///
    /// The data is the id on its own, in which case the type discriminant
    /// CLAIMABLE_BALANCE_ID_TYPE_V0 is put in front of it, the body that already carries
    /// that discriminant, or the XDR encoding opening with the four byte union discriminant,
    /// the shape Horizon reports. CLAIMABLE_BALANCE_ID_TYPE_V0 is the only type the XDR
    /// union defines.
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is none of these: neither the
    /// 32 bytes an id is wide, nor the 33 bytes of a body, nor the 36 bytes of the XDR
    /// encoding, or if a body does not open with that discriminant
    public func encodeClaimableBalanceId() throws -> String {
        let bareId: Data
        do {
            bareId = try ClaimableBalanceIdFraming.bareId(from: self)
        } catch ClaimableBalanceIdFraming.MalformedId.discriminant(let carried) {
            throw StellarSDKError.invalidArgument(message: ClaimableBalanceIdFraming.discriminantMessage(carried))
        } catch ClaimableBalanceIdFraming.MalformedId.width(let width) {
            throw StellarSDKError.invalidArgument(message: "invalid claimable balance id length \(width), must be \(StellarProtocolConstants.CLAIMABLE_BALANCE_ID_SIZE), \(ClaimableBalanceIdFraming.bodySize) or \(ClaimableBalanceIdFraming.xdrBodySize) bytes")
        }
        var body = Data([ClaimableBalanceIdFraming.typeDiscriminant])
        body.append(bareId)
        return try body.encodeCheck(versionByte: .claimableBalance)
    }
    
    /// Encodes raw data to strkey liquidity pool id ("L...").
    ///
    /// - Throws: StellarSDKError.invalidArgument if the data is not the 32 bytes a liquidity
    /// pool id is wide
    public func encodeLiquidityPoolId() throws -> String {
        try requireSize(StellarProtocolConstants.STRKEY_DECODED_SIZE_STANDARD, "liquidity pool id")
        return try encodeCheck(versionByte: .liquidityPool)
    }
    
    /// Encodes raw data representing a MuxedAccountXDR to strkey muxed account id ("M...").
    ///
    /// The data is the 4 byte key type followed by the 32 byte ed25519 key, or by the 8 byte
    /// muxed account id and that key. KEY_TYPE_MUXED_ED25519 names the wider shape and gives
    /// an "M..." strkey; every other key type value is read as the narrower shape and gives
    /// the "G..." strkey of the ed25519 key.
    ///
    /// - Throws: XDRDecoder.Error.prematureEndOfData if the data is narrower than the shape
    /// its key type names: 44 bytes for KEY_TYPE_MUXED_ED25519, 36 bytes for any other value.
    /// Bytes past that width are ignored
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

    /// Throws unless the data is exactly `size` bytes wide.
    ///
    /// A version byte stands for a payload of one width.
    private func requireSize(_ size: Int, _ description: String) throws {
        guard self.count == size else {
            throw StellarSDKError.invalidArgument(message: "invalid \(description) length \(self.count), must be \(size) bytes")
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
