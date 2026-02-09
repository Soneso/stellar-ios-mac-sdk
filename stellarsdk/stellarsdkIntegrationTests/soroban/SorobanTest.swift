//
//  SorobanTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class SorobanTest: XCTestCase {

    static let testOn = "testnet" // "futurenet"
    let sorobanServer = testOn == "testnet" ? SorobanServer(endpoint: "https://soroban-testnet.stellar.org"): SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    var submitterAccount:Account?
    var asset:Asset? = nil
    
    let accountBKeyPair = try! KeyPair.generateRandomKeyPair()

    var wasmContractCode:Data? = nil
    var wasmId:String? = nil
    var contractId:String? = nil
    var createContractFootprint:Footprint? = nil

    override func setUp() async throws {
        try await super.setUp()
    
        sorobanServer.enableLogging = true
        let accountAId = submitterKeyPair.accountId
        let accountBId = accountBKeyPair.accountId
        let asset = ChangeTrustAsset(canonicalForm: "SONESO:" + accountBId)!
        self.asset = asset
        let changeTrustOp = ChangeTrustOperation(sourceAccountId:accountAId, asset:asset, limit: 100000000)
        let payOp = try! PaymentOperation(sourceAccountId: accountBId, destinationAccountId: accountAId, asset: asset, amount: 50000)
        
        var responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: accountAId) : await sdk.accounts.createFutureNetTestAccount(accountId: accountAId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account A: \(accountAId)")
        }
        
        responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: accountBId) : await sdk.accounts.createFutureNetTestAccount(accountId: accountBId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account B: \(accountBId)")
        }
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: accountBId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp, payOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
            try! transaction.sign(keyPair: self.accountBKeyPair, network: self.network)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func testAll() async {
        
        await getHealth()
        await getNetwork()
        await getFeeStats()
        await getVersionInfo()
        await getTransactions()
                
        // test upload contract
        await uploadContractWasm(name: "soroban_hello_world_contract")

        // test create contract from uploaded wasm
        await createContract()
    
        // test get ledger entries
        await getLedgerEntries()
        
        // test contract code loading from soroban
        await loadContractCodeByWasmId()
        await loadContractInfoByWasmId()
        await loadContractCodeByContractId()
        await loadContractInfoByContractId()
        
        // test invoke deployed contract
        await invokeContract()

        // test contract data
        await getContractData()

        // test SAC with asset
        await deploySACWithAsset()
        
        // test restore + extend
        await restoreAndExtendFootprint()
        
        // test transaction error
        await getTransactionStatusError()
        
        // test contract id encoding
        contractIdEncoding()

        
    }
    
    func getHealth() async {
        let response = await sorobanServer.getHealth()
        switch response {
        case .success(let healthResponse):
            XCTAssertEqual(HealthStatus.HEALTHY, healthResponse.status)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func refreshSubmitterAccount() async {
        let accountId = submitterKeyPair.accountId
        let response = await sorobanServer.getAccount(accountId: accountId)
        switch response {
        case .success(let account):
            XCTAssertEqual(accountId, account.accountId)
            self.submitterAccount = account
        case .failure(_):
            XCTFail()
        }
    }
    
    func getNetwork() async {
        let response = await sorobanServer.getNetwork()
        switch response {
        case .success(let networkResponse):
            switch self.network {
            case.testnet:
                XCTAssertEqual("https://friendbot.stellar.org/", networkResponse.friendbotUrl)
                XCTAssertEqual("Test SDF Network ; September 2015", networkResponse.passphrase)
            default:
                XCTAssertEqual("https://friendbot-futurenet.stellar.org/", networkResponse.friendbotUrl)
                XCTAssertEqual("Test SDF Future Network ; October 2022", networkResponse.passphrase)
            }
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func getFeeStats() async {
        let response = await sorobanServer.getFeeStats()
        switch response {
        case .success(let details):
            XCTAssert(details.latestLedger > 0)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func getVersionInfo() async {
        let response = await sorobanServer.getVersionInfo()
        switch response {
        case .success(let details):
            XCTAssert(details.protocolVersion > 20)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func getTransactions() async {
        var latestLedger:Int? = nil
        let latestLedgerResponseEnum = await sorobanServer.getLatestLedger()
        switch latestLedgerResponseEnum {
        case .success(let latestLedgerResponse):
            latestLedger = Int(latestLedgerResponse.sequence)
            // New fields added in RPC v25.0.0
            XCTAssertNotNil(latestLedgerResponse.closeTime)
            XCTAssertFalse(latestLedgerResponse.closeTime!.isEmpty)
            XCTAssertNotNil(latestLedgerResponse.headerXdr)
            XCTAssertFalse(latestLedgerResponse.headerXdr!.isEmpty)
            XCTAssertNotNil(latestLedgerResponse.metadataXdr)
            XCTAssertFalse(latestLedgerResponse.metadataXdr!.isEmpty)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        XCTAssertNotNil(latestLedger)
        
        var cursor:String? = nil
        var transactionsResponseEnum = await sorobanServer.getTransactions(startLedger: latestLedger! - 20, paginationOptions: PaginationOptions(limit:2))
        switch transactionsResponseEnum {
        case .success(let transactionsResponse):
            XCTAssert(transactionsResponse.transactions.count == 2)
            XCTAssertNotNil(transactionsResponse.cursor)
            cursor = transactionsResponse.cursor
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        XCTAssertNotNil(cursor)
        
        transactionsResponseEnum = await sorobanServer.getTransactions(paginationOptions: PaginationOptions(cursor: cursor!, limit:2))
        switch transactionsResponseEnum {
        case .success(let transactionsResponse):
            //XCTAssert(transactionsResponse.transactions.count == 2)
            XCTAssertNotNil(transactionsResponse.cursor)
            cursor = transactionsResponse.cursor
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func restoreAndExtendFootprint() async {
        // see: https://developers.stellar.org/docs/learn/smart-contract-internals/state-archival
        // test restore
        await restoreContractCodeFootprint(fileName: "soroban_hello_world_contract")
        // test bump contract code footprint
        await extendContractCodeFootprintTTL(wasmId: self.wasmId!, ledgersToExpire: 10000)
    }
    
    func restoreContractCodeFootprint(fileName:String) async {
        await refreshSubmitterAccount()
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm") else {
            // File not found
            XCTFail()
            return
        }
        let contractCode = FileManager.default.contents(atPath: path)
        let uploadOperation = try! InvokeHostFunctionOperation.forUploadingContractWasm(contractCode: contractCode!)
        
        var transaction = try! Transaction(sourceAccount: submitterAccount!,
                                           operations: [uploadOperation], memo: Memo.none)
        
        var simulateTxResponse:SimulateTransactionResponse? = nil
        var simulateTxRequest = SimulateTransactionRequest(transaction: transaction);
        var simulateTxResonseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
        switch simulateTxResonseEnum {
        case .success(let response):
            simulateTxResponse = response
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        XCTAssertNotNil(simulateTxResponse)
        XCTAssertNotNil(simulateTxResponse!.transactionData)
        XCTAssertNotNil(simulateTxResponse!.minResourceFee)
        
        // restore only if necessary
        if (simulateTxResponse?.restorePreamble == nil) {
            //return
        }
        
        let restoreFootprintOperation = RestoreFootprintOperation()
        
        // every time we build a transaction with the source account it increments the sequence number
        // so we decrement it now so we do not have to reload it
        self.submitterAccount!.decrementSequenceNumber()
        transaction = try! Transaction(sourceAccount: self.submitterAccount!,
                                           operations: [restoreFootprintOperation], memo: Memo.none)
        
        var transactionData = simulateTxResponse!.transactionData!
        transaction.setSorobanTransactionData(data: transactionData)
        transaction.addResourceFee(resourceFee: simulateTxResponse!.minResourceFee!)
        
        // simulate first to obtain the transaction data + resource fee
        simulateTxRequest = SimulateTransactionRequest(transaction: transaction);
        simulateTxResonseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
        switch simulateTxResonseEnum {
        case .success(let response):
            simulateTxResponse = response
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        XCTAssertNotNil(simulateTxResponse)
        XCTAssertNotNil(simulateTxResponse!.transactionData)
        XCTAssertNotNil(simulateTxResponse!.minResourceFee)
        
        transactionData = simulateTxResponse!.transactionData!
        transaction.setSorobanTransactionData(data: transactionData)
        transaction.addResourceFee(resourceFee: simulateTxResponse!.minResourceFee!)
        
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var restoreTransactionId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            restoreTransactionId = response.transactionId
            XCTAssertNotNil(restoreTransactionId) // we need this to check success status later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        await checkTransactionStatusSuccess(transactionId: restoreTransactionId!, delaySec: 10.0)
        await getTransactionDetails(transactionHash: restoreTransactionId!, type:"restore_footprint", delaySec: 10.0)
    }
    
    func uploadContractWasm(name:String) async {

        await refreshSubmitterAccount()

        guard let path = Bundle.module.path(forResource: name, ofType: "wasm") else {
            // File not found
            XCTFail()
            return
        }
        let contractCode = FileManager.default.contents(atPath: path)
        self.wasmContractCode = contractCode
        let installOperation = try! InvokeHostFunctionOperation.forUploadingContractWasm(contractCode: contractCode!)
        
        let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                           operations: [installOperation], memo: Memo.none)
        
        let simulateTxRequest = SimulateTransactionRequest(transaction: transaction)
        var simulateTxResponse:SimulateTransactionResponse? = nil
        let simulateTxResponseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
        switch simulateTxResponseEnum {
        case .success(let simulateResponse):
            simulateTxResponse = simulateResponse
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        XCTAssertNotNil(simulateTxResponse)
        let simulateResponse = simulateTxResponse!

        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        if (simulateResponse.restorePreamble != nil) {
            // restore first if needed
            await restoreContractCodeFootprint(fileName: name)
            await uploadContractWasm(name: name)
            return
        }
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var uploadTransactionId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            uploadTransactionId = response.transactionId
            XCTAssertNotNil(uploadTransactionId) //we need it to check success later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: uploadTransactionId!)
        switch txResultEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
            self.wasmId = statusResponse.wasmId
            XCTAssertNotNil(self.wasmId)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        await getTransactionDetails(transactionHash: uploadTransactionId!, type:"HostFunctionTypeHostFunctionTypeUploadContractWasm", delaySec: 10.0)
    }
    
    func checkTransactionStatusSuccess(transactionId: String, delaySec:Double) async {
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(delaySec * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: transactionId)
        switch txResultEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func extendContractCodeFootprintTTL(wasmId: String, ledgersToExpire: UInt32) async {
        await refreshSubmitterAccount()
        let extendOperation = ExtendFootprintTTLOperation(ledgersToExpire: ledgersToExpire)
        
        let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                           operations: [extendOperation], memo: Memo.none)
        
        
        let ledgerKeyContractCode = LedgerKeyContractCodeXDR(wasmId:wasmId)
        let codeKey = LedgerKeyXDR.contractCode(ledgerKeyContractCode)
        let footprint = LedgerFootprintXDR(readOnly: [codeKey], readWrite: [])
        let ressources = SorobanResourcesXDR(footprint: footprint)
        let transactionData = SorobanTransactionDataXDR(resources: ressources)
        
        transaction.setSorobanTransactionData(data: transactionData)
        
        // simulate first to obtain the transaction data + resource fee
        let simulateTxRequest = SimulateTransactionRequest(transaction: transaction)
        var simulateTxResponse:SimulateTransactionResponse? = nil
        let simulateTxResponseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
        switch simulateTxResponseEnum {
        case .success(let simulateResponse):
            simulateTxResponse = simulateResponse
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        XCTAssertNotNil(simulateTxResponse)
        XCTAssertNotNil(simulateTxResponse!.transactionData)
        XCTAssertNotNil(simulateTxResponse!.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateTxResponse!.transactionData!)
        transaction.addResourceFee(resourceFee: simulateTxResponse!.minResourceFee!)
       
        
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var bumpTransactionId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            bumpTransactionId = response.transactionId
            XCTAssertNotNil(bumpTransactionId) // we need this to check success status later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        await checkTransactionStatusSuccess(transactionId: bumpTransactionId!, delaySec: 10.0)
        // this is currently not testable because horizon returns status 500
        // await getTransactionDetails(transactionHash: bumpTransactionId!, type:"bump_footprint_expiration", delaySec: 10.0)
    }
    
    func getTransactionDetails(transactionHash:String, type:String, delaySec:Double) async {
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(delaySec * Double(NSEC_PER_SEC)))

        let txDetailsResponseEnum = await sdk.transactions.getTransactionDetails(transactionHash: transactionHash)
        switch txDetailsResponseEnum {
        case .success(let details):
            XCTAssert(details.operationCount == 1)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionDetails", horizonRequestError: error)
            XCTFail()
        }
        
        let opDetailsResponseEnum = await sdk.operations.getOperations(forTransaction: transactionHash, includeFailed:true)
        switch opDetailsResponseEnum {
        case .success(let response):
            XCTAssert(response.records.count > 0)
            if let op = response.records.first! as? InvokeHostFunctionOperationResponse {
                XCTAssertEqual(op.function, type)
            } else if let op = response.records.first! as? RestoreFootprintOperationResponse {
                XCTAssertEqual(op.operationTypeString, type)
            } else if let op = response.records.first! as? ExtendFootprintTTLOperationResponse {
                XCTAssertEqual(op.operationTypeString, type)
            } else {
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionDetails", horizonRequestError: error)
            XCTFail()
        }
    }

    func getTransactionStatusError() async {
        let txResponseEnum = await sorobanServer.getTransaction(transactionHash: "8a6ec76ec8e41b839e7e2df2a5478d5fbf96e5cb0553c86ba1baef6ac1feaa94")
        switch txResponseEnum {
        case .success(let response):
            XCTAssertEqual(GetTransactionResponse.STATUS_NOT_FOUND, response.status)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func createContract() async {
        await refreshSubmitterAccount()
        let createOperation = try! InvokeHostFunctionOperation.forCreatingContract(wasmId: self.wasmId!, address: SCAddressXDR(accountId: submitterAccount!.accountId))
        
        let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                           operations: [createOperation], memo: Memo.none)
        
        let simulateTxRequest = SimulateTransactionRequest(transaction: transaction)
        var simulateTxResponse:SimulateTransactionResponse? = nil
        let simulateTxResponseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
        switch simulateTxResponseEnum {
        case .success(let simulateResponse):
            simulateTxResponse = simulateResponse
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        XCTAssertNotNil(simulateTxResponse)
        let simulateResponse = simulateTxResponse!

        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        self.createContractFootprint = simulateResponse.footprint
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth)
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var createTransactionId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            createTransactionId = response.transactionId
            XCTAssertNotNil(createTransactionId) // we need this to check success status later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: createTransactionId!)
        switch txResultEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
            self.contractId = statusResponse.createdContractId
            XCTAssertNotNil(self.contractId)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        await getTransactionDetails(transactionHash: createTransactionId!, type:"HostFunctionTypeHostFunctionTypeCreateContract", delaySec: 10.0)
        
    }

    
    func getLedgerEntries() async {
        let contractCodeKey = createContractFootprint?.contractCodeLedgerKey
        let contractDataKey = createContractFootprint?.contractDataLedgerKey
        var ledgerEntriesResponseEnum = await sorobanServer.getLedgerEntries(base64EncodedKeys:[contractCodeKey!])
        switch ledgerEntriesResponseEnum {
        case .success(let response):
            XCTAssert(Int(exactly: response.latestLedger)! > 0)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        ledgerEntriesResponseEnum = await sorobanServer.getLedgerEntries(base64EncodedKeys:[contractDataKey!])
        switch ledgerEntriesResponseEnum {
        case .success(let ledgerResponse):
            XCTAssert(Int(exactly:ledgerResponse.latestLedger)! > 0)
            XCTAssertNotNil(ledgerResponse.entries.first?.keyXdrValue)
            XCTAssertNotNil(ledgerResponse.entries.first?.valueXdr)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func loadContractCodeByWasmId() async {
        let responseEnum = await sorobanServer.getContractCodeForWasmId(wasmId: self.wasmId!)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.wasmContractCode, response.code)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func loadContractInfoByWasmId() async {
        let responseEnum = await sorobanServer.getContractInfoForWasmId(wasmId: self.wasmId!)
        switch responseEnum {
        case .success(let response):
            XCTAssertTrue(response.specEntries.count > 0)
            XCTAssertTrue(response.metaEntries.count > 0)
        case .rpcFailure(let error):
            self.printError(error: error)
            XCTFail()
        case .parsingFailure (let error):
            self.printParserError(error: error)
            XCTFail()
        }
    }
    
    func loadContractCodeByContractId() async {
        let responseEnum = await sorobanServer.getContractCodeForContractId(contractId: self.contractId!)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(self.wasmContractCode, response.code)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func loadContractInfoByContractId() async {
        let responseEnum = await sorobanServer.getContractInfoForContractId(contractId: self.contractId!)
        switch responseEnum {
        case .success(let response):
            XCTAssertTrue(response.specEntries.count > 0)
            XCTAssertTrue(response.metaEntries.count > 0)
        case .rpcFailure(let error):
            self.printError(error: error)
            XCTFail()
        case .parsingFailure (let error):
            self.printParserError(error: error)
            XCTFail()
        }
    }
    
    func invokeContract() async {
        await refreshSubmitterAccount()
        
        let functionName = "hello"
        let arg = SCValXDR.symbol("friend")
        let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: [arg])
        
        let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                           operations: [invokeOperation], memo: Memo.none)
        
        let simulateTxRequest = SimulateTransactionRequest(transaction: transaction)
        var simulateTxResponse:SimulateTransactionResponse? = nil
        let simulateTxResponseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
        switch simulateTxResponseEnum {
        case .success(let response):
            simulateTxResponse = response
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        let simulateResponse = simulateTxResponse!
        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var invokeTransactionId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            invokeTransactionId = response.transactionId
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let statusResponseEnum = await sorobanServer.getTransaction(transactionHash: invokeTransactionId!)
        switch statusResponseEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
            if let vec = statusResponse.resultValue?.vec, vec.count > 1 {
                print("[" + vec[0].symbol! + "," + vec[1].symbol! + "]")
            }
            if let vec = statusResponse.resultValue?.vec {
                for val in vec {
                    if let sym = val.symbol {
                        print(sym)
                    } else {
                        XCTFail()
                    }
                }
            } else {
                XCTFail()
            }
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        await getTransactionDetails(transactionHash: invokeTransactionId!, type:"HostFunctionTypeHostFunctionTypeInvokeContract", delaySec: 10.0)
    }

    func getContractData() async {
        let responseEnum = await sorobanServer.getContractData(contractId: self.contractId!, key: SCValXDR.ledgerKeyContractInstance,
                                                               durability: ContractDataDurability.persistent)
        switch responseEnum {
        case .success(let response):
            XCTAssert(response.lastModifiedLedgerSeq > 0)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func deploySACWithAsset() async {
        await refreshSubmitterAccount()
        
        let accountId = accountBKeyPair.accountId
        var accountResponse:AccountResponse? = nil
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: accountId)
        switch accDetailsResEnum {
        case .success(let response):
            accountResponse = response
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"deploySACWithAsset()", horizonRequestError: error)
            XCTFail("could not load account B details")
        }
        
        let deployOperation = try! InvokeHostFunctionOperation.forDeploySACWithAsset(asset: self.asset!)
        
        let transaction = try! Transaction(sourceAccount: accountResponse!,
                                           operations: [deployOperation], memo: Memo.none)
        
        let simulateTxRequest = SimulateTransactionRequest(transaction: transaction)
        var simulateTxResponse:SimulateTransactionResponse? = nil
        let simulateTxResponseEnum = await sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest)
        switch simulateTxResponseEnum {
        case .success(let response):
            simulateTxResponse = response
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        let simulateResponse = simulateTxResponse!
        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        try! transaction.sign(keyPair: self.accountBKeyPair, network: self.network)
        
        let deployWithAssetFootprint = simulateResponse.footprint
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var deployWithAssetTransactionId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            deployWithAssetTransactionId = response.transactionId
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let statusResponseEnum = await sorobanServer.getTransaction(transactionHash: deployWithAssetTransactionId!)
        switch statusResponseEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        await getTransactionDetails(transactionHash: deployWithAssetTransactionId!,
                                    type:"HostFunctionTypeHostFunctionTypeCreateContract",
                                    delaySec: 10.0)
        
        
        // get ledger entries
        let contractDataKey = deployWithAssetFootprint!.contractDataLedgerKey
        let responseEnum = await sorobanServer.getLedgerEntries(base64EncodedKeys:[contractDataKey!])
        switch responseEnum {
        case .success(let response):
            XCTAssert(Int(exactly: response.latestLedger)! > 0)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func printError(error:SorobanRpcRequestError) {
        switch error {
        case .requestFailed(let message):
            print(message)
        case .errorResponse(let err):
            print(err)
        case .parsingResponseFailed(let message, _):
            print(message)
        }
    }
    
    func printParserError(error:SorobanContractParserError) {
        switch error {
        case .invalidByteCode:
            print("Parsing faild: invalid byte code")
        case .environmentMetaNotFound:
            print("Parsing faild: env meta not found ")
        case .specEntriesNotFound:
            print("Parsing faild: spec entries not found ")
        }
    }
    
    func contractIdEncoding() {
        let contractIdA = "86efd9a9d6fbf70297294772c9676127e16a23c2141cab3e29be836bb537a9b9";
        let strEncodedA = "CCDO7WNJ2357OAUXFFDXFSLHMET6C2RDYIKBZKZ6FG7IG25VG6U3SLHT";
        let strEncodedB = try! contractIdA.encodeContractIdHex();
        XCTAssertEqual(strEncodedA, strEncodedB)
        
        let contractIdB = try! strEncodedB.decodeContractIdToHex();
        XCTAssertEqual(contractIdA, contractIdB)
    }
}
