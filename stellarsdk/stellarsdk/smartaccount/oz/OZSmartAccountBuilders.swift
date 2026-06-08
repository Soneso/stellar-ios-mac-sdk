//
//  OZSmartAccountBuilders.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Builder utilities for OpenZeppelin smart-account signers.
///
/// Provides type-safe constructors for creating signers and inspection helpers used by the
/// higher-level smart-account managers. Includes:
/// - Signer builders for delegated, external, WebAuthn, and Ed25519 signers.
/// - Signer inspection (type checks, type description, credential and address extraction).
/// - Signer matching (by credential ID, by address, equality).
/// - Signer deduplication.
public enum OZSmartAccountBuilders {

    // ========================================================================
    // Signer builders
    // ========================================================================

    /// Creates a delegated signer for a native Stellar account.
    ///
    /// Delegated signers use Stellar's native `require_auth()` mechanism; no external
    /// verifier contract is needed.
    ///
    /// - Parameter publicKey: Stellar account or contract address (`G…` or `C…` strkey).
    /// - Returns: An `OZDelegatedSigner` for use in context rules.
    /// - Throws: `SmartAccountValidationException.InvalidAddress` when `publicKey` is not a valid strkey.
    public static func createDelegatedSigner(publicKey: String) throws -> OZDelegatedSigner {
        return try OZDelegatedSigner(address: publicKey)
    }

    /// Creates an external signer that delegates verification to a custom contract.
    ///
    /// Used for WebAuthn passkeys, Ed25519 with custom logic, and other non-native schemes.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the signature verifier.
    ///   - keyData: Public-key bytes plus any auxiliary authentication data; must not be empty.
    /// - Returns: An `OZExternalSigner` for use in context rules.
    /// - Throws: `SmartAccountValidationException.InvalidAddress` when `verifierAddress` is not valid;
    ///           `SmartAccountValidationException.InvalidInput` when `keyData` is empty.
    public static func createExternalSigner(
        verifierAddress: String,
        keyData: Data
    ) throws -> OZExternalSigner {
        return try OZExternalSigner(verifierAddress: verifierAddress, keyData: keyData)
    }

    /// Creates a WebAuthn passkey signer.
    ///
    /// Convenience wrapper around `createExternalSigner` that handles the `keyData` format
    /// for WebAuthn (`publicKey || credentialId`).
    ///
    /// - Parameters:
    ///   - webauthnVerifierAddress: WebAuthn verifier contract address (`C…` strkey).
    ///   - publicKey: 65-byte secp256r1 uncompressed public key (`0x04` prefix + X + Y).
    ///   - credentialId: WebAuthn credential identifier bytes; must not be empty.
    /// - Returns: An `OZExternalSigner` configured for WebAuthn verification.
    /// - Throws: `SmartAccountValidationException.InvalidAddress` when the verifier address is invalid;
    ///           `SmartAccountValidationException.InvalidInput` when the public key size or shape is
    ///           wrong, or when the credential ID is empty.
    public static func createWebAuthnSigner(
        webauthnVerifierAddress: String,
        publicKey: Data,
        credentialId: Data
    ) throws -> OZExternalSigner {
        return try OZExternalSigner.webAuthn(
            verifierAddress: webauthnVerifierAddress,
            publicKey: publicKey,
            credentialId: credentialId
        )
    }

    /// Creates an Ed25519 signer that delegates verification to a custom contract.
    ///
    /// The key data is the 32-byte Ed25519 public key.
    ///
    /// - Parameters:
    ///   - ed25519VerifierAddress: Ed25519 verifier contract address (`C…` strkey).
    ///   - publicKey: 32-byte Ed25519 public key.
    /// - Returns: An `OZExternalSigner` configured for Ed25519 verification.
    /// - Throws: `SmartAccountValidationException.InvalidAddress` when the verifier address is invalid;
    ///           `SmartAccountValidationException.InvalidInput` when the public key is not 32 bytes.
    public static func createEd25519Signer(
        ed25519VerifierAddress: String,
        publicKey: Data
    ) throws -> OZExternalSigner {
        return try OZExternalSigner.ed25519(
            verifierAddress: ed25519VerifierAddress,
            publicKey: publicKey
        )
    }

    // ========================================================================
    // Signer inspection utilities
    // ========================================================================

    /// Extracts the credential ID from a WebAuthn signer's key data.
    ///
    /// WebAuthn signers store key data as: 65-byte uncompressed public key followed by the
    /// credential ID. Returns `nil` for non-WebAuthn signers (delegated signers, or
    /// external signers whose key data is not longer than 65 bytes).
    ///
    /// - Parameter signer: Signer to inspect.
    /// - Returns: Credential ID bytes, or `nil` for non-WebAuthn signers.
    public static func getCredentialIdFromSigner(signer: any OZSmartAccountSigner) -> Data? {
        guard let external = signer as? OZExternalSigner else { return nil }
        if external.keyData.count <= SmartAccountConstants.secp256r1PublicKeySize {
            return nil
        }
        let suffix = external.keyData.suffix(
            external.keyData.count - SmartAccountConstants.secp256r1PublicKeySize
        )
        return Data(suffix)
    }

    /// Returns the WebAuthn credential ID as a Base64URL-encoded string, or `nil` for
    /// non-WebAuthn signers.
    ///
    /// - Parameter signer: Signer to inspect.
    /// - Returns: Base64URL-encoded credential ID string, or `nil`.
    public static func getCredentialIdStringFromSigner(signer: any OZSmartAccountSigner) -> String? {
        guard let credentialId = getCredentialIdFromSigner(signer: signer) else { return nil }
        return credentialId.base64URLEncodedString()
    }

    public static func isDelegatedSigner(signer: any OZSmartAccountSigner) -> Bool {
        return signer is OZDelegatedSigner
    }

    public static func isExternalSigner(signer: any OZSmartAccountSigner) -> Bool {
        return signer is OZExternalSigner
    }

    // ========================================================================
    // Signer matching
    // ========================================================================

    /// Returns `true` when `signer` is a WebAuthn signer whose credential ID matches the
    /// given raw `credentialId` bytes.
    public static func signerMatchesCredential(
        signer: any OZSmartAccountSigner,
        credentialId: Data
    ) -> Bool {
        guard let signerCredId = getCredentialIdFromSigner(signer: signer) else { return false }
        return signerCredId == credentialId
    }

    /// Returns `true` when `signer` is a WebAuthn signer whose credential ID, encoded as
    /// Base64URL, equals `credentialId`.
    ///
    /// The caller-supplied `credentialId` is normalised by stripping trailing `=` padding
    /// before comparison so padded and unpadded Base64URL spellings of the same credential
    /// match. The signer-derived id is already unpadded.
    public static func signerMatchesCredentialId(
        signer: any OZSmartAccountSigner,
        credentialId: String
    ) -> Bool {
        guard let signerCredId = getCredentialIdStringFromSigner(signer: signer) else {
            return false
        }
        return signerCredId == strippedBase64URLPadding(credentialId)
    }

    /// Strips trailing `=` padding from a Base64URL-encoded string.
    ///
    /// The SDK encoder always emits unpadded output; this helper normalises caller-supplied
    /// strings so padded and unpadded spellings compare and key equal.
    static func strippedBase64URLPadding(_ value: String) -> String {
        var index = value.endIndex
        while index > value.startIndex {
            let previous = value.index(before: index)
            if value[previous] != "=" { break }
            index = previous
        }
        if index == value.endIndex { return value }
        return String(value[value.startIndex..<index])
    }

    /// Returns `true` when `signer` is an `OZDelegatedSigner` whose address equals `address`.
    public static func signerMatchesAddress(
        signer: any OZSmartAccountSigner,
        address: String
    ) -> Bool {
        guard let delegated = signer as? OZDelegatedSigner else { return false }
        return delegated.address == address
    }

    // ========================================================================
    // Signer comparison and deduplication
    // ========================================================================

    /// Compares two signers by type and field values.
    ///
    /// For delegated signers compares the address. For external signers compares the
    /// verifier address and the byte content of the key data.
    public static func signersEqual(
        _ a: any OZSmartAccountSigner,
        _ b: any OZSmartAccountSigner
    ) -> Bool {
        if let lhs = a as? OZDelegatedSigner, let rhs = b as? OZDelegatedSigner {
            return lhs.address == rhs.address
        }
        if let lhs = a as? OZExternalSigner, let rhs = b as? OZExternalSigner {
            if lhs.verifierAddress != rhs.verifierAddress { return false }
            return lhs.keyData.constantTimeEquals(rhs.keyData)
        }
        return false
    }

    /// Returns the unique-key string for `signer`. Equivalent to `signer.uniqueKey`.
    public static func getSignerKey(signer: any OZSmartAccountSigner) -> String {
        return signer.uniqueKey
    }

    /// Returns a list of unique signers preserving the first occurrence of each duplicate.
    ///
    /// Uses `getSignerKey` to determine uniqueness; subsequent duplicates are discarded.
    ///
    /// - Parameter signers: Source list (may contain duplicates).
    /// - Returns: List of unique signers in insertion order.
    public static func collectUniqueSigners(
        signers: [any OZSmartAccountSigner]
    ) -> [any OZSmartAccountSigner] {
        var seen = Set<String>()
        var result: [any OZSmartAccountSigner] = []
        for signer in signers {
            let key = getSignerKey(signer: signer)
            if seen.insert(key).inserted {
                result.append(signer)
            }
        }
        return result
    }
}
