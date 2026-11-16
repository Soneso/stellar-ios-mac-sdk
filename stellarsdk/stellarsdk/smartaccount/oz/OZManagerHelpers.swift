//
//  OZManagerHelpers.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Shared helpers used across the OZ smart-account managers and operations.
///
/// Each conformer holds a reference to the kit and routes its RPC traffic
/// (account / ledger fetch, simulation), transaction assembly, credential
/// lookup, and submission routing through these helpers so error-mapping,
/// resource-fee envelopes, and the relayer-vs-direct submission decision line
/// up across the single- and multi-signer flows.
protocol OZManagerHelpers {
    var kit: OZSmartAccountKitProtocol { get }
}

extension OZManagerHelpers {

    /// Maps a Soroban RPC transport error into a human-readable message.
    func rpcErrorMessage(_ error: SorobanRpcRequestError) -> String {
        switch error {
        case .requestFailed(let message):
            return message
        case .errorResponse(let rpcError):
            if let message = rpcError.message, !message.isEmpty {
                return "\(rpcError.code): \(message)"
            }
            return "RPC error \(rpcError.code)"
        case .parsingResponseFailed(let message, _):
            return "Parse failure: \(message)"
        }
    }

    /// Builds the unsigned transaction shape used by the simulate / re-simulate passes.
    ///
    /// Applies `MIN_BASE_FEE`, the operation list, a no-op memo, and a
    /// `TransactionPreconditions` carrying a time-bounds upper limit of
    /// `now + timeoutSeconds`. A `timeoutSeconds` of `0` yields `max_time = 0`,
    /// the Stellar sentinel for "no upper bound".
    func buildTransaction(
        sourceAccount: TransactionAccount,
        operations: [Operation],
        timeoutSeconds: Int
    ) throws -> Transaction {
        let nowSeconds = UInt64(Date().timeIntervalSince1970)
        let maxTime: UInt64 = timeoutSeconds <= 0 ? 0 : nowSeconds + UInt64(timeoutSeconds)
        let timeBounds = TimeBounds(
            minTime: 0,
            maxTime: maxTime
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
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to build transaction: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
    }

    /// Wraps the kit's RPC `simulateTransaction` and lifts transport-level and
    /// simulation-error responses into `SmartAccountTransactionException.SimulationFailed`.
    /// A simulation-error response passes its diagnostic events and the contract error it
    /// reports to the exception; a transport-level failure keeps the RPC error as `cause`.
    ///
    /// Every simulation the kit runs flows through here, so
    /// ``OZSmartAccountConfig/useUpgradedAuth`` decides for the whole kit whether the
    /// RPC records `ADDRESS_V2` or legacy `ADDRESS` credential arms.
    func simulate(
        transaction: Transaction,
        failureMessagePrefix: String
    ) async throws -> SimulateTransactionResponse {
        let request = SimulateTransactionRequest(
            transaction: transaction,
            useUpgradedAuth: kit.config.useUpgradedAuth
        )
        let response = await kit.sorobanServer.simulateTransaction(
            simulateTxRequest: request
        )
        switch response {
        case .success(let simulation):
            if let error = simulation.error {
                throw SmartAccountTransactionException.simulationFailed(
                    reason: "\(failureMessagePrefix)\(error)",
                    diagnosticEventsXdr: simulation.events ?? [],
                    reportedContractError: simulation.reportedContractError()
                )
            }
            return simulation
        case .failure(let error):
            throw SmartAccountTransactionException.simulationFailed(
                reason: "\(failureMessagePrefix)\(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Wraps `SorobanServer.getAccount(accountId:)` and lifts transport-level
    /// failures into `SmartAccountTransactionException.SubmissionFailed`.
    func fetchAccount(accountId: String) async throws -> Account {
        let response = await kit.sorobanServer.getAccount(accountId: accountId)
        switch response {
        case .success(let account):
            return account
        case .failure(let error):
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Failed to fetch account \(accountId): \(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Wraps `SorobanServer.getLatestLedger()` and lifts transport-level
    /// failures into `SmartAccountTransactionException.SubmissionFailed`.
    func fetchLatestLedger() async throws -> GetLatestLedgerResponse {
        let response = await kit.sorobanServer.getLatestLedger()
        switch response {
        case .success(let ledger):
            return ledger
        case .failure(let error):
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Failed to fetch latest ledger: \(rpcErrorMessage(error))",
                cause: error
            )
        }
    }

    /// Prepares one signing operation over the simulated `authEntries` for the smart account
    /// `contractId`. Both signing pipelines call it once, before they ask any signer.
    ///
    /// For each auth entry of the smart account (`ADDRESS` or `ADDRESS_V2` credentials of
    /// its address), validates the signers its invocation tree adds to the wallet
    /// (``requireValidAddedSigners(entry:walletContractId:)``). With at least one such entry,
    /// reads the wallet's instance once and takes the signature expiration from the latest
    /// ledger of that response; otherwise reads the latest ledger alone and makes no
    /// instance read. The pipelines refuse `ADDRESS_WITH_DELEGATES` entries without signing
    /// them, so this pass leaves them out.
    ///
    /// - Parameters:
    ///   - contractId: The connected smart account (`C…`).
    ///   - authEntries: The auth entries of the simulation.
    /// - Returns: The digest scheme of the wallet's code, `nil` without a wallet entry, and
    ///   the signature expiration ledger.
    /// - Throws: ``SmartAccountValidationException`` when an added signer is refused;
    ///   `SmartAccountTransactionException.SigningFailed` when an added signer is malformed
    ///   or the returned entry is not a contract instance;
    ///   `SmartAccountTransactionException.SubmissionFailed` when the RPC reports an error;
    ///   `SmartAccountTransactionException.SimulationFailed` when the latest ledger is not a
    ///   `UInt32` ledger sequence or the expiration overflows `UInt32`.
    func prepareSigningOperation(
        contractId: String,
        authEntries: [SorobanAuthorizationEntryXDR]
    ) async throws -> OZSigningOperationState {
        let walletEntries = authEntries.filter { entry in
            OZSigningOperationState.belongsTo(entry: entry, contractId: contractId)
        }
        for entry in walletEntries {
            try await requireValidAddedSigners(entry: entry, walletContractId: contractId)
        }

        if walletEntries.isEmpty {
            let latestLedger = try await fetchLatestLedger()
            return OZSigningOperationState(
                authDigestScheme: nil,
                expirationLedger: try signatureExpirationLedger(latestLedger: latestLedger.sequence)
            )
        }

        let read = try await readAuthDigestScheme(contractId: contractId)
        return OZSigningOperationState(
            authDigestScheme: read.scheme,
            expirationLedger: try signatureExpirationLedger(latestLedger: read.latestLedger)
        )
    }

    /// Reads the WASM hash the smart account `contractId` runs and maps it to its digest
    /// scheme through ``OZSmartAccountConfig/authDigestScheme(forWasmHashHex:)``.
    ///
    /// One `getLedgerEntries` request for the persistent contract instance entry. A WASM
    /// executable maps through the configured and built-in tables; an external reference, a
    /// Stellar Asset executable or a missing entry signs with
    /// ``OZAuthDigestScheme/legacyConcat``. An RPC error throws and is never read as a
    /// missing entry.
    private func readAuthDigestScheme(
        contractId: String
    ) async throws -> (scheme: OZAuthDigestScheme, latestLedger: UInt32) {
        let ledgerKey = try OZTransactionOperations.contractInstanceLedgerKey(contractId: contractId)
        let response: GetLedgerEntriesResponse
        switch await kit.sorobanServer.getLedgerEntries(base64EncodedKeys: [ledgerKey]) {
        case .success(let entries):
            response = entries
        case .failure(let error):
            throw SmartAccountTransactionException.submissionFailed(
                reason: "Failed to read the instance of \(contractId) to select its auth digest scheme: \(rpcErrorMessage(error))",
                cause: error
            )
        }

        // why: validate before any widening or addition, so a negative or oversized value
        // from the RPC never reaches the expiration arithmetic.
        guard let latestLedger = UInt32(exactly: response.latestLedger) else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "Latest ledger \(response.latestLedger) of the instance read of \(contractId) is not a UInt32 ledger sequence"
            )
        }

        guard let entry = response.entries.first else {
            return (scheme: .legacyConcat, latestLedger: latestLedger)
        }

        let data: LedgerEntryDataXDR
        do {
            data = try LedgerEntryDataXDR(fromBase64: entry.xdr)
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to decode the instance entry of \(contractId) to read its code: \(SmartAccountException.messageOf(error) ?? "unknown")",
                cause: error
            )
        }
        guard let instance = data.contractData?.val.contractInstance else {
            let entryType = LedgerEntryType(rawValue: data.type())?.enumName() ?? String(data.type())
            throw SmartAccountTransactionException.signingFailed(
                reason: "The instance entry of \(contractId) is not a contract instance (\(entryType))"
            )
        }

        // Only a WASM executable carries a hash; an external reference and the Stellar Asset
        // executable do not.
        guard case .wasm(let wasmHash) = instance.executable else {
            return (scheme: .legacyConcat, latestLedger: latestLedger)
        }
        let scheme = kit.config.authDigestScheme(forWasmHashHex: wasmHash.wrapped.base16EncodedString())
        return (scheme: scheme, latestLedger: latestLedger)
    }

    /// Adds the configured signature expiration window to `latestLedger`.
    ///
    /// - Throws: `SmartAccountTransactionException.SimulationFailed` when the sum overflows
    ///   `UInt32`.
    private func signatureExpirationLedger(latestLedger: UInt32) throws -> UInt32 {
        // why: config validation guarantees the addend is >= 1; the sum is computed in
        // 64-bit arithmetic so a near-`UInt32.max` ledger cannot wrap silently.
        let expirationU64 = UInt64(latestLedger) + UInt64(kit.config.signatureExpirationLedgers)
        guard let expiration = UInt32(exactly: expirationU64) else {
            throw SmartAccountTransactionException.simulationFailed(
                reason: "Computed expirationLedger \(expirationU64) overflows UInt32"
            )
        }
        return expiration
    }

    /// Best-effort credential lookup that returns `nil` instead of throwing.
    func safeGetCredential(credentialId: String) async -> OZStoredCredential? {
        do {
            return try await kit.credentialManagerProtocol.getCredential(
                credentialId: credentialId
            )
        } catch {
            return nil
        }
    }

    /// Resolves the submission method given an optional forced override.
    ///
    /// Priority: forced override > relayer (when configured) > RPC.
    func resolveSubmissionMethod(forceMethod: OZSubmissionMethod?) -> OZSubmissionMethod {
        if let forceMethod = forceMethod {
            return forceMethod
        }
        return kit.relayerClient != nil ? .relayer : .rpc
    }

    /// Routes a host-function submission to the appropriate path: direct
    /// transaction submission when there are no selected signers, otherwise the
    /// multi-signer submission flow.
    func routeSubmission(
        hostFunction: HostFunctionXDR,
        selectedSigners: [OZSelectedSigner],
        forceMethod: OZSubmissionMethod?
    ) async throws -> OZTransactionResult {
        if selectedSigners.isEmpty {
            return try await kit.transactionOperations.submit(
                hostFunction: hostFunction,
                auth: [],
                forceMethod: forceMethod
            )
        }
        return try await kit.multiSignerManager.submitWithMultipleSigners(
            hostFunction: hostFunction,
            selectedSigners: selectedSigners,
            forceMethod: forceMethod
        )
    }
}

/// The state one signing operation signs against, read by
/// ``OZManagerHelpers/prepareSigningOperation(contractId:authEntries:)`` before any signer is
/// asked.
struct OZSigningOperationState: Sendable {

    /// The digest scheme of the wallet's code, or `nil` when no auth entry belongs to the
    /// wallet and no instance read was made.
    let authDigestScheme: OZAuthDigestScheme?

    /// The ledger at which the signatures expire.
    let expirationLedger: UInt32

    /// Whether the signing pipelines sign `entry` for the smart account `contractId`:
    /// `ADDRESS` or `ADDRESS_V2` credentials of its address.
    static func belongsTo(entry: SorobanAuthorizationEntryXDR, contractId: String) -> Bool {
        switch entry.credentials {
        case .address(let credentials), .addressV2(let credentials):
            return OZAddressStrKey.fromXdr(credentials.address) == contractId
        case .addressWithDelegates, .sourceAccount:
            return false
        }
    }
}
