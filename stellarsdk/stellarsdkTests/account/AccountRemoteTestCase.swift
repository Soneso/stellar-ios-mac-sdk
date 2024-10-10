//
//  AccountRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Rogobete Christian on 19.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

import XCTest
import stellarsdk

class AccountRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let testKeyPairExtra = try! KeyPair.generateRandomKeyPair()
    let IOMIssuingAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    
    override func setUp() async throws {
        try await super.setUp()

        let testAccountId = testKeyPair.accountId
        let testAccountExtraId = testKeyPairExtra.accountId
        let issuingAccountId = IOMIssuingAccountKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let changeTrustOp1 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:IOMAsset, limit: 100000000)

        let signer = try! Signer.ed25519PublicKey(accountId: testAccountId)
        let setOptionsOp = try! SetOptionsOperation(sourceAccountId: testAccountExtraId, signer: signer, signerWeight: 2)
        let begingSponsorshipOp = BeginSponsoringFutureReservesOperation(sponsoredAccountId: testAccountExtraId)
        let createAccountOp = try! CreateAccountOperation(sourceAccountId: testAccountId, destinationAccountId: testAccountExtraId, startBalance: 10.0)
        let changeTrustOp2 = ChangeTrustOperation(sourceAccountId:testAccountExtraId, asset:IOMAsset, limit: 100000000)
        let endSponsoringOp = EndSponsoringFutureReservesOperation(sponsoredAccountId: testAccountExtraId)
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
        
        responseEnum = await self.sdk.accounts.createTestAccount(accountId: issuingAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create issuing account: \(issuingAccountId)")
        }
        
        let accDetailsResEnum = await self.sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp1, begingSponsorshipOp, createAccountOp, changeTrustOp2, endSponsoringOp, setOptionsOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.testKeyPairExtra, network: Network.testnet)
            
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
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAll() async {
        await getAccountDetails()
        await getAccountsByAsset()
        await getAccountsBySigner()
        await getAccountsBySponsor()
    }
    
    func getAccountDetails() async {
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: testKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountDetails):
            print("Account-ID: \(accountDetails.accountId)")
            print("Sequence Nr: \(accountDetails.sequenceNumber)")
            for balance in accountDetails.balances {
                print("Balance \(balance.balance)")
            }
            if let seqLedger = accountDetails.sequenceLedger {
                print("Seq Ledger: \(seqLedger)")
            } else {
                print("Seq Ledger: nil")
            }
            if let seqTime = accountDetails.sequenceLedger {
                print("Seq Time: \(seqTime)")
            } else {
                print("Seq Time: nil")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountDetails()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getAccountsByAsset() async {
        let accResEnum = await sdk.accounts.getAccounts(asset: "IOM:" + IOMIssuingAccountKeyPair.accountId, order: Order.descending, limit: 2);
        switch accResEnum {
        case .success(let accountsResponse):
            let nextPageRes = await accountsResponse.getNextPage();
            switch nextPageRes {
            case .success(let nextAccountsResponse):
                // load previous page, should contain the same accounts as the first page
                let prevPageRes = await nextAccountsResponse.getPreviousPage()
                switch prevPageRes {
                case .success(let prevAccountsResponse):
                    let account1 = accountsResponse.records.first
                    let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                    XCTAssertNotNil(account1);
                    XCTAssertNotNil(account2);
                    XCTAssertTrue(account1?.accountId == account2?.accountId)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountsByAsset()", horizonRequestError: error)
                    XCTFail()
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountsByAsset()", horizonRequestError: error)
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountsByAsset()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getAccountsBySigner() async {
        let accResEnum = await sdk.accounts.getAccounts(signer: testKeyPair.accountId, asset:nil, cursor: nil, order: Order.descending, limit: 2)
        switch accResEnum {
        case .success(let accountsResponse):
            let nextPageRes = await accountsResponse.getNextPage();
            switch nextPageRes {
            case .success(let nextAccountsResponse):
                // load previous page, should contain the same accounts as the first page
                let prevPageRes = await nextAccountsResponse.getPreviousPage()
                switch prevPageRes {
                case .success(let prevAccountsResponse):
                    let account1 = accountsResponse.records.first
                    let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                    XCTAssertNotNil(account1);
                    XCTAssertNotNil(account2);
                    XCTAssertTrue(account1?.accountId == account2?.accountId)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountsBySigner()", horizonRequestError: error)
                    XCTFail()
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountsBySigner()", horizonRequestError: error)
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountsBySigner()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getAccountsBySponsor() async {
        let accResEnum = await sdk.accounts.getAccounts(sponsor: testKeyPair.accountId, cursor: nil, order: Order.descending, limit: 5)
        switch accResEnum {
        case .success(let accountsResponse):
            XCTAssert(accountsResponse.records.count == 1)
            XCTAssert(accountsResponse.records.first?.accountId == self.testKeyPairExtra.accountId)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getAccountsBySponsor()", horizonRequestError: error)
            XCTFail()
        }
    }
}
