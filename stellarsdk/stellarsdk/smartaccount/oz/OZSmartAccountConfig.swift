//
//  OZSmartAccountConfig.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// Configuration
// ============================================================================

/// Configuration for OpenZeppelin Smart Account operations.
///
/// Defines all parameters required to interact with OpenZeppelin smart accounts on
/// Stellar/Soroban: network connectivity, contract addresses, and operational defaults.
///
/// Example:
/// ```swift
/// let config = try OZSmartAccountConfig(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     networkPassphrase: "Test SDF Network ; September 2015",
///     accountWasmHash: "abc123...",
///     webauthnVerifierAddress: "CBCD1234..."
/// )
///
/// let custom = try OZSmartAccountConfig.builder(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     networkPassphrase: "Test SDF Network ; September 2015",
///     accountWasmHash: "abc123...",
///     webauthnVerifierAddress: "CBCD1234..."
/// )
///     .sessionExpiryMs(86_400_000)
///     .relayerUrl("https://relayer.example.com")
///     .storage(myPersistentStorage)
///     .externalWallet(freighterAdapter)
///     .build()
/// ```
///
/// Throws `ConfigurationException` if required parameters are blank or invalid (for
/// example, `accountWasmHash` is not a 64-character hex string, or
/// `webauthnVerifierAddress` is not a valid C-address).
public struct OZSmartAccountConfig: @unchecked Sendable {

    // MARK: - Required Configuration

    /// The Soroban RPC endpoint URL.
    ///
    /// Example: `https://soroban-testnet.stellar.org`.
    public let rpcUrl: String

    /// The Stellar network passphrase.
    ///
    /// Examples:
    /// - Testnet: `"Test SDF Network ; September 2015"`
    /// - Mainnet: `"Public Global Stellar Network ; September 2015"`
    public let networkPassphrase: String

    /// The WASM hash of the smart account contract (64-character hex string).
    ///
    /// SHA-256 of the smart account contract WASM code, used for deploying new smart
    /// account instances.
    public let accountWasmHash: String

    /// The contract address of the WebAuthn signature verifier (`C…` strkey).
    ///
    /// Validates secp256r1 signatures from WebAuthn / passkeys.
    public let webauthnVerifierAddress: String

    // MARK: - Optional Configuration

    /// The keypair used for deploying smart account contracts.
    ///
    /// When `nil`, a deterministic deployer is derived from
    /// `SHA-256("openzeppelin-smart-account-kit")`. Production apps typically supply a
    /// custom deployer for attribution and traceability. The deployer only pays for
    /// deployment transactions; it does not control user wallets.
    public let deployerKeypair: KeyPair?

    /// Session expiry time in milliseconds.
    ///
    /// Sessions enable silent reconnection without re-authentication.
    public let sessionExpiryMs: Int64

    /// Signature expiration in ledgers for auth entries.
    ///
    /// Auth entries expire after this many ledgers to prevent replay attacks. Default
    /// approximates one hour at five seconds per ledger.
    public let signatureExpirationLedgers: Int

    /// Transaction validity window in seconds.
    ///
    /// Sets each transaction's `TimeBounds` `max_time` to `now + timeoutInSeconds`,
    /// bounding how long a signed transaction stays valid for submission. A value of
    /// `0` means no expiry (infinite): `max_time` is set to `0`, the Stellar sentinel
    /// for "no upper bound". Must be `>= 0`. Default is `30`.
    public let timeoutInSeconds: Int

    /// Optional relayer endpoint URL for fee sponsoring.
    ///
    /// When set, enables gasless transactions by submitting through a fee-bump relayer.
    /// Allows users with empty wallets to transact.
    public let relayerUrl: String?

    /// Optional indexer endpoint URL for credential-to-contract mapping.
    ///
    /// The indexer maps WebAuthn credential IDs to deployed smart account contract
    /// addresses, enabling "Connect Wallet" functionality where users can discover
    /// previously-created wallets.
    public let indexerUrl: String?

    /// Optional WebAuthn provider for passkey authentication.
    ///
    /// Platform-specific implementation that handles WebAuthn registration and
    /// authentication. Required for signing transactions with passkeys.
    public let webauthnProvider: WebAuthnProvider?

    /// Storage adapter for persisting credentials and session data.
    ///
    /// Defaults to `InMemoryStorageAdapter` (non-persistent, suitable for testing).
    public let storage: StorageAdapter

    /// When set, delegates transaction signing to this adapter instead of using WebAuthn credentials.
    public let externalWallet: ExternalWalletAdapter?

    /// Optional adapter for out-of-process Ed25519 signing in multi-signer ceremonies.
    ///
    /// When non-`nil`, the adapter is injected into the kit's ``OZExternalSignerManager`` at
    /// construction time and consulted (with adapter-first precedence) before the in-memory
    /// Ed25519 keypair registry for every
    /// ``SelectedSigner/ed25519(verifierAddress:publicKey:)`` entry. In-memory keypairs can
    /// still be registered at runtime via ``OZSmartAccountKit/externalSigners``
    /// ``OZExternalSignerManager/addEd25519FromRawKey(secretKeyBytes:verifierAddress:)``.
    public let externalEd25519Adapter: OZExternalEd25519SignerAdapter?

    /// Maximum rule ID to scan when iterating context rules.
    ///
    /// The contract assigns monotonically increasing IDs to context rules. When rules
    /// are removed, their IDs leave gaps. Iterating from ID `0` up to this value finds
    /// all active rules. Increase if the account has had many add / remove cycles.
    public let maxContextRuleScanId: UInt32

    // MARK: - Initialization

    /// Initializes a new `OZSmartAccountConfig`.
    ///
    /// - Throws: `ConfigurationException.MissingConfig` for blank required strings;
    ///           `ConfigurationException.InvalidConfig` for malformed `accountWasmHash`
    ///           or `webauthnVerifierAddress`.
    public init(
        rpcUrl: String,
        networkPassphrase: String,
        accountWasmHash: String,
        webauthnVerifierAddress: String,
        deployerKeypair: KeyPair? = nil,
        sessionExpiryMs: Int64 = OZConstants.defaultSessionExpiryMs,
        signatureExpirationLedgers: Int = StellarProtocolConstants.ledgersPerHour,
        timeoutInSeconds: Int = OZConstants.defaultTimeoutSeconds,
        relayerUrl: String? = nil,
        indexerUrl: String? = nil,
        webauthnProvider: WebAuthnProvider? = nil,
        storage: StorageAdapter = InMemoryStorageAdapter(),
        externalWallet: ExternalWalletAdapter? = nil,
        externalEd25519Adapter: OZExternalEd25519SignerAdapter? = nil,
        maxContextRuleScanId: UInt32 = 50
    ) throws {
        if rpcUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ConfigurationException.missingConfig(param: "rpcUrl")
        }
        if networkPassphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ConfigurationException.missingConfig(param: "networkPassphrase")
        }
        if accountWasmHash.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ConfigurationException.missingConfig(param: "accountWasmHash")
        }
        if !OZSmartAccountConfig.isValidWasmHashHex(accountWasmHash) {
            throw ConfigurationException.invalidConfig(
                details: "accountWasmHash must be a 64-character hex string (SHA-256 of WASM), got: \(accountWasmHash)"
            )
        }
        if !webauthnVerifierAddress.isValidContractId() {
            throw ConfigurationException.invalidConfig(
                details: "webauthnVerifierAddress must be a valid contract address (C...), got: \(webauthnVerifierAddress)"
            )
        }

        // why: cap `signatureExpirationLedgers` at 535_680 (the protocol-level
        // ~one-month limit at 5 seconds per ledger) and reject zero / negative
        // values so the signing pass cannot produce an immediately-expired or
        // beyond-protocol-limit expiration ledger.
        if signatureExpirationLedgers < 1 || signatureExpirationLedgers > 535_680 {
            throw ConfigurationException.invalidConfig(
                details: "signatureExpirationLedgers must be in [1, 535680] (one ledger to ~one month at 5s ledgers), got: \(signatureExpirationLedgers)"
            )
        }

        // why: reject only negative values. Zero is a valid Stellar
        // time-bound (`max_time = 0` means no upper bound, i.e. the
        // transaction never expires by time); any positive value sets
        // `max_time = now + timeoutInSeconds`.
        if timeoutInSeconds < 0 {
            throw ConfigurationException.invalidConfig(
                details: "timeoutInSeconds must be >= 0 (0 means no expiry), got: \(timeoutInSeconds)"
            )
        }

        self.rpcUrl = rpcUrl
        self.networkPassphrase = networkPassphrase
        self.accountWasmHash = accountWasmHash
        self.webauthnVerifierAddress = webauthnVerifierAddress
        self.deployerKeypair = deployerKeypair
        self.sessionExpiryMs = sessionExpiryMs
        self.signatureExpirationLedgers = signatureExpirationLedgers
        self.timeoutInSeconds = timeoutInSeconds
        self.relayerUrl = relayerUrl
        self.indexerUrl = indexerUrl
        self.webauthnProvider = webauthnProvider
        self.storage = storage
        self.externalWallet = externalWallet
        self.externalEd25519Adapter = externalEd25519Adapter
        self.maxContextRuleScanId = maxContextRuleScanId
    }

    // MARK: - Static factories

    /// Creates a deterministic deployer keypair for smart account deployment.
    ///
    /// Derives a keypair from `SHA-256("openzeppelin-smart-account-kit")`. The derivation
    /// is deterministic, so the same deployer is produced on every invocation unless
    /// overridden. This keypair only pays deployment fees and does not control user wallets.
    /// Production apps typically supply a custom deployer for attribution and traceability.
    ///
    /// - Returns: A deterministic `KeyPair` for contract deployment.
    /// - Throws: `ConfigurationException.InvalidConfig` if seed generation fails.
    public static func createDefaultDeployer() async throws -> KeyPair {
        // why: the seed must remain byte-stable: the default deployer's contract address
        // is derived from this exact UTF-8 sequence, and changing it would orphan every
        // wallet deployed via the default deployer path.
        let seedString = "openzeppelin-smart-account-kit"
        do {
            let seedBytes = Data(seedString.utf8).sha256Hash
            let seed = try Seed(bytes: [UInt8](seedBytes))
            return KeyPair(seed: seed)
        } catch {
            throw ConfigurationException.invalidConfig(
                details: "Failed to create default deployer keypair: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Creates a builder for constructing `OZSmartAccountConfig` with a fluent API.
    ///
    /// - Parameters:
    ///   - rpcUrl: The Soroban RPC endpoint URL.
    ///   - networkPassphrase: The Stellar network passphrase.
    ///   - accountWasmHash: The smart account contract WASM hash (64-char hex).
    ///   - webauthnVerifierAddress: The WebAuthn verifier contract address (`C…` strkey).
    /// - Returns: A new `Builder` with the four required fields set and defaults
    ///            applied to every optional field.
    public static func builder(
        rpcUrl: String,
        networkPassphrase: String,
        accountWasmHash: String,
        webauthnVerifierAddress: String
    ) -> Builder {
        return Builder(
            rpcUrl: rpcUrl,
            networkPassphrase: networkPassphrase,
            accountWasmHash: accountWasmHash,
            webauthnVerifierAddress: webauthnVerifierAddress
        )
    }

    // MARK: - Instance methods

    /// Returns the deployer keypair, creating the default if needed.
    ///
    /// Async because creating the default deployer involves cryptographic operations
    /// (SHA-256 hashing and Ed25519 seed derivation).
    ///
    /// - Returns: The configured deployer or the default deterministic deployer.
    /// - Throws: `ConfigurationException.InvalidConfig` if default deployer creation
    ///           fails.
    public func effectiveDeployer() async throws -> KeyPair {
        if let configured = deployerKeypair {
            return configured
        }
        return try await OZSmartAccountConfig.createDefaultDeployer()
    }

    /// Returns the indexer URL that will be used after applying fallback logic.
    ///
    /// If an indexer URL is explicitly configured, it is returned. Otherwise the
    /// built-in default for the configured network passphrase is returned, sourced
    /// from `OZIndexerClient.getDefaultUrl(networkPassphrase:)`. Returns `nil` when
    /// no URL is configured and no default exists for the network.
    ///
    /// - Returns: The resolved indexer URL, or `nil`.
    public func effectiveIndexerUrl() -> String? {
        if let explicit = indexerUrl {
            return explicit
        }
        return OZIndexerClient.getDefaultUrl(networkPassphrase: networkPassphrase)
    }

    // MARK: - Private helpers

    /// Validates that the supplied string is exactly 64 hex characters.
    private static func isValidWasmHashHex(_ candidate: String) -> Bool {
        if candidate.count != 64 {
            return false
        }
        for scalar in candidate.unicodeScalars {
            let value = scalar.value
            let isDigit = value >= 0x30 && value <= 0x39
            let isLowerHex = value >= 0x61 && value <= 0x66
            let isUpperHex = value >= 0x41 && value <= 0x46
            if !(isDigit || isLowerHex || isUpperHex) {
                return false
            }
        }
        return true
    }

    // MARK: - Builder

    /// Builder for creating `OZSmartAccountConfig` with a fluent API.
    ///
    /// Example:
    /// ```swift
    /// let config = try OZSmartAccountConfig.builder(
    ///     rpcUrl: "https://soroban-testnet.stellar.org",
    ///     networkPassphrase: "Test SDF Network ; September 2015",
    ///     accountWasmHash: "abc123...",
    ///     webauthnVerifierAddress: "CBCD1234..."
    /// )
    ///     .sessionExpiryMs(86_400_000)
    ///     .relayerUrl("https://relayer.example.com")
    ///     .storage(myPersistentStorage)
    ///     .externalWallet(freighterAdapter)
    ///     .build()
    /// ```
    public final class Builder: @unchecked Sendable {

        private let rpcUrl: String
        private let networkPassphrase: String
        private let accountWasmHash: String
        private let webauthnVerifierAddress: String

        private var _deployerKeypair: KeyPair? = nil
        private var _sessionExpiryMs: Int64 = OZConstants.defaultSessionExpiryMs
        private var _signatureExpirationLedgers: Int = StellarProtocolConstants.ledgersPerHour
        private var _timeoutInSeconds: Int = OZConstants.defaultTimeoutSeconds
        private var _relayerUrl: String? = nil
        private var _indexerUrl: String? = nil
        private var _webauthnProvider: WebAuthnProvider? = nil
        private var _storage: StorageAdapter = InMemoryStorageAdapter()
        private var _externalWallet: ExternalWalletAdapter? = nil
        private var _externalEd25519Adapter: OZExternalEd25519SignerAdapter? = nil
        private var _maxContextRuleScanId: UInt32 = 50

        /// Initializes a new `Builder` with the four required configuration fields.
        ///
        /// - Parameters:
        ///   - rpcUrl: Soroban RPC endpoint URL.
        ///   - networkPassphrase: Stellar network passphrase.
        ///   - accountWasmHash: 64-character hex SHA-256 of the smart account contract WASM.
        ///   - webauthnVerifierAddress: WebAuthn verifier contract address (`C…` strkey).
        public init(
            rpcUrl: String,
            networkPassphrase: String,
            accountWasmHash: String,
            webauthnVerifierAddress: String
        ) {
            self.rpcUrl = rpcUrl
            self.networkPassphrase = networkPassphrase
            self.accountWasmHash = accountWasmHash
            self.webauthnVerifierAddress = webauthnVerifierAddress
        }

        /// Sets the deployer keypair.
        ///
        /// - Parameter value: The deployer keypair (`nil` to use the default).
        /// - Returns: `self` for chaining.
        @discardableResult
        public func deployerKeypair(_ value: KeyPair?) -> Builder {
            _deployerKeypair = value
            return self
        }

        /// Sets the session expiry in milliseconds.
        ///
        /// - Parameter value: The session expiry duration in milliseconds.
        /// - Returns: `self` for chaining.
        @discardableResult
        public func sessionExpiryMs(_ value: Int64) -> Builder {
            _sessionExpiryMs = value
            return self
        }

        /// Sets the signature expiration in ledgers.
        ///
        /// - Parameter value: The signature expiration in ledgers.
        /// - Returns: `self` for chaining.
        @discardableResult
        public func signatureExpirationLedgers(_ value: Int) -> Builder {
            _signatureExpirationLedgers = value
            return self
        }

        /// Sets the operation timeout in seconds.
        ///
        /// - Parameter value: The timeout in seconds.
        /// - Returns: `self` for chaining.
        @discardableResult
        public func timeoutInSeconds(_ value: Int) -> Builder {
            _timeoutInSeconds = value
            return self
        }

        /// Sets the relayer URL.
        ///
        /// - Parameter value: The relayer endpoint URL (`nil` to disable).
        /// - Returns: `self` for chaining.
        @discardableResult
        public func relayerUrl(_ value: String?) -> Builder {
            _relayerUrl = value
            return self
        }

        /// Sets the indexer URL.
        ///
        /// - Parameter value: The indexer endpoint URL (`nil` to disable).
        /// - Returns: `self` for chaining.
        @discardableResult
        public func indexerUrl(_ value: String?) -> Builder {
            _indexerUrl = value
            return self
        }

        /// Sets the WebAuthn provider.
        ///
        /// - Parameter webauthnProvider: The WebAuthn provider (`nil` to disable
        ///                                passkey support).
        /// - Returns: `self` for chaining.
        @discardableResult
        public func webauthnProvider(_ webauthnProvider: WebAuthnProvider?) -> Builder {
            _webauthnProvider = webauthnProvider
            return self
        }

        /// Sets the storage adapter.
        ///
        /// - Parameter storage: The storage adapter for persisting credentials and
        ///                      sessions.
        /// - Returns: `self` for chaining.
        @discardableResult
        public func storage(_ storage: StorageAdapter) -> Builder {
            _storage = storage
            return self
        }

        /// Sets the external wallet adapter.
        ///
        /// - Parameter externalWallet: The external wallet adapter (`nil` to disable
        ///                             external signing).
        /// - Returns: `self` for chaining.
        @discardableResult
        public func externalWallet(_ externalWallet: ExternalWalletAdapter?) -> Builder {
            _externalWallet = externalWallet
            return self
        }

        /// Sets the Ed25519 adapter for out-of-process Ed25519 signing.
        ///
        /// When set, the adapter is injected into the kit's external-signer manager at
        /// construction time and consulted before the in-memory Ed25519 keypair registry.
        ///
        /// - Parameter adapter: The Ed25519 adapter (`nil` to disable adapter-based Ed25519 signing).
        /// - Returns: `self` for chaining.
        @discardableResult
        public func externalEd25519Adapter(_ adapter: OZExternalEd25519SignerAdapter?) -> Builder {
            _externalEd25519Adapter = adapter
            return self
        }

        /// Sets the maximum context-rule ID to scan when iterating rules.
        ///
        /// - Parameter value: The maximum scan ID.
        /// - Returns: `self` for chaining.
        @discardableResult
        public func maxContextRuleScanId(_ value: UInt32) -> Builder {
            _maxContextRuleScanId = value
            return self
        }

        /// Builds the `OZSmartAccountConfig`.
        ///
        /// - Returns: A new `OZSmartAccountConfig` instance.
        /// - Throws: `ConfigurationException` if validation fails.
        public func build() throws -> OZSmartAccountConfig {
            return try OZSmartAccountConfig(
                rpcUrl: rpcUrl,
                networkPassphrase: networkPassphrase,
                accountWasmHash: accountWasmHash,
                webauthnVerifierAddress: webauthnVerifierAddress,
                deployerKeypair: _deployerKeypair,
                sessionExpiryMs: _sessionExpiryMs,
                signatureExpirationLedgers: _signatureExpirationLedgers,
                timeoutInSeconds: _timeoutInSeconds,
                relayerUrl: _relayerUrl,
                indexerUrl: _indexerUrl,
                webauthnProvider: _webauthnProvider,
                storage: _storage,
                externalWallet: _externalWallet,
                externalEd25519Adapter: _externalEd25519Adapter,
                maxContextRuleScanId: _maxContextRuleScanId
            )
        }
    }
}

// MARK: - Equatable

extension OZSmartAccountConfig: Equatable {

    /// Two configurations are equal when every field compares equal.
    ///
    /// `KeyPair` and the protocol-typed `storage`, `webauthnProvider`, and
    /// `externalWallet` fields use reference / instance equality where applicable.
    /// `InMemoryStorageAdapter` overrides equality so all instances of that class
    /// compare equal, which lets two default-constructed configs round-trip through
    /// equality without surprises.
    public static func == (lhs: OZSmartAccountConfig, rhs: OZSmartAccountConfig) -> Bool {
        guard lhs.rpcUrl == rhs.rpcUrl,
              lhs.networkPassphrase == rhs.networkPassphrase,
              lhs.accountWasmHash == rhs.accountWasmHash,
              lhs.webauthnVerifierAddress == rhs.webauthnVerifierAddress,
              lhs.sessionExpiryMs == rhs.sessionExpiryMs,
              lhs.signatureExpirationLedgers == rhs.signatureExpirationLedgers,
              lhs.timeoutInSeconds == rhs.timeoutInSeconds,
              lhs.relayerUrl == rhs.relayerUrl,
              lhs.indexerUrl == rhs.indexerUrl,
              lhs.maxContextRuleScanId == rhs.maxContextRuleScanId
        else {
            return false
        }
        if !keyPairsEqual(lhs.deployerKeypair, rhs.deployerKeypair) {
            return false
        }
        if !storageAdaptersEqual(lhs.storage, rhs.storage) {
            return false
        }
        if !webAuthnProvidersEqual(lhs.webauthnProvider, rhs.webauthnProvider) {
            return false
        }
        if !externalWalletAdaptersEqual(lhs.externalWallet, rhs.externalWallet) {
            return false
        }
        if !externalEd25519AdaptersEqual(lhs.externalEd25519Adapter, rhs.externalEd25519Adapter) {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rpcUrl)
        hasher.combine(networkPassphrase)
        hasher.combine(accountWasmHash)
        hasher.combine(webauthnVerifierAddress)
        hasher.combine(sessionExpiryMs)
        hasher.combine(signatureExpirationLedgers)
        hasher.combine(timeoutInSeconds)
        hasher.combine(relayerUrl)
        hasher.combine(indexerUrl)
        hasher.combine(maxContextRuleScanId)
        hasher.combine(deployerKeypair?.accountId)
        if storage is InMemoryStorageAdapter {
            hasher.combine(InMemoryStorageAdapter.sharedTypeHashTag)
        } else {
            hasher.combine(ObjectIdentifier(storage as AnyObject))
        }
        if let provider = webauthnProvider {
            hasher.combine(ObjectIdentifier(provider as AnyObject))
        }
        if let wallet = externalWallet {
            hasher.combine(ObjectIdentifier(wallet as AnyObject))
        }
        if let adapter = externalEd25519Adapter {
            hasher.combine(ObjectIdentifier(adapter as AnyObject))
        }
    }

    private static func keyPairsEqual(_ lhs: KeyPair?, _ rhs: KeyPair?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            return l.accountId == r.accountId
        default:
            return false
        }
    }

    private static func storageAdaptersEqual(_ lhs: StorageAdapter, _ rhs: StorageAdapter) -> Bool {
        if let l = lhs as? InMemoryStorageAdapter, let r = rhs as? InMemoryStorageAdapter {
            return l == r
        }
        return (lhs as AnyObject) === (rhs as AnyObject)
    }

    private static func webAuthnProvidersEqual(_ lhs: WebAuthnProvider?, _ rhs: WebAuthnProvider?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            return (l as AnyObject) === (r as AnyObject)
        default:
            return false
        }
    }

    private static func externalWalletAdaptersEqual(
        _ lhs: ExternalWalletAdapter?,
        _ rhs: ExternalWalletAdapter?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            return (l as AnyObject) === (r as AnyObject)
        default:
            return false
        }
    }

    private static func externalEd25519AdaptersEqual(
        _ lhs: OZExternalEd25519SignerAdapter?,
        _ rhs: OZExternalEd25519SignerAdapter?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            return (l as AnyObject) === (r as AnyObject)
        default:
            return false
        }
    }
}

extension OZSmartAccountConfig: Hashable {}
