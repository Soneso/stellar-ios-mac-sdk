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
    
    let seed = "SD24I54ZUAYGZCKVQD6DZD6PQGLU7UQKVWDM37TKIACO3P47WG3BRW4C"
    let IOMIssuingAccountId = "GAHVPXP7RPX5EGT6WFDS26AOM3SBZW2RKEDBZ5VO45J7NYDGJYKYE6UW"
    
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
        
        sdk.operations.getOperations(forTransaction: "a6f39f3cbe64bb45d909690f604d8cec7f5a88f7398d8d656f26c63143ae8e59", includeFailed:true, join:"transactions") { (response) -> (Void) in
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
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SBWY3LDUMW2C3MNTBRY6JPZIQIF67KVDS4GBC2XWSEHKCCKWJDKYGLTO")
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let muxDestination = try MuxedAccount(accountId: "GAHV2YLGDBSPNOMZZO2VKKEWXOCGEF4425KTHM6BH5IYQAUFCHNQNIIW",  id: 100000029292)
                        
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
    
    
/*
    func testOperationsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .allOperations(cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_,_):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    func testOperationsForAccountStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .operationsForAccount(account: "GDQZ4N3CMM3FL2HLYKZPF3JPZX3IRHI3SQKNSTEG6GMEA3OAW337EBA6", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testOperationsForLedgerStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .operationsForLedger(ledger: "2365", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testOperationsForTransactionsStream() {
        let expectation = XCTestExpectation(description: "Get response from stream")
        
        sdk.operations.stream(for: .operationsForTransaction(transaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a", cursor: nil)).onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, _):
                expectation.fulfill()
            case .error( _):
                break
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    */
}
