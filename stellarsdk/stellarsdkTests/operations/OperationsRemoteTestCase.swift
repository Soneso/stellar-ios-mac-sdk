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
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")

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
                                                                  operations: [changeTrustOp, createClaimableBalance,
                                                                               createAccountOp, createAccountOp2,
                                                                               createAccountOp3, paymentOp1],
                                                                  memo: Memo.none)
                                try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
                                try! transaction.sign(keyPair: self.IOMIssuingAccountKeyPair, network: Network.testnet)
                                
                                try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                    switch response {
                                    case .success(let response):
                                        print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
                                        self.transactionId = response.transactionHash
                                        self.ledger = response.ledger
                                        switch response.transactionMeta {
                                        case .transactionMetaV2(let metaV2):
                                            for opMeta in metaV2.operations {
                                                for change in opMeta.changes.ledgerEntryChanges {
                                                    switch change {
                                                    case .created(let entry):
                                                        switch entry.data {
                                                        case .claimableBalance(let IDXdr):
                                                            switch IDXdr.claimableBalanceID {
                                                            case .claimableBalanceIDTypeV0(let data):
                                                                self.claimableBalanceId = self.hexEncodedBalanceId(data:data.wrapped)
                                                                print("claimable balance Id: \(self.claimableBalanceId!)")
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
        getOperations()
        getOperationsForAccount()
        getOperationsForClaimableBalance()
        getOperationsForLedger()
        getOperationsForTransaction()
        getOperationDetails()
        createAccount()
        updateHomeDomain()
        accountMerge()
        updateInflationDestination()
        changeTrustline()
        mangeOffer()
        createPassiveSellOffer()
        manageAccountData()
        createClaimableBalances()
        claimableBalancesForSponsor()
        getClaimableBalancesForClaimant()
        getClaimableBalancesForAsset()
        claimClaimableBalance()
        //sponsorship()
        sponsorship2()
    }
    
    func getOperations() {
        XCTContext.runActivity(named: "getOperations") { activity in
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
                                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperations", horizonRequestError: error)
                                    XCTFail()
                                }
                            }
                        case .failure(let error):
                            StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperations", horizonRequestError: error)
                            XCTFail()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperations", horizonRequestError: error)
                    XCTFail()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getOperationsForAccount() {
        XCTContext.runActivity(named: "getOperationsForAccount") { activity in
            let expectation = XCTestExpectation(description: "Get operations for account")
            sdk.operations.getOperations(forAccount: testKeyPair.accountId, from: nil, order: Order.descending, includeFailed: true, join: "transactions") { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForAccount", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getOperationsForClaimableBalance() {
        XCTContext.runActivity(named: "getOperationsForClaimableBalance") { activity in
            let expectation = XCTestExpectation(description: "Get operations for claimable balance")
                let claimableBalanceId = self.claimableBalanceId!
            sdk.operations.getOperations(forClaimableBalance: claimableBalanceId, from: nil, order: Order.descending, includeFailed: true, join: "transactions") { (response) -> (Void) in
                switch response {
                case .success(let ops):
                    if let operation = ops.records.first {
                        XCTAssert(operation.transactionSuccessful)
                    } else {
                        XCTFail()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForClaimableBalance", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getOperationsForLedger() {
        XCTContext.runActivity(named: "getOperationsForLedger") { activity in
            let expectation = XCTestExpectation(description: "Get operations for ledger")
            
            sdk.operations.getOperations(forLedger: String(ledger!), includeFailed:true, join:"transactions") { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForLedger", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getOperationsForTransaction() {
        XCTContext.runActivity(named: "getOperationsForTransaction") { activity in
            let expectation = XCTestExpectation(description: "Get operations for transaction")
            
            sdk.operations.getOperations(forTransaction: self.transactionId!, includeFailed:true, join:"transactions") { (response) -> (Void) in
                switch response {
                case .success(let response):
                    XCTAssert(response.records.count > 0)
                    self.operationId = response.records.first?.id
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationsForTransaction", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getOperationDetails() {
        XCTContext.runActivity(named: "getOperationsForTransaction") { activity in
            let expectation = XCTestExpectation(description: "Get operation details")
            
            sdk.operations.getOperationDetails(operationId: self.operationId!, join:"transactions") { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getOperationDetails", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func createAccount() {
        XCTContext.runActivity(named: "createAccount") { activity in
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
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"createAccount", horizonRequestError:horizonRequestError)
                    } else {
                        print("createAccount: Stream error on destination account: \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let createAccount = try! CreateAccountOperation(sourceAccountId: nil, destinationAccountId: destinationKeyPair.accountId, startBalance: 2.0)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [createAccount],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CA Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
        
    }
    
    func updateHomeDomain() {
        XCTContext.runActivity(named: "updateHomeDomain") { activity in
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
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let setHomeDomainOperation = try! SetOptionsOperation(sourceAccountId: sourceAccountKeyPair.accountId, homeDomain: homeDomain)
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [setHomeDomainOperation],
                                                      memo: Memo.none)
                    
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"UHD Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func accountMerge() {
        XCTContext.runActivity(named: "testAccountMerge") { activity in
            let expectation = XCTestExpectation(description: "account merged")
            let sourceAccountKeyPair = accountToMergeKeyPair
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxDestination = try! MuxedAccount(accountId: self.testKeyPair.accountId,  id: 100000029292)
                    let mergeAccountOperation = try! AccountMergeOperation(destinationAccountId: muxDestination.accountId, sourceAccountId: accountResponse.accountId)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [mergeAccountOperation],
                                                      memo: Memo.none)
                    
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                            expectation.fulfill()
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"AM Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    func updateInflationDestination() {
        XCTContext.runActivity(named: "updateInflationDestination") { activity in
            let expectation = XCTestExpectation(description: "Set inflation destination")
            let sourceAccountKeyPair = testKeyPair
            let destinationAccountId = IOMIssuingAccountKeyPair.accountId
            
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
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"updateInflationDestination- stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("updateInflationDestination stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let setInflationOperation = try! SetOptionsOperation(sourceAccountId: sourceAccountKeyPair.accountId, inflationDestination: KeyPair(accountId:destinationAccountId))
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [setInflationOperation],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            print("updateInflationDestination: Transaction successfully sent")
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"UID Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func changeTrustline() {
        XCTContext.runActivity(named: "changeTrustline") { activity in
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
                                XCTAssert(true)
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
            
            sdk.accounts.getAccountDetails(accountId: trustingAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let changeTrustOp = ChangeTrustOperation(sourceAccountId:accountResponse.accountId, asset:IOM!, limit: 100000000)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [changeTrustOp],
                                                      memo: Memo.none)
                    
                    try! transaction.sign(keyPair: trustingAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CTL Test", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }

    func mangeOffer() {
        XCTContext.runActivity(named: "mangeOffer") { activity in
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
                            XCTAssert(true)
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
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let random = arc4random_uniform(21) + 10;
                    let manageOfferOperation = ManageSellOfferOperation(sourceAccountId:nil, selling:IOM!, buying:XLM!,
                                                                        amount:Decimal(random),
                                                                        price:Price(numerator:5, denominator:15),
                                                                        offerId:0)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [manageOfferOperation],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"mangeOffer", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func createPassiveSellOffer() {
        XCTContext.runActivity(named: "createPassiveSellOffer") { activity in
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
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
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
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createPassiveSellOffer", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func manageAccountData() {
        XCTContext.runActivity(named: "manageAccountData") { activity in
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
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let manageDataOperation = ManageDataOperation(sourceAccountId:sourceAccountKeyPair.accountId, name:name, data:value.data(using: .utf8))
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [manageDataOperation],
                                                          memo: Memo.none)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                XCTAssert(true)
                            default:
                                XCTFail()
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTFail()
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"manageAccountData", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }

    func createClaimableBalances() {
        XCTContext.runActivity(named: "createClaimableBalances") { activity in
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
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
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
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let submitTransactionResponse):
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
                                                    balanceId = self.hexEncodedBalanceId(data: data.wrapped)
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
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 315.0)
        }
    }
   
    func claimableBalancesForSponsor() {
        XCTContext.runActivity(named: "claimableBalancesForSponsor") { activity in
            let expectation = XCTestExpectation(description: "can get claimable balances for sponsor")
            let sourceAccountKeyPair = testKeyPair
            let sourceAccountId = sourceAccountKeyPair.accountId
            
            sdk.claimableBalances.getClaimableBalances(sponsorAccountId: sourceAccountId, order:Order.descending) { (response) -> (Void) in
                switch response {
                case .success(let pageResponse):
                    XCTAssert(pageResponse.records.count > 0)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"claimableBalancesForSponsor", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func getClaimableBalancesForClaimant() {
        XCTContext.runActivity(named: "getClaimableBalancesForClaimant") { activity in
            let expectation = XCTestExpectation(description: "can get claimable balances for claimant")
            let claimantAccountId = "GDSHZPWSL5QBQKKDQNECFPI2PF7JQUACNWG65PMFOK6G5V4QBH4CX2KH"
            
            sdk.claimableBalances.getClaimableBalances(claimantAccountId: claimantAccountId, order:Order.descending) { (response) -> (Void) in
                switch response {
                case .success(let pageResponse):
                    XCTAssert(pageResponse.records.count > 0)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"getClaimableBalancesForClaimant", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func getClaimableBalancesForAsset() {
        XCTContext.runActivity(named: "getClaimableBalancesForAsset") { activity in
            let expectation = XCTestExpectation(description: "can get claimable balances for asset")
            
            let native = "native"
            sdk.claimableBalances.getClaimableBalances(asset: Asset.init(canonicalForm: native)!, order:Order.descending) { (response) -> (Void) in
                switch response {
                case .success(let pageResponse):
                    XCTAssert(pageResponse.records.count > 0)
                    expectation.fulfill()
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func claimClaimableBalance() {
        XCTContext.runActivity(named: "claimClaimableBalance") { activity in
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
                            XCTAssert(true)
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
            
            sdk.accounts.getAccountDetails(accountId: claimantAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let claimClaimableBalanceOp = ClaimClaimableBalanceOperation(balanceId: balanceId)
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [claimClaimableBalanceOp],
                                                      memo: Memo.none)

                    try! transaction.sign(keyPair: claimantAccountKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            XCTAssert(true)
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    
    func sponsorship() {
        XCTContext.runActivity(named: "sponsorship") { activity in
            let expectation = XCTestExpectation(description: "can begin and end sponsorship")
            let masterAccountKeyPair = testKeyPair
            let masterAccountId = masterAccountKeyPair.accountId
            let accountAKeyPair = try! KeyPair.generateRandomKeyPair()
            let accountAId = accountAKeyPair.accountId
            
            sdk.accounts.getAccountDetails(accountId: masterAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let begingSponsorshipOp = BeginSponsoringFutureReservesOperation(sponsoredAccountId: accountAId)
                        
                        let createAccountOp = CreateAccountOperation(sourceAccountId: masterAccountId, destination: accountAKeyPair, startBalance: 10.0)
                        let name = "soneso"
                        let value = "is super"
                        let manageDataOp = ManageDataOperation(sourceAccountId: accountAId, name: name, data: value.data(using: .utf8))
                        let richAsset = ChangeTrustAsset(canonicalForm: "RICH:" + masterAccountId)!
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
                                                          memo: Memo.none)
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
                                XCTFail()
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - send error", horizonRequestError:error)
                                XCTFail()
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTFail()
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 20.0)
        }
    }
    
    
    func sponsorship2() {
        XCTContext.runActivity(named: "sponsorship2") { activity in
            let expectation = XCTestExpectation(description: "can begin and end sponsorship")
            let masterAccountKeyPair = testKeyPair
            let masterAccountId = masterAccountKeyPair.accountId
            let accountAKeyPair = accountToSponsorKeyPair
            let accountAId = accountAKeyPair.accountId
            let issuingAccountKeyPair = try! KeyPair(accountId: IOMIssuingAccountKeyPair.accountId)
            
            sdk.accounts.getAccountDetails(accountId: masterAccountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let begingSponsorshipOp = BeginSponsoringFutureReservesOperation(sponsoredAccountId: accountAId,sponsoringAccountId: masterAccountId)
                
                    
                    let IOM = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
                    let changeTrustOp = ChangeTrustOperation(sourceAccountId: accountAId, asset: IOM!, limit: 10000.00)
                    
                    let endSponsoringOp = EndSponsoringFutureReservesOperation(sponsoredAccountId: accountAId)
                    
                    
                    let transaction = try! Transaction(sourceAccount: accountResponse,
                                                      operations: [begingSponsorshipOp, changeTrustOp, endSponsoringOp],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: masterAccountKeyPair, network: Network.testnet)
                    try! transaction.sign(keyPair: accountAKeyPair, network: Network.testnet)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(_):
                            expectation.fulfill()
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"sponsorship2", horizonRequestError: error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 20.0)
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
