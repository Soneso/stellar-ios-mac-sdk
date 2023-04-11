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

    let sorobanServer = SorobanServer(endpoint: "https://rpc-futurenet.stellar.org:443")
    let sdk = StellarSDK.futureNet()
    let network = Network.futurenet
    var invokerKeyPair = try! KeyPair.generateRandomKeyPair()
    var senderKeyPair = try! KeyPair.generateRandomKeyPair()
    var installTransactionId:String?
    var installWasmId:String?
    var createTransactionId:String?
    var contractId:String?
    var nonce:UInt64?
    var invokeTransactionId:String?
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sorobanServer.enableLogging = true
        sorobanServer.acknowledgeExperimental = true
         
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
        installContractCode()
        getInstallTransactionStatus()
        createContract()
        getCreateTransactionStatus()
        try getNonce()
        try invokeContractAuthAccount() // sender != invoker
        getInvokeTransactionStatus()
        try getNonce()
        try invokeContractAuthInvoker() // sender == invoker
        getInvokeTransactionStatus()
        try getNonce()
        try invokeContractAuthSimAccount() // sender != invoker && auth from simulation
        getInvokeTransactionStatus()
    }
    
    
    func installContractCode() {
        XCTContext.runActivity(named: "installContractCode") { activity in
            let expectation = XCTestExpectation(description: "contract code successfully deployed")
            
            let bundle = Bundle(for: type(of: self))
            guard let path = bundle.path(forResource: "auth", ofType: "wasm") else {
                // File not found
                XCTFail()
                expectation.fulfill()
                return
            }
            let contractCode = FileManager.default.contents(atPath: path)
            let accountId = senderKeyPair.accountId
            sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let installOperation = try! InvokeHostFunctionOperation.forInstallingContractCode(contractCode: contractCode!)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                       operations: [installOperation], memo: Memo.none)
                    
                    self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let simulateResponse):
                            XCTAssertNotNil(simulateResponse.footprint)
                            transaction.setFootprint(footprint: simulateResponse.footprint!)
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
                case .failure(_):
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func getInstallTransactionStatus() {
        XCTContext.runActivity(named: "getInstallTransactionStatus") { activity in
            let expectation = XCTestExpectation(description: "get deployment status of the install transaction")
            
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
            sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let createOperation = try! InvokeHostFunctionOperation.forCreatingContract(wasmId: self.installWasmId!)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                       operations: [createOperation], memo: Memo.none)
                    
                    self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let simulateResponse):
                            XCTAssertNotNil(simulateResponse.footprint)
                            transaction.setFootprint(footprint: simulateResponse.footprint!)
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
                case .failure(_):
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

    func getNonce() throws {
        try XCTContext.runActivity(named: "getNonce") { activity in
            let expectation = XCTestExpectation(description: "get nonce from server for sender and contract")
            try self.sorobanServer.getNonce(accountId:invokerKeyPair.accountId, contractId:self.contractId!) { (response) -> (Void) in
                switch response {
                case .success(let nonce):
                    self.nonce = nonce
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func invokeContractAuthAccount() throws {
        try XCTContext.runActivity(named: "invokeContractAuthAccount") { activity in
            // If sender and invoker use the same account, the submission will fail
            // because in that case we do not need address, nonce and signature in auth or we have to change the footprint - see invokeContractAuthInvoker()
            // See https://discord.com/channels/897514728459468821/1078208197283807305
            
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            let senderId = senderKeyPair.accountId
            let invokerId = invokerKeyPair.accountId
            let functionName = "auth"
            let invokerAddress = Address.accountId(invokerId)
            let args = [try SCValXDR(address:invokerAddress), SCValXDR.u32(3)]
            let rootInvocation = AuthorizedInvocation(contractId: self.contractId!, functionName: functionName, args: args)
            let contractAuth = ContractAuth(address: invokerAddress, nonce: self.nonce!, rootInvocation: rootInvocation)
            try contractAuth.sign(signer: invokerKeyPair, network: Network.futurenet)
            
            sdk.accounts.getAccountDetails(accountId: senderId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: args, auth: [contractAuth])
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                       operations: [invokeOperation], memo: Memo.none)
                    
                    self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let simulateResponse):
                            XCTAssertNotNil(simulateResponse.footprint)
                            transaction.setFootprint(footprint: simulateResponse.footprint!)
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
                case .failure(_):
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func invokeContractAuthInvoker() throws {
       try XCTContext.runActivity(named: "invokeContractAuthInvoker") { activity in
            // see https://soroban.stellar.org/docs/learn/authorization#transaction-invoker
            // If sender and invoker are the same
            // so we should not need its address & nonce in contract auth and no need to sign
            // see https://discord.com/channels/897514728459468821/1078208197283807305
            
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            let invokerId = invokerKeyPair.accountId
            let functionName = "auth"
            let invokerAddress = Address.accountId(invokerId)
            let args = [try SCValXDR(address:invokerAddress), SCValXDR.u32(3)]
            let rootInvocation = AuthorizedInvocation(contractId: self.contractId!, functionName: functionName, args: args)
            let contractAuth = ContractAuth(rootInvocation: rootInvocation)
            
            sdk.accounts.getAccountDetails(accountId: invokerId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: args, auth: [contractAuth])
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                       operations: [invokeOperation], memo: Memo.none)
                    
                    self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let simulateResponse):
                            XCTAssertNotNil(simulateResponse.footprint)
                            transaction.setFootprint(footprint: simulateResponse.footprint!)
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
                case .failure(_):
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 20.0)
        }
            
    }
    
    func invokeContractAuthSimAccount() throws {
        try XCTContext.runActivity(named: "invokeContractAuthSimAccount") { activity in
            // If sender and invoker use the same account, the submission will fail
            // because in that case we do not need address, nonce and signature in auth or we have to change the footprint - see invokeContractAuthInvoker()
            // See https://discord.com/channels/897514728459468821/1078208197283807305
            
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            let senderId = senderKeyPair.accountId
            let invokerId = invokerKeyPair.accountId
            let functionName = "auth"
            let invokerAddress = Address.accountId(invokerId)
            let args = [try SCValXDR(address:invokerAddress), SCValXDR.u32(3)]
            
            sdk.accounts.getAccountDetails(accountId: senderId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: args)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                       operations: [invokeOperation], memo: Memo.none)
                    
                    self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let simulateResponse):
                            XCTAssertNotNil(simulateResponse.footprint)
                            transaction.setFootprint(footprint: simulateResponse.footprint!)
                            
                            XCTAssertNotNil(simulateResponse.auth)
                            if let simAuth = simulateResponse.auth {
                                for nextAuth in simAuth {
                                    try! nextAuth.sign(signer: self.invokerKeyPair, network: Network.futurenet)
                                }
                                try! transaction.setContractAuth(auth: simAuth)
                            }
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
                case .failure(_):
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
                            if let map = statusResponse.resultValue?.map, map.count > 0 {
                                let accId = map[0].key.address?.accountId
                                let val = map[0].val.u32
                                print("{" + accId! + "," + String(val!) + "}")
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
