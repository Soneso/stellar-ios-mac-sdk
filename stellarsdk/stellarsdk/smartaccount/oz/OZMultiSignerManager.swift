//
//  OZMultiSignerManager.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security

// ============================================================================
// MARK: - OZMultiSignerManager
// ============================================================================

/// Manager for multi-signature smart-account operations.
///
/// `OZMultiSignerManager` collects signatures from a caller-supplied list of
/// signers (passkeys and / or external wallet addresses) and submits the
/// resulting transaction through the kit's transaction operations. The manager
/// supports three caller-facing entry points and one shared low-level
/// submission pipeline:
///
/// - ``multiSignerTransfer(tokenContract:recipient:amount:selectedSigners:forceMethod:resolveContextRuleIds:)``
///   — multi-signer SEP-41 token transfer.
/// - ``multiSignerContractCall(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``
///   — direct multi-signer contract call (the smart account is the caller via
///   `require_auth`).
/// - ``multiSignerExecuteAndSubmit(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``
///   — smart-account-mediated multi-signer call routed through the smart
///   account contract's `execute` entry point.
/// - ``submitWithMultipleSigners(hostFunction:selectedSigners:forceMethod:resolveContextRuleIds:)``
///   — low-level shared pipeline consumed by the three high-level entry points
///   above and by sibling managers (signer / policy / context-rule) when they
///   route a non-empty `selectedSigners` list through the multi-signer path.
///
/// ## Signer Ordering
///
/// Signatures are collected sequentially in the order the caller supplies them
/// via `selectedSigners`. Each ``SelectedSigner/passkey(credentialId:credentialIdBytes:keyData:transports:)``
/// triggers exactly one OS WebAuthn authentication prompt. Each
/// ``SelectedSigner/wallet(accountId:)`` triggers exactly one external-wallet
/// signing request. Sequential collection enables fail-fast behaviour on user
/// cancellation.
///
/// The connected passkey is NOT added implicitly. Include it explicitly via
/// ``SelectedSigner/passkey(credentialId:credentialIdBytes:keyData:transports:)`` when the
/// connected passkey should sign.
///
/// ## Delegated-Signer Auth Entries
///
/// Each delegated wallet signer in `selectedSigners` produces:
/// - Its own signed authorization entry whose `Address` credentials reference
///   the wallet's G-address and whose root invocation calls
///   `<smart_account>.__check_auth(authDigest)` — built and signed by the
///   hand-rolled `Auth.authorizeInvocation` equivalent inside this file.
/// - An empty-bytes placeholder in the smart account's signature map so the
///   smart-account contract counts the delegated signer when evaluating the
///   active context rule.
///
/// Auth entries whose `Address` matches a `SelectedSigner.wallet(accountId:)`
/// are signed directly via the external wallet adapter (without the
/// `__check_auth` indirection) and the resulting signature is written into the
/// classical `Vec([Map({public_key, signature})])` shape. The smart account's
/// signature map remains untouched on these entries.
///
/// ## Thread Safety
///
/// All methods are `async`. The manager holds only immutable references
/// captured at construction time, so concurrent invocation is safe at this
/// layer — concurrent invocation of WebAuthn or external-wallet signing is
/// constrained by the underlying OS-level prompt serialization.
// non-final to allow internal test subclassing in the unit-test target.
public class OZMultiSignerManager: @unchecked Sendable {

    // MARK: - Stored properties

    /// Kit reference used to resolve the connected smart-account contract id,
    /// the configured external-wallet adapter, the WebAuthn provider, the
    /// network passphrase, and to delegate the final transaction submission to
    /// the kit's transaction operations.
    private let kit: OZSmartAccountKitProtocol

    // MARK: - Initialization

    /// Initializes a new `OZMultiSignerManager` bound to the supplied kit.
    ///
    /// Internal: instances are created by the smart-account kit and exposed as
    /// `kit.multiSignerManager`. Consumer applications never call this
    /// initializer directly.
    ///
    /// - Parameter kit: The owning smart account kit.
    internal init(kit: OZSmartAccountKitProtocol) {
        self.kit = kit
    }

    // MARK: - Multi-Signer Transfer

    /// Executes a token transfer signed by an explicit list of signers.
    ///
    /// The caller supplies every signer that must sign via `selectedSigners`.
    /// There is no implicit connected passkey — include
    /// ``SelectedSigner/passkey(credentialId:credentialIdBytes:keyData:transports:)`` when
    /// the connected passkey should sign. Signatures are collected in list
    /// order; passkey entries trigger one OS WebAuthn prompt each, wallet
    /// entries trigger one external-wallet request each.
    ///
    /// Validation order (tested explicitly in the unit suite):
    /// 1. ``OZSmartAccountKitProtocol/requireConnected()`` — throws
    ///    ``WalletException/NotConnected`` when no wallet is connected.
    /// 2. `requireStellarAddress(_:fieldName:)` over `recipient`.
    /// 3. Self-transfer guard (recipient must differ from the connected
    ///    contract id).
    /// 4. Amount parsing via ``OZTransactionOperations/amountToStroops(_:)``.
    /// 5. `selectedSigners.isEmpty` — throws ``ValidationException/InvalidInput``.
    /// 6. `tokenContract` validation (delegated to
    ///    ``multiSignerContractCall(target:targetFn:targetArgs:selectedSigners:forceMethod:resolveContextRuleIds:)``).
    ///
    /// - Parameters:
    ///   - tokenContract: SEP-41 token contract address (`C…` strkey).
    ///   - recipient: Recipient address (`G…` account or `C…` contract). Must
    ///     differ from the connected smart-account contract id.
    ///   - amount: Decimal XLM-style amount string (for example `"10"` or
    ///     `"100.5"`). Parsed via ``OZTransactionOperations/amountToStroops(_:)``.
    ///   - selectedSigners: All signers that must sign, in collection order.
    ///     Must be non-empty.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional callback to resolve context rule
    ///     identifiers per auth entry. When `nil` (default), the SDK resolves
    ///     rule identifiers automatically from the supplied signer set and the
    ///     active context rules.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException/NotConnected`` for unconnected kits;
    ///           ``ValidationException`` for invalid inputs;
    ///           ``TransactionException`` for simulation, signing, or
    ///           submission failures;
    ///           ``WebAuthnException`` for biometric-authentication failures;
    ///           ``ConfigurationException`` when wallet signers are supplied
    ///           but no external-wallet adapter is configured.
    public func multiSignerTransfer(
        tokenContract: String,
        recipient: String,
        amount: String,
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod? = nil,
        resolveContextRuleIds: ResolveContextRuleIds? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        try requireStellarAddress(recipient, fieldName: "recipient")

        // why: self-transfer guard fires AFTER requireConnected and after
        // recipient address validation — order matters so the caller receives
        // the most specific error first (NotConnected, then InvalidAddress,
        // then InvalidInput).
        if recipient == connected.contractId {
            throw ValidationException.invalidInput(
                field: "recipient",
                reason: "Cannot transfer to self"
            )
        }

        let stroops = try OZTransactionOperations.amountToStroops(amount)

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
            .i128(stroops: stroops)
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
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException``, ``ValidationException``,
    ///           ``TransactionException``, ``WebAuthnException``,
    ///           ``ConfigurationException``.
    public func multiSignerContractCall(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod? = nil,
        resolveContextRuleIds: ResolveContextRuleIds? = nil
    ) async throws -> TransactionResult {
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
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException``, ``ValidationException``,
    ///           ``TransactionException``, ``WebAuthnException``,
    ///           ``ConfigurationException``.
    public func multiSignerExecuteAndSubmit(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod? = nil,
        resolveContextRuleIds: ResolveContextRuleIds? = nil
    ) async throws -> TransactionResult {
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
    /// Declared in the main class body (rather than in an extension) so test
    /// doubles can subclass ``OZMultiSignerManager`` and override this
    /// overload to observe routing decisions without exercising the real
    /// signing pipeline.
    ///
    /// - Parameters:
    ///   - hostFunction: Host function being authorized.
    ///   - selectedSigners: Signers participating in the ceremony. Must be
    ///     non-empty.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: The on-chain submission outcome.
    /// - Throws: ``WalletException``, ``ValidationException``,
    ///           ``TransactionException``, ``WebAuthnException``,
    ///           ``ConfigurationException``.
    internal func submitWithMultipleSigners(
        hostFunction: HostFunctionXDR,
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod?
    ) async throws -> TransactionResult {
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
    /// 2. Wallet-signer adapter check — wallet entries require an external
    ///    wallet adapter to be configured on the kit's
    ///    ``OZSmartAccountConfig/externalWallet``.
    /// 3. Per-wallet-signer reachability check via
    ///    ``ExternalWalletAdapter/canSignFor(address:)``.
    /// 4. Per-passkey-signer `keyData` precondition — every passkey entry must
    ///    carry pre-fetched `keyData` so context-rule resolution and signature
    ///    binding can run without an extra on-chain lookup.
    /// 5. Initial simulation surface error.
    /// 6. Re-simulation surface error after attaching collected signatures.
    ///
    /// - Parameters:
    ///   - hostFunction: Host function to authorize and submit.
    ///   - selectedSigners: All signers that must sign, in collection order.
    ///     Must be non-empty; an empty list is a routing bug at the call site.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional context-rule resolver override.
    /// - Returns: A ``TransactionResult`` describing the on-chain outcome.
    /// - Throws: ``WalletException``, ``ValidationException``,
    ///           ``TransactionException``, ``WebAuthnException``,
    ///           ``ConfigurationException``.
    public func submitWithMultipleSigners(
        hostFunction: HostFunctionXDR,
        selectedSigners: [SelectedSigner],
        forceMethod: SubmissionMethod? = nil,
        resolveContextRuleIds: ResolveContextRuleIds? = nil
    ) async throws -> TransactionResult {
        let connected = try kit.requireConnected()

        // Step 0: validate signer-set preconditions (wallet adapter
        // availability, per-wallet reachability, passkey keyData).
        let (walletSigners, externalWallet) = try validateSignerSet(
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
        let contextRules = try await kit.contextRuleManager.listContextRules()

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

            let entryAddressString = addressString(from: addressCreds.address)
            if entryAddressString != connected.contractId {
                // The auth entry references some address other than the
                // connected smart-account contract. Either it matches one
                // of the wallet signers (sign via the wallet adapter
                // directly, per D-112), or it is unsupported.
                if let entryAddressString = entryAddressString,
                   walletSigners.contains(entryAddressString) {
                    let signedWalletEntry = try await signWalletAddressAuthEntry(
                        entry: entry,
                        walletAddress: entryAddressString,
                        expirationLedger: expirationLedger,
                        externalWallet: externalWallet
                    )
                    signedAuthEntries.append(signedWalletEntry)
                } else {
                    let displayAddress = entryAddressString ?? "<unparseable address>"
                    throw TransactionException.signingFailed(
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

            // Step 4d: sign with every passkey signer in declaration order.
            workingEntry = try await signEntryWithPasskeys(
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
                externalWallet: externalWallet,
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
    /// - Wallet signers require an external-wallet adapter to be configured.
    /// - Every wallet signer must be reachable through the configured adapter.
    /// - Every passkey signer must carry pre-fetched `keyData` so the
    ///   rule-resolution loop avoids an extra on-chain lookup (D-114).
    ///
    /// - Parameter selectedSigners: The signer set supplied by the caller.
    /// - Returns: The extracted wallet signer addresses and the resolved
    ///   external-wallet adapter (or `nil` when no wallet signers are present).
    /// - Throws: ``ValidationException`` when any of the preconditions fail.
    private func validateSignerSet(
        selectedSigners: [SelectedSigner]
    ) throws -> (walletSigners: [String], externalWallet: ExternalWalletAdapter?) {
        var walletSigners: [String] = []
        for signer in selectedSigners {
            if case .wallet(let accountId) = signer {
                walletSigners.append(accountId)
            }
        }

        let externalWallet: ExternalWalletAdapter?
        if walletSigners.isEmpty {
            externalWallet = nil
        } else {
            guard let configured = kit.config.externalWallet else {
                throw ValidationException.invalidInput(
                    field: "selectedSigners",
                    reason: "Wallet signers require an external wallet adapter to be configured"
                )
            }
            externalWallet = configured
        }

        if let externalWallet = externalWallet {
            for walletAddress in walletSigners {
                let canSign = externalWallet.canSignFor(address: walletAddress)
                if !canSign {
                    throw ValidationException.invalidInput(
                        field: "selectedSigners",
                        reason: "No signer available for address: \(walletAddress). " +
                            "Use externalWallet.addFromSecret() or externalWallet.addFromWallet() to add a signer."
                    )
                }
            }
        }

        for signer in selectedSigners {
            if case .passkey(_, _, let keyData, _) = signer {
                if keyData == nil {
                    throw ValidationException.invalidInput(
                        field: "selectedSigners",
                        reason: "keyData is required for passkey signers for rule resolution"
                    )
                }
            }
        }

        return (walletSigners, externalWallet)
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
            throw TransactionException.simulationFailed(
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
        selectedSigners: [SelectedSigner]
    ) throws -> [any OZSmartAccountSigner] {
        var smartAccountSigners: [any OZSmartAccountSigner] = []
        smartAccountSigners.reserveCapacity(selectedSigners.count)
        for signer in selectedSigners {
            switch signer {
            case .passkey(_, _, let keyData, _):
                guard let keyData = keyData else {
                    // Defensive — `validateSignerSet` has already rejected
                    // nil keyData; the guard exists so the compiler is
                    // satisfied that we can build a signer without
                    // force-unwrapping.
                    throw ValidationException.invalidInput(
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
        selectedSigners: [SelectedSigner]
    ) async throws -> SorobanAuthorizationEntryXDR {
        var workingEntry = workingEntry
        for (signerIndex, signer) in selectedSigners.enumerated() {
            guard case .passkey(_, let credentialIdBytes, let keyData, let transports) = signer else {
                continue
            }
            try Task.checkCancellation()
            guard let webauthnProvider = kit.config.webauthnProvider else {
                throw ValidationException.invalidInput(
                    field: "webauthnProvider",
                    reason: "WebAuthn provider is required for passkey signers but is not configured"
                )
            }
            guard let keyData = keyData else {
                // Defensive — `validateSignerSet` guarantees this is non-nil.
                throw ValidationException.invalidInput(
                    field: "selectedSigners",
                    reason: "keyData is required for passkey signers for rule resolution"
                )
            }

            // why: when credentialIdBytes is available, attach an
            // AllowCredential carrying it and any transport hints so the
            // OS routing layer can pick the correct passkey when more
            // than one is registered for this RP. When credentialIdBytes
            // is nil per D-115 we pass no allowCredentials list at all
            // so the authenticator falls back to its default credential
            // discovery flow.
            let allowCredentials: [AllowCredential]?
            if let credentialIdBytes = credentialIdBytes {
                allowCredentials = [
                    AllowCredential(
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

    /// Produces one delegated-signer auth entry per wallet signer and
    /// appends it to `signedAuthEntries`. Each delegated entry is signed via
    /// ``authorizeInvocation(walletAddress:validUntilLedger:invocation:networkPassphrase:externalWallet:)``
    /// and contributes a `{public_key: <empty>, signature: <empty>}` placeholder
    /// to the smart-account signature map so the rule engine counts the
    /// delegated signer when evaluating the active context rule.
    ///
    /// - Returns: The updated `workingEntry` after every delegated-signer
    ///   placeholder has been merged into its signature map.
    private func appendDelegatedAuthEntries(
        workingEntry: SorobanAuthorizationEntryXDR,
        authDigest: Data,
        expirationLedger: UInt32,
        resolvedContextRuleIds: [UInt32],
        selectedSigners: [SelectedSigner],
        externalWallet: ExternalWalletAdapter?,
        connectedContractId: String,
        signedAuthEntries: inout [SorobanAuthorizationEntryXDR]
    ) async throws -> SorobanAuthorizationEntryXDR {
        var workingEntry = workingEntry
        for signer in selectedSigners {
            guard case .wallet(let walletAddress) = signer else { continue }
            guard let externalWallet = externalWallet else {
                // Defensive — `validateSignerSet` guarantees externalWallet
                // is non-nil whenever a wallet signer is in the list.
                throw ConfigurationException.invalidConfig(
                    details: "External wallet adapter is required for wallet signers but is not configured"
                )
            }

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
                externalWallet: externalWallet
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
        forceMethod: SubmissionMethod?
    ) async throws -> TransactionResult {
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
    /// - Throws: ``ValidationException/InvalidAddress`` for malformed
    ///   `target`; ``ValidationException/InvalidInput`` for blank `targetFn`
    ///   or empty `selectedSigners`.
    private func validateContractCallArgs(
        target: String,
        targetFn: String,
        selectedSigners: [SelectedSigner]
    ) throws {
        try requireContractAddress(target, fieldName: "target")

        if targetFn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationException.invalidInput(
                field: "targetFn",
                reason: "Function name cannot be empty"
            )
        }

        if selectedSigners.isEmpty {
            throw ValidationException.invalidInput(
                field: "selectedSigners",
                reason: "At least one signer must be provided"
            )
        }
    }

    /// Signs an auth entry whose `Address` credentials match a wallet signer
    /// directly, using the external wallet adapter rather than the smart
    /// account's `__check_auth` indirection.
    ///
    /// The signature is formatted as the classical Stellar
    /// `Vec([Map({"public_key": Bytes, "signature": Bytes})])` shape. The
    /// preimage construction reuses the EXISTING entry nonce and the supplied
    /// expiration ledger, matching D-112.
    ///
    /// - Parameters:
    ///   - entry: The unsigned auth entry whose `Address` credentials reference
    ///     `walletAddress`.
    ///   - walletAddress: The Stellar `G…` address of the wallet signer.
    ///   - expirationLedger: Ledger sequence at which the signature expires.
    ///   - externalWallet: External wallet adapter that produces the raw
    ///     Ed25519 signature. Must be non-nil; the caller (Step 0a above)
    ///     guarantees this.
    /// - Returns: The signed auth entry.
    /// - Throws: ``TransactionException/SigningFailed``,
    ///           ``ConfigurationException``.
    private func signWalletAddressAuthEntry(
        entry: SorobanAuthorizationEntryXDR,
        walletAddress: String,
        expirationLedger: UInt32,
        externalWallet: ExternalWalletAdapter?
    ) async throws -> SorobanAuthorizationEntryXDR {
        guard let externalWallet = externalWallet else {
            throw ConfigurationException.invalidConfig(
                details: "External wallet adapter is required for wallet auth entries but is not configured"
            )
        }

        // Clone the entry via XDR round-trip so the caller's instance is
        // never mutated, and stamp the new expiration ledger on the cloned
        // address credentials.
        let cloned = try OZTransactionOperations.cloneAuthEntry(entry)
        guard case .address(let credentials) = cloned.credentials else {
            throw TransactionException.signingFailed(
                reason: "Expected Address credentials on wallet auth entry for \(walletAddress)"
            )
        }

        let signedCredentials = try await signSorobanAuthEntryViaExternalWallet(
            walletAddress: walletAddress,
            nonce: credentials.nonce,
            expirationLedger: expirationLedger,
            invocation: cloned.rootInvocation,
            credentialsAddress: credentials.address,
            externalWallet: externalWallet
        )

        return SorobanAuthorizationEntryXDR(
            credentials: .address(signedCredentials),
            rootInvocation: cloned.rootInvocation
        )
    }

    // MARK: - Hand-rolled Auth.authorizeInvocation equivalent

    /// Hand-rolled equivalent of the `Auth.authorizeInvocation` static helper
    /// that the iOS SDK does not expose at top level.
    ///
    /// Builds an unsigned `SorobanAuthorizationEntryXDR` from scratch:
    /// - Generates a fresh cryptographically random nonce via
    ///   ``OZTransactionOperations/generateNonce()``.
    /// - Constructs the `Address` credentials referencing `walletAddress`,
    ///   with the supplied `validUntilLedger` and a `void` placeholder
    ///   signature.
    /// - Builds the `HashIDPreimage::SorobanAuthorization` preimage and
    ///   base64-encodes it for the external wallet adapter.
    /// - Requests the raw Ed25519 signature from the external wallet
    ///   adapter.
    /// - Wraps the resulting signature into the classical
    ///   `Vec([Map({public_key, signature})])` shape used by stock Stellar
    ///   accounts and writes it into the credentials.
    ///
    /// The iOS SDK does not expose a top-level `Auth.authorizeInvocation`
    /// helper, so the algorithm is hand-rolled here and kept internal to this
    /// manager. The public surface of the smart-account module remains
    /// unchanged.
    ///
    /// - Parameters:
    ///   - walletAddress: The Stellar `G…` address of the delegated wallet
    ///     signer.
    ///   - validUntilLedger: Ledger sequence at which the signature expires.
    ///   - invocation: Invocation tree being authorized — typically the
    ///     `__check_auth(authDigest)` call on the smart account contract.
    ///   - networkPassphrase: Network passphrase used to derive the network
    ///     id bound into the preimage.
    ///   - externalWallet: External wallet adapter that produces the raw
    ///     Ed25519 signature.
    /// - Returns: The fully signed delegated auth entry.
    /// - Throws: ``TransactionException/SigningFailed``.
    private static func authorizeInvocation(
        walletAddress: String,
        validUntilLedger: UInt32,
        invocation: SorobanAuthorizedInvocationXDR,
        networkPassphrase: String,
        externalWallet: ExternalWalletAdapter
    ) async throws -> SorobanAuthorizationEntryXDR {
        // Generate a cryptographically random nonce. The Soroban host
        // requires unique nonces per credentials value within an envelope.
        let nonce = try OZTransactionOperations.generateNonce()

        let walletAccountAddress = try SCAddressXDR(accountId: walletAddress)

        let signedCredentials = try await Self.signSorobanAuthEntryViaExternalWalletStatic(
            walletAddress: walletAddress,
            nonce: nonce,
            expirationLedger: validUntilLedger,
            invocation: invocation,
            credentialsAddress: walletAccountAddress,
            networkPassphrase: networkPassphrase,
            externalWallet: externalWallet,
            preimageEncodeFailureLabel: "Failed to XDR-encode delegated wallet auth preimage"
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(signedCredentials),
            rootInvocation: invocation
        )
    }

    // MARK: - Shared external-wallet signing helper

    /// Instance-method wrapper around
    /// ``signSorobanAuthEntryViaExternalWalletStatic(walletAddress:nonce:expirationLedger:invocation:credentialsAddress:networkPassphrase:externalWallet:preimageEncodeFailureLabel:)``
    /// that captures the kit's network passphrase so callers in instance
    /// context don't need to pass it explicitly.
    private func signSorobanAuthEntryViaExternalWallet(
        walletAddress: String,
        nonce: Int64,
        expirationLedger: UInt32,
        invocation: SorobanAuthorizedInvocationXDR,
        credentialsAddress: SCAddressXDR,
        externalWallet: ExternalWalletAdapter
    ) async throws -> SorobanAddressCredentialsXDR {
        return try await Self.signSorobanAuthEntryViaExternalWalletStatic(
            walletAddress: walletAddress,
            nonce: nonce,
            expirationLedger: expirationLedger,
            invocation: invocation,
            credentialsAddress: credentialsAddress,
            networkPassphrase: kit.config.networkPassphrase,
            externalWallet: externalWallet,
            preimageEncodeFailureLabel: "Failed to XDR-encode wallet auth preimage"
        )
    }

    /// Builds a ``HashIDPreimageSorobanAuthorizationXDR`` from the supplied
    /// `(nonce, expirationLedger, invocation)` tuple, base64-encodes it,
    /// requests an Ed25519 signature from `externalWallet`, base64-decodes
    /// the response, locally verifies the signature against `walletAddress`,
    /// and assembles the final classical Ed25519 ``SorobanAddressCredentialsXDR``.
    ///
    /// Local verification (per F-SEC-iOS-1) refuses signatures that do not
    /// verify under the requested wallet's public key. This protects against
    /// adapters that silently return a valid-looking but wrong signature
    /// (for example because the user authorised a different account in their
    /// wallet UI), which would otherwise surface as an opaque on-chain
    /// `auth-failed` only after submission.
    ///
    /// - Parameters:
    ///   - walletAddress: Stellar G-address that should sign the entry.
    ///   - nonce: Nonce already present on (or freshly generated for) the
    ///     credentials value the entry references.
    ///   - expirationLedger: Signature expiration ledger to bind into the
    ///     preimage.
    ///   - invocation: Invocation tree the entry authorises.
    ///   - credentialsAddress: Address value that ends up on the produced
    ///     ``SorobanAddressCredentialsXDR``. Distinct from `walletAddress`
    ///     because the credentials may carry the address as an encoded
    ///     ``SCAddressXDR`` value sourced from a different code path.
    ///   - networkPassphrase: Network passphrase used to derive the network
    ///     id bound into the preimage.
    ///   - externalWallet: Adapter that produces the raw Ed25519 signature.
    ///   - preimageEncodeFailureLabel: Caller-specific message prefix used
    ///     when the preimage XDR encode fails. Distinguishes the immediate
    ///     auth-entry path from the freshly-built delegated invocation path
    ///     in surfaced error messages.
    /// - Returns: The signed ``SorobanAddressCredentialsXDR``.
    /// - Throws: ``TransactionException/SigningFailed`` for signing or
    ///   verification failures.
    private static func signSorobanAuthEntryViaExternalWalletStatic(
        walletAddress: String,
        nonce: Int64,
        expirationLedger: UInt32,
        invocation: SorobanAuthorizedInvocationXDR,
        credentialsAddress: SCAddressXDR,
        networkPassphrase: String,
        externalWallet: ExternalWalletAdapter,
        preimageEncodeFailureLabel: String
    ) async throws -> SorobanAddressCredentialsXDR {
        let networkIdBytes = networkPassphrase.sha256Hash
        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(
            networkID: HashXDR(networkIdBytes),
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            invocation: invocation
        )
        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)

        let preimageBytes: [UInt8]
        do {
            preimageBytes = try XDREncoder.encode(preimage)
        } catch {
            throw TransactionException.signingFailed(
                reason: "\(preimageEncodeFailureLabel): " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }
        let preimageBase64 = Data(preimageBytes).base64EncodedString()

        let signResult: SignAuthEntryResult
        do {
            signResult = try await externalWallet.signAuthEntry(
                preimageXdr: preimageBase64,
                options: SignAuthEntryOptions(
                    networkPassphrase: networkPassphrase,
                    address: walletAddress
                )
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "External wallet signing failed for \(walletAddress): " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }

        guard let signatureBytes = Data(base64Encoded: signResult.signedAuthEntry) else {
            throw TransactionException.signingFailed(
                reason: "External wallet returned non-base64 signature for \(walletAddress)"
            )
        }

        // Derive the raw 32-byte Ed25519 public key from the wallet signer's
        // G-address (or use the address the adapter reported when present).
        let resolvedSignerAddress = signResult.signerAddress ?? walletAddress
        let signerKeyPair: KeyPair
        do {
            signerKeyPair = try KeyPair(accountId: resolvedSignerAddress)
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to derive public key from wallet signer address \(resolvedSignerAddress): " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }

        // F-SEC-iOS-1: locally verify the wallet adapter's signature against
        // the requested address before trusting it downstream. Failure here
        // is far more actionable than the on-chain `auth-failed` we would
        // otherwise see after submission.
        let preimageHash = Data(preimageBytes).sha256Hash
        let signatureValid: Bool
        do {
            signatureValid = try signerKeyPair.verify(
                signature: [UInt8](signatureBytes),
                message: [UInt8](preimageHash)
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "Wallet adapter returned signature that does not verify against requested address \(resolvedSignerAddress): " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }
        if !signatureValid {
            throw TransactionException.signingFailed(
                reason: "Wallet adapter returned signature that does not verify against requested address \(resolvedSignerAddress)"
            )
        }

        let publicKeyBytes = Data(signerKeyPair.publicKey.bytes)

        let signatureScVal = OZTransactionOperations.classicalEd25519SignatureScVal(
            publicKey: publicKeyBytes,
            signature: signatureBytes
        )

        return SorobanAddressCredentialsXDR(
            address: credentialsAddress,
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            signature: signatureScVal
        )
    }

    // MARK: - Internal RPC and transaction helpers

    /// Builds the unsigned transaction shape used by the simulate / re-simulate
    /// passes. Mirrors the shape used by ``OZTransactionOperations`` so the
    /// resource-fee envelopes line up across single- and multi-signer flows.
    private func buildTransaction(
        sourceAccount: TransactionAccount,
        operations: [Operation],
        timeoutSeconds: Int
    ) throws -> Transaction {
        let nowSeconds = UInt64(Date().timeIntervalSince1970)
        let timeBounds = TimeBounds(
            minTime: 0,
            maxTime: nowSeconds + UInt64(max(0, timeoutSeconds))
        )
        let preconditions = TransactionPreconditions(timeBounds: timeBounds)
        do {
            return try Transaction(
                sourceAccount: sourceAccount,
                operations: operations,
                memo: Memo.none,
                preconditions: preconditions,
                maxOperationFee: StellarProtocolConstants.MIN_BASE_FEE
            )
        } catch {
            throw TransactionException.signingFailed(
                reason: "Failed to build transaction: " +
                    (SmartAccountException.messageOf(error) ?? "unknown"),
                cause: error
            )
        }
    }

    /// Wraps the kit's RPC `simulateTransaction` and lifts transport-level and
    /// simulation-error responses into ``TransactionException/SimulationFailed``.
    private func simulate(
        transaction: Transaction,
        failureMessagePrefix: String
    ) async throws -> SimulateTransactionResponse {
        let request = SimulateTransactionRequest(transaction: transaction)
        let response = await kit.sorobanServer.simulateTransaction(
            simulateTxRequest: request
        )
        switch response {
        case .success(let simulation):
            if let error = simulation.error {
                throw TransactionException.simulationFailed(
                    reason: "\(failureMessagePrefix)\(error)"
                )
            }
            return simulation
        case .failure(let error):
            throw TransactionException.simulationFailed(
                reason: "\(failureMessagePrefix)\(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Wraps `SorobanServer.getAccount(accountId:)` and lifts transport-level
    /// failures into ``TransactionException/SubmissionFailed``.
    private func fetchAccount(accountId: String) async throws -> Account {
        let response = await kit.sorobanServer.getAccount(accountId: accountId)
        switch response {
        case .success(let account):
            return account
        case .failure(let error):
            throw TransactionException.submissionFailed(
                reason: "Failed to fetch account \(accountId): \(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Wraps `SorobanServer.getLatestLedger()` and lifts transport-level
    /// failures into ``TransactionException/SubmissionFailed``.
    private func fetchLatestLedger() async throws -> GetLatestLedgerResponse {
        let response = await kit.sorobanServer.getLatestLedger()
        switch response {
        case .success(let ledger):
            return ledger
        case .failure(let error):
            throw TransactionException.submissionFailed(
                reason: "Failed to fetch latest ledger: \(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Decodes a Soroban `SCAddressXDR` value back into its canonical strkey
    /// representation. Returns the `G…` strkey for account-typed addresses
    /// and the `C…` strkey for contract-typed addresses; returns `nil` when
    /// the address cannot be encoded into either form.
    private func addressString(from scAddress: SCAddressXDR) -> String? {
        if let accountId = scAddress.accountId {
            return accountId
        }
        if case .contract(let wrapped) = scAddress {
            return try? wrapped.wrapped.encodeContractId()
        }
        return nil
    }

    /// Converts an `SorobanRpcRequestError` to a stable string for the
    /// various ``TransactionException`` messages produced by this class.
    private func rpcErrorMessage(_ error: SorobanRpcRequestError) -> String {
        switch error {
        case .requestFailed(let message):
            return message
        case .errorResponse(let rpcError):
            if let message = rpcError.message, !message.isEmpty {
                return "\(rpcError.code): \(message)"
            }
            return "RPC error \(rpcError.code)"
        case .parsingResponseFailed(let message, _):
            return message
        }
    }
}

