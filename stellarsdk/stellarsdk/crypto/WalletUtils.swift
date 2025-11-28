//
//  Wallet.swift
//  stellarsdk
//
//  Created by Satraj Bambra on 2018-03-07.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Implements SEP-0005 - Key Derivation Methods for Stellar Accounts.
///
/// This class provides BIP-39 mnemonic generation and BIP-44 hierarchical deterministic key
/// derivation for Stellar accounts. It allows creating multiple accounts from a single seed phrase,
/// enabling secure wallet backups and account management.
///
/// ## Typical Usage
///
/// ```swift
/// // Generate a 12-word mnemonic
/// let mnemonic = WalletUtils.generate12WordMnemonic()
///
/// // Derive first account (index 0)
/// let keyPair0 = try WalletUtils.createKeyPair(
///     mnemonic: mnemonic,
///     passphrase: nil,
///     index: 0
/// )
///
/// // Derive second account (index 1)
/// let keyPair1 = try WalletUtils.createKeyPair(
///     mnemonic: mnemonic,
///     passphrase: nil,
///     index: 1
/// )
/// ```
///
/// See also:
/// - [SEP-0005 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md)
public final class WalletUtils: Sendable {
    
    /// Generates a 12 word Mnemonic.
    public static func generate12WordMnemonic(language: WordList = .english) -> String {
        return Mnemonic.create(strength: .normal, language: language)
    }
    
    /// Generates a 24 word Mnemonic.
    public static func generate24WordMnemonic(language: WordList = .english) -> String {
        return Mnemonic.create(strength: .high, language: language)
    }
    
    /// Creates a new KeyPair from the given mnemonic and index.
    ///
    /// - Parameter mnemonic: The mnemonic string.
    /// - Parameter passphrase: The passphrase.
    /// - Parameter index: The index of the wallet to generate.
    ///
    public static func createKeyPair(mnemonic: String, passphrase: String?, index: Int) throws -> KeyPair {
        let bip39Seed: Data

        if let passphraseValue = passphrase, !passphraseValue.isEmpty {
            bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic, withPassphrase: passphraseValue)
        } else {
            bip39Seed = Mnemonic.createSeed(mnemonic: mnemonic)
        }

        let masterPrivateKey = Ed25519Derivation(seed: bip39Seed)
        let purpose = masterPrivateKey.derived(at: 44)
        let coinType = purpose.derived(at: 148)
        let account = coinType.derived(at: UInt32(index))
        let stellarSeed = try Seed(bytes: account.raw.bytes)
        let keyPair = KeyPair.init(seed: stellarSeed)

        return keyPair
    }
}
