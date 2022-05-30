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
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

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
        
        sdk.accounts.createTestAccount(accountId: testAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createTestAccount(accountId: issuingAccountId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        self.sdk.accounts.getAccountDetails(accountId: testAccountId) { (response) -> (Void) in
                        switch response {
                        case .success(let accountResponse):
                            let transaction = try! Transaction(sourceAccount: accountResponse,
                                                              operations: [changeTrustOp1, begingSponsorshipOp, createAccountOp, changeTrustOp2, endSponsoringOp, setOptionsOp],
                                                              memo: Memo.none)
                            try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
                            try! transaction.sign(keyPair: self.testKeyPairExtra, network: Network.testnet)
                            
                            try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                switch response {
                                case .success(let response):
                                    print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
                                    expectation.fulfill()
                                default:
                                    XCTFail()
                                }
                            }
                        case .failure(_):
                            XCTFail()
                        }
                    }
                    case .failure(_):
                        XCTFail()
                    }
                }
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 25.0)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAll() {
        getAccountDetails()
        getAccountsByAsset()
        getAccountsBySigner()
        getAccountsBySponsor()
    }
    
    func getAccountDetails() {
        XCTContext.runActivity(named: "getAccountDetails") { activity in
            let expectation = XCTestExpectation(description: "Get account details and parse them successfully")
            
            sdk.accounts.getAccountDetails(accountId: testKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountDetails):
                    print("Account-ID: \(accountDetails.accountId)")
                    print("Sequence Nr: \(accountDetails.sequenceNumber)")
                    for balance in accountDetails.balances {
                        print("Balance \(balance.balance)")
                    }
                    print("Seq Ledger: \(accountDetails.sequenceLedger!)")
                    print("Seq Time: \(accountDetails.sequenceTime!)")
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Get account details test", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getAccountsByAsset() {
        XCTContext.runActivity(named: "getAccountsByAsset") { activity in
            let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
            
            sdk.accounts.getAccounts(asset: "IOM:" + IOMIssuingAccountKeyPair.accountId, order: Order.descending, limit: 2) { (response) -> (Void) in
                switch response {
                case .success(let accountsResponse):
                    // load next page
                    accountsResponse.getNextPage(){ (response) -> (Void) in
                        switch response {
                        case .success(let nextAccountsResponse):
                            // load previous page, should contain the same accounts as the first page
                            nextAccountsResponse.getPreviousPage(){ (response) -> (Void) in
                                switch response {
                                case .success(let prevAccountsResponse):
                                    let account1 = accountsResponse.records.first
                                    let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                                    XCTAssertNotNil(account1);
                                    XCTAssertNotNil(account2);
                                    XCTAssertTrue(account1?.accountId == account2?.accountId)
                                    XCTAssert(true)
                                    expectation.fulfill()
                                case .failure(let error):
                                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                                    XCTFail()
                                }
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                            XCTFail()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getAccountsBySigner() {
        XCTContext.runActivity(named: "getAccountsBySigner") { activity in
            let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
            
            sdk.accounts.getAccounts(signer: testKeyPair.accountId, asset:nil, cursor: nil, order: Order.descending, limit: 2) { (response) -> (Void) in
                switch response {
                case .success(let accountsResponse):
                    // load next page
                    accountsResponse.getNextPage(){ (response) -> (Void) in
                        switch response {
                        case .success(let nextAccountsResponse):
                            // load previous page, should contain the same accounts as the first page
                            nextAccountsResponse.getPreviousPage(){ (response) -> (Void) in
                                switch response {
                                case .success(let prevAccountsResponse):
                                    let account1 = accountsResponse.records.first
                                    let account2 = prevAccountsResponse.records.last // because ordering is asc now.
                                    XCTAssertNotNil(account1);
                                    XCTAssertNotNil(account2);
                                    XCTAssertTrue(account1?.accountId == account2?.accountId)
                                    XCTAssert(true)
                                    expectation.fulfill()
                                case .failure(let error):
                                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                                    XCTFail()
                                }
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                            XCTFail()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getAccountsBySponsor() {
        XCTContext.runActivity(named: "getAccountsBySponsor") { activity in
            let expectation = XCTestExpectation(description: "Get accounts and parse their details successfully")
            
            sdk.accounts.getAccounts(sponsor: testKeyPair.accountId, cursor: nil, order: Order.descending, limit: 5) { (response) -> (Void) in
                switch response {
                case .success(let accountsResponse):
                    XCTAssert(accountsResponse.records.count == 1)
                    XCTAssert(accountsResponse.records.first?.accountId == self.testKeyPairExtra.accountId)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"Load accounts testcase", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
}
