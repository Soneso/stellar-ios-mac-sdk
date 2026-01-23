//
//  SmartAccountTypes.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Signer Types

/// Type of smart account signer.
public enum SmartAccountSignerType: Sendable {
    /// Delegated signer using built-in require_auth_for_args verification.
    case delegated
    /// External signer using a verifier contract for signature validation.
    case external
}

/// Protocol for smart account signers that can authorize transactions.
///
/// Smart account signers define who can authorize transactions on a smart account.
/// Two types exist:
/// - Delegated: A Soroban address (G or C) using built-in require_auth verification
/// - External: A verifier contract + public key bytes for custom signature validation
///
/// Example usage:
/// ```swift
/// // Create a delegated signer
/// let delegatedSigner = try DelegatedSigner(address: "GA7Q...")
///
/// // Create a WebAuthn signer
/// let webAuthnSigner = try ExternalSigner.webAuthn(
///     verifierAddress: "CBCD...",
///     publicKey: publicKeyData,
///     credentialId: credentialIdData
/// )
///
/// // Convert to on-chain representation
/// let scVal = try delegatedSigner.toScVal()
/// ```
public protocol SmartAccountSigner: Sendable {
    /// Converts the signer to its on-chain SCVal representation.
    ///
    /// - Returns: The SCVal representation of this signer
    /// - Throws: SmartAccountError if conversion fails
    func toScVal() throws -> SCValXDR

    /// The type of this signer (delegated or external).
    var signerType: SmartAccountSignerType { get }
}

/// A delegated signer using a Soroban address with built-in require_auth verification.
///
/// Delegated signers are Stellar accounts (G-address) or smart contracts (C-address)
/// that use the native Soroban authorization mechanism. The smart account will call
/// `require_auth_for_args()` on the address to verify authorization.
///
/// Example:
/// ```swift
/// // Account signer
/// let accountSigner = try DelegatedSigner(address: "GA7QYNF7SOWQ...")
///
/// // Contract signer
/// let contractSigner = try DelegatedSigner(address: "CBCD1234...")
/// ```
public struct DelegatedSigner: SmartAccountSigner, Sendable {
    /// The Stellar address of the signer (G-address for accounts, C-address for contracts).
    public let address: String

    /// Creates a new delegated signer.
    ///
    /// - Parameter address: A Stellar address starting with 'G' (account) or 'C' (contract)
    /// - Throws: SmartAccountError.invalidAddress if the address format is invalid
    public init(address: String) throws {
        guard address.hasPrefix("G") || address.hasPrefix("C") else {
            throw SmartAccountError.invalidAddress("Address must start with 'G' (account) or 'C' (contract), got: \(address)")
        }

        guard address.count == 56 else {
            throw SmartAccountError.invalidAddress("Address must be 56 characters long, got: \(address.count)")
        }

        self.address = address
    }

    /// Converts the delegated signer to its on-chain representation.
    ///
    /// Returns: `ScVal::Vec([Symbol("Delegated"), Address(address)])`
    ///
    /// - Returns: The SCVal representation
    /// - Throws: SmartAccountError if conversion fails
    public func toScVal() throws -> SCValXDR {
        let scAddress: SCAddressXDR

        if address.hasPrefix("G") {
            scAddress = try SCAddressXDR(accountId: address)
        } else {
            scAddress = try SCAddressXDR(contractId: address)
        }

        let elements: [SCValXDR] = [
            .symbol("Delegated"),
            .address(scAddress)
        ]

        return .vec(elements)
    }

    /// The type of this signer.
    public var signerType: SmartAccountSignerType {
        .delegated
    }
}

/// An external signer using a verifier contract for custom signature validation.
///
/// External signers delegate signature verification to a Soroban contract. The verifier
/// contract receives the public key data and signature, and returns whether the signature
/// is valid. This enables support for non-native signature schemes like WebAuthn (secp256r1)
/// and Ed25519.
///
/// The verifier contract address must be a C-address, and the key data contains the public
/// key bytes plus any additional authentication data (like WebAuthn credential IDs).
///
/// Example:
/// ```swift
/// // WebAuthn signer
/// let webAuthnSigner = try ExternalSigner.webAuthn(
///     verifierAddress: "CBCD1234...",
///     publicKey: secp256r1PublicKey,
///     credentialId: webAuthnCredentialId
/// )
///
/// // Ed25519 signer
/// let ed25519Signer = try ExternalSigner.ed25519(
///     verifierAddress: "CDEF5678...",
///     publicKey: ed25519PublicKey
/// )
/// ```
public struct ExternalSigner: SmartAccountSigner, Sendable {
    /// The contract address of the signature verifier (C-address).
    public let verifierAddress: String

    /// The public key data and any additional authentication data.
    ///
    /// For WebAuthn signers: 65-byte uncompressed secp256r1 public key + credential ID bytes
    /// For Ed25519 signers: 32-byte Ed25519 public key
    public let keyData: Data

    /// Creates a new external signer.
    ///
    /// - Parameters:
    ///   - verifierAddress: The contract address of the verifier (must start with 'C')
    ///   - keyData: The public key data and authentication information
    /// - Throws: SmartAccountError if validation fails
    public init(verifierAddress: String, keyData: Data) throws {
        guard verifierAddress.hasPrefix("C") else {
            throw SmartAccountError.invalidAddress("Verifier address must start with 'C' (contract), got: \(verifierAddress)")
        }

        guard verifierAddress.count == 56 else {
            throw SmartAccountError.invalidAddress("Verifier address must be 56 characters long, got: \(verifierAddress.count)")
        }

        guard !keyData.isEmpty else {
            throw SmartAccountError.invalidInput("Key data cannot be empty")
        }

        self.verifierAddress = verifierAddress
        self.keyData = keyData
    }

    /// Converts the external signer to its on-chain representation.
    ///
    /// Returns: `ScVal::Vec([Symbol("External"), Address(verifier), Bytes(keyData)])`
    ///
    /// - Returns: The SCVal representation
    /// - Throws: SmartAccountError if conversion fails
    public func toScVal() throws -> SCValXDR {
        let scAddress = try SCAddressXDR(contractId: verifierAddress)

        let elements: [SCValXDR] = [
            .symbol("External"),
            .address(scAddress),
            .bytes(keyData)
        ]

        return .vec(elements)
    }

    /// The type of this signer.
    public var signerType: SmartAccountSignerType {
        .external
    }

    // MARK: - Factory Methods

    /// Creates a WebAuthn external signer with secp256r1 signature verification.
    ///
    /// WebAuthn signers use an uncompressed secp256r1 public key (65 bytes starting with 0x04)
    /// combined with a WebAuthn credential ID for authentication.
    ///
    /// - Parameters:
    ///   - verifierAddress: The contract address of the WebAuthn verifier
    ///   - publicKey: The uncompressed secp256r1 public key (65 bytes, starting with 0x04)
    ///   - credentialId: The WebAuthn credential identifier
    /// - Returns: An external signer configured for WebAuthn verification
    /// - Throws: SmartAccountError if validation fails
    public static func webAuthn(
        verifierAddress: String,
        publicKey: Data,
        credentialId: Data
    ) throws -> ExternalSigner {
        guard publicKey.count == SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE else {
            throw SmartAccountError.invalidInput(
                "WebAuthn public key must be \(SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE) bytes (uncompressed secp256r1), got: \(publicKey.count)"
            )
        }

        guard publicKey.first == SmartAccountConstants.UNCOMPRESSED_PUBKEY_PREFIX else {
            throw SmartAccountError.invalidInput(
                "WebAuthn public key must start with 0x04 (uncompressed format), got: 0x\(String(format: "%02x", publicKey.first ?? 0))"
            )
        }

        guard !credentialId.isEmpty else {
            throw SmartAccountError.invalidInput("WebAuthn credential ID cannot be empty")
        }

        // Combine public key + credential ID
        var keyData = Data()
        keyData.append(publicKey)
        keyData.append(credentialId)

        return try ExternalSigner(verifierAddress: verifierAddress, keyData: keyData)
    }

    /// Creates an Ed25519 external signer.
    ///
    /// Ed25519 signers use a 32-byte Ed25519 public key for signature verification.
    ///
    /// - Parameters:
    ///   - verifierAddress: The contract address of the Ed25519 verifier
    ///   - publicKey: The Ed25519 public key (32 bytes)
    /// - Returns: An external signer configured for Ed25519 verification
    /// - Throws: SmartAccountError if validation fails
    public static func ed25519(
        verifierAddress: String,
        publicKey: Data
    ) throws -> ExternalSigner {
        let expectedSize = 32
        guard publicKey.count == expectedSize else {
            throw SmartAccountError.invalidInput(
                "Ed25519 public key must be \(expectedSize) bytes, got: \(publicKey.count)"
            )
        }

        return try ExternalSigner(verifierAddress: verifierAddress, keyData: publicKey)
    }
}

// MARK: - Signature Types
// (To be added in a separate task)
