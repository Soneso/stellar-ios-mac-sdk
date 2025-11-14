//
//  Mnemonic.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/02/11.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki

import Foundation

/// Implements BIP-39 mnemonic code for generating deterministic keys.
///
/// This class provides functionality for generating and working with mnemonic phrases
/// (also known as seed phrases or recovery phrases) according to the BIP-39 standard.
/// Mnemonics are human-readable representations of cryptographic seeds that can be used
/// to derive hierarchical deterministic wallets.
///
/// The mnemonic consists of 12 or 24 words selected from a standardized word list.
/// These words encode entropy that can be used to generate a seed for wallet derivation.
///
/// See also:
/// - [BIP-39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
public final class Mnemonic {

    /// The strength of the mnemonic, determining the number of words generated.
    ///
    /// - normal: 128 bits of entropy, generates a 12-word mnemonic
    /// - high: 256 bits of entropy, generates a 24-word mnemonic
    public enum Strength: Int {
        case normal = 128
        case high = 256
    }

    /// Creates a new random mnemonic phrase.
    ///
    /// Generates a cryptographically secure random mnemonic using the specified strength
    /// and language word list. The mnemonic can be used to derive deterministic wallets.
    ///
    /// - Parameter strength: The entropy strength (default: .normal for 12 words)
    /// - Parameter language: The word list language (default: .english)
    ///
    /// - Returns: A space-separated mnemonic phrase
    ///
    /// Example:
    /// ```swift
    /// let mnemonic = Mnemonic.create(strength: .normal)
    /// // Returns: "abandon ability able about above absent absorb abstract absurd abuse access accident"
    /// ```
    public static func create(strength: Strength = .normal, language: WordList = .english) -> String {
        let byteCount = strength.rawValue / 8
        var bytes = Data(count: byteCount)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0) }
        return create(entropy: bytes, language: language)
    }
    
    /// Creates a mnemonic phrase from provided entropy.
    ///
    /// Converts raw entropy bytes into a BIP-39 compliant mnemonic phrase by adding a
    /// checksum and encoding the result as words from the specified language word list.
    ///
    /// - Parameter entropy: The entropy bytes (must be 128 or 256 bits)
    /// - Parameter language: The word list language (default: .english)
    ///
    /// - Returns: A space-separated mnemonic phrase
    public static func create(entropy: Data, language: WordList = .english) -> String {
        let entropybits = String(entropy.flatMap { ("00000000" + String($0, radix: 2)).suffix(8) })
        let hashBits = String(entropy.sha256().flatMap { ("00000000" + String($0, radix: 2)).suffix(8) })
        let checkSum = String(hashBits.prefix((entropy.count * 8) / 32))

        let words = language.words
        let concatenatedBits = entropybits + checkSum

        var mnemonic: [String] = []
        for index in 0..<(concatenatedBits.count / 11) {
            let startIndex = concatenatedBits.index(concatenatedBits.startIndex, offsetBy: index * 11)
            let endIndex = concatenatedBits.index(startIndex, offsetBy: 11)
            let wordIndex = Int(strtoul(String(concatenatedBits[startIndex..<endIndex]), nil, 2))
            mnemonic.append(String(words[wordIndex]))
        }

        return mnemonic.joined(separator: " ")
    }

    /// Creates a binary seed from a mnemonic phrase for use in key derivation.
    ///
    /// Generates a 512-bit seed from a mnemonic phrase using PBKDF2-HMAC-SHA512 with 2048 iterations.
    /// This seed can be used with BIP-32 hierarchical deterministic key derivation.
    ///
    /// The passphrase provides an additional security factor. Two different passphrases will
    /// produce completely different seeds from the same mnemonic, effectively creating plausible
    /// deniability.
    ///
    /// - Parameter mnemonic: The BIP-39 mnemonic phrase
    /// - Parameter passphrase: Optional passphrase for additional security (default: empty string)
    ///
    /// - Returns: A 512-bit (64-byte) seed suitable for key derivation
    ///
    /// Security considerations:
    /// - The passphrase is optional but recommended for enhanced security
    /// - Different passphrases generate different seeds from the same mnemonic
    /// - Store the passphrase securely if used; it cannot be recovered
    public static func createSeed(mnemonic: String, withPassphrase passphrase: String = "") -> Data {
        guard let password = mnemonic.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing password failed in \(self)")
        }
        
        guard let salt = ("mnemonic" + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing salt failed in \(self)")
        }
        
        return HDCrypto.PBKDF2SHA512(password: password.bytes, salt: salt.bytes)
    }
}


