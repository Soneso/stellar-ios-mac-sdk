//
//  OZExternalSignerManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation


/// Adapter protocol for external Ed25519 signing sources.
///
/// Conform to this protocol to plug in a hardware wallet, remote signing service, or any
/// other out-of-process Ed25519 signing backend into the multi-signer pipeline. The manager
/// consults the adapter before falling back to its in-memory keypair registry (adapter-first
/// precedence rule).
///
/// Example:
/// ```swift
/// final class MyHardwareWalletAdapter: OZExternalEd25519SignerAdapter {
///     func canSignFor(verifierAddress: String, publicKey: Data) -> Bool {
///         hardwareWallet.hasSigner(for: publicKey)
///     }
///
///     func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data {
///         try await hardwareWallet.sign(digest: authDigest, publicKey: publicKey)
///     }
/// }
/// ```
public protocol OZExternalEd25519SignerAdapter: Sendable {

    /// Returns whether this adapter can produce an Ed25519 signature for the given
    /// verifier-contract address and public key pair.
    ///
    /// Called before the in-memory keypair registry is consulted. When this method
    /// returns `true`, the adapter must be able to fulfil a subsequent
    /// ``signAuthDigest(authDigest:publicKey:)`` call for the same key without error.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the Ed25519 verifier
    ///     contract identifying the on-chain signer slot.
    ///   - publicKey: 32-byte Ed25519 public key identifying the signer slot.
    /// - Returns: `true` when the adapter can sign for this `(verifierAddress, publicKey)` pair.
    func canSignFor(verifierAddress: String, publicKey: Data) -> Bool

    /// Produces a 64-byte Ed25519 signature over the supplied auth digest.
    ///
    /// Called by the multi-signer pipeline when ``canSignFor(verifierAddress:publicKey:)``
    /// returned `true` for the same `publicKey`. The pipeline locally verifies the returned
    /// signature before incorporating it into the authorization payload.
    ///
    /// - Parameters:
    ///   - authDigest: 32-byte digest to sign. Computed as
    ///     `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
    ///   - publicKey: 32-byte Ed25519 public key that identifies which key to sign with.
    /// - Returns: 64-byte raw Ed25519 signature over `authDigest`.
    /// - Throws: Any error that prevents signing (hardware unavailable, user cancelled, etc.).
    func signAuthDigest(authDigest: Data, publicKey: Data) async throws -> Data
}


/// The type of an external signer managed by ``OZExternalSignerManager``.
///
/// External signers fall into two distinct categories: in-memory Ed25519 keypairs
/// and connections to external wallets (for example Freighter or LOBSTR). The
/// manager treats keypair signers as taking precedence over wallet signers when
/// both report the same address.
public enum OZExternalSignerType: String, Sendable, Codable, CaseIterable {

    /// Ed25519 keypair-based signer. Stored in memory only, never persisted.
    case keypair = "KEYPAIR"

    /// External wallet signer (for example Freighter or LOBSTR). Connections are
    /// surfaced from the live ``OZExternalWalletAdapter`` for the duration of the
    /// running process.
    case wallet = "WALLET"
}


/// Information about a managed external signer.
///
/// Represents either a keypair-based signer (in-memory Ed25519 key) or a
/// wallet-based signer (external wallet connection). Returned by
/// ``OZExternalSignerManager/getAll()`` and ``OZExternalSignerManager/get(address:)``
/// to report signer details.
///
/// Example:
/// ```swift
/// let signers = await kit.externalSigners.getAll()
/// for signer in signers {
///     print("\(signer.address) (\(signer.type))")
///     if signer.type == .wallet {
///         print("  Wallet: \(signer.walletName ?? "unknown")")
///     }
/// }
/// ```
public struct OZExternalSignerInfo: Sendable, Codable, Equatable, Hashable {

    /// The Stellar G-address of the signer.
    public let address: String

    /// Whether this signer is a keypair or wallet.
    public let type: OZExternalSignerType

    /// Human-readable wallet name (only populated when ``type`` is ``OZExternalSignerType/wallet``).
    public let walletName: String?

    /// Wallet identifier (only populated when ``type`` is ``OZExternalSignerType/wallet``).
    public let walletId: String?

    /// Initializes a new ``OZExternalSignerInfo``.
    ///
    /// - Parameters:
    ///   - address: The Stellar G-address of the signer.
    ///   - type: Whether this signer is a keypair or wallet.
    ///   - walletName: Optional human-readable wallet name (wallet signers only).
    ///   - walletId: Optional wallet identifier (wallet signers only).
    public init(
        address: String,
        type: OZExternalSignerType,
        walletName: String? = nil,
        walletId: String? = nil
    ) {
        self.address = address
        self.type = type
        self.walletName = walletName
        self.walletId = walletId
    }
}


/// Manager for external (non-passkey) signers in multi-signature smart-account operations.
///
/// Maintains two signer kinds:
/// - **Keypair signers** (``addFromSecret(secretKey:)``): held in memory only; secret-key
///   material is never persisted.
/// - **Wallet signers**: surfaced from the live ``OZExternalWalletAdapter`` for the duration
///   of the running process.
///
/// Example:
/// ```swift
/// let address = try await manager.addFromSecret(secretKey: "SCZANGBA5YHT...")
/// ```
public actor OZExternalSignerManager {

    private let addressLogPrefixCount = 8

    private let networkPassphrase: String
    private let walletAdapter: OZExternalWalletAdapter?

    /// Keypair-based signers keyed by G-address. Memory-only, never persisted.
    private var keypairSigners: [String: KeyPair] = [:]

    // MARK: - Ed25519 state

    /// Composite key for the Ed25519 signer registry. Two entries with the same
    /// public key but different verifier addresses are distinct signers on-chain
    /// and must be stored as separate entries.
    struct Ed25519SignerKey: Hashable, Sendable {
        let verifierAddress: String
        let publicKey: Data
    }

    /// Ed25519 keypairs keyed by `(verifierAddress, publicKey)`. Memory-only, never persisted.
    private var ed25519Signers: [Ed25519SignerKey: KeyPair] = [:]

    /// Optional adapter for out-of-process Ed25519 signing (hardware wallets, remote services).
    ///
    /// When non-`nil`, the adapter is consulted via
    /// ``OZExternalEd25519SignerAdapter/canSignFor(verifierAddress:publicKey:)`` before the
    /// in-memory keypair registry (adapter-first precedence rule). Supplied at construction
    /// time via the `ed25519Adapter` initializer parameter.
    private let ed25519Adapter: OZExternalEd25519SignerAdapter?

    /// Initializes a new ``OZExternalSignerManager``.
    ///
    /// - Parameters:
    ///   - networkPassphrase: Stellar network passphrase. Used as signing
    ///     context when delegating to wallet adapters.
    ///   - walletAdapter: Optional wallet adapter. When `nil`, all wallet-related
    ///     operations either throw ``SmartAccountConfigurationException/MissingConfig`` or
    ///     return empty results.
    ///   - ed25519Adapter: Optional adapter for out-of-process Ed25519 signing.
    ///     When non-`nil`, consulted before the in-memory keypair registry for
    ///     every ``signEd25519AuthDigest(verifierAddress:publicKey:authDigest:)`` call.
    public init(
        networkPassphrase: String,
        walletAdapter: OZExternalWalletAdapter? = nil,
        ed25519Adapter: OZExternalEd25519SignerAdapter? = nil
    ) {
        self.networkPassphrase = networkPassphrase
        self.walletAdapter = walletAdapter
        self.ed25519Adapter = ed25519Adapter
    }

    /// Whether an external wallet adapter is configured.
    ///
    /// Returns `true` when the manager was initialized with a non-`nil`
    /// ``OZExternalWalletAdapter``. Wallet-related operations require this to be `true`.
    public var hasWalletAdapter: Bool {
        return walletAdapter != nil
    }

    // MARK: - Add signers

    /// Adds an Ed25519 keypair signer from a raw secret key.
    ///
    /// Creates a `KeyPair` from the provided Stellar secret key (S-address) and
    /// stores it in memory. The keypair is never persisted to storage; it is
    /// lost when the application terminates or the manager is deinitialized.
    ///
    /// If a signer with the same G-address already exists (either keypair or
    /// wallet), the keypair signer takes precedence and overwrites the existing
    /// entry.
    ///
    /// - Parameter secretKey: A valid Stellar secret key (S-address, 56 characters).
    /// - Returns: The derived G-address of the signer.
    /// - Throws: ``SmartAccountSignerException/Invalid`` when the secret key is malformed
    ///           or keypair creation otherwise fails.
    public func addFromSecret(secretKey: String) async throws -> String {

        let keypair: KeyPair
        do {
            keypair = try KeyPair(secretSeed: secretKey)
        } catch {
            throw SmartAccountSignerException.invalid(
                reason: "Invalid secret key. Must be a valid Stellar secret key (S...): \(describe(error))",
                cause: error
            )
        }

        let address = keypair.accountId
        keypairSigners[address] = keypair

        return address
    }

    // MARK: - Query signers

    /// Returns true when any keypair or connected-wallet adapter can sign for `address`.
    public func canSignFor(address: String) async -> Bool {

        if keypairSigners[address] != nil {
            return true
        }

        if let adapter = walletAdapter, adapter.canSignFor(address: address) {
            return true
        }

        return false
    }

    /// Gets information about a specific signer by address.
    ///
    /// Checks keypair signers first (which take precedence), then wallet signers.
    ///
    /// - Parameter address: The Stellar G-address to look up.
    /// - Returns: The signer info, or `nil` when no signer exists for this address.
    public func get(address: String) async -> OZExternalSignerInfo? {

        if keypairSigners[address] != nil {
            return OZExternalSignerInfo(address: address, type: .keypair)
        }

        if let adapter = walletAdapter,
           let wallet = adapter.getWalletForAddress(address: address) {
            return OZExternalSignerInfo(
                address: wallet.address,
                type: .wallet,
                walletName: wallet.walletName,
                walletId: wallet.walletId
            )
        }

        return nil
    }

    /// Lists all managed external signers (both keypair and wallet).
    ///
    /// Keypair signers are listed first. When a G-address exists as both a
    /// keypair signer and a wallet signer, only the keypair entry is returned
    /// (keypair takes precedence).
    ///
    /// - Returns: All managed external signer info objects.
    public func getAll() async -> [OZExternalSignerInfo] {

        var signers: [OZExternalSignerInfo] = []
        let keypairAddresses = Set(keypairSigners.keys)

        for address in keypairAddresses {
            signers.append(OZExternalSignerInfo(address: address, type: .keypair))
        }

        if let adapter = walletAdapter {
            let wallets = adapter.getConnectedWallets()
            for wallet in wallets where !keypairAddresses.contains(wallet.address) {
                signers.append(
                    OZExternalSignerInfo(
                        address: wallet.address,
                        type: .wallet,
                        walletName: wallet.walletName,
                        walletId: wallet.walletId
                    )
                )
            }
        }

        return signers
    }

    /// Returns whether any external signers are registered (keypair or wallet).
    ///
    /// - Returns: `true` when at least one signer is managed.
    public func hasSigners() async -> Bool {

        if !keypairSigners.isEmpty {
            return true
        }

        let walletCount = walletAdapter?.getConnectedWallets().count ?? 0
        return walletCount > 0
    }

    // MARK: - Sign auth entry

    /// Signs an authorization-entry preimage with the appropriate signer for the given address.
    ///
    /// For keypair signers, the preimage XDR is base64-decoded, hashed with
    /// SHA-256, and signed directly with the in-memory Ed25519 keypair. For
    /// wallet signers, signing is delegated to
    /// ``OZExternalWalletAdapter/signAuthEntry(preimageXdr:options:)``.
    ///
    /// Keypair signers take precedence over wallet signers when both exist for
    /// the same address; the wallet adapter is only consulted when no keypair
    /// signer matches.
    ///
    /// - Parameters:
    ///   - address: The G-address identifying which signer to use.
    ///   - authEntry: Base64-encoded `HashIDPreimage` XDR to sign.
    /// - Returns: The signing result containing the base64-encoded raw Ed25519
    ///            signature and the signer address that produced it.
    /// - Throws: ``SmartAccountSignerException/NotFound`` when no signer is available for
    ///           the address; ``SmartAccountTransactionException/SigningFailed`` when the
    ///           signing operation fails.
    public func signAuthEntry(
        address: String,
        authEntry: String
    ) async throws -> OZSignAuthEntryResult {

        if let keypair = keypairSigners[address] {
            return try signWithKeypair(
                keypair: keypair,
                preimageXdrBase64: authEntry,
                address: address
            )
        }

        if let adapter = walletAdapter, adapter.canSignFor(address: address) {
            let result: OZSignAuthEntryResult
            do {
                result = try await adapter.signAuthEntry(
                    preimageXdr: authEntry,
                    options: OZSignAuthEntryOptions(
                        networkPassphrase: networkPassphrase,
                        address: address
                    )
                )
            } catch {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "External wallet signing failed for \(address): \(describe(error))",
                    cause: error
                )
            }

            // why: locally verify the wallet adapter's signature against the requested address.
            // Refusing here is far more actionable than the on-chain auth-failed we would
            // otherwise see after submission.
            try verifyExternalWalletSignature(
                preimageXdrBase64: authEntry,
                signatureBase64: result.signedAuthEntry,
                expectedSignerAddress: result.signerAddress ?? address
            )

            return OZSignAuthEntryResult(
                signedAuthEntry: result.signedAuthEntry,
                signerAddress: result.signerAddress ?? address
            )
        }

        throw SmartAccountSignerException.notFound(signerId: address)
    }

    /// Verifies an external-wallet adapter's signature against the supplied
    /// preimage and signer address.
    ///
    /// Decodes the base64-encoded preimage XDR, computes its SHA-256 hash,
    /// derives the Ed25519 public key from `expectedSignerAddress`, and
    /// verifies the base64-encoded signature against that key. Any failure
    /// (malformed base64, malformed address, signature verification failure)
    /// is surfaced as ``SmartAccountTransactionException/SigningFailed``.
    private func verifyExternalWalletSignature(
        preimageXdrBase64: String,
        signatureBase64: String,
        expectedSignerAddress: String
    ) throws {
        guard let preimageXdrBytes = Data(base64Encoded: preimageXdrBase64) else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to decode base64 auth entry preimage during verification"
            )
        }
        guard let signatureBytes = Data(base64Encoded: signatureBase64) else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Wallet adapter returned non-base64 signature for \(expectedSignerAddress)"
            )
        }

        let signerKeyPair: KeyPair
        do {
            signerKeyPair = try KeyPair(accountId: expectedSignerAddress)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to derive public key from wallet signer address \(expectedSignerAddress): \(describe(error))",
                cause: error
            )
        }

        let preimageHash = preimageXdrBytes.sha256Hash
        let signatureValid: Bool
        do {
            signatureValid = try signerKeyPair.verify(
                signature: [UInt8](signatureBytes),
                message: [UInt8](preimageHash)
            )
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Wallet adapter returned signature that does not verify against requested address \(expectedSignerAddress): \(describe(error))",
                cause: error
            )
        }
        if !signatureValid {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Wallet adapter returned signature that does not verify against requested address \(expectedSignerAddress)"
            )
        }
    }

    /// Removes a signer by address.
    ///
    /// For keypair signers, removes the keypair from memory. For wallet
    /// signers, calls ``OZExternalWalletAdapter/disconnectByAddress(address:)``
    /// to release the adapter's runtime state. Both paths run when present, so an
    /// address that is somehow registered as both a keypair and a wallet is fully
    /// cleared.
    ///
    /// - Parameter address: The G-address of the signer to remove.
    /// - Throws: Rethrows any error raised by the adapter.
    public func remove(address: String) async throws {

        keypairSigners.removeValue(forKey: address)

        try await walletAdapter?.disconnectByAddress(address: address)
    }

    /// Removes all signers. Clears in-memory keypair signers, in-memory Ed25519
    /// keypairs, and disconnects all external wallets. Failures propagate to the
    /// caller.
    public func removeAll() async throws {

        keypairSigners.removeAll()
        ed25519Signers.removeAll()

        try await walletAdapter?.disconnect()
    }

    /// Drops in-memory keypair and Ed25519 signing secrets only. Unlike
    /// `removeAll()`, this does NOT disconnect the external-wallet adapter.
    /// Called by `OZSmartAccountKit.close()` to release sensitive key material on
    /// teardown.
    internal func clearInMemorySigners() {
        keypairSigners.removeAll()
        ed25519Signers.removeAll()
    }

    // MARK: - Ed25519 methods

    /// Registers an Ed25519 signing keypair derived from a Stellar secret key.
    ///
    /// Creates a `KeyPair` from the supplied raw 32-byte Ed25519 secret seed and stores it
    /// in memory under the composite `(verifierAddress, publicKey)` key. The keypair is
    /// never persisted to storage and is lost when the application terminates or the manager
    /// is deinitialized.
    ///
    /// If a keypair is already registered for the same `(verifierAddress, publicKey)` pair,
    /// it is silently overwritten with the new one.
    ///
    /// - Parameters:
    ///   - secretKeyBytes: Raw 32-byte Ed25519 secret seed. Must be exactly 32 bytes.
    ///   - verifierAddress: Contract address (`C…` strkey) of the Ed25519 verifier contract
    ///     under which the signer is registered on-chain.
    /// - Returns: The derived 32-byte Ed25519 public key.
    /// - Throws: ``SmartAccountValidationException/InvalidInput`` when `verifierAddress` is not a valid
    ///   contract strkey or when `secretKeyBytes` is not exactly 32 bytes;
    ///   ``SmartAccountSignerException/Invalid`` when keypair construction fails.
    public func addEd25519FromRawKey(secretKeyBytes: Data, verifierAddress: String) throws -> Data {
        if !verifierAddress.isValidContractId() {
            throw SmartAccountValidationException.invalidInput(
                field: "verifierAddress",
                reason: "Ed25519 signer has an invalid verifier address (must be a C... contract strkey): \(verifierAddress)"
            )
        }
        guard secretKeyBytes.count == SmartAccountConstants.ed25519SecretSeedSize else {
            throw SmartAccountValidationException.invalidInput(
                field: "secretKeyBytes",
                reason: "Ed25519 secret key must be exactly \(SmartAccountConstants.ed25519SecretSeedSize) bytes, " +
                    "got \(secretKeyBytes.count)"
            )
        }

        let keypair: KeyPair
        do {
            let seed = try Seed(bytes: [UInt8](secretKeyBytes))
            keypair = KeyPair(seed: seed)
        } catch {
            throw SmartAccountSignerException.invalid(
                reason: "Failed to construct Ed25519 keypair from raw key bytes: \(describe(error))",
                cause: error
            )
        }

        let publicKey = Data(keypair.publicKey.bytes)
        let storeKey = Ed25519SignerKey(verifierAddress: verifierAddress, publicKey: publicKey)
        ed25519Signers[storeKey] = keypair
        return publicKey
    }

    /// Returns whether a signing source is available for the given Ed25519 signer.
    ///
    /// Checks the adapter first (adapter-first precedence rule). When the adapter returns
    /// `true` for ``OZExternalEd25519SignerAdapter/canSignFor(verifierAddress:publicKey:)``,
    /// this method returns `true` without consulting the in-memory registry. Falls back to
    /// checking whether an in-memory keypair is registered for `(verifierAddress, publicKey)`.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the Ed25519 verifier contract.
    ///   - publicKey: 32-byte Ed25519 public key identifying the signer slot.
    /// - Returns: `true` when a signing source (adapter or in-memory keypair) can sign for
    ///   this `(verifierAddress, publicKey)` pair.
    public func canSignEd25519For(verifierAddress: String, publicKey: Data) -> Bool {
        if let adapter = ed25519Adapter, adapter.canSignFor(verifierAddress: verifierAddress, publicKey: publicKey) {
            return true
        }
        let storeKey = Ed25519SignerKey(verifierAddress: verifierAddress, publicKey: publicKey)
        return ed25519Signers[storeKey] != nil
    }

    /// Produces a 64-byte Ed25519 signature over the supplied auth digest.
    ///
    /// Resolves the signing source using the adapter-first precedence rule: the adapter is
    /// consulted first via ``OZExternalEd25519SignerAdapter/canSignFor(verifierAddress:publicKey:)``.
    /// If the adapter claims it can sign, it is invoked via
    /// ``OZExternalEd25519SignerAdapter/signAuthDigest(authDigest:publicKey:)``. Otherwise
    /// the in-memory keypair registry is used. Throws when neither source is available.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the Ed25519 verifier contract.
    ///   - publicKey: 32-byte Ed25519 public key identifying the signer slot.
    ///   - authDigest: 32-byte auth digest to sign.
    /// - Returns: 64-byte raw Ed25519 signature over `authDigest`.
    /// - Throws: ``SmartAccountValidationException/InvalidInput`` when no signing source is registered;
    ///   ``SmartAccountTransactionException/SigningFailed`` when the adapter or in-memory keypair fails.
    public func signEd25519AuthDigest(
        verifierAddress: String,
        publicKey: Data,
        authDigest: Data
    ) async throws -> Data {
        if let adapter = ed25519Adapter, adapter.canSignFor(verifierAddress: verifierAddress, publicKey: publicKey) {
            // Exit actor isolation for the potentially long-running adapter call.
            let rawSignature: Data
            do {
                rawSignature = try await adapter.signAuthDigest(authDigest: authDigest, publicKey: publicKey)
            } catch {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Ed25519 adapter signing failed for verifier \(verifierAddress): \(SmartAccountException.messageOf(error) ?? "adapter signing failed")",
                    cause: error
                )
            }
            return rawSignature
        }

        // Snapshot the in-memory keypair from actor-isolated state (no await needed here).
        let storeKey = Ed25519SignerKey(verifierAddress: verifierAddress, publicKey: publicKey)
        guard let keypair = ed25519Signers[storeKey] else {
            let prefix = String(verifierAddress.prefix(addressLogPrefixCount))
            throw SmartAccountValidationException.invalidInput(
                field: "selectedSigners",
                reason: "Ed25519 signer (verifier=\(prefix)...) has no signing source. " +
                    "Register a keypair via addEd25519FromRawKey(...), " +
                    "or supply an Ed25519 adapter via config.externalEd25519Adapter at kit construction."
            )
        }

        let signatureBytes = keypair.sign([UInt8](authDigest))
        return Data(signatureBytes)
    }

    /// Removes a registered Ed25519 signer from the in-memory registry.
    ///
    /// Clears the keypair stored under `(verifierAddress, publicKey)`. No-op when no
    /// keypair is registered for that pair. The adapter is not affected by this call.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the Ed25519 verifier contract.
    ///   - publicKey: 32-byte Ed25519 public key identifying the signer slot to remove.
    public func removeEd25519(verifierAddress: String, publicKey: Data) {
        let storeKey = Ed25519SignerKey(verifierAddress: verifierAddress, publicKey: publicKey)
        ed25519Signers.removeValue(forKey: storeKey)
    }

    // MARK: - Private helpers

    /// Signs an auth-entry preimage with an Ed25519 keypair.
    ///
    /// Decodes the base64-encoded `HashIDPreimage` XDR, computes its SHA-256
    /// hash, signs the hash with the keypair, and returns the base64-encoded
    /// raw Ed25519 signature.
    private func signWithKeypair(
        keypair: KeyPair,
        preimageXdrBase64: String,
        address: String
    ) throws -> OZSignAuthEntryResult {

        guard let preimageXdrBytes = Data(base64Encoded: preimageXdrBase64) else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to decode base64 auth entry preimage"
            )
        }

        let payload = preimageXdrBytes.sha256Hash

        // why: A keypair constructed from an account ID / public key only has a
        // nil ``privateKey`` and cannot produce a valid Ed25519 signature.
        // Reject upfront with a clear error rather than letting ``KeyPair.sign``
        // return an all-zero buffer that the caller would have to detect.
        guard keypair.privateKey != nil else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Keypair for \(address) is public-only and cannot sign"
            )
        }

        let signatureBytes = keypair.sign([UInt8](payload))
        let signature = Data(signatureBytes)
        let signatureBase64 = signature.base64EncodedString()

        return OZSignAuthEntryResult(
            signedAuthEntry: signatureBase64,
            signerAddress: address
        )
    }

    /// Best-effort message extraction from an arbitrary error.
    ///
    /// Prefers ``SmartAccountException``'s structured message when available,
    /// then falls back to the platform's `localizedDescription` and finally to
    /// the type's debug description.
    private func describe(_ error: Error) -> String {
        if let smart = error as? SmartAccountException {
            return smart.message
        }
        let localized = error.localizedDescription
        if !localized.isEmpty {
            return localized
        }
        return String(describing: error)
    }
}
