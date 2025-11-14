//
//  Crypto.swift
//  WalletKit
//
//  Created by yuzushioh on 2018/02/06.
//  Copyright © 2018 yuzushioh. All rights reserved.
//

import Foundation

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
        let output: [UInt8]
        do {
            output = try HMAC(key: key.bytes, variant: .sha512).authenticate(data.bytes)
        } catch let error {
            fatalError("Error occured. Description: \(error.localizedDescription)")
        }
        return Data(output)
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
        let output: [UInt8]
        do {
            output = try PKCS5.PBKDF2(password: password, salt: salt, iterations: 2048, variant: .sha512).calculate()
        } catch let error {
            fatalError("PKCS5.PBKDF2 faild: \(error.localizedDescription)")
        }
        return Data(output)
    }
}

