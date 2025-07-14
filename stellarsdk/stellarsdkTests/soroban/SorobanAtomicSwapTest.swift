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
    
    static let testOn = "futurenet" // "testnet"
    let sorobanServer = testOn == "testnet" ? SorobanServer(endpoint: "https://soroban-testnet.stellar.org"): SorobanServer(endpoint: "https://rpc-futurenet.stellar.org")
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    let submitterKeyPair = try! KeyPair.generateRandomKeyPair()
    let aliceKeyPair = try! KeyPair(secretSeed: "SB2VMA5RB6ATRLYVZQ5KU7C6FQSKES4SWJNSUPYSLNLEHHYXTE22GS7C") // GB7VPA7JRGSUXP5JZKPOPRTEQBX2UPW4LLNLAP6Y5VRDRQ3BN6TCPFJO
    let bobKeyPair = try! KeyPair(secretSeed: "SBDMVEUMKGHBCVARE3CL2QQCXOWU4KTSJYZSCVGWWNPVHXTOS2LFCT33") // GA3LKGOJIJ4BWD4Z5SQGIYTABXLT7MYBZALRKH5F7ENQ3FQKDP57UO3M
    let atomicSwapContractId = "CDBQXE5CFF52OARZ7FR7TKHUZN76QFRFLVCWHR7GVC2TNBNUK2JOMAMN"
    let tokenAId  = "CAKECBTTSYKQEJEUQKHRD5JND4U6EAZ6Q6EQ6I644X5KPPRCM7UYREI7"
    let tokenBId = "CABFWMLEPS2ZECD5WZLAVRMIXEVD4UP3YLKKV7VDLHTQ7Q6CTWOO5ZC5"
    let swapFunctionName = "swap"
    var invokeTransactionId:String?
    var submitterAccount:Account?
    var latestLedger:UInt32?
    
    override func setUp() async throws {
        try await super.setUp()
        
        sorobanServer.enableLogging = true

        let submitterAccountId = submitterKeyPair.accountId
        let responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: submitterAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: submitterAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create submitter account: \(submitterKeyPair.accountId)")
        }
    }
    
    func testAll() async {
        await getSubmitterAccount()
        await getLatestLedger()
        await invokeAtomicSwap()
        await loadContractInfoByContractId(contractId: self.tokenBId)
        //loadContractInfoByContractId(contractId: self.atomicSwapContractId)
    }
    
    func getSubmitterAccount() async {
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
    
    func invokeAtomicSwap() async {
        let addressAlice = try! SCAddressXDR(accountId: aliceKeyPair.accountId);
        let addressBob = try! SCAddressXDR(accountId: bobKeyPair.accountId);
        let tokenAAddress = try! SCAddressXDR(contractId: tokenAId);
        let tokenBAddress = try! SCAddressXDR(contractId: tokenBId);
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
        
        XCTAssertNotNil(simulateTxResponse)
        XCTAssertNotNil(simulateTxResponse!.footprint)
        if let txData = simulateTxResponse!.transactionData {
            transaction.setSorobanTransactionData(data: txData)
        } else {
            XCTFail()
        }
        if let minResFee = simulateTxResponse!.minResourceFee {
            transaction.addResourceFee(resourceFee: minResFee)
        } else {
            XCTFail()
        }
        
        let bobAccountId = self.bobKeyPair.accountId
        let aliceAccountId = self.aliceKeyPair.accountId
        
        if let simulateAuth = simulateTxResponse!.sorobanAuth {
            // sign auth and set it to the transaction
            var sorobanAuth : [SorobanAuthorizationEntryXDR] = []
            for var a in simulateAuth {
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
        }  else {
            XCTFail()
        }
        
        
        
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
    
    func loadContractInfoByContractId(contractId: String) async {
        let responseEnum = await sorobanServer.getContractInfoForContractId(contractId: contractId)
        switch responseEnum {
        case .success(let response):
            XCTAssertTrue(response.specEntries.count > 0)
            XCTAssertTrue(response.metaEntries.count > 0)
            print("SPEC ENTRIES \(response.specEntries.count)")
        case .parsingFailure(let error):
            self.printParserError(error: error)
            XCTFail()
        case .rpcFailure(let error):
            self.printError(error: error)
            XCTFail()
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
