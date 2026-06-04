//
//  OZStorageAdapter.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation


/// The deployment status of a smart account credential.
public enum OZCredentialDeploymentStatus: String, Sendable, CaseIterable {

    case pending = "PENDING"

    case failed = "FAILED"

    // why: there is no `success` arm because a credential is deleted from storage on
    // successful deployment, so the only persistent post-creation states a stored
    // credential can occupy are PENDING and FAILED.
}


/// A stored smart account credential with deployment and usage metadata.
///
/// Represents a WebAuthn credential (passkey) associated with a smart account. Tracks
/// the credential's deployment status, contract address, and usage history.
///
/// Example:
/// ```swift
/// let credential = OZStoredCredential(
///     credentialId: "base64url-encoded-id",
///     publicKey: secp256r1PublicKeyData,
///     contractId: "CBCD1234...",
///     deploymentStatus: .pending,
///     isPrimary: true
/// )
/// ```
public struct OZStoredCredential: Sendable {

    /// The WebAuthn credential ID (Base64URL encoded).
    public let credentialId: String

    /// The uncompressed secp256r1 public key (65 bytes, `0x04`-prefixed).
    public let publicKey: Data

    /// The smart account contract address (`C…` strkey).
    ///
    /// Set during wallet creation. `nil` if the contract address has not been derived
    /// yet.
    public let contractId: String?

    /// The current deployment status of the smart account contract.
    public let deploymentStatus: OZCredentialDeploymentStatus

    /// Error message if deployment failed.
    public let deploymentError: String?

    /// Timestamp of when this credential was created (milliseconds since epoch).
    public let createdAt: Int64

    /// Timestamp of when this credential was last used for signing
    /// (milliseconds since epoch).
    ///
    /// Updated after successful transaction signatures.
    public let lastUsedAt: Int64?

    /// Optional user-friendly nickname for this credential.
    ///
    /// Example: `"MacBook Pro Touch ID"`, `"YubiKey 5"`.
    public let nickname: String?

    /// Whether this is the primary credential for this smart account.
    ///
    /// The primary credential is used as the default for signing operations.
    public let isPrimary: Bool

    /// Authenticator transport hints indicating how the platform can communicate with
    /// the authenticator (for example `"usb"`, `"nfc"`, `"ble"`, `"internal"`).
    ///
    /// Used when constructing `allowCredentials` for future authentication ceremonies,
    /// which helps the platform select the correct authenticator more efficiently.
    public let transports: [String]?

    /// Authenticator device type.
    ///
    /// - `"singleDevice"`: hardware security key (not synced).
    /// - `"multiDevice"`: synced / cloud-backed passkey (available across devices).
    ///
    /// Corresponds to the `credentialDeviceType` field in WebAuthn authenticator data
    /// flags.
    public let deviceType: String?

    /// Whether the passkey is backed up or synced to a cloud provider.
    ///
    /// When `true`, the credential is available across the user's devices via iCloud
    /// Keychain, Google Password Manager, or similar sync services. Corresponds to the
    /// `credentialBackedUp` flag in WebAuthn authenticator data.
    public let backedUp: Bool?

    public init(
        credentialId: String,
        publicKey: Data,
        contractId: String? = nil,
        deploymentStatus: OZCredentialDeploymentStatus = .pending,
        deploymentError: String? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastUsedAt: Int64? = nil,
        nickname: String? = nil,
        isPrimary: Bool = false,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    ) {
        self.credentialId = credentialId
        self.publicKey = publicKey
        self.contractId = contractId
        self.deploymentStatus = deploymentStatus
        self.deploymentError = deploymentError
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.nickname = nickname
        self.isPrimary = isPrimary
        self.transports = transports
        self.deviceType = deviceType
        self.backedUp = backedUp
    }

    /// Returns a copy of this credential with the supplied fields replaced.
    ///
    /// Each parameter that is `nil` leaves the corresponding field unchanged. To
    /// reset a value to `nil`, construct a new `OZStoredCredential` directly rather
    /// than using `copyWith`.
    public func copyWith(
        credentialId: String? = nil,
        publicKey: Data? = nil,
        contractId: String? = nil,
        deploymentStatus: OZCredentialDeploymentStatus? = nil,
        deploymentError: String? = nil,
        createdAt: Int64? = nil,
        lastUsedAt: Int64? = nil,
        nickname: String? = nil,
        isPrimary: Bool? = nil,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    ) -> OZStoredCredential {
        return OZStoredCredential(
            credentialId: credentialId ?? self.credentialId,
            publicKey: publicKey ?? self.publicKey,
            contractId: contractId ?? self.contractId,
            deploymentStatus: deploymentStatus ?? self.deploymentStatus,
            deploymentError: deploymentError ?? self.deploymentError,
            createdAt: createdAt ?? self.createdAt,
            lastUsedAt: lastUsedAt ?? self.lastUsedAt,
            nickname: nickname ?? self.nickname,
            isPrimary: isPrimary ?? self.isPrimary,
            transports: transports ?? self.transports,
            deviceType: deviceType ?? self.deviceType,
            backedUp: backedUp ?? self.backedUp
        )
    }

    /// Returns a new credential with non-nil fields from `updates` applied to this
    /// credential.
    ///
    /// Fields in `updates` that are `nil` are left unchanged. This is the partial-update
    /// semantic that `OZStorageAdapter.update` uses internally.
    public func applyUpdate(_ updates: OZStoredCredentialUpdate) -> OZStoredCredential {
        return OZStoredCredential(
            credentialId: credentialId,
            publicKey: publicKey,
            contractId: updates.contractId ?? contractId,
            deploymentStatus: updates.deploymentStatus ?? deploymentStatus,
            deploymentError: updates.deploymentError ?? deploymentError,
            createdAt: createdAt,
            lastUsedAt: updates.lastUsedAt ?? lastUsedAt,
            nickname: updates.nickname ?? nickname,
            isPrimary: updates.isPrimary ?? isPrimary,
            transports: updates.transports ?? transports,
            deviceType: updates.deviceType ?? deviceType,
            backedUp: updates.backedUp ?? backedUp
        )
    }
}

extension OZStoredCredential: Equatable {

    /// Two stored credentials are equal when every field matches.
    ///
    /// The `publicKey` field is compared in constant time so timing measurements do
    /// not leak how many leading bytes of two compared keys agree, which protects
    /// secret-bearing byte sequences from side-channel inference.
    public static func == (lhs: OZStoredCredential, rhs: OZStoredCredential) -> Bool {
        guard lhs.credentialId == rhs.credentialId else { return false }
        guard lhs.publicKey.constantTimeEquals(rhs.publicKey) else { return false }
        guard lhs.contractId == rhs.contractId else { return false }
        guard lhs.deploymentStatus == rhs.deploymentStatus else { return false }
        guard lhs.deploymentError == rhs.deploymentError else { return false }
        guard lhs.createdAt == rhs.createdAt else { return false }
        guard lhs.lastUsedAt == rhs.lastUsedAt else { return false }
        guard lhs.nickname == rhs.nickname else { return false }
        guard lhs.isPrimary == rhs.isPrimary else { return false }
        guard lhs.transports == rhs.transports else { return false }
        guard lhs.deviceType == rhs.deviceType else { return false }
        guard lhs.backedUp == rhs.backedUp else { return false }
        return true
    }
}

extension OZStoredCredential: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(credentialId)
        hasher.combine(publicKey)
        hasher.combine(contractId)
        hasher.combine(deploymentStatus)
        hasher.combine(deploymentError)
        hasher.combine(createdAt)
        hasher.combine(lastUsedAt)
        hasher.combine(nickname)
        hasher.combine(isPrimary)
        hasher.combine(transports)
        hasher.combine(deviceType)
        hasher.combine(backedUp)
    }
}


/// A stored user session for silent reconnection.
///
/// Sessions enable users to reconnect to their smart account wallet without
/// re-authentication, as long as the session has not expired.
///
/// Example:
/// ```swift
/// let now = Int64(Date().timeIntervalSince1970 * 1000)
/// let session = OZStoredSession(
///     credentialId: "base64url-encoded-id",
///     contractId: "CBCD1234...",
///     connectedAt: now,
///     expiresAt: now + 7 * 24 * 60 * 60 * 1000
/// )
///
/// if !session.isExpired {
///     // Silently reconnect.
/// }
/// ```
public struct OZStoredSession: Sendable, Equatable, Hashable {

    public let credentialId: String
    public let contractId: String
    public let connectedAt: Int64
    public let expiresAt: Int64

    public init(
        credentialId: String,
        contractId: String,
        connectedAt: Int64,
        expiresAt: Int64
    ) {
        self.credentialId = credentialId
        self.contractId = contractId
        self.connectedAt = connectedAt
        self.expiresAt = expiresAt
    }

    /// Whether the session has expired (the current wall-clock millisecond timestamp
    /// is at or past `expiresAt`).
    public var isExpired: Bool {
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        return nowMs >= expiresAt
    }
}


/// Partial updates for a stored credential.
///
/// Only non-nil fields are applied during an update operation. A `nil` value means
/// "no change" — it does **not** clear the field to nil. This is a deliberate design
/// choice: there is no way to set a previously non-nil field back to nil via
/// `OZStorageAdapter.update`. To reset a field, call `OZStorageAdapter.save` with a full
/// `OZStoredCredential` replacement.
///
/// Example:
/// ```swift
/// let update = OZStoredCredentialUpdate(
///     deploymentStatus: .failed,
///     deploymentError: "Transaction failed: insufficient balance"
/// )
/// try await storage.update(credentialId: "abc123", updates: update)
/// ```
public struct OZStoredCredentialUpdate: Sendable, Equatable, Hashable {

    public let deploymentStatus: OZCredentialDeploymentStatus?
    public let deploymentError: String?
    public let contractId: String?
    public let lastUsedAt: Int64?
    public let nickname: String?
    public let isPrimary: Bool?
    public let transports: [String]?
    public let deviceType: String?
    public let backedUp: Bool?

    public init(
        deploymentStatus: OZCredentialDeploymentStatus? = nil,
        deploymentError: String? = nil,
        contractId: String? = nil,
        lastUsedAt: Int64? = nil,
        nickname: String? = nil,
        isPrimary: Bool? = nil,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    ) {
        self.deploymentStatus = deploymentStatus
        self.deploymentError = deploymentError
        self.contractId = contractId
        self.lastUsedAt = lastUsedAt
        self.nickname = nickname
        self.isPrimary = isPrimary
        self.transports = transports
        self.deviceType = deviceType
        self.backedUp = backedUp
    }
}


/// Protocol for persisting smart account credentials and sessions.
///
/// Storage adapters provide a pluggable persistence layer for credentials and sessions.
/// Implementations must be thread-safe and support concurrent access.
///
/// The default implementation is `OZInMemoryStorageAdapter`, which stores data in memory
/// only. Platform-specific implementations can provide persistent storage.
public protocol OZStorageAdapter: AnyObject, Sendable {

    /// Saves a credential to storage using upsert semantics.
    ///
    /// If a credential with the same ID already exists, it is overwritten.
    ///
    /// - Parameter credential: The credential to save.
    /// - Throws: `SmartAccountStorageException.WriteFailed` if saving fails.
    func save(credential: OZStoredCredential) async throws

    /// Retrieves a credential by its ID.
    ///
    /// - Parameter credentialId: The credential ID.
    /// - Returns: The credential, or `nil` if not found.
    /// - Throws: `SmartAccountStorageException.ReadFailed` if reading fails.
    func get(credentialId: String) async throws -> OZStoredCredential?

    /// Retrieves all credentials associated with a contract address.
    ///
    /// - Parameter contractId: The contract address.
    /// - Returns: List of credentials (empty if none found).
    /// - Throws: `SmartAccountStorageException.ReadFailed` if reading fails.
    func getByContract(contractId: String) async throws -> [OZStoredCredential]

    /// Retrieves all stored credentials.
    ///
    /// - Returns: List of all credentials.
    /// - Throws: `SmartAccountStorageException.ReadFailed` if reading fails.
    func getAll() async throws -> [OZStoredCredential]

    /// Deletes a credential by its ID. Does nothing if the credential does not exist.
    ///
    /// - Parameter credentialId: The credential ID to delete.
    /// - Throws: `SmartAccountStorageException.WriteFailed` if deletion fails.
    func delete(credentialId: String) async throws

    /// Updates a credential with partial changes. Only non-nil fields in the update
    /// are applied.
    ///
    /// - Parameters:
    ///   - credentialId: The credential ID to update.
    ///   - updates: The partial updates to apply.
    /// - Throws: `SmartAccountCredentialException.NotFound` if the credential is not found;
    ///           `SmartAccountStorageException.WriteFailed` if updating fails.
    func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws

    /// Clears all credentials AND the stored session from storage. Equivalent
    /// to a hard reset of the adapter's contents.
    ///
    /// - Throws: `SmartAccountStorageException.WriteFailed` if clearing fails.
    func clear() async throws

    /// Saves a session to storage. Overwrites any previously stored session.
    ///
    /// - Parameter session: The session to save.
    /// - Throws: `SmartAccountStorageException.WriteFailed` if saving fails.
    func saveSession(_ session: OZStoredSession) async throws

    /// Retrieves the current session, returning `nil` when no session exists or when
    /// the stored session has expired. Expired sessions are auto-cleared on read.
    ///
    /// - Returns: The session, or `nil` if no session exists or the session is expired.
    /// - Throws: `SmartAccountStorageException.ReadFailed` if reading fails.
    func getSession() async throws -> OZStoredSession?

    /// Clears the current session.
    ///
    /// - Throws: `SmartAccountStorageException.WriteFailed` if clearing fails.
    func clearSession() async throws
}


/// In-memory storage adapter for credentials and sessions.
///
/// Stores all data in memory and does not persist across application restarts.
/// Thread-safe via Swift Concurrency actor isolation.
///
/// Use `OZKeychainStorageAdapter` for persistent encrypted storage on Apple platforms
/// (Keychain Services), or `OZUserDefaultsStorageAdapter` for non-sensitive metadata.
///
/// All `OZInMemoryStorageAdapter` instances are considered equal because two
/// freshly-created instances are functionally identical (both empty), so they are
/// interchangeable as default values in configuration data structures.
///
/// Example:
/// ```swift
/// let storage = OZInMemoryStorageAdapter()
/// let credential = OZStoredCredential(...)
/// try await storage.save(credential: credential)
/// ```
///
/// - Important: Not persistent and not secure. Data is held in process memory only,
///   is lost on application termination, and is not encrypted at rest. Suitable for
///   tests and ephemeral demos. Production applications must supply a persistent,
///   encrypted storage adapter (for example a Keychain-backed implementation on
///   Apple platforms).
public final actor OZInMemoryStorageAdapter: OZStorageAdapter {

    /// Type-level hash tag used by `Hashable` consumers that want a stable hash for
    /// any `OZInMemoryStorageAdapter` instance regardless of identity.
    nonisolated internal static let sharedTypeHashTag: String = "OZInMemoryStorageAdapter"

    private var credentials: [String: OZStoredCredential] = [:]
    private var session: OZStoredSession? = nil

    /// Initializes a new empty in-memory storage adapter.
    public init() {}

    public func save(credential: OZStoredCredential) async throws {
        credentials[credential.credentialId] = credential
    }

    public func get(credentialId: String) async throws -> OZStoredCredential? {
        return credentials[credentialId]
    }

    public func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        return credentials.values.filter { $0.contractId == contractId }
    }

    public func getAll() async throws -> [OZStoredCredential] {
        return Array(credentials.values)
    }

    public func delete(credentialId: String) async throws {
        credentials.removeValue(forKey: credentialId)
    }

    public func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        guard let existing = credentials[credentialId] else {
            throw SmartAccountCredentialException.notFound(credentialId: credentialId)
        }
        credentials[credentialId] = existing.applyUpdate(updates)
    }

    public func clear() async throws {
        credentials.removeAll()
    }

    public func saveSession(_ session: OZStoredSession) async throws {
        self.session = session
    }

    public func getSession() async throws -> OZStoredSession? {
        // why: an expired session is treated as if no session exists; it is also
        // dropped from storage on read so a subsequent read does not need to
        // re-evaluate expiry against the same stale entry. Callers receive the
        // simple "valid session OR nil" contract.
        if let current = session, current.isExpired {
            session = nil
            return nil
        }
        return session
    }

    public func clearSession() async throws {
        session = nil
    }
}

extension OZInMemoryStorageAdapter: Equatable {

    /// All `OZInMemoryStorageAdapter` instances compare equal.
    ///
    /// Two freshly-constructed instances are functionally indistinguishable (both
    /// empty), and this equivalence is what makes structural equality on
    /// configuration types behave intuitively when the default in-memory adapter is
    /// used in two configurations that are otherwise equal.
    public nonisolated static func == (lhs: OZInMemoryStorageAdapter, rhs: OZInMemoryStorageAdapter) -> Bool {
        return true
    }
}

extension OZInMemoryStorageAdapter: Hashable {

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(OZInMemoryStorageAdapter.sharedTypeHashTag)
    }
}


/// Information about an externally connected wallet.
///
/// Returned by `OZExternalWalletAdapter.connect` and
/// `OZExternalWalletAdapter.getConnectedWallets` to identify which wallet is connected
/// and its signing address.
///
/// Example:
/// ```swift
/// let wallet = OZConnectedWallet(
///     address: "GABC123...",
///     walletId: "freighter",
///     walletName: "Freighter"
/// )
/// ```
public struct OZConnectedWallet: Sendable, Equatable, Hashable {

    /// The Stellar G-address of the connected wallet.
    public let address: String

    /// Unique wallet identifier (for example `"freighter"`, `"lobstr"`). Used for
    /// reconnection via `OZExternalWalletAdapter.reconnect`.
    public let walletId: String

    /// Human-readable display name for the wallet (for example `"Freighter"`,
    /// `"LOBSTR"`).
    public let walletName: String

    /// Initializes a new `OZConnectedWallet`.
    public init(address: String, walletId: String, walletName: String) {
        self.address = address
        self.walletId = walletId
        self.walletName = walletName
    }
}


/// Options for signing an authorization entry with an external wallet.
///
/// Allows specifying a network passphrase and a particular address when multiple
/// wallets are connected.
public struct OZSignAuthEntryOptions: Sendable, Equatable, Hashable {

    /// Network passphrase for signing context.
    public let networkPassphrase: String?

    /// Specific address to sign with, when multiple wallets are connected.
    public let address: String?

    /// Initializes a new `OZSignAuthEntryOptions`.
    public init(networkPassphrase: String? = nil, address: String? = nil) {
        self.networkPassphrase = networkPassphrase
        self.address = address
    }
}

/// Result of signing an authorization preimage with an external wallet.
///
/// Contains the raw Ed25519 signature and optionally the signer address, which may
/// differ from the requested address in some wallet implementations.
public struct OZSignAuthEntryResult: Sendable, Equatable, Hashable {

    /// The base64-encoded raw Ed25519 signature (64 bytes).
    ///
    /// The wallet hashes the preimage with SHA-256 and signs the resulting 32-byte
    /// payload with Ed25519. This field contains the 64-byte signature.
    public let signedAuthEntry: String

    /// The Stellar G-address that produced the signature, or `nil` when the wallet
    /// does not report a signer address.
    public let signerAddress: String?

    /// Initializes a new `OZSignAuthEntryResult`.
    public init(signedAuthEntry: String, signerAddress: String? = nil) {
        self.signedAuthEntry = signedAuthEntry
        self.signerAddress = signerAddress
    }
}


/// Protocol for integrating external wallet adapters for multi-signer support.
///
/// External wallet adapters enable signing with external wallets like Freighter or
/// Albedo for multi-signature smart accounts. They handle wallet connection, signature
/// collection, and wallet reconnection.
///
/// Example implementation:
/// ```swift
/// final class FreighterAdapter: OZExternalWalletAdapter {
///     func connect() async throws -> OZConnectedWallet? {
///         return OZConnectedWallet(address: "G...", walletId: "freighter", walletName: "Freighter")
///     }
///     func signAuthEntry(
///         preimageXdr: String,
///         options: OZSignAuthEntryOptions?
///     ) async throws -> OZSignAuthEntryResult {
///         // Decode preimage, hash with SHA-256, sign with Ed25519, return result.
///     }
///     // ... remaining members ...
/// }
/// ```
public protocol OZExternalWalletAdapter: AnyObject, Sendable {

    /// Connects to the external wallet, prompting the user to authorize via the
    /// wallet's UI (for example a wallet selection modal).
    ///
    /// - Returns: The connected wallet info, or `nil` if the user cancelled.
    /// - Throws: `SmartAccountWalletException` if connection fails.
    func connect() async throws -> OZConnectedWallet?

    /// Disconnects all external wallets.
    ///
    /// - Throws: `SmartAccountWalletException` if disconnection fails.
    func disconnect() async throws

    /// Disconnects a specific wallet by address. The default implementation is a no-op
    /// suitable for adapters that do not need per-address cleanup.
    ///
    /// - Parameter address: The Stellar G-address of the wallet to disconnect.
    func disconnectByAddress(address: String) async throws

    /// Signs an authorization preimage with the external wallet.
    ///
    /// The SDK passes a base64-encoded `HashIDPreimage` XDR. The wallet must:
    /// 1. Base64-decode the preimage bytes.
    /// 2. SHA-256 hash the preimage bytes.
    /// 3. Ed25519-sign the 32-byte hash.
    /// 4. Return the 64-byte raw signature as base64.
    ///
    /// The SDK handles auth-entry construction and signature format; the wallet only
    /// needs to produce the raw Ed25519 signature.
    ///
    /// - Parameters:
    ///   - preimageXdr: The base64-encoded `HashIDPreimage` XDR to sign.
    ///   - options: Optional signing options (network passphrase, specific address).
    /// - Returns: The signing result with base64-encoded raw Ed25519 signature
    ///            (64 bytes).
    /// - Throws: `SmartAccountTransactionException.SigningFailed` if signing fails or is rejected.
    func signAuthEntry(
        preimageXdr: String,
        options: OZSignAuthEntryOptions?
    ) async throws -> OZSignAuthEntryResult

    /// Returns all currently connected wallets with their addresses and identifiers.
    func getConnectedWallets() -> [OZConnectedWallet]

    /// Returns whether a specific address has a connected wallet that can sign for it.
    func canSignFor(address: String) -> Bool

    /// Returns wallet info for a specific address, or `nil` when not found.
    ///
    /// The default implementation returns `nil`.
    func getWalletForAddress(address: String) -> OZConnectedWallet?

    /// Reconnects to a previously connected wallet by its wallet ID, returning the
    /// reconnected wallet info, or `nil` if reconnection failed or is not supported.
    ///
    /// The default implementation returns `nil`.
    func reconnect(walletId: String) async throws -> OZConnectedWallet?
}

public extension OZExternalWalletAdapter {

    func disconnectByAddress(address: String) async throws {
        // why: most adapters do not maintain per-address runtime state, so the
        // default behaviour is intentionally a no-op; adapters that do hold
        // per-signer state override this method to free that state.
    }

    func getWalletForAddress(address: String) -> OZConnectedWallet? {
        return nil
    }

    func reconnect(walletId: String) async throws -> OZConnectedWallet? {
        return nil
    }
}
