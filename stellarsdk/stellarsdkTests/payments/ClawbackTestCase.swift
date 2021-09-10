//
//  ClawbackTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 30.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class ClawbackTestCase: XCTestCase {

    let sdk = StellarSDK()
    let network = Network.testnet
    let masterSeed = "SCQ5ABUIEMOHR3U6TH4DP4ZQKPBGPZDRHL5645QRGTF26JTOSTJZ2NB3"
    let SKYIssuingAccountSeed = "SCZAKQ6QQVLUZLZOAAGMSAYOBJFNHUPLUNQ4VGXZ35MOWXE3YRMTKGWR"
    let destinationSeed = "SCS4NEFSJIRV6JSOA3B7REIKTUEZGUZPQL5VDXCXMZ4XFTZNGHVXQCZ7"
    let donorSeed = "SAIBHQWHY6IAO4FT5NLZN5YRZSSGQVPEP5BF2Q776SYTUZGK7KXEKXZJ"
    let claimantSeed = "SCLAJA2WUI5M3Q4YE5LGFWHUVYZWHN3WNBKZ67AQHUHFVST6CVPHKKIU"
    
    var streamItem:OperationsStreamItem? = nil
    var effectsStreamItem:EffectsStreamItem? = nil
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testCreateNewAccount() {
        let expectation = XCTestExpectation(description: "Create and fund a new account")
        do {
            
            let sourceAccountKeyPair = try KeyPair(secretSeed:masterSeed)
            let destinationKeyPair = try KeyPair.generateRandomKeyPair()
            print ("Public Key: \(destinationKeyPair.accountId)")
            print ("Secret Seed: \(destinationKeyPair.secretSeed!)")

            streamItem = sdk.operations.stream(for: .operationsForAccount(account:destinationKeyPair.accountId, cursor:nil))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(let id, let operationResponse):
                    if let accountCreatedResponse = operationResponse as? AccountCreatedOperationResponse {
                        print("CNA Test: Stream source account received response with effect-ID: \(id) - type: Account created - New account with accountId: \(accountCreatedResponse.account) now has a balance of : \(accountCreatedResponse.startingBalance) XLM" )
                        print("CNA Test: Success")
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
                        
                        let createAccount = CreateAccountOperation(sourceAccountId: nil, destination: destinationKeyPair, startBalance: 10.0)
                        /*let createAccount = try PaymentOperation(sourceAccountId: nil, destinationAccountId:"GB4ZJJ5UEP7PASWL4GUDNN2I5EGP3PSGCFOABS2YO6DPKAZCNOOZB4V4", asset:Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)*/
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [createAccount],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("CNA Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CNA Test: Destination requires memo \(destinationAccountId)")
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
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CNA Test", horizonRequestError: error)
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
    
    func testSetIssuerClawbackFlag() {
            
        let expectation = XCTestExpectation(description: "Clawback flag set")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:SKYIssuingAccountSeed)
            
            streamItem = sdk.operations.stream(for: .operationsForAccount(account:sourceAccountKeyPair.accountId, cursor:"now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let operationResponse):
                    if let updateFlagsResponse = operationResponse as?  SetOptionsOperationResponse {
                        if let setFlags = updateFlagsResponse.setFlagsS {
                            print("SCF Test: Set flags: \(setFlags)-" )
                            if setFlags.contains("auth_clawback_enabled") {
                                print("Success")
                                self.streamItem?.closeStream()
                                self.streamItem = nil
                                expectation.fulfill()
                            }
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"SCF Test - source", horizonRequestError:horizonRequestError)
                    } else {
                        print("SCF Test stream error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        
                        let setOp = try SetOptionsOperation(sourceAccountId:sourceAccountKeyPair.accountId, setFlags:AccountFlags.AUTH_CLAWBACK_ENABLED_FLAG | AccountFlags.AUTH_REVOCABLE_FLAG)
           
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [setOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("SCF Test: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("SCF Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"SCF Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"SCF Test", horizonRequestError:error)
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
        let expectation = XCTestExpectation(description: "Change trustline, allow destination account to receive SKY - our sdk token")
        do {
            
            let issuingAccountKeyPair = try KeyPair(secretSeed: SKYIssuingAccountSeed)
            let SKY = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "SKY", issuer: issuingAccountKeyPair)
            let trustingAccountKeyPair = try KeyPair(secretSeed: destinationSeed)
            // let trustingAccountKeyPair = try KeyPair(secretSeed: donorSeed)
            // let trustingAccountKeyPair = try KeyPair(secretSeed: claimantSeed)
            
            streamItem = sdk.operations.stream(for: .operationsForAccount(account: trustingAccountKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let changeTrustlineResponse = operationResponse as? ChangeTrustOperationResponse {
                        if let assetCode = changeTrustlineResponse.assetCode, let assetIssuer = changeTrustlineResponse.assetIssuer, let limit = changeTrustlineResponse.limit {
                            if assetCode == "SKY", assetIssuer == issuingAccountKeyPair.accountId, limit == "100000000.0000000" {
                                self.streamItem?.closeStream()
                                self.streamItem = nil
                                XCTAssert(true)
                                expectation.fulfill()
                            }
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CTL Test - stream", horizonRequestError:horizonRequestError)
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
                        let changeTrustOp = ChangeTrustOperation(sourceAccountId: nil, asset:SKY!, limit: 100000000)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [changeTrustOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        
                        try transaction.sign(keyPair: trustingAccountKeyPair, network: self.network)
                        
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
    
    func testSendSKY() {
            
        let expectation = XCTestExpectation(description: "SKY payment successfully sent and received")
        
        do {
            
            let destinationAccountKeyPair = try KeyPair(secretSeed: destinationSeed)
            //let destinationAccountKeyPair = try KeyPair(secretSeed: donorSeed)
            let issuingAccountKeyPair = try KeyPair(secretSeed: SKYIssuingAccountSeed)
            let SKY = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "SKY", issuer: issuingAccountKeyPair)
            
            streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(let id, let operationResponse):
                    if let paymentResponse = operationResponse as? PaymentOperationResponse {
                        if paymentResponse.assetCode == SKY?.code {
                            print("Payment of \(paymentResponse.amount) SKY from \(paymentResponse.sourceAccount) received -  id \(id)" )
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"SSKY Test - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let muxSource = MuxedAccount(keyPair: issuingAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        let muxDest = try MuxedAccount(accountId: destinationAccountKeyPair.accountId, id:9919191919)

                        let paymentOperation = try PaymentOperation(sourceAccountId: muxSource.accountId,
                                                                destinationAccountId: muxDest.accountId,
                                                                asset: SKY!,
                                                                amount: 122.5)
                        
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [paymentOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("SSKY Test: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("SSKY Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"SSKY Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"SSKY Test", horizonRequestError:error)
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
    
    func testClawbackSKY() {
            
        let expectation = XCTestExpectation(description: "SKY payment successfully clawed back")
        
        do {
            
            let destinationAccountKeyPair = try KeyPair(secretSeed: destinationSeed)
            let issuingAccountKeyPair = try KeyPair(secretSeed: SKYIssuingAccountSeed)
            let SKY = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "SKY", issuer: issuingAccountKeyPair)
            
            streamItem = sdk.operations.stream(for: .operationsForAccount(account: issuingAccountKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(let id, let operationResponse):
                    if let clawbackResponse = operationResponse as? ClawbackOperationResponse {
                        if clawbackResponse.assetCode == SKY?.code {
                            print("Calwback of \(clawbackResponse.amount) SKY from \(clawbackResponse.sourceAccount) received -  id \(id)" )
                            XCTAssert(true)
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CSKY Test - destination", horizonRequestError:horizonRequestError)
                    } else {
                        print("Error \(error?.localizedDescription ?? "")")
                    }
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let muxSource = MuxedAccount(keyPair: issuingAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        let muxDest = try MuxedAccount(accountId: destinationAccountKeyPair.accountId, id:9919191919)

                        let clawbackOperation = ClawbackOperation(sourceAccountId: muxSource.accountId,
                                                                      asset: SKY!,
                                                                      fromAccountId: muxDest.accountId,
                                                                      amount: 2.5)
                        
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [clawbackOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
                        
                        let xdrEnvelope = try! transaction.encodedEnvelope()
                        print(xdrEnvelope)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("CSKY Test: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CSKY Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CSKY Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CSKY Test", horizonRequestError:error)
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
    
    func testTransactionClawbackXDR() throws {
        
        let xdr = "AAAAAgAAAQAAAAAAABODoS/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAAAZAAAficAAAAMAAAAAAAAAAAAAAABAAAAAQAAAQAAAAAAABODoS/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAAAEwAAAAFTS1kAAAAAAC/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAABAAAAAAJPOttvUOtftcj4FgTXzV7Zkqisq3x67nLKsLyf14XVl5xAQ+wAAAAAAX14QAAAAAAAAAABUob7ewAAAEA3ABxO2mMBepQaN9iqKNixUHC3u4GiaCW2tpeImk1MY7TPrKa6BFaN8SvuDheOm9MXcWeJpOYEZUlHN/oQQ9oF"

        let transaction = try Transaction(envelopeXdr: xdr)
        let envelopeXDR = try transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }
    
    func testSetTrustlineFlags() {
        let expectation = XCTestExpectation(description: "remove clawback flag")
        do {
            
            let issuingAccountKeyPair = try KeyPair(secretSeed: SKYIssuingAccountSeed)
            let SKY = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "SKY", issuer: issuingAccountKeyPair)
            let trustingAccountKeyPair = try KeyPair(secretSeed: destinationSeed)
            
            /*streamItem = sdk.operations.stream(for: .operationsForAccount(account: trustingAccountKeyPair.accountId, cursor: "now"))
            streamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response( _, let operationResponse):
                    if let setTrustlineFlagsResponse = operationResponse as? SetTrustLineFlagsOperationResponse {
                        if let assetCode = setTrustlineFlagsResponse.assetCode, let assetIssuer = setTrustlineFlagsResponse.assetIssuer {
                            if assetCode == "SKY", assetIssuer == issuingAccountKeyPair.accountId, let cfs = setTrustlineFlagsResponse.clearFlagsS,
                               cfs.contains("clawback_enabled"){
                                self.streamItem?.closeStream()
                                self.streamItem = nil
                                XCTAssert(true)
                                expectation.fulfill()
                            }
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"STF Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("STF Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }*/
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:issuingAccountKeyPair.accountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? TrustLineFlagsUpdatedEffectResponse, let ceflag = effect.clawbackEnabledFlag {
                        print("TrustLineFlagsUpdatedEffectResponse received \(trustingAccountKeyPair.accountId) - ce \(ceflag)")
                        if effect.trustor == trustingAccountKeyPair.accountId && !ceflag {
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"STF Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("STF Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let setTrustlineFlagsOp = SetTrustlineFlagsOperation(sourceAccountId: nil, asset:SKY!, trustorAccountId: trustingAccountKeyPair.accountId, setFlags: 0, clearFlags: TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [setTrustlineFlagsOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        
                        try transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
                        
                        let xdrEnvelope = try! transaction.encodedEnvelope()
                        print(xdrEnvelope)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                print("STF Test: Transaction successfully sent")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("STF Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"STF Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"STF Test", horizonRequestError:error)
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
    
    func testTransactionSetTrustlineFlagsXDR() throws {
        
        let xdr = "AAAAAgAAAAAv4lLQGXjIGA7acvRzBZP3UZEQ9/nsXM0L4ISWUob7ewAAAGQAAH4nAAAADQAAAAAAAAAAAAAAAQAAAAAAAAAVAAAAAFDrX7XI+BYE181e2ZKorKt8eu5yyrC8n9eF1ZecQEPsAAAAAVNLWQAAAAAAL+JS0Bl4yBgO2nL0cwWT91GREPf57FzNC+CEllKG+3sAAAAEAAAAAAAAAAAAAAABUob7ewAAAECRznSEYj2xr7S5Pikvh5jbY04A/f89lp1OuU2A9qbhmRkWhDSrI+Hu/jWfZXNzPblVjpzGsdRIh8mkhx4WL8gD"

        let transaction = try Transaction(envelopeXdr: xdr)
        let envelopeXDR = try transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }
    
    func testCreateClaimableBalances() {
        let expectation = XCTestExpectation(description: "creates claimable balances")
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:donorSeed)
            let sourceAccountId = sourceAccountKeyPair.accountId
            let claimantAccountKeyPair = try KeyPair(secretSeed:claimantSeed)
            let claimantAccountId = claimantAccountKeyPair.accountId
            let issuingAccountKeyPair = try KeyPair(secretSeed: SKYIssuingAccountSeed)
            let SKY = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "SKY", issuer: issuingAccountKeyPair)
            var balanceId = "-1"
            
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
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CCB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let claimant = Claimant(destination:claimantAccountId)
                        let claimants = [ claimant]
                        let createClaimableBalance = CreateClaimableBalanceOperation(asset: SKY!, amount: 1.00, claimants: claimants)
                        
                        let transaction = try Transaction(sourceAccount: accountResponse,
                                                          operations: [createClaimableBalance],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                        
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
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CCB Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCB Test - send error", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCB Test", horizonRequestError: error)
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
    
    func testClawbackCalimableSKY() {
            
        let expectation = XCTestExpectation(description: "SKY successfully clawed back from claimable balance")
        
        do {
            
            let issuingAccountKeyPair = try KeyPair(secretSeed: SKYIssuingAccountSeed)
            let balanceId = "4e619ecb4d8c46388dfc494217323f02c076626d6d60cd42d45af2eee998d3a2"
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:issuingAccountKeyPair.accountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? ClaimableBalanceClawedBackEffectResponse {
                        print("ClaimableBalanceClawedBackEffectResponse received: balance_id: " + effect.balanceId)
                        if effect.balanceId.hasSuffix(balanceId) {
                            print("match:\(effect.balanceId)")
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("CCB Test stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let muxSource = MuxedAccount(keyPair: issuingAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1232322)

                        let clawbackOperation = ClawbackClaimableBalanceOperation(claimableBalanceID: balanceId)
                        
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [clawbackOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
                        
                        let xdrEnvelope = try! transaction.encodedEnvelope()
                        print(xdrEnvelope)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("CCB Test: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("CCB Test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCB Test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCB Test", horizonRequestError:error)
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
    
    func testTransactionClaimableBalanceClawbackXDR() throws {
        
        let xdr = "AAAAAgAAAQAAAAAAABLNwi/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAAAZAAAficAAAAUAAAAAAAAAAAAAAABAAAAAAAAABQAAAAATmGey02MRjiN/ElCFzI/AsB2Ym1tYM1C1Fry7umY06IAAAAAAAAAAVKG+3sAAABAeA9ueIXWF1jAXMJU5o+8nk209KyH7Tfi35WvxXSgQeVmm1g5lVgQh0c0EAKJgAKkBbm32n0/I2itYKZxZBwDDA=="

        let transaction = try Transaction(envelopeXdr: xdr)
        let envelopeXDR = try transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }
}
