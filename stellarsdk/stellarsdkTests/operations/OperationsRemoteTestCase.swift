//
//  OperationsRemoteTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class OperationsRemoteTestCase: XCTestCase {
    let sdk = StellarSDK()
    
    var streamItem:OperationsStreamItem? = nil
    var effectsStreamItem:EffectsStreamItem? = nil

    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let IOMIssuingAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    let accountToMergeKeyPair = try! KeyPair.generateRandomKeyPair()
    let accountToSponsorKeyPair = try! KeyPair.generateRandomKeyPair()
    let trustingAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    var claimableBalanceId:String? = nil
    var transactionId:String? = nil
    var ledger:Int? = nil
    var operationId:String? = nil
    
    override func setUp() async throws {
        try await super.setUp()

        let testAccountId = testKeyPair.accountId
        let issuingAccountId = IOMIssuingAccountKeyPair.accountId
        
        let IOMAsset = ChangeTrustAsset(canonicalForm: "IOM:" + issuingAccountId)!
        let changeTrustOp = ChangeTrustOperation(sourceAccountId:testAccountId, asset:IOMAsset, limit: 100000000)
        let claimant = Claimant(destination:testAccountId)
        let createClaimableBalance = CreateClaimableBalanceOperation(asset: IOMAsset, amount: 1.00, claimants: [claimant], sourceAccountId: issuingAccountId)
        let createAccountOp = CreateAccountOperation(sourceAccountId: testAccountId, destination: accountToMergeKeyPair, startBalance: 100.0)
        let createAccountOp2 = CreateAccountOperation(sourceAccountId: testAccountId, destination: trustingAccountKeyPair, startBalance: 100.0)
        let createAccountOp3 = CreateAccountOperation(sourceAccountId: testAccountId, destination: accountToSponsorKeyPair, startBalance: 100.0)
        let paymentOp1 = try! PaymentOperation(sourceAccountId: issuingAccountId, destinationAccountId: testAccountId, asset: IOMAsset, amount: 20000)
        
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
            XCTFail("could not create issuing account: \(issuingAccountId)")
        }
        
        let accDetailsResEnum = await self.sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp, createClaimableBalance,
                                                           createAccountOp, createAccountOp2,
                                                           createAccountOp3, paymentOp1],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.IOMIssuingAccountKeyPair, network: Network.testnet)
            
            let submitTxResponse = await self.sdk.transactions.submitTransaction(transaction: transaction);
            switch submitTxResponse {
            case .success(let response):
                XCTAssert(response.operationCount > 0)
                self.transactionId = response.transactionHash
                self.ledger = response.ledger
                switch response.transactionResult.resultBody {
                case .success(let array):
                    for opResult in array {
                        switch opResult {
                        case .createClaimableBalance(_, let createClaimableBalanceResultXDR):
                            switch createClaimableBalanceResultXDR {
                            case .success(_, let claimableBalanceIDXDR):
                                switch claimableBalanceIDXDR {
                                case .claimableBalanceIDTypeV0(let data):
                                    self.claimableBalanceId = self.hexEncodedBalanceId(data: data.wrapped)
                                }
                            default:
                                break
                            }
                        default:
                            break
                        }
                    }
                default:
                    break
                }
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
        
        XCTAssertNotNil(self.transactionId)
        XCTAssertNotNil(self.ledger)
        XCTAssertNotNil(self.claimableBalanceId)
        
    }
    
    func testAll() async {
        await getOperations()
        await getOperationsForAccount()
        await getOperationsForClaimableBalance()
        await getOperationsForLedger()
        await getOperationsForTransaction()
        await getOperationDetails()
        await createAccount()
        await updateHomeDomain()
        await accountMerge()
        await changeTrustline()
        await mangeOffer()
        await createPassiveSellOffer()
        await manageAccountData()
        await createClaimableBalances()
        await getClaimableBalancesForSponsor()
        await getClaimableBalancesForClaimant()
        await getClaimableBalancesForAsset()
        await claimClaimableBalance()
        await sponsorship()
        await sponsorship2()
        await issue169()
        await issue170()
    }
        
    func getOperations() async {
        let operationsResEnum = await sdk.operations.getOperations()
        switch operationsResEnum {
        case .success(let firstPage):
            let nextPageResult = await firstPage.getNextPage()
            switch nextPageResult {
            case .success(let nextPage):
                let prevPageResult = await nextPage.getPreviousPage()
                switch prevPageResult {
                case .success(let page):
                    XCTAssertTrue(page.records.count > 0)
                    XCTAssertTrue(firstPage.records.count > 0)
                    let operation1 = firstPage.records.first!
                    let operation2 = page.records.last! // because ordering is asc now.
                    XCTAssertTrue(operation1.id == operation2.id)
                    XCTAssertTrue(operation1.sourceAccount == operation2.sourceAccount)
                    XCTAssertTrue(operation1.sourceAccount == operation2.sourceAccount)
                    XCTAssertTrue(operation1.operationTypeString == operation2.operationTypeString)
                    XCTAssertTrue(operation1.operationType == operation2.operationType)
                    XCTAssertTrue(operation1.createdAt == operation2.createdAt)
                    XCTAssertTrue(operation1.transactionHash == operation2.transactionHash)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperations()", horizonRequestError: error)
                    XCTFail("failed to load prev page")
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperations()", horizonRequestError: error)
                XCTFail("failed to load next page")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperations()", horizonRequestError: error)
            XCTFail("failed to load operations")
        }
    }
    
    func getOperationsForAccount() async {
        let responseEnum = await sdk.operations.getOperations(forAccount: testKeyPair.accountId, from: nil, order: Order.descending, includeFailed: true, join: "transactions")
        switch responseEnum {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForAccount()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getOperationsForClaimableBalance() async {
        let claimableBalanceId = self.claimableBalanceId!
        let responseEnum = await sdk.operations.getOperations(forClaimableBalance: claimableBalanceId, from: nil, order: Order.descending, includeFailed: true, join: "transactions")
        switch responseEnum {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForClaimableBalance()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getOperationsForLedger() async {
        let responseEnum = await sdk.operations.getOperations(forLedger: String(self.ledger!), includeFailed:false, join:"transactions")
        switch responseEnum {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
            self.operationId = page.records.first!.id
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForLedger()", horizonRequestError: error)
            XCTFail()
        }
        XCTAssertNotNil(self.operationId)
    }
    
    func getOperationsForTransaction() async {
        
        let responseEnum = await sdk.operations.getOperations(forTransaction: self.transactionId!, includeFailed:true, join:"transactions")
        switch responseEnum {
        case .success(let page):
            XCTAssertFalse(page.records.isEmpty)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForLedger()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getOperationDetails() async {
        let responseEnum = await sdk.operations.getOperationDetails(operationId: self.operationId!, join:"transactions")
        switch responseEnum {
        case .success(let details):
            XCTAssertTrue(details.transactionSuccessful)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationDetails()", horizonRequestError: error)
            XCTFail("could not load op details for op \(self.operationId!)")
        }
    }
    
    func createAccount() async {
        let expectation = XCTestExpectation(description: "Create and fund a new account")
        let sourceAccountKeyPair = testKeyPair
        let destinationKeyPair = try! KeyPair.generateRandomKeyPair()

        streamItem = sdk.operations.stream(for: .operationsForAccount(account:destinationKeyPair.accountId, cursor:nil))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let _ = operationResponse as? AccountCreatedOperationResponse {
                    self.streamItem?.closeStream()
                    self.streamItem = nil
                    XCTAssert(true)
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createAccount()", horizonRequestError:horizonRequestError)
                } else {
                    print("createAccount: Stream error on destination account: \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let createAccount = try! CreateAccountOperation(sourceAccountId: nil, destinationAccountId: destinationKeyPair.accountId, startBalance: 2.0)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [createAccount],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: sourceAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createAccount()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createAccount()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
    }
    
    func updateHomeDomain() async {
        let expectation = XCTestExpectation(description: "Set www.soneso.com as home domain")
        let sourceAccountKeyPair = testKeyPair
        let homeDomain = "http://www.soneso.com"
        
        streamItem = sdk.operations.stream(for: .operationsForAccount(account:sourceAccountKeyPair.accountId, cursor:"now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let updateHomeDomainResponse = operationResponse as?  SetOptionsOperationResponse {
                    if let responseHomeDomain = updateHomeDomainResponse.homeDomain {
                        if homeDomain == responseHomeDomain {
                            self.streamItem?.closeStream()
                            self.streamItem = nil
                            expectation.fulfill()
                        }
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"UDH Test - source", horizonRequestError:horizonRequestError)
                } else {
                    print("updateHomeDomain stream error \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let setHomeDomainOperation = try! SetOptionsOperation(sourceAccountId: sourceAccountKeyPair.accountId, homeDomain: homeDomain)
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [setHomeDomainOperation],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: sourceAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createAccount()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createAccount()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    
    }
    
    func accountMerge() async {
        let sourceAccountKeyPair = accountToMergeKeyPair
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let muxDestination = try! MuxedAccount(accountId: self.testKeyPair.accountId,  id: 100000029292)
            let mergeAccountOperation = try! AccountMergeOperation(destinationAccountId: muxDestination.accountId, sourceAccountId: accountResponse.accountId)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [mergeAccountOperation],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: sourceAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"accountMerge()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"accountMerge()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
    }
    
    func changeTrustline() async {
        let expectation = XCTestExpectation(description: "Change trustline, allow destination account to receive IOM - our sdk token")
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        let IOM = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        let trustingAccountKeyPair = trustingAccountKeyPair
    
        
        streamItem = sdk.operations.stream(for: .operationsForAccount(account: trustingAccountKeyPair.accountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, let operationResponse):
                if let changeTrustlineResponse = operationResponse as? ChangeTrustOperationResponse {
                    if let assetCode = changeTrustlineResponse.assetCode, let assetIssuer = changeTrustlineResponse.assetIssuer, let limit = changeTrustlineResponse.limit {
                        if assetCode == "IOM", assetIssuer ==  issuingAccountKeyPair.accountId, limit == "100000000.0000000" {
                            self.streamItem?.closeStream()
                            self.streamItem = nil
                            expectation.fulfill()
                        }
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"changeTrustline - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("changeTrustline stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: trustingAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let changeTrustOp = ChangeTrustOperation(sourceAccountId:accountResponse.accountId, asset:IOM!, limit: 100000000)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: trustingAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"changeTrustline()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"changeTrustline()", horizonRequestError: error)
            XCTFail("could not load account details for \(trustingAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }

    func mangeOffer() async {
        let expectation = XCTestExpectation(description: "Create an offer for IOM, the sdk token.")
        let sourceAccountKeyPair = testKeyPair
        
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        let XLM = Asset(type: AssetType.ASSET_TYPE_NATIVE)
        
        streamItem = sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, let operationResponse):
                if let manageOfferResponse = operationResponse as? ManageSellOfferOperationResponse {
                    if manageOfferResponse.buyingAssetType == AssetTypeAsString.NATIVE, manageOfferResponse.offerId == "0" {
                        self.streamItem?.closeStream()
                        self.streamItem = nil
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"MOF Test - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("mangeOffer: stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let random = arc4random_uniform(21) + 10;
            let manageOfferOperation = ManageSellOfferOperation(sourceAccountId:nil, selling:IOM!, buying:XLM!,
                                                                amount:Decimal(random),
                                                                price:Price(numerator:5, denominator:15),
                                                                offerId:0)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [manageOfferOperation],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: sourceAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"mangeOffer()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"mangeOffer()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func createPassiveSellOffer() async {
        let expectation = XCTestExpectation(description: "Create a passive offer for IOM, the sdk token.")
        let sourceAccountKeyPair = testKeyPair
        
        let issuingAccountKeyPair = try! KeyPair(accountId: IOMIssuingAccountKeyPair.accountId)
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        let XLM = Asset(type: AssetType.ASSET_TYPE_NATIVE)
        
        
        streamItem = sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, let operationResponse):
                if let createOfferResponse = operationResponse as? CreatePassiveSellOfferOperationResponse {
                    if createOfferResponse.buyingAssetType == AssetTypeAsString.NATIVE {
                        XCTAssert(true)
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CPO Test - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("createPassiveSellOffer: stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let random = arc4random_uniform(81) + 10;
            
            let createPassiveSellOfferOperation = CreatePassiveSellOfferOperation(sourceAccountId:sourceAccountKeyPair.accountId,
                                                                                  selling:IOM!,
                                                                                  buying:XLM!,
                                                                                  amount:Decimal(random),
                                                                                  price:Price(numerator:6, denominator:17))
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [createPassiveSellOfferOperation],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: sourceAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createPassiveSellOffer()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createPassiveSellOffer()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func manageAccountData() async {
        let expectation = XCTestExpectation(description: "Add a key value pair to an account")
        let sourceAccountKeyPair = testKeyPair
        
        let name = "soneso"
        let value = "is super"
        
        streamItem = sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, let operationResponse):
                if let manageDataResponse = operationResponse as? ManageDataOperationResponse {
                    if (manageDataResponse.name == name && manageDataResponse.value.base64Decoded() == value) {
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"manageAccountData - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("manageAccountData stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let manageDataOperation = ManageDataOperation(sourceAccountId:sourceAccountKeyPair.accountId, name:name, data:value.data(using: .utf8))
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [manageDataOperation],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: sourceAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"manageAccountData()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"manageAccountData()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }

    func createClaimableBalances() async {
        let expectation = XCTestExpectation(description: "can create claimable balances")
        let sourceAccountKeyPair = testKeyPair
        let sourceAccountId = sourceAccountKeyPair.accountId

        var balanceId = "-1"
        
        effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:sourceAccountId, cursor: "now"))
        effectsStreamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let effectResponse):
                if let effect = effectResponse as? ClaimableBalanceCreatedEffectResponse {
                    if effect.balanceId.hasSuffix(balanceId) {
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("createClaimableBalances stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let firstClaimant = Claimant(destination:"GDSHZPWSL5QBQKKDQNECFPI2PF7JQUACNWG65PMFOK6G5V4QBH4CX2KH")
            let predicateA = Claimant.predicateBeforeRelativeTime(seconds: 100)
            let predicateB = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1634000400)
            let predicateC = Claimant.predicateNot(predicate: predicateA)
            let predicateD = Claimant.predicateAnd(left: predicateC, right: predicateB)
            let predicateE = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1601671345)
            let predicateF = Claimant.predicateOr(left: predicateD, right: predicateE)
            let secondClaimant = Claimant(destination:"GAHHMAYMOTYPHQQEIPZNHPOXMSIBYR6LSU2BDW4GAFQH6HKA56U7EDE6",predicate: predicateF)
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: self.IOMIssuingAccountKeyPair)
            
            let claimants = [ firstClaimant, secondClaimant]
            let createClaimableBalance = CreateClaimableBalanceOperation(asset: IOM!, amount: 2.00, claimants: claimants)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [createClaimableBalance],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: sourceAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let submitTransactionResponse):
                XCTAssertTrue(submitTransactionResponse.operationCount > 0)
                switch submitTransactionResponse.transactionResult.resultBody {
                case .success(let array):
                    for opResult in array {
                        switch opResult {
                        case .createClaimableBalance(_, let createClaimableBalanceResultXDR):
                            switch createClaimableBalanceResultXDR {
                            case .success(_, let claimableBalanceIDXDR):
                                switch claimableBalanceIDXDR {
                                case .claimableBalanceIDTypeV0(let data):
                                    balanceId = self.hexEncodedBalanceId(data: data.wrapped)
                                }
                            default:
                                break
                            }
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalances()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalances()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        await fulfillment(of: [expectation], timeout: 15.0)
    }
   
    func getClaimableBalancesForSponsor() async {
        let sourceAccountKeyPair = testKeyPair
        let sourceAccountId = sourceAccountKeyPair.accountId
        let responseEnum = await sdk.claimableBalances.getClaimableBalances(sponsorAccountId: sourceAccountId, order:Order.descending)
        switch responseEnum {
        case .success(let page):
            XCTAssert(page.records.count > 0)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"claimableBalancesForSponsor()", horizonRequestError: error)
            XCTFail("could not get claimable balances for sponsor \(sourceAccountId)")
        }
    }
    
    func getClaimableBalancesForClaimant() async {
        let claimantAccountId = "GDSHZPWSL5QBQKKDQNECFPI2PF7JQUACNWG65PMFOK6G5V4QBH4CX2KH"
        
        let responseEnum = await sdk.claimableBalances.getClaimableBalances(claimantAccountId: claimantAccountId, order:Order.descending)
        switch responseEnum {
        case .success(let page):
            XCTAssert(page.records.count > 0)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getClaimableBalancesForClaimant()", horizonRequestError: error)
            XCTFail("could not get claimable balances for claimantAccountId \(claimantAccountId)")
        }
    }
    
    func getClaimableBalancesForAsset() async {
        let native = "native"
        let responseEnum = await sdk.claimableBalances.getClaimableBalances(asset: Asset.init(canonicalForm: native)!, order:Order.descending)
        switch responseEnum {
        case .success(let page):
            XCTAssert(page.records.count > 0)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getClaimableBalancesForAsset()", horizonRequestError: error)
            XCTFail("could not get claimable balances for asset native")
        }
    }
    
    func claimClaimableBalance() async {
        let expectation = XCTestExpectation(description: "can claim claimable balance")
        let balanceId = self.claimableBalanceId!
        let claimantAccountKeyPair = testKeyPair
        let claimantAccountId = claimantAccountKeyPair.accountId
       
        effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:claimantAccountId, cursor: "now"))
        effectsStreamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let effectResponse):
                if let effect = effectResponse as? ClaimableBalanceClaimedEffectResponse {
                    if effect.balanceId.hasSuffix(balanceId) {
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("claimClaimableBalance stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: claimantAccountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            // test also acceptance of claimable balance ids in their strkey representation
            var requestBalanceId = balanceId
            if (requestBalanceId.isHexString()) {
                // convert to strkey representation
                requestBalanceId = try! requestBalanceId.encodeClaimableBalanceIdHex()
            }
            let claimClaimableBalanceOp = ClaimClaimableBalanceOperation(balanceId: requestBalanceId)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [claimClaimableBalanceOp],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: claimantAccountKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"claimClaimableBalance()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"claimClaimableBalance()", horizonRequestError: error)
            XCTFail("could not load account details for \(claimantAccountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    
    func sponsorship() async {
        let masterAccountKeyPair = testKeyPair
        let masterAccountId = masterAccountKeyPair.accountId
        let accountAKeyPair = try! KeyPair.generateRandomKeyPair()
        let accountAId = accountAKeyPair.accountId
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: masterAccountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let begingSponsorshipOp = BeginSponsoringFutureReservesOperation(sponsoredAccountId: accountAId)
            
            let createAccountOp = CreateAccountOperation(sourceAccountId: masterAccountId, destination: accountAKeyPair, startBalance: 10.0)
            let name = "soneso"
            let value = "is super"
            let manageDataOp = ManageDataOperation(sourceAccountId: accountAId, name: name, data: value.data(using: .utf8))
            let richAsset = ChangeTrustAsset(canonicalForm: "RICH:" + masterAccountId)!
            let nativeAsset = Asset(canonicalForm: "native")!
            let changeTrustOp = ChangeTrustOperation(sourceAccountId: accountAId, asset: richAsset, limit: 10000.00)
            let payRichOp = try! PaymentOperation(sourceAccountId:masterAccountId, destinationAccountId: accountAId, asset: richAsset, amount: 100)
            let claimantM = Claimant(destination: masterAccountId)
            let createOfferOp = ManageSellOfferOperation(sourceAccountId: accountAId, selling: richAsset, buying: nativeAsset, amount: 10, price: Price(numerator: 2, denominator: 5), offerId: 0)
            
            let createClaimableBalanceAOp = CreateClaimableBalanceOperation(asset: Asset(canonicalForm: "native")!, amount: 2, claimants: [claimantM], sourceAccountId: accountAId)
            
            let signerKey = Signer.sha256Hash(hash: "stellar.org".sha256Hash)
            let addSignerOperation = try! SetOptionsOperation(sourceAccountId:accountAId, signer:signerKey, signerWeight: 1)
            
            let accSignerKey =  try! Signer.ed25519PublicKey(accountId: masterAccountId)
            let addAccSignerOperation = try! SetOptionsOperation(sourceAccountId:accountAId, signer:accSignerKey, signerWeight: 1)
            
            let endSponsoringOp = EndSponsoringFutureReservesOperation(sponsoredAccountId: accountAId)
            
            let revokeAccountLedgerKeyXdr = try! RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(accountId:accountAId)
            let revokeAccountSponsorshipOp = RevokeSponsorshipOperation(ledgerKey: revokeAccountLedgerKeyXdr, sourceAccountId: masterAccountId)
            
            let revokeDataLedgerKeyXdr = try! RevokeSponsorshipOperation.revokeDataSponsorshipLedgerKey(accountId:accountAId,dataName:name)
            let revokeDataSponsorshipOp = RevokeSponsorshipOperation(ledgerKey: revokeDataLedgerKeyXdr, sourceAccountId: masterAccountId)
            
            let revokeTrustlineLedgerKeyXdr = try! RevokeSponsorshipOperation.revokeTrustlineSponsorshipLedgerKey(accountId:accountAId, asset:richAsset)
            let revokeTrustlineSponsorshipOp = RevokeSponsorshipOperation(ledgerKey: revokeTrustlineLedgerKeyXdr, sourceAccountId: masterAccountId)
            
            let revokeSignerSponsorshipOp = RevokeSponsorshipOperation(signerAccountId: accountAId, signerKey: signerKey)
            let revokeAccSignerSponsorshipOp = RevokeSponsorshipOperation(signerAccountId: accountAId, signerKey: accSignerKey)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [begingSponsorshipOp, createAccountOp, manageDataOp, changeTrustOp, payRichOp, createClaimableBalanceAOp, createOfferOp, addSignerOperation, addAccSignerOperation, endSponsoringOp, revokeAccountSponsorshipOp, revokeDataSponsorshipOp, revokeTrustlineSponsorshipOp, revokeSignerSponsorshipOp, revokeAccSignerSponsorshipOp],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: masterAccountKeyPair, network: .testnet))
            XCTAssertNoThrow(try transaction.sign(keyPair: accountAKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorship()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorship()", horizonRequestError: error)
            XCTFail("could not load account details for \(masterAccountId)")
        }
    }
    
    
    func sponsorship2() async {
        let masterAccountKeyPair = testKeyPair
        let masterAccountId = masterAccountKeyPair.accountId
        let accountAKeyPair = accountToSponsorKeyPair
        let accountAId = accountAKeyPair.accountId
        let issuingAccountKeyPair = try! KeyPair(accountId: IOMIssuingAccountKeyPair.accountId)
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: masterAccountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let begingSponsorshipOp = BeginSponsoringFutureReservesOperation(sponsoredAccountId: accountAId,sponsoringAccountId: masterAccountId)
        
            
            let IOM = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            let changeTrustOp = ChangeTrustOperation(sourceAccountId: accountAId, asset: IOM!, limit: 10000.00)
            
            let endSponsoringOp = EndSponsoringFutureReservesOperation(sponsoredAccountId: accountAId)
            
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [begingSponsorshipOp, changeTrustOp, endSponsoringOp],
                                              memo: Memo.none)
            
            XCTAssertNoThrow(try transaction.sign(keyPair: masterAccountKeyPair, network: .testnet))
            XCTAssertNoThrow(try transaction.sign(keyPair: accountAKeyPair, network: .testnet))
 
            let submitTxResultEnum = await self.sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorship()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorship()", horizonRequestError: error)
            XCTFail("could not load account details for \(masterAccountId)")
        }
    }
     
    func issue169() async {
        let publicSdk = StellarSDK.publicNet()
        let opId = "243686570245677057"
        let operationResponseEnum = await publicSdk.operations.getOperationDetails(operationId: opId)
        switch operationResponseEnum {
        case .success(let details):
            guard let invokeDetails = details as? InvokeHostFunctionOperationResponse else {
                XCTFail("not invoke host func op")
                return
            }
            guard let assetBalanceChanges = invokeDetails.assetBalanceChanges else {
                XCTFail("no asset balance changes found")
                return
            }
            XCTAssertTrue(assetBalanceChanges.count > 0)
        case .failure(_):
            XCTFail("could not load operation details for operation id: \(opId)")
        }
    }
    
    func issue170() async {
        let publicSdk = StellarSDK.publicNet()
        let responseEnum = await publicSdk.operations.getOperationDetails(operationId: "235893644145414236")
        switch responseEnum {
        case .success(let details):
            guard let cOp = details as? CreateClaimableBalanceOperationResponse else {
                XCTFail()
                return
            }
            XCTAssertNil(cOp.sponsor)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"issue170()", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func hexEncodedBalanceId(data: Data) -> String {
        let hexDigits = Array(("0123456789abcdef").utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * data.count)
        for byte in data {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        var z = String(utf16CodeUnits: chars, count: chars.count)
        let leadingZeros = 72 - chars.count
        if (leadingZeros > 0){
            z = String(format: "%0"+String(leadingZeros)+"d", 0) + z
        }
        return z
    }
}
