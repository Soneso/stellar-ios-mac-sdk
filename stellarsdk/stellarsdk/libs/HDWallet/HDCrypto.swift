//
//  Crypto.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/02/06.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

import Foundation
import CommonCrypto

/// Internal cryptographic utility functions for hierarchical deterministic wallet operations.
///
/// This class provides HMAC-SHA512 and PBKDF2-SHA512 implementations used in BIP-32 key
/// derivation and BIP-39 seed generation. These functions are fundamental building blocks
/// for the wallet's cryptographic operations.
///
/// Note: This is an internal class and not part of the public API.
final class HDCrypto {

    /// Computes HMAC-SHA512 authentication code.
    ///
    /// Used in BIP-32 hierarchical deterministic key derivation to generate child keys
    /// from parent keys. HMAC-SHA512 provides both authentication and deterministic
    /// derivation properties needed for HD wallets.
    ///
    /// - Parameter key: The HMAC key (typically the chain code)
    /// - Parameter data: The data to authenticate (typically includes parent key and index)
    ///
    /// - Returns: 64-byte HMAC-SHA512 digest
    static func HMACSHA512(key: Data, data: Data) -> Data {
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512),
                       keyBytes.baseAddress, key.count,
                       dataBytes.baseAddress, data.count,
                       &hmac)
            }
        }
        return Data(hmac)
    }

    /// Derives a cryptographic key from a password using PBKDF2-SHA512.
    ///
    /// Used in BIP-39 to convert a mnemonic phrase and optional passphrase into a
    /// binary seed. PBKDF2 (Password-Based Key Derivation Function 2) applies 2048
    /// iterations of HMAC-SHA512 to strengthen the key against brute-force attacks.
    ///
    /// - Parameter password: The password bytes (normalized mnemonic phrase)
    /// - Parameter salt: The salt bytes (typically "mnemonic" + optional passphrase)
    ///
    /// - Returns: 64-byte derived key suitable for BIP-32 seed
    static func PBKDF2SHA512(password: [UInt8], salt: [UInt8]) -> Data {
        var derivedKey = [UInt8](repeating: 0, count: 64)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password, password.count,
            salt, salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512),
            2048,
            &derivedKey, 64
        )

        guard status == kCCSuccess else {
            fatalError("PBKDF2 derivation failed with status: \(status)")
        }

        return Data(derivedKey)
    }
}

