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
    
    let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
    let sdk = StellarSDK.testNet()
    let network = Network.testnet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    let aliceKeyPair = try! KeyPair(secretSeed: "SAA5STOJXSTYU5EONKI6WCNYXTGRNOZK4Z4KFTMCCQ3YI2WPZPKQPECK") // GDTI4BTSECIIXAUHENKEDTTQBJADZGOJSSPYTTX4H76OQWNLXFM3X4BH
    let bobKeyPair = try! KeyPair(secretSeed: "SAHZ37UVWQJKT4SITMEBXIBF76N2BWHEBX7NJZPHQ3OEKK3NZG3ZZG32") // GA7DGBRT5U4U5AV5V3PC6XPMMGODFKYYIGES27EBQ5RYF2PJ3KYA5XJU
    let atomicSwapContractId = "63b454c1e5fafe65b13f5173fdec557611df29cd21a1882cdec3cefbf5af0ddb"
    let tokenAId  = "47ed98e8deb59eaf8d5becf83130a97da55a13aaf3aa36247f36573e2192eca0"
    let tokenBId = "3cc029dc4cf07923e5eb634b4ff29edabdfd14ba9556044d39cb7bdf82a02b42"
    let swapFunctionName = "swap"
    var invokeTransactionId:String?
    var submitterAccount:AccountResponse?
    var latestLedger:UInt32?
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sorobanServer.enableLogging = true
        StellarSDK.testNet().accounts.createTestAccount(accountId: submitterKeyPair.accountId) { (response) -> (Void) in
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
        getLatestLedger()
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
    
    func invokeAtomicSwap() throws {
        try XCTContext.runActivity(named: "invokeAtomicSwap") { activity in
            let expectation = XCTestExpectation(description: "contract successfully invoked")
            
            let addressAlice = try SCAddressXDR(accountId: aliceKeyPair.accountId);
            let addressBob = try SCAddressXDR(accountId: bobKeyPair.accountId);
            let tokenAAddress = try SCAddressXDR(contractId: tokenAId);
            let tokenBAddress = try SCAddressXDR(contractId: tokenBId);
            let amountA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 1000))
            let minBForA = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 4500))
            let amountB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 5000))
            let minAForB = SCValXDR.i128(Int128PartsXDR(hi: 0, lo: 950))
            
            
            
            let invokeArgs:[SCValXDR] = [SCValXDR.address(addressAlice),
                                         SCValXDR.address(addressBob),
                                         SCValXDR.address(tokenAAddress),
                                         SCValXDR.address(tokenBAddress),
                                         amountA,
                                         minBForA,
                                         amountB,
                                         minAForB]
            
            let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.atomicSwapContractId,
                                                                                       functionName: self.swapFunctionName,
                                                                                       functionArguments: invokeArgs)
            
            let transaction = try! Transaction(sourceAccount: submitterAccount!,
                                               operations: [invokeOperation], memo: Memo.none)
            
            let simulateTxRequest = SimulateTransactionRequest(transaction: transaction);
            self.sorobanServer.simulateTransaction(simulateTxRequest: simulateTxRequest) { (response) -> (Void) in
                switch response {
                case .success(let simulateResponse):
                    XCTAssertNotNil(simulateResponse.footprint)
                    XCTAssertNotNil(simulateResponse.transactionData)
                    XCTAssertNotNil(simulateResponse.minResourceFee)
                    
                    transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
                    transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
                    
                    let bobAccountId = self.bobKeyPair.accountId
                    let aliceAccountId = self.aliceKeyPair.accountId
                    
                    // sign auth and set it to the transaction
                    var sorobanAuth : [SorobanAuthorizationEntryXDR] = []
                    for var a in simulateResponse.sorobanAuth! {
                        if (a.credentials.address?.address.accountId == bobAccountId) {
                            try! a.sign(signer: self.bobKeyPair,
                                        network: Network.testnet,
                                        signatureExpirationLedger: self.latestLedger! + 10)
                        }
                        if (a.credentials.address?.address.accountId == aliceAccountId) {
                            try! a.sign(signer: self.aliceKeyPair,
                                        network: Network.testnet,
                                        signatureExpirationLedger: self.latestLedger! + 10)
                        }
                        sorobanAuth.append(a)
                    }
                    transaction.setSorobanAuth(auth: sorobanAuth)
                    
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
