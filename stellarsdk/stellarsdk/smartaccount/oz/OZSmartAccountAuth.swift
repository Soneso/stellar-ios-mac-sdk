//
//  OZSmartAccountAuth.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// The digest that the `__check_auth` of an OpenZeppelin smart account build checks.
///
/// Every signer of one auth entry commits to the same digest. Its form depends on the code
/// the smart account runs, so the kit reads the wallet's WASM hash before each signing
/// operation and selects the scheme through ``OZSmartAccountConfig/authDigestSchemes``.
public enum OZAuthDigestScheme: String, Sendable, Hashable {

    /// The digest of stellar-accounts 0.7:
    /// `auth_digest = SHA-256(signature_payload || XDR(ScVal::Vec([ScVal::U32(id), ...])))`.
    /// Delegated signers authorize `__check_auth(Bytes(auth_digest))`.
    case legacyConcat

    /// The digest of stellar-accounts 0.8.0: `auth_digest = SHA-256(XDR(AuthDigestPreimage))`,
    /// where `AuthDigestPreimage` is the `ScVal::Map` with the Symbol keys `account` (the smart
    /// account address), `context_rule_ids` (`Vec` of `U32`) and `signature_payload`
    /// (32 `Bytes`). Delegated signers authorize `__check_auth(AuthDigestPreimage)`.
    case preimageV1
}

/// The digest material every signer of one smart account auth entry commits to, as
/// ``OZSmartAccountAuth/computeEntryAuthDigest(entry:expirationLedger:networkPassphrase:contextRuleIds:scheme:)``
/// returns it.
public struct OZEntryAuthDigest: Sendable {

    /// The 32-byte payload the host passes to `__check_auth`.
    public let signaturePayload: Data

    /// The 32-byte digest that External signers (passkeys, Ed25519 keys) sign.
    public let authDigest: Data

    /// The `__check_auth` arguments that Delegated signers authorize.
    public let delegatedAuthArgs: [SCValXDR]
}

/// Authentication helpers for OpenZeppelin smart-account authorization entries.
///
/// Provides functions to attach signatures to authorisation entries and to build the
/// payload hashes and digests that signers must commit to. The helpers cover:
/// - Computing the auth digest that binds context rule IDs to a signature payload, in the
///   ``OZAuthDigestScheme`` of the code the smart account runs:
///   `SHA-256(signaturePayload || contextRuleIds.toXDR())` for stellar-accounts 0.7 and
///   `SHA-256(XDR(AuthDigestPreimage))` for stellar-accounts 0.8.0
///   (``computeEntryAuthDigest(entry:expirationLedger:networkPassphrase:contextRuleIds:scheme:)``).
/// - Building the authorisation payload hash for both address and source-account credentials.
/// - Attaching pre-computed signatures to authorisation entries while preserving any
///   existing signatures and ordering map entries deterministically.
/// - Adding raw signature map entries (used for delegated-signer placeholders).
///
/// Example:
/// ```swift
/// // Compute the digest the wallet's code checks (the WebAuthn challenge).
/// let digest = try await OZSmartAccountAuth.computeEntryAuthDigest(
///     entry: unsignedEntry,
///     expirationLedger: currentLedger + 100,
///     networkPassphrase: Network.testnet.passphrase,
///     contextRuleIds: [0],
///     scheme: .preimageV1
/// )
/// // ... compute the signature over `digest.authDigest` externally ...
/// let signedEntry = try await OZSmartAccountAuth.signAuthEntry(
///     entry: unsignedEntry,
///     signer: webAuthnSigner,
///     signature: webAuthnSignature,
///     expirationLedger: currentLedger + 100,
///     contextRuleIds: [0]
/// )
/// ```
public enum OZSmartAccountAuth {

    /// Size in bytes of the signature payload the host passes to `__check_auth`.
    private static let signaturePayloadSize = 32

    // ========================================================================
    // Payload hash building
    // ========================================================================

    /// Computes the stellar-accounts 0.7 auth digest, ``OZAuthDigestScheme/legacyConcat`` only.
    ///
    /// The digest is `SHA-256(signaturePayload || contextRuleIds.toXDR())` where
    /// `contextRuleIds.toXDR()` is the XDR encoding of `ScVal::Vec([ScVal::U32(id), ...])`.
    /// Binding the rule IDs into the digest prevents replay of a signed payload against a
    /// different rule set. A wallet on stellar-accounts 0.8.0 checks the
    /// ``OZAuthDigestScheme/preimageV1`` digest instead, which this function cannot produce.
    ///
    /// - Parameters:
    ///   - signaturePayload: 32-byte signature payload hash from `buildAuthPayloadHash`.
    ///   - contextRuleIds: Context rule IDs to bind into the digest.
    /// - Returns: 32-byte SHA-256 auth digest.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when XDR encoding fails.
    @available(*, deprecated, message: "Computes the stellar-accounts 0.7 digest only. Use computeEntryAuthDigest with the OZAuthDigestScheme of the code the wallet runs.")
    public static func buildAuthDigest(
        signaturePayload: Data,
        contextRuleIds: [UInt32]
    ) async throws -> Data {
        return try legacyAuthDigest(signaturePayload: signaturePayload, contextRuleIds: contextRuleIds)
    }

    /// Computes the signature payload, the auth digest and the delegated `__check_auth`
    /// arguments of a smart account auth entry for `scheme`.
    ///
    /// The signature payload is
    /// ``buildAuthPayloadHash(entry:expirationLedger:networkPassphrase:)`` of the entry. With
    /// ``OZAuthDigestScheme/legacyConcat`` the digest is
    /// `SHA-256(signature_payload || XDR(ScVal::Vec([ScVal::U32(id), ...])))` and Delegated
    /// signers authorize `Bytes(auth_digest)`. With ``OZAuthDigestScheme/preimageV1`` the digest
    /// is `SHA-256(XDR(AuthDigestPreimage))`, the preimage binding the entry's credential address
    /// as the smart account, and Delegated signers authorize the preimage itself.
    ///
    /// The scheme must be the one the wallet's `__check_auth` checks. A signature over the
    /// other digest is rejected by the contract when the transaction is simulated or submitted,
    /// after every signer has signed, and nothing executes.
    ///
    /// Example:
    /// ```swift
    /// let digest = try await OZSmartAccountAuth.computeEntryAuthDigest(
    ///     entry: authEntry,
    ///     expirationLedger: currentLedger + 100,
    ///     networkPassphrase: Network.testnet.passphrase,
    ///     contextRuleIds: [0],
    ///     scheme: .preimageV1
    /// )
    /// // digest.authDigest is the WebAuthn challenge and the message an Ed25519 signer signs.
    /// ```
    ///
    /// - Parameters:
    ///   - entry: The smart account authorization entry. Must carry address credentials
    ///     (`ADDRESS`, `ADDRESS_V2` or `ADDRESS_WITH_DELEGATES`).
    ///   - expirationLedger: Ledger number at which the signatures expire.
    ///   - networkPassphrase: Network passphrase.
    ///   - contextRuleIds: Context rule IDs the signatures satisfy, one per auth context.
    ///   - scheme: Digest scheme of the code the smart account runs.
    /// - Returns: The signature payload, the auth digest and the delegated `__check_auth`
    ///   arguments.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when the credentials are not
    ///   an address type, when their address is a muxed account (M...) or muxed contract (W...)
    ///   address, or when XDR encoding fails.
    public static func computeEntryAuthDigest(
        entry: SorobanAuthorizationEntryXDR,
        expirationLedger: UInt32,
        networkPassphrase: String,
        contextRuleIds: [UInt32],
        scheme: OZAuthDigestScheme
    ) async throws -> OZEntryAuthDigest {
        let signaturePayload = try await buildAuthPayloadHash(
            entry: entry,
            expirationLedger: expirationLedger,
            networkPassphrase: networkPassphrase
        )
        switch scheme {
        case .legacyConcat:
            let authDigest = try legacyAuthDigest(
                signaturePayload: signaturePayload,
                contextRuleIds: contextRuleIds
            )
            return OZEntryAuthDigest(
                signaturePayload: signaturePayload,
                authDigest: authDigest,
                delegatedAuthArgs: [.bytes(authDigest)]
            )
        case .preimageV1:
            // buildAuthPayloadHash has already refused credentials without an address.
            let account = entry.credentials.addressCredentials!.address
            let preimage = try buildAuthDigestPreimage(
                account: account,
                signaturePayload: signaturePayload,
                contextRuleIds: contextRuleIds
            )
            return OZEntryAuthDigest(
                signaturePayload: signaturePayload,
                authDigest: try encodeScVal(preimage, description: "AuthDigestPreimage").sha256Hash,
                delegatedAuthArgs: [preimage]
            )
        }
    }

    /// Encodes the `AuthDigestPreimage` contract struct of stellar-accounts 0.8.0: an
    /// `ScVal::Map` with the Symbol keys in name order, `account`, `context_rule_ids` and
    /// `signature_payload`.
    ///
    /// - Parameters:
    ///   - account: The smart account performing the authorization check.
    ///   - signaturePayload: The 32-byte payload the host passes to `__check_auth`.
    ///   - contextRuleIds: The context rule IDs, one per auth context.
    /// - Returns: The preimage as an `ScVal::Map`.
    /// - Throws: `SmartAccountValidationException.InvalidInput` when `signaturePayload` is not
    ///   32 bytes.
    internal static func buildAuthDigestPreimage(
        account: SCAddressXDR,
        signaturePayload: Data,
        contextRuleIds: [UInt32]
    ) throws -> SCValXDR {
        guard signaturePayload.count == signaturePayloadSize else {
            throw SmartAccountValidationException.invalidInput(
                field: "signaturePayload",
                reason: "Signature payload must be \(signaturePayloadSize) bytes, got \(signaturePayload.count)"
            )
        }
        return .map([
            SCMapEntryXDR(key: .symbol("account"), val: .address(account)),
            SCMapEntryXDR(key: .symbol("context_rule_ids"), val: .vec(contextRuleIds.map { SCValXDR.u32($0) })),
            SCMapEntryXDR(key: .symbol("signature_payload"), val: .bytes(signaturePayload))
        ])
    }

    /// Computes `SHA-256(signaturePayload || XDR(ScVal::Vec([ScVal::U32(id), ...])))`.
    ///
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when XDR encoding fails.
    private static func legacyAuthDigest(
        signaturePayload: Data,
        contextRuleIds: [UInt32]
    ) throws -> Data {
        let ruleIdsScVal: SCValXDR = .vec(contextRuleIds.map { SCValXDR.u32($0) })
        let ruleIdsXdr = try encodeScVal(ruleIdsScVal, description: "context rule IDs ScVal")

        var concatenated = Data(capacity: signaturePayload.count + ruleIdsXdr.count)
        concatenated.append(signaturePayload)
        concatenated.append(ruleIdsXdr)
        return concatenated.sha256Hash
    }

    /// XDR-encodes `value`.
    ///
    /// - Throws: `SmartAccountTransactionException.SigningFailed` naming `description` when XDR
    ///   encoding fails.
    private static func encodeScVal(_ value: SCValXDR, description: String) throws -> Data {
        do {
            return Data(try XDREncoder.encode(value))
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR encode \(description)",
                cause: error
            )
        }
    }

    /// Builds the authorisation payload hash for signing.
    ///
    /// Computes the hash that must be signed to authorise a Soroban operation; the hash is
    /// used as the WebAuthn challenge when collecting biometric signatures. All three
    /// address-credential arms are supported (`ADDRESS`, `ADDRESS_V2`,
    /// `ADDRESS_WITH_DELEGATES`). The preimage is built via
    /// `SorobanAuthorizationEntryXDR.buildPreimage(network:)`, which selects
    /// `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION` for the legacy `ADDRESS` arm and
    /// `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS` (protocol 27) for the V2 and
    /// WITH_DELEGATES arms.
    ///
    /// The returned value is `SHA-256(XDR_encode(preimage))`.
    ///
    /// - Parameters:
    ///   - entry: Authorisation entry to build the payload hash for. Must have address credentials.
    ///   - expirationLedger: Ledger number at which the signature expires; stamped into a
    ///     temporary copy of the credentials before the preimage is built.
    ///   - networkPassphrase: Network passphrase.
    /// - Returns: 32-byte SHA-256 hash of the authorisation payload.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when credentials are not an
    ///           address type, when their address is a muxed account (M...) or muxed contract
    ///           (W...) address, or when XDR encoding fails.
    public static func buildAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        expirationLedger: UInt32,
        networkPassphrase: String
    ) async throws -> Data {
        guard var creds = entry.credentials.addressCredentials else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Credentials must be of an address type to build auth payload hash"
            )
        }
        if let refusal = try muxedCredentialAddressRefusal(creds.address) {
            throw SmartAccountTransactionException.signingFailed(reason: refusal)
        }
        // Stamp the expiration into a temporary copy so the preimage reflects the
        // final expiration value without mutating the caller's entry.
        creds.signatureExpirationLedger = expirationLedger
        var stampedEntry = entry
        do {
            stampedEntry.credentials = try entry.credentials.withAddressCredentials(creds)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to stamp expiration ledger into credentials",
                cause: error
            )
        }

        return try await hashAuthPreimage(
            entry: stampedEntry,
            networkPassphrase: networkPassphrase
        )
    }

    /// Builds the authorisation payload hash for source-account credentials.
    ///
    /// Used when converting source-account (`Void`) credentials to fresh address
    /// credentials, typically for relayer fee sponsoring.
    ///
    /// `useUpgradedAuth` selects the credential arm of the replacement credentials, and
    /// with it the preimage: `true` (the default) hashes the address-bound
    /// `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS` preimage built from `address`,
    /// `nonce` and `expirationLedger` combined with the entry's root invocation; `false`
    /// hashes the legacy `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION` preimage, which carries
    /// no address.
    ///
    /// The host reconstructs the preimage from the submitted credentials, so `address`
    /// must be the address carried by the credentials the resulting signature is attached
    /// to, and `useUpgradedAuth` must match their arm.
    ///
    /// - Parameters:
    ///   - entry: Authorisation entry whose root invocation is bound into the preimage.
    ///   - address: Address carried by the new address credentials.
    ///   - nonce: Nonce to use for the new address credentials.
    ///   - expirationLedger: Ledger number at which the signature expires.
    ///   - networkPassphrase: Network passphrase.
    ///   - useUpgradedAuth: `true` (the default) for `ADDRESS_V2` replacement credentials,
    ///     `false` for the legacy `ADDRESS` arm.
    /// - Returns: 32-byte SHA-256 hash of the authorisation payload.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when `address` is a muxed
    ///           account (M...) or muxed contract (W...) address or when XDR encoding fails.
    public static func buildSourceAccountAuthPayloadHash(
        entry: SorobanAuthorizationEntryXDR,
        address: SCAddressXDR,
        nonce: Int64,
        expirationLedger: UInt32,
        networkPassphrase: String,
        useUpgradedAuth: Bool = true
    ) async throws -> Data {
        if let refusal = try muxedCredentialAddressRefusal(address) {
            throw SmartAccountTransactionException.signingFailed(reason: refusal)
        }
        // Build a temporary entry in the arm the replacement credentials will carry so
        // buildPreimage derives the matching preimage from the same fields.
        let tempCreds = SorobanAddressCredentialsXDR(
            address: address,
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            signature: .void
        )
        let credentials: SorobanCredentialsXDR = useUpgradedAuth
            ? .addressV2(tempCreds)
            : .address(tempCreds)
        let tempEntry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: entry.rootInvocation
        )
        return try await hashAuthPreimage(
            entry: tempEntry,
            networkPassphrase: networkPassphrase
        )
    }

    // ========================================================================
    // Entry signing
    // ========================================================================

    /// Attaches a pre-computed signature to an authorisation entry without mutating the input.
    ///
    /// Does not perform cryptographic signing; the caller must compute the signature over
    /// the `authDigest` that
    /// ``computeEntryAuthDigest(entry:expirationLedger:networkPassphrase:contextRuleIds:scheme:)``
    /// returns for the same `expirationLedger` and `contextRuleIds`.
    /// When `contextRuleIds` is non-empty it overrides any existing context-rule IDs in the
    /// payload; otherwise the existing value is preserved.
    ///
    /// - Parameters:
    ///   - entry: Authorisation entry to attach the signature to.
    ///   - signer: Smart-account signer (delegated or external).
    ///   - signature: Pre-computed signature object (WebAuthn, Ed25519, or Policy).
    ///   - expirationLedger: Ledger number at which the signature expires (must match the
    ///                       value used when computing the auth digest).
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

        guard var credentialsCopy = entryCopy.credentials.addressCredentials else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Credentials must be of an address type to sign auth entry"
            )
        }

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

        credentialsCopy.signatureExpirationLedger = expirationLedger
        credentialsCopy.signature = payloadScVal

        let updatedEntryCredentials: SorobanCredentialsXDR
        do {
            updatedEntryCredentials = try entryCopy.credentials.withAddressCredentials(credentialsCopy)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to write back updated credentials",
                cause: error
            )
        }
        return SorobanAuthorizationEntryXDR(
            credentials: updatedEntryCredentials,
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
        guard var credentials = entry.credentials.addressCredentials else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Credentials must be of an address type to add signature map entry"
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
        credentials.signature = payloadScVal

        let updatedEntryCredentials: SorobanCredentialsXDR
        do {
            updatedEntryCredentials = try entry.credentials.withAddressCredentials(credentials)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to write back updated credentials",
                cause: error
            )
        }
        return SorobanAuthorizationEntryXDR(
            credentials: updatedEntryCredentials,
            rootInvocation: entry.rootInvocation
        )
    }

    // ========================================================================
    // Helper functions
    // ========================================================================

    /// Hashes the Soroban authorisation preimage for `entry`.
    ///
    /// Delegates preimage construction to `SorobanAuthorizationEntryXDR.buildPreimage(network:)`,
    /// which selects the correct envelope type from the credential arm:
    /// `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION` for `ADDRESS`; and
    /// `ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS` for `ADDRESS_V2` and
    /// `ADDRESS_WITH_DELEGATES`. Returns `SHA-256(XDR_encode(preimage))`.
    ///
    /// The credentials in `entry` must already carry the final `signatureExpirationLedger`
    /// value before this method is called.
    private static func hashAuthPreimage(
        entry: SorobanAuthorizationEntryXDR,
        networkPassphrase: String
    ) async throws -> Data {
        let network = Network.custom(passphrase: networkPassphrase)
        let preimage: HashIDPreimageXDR
        do {
            preimage = try entry.buildPreimage(network: network)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to build auth preimage",
                cause: error
            )
        }

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
