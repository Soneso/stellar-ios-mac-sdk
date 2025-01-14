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

    let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org") // SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let sdk =  StellarSDK.testNet() // StellarSDK.futureNet()
    let network = Network.testnet // Network.futurenet
    var invokerKeyPair = try! KeyPair.generateRandomKeyPair()
    var senderKeyPair = try! KeyPair.generateRandomKeyPair()
    var installTransactionId:String?
    var installWasmId:String?
    var createTransactionId:String?
    var contractId:String?
    var invokeTransactionId:String?
    var senderAccount:Account?
    var invokerAccount:Account?
    var latestLedger:UInt32?
    
    override func setUp() async throws {
        try await super.setUp()
        
        sorobanServer.enableLogging = true
         
        let invokerId = invokerKeyPair.accountId
        let senderId = senderKeyPair.accountId
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: invokerId)
        //var responseEnum = await sdk.accounts.createFutureNetTestAccount(accountId: invokerId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create invoker account: \(invokerId)")
        }
        
        //responseEnum = await sdk.accounts.createFutureNetTestAccount(accountId: senderId)
        responseEnum = await sdk.accounts.createTestAccount(accountId: senderId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create sender account: \(senderId)")
        }
    }
    
    func testAll() async {
        await refreshSenderAccount()
        await uploadContractWasm()
        await refreshSenderAccount()
        await createContract()

        await refreshSenderAccount()
        await getLatestLedger()
        await invokeContractAuthAccount() // sender != invoker

        await refreshInvokerAccount()
        await invokeContractAuthInvoker() // sender == invoker
    }
    
    
    func refreshSenderAccount() async {
        let accountId = senderKeyPair.accountId
        let response = await sorobanServer.getAccount(accountId: accountId)
        switch response {
        case .success(let account):
            XCTAssertEqual(accountId, account.accountId)
            self.senderAccount = account
        case .failure(_):
            XCTFail()
        }
    }
    
    func uploadContractWasm() async {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "soroban_auth_contract", ofType: "wasm") else {
            // File not found
            XCTFail()
            return
        }
        let contractCode = FileManager.default.contents(atPath: path)
        let installOperation = try! InvokeHostFunctionOperation.forUploadingContractWasm(contractCode: contractCode!)
        
        let transaction = try! Transaction(sourceAccount: senderAccount!,
                                           operations: [installOperation], memo: Memo.none)
        
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
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        try! transaction.sign(keyPair: self.senderKeyPair, network: self.network)
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            self.installTransactionId = response.transactionId
            XCTAssertNotNil(self.installTransactionId)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: self.installTransactionId!)
        switch txResultEnum {
        case .success(let statusResponse):
            XCTAssertEqual(GetTransactionResponse.STATUS_SUCCESS, statusResponse.status)
            self.installWasmId = statusResponse.wasmId
            XCTAssertNotNil(self.installWasmId)
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func createContract() async {
        let accountId = senderKeyPair.accountId
        
        //let createOperation = try! InvokeHostFunctionOperation.forCreatingContract(wasmId: self.installWasmId!, address: SCAddressXDR(accountId: accountId))
        let createOperation = try! InvokeHostFunctionOperation.forCreatingContractWithConstructor(wasmId: self.installWasmId!, address: SCAddressXDR(accountId: accountId), constructorArguments: [])
        let transaction = try! Transaction(sourceAccount: senderAccount!,
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
        
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            self.createTransactionId = response.transactionId
            XCTAssertNotNil(self.createTransactionId)
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
    
    func getLatestLedger() async {
        let latestLedgerResponseEnum = await sorobanServer.getLatestLedger()
        switch latestLedgerResponseEnum {
        case .success(let latestLedgerResponse):
            self.latestLedger = latestLedgerResponse.sequence
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func invokeContractAuthAccount() async {
        let invokerId = invokerKeyPair.accountId
        let functionName = "increment"
        let invokerAddress = try! SCAddressXDR(accountId: invokerId)
        let args = [SCValXDR.address(invokerAddress), SCValXDR.u32(3)]
        
        let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: args)
        
        let transaction = try! Transaction(sourceAccount: senderAccount!,
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
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        
        // sign auth and set it to the transaction
        var sorobanAuth = simulateResponse.sorobanAuth!
        for i in sorobanAuth.indices {
            try! sorobanAuth[i].sign(signer: self.invokerKeyPair,
                                     network: self.network,
                                signatureExpirationLedger: self.latestLedger! + 10)
        }
        transaction.setSorobanAuth(auth: sorobanAuth)
        
        try! transaction.sign(keyPair: self.senderKeyPair, network: self.network)
        
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
            guard let val = statusResponse.resultValue?.u32,val > 0 else {
                XCTFail()
                return
            }
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
    }
    
    func refreshInvokerAccount() async {
        let accountId = invokerKeyPair.accountId
        let response = await sorobanServer.getAccount(accountId: accountId)
        switch response {
        case .success(let account):
            XCTAssertEqual(accountId, account.accountId)
            self.invokerAccount = account
        case .failure(_):
            XCTFail()
        }
    }

    func invokeContractAuthInvoker() async {
        let invokerId = invokerKeyPair.accountId
        let functionName = "increment"
        let invokerAddress = try! SCAddressXDR(accountId: invokerId)
        let args = [SCValXDR.address(invokerAddress), SCValXDR.u32(3)]
        
        let invokeOperation = try! InvokeHostFunctionOperation.forInvokingContract(contractId: self.contractId!, functionName: functionName, functionArguments: args)
        
        let transaction = try! Transaction(sourceAccount: invokerAccount!,
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
        XCTAssertNotNil(simulateResponse.footprint)
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        // no need to sign soroban auth
        transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth!)
        
        try! transaction.sign(keyPair: self.invokerKeyPair, network: self.network)
        
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
            guard let val = statusResponse.resultValue?.u32,val > 0 else {
                XCTFail()
                return
            }
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
}
