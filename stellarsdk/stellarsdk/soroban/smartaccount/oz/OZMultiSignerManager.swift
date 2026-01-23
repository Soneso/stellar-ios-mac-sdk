//
//  OZMultiSignerManager.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Available Signer Types

/// Represents a signer available for multi-signature operations.
///
/// Contains information about whether the signer can currently sign and where
/// the signer originates from (passkey or external wallet).
public struct AvailableSigner: Sendable {
    /// The smart account signer.
    public let signer: SmartAccountSigner

    /// Whether this signer can currently sign transactions.
    ///
    /// For passkey signers: true if the credential ID matches the connected wallet.
    /// For delegated signers: true if the external wallet can sign for the address.
    /// For external signers with non-WebAuthn verifiers: false (not yet supported).
    public let canSign: Bool

    /// The source of this signer.
    public let source: SignerSource

    /// Creates a new AvailableSigner.
    ///
    /// - Parameters:
    ///   - signer: The smart account signer
    ///   - canSign: Whether this signer can currently sign
    ///   - source: The source of this signer
    public init(signer: SmartAccountSigner, canSign: Bool, source: SignerSource) {
        self.signer = signer
        self.canSign = canSign
        self.source = source
    }
}

/// The source of a signer for multi-signature operations.
public enum SignerSource: String, Sendable {
    /// Passkey signer (WebAuthn credential).
    case passkey

    /// External wallet signer (e.g., Freighter, Albedo).
    case externalWallet
}

// MARK: - Multi-Signer Manager

/// Manager for multi-signature smart account operations.
///
/// OZMultiSignerManager provides functionality for:
/// - Querying available signers from context rules
/// - Executing multi-signature token transfers
/// - Collecting signatures from both passkey and external wallets
///
/// Multi-signature transactions require collecting signatures from multiple signers
/// sequentially to enable fail-fast behavior on user cancellation. The signature
/// collection order is:
/// 1. Connected passkey (if required)
/// 2. External wallet signers (delegated addresses)
///
/// Delegated signers produce their own auth entries with Address credentials that
/// reference the smart account's __check_auth function. The smart account's signature
/// map includes a placeholder for each delegated signer.
///
/// Example usage:
/// ```swift
/// let kit = try OZSmartAccountKit(config: config)
/// let multiSigner = OZMultiSignerManager(kit: kit, transactionOps: txOps)
///
/// // Get available signers
/// let signers = try await multiSigner.getAvailableSigners()
/// print("Available signers: \(signers.count)")
///
/// // Execute multi-signature transfer
/// let additionalSigners = [delegatedSigner]
/// let result = try await multiSigner.multiSignerTransfer(
///     tokenContract: "CBCD...",
///     recipient: "GA7Q...",
///     amount: 100.0,
///     additionalSigners: additionalSigners
/// )
/// print("Transfer \(result.success ? "succeeded" : "failed")")
/// ```
public final class OZMultiSignerManager: @unchecked Sendable {
    /// Reference to the parent SmartAccountKit instance.
    private let kit: OZSmartAccountKit

    /// Transaction operations manager.
    private let transactionOps: OZTransactionOperations

    /// Creates a new OZMultiSignerManager instance.
    ///
    /// - Parameters:
    ///   - kit: The parent OZSmartAccountKit instance
    ///   - transactionOps: The transaction operations manager
    internal init(kit: OZSmartAccountKit, transactionOps: OZTransactionOperations) {
        self.kit = kit
        self.transactionOps = transactionOps
    }

    // MARK: - Get Available Signers

    /// Retrieves the list of available signers for the connected smart account.
    ///
    /// Queries the smart account contract's context rules and determines which signers
    /// can currently sign transactions. A signer is marked as "can sign" if:
    ///
    /// - External signer with WebAuthn verifier: canSign = true if credential ID matches connected wallet
    /// - Delegated signer: canSign = true if externalWallet.canSignFor(address) returns true
    /// - External signer with other verifier: canSign = false (not yet supported)
    ///
    /// - Returns: Array of available signers with their signing capabilities
    /// - Throws: SmartAccountError if not connected or if contract query fails
    ///
    /// Example:
    /// ```swift
    /// let signers = try await multiSigner.getAvailableSigners()
    /// for availableSigner in signers {
    ///     if availableSigner.canSign {
    ///         print("Can sign with: \(availableSigner.source)")
    ///     }
    /// }
    /// ```
    public func getAvailableSigners() async throws -> [AvailableSigner] {
        // STEP 1: Require connected state
        let (credentialId, contractId) = try kit.requireConnected()

        // STEP 2: Query default context rules from contract
        let contextTypeScVal = SCValXDR.vec([.symbol("Default")])
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: contractId),
            functionName: "get_context_rules",
            args: [contextTypeScVal]
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        let resultScVal: SCValXDR
        do {
            resultScVal = try await SmartAccountSharedUtils.simulateAndExtractResult(hostFunction: hostFunction, kit: kit)
        } catch {
            // If query fails (e.g., no rules configured), return empty array
            return []
        }

        // STEP 3: Parse signers from context rules response
        let parsedSigners = Self.parseSignersFromContextRulesResponse(resultScVal)

        // STEP 4: Determine canSign for each signer
        var availableSigners: [AvailableSigner] = []

        for parsed in parsedSigners {
            switch parsed.tag {
            case "Delegated":
                let canSign: Bool
                if let externalWallet = kit.config.externalWallet {
                    canSign = (try? await externalWallet.canSignFor(address: parsed.address)) ?? false
                } else {
                    canSign = false
                }
                let signer = try DelegatedSigner(address: parsed.address)
                availableSigners.append(AvailableSigner(
                    signer: signer,
                    canSign: canSign,
                    source: .externalWallet
                ))

            case "External":
                guard let keyBytes = parsed.keyBytes else { continue }
                let signer = try ExternalSigner(verifierAddress: parsed.address, keyData: keyBytes)

                // Determine if this is a WebAuthn signer we can sign with
                let canSign: Bool
                if parsed.address == kit.config.webauthnVerifierAddress,
                   let signerCredentialId = parsed.credentialId {
                    let signerCredentialIdEncoded = SmartAccountSharedUtils.base64urlEncode(signerCredentialId)
                    canSign = (signerCredentialIdEncoded == credentialId)
                } else {
                    canSign = false
                }

                availableSigners.append(AvailableSigner(
                    signer: signer,
                    canSign: canSign,
                    source: .passkey
                ))

            default:
                continue
            }
        }

        return availableSigners
    }

    // MARK: - Signer Parsing (Internal for testing)

    /// Parsed signer extracted from on-chain context rules.
    internal struct ParsedContractSigner: Equatable {
        let tag: String // "Delegated" or "External"
        let address: String // G-address for Delegated, C-address (verifier) for External
        let keyBytes: Data? // key_data for External signers, nil for Delegated

        /// For WebAuthn External signers, extracts the credential ID from keyBytes.
        /// Key data format: publicKey (65 bytes) + credentialId (variable).
        /// Returns nil if not a WebAuthn signer (keyBytes <= 65 bytes).
        var credentialId: Data? {
            guard let keyBytes = keyBytes,
                  keyBytes.count > SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE else {
                return nil
            }
            return Data(keyBytes.suffix(from: SmartAccountConstants.SECP256R1_PUBLIC_KEY_SIZE))
        }
    }

    /// Parses unique signers from a `get_context_rules` contract response.
    ///
    /// The response ScVal is expected to be `Vec<ContextRule>` where each ContextRule
    /// is a Map (Soroban struct) with alphabetically-sorted Symbol keys.
    /// The "signers" field contains `Vec<Signer>` where each Signer is:
    /// - `Vec([Symbol("Delegated"), Address(addr)])`
    /// - `Vec([Symbol("External"), Address(verifier), Bytes(keyData)])`
    ///
    /// - Parameter resultScVal: The raw ScVal response from `get_context_rules`
    /// - Returns: Array of unique parsed signers, deduplicated by composite key
    internal static func parseSignersFromContextRulesResponse(
        _ resultScVal: SCValXDR
    ) -> [ParsedContractSigner] {
        guard case .vec(let rules?) = resultScVal else {
            return []
        }

        var signerKeys = Set<String>()
        var uniqueSigners: [ParsedContractSigner] = []

        for ruleScVal in rules {
            guard case .map(let fields?) = ruleScVal else { continue }

            for field in fields {
                guard case .symbol(let key) = field.key, key == "signers" else { continue }
                guard case .vec(let signerVec?) = field.val else { break }

                for signerScVal in signerVec {
                    guard case .vec(let signerParts?) = signerScVal, !signerParts.isEmpty else { continue }
                    guard case .symbol(let tag) = signerParts[0] else { continue }

                    let parsed: ParsedContractSigner
                    let signerKey: String

                    switch tag {
                    case "Delegated":
                        guard signerParts.count >= 2,
                              case .address(let addr) = signerParts[1],
                              let address = SmartAccountSharedUtils.extractAddressString(from: addr) else { continue }
                        signerKey = "delegated:\(address)"
                        parsed = ParsedContractSigner(tag: "Delegated", address: address, keyBytes: nil)

                    case "External":
                        guard signerParts.count >= 3,
                              case .address(let addr) = signerParts[1],
                              case .bytes(let bytes) = signerParts[2],
                              let address = SmartAccountSharedUtils.extractAddressString(from: addr) else { continue }
                        signerKey = "external:\(address):\(bytes.map { String(format: "%02x", $0) }.joined())"
                        parsed = ParsedContractSigner(tag: "External", address: address, keyBytes: bytes)

                    default:
                        continue
                    }

                    guard !signerKeys.contains(signerKey) else { continue }
                    signerKeys.insert(signerKey)
                    uniqueSigners.append(parsed)
                }
                break
            }
        }

        return uniqueSigners
    }

    // MARK: - Multi-Signer Transfer

    /// Executes a token transfer with multiple signers.
    ///
    /// Performs a multi-signature token transfer by collecting signatures from the connected
    /// passkey and any additional delegated signers. The signature collection is sequential:
    /// 1. Passkey signer (if WebAuthn provider is configured)
    /// 2. External wallet signers (for each delegated signer)
    ///
    /// This ordering enables fail-fast behavior: if the user cancels the passkey prompt,
    /// no external wallet signatures are collected.
    ///
    /// Delegated signers produce their own auth entries with Address credentials that
    /// invoke the smart account's __check_auth function. The smart account's signature
    /// map includes a placeholder entry for each delegated signer.
    ///
    /// - Parameters:
    ///   - tokenContract: The token contract address (C-address)
    ///   - recipient: The recipient address (G-address or C-address)
    ///   - amount: The amount to transfer in XLM units
    ///   - additionalSigners: Array of additional signers (delegated addresses)
    /// - Returns: TransactionResult indicating success or failure
    /// - Throws: SmartAccountError if validation fails, signing fails, or submission fails
    ///
    /// Example:
    /// ```swift
    /// let delegatedSigner = try DelegatedSigner(address: "GA7Q...")
    /// let result = try await multiSigner.multiSignerTransfer(
    ///     tokenContract: nativeTokenAddress,
    ///     recipient: "GBXYZ...",
    ///     amount: 50.0,
    ///     additionalSigners: [delegatedSigner]
    /// )
    /// if result.success {
    ///     print("Multi-sig transfer succeeded: \(result.hash ?? "")")
    /// }
    /// ```
    public func multiSignerTransfer(
        tokenContract: String,
        recipient: String,
        amount: Decimal,
        additionalSigners: [SmartAccountSigner]
    ) async throws -> TransactionResult {
        // STEP 1: Validate inputs (same as single-signer transfer)
        let (credentialId, contractId) = try kit.requireConnected()

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

        // Check for delegated signers requiring external wallet
        let hasDelegatedSigners = additionalSigners.contains { $0.signerType == .delegated }
        if hasDelegatedSigners && kit.config.externalWallet == nil {
            throw SmartAccountError.invalidInput("Delegated signers require an external wallet adapter to be configured")
        }

        // STEP 2: Build host function for token transfer
        let stroops = try SmartAccountSharedUtils.amountToStroops(amount)

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

        // STEP 3: Simulate to get auth entries
        let deployer = try kit.getDeployer()
        let accountResponse = await kit.sorobanServer.getAccount(accountId: deployer.accountId)
        guard case .success(let deployerAccount) = accountResponse else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to fetch deployer account")
        }

        let operation = InvokeHostFunctionOperation(hostFunction: hostFunction, auth: [])
        let transaction = try Transaction(
            sourceAccount: deployerAccount,
            operations: [operation],
            memo: Memo.none,
            preconditions: nil
        )

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

        if let error = simulation.error {
            throw SmartAccountError.transactionSimulationFailed("Simulation error: \(error)")
        }

        guard let authEntries = simulation.results?.first?.auth else {
            throw SmartAccountError.transactionSimulationFailed("No auth entries returned from simulation")
        }

        // STEP 4: Get current ledger sequence
        let latestLedgerResponse = await kit.sorobanServer.getLatestLedger()
        guard case .success(let latestLedger) = latestLedgerResponse else {
            throw SmartAccountError.transactionSigningFailed("Failed to fetch latest ledger for expiration calculation")
        }

        // STEP 5: Calculate expiration
        let expirationLedger = latestLedger.sequence + UInt32(SmartAccountConstants.AUTH_ENTRY_EXPIRATION_BUFFER)

        // STEP 6: Decode auth entries from base64 and collect signatures
        var signedAuthEntries: [SorobanAuthorizationEntryXDR] = []

        for authEntryString in authEntries {
            // Decode the auth entry from base64
            let entry = try SorobanAuthorizationEntryXDR(fromBase64: authEntryString)

            // Check if this entry's credentials match our contract
            guard let credentials = entry.credentials.address else {
                // Not an address credential, pass through unchanged
                signedAuthEntries.append(entry)
                continue
            }

            let entryAddress = SmartAccountSharedUtils.extractAddressString(from: credentials.address)
            if entryAddress != contractId {
                // Not our entry, pass through unchanged
                signedAuthEntries.append(entry)
                continue
            }

            // STEP 6a: Build payload hash
            let payloadHash = try SmartAccountAuth.buildAuthPayloadHash(
                entry: entry,
                expirationLedger: expirationLedger,
                networkPassphrase: kit.config.networkPassphrase
            )

            // STEP 6b: Collect signatures sequentially
            var collectedSignatures: [(signer: SmartAccountSigner, signatureScVal: SCValXDR, isPlaceholder: Bool)] = []

            // Check if connected passkey is required as a signer
            let availableSigners = try await getAvailableSigners()
            let passkeyRequired = availableSigners.contains { $0.canSign && $0.source == .passkey }

            // Fallback: if getAvailableSigners returned empty (network query failed),
            // assume passkey is needed to avoid silent transfer failure
            let shouldPromptPasskey = passkeyRequired || availableSigners.isEmpty

            // First, collect passkey signature if required and WebAuthn provider is configured
            if shouldPromptPasskey, let webauthnProvider = kit.webauthnProvider {
                // Trigger WebAuthn authentication
                let authResult: WebAuthnAuthenticationResult
                do {
                    authResult = try await webauthnProvider.authenticate(
                        challenge: payloadHash,
                        rpId: kit.config.rpId ?? "localhost",
                        allowCredentials: nil
                    )
                } catch {
                    throw SmartAccountError.webAuthnAuthenticationFailed(
                        "WebAuthn authentication failed: \(error.localizedDescription)",
                        cause: error
                    )
                }

                // Normalize signature (DER to compact, low-S)
                let normalizedSignature = try SmartAccountUtils.normalizeSignature(authResult.signature)

                // Build WebAuthnSignature
                let webAuthnSignature = WebAuthnSignature(
                    authenticatorData: authResult.authenticatorData,
                    clientData: authResult.clientDataJSON,
                    signature: normalizedSignature
                )

                let webAuthnSignatureScVal = try webAuthnSignature.toScVal()

                // Look up stored credential to get the public key
                let storage = kit.config.getStorage()
                let storedCredential = try storage.get(credentialId: credentialId)
                guard let publicKey = storedCredential?.publicKey else {
                    throw SmartAccountError.credentialNotFound(
                        "No stored credential found for: \(credentialId)"
                    )
                }

                // Build key_data: publicKey (65 bytes) + credentialIdBytes
                // This matches the on-chain signer format where key_data contains both
                guard let credentialIdBytes = SmartAccountSharedUtils.base64urlDecode(credentialId) else {
                    throw SmartAccountError.invalidInput("Failed to decode credential ID")
                }
                var keyData = publicKey
                keyData.append(credentialIdBytes)

                // Build ExternalSigner with WebAuthn verifier and full key data
                let passkeySigner = try ExternalSigner(
                    verifierAddress: kit.config.webauthnVerifierAddress,
                    keyData: keyData
                )

                collectedSignatures.append((
                    signer: passkeySigner,
                    signatureScVal: webAuthnSignatureScVal,
                    isPlaceholder: false
                ))
            }

            // STEP 6b: Collect signatures from delegated signers
            for additionalSigner in additionalSigners {
                if additionalSigner.signerType == .delegated {
                    guard let delegatedSigner = additionalSigner as? DelegatedSigner else {
                        throw SmartAccountError.signerInvalid("Additional signer is not a DelegatedSigner")
                    }

                    guard let externalWallet = kit.config.externalWallet else {
                        throw SmartAccountError.invalidInput("External wallet adapter is required for delegated signers")
                    }

                    // Build delegated signer auth entry
                    let delegatedAuthEntry = try await buildDelegatedSignerAuthEntry(
                        payloadHash: payloadHash,
                        delegatedAddress: delegatedSigner.address,
                        expirationLedger: expirationLedger
                    )

                    // XDR encode the auth entry for signing
                    let authEntryXdr = try XDREncoder.encode(delegatedAuthEntry)
                    let authEntryXdrBase64 = Data(authEntryXdr).base64EncodedString()

                    // Request signature from external wallet
                    let signedAuthEntryXdr: String
                    do {
                        signedAuthEntryXdr = try await externalWallet.signAuthEntry(
                            preimageXdr: authEntryXdrBase64,
                            options: ExternalSignOptions(
                                address: delegatedSigner.address,
                                networkPassphrase: kit.config.networkPassphrase
                            )
                        )
                    } catch {
                        throw SmartAccountError.transactionSigningFailed(
                            "External wallet signing failed: \(error.localizedDescription)",
                            cause: error
                        )
                    }

                    // Decode the signed auth entry
                    guard let signedAuthEntryData = Data(base64Encoded: signedAuthEntryXdr) else {
                        throw SmartAccountError.transactionSigningFailed("Failed to decode signed auth entry from external wallet")
                    }

                    let signedDelegatedAuthEntry = try XDRDecoder.decode(
                        SorobanAuthorizationEntryXDR.self,
                        data: [UInt8](signedAuthEntryData)
                    )

                    // Add the signed delegated auth entry to our list
                    signedAuthEntries.append(signedDelegatedAuthEntry)

                    // Add placeholder to smart account's signature map
                    let placeholderSignature = SCValXDR.bytes(Data()) // Empty bytes
                    collectedSignatures.append((
                        signer: delegatedSigner,
                        signatureScVal: placeholderSignature,
                        isPlaceholder: true
                    ))
                }
            }

            // STEP 6c: Build signature map with ALL collected signatures
            var mapEntries: [SCMapEntryXDR] = []

            for (signer, signatureScVal, isPlaceholder) in collectedSignatures {
                let signerKey = try signer.toScVal()

                let signatureValue: SCValXDR
                if isPlaceholder {
                    // Delegated signer placeholder: use the ScVal directly (no double-encoding).
                    // This matches the TypeScript reference which uses xdr.ScVal.scvBytes(Buffer.alloc(0))
                    // directly without additional XDR encoding.
                    signatureValue = signatureScVal
                } else {
                    // Real signature (e.g., WebAuthn): XDR-encode the signature ScVal
                    // and wrap it in bytes, matching the contract's expected format.
                    let sigXdrBytes = try XDREncoder.encode(signatureScVal)
                    signatureValue = SCValXDR.bytes(Data(sigXdrBytes))
                }

                let mapEntry = SCMapEntryXDR(key: signerKey, val: signatureValue)
                mapEntries.append(mapEntry)
            }

            // STEP 6d: Sort map entries by ascending lowercase hex of XDR-encoded keys
            mapEntries.sort { entry1, entry2 in
                do {
                    let key1Bytes = try XDREncoder.encode(entry1.key)
                    let key2Bytes = try XDREncoder.encode(entry2.key)

                    let key1Hex = key1Bytes.map { String(format: "%02x", $0) }.joined()
                    let key2Hex = key2Bytes.map { String(format: "%02x", $0) }.joined()

                    return key1Hex < key2Hex
                } catch {
                    return false
                }
            }

            // STEP 6e: Set credentials.signature
            var updatedCredentials = credentials
            updatedCredentials.signatureExpirationLedger = expirationLedger

            let signatureMap = SCValXDR.map(mapEntries)
            updatedCredentials.signature = SCValXDR.vec([signatureMap])

            var signedEntry = entry
            signedEntry.credentials = SorobanCredentialsXDR.address(updatedCredentials)

            signedAuthEntries.append(signedEntry)
        }

        // STEP 7: Re-simulate with signed auth entries
        // Refetch deployer account to avoid sequence number double-increment.
        // The first Transaction (used for initial simulation) already incremented
        // deployerAccount's sequence number in memory, so reusing it would produce
        // a transaction with seqNum + 2, which fails on-chain.
        let refetchedAccountResponse = await kit.sorobanServer.getAccount(accountId: deployer.accountId)
        guard case .success(let freshDeployerAccount) = refetchedAccountResponse else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to refetch deployer account")
        }

        let signedOperation = InvokeHostFunctionOperation(hostFunction: hostFunction, auth: signedAuthEntries)
        let signedTransaction = try Transaction(
            sourceAccount: freshDeployerAccount,
            operations: [signedOperation],
            memo: Memo.none,
            preconditions: nil
        )

        let resignedSimulateRequest = SimulateTransactionRequest(transaction: signedTransaction)
        let resignedSimulateResponse = await kit.sorobanServer.simulateTransaction(simulateTxRequest: resignedSimulateRequest)

        guard case .success(let resignedSimulation) = resignedSimulateResponse else {
            throw SmartAccountError.transactionSimulationFailed("Re-simulation with signed auth entries failed")
        }

        if let error = resignedSimulation.error {
            throw SmartAccountError.transactionSimulationFailed("Re-simulation error: \(error)")
        }

        guard let transactionData = resignedSimulation.transactionData,
              let minResourceFee = resignedSimulation.minResourceFee else {
            throw SmartAccountError.transactionSubmissionFailed("Failed to get transaction data from re-simulation")
        }

        signedTransaction.setSorobanTransactionData(data: transactionData)
        signedTransaction.addResourceFee(resourceFee: minResourceFee)

        // STEP 8: Submit the assembled transaction (already simulated, auth signed, fees applied)
        return try await transactionOps.submitAssembledTransaction(signedTransaction)
    }

    // MARK: - Private Helpers

    /// Builds a delegated signer auth entry for external wallet signing.
    ///
    /// Delegated signers produce their own auth entries with Address credentials
    /// that invoke the smart account's __check_auth function.
    ///
    /// - Parameters:
    ///   - payloadHash: The payload hash to authorize
    ///   - delegatedAddress: The delegated signer's Stellar address
    ///   - expirationLedger: The ledger number at which the signature expires
    /// - Returns: The auth entry for the delegated signer
    /// - Throws: SmartAccountError if construction fails
    private func buildDelegatedSignerAuthEntry(
        payloadHash: Data,
        delegatedAddress: String,
        expirationLedger: UInt32
    ) async throws -> SorobanAuthorizationEntryXDR {
        let (_, contractId) = try kit.requireConnected()

        // Build the delegated signer's Address credentials
        let delegatedScAddress = try SCAddressXDR(accountId: delegatedAddress)

        // Use timestamp-based nonce
        let nonce = Int64(Date().timeIntervalSince1970 * 1000)

        let addressCredentials = SorobanAddressCredentialsXDR(
            address: delegatedScAddress,
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            signature: SCValXDR.vec([]) // Will be filled by external wallet
        )

        // Build the root invocation targeting smart account's __check_auth
        let smartAccountAddress = try SCAddressXDR(contractId: contractId)

        let contractFn = SorobanAuthorizedFunctionXDR.contractFn(
            InvokeContractArgsXDR(
                contractAddress: smartAccountAddress,
                functionName: "__check_auth",
                args: [SCValXDR.bytes(payloadHash)]
            )
        )

        let rootInvocation = SorobanAuthorizedInvocationXDR(
            function: contractFn,
            subInvocations: []
        )

        // Build the auth entry
        return SorobanAuthorizationEntryXDR(
            credentials: SorobanCredentialsXDR.address(addressCredentials),
            rootInvocation: rootInvocation
        )
    }

}
