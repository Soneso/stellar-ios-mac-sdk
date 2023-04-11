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
    let aliceKeyPair = try! KeyPair(secretSeed: "SDU4I7GRJPI7XWGOJDO6WMVSOM3XU57RDBIXY67JOOWERHQT5D2E224V") // GDUG444TELMBAHRJIE2YYPX6MANC4Y442VDFMYYO7DG75BUXXQW4LCTA
    let bobKeyPair = try! KeyPair(secretSeed: "SBR7ELIC7VZVR5KRQCW4PHTVXRCRZKRN4RNSRQJBOA5XHFYEMUNNFEM3") // GDLQG27OQHR6RRNTMMIT7YGLGBFZQRKKSZSRXGMWZFZD6SCFRSY7FIH5
    let atomicSwapContractId = "eeed6390e27c4df75eb8baecc2d059f56f87a72a3796ac99ba65cf1b6368930d"
    let nativeTokenContractId  = "4a1e5322d3fa1525e7acc7282ee9e9006dd38b55fde29aa86da347ed231dba50"
    let catTokenContractId = "75349045d3c3ebd07b1de12a69731c0a69c7411efb6fc48ddc6c7c073b554d0f"
    let swapFunctionName = "swap"
    let incrAllowFunctionName = "incr_allow"
    
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
            let tokenABytes = SCValXDR.bytes(nativeTokenContractId.data(using: .hexadecimal)!)
            let tokenBBytes = SCValXDR.bytes(catTokenContractId.data(using: .hexadecimal)!)
            let amountA = SCValXDR.i128(Int128PartsXDR(lo: 1000, hi: 0))
            let minBForA = SCValXDR.i128(Int128PartsXDR(lo: 4500, hi: 0))
            let amountB = SCValXDR.i128(Int128PartsXDR(lo: 5000, hi: 0))
            let minAForB = SCValXDR.i128(Int128PartsXDR(lo: 950, hi: 0))
            
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
