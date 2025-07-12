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

    static let testOn = "testnet" // "futurenet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet
    
    let IOMIssuingAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    let destinationKeyPair = try! KeyPair.generateRandomKeyPair()
    let donorKeyPair = try! KeyPair.generateRandomKeyPair()
    let claimantKeyPair = try! KeyPair.generateRandomKeyPair()
    var claimableBalanceId:String? = nil
    
    var streamItem:OperationsStreamItem? = nil
    var effectsStreamItem:EffectsStreamItem? = nil
    
    override func setUp()  async throws {
        try await super.setUp()

        let donorAccountId = donorKeyPair.accountId

        let createAccountOp1 = CreateAccountOperation(sourceAccountId: donorAccountId, destination: IOMIssuingAccountKeyPair, startBalance: 100)
        let createAccountOp2 = CreateAccountOperation(sourceAccountId: donorAccountId, destination: destinationKeyPair, startBalance: 100)
        let createAccountOp3 = CreateAccountOperation(sourceAccountId: donorAccountId, destination: claimantKeyPair, startBalance: 100)
        
        let responseEnum = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: donorAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: donorAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create donor account: \(donorAccountId)")
        }
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: donorAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [createAccountOp1, createAccountOp2, createAccountOp3],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.donorKeyPair, network: self.network)
            
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
        await setIssuerClawbackFlag()
        await changeTrustlines()
        await sendIOM()
        await clawbackIOM()
        transactionClawbackXDR()
        await setTrustlineFlags()
        transactionSetTrustlineFlagsXDR()
        await createClaimableBalance()
        await clawbackCalimableBalance()
        transactionClaimableBalanceClawbackXDR()
    }
    
    func setIssuerClawbackFlag() async {
        let expectation = XCTestExpectation(description: "Clawback flag set")
        
        let sourceAccountKeyPair = IOMIssuingAccountKeyPair
        
        streamItem = sdk.operations.stream(for: .operationsForAccount(account:sourceAccountKeyPair.accountId, cursor:"now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let updateFlagsResponse = operationResponse as?  SetOptionsOperationResponse {
                    if let setFlags = updateFlagsResponse.setFlagsS {
                        if setFlags.contains("auth_clawback_enabled") {
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
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let setOp = try! SetOptionsOperation(sourceAccountId:sourceAccountKeyPair.accountId, setFlags:AccountFlags.AUTH_CLAWBACK_ENABLED_FLAG | AccountFlags.AUTH_REVOCABLE_FLAG)

            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [setOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"setIssuerClawbackFlag()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setIssuerClawbackFlag()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        await fulfillment(of: [expectation], timeout: 15.0)
    }

    func changeTrustlines() async {
        let expectation = XCTestExpectation(description: "Change trustline, allow destination account to receive IOM - our sdk token")
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        let IOM = ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        let trustingAccountKeyPair = destinationKeyPair
           
        streamItem = sdk.operations.stream(for: .operationsForAccount(account: trustingAccountKeyPair.accountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response( _, let operationResponse):
                if let changeTrustlineResponse = operationResponse as? ChangeTrustOperationResponse {
                    if let assetCode = changeTrustlineResponse.assetCode, let assetIssuer = changeTrustlineResponse.assetIssuer, let limit = changeTrustlineResponse.limit {
                        if assetCode == "IOM", assetIssuer == issuingAccountKeyPair.accountId, limit == "100000000.0000000" {
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
                    print("changeTrustlines stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: trustingAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let changeTrustOp1 = ChangeTrustOperation(sourceAccountId: nil, asset:IOM!, limit: 100000000)
            let changeTrustOp2 = ChangeTrustOperation(sourceAccountId: self.donorKeyPair.accountId, asset:IOM!, limit: 100000000)
            let changeTrustOp3 = ChangeTrustOperation(sourceAccountId: self.claimantKeyPair.accountId, asset:IOM!, limit: 100000000)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp1, changeTrustOp2, changeTrustOp3],
                                              memo: Memo.none)
            
            try! transaction.sign(keyPair: trustingAccountKeyPair, network: self.network)
            try! transaction.sign(keyPair: self.donorKeyPair, network: self.network)
            try! transaction.sign(keyPair: self.claimantKeyPair, network: self.network)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"changeTrustlines()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"changeTrustlines()", horizonRequestError: error)
            XCTFail("could not load account details for \(trustingAccountKeyPair.accountId)")
        }
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func sendIOM() async {
        let expectation = XCTestExpectation(description: "sendIOM payment successfully sent and received")
        
        let destinationAccountKeyPair = destinationKeyPair
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        
        streamItem = sdk.payments.stream(for: .paymentsForAccount(account: destinationAccountKeyPair.accountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let paymentResponse = operationResponse as? PaymentOperationResponse {
                    if paymentResponse.assetCode == IOM?.code {
                        XCTAssert(true)
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendIOM - destination", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: issuingAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            let muxDest = try! MuxedAccount(accountId: destinationAccountKeyPair.accountId, id:9919191919)

            let paymentOperation1 = try! PaymentOperation(sourceAccountId: muxSource.accountId,
                                                          destinationAccountId: muxDest.accountId,
                                                          asset: IOM!,
                                                          amount: 122.5)
            let paymentOperation2 = try! PaymentOperation(sourceAccountId: muxSource.accountId,
                                                          destinationAccountId: self.donorKeyPair.accountId,
                                                          asset: IOM!,
                                                          amount: 5000.0)
            
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [paymentOperation1, paymentOperation2],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendIOM()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"sendIOM()", horizonRequestError: error)
            XCTFail("could not load account details for \(issuingAccountKeyPair.accountId)")
        }
    }
    
    func clawbackIOM() async {
        let expectation = XCTestExpectation(description: "IOM payment successfully clawed back")
    
        let destinationAccountKeyPair = destinationKeyPair
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        
        streamItem = sdk.operations.stream(for: .operationsForAccount(account: issuingAccountKeyPair.accountId, cursor: "now"))
        streamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let operationResponse):
                if let clawbackResponse = operationResponse as? ClawbackOperationResponse {
                    if clawbackResponse.assetCode == IOM?.code {
                        XCTAssert(true)
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"clawbackIOM - destination", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: issuingAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            let muxDest = try! MuxedAccount(accountId: destinationAccountKeyPair.accountId, id:9919191919)

            let clawbackOperation = ClawbackOperation(sourceAccountId: muxSource.accountId,
                                                          asset: IOM!,
                                                          fromAccountId: muxDest.accountId,
                                                          amount: 2.5)
            
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [clawbackOperation],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"clawbackIOM()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"clawbackIOM()", horizonRequestError: error)
            XCTFail("could not load account details for \(issuingAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
    }
    
    func transactionClawbackXDR() {
        let xdr = "AAAAAgAAAQAAAAAAABODoS/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAAAZAAAficAAAAMAAAAAAAAAAAAAAABAAAAAQAAAQAAAAAAABODoS/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAAAEwAAAAFTS1kAAAAAAC/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAABAAAAAAJPOttvUOtftcj4FgTXzV7Zkqisq3x67nLKsLyf14XVl5xAQ+wAAAAAAX14QAAAAAAAAAABUob7ewAAAEA3ABxO2mMBepQaN9iqKNixUHC3u4GiaCW2tpeImk1MY7TPrKa6BFaN8SvuDheOm9MXcWeJpOYEZUlHN/oQQ9oF"

        let transaction = try! Transaction(envelopeXdr: xdr)
        let envelopeXDR = try! transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }
    
    func setTrustlineFlags() async {
        let expectation = XCTestExpectation(description: "remove clawback flag")
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        let trustingAccountKeyPair = destinationKeyPair
        
        effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:issuingAccountKeyPair.accountId, cursor: "now"))
        effectsStreamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let effectResponse):
                if let effect = effectResponse as? TrustLineFlagsUpdatedEffectResponse, let ceflag = effect.clawbackEnabledFlag {
                    if effect.trustor == trustingAccountKeyPair.accountId && !ceflag {
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"setTrustlineFlags - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("setTrustlineFlags stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let setTrustlineFlagsOp = SetTrustlineFlagsOperation(sourceAccountId: nil, asset:IOM!,
                                                                 trustorAccountId: trustingAccountKeyPair.accountId,
                                                                 setFlags: 0,
                                                                 clearFlags: TrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [setTrustlineFlagsOp],
                                              memo: Memo.none)
            
            try! transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"setTrustlineFlags()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setTrustlineFlags()", horizonRequestError: error)
            XCTFail("could not load account details for \(issuingAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func transactionSetTrustlineFlagsXDR() {
        let xdr = "AAAAAgAAAAAv4lLQGXjIGA7acvRzBZP3UZEQ9/nsXM0L4ISWUob7ewAAAGQAAH4nAAAADQAAAAAAAAAAAAAAAQAAAAAAAAAVAAAAAFDrX7XI+BYE181e2ZKorKt8eu5yyrC8n9eF1ZecQEPsAAAAAVNLWQAAAAAAL+JS0Bl4yBgO2nL0cwWT91GREPf57FzNC+CEllKG+3sAAAAEAAAAAAAAAAAAAAABUob7ewAAAECRznSEYj2xr7S5Pikvh5jbY04A/f89lp1OuU2A9qbhmRkWhDSrI+Hu/jWfZXNzPblVjpzGsdRIh8mkhx4WL8gD"

        let transaction = try! Transaction(envelopeXdr: xdr)
        let envelopeXDR = try! transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
    }

    
    func createClaimableBalance() async {
        let expectation = XCTestExpectation(description: "creates claimable balance")
        let sourceAccountKeyPair = donorKeyPair
        let sourceAccountId = sourceAccountKeyPair.accountId
        let claimantAccountKeyPair = claimantKeyPair
        let claimantAccountId = claimantAccountKeyPair.accountId
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        
        let IOM = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "IOM", issuer: issuingAccountKeyPair)
        
        effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:sourceAccountId, cursor: "now"))
        effectsStreamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let effectResponse):
                if let effect = effectResponse as? ClaimableBalanceCreatedEffectResponse {
                    if let balanceId = self.claimableBalanceId, effect.balanceId.hasSuffix(balanceId) {
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("createClaimableBalance stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let claimant = Claimant(destination:claimantAccountId)
            let claimants = [ claimant]
            let createClaimableBalance = CreateClaimableBalanceOperation(asset: IOM!, amount: 1.00, claimants: claimants)
            
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [createClaimableBalance],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let submitTransactionResponse):
                switch submitTransactionResponse.transactionResult.resultBody {
                case .success(let array):
                    if let opResult = array.first {
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
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createClaimableBalance()", horizonRequestError: error)
            XCTFail("could not load account details for \(sourceAccountKeyPair.accountId)")
        }
        
        XCTAssertNotNil(self.claimableBalanceId)
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
    }

    func clawbackCalimableBalance() async {
        let expectation = XCTestExpectation(description: "IOM successfully clawed back from claimable balance")
        let issuingAccountKeyPair = IOMIssuingAccountKeyPair
        
        effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account:issuingAccountKeyPair.accountId, cursor: "now"))
        effectsStreamItem?.onReceive { (response) -> (Void) in
            switch response {
            case .open:
                break
            case .response(_, let effectResponse):
                if let effect = effectResponse as? ClaimableBalanceClawedBackEffectResponse {
                    if let balanceId = self.claimableBalanceId, effect.balanceId.hasSuffix(balanceId) {
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"CCB Test - stream", horizonRequestError:horizonRequestError)
                } else {
                    print("clawbackCalimableBalance stream error \(error?.localizedDescription ?? "")")
                }
                break
            }
        }
        
        let accDetailsEnum = await sdk.accounts.getAccountDetails(accountId: issuingAccountKeyPair.accountId)
        switch accDetailsEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: issuingAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1232322)

            let clawbackOperation = ClawbackClaimableBalanceOperation(claimableBalanceID: self.claimableBalanceId!)
            
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [clawbackOperation],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: issuingAccountKeyPair, network: self.network)
            let submitTxResultEnum = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResultEnum {
            case .success(let result):
                XCTAssertTrue(result.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"clawbackCalimableBalance()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"clawbackCalimableBalance()", horizonRequestError: error)
            XCTFail("could not load account details for \(issuingAccountKeyPair.accountId)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func transactionClaimableBalanceClawbackXDR() {
        let xdr = "AAAAAgAAAQAAAAAAABLNwi/iUtAZeMgYDtpy9HMFk/dRkRD3+exczQvghJZShvt7AAAAZAAAficAAAAUAAAAAAAAAAAAAAABAAAAAAAAABQAAAAATmGey02MRjiN/ElCFzI/AsB2Ym1tYM1C1Fry7umY06IAAAAAAAAAAVKG+3sAAABAeA9ueIXWF1jAXMJU5o+8nk209KyH7Tfi35WvxXSgQeVmm1g5lVgQh0c0EAKJgAKkBbm32n0/I2itYKZxZBwDDA=="

        let transaction = try! Transaction(envelopeXdr: xdr)
        let envelopeXDR = try! transaction.encodedEnvelope()
        
        XCTAssertEqual(xdr, envelopeXDR)
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
