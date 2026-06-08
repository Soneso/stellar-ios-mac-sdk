//
//  SmartAccountConstants.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Cryptographic and protocol-level constants used by Smart Account operations.
///
/// These constants describe public-key sizes and prefix bytes for the signature schemes
/// supported by the Smart Account contracts. They are exposed as a namespace so callers
/// can reference them when constructing or validating signer key material without
/// duplicating magic numbers.
public enum SmartAccountConstants {

    /// Size in bytes of an Ed25519 public key as defined by RFC 8032.
    public static let ed25519PublicKeySize: Int = 32

    /// Size in bytes of an Ed25519 secret seed as defined by RFC 8032.
    public static let ed25519SecretSeedSize: Int = 32

    /// Size in bytes of a raw Ed25519 signature (the on-wire `BytesN<64>` payload
    /// the Ed25519 verifier contract expects).
    public static let ed25519SignatureSize: Int = 64

    /// Size in bytes of an uncompressed secp256r1 public key.
    ///
    /// Layout: 1 prefix byte (`0x04`) + 32-byte x-coordinate + 32-byte y-coordinate.
    public static let secp256r1PublicKeySize: Int = 65

    /// Uncompressed point prefix byte (`0x04`) for secp256r1 public keys, as defined in SEC 1.
    public static let uncompressedPubkeyPrefix: UInt8 = 0x04
}
