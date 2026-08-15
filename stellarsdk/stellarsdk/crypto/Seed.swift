//
//  Seed.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/01/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation
import ed25519C

/// Represents a Stellar Ed25519 seed used for key generation.
///
/// A seed is a 32-byte value used to generate Ed25519 keypairs for Stellar accounts.
/// The seed is the private component from which both the private and public keys are derived.
///
/// Seeds can be:
/// - Generated randomly for new accounts
/// - Derived from BIP-39 mnemonics for hierarchical deterministic wallets
/// - Created from existing secret seeds (S-address format)
///
/// Security considerations:
/// - Seeds must be stored securely (use iOS Keychain or equivalent)
/// - Never expose seeds in logs, network requests, or version control
/// - Seeds encoded as secret seeds start with 'S' and are base32-encoded
public final class Seed: Sendable {
    private let buffer: [UInt8]

    /// Internal initializer that skips validation.
    ///
    /// - Parameter bytes: The seed bytes (assumed to be 32 bytes)
    init(unchecked bytes: [UInt8]) {
        self.buffer = bytes
    }

    /// Creates a seed from the provided bytes.
    ///
    /// - Parameter bytes: The seed bytes (must be exactly 32 bytes)
    ///
    /// - Throws: Ed25519Error.invalidSeedLength if bytes.count != 32
    public init(bytes: [UInt8]) throws {
        guard bytes.count == StellarProtocolConstants.ED25519_SEED_SIZE else {
            throw Ed25519Error.invalidSeedLength
        }
        
        buffer = bytes
    }

    /// Generates a new random seed using cryptographically secure random number generation.
    ///
    /// This creates a 32-byte seed suitable for generating a new Stellar account.
    /// The seed is generated using the ed25519C library's secure random function.
    ///
    /// - Throws: Ed25519Error.seedGenerationFailed if random generation fails
    ///
    /// Example:
    /// ```swift
    /// let seed = try Seed()
    /// let keyPair = KeyPair(seed: seed)
    /// ```
    public convenience init() throws {
        var buffer = [UInt8](repeating: 0, count: StellarProtocolConstants.ED25519_SEED_SIZE)

        let result = buffer.withUnsafeMutableBufferPointer {
            ed25519_create_seed($0.baseAddress)
        }

        guard result == 0 else {
            throw Ed25519Error.seedGenerationFailed
        }

        self.init(unchecked: buffer)
    }

    /// Creates a seed from a Stellar secret seed string (S-address).
    ///
    /// The secret must be a strkey encoded ed25519 secret seed ("S..."): canonical base32
    /// carrying the ed25519 secret seed version byte and a matching CRC-16 checksum. The
    /// checksum is verified, so a corrupted secret is rejected.
    ///
    /// - Parameter secret: A Stellar secret seed string (e.g., "SXXX...")
    ///
    /// - Throws:
    ///   - Ed25519Error.invalidSeed if the secret is not a well formed strkey encoded ed25519 secret seed
    ///
    /// Example:
    /// ```swift
    /// let seed = try Seed(secret: "SAVZ4FJLGPUXPN4EPLWJBLZW3FZSHH2GQJA6KPB47BQZBZJ7XHVI32D7")
    /// ```
    public convenience init(secret: String) throws {
        let decoded: Data
        do {
            decoded = try secret.decodeEd25519SecretSeed()
        } catch is KeyUtilsError {
            throw Ed25519Error.invalidSeed
        }

        try self.init(bytes: [UInt8](decoded))
    }

    /// The raw seed bytes (32 bytes).
    public var bytes: [UInt8] {
        return buffer
    }

    /// The Stellar secret seed string (S-address) representation of this seed.
    ///
    /// Returns the base32-encoded strkey format with version byte and checksum.
    /// This is the format used for storing and transmitting secret seeds.
    ///
    /// Security warning: This value grants full control over the associated account.
    /// Store it securely and never expose it publicly.
    public var secret: String {
        get {
            var versionByte = VersionByte.ed25519SecretSeed.rawValue
            let versionByteData = Data(bytes: &versionByte, count: MemoryLayout.size(ofValue: versionByte))
            var payload = Data(versionByteData)
            payload.append(Data(bytes))
            let checksumedData = payload.crc16Data()

            return checksumedData.base32EncodedString
        }
    }
}
