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

    var sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org") // SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    var sdk = StellarSDK.testNet() // StellarSDK.futureNet()
    var network = Network.testnet // Network.futurenet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    let accountBKeyPair = try! KeyPair.generateRandomKeyPair()
    var uploadTransactionId:String? = nil
    var wasmContractCode:Data? = nil
    var restoreTransactionId:String? = nil
    var bumpTransactionId:String? = nil
    var wasmId:String? = nil
    var uploadContractWasmFootprint:Footprint? = nil
    var createTransactionId:String? = nil
    var contractId:String? = nil
    var createContractFootprint:Footprint? = nil
    var invokeTransactionId:String? = nil
    var invokeContractFootprint:Footprint? = nil
    var deploySATransactionId:String? = nil
    var deploySAFootprint:Footprint? = nil
    var asset:Asset? = nil
    var deployWithAssetTransactionId:String? = nil
    var deployWithAssetFootprint:Footprint? = nil
    var submitterAccount:Account?
    
    override func setUp() async throws {
        try await super.setUp()
    
        sorobanServer.enableLogging = true
        let accountAId = submitterKeyPair.accountId
        let accountBId = accountBKeyPair.accountId
        let asset = ChangeTrustAsset(canonicalForm: "SONESO:" + accountBId)!
        self.asset = asset
        let changeTrustOp = ChangeTrustOperation(sourceAccountId:accountAId, asset:asset, limit: 100000000)
        let payOp = try! PaymentOperation(sourceAccountId: accountBId, destinationAccountId: accountAId, asset: asset, amount: 50000)
        
     
        var responseEnum = await sdk.accounts.createTestAccount(accountId: accountAId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account A: \(accountAId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: accountBId)
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
        
        await refreshSubmitterAccount()
        
        // test restore contract code footprint
        // see: https://developers.stellar.org/docs/learn/smart-contract-internals/state-archival
        await restoreContractCodeFootprint(fileName: "soroban_hello_world_contract")
        await checkTransactionStatusSuccess(transactionId: self.restoreTransactionId!, delaySec: 10.0)
        await getTransactionDetails(transactionHash: self.restoreTransactionId!, type:"restore_footprint", delaySec: 10.0)
        
        // test upload contract
        await refreshSubmitterAccount()
        await uploadContractWasm(name: "soroban_hello_world_contract")
        await getTransactionDetails(transactionHash: self.uploadTransactionId!, type:"HostFunctionTypeHostFunctionTypeUploadContractWasm", delaySec: 10.0)
                
        // test transaction error
        await getTransactionStatusError()
        
        // test bump contract code footprint
        // see: https://developers.stellar.org/docs/learn/smart-contract-internals/state-archival
        await refreshSubmitterAccount()
        await extendContractCodeFootprintTTL(wasmId: self.wasmId!, ledgersToExpire: 10000)
        await checkTransactionStatusSuccess(transactionId: self.bumpTransactionId!, delaySec: 10.0)
        // this is currently not testable because horizon returns status 500
        //getTransactionDetails(transactionHash: self.bumpTransactionId!, type:"bump_footprint_expiration")
        

        // test create contract from uploaded wasm
        await refreshSubmitterAccount()
        await createContract()
        await getTransactionDetails(transactionHash: self.createTransactionId!, type:"HostFunctionTypeHostFunctionTypeCreateContract", delaySec: 10.0)
        await getLedgerEntries()
        
        // test contract code loading from soroban
        await loadContractCodeByWasmId()
        await loadContractInfoByWasmId()
        await loadContractCodeByContractId()
        await loadContractInfoByContractId()
        
        // test invoke deployed contract
        await refreshSubmitterAccount()
        await invokeContract()
        await getTransactionDetails(transactionHash: self.invokeTransactionId!, type:"HostFunctionTypeHostFunctionTypeInvokeContract", delaySec: 10.0)
        await getContractData()

        // test SAC with source account
        await refreshSubmitterAccount()
        await deploySACWithSourceAccount()
        await getTransactionDetails(transactionHash: self.deploySATransactionId!, type:"HostFunctionTypeHostFunctionTypeCreateContract", delaySec: 10.0)
        
        // test SAC with asset
        await refreshSubmitterAccount()
        await deploySACWithAsset()
        await getTransactionDetails(transactionHash: self.deployWithAssetTransactionId!, type:"HostFunctionTypeHostFunctionTypeCreateContract", delaySec: 10.0)
        
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
            XCTAssert(transactionsResponse.transactions.count == 2)
            XCTAssertNotNil(transactionsResponse.cursor)
            cursor = transactionsResponse.cursor
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func restoreContractCodeFootprint(fileName:String) async {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: fileName, ofType: "wasm") else {
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
        
        let restoreFootprintOperation = RestoreFootprintOperation()
        
        // every time we build a transaction with the source account it increments the sequence number
        // so we decrement it now so we do not have to reload it
        self.submitterAccount!.decrementSequenceNumber()
        transaction = try! Transaction(sourceAccount: self.submitterAccount!,
                                           operations: [restoreFootprintOperation], memo: Memo.none)
        
        var transactionData = simulateTxResponse!.transactionData!
        transactionData.resources.footprint.readWrite.append(contentsOf:transactionData.resources.footprint.readOnly)
        transactionData.resources.footprint.readOnly = [] // readonly must be empty
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
        transactionData.resources.footprint.readWrite.append(contentsOf:transactionData.resources.footprint.readOnly)
        transactionData.resources.footprint.readOnly = []
        transaction.setSorobanTransactionData(data: transactionData)
        let ressourceFee = simulateTxResponse!.minResourceFee! + 5000
        transaction.addResourceFee(resourceFee: ressourceFee)
        
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            self.restoreTransactionId = response.transactionId
            XCTAssertNotNil(self.restoreTransactionId) // we need this to check success status later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func uploadContractWasm(name:String) async {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: name, ofType: "wasm") else {
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
        if let cost = simulateResponse.cost {
            XCTAssert(Int(cost.cpuInsns)! > 0)
            XCTAssert(Int(cost.memBytes)! > 0)
        }

        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        
        self.uploadContractWasmFootprint = simulateResponse.footprint
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            self.uploadTransactionId = response.transactionId
            XCTAssertNotNil(self.uploadTransactionId) //we need it to check success later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: self.uploadTransactionId!)
        switch txResultEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
            self.wasmId = statusResponse.wasmId
            XCTAssertNotNil(self.wasmId)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
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
        let resourceConfig = ResourceConfig(instructionLeeway: 3000000)
        let simulateTxRequest = SimulateTransactionRequest(transaction: transaction, resourceConfig: resourceConfig)
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
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            self.bumpTransactionId = response.transactionId
            XCTAssertNotNil(self.bumpTransactionId) // we need this to check success status later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
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
        if let cost = simulateResponse.cost {
            XCTAssert(Int(cost.cpuInsns)! > 0)
            XCTAssert(Int(cost.memBytes)! > 0)
        }

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
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            self.createTransactionId = response.transactionId
            XCTAssertNotNil(self.createTransactionId) // we need this to check success status later
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: self.createTransactionId!)
        switch txResultEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
            self.contractId = statusResponse.createdContractId
            XCTAssertNotNil(self.contractId)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
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
        if let cost = simulateResponse.cost {
            XCTAssert(Int(cost.cpuInsns)! > 0)
            XCTAssert(Int(cost.memBytes)! > 0)
        }
        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        self.invokeContractFootprint = simulateResponse.footprint
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            self.invokeTransactionId = response.transactionId
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let statusResponseEnum = await sorobanServer.getTransaction(transactionHash: self.invokeTransactionId!)
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
    
    func deploySACWithSourceAccount() async {
        let deployOperation = try! InvokeHostFunctionOperation.forDeploySACWithSourceAccount(address: SCAddressXDR(accountId: submitterAccount!.accountId))
        
        let transaction = try! Transaction(sourceAccount: submitterAccount!,
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
        if let cost = simulateResponse.cost {
            XCTAssert(Int(cost.cpuInsns)! > 0)
            XCTAssert(Int(cost.memBytes)! > 0)
        }
        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        switch self.network {
        case .futurenet:
            XCTAssertNotNil(simulateResponse.stateChanges)
            let stateChange = simulateResponse.stateChanges!.first
            XCTAssertNotNil(stateChange!.after)
        default:
            break
        }
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth)
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        self.deploySAFootprint = simulateResponse.footprint
        XCTAssertNotNil(self.deploySAFootprint)
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            self.deploySATransactionId = response.transactionId
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let statusResponseEnum = await sorobanServer.getTransaction(transactionHash: self.deploySATransactionId!)
        switch statusResponseEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // get ledger entries
        let contractDataKey = deploySAFootprint!.contractDataLedgerKey
        let responseEnum = await sorobanServer.getLedgerEntries(base64EncodedKeys:[contractDataKey!])
        switch responseEnum {
        case .success(let response):
            XCTAssert(Int(exactly: response.latestLedger)! > 0)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func deploySACWithAsset() async {
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
        if let cost = simulateResponse.cost {
            XCTAssert(Int(cost.cpuInsns)! > 0)
            XCTAssert(Int(cost.memBytes)! > 0)
        }
        XCTAssertNotNil(simulateResponse.results)
        XCTAssert(simulateResponse.results!.count > 0)
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        try! transaction.sign(keyPair: self.accountBKeyPair, network: self.network)
        self.deployWithAssetFootprint = simulateResponse.footprint
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            self.deployWithAssetTransactionId = response.transactionId
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let statusResponseEnum = await sorobanServer.getTransaction(transactionHash: self.deployWithAssetTransactionId!)
        switch statusResponseEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
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
        
        let contractIdB = try! strEncodedB.decodeContractIdHex();
        XCTAssertEqual(contractIdA, contractIdB)
    }
}
