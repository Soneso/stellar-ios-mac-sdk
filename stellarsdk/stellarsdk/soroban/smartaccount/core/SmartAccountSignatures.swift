//
//  SmartAccountSignatures.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - SmartAccountSignature Protocol

/// Protocol for smart account signature types that can be converted to Soroban SCVal format.
///
/// Smart accounts support multiple signature types for transaction authorization:
/// - WebAuthn signatures from passkeys (biometric authentication)
/// - Ed25519 signatures from traditional keypairs
/// - Policy signatures (empty, representing policy-based authorization)
///
/// Example usage:
/// ```swift
/// let signature = WebAuthnSignature(
///     authenticatorData: authenticatorData,
///     clientData: clientData,
///     signature: signatureBytes
/// )
/// let scVal = try signature.toScVal()
/// ```
public protocol SmartAccountSignature: Sendable {
    /// Converts the signature to a Soroban SCVal representation.
    ///
    /// - Returns: The signature encoded as an SCValXDR map
    /// - Throws: SmartAccountError if the signature is invalid or cannot be converted
    func toScVal() throws -> SCValXDR
}

// MARK: - WebAuthn Signature

/// WebAuthn signature from a passkey authentication ceremony.
///
/// WebAuthn signatures contain the complete attestation data required to verify
/// biometric or security key authentication. The signature is in compact format
/// (64 bytes) with normalized S value to prevent signature malleability.
///
/// Field ordering in the SCVal map is CRITICAL and must be alphabetical:
/// 1. authenticator_data
/// 2. client_data
/// 3. signature
///
/// Example:
/// ```swift
/// let webauthnSig = WebAuthnSignature(
///     authenticatorData: Data([...]),  // Raw authenticator data from WebAuthn ceremony
///     clientData: Data([...]),         // Client data JSON from WebAuthn ceremony
///     signature: Data([...])           // 64-byte compact ECDSA signature (r || s)
/// )
/// ```
public struct WebAuthnSignature: SmartAccountSignature, Sendable {
    /// Raw authenticator data from the WebAuthn authentication ceremony.
    /// Contains RP ID hash, flags, signature counter, and optional extensions.
    public let authenticatorData: Data

    /// Client data JSON from the WebAuthn ceremony.
    /// CRITICAL: This is stored as "client_data", NOT "client_data_json".
    /// Contains challenge, origin, type, and other client-side information.
    public let clientData: Data

    /// ECDSA signature in compact 64-byte format (r || s).
    /// The signature must already be normalized (S value in lower half of curve order)
    /// to prevent signature malleability attacks. This is typically handled by the
    /// WebAuthn browser API.
    public let signature: Data

    /// Creates a WebAuthn signature.
    ///
    /// - Parameters:
    ///   - authenticatorData: Raw authenticator data from WebAuthn ceremony
    ///   - clientData: Client data JSON from WebAuthn ceremony
    ///   - signature: 64-byte compact ECDSA signature (r || s), already normalized
    public init(authenticatorData: Data, clientData: Data, signature: Data) {
        self.authenticatorData = authenticatorData
        self.clientData = clientData
        self.signature = signature
    }

    /// Converts the WebAuthn signature to a Soroban SCVal map.
    ///
    /// The resulting map has keys in alphabetical order (CRITICAL for contract compatibility):
    /// ```
    /// ScVal::Map([
    ///   { Symbol("authenticator_data"), Bytes(authenticatorData) },
    ///   { Symbol("client_data"), Bytes(clientData) },
    ///   { Symbol("signature"), Bytes(signature) },
    /// ])
    /// ```
    ///
    /// - Returns: SCValXDR map with signature components
    /// - Throws: SmartAccountError.invalidInput if signature is not exactly 64 bytes
    public func toScVal() throws -> SCValXDR {
        // Validate signature length
        guard signature.count == 64 else {
            throw SmartAccountError.invalidInput(
                "WebAuthn signature must be exactly 64 bytes, got \(signature.count)"
            )
        }

        // Build map entries in ALPHABETICAL order
        // CRITICAL: Keys must be in alphabetical order for contract compatibility
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(
                key: .symbol("authenticator_data"),
                val: .bytes(authenticatorData)
            ),
            SCMapEntryXDR(
                key: .symbol("client_data"),
                val: .bytes(clientData)
            ),
            SCMapEntryXDR(
                key: .symbol("signature"),
                val: .bytes(signature)
            )
        ]

        return .map(entries)
    }
}

// MARK: - Ed25519 Signature

/// Ed25519 signature from a traditional keypair.
///
/// Ed25519 signatures are 64 bytes and provide strong security guarantees with
/// deterministic signing and built-in resistance to side-channel attacks.
///
/// Example:
/// ```swift
/// let ed25519Sig = Ed25519Signature(signature: signatureBytes)
/// let scVal = try ed25519Sig.toScVal()
/// ```
public struct Ed25519Signature: SmartAccountSignature, Sendable {
    /// Ed25519 signature bytes (64 bytes).
    /// Generated by signing a message hash with an Ed25519 private key.
    public let signature: Data

    /// Creates an Ed25519 signature.
    ///
    /// - Parameter signature: 64-byte Ed25519 signature
    public init(signature: Data) {
        self.signature = signature
    }

    /// Converts the Ed25519 signature to a Soroban SCVal map.
    ///
    /// The resulting map contains only the signature field:
    /// ```
    /// ScVal::Map([
    ///   { Symbol("signature"), Bytes(signature) },
    /// ])
    /// ```
    ///
    /// - Returns: SCValXDR map with signature bytes
    /// - Throws: SmartAccountError.invalidInput if signature is not exactly 64 bytes
    public func toScVal() throws -> SCValXDR {
        // Validate signature length
        guard signature.count == 64 else {
            throw SmartAccountError.invalidInput(
                "Ed25519 signature must be exactly 64 bytes, got \(signature.count)"
            )
        }

        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(
                key: .symbol("signature"),
                val: .bytes(signature)
            )
        ]

        return .map(entries)
    }
}

// MARK: - Policy Signature

/// Policy signature representing policy-based authorization.
///
/// Policy signatures are empty maps that indicate authorization should be
/// determined by the smart account's policy evaluation (e.g., spending limits,
/// threshold signatures, time-based restrictions).
///
/// The policy itself is responsible for validating the authorization context
/// and returning success or failure. This signature type is a marker indicating
/// that no explicit cryptographic signature is required.
///
/// Example:
/// ```swift
/// let policySig = PolicySignature()
/// let scVal = try policySig.toScVal()  // Returns empty map
/// ```
public struct PolicySignature: SmartAccountSignature, Sendable {
    /// Creates a policy signature.
    public init() {}

    /// Converts the policy signature to a Soroban SCVal map.
    ///
    /// Policy signatures are represented as empty maps:
    /// ```
    /// ScVal::Map([])
    /// ```
    ///
    /// - Returns: Empty SCValXDR map
    public func toScVal() throws -> SCValXDR {
        return .map([])
    }
}
