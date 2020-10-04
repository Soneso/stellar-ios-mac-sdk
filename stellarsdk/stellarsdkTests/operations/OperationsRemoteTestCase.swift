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
    
    let seed = "SC5DJLUVRNNYR3M4IZUHJKYHKWLEYXTI6IZ2CZCGS45IIBNLVCFJFVW7"
    let IOMIssuingAccountId = "GCP76QULG2X3SKYG4Z3OYY3DJJXWSQ7NTTJCH4E3EOLUQDAJU2AU6ZVI"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetOperations() {
        let expectation = XCTestExpectation(description: "Get operations and parse their details successfully")
        
        sdk.operations.getOperations { (response) -> (Void) in
            switch response {
            case .success(let operationsResponse):
                // load next page
                operationsResponse.getNextPage(){ (response) -> (Void) in
                    switch response {
                    case .success(let nextOperationsResponse):
                        // load previous page, should contain the same operations as the first page
                        nextOperationsResponse.getPreviousPage(){ (response) -> (Void) in
                            switch response {
                            case .success(let prevOperationsResponse):
                                let operation1 = operationsResponse.records.first
                                let operation2 = prevOperationsResponse.records.last // because ordering is asc now.
                                XCTAssertTrue(operation1?.id == operation2?.id)
                                XCTAssertTrue(operation1?.sourceAccount == operation2?.sourceAccount)
                                XCTAssertTrue(operation1?.sourceAccount == operation2?.sourceAccount)
                                XCTAssertTrue(operation1?.operationTypeString == operation2?.operationTypeString)
                                XCTAssertTrue(operation1?.operationType == operation2?.operationType)
                                XCTAssertTrue(operation1?.createdAt == operation2?.createdAt)
                                XCTAssertTrue(operation1?.transactionHash == operation2?.transactionHash)
                                XCTAssert(true)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GO Test", horizonRequestError: error)
                                XCTAssert(false)
                            }
                        }
                    case .failure(let error):
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"GO Test", horizonRequestError: error)
                        XCTAssert(false)
                    }
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GO Test", horizonRequestError: error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationsForAccount() {
        let expectation = XCTestExpectation(description: "Get operations for account")
        let accountID = try! KeyPair(secretSeed: seed).accountId
        sdk.operations.getOperations(forAccount: accountID, from: nil, order: Order.descending, includeFailed: true, join: "transactions") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOFA Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationsForLedger() {
        let expectation = XCTestExpectation(description: "Get operations for ledger")
        
        sdk.operations.getOperations(forLedger: "180983", includeFailed:true, join:"transactions") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOFL Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationsForTransaction() {
        let expectation = XCTestExpectation(description: "Get operations for transaction")
        
        sdk.operations.getOperations(forTransaction: "a5287f0dc3cb3ea088722f25927125aed4c78bf49051c530c4ca04a07a2103e8", includeFailed:true, join:"transactions") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOFT Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationDetails() {
        let expectation = XCTestExpectation(description: "Get operation details")
        
        sdk.operations.getOperationDetails(operationId: "777015418425345", join:"transactions") { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GOD Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }

    func testCreateAccount() {
        let expectation = XCTestExpectation(description: "Create and fund a new account")
        do {
            
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            let destinationKeyPair = try KeyPair.generateRandomKeyPair()
            print ("CA Test: Source account id: \(sourceAccountKeyPair.accountId)")
            print("CA Test: New destination keipair created with secret seed: \(destinationKeyPair.secretSeed!) and accountId: \(destinationKeyPair.accountId)")

    
            streamItem = sdk.operations.stream(for: .operationsForAccount(account:destinationKeyPair.accountId, cursor:nil))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(let id, let operationResponse):
                    if let accountCreatedResponse = operationResponse as? AccountCreatedOperationResponse {
                        print("CA Test: Stream source account received response with effect-ID: \(id) - type: Account created - New account with accountId: \(accountCreatedResponse.account) now has a balance of : \(accountCreatedResponse.startingBalance) XLM" )
                        print("CA Test: Success")
                        self.streamItem?.closeStream()
                        self.streamItem = nil
                        XCTAssert(true)
                        expectation.fulfill()
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCA Test - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("CA Test: Stream error on destination account: \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let createAccount = CreateAccountOperation(sourceAccount: nil, destination: destinationKeyPair, startBalance: 2.0)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [createAccount],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("CA Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CA Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"GT Test send error", horizonRequestError: error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CA Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
        
    }
    
    func testUpdateHomeDomain() {
        let expectation = XCTestExpectation(description: "Set www.soneso.com as home domain")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            print ("Account ID: \(sourceAccountKeyPair.accountId)")
            
            let homeDomain = "http://www.soneso.com"
            print ("Home domain: \(homeDomain)")
            
            streamItem = sdk.operations.stream(for: .operationsForAccount(account:sourceAccountKeyPair.accountId, cursor:"now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let operationResponse):
                    if let updateHomeDomainResponse = operationResponse as?  SetOptionsOperationResponse {
                        if let responseHomeDomain = updateHomeDomainResponse.homeDomain {
                            print("UHD Test: Home domain updated to: \(responseHomeDomain)-" )
                            if homeDomain == responseHomeDomain {
                                print("Success")
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
                        print("UID Test stream error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        
                        let setHomeDomainOperation = try SetOptionsOperation(homeDomain: homeDomain)
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [setHomeDomainOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        
                        let thash = try transaction.getTransactionHash(network: Network.testnet)
                        print("Transaction hash: \(thash)")
                        
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        let tenvelope = try transaction.encodedEnvelope()
                        print ("Transaction envelope: \(tenvelope)")
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("UHD Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("UHD Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"UHD Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"UHD Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
        
    }
    
    func testAccountMerge() {
        let expectation = XCTestExpectation(description: "account merged")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SA45WOS6WCPPHKHAIXTH6RK5ACXMVWQ2MEIDSG6VYAXX3O5GFXMEZ3JW")
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let muxDestination = try MuxedAccount(accountId: "GALA3JYOCVM4ENFPXMMXQBFGTQZKWRIOAVZSHGGNUVC4KOGOB3A4EFGZ",  id: 100000029292)
                        
                        print("dest:\(muxDestination.accountId)")
                        
                        let mergeAccountOperation = try AccountMergeOperation(destinationAccountId: muxDestination.accountId, sourceAccountId: accountResponse.accountId)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [mergeAccountOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("AM Test: Transaction successfully sent. Hash: \(response.transactionHash)")
                                XCTAssert(true)
                                expectation.fulfill()
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("AM Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"AM Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"AM Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
        
    }
    
    func testUpdateInflationDestination() {
        let expectation = XCTestExpectation(description: "Set inflation destination")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            print ("UID Test source account id: \(sourceAccountKeyPair.accountId)")
            let destinationAccountId = IOMIssuingAccountId
            
            streamItem = sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let setOptionsResponse = operationResponse as? SetOptionsOperationResponse {
                        if (setOptionsResponse.inflationDestination == destinationAccountId) {
                            self.streamItem?.closeStream()
                            self.streamItem = nil
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"UID Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("UID Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let setInflationOperation = try SetOptionsOperation(inflationDestination: KeyPair(accountId:destinationAccountId))
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [setInflationOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("UID Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("UID Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"UID Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"UID Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
        
    }
    
    func testChangeTrustline() {
        let expectation = XCTestExpectation(description: "Change trustline, allow destination account to receive IOM - our sdk token")
        do {
            
            let issuingAccountKeyPair = try KeyPair(accountId: IOMIssuingAccountId)
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            let trustingAccountKeyPair = try KeyPair(secretSeed: seed)
            
            printAccountDetails(tag: "CTL Test - trusting account", accountId: trustingAccountKeyPair.accountId)
            
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
                                XCTAssert(true)
                                expectation.fulfill()
                            }
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"UID Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CTL Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: trustingAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let changeTrustOp = ChangeTrustOperation(asset:IOM!, limit: 100000000)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [changeTrustOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        
                        try transaction.sign(keyPair: trustingAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("CTL Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CLT Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CTL Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CTL Test", horizonRequestError:error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testManageOffer() {
        let expectation = XCTestExpectation(description: "Create an offer for IOM, the sdk token.")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            print ("MOF Test source accountId: \(sourceAccountKeyPair.accountId)")
            
            let issuingAccountKeyPair = try KeyPair(accountId: IOMIssuingAccountId)
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
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"MOF Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("MOF Test: stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let random = arc4random_uniform(21) + 10;
                        let manageOfferOperation = ManageSellOfferOperation(selling:IOM!, buying:XLM!, amount:Decimal(random), price:Price(numerator:5, denominator:15), offerId:0)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [manageOfferOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("MOF Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("MDF Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"MOF Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"MOF Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testCreatePassiveSellOffer() {
        let expectation = XCTestExpectation(description: "Create a passive offer for IOM, the sdk token.")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            print ("CPO Test source accountId: \(sourceAccountKeyPair.accountId)")
            
            let issuingAccountKeyPair = try KeyPair(accountId: IOMIssuingAccountId)
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
                        print("CPO Test: stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let random = arc4random_uniform(81) + 10;
                        
                        let createPassiveSellOfferOperation = CreatePassiveSellOfferOperation(selling:IOM!, buying:XLM!, amount:Decimal(random), price:Price(numerator:6, denominator:17))
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [createPassiveSellOfferOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("CPO Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CPO Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CPO Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CPO Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testManageAccountData() {
        let expectation = XCTestExpectation(description: "Add a key value pair to an account")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            print ("MAD Test: source accoint Id \(sourceAccountKeyPair.accountId)")
            
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
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"MAD Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("MAD Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let manageDataOperation = ManageDataOperation(name:name, data:value.data(using: .utf8))
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [manageDataOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("MAD Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("MAD Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"MAD Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"MAD Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
            
        } catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func printAccountDetails(tag: String, accountId: String) {
        sdk.accounts.getAccountDetails(accountId: accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountResponse):
                print("\(tag): Account ID: \(accountResponse.accountId)")
                print("\(tag): Account Sequence: \(accountResponse.sequenceNumber)")
                for balance in accountResponse.balances {
                    if balance.assetType == AssetTypeAsString.NATIVE {
                        print("\(tag): Account balance: \(balance.balance) XLM")
                    } else {
                        print("\(tag): Account balance: \(balance.balance) \(balance.assetCode!) of issuer: \(balance.assetIssuer!)")
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func testCreateClaimableBalances() {
        let expectation = XCTestExpectation(description: "can create claimable balances")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            // GALA3JYOCVM4ENFPXMMXQBFGTQZKWRIOAVZSHGGNUVC4KOGOB3A4EFGZ
            let sourceAccountId = sourceAccountKeyPair.accountId
            print("acc: " + sourceAccountId)
            var balanceId = "-1"
            
            /*streamItem = sdk.operations.stream(for: .operationsForAccount(account: sourceAccountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let opr = operationResponse as? CreateClaimableBalanceOperationResponse {
                        print("OPR: amount: " + opr.amount)
                        XCTAssert(true)
                        expectation.fulfill()
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }*/
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:sourceAccountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? ClaimableBalanceCreatedEffectResponse {
                        print("ClaimableBalanceCreatedEffect received: balance_id: " + effect.balanceId)
                        if effect.balanceId.hasSuffix(balanceId) {
                            print("match:\(effect.balanceId)")
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let XLM = Asset(type: AssetType.ASSET_TYPE_NATIVE)
                        let moonIssuerKeypair = try KeyPair(accountId: "GCSODO5SLOZIAMJWUFZWKL4AIQRYCS6VZ55MQ5TF2SUO5QKVJW6TG2P5")
                        let MOON = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "MOON", issuer: moonIssuerKeypair)!
                        let firstClaimant = Claimant(destination:"GDQ7DUQ2KA5SZH5ZSBO7GNSG2XOGM5NVT5AWJQZRB2HCYGOTQ5VQ4QOH")
                        let predicateA = Claimant.predicateBeforeRelativeTime(seconds: 100)
                        let predicateB = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1634000400)
                        let predicateC = Claimant.predicateNot(predicate: predicateA)
                        let predicateD = Claimant.predicateAnd(left: predicateC, right: predicateB)
                        let predicateE = Claimant.predicateBeforeAbsoluteTime(unixEpoch: 1601671345)
                        let predicateF = Claimant.predicateOr(left: predicateD, right: predicateE)
                        let secondClaimant = Claimant(destination:"GCAVRAJT3OL7XUTGB54RSJKPASB5KNB66PB6HDOPVFBDKKY7XMPYSUIH",predicate: predicateF)
                        
                        let claimants = [ firstClaimant, secondClaimant]
                        let createClaimableBalance = CreateClaimableBalanceOperation(asset: MOON, amount: 2.00, claimants: claimants)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [createClaimableBalance],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let submitTransactionResponse):
                                print("CB Test: Transaction successfully sent:" + submitTransactionResponse.transactionHash)
                                switch submitTransactionResponse.transactionMeta {
                                case .transactionMetaV2(let metaV2):
                                    for opMeta in metaV2.operations {
                                        for change in opMeta.changes.ledgerEntryChanges {
                                            switch change {
                                            case .created(let entry):
                                                switch entry.data {
                                                case .claimableBalance(let IDXdr):
                                                    switch IDXdr.claimableBalanceID {
                                                    case .claimableBalanceIDTypeV0(let data):
                                                        balanceId = self.hexEncodedString(data: data.wrapped)
                                                        print("Balance Id: \(balanceId)")
                                                    }
                                                default:
                                                    break
                                                }
                                            default:
                                                break
                                            }
                                        }
                                    }
                                default:
                                    break
                                }
                                //XCTAssert(true)
                                //expectation.fulfill()
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CB Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        }
        catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 315.0)
    }
    
    
    func hexEncodedString(data: Data) -> String {
        let hexDigits = Array(("0123456789abcdef").utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * data.count)
        for byte in data {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        return String(utf16CodeUnits: chars, count: chars.count)
    }
    
    func testGetClaimableBalancesForSponsor() {
        let expectation = XCTestExpectation(description: "can get claimable balances for sponsor")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            let sourceAccountId = sourceAccountKeyPair.accountId
            print("acc: " + sourceAccountId)
            
            
            
            sdk.claimableBalances.getClaimableBalances(sponsorAccountId: sourceAccountId, order:Order.descending) { (response) -> (Void) in
                switch response {
                case .success(let pageResponse):
                    print("Records: \(pageResponse.records.count)")
                    for record in pageResponse.records {
                        print("NEXT RECORD")
                        print("balanceId: \(record.balanceId)")
                        print("asset: \(record.asset.toCanonicalForm())")
                        print("amount: \(record.amount)")
                        for claimant in record.claimants {
                            print("claimant destination id: \(claimant.destination)")
                            claimant.predicate.printPredicate()
                        }
                        print("last modified ledger: \(record.lastModifiedLedger)")
                        print("last modified time: \(record.lastModifiedTime)")
                    }
                    XCTAssert(true)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        }
        catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 315.0)
    }
    
    func testGetClaimableBalancesForClaimant() {
        let expectation = XCTestExpectation(description: "can get claimable balances for claimant")
        let claimantAccountId = "GDQ7DUQ2KA5SZH5ZSBO7GNSG2XOGM5NVT5AWJQZRB2HCYGOTQ5VQ4QOH"
        print("claimant account id: " + claimantAccountId)
        
        sdk.claimableBalances.getClaimableBalances(claimantAccountId: claimantAccountId, order:Order.descending) { (response) -> (Void) in
            switch response {
            case .success(let pageResponse):
                print("Records: \(pageResponse.records.count)")
                for record in pageResponse.records {
                    print("NEXT RECORD")
                    print("balanceId: \(record.balanceId)")
                    print("asset: \(record.asset.toCanonicalForm())")
                    print("amount: \(record.amount)")
                    for claimant in record.claimants {
                        print("claimant destination id: \(claimant.destination)")
                        claimant.predicate.printPredicate()
                    }
                    print("last modified ledger: \(record.lastModifiedLedger)")
                    print("last modified time: \(record.lastModifiedTime)")
                }
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 315.0)
    }
    
    func testGetClaimableBalancesForAsset() {
        let expectation = XCTestExpectation(description: "can get claimable balances for asset")
        
        let native = "native"
        //let moon = "MOON:GCSODO5SLOZIAMJWUFZWKL4AIQRYCS6VZ55MQ5TF2SUO5QKVJW6TG2P5"
        sdk.claimableBalances.getClaimableBalances(asset: Asset.init(canonicalForm: native)!, order:Order.descending) { (response) -> (Void) in
            switch response {
            case .success(let pageResponse):
                print("Records: \(pageResponse.records.count)")
                for record in pageResponse.records {
                    print("NEXT RECORD")
                    print("balanceId: \(record.balanceId)")
                    print("asset: \(record.asset.toCanonicalForm())")
                    print("amount: \(record.amount)")
                    for claimant in record.claimants {
                        print("claimant destination id: \(claimant.destination)")
                        claimant.predicate.printPredicate()
                    }
                    print("last modified ledger: \(record.lastModifiedLedger)")
                    print("last modified time: \(record.lastModifiedTime)")
                }
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                XCTAssert(false)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 315.0)
    }
    
    func testClaimClaimableBalance() {
        let expectation = XCTestExpectation(description: "can claim claimable balance")
        do {
            let balanceId = "0000000059f2fc357ce5e28d0de875e3c7e96dfa10c3624198f033a833447e709985a494"
            let claimantAccountKeyPair = try KeyPair(secretSeed:"SDDJMSYAUF5QBS2T6IIPUNBAHCNQ6LJ3GWK2KWYW5INSRUK5AEYPAZWK")
            let claimantAccountId = claimantAccountKeyPair.accountId
            print("claimant: " + claimantAccountId) //GDQ7DUQ2KA5SZH5ZSBO7GNSG2XOGM5NVT5AWJQZRB2HCYGOTQ5VQ4QOH
            
            /*streamItem = sdk.operations.stream(for: .operationsForAccount(account: claimantAccountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let opr = operationResponse as? ClaimClaimableBalanceOperationResponse {
                        if opr.balanceId.hasSuffix(balanceId) {
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }*/
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:claimantAccountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? ClaimableBalanceClaimedEffectResponse {
                        print("ClaimableBalanceClaimedEffect received: balance_id: " + effect.balanceId)
                        if effect.balanceId.hasSuffix(balanceId) {
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: claimantAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let claimClaimableBalanceOp = ClaimClaimableBalanceOperation(balanceId: balanceId)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [claimClaimableBalanceOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: claimantAccountKeyPair, network: Network.testnet)
                        
                        print(try transaction.transactionXDR.encodedEnvelope())
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let submitTransactionResponse):
                                print("CB Test: Transaction successfully sent:" + submitTransactionResponse.transactionHash)
                                //XCTAssert(true)
                                //expectation.fulfill()
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CB Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        }
        catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 315.0)
    }
    
    func testSponsorship() {
        let expectation = XCTestExpectation(description: "can begin and end sponsorship")
        do {
            
            let masterAccountKeyPair = try KeyPair(secretSeed:seed)
            let masterAccountId = masterAccountKeyPair.accountId
            let accountAKeyPair = try KeyPair.generateRandomKeyPair()
            let accountAId = accountAKeyPair.accountId
            print("MASTER ACCOUNT: " + masterAccountId)
            print("CREATED ACCOUNT: " + accountAId)
            
            /*streamItem = sdk.operations.stream(for: .operationsForAccount(account: masterAccountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let _ = operationResponse as? BeginSponsoringFutureReservesOperationResponse {
                        print("BEGIN")
                    }
                    if let _ = operationResponse as? EndSponsoringFutureReservesOperationResponse {
                        print("END")
                    }
                    if let _ = operationResponse as? RevokeSponsorshipOperationResponse {
                        print("REVOKE")
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            effectsStreamItem = sdk.effects.stream(for: .allEffects(cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let eff = effectResponse as? DataSponsorshipCreatedEffectResponse {
                        print("eff: data sponsorship created: " + eff.sponsor)
                    }
                    if let eff = effectResponse as? AccountSponsorshipCreatedEffectResponse {
                        print("eff: account sponsorship created " + eff.sponsor)
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }*/
            
            sdk.accounts.getAccountDetails(accountId: masterAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let begingSponsorshipOp = BeginSponsoringFutureReservesOperation(sponsoredAccountId: accountAId, sponsoringAccountId: masterAccountId)
                        
                        let createAccountOp = CreateAccountOperation(sourceAccountId: masterAccountId, destination: accountAKeyPair, startBalance: 10.0)
                        let name = "soneso"
                        let value = "is super"
                        let manageDataOp = ManageDataOperation(sourceAccountId: accountAId, name: name, data: value.data(using: .utf8))
                        let richAsset = Asset(canonicalForm: "RICH:" + masterAccountId)!
                        let nativeAsset = Asset(canonicalForm: "native")!
                        let changeTrustOp = ChangeTrustOperation(sourceAccountId: accountAId, asset: richAsset, limit: 10000.00)
                        let payRichOp = try PaymentOperation(sourceAccountId:masterAccountId, destinationAccountId: accountAId, asset: richAsset, amount: 100)
                        let claimantM = Claimant(destination: masterAccountId)
                        let createOfferOp = ManageSellOfferOperation(sourceAccountId: accountAId, selling: richAsset, buying: nativeAsset, amount: 10, price: Price(numerator: 2, denominator: 5), offerId: 0)
                        
                        let createClaimableBalanceAOp = CreateClaimableBalanceOperation(asset: Asset(canonicalForm: "native")!, amount: 2, claimants: [claimantM], sourceAccountId: accountAId)
                        
                        let signerKey = Signer.sha256Hash(hash: "stellar.org".sha256Hash)
                        let addSignerOperation = try SetOptionsOperation(sourceAccountId:accountAId, signer:signerKey, signerWeight: 1)
                        
                        let accSignerKey =  try Signer.ed25519PublicKey(accountId: masterAccountId)
                        let addAccSignerOperation = try SetOptionsOperation(sourceAccountId:accountAId, signer:accSignerKey, signerWeight: 1)
                        
                        let endSponsoringOp = EndSponsoringFutureReservesOperation(sponsoredAccountId: accountAId)
                        
                        let revokeAccountLedgerKeyXdr = try RevokeSponsorshipOperation.revokeAccountSponsorshipLedgerKey(accountId:accountAId)
                        let revokeAccountSponsorshipOp = RevokeSponsorshipOperation(ledgerKey: revokeAccountLedgerKeyXdr, sourceAccountId: masterAccountId)
                        
                        let revokeDataLedgerKeyXdr = try RevokeSponsorshipOperation.revokeDataSponsorshipLedgerKey(accountId:accountAId,dataName:name)
                        let revokeDataSponsorshipOp = RevokeSponsorshipOperation(ledgerKey: revokeDataLedgerKeyXdr, sourceAccountId: masterAccountId)
                        
                        let revokeTrustlineLedgerKeyXdr = try RevokeSponsorshipOperation.revokeTrustlineSponsorshipLedgerKey(accountId:accountAId, asset:richAsset)
                        let revokeTrustlineSponsorshipOp = RevokeSponsorshipOperation(ledgerKey: revokeTrustlineLedgerKeyXdr, sourceAccountId: masterAccountId)
                        
                        let revokeSignerSponsorshipOp = RevokeSponsorshipOperation(signerAccountId: accountAId, signerKey: signerKey)
                        let revokeAccSignerSponsorshipOp = RevokeSponsorshipOperation(signerAccountId: accountAId, signerKey: accSignerKey)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [begingSponsorshipOp, createAccountOp, manageDataOp, changeTrustOp, payRichOp, createClaimableBalanceAOp, createOfferOp, addSignerOperation, addAccSignerOperation, endSponsoringOp, revokeAccountSponsorshipOp, revokeDataSponsorshipOp, revokeTrustlineSponsorshipOp, revokeSignerSponsorshipOp, revokeAccSignerSponsorshipOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: masterAccountKeyPair, network: Network.testnet)
                        try transaction.sign(keyPair: accountAKeyPair, network: Network.testnet)
                        
                        print(try transaction.transactionXDR.encodedEnvelope())
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let submitTransactionResponse):
                                print("CB Test: Transaction successfully sent:" + submitTransactionResponse.transactionHash)
                                expectation.fulfill()
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CB Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTAssert(false)
                    expectation.fulfill()
                }
            }
        }
        catch {
            XCTAssert(false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
}
