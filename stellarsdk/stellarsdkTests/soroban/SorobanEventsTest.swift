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

    let sorobanServer = SorobanServer(endpoint: "https://rpc-futurenet.stellar.org:443")
    let sdk = StellarSDK.futureNet()
    let network = Network.futurenet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    var installTransactionId:String? = nil
    var installWasmId:String? = nil
    var uploadContractWasmFootprint:Footprint? = nil
    var createTransactionId:String? = nil
    var contractId:String? = nil
    var createContractFootprint:Footprint? = nil
    var invokeTransactionId:String? = nil
    var invokeContractFootprint:Footprint? = nil
    var submitterAccount:AccountResponse?
    var transactionLedger:Int? = nil
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sorobanServer.enableLogging = true
        sorobanServer.acknowledgeExperimental = true
        let accountAId = submitterKeyPair.accountId

        sdk.accounts.createFutureNetTestAccount(accountId: accountAId) { (response) -> (Void) in
            switch response {
            case .success(_):
                expectation.fulfill()
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testAll() {
        getSubmitterAccount()
        uploadContractWasm(name: "event")
        getUploadTransactionStatus()
        getSubmitterAccount()
        createContract()
        getCreateTransactionStatus()
        getSubmitterAccount()
        invokeContract()
        getInvokeTransactionStatus()
        getTransactionLedger()
        getEvents()
    }
    
    func getSubmitterAccount() {
        XCTContext.runActivity(named: "getSubmitterAccount") { activity in
            let expectation = XCTestExpectation(description: "get account response received")
            
            let accountId = submitterKeyPair.accountId
            sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let accResponse):
                    XCTAssertEqual(accountId, accResponse.accountId)
                    self.submitterAccount = accResponse
                    expectation.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func uploadContractWasm(name:String) {
        XCTContext.runActivity(named: "uploadContractWasm") { activity in
            let expectation = XCTestExpectation(description: "contract code successfully deployed")
            
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
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    self.uploadContractWasmFootprint = simulateResponse.footprint
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    
                    self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let sendResponse):
                            XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                            self.installTransactionId = sendResponse.transactionId
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getUploadTransactionStatus() {
        XCTContext.runActivity(named: "getUploadTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get deployment status of the upload transaction")
            
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.installTransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS == statusResponse.status {
                            self.installWasmId = statusResponse.wasmId
                            XCTAssertNotNil(self.installWasmId)
                        } else {
                            XCTFail()
                        }
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    

    func createContract() {
        XCTContext.runActivity(named: "createContract") { activity in
            let expectation = XCTestExpectation(description: "contract successfully created")
            let createOperation = try! InvokeHostFunctionOperation.forCreatingContract(wasmId: self.installWasmId!)
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [createOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    
                    self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let sendResponse):
                            XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                            self.createTransactionId = sendResponse.transactionId
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getCreateTransactionStatus() {
        XCTContext.runActivity(named: "getCreateTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get status of the create transaction")
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.createTransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS == statusResponse.status {
                            self.contractId = statusResponse.contractId
                            XCTAssertNotNil(self.contractId)
                        } else {
                            XCTFail()
                        }
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            wait(for: [expectation], timeout: 20.0)
        }
    }

    func invokeContract() {
        XCTContext.runActivity(named: "invokeContract") { activity in
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            let functionName = "events"
            let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName)
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [invokeOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    self.invokeContractFootprint = simulateResponse.footprint
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope();
                    XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
                    
                    self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let sendResponse):
                            XCTAssert(SendTransactionResponse.STATUS_ERROR != sendResponse.status)
                            self.invokeTransactionId = sendResponse.transactionId
                        case .failure(let error):
                            self.printError(error: error)
                            XCTFail()
                        }
                        expectation.fulfill()
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getInvokeTransactionStatus() {
        XCTContext.runActivity(named: "getInvokeTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get status of the invoke transaction")
            // wait a couple of seconds before checking the status
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                self.sorobanServer.getTransaction(transactionHash: self.invokeTransactionId!) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        expectation.fulfill()
                    case .failure(let error):
                        self.printError(error: error)
                        XCTFail()
                    }
                    expectation.fulfill()
                }
            })
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getTransactionLedger() {
        XCTContext.runActivity(named: "getTransactionLedger") { activity in
            let expectation = XCTestExpectation(description: "Get transaction ledger")
            sdk.transactions.getTransactionDetails(transactionHash: self.invokeTransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    self.transactionLedger = response.ledger
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactionLedger", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getEvents() {
        XCTContext.runActivity(named: "getEvents") { activity in
            let expectation = XCTestExpectation(description: "successfully get events")
            let ledger = String(self.transactionLedger!)
            let eventFilter = EventFilter(type:"contract", contractIds: [contractId!])
            
            self.sorobanServer.getEvents(startLedger: ledger, eventFilters: [eventFilter]) { (response) -> (Void) in
                switch response {
                case .success(let eventsResponse):
                    XCTAssert(eventsResponse.events.count > 0)
                    XCTAssert(self.contractId! == eventsResponse.events[0].contractId)
                    XCTAssert("AAAADwAAAAdDT1VOVEVSAA==" == eventsResponse.events[0].topic[0])
                    XCTAssert("AAAAAwAAAAE=" == eventsResponse.events[0].value.xdr)
                    expectation.fulfill()
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 20.0)
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
}
