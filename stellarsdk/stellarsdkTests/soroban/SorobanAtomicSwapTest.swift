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
    
    let sorobanServer = SorobanServer(endpoint: "https://horizon-futurenet.stellar.cash/soroban/rpc")
    let network = Network.futurenet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    let aliceKeyPair = try! KeyPair(secretSeed: "SAAPYAPTTRZMCUZFPG3G66V4ZMHTK4TWA6NS7U4F7Z3IMUD52EK4DDEV") // GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
    let bobKeyPair = try! KeyPair(secretSeed: "SAEZSI6DY7AXJFIYA4PM6SIBNEYYXIEM2MSOTHFGKHDW32MBQ7KVO6EN") // GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
    let atomicSwapContractId = "828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c"
    let nativeTokenContractId  = "d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813"
    let catTokenContractId = "8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67"
    let swapFunctionName = "swap"
    let incrAllowFunctionName = "incr_allow"
    
    var aliceNonce:UInt64?
    var bobNonce:UInt64?
    var invokeTransactionId:String?
    
    var submitterAccount:GetAccountResponse?
    
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
        let expectation = XCTestExpectation(description: "get account response received")
        
        let accountId = submitterKeyPair.accountId
        sorobanServer.getAccount(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accResponse):
                XCTAssertEqual(accountId, accResponse.id)
                self.submitterAccount = accResponse
                expectation.fulfill()
            case .failure(let error):
                self.printError(error: error)
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func getNonce(accountId: String) throws {
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
    
    func invokeAtomicSwap() throws {
        
        let expectation = XCTestExpectation(description: "contract successfully invoked")
        
        // See https://soroban.stellar.org/docs/how-to-guides/atomic-swap
        // See https://soroban.stellar.org/docs/learn/authorization
        // See https://github.com/StellarCN/py-stellar-base/blob/soroban/examples/soroban_auth_atomic_swap.py
        
        let addressAlice = Address.accountId(aliceKeyPair.accountId)
        let addressBob = Address.accountId(bobKeyPair.accountId)
        let addressSwapContract = Address.contractId(atomicSwapContractId)
        let tokenABytes = SCValXDR.object(SCObjectXDR.bytes(nativeTokenContractId.data(using: .hexadecimal)!))
        let tokenBBytes = SCValXDR.object(SCObjectXDR.bytes(catTokenContractId.data(using: .hexadecimal)!))
        let amountA = SCValXDR.object(SCObjectXDR.i128(Int128PartsXDR(lo: 1000, hi: 0)))
        let minBForA = SCValXDR.object(SCObjectXDR.i128(Int128PartsXDR(lo: 4500, hi: 0)))
        let amountB = SCValXDR.object(SCObjectXDR.i128(Int128PartsXDR(lo: 5000, hi: 0)))
        let minAForB = SCValXDR.object(SCObjectXDR.i128(Int128PartsXDR(lo: 950, hi: 0)))
        
        let aliceSubAuthArgs:[SCValXDR] = [try SCValXDR(address: addressAlice), try SCValXDR(address: addressSwapContract), amountA]
        let aliceSubAuthInvocation = AuthorizedInvocation(contractId: nativeTokenContractId, functionName: incrAllowFunctionName, args: aliceSubAuthArgs)
        let aliceRootAuthArgs:[SCValXDR] = [tokenABytes, tokenBBytes, amountA, minBForA]
        let aliceRootInvocation = AuthorizedInvocation(contractId: atomicSwapContractId, functionName: swapFunctionName, args: aliceRootAuthArgs, subInvocations: [aliceSubAuthInvocation])
        
        let bobSubAuthArgs:[SCValXDR] = [try SCValXDR(address: addressBob), try SCValXDR(address: addressSwapContract), amountB]
        let bobSubAuthInvocation = AuthorizedInvocation(contractId: catTokenContractId, functionName: incrAllowFunctionName, args: bobSubAuthArgs)
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
                transaction.setFootprint(footprint: simulateResponse.footprint!)
                try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)

                // check encoding and decoding
                let enveloperXdr = try! transaction.encodedEnvelope()
                let enveloperXdrBack = try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope()
                XCTAssertEqual(enveloperXdr, enveloperXdrBack)
                
                self.sorobanServer.sendTransaction(transaction: transaction) { (response) -> (Void) in
                    switch response {
                    case .success(let sendResponse):
                        XCTAssert(TransactionStatus.PENDING == sendResponse.status)
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
    
    
    func getInvokeTransactionStatus() {
        let expectation = XCTestExpectation(description: "get status of the invoke transaction")
        // wait a couple of seconds before checking the status
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
            self.sorobanServer.getTransactionStatus(transactionHash: self.invokeTransactionId!) { (response) -> (Void) in
                switch response {
                case .success(let statusResponse):
                    if TransactionStatus.SUCCESS == statusResponse.status {
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
