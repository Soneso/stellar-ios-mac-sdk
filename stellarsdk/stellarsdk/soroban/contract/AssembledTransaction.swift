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
public class AssembledTransaction {
    
    public var raw:Transaction?
    public var tx:Transaction?
    public var simulationResponse:SimulateTransactionResponse?
    private var simulationResult:SimulateHostFunctionResult?
    private let server:SorobanServer
    public var signed:Transaction?
    public let options:AssembledTransactionOptions
    
    public init(options: AssembledTransactionOptions) {
        self.options = options
        self.server = SorobanServer(endpoint: options.clientOptions.rpcUrl)
        self.server.enableLogging = options.enableServerLogging
    }
    
    public static func build(options:AssembledTransactionOptions) async throws -> AssembledTransaction {

        let invokeContractHostFunction = try InvokeHostFunctionOperation.forInvokingContract(contractId: options.clientOptions.contractId, functionName: options.method, functionArguments: options.arguments ?? [])
        
        return try await AssembledTransaction.buildWithOp(operation: invokeContractHostFunction, options: options)
    }
    
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
    
    public func simulate(restore:Bool? = nil) async throws {
        if tx == nil {
            if raw == nil {
                throw AssembledTransactionError.notYetAssembled(message: "Transaction has not yet been assembled; call 'AssembledTransaction.build' first.")
            }
            tx = raw!
        }
        let shouldRestore = restore ?? options.methodOptions.restore
        simulationResult = nil
        let simulationResponseEnum = await server.simulateTransaction(simulateTxRequest: SimulateTransactionRequest(transaction: tx!))
        switch simulationResponseEnum {
        case .success(let response):
            simulationResponse = response
            if let err =  response.error, response.restorePreamble == nil {
                throw AssembledTransactionError.simulationFailed(message: "Simulatiuon failed with error: \(err)")
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
    
    public func restoreFootprint(restorePreamble:RestorePreamble) async throws -> GetTransactionResponse {
        let restoreTx = try await AssembledTransaction.buildFootprintRestoreTransaction(options: options, transactionData: restorePreamble.transactionData, fee: restorePreamble.minResourceFee)
        return try await restoreTx.signAndSend()
    }
    
    public func signAndSend(sourceAccountKeyPair:KeyPair? = nil, force:Bool = false) async throws -> GetTransactionResponse {
        if signed == nil {
            try sign(sourceAccountKeyPair: sourceAccountKeyPair, force: force)
        }
        return try await send()
    }
    
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
        var neededAccountSigners:[String] = []
        for signer in allNeededSigners {
            if signer.starts(with: "C") {
                neededAccountSigners.append(signer)
            }
        }
        if !neededAccountSigners.isEmpty {
            throw AssembledTransactionError.multipleSignersRequired(message: "Transaction requires signatures from multiple signers. See `needsNonInvokerSigningBy` for details.")
        }
     
        // clone tx
        let envelopeXdr = try tx!.encodedEnvelope()
        let clonedTx = try Transaction(envelopeXdr: envelopeXdr)
        
        try clonedTx.sign(keyPair: signerKp, network: options.clientOptions.network)
        signed = clonedTx
    }
    
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
    
    public func needsNonInvokerSigningBy(includeAlreadySigned:Bool = false) throws -> [String] {
        guard let transaction = tx else {
            throw AssembledTransactionError.notYetSimulated(message: "Transaction has not yet been simulated")
        }
        let ops = transaction.operations
        if ops.isEmpty {
            throw AssembledTransactionError.unexpectedTxType(message: "Unexpected Transaction type; no operations found.")
        }
        var needed:[String] = []
        guard let invokeHostFuncOp = ops.first! as? InvokeHostFunctionOperation else {
            throw AssembledTransactionError.unexpectedTxType(message: "Unexpected Transaction type; no invoke host function operations found.")
        }
        let authEntries = invokeHostFuncOp.auth
        for entry in authEntries {
            if let addressCredentials = entry.credentials.address {
                if includeAlreadySigned || addressCredentials.signature.type() == SCValType.void.rawValue {
                    if let signer = addressCredentials.address.accountId ?? addressCredentials.address.contractId {
                        needed.append(signer)
                    }
                }
            }
        }
        return needed
    }
    
    public func isReadCall() throws -> Bool {
        let res = try getSimulationData()
        let authsCount = res.auth != nil ? res.auth!.count : 0
        let writeLength = res.transactionData.resources.footprint.readWrite.count
        return authsCount == 0 && writeLength == 0
    }
    
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
    
    public func signAuthEntries(signerKeyPair:KeyPair, authorizeEntryCallback:((_:SorobanAuthorizationEntryXDR, _:Network) async throws -> SorobanAuthorizationEntryXDR)? = nil, validUntilLedgerSeq:UInt32? = nil) async throws {
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
        for i in 0..<authEntries.count{
            var entry = authEntries[i]
            var addressCredentials = entry.credentials.address
            if addressCredentials == nil || addressCredentials?.address.accountId == nil || addressCredentials?.address.accountId != signerAddress {
                continue
            }
            addressCredentials!.signatureExpirationLedger = expirationLedger!
            entry.credentials = SorobanCredentialsXDR.address(addressCredentials!)
            if let callback = authorizeEntryCallback {
                let signed = try await callback(entry, options.clientOptions.network)
                authEntries[i] = signed
            } else {
                if signerKeyPair.privateKey == nil {
                    throw AssembledTransactionError.missingPrivateKey(message: "Signer keypair requires private key if no authorization callback provided")
                }
                try entry.sign(signer: signerKeyPair, network: options.clientOptions.network)
                authEntries[i] = entry
            }
        }
        tx!.setSorobanAuth(auth: authEntries)
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
        return statusResponse!
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
        restoreTx.tx!.setSorobanTransactionData(data: transactionData)
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
