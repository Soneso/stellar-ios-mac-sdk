//
//  PrivateKey.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import ed25519C

/// Represents a Stellar Ed25519 private key.
///
/// A private key is a 64-byte value that represents the private component of an Ed25519 keypair.
/// The first 32 bytes are the secret scalar, and the last 32 bytes are the precomputed public key.
/// Private keys are used to sign transactions and messages on the Stellar network.
///
/// Security considerations:
/// - Private keys must be kept absolutely secret and secure
/// - Never transmit private keys over insecure channels
/// - Store private keys using secure storage (iOS Keychain or equivalent)
/// - Never commit private keys to version control
/// - Use Seed class for human-readable secret seed representation
/// - Clear sensitive data from memory when no longer needed
///
/// Note: For most use cases, use the Seed class which provides the 32-byte seed
/// and can be encoded as a human-readable secret seed (S-address).
public final class PrivateKey {
    private let buffer: [UInt8]
    
    /// Creates a new Stellar private key from the given bytes
    ///
    /// - Parameter bytes: the byte array of the key. The length of the byte array must be 64
    ///
    /// - Throws Ed25519Error.invalidPrivateKeyLength if the lenght of the given byte array != 64
    ///
    public init(_ bytes: [UInt8]) throws {
        guard bytes.count == StellarProtocolConstants.ED25519_PRIVATE_KEY_SIZE else {
            throw Ed25519Error.invalidPrivateKeyLength
        }
        
        self.buffer = bytes
    }

    /// Internal initializer that skips validation.
    ///
    /// Used internally when the bytes are known to be valid.
    ///
    /// - Parameter buffer: The private key bytes (assumed to be 64 bytes)
    init(unchecked buffer: [UInt8]) {
        self.buffer = buffer
    }

    /// The raw private key bytes (64 bytes).
    ///
    /// The first 32 bytes are the secret scalar, and the last 32 bytes are
    /// the precomputed public key for efficient signature operations.
    public var bytes: [UInt8] {
        return buffer
    }
}
