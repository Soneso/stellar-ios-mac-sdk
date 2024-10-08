//
//  EffectsRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 05/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class EffectsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    var transactionHash:String? = nil
    var ledger:Int? = nil
    
    override func setUp() async throws {
        try await super.setUp()
        
        let testAccountId = testKeyPair.accountId
        let manageDataOp = ManageDataOperation(sourceAccountId: testAccountId, name: "soneso", data: "is super".data(using: .utf8))

        let responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
        let accDetailsResEnum = await self.sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [manageDataOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
            
            let submitTxResponse = await self.sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
                self.transactionHash = details.transactionHash
                self.ledger = details.ledger
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
    
    func testAll() async {
        await getEffects()
        await getEffectsForAccount()
        await getEffectsForOperation()
        await getEffectsForLedger()
        await getEffectsForTransaction()
    }
        
    
    func getEffects() async {
        let effetcsResponseEnum = await sdk.effects.getEffects();
        switch effetcsResponseEnum {
        case .success(let firstPage):
            let nextPageResult = await firstPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPage):
                let prevPageResult = await nextPage.getPreviousPage()
                switch prevPageResult {
                case .success(let page):
                    XCTAssertTrue(page.records.count > 0)
                    XCTAssertTrue(firstPage.records.count > 0)
                    let effect1 = firstPage.records.first!
                    let effect2 = page.records.last! // because ordering is asc now.
                    XCTAssertTrue(effect1.id == effect2.id)
                    XCTAssertTrue(effect1.account == effect2.account)
                    XCTAssertTrue(effect1.effectType == effect2.effectType)
                    XCTAssertTrue(effect1.effectTypeString == effect2.effectTypeString)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffects()", horizonRequestError: error)
                    XCTFail("failed to load prev page")
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffects()", horizonRequestError: error)
                XCTFail("failed to load next page")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffects()", horizonRequestError: error)
            XCTFail("failed to load effects")
        }
    }
    
    func getEffectsForAccount() async {
        
        let response = await sdk.effects.getEffects(forAccount: testKeyPair.accountId, order:Order.descending)
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"GEFA Test", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getEffectsForOperation() async {
        let opResponseEnum = await sdk.operations.getOperations(forAccount: testKeyPair.accountId, from: nil, order: Order.descending, includeFailed: true, join: "transactions");
        switch opResponseEnum {
        case .success(let page):
            XCTAssertNotNil(page.records.first)
            let effectsReponseEnum = await self.sdk.effects.getEffects(forOperation: page.records.first!.id)
            switch effectsReponseEnum {
            case .success(let effectsPage):
                XCTAssertFalse(effectsPage.records.isEmpty)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForOperation", horizonRequestError: error)
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForOperation", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getEffectsForLedger() async {
        let response = await sdk.effects.getEffects(forLedger: String(self.ledger!))
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForLedger", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getEffectsForTransaction() async {
        let response = await sdk.effects.getEffects(forTransaction: self.transactionHash!)
        switch response {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getEffectsForTransaction", horizonRequestError: error)
            XCTFail()
        }
    }
}
