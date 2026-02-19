//
//  Ed25519Error.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

/// Errors that can occur during Ed25519 cryptographic operations.
///
/// These errors indicate issues with key material, signatures, or cryptographic operations
/// related to Ed25519 keypairs used in Stellar.
public enum Ed25519Error: Error, Sendable {

    /// Cryptographic random seed generation failed.
    ///
    /// Thrown when the system's secure random number generator fails to produce
    /// the required entropy for seed generation. This is a critical error that
    /// should be rare in normal circumstances.
    case seedGenerationFailed

    /// The provided seed string (S-address) is invalid or malformed.
    ///
    /// This occurs when:
    /// - The seed string doesn't start with 'S'
    /// - The base32 decoding fails
    /// - The checksum validation fails
    case invalidSeed

    /// The seed byte array has an incorrect length.
    ///
    /// Seeds must be exactly 32 bytes. This error is thrown when attempting
    /// to create a Seed from a byte array of any other length.
    case invalidSeedLength

    /// The scalar value has an incorrect length.
    ///
    /// Ed25519 scalars must be exactly 32 bytes.
    case invalidScalarLength

    /// The provided public key string (G-address) is invalid or malformed.
    ///
    /// This occurs when:
    /// - The account ID doesn't start with 'G'
    /// - The base32 decoding fails
    /// - The checksum validation fails
    case invalidPublicKey

    /// The public key byte array has an incorrect length.
    ///
    /// Public keys must be exactly 32 bytes. This error is thrown when attempting
    /// to create a PublicKey from a byte array of any other length.
    case invalidPublicKeyLength

    /// The provided private key is invalid.
    ///
    /// This indicates that the private key material is malformed or unusable.
    case invalidPrivateKey

    /// The private key byte array has an incorrect length.
    ///
    /// Private keys must be exactly 64 bytes (32 bytes secret scalar + 32 bytes public key).
    /// This error is thrown when attempting to create a PrivateKey from a byte array
    /// of any other length.
    case invalidPrivateKeyLength

    /// The signature byte array has an incorrect length.
    ///
    /// Ed25519 signatures must be exactly 64 bytes. This error is thrown when
    /// attempting to verify a signature that doesn't match the expected length.
    case invalidSignatureLength

    /// The keypair does not contain a private key and cannot sign.
    ///
    /// Thrown when attempting to sign a message with a public-key-only keypair.
    /// Create the keypair from a secret seed or generate a new keypair to sign.
    case missingPrivateKey
}
