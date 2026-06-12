//
//  OZTransactionOperations.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security

/// Outcome of a smart-account transaction submission.
///
/// Carries the success flag, the transaction hash (when one was assigned at the
/// network boundary), the ledger sequence the transaction landed in (when known),
/// and a human-readable error description for failure paths.
///
/// Example:
/// ```swift
/// let result = try await txOps.transfer(
///     tokenContract: "C...",
///     recipient: "G...",
///     amount: "10"
/// )
/// if result.success {
///     print("Confirmed in ledger \(result.ledger ?? 0)")
/// } else {
///     print("Failed: \(result.error ?? "unknown")")
/// }
/// ```
public struct OZTransactionResult: Sendable, Equatable, Hashable {

    /// `true` when the transaction was accepted by the network and confirmed
    /// successfully on-chain; `false` for every other outcome (simulation failure,
    /// network rejection, polling timeout, on-chain `FAILED` status).
    public let success: Bool

    /// Stellar transaction hash assigned at submission. `nil` only when submission
    /// failed before a hash could be assigned (for example, simulation failure).
    public let hash: String?

    /// Ledger sequence number that included the transaction. Present only after
    /// successful confirmation polling.
    public let ledger: UInt32?

    /// Human-readable failure description. `nil` on success.
    public let error: String?

    public init(
        success: Bool,
        hash: String? = nil,
        ledger: UInt32? = nil,
        error: String? = nil
    ) {
        self.success = success
        self.hash = hash
        self.ledger = ledger
        self.error = error
    }
}

/// Callback that resolves the context rule identifiers to bind into the auth
/// digest for a single authorization entry during the signing loop.
///
/// The callback is invoked once per matching auth entry. The first argument
/// carries the authorization entry being signed; the second is the entry's index
/// in the simulation-supplied list. The returned identifiers replace the
/// automatic context-rule resolution that otherwise runs against the connected
/// signer set.
///
/// Errors thrown from the callback propagate to the caller of ``OZTransactionOperations/submit(hostFunction:auth:forceMethod:resolveContextRuleIds:)``.
public typealias OZResolveContextRuleIds = @Sendable (
    _ entry: SorobanAuthorizationEntryXDR,
    _ index: Int
) async throws -> [UInt32]

/// Transaction-pipeline operations for OpenZeppelin Smart Accounts.
///
/// Builds, signs, and submits transactions for a connected smart account wallet.
/// Drives the full simulate / sign / re-simulate / submit pipeline, including
/// WebAuthn auth-entry signing, relayer-vs-RPC submission selection, and
/// transaction-result polling.
///
/// When a relayer is configured, submission mode is auto-selected: Mode 1
/// (host function + auth entries, envelope unsigned) when all auth entries use
/// `Address` credentials; Mode 2 (signed envelope XDR forwarded to the relayer)
/// when any auth entry carries `sourceAccount` credentials. The `forceMethod`
/// parameter overrides auto-detection per call.
///
/// The transaction is re-simulated after the signing pass so that resource fees
/// reflect the real WebAuthn signature payload size.
///
/// Instances are constructed by ``OZSmartAccountKit`` and accessed through
/// `kit.transactionOperations`.
public final class OZTransactionOperations: OZManagerHelpers, @unchecked Sendable {

    // MARK: - Stored properties

    let kit: OZSmartAccountKitProtocol

    // MARK: - Initialization

    /// Internal initializer; instances are constructed by `OZSmartAccountKit`.
    internal init(kit: OZSmartAccountKitProtocol) {
        self.kit = kit
    }

    /// Transfers tokens from the connected smart account to a recipient.
    ///
    /// Compatible with any SEP-41 token (native asset via the Stellar Asset
    /// Contract, or custom Soroban tokens). The decimal amount is converted to
    /// the token's base units before submission: the `decimals` value is used
    /// when supplied, otherwise the token's on-chain `decimals()` is fetched
    /// automatically via ``fetchTokenDecimals(tokenContract:)``. Delegates to
    /// ``contractCall(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)``
    /// to drive the full simulate / sign / submit pipeline.
    ///
    /// - Parameters:
    ///   - tokenContract: SEP-41 token contract address (`C…` strkey).
    ///   - recipient: Recipient address (`G…` account or `C…` contract).
    ///   - amount: Decimal amount string (for example `"10"` or `"100.5"`).
    ///   - decimals: The token's decimal scale used to convert `amount` to base
    ///     units. When `nil` (default) the value is fetched on-chain via
    ///     ``fetchTokenDecimals(tokenContract:)``. Supply it to avoid the extra
    ///     RPC round trip when the scale is already known.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException/NotConnected`` when no wallet is connected;
    ///   ``SmartAccountValidationException`` for invalid inputs or self-transfer;
    ///   ``SmartAccountTransactionException`` for simulation, signing, or submission failures;
    ///   ``WebAuthnException`` for biometric-authentication failures.
    public func transfer(
        tokenContract: String,
        recipient: String,
        amount: String,
        decimals: Int? = nil,
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()
        try requireStellarAddress(recipient, fieldName: "recipient")
        if recipient == connected.contractId {
            throw SmartAccountValidationException.invalidInput(
                field: "recipient",
                reason: "Cannot transfer to self"
            )
        }

        let resolvedDecimals: Int
        if let decimals = decimals {
            resolvedDecimals = decimals
        } else {
            resolvedDecimals = try await fetchTokenDecimals(tokenContract: tokenContract)
        }
        let baseUnits = try OZTransactionOperations.amountToBaseUnits(amount, decimals: resolvedDecimals)

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

        return try await contractCall(
            target: tokenContract,
            targetFn: "transfer",
            targetArgs: targetArgs,
            forceMethod: forceMethod
        )
    }

    /// Reads the `decimals()` value from a SEP-41 token contract.
    ///
    /// Simulates the token contract's `decimals` function and returns the
    /// reported `u32` scale.
    ///
    /// - Parameter tokenContract: SEP-41 token contract address (`C…` strkey).
    /// - Returns: The token's decimal scale.
    /// - Throws: ``SmartAccountValidationException`` when `tokenContract` is not
    ///   a valid contract address; ``SmartAccountTransactionException`` when the
    ///   simulation fails or the contract does not return a valid `u32` value.
    public func fetchTokenDecimals(tokenContract: String) async throws -> Int {
        try requireContractAddress(tokenContract, fieldName: "tokenContract")

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: tokenContract),
            functionName: "decimals",
            args: []
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)
        let result = try await simulateAndExtractResult(hostFunction: hostFunction)

        guard let decimals = OZTransactionOperations.scValToUInt32(result) else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "Token contract \(tokenContract) did not return a valid u32 decimals value"
            )
        }
        return Int(decimals)
    }

    /// Calls an arbitrary function on an external contract directly from the
    /// smart account.
    ///
    /// The smart account authorizes the call via Soroban's `require_auth`
    /// mechanism triggered by the target contract. Use this for any external
    /// contract interaction (token approvals, token transfers, DeFi protocol
    /// calls) where the smart account is the authorized party.
    ///
    /// - Parameters:
    ///   - target: Target contract address (`C…` strkey).
    ///   - targetFn: Function name to invoke on the target contract.
    ///   - targetArgs: Pre-encoded SCVal arguments forwarded to the function.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional override of the automatic
    ///     context-rule resolution performed during the signing loop.
    /// - Returns: ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException/NotConnected``, ``SmartAccountValidationException``,
    ///   ``SmartAccountTransactionException``, ``WebAuthnException``, ``SmartAccountCredentialException``.
    public func contractCall(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        _ = try kit.requireConnected()

        try requireContractAddress(target, fieldName: "target")
        try requireNonBlankFunctionName(targetFn)

        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: target),
            functionName: targetFn,
            args: targetArgs
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        return try await submit(
            hostFunction: hostFunction,
            auth: [],
            forceMethod: forceMethod,
            resolveContextRuleIds: resolveContextRuleIds
        )
    }

    /// Executes an arbitrary function via the smart account contract's `execute`
    /// entry point.
    ///
    /// Calls `execute(target, target_fn, target_args)` on the smart account
    /// contract; the contract dispatches the inner call on behalf of the smart
    /// account after evaluating its context rules and policies.
    ///
    /// - Parameters:
    ///   - target: Target contract address (`C…` strkey).
    ///   - targetFn: Function name to invoke on the target contract.
    ///   - targetArgs: Pre-encoded SCVal arguments forwarded to the inner call.
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional context-rule resolver override.
    /// - Returns: ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException/NotConnected``, ``SmartAccountValidationException``,
    ///   ``SmartAccountTransactionException``, ``WebAuthnException``, ``SmartAccountCredentialException``.
    public func executeAndSubmit(
        target: String,
        targetFn: String,
        targetArgs: [SCValXDR] = [],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()

        try requireContractAddress(target, fieldName: "target")
        try requireNonBlankFunctionName(targetFn)

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

        return try await submit(
            hostFunction: hostFunction,
            auth: [],
            forceMethod: forceMethod,
            resolveContextRuleIds: resolveContextRuleIds
        )
    }

    /// Submits a host function through the full simulate / sign / re-simulate /
    /// submit pipeline.
    ///
    /// This is the low-level entry point used by ``transfer(tokenContract:recipient:amount:forceMethod:)``,
    /// ``contractCall(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)``,
    /// and ``executeAndSubmit(target:targetFn:targetArgs:forceMethod:resolveContextRuleIds:)``.
    /// Callers that need to construct a host function manually use this method
    /// directly. The auth-entry signing pass writes the OpenZeppelin AuthPayload
    /// Map directly into the credentials' `signature` field; the transaction is
    /// re-simulated after signing because WebAuthn signatures are larger than the
    /// placeholders the initial simulation used.
    ///
    /// - Parameters:
    ///   - hostFunction: Host function to execute.
    ///   - auth: Authorization entries supplied as input to the simulation
    ///     (typically empty — the simulation discovers them).
    ///   - forceMethod: Optional submission-method override.
    ///   - resolveContextRuleIds: Optional context-rule resolver override.
    /// - Returns: ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountWalletException/NotConnected``, ``SmartAccountValidationException``,
    ///   ``SmartAccountTransactionException``, ``WebAuthnException``, ``SmartAccountCredentialException``.
    public func submit(
        hostFunction: HostFunctionXDR,
        auth: [SorobanAuthorizationEntryXDR],
        forceMethod: OZSubmissionMethod? = nil,
        resolveContextRuleIds: OZResolveContextRuleIds? = nil
    ) async throws -> OZTransactionResult {
        let connected = try kit.requireConnected()
        let deployer = try await kit.getDeployer()
        let deployerAccount = try await fetchAccount(accountId: deployer.accountId)

        let initialOperation = InvokeHostFunctionOperation(
            hostFunction: hostFunction,
            auth: auth
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
        let simulatedAuthEntries = simulation.sorobanAuth ?? []

        let signedAuthEntries = try await signAuthEntriesPass(
            simulatedAuthEntries: simulatedAuthEntries,
            connected: connected,
            resolveContextRuleIds: resolveContextRuleIds
        )

        if !signedAuthEntries.isEmpty {
            do {
                try await kit.credentialManagerProtocol.updateLastUsed(
                    credentialId: connected.credentialId
                )
            } catch {
                // best-effort; the credential update is non-critical
            }
        }

        kit.events.emit(
            .transactionSigned(
                contractId: connected.contractId,
                credentialId: signedAuthEntries.isEmpty ? nil : connected.credentialId
            )
        )

        let signedTransaction = try await rebuildAndReSimulate(
            deployer: deployer,
            hostFunction: hostFunction,
            signedAuthEntries: signedAuthEntries
        )

        let useRelayer = resolveSubmissionMethod(forceMethod: forceMethod) == .relayer
        return try await submitOrRelay(
            transaction: signedTransaction,
            hostFunction: hostFunction,
            signedAuthEntries: signedAuthEntries,
            signer: deployer,
            useRelayer: useRelayer,
            emitEvents: true
        )
    }

    /// Signs every authorization entry whose `Address` credentials match the
    /// connected smart account contract. Entries pointing at other addresses
    /// and entries with `sourceAccount` credentials are returned unchanged.
    ///
    /// Pre-fetches the latest ledger and the active context-rule set once so
    /// the per-entry signing pass does not perform N redundant RPC round trips.
    ///
    /// - Parameters:
    ///   - simulatedAuthEntries: Entries returned from the initial simulation.
    ///   - connected: Active connected-state pair identifying the smart account.
    ///   - resolveContextRuleIds: Optional override of the automatic context-rule
    ///     resolution.
    /// - Returns: Authorization entries with the OZ AuthPayload Map wired into
    ///   the `signature` field of every matching entry.
    /// - Throws: ``SmartAccountValidationException``, ``SmartAccountCredentialException``,
    ///   ``WebAuthnException``, ``SmartAccountTransactionException``.
    private func signAuthEntriesPass(
        simulatedAuthEntries: [SorobanAuthorizationEntryXDR],
        connected: ConnectedState,
        resolveContextRuleIds: OZResolveContextRuleIds?
    ) async throws -> [SorobanAuthorizationEntryXDR] {
        if simulatedAuthEntries.isEmpty {
            return []
        }

        // why: fetch latest ledger ONCE before the signing loop so the
        // expiration value is constant across all auth entries; a per-entry
        // fetch would add N redundant RPC round trips on long entry lists.
        let latestLedger = try await fetchLatestLedger()
        // why: compute expiration ledger in 64-bit arithmetic and clamp via
        // `UInt32(exactly:)` so a near-`UInt32.max` ledger sequence cannot
        // wrap silently. Config validation guarantees the addend is >= 1;
        // overflow is unlikely in practice but we still refuse to ship a
        // wrapped value.
        let expirationU64 = UInt64(latestLedger.sequence)
            + UInt64(kit.config.signatureExpirationLedgers)
        guard let expiration = UInt32(exactly: expirationU64) else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "Computed expirationLedger \(expirationU64) overflows UInt32"
            )
        }

        // why: pre-fetch the active context rules ONCE so the signer pass
        // does not perform N additional RPC calls; the rule set is stable
        // throughout the signing pass.
        let contextRules = try await kit.contextRuleManagerProtocol.listContextRules(maxScanId: nil)

        var signedAuthEntries: [SorobanAuthorizationEntryXDR] = []
        signedAuthEntries.reserveCapacity(simulatedAuthEntries.count)

        for (entryIndex, entry) in simulatedAuthEntries.enumerated() {
            // Source-account entries do not need client-side signing; pass through unchanged.
            if case .sourceAccount = entry.credentials {
                signedAuthEntries.append(entry)
                continue
            }

            // WITH_DELEGATES entries require caller-assembled delegate signatures and cannot
            // be auto-signed by this pipeline. The caller must sign each delegate node via
            // SorobanAuthorizationEntryXDR.sign(forAddress:) before submission.
            if case .addressWithDelegates = entry.credentials {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Authorization entry carries WITH_DELEGATES credentials. " +
                        "Delegated entries must be signed per delegate node via " +
                        "SorobanAuthorizationEntryXDR.sign(forAddress:) before submission."
                )
            }

            guard let addressCreds = entry.credentials.addressCredentials else {
                // Unknown credential arm; fail fast rather than silently skipping.
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Authorization entry has unrecognised credentials and cannot be signed"
                )
            }

            let entryAddress = OZAddressStrKey.fromXdr(addressCreds.address)
            if entryAddress != connected.contractId {
                signedAuthEntries.append(entry)
                continue
            }

            let payloadHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
                entry: entry,
                expirationLedger: expiration,
                networkPassphrase: kit.config.networkPassphrase
            )

            guard let webauthnProvider = kit.config.webauthnProvider else {
                throw SmartAccountValidationException.invalidInput(
                    field: "webauthnProvider",
                    reason: "WebAuthn provider is required for signing auth entries but is not configured"
                )
            }

            let credIdBytes: Data
            do {
                credIdBytes = try Data(base64URLEncoded: connected.credentialId)
            } catch {
                throw SmartAccountCredentialException.invalid(
                    reason: "Failed to decode credentialId from Base64URL: \(connected.credentialId)",
                    cause: error
                )
            }

            // why: storage hit short-circuits the on-chain lookup; otherwise
            // the active context rules are scanned for an External signer whose
            // key suffix matches the decoded credential id.
            let stored: OZStoredCredential? = await safeGetCredential(
                credentialId: connected.credentialId
            )
            let signer: OZExternalSigner
            if let stored = stored {
                signer = try OZExternalSigner.webAuthn(
                    verifierAddress: kit.config.webauthnVerifierAddress,
                    publicKey: stored.publicKey,
                    credentialId: credIdBytes
                )
            } else {
                let keyData = try await findKeyDataFromContextRules(
                    credentialIdBytes: credIdBytes
                )
                signer = try OZExternalSigner(
                    verifierAddress: kit.config.webauthnVerifierAddress,
                    keyData: keyData
                )
            }

            let resolvedContextRuleIds: [UInt32]
            if let resolveContextRuleIds = resolveContextRuleIds {
                resolvedContextRuleIds = try await resolveContextRuleIds(entry, entryIndex)
            } else {
                resolvedContextRuleIds = try await kit.contextRuleManagerProtocol.resolveContextRuleIdsForEntry(
                    entry: entry,
                    signers: [signer],
                    contextRules: contextRules
                )
            }

            let authDigest = try await OZSmartAccountAuth.buildAuthDigest(
                signaturePayload: payloadHash,
                contextRuleIds: resolvedContextRuleIds
            )

            let allowCredential = WebAuthnAllowCredential(
                id: credIdBytes,
                transports: stored?.transports
            )
            let authResult: WebAuthnAuthenticationResult
            do {
                authResult = try await webauthnProvider.authenticate(
                    challenge: authDigest,
                    allowCredentials: [allowCredential]
                )
            } catch let error as WebAuthnException {
                throw error
            } catch {
                throw WebAuthnException.authenticationFailed(
                    reason: SmartAccountException.messageOf(error) ?? "WebAuthn authentication failed",
                    cause: error
                )
            }

            let compactSig = try SmartAccountUtils.normalizeSignature(authResult.signature)
            let webAuthnSig = try OZWebAuthnSignature(
                authenticatorData: authResult.authenticatorData,
                clientData: authResult.clientDataJSON,
                signature: compactSig
            )

            let signedEntry = try await OZSmartAccountAuth.signAuthEntry(
                entry: entry,
                signer: signer,
                signature: webAuthnSig,
                expirationLedger: expiration,
                contextRuleIds: resolvedContextRuleIds
            )
            signedAuthEntries.append(signedEntry)
        }

        return signedAuthEntries
    }

    /// Rebuilds the transaction with the signed authorization entries and
    /// re-simulates so resource fees reflect the real WebAuthn signature size.
    ///
    /// WebAuthn signatures are larger than the placeholders the initial
    /// simulation uses; the post-signing transaction must be re-simulated and
    /// have the fresh `sorobanData` and `minResourceFee` applied so the network
    /// will accept the envelope.
    ///
    /// - Parameters:
    ///   - deployer: Source-account keypair owning the transaction envelope.
    ///   - hostFunction: Host function executed by the transaction.
    ///   - signedAuthEntries: Auth entries with the OZ AuthPayload Map wired
    ///     into every matching entry's `signature` field.
    /// - Returns: A re-simulated transaction with the fresh resource-fee envelope.
    /// - Throws: ``SmartAccountTransactionException`` on re-simulation failure or rebuild
    ///   error.
    private func rebuildAndReSimulate(
        deployer: KeyPair,
        hostFunction: HostFunctionXDR,
        signedAuthEntries: [SorobanAuthorizationEntryXDR]
    ) async throws -> Transaction {
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
        let reSimulation = try await simulate(
            transaction: signedTransaction,
            failureMessagePrefix: "Re-simulation error: "
        )
        try OZTransactionOperations.applySimulation(
            simulation: reSimulation,
            transaction: signedTransaction,
            signedAuthEntries: signedAuthEntries,
            relayerMode: false
        )
        return signedTransaction
    }

    /// Submits a multi-signer transaction using the same Mode 1 / Mode 2 routing
    /// as ``submit(hostFunction:auth:forceMethod:resolveContextRuleIds:)``.
    ///
    /// Consumed by the multi-signer manager after it has collected every
    /// signature and produced the final re-simulated transaction shape. The
    /// re-simulation outputs are applied to the transaction here so the caller
    /// does not have to duplicate the hand-assembly logic.
    ///
    /// - Parameters:
    ///   - hostFunction: Host function executed by the transaction.
    ///   - signedAuthEntries: Auth entries with every collected signature.
    ///   - signedTransaction: Transaction carrying the signed auth entries
    ///     prior to envelope assembly.
    ///   - simulation: The re-simulation response that informs resource fees.
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: ``OZTransactionResult`` describing the on-chain outcome.
    /// - Throws: ``SmartAccountTransactionException`` for any submission or polling failure.
    internal func submitMultiSignerTransaction(
        hostFunction: HostFunctionXDR,
        signedAuthEntries: [SorobanAuthorizationEntryXDR],
        signedTransaction: Transaction,
        simulation: SimulateTransactionResponse,
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> OZTransactionResult {
        let deployer = try await kit.getDeployer()
        let useRelayer = resolveSubmissionMethod(forceMethod: forceMethod) == .relayer

        try OZTransactionOperations.applySimulation(
            simulation: simulation,
            transaction: signedTransaction,
            signedAuthEntries: signedAuthEntries,
            relayerMode: false
        )

        return try await submitOrRelay(
            transaction: signedTransaction,
            hostFunction: hostFunction,
            signedAuthEntries: signedAuthEntries,
            signer: deployer,
            useRelayer: useRelayer,
            emitEvents: true
        )
    }

    /// Funds the connected smart account wallet using Friendbot (testnet only).
    ///
    /// Generates a fresh temporary keypair, funds it via Friendbot, queries its
    /// XLM balance via the native token contract, and transfers the surplus
    /// (balance minus the protocol minimum-balance reserve) to the smart account
    /// contract. Source-account authorization entries from the transfer
    /// simulation are converted to classical Ed25519 `Address` credentials so
    /// the relayer can substitute its own channel accounts for fee sponsoring.
    ///
    /// The conversion uses the classical Stellar Ed25519 signature shape
    /// (`Vec([Map({public_key, signature})])`), NOT the OpenZeppelin AuthPayload
    /// Map written by the smart-account signing path — the temp keypair is a
    /// classical Stellar account, not a smart account.
    ///
    /// - Parameters:
    ///   - nativeTokenContract: Native token contract address (`C…` strkey).
    ///   - forceMethod: Optional submission-method override.
    /// - Returns: Funded amount as a decimal XLM string (for example `"100"` or
    ///   `"12.34567"`). Trailing zeroes in the fractional component are trimmed.
    /// - Throws: ``SmartAccountWalletException/NotConnected``, ``SmartAccountValidationException``,
    ///   ``SmartAccountTransactionException``.
    public func fundWallet(
        nativeTokenContract: String,
        forceMethod: OZSubmissionMethod? = nil
    ) async throws -> String {
        let connected = try kit.requireConnected()
        try requireContractAddress(
            nativeTokenContract,
            fieldName: "nativeTokenContract"
        )

        let tempKeypair = try KeyPair.generateRandomKeyPair()

        let funded = await OZTransactionOperations.fundTestnetAccount(
            accountId: tempKeypair.accountId
        )
        if !funded {
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Friendbot funding failed"
            )
        }

        // why: wait for Friendbot propagation to Soroban RPC state. The
        // Horizon submission confirms in milliseconds but Soroban RPC may not
        // observe the new account ledger entry until the next ledger close
        // (~5 seconds on testnet).
        try await Task.sleep(nanoseconds: 5_000_000_000)

        let tempAccount = try await fetchAccount(accountId: tempKeypair.accountId)

        let reserveStroopsInt64: Int64 =
            Int64(OZConstants.friendbotReserveXlm) * StellarProtocolConstants.stroopsPerXlm

        let balanceArgs: [SCValXDR] = [
            .address(try SCAddressXDR(accountId: tempKeypair.accountId))
        ]
        let balanceInvokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: nativeTokenContract),
            functionName: "balance",
            args: balanceArgs
        )
        let balanceHostFunction = HostFunctionXDR.invokeContract(balanceInvokeArgs)
        let balanceResult = try await simulateAndExtractResult(
            hostFunction: balanceHostFunction
        )

        guard let balanceStroops = OZTransactionOperations.scValToInt64(balanceResult) else {
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Failed to query temp account balance"
            )
        }
        if balanceStroops <= reserveStroopsInt64 {
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Insufficient balance after Friendbot funding"
            )
        }
        let transferStroops: Int64 = balanceStroops - reserveStroopsInt64

        let fromAddress = try SCAddressXDR(accountId: tempKeypair.accountId)
        let toAddress = try SCAddressXDR(contractId: connected.contractId)
        let transferStroopsString = String(transferStroops)
        let functionArgs: [SCValXDR] = [
            .address(fromAddress),
            .address(toAddress),
            try OZTransactionOperations.baseUnitsToI128ScVal(
                transferStroopsString, amount: transferStroopsString)
        ]
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: try SCAddressXDR(contractId: nativeTokenContract),
            functionName: "transfer",
            args: functionArgs
        )
        let hostFunction = HostFunctionXDR.invokeContract(invokeArgs)

        let transferOperation = InvokeHostFunctionOperation(
            hostFunction: hostFunction,
            auth: []
        )
        let transaction = try buildTransaction(
            sourceAccount: tempAccount,
            operations: [transferOperation],
            timeoutSeconds: kit.config.timeoutInSeconds
        )
        let simulation = try await simulate(
            transaction: transaction,
            failureMessagePrefix: "Failed to simulate funding transfer: "
        )
        let simulatedAuthEntries = simulation.sorobanAuth ?? []

        let latestLedger = try await fetchLatestLedger()
        // why: compute the expiration ledger in 64-bit arithmetic and clamp
        // via `UInt32(exactly:)` so a near-`UInt32.max` ledger sequence cannot
        // wrap silently.
        let expirationU64 = UInt64(latestLedger.sequence)
            + UInt64(StellarProtocolConstants.ledgersPerHour)
        guard let expirationLedger = UInt32(exactly: expirationU64) else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "Computed expirationLedger \(expirationU64) overflows UInt32"
            )
        }

        // why: source-account credentials are converted to Address credentials
        // signed by the temp keypair so the relayer can substitute its own
        // channel accounts for fee sponsoring.
        let signedAuthEntries = try await convertAndSignAuthEntries(
            authEntries: simulatedAuthEntries,
            tempKeypair: tempKeypair,
            expirationLedger: expirationLedger
        )

        let tempAccountRefresh = try await fetchAccount(accountId: tempKeypair.accountId)
        let signedOperation = InvokeHostFunctionOperation(
            hostFunction: hostFunction,
            auth: signedAuthEntries
        )
        let signedTransaction = try buildTransaction(
            sourceAccount: tempAccountRefresh,
            operations: [signedOperation],
            timeoutSeconds: kit.config.timeoutInSeconds
        )
        let reSimulation = try await simulate(
            transaction: signedTransaction,
            failureMessagePrefix: "Re-simulation error: "
        )

        try OZTransactionOperations.applySimulation(
            simulation: reSimulation,
            transaction: signedTransaction,
            signedAuthEntries: signedAuthEntries,
            relayerMode: false
        )

        // why: the funding flow does not emit `transactionSigned` /
        // `transactionSubmitted` events because it is an internal helper, not
        // a user-initiated transaction.
        let useRelayer = resolveSubmissionMethod(forceMethod: forceMethod) == .relayer
        let result = try await submitOrRelay(
            transaction: signedTransaction,
            hostFunction: hostFunction,
            signedAuthEntries: signedAuthEntries,
            signer: tempKeypair,
            useRelayer: useRelayer,
            emitEvents: false
        )

        if !result.success {
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Funding transaction failed: \(result.error ?? "unknown error")"
            )
        }

        return OZTransactionOperations.formatXlmAmount(stroops: transferStroops)
    }

    /// Simulates a host function in isolation and returns the parsed `SCValXDR`
    /// result.
    ///
    /// Used by ``fundWallet(nativeTokenContract:forceMethod:)`` to query the
    /// temp keypair's balance, and by other managers that read on-chain state
    /// through simulated host-function calls (for example, context-rule
    /// introspection).
    ///
    /// - Parameter hostFunction: Host function to simulate.
    /// - Returns: The parsed `SCValXDR` returned by the simulation.
    /// - Throws: ``SmartAccountTransactionException`` on simulation failure or when the
    ///   simulation produced no result.
    internal func simulateAndExtractResult(
        hostFunction: HostFunctionXDR
    ) async throws -> SCValXDR {
        let deployer = try await kit.getDeployer()
        let deployerAccount = try await fetchAccount(accountId: deployer.accountId)

        let operation = InvokeHostFunctionOperation(hostFunction: hostFunction)
        let transaction = try buildTransaction(
            sourceAccount: deployerAccount,
            operations: [operation],
            timeoutSeconds: kit.config.timeoutInSeconds
        )

        let simulation = try await simulate(
            transaction: transaction,
            failureMessagePrefix: "Simulation error: "
        )

        guard let firstResult = simulation.results?.first else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "No results returned from simulation"
            )
        }
        guard let parsedValue = firstResult.value else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "No return value in simulation result"
            )
        }
        return parsedValue
    }

    // MARK: - Private helpers

    /// Returns `true` when any auth entry uses source-account credentials. The
    /// relayer Mode 2 (signed-envelope) path is engaged when this returns
    /// `true`; otherwise Mode 1 (host function + auth entries) is used.
    private func shouldUseRelayerMode2(authEntries: [SorobanAuthorizationEntryXDR]) -> Bool {
        for entry in authEntries {
            if case .sourceAccount = entry.credentials {
                return true
            }
        }
        return false
    }

    /// Searches the on-chain context-rule set for an external signer whose key
    /// data ends with the supplied credential id. Used during the auth-entry
    /// signing pass when the credential is not present in local storage.
    private func findKeyDataFromContextRules(
        credentialIdBytes: Data
    ) async throws -> Data {
        let allRules = try await kit.contextRuleManagerProtocol.getAllContextRules(maxScanId: nil)
        for ruleScVal in allRules {
            guard case .map(let mapEntries) = ruleScVal,
                  let mapEntries = mapEntries else {
                continue
            }
            for field in mapEntries {
                guard case .symbol(let key) = field.key, key == ContextRuleField.signers else {
                    continue
                }
                guard case .vec(let signerEntries) = field.val,
                      let signerEntries = signerEntries else {
                    break
                }
                for signerScVal in signerEntries {
                    guard let keyDataBytes = OZTransactionOperations.tryFromContextRuleSignerScVal(signerScVal) else {
                        continue
                    }
                    let prefix = SmartAccountConstants.secp256r1PublicKeySize
                    if keyDataBytes.count > prefix {
                        let suffix = keyDataBytes.suffix(keyDataBytes.count - prefix)
                        if suffix == credentialIdBytes {
                            return keyDataBytes
                        }
                    }
                }
                break
            }
        }

        throw SmartAccountCredentialException.notFound(
            credentialId: credentialIdBytes.base64URLEncodedString()
        )
    }

    /// Attempts to decode an on-chain context-rule signer entry into its raw
    /// `keyData` bytes. Returns `nil` for any ScVal shape that is not a valid
    /// external-signer `Vec([Symbol("External"), Address, Bytes])` triple.
    ///
    /// Single source of truth for the encode-decode pair: the encode side is
    /// ``OZExternalSigner/toScVal()``; this is its decode-side counterpart used
    /// by the on-chain credential-id lookup when local storage is not
    /// authoritative.
    ///
    /// - Parameter signerScVal: A single entry from a context rule's `signers`
    ///   vector.
    /// - Returns: The raw `keyData` bytes when the entry encodes an external
    ///   signer; `nil` otherwise.
    internal static func tryFromContextRuleSignerScVal(_ signerScVal: SCValXDR) -> Data? {
        guard case .vec(let partsOpt) = signerScVal,
              let parts = partsOpt,
              parts.count >= 3 else {
            return nil
        }
        guard case .symbol(let tag) = parts[0], tag == "External" else {
            return nil
        }
        guard case .bytes(let keyDataBytes) = parts[2] else {
            return nil
        }
        return keyDataBytes
    }

    /// Converts the simulation-supplied auth entries for the funding flow into a
    /// shape acceptable to the relayer. Source-account credentials are replaced
    /// with `Address` credentials carrying a fresh nonce and a classical Ed25519
    /// signature over the auth payload; existing `Address` credentials are
    /// re-signed by the temp keypair using the same classical Ed25519 shape.
    ///
    /// The signature shape is `Vec([Map({"public_key", "signature"})])` — the
    /// classical Stellar Ed25519 ScVal used by stock accounts, NOT the smart
    /// account's AuthPayload Map. The two shapes are not interchangeable; using
    /// the AuthPayload Map here would fail the classical Stellar verifier.
    private func convertAndSignAuthEntries(
        authEntries: [SorobanAuthorizationEntryXDR],
        tempKeypair: KeyPair,
        expirationLedger: UInt32
    ) async throws -> [SorobanAuthorizationEntryXDR] {
        var result: [SorobanAuthorizationEntryXDR] = []
        result.reserveCapacity(authEntries.count)

        for entry in authEntries {
            switch entry.credentials {
            case .sourceAccount:
                let nonce = try OZTransactionOperations.generateNonce()
                let payloadHash = try await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
                    entry: entry,
                    nonce: nonce,
                    expirationLedger: expirationLedger,
                    networkPassphrase: kit.config.networkPassphrase
                )
                let signature = Data(tempKeypair.sign([UInt8](payloadHash)))
                let signatureVec = OZTransactionOperations.classicalEd25519SignatureScVal(
                    publicKey: Data(tempKeypair.publicKey.bytes),
                    signature: signature
                )
                let addressCredentials = SorobanAddressCredentialsXDR(
                    address: try SCAddressXDR(accountId: tempKeypair.accountId),
                    nonce: nonce,
                    signatureExpirationLedger: expirationLedger,
                    signature: signatureVec
                )
                result.append(
                    SorobanAuthorizationEntryXDR(
                        credentials: .address(addressCredentials),
                        rootInvocation: entry.rootInvocation
                    )
                )
            case .address(let credentials):
                // Clone the entry via XDR round-trip so the caller's instance is
                // never mutated. Preserve the `.address` arm on write-back.
                let cloned = try OZTransactionOperations.cloneAuthEntry(entry)
                let payloadHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
                    entry: cloned,
                    expirationLedger: expirationLedger,
                    networkPassphrase: kit.config.networkPassphrase
                )
                let signature = Data(tempKeypair.sign([UInt8](payloadHash)))
                let signatureVec = OZTransactionOperations.classicalEd25519SignatureScVal(
                    publicKey: Data(tempKeypair.publicKey.bytes),
                    signature: signature
                )
                var updatedCredentials = credentials
                updatedCredentials.signatureExpirationLedger = expirationLedger
                updatedCredentials.signature = signatureVec
                result.append(
                    SorobanAuthorizationEntryXDR(
                        credentials: .address(updatedCredentials),
                        rootInvocation: cloned.rootInvocation
                    )
                )
            case .addressV2(let credentials):
                // ADDRESS_V2 entries are handled identically to ADDRESS, preserving the V2 arm.
                var cloned = try OZTransactionOperations.cloneAuthEntry(entry)
                let payloadHash = try await OZSmartAccountAuth.buildAuthPayloadHash(
                    entry: cloned,
                    expirationLedger: expirationLedger,
                    networkPassphrase: kit.config.networkPassphrase
                )
                let signature = Data(tempKeypair.sign([UInt8](payloadHash)))
                let signatureVec = OZTransactionOperations.classicalEd25519SignatureScVal(
                    publicKey: Data(tempKeypair.publicKey.bytes),
                    signature: signature
                )
                var updatedCredentials = credentials
                updatedCredentials.signatureExpirationLedger = expirationLedger
                updatedCredentials.signature = signatureVec
                cloned.credentials = .addressV2(updatedCredentials)
                result.append(cloned)
            case .addressWithDelegates:
                // WITH_DELEGATES entries cannot be auto-signed by this funding flow:
                // which signer covers which delegate node is caller policy, not SDK policy.
                // The caller must assemble and sign delegate nodes via
                // SorobanAuthorizationEntryXDR.sign(forAddress:) before submission.
                throw StellarSDKError.invalidArgument(
                    message: "convertAndSignAuthEntries: ADDRESS_WITH_DELEGATES entries " +
                        "cannot be auto-signed by the funding flow. " +
                        "Sign each delegate node via SorobanAuthorizationEntryXDR.sign(forAddress:) before submission."
                )
            }
        }

        return result
    }

    /// Signs the envelope (when required) and submits the transaction via the
    /// relayer or directly to Soroban RPC. Polls the network for confirmation
    /// using the 30-attempt / 3-second cadence required to absorb ledger close
    /// times and brief congestion windows.
    private func submitOrRelay(
        transaction: Transaction,
        hostFunction: HostFunctionXDR,
        signedAuthEntries: [SorobanAuthorizationEntryXDR],
        signer: KeyPair,
        useRelayer: Bool,
        emitEvents: Bool
    ) async throws -> OZTransactionResult {
        let hasSourceAuth = shouldUseRelayerMode2(authEntries: signedAuthEntries)

        // Sign the envelope unless we're forwarding to the relayer in Mode 1.
        // RPC submission and Mode 2 both require a signed envelope.
        if !useRelayer || hasSourceAuth {
            do {
                try transaction.sign(
                    keyPair: signer,
                    network: .custom(passphrase: kit.config.networkPassphrase)
                )
            } catch {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Failed to sign transaction envelope: \(SmartAccountException.messageOf(error) ?? "unknown")",
                    cause: error
                )
            }
        }

        if useRelayer {
            guard let relayer = kit.relayerClient else {
                throw SmartAccountTransactionException.submissionFailed(
                    reason: "Relayer is not configured"
                )
            }
            let relayerResponse: OZRelayerResponse
            if hasSourceAuth {
                let envelope: TransactionEnvelopeXDR
                do {
                    envelope = try transaction.transactionXDR.toEnvelopeXDR()
                } catch {
                    throw SmartAccountTransactionException.submissionFailed(
                        reason: "Failed to build signed envelope: \(SmartAccountException.messageOf(error) ?? "unknown")",
                        cause: error
                    )
                }
                relayerResponse = await relayer.sendXdr(transactionEnvelope: envelope)
            } else {
                relayerResponse = await relayer.send(
                    hostFunction: hostFunction,
                    authEntries: signedAuthEntries
                )
            }

            if emitEvents, let hash = relayerResponse.hash {
                kit.events.emit(
                    .transactionSubmitted(
                        hash: hash,
                        success: relayerResponse.success
                    )
                )
            }

            if relayerResponse.success, let hash = relayerResponse.hash {
                return try await pollForConfirmation(hash: hash)
            }
            return OZTransactionResult(
                success: false,
                error: relayerResponse.error ?? "Relayer submission failed"
            )
        }

        // Direct RPC submission.
        let sendResponse = await kit.sorobanServer.sendTransaction(
            transaction: transaction
        )
        switch sendResponse {
        case .success(let sendResult):
            switch sendResult.status {
            case SendTransactionResponse.STATUS_ERROR:
                return OZTransactionResult(
                    success: false,
                    hash: sendResult.transactionId,
                    error: sendResult.errorResultXdr ?? "Transaction rejected by network"
                )
            case SendTransactionResponse.STATUS_TRY_AGAIN_LATER:
                return OZTransactionResult(
                    success: false,
                    hash: sendResult.transactionId,
                    error: "Network is congested. Try again later."
                )
            case SendTransactionResponse.STATUS_PENDING,
                 SendTransactionResponse.STATUS_DUPLICATE:
                if emitEvents {
                    kit.events.emit(
                        .transactionSubmitted(
                            hash: sendResult.transactionId,
                            success: true
                        )
                    )
                }
                return try await pollForConfirmation(hash: sendResult.transactionId)
            default:
                if emitEvents {
                    kit.events.emit(
                        .transactionSubmitted(
                            hash: sendResult.transactionId,
                            success: true
                        )
                    )
                }
                return try await pollForConfirmation(hash: sendResult.transactionId)
            }
        case .failure(let error):
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Failed to send transaction: \(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Polls Soroban RPC for confirmation using a 30-attempt, 3-second cadence
    /// (90-second wall-clock budget) that accommodates ledger close times and
    /// brief congestion windows.
    private func pollForConfirmation(hash: String) async throws -> OZTransactionResult {
        let response = await kit.sorobanServer.pollTransaction(
            hash: hash,
            maxAttempts: 30,
            sleepStrategy: { _ in 3.0 }
        )
        switch response {
        case .success(let txResponse):
            switch txResponse.status {
            case GetTransactionResponse.STATUS_SUCCESS:
                let ledger: UInt32? = txResponse.ledger.map { UInt32($0) }
                return OZTransactionResult(success: true, hash: hash, ledger: ledger)
            case GetTransactionResponse.STATUS_FAILED:
                let ledger: UInt32? = txResponse.ledger.map { UInt32($0) }
                return OZTransactionResult(
                    success: false,
                    hash: hash,
                    ledger: ledger,
                    error: txResponse.resultXdr ?? "Transaction failed on-chain"
                )
            case GetTransactionResponse.STATUS_NOT_FOUND:
                return OZTransactionResult(
                    success: false,
                    hash: hash,
                    error: "Transaction not confirmed after 30 polling attempts"
                )
            default:
                return OZTransactionResult(
                    success: false,
                    hash: hash,
                    error: "Unexpected transaction status: \(txResponse.status)"
                )
            }
        case .failure(let error):
            return OZTransactionResult(
                success: false,
                hash: hash,
                error: "Polling failed: \(rpcErrorMessage(error))"
            )
        }
    }

    // MARK: - Static helpers

    /// Maximum number of decimal places accepted by ``amountToBaseUnits(_:decimals:)``.
    ///
    /// `10^38` already exceeds the `i128` range used for token amounts, so a
    /// larger scale could never produce a representable base-units value.
    internal static let maxTokenDecimals: Int = 38

    /// Converts a positive decimal amount string to its base-units representation
    /// scaled by `decimals` decimal places.
    ///
    /// Rejects scientific notation, empty or non-numeric strings, values less than
    /// or equal to zero, and values carrying more fractional digits than `decimals`
    /// allows. Accepted shape: `^[0-9]+(\.[0-9]+)?$` with at most `decimals`
    /// fractional digits and a result greater than zero.
    ///
    /// - Parameters:
    ///   - amount: Positive decimal string (for example `"10"` or `"100.5"`).
    ///   - decimals: The token's decimal scale. Must be in `0...maxTokenDecimals`.
    ///     A value of `0` accepts only integer amounts and rejects any fractional digit.
    /// - Returns: The base-units amount as a non-negative decimal integer string
    ///   with no leading zeros (except the single digit `"0"`).
    /// - Throws: ``SmartAccountValidationException/InvalidAmount`` when the input
    ///   is invalid or out of the `i128` representable range.
    public static func amountToBaseUnits(_ amount: String, decimals: Int) throws -> String {
        if decimals < 0 {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Token decimals must not be negative"
            )
        }
        if decimals > maxTokenDecimals {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Token decimals must not exceed \(maxTokenDecimals)"
            )
        }

        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Amount must not be empty"
            )
        }

        // Strict numeric validation: optional leading sign + digits + optional
        // single dot + digits. Scientific notation is rejected outright;
        // `1e5`-style inputs are not accepted.
        let pattern = "^-?[0-9]+(\\.[0-9]+)?$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Internal amount validator error"
            )
        }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        if regex.firstMatch(in: trimmed, options: [], range: range) == nil {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Amount must be a positive decimal number"
            )
        }

        // Reject negative values.
        if trimmed.hasPrefix("-") {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Amount must be positive"
            )
        }

        // Split into whole and fractional parts.
        let parts = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let wholePart = String(parts[0])
        let fractionPart: String = parts.count > 1 ? String(parts[1]) : ""

        if fractionPart.count > decimals {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Amount has more than \(decimals) fractional digits"
            )
        }

        let paddedFraction = fractionPart.padding(
            toLength: decimals,
            withPad: "0",
            startingAt: 0
        )
        let combined = wholePart + paddedFraction
        // Canonical non-negative integer string in base units (leading zeros removed).
        // The range is validated where the value is encoded as i128.
        let baseUnits = String(combined.drop(while: { $0 == "0" }))
        if baseUnits.isEmpty {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Amount must be greater than zero"
            )
        }
        return baseUnits
    }

    /// Encodes a non-negative integer base-units string as an `i128` `SCValXDR`,
    /// surfacing an out-of-range value as a tagged validation error.
    ///
    /// - Parameters:
    ///   - baseUnits: Amount in the token's base units as a non-negative decimal
    ///     integer string.
    ///   - amount: The original caller-supplied amount, used for error messages.
    internal static func baseUnitsToI128ScVal(_ baseUnits: String, amount: String) throws -> SCValXDR {
        do {
            return try SCValXDR.i128(stringValue: baseUnits)
        } catch {
            throw SmartAccountValidationException.invalidAmount(
                amount: amount,
                reason: "Amount is outside the supported i128 range",
                cause: error
            )
        }
    }

    /// Generates a cryptographically random 64-bit nonce. Reads 8 bytes from
    /// Apple's `SecRandomCopyBytes` and interprets them as a signed Int64 (big
    /// endian).
    ///
    /// - Throws: ``SmartAccountTransactionException/SigningFailed`` when the system CSPRNG
    ///   returns a non-success status; throws rather than returning zero bytes.
    internal static func generateNonce() throws -> Int64 {
        var bytes = [UInt8](repeating: 0, count: 8)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "SecRandomCopyBytes failed with OSStatus \(status); refusing to produce a non-random nonce"
            )
        }
        var nonce: Int64 = 0
        for byte in bytes {
            nonce = (nonce &<< 8) | Int64(byte)
        }
        return nonce
    }

    /// Constructs the classical Stellar Ed25519 signature ScVal used by
    /// stock accounts (NOT the OpenZeppelin AuthPayload Map). Shape:
    /// `Vec([Map({"public_key": <bytes>, "signature": <bytes>})])`.
    internal static func classicalEd25519SignatureScVal(
        publicKey: Data,
        signature: Data
    ) -> SCValXDR {
        let mapEntries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("public_key"), val: .bytes(publicKey)),
            SCMapEntryXDR(key: .symbol("signature"), val: .bytes(signature))
        ]
        return .vec([.map(mapEntries)])
    }

    /// Clones a `SorobanAuthorizationEntryXDR` via an XDR round trip so the
    /// caller's instance is never mutated when the funding flow re-signs
    /// existing `Address` credentials.
    internal static func cloneAuthEntry(
        _ entry: SorobanAuthorizationEntryXDR
    ) throws -> SorobanAuthorizationEntryXDR {
        let encoded: [UInt8]
        do {
            encoded = try XDREncoder.encode(entry)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to clone auth entry (encode): \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
        do {
            return try XDRDecoder.decode(SorobanAuthorizationEntryXDR.self, data: encoded)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to clone auth entry (decode): \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
    }

    /// Extracts an `Int64`-fitting balance from an `SCValXDR.i128` value, used
    /// to parse the temp keypair's XLM balance during the funding flow. Returns
    /// `nil` when the supplied ScVal is not an `i128` or when the value does
    /// not fit in `Int64`.
    internal static func scValToInt64(_ scVal: SCValXDR) -> Int64? {
        guard case .i128(let parts) = scVal else {
            return nil
        }
        // Friendbot funds at most a few hundred million XLM (well within Int64
        // range). High-order bits must be zero (positive) or all-ones
        // (negative) for the low bits to fit.
        if parts.hi == 0 {
            if parts.lo > UInt64(Int64.max) {
                return nil
            }
            return Int64(parts.lo)
        }
        if parts.hi == -1 {
            if parts.lo >= UInt64(bitPattern: Int64.min) {
                return Int64(bitPattern: parts.lo)
            }
            return nil
        }
        return nil
    }

    /// Extracts a `UInt32` from an `SCValXDR.u32` value, used to parse a token
    /// contract's `decimals()` return value. Returns `nil` when the supplied
    /// ScVal is not a `u32`.
    internal static func scValToUInt32(_ scVal: SCValXDR) -> UInt32? {
        guard case .u32(let value) = scVal else {
            return nil
        }
        return value
    }

    /// Formats a non-negative stroops amount as a decimal XLM string. Trims
    /// trailing zeroes in the fractional part; suppresses the decimal point
    /// when the amount is a whole number of XLM.
    internal static func formatXlmAmount(stroops: Int64) -> String {
        let stroopsPerXlm: Int64 = StellarProtocolConstants.stroopsPerXlm
        let whole = stroops / stroopsPerXlm
        let fraction = stroops % stroopsPerXlm
        if fraction == 0 {
            return String(whole)
        }
        var fractionString = String(fraction)
        while fractionString.count < 7 {
            fractionString = "0" + fractionString
        }
        while fractionString.hasSuffix("0") {
            fractionString.removeLast()
        }
        return "\(whole).\(fractionString)"
    }

    /// Hand-rolled Friendbot HTTP GET. Returns `true` iff the Friendbot
    /// endpoint responds with a 2xx HTTP status.
    internal static func fundTestnetAccount(accountId: String) async -> Bool {
        guard let escaped = accountId.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ),
        let url = URL(string: "https://friendbot.stellar.org/?addr=\(escaped)") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return (200..<300).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }

    /// Applies the post-simulation outputs to the supplied transaction by
    /// setting auth entries, soroban transaction data, and the final fee.
    /// When `relayerMode` is `true` the transaction fee is set to `minResourceFee`
    /// only so the relayer can wrap the inner transaction with its own fee-bump
    /// without double-counting the classical operation fee.
    internal static func applySimulation(
        simulation: SimulateTransactionResponse,
        transaction: Transaction,
        signedAuthEntries: [SorobanAuthorizationEntryXDR],
        relayerMode: Bool
    ) throws {
        if let data = simulation.transactionData {
            transaction.setSorobanTransactionData(data: data)
        }
        transaction.setSorobanAuth(auth: signedAuthEntries)
        if let minResourceFee = simulation.minResourceFee {
            if relayerMode {
                transaction.setFee(fee: minResourceFee)
            } else {
                transaction.addResourceFee(resourceFee: minResourceFee)
            }
        } else if relayerMode {
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Failed to get min resource fee from simulation"
            )
        }
    }
}

// MARK: - Internal exception-message helper

extension SmartAccountException {

    /// Returns a best-effort message description for an arbitrary error.
    ///
    /// Used by the operations classes when wrapping platform errors into
    /// `SmartAccountException` subclasses; falls back to
    /// `localizedDescription` and then to `String(describing:)`.
    internal static func messageOf(_ error: Error?) -> String? {
        guard let error = error else { return nil }
        if let smartError = error as? SmartAccountException {
            return smartError.message
        }
        let localized = error.localizedDescription
        if !localized.isEmpty {
            return localized
        }
        return String(describing: error)
    }
}
