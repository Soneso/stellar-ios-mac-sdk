//
//  SorobanAuthTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SorobanAuthTest: XCTestCase {

    let sorobanServer = SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let sdk = StellarSDK.futureNet()
    let network = Network.futurenet
    var invokerKeyPair = try! KeyPair.generateRandomKeyPair()
    var senderKeyPair = try! KeyPair.generateRandomKeyPair()
    var installTransactionId:String?
    var installWasmId:String?
    var createTransactionId:String?
    var contractId:String?
    var invokeTransactionId:String?
    var senderAccount:AccountResponse?
    var invokerAccount:AccountResponse?
    var latestLedger:UInt32?
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sorobanServer.enableLogging = true
         
        let invokerId = invokerKeyPair.accountId
        let senderId = senderKeyPair.accountId
        
        sdk.accounts.createFutureNetTestAccount(accountId: invokerId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createFutureNetTestAccount(accountId: senderId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        expectation.fulfill()
                    case .failure(_):
                        XCTFail()
                    }
                }
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testAll() throws {
        refreshSenderAccount()
        uploadContractWasm()
        getUploadTransactionStatus()
        refreshSenderAccount()
        createContract()
        getCreateTransactionStatus()

        refreshSenderAccount()
        getLatestLedger()
        invokeContractAuthAccount() // sender != invoker
        getInvokeTransactionStatus()

        refreshInvokerAccount()
        invokeContractAuthInvoker() // sender == invoker
        getInvokeTransactionStatus()
    }
    
    
    func refreshSenderAccount() {
        XCTContext.runActivity(named: "refreshSubmitterAccount") { activity in
            let expectation = XCTestExpectation(description: "current account data received")
            
            let accountId = senderKeyPair.accountId
            sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let accResponse):
                    XCTAssertEqual(accountId, accResponse.accountId)
                    self.senderAccount = accResponse
                    expectation.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func uploadContractWasm() {
        XCTContext.runActivity(named: "uploadContractWasm") { activity in
            let expectation = XCTestExpectation(description: "contract code successfully uploaded")
            
            let bundle = Bundle(for: type(of: self))
            guard let path = bundle.path(forResource: "soroban_auth_contract", ofType: "wasm") else {
                // File not found
                XCTFail()
                expectation.fulfill()
                return
            }
            let contractCode = FileManager.default.contents(atPath: path)
            let installOperation = try! InvokeHostFunctionOperation.forUploadingContractWasm(contractCode: contractCode!)
            
            let transaction = try! Transaction(sourceAccount: senderAccount!,
                                               operations: [installOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    try! transaction.sign(keyPair: self.senderKeyPair, network: self.network)
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
            let accountId = senderKeyPair.accountId
            let createOperation = try! InvokeHostFunctionOperation.forCreatingContract(wasmId: self.installWasmId!, address: SCAddressXDR(accountId: accountId))
            
            let transaction = try! Transaction(sourceAccount: senderAccount!,
                                               operations: [createOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth)
                    try! transaction.sign(keyPair: self.senderKeyPair, network: self.network)
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope();
                    XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
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
                            self.contractId = statusResponse.createdContractId
                            print("Latest ledger:\(self.contractId!)")
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
    
    func getLatestLedger() {
        XCTContext.runActivity(named: "getLatestLedger") { activity in
            let expectation = XCTestExpectation(description: "get latest ledger")
            self.sorobanServer.getLatestLedger() { (response) -> (Void) in
                switch response {
                case .success(let response):
                    self.latestLedger = response.sequence
                    XCTAssertNotNil(self.latestLedger)
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func invokeContractAuthAccount() {
        XCTContext.runActivity(named: "invokeContractAuthAccount") { activity in
            // submitter and invoker are NOT the same
            // we need to sign soroban auth
            
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            let invokerId = invokerKeyPair.accountId
            let functionName = "increment"
            let invokerAddress = try! SCAddressXDR(accountId: invokerId)
            let args = [SCValXDR.address(invokerAddress), SCValXDR.u32(3)]
            
            let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: args)
            
            let transaction = try! Transaction(sourceAccount: senderAccount!,
                                               operations: [invokeOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    
                    // sign auth and set it to the transaction
                    var sorobanAuth = simulateResponse.sorobanAuth!
                    for i in sorobanAuth.indices {
                        try! sorobanAuth[i].sign(signer: self.invokerKeyPair,
                                            network: Network.futurenet,
                                            signatureExpirationLedger: self.latestLedger! + 10)
                    }
                    transaction.setSorobanAuth(auth: sorobanAuth)
                    
                    try! transaction.sign(keyPair: self.senderKeyPair, network: self.network)
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope()
                    let env2 = try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope()
                    XCTAssertEqual(enveloperXdr, env2)
                    
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
    
    func refreshInvokerAccount() {
        XCTContext.runActivity(named: "refreshInvokerAccount") { activity in
            let expectation = XCTestExpectation(description: "current account data received")
            
            let accountId = invokerKeyPair.accountId
            sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let accResponse):
                    XCTAssertEqual(accountId, accResponse.accountId)
                    self.invokerAccount = accResponse
                    expectation.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }

    func invokeContractAuthInvoker() {
        XCTContext.runActivity(named: "invokeContractAuthInvoker") { activity in
            // submitter and invoker are the same
            // no need to sign soroban auth
            
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            let invokerId = invokerKeyPair.accountId
            let functionName = "increment"
            let invokerAddress = try! SCAddressXDR(accountId: invokerId)
            let args = [SCValXDR.address(invokerAddress), SCValXDR.u32(3)]
            
            let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: args)
            
            let transaction = try! Transaction(sourceAccount: invokerAccount!,
                                               operations: [invokeOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    // no need to sign soroban auth
                    transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth!)
                    
                    try! transaction.sign(keyPair: self.invokerKeyPair, network: self.network)
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope()
                    let env2 = try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope()
                    XCTAssertEqual(enveloperXdr, env2)
                    
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
                    case .success(let statusResponse):
                        if GetTransactionResponse.STATUS_SUCCESS == statusResponse.status {
                            if let val = statusResponse.resultValue?.u32,val > 0 {
                                expectation.fulfill()
                            } else {
                                XCTFail()
                            }
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
