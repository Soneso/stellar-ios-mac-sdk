//
//  OZSmartAccountSignatures.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Base type for OpenZeppelin smart-account signature variants.
///
/// Smart accounts support multiple signature types for transaction authorization:
/// - `OZWebAuthnSignature` for passkey / biometric authentication signatures.
/// - `OZEd25519Signature` for traditional Ed25519 keypair signatures.
/// - `OZPolicySignature` as a marker for policy-based authorization (an empty map).
///
/// Each variant converts to the `SCValXDR` map shape that the smart-account contract
/// verifies.
///
/// Example:
/// ```swift
/// let signature = try OZWebAuthnSignature(
///     authenticatorData: authenticatorDataBytes,
///     clientData: clientDataBytes,
///     signature: signatureBytes
/// )
/// let scVal = signature.toScVal()
/// ```
public protocol OZSmartAccountSignature: Sendable {

    /// Converts this signature to its on-chain `SCValXDR` representation.
    ///
    /// The returned value is typically an `SCValXDR.map` whose keys are alphabetically
    /// sorted because the verifier contract requires that ordering. Construction-time
    /// validation may throw `ValidationException.InvalidInput`; this conversion is total.
    ///
    /// - Returns: The signature encoded as an `SCValXDR` map.
    func toScVal() -> SCValXDR
}

// ============================================================================
// OZWebAuthnSignature
// ============================================================================

/// A WebAuthn signature produced by a passkey authentication ceremony.
///
/// Carries the complete attestation data required to verify biometric or security-key
/// authentication. The signature must be in compact format (64 bytes) with a normalised
/// low-S value to avoid signature malleability.
///
/// Field ordering in the SCVal map is alphabetical and is required for contract
/// compatibility:
/// 1. `authenticator_data`
/// 2. `client_data`
/// 3. `signature`
///
/// The map key is `client_data`, not `client_data_json`.
public struct OZWebAuthnSignature: OZSmartAccountSignature, Hashable {

    /// Raw authenticator data from the WebAuthn ceremony.
    public let authenticatorData: Data

    /// Client data JSON from the WebAuthn ceremony, stored under the `client_data` map key.
    public let clientData: Data

    /// ECDSA signature in compact 64-byte format (`r || s`), already low-S normalised.
    public let signature: Data

    /// Initializes a new `OZWebAuthnSignature`.
    ///
    /// - Parameters:
    ///   - authenticatorData: Raw authenticator data bytes.
    ///   - clientData: Client data JSON bytes.
    ///   - signature: ECDSA signature in compact 64-byte format.
    /// - Throws: `ValidationException.InvalidInput` when `signature` is not exactly 64 bytes.
    public init(authenticatorData: Data, clientData: Data, signature: Data) throws {
        if signature.count != 64 {
            throw ValidationException.invalidInput(
                field: "signature",
                reason: "WebAuthn signature must be exactly 64 bytes, got \(signature.count)"
            )
        }
        self.authenticatorData = authenticatorData
        self.clientData = clientData
        self.signature = signature
    }

    /// Converts the signature to a Soroban `SCValXDR` map with alphabetically-ordered keys
    /// (`authenticator_data`, `client_data`, `signature`).
    ///
    /// - Returns: An `SCValXDR.map` with three byte-valued entries.
    public func toScVal() -> SCValXDR {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("authenticator_data"), val: .bytes(authenticatorData)),
            SCMapEntryXDR(key: .symbol("client_data"), val: .bytes(clientData)),
            SCMapEntryXDR(key: .symbol("signature"), val: .bytes(signature))
        ]
        return .map(entries)
    }

    /// Equality implemented with constant-time comparison over each byte field to avoid
    /// leaking information about the byte content through a timing side channel.
    ///
    /// The boolean per-field results are combined with bitwise `and` (rather than the
    /// short-circuiting `&&`) so a difference in one field cannot leak through the timing
    /// of the boolean reduction.
    ///
    /// - Parameters:
    ///   - lhs: First signature.
    ///   - rhs: Second signature.
    /// - Returns: `true` when all three byte fields compare equal.
    public static func == (lhs: OZWebAuthnSignature, rhs: OZWebAuthnSignature) -> Bool {
        let a = lhs.authenticatorData.constantTimeEquals(rhs.authenticatorData)
        let b = lhs.clientData.constantTimeEquals(rhs.clientData)
        let c = lhs.signature.constantTimeEquals(rhs.signature)
        return ((a ? 1 : 0) & (b ? 1 : 0) & (c ? 1 : 0)) == 1
    }

    /// Combines content-based hashes of the three byte fields into a single hash value.
    ///
    /// - Parameter hasher: Hasher to feed.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(authenticatorData)
        hasher.combine(clientData)
        hasher.combine(signature)
    }
}

// ============================================================================
// OZEd25519Signature
// ============================================================================

/// An Ed25519 signature produced by a traditional Ed25519 keypair.
///
/// Ed25519 signatures are 64 bytes and provide deterministic signing with strong
/// side-channel resistance.
///
/// Field ordering in the SCVal map is alphabetical and is required for contract
/// compatibility:
/// 1. `public_key`
/// 2. `signature`
public struct OZEd25519Signature: OZSmartAccountSignature, Hashable {

    /// Ed25519 public key (`SmartAccountConstants.ed25519PublicKeySize` bytes).
    public let publicKey: Data

    /// Ed25519 signature (64 bytes).
    public let signature: Data

    /// Initializes a new `OZEd25519Signature`.
    ///
    /// - Parameters:
    ///   - publicKey: 32-byte Ed25519 public key.
    ///   - signature: 64-byte Ed25519 signature.
    /// - Throws: `ValidationException.InvalidInput` when `publicKey` is not 32 bytes or
    ///           `signature` is not 64 bytes.
    public init(publicKey: Data, signature: Data) throws {
        if publicKey.count != SmartAccountConstants.ed25519PublicKeySize {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Ed25519 public key must be exactly \(SmartAccountConstants.ed25519PublicKeySize) bytes, got \(publicKey.count)"
            )
        }
        if signature.count != 64 {
            throw ValidationException.invalidInput(
                field: "signature",
                reason: "Ed25519 signature must be exactly 64 bytes, got \(signature.count)"
            )
        }
        self.publicKey = publicKey
        self.signature = signature
    }

    /// Converts the signature to a Soroban `SCValXDR` map with alphabetically-ordered keys
    /// (`public_key`, `signature`).
    ///
    /// - Returns: An `SCValXDR.map` with two byte-valued entries.
    public func toScVal() -> SCValXDR {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("public_key"), val: .bytes(publicKey)),
            SCMapEntryXDR(key: .symbol("signature"), val: .bytes(signature))
        ]
        return .map(entries)
    }

    /// Equality implemented with constant-time comparison over each byte field; the boolean
    /// per-field results are combined with bitwise `and` to avoid early-exit timing leaks.
    public static func == (lhs: OZEd25519Signature, rhs: OZEd25519Signature) -> Bool {
        let a = lhs.publicKey.constantTimeEquals(rhs.publicKey)
        let b = lhs.signature.constantTimeEquals(rhs.signature)
        return ((a ? 1 : 0) & (b ? 1 : 0)) == 1
    }

    /// Combines content-based hashes of both byte fields into a single hash value.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(publicKey)
        hasher.combine(signature)
    }
}

// ============================================================================
// OZPolicySignature
// ============================================================================

/// Marker signature representing policy-based authorization.
///
/// Policy signatures are encoded as empty maps and indicate that authorization should be
/// determined by the smart-account's policy evaluation (for example spending limits,
/// threshold signatures, or time-based restrictions). Use the canonical singleton instance
/// via `OZPolicySignature.instance`.
public struct OZPolicySignature: OZSmartAccountSignature, Hashable {

    /// Canonical singleton instance.
    public static let instance = OZPolicySignature()

    /// Private initializer keeps the type a singleton; obtain instances via `instance`.
    private init() {}

    /// Converts the policy signature to an empty Soroban `SCValXDR` map.
    public func toScVal() -> SCValXDR {
        return .map([])
    }
}
