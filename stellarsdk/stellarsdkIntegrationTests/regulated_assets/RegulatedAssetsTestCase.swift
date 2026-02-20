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
    
    override func setUp() async throws {
        try await super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
        let host = "goat.io"
        sep08PostSuccessMock = Sep08PostSuccessMock(host:host)
        sep08PostPendingMock = Sep08PostPendingMock(host:host)
        sep08PostRevisedMock = Sep08PostRevisedMock(host:host)
        sep08PostRejectedMock = Sep08PostRejectedMock(host:host)
        sep08PostActionRequiredMock = Sep08PostActionRequiredMock(host:host)
        sep08FollowNextMock = Sep08FollowNextMock(host: host)
        sep08ActionDoneMock = Sep08ActionDoneMock(host: host)
        
        self.stellarToml = try! StellarToml(fromString: """
            # Sample stellar.toml
            VERSION="2.0.0"

            NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
            WEB_AUTH_ENDPOINT="https://api.anchor.org/auth"
            TRANSFER_SERVER_SEP0024="http://api.stellar.org/transfer-sep24/"
            ANCHOR_QUOTE_SERVER="http://api.stellar.org/quotes-sep38/"
            SIGNING_KEY="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"

            [[CURRENCIES]]
            code="GOAT"
            issuer="\(asset1IssuerKp.accountId)"
            regulated=true
            approval_server="http://goat.io/tx_approve"
            approval_criteria="The goat approval server will ensure that transactions are compliant with NFO regulation"

            [[CURRENCIES]]
            code="NOP"
            issuer="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
            display_decimals=2

            [[CURRENCIES]]
            code="JACK"
            issuer="\(asset2IssuerKp.accountId)"
            regulated=true
            approval_server="https://jack.io/tx_approve"
            approval_criteria="The jack approval server will ensure that transactions are compliant with NFO regulation"

            """)
        service = try! RegulatedAssetsService(tomlData: self.stellarToml)
        let goatAsset = service.regulatedAssets.first!
        let authOp = SetTrustlineFlagsOperation(sourceAccountId: goatAsset.issuerId,
                                                asset: goatAsset,
                                                trustorAccountId: accountAKp.accountId,
                                                setFlags: TrustLineFlags.AUTHORIZED_FLAG,
                                                clearFlags: 0)
        let buyOp = ManageBuyOfferOperation(sourceAccountId: accountAKp.accountId,
                                            selling: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                            buying: goatAsset,
                                            amount: 10,
                                            price: Price.fromString(price: "0.1"),
                                            offerId: 0)
        let maintainOp = SetTrustlineFlagsOperation(sourceAccountId: goatAsset.issuerId, 
                                                    asset: goatAsset,
                                                    trustorAccountId: accountAKp.accountId,
                                                    setFlags: TrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG,
                                                    clearFlags: 0)
        
        let tx = try! Transaction(sourceAccount: Account(keyPair: accountAKp, sequenceNumber: 0),
                                  operations: [authOp, buyOp, maintainOp],
                                  memo: Memo.none)
        
        try! tx.sign(keyPair: self.accountAKp, network: self.network)
        self.txB64Xdr = try! tx.encodedEnvelope()
        
        let setFlagsOp = try! SetOptionsOperation(sourceAccountId:asset1IssuerKp.accountId, setFlags: AccountFlags.AUTH_REQUIRED_FLAG | AccountFlags.AUTH_REVOCABLE_FLAG)
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: asset1IssuerKp.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create asset1Issuer account: \(asset1IssuerKp.accountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: asset2IssuerKp.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create asset2Issuer account: \(asset2IssuerKp.accountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: accountAKp.accountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create accountA account: \(accountAKp.accountId)")
        }
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: asset1IssuerKp.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [setFlagsOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.asset1IssuerKp, network: Network.testnet)
            
            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction);
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
        regulatedAssestParsed()
        await authRequired()
        await postTransactionSuccess()
        await postTransactionPending()
        await postTransactionRevised()
        await postTransactionRejected()
        await postTransactionActionRequired()
        await postActionFollowNext()
        await postActionDone()
    }
    
    func regulatedAssestParsed() {
        let regulatedAssets = service.regulatedAssets
        XCTAssertTrue(regulatedAssets.count == 2)
        
        let goatAsset = regulatedAssets.first!
        XCTAssertEqual("http://goat.io/tx_approve", goatAsset.approvalServer)
        XCTAssertEqual("The goat approval server will ensure that transactions are compliant with NFO regulation", goatAsset.approvalCriteria)
        
        let jackAsset = regulatedAssets.last!
        XCTAssertEqual("https://jack.io/tx_approve", jackAsset.approvalServer)
        XCTAssertEqual("The jack approval server will ensure that transactions are compliant with NFO regulation", jackAsset.approvalCriteria)
    }
    
    
    func authRequired() async {
        var responseEnum = await service.authorizationRequired(asset: service.regulatedAssets.first!)
        switch responseEnum {
        case .success(let required):
            XCTAssertTrue(required)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
        
        responseEnum = await service.authorizationRequired(asset: service.regulatedAssets.last!)
        switch responseEnum {
        case .success(let required):
            XCTAssertFalse(required)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func postTransactionSuccess() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/success")
        switch responseEnum {
        case .success(let response):
            XCTAssertTrue(response.tx == self.txB64Xdr)
            XCTAssertTrue(response.message == "hello")
        case .failure(let err):
            XCTFail(err.localizedDescription)
        default:
            XCTFail()
        }
    }
    
    func postTransactionPending() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/pending")
        switch responseEnum {
        case .pending(let response):
            XCTAssertTrue(response.timeout == 10)
            XCTAssertTrue(response.message == "hello")
        case .failure(let err):
            XCTFail(err.localizedDescription)
        default:
            XCTFail()
        }
    }
    
    func postTransactionRevised() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/revised")
        switch responseEnum {
        case .revised(let response):
            XCTAssertTrue(response.tx == self.txB64Xdr + self.txB64Xdr)
            XCTAssertTrue(response.message == "hello")
        case .failure(let err):
            XCTFail(err.localizedDescription)
        default:
            XCTFail()
        }
    }
    
    func postTransactionRejected() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/rejected")
        switch responseEnum {
        case .rejected(let response):
            XCTAssertTrue(response.error == "hello")
        case .failure(let err):
            XCTFail(err.localizedDescription)
        default:
            XCTFail()
        }
    }
    
    func postTransactionActionRequired() async {
        let goatAsset = service.regulatedAssets.first!
        let responseEnum = await service.postTransaction(txB64Xdr: self.txB64Xdr, apporvalServer: goatAsset.approvalServer + "/action_required")
        switch responseEnum {
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
    }
    
    func postActionFollowNext() async {
        let responseEnum = await service.postAction(url: "http://goat.io/action/next", actionFields: ["email_addres" : "test@gmail.com"])
        switch responseEnum {
        case .nextUrl(let response):
            XCTAssertTrue(response.message == "Please submit mobile number")
            XCTAssertTrue(response.nextUrl == "http://goat.io/action")
        case .failure(let err):
            XCTFail(err.localizedDescription)
        default:
            XCTFail()
        }
    }
    
    func postActionDone() async {
        let responseEnum = await service.postAction(url: "http://goat.io/action/done", actionFields: ["mobile_number" : "+347282983922"])
        switch responseEnum {
        case .done:
            return
        case .failure(let err):
            XCTFail(err.localizedDescription)
        default:
            XCTFail()
        }
    }
}

