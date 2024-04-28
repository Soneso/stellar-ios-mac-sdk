//
//  RegulatedAssetsTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

import XCTest
import stellarsdk

class RegulatedAssetsTestCase: XCTestCase {
    
    let anchorDomain: String = "api.anchor.org"
    
    let sdk = StellarSDK()
    let network = Network.testnet
    var service: RegulatedAssetsService!
    var sep08PostSuccessMock: Sep08PostSuccessMock!
    var sep08PostPendingMock: Sep08PostPendingMock!
    var sep08PostRevisedMock: Sep08PostRevisedMock!
    var sep08PostRejectedMock: Sep08PostRejectedMock!
    var sep08PostActionRequiredMock: Sep08PostActionRequiredMock!
    var sep08FollowNextMock: Sep08FollowNextMock!
    var sep08ActionDoneMock: Sep08ActionDoneMock!
    
    let asset1IssuerKp = try! KeyPair.generateRandomKeyPair()
    let asset2IssuerKp = try! KeyPair.generateRandomKeyPair()
    let accountAKp = try! KeyPair.generateRandomKeyPair()
    var stellarToml = try! StellarToml(fromString: """
        # Sample stellar.toml
        VERSION="2.0.0"
        
        NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
        WEB_AUTH_ENDPOINT="https://api.anchor.org/auth"
        TRANSFER_SERVER_SEP0024="http://api.stellar.org/transfer-sep24/"
        ANCHOR_QUOTE_SERVER="http://api.stellar.org/quotes-sep38/"
        SIGNING_KEY="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
        
        [[CURRENCIES]]
        code="GOAT"
        regulated=true
        approval_server="http://goat.io/tx_approve"
        approval_criteria="The goat approval server will ensure that transactions are compliant with NFO regulation"
        
        [[CURRENCIES]]
        code="NOP"
        issuer="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
        display_decimals=2
        
        [[CURRENCIES]]
        code="JACK"
        regulated=true
        approval_server="https://jack.io/tx_approve"
        approval_criteria="The jack approval server will ensure that transactions are compliant with NFO regulation"
        
        """)
    
    var txB64Xdr: String!
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")
        
        URLProtocol.registerClass(ServerMock.self)
        let host = "goat.io"
        sep08PostSuccessMock = Sep08PostSuccessMock(host:host)
        sep08PostPendingMock = Sep08PostPendingMock(host:host)
        sep08PostRevisedMock = Sep08PostRevisedMock(host:host)
        sep08PostRejectedMock = Sep08PostRejectedMock(host:host)
        sep08PostActionRequiredMock = Sep08PostActionRequiredMock(host:host)
        sep08FollowNextMock = Sep08FollowNextMock(host: host)
        sep08ActionDoneMock = Sep08ActionDoneMock(host: host)
        
        self.stellarToml.currenciesDocumentation.first?.issuer = asset1IssuerKp.accountId
        self.stellarToml.currenciesDocumentation.last?.issuer = asset2IssuerKp.accountId
        service = try! RegulatedAssetsService(tomlData: self.stellarToml)
        let goatAsset = service.regulatedAssets.first!
        let authOp = SetTrustlineFlagsOperation(sourceAccountId: goatAsset.isserId, asset: goatAsset, trustorAccountId: accountAKp.accountId, setFlags: TrustLineFlags.AUTHORIZED_FLAG, clearFlags: 0)
        let buyOp = ManageBuyOfferOperation(sourceAccountId: accountAKp.accountId, selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, buying: goatAsset, amount: 10, price: Price.fromString(price: "0.1"), offerId: 0)
        let maintainOp = SetTrustlineFlagsOperation(sourceAccountId: goatAsset.isserId, asset: goatAsset, trustorAccountId: accountAKp.accountId, setFlags: TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG, clearFlags: 0)
        
        let tx = try! Transaction(sourceAccount: Account(keyPair: accountAKp, sequenceNumber: 0),
                                  operations: [authOp, buyOp, maintainOp],
                                  memo: Memo.none)
        try! tx.sign(keyPair: self.accountAKp, network: self.network)
        self.txB64Xdr = try! tx.encodedEnvelope()
        
        let setFlagsOp = try! SetOptionsOperation(sourceAccountId:asset1IssuerKp.accountId, setFlags: AccountFlags.AUTH_REQUIRED_FLAG | AccountFlags.AUTH_REVOCABLE_FLAG)
        
        sdk.accounts.createTestAccount(accountId: self.asset1IssuerKp.accountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createTestAccount(accountId: self.asset2IssuerKp.accountId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        self.sdk.accounts.createTestAccount(accountId: self.accountAKp.accountId) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                self.sdk.accounts.getAccountDetails(accountId: self.asset1IssuerKp.accountId) { (response) -> (Void) in
                                    switch response {
                                    case .success(let accountResponse):
                                        
        
                                        let transaction = try! Transaction(sourceAccount: accountResponse,
                                                                          operations: [setFlagsOp],
                                                                          memo: Memo.none)
                                        try! transaction.sign(keyPair: self.asset1IssuerKp, network: Network.testnet)
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
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 55.0)
    }
    
    
    func testAll() {
        regulatedAssestParsed()
        authRequired()
        postTransactionSuccess()
        postTransactionPending()
        postTransactionRevised()
        postTransactionRejected()
        postTransactionActionRequired()
        postActionFollowNext()
        postActionDone()
    }
    
    func regulatedAssestParsed() {
        let expectation = XCTestExpectation(description: "Test sep08 support")
        
        let regulatedAssets = service.regulatedAssets
        XCTAssertTrue(regulatedAssets.count == 2)
        
        let goatAsset = regulatedAssets.first!
        XCTAssertEqual("http://goat.io/tx_approve", goatAsset.approvalServer)
        XCTAssertEqual("The goat approval server will ensure that transactions are compliant with NFO regulation", goatAsset.approvalCriteria)
        
        let jackAsset = regulatedAssets.last!
        XCTAssertEqual("https://jack.io/tx_approve", jackAsset.approvalServer)
        XCTAssertEqual("The jack approval server will ensure that transactions are compliant with NFO regulation", jackAsset.approvalCriteria)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 15.0)
    }
    
    
    func authRequired() {
        let expectation = XCTestExpectation(description: "Test sep08 authorization required")
        
        service.authorizationRequired(asset: service.regulatedAssets.first!) { (response) -> (Void) in
            switch response {
            case .success(let required):
                XCTAssertTrue(required)
            case .failure(let err):
                XCTFail(err.localizedDescription)
            }
            self.service.authorizationRequired(asset: self.service.regulatedAssets.last!) { (response) -> (Void) in
                switch response {
                case .success(let required):
                    XCTAssertFalse(required)
                case .failure(let err):
                    XCTFail(err.localizedDescription)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func postTransactionSuccess() {
        let expectation = XCTestExpectation(description: "Test sep08 post tx success")
        let goatAsset = service.regulatedAssets.first!
        
        service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/success") { (response) -> (Void) in
            switch response {
            case .success(let response):
                XCTAssertTrue(response.tx == self.txB64Xdr)
                XCTAssertTrue(response.message == "hello")
            case .failure(let err):
                XCTFail(err.localizedDescription)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func postTransactionPending() {
        let expectation = XCTestExpectation(description: "Test sep08 post tx pending")
        let goatAsset = service.regulatedAssets.first!
        
        service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/pending") { (response) -> (Void) in
            switch response {
            case .pending(let response):
                XCTAssertTrue(response.timeout == 10)
                XCTAssertTrue(response.message == "hello")
            case .failure(let err):
                XCTFail(err.localizedDescription)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func postTransactionRevised() {
        let expectation = XCTestExpectation(description: "Test sep08 post tx revised")
        let goatAsset = service.regulatedAssets.first!
        
        service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/revised") { (response) -> (Void) in
            switch response {
            case .revised(let response):
                XCTAssertTrue(response.tx == self.txB64Xdr + self.txB64Xdr)
                XCTAssertTrue(response.message == "hello")
            case .failure(let err):
                XCTFail(err.localizedDescription)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    
    func postTransactionRejected() {
        let expectation = XCTestExpectation(description: "Test sep08 post tx rejected")
        let goatAsset = service.regulatedAssets.first!
        
        service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/rejected") { (response) -> (Void) in
            switch response {
            case .rejected(let response):
                XCTAssertTrue(response.error == "hello")
            case .failure(let err):
                XCTFail(err.localizedDescription)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func postTransactionActionRequired() {
        let expectation = XCTestExpectation(description: "Test sep08 post tx action required")
        let goatAsset = service.regulatedAssets.first!
        
        service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/action_required") { (response) -> (Void) in
            switch response {
            case .actionRequired(let response):
                XCTAssertTrue(response.message == "hello")
                XCTAssertTrue(response.actionUrl == "http://goat.io/action")
                XCTAssertTrue(response.actionMethod == "POST")
                XCTAssertTrue(response.actionFields!.count == 2)
                XCTAssertTrue(response.actionFields!.first == "email_address")
                XCTAssertTrue(response.actionFields!.last == "mobile_number")
            case .failure(let err):
                XCTFail(err.localizedDescription)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func postActionFollowNext() {
        let expectation = XCTestExpectation(description: "Test sep08 post action follow next")
        
        service.postAction(url: "http://goat.io/action/next", actionFields: ["email_addres" : "test@gmail.com"]) { (response) -> (Void) in
            switch response {
            case .nextUrl(let response):
                XCTAssertTrue(response.message == "Please submit mobile number")
                XCTAssertTrue(response.nextUrl == "http://goat.io/action")
            case .failure(let err):
                XCTFail(err.localizedDescription)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func postActionDone() {
        let expectation = XCTestExpectation(description: "Test sep08 post action done")
        
        service.postAction(url: "http://goat.io/action/done", actionFields: ["mobile_number" : "+347282983922"]) { (response) -> (Void) in
            switch response {
            case .done:
                expectation.fulfill()
            case .failure(let err):
                XCTFail(err.localizedDescription)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}

