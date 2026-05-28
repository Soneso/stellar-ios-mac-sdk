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
/// Each variant converts to the `SCValXDR` representation expected by the on-chain
/// verifier contract. The shape differs per variant:
/// - WebAuthn: `SCValXDR.map` with alphabetically-ordered keys.
/// - Ed25519: `SCValXDR.bytes` containing the raw 64-byte signature.
/// - Policy: `SCValXDR.map([])` (empty map).
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
    /// Construction-time validation may throw `ValidationException.InvalidInput`;
    /// this conversion is total (non-throwing).
    ///
    /// - Returns: The signature encoded as an `SCValXDR` value. The concrete type
    ///   depends on the variant (map for WebAuthn/Policy, bytes for Ed25519).
    func toScVal() -> SCValXDR

    /// Returns the raw bytes content that is stored inside the `ScVal::Bytes` value of the
    /// smart account's on-chain `AuthPayload.signers: Map<Signer, Bytes>`.
    ///
    /// The exact content is verifier-dependent:
    /// - **WebAuthn**: XDR-encoded `WebAuthnSigData` contracttype struct. The WebAuthn
    ///   verifier receives this as `sig_data: Bytes` and deserializes it to `WebAuthnSigData`.
    /// - **Ed25519**: the raw 64-byte Ed25519 signature with no XDR wrapper. The Ed25519
    ///   verifier receives `sig_data: BytesN<64>` and the host coerces `Bytes(64)` to
    ///   `BytesN<64>` directly. Wrapping in an XDR envelope inflates the content to ~70 bytes,
    ///   which the coercion rejects with `InvalidAction`.
    /// - **Policy**: XDR-encoded empty map (same byte sequence as `toScVal()` encoded).
    ///
    /// - Throws: `TransactionException.SigningFailed` if XDR encoding fails (WebAuthn/Policy).
    func toAuthPayloadBytes() throws -> Data
}

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

    /// ECDSA signature in compact 64-byte format (r || s), low-S normalised.
    public let signature: Data

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

    /// See ``OZSmartAccountSignature/toAuthPayloadBytes()`` for the per-variant byte format.
    ///
    /// - Throws: `TransactionException.SigningFailed` if XDR encoding fails.
    public func toAuthPayloadBytes() throws -> Data {
        do {
            return Data(try XDREncoder.encode(toScVal()))
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to XDR encode WebAuthn signature for auth payload",
                cause: error
            )
        }
    }

    /// Uses constant-time byte comparison via `Data.constantTimeEquals` — see that extension for the timing-attack rationale.
    public static func == (lhs: OZWebAuthnSignature, rhs: OZWebAuthnSignature) -> Bool {
        let a = lhs.authenticatorData.constantTimeEquals(rhs.authenticatorData)
        let b = lhs.clientData.constantTimeEquals(rhs.clientData)
        let c = lhs.signature.constantTimeEquals(rhs.signature)
        return ((a ? 1 : 0) & (b ? 1 : 0) & (c ? 1 : 0)) == 1
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(authenticatorData)
        hasher.combine(clientData)
        hasher.combine(signature)
    }
}

/// An Ed25519 signature produced by a traditional Ed25519 keypair.
///
/// Ed25519 signatures are 64 bytes and provide deterministic signing with strong
/// side-channel resistance.
///
/// The `publicKey` field is retained on this struct for local signature verification
/// inside the multi-signer pipeline before submission. It is **not** transmitted in
/// the auth payload: the OZ Ed25519 verifier contract looks up the public key from
/// the on-chain `External(verifier, key_data)` signer storage. Only the raw 64-byte
/// signature is placed in the payload.
public struct OZEd25519Signature: OZSmartAccountSignature, Hashable {

    /// Ed25519 public key (`SmartAccountConstants.ed25519PublicKeySize` bytes).
    ///
    /// Used for local pre-submission signature verification only. Not transmitted
    /// in the auth payload.
    public let publicKey: Data

    /// Ed25519 signature (64 bytes).
    public let signature: Data

    /// Initializes a new `OZEd25519Signature`.
    ///
    /// - Parameters:
    ///   - publicKey: 32-byte Ed25519 public key (used for local verification only).
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

    /// Returns the raw 64-byte Ed25519 signature as `SCValXDR.bytes`.
    ///
    /// The OZ Ed25519 verifier contract expects `BytesN<64>` directly as the per-signer
    /// `sig_data` in the `AuthPayload.signers` map. The public key is supplied separately
    /// by the smart account contract from its on-chain `External(verifier, key_data)`
    /// storage and is NOT transmitted in the auth payload.
    ///
    /// - Returns: `SCValXDR.bytes(signature)` — the raw 64-byte signature.
    public func toScVal() -> SCValXDR {
        return .bytes(signature)
    }

    /// See ``OZSmartAccountSignature/toAuthPayloadBytes()`` for the per-variant byte format.
    ///
    /// - Returns: The raw 64-byte `signature` field.
    public func toAuthPayloadBytes() throws -> Data {
        return signature
    }

    /// Uses constant-time byte comparison via `Data.constantTimeEquals` — see that extension for the timing-attack rationale.
    public static func == (lhs: OZEd25519Signature, rhs: OZEd25519Signature) -> Bool {
        let a = lhs.publicKey.constantTimeEquals(rhs.publicKey)
        let b = lhs.signature.constantTimeEquals(rhs.signature)
        return ((a ? 1 : 0) & (b ? 1 : 0)) == 1
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(publicKey)
        hasher.combine(signature)
    }
}

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

    /// See ``OZSmartAccountSignature/toAuthPayloadBytes()`` for the per-variant byte format.
    ///
    /// - Throws: `TransactionException.SigningFailed` if XDR encoding fails.
    public func toAuthPayloadBytes() throws -> Data {
        do {
            return Data(try XDREncoder.encode(toScVal()))
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to XDR encode policy signature for auth payload",
                cause: error
            )
        }
    }
}
