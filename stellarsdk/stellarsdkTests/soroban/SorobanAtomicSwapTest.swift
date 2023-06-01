//
//  SorobanAtomicSwapTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.02.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation
import XCTest
import stellarsdk

class SorobanAtomicSwapTest: XCTestCase {
    // See https://soroban.stellar.org/docs/how-to-guides/atomic-swap
    // See https://soroban.stellar.org/docs/learn/authorization
    // See https://github.com/StellarCN/py-stellar-base/blob/soroban/examples/soroban_auth_atomic_swap.py
    
    let sorobanServer = SorobanServer(endpoint: "https://rpc-futurenet.stellar.org:443")
    let sdk = StellarSDK.futureNet()
    let network = Network.futurenet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    let aliceKeyPair = try! KeyPair(secretSeed: "SBFUQ62QHPUZYF76ND4KFANQI4WGP62BN3GZKHTM67XXLBUOERI5R4ZD") // GCCZHIMWV7CNB76WXOVZ7QKU25AQWR6Q25TSCIBJFAOFVXJNXGTZNN6R
    let bobKeyPair = try! KeyPair(secretSeed: "SDLF7VP2MO6XWHJXTTKUUNT63CEFRH3LG5ARYF6WBYSXS4TMRWIBFG5P") // GBH6UHX7VYRG6VZ7GDNYSI6ZSDZGV3GIGQRPPPPLENH3WY7FAZAFROLD
    let atomicSwapContractId = "098fe6de43565b1956454f82c04e7d176c222c9971f5cb24adac193fb132fb23"
    let tokenAId  = "7a2a228956a3586bc009faa033142e7a5deffb607e1a4b4ffa1ef6cd8206e9e1"
    let tokenBId = "116eb3e5c57b77d74abcde25766369ba36df632d28e46880eca087c643a78332"
    let swapFunctionName = "swap"
    let incrAllowFunctionName = "increase_allowance"
    
    var aliceNonce:UInt64?
    var bobNonce:UInt64?
    var invokeTransactionId:String?
    
    var submitterAccount:AccountResponse?
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sorobanServer.enableLogging = true
        sorobanServer.acknowledgeExperimental = true
        StellarSDK.futureNet().accounts.createFutureNetTestAccount(accountId: submitterKeyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                expectation.fulfill()
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testAll() throws {
        getSubmitterAccount()
        try getNonce(accountId: aliceKeyPair.accountId)
        try getNonce(accountId: bobKeyPair.accountId)
        try invokeAtomicSwap()
        getInvokeTransactionStatus()
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
    
    func getNonce(accountId: String) throws {
        try XCTContext.runActivity(named: "getNonce") { activity in
            let expectation = XCTestExpectation(description: "get nonce from server")
            try self.sorobanServer.getNonce(accountId:accountId, contractId:atomicSwapContractId) { (response) -> (Void) in
                switch response {
                case .success(let nonce):
                    if (accountId == self.aliceKeyPair.accountId) {
                        self.aliceNonce = nonce
                    } else if (accountId == self.bobKeyPair.accountId) {
                        self.bobNonce = nonce
                    }
                case .failure(let error):
                    self.printError(error: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func invokeAtomicSwap() throws {
        try XCTContext.runActivity(named: "invokeAtomicSwap") { activity in
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            
            // See https://soroban.stellar.org/docs/how-to-guides/atomic-swap
            // See https://soroban.stellar.org/docs/learn/authorization
            // See https://github.com/StellarCN/py-stellar-base/blob/soroban/examples/soroban_auth_atomic_swap.py
            
            let addressAlice = Address.accountId(aliceKeyPair.accountId)
            let addressBob = Address.accountId(bobKeyPair.accountId)
            let addressSwapContract = Address.contractId(atomicSwapContractId)
            let tokenABytes = SCValXDR.bytes(tokenAId.data(using: .hexadecimal)!)
            let tokenBBytes = SCValXDR.bytes(tokenBId.data(using: .hexadecimal)!)
            let amountA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))
            let minBForA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 4500))
            let amountB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5000))
            let minAForB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 950))
            
            let aliceSubAuthArgs:[SCValXDR] = [try SCValXDR(address: addressAlice), try SCValXDR(address: addressSwapContract), amountA]
            let aliceSubAuthInvocation = AuthorizedInvocation(contractId: tokenAId, functionName: incrAllowFunctionName, args: aliceSubAuthArgs)
            let aliceRootAuthArgs:[SCValXDR] = [tokenABytes, tokenBBytes, amountA, minBForA]
            let aliceRootInvocation = AuthorizedInvocation(contractId: atomicSwapContractId, functionName: swapFunctionName, args: aliceRootAuthArgs, subInvocations: [aliceSubAuthInvocation])
            
            let bobSubAuthArgs:[SCValXDR] = [try SCValXDR(address: addressBob), try SCValXDR(address: addressSwapContract), amountB]
            let bobSubAuthInvocation = AuthorizedInvocation(contractId: tokenBId, functionName: incrAllowFunctionName, args: bobSubAuthArgs)
            let bobRootAuthArgs:[SCValXDR] = [tokenBBytes, tokenABytes, amountB, minAForB]
            let bobRootInvocation = AuthorizedInvocation(contractId: atomicSwapContractId, functionName: swapFunctionName, args: bobRootAuthArgs, subInvocations: [bobSubAuthInvocation])
            
            let aliceContractAuth = ContractAuth(address: addressAlice, nonce: aliceNonce!, rootInvocation: aliceRootInvocation)
            try aliceContractAuth.sign(signer: aliceKeyPair, network: Network.futurenet)
            
            let bobContractAuth = ContractAuth(address: addressBob, nonce: bobNonce!, rootInvocation: bobRootInvocation)
            try bobContractAuth.sign(signer: bobKeyPair, network: Network.futurenet)
            
            let invokeArgs:[SCValXDR] = [try SCValXDR(address: addressAlice),
                                         try SCValXDR(address: addressBob),
                                         tokenABytes,
                                         tokenBBytes,
                                         amountA,
                                         minBForA,
                                         amountB,
                                         minAForB]
            
            let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.atomicSwapContractId,
                                                                                       functionName: self.swapFunctionName,
                                                                                       functionArguments: invokeArgs,
                                                                                       auth: [aliceContractAuth, bobContractAuth])
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [invokeOperation], memo: Memo.none)
            
            self.sorobanServer.simulateTransaction(transaction: transaction) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
                    
                    // check encoding and decoding
                    let enveloperXdr = try! transaction.encodedEnvelope()
                    let enveloperXdrBack = try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope()
                    XCTAssertEqual(enveloperXdr, enveloperXdrBack)
                    
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
                            expectation.fulfill()
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
