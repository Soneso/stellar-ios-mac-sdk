//
//  AssetsTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 03.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AssetsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let IOMIssuingAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    
    override func setUp() async throws {
        try await super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

        let testAccountId = testKeyPair.accountId
        let issuingAccountId = IOMIssuingAccountKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let changeTrustOp = ChangeTrustOperation(sourceAccountId:testAccountId, asset:IOMAsset, limit: 100000000)
        let paymentOp = try! PaymentOperation(sourceAccountId: issuingAccountId, destinationAccountId: testAccountId, asset: IOMAsset, amount: 20000.0)

        var responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
        responseEnum = await sdk.accounts.createTestAccount(accountId: issuingAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(issuingAccountId)")
        }
        let accDetailsResEnum = await self.sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp, paymentOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.IOMIssuingAccountKeyPair, network: Network.testnet)
            
            let submitTxResponse = await self.sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
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
        await getAssets()
        await getAssetAccountsAndBalances()
    }
        
    func getAssets() async {
        let assetsResponseEnum = await sdk.assets.getAssets(order:Order.descending, limit:2)
        switch assetsResponseEnum {
        case .success(let firstPage):
            let nextPageResult = await firstPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPage):
                let prevPageResult = await nextPage.getPreviousPage()
                switch prevPageResult {
                case .success(let page):
                    let asset1 = firstPage.records.first!
                    let asset2 = page.records.last! // because ordering is asc now.
                    XCTAssertTrue(asset1.amount == asset2.amount)
                    XCTAssertTrue(asset1.assetType == asset2.assetType)
                    if (asset1.assetType != AssetTypeAsString.NATIVE) {
                        XCTAssertTrue(asset1.assetCode == asset2.assetCode)
                        XCTAssertTrue(asset1.assetIssuer == asset2.assetIssuer)
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
                    XCTFail("failed to load prev page")
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
                XCTFail("failed to load next page")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getTransactions()", horizonRequestError: error)
            XCTFail("failed to load assets")
        }
    }
    
    func getAssetAccountsAndBalances() async {
        let response = await sdk.assets.getAssets(for: "IOM", assetIssuer: IOMIssuingAccountKeyPair.accountId)
        switch response {
        case .success(let assetsResponse):
            if let asset = assetsResponse.records.first {
                let accounts = asset.accounts
                XCTAssert(accounts.authorized == 1)
                XCTAssert(accounts.authorizedToMaintainLiabilities == 0)
                XCTAssert(accounts.unauthorized == 0)
                XCTAssert(asset.numberOfAccounts == 1)
                XCTAssert(asset.numClaimableBalances == 0)
                XCTAssert(asset.claimableBalancesAmount == 0.0)
                XCTAssert(asset.amount == 20000.0)
                let balances = asset.balances
                XCTAssert(balances.authorized == 20000.0)
            } else {
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load assets testcase", horizonRequestError: error)
            XCTFail()
        }
    }
}
