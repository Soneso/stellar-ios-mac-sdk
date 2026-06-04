//
//  OZSmartAccountAuth.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import CommonCrypto

/// Authentication helpers for OpenZeppelin smart-account authorization entries.
///
/// Provides functions to attach signatures to authorisation entries and to build the
/// payload hashes that signers must commit to. The helpers cover:
/// - Computing the auth digest that binds context rule IDs to a signature payload.
/// - Building the authorisation payload hash for both address and source-account credentials.
/// - Attaching pre-computed signatures to authorisation entries while preserving any
///   existing signatures and ordering map entries deterministically.
/// - Adding raw signature map entries (used for delegated-signer placeholders).
///
/// Example:
/// ```swift
/// let payloadHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
///     entry: unsignedEntry,
///     expirationLedger: currentLedger + 100,
///     networkPassphrase: Network.testnet.passphrase
/// )
/// // ... compute the signature over `payloadHash` externally ...
/// let signedEntry = try await OZSmartAccountAuth.signAuthEntry(
///     entry: unsignedEntry,
///     signer: webAuthnSigner,
///     signature: webAuthnSignature,
///     expirationLedger: currentLedger + 100
/// )
/// ```
public enum OZSmartAccountAuth {

    // ========================================================================
    // Payload hash building
    // ========================================================================

    /// Computes the auth digest that binds context rule IDs to the signature payload.
    ///
    /// The digest is `SHA-256(signaturePayload || contextRuleIds.toXDR())` where
    /// `contextRuleIds.toXDR()` is the XDR encoding of `ScVal::Vec([ScVal::U32(id), ...])`.
    /// Binding the rule IDs into the digest prevents replay of a signed payload against a
    /// different rule set.
    ///
    /// - Parameters:
    ///   - signaturePayload: 32-byte signature payload hash from `buildAuthPayloadHash`.
    ///   - contextRuleIds: Context rule IDs to bind into the digest.
    /// - Returns: 32-byte SHA-256 auth digest.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when XDR encoding fails.
    public static func buildAuthDigest(
        signaturePayload: Data,
        contextRuleIds: [UInt32]
    ) async throws -> Data {
        let ruleIdsScVal: SCValXDR = .vec(contextRuleIds.map { SCValXDR.u32($0) })

        let ruleIdsXdr: Data
        do {
            let encoded = try XDREncoder.encode(ruleIdsScVal)
            ruleIdsXdr = Data(encoded)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR encode context rule IDs ScVal",
                cause: error
            )
        }

        var concatenated = Data(capacity: signaturePayload.count + ruleIdsXdr.count)
        concatenated.append(signaturePayload)
        concatenated.append(ruleIdsXdr)
        return concatenated.sha256Hash
    }

    /// Builds the authorisation payload hash for signing.
    ///
    /// Computes the hash that must be signed to authorise a Soroban operation; the hash is
    /// used as the WebAuthn challenge when collecting biometric signatures. The entry must
    /// have address credentials.
    ///
    /// The preimage is constructed as
    /// `HashIDPreimage::SorobanAuthorization { networkId, nonce, signatureExpirationLedger,
    /// invocation }` and the returned value is `SHA-256(XDR_encode(preimage))`.
    ///
    /// - Parameters:
    ///   - entry: Authorisation entry to build the payload hash for.
    ///   - expirationLedger: Ledger number at which the signature expires.
    ///   - networkPassphrase: Network passphrase.
    /// - Returns: 32-byte SHA-256 hash of the authorisation payload.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when credentials are not address
    ///           type or when XDR encoding fails.
    public static func buildAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) async throws -> Data {
        guard case .address(let credentials) = entry.credentials else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Credentials must be of type address to build auth payload hash"
            )
        }
        return try await hashAuthPreimage(
            nonce: credentials.nonce,
            expirationLedger: expirationLedger,
            invocation: entry.rootInvocation,
            networkPassphrase: networkPassphrase
        )
    }

    /// Builds the authorisation payload hash for source-account credentials.
    ///
    /// Used when converting source-account credentials to address credentials, typically
    /// for relayer fee sponsoring. The preimage is constructed identically to
    /// `buildAuthPayloadHash` but uses the supplied `nonce` and `expirationLedger` instead
    /// of reading them from existing credentials.
    ///
    /// - Parameters:
    ///   - entry: Authorisation entry whose root invocation is bound into the preimage.
    ///   - nonce: Nonce to use for the new address credentials.
    ///   - expirationLedger: Ledger number at which the signature expires.
    ///   - networkPassphrase: Network passphrase.
    /// - Returns: 32-byte SHA-256 hash of the authorisation payload.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when XDR encoding fails.
    public static func buildSourceAccountAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        nonce: Int64,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) async throws -> Data {
        return try await hashAuthPreimage(
            nonce: nonce,
            expirationLedger: expirationLedger,
            invocation: entry.rootInvocation,
            networkPassphrase: networkPassphrase
        )
    }

    // ========================================================================
    // Entry signing
    // ========================================================================

    /// Attaches a pre-computed signature to an authorisation entry without mutating the input.
    ///
    /// Does not perform cryptographic signing; the caller must compute the signature over
    /// the hash returned by `buildAuthPayloadHash` using the same `expirationLedger`.
    /// When `contextRuleIds` is non-empty it overrides any existing context-rule IDs in the
    /// payload; otherwise the existing value is preserved.
    ///
    /// - Parameters:
    ///   - entry: Authorisation entry to attach the signature to.
    ///   - signer: Smart-account signer (delegated or external).
    ///   - signature: Pre-computed signature object (WebAuthn, Ed25519, or Policy).
    ///   - expirationLedger: Ledger number at which the signature expires (must match the
    ///                       value used when computing the payload hash).
    ///   - contextRuleIds: Optional override for the bound context rule IDs.
    /// - Returns: A new authorisation entry with the signature attached.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when credentials are not address type,
    ///           when the XDR clone fails, or when encoding the signer or signature fails.
    public static func signAuthEntry(
        entry: SorobanAuthorizationEntryXDR,
        signer: any OZSmartAccountSigner,
        signature: any OZSmartAccountSignature,
        expirationLedger: UInt32,
        contextRuleIds: [UInt32] = []
    ) async throws -> SorobanAuthorizationEntryXDR {
        // Clone via XDR round-trip so the caller's instance is never mutated.
        let entryBytes: [UInt8]
        do {
            entryBytes = try XDREncoder.encode(entry)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR encode authorization entry for cloning",
                cause: error
            )
        }

        let entryCopy: SorobanAuthorizationEntryXDR
        do {
            entryCopy = try XDRDecoder.decode(SorobanAuthorizationEntryXDR.self, data: entryBytes)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR decode authorization entry after cloning",
                cause: error
            )
        }

        guard case .address(let credentialsCopy) = entryCopy.credentials else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Credentials must be of type address to sign auth entry"
            )
        }

        let signerKey: SCValXDR
        do {
            signerKey = try signer.toScVal()
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to convert signer to SCVal",
                cause: error
            )
        }
        _ = signerKey

        let sigXdrBytes: Data
        do {
            sigXdrBytes = try signature.toAuthPayloadBytes()
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to encode signature bytes for auth payload",
                cause: error
            )
        }

        let existingPayload = try OZSmartAccountAuthPayloadCodec.read(credentialsCopy.signature)

        let updatedRuleIds = contextRuleIds.isEmpty
            ? existingPayload.contextRuleIds
            : contextRuleIds
        let updatedPayload = OZSmartAccountAuthPayload(
            signers: existingPayload.signers,
            contextRuleIds: updatedRuleIds
        )
        OZSmartAccountAuthPayloadCodec.upsertSigner(
            payload: updatedPayload,
            signer: signer,
            signatureBytes: sigXdrBytes
        )

        let payloadScVal = try OZSmartAccountAuthPayloadCodec.write(updatedPayload)

        let updatedCredentials = SorobanAddressCredentialsXDR(
            address: credentialsCopy.address,
            nonce: credentialsCopy.nonce,
            signatureExpirationLedger: expirationLedger,
            signature: payloadScVal
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(updatedCredentials),
            rootInvocation: entryCopy.rootInvocation
        )
    }

    // ========================================================================
    // Signature map manipulation
    // ========================================================================

    /// Adds a raw key/value entry to the auth entry's signature map.
    ///
    /// Used for delegated-signer placeholders where the value is `Bytes` (often empty).
    /// Uses the AuthPayload format accepted by the OpenZeppelin Smart Account contract.
    ///
    /// When `signatureValue` is an `SCValXDR.bytes` value its raw bytes are stored
    /// directly; otherwise the value is XDR-encoded and the resulting bytes are stored.
    /// The input entry is never mutated; a new entry with the updated payload is returned.
    ///
    /// - Parameters:
    ///   - entry: Authorisation entry to modify.
    ///   - signerKey: Signer-key ScVal (map key).
    ///   - signatureValue: Raw ScVal value to attach.
    ///   - contextRuleIds: Optional override for the bound context rule IDs.
    /// - Returns: A new authorisation entry with the map entry added.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when credentials are not address
    ///           type or when XDR encoding of the signature value fails.
    public static func addRawSignatureMapEntry(
        entry: SorobanAuthorizationEntryXDR,
        signerKey: SCValXDR,
        signatureValue: SCValXDR,
        contextRuleIds: [UInt32] = []
    ) throws -> SorobanAuthorizationEntryXDR {
        guard case .address(let credentials) = entry.credentials else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Credentials must be of type address to add signature map entry"
            )
        }

        let existingPayload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)

        let updatedRuleIds = contextRuleIds.isEmpty
            ? existingPayload.contextRuleIds
            : contextRuleIds
        let updatedPayload = OZSmartAccountAuthPayload(
            signers: existingPayload.signers,
            contextRuleIds: updatedRuleIds
        )

        let sigBytes: Data
        if case .bytes(let raw) = signatureValue {
            sigBytes = raw
        } else {
            do {
                sigBytes = Data(try XDREncoder.encode(signatureValue))
            } catch {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Failed to XDR-encode raw signature value",
                    cause: error
                )
            }
        }

        let signer = try OZSmartAccountAuthPayloadCodec.signerFromScVal(signerKey)
        OZSmartAccountAuthPayloadCodec.upsertSigner(
            payload: updatedPayload,
            signer: signer,
            signatureBytes: sigBytes
        )

        let payloadScVal = try OZSmartAccountAuthPayloadCodec.write(updatedPayload)

        let updatedCredentials = SorobanAddressCredentialsXDR(
            address: credentials.address,
            nonce: credentials.nonce,
            signatureExpirationLedger: credentials.signatureExpirationLedger,
            signature: payloadScVal
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(updatedCredentials),
            rootInvocation: entry.rootInvocation
        )
    }

    // ========================================================================
    // Helper functions
    // ========================================================================

    /// Hashes a Soroban authorisation preimage.
    ///
    /// Constructs `HashIDPreimage::SorobanAuthorization` from the given parameters,
    /// XDR-encodes it, and returns `SHA-256(encoded bytes)`. Used by both
    /// `buildAuthPayloadHash` and `buildSourceAccountAuthPayloadHash`.
    private static func hashAuthPreimage(
        nonce: Int64,
        expirationLedger: UInt32,
        invocation: SorobanAuthorizedInvocationXDR,
        networkPassphrase: String
    ) async throws -> Data {
        let networkIdBytes = networkPassphrase.sha256Hash

        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(
            networkID: HashXDR(networkIdBytes),
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            invocation: invocation
        )
        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)

        let encodedPreimage: Data
        do {
            encodedPreimage = Data(try XDREncoder.encode(preimage))
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR encode auth payload preimage",
                cause: error
            )
        }
        return encodedPreimage.sha256Hash
    }
}
