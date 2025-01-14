//
//  SorobanEventsTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 01.03.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SorobanEventsTest: XCTestCase {

    var sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org") // SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    var sdk = StellarSDK.testNet() // StellarSDK.futureNet()
    var network = Network.testnet // Network.futurenet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    var uploadTransactionId:String? = nil
    var wasmId:String? = nil
    var uploadContractWasmFootprint:Footprint? = nil
    var createTransactionId:String? = nil
    var contractId:String? = nil
    var createContractFootprint:Footprint? = nil
    var invokeTransactionId:String? = nil
    var submitterAccount:Account?
    var transactionLedger:Int? = nil
    
    override func setUp() async throws {
        try await super.setUp()
        
        sorobanServer.enableLogging = true
        let accountAId = submitterKeyPair.accountId

        // let responseEnum = await sdk.accounts.createFutureNetTestAccount(accountId: accountAId)
        let responseEnum = await sdk.accounts.createTestAccount(accountId: accountAId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account A: \(accountAId)")
        }
    }
    
    func testAll() async {
        await refreshSubmitterAccount()
        await restoreContractCodeFootprint(name: "soroban_events_contract")
        await uploadContractWasm(name: "soroban_events_contract")

        await refreshSubmitterAccount()
        await createContract()

        await refreshSubmitterAccount()
        await invokeContract()
        
        await getTransactionLedger()
        await getEvents()
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
    
    func uploadContractWasm(name:String) async {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: name, ofType: "wasm") else {
            // File not found
            XCTFail()
            return
        }
        let contractCode = FileManager.default.contents(atPath: path)
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
    
    func invokeContract() async {
        
        let functionName = "increment"
        let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName)
        
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
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
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
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: self.invokeTransactionId!)
        switch txResultEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
    }
    
    func getTransactionLedger() async {
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let responseEnum = await sdk.transactions.getTransactionDetails(transactionHash: self.invokeTransactionId!)
        switch responseEnum {
        case .success(let details):
            self.transactionLedger = details.ledger
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionLedger", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getEvents() async {
        let ledger = self.transactionLedger!
        // seams that position of the topic in the filter must match event topics ...
        let topicFilter = TopicFilter(segmentMatchers:["*", SCValXDR.symbol("increment").xdrEncoded!])
        //let topicFilter = TopicFilter(segmentMatchers:[SCValXDR.symbol("COUNTER").xdrEncoded!, "*"])
        let eventFilter = EventFilter(type:"contract", contractIds: [try! contractId!.encodeContractIdHex()], topics: [topicFilter])
        
        let responseEnum = await sorobanServer.getEvents(startLedger: ledger, eventFilters: [eventFilter], paginationOptions: PaginationOptions(limit: 2))
        switch responseEnum {
        case .success(let eventsResponse):
            XCTAssert(eventsResponse.events.count > 0)
            let event = eventsResponse.events.first!
            let cId = try! event.contractId.decodeContractIdHex()
            XCTAssert(self.contractId! == cId)
            XCTAssert("AAAADwAAAAdDT1VOVEVSAA==" == event.topic[0])
            XCTAssert("AAAAAwAAAAE=" == event.value)
            XCTAssert("contract" == event.type)
            XCTAssertTrue(event.inSuccessfulContractCall)
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
    
    func restoreContractCodeFootprint(name:String) async {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: name, ofType: "wasm") else {
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
            try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
            let txResultEnum = await sorobanServer.getTransaction(transactionHash: response.transactionId)
            switch txResultEnum {
            case .success(let statusResponse):
                XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
            case .failure(let error):
                self.printError(error: error)
                XCTFail()
            }
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
}
