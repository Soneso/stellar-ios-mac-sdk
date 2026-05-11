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
///     .rpName("My Custom Wallet")
///     .sessionExpiryMs(86_400_000)
///     .relayerUrl("https://relayer.example.com")
///     .storage(myPersistentStorage)
///     .externalWallet(freighterAdapter)
///     .build()
/// ```
///
/// | Field | Required | Default |
/// |-------|----------|---------|
/// | rpcUrl | Yes | - |
/// | networkPassphrase | Yes | - |
/// | accountWasmHash | Yes | - |
/// | webauthnVerifierAddress | Yes | - |
/// | deployerKeypair | No | Deterministic deployer |
/// | rpId | No | Browser default |
/// | rpName | No | "Smart Account" |
/// | sessionExpiryMs | No | 604_800_000 (7 days) |
/// | signatureExpirationLedgers | No | 720 (~1 hour) |
/// | timeoutInSeconds | No | 30 |
/// | relayerUrl | No | nil |
/// | indexerUrl | No | nil |
/// | webauthnProvider | No | nil |
/// | storage | No | InMemoryStorageAdapter |
/// | externalWallet | No | nil |
/// | maxContextRuleScanId | No | 50 |
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

    /// The WebAuthn Relying Party ID (`rpId`).
    ///
    /// Should match the domain where WebAuthn credentials are created. When `nil`, the
    /// browser uses the current domain.
    public let rpId: String?

    /// The WebAuthn Relying Party name displayed to users during authentication.
    public let rpName: String

    /// Session expiry time in milliseconds.
    ///
    /// Sessions enable silent reconnection without re-authentication.
    public let sessionExpiryMs: Int64

    /// Signature expiration in ledgers for auth entries.
    ///
    /// Auth entries expire after this many ledgers to prevent replay attacks. Default
    /// approximates one hour at five seconds per ledger.
    public let signatureExpirationLedgers: Int

    /// Default timeout for operations in seconds.
    ///
    /// Used for network requests and transaction submission.
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

    /// External wallet adapter for signing transactions with an external signer.
    ///
    /// When set, the kit delegates transaction signing to this adapter instead of using
    /// WebAuthn credentials.
    public let externalWallet: ExternalWalletAdapter?

    /// Maximum rule ID to scan when iterating context rules.
    ///
    /// The contract assigns monotonically increasing IDs to context rules. When rules
    /// are removed, their IDs leave gaps. Iterating from ID `0` up to this value finds
    /// all active rules. Increase if the account has had many add / remove cycles.
    public let maxContextRuleScanId: UInt32

    // MARK: - Initialization

    /// Initializes a new `OZSmartAccountConfig`.
    ///
    /// - Parameters:
    ///   - rpcUrl: Soroban RPC endpoint URL (required, must not be blank).
    ///   - networkPassphrase: Stellar network passphrase (required, must not be blank).
    ///   - accountWasmHash: 64-character hex SHA-256 of the smart account contract WASM
    ///     (required, must not be blank, must match `[0-9a-fA-F]{64}`).
    ///   - webauthnVerifierAddress: Contract address (`C…` strkey) of the WebAuthn
    ///     verifier (required, must be a valid `C…` strkey).
    ///   - deployerKeypair: Optional deployer keypair; defaults to the deterministic
    ///     deployer when `nil`.
    ///   - rpId: Optional WebAuthn Relying Party ID; `nil` means the browser default.
    ///   - rpName: WebAuthn Relying Party name; defaults to `"Smart Account"`.
    ///   - sessionExpiryMs: Session expiry in milliseconds; defaults to 7 days.
    ///   - signatureExpirationLedgers: Signature expiration in ledgers; defaults to 720.
    ///   - timeoutInSeconds: Operation timeout in seconds; defaults to 30.
    ///   - relayerUrl: Optional relayer endpoint URL.
    ///   - indexerUrl: Optional indexer endpoint URL.
    ///   - webauthnProvider: Optional WebAuthn provider.
    ///   - storage: Storage adapter; defaults to a fresh `InMemoryStorageAdapter`.
    ///   - externalWallet: Optional external wallet adapter.
    ///   - maxContextRuleScanId: Maximum context-rule ID to scan; defaults to 50.
    /// - Throws: `ConfigurationException.MissingConfig` for blank required strings;
    ///           `ConfigurationException.InvalidConfig` for malformed `accountWasmHash`
    ///           or `webauthnVerifierAddress`.
    public init(
        rpcUrl: String,
        networkPassphrase: String,
        accountWasmHash: String,
        webauthnVerifierAddress: String,
        deployerKeypair: KeyPair? = nil,
        rpId: String? = nil,
        rpName: String = "Smart Account",
        sessionExpiryMs: Int64 = OZConstants.defaultSessionExpiryMs,
        signatureExpirationLedgers: Int = StellarProtocolConstants.ledgersPerHour,
        timeoutInSeconds: Int = OZConstants.defaultTimeoutSeconds,
        relayerUrl: String? = nil,
        indexerUrl: String? = nil,
        webauthnProvider: WebAuthnProvider? = nil,
        storage: StorageAdapter = InMemoryStorageAdapter(),
        externalWallet: ExternalWalletAdapter? = nil,
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

        self.rpcUrl = rpcUrl
        self.networkPassphrase = networkPassphrase
        self.accountWasmHash = accountWasmHash
        self.webauthnVerifierAddress = webauthnVerifierAddress
        self.deployerKeypair = deployerKeypair
        self.rpId = rpId
        self.rpName = rpName
        self.sessionExpiryMs = sessionExpiryMs
        self.signatureExpirationLedgers = signatureExpirationLedgers
        self.timeoutInSeconds = timeoutInSeconds
        self.relayerUrl = relayerUrl
        self.indexerUrl = indexerUrl
        self.webauthnProvider = webauthnProvider
        self.storage = storage
        self.externalWallet = externalWallet
        self.maxContextRuleScanId = maxContextRuleScanId
    }

    // MARK: - Static factories

    /// Creates a deterministic deployer keypair for smart account deployment.
    ///
    /// Derives a keypair from `SHA-256("openzeppelin-smart-account-kit")`. The
    /// derivation is deterministic and reproducible across all Smart Account Kit
    /// implementations, so the same default deployer is used everywhere unless
    /// overridden. This keypair only pays deployment fees and does not control user
    /// wallets. Suitable for testing and simple deployments; production apps typically
    /// supply a custom deployer for attribution and traceability.
    ///
    /// - Returns: A deterministic `KeyPair` for contract deployment.
    /// - Throws: `ConfigurationException.InvalidConfig` if seed generation fails.
    public static func createDefaultDeployer() async throws -> KeyPair {
        // why: the literal seed string is a cross-implementation contract — every Smart
        // Account Kit derives the same default deployer from this exact UTF-8 byte
        // sequence, so changing it would break interoperability with deployments
        // performed by other clients.
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
    ///            applied to the twelve optional fields.
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
    /// If an indexer URL is explicitly configured, it is returned. Otherwise falls back
    /// to the built-in default URL for well-known networks (testnet has a default;
    /// mainnet does not).
    ///
    /// - Returns: The resolved indexer URL, or `nil` when no URL is configured and no
    ///            default exists for the network.
    public func effectiveIndexerUrl() -> String? {
        if let explicit = indexerUrl {
            return explicit
        }
        return OZSmartAccountConfig.defaultIndexerUrl(forNetworkPassphrase: networkPassphrase)
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

    /// Returns the built-in default indexer URL for a known network passphrase.
    ///
    /// Returns `nil` for unknown passphrases and for mainnet, which has no default
    /// indexer endpoint.
    private static func defaultIndexerUrl(forNetworkPassphrase passphrase: String) -> String? {
        return nil
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
    ///     .rpName("My Wallet")
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
        private var _rpId: String? = nil
        private var _rpName: String = "Smart Account"
        private var _sessionExpiryMs: Int64 = OZConstants.defaultSessionExpiryMs
        private var _signatureExpirationLedgers: Int = StellarProtocolConstants.ledgersPerHour
        private var _timeoutInSeconds: Int = OZConstants.defaultTimeoutSeconds
        private var _relayerUrl: String? = nil
        private var _indexerUrl: String? = nil
        private var _webauthnProvider: WebAuthnProvider? = nil
        private var _storage: StorageAdapter = InMemoryStorageAdapter()
        private var _externalWallet: ExternalWalletAdapter? = nil
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

        /// Sets the WebAuthn Relying Party ID.
        ///
        /// - Parameter value: The `rpId` (`nil` to use the browser default).
        /// - Returns: `self` for chaining.
        @discardableResult
        public func rpId(_ value: String?) -> Builder {
            _rpId = value
            return self
        }

        /// Sets the WebAuthn Relying Party name.
        ///
        /// - Parameter value: The `rpName`.
        /// - Returns: `self` for chaining.
        @discardableResult
        public func rpName(_ value: String) -> Builder {
            _rpName = value
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
                rpId: _rpId,
                rpName: _rpName,
                sessionExpiryMs: _sessionExpiryMs,
                signatureExpirationLedgers: _signatureExpirationLedgers,
                timeoutInSeconds: _timeoutInSeconds,
                relayerUrl: _relayerUrl,
                indexerUrl: _indexerUrl,
                webauthnProvider: _webauthnProvider,
                storage: _storage,
                externalWallet: _externalWallet,
                maxContextRuleScanId: _maxContextRuleScanId
            )
        }
    }
}

// MARK: - Equatable

extension OZSmartAccountConfig: Equatable {

    /// Two configurations are equal when all sixteen fields compare equal.
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
              lhs.rpId == rhs.rpId,
              lhs.rpName == rhs.rpName,
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
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rpcUrl)
        hasher.combine(networkPassphrase)
        hasher.combine(accountWasmHash)
        hasher.combine(webauthnVerifierAddress)
        hasher.combine(rpId)
        hasher.combine(rpName)
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
}

extension OZSmartAccountConfig: Hashable {}
