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

extension VersionByte: RawRepresentable {
    typealias RawValue = UInt8
    
    var rawValue: UInt8 {
        switch self {
        case .ed25519PublicKey:
            return 48
        case .med25519PublicKey:
            return 96
        case .signedPayload:
            return 120
        case .ed25519SecretSeed:
            return 144
        case .preAuthTX:
            return 152
        case .sha256Hash:
            return 184
        case .contract:
            return 16
        case .liquidityPool:
            return 88
        case .claimableBalance:
            return 8
        }
    }
}
