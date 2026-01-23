//
//  OZSmartAccountKit.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Main orchestrator for OpenZeppelin Smart Account operations on Stellar/Soroban.
///
/// OZSmartAccountKit is the primary entry point for creating and managing smart accounts
/// with WebAuthn/passkey authentication. It provides a high-level interface for:
///
/// - Creating new smart account wallets with biometric authentication
/// - Connecting to existing wallets via credential discovery
/// - Managing wallet sessions and credentials
/// - Submitting transactions with WebAuthn signatures
/// - Interacting with signers, policies, and context rules
///
/// The kit orchestrates multiple components:
/// - Storage adapter for credential persistence
/// - Soroban RPC server for blockchain interaction
/// - Relayer client for fee-sponsored transactions (optional)
/// - Indexer client for credential-to-contract discovery (optional)
///
/// Example usage:
/// ```swift
/// // Initialize the kit
/// let config = try OZSmartAccountConfig(
///     rpcUrl: "https://soroban-testnet.stellar.org",
///     networkPassphrase: "Test SDF Network ; September 2015",
///     accountWasmHash: "abc123...",
///     webauthnVerifierAddress: "CBCD1234...",
///     relayerUrl: "https://relayer.example.com",
///     indexerUrl: "https://indexer.example.com"
/// )
/// let kit = try OZSmartAccountKit(config: config)
///
/// // Create a new wallet (prompts for biometric authentication)
/// let wallet = try await kit.createWallet(name: "My Wallet")
/// print("Created wallet: \(wallet.address)")
///
/// // Connect to an existing wallet
/// let existingWallet = try await kit.connectWallet()
/// print("Connected to: \(existingWallet.address)")
///
/// // Send a payment
/// let result = try await kit.sendPayment(
///     destination: "GABC123...",
///     amount: 100_000_000, // 10 XLM in stroops
///     assetCode: "USDC",
///     assetIssuer: "GABC123..."
/// )
/// print("Transaction hash: \(result.hash)")
///
/// // Disconnect
/// kit.disconnect()
/// ```
///
/// Thread Safety:
/// This class is thread-safe. All internal state is protected by a serial dispatch queue.
/// Public methods can be safely called from any thread.
public final class OZSmartAccountKit: @unchecked Sendable {
    // MARK: - Configuration

    /// The configuration defining network endpoints, contract addresses, and operational parameters.
    public let config: OZSmartAccountConfig

    // MARK: - Internal Components

    /// Storage adapter for persisting credentials and sessions.
    private let storage: StorageAdapter

    /// Soroban RPC server client for blockchain interaction.
    private let rpcServer: SorobanServer

    /// Optional relayer client for fee-sponsored transaction submission.
    private let relayer: OZRelayerClient?

    /// Optional indexer client for credential-to-contract discovery.
    private let indexer: OZIndexerClient?

    /// Optional WebAuthn provider for passkey operations.
    ///
    /// Applications must set this property before calling wallet operations that require
    /// WebAuthn registration or authentication (createWallet, connectWallet without session).
    ///
    /// Example:
    /// ```swift
    /// let kit = try OZSmartAccountKit(config: config)
    /// kit.webauthnProvider = ASAuthorizationWebAuthnProvider(window: window)
    /// ```
    public var webauthnProvider: WebAuthnProvider?

    // MARK: - Connection State

    /// Currently connected credential ID (Base64URL-encoded).
    private var _credentialId: String?

    /// Currently connected smart account contract address (C-address).
    private var _contractId: String?

    /// Serial queue for thread-safe state access.
    private let stateLock = DispatchQueue(label: "com.stellarsdk.smartaccount.kit.state")

    // MARK: - Public State Accessors

    /// Indicates whether a wallet is currently connected.
    ///
    /// A wallet is connected when both the credential ID and contract ID are set.
    /// This state persists across app launches if a valid session exists.
    public var isConnected: Bool {
        stateLock.sync { _credentialId != nil && _contractId != nil }
    }

    /// The credential ID of the currently connected wallet.
    ///
    /// Returns nil if no wallet is connected. The credential ID is Base64URL-encoded
    /// without padding, matching the WebAuthn specification.
    public var credentialId: String? {
        stateLock.sync { _credentialId }
    }

    /// The contract address of the currently connected wallet.
    ///
    /// Returns nil if no wallet is connected. The contract ID is a Stellar C-address
    /// (56 characters, starting with 'C').
    public var contractId: String? {
        stateLock.sync { _contractId }
    }

    // MARK: - Initialization

    /// Creates a new OZSmartAccountKit with the specified configuration.
    ///
    /// Initializes all required components including:
    /// - Soroban RPC server connection
    /// - Storage adapter (defaults to Keychain if not provided)
    /// - Relayer client (if relayerUrl is configured)
    /// - Indexer client (if indexerUrl is configured)
    ///
    /// This initializer does not perform any network requests or load saved sessions.
    /// Call `connectWallet()` separately if you want to restore a previous connection.
    ///
    /// - Parameter config: The configuration for smart account operations
    /// - Throws: SmartAccountError.invalidConfig if the RPC URL is malformed
    ///
    /// Example:
    /// ```swift
    /// let config = try OZSmartAccountConfig(
    ///     rpcUrl: "https://soroban-testnet.stellar.org",
    ///     networkPassphrase: "Test SDF Network ; September 2015",
    ///     accountWasmHash: "abc123...",
    ///     webauthnVerifierAddress: "CBCD1234..."
    /// )
    /// let kit = try OZSmartAccountKit(config: config)
    /// ```
    public init(config: OZSmartAccountConfig) throws {
        // Validate RPC URL format
        guard let rpcUrl = URL(string: config.rpcUrl) else {
            throw SmartAccountError.invalidConfig("Invalid RPC URL: \(config.rpcUrl)")
        }

        // Validate RPC URL has a scheme and host
        guard rpcUrl.scheme != nil, rpcUrl.host != nil else {
            throw SmartAccountError.invalidConfig("RPC URL must have a valid scheme and host: \(config.rpcUrl)")
        }

        self.config = config

        // Initialize Soroban RPC server
        self.rpcServer = SorobanServer(endpoint: config.rpcUrl)

        // Initialize storage adapter (uses Keychain by default)
        self.storage = config.getStorage()

        // Initialize relayer client if configured
        if let relayerUrl = config.relayerUrl {
            self.relayer = OZRelayerClient(
                relayerUrl: relayerUrl,
                timeoutMs: SmartAccountConstants.DEFAULT_RELAYER_TIMEOUT_MS
            )
        } else {
            self.relayer = nil
        }

        // Initialize indexer client if configured
        if let indexerUrl = config.indexerUrl {
            self.indexer = OZIndexerClient(
                indexerUrl: indexerUrl,
                timeoutMs: SmartAccountConstants.DEFAULT_INDEXER_TIMEOUT_MS
            )
        } else {
            self.indexer = nil
        }
    }

    // MARK: - Connection Management

    /// Disconnects the currently connected wallet.
    ///
    /// Clears the in-memory connection state (credential ID and contract ID) and
    /// removes the stored session. The stored credentials remain in storage and
    /// can be reconnected later.
    ///
    /// This method is safe to call even if no wallet is connected.
    ///
    /// Example:
    /// ```swift
    /// kit.disconnect()
    /// print("Disconnected. isConnected: \(kit.isConnected)") // false
    /// ```
    public func disconnect() {
        stateLock.sync {
            _credentialId = nil
            _contractId = nil
        }
        try? storage.clearSession()
    }

    // MARK: - Internal Helpers

    /// Sets the connected wallet state.
    ///
    /// This method is called by wallet operation modules after successful wallet
    /// creation or connection. It updates the in-memory state with the provided
    /// credential ID and contract ID.
    ///
    /// Thread-safe: This method can be called from any thread.
    ///
    /// - Parameters:
    ///   - credentialId: The Base64URL-encoded credential ID
    ///   - contractId: The smart account contract address (C-address)
    internal func setConnected(credentialId: String, contractId: String) {
        stateLock.sync {
            _credentialId = credentialId
            _contractId = contractId
        }
    }

    /// Returns the deployer keypair, resolving to the default if not explicitly configured.
    ///
    /// The deployer keypair is used for deploying smart account contracts. If no deployer
    /// was provided in the configuration, a deterministic deployer is derived from
    /// SHA256("openzeppelin-smart-account-kit") for interoperability with the TypeScript SDK.
    ///
    /// Note: The deployer only pays for deployment transactions. It does not control user wallets.
    ///
    /// - Returns: The configured or default deployer keypair
    /// - Throws: An error if default deployer creation fails
    internal func getDeployer() throws -> KeyPair {
        return try config.getDeployer()
    }

    /// Provides access to the Soroban RPC server for contract operations.
    ///
    /// Used by operation modules to simulate transactions, submit transactions,
    /// query ledger state, and fetch account information.
    internal var sorobanServer: SorobanServer {
        return rpcServer
    }

    /// Provides access to the storage adapter for credential persistence.
    ///
    /// Used by operation modules to save, retrieve, update, and delete credentials
    /// and sessions.
    internal var storageAdapter: StorageAdapter {
        return storage
    }

    /// Provides access to the relayer client for fee-sponsored transaction submission.
    ///
    /// Returns nil if no relayer URL was configured. Operations should check for nil
    /// before attempting to use the relayer.
    internal var relayerClient: OZRelayerClient? {
        return relayer
    }

    /// Provides access to the indexer client for credential discovery.
    ///
    /// Returns nil if no indexer URL was configured. Operations should check for nil
    /// before attempting to use the indexer.
    internal var indexerClient: OZIndexerClient? {
        return indexer
    }

    /// Requires that a wallet is currently connected, throwing an error if not.
    ///
    /// This helper method is used by operations that require an active connection.
    /// It provides a consistent error message and atomic access to both credential ID
    /// and contract ID.
    ///
    /// - Returns: A tuple containing the credential ID and contract ID
    /// - Throws: SmartAccountError.walletNotConnected if no wallet is connected
    ///
    /// Example usage in operation modules:
    /// ```swift
    /// let (credentialId, contractId) = try kit.requireConnected()
    /// // Proceed with operation using credentialId and contractId
    /// ```
    internal func requireConnected() throws -> (credentialId: String, contractId: String) {
        return try stateLock.sync {
            guard let cId = _credentialId, let ctId = _contractId else {
                throw SmartAccountError.walletNotConnected("No wallet connected. Call createWallet() or connectWallet() first.")
            }
            return (cId, ctId)
        }
    }
}
