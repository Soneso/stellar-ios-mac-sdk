//
//  OZWalletOperations.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - WebAuthn Provider Protocol

/// Protocol for platform-specific WebAuthn registration and authentication.
///
/// WebAuthn operations require platform-specific integration with iOS ASAuthorization APIs,
/// which need access to UI elements like UIWindow. Since the SDK cannot directly provide
/// these implementations, applications must inject a WebAuthnProvider implementation.
///
/// Example implementation:
/// ```swift
/// class ASAuthorizationWebAuthnProvider: WebAuthnProvider {
///     private weak var window: UIWindow?
///
///     init(window: UIWindow) {
///         self.window = window
///     }
///
///     func register(
///         challenge: Data,
///         rpId: String,
///         rpName: String,
///         userName: String,
///         userId: Data
///     ) async throws -> WebAuthnRegistrationResult {
///         let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
///         let request = provider.createCredentialRegistrationRequest(
///             challenge: challenge,
///             name: userName,
///             userID: userId
///         )
///         // Present ASAuthorizationController and return result
///     }
/// }
/// ```
public protocol WebAuthnProvider: Sendable {
    /// Registers a new WebAuthn credential with the authenticator.
    ///
    /// Triggers platform authentication (Touch ID, Face ID, security key) to create
    /// a new credential. The user will be prompted to authenticate, and a new
    /// secp256r1 keypair will be generated and stored by the authenticator.
    ///
    /// - Parameters:
    ///   - challenge: Random challenge bytes (typically 32 bytes)
    ///   - rpId: Relying Party identifier (e.g., "example.com")
    ///   - rpName: Relying Party display name (e.g., "My Wallet")
    ///   - userName: User name to display (e.g., "Smart Account User")
    ///   - userId: User identifier bytes (typically 32 random bytes)
    /// - Returns: WebAuthnRegistrationResult containing credential ID and attestation
    /// - Throws: An error if registration fails or is cancelled
    func register(
        challenge: Data,
        rpId: String,
        rpName: String,
        userName: String,
        userId: Data
    ) async throws -> WebAuthnRegistrationResult

    /// Authenticates with an existing WebAuthn credential.
    ///
    /// Triggers platform authentication to sign a challenge with an existing credential.
    /// The user will be prompted to authenticate, and the authenticator will sign the
    /// challenge with the private key associated with the credential.
    ///
    /// - Parameters:
    ///   - challenge: Challenge bytes to sign
    ///   - rpId: Relying Party identifier
    ///   - allowCredentials: Optional list of credential IDs to filter (nil = allow all)
    /// - Returns: WebAuthnAuthenticationResult containing signature and authenticator data
    /// - Throws: An error if authentication fails or is cancelled
    func authenticate(
        challenge: Data,
        rpId: String,
        allowCredentials: [Data]?
    ) async throws -> WebAuthnAuthenticationResult
}

// MARK: - WebAuthn Result Types

/// Result of a WebAuthn registration operation.
///
/// Contains the credential ID and attestation object returned by the authenticator
/// during credential creation. The attestation object includes the public key and
/// other metadata required for signature verification.
public struct WebAuthnRegistrationResult: Sendable {
    /// The credential ID (unique identifier for this credential).
    public let credentialId: Data

    /// The attestation object containing public key and metadata.
    public let attestationObject: Data

    /// The client data JSON sent by the browser/platform.
    public let clientDataJSON: Data

    /// Creates a new WebAuthnRegistrationResult.
    public init(credentialId: Data, attestationObject: Data, clientDataJSON: Data) {
        self.credentialId = credentialId
        self.attestationObject = attestationObject
        self.clientDataJSON = clientDataJSON
    }
}

/// Result of a WebAuthn authentication operation.
///
/// Contains the signature and authenticator data returned by the authenticator
/// during authentication. The signature is a DER-encoded secp256r1 signature.
public struct WebAuthnAuthenticationResult: Sendable {
    /// The credential ID used for authentication.
    public let credentialId: Data

    /// The authenticator data (flags, counter, etc.).
    public let authenticatorData: Data

    /// The client data JSON sent by the browser/platform.
    public let clientDataJSON: Data

    /// The signature in DER format (secp256r1).
    public let signature: Data

    /// Creates a new WebAuthnAuthenticationResult.
    public init(credentialId: Data, authenticatorData: Data, clientDataJSON: Data, signature: Data) {
        self.credentialId = credentialId
        self.authenticatorData = authenticatorData
        self.clientDataJSON = clientDataJSON
        self.signature = signature
    }
}

// MARK: - Wallet Operation Results

/// Result of a wallet creation operation.
///
/// Contains the credential ID, contract address, public key, and optional transaction
/// hash if the wallet was auto-submitted to the network.
public struct CreateWalletResult: Sendable {
    /// The credential ID (Base64URL-encoded, no padding).
    public let credentialId: String

    /// The smart account contract address (C-address).
    public let contractId: String

    /// The uncompressed secp256r1 public key (65 bytes).
    public let publicKey: Data

    /// The transaction hash if auto-submitted, nil otherwise.
    public let transactionHash: String?

    /// Creates a new CreateWalletResult.
    public init(credentialId: String, contractId: String, publicKey: Data, transactionHash: String? = nil) {
        self.credentialId = credentialId
        self.contractId = contractId
        self.publicKey = publicKey
        self.transactionHash = transactionHash
    }
}

/// Result of a wallet connection operation.
///
/// Contains the credential ID, contract address, and whether the connection was
/// restored from a saved session.
public struct ConnectWalletResult: Sendable {
    /// The credential ID (Base64URL-encoded, no padding).
    public let credentialId: String

    /// The smart account contract address (C-address).
    public let contractId: String

    /// Whether the connection was restored from a saved session.
    public let restoredFromSession: Bool

    /// Creates a new ConnectWalletResult.
    public init(credentialId: String, contractId: String, restoredFromSession: Bool) {
        self.credentialId = credentialId
        self.contractId = contractId
        self.restoredFromSession = restoredFromSession
    }
}

// MARK: - Wallet Operations

/// Operations for creating and connecting smart account wallets.
///
/// OZWalletOperations provides high-level wallet lifecycle management:
///
/// - Wallet creation with WebAuthn passkey generation
/// - Contract deployment with deterministic address derivation
/// - Wallet connection via session restoration or credential lookup
/// - Integration with indexer for credential-to-contract discovery
///
/// This class requires a WebAuthnProvider to be set on the kit before use.
/// The provider handles platform-specific WebAuthn operations.
///
/// Example usage:
/// ```swift
/// let kit = try OZSmartAccountKit(config: config)
/// kit.webauthnProvider = ASAuthorizationWebAuthnProvider(window: window)
/// let walletOps = OZWalletOperations(kit: kit, credentialManager: credentialManager)
///
/// // Create a new wallet
/// let wallet = try await walletOps.createWallet(userName: "Alice", autoSubmit: true)
/// print("Created wallet: \(wallet.contractId)")
///
/// // Connect to existing wallet
/// let connected = try await walletOps.connectWallet()
/// print("Connected: \(connected.contractId)")
/// ```
public final class OZWalletOperations: @unchecked Sendable {
    /// Reference to the parent SmartAccountKit instance.
    private let kit: OZSmartAccountKit

    /// Credential manager for storage operations.
    private let credentialManager: OZCredentialManager

    /// Creates a new OZWalletOperations instance.
    ///
    /// - Parameters:
    ///   - kit: The parent OZSmartAccountKit instance
    ///   - credentialManager: The credential manager for storage operations
    internal init(kit: OZSmartAccountKit, credentialManager: OZCredentialManager) {
        self.kit = kit
        self.credentialManager = credentialManager
    }

    // MARK: - Create Wallet

    /// Creates a new smart account wallet with WebAuthn passkey authentication.
    ///
    /// Creates a new wallet by generating a WebAuthn credential, deriving the contract
    /// address, and optionally deploying the smart account contract to the network.
    ///
    /// Flow:
    /// 1. Generate random 32-byte challenge for WebAuthn
    /// 2. Call WebAuthn registration (user authenticates with Touch ID/Face ID)
    /// 3. Extract secp256r1 public key from attestation
    /// 4. Derive deterministic contract address from credential ID
    /// 5. Save credential as pending in storage
    /// 6. Build deploy transaction (if autoSubmit, submit and delete credential on success)
    /// 7. Return result
    ///
    /// IMPORTANT: Requires a WebAuthnProvider to be set on the kit. Throws
    /// WEBAUTHN_NOT_SUPPORTED if no provider is configured.
    ///
    /// - Parameters:
    ///   - userName: Display name for the user (default: "Smart Account User")
    ///   - autoSubmit: Whether to automatically submit the deploy transaction (default: false)
    /// - Returns: CreateWalletResult containing credential ID, contract address, and transaction hash
    /// - Throws: SmartAccountError if WebAuthn registration fails, extraction fails, or submission fails
    ///
    /// Example:
    /// ```swift
    /// // Create wallet without deploying (for later deployment)
    /// let wallet = try await walletOps.createWallet(userName: "Alice", autoSubmit: false)
    /// print("Wallet address: \(wallet.contractId)")
    /// print("Credential ID: \(wallet.credentialId)")
    ///
    /// // Create and deploy immediately
    /// let deployedWallet = try await walletOps.createWallet(userName: "Bob", autoSubmit: true)
    /// print("Deployed at: \(deployedWallet.transactionHash ?? "unknown")")
    /// ```
    public func createWallet(
        userName: String = "Smart Account User",
        autoSubmit: Bool = false
    ) async throws -> CreateWalletResult {
        // STEP 1: Check for WebAuthn provider
        guard let webauthnProvider = kit.webauthnProvider else {
            throw SmartAccountError.webAuthnNotSupported(
                "No WebAuthnProvider configured. Set kit.webauthnProvider before calling createWallet()."
            )
        }

        // STEP 2: Generate random challenge (32 bytes)
        var challengeData = Data(count: 32)
        let result = challengeData.withUnsafeMutableBytes { bufferPointer -> OSStatus in
            guard let baseAddress = bufferPointer.baseAddress else {
                return errSecAllocate
            }
            return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
        }
        guard result == errSecSuccess else {
            throw SmartAccountError.webAuthnRegistrationFailed("Failed to generate random challenge")
        }

        // Generate random user ID (32 bytes)
        var userIdData = Data(count: 32)
        let userIdResult = userIdData.withUnsafeMutableBytes { bufferPointer -> OSStatus in
            guard let baseAddress = bufferPointer.baseAddress else {
                return errSecAllocate
            }
            return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
        }
        guard userIdResult == errSecSuccess else {
            throw SmartAccountError.webAuthnRegistrationFailed("Failed to generate random user ID")
        }

        // STEP 3: Call WebAuthn registration
        let registrationResult: WebAuthnRegistrationResult
        do {
            registrationResult = try await webauthnProvider.register(
                challenge: challengeData,
                rpId: kit.config.rpId ?? "localhost",
                rpName: kit.config.rpName,
                userName: userName,
                userId: userIdData
            )
        } catch {
            throw SmartAccountError.webAuthnRegistrationFailed(
                "WebAuthn registration failed: \(error.localizedDescription)",
                cause: error
            )
        }

        // STEP 4: Extract public key from attestation
        let publicKey: Data
        do {
            publicKey = try SmartAccountUtils.extractPublicKey(
                fromAttestationObject: registrationResult.attestationObject
            )
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.webAuthnRegistrationFailed(
                "Failed to extract public key from attestation: \(error.localizedDescription)",
                cause: error
            )
        }

        // STEP 5: Derive contract address
        let deployer = try kit.getDeployer()
        let contractId: String
        do {
            contractId = try SmartAccountUtils.deriveContractAddress(
                credentialId: registrationResult.credentialId,
                deployerPublicKey: deployer.accountId,
                networkPassphrase: kit.config.networkPassphrase
            )
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.transactionSigningFailed(
                "Failed to derive contract address: \(error.localizedDescription)",
                cause: error
            )
        }

        // STEP 6: Base64URL-encode credential ID
        let credentialIdBase64url = SmartAccountSharedUtils.base64urlEncode(registrationResult.credentialId)

        // STEP 7: Save credential as pending
        do {
            _ = try credentialManager.createPendingCredential(
                credentialId: credentialIdBase64url,
                publicKey: publicKey,
                contractId: contractId
            )
        } catch let error as SmartAccountError {
            throw error
        } catch {
            throw SmartAccountError.storageWriteFailed(
                "Failed to save credential: \(error.localizedDescription)",
                cause: error
            )
        }

        // STEP 8: Build deploy transaction
        var transactionHash: String?

        if autoSubmit {
            // Build deployment transaction
            do {
                // Prepare constructor arguments
                // signers = [External(webauthnVerifier, keyData)]
                // keyData = publicKey (65 bytes) + credentialId
                var keyData = Data()
                keyData.append(publicKey)
                keyData.append(registrationResult.credentialId)

                let webauthnSigner = try ExternalSigner(
                    verifierAddress: kit.config.webauthnVerifierAddress,
                    keyData: keyData
                )

                // Build constructor arguments:
                // - signers: Vec([External signer])
                // - policies: Map([])
                let signersScVal = SCValXDR.vec([try webauthnSigner.toScVal()])
                let policiesScVal = SCValXDR.map([]) // Empty map

                let constructorArgs: [SCValXDR] = [signersScVal, policiesScVal]

                // Create contract deployment operation with constructor
                let salt = WrappedData32(SmartAccountUtils.getContractSalt(credentialId: registrationResult.credentialId))
                let deployerAddress = try SCAddressXDR(accountId: deployer.accountId)

                let operation = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(
                    wasmId: kit.config.accountWasmHash,
                    address: deployerAddress,
                    constructorArguments: constructorArgs,
                    salt: salt,
                    sourceAccountId: deployer.accountId
                )

                // Get deployer account
                let accountResponse = await kit.sorobanServer.getAccount(accountId: deployer.accountId)
                guard case .success(let deployerAccount) = accountResponse else {
                    throw SmartAccountError.transactionSubmissionFailed("Failed to fetch deployer account")
                }

                // Build transaction
                let transaction = try Transaction(
                    sourceAccount: deployerAccount,
                    operations: [operation],
                    memo: Memo.none,
                    preconditions: nil
                )

                // Simulate transaction
                let simulateRequest = SimulateTransactionRequest(transaction: transaction)
                let simulateResponse = await kit.sorobanServer.simulateTransaction(simulateTxRequest: simulateRequest)

                guard case .success(let simulation) = simulateResponse else {
                    throw SmartAccountError.transactionSimulationFailed("Failed to simulate deployment transaction")
                }

                if let error = simulation.error {
                    throw SmartAccountError.transactionSimulationFailed("Simulation error: \(error)")
                }

                // Assemble transaction from simulation
                guard let transactionData = simulation.transactionData,
                      let minResourceFee = simulation.minResourceFee else {
                    throw SmartAccountError.transactionSubmissionFailed("Failed to get transaction data from simulation")
                }

                transaction.setSorobanTransactionData(data: transactionData)
                transaction.addResourceFee(resourceFee: minResourceFee)

                // Sign with deployer
                try transaction.sign(
                    keyPair: deployer,
                    network: Network.custom(passphrase: kit.config.networkPassphrase)
                )

                // Submit transaction
                let sendResponse = await kit.sorobanServer.sendTransaction(transaction: transaction)

                guard case .success(let sendResult) = sendResponse else {
                    // Mark deployment as failed
                    try? credentialManager.markDeploymentFailed(
                        credentialId: credentialIdBase64url,
                        error: "Failed to send transaction"
                    )
                    throw SmartAccountError.transactionSubmissionFailed("Failed to send deployment transaction")
                }

                if let error = sendResult.errorResultXdr {
                    // Mark deployment as failed
                    try? credentialManager.markDeploymentFailed(
                        credentialId: credentialIdBase64url,
                        error: "Transaction error: \(error)"
                    )
                    throw SmartAccountError.transactionSubmissionFailed("Deployment transaction error: \(error)")
                }

                transactionHash = sendResult.transactionId

                // Poll for confirmation
                var confirmed = false
                for attempt in 1...10 {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    let txResponse = await kit.sorobanServer.getTransaction(transactionHash: transactionHash!)

                    guard case .success(let txStatus) = txResponse else {
                        // Network error, retry
                        if attempt < 10 {
                            continue
                        }
                        try? credentialManager.markDeploymentFailed(
                            credentialId: credentialIdBase64url,
                            error: "Deployment confirmation timed out"
                        )
                        throw SmartAccountError.transactionTimeout("Deployment confirmation timed out")
                    }

                    switch txStatus.status {
                    case GetTransactionResponse.STATUS_SUCCESS:
                        confirmed = true

                    case GetTransactionResponse.STATUS_FAILED:
                        try? credentialManager.markDeploymentFailed(
                            credentialId: credentialIdBase64url,
                            error: txStatus.resultXdr ?? "Deployment failed on-chain"
                        )
                        throw SmartAccountError.transactionSubmissionFailed(
                            "Deployment failed: \(txStatus.resultXdr ?? "unknown")"
                        )

                    default:
                        // STATUS_NOT_FOUND or unknown - continue polling
                        continue
                    }

                    if confirmed { break }
                }

                guard confirmed else {
                    try? credentialManager.markDeploymentFailed(
                        credentialId: credentialIdBase64url,
                        error: "Deployment confirmation timed out"
                    )
                    throw SmartAccountError.transactionTimeout("Deployment confirmation timed out")
                }

                // Set connected state after successful deployment
                kit.setConnected(credentialId: credentialIdBase64url, contractId: contractId)

                // Delete credential on successful deployment
                try? credentialManager.deleteCredential(credentialId: credentialIdBase64url)
            } catch let error as SmartAccountError {
                throw error
            } catch {
                // Mark deployment as failed
                try? credentialManager.markDeploymentFailed(
                    credentialId: credentialIdBase64url,
                    error: error.localizedDescription
                )
                throw SmartAccountError.transactionSubmissionFailed(
                    "Failed to deploy wallet: \(error.localizedDescription)",
                    cause: error
                )
            }
        }

        // STEP 9: Return result
        return CreateWalletResult(
            credentialId: credentialIdBase64url,
            contractId: contractId,
            publicKey: publicKey,
            transactionHash: transactionHash
        )
    }

    // MARK: - Connect Wallet

    /// Connects to an existing smart account wallet.
    ///
    /// Attempts to connect to a wallet by:
    /// 1. Checking for a valid saved session (silent reconnection)
    /// 2. Prompting for WebAuthn authentication (if no session)
    /// 3. Looking up the contract address via storage or indexer
    /// 4. Verifying the contract exists on-chain
    /// 5. Saving a new session
    ///
    /// Flow:
    /// 1. Check storage for valid (non-expired) session
    /// 2. If valid session: set kit connected state, return restoredFromSession: true
    /// 3. If expired session: delete silently, continue
    /// 4. If no valid session: trigger WebAuthn authentication (no allowCredentials filter)
    /// 5. Extract credentialId from authentication result (base64url encode)
    /// 6. Look up contractId:
    ///    a. Check local storage
    ///    b. If not found and indexer configured: call indexer
    ///    c. If not found: derive contract address and verify on-chain via RPC
    ///    d. If contract doesn't exist: throw WALLET_NOT_FOUND
    /// 7. Save session
    /// 8. Set kit connected state
    /// 9. Return result
    ///
    /// IMPORTANT: Requires a WebAuthnProvider to be set on the kit for non-session reconnection.
    ///
    /// - Returns: ConnectWalletResult containing credential ID, contract ID, and session flag
    /// - Throws: SmartAccountError if authentication fails, wallet not found, or RPC fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let result = try await walletOps.connectWallet()
    ///     if result.restoredFromSession {
    ///         print("Silently reconnected to: \(result.contractId)")
    ///     } else {
    ///         print("Authenticated and connected to: \(result.contractId)")
    ///     }
    /// } catch let error as SmartAccountError {
    ///     switch error.code {
    ///     case .walletNotFound:
    ///         print("No wallet found for this credential")
    ///     case .webAuthnCancelled:
    ///         print("User cancelled authentication")
    ///     default:
    ///         print("Connection failed: \(error.message)")
    ///     }
    /// }
    /// ```
    public func connectWallet() async throws -> ConnectWalletResult {
        // STEP 1: Check for valid session
        let session = try? kit.storageAdapter.getSession()

        if let session = session, !session.isExpired {
            // Valid session exists - silently reconnect
            kit.setConnected(credentialId: session.credentialId, contractId: session.contractId)
            return ConnectWalletResult(
                credentialId: session.credentialId,
                contractId: session.contractId,
                restoredFromSession: true
            )
        }

        // STEP 2: If expired session, delete silently
        if let session = session, session.isExpired {
            try? kit.storageAdapter.clearSession()
        }

        // STEP 3: No valid session - require WebAuthn authentication
        guard let webauthnProvider = kit.webauthnProvider else {
            throw SmartAccountError.webAuthnNotSupported(
                "No WebAuthnProvider configured. Set kit.webauthnProvider before calling connectWallet()."
            )
        }

        // Generate random challenge (32 bytes)
        var challengeData = Data(count: 32)
        let result = challengeData.withUnsafeMutableBytes { bufferPointer -> OSStatus in
            guard let baseAddress = bufferPointer.baseAddress else {
                return errSecAllocate
            }
            return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
        }
        guard result == errSecSuccess else {
            throw SmartAccountError.webAuthnAuthenticationFailed("Failed to generate random challenge")
        }

        // STEP 4: Call WebAuthn authentication (no credential filter - allow all)
        let authenticationResult: WebAuthnAuthenticationResult
        do {
            authenticationResult = try await webauthnProvider.authenticate(
                challenge: challengeData,
                rpId: kit.config.rpId ?? "localhost",
                allowCredentials: nil
            )
        } catch {
            throw SmartAccountError.webAuthnAuthenticationFailed(
                "WebAuthn authentication failed: \(error.localizedDescription)",
                cause: error
            )
        }

        // STEP 5: Base64URL-encode credential ID
        let credentialIdBase64url = SmartAccountSharedUtils.base64urlEncode(authenticationResult.credentialId)

        // STEP 6: Look up contract ID
        var contractId: String?

        // 6a. Check local storage
        if let storedCredential = try? credentialManager.getCredential(credentialId: credentialIdBase64url) {
            contractId = storedCredential.contractId
        }

        // 6b. If not found and indexer configured: call indexer
        if contractId == nil, let indexer = kit.indexerClient {
            do {
                let lookupResponse = try await indexer.lookupByCredentialId(credentialIdBase64url)
                if let firstContract = lookupResponse.contracts.first {
                    contractId = firstContract.contractId
                }
            } catch {
                // Indexer lookup failed - continue to derivation
            }
        }

        // 6c. If still not found: derive contract address and verify on-chain
        if contractId == nil {
            let deployer = try kit.getDeployer()
            let derivedContractId = try SmartAccountUtils.deriveContractAddress(
                credentialId: authenticationResult.credentialId,
                deployerPublicKey: deployer.accountId,
                networkPassphrase: kit.config.networkPassphrase
            )

            // Verify contract exists by simulating a read-only call
            let verifyArgs = InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: derivedContractId),
                functionName: "get_context_rules_count",
                args: []
            )
            let verifyFunction = HostFunctionXDR.invokeContract(verifyArgs)
            do {
                _ = try await SmartAccountSharedUtils.simulateAndExtractResult(hostFunction: verifyFunction, kit: kit)
            } catch {
                throw SmartAccountError.walletNotFound(
                    "Contract not found at derived address: \(derivedContractId)"
                )
            }

            contractId = derivedContractId
        }

        guard let finalContractId = contractId else {
            throw SmartAccountError.walletNotFound(
                "Failed to resolve contract address for credential ID: \(credentialIdBase64url)"
            )
        }

        // STEP 7: Save session
        let expiresAt = Date(timeIntervalSinceNow: TimeInterval(kit.config.sessionExpiryMs) / 1000.0)
        let newSession = StoredSession(
            credentialId: credentialIdBase64url,
            contractId: finalContractId,
            connectedAt: Date(),
            expiresAt: expiresAt
        )

        do {
            try kit.storageAdapter.saveSession(session: newSession)
        } catch {
            // Session save failed - not critical, continue
        }

        // STEP 8: Set kit connected state
        kit.setConnected(credentialId: credentialIdBase64url, contractId: finalContractId)

        // STEP 9: Return result
        return ConnectWalletResult(
            credentialId: credentialIdBase64url,
            contractId: finalContractId,
            restoredFromSession: false
        )
    }

}
