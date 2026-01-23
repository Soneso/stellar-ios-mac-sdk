//
//  OZSmartAccountConfig.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Configuration for OpenZeppelin Smart Account operations.
///
/// This configuration struct defines all parameters required to interact with OpenZeppelin
/// smart accounts on Stellar/Soroban. It includes network connectivity settings, contract
/// addresses, storage adapters, and operational timeouts.
///
/// Example usage:
/// ```swift
/// let config = try OZSmartAccountConfig(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     networkPassphrase: "Test SDF Network ; September 2015",
///     accountWasmHash: "abc123...",
///     webauthnVerifierAddress: "CBCD1234..."
/// )
///
/// // With custom settings
/// let customConfig = try OZSmartAccountConfig.Builder(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     networkPassphrase: "Test SDF Network ; September 2015",
///     accountWasmHash: "abc123...",
///     webauthnVerifierAddress: "CBCD1234..."
/// )
/// .rpName("My Custom Wallet")
/// .sessionExpiryMs(86400000) // 1 day
/// .relayerUrl("https://relayer.example.com")
/// .build()
/// ```
public struct OZSmartAccountConfig: Sendable {
    // MARK: - Required Configuration

    /// The Soroban RPC endpoint URL.
    ///
    /// Example: "https://soroban-testnet.stellar.org"
    public let rpcUrl: String

    /// The Stellar network passphrase.
    ///
    /// Examples:
    /// - Testnet: "Test SDF Network ; September 2015"
    /// - Mainnet: "Public Global Stellar Network ; September 2015"
    public let networkPassphrase: String

    /// The WASM hash of the smart account contract (hex string).
    ///
    /// This is the SHA-256 hash of the smart account contract WASM code,
    /// used for deploying new smart account instances.
    public let accountWasmHash: String

    /// The contract address of the WebAuthn signature verifier (C-address).
    ///
    /// This verifier contract validates secp256r1 signatures from WebAuthn/passkeys.
    public let webauthnVerifierAddress: String

    // MARK: - Optional Configuration

    /// The keypair used for deploying smart account contracts.
    ///
    /// If nil, a deterministic deployer is derived from SHA256("openzeppelin-smart-account-kit").
    /// This ensures interoperability with the TypeScript SDK's default deployer.
    ///
    /// Note: The deployer only pays for deployment transactions. It does not control user wallets.
    public let deployerKeypair: KeyPair?

    /// The WebAuthn Relying Party ID (rpId).
    ///
    /// This should match the domain where WebAuthn credentials are created.
    /// If nil, the browser will use the current domain.
    ///
    /// Example: "example.com"
    public let rpId: String?

    /// The WebAuthn Relying Party name displayed to users during authentication.
    ///
    /// Default: "Smart Account"
    public let rpName: String

    /// The storage adapter for persisting credentials and sessions.
    ///
    /// If nil, defaults to KeychainStorageAdapter for secure iOS Keychain storage.
    public let storage: StorageAdapter?

    /// Session expiry time in milliseconds.
    ///
    /// Sessions enable silent reconnection without re-authentication.
    /// Default: 604800000 (7 days)
    public let sessionExpiryMs: Int64

    /// Signature expiration in ledgers for auth entries.
    ///
    /// Auth entries expire after this many ledgers to prevent replay attacks.
    /// Default: 720 (~1 hour, since ~5 seconds per ledger)
    public let signatureExpirationLedgers: Int

    /// Default timeout for operations in seconds.
    ///
    /// Used for WebAuthn operations, network requests, and transaction submission.
    /// Default: 30 seconds
    public let timeoutInSeconds: Int

    /// Optional relayer endpoint URL for fee sponsoring.
    ///
    /// When set, enables gasless transactions by submitting through a fee-bump relayer.
    /// This allows users with empty wallets to transact.
    ///
    /// Example: "https://relayer.example.com"
    public let relayerUrl: String?

    /// Optional indexer endpoint URL for credential-to-contract mapping.
    ///
    /// The indexer maps WebAuthn credential IDs to deployed smart account contract addresses,
    /// enabling "Connect Wallet" functionality where users can discover their wallets.
    ///
    /// Example: "https://indexer.example.com"
    public let indexerUrl: String?

    /// Optional external wallet adapter for multi-signer support.
    ///
    /// Enables integration with external wallets (e.g., Freighter, Albedo) to collect
    /// signatures for multi-sig smart accounts.
    public let externalWallet: ExternalWalletAdapter?

    // MARK: - Initialization

    /// Creates a new OZSmartAccountConfig with the specified parameters.
    ///
    /// - Parameters:
    ///   - rpcUrl: The Soroban RPC endpoint URL (required, must not be empty)
    ///   - networkPassphrase: The Stellar network passphrase (required, must not be empty)
    ///   - accountWasmHash: The smart account contract WASM hash (required, must not be empty)
    ///   - webauthnVerifierAddress: The WebAuthn verifier contract address (required, must be C-address)
    ///   - deployerKeypair: Optional deployer keypair (defaults to deterministic derivation)
    ///   - rpId: Optional WebAuthn Relying Party ID
    ///   - rpName: WebAuthn Relying Party name (default: "Smart Account")
    ///   - storage: Optional storage adapter (defaults to KeychainStorageAdapter)
    ///   - sessionExpiryMs: Session expiry in milliseconds (default: 7 days)
    ///   - signatureExpirationLedgers: Signature expiration in ledgers (default: 720)
    ///   - timeoutInSeconds: Operation timeout in seconds (default: 30)
    ///   - relayerUrl: Optional relayer endpoint for fee sponsoring
    ///   - indexerUrl: Optional indexer endpoint for credential discovery
    ///   - externalWallet: Optional external wallet adapter
    ///
    /// - Throws: SmartAccountError if validation fails
    public init(
        rpcUrl: String,
        networkPassphrase: String,
        accountWasmHash: String,
        webauthnVerifierAddress: String,
        deployerKeypair: KeyPair? = nil,
        rpId: String? = nil,
        rpName: String = "Smart Account",
        storage: StorageAdapter? = nil,
        sessionExpiryMs: Int64 = SmartAccountConstants.DEFAULT_SESSION_EXPIRY_MS,
        signatureExpirationLedgers: Int = SmartAccountConstants.LEDGERS_PER_HOUR,
        timeoutInSeconds: Int = SmartAccountConstants.DEFAULT_TIMEOUT_SECONDS,
        relayerUrl: String? = nil,
        indexerUrl: String? = nil,
        externalWallet: ExternalWalletAdapter? = nil
    ) throws {
        // Validate required parameters
        guard !rpcUrl.isEmpty else {
            throw SmartAccountError.missingConfig("rpcUrl cannot be empty")
        }

        guard !networkPassphrase.isEmpty else {
            throw SmartAccountError.missingConfig("networkPassphrase cannot be empty")
        }

        guard !accountWasmHash.isEmpty else {
            throw SmartAccountError.missingConfig("accountWasmHash cannot be empty")
        }

        guard webauthnVerifierAddress.hasPrefix("C") else {
            throw SmartAccountError.invalidConfig("webauthnVerifierAddress must start with 'C' (contract address), got: \(webauthnVerifierAddress)")
        }

        guard webauthnVerifierAddress.count == 56 else {
            throw SmartAccountError.invalidConfig("webauthnVerifierAddress must be 56 characters long, got: \(webauthnVerifierAddress.count)")
        }

        self.rpcUrl = rpcUrl
        self.networkPassphrase = networkPassphrase
        self.accountWasmHash = accountWasmHash
        self.webauthnVerifierAddress = webauthnVerifierAddress
        self.deployerKeypair = deployerKeypair
        self.rpId = rpId
        self.rpName = rpName
        self.storage = storage
        self.sessionExpiryMs = sessionExpiryMs
        self.signatureExpirationLedgers = signatureExpirationLedgers
        self.timeoutInSeconds = timeoutInSeconds
        self.relayerUrl = relayerUrl
        self.indexerUrl = indexerUrl
        self.externalWallet = externalWallet
    }

    // MARK: - Default Deployer

    /// Creates a deterministic deployer keypair for smart account deployment.
    ///
    /// Derives a keypair from SHA256("openzeppelin-smart-account-kit") to ensure
    /// interoperability with the TypeScript SDK's default deployer. This keypair
    /// only pays deployment fees and does not control user wallets.
    ///
    /// - Returns: A deterministic KeyPair for contract deployment
    /// - Throws: An error if seed generation fails
    public static func createDefaultDeployer() throws -> KeyPair {
        let seedString = "openzeppelin-smart-account-kit"
        let seedHash = seedString.sha256Hash

        // Convert Data to [UInt8]
        let seedBytes = [UInt8](seedHash)

        // Create Seed from 32-byte hash
        let seed = try Seed(bytes: seedBytes)

        // Create KeyPair from seed
        return KeyPair(seed: seed)
    }

    /// Returns the deployer keypair, creating the default if needed.
    ///
    /// - Returns: The configured deployer or the default deterministic deployer
    /// - Throws: An error if default deployer creation fails
    public func getDeployer() throws -> KeyPair {
        if let deployer = deployerKeypair {
            return deployer
        }
        return try Self.createDefaultDeployer()
    }

    /// Returns the storage adapter, creating the default if needed.
    ///
    /// - Returns: The configured storage adapter or a new KeychainStorageAdapter
    public func getStorage() -> StorageAdapter {
        if let storage = storage {
            return storage
        }
        return KeychainStorageAdapter()
    }

    // MARK: - Builder

    /// Builder for creating OZSmartAccountConfig with a fluent API.
    ///
    /// Example:
    /// ```swift
    /// let config = try OZSmartAccountConfig.Builder(
    ///     rpcUrl: "https://soroban-testnet.stellar.org",
    ///     networkPassphrase: "Test SDF Network ; September 2015",
    ///     accountWasmHash: "abc123...",
    ///     webauthnVerifierAddress: "CBCD1234..."
    /// )
    /// .rpName("My Wallet")
    /// .sessionExpiryMs(86400000)
    /// .relayerUrl("https://relayer.example.com")
    /// .build()
    /// ```
    public struct Builder: Sendable {
        private let rpcUrl: String
        private let networkPassphrase: String
        private let accountWasmHash: String
        private let webauthnVerifierAddress: String
        private var deployerKeypair: KeyPair?
        private var rpId: String?
        private var rpName: String = "Smart Account"
        private var storage: StorageAdapter?
        private var sessionExpiryMs: Int64 = SmartAccountConstants.DEFAULT_SESSION_EXPIRY_MS
        private var signatureExpirationLedgers: Int = SmartAccountConstants.LEDGERS_PER_HOUR
        private var timeoutInSeconds: Int = SmartAccountConstants.DEFAULT_TIMEOUT_SECONDS
        private var relayerUrl: String?
        private var indexerUrl: String?
        private var externalWallet: ExternalWalletAdapter?

        /// Creates a new builder with required parameters.
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
        public func deployerKeypair(_ value: KeyPair?) -> Builder {
            var copy = self
            copy.deployerKeypair = value
            return copy
        }

        /// Sets the WebAuthn Relying Party ID.
        public func rpId(_ value: String?) -> Builder {
            var copy = self
            copy.rpId = value
            return copy
        }

        /// Sets the WebAuthn Relying Party name.
        public func rpName(_ value: String) -> Builder {
            var copy = self
            copy.rpName = value
            return copy
        }

        /// Sets the storage adapter.
        public func storage(_ value: StorageAdapter?) -> Builder {
            var copy = self
            copy.storage = value
            return copy
        }

        /// Sets the session expiry in milliseconds.
        public func sessionExpiryMs(_ value: Int64) -> Builder {
            var copy = self
            copy.sessionExpiryMs = value
            return copy
        }

        /// Sets the signature expiration in ledgers.
        public func signatureExpirationLedgers(_ value: Int) -> Builder {
            var copy = self
            copy.signatureExpirationLedgers = value
            return copy
        }

        /// Sets the operation timeout in seconds.
        public func timeoutInSeconds(_ value: Int) -> Builder {
            var copy = self
            copy.timeoutInSeconds = value
            return copy
        }

        /// Sets the relayer URL.
        public func relayerUrl(_ value: String?) -> Builder {
            var copy = self
            copy.relayerUrl = value
            return copy
        }

        /// Sets the indexer URL.
        public func indexerUrl(_ value: String?) -> Builder {
            var copy = self
            copy.indexerUrl = value
            return copy
        }

        /// Sets the external wallet adapter.
        public func externalWallet(_ value: ExternalWalletAdapter?) -> Builder {
            var copy = self
            copy.externalWallet = value
            return copy
        }

        /// Builds the OZSmartAccountConfig.
        ///
        /// - Returns: A new OZSmartAccountConfig instance
        /// - Throws: SmartAccountError if validation fails
        public func build() throws -> OZSmartAccountConfig {
            try OZSmartAccountConfig(
                rpcUrl: rpcUrl,
                networkPassphrase: networkPassphrase,
                accountWasmHash: accountWasmHash,
                webauthnVerifierAddress: webauthnVerifierAddress,
                deployerKeypair: deployerKeypair,
                rpId: rpId,
                rpName: rpName,
                storage: storage,
                sessionExpiryMs: sessionExpiryMs,
                signatureExpirationLedgers: signatureExpirationLedgers,
                timeoutInSeconds: timeoutInSeconds,
                relayerUrl: relayerUrl,
                indexerUrl: indexerUrl,
                externalWallet: externalWallet
            )
        }
    }
}
