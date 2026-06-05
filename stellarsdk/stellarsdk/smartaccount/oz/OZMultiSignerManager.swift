//
//  OZMultiSignerManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security


/// Manager for multi-signature smart-account operations.
///
/// Collects signatures from a caller-supplied list of signers (passkeys,
/// external wallet addresses, and Ed25519 external signers) and submits the
/// assembled transaction through the kit's transaction operations.
///
/// Signatures are collected sequentially in `selectedSigners` order. Each
/// passkey signer triggers one OS WebAuthn prompt; each wallet signer triggers
/// one external-wallet signing request. The connected passkey is NOT added
/// implicitly — include it explicitly when it should sign.
///
/// Each delegated wallet signer produces its own signed auth entry (root
/// invocation `__check_auth(authDigest)`) plus an empty-bytes placeholder in
/// the smart account's signature map. Direct wallet entries are signed via the
/// external wallet adapter and written into the classical
/// `Vec([Map({public_key, signature})])` shape; the smart account signature
/// map is not modified for those entries.
///
/// Example:
/// ```swift
/// let result = try await kit.multiSignerManager.multiSignerTransfer(
///     tokenContract: xlmSac,
///     recipient: recipientAddress,
///     amount: "10",
///     selectedSigners: [.passkey(credentialId: id, credentialIdBytes: idBytes, keyData: key)]
/// )
/// ```
// non-final to allow internal test subclassing in the unit-test target.
public class OZMultiSignerManager: OZManagerHelpers, @unchecked Sendable {

    // MARK: - Stored properties

    private let addressLogPrefixCount = 8

    let kit: OZSmartAccountKitProtocol

    // MARK: - Initialization

    /// Internal initializer; instances are constructed by `OZSmartAccountKit`.
    internal init(kit: OZSmartAccountKitProtocol) {
        self.kit = kit
    }

    // MARK: - Multi-Signer Transfer

    /// Executes a token transfer signed by an explicit list of signers.
    ///
    /// The caller supplies every signer that must sign via `selectedSigners`.
    /// There is no implicit connected passkey — include
    /// ``OZSelectedSigner/passkey(credentialId:credentialIdBytes:keyData:transports:)`` when
    /// the connected passkey should sign. Signatures are collected in list
    /// order; passkey entries trigger one OS WebAuthn prompt each, wallet
    /// entries trigger one external-wallet request each.
    ///
    /// Validation order:
    /// Steps 1-4 run inline here; steps 5-6 are enforced downstream by
    /// ``multiSignerContractCall(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``
    /// (via `validateContractCallArgs`), not in this method.
    /// 1. ``OZSmartAccountKitProtocol/requireConnected()`` — throws
    ///    ``SmartAccountWalletException/NotConnected`` when no wallet is connected.
    /// 2. `requireStellarAddress(_:fieldName:)` over `recipient`.
    /// 3. Self-transfer guard (recipient must differ from the connected
    ///    contract id).
    /// 4. Amount parsing via ``OZTransactionOperations/amountToBaseUnits(_:)``.
    /// 5. `selectedSigners.isEmpty` — throws ``SmartAccountValidationException/InvalidInput``.
    /// 6. `tokenContract` validation.
    ///
    /// - Parameters:
    ///   - tokenContract: SEP-41 token contract address (`C…` strkey).
    ///   - recipient: Recipient address (`G…` account or `C…` contract). Must
    ///     differ from the connected smart-account contract id.
    ///   - amount: Decimal XLM-style amount string (for example `"10"` or
    ///     `"100.5"`). Parsed via ``OZTransactionOperations/amountToBaseUnits(_:)``.
    ///   - selectedSigners: All signers that must sign, in collection order.
    ///     Must be non-empty.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional callback to resolve context rule
    ///     identifiers per auth entry. When `nil` (default), the SDK resolves
    ///     rule identifiers automatically from the supplied signer set and the
    ///     active context rules.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException/NotConnected`` for unconnected kits;
    ///           ``SmartAccountValidationException`` for invalid inputs;
    ///           ``SmartAccountTransactionException`` for simulation, signing, or
    ///           submission failures;
    ///           ``WebAuthnException`` for biometric-authentication failures.
    public func multiSignerTransfer(
        tokenContract: String,
        recipient: String,
        amount: String,
        selectedSigners: [OZSelectedSigner],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()

        try requireStellarAddress(recipient, fieldName: "recipient")

        // why: self-transfer guard fires AFTER requireConnected and after
        // recipient address validation — order matters so the caller receives
        // the most specific error first (NotConnected, then InvalidAddress,
        // then InvalidInput).
        if recipient == connected.contractId {
            throw SmartAccountValidationException.invalidInput(
                field: "recipient",
                reason: "Cannot transfer to self"
            )
        }

        let baseUnits = try OZTransactionOperations.amountToBaseUnits(amount)

        let fromAddress = try SCAddressXDR(contractId: connected.contractId)
        let toAddress: SCAddressXDR
        if recipient.hasPrefix("C") {
            toAddress = try SCAddressXDR(contractId: recipient)
        } else {
            toAddress = try SCAddressXDR(accountId: recipient)
        }

        let targetArgs: [SCValXDR] = [
            .address(fromAddress),
            .address(toAddress),
            try OZTransactionOperations.baseUnitsToI128ScVal(baseUnits, amount: amount)
        ]

        return try await multiSignerContractCall(
            target: tokenContract,
            targetFn: "transfer",
            targetArgs: targetArgs,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod,
            resolveContextRuleIds: resolveContextRuleIds
        )
    }

    // MARK: - Multi-Signer Direct Contract Call

    /// Calls an arbitrary function on an external contract with multi-signer
    /// authorization, bypassing the smart account's `execute` indirection.
    ///
    /// Builds a host function that invokes `target.targetFn(targetArgs)`
    /// directly. Context rules of type `CallContract(target)` match the
    /// authorization, allowing contract-specific multi-signer rules to apply.
    ///
    /// This is the multi-signer counterpart to
    /// ``OZTransactionOperations/contractCall(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)``.
    ///
    /// - Parameters:
    ///   - target: Target contract address (`C…` strkey).
    ///   - targetFn: Function name to invoke. Must not be blank.
    ///   - targetArgs: Pre-encoded `SCValXDR` arguments forwarded to the
    ///     function. Defaults to an empty list.
    ///   - selectedSigners: All signers that must sign, in collection order.
    ///     Must be non-empty.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional context-rule resolver override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException``, ``SmartAccountValidationException``,
    ///           ``SmartAccountTransactionException``, ``WebAuthnException``,
    ///           ``SmartAccountConfigurationException``.
    public func multiSignerContractCall(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        selectedSigners: [OZSelectedSigner],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        _ = try kit.requireConnected()
        try validateContractCallArgs(
            target: target,
            targetFn: targetFn,
            selectedSigners: selectedSigners
        )

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: target),
            functionName: targetFn,
            args: targetArgs
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await submitWithMultipleSigners(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod,
            resolveContextRuleIds: resolveContextRuleIds
        )
    }

    // MARK: - Multi-Signer Execute (Smart-Account Mediated Call)

    /// Executes an arbitrary contract function through the smart account's
    /// `execute` entry point with multi-signer authorization.
    ///
    /// Routes the call through the smart account contract's
    /// `execute(target, target_fn, target_args)` entry point and collects
    /// signatures from every entry in `selectedSigners` before submission.
    ///
    /// Use this method when a contract call must be authorized by more than
    /// one signer — for example, a governance vote, a multi-sig swap, or any
    /// operation gated by a multi-signer context rule.
    ///
    /// - Parameters:
    ///   - target: Target contract address (`C…` strkey).
    ///   - targetFn: Function name to invoke. Must not be blank.
    ///   - targetArgs: Pre-encoded `SCValXDR` arguments. Defaults to an empty
    ///     list.
    ///   - selectedSigners: All signers that must sign, in collection order.
    ///     Must be non-empty.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional context-rule resolver override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException``, ``SmartAccountValidationException``,
    ///           ``SmartAccountTransactionException``, ``WebAuthnException``,
    ///           ``SmartAccountConfigurationException``.
    public func multiSignerExecuteAndSubmit(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        selectedSigners: [OZSelectedSigner],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()
        try validateContractCallArgs(
            target: target,
            targetFn: targetFn,
            selectedSigners: selectedSigners
        )

        let targetSCAddress = try SCAddressXDR(contractId: target)
        let functionArgs: [SCValXDR] = [
            .address(targetSCAddress),
            .symbol(targetFn),
            .vec(targetArgs)
        ]

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: connected.contractId),
            functionName: "execute",
            args: functionArgs
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await submitWithMultipleSigners(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod,
            resolveContextRuleIds: resolveContextRuleIds
        )
    }

    // MARK: - Sibling-Manager Submission Entry Point

    /// Three-argument overload consumed by sibling managers
    /// (signer / policy / context-rule) when one of their state-changing
    /// methods is invoked with a non-empty `selectedSigners` list.
    ///
    /// Routes through the four-argument
    /// ``submitWithMultipleSigners(hostFunction:selectedSigners:forceMethod:resolveContextRuleIds:)``
    /// with `resolveContextRuleIds = nil` so sibling managers do not need to
    /// know about the context-rule resolver override.
    ///
    /// Declared in the main class body (not an extension) so test doubles can
    /// override this overload.
    ///
    /// - Parameters:
    ///   - hostFunction: Host function being authorized.
    ///   - selectedSigners: Signers participating in the ceremony. Must be
    ///     non-empty.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: The on-chain submission outcome.
    /// - Throws: ``SmartAccountWalletException``, ``SmartAccountValidationException``,
    ///           ``SmartAccountTransactionException``, ``WebAuthnException``,
    ///           ``SmartAccountConfigurationException``.
    internal func submitWithMultipleSigners(
        hostFunction: HostFunctionXDR,
        selectedSigners: [OZSelectedSigner],
        forceMethod: OZSubmissionMethod?
    ) async throws -> OZTransactionResult {
        return try await submitWithMultipleSigners(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod,
            resolveContextRuleIds: nil
        )
    }

    // MARK: - Shared Multi-Signer Submission Pipeline

    /// Shared multi-signer signing pipeline.
    ///
    /// Validates the wallet-signer set, simulates the supplied host function
    /// to discover the authorization entries, signs every matching entry with
    /// every supplied signer, re-simulates the resulting transaction so the
    /// resource fees reflect the real signature payload size, and submits the
    /// final envelope through ``OZTransactionOperations/submitMultiSignerTransaction(hostFunction:signedAuthEntries:signedTransaction:simulation:forceMethod:)``.
    ///
    /// Caller-facing entry points (``multiSignerTransfer(tokenContract:recipient:amount:selectedSigners:forceMethod:resolveContextRuleIds:)``,
    /// ``multiSignerContractCall(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``,
    /// ``multiSignerExecuteAndSubmit(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``)
    /// build the host function and delegate to this method. Sibling managers
    /// (signer / policy / context-rule) call this method directly on
    /// ``OZSmartAccountKitProtocol/multiSignerManager`` when a non-empty
    /// `selectedSigners` list is supplied to one of their state-changing
    /// methods.
    ///
    /// Validation order (each step is exercised by a dedicated unit test):
    /// 1. ``OZSmartAccountKitProtocol/requireConnected()``.
    /// 2. Per-wallet-signer reachability check via
    ///    ``OZExternalSignerManager/canSignFor(address:)``.
    /// 3. Per-passkey-signer `keyData` precondition — every passkey entry must
    ///    carry pre-fetched `keyData` so context-rule resolution and signature
    ///    binding can run without an extra on-chain lookup.
    /// 4. Initial simulation surface error.
    /// 5. Re-simulation surface error after attaching collected signatures.
    ///
    /// - Parameters:
    ///   - hostFunction: Host function to authorize and submit.
    ///   - selectedSigners: All signers that must sign, in collection order.
    ///     Must be non-empty; an empty list is a routing bug at the call site.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional context-rule resolver override.
    /// - Returns: An ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException``, ``SmartAccountValidationException``,
    ///           ``SmartAccountTransactionException``, ``WebAuthnException``,
    ///           ``SmartAccountConfigurationException``.
    public func submitWithMultipleSigners(
        hostFunction: HostFunctionXDR,
        selectedSigners: [OZSelectedSigner],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()

        // Step 0: validate signer-set preconditions (per-wallet reachability,
        // passkey keyData, Ed25519 registration).
        let walletSigners = try await validateSignerSet(
            selectedSigners: selectedSigners
        )

        // Step 1: initial simulation against the deployer account.
        let deployer = try await kit.getDeployer()
        let simulationResult = try await runInitialSimulation(
            hostFunction: hostFunction,
            deployerAccountId: deployer.accountId
        )

        // Step 2: compute the expiration ledger from the latest network
        // ledger and the configured signature-expiration window.
        let expirationLedger = try await computeExpirationLedger()

        // Step 3a: pre-fetch the active context rules ONCE so the auth-entry
        // loop does not perform N additional RPC calls.
        let contextRules = try await kit.contextRuleManager.listContextRules(maxScanId: nil)

        // Step 3b: build per-signer OZSmartAccountSigner instances. Hoisted
        // outside the auth-entry loop because the set is invariant across
        // entries.
        let smartAccountSigners = try buildSmartAccountSigners(
            selectedSigners: selectedSigners
        )

        // Step 4: sign every auth entry against the matching signers.
        var signedAuthEntries: [SorobanAuthorizationEntryXDR] = []
        signedAuthEntries.reserveCapacity(simulationResult.authEntries.count)

        for (entryIndex, entry) in simulationResult.authEntries.enumerated() {
            try Task.checkCancellation()
            guard case .address(let addressCreds) = entry.credentials else {
                signedAuthEntries.append(entry)
                continue
            }

            let entryAddressString = OZAddressStrKey.fromXdr(addressCreds.address)
            if entryAddressString != connected.contractId {
                // The auth entry references some address other than the
                // connected smart-account contract. Either it matches one
                // of the wallet signers (sign via the wallet adapter
                // directly), or it is unsupported.
                if let entryAddressString = entryAddressString,
                   walletSigners.contains(entryAddressString) {
                    let signedWalletEntry = try await signWalletAddressAuthEntry(
                        entry: entry,
                        walletAddress: entryAddressString,
                        expirationLedger: expirationLedger
                    )
                    signedAuthEntries.append(signedWalletEntry)
                } else {
                    let displayAddress = entryAddressString ?? "<unparseable address>"
                    throw SmartAccountTransactionException.signingFailed(
                        reason: "Unsupported auth entry for \(displayAddress). " +
                            "Add an external signer for that address or remove it from the transaction."
                    )
                }
                continue
            }

            // Step 4a: clone the entry and stamp the signature expiration
            // ledger before resolving rules and signing.
            var workingEntry = try cloneAndStampExpirationLedger(
                entry: entry,
                expirationLedger: expirationLedger
            )

            // Step 4b: resolve the context rule identifiers either through
            // the caller-provided callback or through the kit's
            // context-rule manager using the hoisted rule list.
            let resolvedContextRuleIds: [UInt32]
            if let resolveContextRuleIds = resolveContextRuleIds {
                resolvedContextRuleIds = try await resolveContextRuleIds(workingEntry, entryIndex)
            } else {
                resolvedContextRuleIds = try await kit.contextRuleManager.resolveContextRuleIdsForEntry(
                    entry: workingEntry,
                    signers: smartAccountSigners,
                    contextRules: contextRules
                )
            }

            // Step 4c: compute the payload hash and the bound auth digest
            // ONCE per entry. Both the passkey and the delegated paths sign
            // the same digest so the on-chain verifier can bind the rule
            // identifiers without ambiguity.
            let payloadHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
                entry: workingEntry,
                expirationLedger: expirationLedger,
                networkPassphrase: kit.config.networkPassphrase
            )
            let authDigest = try await OZSmartAccountAuth.buildAuthDigest(
                signaturePayload: payloadHash,
                contextRuleIds: resolvedContextRuleIds
            )

            // Sign with every passkey signer in declaration order.
            workingEntry = try await signEntryWithPasskeys(
                workingEntry: workingEntry,
                authDigest: authDigest,
                expirationLedger: expirationLedger,
                resolvedContextRuleIds: resolvedContextRuleIds,
                selectedSigners: selectedSigners
            )

            // Sign with every Ed25519 signer in declaration order.
            workingEntry = try await signEntryWithEd25519Signers(
                workingEntry: workingEntry,
                authDigest: authDigest,
                expirationLedger: expirationLedger,
                resolvedContextRuleIds: resolvedContextRuleIds,
                selectedSigners: selectedSigners
            )

            // Step 4e: append delegated-signer auth entries and the
            // matching signature-map placeholders.
            workingEntry = try await appendDelegatedAuthEntries(
                workingEntry: workingEntry,
                authDigest: authDigest,
                expirationLedger: expirationLedger,
                resolvedContextRuleIds: resolvedContextRuleIds,
                selectedSigners: selectedSigners,
                connectedContractId: connected.contractId,
                signedAuthEntries: &signedAuthEntries
            )

            signedAuthEntries.append(workingEntry)
        }

        // Step 4f: best-effort lastUsedAt update for every passkey credential
        // that participated. The credential manager's storage write is a
        // tracking concern and must never block submission — wrap each call
        // in a do/catch so a storage failure does not derail the result.
        for signer in selectedSigners {
            if case .passkey(let credentialId, _, _, _) = signer {
                do {
                    try await kit.credentialManager.updateLastUsed(credentialId: credentialId)
                } catch {
                    // best-effort; the credential update is non-critical
                }
            }
        }

        // Step 5 + 6: re-simulate with the signed auth entries and submit.
        return try await resimulateAndSubmit(
            hostFunction: hostFunction,
            signedAuthEntries: signedAuthEntries,
            deployer: deployer,
            forceMethod: forceMethod
        )
    }

    // MARK: - Pipeline step helpers

    /// Validates the selected-signer set:
    /// - Every wallet signer must be reachable through the kit's external-signer manager.
    /// - Every passkey signer must carry pre-fetched `keyData` so the
    ///   rule-resolution loop avoids an extra on-chain lookup.
    /// - Every Ed25519 signer must have a valid verifier address, correct public-key length,
    ///   and a registered signing source.
    ///
    /// - Parameter selectedSigners: The signer set supplied by the caller.
    /// - Returns: The extracted wallet signer addresses.
    /// - Throws: ``SmartAccountValidationException`` when any of the preconditions fail.
    private func validateSignerSet(
        selectedSigners: [OZSelectedSigner]
    ) async throws -> [String] {
        var walletSigners: [String] = []
        for signer in selectedSigners {
            if case .wallet(let accountId) = signer {
                walletSigners.append(accountId)
            }
        }

        try await validateWalletSigners(walletSigners)

        try validatePasskeyKeyData(selectedSigners)

        try await validateEd25519Signers(selectedSigners, signerManager: kit.externalSigners)

        return walletSigners
    }

    /// Verifies that the kit's external-signer manager can sign for every wallet signer address.
    ///
    /// - Parameter walletSigners: G-address strings extracted from the `selectedSigners` list.
    /// - Throws: ``SmartAccountValidationException`` when a signer address has no signing source available.
    private func validateWalletSigners(
        _ walletSigners: [String]
    ) async throws {
        guard !walletSigners.isEmpty else { return }
        for walletAddress in walletSigners {
            let canSign = await kit.externalSigners.canSignFor(address: walletAddress)
            if !canSign {
                throw SmartAccountValidationException.invalidInput(
                    field: "selectedSigners",
                    reason: "No signing source available for wallet address: \(walletAddress). " +
                        "Register a keypair via kit.externalSigners.addFromSecret(secretKey:), " +
                        "or supply a wallet adapter via config.externalWallet at kit construction."
                )
            }
        }
    }

    /// Verifies that every passkey signer in `selectedSigners` carries non-nil `keyData`.
    ///
    /// - Parameter selectedSigners: The full signer list; non-passkey entries are skipped.
    /// - Throws: ``SmartAccountValidationException`` when any passkey entry has `keyData == nil`.
    private func validatePasskeyKeyData(_ selectedSigners: [OZSelectedSigner]) throws {
        for signer in selectedSigners {
            if case .passkey(_, _, let keyData, _) = signer {
                if keyData == nil {
                    throw SmartAccountValidationException.invalidInput(
                        field: "selectedSigners",
                        reason: "keyData is required for passkey signers for rule resolution"
                    )
                }
            }
        }
    }

    /// Verifies verifier address format, public-key length, and registration for every
    /// Ed25519 signer in `selectedSigners`.
    ///
    /// - Parameters:
    ///   - selectedSigners: The full signer list; non-Ed25519 entries are skipped.
    ///   - signerManager: The kit's external-signer manager.
    /// - Throws: ``SmartAccountValidationException`` when any Ed25519 precondition fails.
    private func validateEd25519Signers(
        _ selectedSigners: [OZSelectedSigner],
        signerManager: OZExternalSignerManager
    ) async throws {
        for signer in selectedSigners {
            guard case .ed25519(let verifierAddress, let publicKey) = signer else { continue }

            if !verifierAddress.isValidContractId() {
                throw SmartAccountValidationException.invalidInput(
                    field: "selectedSigners",
                    reason: "Ed25519 signer has an invalid verifier address (must be a C... contract strkey): \(verifierAddress)"
                )
            }

            if publicKey.count != SmartAccountConstants.ed25519PublicKeySize {
                throw SmartAccountValidationException.invalidInput(
                    field: "selectedSigners",
                    reason: "Ed25519 signer public key must be exactly \(SmartAccountConstants.ed25519PublicKeySize) bytes, " +
                        "got \(publicKey.count)"
                )
            }

            let canSign = await signerManager.canSignEd25519For(
                verifierAddress: verifierAddress,
                publicKey: publicKey
            )
            if !canSign {
                let prefix = String(verifierAddress.prefix(addressLogPrefixCount))
                throw SmartAccountValidationException.invalidInput(
                    field: "selectedSigners",
                    reason: "Ed25519 signer (verifier=\(prefix)...) has no registered signing source. " +
                        "Register a keypair via kit.externalSigners.addEd25519FromRawKey(...), " +
                        "or supply an Ed25519 adapter via config.externalEd25519Adapter at kit construction."
                )
            }
        }
    }

    /// Initial-simulation result carrying the auth entries the host function
    /// will need authorised.
    private struct InitialSimulationResult {
        let authEntries: [SorobanAuthorizationEntryXDR]
    }

    /// Builds the deployer-source transaction, simulates it, and returns the
    /// auth entries the host function asks for.
    ///
    /// Use of the deployer account matches the single-signer pipeline: the
    /// deployer pays the fee in the no-relayer case and the relayer rebuilds
    /// the envelope around the host function in the relayer case.
    private func runInitialSimulation(
        hostFunction: HostFunctionXDR,
        deployerAccountId: String
    ) async throws -> InitialSimulationResult {
        let deployerAccount = try await fetchAccount(accountId: deployerAccountId)

        let initialOperation = InvokeHostFunctionOperation(
            hostFunction: hostFunction,
            auth: []
        )
        let initialTransaction = try buildTransaction(
            sourceAccount: deployerAccount,
            operations: [initialOperation],
            timeoutSeconds: kit.config.timeoutInSeconds
        )

        let simulation = try await simulate(
            transaction: initialTransaction,
            failureMessagePrefix: "Simulation error: "
        )
        return InitialSimulationResult(authEntries: simulation.sorobanAuth ?? [])
    }

    /// Computes the signature expiration ledger using the latest ledger plus
    /// the configured expiration window. Clamps via `UInt32(exactly:)` so a
    /// near-`UInt32.max` ledger sequence cannot wrap silently.
    private func computeExpirationLedger() async throws -> UInt32 {
        let latestLedger = try await fetchLatestLedger()
        let expirationU64 = UInt64(latestLedger.sequence)
            + UInt64(kit.config.signatureExpirationLedgers)
        guard let expirationLedger = UInt32(exactly: expirationU64) else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "Computed expirationLedger \(expirationU64) overflows UInt32"
            )
        }
        return expirationLedger
    }

    /// Materialises one ``OZSmartAccountSigner`` instance per selected
    /// signer. Building these once outside the auth-entry loop avoids
    /// repeating the work N times for entries that all reference the same
    /// signer set.
    private func buildSmartAccountSigners(
        selectedSigners: [OZSelectedSigner]
    ) throws -> [any OZSmartAccountSigner] {
        var smartAccountSigners: [any OZSmartAccountSigner] = []
        smartAccountSigners.reserveCapacity(selectedSigners.count)
        for signer in selectedSigners {
            switch signer {
            case .passkey(_, _, let keyData, _):
                guard let keyData = keyData else {
                    // compiler-required unwrap; validateSignerSet rejects nil keyData upstream.
                    throw SmartAccountValidationException.invalidInput(
                        field: "selectedSigners",
                        reason: "keyData is required for passkey signers for rule resolution"
                    )
                }
                let externalSigner = try OZExternalSigner(
                    verifierAddress: kit.config.webauthnVerifierAddress,
                    keyData: keyData
                )
                smartAccountSigners.append(externalSigner)
            case .wallet(let accountId):
                let delegated = try OZDelegatedSigner(address: accountId)
                smartAccountSigners.append(delegated)
            case .ed25519(let verifierAddress, let publicKey):
                let externalSigner = try OZExternalSigner.ed25519(
                    verifierAddress: verifierAddress,
                    publicKey: publicKey
                )
                smartAccountSigners.append(externalSigner)
            }
        }
        return smartAccountSigners
    }

    /// Returns a clone of `entry` with `signatureExpirationLedger` rewritten
    /// to `expirationLedger` so the per-entry signing pass receives a fresh
    /// instance whose expiration matches the value bound into the digest.
    private func cloneAndStampExpirationLedger(
        entry: SorobanAuthorizationEntryXDR,
        expirationLedger: UInt32
    ) throws -> SorobanAuthorizationEntryXDR {
        var workingEntry = try OZTransactionOperations.cloneAuthEntry(entry)
        if case .address(let creds) = workingEntry.credentials {
            let updated = SorobanAddressCredentialsXDR(
                address: creds.address,
                nonce: creds.nonce,
                signatureExpirationLedger: expirationLedger,
                signature: creds.signature
            )
            workingEntry = SorobanAuthorizationEntryXDR(
                credentials: .address(updated),
                rootInvocation: workingEntry.rootInvocation
            )
        }
        return workingEntry
    }

    /// Collects one WebAuthn signature per passkey signer in declaration
    /// order and chains it onto the working entry's signature map. The
    /// chained map is naturally additive because
    /// ``OZSmartAccountAuth/signAuthEntry(entry:signer:signature:expirationLedger:contextRuleIds:)``
    /// merges new entries with the existing map.
    private func signEntryWithPasskeys(
        workingEntry: SorobanAuthorizationEntryXDR,
        authDigest: Data,
        expirationLedger: UInt32,
        resolvedContextRuleIds: [UInt32],
        selectedSigners: [OZSelectedSigner]
    ) async throws -> SorobanAuthorizationEntryXDR {
        var workingEntry = workingEntry
        for (signerIndex, signer) in selectedSigners.enumerated() {
            guard case .passkey(_, let credentialIdBytes, let keyData, let transports) = signer else {
                continue
            }
            try Task.checkCancellation()
            guard let webauthnProvider = kit.config.webauthnProvider else {
                throw SmartAccountValidationException.invalidInput(
                    field: "webauthnProvider",
                    reason: "WebAuthn provider is required for passkey signers but is not configured"
                )
            }
            guard let keyData = keyData else {
                // compiler-required unwrap; validateSignerSet rejects nil keyData upstream.
                throw SmartAccountValidationException.invalidInput(
                    field: "selectedSigners",
                    reason: "keyData is required for passkey signers for rule resolution"
                )
            }

            // why: when credentialIdBytes is available, attach an
            // WebAuthnAllowCredential carrying it and any transport hints so the
            // OS routing layer can pick the correct passkey when more
            // than one is registered for this RP. When credentialIdBytes
            // is nil we pass no allowCredentials list at all so the
            // authenticator falls back to its default credential
            // discovery flow.
            let allowCredentials: [WebAuthnAllowCredential]?
            if let credentialIdBytes = credentialIdBytes {
                allowCredentials = [
                    WebAuthnAllowCredential(
                        id: credentialIdBytes,
                        transports: transports
                    )
                ]
            } else {
                allowCredentials = nil
            }

            let authResult: WebAuthnAuthenticationResult
            do {
                authResult = try await webauthnProvider.authenticate(
                    challenge: authDigest,
                    allowCredentials: allowCredentials
                )
            } catch let error as WebAuthnException {
                // why: per-signer human numbering uses 1-based indices so a
                // non-developer caller can correlate the prompt order with
                // the failure message.
                throw WebAuthnException.authenticationFailed(
                    reason: "WebAuthn authentication failed for passkey signer " +
                        "\(signerIndex + 1)/\(selectedSigners.count): " +
                        (SmartAccountException.messageOf(error) ?? "unknown"),
                    cause: error
                )
            } catch {
                throw WebAuthnException.authenticationFailed(
                    reason: "WebAuthn authentication failed for passkey signer " +
                        "\(signerIndex + 1)/\(selectedSigners.count): " +
                        (SmartAccountException.messageOf(error) ?? "unknown"),
                    cause: error
                )
            }

            let compactSig = try SmartAccountUtils.normalizeSignature(authResult.signature)
            let webAuthnSig = try OZWebAuthnSignature(
                authenticatorData: authResult.authenticatorData,
                clientData: authResult.clientDataJSON,
                signature: compactSig
            )

            let passkeySigner = try OZExternalSigner(
                verifierAddress: kit.config.webauthnVerifierAddress,
                keyData: keyData
            )

            workingEntry = try await OZSmartAccountAuth.signAuthEntry(
                entry: workingEntry,
                signer: passkeySigner,
                signature: webAuthnSig,
                expirationLedger: expirationLedger,
                contextRuleIds: resolvedContextRuleIds
            )
        }
        return workingEntry
    }

    /// Collects one Ed25519 signature per `.ed25519` signer in declaration order and chains
    /// it onto the working entry's signature map.
    ///
    /// The signing source is resolved via the adapter-first precedence rule documented on
    /// ``OZExternalSignerManager/signEd25519AuthDigest(verifierAddress:publicKey:authDigest:)``.
    /// After the adapter or in-memory keypair returns the 64-byte signature, the pipeline
    /// locally verifies it using the SDK's existing ``KeyPair/verify(signature:message:)``
    /// primitive before accepting it. This prevents an adapter that silently returns a
    /// valid-looking but wrong signature from causing an opaque on-chain failure after
    /// submission.
    ///
    /// - Parameters:
    ///   - workingEntry: The auth entry to accumulate signatures onto.
    ///   - authDigest: 32-byte digest shared across all signers for this entry.
    ///   - expirationLedger: Ledger at which all signatures on this entry expire.
    ///   - resolvedContextRuleIds: Context rule IDs bound into the auth-payload map.
    ///   - selectedSigners: Full signer list; non-Ed25519 entries are skipped.
    /// - Returns: The updated working entry after all Ed25519 signatures have been attached.
    /// - Throws: ``SmartAccountValidationException`` when the external signer manager is not configured;
    ///   ``SmartAccountTransactionException/SigningFailed`` when signing or local verification fails.
    private func signEntryWithEd25519Signers(
        workingEntry: SorobanAuthorizationEntryXDR,
        authDigest: Data,
        expirationLedger: UInt32,
        resolvedContextRuleIds: [UInt32],
        selectedSigners: [OZSelectedSigner]
    ) async throws -> SorobanAuthorizationEntryXDR {
        var workingEntry = workingEntry
        let signerManager = kit.externalSigners

        for signer in selectedSigners {
            guard case .ed25519(let verifierAddress, let publicKey) = signer else { continue }
            try Task.checkCancellation()

            // Request the 64-byte signature from the kit's external-signer manager.
            // The manager implements adapter-first precedence internally and exits
            // actor isolation for any adapter await it performs.
            let rawSignature = try await signerManager.signEd25519AuthDigest(
                verifierAddress: verifierAddress,
                publicKey: publicKey,
                authDigest: authDigest
            )

            // Local signature verification: derive the public key from the raw bytes and
            // verify using the SDK's KeyPair.verify primitive before trusting the signature
            // downstream.
            try locallyVerifyEd25519(
                rawSignature: rawSignature,
                publicKey: publicKey,
                authDigest: authDigest,
                verifierAddress: verifierAddress
            )

            // Wrap the verified 64-byte signature and attach it to the working entry.
            // OZEd25519Signature.toScVal() produces Bytes(<64-byte raw signature>);
            // the public key is not transmitted — the verifier reads it from on-chain storage.
            let ed25519Sig = try OZEd25519Signature(publicKey: publicKey, signature: rawSignature)

            let ed25519Signer = try OZExternalSigner.ed25519(
                verifierAddress: verifierAddress,
                publicKey: publicKey
            )

            workingEntry = try await OZSmartAccountAuth.signAuthEntry(
                entry: workingEntry,
                signer: ed25519Signer,
                signature: ed25519Sig,
                expirationLedger: expirationLedger,
                contextRuleIds: resolvedContextRuleIds
            )
        }

        return workingEntry
    }

    /// Verifies that a raw 64-byte Ed25519 signature covers `authDigest` under the
    /// given `publicKey`.
    ///
    /// - Parameters:
    ///   - rawSignature: 64-byte signature returned by the signing source.
    ///   - publicKey: 32-byte Ed25519 public key used to verify the signature.
    ///   - authDigest: 32-byte message that was signed.
    ///   - verifierAddress: On-chain verifier contract address; used only in error messages.
    /// - Throws: ``SmartAccountTransactionException/signingFailed`` when the length check, key
    ///   construction, or signature verification fails.
    private func locallyVerifyEd25519(
        rawSignature: Data,
        publicKey: Data,
        authDigest: Data,
        verifierAddress: String
    ) throws {
        guard rawSignature.count == SmartAccountConstants.ed25519SignatureSize else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Ed25519 signing source returned \(rawSignature.count) bytes for verifier " +
                    "\(verifierAddress); expected \(SmartAccountConstants.ed25519SignatureSize)"
            )
        }

        let pubKeyObj: PublicKey
        do {
            pubKeyObj = try PublicKey([UInt8](publicKey))
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to construct Ed25519 public key for local verification: " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }
        let signerKeyPair = KeyPair(publicKey: pubKeyObj)

        let signatureValid: Bool
        do {
            signatureValid = try signerKeyPair.verify(
                signature: [UInt8](rawSignature),
                message: [UInt8](authDigest)
            )
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Ed25519 signature local verification failed for verifier \(verifierAddress): " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }
        if !signatureValid {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Ed25519 signing source returned a signature that does not verify " +
                    "against the registered public key for verifier \(verifierAddress)"
            )
        }
    }

    /// Produces one delegated-signer auth entry per wallet signer and
    /// appends it to `signedAuthEntries`. Each delegated entry is signed via
    /// the kit's external-signer manager and contributes a signature-map entry
    /// keyed by the delegated signer with an empty-bytes signature value, so
    /// the rule engine counts the delegated signer when evaluating the active
    /// context rule.
    ///
    /// - Returns: The updated `workingEntry` after every delegated-signer
    ///   placeholder has been merged into its signature map.
    private func appendDelegatedAuthEntries(
        workingEntry: SorobanAuthorizationEntryXDR,
        authDigest: Data,
        expirationLedger: UInt32,
        resolvedContextRuleIds: [UInt32],
        selectedSigners: [OZSelectedSigner],
        connectedContractId: String,
        signedAuthEntries: inout [SorobanAuthorizationEntryXDR]
    ) async throws -> SorobanAuthorizationEntryXDR {
        var workingEntry = workingEntry
        for signer in selectedSigners {
            guard case .wallet(let walletAddress) = signer else { continue }

            let checkAuthInvocation = SorobanAuthorizedInvocationXDR(
                function: .contractFn(
                    InvokeContractArgsXDR(
                        contractAddress: try SCAddressXDR(contractId: connectedContractId),
                        functionName: "__check_auth",
                        args: [.bytes(authDigest)]
                    )
                ),
                subInvocations: []
            )

            let signedDelegatedEntry = try await Self.authorizeInvocation(
                walletAddress: walletAddress,
                validUntilLedger: expirationLedger,
                invocation: checkAuthInvocation,
                networkPassphrase: kit.config.networkPassphrase,
                externalSigners: kit.externalSigners
            )
            signedAuthEntries.append(signedDelegatedEntry)

            let delegatedSigner = try OZDelegatedSigner(address: walletAddress)
            workingEntry = try OZSmartAccountAuth.addRawSignatureMapEntry(
                entry: workingEntry,
                signerKey: try delegatedSigner.toScVal(),
                signatureValue: .bytes(Data()),
                contextRuleIds: resolvedContextRuleIds
            )
        }
        return workingEntry
    }

    /// Re-simulates the supplied signed transaction (so resource fees reflect
    /// the real signature payload size) and then delegates the final
    /// submission to the kit's transaction-operations pipeline.
    private func resimulateAndSubmit(
        hostFunction: HostFunctionXDR,
        signedAuthEntries: [SorobanAuthorizationEntryXDR],
        deployer: KeyPair,
        forceMethod: OZSubmissionMethod?
    ) async throws -> OZTransactionResult {
        try Task.checkCancellation()
        let refreshedDeployerAccount = try await fetchAccount(accountId: deployer.accountId)
        let signedOperation = InvokeHostFunctionOperation(
            hostFunction: hostFunction,
            auth: signedAuthEntries
        )
        let signedTransaction = try buildTransaction(
            sourceAccount: refreshedDeployerAccount,
            operations: [signedOperation],
            timeoutSeconds: kit.config.timeoutInSeconds
        )
        let resignedSimulation = try await simulate(
            transaction: signedTransaction,
            failureMessagePrefix: "Re-simulation error: "
        )

        try Task.checkCancellation()
        return try await kit.transactionOperations.submitMultiSignerTransaction(
            hostFunction: hostFunction,
            signedAuthEntries: signedAuthEntries,
            signedTransaction: signedTransaction,
            simulation: resignedSimulation,
            forceMethod: forceMethod
        )
    }

    // MARK: - Private helpers

    /// Validates the shared parameters required by every contract-call entry
    /// point.
    ///
    /// - Parameters:
    ///   - target: Target contract address.
    ///   - targetFn: Function name. Must be non-blank.
    ///   - selectedSigners: Signer set. Must be non-empty.
    /// - Throws: ``SmartAccountValidationException/InvalidAddress`` for malformed
    ///   `target`; ``SmartAccountValidationException/InvalidInput`` for blank `targetFn`
    ///   or empty `selectedSigners`.
    private func validateContractCallArgs(
        target: String,
        targetFn: String,
        selectedSigners: [OZSelectedSigner]
    ) throws {
        try requireContractAddress(target, fieldName: "target")

        try requireNonBlankFunctionName(targetFn)

        if selectedSigners.isEmpty {
            throw SmartAccountValidationException.invalidInput(
                field: "selectedSigners",
                reason: "At least one signer must be provided"
            )
        }
    }

    /// Signs an auth entry whose `Address` credentials match a wallet signer
    /// directly, routing through the kit's external-signer manager.
    ///
    /// The signature is formatted as the classical Stellar
    /// `Vec([Map({"public_key": Bytes, "signature": Bytes})])` shape. The
    /// preimage construction reuses the EXISTING entry nonce and the supplied
    /// expiration ledger.
    ///
    /// - Parameters:
    ///   - entry: The unsigned auth entry whose `Address` credentials reference
    ///     `walletAddress`.
    ///   - walletAddress: The Stellar `G…` address of the wallet signer.
    ///   - expirationLedger: Ledger sequence at which the signature expires.
    /// - Returns: The signed auth entry.
    /// - Throws: ``SmartAccountTransactionException/SigningFailed``.
    private func signWalletAddressAuthEntry(
        entry: SorobanAuthorizationEntryXDR,
        walletAddress: String,
        expirationLedger: UInt32
    ) async throws -> SorobanAuthorizationEntryXDR {
        // Clone the entry via XDR round-trip so the caller's instance is
        // never mutated, and stamp the new expiration ledger on the cloned
        // address credentials.
        let cloned = try OZTransactionOperations.cloneAuthEntry(entry)
        guard case .address(let credentials) = cloned.credentials else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Expected Address credentials on wallet auth entry for \(walletAddress)"
            )
        }

        let preimage = HashIDPreimageSorobanAuthorizationXDR(
            networkID: HashXDR(kit.config.networkPassphrase.sha256Hash),
            nonce: credentials.nonce,
            signatureExpirationLedger: expirationLedger,
            invocation: cloned.rootInvocation
        )
        let preimageXdr = HashIDPreimageXDR.sorobanAuthorization(preimage)
        let preimageBytes: [UInt8]
        do {
            preimageBytes = try XDREncoder.encode(preimageXdr)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR-encode wallet auth preimage: " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }
        let preimageBase64 = Data(preimageBytes).base64EncodedString()

        let signResult = try await kit.externalSigners.signAuthEntry(
            address: walletAddress,
            authEntry: preimageBase64
        )

        guard let signatureBytes = Data(base64Encoded: signResult.signedAuthEntry) else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "External signer returned non-base64 signature for \(walletAddress)"
            )
        }

        let resolvedSignerAddress = signResult.signerAddress ?? walletAddress
        let signerKeyPair: KeyPair
        do {
            signerKeyPair = try KeyPair(accountId: resolvedSignerAddress)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to derive public key from wallet signer address \(resolvedSignerAddress): " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }

        let publicKeyBytes = Data(signerKeyPair.publicKey.bytes)
        let signatureScVal = OZTransactionOperations.classicalEd25519SignatureScVal(
            publicKey: publicKeyBytes,
            signature: signatureBytes
        )

        return SorobanAuthorizationEntryXDR(
            credentials: .address(SorobanAddressCredentialsXDR(
                address: credentials.address,
                nonce: credentials.nonce,
                signatureExpirationLedger: expirationLedger,
                signature: signatureScVal
            )),
            rootInvocation: cloned.rootInvocation
        )
    }

    // MARK: - Hand-rolled Auth.authorizeInvocation equivalent

    /// Builds and signs a delegated wallet auth entry for `walletAddress` via the
    /// kit's external-signer manager. Produces the `Vec([Map({public_key, signature})])`
    /// credential shape.
    /// - Throws: ``SmartAccountTransactionException/SigningFailed``.
    private static func authorizeInvocation(
        walletAddress: String,
        validUntilLedger: UInt32,
        invocation: SorobanAuthorizedInvocationXDR,
        networkPassphrase: String,
        externalSigners: OZExternalSignerManager
    ) async throws -> SorobanAuthorizationEntryXDR {
        // Generate a cryptographically random nonce. The Soroban host
        // requires unique nonces per credentials value within an envelope.
        let nonce = try OZTransactionOperations.generateNonce()

        let networkIdBytes = networkPassphrase.sha256Hash
        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(
            networkID: HashXDR(networkIdBytes),
            nonce: nonce,
            signatureExpirationLedger: validUntilLedger,
            invocation: invocation
        )
        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)

        let preimageBytes: [UInt8]
        do {
            preimageBytes = try XDREncoder.encode(preimage)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR-encode delegated wallet auth preimage: " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }
        let preimageBase64 = Data(preimageBytes).base64EncodedString()

        let signResult = try await externalSigners.signAuthEntry(
            address: walletAddress,
            authEntry: preimageBase64
        )

        guard let signatureBytes = Data(base64Encoded: signResult.signedAuthEntry) else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "External signer returned non-base64 signature for \(walletAddress)"
            )
        }

        let resolvedSignerAddress = signResult.signerAddress ?? walletAddress
        let signerKeyPair: KeyPair
        do {
            signerKeyPair = try KeyPair(accountId: resolvedSignerAddress)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to derive public key from wallet signer address \(resolvedSignerAddress): " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }

        let publicKeyBytes = Data(signerKeyPair.publicKey.bytes)
        let signatureScVal = OZTransactionOperations.classicalEd25519SignatureScVal(
            publicKey: publicKeyBytes,
            signature: signatureBytes
        )

        return SorobanAuthorizationEntryXDR(
            credentials: .address(SorobanAddressCredentialsXDR(
                address: try SCAddressXDR(accountId: walletAddress),
                nonce: nonce,
                signatureExpirationLedger: validUntilLedger,
                signature: signatureScVal
            )),
            rootInvocation: invocation
        )
    }
}

