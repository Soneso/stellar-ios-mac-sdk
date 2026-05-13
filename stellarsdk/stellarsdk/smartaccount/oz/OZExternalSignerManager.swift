//
//  OZExternalSignerManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// External Signer Type
// ============================================================================

/// The type of an external signer managed by ``OZExternalSignerManager``.
///
/// External signers fall into two distinct categories: in-memory Ed25519 keypairs
/// and connections to external wallets (for example Freighter or LOBSTR). The
/// manager treats keypair signers as taking precedence over wallet signers when
/// both report the same address.
public enum ExternalSignerType: String, Sendable, Codable, CaseIterable {

    /// Ed25519 keypair-based signer. Stored in memory only, never persisted.
    case keypair = "KEYPAIR"

    /// External wallet signer (for example Freighter or LOBSTR). Connection
    /// metadata can be persisted to ``WalletConnectionStorage`` for session
    /// restoration via ``OZExternalSignerManager/restoreConnections()``.
    case wallet = "WALLET"
}

// ============================================================================
// External Signer Info
// ============================================================================

/// Information about a managed external signer.
///
/// Represents either a keypair-based signer (in-memory Ed25519 key) or a
/// wallet-based signer (external wallet connection). Returned by
/// ``OZExternalSignerManager/getAll()`` and ``OZExternalSignerManager/get(address:)``
/// to report signer details.
///
/// Example:
/// ```swift
/// let signers = await externalSignerManager.getAll()
/// for signer in signers {
///     print("\(signer.address) (\(signer.type))")
///     if signer.type == .wallet {
///         print("  Wallet: \(signer.walletName ?? "unknown")")
///     }
/// }
/// ```
public struct ExternalSignerInfo: Sendable, Codable, Equatable, Hashable {

    /// The Stellar G-address of the signer.
    public let address: String

    /// Whether this signer is a keypair or wallet.
    public let type: ExternalSignerType

    /// Human-readable wallet name (only populated when ``type`` is ``ExternalSignerType/wallet``).
    public let walletName: String?

    /// Wallet identifier for reconnection (only populated when ``type`` is ``ExternalSignerType/wallet``).
    public let walletId: String?

    /// Initializes a new ``ExternalSignerInfo``.
    ///
    /// - Parameters:
    ///   - address: The Stellar G-address of the signer.
    ///   - type: Whether this signer is a keypair or wallet.
    ///   - walletName: Optional human-readable wallet name (wallet signers only).
    ///   - walletId: Optional wallet identifier for reconnection (wallet signers only).
    public init(
        address: String,
        type: ExternalSignerType,
        walletName: String? = nil,
        walletId: String? = nil
    ) {
        self.address = address
        self.type = type
        self.walletName = walletName
        self.walletId = walletId
    }
}

// ============================================================================
// Wallet Connection Storage
// ============================================================================

/// Simple key-value storage interface for persisting external wallet connections.
///
/// Implementations must be safe to call from arbitrary concurrent contexts.
/// Platform-specific implementations can use `UserDefaults`, the iOS Keychain,
/// or any other persistent key-value store. The default in-memory fallback is
/// ``InMemoryWalletConnectionStorage``.
///
/// Example implementation backed by `UserDefaults`:
/// ```swift
/// final class UserDefaultsWalletConnectionStorage: WalletConnectionStorage {
///     private let defaults: UserDefaults
///     init(defaults: UserDefaults = .standard) { self.defaults = defaults }
///
///     func getItem(key: String) async -> String? {
///         defaults.string(forKey: key)
///     }
///
///     func setItem(key: String, value: String) async {
///         defaults.set(value, forKey: key)
///     }
///
///     func removeItem(key: String) async {
///         defaults.removeObject(forKey: key)
///     }
/// }
/// ```
public protocol WalletConnectionStorage: Sendable {

    /// Retrieves a value by key.
    ///
    /// - Parameter key: The storage key.
    /// - Returns: The stored value, or `nil` if the key does not exist.
    func getItem(key: String) async throws -> String?

    /// Stores a value for a key. Overwrites any existing value.
    ///
    /// - Parameters:
    ///   - key: The storage key.
    ///   - value: The value to store.
    func setItem(key: String, value: String) async throws

    /// Removes a value by key. No-op if the key does not exist.
    ///
    /// - Parameter key: The storage key to remove.
    func removeItem(key: String) async throws
}

/// In-memory implementation of ``WalletConnectionStorage``.
///
/// Used as the default when no ``WalletConnectionStorage`` is provided to
/// ``OZExternalSignerManager``. Data is not persisted across application
/// restarts. Access is serialized via Swift actor isolation.
public actor InMemoryWalletConnectionStorage: WalletConnectionStorage {

    private var data: [String: String] = [:]

    /// Creates an empty in-memory storage.
    public init() {}

    public func getItem(key: String) async -> String? {
        return data[key]
    }

    public func setItem(key: String, value: String) async {
        data[key] = value
    }

    public func removeItem(key: String) async {
        data.removeValue(forKey: key)
    }
}

// ============================================================================
// External Signer Manager
// ============================================================================

/// Manager for external (non-passkey) signers used by multi-signature smart account operations.
///
/// ``OZExternalSignerManager`` provides a unified interface for managing Stellar
/// account signers that originate from Ed25519 secret keys or external wallet
/// connections (for example Freighter or LOBSTR). It supports two methods of
/// adding signers:
///
/// 1. **Keypair signers** (via ``addFromSecret(secretKey:)``): created from a raw
///    Ed25519 secret key. These are held in memory only and are never persisted
///    to storage. Secret-key material is reachable only through the in-memory
///    `KeyPair` instance.
/// 2. **Wallet signers** (via ``addFromWallet()``): connected through an
///    ``ExternalWalletAdapter``. Wallet-connection metadata (address, wallet
///    identifier, wallet name) is persisted to ``WalletConnectionStorage`` so
///    that connections can be restored across app launches via
///    ``restoreConnections()``.
///
/// Concurrency:
/// All mutable state is protected by Swift actor isolation. Public methods can
/// be safely awaited from any concurrent context.
///
/// Example usage:
/// ```swift
/// let manager = OZExternalSignerManager(
///     networkPassphrase: Network.testnet.passphrase,
///     walletAdapter: myWalletAdapter,
///     walletConnectionStorage: myStorage
/// )
///
/// // Add from secret key (memory-only)
/// let address = try await manager.addFromSecret(secretKey: "SCZANGBA5YHT...")
/// print("Added keypair signer: \(address)")
///
/// // Add from external wallet
/// if let wallet = try await manager.addFromWallet() {
///     print("Connected wallet: \(wallet.walletName) (\(wallet.address))")
/// }
///
/// // Check signing capability
/// if await manager.canSignFor(address: "GABC...") {
///     let result = try await manager.signAuthEntry(
///         address: "GABC...",
///         authEntry: preimageXdrBase64
///     )
///     print("Signed by: \(result.signerAddress ?? "unknown")")
/// }
///
/// // List all signers
/// let signers = await manager.getAll()
/// ```
public actor OZExternalSignerManager {

    // ------------------------------------------------------------------
    // Public static constants
    // ------------------------------------------------------------------

    /// Storage key under which the manager persists wallet connections in the
    /// supplied ``WalletConnectionStorage``.
    ///
    /// Exposed for diagnostic / migration tooling that needs to reach into the
    /// persisted JSON directly. Production code should prefer the manager API.
    /// The namespaced prefix (`oz_smart_account.`) avoids collisions with other
    /// storage consumers sharing the same backing store.
    public static let walletStorageKey: String = "oz_smart_account.connected_wallets"

    // ------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------

    private let networkPassphrase: String
    private let walletAdapter: ExternalWalletAdapter?
    private let walletConnectionStorage: WalletConnectionStorage?

    // ------------------------------------------------------------------
    // Internal state
    // ------------------------------------------------------------------

    /// Keypair-based signers keyed by G-address. Memory-only, never persisted.
    private var keypairSigners: [String: KeyPair] = [:]

    /// Whether ``restoreConnections()`` has run successfully at least once on
    /// this instance. Used to short-circuit subsequent calls so that storage
    /// is read at most once per session.
    private var restored: Bool = false

    // ------------------------------------------------------------------
    // Initialisation
    // ------------------------------------------------------------------

    /// Initializes a new ``OZExternalSignerManager``.
    ///
    /// - Parameters:
    ///   - networkPassphrase: Stellar network passphrase. Used as signing
    ///     context when delegating to wallet adapters.
    ///   - walletAdapter: Optional wallet adapter. When `nil`, all wallet-related
    ///     operations either throw ``ConfigurationException/MissingConfig`` or
    ///     return empty results.
    ///   - walletConnectionStorage: Optional persistent storage for wallet
    ///     connections. When `nil`, wallet connections live only for the
    ///     duration of the running process.
    public init(
        networkPassphrase: String,
        walletAdapter: ExternalWalletAdapter? = nil,
        walletConnectionStorage: WalletConnectionStorage? = nil
    ) {
        self.networkPassphrase = networkPassphrase
        self.walletAdapter = walletAdapter
        self.walletConnectionStorage = walletConnectionStorage
    }

    // ------------------------------------------------------------------
    // Wallet adapter access
    // ------------------------------------------------------------------

    /// Whether an external wallet adapter is configured.
    ///
    /// Returns `true` when the manager was initialized with a non-`nil`
    /// ``ExternalWalletAdapter``. Wallet-related operations
    /// (``addFromWallet()``, ``restoreConnections()``) require this to be `true`.
    public var hasWalletAdapter: Bool {
        return walletAdapter != nil
    }

    // ------------------------------------------------------------------
    // Add signers
    // ------------------------------------------------------------------

    /// Adds an Ed25519 keypair signer from a raw secret key.
    ///
    /// Creates a `KeyPair` from the provided Stellar secret key (S-address) and
    /// stores it in memory. The keypair is never persisted to storage; it is
    /// lost when the application terminates or the manager is deinitialized.
    ///
    /// If a signer with the same G-address already exists (either keypair or
    /// wallet), the keypair signer takes precedence and overwrites the existing
    /// entry. Any persisted wallet connection for the same address is removed
    /// from storage; without this cleanup the wallet would reappear on the
    /// next ``restoreConnections()`` call.
    ///
    /// - Parameter secretKey: A valid Stellar secret key (S-address, 56 characters).
    /// - Returns: The derived G-address of the signer.
    /// - Throws: ``SignerException/Invalid`` when the secret key is malformed
    ///           or keypair creation otherwise fails.
    public func addFromSecret(secretKey: String) async throws -> String {

        let keypair: KeyPair
        do {
            keypair = try KeyPair(secretSeed: secretKey)
        } catch {
            throw SignerException.invalid(
                reason: "Invalid secret key. Must be a valid Stellar secret key (S...): \(describe(error))",
                cause: error
            )
        }

        let address = keypair.accountId
        keypairSigners[address] = keypair

        // why: keypair signers take precedence at sign time; clearing any wallet
        // entry for this address from storage prevents a future
        // restoreConnections() call from resurrecting the wallet entry and
        // confusing getAll() with two entries for the same address.
        try await removeWalletFromStorage(address: address)

        return address
    }

    /// Connects an external wallet and adds it as a signer.
    ///
    /// Delegates to the configured ``ExternalWalletAdapter`` to prompt the user
    /// for wallet authorization (for example by displaying a wallet-selection
    /// modal). When the connection succeeds and ``WalletConnectionStorage`` is
    /// configured, the connection metadata is persisted for later restoration
    /// via ``restoreConnections()``.
    ///
    /// - Returns: The connected wallet info, or `nil` when the user cancelled
    ///            the connection request.
    /// - Throws: ``ConfigurationException/MissingConfig`` when no wallet adapter
    ///           is configured; rethrows any error raised by the adapter.
    public func addFromWallet() async throws -> ConnectedWallet? {

        guard let adapter = walletAdapter else {
            throw ConfigurationException.missingConfig(
                param: "walletAdapter: No wallet adapter configured. Pass an ExternalWalletAdapter " +
                       "to OZExternalSignerManager to enable wallet connections."
            )
        }

        guard let wallet = try await adapter.connect() else {
            return nil
        }

        if walletConnectionStorage != nil {
            try await saveWalletToStorage(wallet: wallet)
        }

        return wallet
    }

    // ------------------------------------------------------------------
    // Query signers
    // ------------------------------------------------------------------

    /// Checks whether any managed signer can sign for the given address.
    ///
    /// Checks keypair signers first (O(1) map lookup), then delegates to the
    /// wallet adapter's ``ExternalWalletAdapter/canSignFor(address:)`` when
    /// available.
    ///
    /// - Parameter address: The Stellar G-address to check.
    /// - Returns: `true` when a keypair or connected wallet can sign for this address.
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
    public func get(address: String) async -> ExternalSignerInfo? {

        if keypairSigners[address] != nil {
            return ExternalSignerInfo(address: address, type: .keypair)
        }

        if let adapter = walletAdapter,
           let wallet = adapter.getWalletForAddress(address: address) {
            return ExternalSignerInfo(
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
    public func getAll() async -> [ExternalSignerInfo] {

        var signers: [ExternalSignerInfo] = []
        let keypairAddresses = Set(keypairSigners.keys)

        for address in keypairAddresses {
            signers.append(ExternalSignerInfo(address: address, type: .keypair))
        }

        if let adapter = walletAdapter {
            let wallets = adapter.getConnectedWallets()
            for wallet in wallets where !keypairAddresses.contains(wallet.address) {
                signers.append(
                    ExternalSignerInfo(
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

    // ------------------------------------------------------------------
    // Sign auth entry
    // ------------------------------------------------------------------

    /// Signs an authorization-entry preimage with the appropriate signer for the given address.
    ///
    /// For keypair signers, the preimage XDR is base64-decoded, hashed with
    /// SHA-256, and signed directly with the in-memory Ed25519 keypair. For
    /// wallet signers, signing is delegated to
    /// ``ExternalWalletAdapter/signAuthEntry(preimageXdr:options:)``.
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
    /// - Throws: ``SignerException/NotFound`` when no signer is available for
    ///           the address; ``TransactionException/SigningFailed`` when the
    ///           signing operation fails.
    public func signAuthEntry(
        address: String,
        authEntry: String
    ) async throws -> SignAuthEntryResult {

        if let keypair = keypairSigners[address] {
            return try signWithKeypair(
                keypair: keypair,
                preimageXdrBase64: authEntry,
                address: address
            )
        }

        if let adapter = walletAdapter, adapter.canSignFor(address: address) {
            let result: SignAuthEntryResult
            do {
                result = try await adapter.signAuthEntry(
                    preimageXdr: authEntry,
                    options: SignAuthEntryOptions(
                        networkPassphrase: networkPassphrase,
                        address: address
                    )
                )
            } catch {
                throw TransactionException.signingFailed(
                    reason: "External wallet signing failed for \(address): \(describe(error))",
                    cause: error
                )
            }

            // F-SEC-iOS-1: locally verify the wallet adapter's signature
            // against the requested address. Refusing here is far more
            // actionable than the on-chain `auth-failed` we would otherwise
            // see after submission. Failure to decode either the preimage or
            // the signature is treated as a signing failure.
            try verifyExternalWalletSignature(
                preimageXdrBase64: authEntry,
                signatureBase64: result.signedAuthEntry,
                expectedSignerAddress: result.signerAddress ?? address
            )

            return SignAuthEntryResult(
                signedAuthEntry: result.signedAuthEntry,
                signerAddress: result.signerAddress ?? address
            )
        }

        throw SignerException.notFound(signerId: address)
    }

    /// Verifies an external-wallet adapter's signature against the supplied
    /// preimage and signer address.
    ///
    /// Decodes the base64-encoded preimage XDR, computes its SHA-256 hash,
    /// derives the Ed25519 public key from `expectedSignerAddress`, and
    /// verifies the base64-encoded signature against that key. Any failure
    /// (malformed base64, malformed address, signature verification failure)
    /// is surfaced as ``TransactionException/SigningFailed``.
    private func verifyExternalWalletSignature(
        preimageXdrBase64: String,
        signatureBase64: String,
        expectedSignerAddress: String
    ) throws {
        guard let preimageXdrBytes = Data(base64Encoded: preimageXdrBase64) else {
            throw TransactionException.signingFailed(
                reason: "Failed to decode base64 auth entry preimage during verification"
            )
        }
        guard let signatureBytes = Data(base64Encoded: signatureBase64) else {
            throw TransactionException.signingFailed(
                reason: "Wallet adapter returned non-base64 signature for \(expectedSignerAddress)"
            )
        }

        let signerKeyPair: KeyPair
        do {
            signerKeyPair = try KeyPair(accountId: expectedSignerAddress)
        } catch {
            throw TransactionException.signingFailed(
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
            throw TransactionException.signingFailed(
                reason: "Wallet adapter returned signature that does not verify against requested address \(expectedSignerAddress): \(describe(error))",
                cause: error
            )
        }
        if !signatureValid {
            throw TransactionException.signingFailed(
                reason: "Wallet adapter returned signature that does not verify against requested address \(expectedSignerAddress)"
            )
        }
    }

    // ------------------------------------------------------------------
    // Remove signers
    // ------------------------------------------------------------------

    /// Removes a signer by address.
    ///
    /// For keypair signers, removes the keypair from memory. For wallet
    /// signers, removes the connection from storage and calls
    /// ``ExternalWalletAdapter/disconnectByAddress(address:)`` to release the
    /// adapter's runtime state. Both paths run when present, so an address that
    /// is somehow registered as both a keypair and a wallet is fully cleared.
    ///
    /// - Parameter address: The G-address of the signer to remove.
    /// - Throws: Rethrows any error raised by the adapter or storage layer.
    public func remove(address: String) async throws {

        keypairSigners.removeValue(forKey: address)

        try await walletAdapter?.disconnectByAddress(address: address)
        try await removeWalletFromStorage(address: address)
    }

    /// Removes all signers.
    ///
    /// Clears all keypair signers from memory, disconnects all external
    /// wallets, and removes all persisted wallet connections from storage.
    /// This is best-effort with no internal error suppression: failures from
    /// the adapter or storage layer propagate to the caller. The signer
    /// taxonomy intentionally lacks a `removeFailed` arm because the operation
    /// is idempotent on retry.
    ///
    /// - Throws: Rethrows any error raised by the adapter or storage layer.
    public func removeAll() async throws {

        keypairSigners.removeAll()

        try await walletAdapter?.disconnect()
        try await walletConnectionStorage?.removeItem(key: OZExternalSignerManager.walletStorageKey)
    }

    // ------------------------------------------------------------------
    // Wallet connection persistence
    // ------------------------------------------------------------------

    /// Restores previously connected wallets from storage.
    ///
    /// Reads stored wallet-connection metadata from ``WalletConnectionStorage``
    /// and attempts to reconnect each wallet via
    /// ``ExternalWalletAdapter/reconnect(walletId:)``.
    ///
    /// Failure handling is differentiated per F-SEC-iOS-2:
    /// - When `reconnect` returns `nil`, the entry is purged from storage
    ///   because the adapter has reported the wallet as unavailable in a
    ///   definitive way.
    /// - When `reconnect` raises an error, the entry is left in storage on
    ///   the assumption that the failure is transient (network outage,
    ///   pop-up blocked, adapter back-end overload). The next session-reset
    ///   path can re-attempt the restoration.
    ///
    /// This method is idempotent: subsequent calls after the first successful
    /// restoration return the currently connected wallets without re-reading
    /// storage. Idempotency is enforced via an actor-isolated flag, so two
    /// concurrent callers cannot both perform the read-and-reconnect cycle.
    ///
    /// - Returns: List of successfully restored wallet connections.
    /// - Throws: Rethrows storage failures during stale-entry cleanup.
    public func restoreConnections() async throws -> [ConnectedWallet] {

        // why: actor isolation makes this check-and-set atomic; a second
        // concurrent caller observes restored == true and short-circuits.
        let alreadyRestored = restored
        restored = true

        if alreadyRestored {
            return walletAdapter?.getConnectedWallets() ?? []
        }

        guard walletConnectionStorage != nil, let adapter = walletAdapter else {
            return []
        }

        let stored = await getStoredWallets()
        var restoredWallets: [ConnectedWallet] = []

        for savedWallet in stored {
            do {
                if let wallet = try await adapter.reconnect(walletId: savedWallet.walletId) {
                    restoredWallets.append(wallet)
                } else {
                    // why: `reconnect` returning `nil` is a definitive
                    // "wallet is not available" signal from the adapter
                    // (the user revoked authorisation, the wallet was
                    // uninstalled, or the wallet identifier was rotated).
                    // Drop the stale entry so future runs do not keep
                    // retrying the same dead connection.
                    try await removeWalletFromStorage(address: savedWallet.address)
                }
            } catch {
                // why: `reconnect` raising an error is treated as a
                // potentially-transient failure (network outage, adapter
                // backend rate-limiting, browser pop-up blocked, etc.). We
                // intentionally do NOT purge the storage entry here per
                // F-SEC-iOS-2 — purging on transient failure breaks user
                // sessions on a flaky network. The next `restoreConnections`
                // call (after the idempotency flag is reset by the caller's
                // session-reset path) re-attempts the reconnect; the user
                // can also explicitly call `remove(address:)` to drop a
                // stale entry. Storage is left untouched.
            }
        }

        return restoredWallets
    }

    // ------------------------------------------------------------------
    // Private signing helpers
    // ------------------------------------------------------------------

    /// Signs an auth-entry preimage with an Ed25519 keypair.
    ///
    /// Decodes the base64-encoded `HashIDPreimage` XDR, computes its SHA-256
    /// hash, signs the hash with the keypair, and returns the base64-encoded
    /// raw Ed25519 signature.
    private func signWithKeypair(
        keypair: KeyPair,
        preimageXdrBase64: String,
        address: String
    ) throws -> SignAuthEntryResult {

        guard let preimageXdrBytes = Data(base64Encoded: preimageXdrBase64) else {
            throw TransactionException.signingFailed(
                reason: "Failed to decode base64 auth entry preimage"
            )
        }

        let payload = preimageXdrBytes.sha256Hash

        // why: A keypair constructed from an account ID / public key only has a
        // nil ``privateKey`` and cannot produce a valid Ed25519 signature.
        // Reject upfront with a clear error rather than letting ``KeyPair.sign``
        // return an all-zero buffer that the caller would have to detect.
        guard keypair.privateKey != nil else {
            throw TransactionException.signingFailed(
                reason: "Keypair for \(address) is public-only and cannot sign"
            )
        }

        let signatureBytes = keypair.sign([UInt8](payload))
        let signature = Data(signatureBytes)
        let signatureBase64 = signature.base64EncodedString()

        return SignAuthEntryResult(
            signedAuthEntry: signatureBase64,
            signerAddress: address
        )
    }

    // ------------------------------------------------------------------
    // Private storage helpers
    // ------------------------------------------------------------------

    /// Stored wallet-connection record persisted to ``WalletConnectionStorage``.
    ///
    /// Internal implementation detail; never part of the manager's public
    /// surface. Codable-synthesized JSON shape is the long-term wire format
    /// for persisted external-wallet sessions.
    internal struct StoredWalletConnection: Sendable, Codable, Equatable, Hashable {
        let address: String
        let walletId: String
        let walletName: String
        let connectedAt: Int64
    }

    /// Reads stored wallet connections from storage.
    ///
    /// Parses the JSON array stored under ``OZExternalSignerManager.walletStorageKey``. Returns an
    /// empty list when storage is not configured, the key does not exist, or
    /// parsing fails.
    private func getStoredWallets() async -> [StoredWalletConnection] {

        guard let storage = walletConnectionStorage else { return [] }

        do {
            guard let data = try await storage.getItem(key: OZExternalSignerManager.walletStorageKey) else {
                return []
            }
            return parseStoredWallets(jsonString: data)
        } catch {
            return []
        }
    }

    /// Saves a wallet connection to storage.
    ///
    /// Performs upsert semantics: when a connection with the same address
    /// already exists, it is replaced. The connection list is serialized as a
    /// JSON array.
    private func saveWalletToStorage(wallet: ConnectedWallet) async throws {

        guard let storage = walletConnectionStorage else { return }

        var stored = await getStoredWallets()
        stored.removeAll { $0.address == wallet.address }
        stored.append(
            StoredWalletConnection(
                address: wallet.address,
                walletId: wallet.walletId,
                walletName: wallet.walletName,
                connectedAt: currentTimeMillis()
            )
        )

        let serialized = try serializeWallets(stored)
        try await storage.setItem(key: OZExternalSignerManager.walletStorageKey, value: serialized)
    }

    /// Removes a wallet connection from storage by address.
    ///
    /// When no connections remain after the removal, deletes the storage key
    /// entirely rather than writing an empty array. This keeps a fresh-install
    /// representation indistinguishable from a fully-cleared store.
    private func removeWalletFromStorage(address: String) async throws {

        guard let storage = walletConnectionStorage else { return }

        var stored = await getStoredWallets()
        let originalCount = stored.count
        stored.removeAll { $0.address == address }

        if stored.count == originalCount {
            return
        }

        if stored.isEmpty {
            try await storage.removeItem(key: OZExternalSignerManager.walletStorageKey)
        } else {
            let serialized = try serializeWallets(stored)
            try await storage.setItem(key: OZExternalSignerManager.walletStorageKey, value: serialized)
        }
    }

    // ------------------------------------------------------------------
    // JSON serialization
    // ------------------------------------------------------------------

    /// Serializes wallet connections to a JSON array string.
    ///
    /// Encodes a `[StoredWalletConnection]` to UTF-8 JSON via `JSONEncoder`,
    /// then converts the resulting `Data` to `String`. The output is a flat
    /// JSON array suitable for storage in any string-valued key-value store.
    private func serializeWallets(_ wallets: [StoredWalletConnection]) throws -> String {

        let encoder = JSONEncoder()
        // why: ordering of object keys is irrelevant for the persisted
        // shape; sorting them produces stable on-disk output across encoder
        // versions, which keeps backward-compatibility checks deterministic.
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(wallets)
        guard let string = String(data: data, encoding: .utf8) else {
            throw TransactionException.signingFailed(
                reason: "Failed to encode wallet connections to UTF-8 JSON"
            )
        }
        return string
    }

    /// Parses wallet connections from a JSON array string.
    ///
    /// Parses atomically: when the JSON is malformed, returns an empty list
    /// rather than partial results. Atomic-failure semantics are acceptable
    /// because the serializer always produces valid JSON; encountering
    /// malformed JSON indicates external corruption, not partial writes from
    /// this manager.
    private func parseStoredWallets(jsonString: String) -> [StoredWalletConnection] {

        guard let data = jsonString.data(using: .utf8) else { return [] }

        do {
            return try JSONDecoder().decode([StoredWalletConnection].self, from: data)
        } catch {
            return []
        }
    }

    // ------------------------------------------------------------------
    // Misc helpers
    // ------------------------------------------------------------------

    /// Current wall-clock time in milliseconds since the Unix epoch.
    private func currentTimeMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000.0)
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
