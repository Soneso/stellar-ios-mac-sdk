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

    static let testOn = "testnet" // "futurenet"
    let sorobanServer = testOn == "testnet" ? SorobanServer(endpoint: "https://soroban-testnet.stellar.org"): SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    var submitterAccount:Account?
    
    var wasmId:String? = nil
    var contractId:String? = nil
    var invokeTransactionId:String? = nil
    var transactionLedger:Int? = nil
    
    override func setUp() async throws {
        try await super.setUp()
        
        sorobanServer.enableLogging = true
        let accountAId = submitterKeyPair.accountId

        let responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: accountAId) : await sdk.accounts.createFutureNetTestAccount(accountId: accountAId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account A: \(accountAId)")
        }
    }
    
    func testAll() async {
        await uploadContractWasm(name: "soroban_events_contract")
        await createContract()
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
        
        await refreshSubmitterAccount()

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
        
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var txId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssert(SendTransactionResponse.STATUS_ERROR != response.status)
            txId = response.transactionId
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: txId!)
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
        
        await refreshSubmitterAccount()
        
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
        XCTAssertNotNil(simulateResponse.transactionData)
        XCTAssertNotNil(simulateResponse.minResourceFee)
        
        transaction.setSorobanTransactionData(data: simulateResponse.transactionData!)
        transaction.addResourceFee(resourceFee: simulateResponse.minResourceFee!)
        transaction.setSorobanAuth(auth: simulateResponse.sorobanAuth)
        try! transaction.sign(keyPair: self.submitterKeyPair, network: self.network)
        
        // check encoding and decoding
        let enveloperXdr = try! transaction.encodedEnvelope();
        XCTAssertEqual(enveloperXdr, try! Transaction(envelopeXdr: enveloperXdr).encodedEnvelope())
        
        var txId:String? = nil
        let sendTxResponseEnum = await sorobanServer.sendTransaction(transaction: transaction)
        switch sendTxResponseEnum {
        case .success(let response):
            XCTAssertNotEqual(SendTransactionResponse.STATUS_ERROR, response.status)
            txId = response.transactionId
        case .failure(let error):
            self.printError(error: error)
            XCTFail()
        }
        
        // wait a couple of seconds before checking the status
        try! await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        let txResultEnum = await sorobanServer.getTransaction(transactionHash: txId!)
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
        
        let responseEnum = await sorobanServer.getEvents(
            startLedger: ledger,
            endLedger: ledger + 5,
            eventFilters: [eventFilter],
            paginationOptions: PaginationOptions(limit: 2)
        )
        
        switch responseEnum {
        case .success(let eventsResponse):
            XCTAssert(eventsResponse.events.count > 0)
            let event = eventsResponse.events.first!
            let cId = try! event.contractId.decodeContractIdToHex()
            XCTAssert(self.contractId! == cId)
            XCTAssert("AAAADwAAAAdDT1VOVEVSAA==" == event.topic[0])
            XCTAssert("AAAAAwAAAAE=" == event.value)
            XCTAssert("contract" == event.type)
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
    
    func testTxEventsParsing() async throws {
        let success = """
          {
            "latestLedger": 1317536,
            "latestLedgerCloseTime": "1748999063",
            "oldestLedger": 1297535,
            "oldestLedgerCloseTime": "1748898975",
            "status": "SUCCESS",
            "txHash": "2e29cacfc90565027c44bb9477f58af7c179309b5234d6742cd7e7301fcd847f",
            "applicationOrder": 1,
            "feeBump": false,
            "envelopeXdr": "AAAAAgAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQBY644AEETyAAAOngAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAA1jcmVhdGVfZXNjcm93AAAAAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAegAAAAAAAAAAQAAAAAAAAACAAAABgAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAABQAAAABAAAABw92WUOXbPOCn5SPHsgIOq8K1UypMpJe18Eh5s6eH8KeAAAAAQAAAAYAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAAQAAAAAQAAAAIAAAAPAAAABVN0YXRlAAAAAAAABQAAAAAABpGZAAAAAQA1p5gAAEC0AAABuAAAAAAAWOsqAAAAAcVTVrkAAABAkR3EyCbHmZqEzQ1hvb1u2zY8PMqfhm7Z8zULGlpdNV0rWSbchA/NDudYEYrQKdA0qy647T+ojtdMfwLrfHELCA==",
            "resultXdr": "AAAAAABM5iEAAAAAAAAAAQAAAAAAAAAYAAAAANkPSp3CD6fXFropzD1Dse4sGrxEO/NPfv6SvhMR1kNkAAAAAA==",
            "resultMetaXdr": "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",
            "diagnosticEventsXdr": [
              "AAAAAQAAAAAAAAAAAAAAAgAAAAAAAAADAAAADwAAAAdmbl9jYWxsAAAAAA0AAAAg3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAAPAAAADWNyZWF0ZV9lc2Nyb3cAAAAAAAAQAAAAAQAAAAUAAAAFAAAAAAAGkZkAAAASAAAAAAAAAAAnDGNhr4xd4oCt9ulsolPIb9dO6fWMbwEtvYLdX5pdlgAAABIAAAAAAAAAAMnsMF5O5aqcYkDWD91ZWdRBKazSvnUgVeCkPYpbsG8fAAAAEgAAAAAAAAAAGNkZtSF153RCNK2INm7df68NpotUmDlE9qnij73+enIAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHo",
              "AAAAAQAAAAAAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAABAAAAAAAAAAEAAAAPAAAABGluaXQAAAAQAAAAAQAAAAUAAAAFAAAAAAAGkZkAAAASAAAAAAAAAAAnDGNhr4xd4oCt9ulsolPIb9dO6fWMbwEtvYLdX5pdlgAAABIAAAAAAAAAAMnsMF5O5aqcYkDWD91ZWdRBKazSvnUgVeCkPYpbsG8fAAAAEgAAAAAAAAAAGNkZtSF153RCNK2INm7df68NpotUmDlE9qnij73+enIAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHo",
              "AAAAAQAAAAAAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAACAAAAAAAAAAIAAAAPAAAACWZuX3JldHVybgAAAAAAAA8AAAANY3JlYXRlX2VzY3JvdwAAAAAAAAE=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACnJlYWRfZW50cnkAAAAAAAUAAAAAAAAAAw==",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAC3dyaXRlX2VudHJ5AAAAAAUAAAAAAAAAAQ==",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEGxlZGdlcl9yZWFkX2J5dGUAAAAFAAAAAAAAQLQ=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWxlZGdlcl93cml0ZV9ieXRlAAAAAAAABQAAAAAAAAG4",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADXJlYWRfa2V5X2J5dGUAAAAAAAAFAAAAAAAAAKg=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADndyaXRlX2tleV9ieXRlAAAAAAAFAAAAAAAAAAA=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfZGF0YV9ieXRlAAAAAAAFAAAAAAAAAGg=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2RhdGFfYnl0ZQAAAAAFAAAAAAAAAbg=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfY29kZV9ieXRlAAAAAAAFAAAAAAAAQEw=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2NvZGVfYnl0ZQAAAAAFAAAAAAAAAAA=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACmVtaXRfZXZlbnQAAAAAAAUAAAAAAAAAAQ==",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD2VtaXRfZXZlbnRfYnl0ZQAAAAAFAAAAAAAAAQQ=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACGNwdV9pbnNuAAAABQAAAAAAM2BC",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACG1lbV9ieXRlAAAABQAAAAAAGwer",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWludm9rZV90aW1lX25zZWNzAAAAAAAABQAAAAAACD99",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD21heF9yd19rZXlfYnl0ZQAAAAAFAAAAAAAAAFQ=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19kYXRhX2J5dGUAAAAFAAAAAAAAAbg=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19jb2RlX2J5dGUAAAAFAAAAAAAAQEw=",
              "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAE21heF9lbWl0X2V2ZW50X2J5dGUAAAAABQAAAAAAAAEE",
              "AAAAAQAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAoAAAAAAAAAAAAAAAAAWOuO",
              "AAAAAQAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAr/////////////////8/qT"
            ],
            "events": {
              "diagnosticEventsXdr": [
                "AAAAAQAAAAAAAAAAAAAAAgAAAAAAAAADAAAADwAAAAdmbl9jYWxsAAAAAA0AAAAg3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAAPAAAADWNyZWF0ZV9lc2Nyb3cAAAAAAAAQAAAAAQAAAAUAAAAFAAAAAAAGkZkAAAASAAAAAAAAAAAnDGNhr4xd4oCt9ulsolPIb9dO6fWMbwEtvYLdX5pdlgAAABIAAAAAAAAAAMnsMF5O5aqcYkDWD91ZWdRBKazSvnUgVeCkPYpbsG8fAAAAEgAAAAAAAAAAGNkZtSF153RCNK2INm7df68NpotUmDlE9qnij73+enIAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHo",
                "AAAAAQAAAAAAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAACAAAAAAAAAAIAAAAPAAAACWZuX3JldHVybgAAAAAAAA8AAAANY3JlYXRlX2VzY3JvdwAAAAAAAAE=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACnJlYWRfZW50cnkAAAAAAAUAAAAAAAAAAw==",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAC3dyaXRlX2VudHJ5AAAAAAUAAAAAAAAAAQ==",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEGxlZGdlcl9yZWFkX2J5dGUAAAAFAAAAAAAAQLQ=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWxlZGdlcl93cml0ZV9ieXRlAAAAAAAABQAAAAAAAAG4",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADXJlYWRfa2V5X2J5dGUAAAAAAAAFAAAAAAAAAKg=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADndyaXRlX2tleV9ieXRlAAAAAAAFAAAAAAAAAAA=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfZGF0YV9ieXRlAAAAAAAFAAAAAAAAAGg=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2RhdGFfYnl0ZQAAAAAFAAAAAAAAAbg=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfY29kZV9ieXRlAAAAAAAFAAAAAAAAQEw=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2NvZGVfYnl0ZQAAAAAFAAAAAAAAAAA=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACmVtaXRfZXZlbnQAAAAAAAUAAAAAAAAAAQ==",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD2VtaXRfZXZlbnRfYnl0ZQAAAAAFAAAAAAAAAQQ=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACGNwdV9pbnNuAAAABQAAAAAAM2BC",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACG1lbV9ieXRlAAAABQAAAAAAGwer",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWludm9rZV90aW1lX25zZWNzAAAAAAAABQAAAAAACD99",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD21heF9yd19rZXlfYnl0ZQAAAAAFAAAAAAAAAFQ=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19kYXRhX2J5dGUAAAAFAAAAAAAAAbg=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19jb2RlX2J5dGUAAAAFAAAAAAAAQEw=",
                "AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAE21heF9lbWl0X2V2ZW50X2J5dGUAAAAABQAAAAAAAAEE"
              ],
              "transactionEventsXdr": [
                "AAAAAAAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAoAAAAAAAAAAAAAAAAAWOuO",
                "AAAAAQAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAr/////////////////8/qT"
              ],
              "contractEventsXdr": [
                [
                  "AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg=",
                   "AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg="
                ],
                [
                  "AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg=",
                   "AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg="
                ]
              ]
            },
            "ledger": 1303424,
            "createdAt": "1748928444"
          }
        """
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let jsonData = success.data(using: .utf8)!
        let response = try jsonDecoder.decode(GetTransactionResponse.self, from: jsonData)
        XCTAssertNotNil(response.events)
        XCTAssertNotNil(response.events?.diagnosticEventsXdr)
        XCTAssertNotNil(response.events?.transactionEventsXdr)
        XCTAssertNotNil(response.events?.contractEventsXdr)
        XCTAssertEqual(response.events!.diagnosticEventsXdr!.count, 21)
        XCTAssertEqual(response.events!.transactionEventsXdr!.count, 2)
        XCTAssertEqual(response.events!.contractEventsXdr!.count, 2)
        XCTAssertEqual(response.events!.contractEventsXdr!.first!.count, 2)
        
        for eventXdrStr in response.events!.diagnosticEventsXdr! {
            guard let _ = try? DiagnosticEventXDR.init(xdr: eventXdrStr) else {
                XCTFail("invalid diagnostic event xdr \(eventXdrStr)")
                return
            }
        }
        
        for eventXdrStr in response.events!.transactionEventsXdr! {
            guard let _ = try? TransactionEventXDR.init(xdr: eventXdrStr) else {
                XCTFail("invalid transaction event xdr \(eventXdrStr)")
                return
            }
        }
        
        for list in response.events!.contractEventsXdr! {
            for eventXdrStr in list {
                guard let _ = try? ContractEventXDR.init(xdr: eventXdrStr) else {
                    XCTFail("invalid contract event xdr \(eventXdrStr)")
                    return
                }
            }
        }
    }
}
