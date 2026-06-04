//
//  OZWalletOperations.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security

/// Result of creating a new smart account wallet.
///
/// Carries the credential identifier, the derived contract address, the
/// uncompressed secp256r1 public key, the signed deploy transaction envelope
/// (always populated — the deploy transaction is built and signed regardless of
/// `autoSubmit`), and the transaction hash when auto-submitted.
public struct CreateWalletResult: Sendable, Hashable {

    /// Base64URL-encoded WebAuthn credential identifier.
    public let credentialId: String

    /// Smart account contract address (`C…` strkey).
    public let contractId: String

    /// Uncompressed secp256r1 public key (65 bytes starting with `0x04`).
    public let publicKey: Data

    /// Base64-encoded signed deploy transaction envelope. Always populated.
    public let signedTransactionXdr: String

    /// Transaction hash assigned at submission time. `nil` when `autoSubmit`
    /// was `false`.
    public let transactionHash: String?

    /// User display name supplied during wallet creation.
    public let nickname: String?

    public init(
        credentialId: String,
        contractId: String,
        publicKey: Data,
        signedTransactionXdr: String,
        transactionHash: String? = nil,
        nickname: String? = nil
    ) {
        self.credentialId = credentialId
        self.contractId = contractId
        self.publicKey = publicKey
        self.signedTransactionXdr = signedTransactionXdr
        self.transactionHash = transactionHash
        self.nickname = nickname
    }

    /// Equality compares every field. The `publicKey` field is compared in
    /// constant time so byte-level timing inference is not possible from
    /// equality side channels.
    public static func == (lhs: CreateWalletResult, rhs: CreateWalletResult) -> Bool {
        guard lhs.credentialId == rhs.credentialId else { return false }
        guard lhs.contractId == rhs.contractId else { return false }
        guard lhs.publicKey.constantTimeEquals(rhs.publicKey) else { return false }
        guard lhs.signedTransactionXdr == rhs.signedTransactionXdr else { return false }
        guard lhs.transactionHash == rhs.transactionHash else { return false }
        guard lhs.nickname == rhs.nickname else { return false }
        return true
    }

    /// Combines every field into the supplied hasher. The `publicKey` field is
    /// hashed by raw byte content so two results with byte-equal public keys
    /// produce the same hash value (matching the constant-time `==` contract).
    public func hash(into hasher: inout Hasher) {
        hasher.combine(credentialId)
        hasher.combine(contractId)
        hasher.combine(publicKey)
        hasher.combine(signedTransactionXdr)
        hasher.combine(transactionHash)
        hasher.combine(nickname)
    }

    public func copy(
        credentialId: String? = nil,
        contractId: String? = nil,
        publicKey: Data? = nil,
        signedTransactionXdr: String? = nil,
        transactionHash: String?? = .none,
        nickname: String?? = .none
    ) -> CreateWalletResult {
        let resolvedHash: String?
        switch transactionHash {
        case .none: resolvedHash = self.transactionHash
        case .some(let value): resolvedHash = value
        }
        let resolvedNickname: String?
        switch nickname {
        case .none: resolvedNickname = self.nickname
        case .some(let value): resolvedNickname = value
        }
        return CreateWalletResult(
            credentialId: credentialId ?? self.credentialId,
            contractId: contractId ?? self.contractId,
            publicKey: publicKey ?? self.publicKey,
            signedTransactionXdr: signedTransactionXdr ?? self.signedTransactionXdr,
            transactionHash: resolvedHash,
            nickname: resolvedNickname
        )
    }
}

/// Result of deploying a pending credential when retrying a failed or deferred wallet deployment.
public struct DeployPendingResult: Sendable, Equatable, Hashable {

    /// Smart account contract address (`C…` strkey).
    public let contractId: String

    /// Base64-encoded signed deploy transaction envelope.
    public let signedTransactionXdr: String

    /// Transaction hash assigned at submission time. `nil` when `autoSubmit`
    /// was `false`.
    public let transactionHash: String?

    public init(
        contractId: String,
        signedTransactionXdr: String,
        transactionHash: String? = nil
    ) {
        self.contractId = contractId
        self.signedTransactionXdr = signedTransactionXdr
        self.transactionHash = transactionHash
    }

    public func copy(
        contractId: String? = nil,
        signedTransactionXdr: String? = nil,
        transactionHash: String?? = .none
    ) -> DeployPendingResult {
        let resolvedHash: String?
        switch transactionHash {
        case .none: resolvedHash = self.transactionHash
        case .some(let value): resolvedHash = value
        }
        return DeployPendingResult(
            contractId: contractId ?? self.contractId,
            signedTransactionXdr: signedTransactionXdr ?? self.signedTransactionXdr,
            transactionHash: resolvedHash
        )
    }
}

/// Outcome of a connect-wallet operation.
///
/// `connectWallet(options:)` returns one of three results:
/// - `nil` — no valid session and `prompt` was `false`. The caller should show
///   a login UI.
/// - ``ConnectWalletResult/connected(credentialId:contractId:restoredFromSession:)``
///   — a single contract was resolved for the credential. The kit's connected
///   state has been set and the session has been saved.
/// - ``ConnectWalletResult/ambiguous(credentialId:candidates:)`` — the indexer
///   reported multiple contracts where the passkey is registered. The kit's
///   connected state has NOT been set; the caller must let the user pick a
///   candidate and re-call `connectWallet(options:)` with the chosen contract id.
public enum ConnectWalletResult: Sendable, Equatable, Hashable {

    /// A single contract was resolved for the credential.
    case connected(credentialId: String, contractId: String, restoredFromSession: Bool)

    /// The indexer returned more than one contract for the credential. The
    /// caller must let the user pick a candidate.
    case ambiguous(credentialId: String, candidates: [String])

    /// Base64URL-encoded credential identifier carried by both arms.
    public var credentialId: String {
        switch self {
        case .connected(let credentialId, _, _): return credentialId
        case .ambiguous(let credentialId, _): return credentialId
        }
    }
}

/// Result of standalone passkey authentication, typically used with the indexer to
/// discover deployed contracts before calling `connectWallet(options:)`.
public struct AuthenticatePasskeyResult: Sendable, Hashable {

    /// Base64URL-encoded credential identifier.
    public let credentialId: String

    /// Normalised WebAuthn signature produced during the ceremony.
    public let signature: OZWebAuthnSignature

    /// Stored secp256r1 public key (65 bytes) when the credential is present in
    /// local storage. Empty `Data` otherwise — callers can resolve the key
    /// through the indexer or on-chain context rules when needed.
    public let publicKey: Data

    public init(
        credentialId: String,
        signature: OZWebAuthnSignature,
        publicKey: Data
    ) {
        self.credentialId = credentialId
        self.signature = signature
        self.publicKey = publicKey
    }

    /// Equality compares every field. The `publicKey` field is compared in
    /// constant time.
    public static func == (lhs: AuthenticatePasskeyResult, rhs: AuthenticatePasskeyResult) -> Bool {
        guard lhs.credentialId == rhs.credentialId else { return false }
        guard lhs.signature == rhs.signature else { return false }
        guard lhs.publicKey.constantTimeEquals(rhs.publicKey) else { return false }
        return true
    }

    /// Combines every field into the supplied hasher. The `publicKey` field is
    /// hashed by raw byte content so two results with byte-equal public keys
    /// produce the same hash value (matching the constant-time `==` contract).
    public func hash(into hasher: inout Hasher) {
        hasher.combine(credentialId)
        hasher.combine(signature)
        hasher.combine(publicKey)
    }
}

/// Options controlling how ``OZWalletOperations/connectWallet(options:)`` resolves the credential and contract.
///
/// All fields default to permissive values so a zero-argument call performs a
/// silent session check.
///
/// | Configuration | Behaviour |
/// | --- | --- |
/// | (default) | Restore session if valid; return `nil` otherwise. |
/// | `credentialId` and/or `contractId` | Direct connect, skip the session check. |
/// | `fresh = true` | Skip the session, always trigger WebAuthn. |
/// | `prompt = true` | Restore session if valid, trigger WebAuthn otherwise. |
/// | `fresh = true, prompt = true` | `fresh` takes priority; always WebAuthn. |
public struct ConnectWalletOptions: Sendable, Equatable, Hashable {

    /// Connect directly using this credential identifier (Base64URL-encoded).
    /// When provided alone, the contract address is resolved via the
    /// storage → derivation → indexer cascade.
    public let credentialId: String?

    /// Connect directly to this contract address (`C…` strkey). Must be used
    /// with ``credentialId``.
    public let contractId: String?

    /// Force fresh WebAuthn authentication, skipping the session-restore step.
    public let fresh: Bool

    /// When `true`, trigger WebAuthn authentication if no valid session exists.
    /// When `false` (default), `connectWallet` returns `nil` when no session
    /// can be restored.
    public let prompt: Bool

    public init(
        credentialId: String? = nil,
        contractId: String? = nil,
        fresh: Bool = false,
        prompt: Bool = false
    ) {
        self.credentialId = credentialId
        self.contractId = contractId
        self.fresh = fresh
        self.prompt = prompt
    }

    /// Returns a copy with the supplied fields replaced. Parameters left as their
    /// default sentinel (`.none`) preserve the current field value; pass an explicit
    /// value (including `nil`) to override.
    public func copy(
        credentialId: String?? = .none,
        contractId: String?? = .none,
        fresh: Bool? = nil,
        prompt: Bool? = nil
    ) -> ConnectWalletOptions {
        let resolvedCred: String?
        switch credentialId {
        case .none: resolvedCred = self.credentialId
        case .some(let value): resolvedCred = value
        }
        let resolvedContract: String?
        switch contractId {
        case .none: resolvedContract = self.contractId
        case .some(let value): resolvedContract = value
        }
        return ConnectWalletOptions(
            credentialId: resolvedCred,
            contractId: resolvedContract,
            fresh: fresh ?? self.fresh,
            prompt: prompt ?? self.prompt
        )
    }
}

/// Wallet-lifecycle operations for OpenZeppelin Smart Accounts.
///
/// Handles wallet creation (WebAuthn registration + deterministic contract
/// derivation + deploy-transaction build and submission), wallet connection
/// (session restore, storage → derivation → indexer cascade, ambiguous-multi-
/// contract handling), standalone passkey authentication, and retry of a
/// previously deferred or failed deployment.
///
/// Instances are constructed by ``OZSmartAccountKit`` and accessed through
/// `kit.walletOperations`.
public final class OZWalletOperations: OZRpcHelpers, @unchecked Sendable {

    // MARK: - Stored properties

    let kit: OZSmartAccountKitProtocol

    // MARK: - Initialization

    /// Internal initializer; instances are constructed by `OZSmartAccountKit`.
    internal init(kit: OZSmartAccountKitProtocol) {
        self.kit = kit
    }

    /// Shortcut to the kit's credential manager.
    private var credentialManager: OZCredentialManagerProtocol {
        return kit.credentialManager
    }

    /// Creates a new smart-account wallet backed by a fresh WebAuthn credential.
    ///
    /// Registers a passkey, derives the deterministic contract address, builds
    /// and signs the deploy transaction, and optionally submits it. The signed
    /// deploy XDR is always present in the result for deferred submission.
    ///
    /// - Parameters:
    ///   - userName: Display name persisted with the credential.
    ///   - autoSubmit: When `true`, submits the deploy transaction immediately
    ///     (default `false`). The `signedTransactionXdr` field of the result
    ///     carries the signed envelope for later external submission regardless.
    ///   - autoFund: Fund the freshly deployed wallet via Friendbot (testnet
    ///     only). Requires `autoSubmit = true` and `nativeTokenContract != nil`.
    ///   - nativeTokenContract: Native token (XLM SAC) contract address used
    ///     when `autoFund = true`.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: ``CreateWalletResult`` describing the new wallet.
    /// - Throws: ``WebAuthnException``, ``ValidationException``,
    ///   ``TransactionException``, ``CredentialException``, ``StorageException``.
    public func createWallet(
        userName: String = "Smart Account User",
        autoSubmit: Bool = false,
        autoFund: Bool = false,
        nativeTokenContract: String? = nil,
        forceMethod: SubmissionMethod? = nil
    ) async throws -> CreateWalletResult {
        guard let webauthnProvider = kit.config.webauthnProvider else {
            throw WebAuthnException.notSupported(
                details: "No WebAuthnProvider configured. Set webauthnProvider in config before calling createWallet()."
            )
        }

        // Validate autoFund's nativeTokenContract requirement before any side effect.
        if autoFund && nativeTokenContract == nil {
            throw ValidationException.invalidInput(
                field: "nativeTokenContract",
                reason: "nativeTokenContract is required when autoFund is true"
            )
        }

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

        let publicKey: Data
        do {
            publicKey = try SmartAccountUtils.extractPublicKeyFromRegistration(
                publicKey: registrationResult.publicKey,
                attestationObject: registrationResult.attestationObject
            )
        } catch let error as ValidationException {
            throw error
        } catch {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Failed to extract public key from registration: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let deployer = try await kit.getDeployer()
        let contractId: String
        do {
            contractId = try SmartAccountUtils.deriveContractAddress(
                credentialId: registrationResult.credentialId,
                deployerPublicKey: deployer.accountId,
                networkPassphrase: kit.config.networkPassphrase
            )
        } catch let error as ValidationException {
            throw error
        } catch let error as TransactionException {
            throw error
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to derive contract address: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let credentialIdBase64url = registrationResult.credentialId.base64URLEncodedString()

        let credential: StoredCredential
        do {
            credential = try await credentialManager.createPendingCredential(
                credentialId: credentialIdBase64url,
                publicKey: publicKey,
                contractId: contractId,
                nickname: userName,
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

        do {
            try await credentialManager.setPrimary(credentialId: credentialIdBase64url)
        } catch {
            // best-effort; primary tracking is metadata only
        }

        kit.events.emit(.credentialCreated(credential: credential))
        kit.setConnectedState(
            credentialId: credentialIdBase64url,
            contractId: contractId
        )
        kit.events.emit(
            .walletConnected(
                contractId: contractId,
                credentialId: credentialIdBase64url
            )
        )
        try await saveSession(
            credentialId: credentialIdBase64url,
            contractId: contractId
        )

        let built = try await buildCreateContractTransaction(
            publicKey: publicKey,
            credentialId: registrationResult.credentialId,
            credentialIdBase64url: credentialIdBase64url,
            forceMethod: forceMethod
        )

        var transactionHash: String? = nil
        if autoSubmit {
            transactionHash = try await signAndSubmitDeploy(
                deployTransaction: built.transaction,
                credentialIdBase64url: credentialIdBase64url,
                autoFund: autoFund,
                nativeTokenContract: nativeTokenContract,
                forceMethod: forceMethod
            )
        }

        return CreateWalletResult(
            credentialId: credentialIdBase64url,
            contractId: contractId,
            publicKey: publicKey,
            signedTransactionXdr: built.envelopeXdr,
            transactionHash: transactionHash,
            nickname: userName
        )
    }

    /// Output of ``buildCreateContractTransaction(publicKey:credentialId:credentialIdBase64url:forceMethod:)``.
    /// Carries the built `Transaction` and its serialised envelope XDR so the
    /// caller can submit directly or hand the XDR back to an off-line client.
    private struct BuiltDeploy {
        let transaction: Transaction
        let envelopeXdr: String
    }

    /// Builds the deploy transaction, captures its envelope XDR, and marks the
    /// pending credential as failed when the build raises an error.
    ///
    /// - Parameters:
    ///   - publicKey: 65-byte uncompressed secp256r1 public key extracted from
    ///     the WebAuthn registration.
    ///   - credentialId: Raw credential identifier (not Base64URL encoded).
    ///   - credentialIdBase64url: Base64URL-encoded credential identifier used
    ///     for credential-manager bookkeeping.
    ///   - forceMethod: Optional submission-method override forwarded to the
    ///     underlying build helper.
    /// - Returns: ``BuiltDeploy`` carrying both the built `Transaction` and its
    ///   serialised envelope XDR.
    /// - Throws: ``TransactionException``, ``WebAuthnException``,
    ///   ``ValidationException``.
    private func buildCreateContractTransaction(
        publicKey: Data,
        credentialId: Data,
        credentialIdBase64url: String,
        forceMethod: SubmissionMethod?
    ) async throws -> BuiltDeploy {
        let deployTransaction: Transaction
        do {
            deployTransaction = try await buildDeployTransaction(
                publicKey: publicKey,
                credentialId: credentialId,
                forceMethod: forceMethod
            )
        } catch {
            await markDeploymentFailedSafely(
                credentialId: credentialIdBase64url,
                error: SmartAccountException.messageOf(error) ?? "Build failed"
            )
            if let smartError = error as? SmartAccountException {
                throw smartError
            }
            throw TransactionException.submissionFailed(
                reason: "Failed to build deploy transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
        let envelopeXdr: String
        do {
            envelopeXdr = try deployTransaction.encodedEnvelope()
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to encode envelope: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
        return BuiltDeploy(transaction: deployTransaction, envelopeXdr: envelopeXdr)
    }

    /// Submits the previously-built deploy transaction, optionally funds the
    /// freshly deployed wallet, and best-effort deletes the transitional
    /// credential after a confirmed deployment.
    ///
    /// - Parameters:
    ///   - deployTransaction: Built and signed deploy transaction.
    ///   - credentialIdBase64url: Base64URL-encoded credential identifier for
    ///     credential-manager bookkeeping.
    ///   - autoFund: Whether to fund the wallet via Friendbot after the deploy
    ///     confirms.
    ///   - nativeTokenContract: SAC contract used by the funding flow.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: Stellar transaction hash returned by the submission path.
    /// - Throws: ``TransactionException``, ``ValidationException``,
    ///   ``WebAuthnException``.
    private func signAndSubmitDeploy(
        deployTransaction: Transaction,
        credentialIdBase64url: String,
        autoFund: Bool,
        nativeTokenContract: String?,
        forceMethod: SubmissionMethod?
    ) async throws -> String {
        let transactionHash = try await submitDeployTransaction(
            transaction: deployTransaction,
            credentialIdBase64url: credentialIdBase64url,
            forceMethod: forceMethod
        )

        if autoFund {
            guard let tokenContract = nativeTokenContract else {
                throw ValidationException.invalidInput(
                    field: "nativeTokenContract",
                    reason: "nativeTokenContract is required when autoFund is true"
                )
            }
            // why: the deploy transaction may be confirmed on Horizon before
            // Soroban RPC's simulation endpoint observes the new contract
            // instance; wait for the next ledger close (~5s on testnet) before
            // the funding flow simulates against the contract.
            try await Task.sleep(nanoseconds: 5_000_000_000)
            _ = try await transactionOperations.fundWallet(
                nativeTokenContract: tokenContract,
                forceMethod: forceMethod
            )
        }

        do {
            try await credentialManager.deleteCredential(credentialId: credentialIdBase64url)
        } catch {
            // best-effort: the transitional credential is no longer needed
            // after the deploy confirms; failure to delete it is not fatal.
        }

        return transactionHash
    }

    /// Connects to an existing smart-account wallet.
    ///
    /// Returns ``ConnectWalletResult`` on success, or `nil` when no valid
    /// session exists and `options.prompt == false`. The non-`nil` result is
    /// either a ``ConnectWalletResult/connected(credentialId:contractId:restoredFromSession:)``
    /// arm (single contract resolved, kit state set, session saved) or a
    /// ``ConnectWalletResult/ambiguous(credentialId:candidates:)`` arm (indexer
    /// reported multiple contracts — kit state NOT set, caller must let the
    /// user pick).
    ///
    /// - Parameter options: Connect-wallet options. Defaults to a silent
    ///   session-only restore.
    /// - Returns: ``ConnectWalletResult`` or `nil`.
    /// - Throws: ``WebAuthnException`` (prompt path), ``WalletException`` (no
    ///   contract resolved), ``ValidationException`` (options validation),
    ///   ``TransactionException`` (RPC failure), ``IndexerException`` (indexer
    ///   transport failure).
    public func connectWallet(
        options: ConnectWalletOptions = ConnectWalletOptions()
    ) async throws -> ConnectWalletResult? {
        if options.credentialId != nil || options.contractId != nil {
            return try await connectWithCredentials(
                credentialId: options.credentialId,
                contractId: options.contractId
            )
        }

        if !options.fresh {
            let session: StoredSession? = await safeGetSession()

            if let session = session, !session.isExpired {
                do {
                    let result = try await connectWithCredentials(
                        credentialId: session.credentialId,
                        contractId: session.contractId
                    )
                    // The explicit-contractId path always returns Connected;
                    // Ambiguous is by construction unreachable here.
                    switch result {
                    case .connected(let credentialId, let contractId, _):
                        return .connected(
                            credentialId: credentialId,
                            contractId: contractId,
                            restoredFromSession: true
                        )
                    case .ambiguous:
                        // unreachable per the explicit-contractId branch of
                        // connectWithCredentials; surface as a defensive error
                        throw WalletException.notFound(
                            identifier: session.contractId
                        )
                    }
                } catch let error as WalletException.NotFound {
                    _ = error
                    await safeClearSession()
                    // fall through
                }
                // Any other exception propagates so transient RPC failures do
                // not silently clear the session.
            } else if let session = session, session.isExpired {
                kit.events.emit(
                    .sessionExpired(
                        contractId: session.contractId,
                        credentialId: session.credentialId
                    )
                )
                await safeClearSession()
            }

            if !options.prompt {
                return nil
            }
        }

        guard let webauthnProvider = kit.config.webauthnProvider else {
            throw WebAuthnException.notSupported(
                details: "No WebAuthnProvider configured. Set webauthnProvider in config before calling connectWallet()."
            )
        }

        let challengeData = try OZWalletOperations.secureRandomData(count: 32)
        let authenticationResult: WebAuthnAuthenticationResult
        do {
            authenticationResult = try await webauthnProvider.authenticate(
                challenge: challengeData,
                allowCredentials: nil
            )
        } catch let error as WebAuthnException {
            throw error
        } catch {
            throw WebAuthnException.authenticationFailed(
                reason: SmartAccountException.messageOf(error) ?? "WebAuthn authentication failed",
                cause: error
            )
        }

        let credentialIdBase64url = authenticationResult.credentialId.base64URLEncodedString()

        // why: cascade storage -> deterministic derivation -> indexer fallback.
        // Storage hits short-circuit at stage A; deterministic derivation is the
        // happy path when the contract was deployed by this kit; the indexer is
        // a last-resort lookup for cross-device discovery.
        var contractId: String? = nil

        let stored: StoredCredential? = await safeGetCredential(
            credentialId: credentialIdBase64url
        )
        if let stored = stored {
            if stored.deploymentStatus == .failed {
                throw WalletException.notFound(
                    identifier: credentialIdBase64url +
                        " (smart account deployment previously failed; call deployPendingCredential() to retry or deleteCredential() to start over)"
                )
            }
            contractId = stored.contractId
        }

        if contractId == nil {
            let deployer = try await kit.getDeployer()
            let derivedContractId = try SmartAccountUtils.deriveContractAddress(
                credentialId: authenticationResult.credentialId,
                deployerPublicKey: deployer.accountId,
                networkPassphrase: kit.config.networkPassphrase
            )
            do {
                try await verifyContractExists(contractId: derivedContractId)
                contractId = derivedContractId
            } catch let error as WalletException.NotFound {
                _ = error
                // Address well-formed but no contract on-chain — fall through.
            }
        }

        if contractId == nil {
            guard let indexer = kit.indexerClient else {
                throw WalletException.notFound(
                    identifier: credentialIdBase64url +
                        " (no contract was found at the derived address and no indexer is configured)"
                )
            }
            let lookup = try await indexer.lookupByCredentialId(
                credentialId: credentialIdBase64url
            )
            let candidates = lookup.contracts
            switch candidates.count {
            case 0:
                throw WalletException.notFound(
                    identifier: credentialIdBase64url
                )
            case 1:
                guard let candidate = candidates.first?.contractId else {
                    throw WalletException.notFound(
                        identifier: credentialIdBase64url
                    )
                }
                try await verifyContractExists(contractId: candidate)
                contractId = candidate
            default:
                return .ambiguous(
                    credentialId: credentialIdBase64url,
                    candidates: candidates.map { $0.contractId }
                )
            }
        }

        guard let finalContractId = contractId else {
            throw WalletException.notFound(
                identifier: "Could not determine contract ID for credential \(credentialIdBase64url)"
            )
        }

        // End-of-cascade verify. Redundant for the derivation / N=1 paths;
        // mandatory for the storage-hit path (PENDING credential).
        try await verifyContractExists(contractId: finalContractId)

        // best-effort: delete transitional credential after on-chain confirm
        do {
            try await credentialManager.deleteCredential(credentialId: credentialIdBase64url)
        } catch {
            // best-effort
        }

        kit.setConnectedState(
            credentialId: credentialIdBase64url,
            contractId: finalContractId
        )
        kit.events.emit(
            .walletConnected(
                contractId: finalContractId,
                credentialId: credentialIdBase64url
            )
        )
        try await saveSession(
            credentialId: credentialIdBase64url,
            contractId: finalContractId
        )

        return .connected(
            credentialId: credentialIdBase64url,
            contractId: finalContractId,
            restoredFromSession: false
        )
    }

    /// Authenticates with a passkey without connecting to a wallet.
    ///
    /// Used to authenticate the user before contract selection (for example to
    /// discover deployed contracts via the indexer) or for multi-signer
    /// operations that do not require a fully-connected kit state.
    ///
    /// - Parameters:
    ///   - challenge: Optional challenge bytes to sign. When `nil`, a fresh
    ///     32-byte random challenge is generated.
    ///   - credentialIds: Optional list of allowed credential ids
    ///     (Base64URL-encoded). When provided, only those credentials may be
    ///     used by the authenticator.
    /// - Returns: ``AuthenticatePasskeyResult`` carrying the credential id,
    ///   normalised signature, and stored public key (when available).
    /// - Throws: ``WebAuthnException`` (authentication failure / no provider),
    ///   ``ValidationException`` (signature normalisation failure).
    public func authenticatePasskey(
        challenge: Data? = nil,
        credentialIds: [String]? = nil
    ) async throws -> AuthenticatePasskeyResult {
        guard let webauthnProvider = kit.config.webauthnProvider else {
            throw WebAuthnException.notSupported(
                details: "No WebAuthnProvider configured. Set webauthnProvider in config before calling authenticatePasskey()."
            )
        }

        let challengeData = try challenge ?? OZWalletOperations.secureRandomData(count: 32)

        var allowCredentials: [AllowCredential]? = nil
        if let credentialIds = credentialIds {
            var built: [AllowCredential] = []
            built.reserveCapacity(credentialIds.count)
            for rawCredIdStr in credentialIds {
                // Storage entries are written under the canonical unpadded
                // Base64URL form produced by ``Data.base64URLEncodedString()``;
                // normalise the caller-supplied id before the storage lookup
                // so padded inputs resolve to the same allow-list entry.
                let credIdStr = OZSmartAccountBuilders.strippedBase64URLPadding(rawCredIdStr)
                let idBytes: Data
                do {
                    idBytes = try Data(base64URLEncoded: credIdStr)
                } catch {
                    throw ValidationException.invalidInput(
                        field: "credentialIds",
                        reason: "Invalid Base64URL-encoded credential ID: \(credIdStr)",
                        cause: error
                    )
                }
                let stored = await safeGetCredential(credentialId: credIdStr)
                built.append(AllowCredential(id: idBytes, transports: stored?.transports))
            }
            allowCredentials = built
        }

        let authenticationResult: WebAuthnAuthenticationResult
        do {
            authenticationResult = try await webauthnProvider.authenticate(
                challenge: challengeData,
                allowCredentials: allowCredentials
            )
        } catch let error as WebAuthnException {
            throw error
        } catch {
            throw WebAuthnException.authenticationFailed(
                reason: SmartAccountException.messageOf(error) ?? "WebAuthn authentication failed",
                cause: error
            )
        }

        let credentialIdBase64url = authenticationResult.credentialId.base64URLEncodedString()

        let normalizedSignature: Data
        do {
            normalizedSignature = try SmartAccountUtils.normalizeSignature(
                authenticationResult.signature
            )
        } catch let error as ValidationException {
            throw error
        } catch {
            throw ValidationException.invalidInput(
                field: "signature",
                reason: "Failed to normalize WebAuthn signature: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let webAuthnSignature: OZWebAuthnSignature
        do {
            webAuthnSignature = try OZWebAuthnSignature(
                authenticatorData: authenticationResult.authenticatorData,
                clientData: authenticationResult.clientDataJSON,
                signature: normalizedSignature
            )
        } catch let error as ValidationException {
            throw error
        } catch {
            throw ValidationException.invalidInput(
                field: "signature",
                reason: "Failed to build WebAuthn signature: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        // best-effort: look up the stored public key
        var publicKey = Data()
        if let stored = await safeGetCredential(credentialId: credentialIdBase64url) {
            publicKey = stored.publicKey
        }

        return AuthenticatePasskeyResult(
            credentialId: credentialIdBase64url,
            signature: webAuthnSignature,
            publicKey: publicKey
        )
    }

    /// Deploys a wallet from a previously created pending credential.
    ///
    /// Used to retry a failed deployment or to submit a wallet created with
    /// `createWallet(autoSubmit: false)`. The credential must exist in storage
    /// with a valid `publicKey` and `contractId`.
    ///
    /// - Parameters:
    ///   - credentialId: Base64URL-encoded credential identifier of the
    ///     credential to deploy.
    ///   - autoSubmit: Whether to submit the deploy transaction. Defaults to
    ///     `true` (this entry point is typically used to retry a failed deploy
    ///     so callers usually want submission).
    ///   - autoFund: Whether to fund the freshly deployed wallet using
    ///     Friendbot (testnet only). Requires `autoSubmit = true`.
    ///   - nativeTokenContract: Native token contract address used when
    ///     `autoFund = true`.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: ``DeployPendingResult`` describing the deployment.
    /// - Throws: ``CredentialException``, ``ValidationException``,
    ///   ``TransactionException``.
    public func deployPendingCredential(
        credentialId: String,
        autoSubmit: Bool = true,
        autoFund: Bool = false,
        nativeTokenContract: String? = nil,
        forceMethod: SubmissionMethod? = nil
    ) async throws -> DeployPendingResult {
        // Validate autoFund requirements early so the failure occurs before
        // any storage / network calls.
        if autoFund && nativeTokenContract == nil {
            throw ValidationException.invalidInput(
                field: "nativeTokenContract",
                reason: "nativeTokenContract is required when autoFund is true"
            )
        }

        // Normalise caller-supplied Base64URL credential id by stripping any
        // trailing `=` padding so storage lookups, connected-state writes,
        // event payloads, and the saved session all use the canonical unpadded
        // form produced by ``Data.base64URLEncodedString()``.
        let credentialId = OZSmartAccountBuilders.strippedBase64URLPadding(credentialId)

        let credential = try await credentialManager.getCredential(
            credentialId: credentialId
        )
        guard let credential = credential else {
            throw CredentialException.notFound(credentialId: credentialId)
        }

        let publicKey = credential.publicKey
        if publicKey.isEmpty {
            throw CredentialException.invalid(
                reason: "Credential '\(credentialId)' is missing publicKey"
            )
        }
        guard let contractId = credential.contractId, !contractId.isEmpty else {
            throw CredentialException.invalid(
                reason: "Credential '\(credentialId)' is missing contractId"
            )
        }

        let credentialIdBytes: Data
        do {
            credentialIdBytes = try Data(base64URLEncoded: credentialId)
        } catch {
            throw CredentialException.invalid(
                reason: "Invalid Base64URL-encoded credential ID: \(credentialId)",
                cause: error
            )
        }

        // why: re-derive the contract address from the stored credential's
        // public key + the deployer + the network passphrase, and compare it
        // against `credential.contractId`. Storage that has been tampered with
        // out-of-band could otherwise drive a deploy against an address that
        // does not correspond to the credential's deterministic identity.
        let deployer = try await kit.getDeployer()
        let derivedContractId = try SmartAccountUtils.deriveContractAddress(
            credentialId: credentialIdBytes,
            deployerPublicKey: deployer.accountId,
            networkPassphrase: kit.config.networkPassphrase
        )
        if derivedContractId != contractId {
            throw CredentialException.invalid(
                reason: "Stored credential '\(credentialId)' contractId (\(contractId)) does not match deterministically derived contractId (\(derivedContractId)); refusing to deploy against a divergent address."
            )
        }

        kit.setConnectedState(
            credentialId: credentialId,
            contractId: contractId
        )
        kit.events.emit(
            .walletConnected(
                contractId: contractId,
                credentialId: credentialId
            )
        )
        try await saveSession(credentialId: credentialId, contractId: contractId)

        let deployTransaction: Transaction
        do {
            deployTransaction = try await buildDeployTransaction(
                publicKey: publicKey,
                credentialId: credentialIdBytes,
                forceMethod: forceMethod
            )
        } catch {
            await markDeploymentFailedSafely(
                credentialId: credentialId,
                error: SmartAccountException.messageOf(error) ?? "Build failed"
            )
            if let smartError = error as? SmartAccountException {
                throw smartError
            }
            throw TransactionException.submissionFailed(
                reason: "Failed to build deploy transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
        let signedTxXdr: String
        do {
            signedTxXdr = try deployTransaction.encodedEnvelope()
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to encode envelope: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        if !autoSubmit {
            return DeployPendingResult(
                contractId: contractId,
                signedTransactionXdr: signedTxXdr
            )
        }

        let hash = try await submitDeployTransaction(
            transaction: deployTransaction,
            credentialIdBase64url: credentialId,
            forceMethod: forceMethod
        )

        if autoFund {
            guard let tokenContract = nativeTokenContract else {
                throw ValidationException.invalidInput(
                    field: "nativeTokenContract",
                    reason: "nativeTokenContract is required when autoFund is true"
                )
            }
            try await Task.sleep(nanoseconds: 5_000_000_000)
            _ = try await transactionOperations.fundWallet(
                nativeTokenContract: tokenContract,
                forceMethod: forceMethod
            )
        }

        do {
            try await credentialManager.deleteCredential(credentialId: credentialId)
        } catch {
            // best-effort
        }

        return DeployPendingResult(
            contractId: contractId,
            signedTransactionXdr: signedTxXdr,
            transactionHash: hash
        )
    }

    // MARK: - Private helpers

    /// Passthrough to the kit's transaction-operations instance.
    private var transactionOperations: OZTransactionOperations {
        return kit.transactionOperations
    }

    /// Connects to a wallet using an explicit credential id and / or contract
    /// id. When both are supplied, the cascade is bypassed; when only the
    /// credential id is supplied, the storage → derivation → indexer cascade
    /// drives the contract resolution.
    private func connectWithCredentials(
        credentialId: String?,
        contractId: String?
    ) async throws -> ConnectWalletResult {
        // contractId requires credentialId
        if contractId != nil && credentialId == nil {
            throw ValidationException.invalidInput(
                field: "contractId",
                reason: "contractId option requires credentialId to be provided"
            )
        }

        // Normalise caller-supplied Base64URL credential id by stripping any
        // trailing `=` padding so storage-key lookups, connected-state writes,
        // event payloads, and the saved session all use the canonical unpadded
        // form produced by ``Data.base64URLEncodedString()``.
        let credentialId = credentialId.map(OZSmartAccountBuilders.strippedBase64URLPadding)

        var finalContractId: String? = contractId

        if let credentialId = credentialId, finalContractId == nil {
            // Stage A: storage
            let stored: StoredCredential? = await safeGetCredential(
                credentialId: credentialId
            )
            if let stored = stored {
                if stored.deploymentStatus == .failed {
                    throw WalletException.notFound(
                        identifier: credentialId +
                            " (smart account deployment previously failed; call deployPendingCredential() to retry or deleteCredential() to start over)"
                    )
                }
                finalContractId = stored.contractId
            }

            // Stage B: derivation
            if finalContractId == nil {
                let deployer = try await kit.getDeployer()
                let credentialIdBytes: Data
                do {
                    credentialIdBytes = try Data(base64URLEncoded: credentialId)
                } catch {
                    throw ValidationException.invalidInput(
                        field: "credentialId",
                        reason: "Invalid Base64URL-encoded credential ID",
                        cause: error
                    )
                }
                let derivedContractId = try SmartAccountUtils.deriveContractAddress(
                    credentialId: credentialIdBytes,
                    deployerPublicKey: deployer.accountId,
                    networkPassphrase: kit.config.networkPassphrase
                )
                do {
                    try await verifyContractExists(contractId: derivedContractId)
                    finalContractId = derivedContractId
                } catch let error as WalletException.NotFound {
                    _ = error
                    // fall through to indexer
                }
            }

            // Stage C: indexer
            if finalContractId == nil {
                guard let indexer = kit.indexerClient else {
                    throw WalletException.notFound(
                        identifier: credentialId +
                            " (no contract was found at the derived address and no indexer is configured)"
                    )
                }
                let lookup = try await indexer.lookupByCredentialId(
                    credentialId: credentialId
                )
                let candidates = lookup.contracts
                switch candidates.count {
                case 0:
                    throw WalletException.notFound(
                        identifier: credentialId
                    )
                case 1:
                    guard let candidate = candidates.first?.contractId else {
                        throw WalletException.notFound(
                            identifier: credentialId
                        )
                    }
                    try await verifyContractExists(contractId: candidate)
                    finalContractId = candidate
                default:
                    return .ambiguous(
                        credentialId: credentialId,
                        candidates: candidates.map { $0.contractId }
                    )
                }
            }
        }

        guard let credentialId = credentialId,
              let finalContractId = finalContractId else {
            throw WalletException.notFound(
                identifier: "Could not determine credential ID or contract ID"
            )
        }

        // End-of-cascade on-chain verify.
        try await verifyContractExists(contractId: finalContractId)

        do {
            try await credentialManager.deleteCredential(credentialId: credentialId)
        } catch {
            // best-effort
        }

        kit.setConnectedState(
            credentialId: credentialId,
            contractId: finalContractId
        )
        kit.events.emit(
            .walletConnected(
                contractId: finalContractId,
                credentialId: credentialId
            )
        )
        try await saveSession(credentialId: credentialId, contractId: finalContractId)

        return .connected(
            credentialId: credentialId,
            contractId: finalContractId,
            restoredFromSession: false
        )
    }

    /// Verifies the supplied contract address has a live instance ledger entry.
    ///
    /// Three outcomes:
    /// - An entry is returned: the method returns normally (the contract may be
    ///   live or archived; archived entries are returned by Soroban RPC as
    ///   regular entries with an archive marker).
    /// - The address is malformed or RPC reports "not found": throws
    ///   ``WalletException/NotFound``.
    /// - The RPC call fails for transport reasons: the original
    ///   ``TransactionException`` is re-thrown so the caller knows the lookup
    ///   was inconclusive.
    private func verifyContractExists(contractId: String) async throws {
        let response = await kit.sorobanServer.getContractData(
            contractId: contractId,
            key: .ledgerKeyContractInstance,
            durability: ContractDataDurability.persistent
        )
        switch response {
        case .success:
            return
        case .failure(let error):
            // SorobanServer.getContractData returns `.failure(.requestFailed(...))`
            // when the contract id is malformed (Address conversion failed) or
            // when the ledger entry simply does not exist on-chain. Both cases
            // mean "no contract here". Other RPC errors carry an `errorResponse`
            // payload and are surfaced verbatim so transient transport
            // failures can be distinguished from authoritative not-found.
            switch error {
            case .requestFailed:
                throw WalletException.notFound(
                    identifier: contractId
                )
            case .errorResponse, .parsingResponseFailed:
                throw TransactionException.submissionFailed(
                    reason: "Contract lookup failed for \(contractId): \(rpcErrorMessage(error))",
                    cause: error
                )
            }
        }
    }

    /// Persists a session for silent reconnection. The session expires at
    /// `now + kit.config.sessionExpiryMs`.
    private func saveSession(credentialId: String, contractId: String) async throws {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let session = StoredSession(
            credentialId: credentialId,
            contractId: contractId,
            connectedAt: now,
            expiresAt: now + kit.config.sessionExpiryMs
        )
        do {
            try await kit.getStorage().saveSession(session)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.writeFailed(
                key: "session:\(credentialId)",
                cause: error
            )
        }
    }

    /// Builds, simulates, hand-assembles, and signs the deploy transaction.
    /// Side-effect-free — does not write to storage or mark credentials as
    /// failed; the caller is responsible for failure marking.
    private func buildDeployTransaction(
        publicKey: Data,
        credentialId: Data,
        forceMethod: SubmissionMethod?
    ) async throws -> Transaction {
        // key_data = publicKey || credentialId
        var keyData = Data(capacity: publicKey.count + credentialId.count)
        keyData.append(publicKey)
        keyData.append(credentialId)

        let webauthnSigner: OZExternalSigner
        do {
            webauthnSigner = try OZExternalSigner(
                verifierAddress: kit.config.webauthnVerifierAddress,
                keyData: keyData
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to create WebAuthn signer: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let signersScVal: SCValXDR
        do {
            signersScVal = .vec([try webauthnSigner.toScVal()])
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to convert signer to ScVal: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let policiesScVal: SCValXDR = .map([])
        let constructorArgs: [SCValXDR] = [signersScVal, policiesScVal]

        let deployer = try await kit.getDeployer()
        let salt = SmartAccountUtils.getContractSalt(credentialId: credentialId)

        let deployerSCAddress = try SCAddressXDR(accountId: deployer.accountId)
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(
                address: deployerSCAddress,
                salt: Uint256XDR(salt)
            )
        )

        // WASM hash: convert hex string to 32 bytes
        guard let wasmHashData = kit.config.accountWasmHash.data(using: .hexadecimal),
              wasmHashData.count == 32 else {
            throw TransactionException.signingFailed(
                reason: "Invalid accountWasmHash: must be 64 hex chars decoding to 32 bytes"
            )
        }
        let executable = ContractExecutableXDR.wasm(HashXDR(wasmHashData))

        let createContractArgs = CreateContractV2ArgsXDR(
            contractIDPreimage: preimage,
            executable: executable,
            constructorArgs: constructorArgs
        )
        let hostFunction = HostFunctionXDR.createContractV2(createContractArgs)

        let operation = InvokeHostFunctionOperation(
            hostFunction: hostFunction,
            auth: [],
            sourceAccountId: deployer.accountId
        )

        let deployerAccount: Account
        do {
            deployerAccount = try await fetchAccount(accountId: deployer.accountId)
        } catch {
            throw TransactionException.submissionFailed(
                reason: "Failed to fetch deployer account: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let nowSeconds = UInt64(Date().timeIntervalSince1970)
        let timeoutSeconds = kit.config.timeoutInSeconds
        let maxTime: UInt64 = timeoutSeconds <= 0 ? 0 : nowSeconds + UInt64(timeoutSeconds)
        let timeBounds = TimeBounds(
            minTime: 0,
            maxTime: maxTime
        )
        let preconditions = TransactionPreconditions(timeBounds: timeBounds)
        let transaction: Transaction
        do {
            transaction = try Transaction(
                sourceAccount: deployerAccount,
                operations: [operation],
                memo: Memo.none,
                preconditions: preconditions,
                maxOperationFee: StellarProtocolConstants.MIN_BASE_FEE
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to build transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let simulation: SimulateTransactionResponse
        do {
            simulation = try await simulate(
                transaction: transaction,
                failureMessagePrefix: "Simulation error: "
            )
        } catch let error as TransactionException {
            throw error
        } catch {
            throw TransactionException.simulationFailed(
                reason: "Failed to simulate deployment transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        let useRelayer = resolveDeploySubmissionMethod(forceMethod: forceMethod) == .relayer

        do {
            try OZTransactionOperations.applySimulation(
                simulation: simulation,
                transaction: transaction,
                signedAuthEntries: simulation.sorobanAuth ?? [],
                relayerMode: useRelayer
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to assemble transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        do {
            try transaction.sign(
                keyPair: deployer,
                network: .custom(passphrase: kit.config.networkPassphrase)
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to sign transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }

        return transaction
    }

    /// Submits the supplied deploy transaction and polls for confirmation
    /// using the 10-attempt, 2-second cadence required by the deploy path.
    private func submitDeployTransaction(
        transaction: Transaction,
        credentialIdBase64url: String,
        forceMethod: SubmissionMethod?
    ) async throws -> String {
        let useRelayer = resolveDeploySubmissionMethod(forceMethod: forceMethod) == .relayer

        let transactionHash: String

        if useRelayer {
            guard let relayer = kit.relayerClient else {
                throw TransactionException.submissionFailed(
                    reason: "Relayer was selected but no relayer is configured"
                )
            }
            let envelope: TransactionEnvelopeXDR
            do {
                envelope = try transaction.transactionXDR.toEnvelopeXDR()
            } catch {
                await markDeploymentFailedSafely(
                    credentialId: credentialIdBase64url,
                    error: "Failed to build signed envelope: \(SmartAccountException.messageOf(error) ?? "unknown")"
                )
                throw TransactionException.submissionFailed(
                    reason: "Failed to build signed envelope: \(SmartAccountException.messageOf(error) ?? "unknown")",
                    cause: error
                )
            }
            let relayerResponse = await relayer.sendXdr(transactionEnvelope: envelope)
            if !relayerResponse.success {
                let errorMsg = relayerResponse.error ?? "Relayer submission failed"
                await markDeploymentFailedSafely(
                    credentialId: credentialIdBase64url,
                    error: "Relayer error: \(errorMsg)"
                )
                throw TransactionException.submissionFailed(
                    reason: "Deployment relayer error: \(errorMsg)"
                )
            }
            guard let hash = relayerResponse.hash else {
                await markDeploymentFailedSafely(
                    credentialId: credentialIdBase64url,
                    error: "No transaction hash returned from relayer"
                )
                throw TransactionException.submissionFailed(
                    reason: "No transaction hash returned from relayer"
                )
            }
            transactionHash = hash
        } else {
            let sendResponse = await kit.sorobanServer.sendTransaction(transaction: transaction)
            switch sendResponse {
            case .success(let sendResult):
                if let errorResultXdr = sendResult.errorResultXdr {
                    await markDeploymentFailedSafely(
                        credentialId: credentialIdBase64url,
                        error: "Transaction error: \(errorResultXdr)"
                    )
                    throw TransactionException.submissionFailed(
                        reason: "Deployment transaction error: \(errorResultXdr)"
                    )
                }
                transactionHash = sendResult.transactionId
            case .failure(let error):
                await markDeploymentFailedSafely(
                    credentialId: credentialIdBase64url,
                    error: "Failed to send transaction: \(rpcErrorMessage(error))"
                )
                throw TransactionException.submissionFailed(
                    reason: "Failed to send deployment transaction: \(rpcErrorMessage(error))",
                    cause: error
                )
            }
        }

        // Poll for confirmation: 10 attempts, 2 seconds between each.
        var confirmed = false
        for attempt in 1...10 {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let txStatusResponse = await kit.sorobanServer.getTransaction(
                transactionHash: transactionHash
            )
            switch txStatusResponse {
            case .success(let txStatus):
                switch txStatus.status {
                case GetTransactionResponse.STATUS_SUCCESS:
                    confirmed = true
                case GetTransactionResponse.STATUS_FAILED:
                    await markDeploymentFailedSafely(
                        credentialId: credentialIdBase64url,
                        error: txStatus.resultXdr ?? "Deployment failed on-chain"
                    )
                    throw TransactionException.submissionFailed(
                        reason: "Deployment failed: \(txStatus.resultXdr ?? "unknown")"
                    )
                default:
                    continue
                }
            case .failure:
                if attempt < 10 {
                    continue
                }
                await markDeploymentFailedSafely(
                    credentialId: credentialIdBase64url,
                    error: "Deployment confirmation timed out"
                )
                throw TransactionException.timeout(
                    details: "Deployment confirmation timed out"
                )
            }
            if confirmed { break }
        }

        if !confirmed {
            await markDeploymentFailedSafely(
                credentialId: credentialIdBase64url,
                error: "Deployment confirmation timed out"
            )
            throw TransactionException.timeout(
                details: "Deployment confirmation timed out"
            )
        }

        return transactionHash
    }

    /// Resolves the deploy-submission method.
    ///
    /// Priority: forced override > relayer (if configured) > RPC.
    private func resolveDeploySubmissionMethod(
        forceMethod: SubmissionMethod?
    ) -> SubmissionMethod {
        if let forceMethod = forceMethod {
            return forceMethod
        }
        return kit.relayerClient != nil ? .relayer : .rpc
    }

    private func safeGetSession() async -> StoredSession? {
        do {
            return try await kit.getStorage().getSession()
        } catch {
            return nil
        }
    }

    private func safeClearSession() async {
        do {
            try await kit.getStorage().clearSession()
        } catch {
            // best-effort
        }
    }

    private func markDeploymentFailedSafely(credentialId: String, error: String) async {
        do {
            try await credentialManager.markDeploymentFailed(
                credentialId: credentialId,
                error: error
            )
        } catch {
            // best-effort; the credential update is non-critical
        }
    }

    /// Reads cryptographically random bytes from `SecRandomCopyBytes`; throws on hardware failure rather than returning zero bytes.
    internal static func secureRandomData(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else {
            throw WebAuthnException.registrationFailed(
                reason: "SecRandomCopyBytes failed with OSStatus \(status); refusing to produce non-random WebAuthn material"
            )
        }
        return Data(bytes)
    }
}
