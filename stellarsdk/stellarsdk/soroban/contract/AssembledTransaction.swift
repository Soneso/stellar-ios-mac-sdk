//
//  AssembledTransaction.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

///
/// The main workhorse of `SorobanClient`. This class is used to wrap a
/// transaction-under-construction and provide high-level interfaces to the most
/// common workflows, while still providing access to low-level stellar-sdk
/// transaction manipulation.
///
/// Most of the time, you will not construct an `AssembledTransaction` directly,
/// but instead receive one as the return value of a `SorobanClient.buildInvokeMethodTx` method.
///
/// Let's look at examples of how to use `AssembledTransaction` for a variety of
/// use-cases:
///
/// #### 1. Simple read call
///
/// Since these only require simulation, you can get the `result` of the call
/// right after constructing your `AssembledTransaction`:
///
///  ```swift
///
/// let clientOptions = ClientOptions(sourceAccountKeyPair: sourceAccountKeyPair,
///                                   contractId: "C123…",
///                                   network: Network.testnet,
///                                   rpcUrl: "https://…")
///
/// let txOptions = AssembledTransactionOptions(clientOptions: clientOptions,
///                                             methodOptions: MethodOptions(),
///                                             method: "myReadMethod",
///                                             arguments: args)
/// let tx = try await AssembledTransaction.build(options: txOptions)
/// let result = try tx.getSimulationData().returnedValue
/// ```
///
///
/// While that looks pretty complicated, most of the time you will use this in
/// conjunction with `SorobanClient`, which simplifies it to:
///
/// ```swift
/// let result = try await client.invokeMethod(name: "myReadMethod", args: args)
/// ```
///
/// #### 2. Simple write call
///
/// For write calls that will be simulated and then sent to the network without
/// further manipulation, only one more step is needed:
///
/// ```swift
/// let tx = try await AssembledTransaction.build(options: txOptions)
/// let response = try await tx.signAndSend()
/// if response.status == GetTransactionResponse.STATUS_SUCCESS {
///     let result = response.resultValue
/// }
/// ```
///
/// If you are using it in conjunction with `SorobanClient`:
///
/// ```swift
/// let result = try await client.invokeMethod(name: "myWriteMethod", args: args)
/// ```
///
/// #### 3. More fine-grained control over transaction construction
///
/// If you need more control over the transaction before simulating it, you can
/// set various `MethodOptions` when constructing your
/// `AssembledTransaction`. With a `SorobanClient`,  this can be passed as an
/// argument when calling `invokeMethod` or `buildInvokeMethodTx` :
///
/// ```swift
/// let methodOptions = MethodOptions(fee: 10000,
///                                   timeoutInSeconds: 20,
///                                   simulate: false)
///
/// let tx = try await client.buildInvokeMethodTx(name: "myWriteMethod",
///                                               args: args,
///                                               methodOptions: methodOptions)
/// ```
///
/// Since we've skipped simulation, we can now edit the `raw` transaction builder and
/// then manually call `simulate`:
///
/// ```swift
/// tx.raw?.setMemo(memo: Memo.text("Hello"))
/// try await tx.simulate()
///
/// ```
///
/// If you need to inspect the simulation later, you can access it with
/// `let data = try tx.getSimulationData()`
///
///  #### 4. Multi-auth workflows
///
///  Soroban, and Stellar in general, allows multiple parties to sign a
///  transaction.
///
///  Let's consider an Atomic Swap contract. Alice wants to give some of her Token
///  A tokens to Bob for some of his Token B tokens.
///
/// ```swift
///  let swapMethodName = "swap"
///  let amountA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))
///  let minBForA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 4500))
///
///  let amountB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5000))
///  let minAForB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 950))
///  let args:[SCValXDR] = [try SCValXDR.address(SCAddressXDR(accountId: aliceId)),
///                         try SCValXDR.address(SCAddressXDR(accountId: bobId)),
///                         try SCValXDR.address(SCAddressXDR(contractId: tokenAContractId)),
///                         try SCValXDR.address(SCAddressXDR(contractId: tokenBContractId)),
///                         amountA,
///                         minBForA,
///                         amountB,
///                         minAForB]
///
/// ```
///
/// Let's say Alice is also going to be the one signing the final transaction
/// envelope, meaning she is the invoker. So your app, she
/// simulates the `swap` call:
///
/// ```swift
/// let tx = try await atomicSwapClient.buildInvokeMethodTx(name: swapMethodName,
///                                                         args: args)
/// ```
/// But your app can't `signAndSend` this right away, because Bob needs to sign
/// it first. You can check this:
///
/// ```swift
/// let whoElseNeedsToSign = try tx.needsNonInvokerSigningBy()
/// ```
///
/// You can verify that `whoElseNeedsToSign` is an array of length `1`,
/// containing only Bob's public key.
///
/// If you have Bob's secret key, you can sign it right away with:
///
/// ```swift
/// let bobsKeyPair = try KeyPair(secretSeed: "S...")
/// try await tx.signAuthEntries(signerKeyPair: bobsKeyPair)
/// ```
/// But if you don't have Bob's private key, and e.g. need to send it to another server for signing,
/// you can provide a callback function for signing the auth entry:
///
/// ```swift
/// let bobPublicKeyKeypair = try KeyPair(accountId: bobsAccountId)
/// try await tx.signAuthEntries(signerKeyPair: bobPublicKeyKeypair, authorizeEntryCallback: { (entry, network) async throws in
///
///        // You can send it to some other server for signing by encoding it as a base64xdr string
///        let base64Entry = entry.xdrEncoded!
///        
///        // send for signing ...
///        // and on the other server you can decode it:
///        var entryToSign = try SorobanAuthorizationEntryXDR.init(fromBase64: base64Entry)
///        
///        // sign it
///        try entryToSign.sign(signer: bobsSecretKeyPair, network: network)
///        
///        // encode as a base64xdr string and send it back
///        let signedBase64Entry = entryToSign.xdrEncoded!
///
///        // here you can now decode it and return it
///        return try SorobanAuthorizationEntryXDR.init(fromBase64: signedBase64Entry)
/// })
/// ```
///
/// To see an even more complicated example, where Alice swaps with Bob but the
/// transaction is invoked by yet another party, check out in the SorobanClientTest.atomicSwapTest()
///
// @unchecked Sendable: Sequential workflow object (build -> simulate -> sign -> send). Single-owner, not shared across threads.
public final class AssembledTransaction: @unchecked Sendable {

    /// Unconstructed transaction envelope that can be modified before simulation.
    public var raw:Transaction?

    /// Whether the transaction has been signed by the source account.
    public var signed:Transaction?

    /// Soroban RPC simulation result containing resource costs, events, and return values.
    public var simulationResponse:SimulateTransactionResponse?

    private var simulationResult:SimulateHostFunctionResult?
    private let server:SorobanServer

    /// Built transaction ready for submission with simulation results and resource limits applied.
    public var tx:Transaction?

    /// Configuration options for transaction assembly including network, contract, and method parameters.
    public let options:AssembledTransactionOptions

    /// Creates a new assembled transaction with specified configuration options.
    public init(options: AssembledTransactionOptions) {
        self.options = options
        self.server = SorobanServer(endpoint: options.clientOptions.rpcUrl)
        self.server.enableLogging = options.enableServerLogging
    }

    /// Builds an assembled transaction for invoking a contract method with automatic simulation.
    public static func build(options:AssembledTransactionOptions) async throws -> AssembledTransaction {

        let invokeContractHostFunction = try InvokeHostFunctionOperation.forInvokingContract(contractId: options.clientOptions.contractId, functionName: options.method, functionArguments: options.arguments ?? [])
        
        return try await AssembledTransaction.buildWithOp(operation: invokeContractHostFunction, options: options)
    }

    /// Builds an assembled transaction from a custom invoke host function operation.
    public static func buildWithOp(operation: InvokeHostFunctionOperation, options:AssembledTransactionOptions) async throws -> AssembledTransaction {
        let aTx = AssembledTransaction(options: options)
        let sourceAccount = try await aTx.getSourceAccount()
        let timeBounds = TimeBounds(minTime: UInt64(Date().timeIntervalSince1970) - 10,
                                    maxTime: UInt64(Date().timeIntervalSince1970) + options.methodOptions.timeoutInSeconds)
        let preconditions = TransactionPreconditions(timeBounds:timeBounds)
        aTx.raw = try Transaction(sourceAccount: sourceAccount, operations: [operation], memo: nil, preconditions: preconditions, maxOperationFee: options.methodOptions.fee)
        if options.methodOptions.simulate {
            try await aTx.simulate()
        }

        return aTx
    }

    /// Simulates the transaction to calculate resource requirements and validate execution.
    public func simulate(restore: Bool? = nil) async throws {
        if tx == nil {
            if raw == nil {
                throw AssembledTransactionError.notYetAssembled(message: "Transaction has not yet been assembled; call 'AssembledTransaction.build' first.")
            }
            tx = raw!
        }
        let shouldRestore = restore ?? options.methodOptions.restore
        simulationResult = nil
        let simRequest = SimulateTransactionRequest(transaction: tx!, authV2: options.methodOptions.authV2)
        let simulationResponseEnum = await server.simulateTransaction(simulateTxRequest: simRequest)
        switch simulationResponseEnum {
        case .success(let response):
            simulationResponse = response
            if let err =  response.error, response.restorePreamble == nil {
                throw AssembledTransactionError.simulationFailed(message: "Simulation failed with error: \(err)")
            }
        case .failure(let error):
            throw error
        }
        if shouldRestore, let restorePreamble = simulationResponse?.restorePreamble {
            if options.clientOptions.sourceAccountKeyPair.privateKey == nil {
                throw AssembledTransactionError.missingPrivateKey(message: "Source account keypair has no private key, but needed for automatic restore.")
            }
            let result = try await restoreFootprint(restorePreamble: restorePreamble)
            if result.status == GetTransactionResponse.STATUS_SUCCESS {
                let sourceAccount = try await getSourceAccount()
                let timeBounds = TimeBounds(minTime: UInt64(Date().timeIntervalSince1970) - 10,
                                            maxTime: UInt64(Date().timeIntervalSince1970) + options.methodOptions.timeoutInSeconds)
                let preconditions = TransactionPreconditions(timeBounds:timeBounds)
                let invokeContractHostFunction = try InvokeHostFunctionOperation.forInvokingContract(contractId: options.clientOptions.contractId, functionName: options.method, functionArguments: options.arguments ?? [])
                
                raw = try Transaction(sourceAccount: sourceAccount, operations: [invokeContractHostFunction], memo: nil, preconditions: preconditions, maxOperationFee: options.methodOptions.fee)
                
                try await simulate()
            }
            let resultXdr = result.resultXdr ?? "not available"
            throw AssembledTransactionError.automaticRestoreFailed(message: "Automatic restore failed! You set 'restore: true' but the attempted restore did not work. Status: \(result.status) , transaction result xdr: \(resultXdr)")
        }
        if let txData = simulationResponse?.transactionData {
            tx?.setSorobanTransactionData(data: txData)
            if let sorobanAuth = simulationResponse?.sorobanAuth {
                tx?.setSorobanAuth(auth: sorobanAuth)
            }
            if let minResourceFee = simulationResponse?.minResourceFee {
                tx?.addResourceFee(resourceFee: minResourceFee)
            }
        }
    }

    /// Restores expired contract state using the restore preamble from simulation.
    public func restoreFootprint(restorePreamble:RestorePreamble) async throws -> GetTransactionResponse {
        let restoreTx = try await AssembledTransaction.buildFootprintRestoreTransaction(options: options, transactionData: restorePreamble.transactionData, fee: restorePreamble.minResourceFee)
        return try await restoreTx.signAndSend()
    }

    /// Signs the transaction with source account and submits it to the network.
    public func signAndSend(sourceAccountKeyPair:KeyPair? = nil, force:Bool = false) async throws -> GetTransactionResponse {
        if signed == nil {
            try sign(sourceAccountKeyPair: sourceAccountKeyPair, force: force)
        }
        return try await send()
    }

    /// Signs the transaction envelope with the source account keypair.
    public func sign(sourceAccountKeyPair:KeyPair? = nil, force:Bool = false) throws {
        if tx == nil {
            throw AssembledTransactionError.notYetSimulated(message: "Transaction has not yet been simulated")
        }
        
        let isReadCall = try isReadCall()
        if !force && isReadCall {
            throw AssembledTransactionError.isReadCall(message: "This is a read call. It requires no signature or sending. Use `force: true` to sign and send anyway.")
        }
        let signerKp = sourceAccountKeyPair ?? options.clientOptions.sourceAccountKeyPair
        if signerKp.privateKey == nil {
            throw AssembledTransactionError.missingPrivateKey(message: "Source account keypair has no private key, but needed for signing.")
        }
        
        let allNeededSigners = try needsNonInvokerSigningBy()
        // Filter out top-level addresses of WITH_DELEGATES entries where every delegate
        // node already carries a signature: the void top-level is the legitimate
        // delegates-only pattern and must not block the send flow.
        let unsatisfiedSigners = allNeededSigners.filter { address in
            !address.starts(with: "C") && !isTopLevelVoidCoveredByDelegates(address: address)
        }
        if !unsatisfiedSigners.isEmpty {
            throw AssembledTransactionError.multipleSignersRequired(message: "Transaction requires signatures from multiple signers. See `needsNonInvokerSigningBy` for details.")
        }

        // clone tx
        guard let transaction = tx else {
            throw AssembledTransactionError.notYetSimulated(message: "Transaction has not yet been simulated")
        }
        let envelopeXdr = try transaction.encodedEnvelope()
        let clonedTx = try Transaction(envelopeXdr: envelopeXdr)
        
        try clonedTx.sign(keyPair: signerKp, network: options.clientOptions.network)
        signed = clonedTx
    }
    
    /// Submits the signed transaction to the network and polls until completion.
    /// Returns the final transaction status including success/failure and return value.
    public func send() async throws -> GetTransactionResponse {
        guard let signedTx = signed else {
            throw AssembledTransactionError.notYetSigned(message: "The transaction has not yet been signed. Run `sign` first, or use `signAndSend` instead.")
        }
        
        let sendTxResponseEnum = await server.sendTransaction(transaction: signedTx)
        switch sendTxResponseEnum {
        case .success(let response):
            if response.status == SendTransactionResponse.STATUS_ERROR {
                let errorResultXdr = response.errorResultXdr ?? "unknown"
                throw AssembledTransactionError.sendFailed(message: "Sent transaction has status ERROR. Transaction result xdr: \(errorResultXdr)")
            }
            return try await pollStatus(transactionId: response.transactionId)
        case .failure(let error):
            throw error
        }

    }

    /// Returns the addresses of every node whose signature is void, across all authorization entries.
    ///
    /// **All three credential arms are supported** (`ADDRESS`, `ADDRESS_V2`,
    /// `ADDRESS_WITH_DELEGATES`). For `WITH_DELEGATES` entries, the top-level address and
    /// every unsigned delegate node (depth-first) are reported individually. A top-level
    /// signature alongside delegates is a legal pattern, so the top-level address is always
    /// included when its signature is void, even when delegates are present.
    ///
    /// **`WITH_DELEGATES` send precheck**: `sign()` and `signAndSend()` treat a
    /// `WITH_DELEGATES` entry as satisfied when every delegate node in the tree carries a
    /// non-void signature, regardless of the void top-level. Do not block the send flow
    /// solely because this method reports the top-level address of a fully-delegate-signed
    /// entry.
    ///
    /// `.sourceAccount` entries are ignored (they carry no explicit signer address).
    ///
    /// - Parameter includeAlreadySigned: When `true`, includes addresses whose signature is
    ///   non-void. Defaults to `false`.
    public func needsNonInvokerSigningBy(includeAlreadySigned: Bool = false) throws -> [String] {
        guard let transaction = tx else {
            throw AssembledTransactionError.notYetSimulated(message: "Transaction has not yet been simulated")
        }
        let ops = transaction.operations
        if ops.isEmpty {
            throw AssembledTransactionError.unexpectedTxType(message: "Unexpected Transaction type; no operations found.")
        }
        var needed: [String] = []
        guard let invokeHostFuncOp = ops.first as? InvokeHostFunctionOperation else {
            return needed
        }
        let authEntries = invokeHostFuncOp.auth
        for entry in authEntries {
            switch entry.credentials {
            case .sourceAccount:
                // Source-account entries do not carry an explicit signer address.
                break
            case .address(let creds), .addressV2(let creds):
                if includeAlreadySigned || creds.signature.type() == SCValType.void.rawValue {
                    if let signer = creds.address.accountId ?? creds.address.contractId {
                        needed.append(signer)
                    }
                }
            case .addressWithDelegates(let withDelegates):
                let creds = withDelegates.addressCredentials
                // Top-level node: always report when void (top-level signature alongside
                // delegates is legal; the caller decides which nodes to sign).
                if includeAlreadySigned || creds.signature.type() == SCValType.void.rawValue {
                    if let signer = creds.address.accountId ?? creds.address.contractId {
                        needed.append(signer)
                    }
                }
                // Delegate nodes: depth-first.
                collectUnsignedDelegates(nodes: withDelegates.delegates, into: &needed, includeAlreadySigned: includeAlreadySigned)
            }
        }
        return needed
    }

    /// Recursively collects the strkey addresses of unsigned (or all, when
    /// `includeAlreadySigned` is true) delegate nodes into `result`.
    private func collectUnsignedDelegates(
        nodes: [SorobanDelegateSignatureXDR],
        into result: inout [String],
        includeAlreadySigned: Bool
    ) {
        for node in nodes {
            if includeAlreadySigned || node.signature.type() == SCValType.void.rawValue {
                if let signer = node.address.accountId ?? node.address.contractId {
                    result.append(signer)
                }
            }
            collectUnsignedDelegates(nodes: node.nestedDelegates, into: &result, includeAlreadySigned: includeAlreadySigned)
        }
    }
    
    /// Determines if this is a read-only call requiring no signatures or network submission.
    /// Returns true if the call has no auth entries and writes no ledger data.
    public func isReadCall() throws -> Bool {
        let res = try getSimulationData()
        let authsCount = res.auth != nil ? res.auth!.count : 0
        let writeLength = res.transactionData.resources.footprint.readWrite.count
        return authsCount == 0 && writeLength == 0
    }
    
    /// Retrieves parsed simulation data including auth entries and return value.
    /// Throws if transaction has not been simulated or simulation failed.
    public func getSimulationData() throws -> SimulateHostFunctionResult {
        if simulationResult != nil {
            return simulationResult!
        }
        guard let simResponse = simulationResponse else {
            throw AssembledTransactionError.notYetSimulated(message: "Transaction has not yet been simulated")
        }
        
        if simResponse.error != nil || simResponse.transactionData == nil {
            if let err = simResponse.error {
                throw AssembledTransactionError.simulationFailed(message: "Transaction simulation failed. Error: \(err)")
            }
            throw AssembledTransactionError.simulationFailed(message: "Transaction simulation failed")
        }
        
        if simResponse.restorePreamble != nil {
            throw AssembledTransactionError.restoreNeeded(message: "You need to restore some contract state before you can invoke this method. You can set `restore` to true in the options in order to automatically restore the contract state when needed.")
        }
        
        var resultValue = SCValXDR.void
        if let results = simResponse.results, results.count > 0, let val = results.first?.value {
            resultValue = val
        }
        simulationResult = SimulateHostFunctionResult(transactionData: simResponse.transactionData!, returnedValue: resultValue, auth: simResponse.sorobanAuth)
        
        return simulationResult!
    }

    /// Signs authorization entries for multi-party transactions using a keypair or callback.
    ///
    /// Handles all three credential arms (`ADDRESS`, `ADDRESS_V2`, `ADDRESS_WITH_DELEGATES`).
    /// The credential arm is preserved on write-back; no arm coercion is performed.
    ///
    /// **Delegate routing**: For `WITH_DELEGATES` entries the signer address is matched
    /// against the top-level address AND every delegate node (depth-first) via the
    /// `forAddress` routing in `SorobanAuthorizationEntryXDR.sign`. When the signer matches
    /// a delegate node, the signature lands in that node; the top-level is left untouched
    /// unless the signer's address also matches the top-level.
    ///
    /// **Skipping policy**: `.sourceAccount` entries are skipped silently; they are
    /// authorized by the transaction-envelope signer, not by auth-entry signing. An entry
    /// whose top-level address and delegate tree both differ from the signer is also silently
    /// skipped (multi-party transactions carry entries for different signers).
    public func signAuthEntries(signerKeyPair: KeyPair, authorizeEntryCallback: ((_ entry: SorobanAuthorizationEntryXDR, _ network: Network) async throws -> SorobanAuthorizationEntryXDR)? = nil, validUntilLedgerSeq: UInt32? = nil) async throws {
        let signerAddress = signerKeyPair.accountId

        guard let transaction = tx else {
            throw AssembledTransactionError.notYetSimulated(message: "Transaction has not yet been simulated")
        }

        var expirationLedger = validUntilLedgerSeq
        if expirationLedger == nil {
            let latestLedgerResponseEnum = await server.getLatestLedger()
            switch latestLedgerResponseEnum {
            case .success(let response):
                expirationLedger = response.sequence + 100
            case .failure(let error):
                throw error
            }
        }

        let ops = transaction.operations
        if ops.isEmpty {
            throw AssembledTransactionError.unexpectedTxType(message: "Unexpected Transaction type; no operations found.")
        }

        guard let invokeHostFuncOp = ops.first as? InvokeHostFunctionOperation else {
            throw AssembledTransactionError.unexpectedTxType(message: "Unexpected Transaction type; no invoke host function operations found.")
        }

        var authEntries = invokeHostFuncOp.auth
        for i in 0..<authEntries.count {
            var entry = authEntries[i]

            switch entry.credentials {
            case .sourceAccount:
                // Source-account entries are authorized by the transaction envelope signer;
                // they carry no explicit address to match against.
                continue

            case .address(let creds):
                guard creds.address.accountId == signerAddress else { continue }
                var updatedCreds = creds
                updatedCreds.signatureExpirationLedger = expirationLedger!
                entry.credentials = .address(updatedCreds)
                if let callback = authorizeEntryCallback {
                    authEntries[i] = try await callback(entry, options.clientOptions.network)
                } else {
                    if signerKeyPair.privateKey == nil {
                        throw AssembledTransactionError.missingPrivateKey(message: "Signer keypair requires private key if no authorization callback provided")
                    }
                    try entry.sign(signer: signerKeyPair, network: options.clientOptions.network)
                    authEntries[i] = entry
                }

            case .addressV2(let creds):
                guard creds.address.accountId == signerAddress else { continue }
                var updatedCreds = creds
                updatedCreds.signatureExpirationLedger = expirationLedger!
                entry.credentials = .addressV2(updatedCreds)
                if let callback = authorizeEntryCallback {
                    authEntries[i] = try await callback(entry, options.clientOptions.network)
                } else {
                    if signerKeyPair.privateKey == nil {
                        throw AssembledTransactionError.missingPrivateKey(message: "Signer keypair requires private key if no authorization callback provided")
                    }
                    try entry.sign(signer: signerKeyPair, network: options.clientOptions.network)
                    authEntries[i] = entry
                }

            case .addressWithDelegates(let withDelegates):
                // Determine whether this signer is relevant to this entry: the signer must
                // match the top-level address or at least one delegate node.
                let topLevelMatches = withDelegates.addressCredentials.address.accountId == signerAddress
                let delegateMatches = delegateTreeContainsAccountId(nodes: withDelegates.delegates, accountId: signerAddress)
                guard topLevelMatches || delegateMatches else { continue }

                // Stamp the expiration on the top-level credentials before signing.
                var updatedCreds = withDelegates.addressCredentials
                updatedCreds.signatureExpirationLedger = expirationLedger!
                let updatedWithDelegates = SorobanAddressCredentialsWithDelegatesXDR(
                    addressCredentials: updatedCreds,
                    delegates: withDelegates.delegates
                )
                entry.credentials = .addressWithDelegates(updatedWithDelegates)

                if let callback = authorizeEntryCallback {
                    authEntries[i] = try await callback(entry, options.clientOptions.network)
                } else {
                    if signerKeyPair.privateKey == nil {
                        throw AssembledTransactionError.missingPrivateKey(message: "Signer keypair requires private key if no authorization callback provided")
                    }
                    // sign(forAddress:) routes the signature into every matching node,
                    // top-level or delegate, depth-first.
                    try entry.sign(signer: signerKeyPair, network: options.clientOptions.network, forAddress: signerAddress)
                    authEntries[i] = entry
                }
            }
        }

        guard let transaction = tx else {
            throw AssembledTransactionError.notYetSimulated(message: "Transaction has not yet been simulated")
        }
        transaction.setSorobanAuth(auth: authEntries)
    }

    /// Returns `true` when a `WITH_DELEGATES` entry's top-level address is void but every
    /// delegate node in the tree carries a non-void signature.
    ///
    /// This is the legitimate delegates-only pattern: the top-level signer opted out and
    /// all delegates have signed. The send precheck must not block on such an entry.
    private func isTopLevelVoidCoveredByDelegates(address: String) -> Bool {
        guard let transaction = tx else { return false }
        guard let invokeHostFuncOp = transaction.operations.first as? InvokeHostFunctionOperation else { return false }

        for entry in invokeHostFuncOp.auth {
            guard case .addressWithDelegates(let withDelegates) = entry.credentials else { continue }
            let creds = withDelegates.addressCredentials
            guard creds.address.accountId == address else { continue }
            // Only applicable when the top-level is void.
            guard creds.signature.type() == SCValType.void.rawValue else { continue }
            // Entry is covered when it has at least one delegate and all are signed.
            if !withDelegates.delegates.isEmpty && allDelegatesSigned(nodes: withDelegates.delegates) {
                return true
            }
        }
        return false
    }

    /// Returns `true` when every delegate node in the tree (depth-first) carries a non-void signature.
    private func allDelegatesSigned(nodes: [SorobanDelegateSignatureXDR]) -> Bool {
        for node in nodes {
            if node.signature.type() == SCValType.void.rawValue { return false }
            if !allDelegatesSigned(nodes: node.nestedDelegates) { return false }
        }
        return true
    }

    /// Returns `true` when any node in the delegate tree has the given account ID.
    private func delegateTreeContainsAccountId(nodes: [SorobanDelegateSignatureXDR], accountId: String) -> Bool {
        for node in nodes {
            if node.address.accountId == accountId { return true }
            if delegateTreeContainsAccountId(nodes: node.nestedDelegates, accountId: accountId) { return true }
        }
        return false
    }
    
    private func pollStatus(transactionId:String) async throws -> GetTransactionResponse {
        var statusResponse:GetTransactionResponse? = nil
        var status = GetTransactionResponse.STATUS_NOT_FOUND
        let waitTime = 3.0
        var waited = 0.0
        while status == GetTransactionResponse.STATUS_NOT_FOUND {
            if waited > Double(options.methodOptions.timeoutInSeconds) {
                throw AssembledTransactionError.pollInterrupted(message: "Interrupted after waiting \(options.methodOptions.timeoutInSeconds) seconds (options->timeoutInSeconds) for the transaction \(transactionId) to complete.")
            }
            try await Task.sleep(nanoseconds: UInt64(waitTime * Double(NSEC_PER_SEC)))
            waited += waitTime
            let statusResponseEnum =  await server.getTransaction(transactionHash: transactionId)
            switch statusResponseEnum {
            case .success(let response):
                statusResponse = response
                status = response.status
            case .failure(let error):
                throw error
            }
        }
        guard let response = statusResponse else {
            throw AssembledTransactionError.pollInterrupted(message: "Failed to get transaction status")
        }
        return response
    }
    
    private static func buildFootprintRestoreTransaction(options:AssembledTransactionOptions, transactionData:SorobanTransactionDataXDR, fee:UInt32) async throws -> AssembledTransaction {
        let restoreTx = AssembledTransaction(options: options)
        let restoreOp = RestoreFootprintOperation()
        let sourceAccount = try await restoreTx.getSourceAccount()
        let timeBounds = TimeBounds(minTime: UInt64(Date().timeIntervalSince1970) - 10,
                                    maxTime: UInt64(Date().timeIntervalSince1970) + restoreTx.options.methodOptions.timeoutInSeconds)
        let preconditions = TransactionPreconditions(timeBounds:timeBounds)
        restoreTx.raw = try Transaction(sourceAccount: sourceAccount, operations: [restoreOp], memo: nil, preconditions: preconditions, maxOperationFee: fee)
        restoreTx.tx = restoreTx.raw
        guard let transaction = restoreTx.tx else {
            throw AssembledTransactionError.notYetSimulated(message: "Failed to build restore transaction")
        }
        transaction.setSorobanTransactionData(data: transactionData)
        try await restoreTx.simulate(restore: false)
        return restoreTx
    }
    
    private func getSourceAccount() async throws -> Account {
        let accountResponseEnum = await server.getAccount(accountId: options.clientOptions.sourceAccountKeyPair.accountId)
        switch accountResponseEnum {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
