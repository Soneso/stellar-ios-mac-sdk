//
//  VersionByte.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Version bytes used in Stellar address encoding.
///
/// Each Stellar address type (public keys, seeds, hashes, contracts, etc.) uses a unique
/// version byte that determines the address prefix when encoded in base32 (StrKey format).
/// This ensures different address types cannot be confused and provides a visual indicator
/// of the address type.
///
/// The version byte is combined with the raw data and a checksum, then base32 encoded to
/// produce the final address string. The leftmost bits of the version byte determine the
/// prefix character.
///
/// Common address prefixes:
/// - G: Ed25519 public key (standard account address)
/// - M: Multiplexed Ed25519 public key (account with memo ID)
/// - S: Ed25519 secret seed (private key)
/// - T: Pre-authorized transaction hash (used in signers)
/// - X: SHA256 hash (used in signers)
/// - P: Signed payload (used in payload signers)
/// - C: Smart contract address
/// - L: Liquidity pool ID
/// - B: Claimable balance ID
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [SEP-0023: Strkeys](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md)
enum VersionByte:UInt8 {
    /// Ed25519 public key - Standard account address starting with 'G'
    case ed25519PublicKey = 48 // 6 << 3 - G (when encoded in base32)

    /// Ed25519 secret seed - Private key starting with 'S'
    case ed25519SecretSeed = 144 // 18 << 3 - S

    /// Multiplexed Ed25519 public key - Account address with memo ID starting with 'M'
    case med25519PublicKey = 96 // 12 << 3 - M

    /// Pre-authorized transaction hash - Used in multisig signers starting with 'T'
    case preAuthTX = 152 // 19 << 3 - T

    /// SHA256 hash - Used in hash-based signers starting with 'X'
    case sha256Hash = 184 // 23 << 3 - X

    /// Signed payload - Used in payload signers starting with 'P'
    case signedPayload = 120 // 15 << 3 - P

    /// Smart contract address - Soroban contract identifier starting with 'C'
    case contract = 16 // 2 << 3 - C

    /// Liquidity pool identifier - AMM pool ID starting with 'L'
    case liquidityPool = 88 // 11 << 3 - L

    /// Claimable balance identifier - Claimable balance ID starting with 'B'
    case claimableBalance = 8 // 1 << 3 - B
}

extension VersionByte {

    /// The strkey encoded string lengths a strkey carrying this version byte may have.
    ///
    /// A strkey encodes the version byte, the body and the CRC-16 checksum, so a type with a
    /// fixed body size has exactly one valid encoded length. Only the signed payload has a
    /// variable body and therefore a range of lengths: its body is the 32 signer bytes, a 4
    /// byte length field and the signed data zero padded to a multiple of 4 bytes. The signed
    /// data is 1 to 64 bytes, so the body spans 40 to 100 bytes.
    var encodedLengthRange: ClosedRange<Int> {
        switch self {
        case .ed25519PublicKey, .ed25519SecretSeed, .preAuthTX, .sha256Hash, .contract, .liquidityPool:
            return StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD...StellarProtocolConstants.STRKEY_ENCODED_LENGTH_STANDARD
        case .med25519PublicKey:
            return StellarProtocolConstants.STRKEY_ENCODED_LENGTH_MUXED...StellarProtocolConstants.STRKEY_ENCODED_LENGTH_MUXED
        case .signedPayload:
            return StellarProtocolConstants.STRKEY_SIGNED_PAYLOAD_MIN_LENGTH...StellarProtocolConstants.STRKEY_ENCODED_LENGTH_SIGNED_PAYLOAD_MAX
        case .claimableBalance:
            return StellarProtocolConstants.STRKEY_ENCODED_LENGTH_CLAIMABLE_BALANCE...StellarProtocolConstants.STRKEY_ENCODED_LENGTH_CLAIMABLE_BALANCE
        }
    }
}
