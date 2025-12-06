//
//  Ed25519Derivation.swift
//  stellarsdk
//
//  Created by Satraj Bambra on 2018-03-07.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Implements BIP-32 hierarchical deterministic key derivation for Ed25519 keys.
///
/// This struct provides Ed25519 key derivation following the BIP-32 standard, specifically
/// for deriving Stellar keys using the path m/44'/148'/account'. The derivation uses
/// HMAC-SHA512 to generate child keys from parent keys in a deterministic way.
///
/// The Stellar derivation path follows BIP-44:
/// - Purpose: 44' (hardened, meaning BIP-44)
/// - Coin type: 148' (hardened, Stellar's registered coin type)
/// - Account: n' (hardened, user-defined account index)
///
/// All derivation levels use hardened keys (indicated by '), which means the parent
/// private key is required to derive child keys, providing better security isolation.
///
/// See also:
/// - [BIP-32 Specification](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)
/// - [BIP-44 Specification](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)
/// - [SEP-0005 Key Derivation](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md)
public struct Ed25519Derivation: Sendable {

    /// The derived private key material (32 bytes).
    public let raw: Data

    /// The chain code used for deriving child keys (32 bytes).
    ///
    /// The chain code is additional entropy that ensures deterministic derivation
    /// while preventing knowledge of parent keys from child keys alone.
    public let chainCode: Data

    /// Initializes the root derivation node from a BIP-39 seed.
    ///
    /// Creates the master key from a BIP-39 seed using HMAC-SHA512 with the key "ed25519 seed".
    /// The first 32 bytes become the private key material, and the last 32 bytes become the chain code.
    ///
    /// - Parameter seed: A 512-bit (64-byte) seed generated from a BIP-39 mnemonic
    public init(seed: Data) {
        let output = HDCrypto.HMACSHA512(key: "ed25519 seed".data(using: .utf8)!, data: seed)
        self.raw = output[0..<32]
        self.chainCode = output[32..<64]
    }
    
    /// Internal initializer for creating derived keys.
    ///
    /// - Parameter privateKey: The derived private key material
    /// - Parameter chainCode: The derived chain code
    private init(privateKey: Data, chainCode: Data) {
        self.raw = privateKey
        self.chainCode = chainCode
    }

    /// Derives a child key at the specified hardened index.
    ///
    /// Performs BIP-32 hardened derivation to generate a child key from the current key.
    /// Hardened derivation (index + 0x80000000) ensures that child keys cannot be derived
    /// from the parent public key, providing better security isolation between derivation levels.
    ///
    /// This method is used to traverse the BIP-44 derivation path:
    /// ```
    /// let masterKey = Ed25519Derivation(seed: bip39Seed)
    /// let purpose = masterKey.derived(at: 44)      // m/44'
    /// let coinType = purpose.derived(at: 148)      // m/44'/148'
    /// let account = coinType.derived(at: 0)        // m/44'/148'/0'
    /// ```
    ///
    /// - Parameter index: The unhardened index (0-based). The method automatically applies
    ///                    hardening by adding 0x80000000 to the index.
    ///
    /// - Returns: A new Ed25519Derivation representing the derived child key
    ///
    /// The derivation process:
    /// 1. Prepends 0x00 to the parent private key
    /// 2. Appends the hardened index (index + 0x80000000)
    /// 3. Computes HMAC-SHA512 using the parent chain code as key
    /// 4. First 32 bytes become the child private key
    /// 5. Last 32 bytes become the child chain code
    public func derived(at index: UInt32) -> Ed25519Derivation {
        let edge: UInt32 = 0x80000000
        guard (edge & index) == 0 else { fatalError("Invalid index") }

        var data = Data()
        data += UInt8(0)
        data += raw

        let derivingIndex = edge + index
        data += derivingIndex.bigEndian

        let digest = HDCrypto.HMACSHA512(key: chainCode, data: data)
        let factor = BInt(data: digest[0..<32])

        let derivedPrivateKey = factor.data
        let derivedChainCode = digest[32..<64]

        return Ed25519Derivation (
            privateKey: derivedPrivateKey,
            chainCode: derivedChainCode
        )
    }
}
