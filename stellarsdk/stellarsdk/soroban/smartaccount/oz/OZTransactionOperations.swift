//
//  OZTransactionOperations.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Result of a transaction submission and polling operation.
///
/// Contains the outcome of a transaction after it has been submitted to the network
/// and potentially confirmed on-chain. Use this to determine if a transaction succeeded
/// and retrieve its hash and ledger number.
///
/// Example:
/// ```swift
/// let result = try await txOps.transfer(
///     tokenContract: "CBCD...",
///     recipient: "GA7Q...",
///     amount: 10.0
/// )
///
/// if result.success {
///     print("Transaction succeeded! Hash: \(result.hash ?? "unknown")")
///     print("Confirmed in ledger: \(result.ledger ?? 0)")
/// } else {
///     print("Transaction failed: \(result.error ?? "unknown error")")
/// }
/// ```
public struct TransactionResult: Sendable {
    /// Whether the transaction was successful.
    public let success: Bool

    /// The transaction hash if submission succeeded.
    public let hash: String?

    /// The ledger number where the transaction was confirmed.
    public let ledger: UInt32?

    /// Error message if the transaction failed.
    public let error: String?

    /// Creates a new TransactionResult.
    ///
    /// - Parameters:
    ///   - success: Whether the transaction succeeded
    ///   - hash: Optional transaction hash
    ///   - ledger: Optional ledger number
    ///   - error: Optional error message
    public init(success: Bool, hash: String? = nil, ledger: UInt32? = nil, error: String? = nil) {
        self.success = success
        self.hash = hash
        self.ledger = ledger
        self.error = error
    }
}

/// Transaction operations for OpenZeppelin Smart Accounts.
///
/// Provides high-level transaction building, signing, and submission capabilities
/// for smart account operations. Handles:
///
/// - Token transfers with automatic stroops conversion
/// - Transaction simulation and fee estimation
/// - Authorization entry signing with WebAuthn
/// - Relayer submission for fee sponsoring
/// - Transaction polling and confirmation
/// - Testnet wallet funding via Friendbot
///
/// This class works in tandem with OZSmartAccountKit and should be accessed via
/// the kit instance rather than instantiated directly.
///
/// Example usage:
/// ```swift
/// let kit = try OZSmartAccountKit(config: config)
/// let txOps = OZTransactionOperations(kit: kit)
///
/// // Transfer tokens
/// let result = try await txOps.transfer(
///     tokenContract: nativeTokenAddress,
///     recipient: "GA7Q...",
///     amount: 100.0
/// )
/// print("Transfer \(result.success ? "succeeded" : "failed")")
///
/// // Fund testnet wallet
/// let fundedAmount = try await txOps.fundWallet(nativeTokenContract: nativeTokenAddress)
/// print("Funded with \(fundedAmount) XLM")
/// ```
public final class OZTransactionOperations: @unchecked Sendable {
    /// Reference to the parent SmartAccountKit instance.
    private let kit: OZSmartAccountKit

    /// Creates a new OZTransactionOperations instance.
    ///
    /// - Parameter kit: The parent OZSmartAccountKit instance
    internal init(kit: OZSmartAccountKit) {
        self.kit = kit
    }

    // MARK: - Token Transfer

    /// Transfers tokens from the smart account to a recipient.
    ///
    /// Builds and submits a token transfer transaction from the connected smart account
    /// to the specified recipient. The amount is automatically converted from XLM to stroops.
    ///
    /// Flow:
    /// 1. Validates inputs (addresses, amount, not sending to self)
    /// 2. Converts amount to stroops (1 XLM = 10,000,000 stroops)
    /// 3. Builds contract invocation for token transfer
    /// 4. Simulates transaction to get auth entries
    /// 5. Signs auth entries with passkey (requires user interaction)
    /// 6. Re-simulates with signed auth entries
    /// 7. Submits via relayer (if configured) or RPC
    /// 8. Polls for confirmation
    ///
    /// IMPORTANT: This method requires WebAuthn interaction to sign auth entries.
    /// The user will be prompted for biometric authentication.
    ///
    /// - Parameters:
    ///   - tokenContract: The token contract address (C-address)
    ///   - recipient: The recipient address (G-address for accounts, C-address for contracts)
    ///   - amount: The amount to transfer in XLM (will be converted to stroops)
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails, simulation fails, or submission fails
    ///
    /// Example:
    /// ```swift
    /// let result = try await txOps.transfer(
    ///     tokenContract: "CBCD1234...",
    ///     recipient: "GA7QYNF7...",
    ///     amount: 10.5
    /// )
    ///
    /// if result.success {
    ///     print("Transferred 10.5 XLM. Hash: \(result.hash ?? "")")
    /// } else {
    ///     print("Transfer failed: \(result.error ?? "")")
    /// }
    /// ```
    public func transfer(
        tokenContract: String,
        recipient: String,
        amount: Decimal
    ) async throws -> TransactionResult {
        // STEP 1: Validate inputs
        let (_, contractId) = try kit.requireConnected()

        // Validate token contract address (must be C-address)
        guard tokenContract.hasPrefix("C"), tokenContract.count == 56 else {
            throw SmartAccountError.invalidAddress("Token contract must be a valid C-address, got: \(tokenContract)")
        }

        // Validate recipient address (G or C)
        guard (recipient.hasPrefix("G") || recipient.hasPrefix("C")), recipient.count == 56 else {
            throw SmartAccountError.invalidAddress("Recipient must be a valid G-address or C-address, got: \(recipient)")
        }

        // Validate amount
        guard amount > 0 else {
            throw SmartAccountError.invalidAmount("Amount must be greater than zero, got: \(amount)")
        }

        // Prevent self-transfer
        guard recipient != contractId else {
            throw SmartAccountError.invalidInput("Cannot transfer to self")
        }

        // STEP 2: Convert amount to stroops
        let stroops = try SmartAccountSharedUtils.amountToStroops(amount)

        // STEP 3: Build host function for token transfer
        // Contract call: token.transfer(from: smartAccount, to: recipient, amount: stroops)
        let fromAddress = try SCAddressXDR(contractId: contractId)
        let toAddress: SCAddressXDR
        if recipient.hasPrefix("G") {
            toAddress = try SCAddressXDR(accountId: recipient)
        } else {
            toAddress = try SCAddressXDR(contractId: recipient)
        }

        let amountScVal = SmartAccountSharedUtils.stroopsToI128ScVal(stroops)

        let functionArgs: [SCValXDR] = [
            .address(fromAddress),
            .address(toAddress),
            amountScVal
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: tokenContract),
            functionName: "transfer",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        // STEP 4-8: Submit the transaction (will handle simulation, signing, and polling)
        return try await submit(hostFunction: hostFunction, auth: [])
    }

    // MARK: - Auth Entry Signing

    /// Signs authorization entries matching the connected contract.
    ///
    /// Iterates through all auth entries and signs those with address credentials
    /// matching the connected smart account contract. The signature is added to the
    /// entry's signature map using the specified signer.
    ///
    /// - Parameters:
    ///   - authEntries: The authorization entries to sign
    ///   - signer: The smart account signer to use for signing
    ///   - signatureScVal: The signature value as an SCVal (e.g., WebAuthn signature map)
    ///   - expirationLedger: Optional ledger number at which signatures expire (defaults to current + buffer)
    /// - Returns: Array of signed authorization entries
    /// - Throws: SmartAccountError if signing fails
    ///
    /// Example:
    /// ```swift
    /// let webAuthnSig = try webAuthnSignature.toScVal()
    /// let signedEntries = try await txOps.signAuthEntries(
    ///     authEntries: unsignedEntries,
    ///     signer: externalSigner,
    ///     signatureScVal: webAuthnSig,
    ///     expirationLedger: currentLedger + 100
    /// )
    /// ```
    public func signAuthEntries(
        authEntries: [SorobanAuthorizationEntryXDR],
        signer: SmartAccountSigner,
        signatureScVal: SCValXDR,
        expirationLedger: UInt32? = nil
    ) async throws -> [SorobanAuthorizationEntryXDR] {
        let (_, contractId) = try kit.requireConnected()

        // Determine expiration ledger
        let expiration: UInt32
        if let providedExpiration = expirationLedger {
            expiration = providedExpiration
        } else {
            // Fetch latest ledger and add buffer
            let latestLedgerResponse = await kit.sorobanServer.getLatestLedger()
            guard case .success(let latestLedger) = latestLedgerResponse else {
                throw SmartAccountError.transactionSigningFailed("Failed to fetch latest ledger for expiration calculation")
            }
            expiration = latestLedger.sequence + UInt32(SmartAccountConstants.AUTH_ENTRY_EXPIRATION_BUFFER)
        }

        // Sign all matching auth entries
        var signedEntries: [SorobanAuthorizationEntryXDR] = []

        for entry in authEntries {
            // Check if this entry's credentials match our contract
            guard let credentials = entry.credentials.address else {
                // Not an address credential, skip
                signedEntries.append(entry)
                continue
            }

            // Check if the address matches our contract
            let entryAddress = SmartAccountSharedUtils.extractAddressString(from: credentials.address)
            if entryAddress == contractId {
                // This entry is for our smart account - sign it
                let signedEntry = try SmartAccountAuth.signAuthEntry(
                    entry: entry,
                    signer: signer,
                    signatureScVal: signatureScVal,
                    expirationLedger: expiration,
                    networkPassphrase: kit.config.networkPassphrase
                )
                signedEntries.append(signedEntry)
            } else {
                // Not our entry, pass through unchanged
                signedEntries.append(entry)
            }
        }

        return signedEntries
    }

    // MARK: - Transaction Submission

    /// Submits a host function with full Soroban authorization flow.
    ///
    /// Performs the complete transaction lifecycle: simulation, auth entry extraction,
    /// WebAuthn signing, re-simulation with signed auth, and submission. This method
    /// handles the critical authorization step that allows state-changing operations
    /// to succeed on-chain.
    ///
    /// Flow:
    /// 1. Require connected wallet (credential ID + contract ID)
    /// 2. Get deployer account from kit
    /// 3. Build transaction with host function and provided auth (may be empty)
    /// 4. Simulate transaction to discover required auth entries
    /// 5. Extract auth entries from simulation result
    /// 6. For each auth entry matching our contract:
    ///    a. Set signature expiration ledger
    ///    b. Build auth payload hash
    ///    c. Sign with WebAuthn passkey (triggers biometric prompt)
    ///    d. Normalize signature to low-S compact format
    ///    e. Build WebAuthn signature ScVal
    ///    f. Construct signer key from stored credential
    ///    g. Build signature map entry with double XDR-encoded signature
    ///    h. Set credential signature on entry
    /// 7. Update transaction with signed auth entries
    /// 8. Re-simulate to get correct resource fees
    /// 9. Assemble transaction from re-simulation
    /// 10. Sign envelope with deployer keypair
    /// 11. Determine submission mode (relayer vs RPC)
    /// 12. Submit and poll for confirmation
    ///
    /// IMPORTANT: This method requires WebAuthn interaction to sign auth entries.
    /// The user will be prompted for biometric authentication for each auth entry
    /// that matches the connected smart account contract.
    ///
    /// - Parameters:
    ///   - hostFunction: The host function to execute
    ///   - auth: Authorization entries for the transaction (typically empty; simulation provides them)
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if submission, simulation, signing, or polling fails
    public func submit(
        hostFunction: HostFunctionXDR,
        auth: [SorobanAuthorizationEntryXDR]
    ) async throws -> TransactionResult {
        // STEP 1: Require connected wallet
        let (credentialId, contractId) = try kit.requireConnected()

        // STEP 2: Get deployer account
        let deployer = try kit.getDeployer()

        let accountResponse = await kit.sorobanServer.getAccount(accountId: deployer.accountId)
        guard case .success(let deployerAccount) = accountResponse else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to fetch deployer account")
        }

        // STEP 3: Build transaction with host function and provided auth
        let operation = InvokeHostFunctionOperation(hostFunction: hostFunction, auth: auth)

        let transaction = try Transaction(
            sourceAccount: deployerAccount,
            operations: [operation],
            memo: Memo.none,
            preconditions: nil
        )

        // STEP 4: Simulate transaction
        let simulateRequest = SimulateTransactionRequest(transaction: transaction)
        let simulateResponse = await kit.sorobanServer.simulateTransaction(simulateTxRequest: simulateRequest)

        guard case .success(let simulation) = simulateResponse else {
            if case .failure(let error) = simulateResponse {
                throw SmartAccountError.transactionSimulationFailed(
                    "Transaction simulation failed: \(error.localizedDescription)",
                    cause: error
                )
            }
            throw SmartAccountError.transactionSimulationFailed("Transaction simulation failed")
        }

        // STEP 5: Check for simulation errors
        if let error = simulation.error {
            throw SmartAccountError.transactionSimulationFailed("Simulation error: \(error)")
        }

        // STEP 6: Extract auth entries from simulation
        let simulatedAuthEntries = simulation.sorobanAuth ?? []

        // STEP 7-8: Sign auth entries matching our contract
        var signedAuthEntries: [SorobanAuthorizationEntryXDR] = []

        if !simulatedAuthEntries.isEmpty {
            // Get latest ledger ONCE before the signing loop
            let latestLedgerResponse = await kit.sorobanServer.getLatestLedger()
            guard case .success(let latestLedger) = latestLedgerResponse else {
                throw SmartAccountError.transactionSigningFailed(
                    "Failed to fetch latest ledger for auth entry expiration"
                )
            }
            let expiration = latestLedger.sequence + UInt32(SmartAccountConstants.AUTH_ENTRY_EXPIRATION_BUFFER)

            for var entry in simulatedAuthEntries {
                // Check if this entry has address credentials
                guard case .address(var addressCreds) = entry.credentials else {
                    // Not an address credential (e.g., sourceAccount), pass through unchanged
                    signedAuthEntries.append(entry)
                    continue
                }

                // Check if the address matches our contract
                let entryAddress = SmartAccountSharedUtils.extractAddressString(from: addressCreds.address)
                guard entryAddress == contractId else {
                    // Not our contract's entry, pass through unchanged
                    signedAuthEntries.append(entry)
                    continue
                }

                // This entry matches our smart account contract -- sign it

                // (a) Set expiration ledger
                addressCreds.signatureExpirationLedger = expiration
                // Write back the modified credentials (value semantics)
                entry.credentials = .address(addressCreds)

                // (b) Build the auth payload hash for WebAuthn signing
                let payloadHash = try SmartAccountAuth.buildAuthPayloadHash(
                    entry: entry,
                    expirationLedger: expiration,
                    networkPassphrase: kit.config.networkPassphrase
                )

                // (c) Require WebAuthn provider
                guard let webauthnProvider = kit.webauthnProvider else {
                    throw SmartAccountError.invalidInput(
                        "WebAuthn provider is required for signing auth entries but is not configured"
                    )
                }

                // (d) Authenticate with passkey (triggers biometric prompt)
                let authResult = try await webauthnProvider.authenticate(
                    challenge: payloadHash,
                    rpId: kit.config.rpId ?? "",
                    allowCredentials: nil
                )

                // (e) Normalize DER signature to compact format with low-S
                let compactSig = try SmartAccountUtils.normalizeSignature(authResult.signature)

                // (f) Build WebAuthn signature
                let webAuthnSig = WebAuthnSignature(
                    authenticatorData: authResult.authenticatorData,
                    clientData: authResult.clientDataJSON,
                    signature: compactSig
                )

                // (g) Convert to ScVal
                let sigScVal = try webAuthnSig.toScVal()

                // (h) Reconstruct keyData from stored credential
                let storage = kit.config.getStorage()
                guard let stored = try storage.get(credentialId: credentialId) else {
                    throw SmartAccountError.credentialNotFound(
                        "Stored credential not found for credentialId: \(credentialId)"
                    )
                }

                let publicKey = stored.publicKey
                guard let credIdBytes = SmartAccountSharedUtils.base64urlDecode(credentialId) else {
                    throw SmartAccountError.credentialNotFound(
                        "Failed to decode credentialId from Base64URL: \(credentialId)"
                    )
                }

                var keyData = publicKey
                keyData.append(credIdBytes)

                // (i) Build external signer
                let signer = try ExternalSigner(
                    verifierAddress: kit.config.webauthnVerifierAddress,
                    keyData: keyData
                )

                // (j) Build signature map entry
                let signerKey = try signer.toScVal()
                let sigXdrBytes = try XDREncoder.encode(sigScVal)
                let signatureValue = SCValXDR.bytes(Data(sigXdrBytes))
                let mapEntry = SCMapEntryXDR(key: signerKey, val: signatureValue)

                // (k) Set credential signature: Vec([Map([mapEntry])])
                addressCreds.signature = SCValXDR.vec([SCValXDR.map([mapEntry])])
                entry.credentials = .address(addressCreds)

                signedAuthEntries.append(entry)
            }
        }

        // STEP 9: Update transaction auth entries (avoids building new Transaction / double sequence increment)
        transaction.setSorobanAuth(auth: signedAuthEntries)

        // STEP 10: Re-simulate with signed auth entries to get correct resource fees
        let reSimulateRequest = SimulateTransactionRequest(transaction: transaction)
        let reSimulateResponse = await kit.sorobanServer.simulateTransaction(simulateTxRequest: reSimulateRequest)

        guard case .success(let reSimulation) = reSimulateResponse else {
            if case .failure(let error) = reSimulateResponse {
                throw SmartAccountError.transactionSimulationFailed(
                    "Re-simulation with signed auth failed: \(error.localizedDescription)",
                    cause: error
                )
            }
            throw SmartAccountError.transactionSimulationFailed("Re-simulation with signed auth failed")
        }

        if let error = reSimulation.error {
            throw SmartAccountError.transactionSimulationFailed("Re-simulation error: \(error)")
        }

        // STEP 11: Assemble transaction from re-simulation
        guard let transactionData = reSimulation.transactionData,
              let minResourceFee = reSimulation.minResourceFee else {
            throw SmartAccountError.transactionSubmissionFailed(
                "Failed to get transaction data from re-simulation"
            )
        }

        transaction.setSorobanTransactionData(data: transactionData)
        transaction.addResourceFee(resourceFee: minResourceFee)

        // STEP 12: Sign envelope with deployer keypair
        try transaction.sign(keyPair: deployer, network: Network.custom(passphrase: kit.config.networkPassphrase))

        // STEP 13: Determine submission method using SIGNED auth entries (not original input)
        if let relayer = kit.relayerClient {
            let useMode2 = shouldUseRelayerMode2(authEntries: signedAuthEntries)

            if useMode2 {
                // Mode 2: Submit signed transaction XDR
                let txXdr = try transaction.encodedEnvelope()
                let relayerResponse = try await relayer.sendXdr(txXdr)

                if relayerResponse.success, let hash = relayerResponse.hash {
                    return try await pollForConfirmation(hash: hash)
                } else {
                    return TransactionResult(
                        success: false,
                        error: relayerResponse.error ?? "Relayer submission failed"
                    )
                }
            } else {
                // Mode 1: Submit host function and signed auth entries
                let relayerResponse = try await relayer.send(func: hostFunction, auth: signedAuthEntries)

                if relayerResponse.success, let hash = relayerResponse.hash {
                    return try await pollForConfirmation(hash: hash)
                } else {
                    return TransactionResult(
                        success: false,
                        error: relayerResponse.error ?? "Relayer submission failed"
                    )
                }
            }
        } else {
            // No relayer - submit via RPC
            let sendResponse = await kit.sorobanServer.sendTransaction(transaction: transaction)

            guard case .success(let sendResult) = sendResponse else {
                if case .failure(let error) = sendResponse {
                    throw SmartAccountError.transactionSubmissionFailed(
                        "Failed to send transaction: \(error.localizedDescription)",
                        cause: error
                    )
                }
                throw SmartAccountError.transactionSubmissionFailed("Failed to send transaction")
            }

            if let error = sendResult.errorResultXdr {
                throw SmartAccountError.transactionSubmissionFailed("Transaction submission error: \(error)")
            }

            return try await pollForConfirmation(hash: sendResult.transactionId)
        }
    }

    // MARK: - Pre-Assembled Transaction Submission

    /// Submits a pre-assembled transaction (already simulated, signed auth entries set, resource fees applied).
    ///
    /// This is used by multiSignerTransfer which handles its own simulation and auth signing flow.
    /// The transaction only needs the deployer envelope signature and submission.
    ///
    /// - Parameter transaction: The assembled transaction ready for submission
    /// - Returns: TransactionResult with submission outcome
    /// - Throws: SmartAccountError if submission fails
    internal func submitAssembledTransaction(_ transaction: Transaction) async throws -> TransactionResult {
        let deployer = try kit.getDeployer()
        try transaction.sign(keyPair: deployer, network: Network.custom(passphrase: kit.config.networkPassphrase))

        // Determine submission method
        let authEntries: [SorobanAuthorizationEntryXDR] = transaction.operations
            .compactMap { $0 as? InvokeHostFunctionOperation }
            .flatMap { $0.auth }

        if let relayer = kit.relayerClient {
            let useMode2 = shouldUseRelayerMode2(authEntries: authEntries)

            if useMode2 {
                // Mode 2: Submit signed transaction XDR
                let txXdr = try transaction.encodedEnvelope()
                let relayerResponse = try await relayer.sendXdr(txXdr)

                if relayerResponse.success, let hash = relayerResponse.hash {
                    return try await pollForConfirmation(hash: hash)
                } else {
                    return TransactionResult(
                        success: false,
                        error: relayerResponse.error ?? "Relayer submission failed"
                    )
                }
            } else {
                // Mode 1: Submit signed transaction XDR (multi-signer transactions
                // always use Mode 2 since the auth entries are already assembled)
                let txXdr = try transaction.encodedEnvelope()
                let relayerResponse = try await relayer.sendXdr(txXdr)

                if relayerResponse.success, let hash = relayerResponse.hash {
                    return try await pollForConfirmation(hash: hash)
                } else {
                    return TransactionResult(
                        success: false,
                        error: relayerResponse.error ?? "Relayer submission failed"
                    )
                }
            }
        } else {
            // No relayer - submit via RPC
            let sendResponse = await kit.sorobanServer.sendTransaction(transaction: transaction)

            guard case .success(let sendResult) = sendResponse else {
                if case .failure(let error) = sendResponse {
                    throw SmartAccountError.transactionSubmissionFailed(
                        "Failed to send transaction: \(error.localizedDescription)",
                        cause: error
                    )
                }
                throw SmartAccountError.transactionSubmissionFailed("Failed to send transaction")
            }

            if let error = sendResult.errorResultXdr {
                throw SmartAccountError.transactionSubmissionFailed("Transaction submission error: \(error)")
            }

            return try await pollForConfirmation(hash: sendResult.transactionId)
        }
    }

    // MARK: - Testnet Wallet Funding

    /// Funds the smart account wallet using Friendbot (testnet only).
    ///
    /// Creates a temporary keypair, funds it via Friendbot, then transfers the balance
    /// (minus reserve) to the smart account contract. This enables testing without
    /// requiring pre-funded wallets.
    ///
    /// Flow:
    /// 1. Generate random temporary keypair
    /// 2. Fund temp account via Friendbot HTTP GET
    /// 3. Wait briefly for funding to confirm
    /// 4. Query temp account balance via native token contract simulation
    /// 5. Calculate transfer amount (balance - reserve)
    /// 6. Build transfer from temp to smart account
    /// 7. Simulate, sign with temp keypair, submit via RPC
    /// 8. Return funded amount in XLM
    ///
    /// IMPORTANT: Only works on testnet. Do not use on mainnet.
    ///
    /// - Parameter nativeTokenContract: The native token (XLM) contract address (C-address)
    /// - Returns: The amount funded in XLM
    /// - Throws: SmartAccountError if funding fails at any step
    ///
    /// Example:
    /// ```swift
    /// let fundedAmount = try await txOps.fundWallet(
    ///     nativeTokenContract: "CBCD1234..."
    /// )
    /// print("Funded smart account with \(fundedAmount) XLM")
    /// ```
    public func fundWallet(nativeTokenContract: String) async throws -> Decimal {
        let (_, contractId) = try kit.requireConnected()

        // Validate native token contract address
        guard nativeTokenContract.hasPrefix("C"), nativeTokenContract.count == 56 else {
            throw SmartAccountError.invalidAddress("Native token contract must be a valid C-address, got: \(nativeTokenContract)")
        }

        // STEP 1: Create temporary keypair
        let tempKeypair = try KeyPair.generateRandomKeyPair()

        // STEP 2: Fund via Friendbot
        let friendbotUrl = "\(SmartAccountConstants.FRIENDBOT_URL)?addr=\(tempKeypair.accountId)"
        guard let url = URL(string: friendbotUrl) else {
            throw SmartAccountError.transactionSubmissionFailed("Invalid Friendbot URL")
        }

        let (_, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SmartAccountError.transactionSubmissionFailed("Friendbot funding failed")
        }

        // STEP 3: Wait for funding to confirm (2 seconds)
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // STEP 4: Get temp account
        let accountResponse = await kit.sorobanServer.getAccount(accountId: tempKeypair.accountId)
        guard case .success(let tempAccount) = accountResponse else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to fetch temp account after funding")
        }

        // STEP 5: Calculate transfer amount
        // Reserve for account minimum balance
        let reserveStroops = Int64(SmartAccountConstants.FRIENDBOT_RESERVE_XLM) * SmartAccountConstants.STROOPS_PER_XLM

        // Query temp account balance via contract simulation
        let balanceArgs: [SCValXDR] = [.address(try SCAddressXDR(accountId: tempKeypair.accountId))]
        let balanceInvokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: nativeTokenContract),
            functionName: "balance",
            args: balanceArgs
        )
        let balanceHostFunction = HostFunctionXDR.invokeContract(balanceInvokeArgs)
        let balanceResult = try await SmartAccountSharedUtils.simulateAndExtractResult(
            hostFunction: balanceHostFunction, kit: kit
        )

        // Parse I128 result to Int64 stroops
        guard case .i128(let i128Parts) = balanceResult else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to query temp account balance")
        }
        // For typical Friendbot amounts (10,000 XLM), the hi part is zero and lo fits in Int64
        let balanceStroops = Int64(bitPattern: i128Parts.lo)

        guard balanceStroops > reserveStroops else {
            throw SmartAccountError.transactionSubmissionFailed("Insufficient balance after Friendbot funding")
        }

        let transferStroops = balanceStroops - reserveStroops

        // STEP 6: Build transfer from temp account to smart account
        let fromAddress = try SCAddressXDR(accountId: tempKeypair.accountId)
        let toAddress = try SCAddressXDR(contractId: contractId)
        let amountScVal = SmartAccountSharedUtils.stroopsToI128ScVal(transferStroops)

        let functionArgs: [SCValXDR] = [
            .address(fromAddress),
            .address(toAddress),
            amountScVal
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: nativeTokenContract),
            functionName: "transfer",
            args: functionArgs
        )

        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)
        let operation = InvokeHostFunctionOperation(hostFunction: hostFunction, auth: [])

        // STEP 7: Simulate
        let transaction = try Transaction(
            sourceAccount: tempAccount,
            operations: [operation],
            memo: Memo.none,
            preconditions: nil
        )

        let simulateRequest = SimulateTransactionRequest(transaction: transaction)
        let simulateResponse = await kit.sorobanServer.simulateTransaction(simulateTxRequest: simulateRequest)

        guard case .success(let simulation) = simulateResponse else {
            throw SmartAccountError.transactionSimulationFailed("Failed to simulate funding transfer")
        }

        // Extract auth entries from simulation and set on transaction
        let decodedAuth = simulation.sorobanAuth ?? []
        if !decodedAuth.isEmpty {
            transaction.setSorobanAuth(auth: decodedAuth)
        }

        // Assemble transaction from simulation
        guard let transactionData = simulation.transactionData,
              let minResourceFee = simulation.minResourceFee else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to get transaction data from simulation")
        }

        transaction.setSorobanTransactionData(data: transactionData)
        transaction.addResourceFee(resourceFee: minResourceFee)

        // Sign with temp keypair
        try transaction.sign(keyPair: tempKeypair, network: Network.custom(passphrase: kit.config.networkPassphrase))

        // Submit via RPC
        let sendResponse = await kit.sorobanServer.sendTransaction(transaction: transaction)

        guard case .success(let sendResult) = sendResponse else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to send funding transaction")
        }

        // Poll for confirmation
        let result = try await pollForConfirmation(hash: sendResult.transactionId)

        if !result.success {
            throw SmartAccountError.transactionSubmissionFailed(
                "Funding transaction failed: \(result.error ?? "unknown error")"
            )
        }

        // STEP 8: Return funded amount in XLM
        let fundedXLM = Decimal(transferStroops) / Decimal(SmartAccountConstants.STROOPS_PER_XLM)
        return fundedXLM
    }

    // MARK: - Private Helpers

    /// Determines if relayer Mode 2 should be used based on auth entries.
    ///
    /// Mode 2 (signed transaction XDR) is required when any auth entry has
    /// source_account credentials rather than address credentials.
    ///
    /// - Parameter authEntries: The authorization entries to check
    /// - Returns: True if Mode 2 should be used, false for Mode 1
    private func shouldUseRelayerMode2(authEntries: [SorobanAuthorizationEntryXDR]) -> Bool {
        return authEntries.contains { entry in
            if case .sourceAccount = entry.credentials {
                return true
            }
            return false
        }
    }

    /// Polls for transaction confirmation.
    ///
    /// Repeatedly checks the transaction status on Soroban RPC until it is confirmed,
    /// fails, or times out. Uses exponential backoff between attempts.
    ///
    /// - Parameter hash: The transaction hash to poll
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if polling times out
    private func pollForConfirmation(hash: String) async throws -> TransactionResult {
        let maxAttempts = 10
        let sleepDurationNs: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds

        for attempt in 1...maxAttempts {
            let txResponse = await kit.sorobanServer.getTransaction(transactionHash: hash)

            guard case .success(let txStatus) = txResponse else {
                // Network error, retry
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: sleepDurationNs)
                    continue
                }
                throw SmartAccountError.transactionTimeout("Failed to retrieve transaction status after \(maxAttempts) attempts")
            }

            switch txStatus.status {
            case GetTransactionResponse.STATUS_SUCCESS:
                return TransactionResult(
                    success: true,
                    hash: hash,
                    ledger: txStatus.ledger.flatMap { UInt32(exactly: $0) }
                )

            case GetTransactionResponse.STATUS_FAILED:
                let errorMessage = txStatus.resultXdr ?? "Transaction failed on-chain"
                return TransactionResult(
                    success: false,
                    hash: hash,
                    ledger: txStatus.ledger.flatMap { UInt32(exactly: $0) },
                    error: errorMessage
                )

            case GetTransactionResponse.STATUS_NOT_FOUND:
                // Transaction not yet confirmed, retry
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: sleepDurationNs)
                    continue
                }
                return TransactionResult(
                    success: false,
                    hash: hash,
                    error: "Transaction timed out after \(maxAttempts) attempts"
                )

            default:
                // Unknown status, retry
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: sleepDurationNs)
                    continue
                }
                return TransactionResult(
                    success: false,
                    hash: hash,
                    error: "Transaction polling timed out with unknown status: \(txStatus.status)"
                )
            }
        }

        // Should not reach here, but for safety
        throw SmartAccountError.transactionTimeout("Transaction polling timed out after \(maxAttempts) attempts")
    }
}
