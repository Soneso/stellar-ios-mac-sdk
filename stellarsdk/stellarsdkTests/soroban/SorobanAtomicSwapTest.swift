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
    // See https://developers.stellar.org/docs/smart-contracts/example-contracts/atomic-swap
    // See https://developers.stellar.org/docs/learn/smart-contract-internals/authorization
    
    let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org") // SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let sdk = StellarSDK.testNet() // StellarSDK.futureNet()
    let network =  Network.testnet // Network.futurenet
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    let aliceKeyPair = try! KeyPair(secretSeed: "SB5HSDMRVI2EQCHAJZAKAZQ3ZJPV4XE5JYWJ33INVAWZI3H22CBLCPQI") // GAJ7SO3AKJSY7ESWYCMEX36F25EEHWO44VASGCIRVGOSUQC7J5BGNUJ4
    let bobKeyPair = try! KeyPair(secretSeed: "SB2YFAESRTAQKEWBWY3BG7ZV47SQYCBBUFCKW3P3CEF5DYITF4U2YEGD") // GAMLJPFPGKDZ2JLUEDL27KEFT6LN5HKHLVNVR6TUNM66Z4BUEKUS2O4Z
    let atomicSwapContractId = "5cd56a3e9f0f667cbc510e6d459f9b988152a975a11176cb1ae67108dde961e1"
    let tokenAId  = "5f75959d58c1dde770dac6143507f95e1e9d2208e696f69076f91383557e0aa7"
    let tokenBId = "4a3839fc364af5cda44ca03419eaec74e19bce86a96537c18e455bfa6bfc2d12"
    let swapFunctionName = "swap"
    var invokeTransactionId:String?
    var submitterAccount:Account?
    var latestLedger:UInt32?
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "account prepared for tests")
        sorobanServer.enableLogging = true
        //sdk.accounts.createFutureNetTestAccount(accountId: submitterKeyPair.accountId) { (response) -> (Void) in
        sdk.accounts.createTestAccount(accountId: submitterKeyPair.accountId) { (response) -> (Void) in
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
        loadContractInfoByContractId(contractId: self.tokenBId)
        //loadContractInfoByContractId(contractId: self.atomicSwapContractId)
    }
    
    func getSubmitterAccount() {
        XCTContext.runActivity(named: "getSubmitterAccount") { activity in
            let expectation = XCTestExpectation(description: "get account response received")
            
            let accountId = submitterKeyPair.accountId
            sorobanServer.getAccount(accountId: accountId) { (response) -> (Void) in
                switch response {
                case .success(let account):
                    XCTAssertEqual(accountId, account.accountId)
                    self.submitterAccount = account
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
                                        network: self.network,
                                        signatureExpirationLedger: self.latestLedger! + 10)
                        }
                        if (a.credentials.address?.address.accountId == aliceAccountId) {
                            try! a.sign(signer: self.aliceKeyPair,
                                        network: self.network,
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
    
    func loadContractInfoByContractId(contractId: String) {
        XCTContext.runActivity(named: "getContractInfoByContractId") { activity in
            let expectation = XCTestExpectation(description: "loads contract info from soroban by contract id")
            try! self.sorobanServer.getContractInfoForContractId(contractId: contractId) { (response) -> (Void) in
                switch response {
                case .success(let response):
                    XCTAssertTrue(response.specEntries.count > 0)
                    XCTAssertTrue(response.metaEntries.count > 0)
                    print("SPEC ENTRIES \(response.specEntries.count)")
                    expectation.fulfill()
                case .rpcFailure(let error):
                    self.printError(error: error)
                    XCTFail()
                    expectation.fulfill()
                case .parsingFailure (let error):
                    self.printParserError(error: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 10.0)
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
}
