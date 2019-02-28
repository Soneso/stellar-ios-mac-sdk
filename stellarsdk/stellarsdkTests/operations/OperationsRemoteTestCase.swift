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
        
        sdk.operations.getOperations(forAccount: "GBMDWGIFG6M3K5Y5UNF4OLASG2MXTQ6KFZ6J2HNR3LMZVSUUJFVUUSQT", from: nil, order: Order.descending) { (response) -> (Void) in
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
        
        sdk.operations.getOperations(forLedger: "1") { (response) -> (Void) in
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
        
        sdk.operations.getOperations(forTransaction: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a") { (response) -> (Void) in
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
        
        sdk.operations.getOperationDetails(operationId: "760209215489") { (response) -> (Void) in
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
            
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SDBLUM623VOIEQWXD5FN6K7HOU5GUKUGD6SGWTW2BB3PPD5GVFG7RZU5")
            //let sourceAccountKeyPair = try KeyPair(secretSeed:"SA3QF6XW433CBDLUEY5ZAMHYJLJNH4GOPASLJLO4QKH75HRRXZ3UM2YJ")
            let destinationKeyPair = try KeyPair.generateRandomKeyPair()
            print ("CA Test: Source account id: \(sourceAccountKeyPair.accountId)")
            print("CA Test: New destination keipair created with secret seed: \(destinationKeyPair.secretSeed!) and accountId: \(destinationKeyPair.accountId)")

            sdk.effects.stream(for: .effectsForAccount(account:sourceAccountKeyPair.accountId, cursor:"now")).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(let id, let effectResponse):
                    if let accountDebitedResponse = effectResponse as? AccountDebitedEffectResponse {
                        print("CA Test: Stream source account received response with effect-ID: \(id) - type: Account debited - debited amount: \(accountDebitedResponse.amount)")
                        self.printAccountDetails(tag:"Create account testcase", accountId: destinationKeyPair.accountId)
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CA Test - source", horizonRequestError:horizonRequestError)
                    } else {
                        print("CA Test: Stream error on source account: \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.operations.stream(for: .operationsForAccount(account:destinationKeyPair.accountId, cursor:nil)).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(let id, let operationResponse):
                    if let accountCreatedResponse = operationResponse as? AccountCreatedOperationResponse {
                        print("CA Test: Stream source account received response with effect-ID: \(id) - type: Account created - New account with accountId: \(accountCreatedResponse.account) now has a balance of : \(accountCreatedResponse.startingBalance) XLM" )
                        print("CA Test: Success")
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
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SDZ2TGEQ6IZETYLNVO4MOSOFRUVWY6D63EWIRTCT2S777TK3Z3R5JIFE")
            print ("Account ID: \(sourceAccountKeyPair.accountId)")
            
            let homeDomain = "http://www.soneso.com"
            print ("Home domain: \(homeDomain)")
            
            sdk.operations.stream(for: .operationsForAccount(account:sourceAccountKeyPair.accountId, cursor:"now")).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let operationResponse):
                    if let updateHomeDomainResponse = operationResponse as?  SetOptionsOperationResponse {
                        if let responseHomeDomain = updateHomeDomainResponse.homeDomain {
                            print("UHD Test: Home domain updated to: \(responseHomeDomain)-" )
                            if homeDomain == responseHomeDomain {
                                print("Success")
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
    
    func testUpdateInflationDestination() {
        let expectation = XCTestExpectation(description: "Set inflation destination")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SDBLUM623VOIEQWXD5FN6K7HOU5GUKUGD6SGWTW2BB3PPD5GVFG7RZU5")
            print ("UID Test source account id: \(sourceAccountKeyPair.accountId)")
            let destinationAccountId = "GBMDWGIFG6M3K5Y5UNF4OLASG2MXTQ6KFZ6J2HNR3LMZVSUUJFVUUSQT"
            
            sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now")).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let setOptionsResponse = operationResponse as? SetOptionsOperationResponse {
                        if (setOptionsResponse.inflationDestination == destinationAccountId) {
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
            
            let issuingAccountKeyPair = try KeyPair(accountId: "GCVLKGCW2X26NMNAM7PDCTS2VO5MMOQPHSG6KWYEM7MHGDMLHORCNLZC")
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            let trustingAccountKeyPair = try KeyPair(secretSeed: "SDFP7WG4ROP66JTN7CHHKTIEHIPG27WZ5G3Y5HR74GPMCHVZUVXBDLLR")
            
            printAccountDetails(tag: "CTL Test - trusting account", accountId: trustingAccountKeyPair.accountId)
            
            sdk.operations.stream(for: .operationsForAccount(account: trustingAccountKeyPair.accountId, cursor: "now")).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let changeTrustlineResponse = operationResponse as? ChangeTrustOperationResponse {
                        if let assetCode = changeTrustlineResponse.assetCode, let assetIssuer = changeTrustlineResponse.assetIssuer, let limit = changeTrustlineResponse.limit {
                            if assetCode == "IOM", assetIssuer ==  issuingAccountKeyPair.accountId, limit == "100000000.0000000" {
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
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SALRLAO6L23EIBZD526CLQKZJWSNP3OOG2KDQ3BUN2K6PLMQKR5WIN5J")
            print ("MOF Test source accountId: \(sourceAccountKeyPair.accountId)")
            
            let issuingAccountKeyPair = try KeyPair(secretSeed: "SDNCAM5TADVOA2CFWZ2LCWSHYPXLTGTC545KZWEQJW6WUUMUY33ZISSW")
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            let XLM = Asset(type: AssetType.ASSET_TYPE_NATIVE)
        
            /*var eventReceived = false
            
             // TODO: find out why this is not receiving events.
            sdk.effects.stream(for: .effectsForAccount(account: sourceAccountKeyPair.accountId, cursor: nil)).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let effectResponse):
                    if let updateOfferResponse = effectResponse as? OfferUpdatedEffectResponse {
                        if updateOfferResponse.id == "113064" {
                            print("Update offer id: \(updateOfferResponse.id)" )
                            if eventReceived {
                                XCTAssert(true)
                                expectation.fulfill()
                            } else {
                                eventReceived = true
                            }
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"UID Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("MOF Test: stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }*/
            
            
            sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now")).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let manageOfferResponse = operationResponse as? ManageOfferOperationResponse {
                        if manageOfferResponse.buyingAssetType == AssetTypeAsString.NATIVE, manageOfferResponse.offerId == 0 {
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
                        let manageOfferOperation = ManageOfferOperation(selling:IOM!, buying:XLM!, amount:Decimal(random), price:Price(numerator:5, denominator:15), offerId:0)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [manageOfferOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("MOF Test: Transaction successfully sent")
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
    
    func testCreatePassiveOffer() {
        let expectation = XCTestExpectation(description: "Create a passive offer for IOM, the sdk token.")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SALRLAO6L23EIBZD526CLQKZJWSNP3OOG2KDQ3BUN2K6PLMQKR5WIN5J")
            print ("CPO Test source accountId: \(sourceAccountKeyPair.accountId)")
            
            let issuingAccountKeyPair = try KeyPair(secretSeed: "SDNCAM5TADVOA2CFWZ2LCWSHYPXLTGTC545KZWEQJW6WUUMUY33ZISSW")
            let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
            let XLM = Asset(type: AssetType.ASSET_TYPE_NATIVE)
            
            sdk.transactions.stream(for: .transactionsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now")).onReceive { (response) in
                
            }
            
            sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now")).onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let createOfferResponse = operationResponse as? CreatePassiveOfferOperationResponse {
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
                        
                        let createPassiveOfferOperation = CreatePassiveOfferOperation(selling:IOM!, buying:XLM!, amount:Decimal(random), price:Price(numerator:6, denominator:17))
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [createPassiveOfferOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: Network.testnet)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("CPO Test: Transaction successfully sent")
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
            let sourceAccountKeyPair = try KeyPair(secretSeed:"SDBLUM623VOIEQWXD5FN6K7HOU5GUKUGD6SGWTW2BB3PPD5GVFG7RZU5")
            print ("MAD Test: source accoint Id \(sourceAccountKeyPair.accountId)")
            
            let name = "soneso"
            let value = "is super"
            
            sdk.operations.stream(for: .operationsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now")).onReceive { (response) -> (Void) in
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
