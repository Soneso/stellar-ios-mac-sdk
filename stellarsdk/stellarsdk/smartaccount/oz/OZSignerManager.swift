//
//  OZSignerManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// MARK: - OZContextRuleParser
// ============================================================================

/// Internal collaborator surface consumed by ``OZSignerManager`` when the
/// signer-by-value overload of ``OZSignerManager/removeSignerBySigner(contextRuleId:signer:selectedSigners:forceMethod:)``
/// needs to resolve a signer's on-chain numeric identifier.
///
/// The kit's context-rule manager conforms to this protocol so the signer
/// manager can fetch and parse a single rule without holding a typed reference
/// to the context-rule manager class. The protocol exists so
/// ``OZSignerManager`` can be constructed and unit-tested without instantiating
/// the full context-rule manager dependency graph.
///
/// - Important: Conformance is supplied by the kit composition root. Tests
///   stub this protocol directly with an in-line fake to validate the
///   resolution path without coupling to the real context-rule manager.
internal protocol OZContextRuleParser: AnyObject, Sendable {

    /// Returns the raw on-chain `SCValXDR` representation of a single context
    /// rule, identified by its numeric id.
    ///
    /// - Parameter contextRuleId: The numeric identifier of the rule.
    /// - Returns: The raw `SCValXDR` payload describing the rule.
    /// - Throws: ``TransactionException`` on simulation failure;
    ///   ``ValidationException`` when the rule is not found.
    func getContextRule(contextRuleId: UInt32) async throws -> SCValXDR

    /// Parses a raw context-rule `SCValXDR` into the typed
    /// ``ParsedContextRule`` representation.
    ///
    /// - Parameter scVal: The raw on-chain context-rule payload.
    /// - Returns: A typed view over the rule's signers, signer ids, policies,
    ///   policy ids, name, and expiration ledger.
    /// - Throws: ``ValidationException`` when the payload is malformed.
    func parseContextRule(_ scVal: SCValXDR) throws -> ParsedContextRule
}

// ============================================================================
// MARK: - AddPasskeySignerResult
// ============================================================================

/// Result of ``OZSignerManager/addNewPasskeySigner(contextRuleId:userName:selectedSigners:forceMethod:)``.
///
/// Carries the WebAuthn credential information from the registration ceremony
/// and the on-chain transaction outcome from adding the new passkey as a signer
/// on the smart-account contract.
public struct AddPasskeySignerResult: Sendable, Hashable {

    /// Base64URL-encoded credential identifier (no padding).
    public let credentialId: String

    /// Uncompressed secp256r1 public key (65 bytes, starting with `0x04`).
    public let publicKey: Data

    /// Outcome of the on-chain signer-addition transaction.
    public let transactionResult: TransactionResult

    /// Initializes a new ``AddPasskeySignerResult``.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier.
    ///   - publicKey: Uncompressed secp256r1 public key bytes.
    ///   - transactionResult: On-chain transaction outcome.
    public init(
        credentialId: String,
        publicKey: Data,
        transactionResult: TransactionResult
    ) {
        self.credentialId = credentialId
        self.publicKey = publicKey
        self.transactionResult = transactionResult
    }

    /// Field-by-field equality using a constant-time comparison for the
    /// `publicKey` bytes so the comparison cost does not depend on where the
    /// first differing byte sits in the buffer.
    ///
    /// - Parameters:
    ///   - lhs: The first value to compare.
    ///   - rhs: The second value to compare.
    /// - Returns: `true` when every field matches.
    public static func == (lhs: AddPasskeySignerResult, rhs: AddPasskeySignerResult) -> Bool {
        if lhs.credentialId != rhs.credentialId { return false }
        if lhs.transactionResult != rhs.transactionResult { return false }
        return AddPasskeySignerResult.constantTimeEquals(lhs.publicKey, rhs.publicKey)
    }

    /// Hashes the value using content-based hashing of the `publicKey` bytes
    /// so two values with byte-equal keys hash identically.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(credentialId)
        hasher.combine(publicKey)
        hasher.combine(transactionResult)
    }

    /// Constant-time byte comparison.
    ///
    /// Folds a length-difference flag with the XOR of every byte pair across
    /// the common prefix into a single accumulator. The comparison cost does
    /// not depend on where the first differing byte sits, which avoids leaking
    /// information about cryptographic key contents through timing
    /// measurements. The length-difference flag is a Boolean indicator (0 or
    /// 1) rather than a narrowed XOR of the lengths, which both keeps the
    /// helper trap-free for any input sizes and prevents two different-length
    /// inputs from collapsing to a zero-difference accumulator through integer
    /// overflow truncation.
    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        var diff: UInt8 = (lhs.count == rhs.count) ? 0 : 1
        let length = min(lhs.count, rhs.count)
        let lhsStart = lhs.startIndex
        let rhsStart = rhs.startIndex
        for i in 0 ..< length {
            diff |= lhs[lhsStart + i] ^ rhs[rhsStart + i]
        }
        return diff == 0
    }
}

// ============================================================================
// MARK: - OZSignerManager
// ============================================================================

/// Manager for signer operations on OpenZeppelin Smart Accounts.
///
/// `OZSignerManager` provides high-level operations for managing the signer
/// set bound to a context rule on a smart-account contract. The supported
/// signer kinds are:
///
/// - WebAuthn passkeys (secp256r1 verification through a verifier contract)
/// - Delegated signers (Stellar `G…` accounts or `C…` contract addresses
///   authorising through the host's built-in `require_auth`)
/// - Ed25519 signers (32-byte Ed25519 keys verified by a verifier contract)
///
/// Every state-changing method accepts an optional `selectedSigners`
/// parameter. When the list is empty (default) the operation uses
/// single-signer authorization through the connected passkey credential. When
/// the list is non-empty the manager routes through a multi-signer ceremony
/// coordinator that collects signatures from every listed signer and assembles
/// the final authorization payload.
///
/// The manager performs no state mutation of its own; all on-chain side
/// effects flow through the kit's transaction operations (single-signer path)
/// or the multi-signer submitter (multi-signer path).
///
/// This manager is typically accessed via the kit; constructing one directly
/// is reserved for advanced integrations and unit tests.
///
/// Example:
/// ```swift
/// let kit = try await OZSmartAccountKit.create(config: cfg)
/// let signerManager = kit.signerManager
///
/// // Add a delegated account signer to the Default context rule.
/// let result = try await signerManager.addDelegated(
///     contextRuleId: 0,
///     address: "GA7QYNF7SOWQ..."
/// )
///
/// // Add a passkey signer through multi-signer authorisation.
/// let passkeyResult = try await signerManager.addPasskey(
///     contextRuleId: 0,
///     publicKey: secp256r1PublicKey,
///     credentialId: credentialIdBytes,
///     selectedSigners: [
///         .passkey(credentialId: "AAAA", credentialIdBytes: Data([0])),
///         .wallet(accountId: "GA7Q...")
///     ]
/// )
/// ```
///
/// - Note: Thread safety — every method is `async` and may be invoked
///   concurrently. Internal state is limited to immutable properties
///   captured at initialisation time, so no synchronisation is required at
///   this layer.
public final class OZSignerManager: @unchecked Sendable {

    // MARK: - Stored properties

    /// Kit reference used to resolve the connected smart-account contract id
    /// and to delegate single-signer host-function submission through the
    /// kit's transaction operations.
    private let kit: OZSmartAccountKitProtocol

    /// Context-rule parser consulted when ``removeSignerBySigner(contextRuleId:signer:selectedSigners:forceMethod:)``
    /// needs to resolve a signer value to its on-chain numeric identifier.
    ///
    /// Optional so the manager can be constructed and unit-tested without
    /// wiring the full context-rule manager. When `nil`, calls that require
    /// the parser throw a configuration error so the misconfiguration is
    /// surfaced at the call site rather than producing a confusing runtime
    /// failure deeper in the resolution path.
    private let contextRuleParser: OZContextRuleParser?

    /// WebAuthn provider override used by ``addNewPasskeySigner(contextRuleId:userName:selectedSigners:forceMethod:)``
    /// when the caller wants to drive the registration ceremony through an
    /// adapter other than the one configured on the kit. When `nil`, the
    /// provider from the kit configuration is used.
    private let webauthnProviderOverride: WebAuthnProvider?

    /// Credential manager used by ``addNewPasskeySigner(contextRuleId:userName:selectedSigners:forceMethod:)``
    /// to persist the new credential in the `pending` deployment state. When
    /// `nil`, the credential manager exposed on the kit is used.
    ///
    /// The override exists so tests can drive the new-passkey flow without
    /// instantiating the concrete ``OZCredentialManager`` and its storage
    /// adapter dependency graph.
    private let credentialManagerOverride: OZCredentialManagerProtocol?

    // MARK: - Initialization

    /// Initializes a new ``OZSignerManager`` bound to the supplied kit.
    ///
    /// The manager is created by the kit during construction and is reachable
    /// through `kit.signerManager`. Manual instantiation is supported for
    /// advanced integrations and unit tests.
    ///
    /// - Parameters:
    ///   - kit: The smart-account kit this manager belongs to. Used to resolve
    ///     the connected contract id, the configured WebAuthn provider, the
    ///     credential manager, to delegate single-signer submission to the
    ///     kit's transaction operations, and to delegate multi-signer
    ///     submission to ``OZSmartAccountKitProtocol/multiSignerManager`` when
    ///     a caller supplies a non-empty `selectedSigners` list.
    ///   - contextRuleParser: Optional parser consulted when resolving a
    ///     signer value to its on-chain numeric id. The kit assembles the
    ///     concrete context-rule manager and supplies it here at construction
    ///     time. Pass `nil` in unit tests that exclusively cover the
    ///     id-based remove path.
    ///   - webauthnProvider: Optional WebAuthn provider override. When `nil`,
    ///     the provider configured on `kit.config.webauthnProvider` is used.
    ///   - credentialManager: Optional credential manager override. When
    ///     `nil`, `kit.credentialManager` is used.
    internal init(
        kit: OZSmartAccountKitProtocol,
        contextRuleParser: OZContextRuleParser? = nil,
        webauthnProvider: WebAuthnProvider? = nil,
        credentialManager: OZCredentialManagerProtocol? = nil
    ) {
        self.kit = kit
        self.contextRuleParser = contextRuleParser
        self.webauthnProviderOverride = webauthnProvider
        self.credentialManagerOverride = credentialManager
    }

    // MARK: - Add Signers (high-level)

    /// Registers a new WebAuthn passkey and adds it as a signer to a context
    /// rule.
    ///
    /// Performs the full end-to-end flow of creating a new passkey via the
    /// platform's WebAuthn API, persisting the credential locally as
    /// `pending`, emitting a ``SmartAccountEvent/credentialCreated(credential:)``
    /// event, and adding the resulting public key as a signer on the
    /// smart-account contract. Use ``addPasskey(contextRuleId:publicKey:credentialId:selectedSigners:forceMethod:)``
    /// directly when the credential identifier and public key are already in
    /// hand.
    ///
    /// Flow:
    /// 1. Validates that a wallet is connected and a ``WebAuthnProvider`` is
    ///    configured (either through the kit or the manager override).
    /// 2. Generates cryptographically secure random challenge and user-id
    ///    buffers (32 bytes each) using ``OZWalletOperations/secureRandomData(count:)``.
    /// 3. Triggers the platform WebAuthn registration ceremony (biometric
    ///    prompt). Failures from the provider are wrapped in
    ///    ``WebAuthnException/RegistrationFailed``.
    /// 4. Base64URL-encodes the credential id for local storage.
    /// 5. Persists the new credential through
    ///    ``OZCredentialManagerProtocol/createPendingCredential(credentialId:publicKey:contractId:nickname:transports:deviceType:backedUp:)``.
    /// 6. Emits ``SmartAccountEvent/credentialCreated(credential:)``.
    /// 7. Adds the passkey signer on-chain by delegating to
    ///    ``addPasskey(contextRuleId:publicKey:credentialId:selectedSigners:forceMethod:)``.
    ///
    /// The on-chain addition step requires authorization from an existing
    /// signer on the supplied context rule. The user is therefore prompted for
    /// biometric authentication twice in single-signer mode: once for the new
    /// passkey registration and once for the existing signer to authorize the
    /// signer-addition transaction.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the new signer is being
    ///     added to (zero is the default rule).
    ///   - userName: User-friendly name for the new passkey (displayed by the
    ///     authenticator).
    ///   - selectedSigners: Optional list of signers participating in the
    ///     on-chain authorization ceremony. Empty (default) routes through
    ///     single-signer submission with the connected passkey credential.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: An ``AddPasskeySignerResult`` carrying the credential id,
    ///   the public key, and the on-chain transaction outcome.
    /// - Throws: ``WalletException/NotConnected`` when no wallet is connected;
    ///   ``WebAuthnException/NotSupported`` when no WebAuthn provider is
    ///   configured; ``WebAuthnException`` when the registration ceremony
    ///   fails or the user cancels; ``CredentialException`` when credential
    ///   storage fails; ``TransactionException`` when the on-chain signer
    ///   addition fails.
    public func addNewPasskeySigner(
        contextRuleId: UInt32,
        userName: String,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> AddPasskeySignerResult {
        let connected = try kit.requireConnected()

        guard let webauthnProvider = webauthnProviderOverride ?? kit.config.webauthnProvider else {
            throw WebAuthnException.notSupported(
                details: "No WebAuthnProvider configured. Set webauthnProvider in config before calling addNewPasskeySigner()."
            )
        }

        // why: drawing both the WebAuthn challenge and the user-id from the
        // system CSPRNG with strict error propagation prevents a hardware
        // failure from silently producing a predictable zero buffer. The same
        // helper is used by `OZWalletOperations.createWallet` so the two
        // entry points stay aligned on the random-source policy.
        let challengeData = try OZWalletOperations.secureRandomData(count: 32)
        let userIdData = try OZWalletOperations.secureRandomData(count: 32)

        let registrationResult: WebAuthnRegistrationResult
        do {
            registrationResult = try await webauthnProvider.register(
                challenge: challengeData,
                userId: userIdData,
                userName: userName
            )
        } catch let error as WebAuthnException {
            throw error
        } catch {
            throw WebAuthnException.registrationFailed(
                reason: SmartAccountException.messageOf(error) ?? "WebAuthn registration failed",
                cause: error
            )
        }

        try Task.checkCancellation()

        let credentialIdBase64url = registrationResult.credentialId.base64URLEncodedString()

        // why: the wallet-creation flow runs registration output through
        // `SmartAccountUtils.extractPublicKeyFromRegistration` because the
        // platform WebAuthn API may return the public key in COSE or SPKI
        // form. The signer-addition flow already requires the canonical
        // uncompressed 65-byte form (the on-chain verifier signature
        // contract rejects any other shape), and the caller may have driven
        // the registration through an adapter that bypasses platform
        // extraction. Pass the raw `publicKey` bytes through unchanged here
        // so the validation in `addPasskey` surfaces the correct error if the
        // bytes are malformed.
        let credentialManager = credentialManagerOverride ?? kit.credentialManager
        let credential: StoredCredential
        do {
            credential = try await credentialManager.createPendingCredential(
                credentialId: credentialIdBase64url,
                publicKey: registrationResult.publicKey,
                contractId: connected.contractId,
                nickname: nil,
                transports: registrationResult.transports,
                deviceType: registrationResult.deviceType,
                backedUp: registrationResult.backedUp
            )
        } catch let error as CredentialException {
            throw error
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(
                key: credentialIdBase64url,
                cause: error
            )
        }

        kit.events.emit(.credentialCreated(credential: credential))

        try Task.checkCancellation()

        let transactionResult = try await addPasskey(
            contextRuleId: contextRuleId,
            publicKey: registrationResult.publicKey,
            credentialId: registrationResult.credentialId,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )

        return AddPasskeySignerResult(
            credentialId: credentialIdBase64url,
            publicKey: registrationResult.publicKey,
            transactionResult: transactionResult
        )
    }

    /// Adds a WebAuthn passkey signer to a context rule.
    ///
    /// Creates a WebAuthn external signer via ``OZExternalSigner/webAuthn(verifierAddress:publicKey:credentialId:)``
    /// and submits an `add_signer` invocation against the connected
    /// smart-account contract. The verifier address is sourced from
    /// ``OZSmartAccountConfig/webauthnVerifierAddress``.
    ///
    /// The on-chain transaction requires authorization from an existing
    /// signer on the specified context rule.
    ///
    /// Contract call: `smart_account.add_signer(context_rule_id, signer) -> u32`.
    /// The assigned numeric id surfaces on
    /// ``ParsedContextRule/signerIds`` once the rule is refetched.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the new signer is being
    ///     added to.
    ///   - publicKey: Uncompressed secp256r1 public key
    ///     (``SmartAccountConstants/secp256r1PublicKeySize`` bytes starting
    ///     with ``SmartAccountConstants/uncompressedPubkeyPrefix``).
    ///   - credentialId: WebAuthn credential identifier bytes; must not be
    ///     empty.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``ValidationException`` for invalid input;
    ///   ``WalletException`` for missing connection;
    ///   ``TransactionException`` for submission failures.
    public func addPasskey(
        contextRuleId: UInt32,
        publicKey: Data,
        credentialId: Data,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        _ = try kit.requireConnected()

        if publicKey.count != SmartAccountConstants.secp256r1PublicKeySize {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Public key must be \(SmartAccountConstants.secp256r1PublicKeySize) bytes, got: \(publicKey.count)"
            )
        }
        if publicKey[publicKey.startIndex] != SmartAccountConstants.uncompressedPubkeyPrefix {
            let firstByteHex = String(format: "%02x", publicKey[publicKey.startIndex])
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Public key must start with 0x04 (uncompressed format), got: 0x\(firstByteHex)"
            )
        }
        if credentialId.isEmpty {
            throw ValidationException.invalidInput(
                field: "credentialId",
                reason: "Credential ID cannot be empty"
            )
        }

        let signer = try OZExternalSigner.webAuthn(
            verifierAddress: kit.config.webauthnVerifierAddress,
            publicKey: publicKey,
            credentialId: credentialId
        )

        return try await addSigner(
            contextRuleId: contextRuleId,
            signer: signer,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Adds a delegated signer (Stellar account or contract) to a context
    /// rule.
    ///
    /// Creates an ``OZDelegatedSigner`` that authorises through the host's
    /// built-in `require_auth` mechanism and submits an `add_signer`
    /// invocation against the connected smart-account contract. The supplied
    /// `address` may be either a `G…` Stellar account or a `C…` contract
    /// strkey.
    ///
    /// The on-chain transaction requires authorization from an existing
    /// signer on the specified context rule.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the new signer is being
    ///     added to.
    ///   - address: Stellar account (`G…`) or contract (`C…`) strkey.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``ValidationException/InvalidAddress`` when the address
    ///   strkey is malformed; ``WalletException/NotConnected`` when no
    ///   wallet is connected; ``TransactionException`` for submission
    ///   failures.
    public func addDelegated(
        contextRuleId: UInt32,
        address: String,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        _ = try kit.requireConnected()

        let signer = try OZDelegatedSigner(address: address)

        return try await addSigner(
            contextRuleId: contextRuleId,
            signer: signer,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Adds an Ed25519 signer to a context rule.
    ///
    /// Creates an ``OZExternalSigner`` configured for Ed25519 verification via
    /// the supplied verifier-contract address and submits an `add_signer`
    /// invocation against the connected smart-account contract. The public
    /// key must be the canonical 32-byte Ed25519 encoding.
    ///
    /// The on-chain transaction requires authorization from an existing
    /// signer on the specified context rule.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the new signer is being
    ///     added to.
    ///   - verifierAddress: Verifier contract address (`C…` strkey).
    ///   - publicKey: Ed25519 public key (``SmartAccountConstants/ed25519PublicKeySize``
    ///     bytes).
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``ValidationException`` for invalid input;
    ///   ``WalletException/NotConnected`` when no wallet is connected;
    ///   ``TransactionException`` for submission failures.
    public func addEd25519(
        contextRuleId: UInt32,
        verifierAddress: String,
        publicKey: Data,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        _ = try kit.requireConnected()

        let signer = try OZExternalSigner.ed25519(
            verifierAddress: verifierAddress,
            publicKey: publicKey
        )

        return try await addSigner(
            contextRuleId: contextRuleId,
            signer: signer,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Remove Signer

    /// Removes a signer from a context rule by its on-chain numeric id.
    ///
    /// The id is assigned by the smart-account contract when the signer is
    /// added and surfaces on ``ParsedContextRule/signerIds`` after the rule
    /// is fetched. Use ``removeSignerBySigner(contextRuleId:signer:selectedSigners:forceMethod:)``
    /// when only the signer value is known — that overload performs one extra
    /// RPC round trip to resolve the id internally.
    ///
    /// - Important: A context rule cannot have its last signer removed unless
    ///   the rule has policies that supply authorization. The smart-account
    ///   contract returns error code 3004 if the last signer is removed with
    ///   no policies configured.
    ///
    /// Contract call: `smart_account.remove_signer(context_rule_id, signer_id)`.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the signer is being removed
    ///     from.
    ///   - signerId: Numeric signer identifier assigned at addition time.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException/NotConnected`` when no wallet is
    ///   connected; ``TransactionException`` for submission failures.
    public func removeSigner(
        contextRuleId: UInt32,
        signerId: UInt32,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        let hostFunction = try OZSignerManager.buildRemoveSignerFunction(
            contractId: connected.contractId,
            contextRuleId: contextRuleId,
            signerId: signerId
        )

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Removes a signer from a context rule by matching the signer value.
    ///
    /// Convenience overload that resolves the on-chain numeric signer id
    /// internally before delegating to
    /// ``removeSigner(contextRuleId:signerId:selectedSigners:forceMethod:)``.
    /// Fetches the target context rule (single RPC call), parses it through
    /// the kit's context-rule parser, locates the signer by equality, and
    /// uses the positionally-aligned identifier.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the signer is being removed
    ///     from.
    ///   - signer: The signer value to match against the rule's signer list.
    ///   - selectedSigners: Optional multi-signer participants list.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException/NotConnected`` when no wallet is
    ///   connected; ``ValidationException`` when the signer is not found on
    ///   the supplied rule or the rule's `signers` and `signerIds` arrays are
    ///   misaligned; ``ConfigurationException`` when the manager was
    ///   constructed without a context-rule parser; ``TransactionException``
    ///   for simulation, signing, or submission failures.
    ///
    /// - Note: The Swift name differs from the underlying contract method to
    ///   distinguish this overload at the call site from the id-based
    ///   ``removeSigner(contextRuleId:signerId:selectedSigners:forceMethod:)``.
    ///   Swift's argument-label-based overload resolution cannot
    ///   disambiguate `removeSigner(by: UInt32)` from
    ///   `removeSigner(by: any OZSmartAccountSigner)` without parameter
    ///   labels that name the value's shape, so the explicit suffix keeps the
    ///   call site self-documenting.
    public func removeSignerBySigner(
        contextRuleId: UInt32,
        signer: any OZSmartAccountSigner,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        _ = try kit.requireConnected()

        guard let parser = contextRuleParser else {
            // why: in production the kit always installs the context-rule
            // parser at construction time. Reaching this branch means a
            // unit-test or alternate kit composition wired the manager
            // without a parser yet still asked for value-based removal;
            // surface a configuration error so the caller can correct the
            // composition root rather than seeing a confusing parse failure
            // deeper in the resolution path.
            throw ConfigurationException.invalidConfig(
                details: "Value-based signer removal requested but no context-rule parser is wired into the signer manager"
            )
        }

        let ruleScVal = try await parser.getContextRule(contextRuleId: contextRuleId)
        let rule = try parser.parseContextRule(ruleScVal)

        guard let signerIndex = rule.signers.firstIndex(where: { existing in
            OZSmartAccountBuilders.signersEqual(existing, signer)
        }) else {
            throw ValidationException.invalidInput(
                field: "signer",
                reason: "Signer not found on context rule \(contextRuleId)"
            )
        }

        if signerIndex >= rule.signerIds.count {
            throw ValidationException.invalidInput(
                field: "signer",
                reason: "Signer found at index \(signerIndex) but signerIds has only \(rule.signerIds.count) entries"
            )
        }

        let signerId = rule.signerIds[signerIndex]
        return try await removeSigner(
            contextRuleId: contextRuleId,
            signerId: signerId,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Private helpers

    /// Internal helper that builds the `add_signer` host function and routes
    /// the submission through the appropriate code path.
    ///
    /// Used by every public `add*` method. The contract assigns a `u32`
    /// signer identifier to the newly added signer; the identifier is not
    /// included in the returned ``TransactionResult``. Callers that need the
    /// id must refetch the context rule and read
    /// ``ParsedContextRule/signerIds``.
    ///
    /// - Parameters:
    ///   - contextRuleId: Context-rule identifier the signer is being added
    ///     to.
    ///   - signer: The signer being added.
    ///   - selectedSigners: Multi-signer participants. Empty selects
    ///     single-signer routing.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException/NotConnected`` when no wallet is
    ///   connected; ``ValidationException`` when the signer cannot be
    ///   encoded; ``TransactionException`` for submission failures.
    private func addSigner(
        contextRuleId: UInt32,
        signer: any OZSmartAccountSigner,
        selectedSigners: [SelectedSigner] = [],
        forceMethod: SubmissionMethod? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        let hostFunction = try OZSignerManager.buildAddSignerFunction(
            contractId: connected.contractId,
            contextRuleId: contextRuleId,
            signer: signer
        )

        return try await routeSubmission(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    /// Routes a host-function submission to either the single-signer or the
    /// multi-signer code path based on the supplied `selectedSigners` list.
    ///
    /// When `selectedSigners` is empty, the submission is forwarded through the
    /// kit's transaction operations on the single-signer path bound to the
    /// connected passkey. When non-empty, the kit's multi-signer manager is
    /// consulted directly to coordinate signature collection across every
    /// supplied signer.
    private func routeSubmission(
        hostFunction: HostFunctionXDR,
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod?
    ) async throws -> TransactionResult {
        if selectedSigners.isEmpty {
            return try await kit.transactionOperations.submit(
                hostFunction: hostFunction,
                auth: [],
                forceMethod: forceMethod
            )
        }
        return try await kit.multiSignerManager.submitWithMultipleSigners(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }

    // MARK: - Host-function builders (internal for unit-test access)

    /// Builds the host function that invokes the smart-account contract's
    /// `add_signer` method.
    ///
    /// - Parameters:
    ///   - contractId: Smart-account contract address (`C…` strkey).
    ///   - contextRuleId: Context-rule identifier the signer is being added
    ///     to.
    ///   - signer: The signer being added; encoded via
    ///     ``OZSmartAccountSigner/toScVal()``.
    /// - Returns: The matching ``HostFunctionXDR`` ready for transaction
    ///   assembly.
    /// - Throws: ``ValidationException/InvalidInput`` when the signer cannot
    ///   be encoded; ``StellarSDKError`` when the contract id cannot be
    ///   decoded into an ``SCAddressXDR``.
    internal static func buildAddSignerFunction(
        contractId: String,
        contextRuleId: UInt32,
        signer: any OZSmartAccountSigner
    ) throws -> HostFunctionXDR {
        let contractScAddress = try SCAddressXDR(contractId: contractId)
        let signerScVal = try signer.toScVal()

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractScAddress,
            functionName: "add_signer",
            args: [
                .u32(contextRuleId),
                signerScVal
            ]
        )
        return HostFunctionXDR.invokeContract(invokeArgs)
    }

    /// Builds the host function that invokes the smart-account contract's
    /// `remove_signer` method.
    ///
    /// - Parameters:
    ///   - contractId: Smart-account contract address (`C…` strkey).
    ///   - contextRuleId: Context-rule identifier the signer is being removed
    ///     from.
    ///   - signerId: Numeric signer identifier assigned at addition time.
    /// - Returns: The matching ``HostFunctionXDR`` ready for transaction
    ///   assembly.
    /// - Throws: ``StellarSDKError`` when the contract id cannot be decoded
    ///   into an ``SCAddressXDR``.
    internal static func buildRemoveSignerFunction(
        contractId: String,
        contextRuleId: UInt32,
        signerId: UInt32
    ) throws -> HostFunctionXDR {
        let contractScAddress = try SCAddressXDR(contractId: contractId)

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: contractScAddress,
            functionName: "remove_signer",
            args: [
                .u32(contextRuleId),
                .u32(signerId)
            ]
        )
        return HostFunctionXDR.invokeContract(invokeArgs)
    }
}
