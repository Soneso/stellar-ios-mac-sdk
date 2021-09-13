//
//  AmmTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 10.09.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class AmmTestCase: XCTestCase {

    let sdk = StellarSDK(withHorizonUrl:"....")
    let network = Network.custom(networkId: "....")
    let seed = "SAHSE34PEZCT3WAWBCR5TMVXUZES62OAJPNUV4Q5TZVAM72J6O2CW4W3"
    let assetAIssuingAccount = "GDQ4273UBKSHIE73RJB5KLBBM7W3ESHWA74YG7ZBXKZLKT5KZGPKKB7E"
    let assetBIssuingAccount = "GC2262FQJAHVJSYWI6XEVQEH5CLPYCVSOLQHCDHNSKVWHTKYEZNAQS25"
    var effectsStreamItem:EffectsStreamItem? = nil
    let liquidityPoolId = "4f7f29db33ead1a38c2edf17aa0416c369c207ca081de5c686c050c1ad320385"
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreatePoolShareTrustline() {
        
        let expectation = XCTestExpectation(description: "pool share trustline created")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
        
            let issuingAccountAKeyPair = try KeyPair(accountId: assetAIssuingAccount)
            let assetA = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "COOL", issuer: issuingAccountAKeyPair)
            
            let issuingAccountBKeyPair = try KeyPair(accountId: assetBIssuingAccount)
            let assetB = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "SONESO", issuer: issuingAccountBKeyPair)
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    do {
                        let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let changeTrustAsset = try ChangeTrustAsset(assetA:assetA!, assetB:assetB!);
                        let changeTrustOperation = ChangeTrustOperation(sourceAccountId: muxSource.accountId, asset:changeTrustAsset!)
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [changeTrustOperation],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("create poolshare test: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("create poolshare test: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"create poolshare test", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"create poolshare test", horizonRequestError:error)
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
    
    func testPoolShareDeposit() {
        
        let expectation = XCTestExpectation(description: "pool share deposit")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForLiquidityPool(liquidityPool: liquidityPoolId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? LiquidityPoolDepositedEffectResponse {
                        print("liquidity pool id: " + effect.liquidityPool.poolId)
                        print("shares received: " + effect.sharesReceived)
                        if (effect.reservesDeposited.first?.asset.code == "COOL") {
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
                        let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let minPrice = Price.fromString(price: "1.0")
                        let maxPrice = Price.fromString(price: "2.0")
                        
                        let liquidityPoolDepositOp = LiquidityPoolDepositOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: self.liquidityPoolId, maxAmountA: 250.0, maxAmountB: 250.0, minPrice: minPrice, maxPrice: maxPrice)
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [liquidityPoolDepositOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("pool share deposit: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("pool share deposit: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"pool share deposit", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"pool share deposit", horizonRequestError:error)
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
    
    func testPoolShareWithdraw() {
        
        let expectation = XCTestExpectation(description: "pool share withdraw")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForLiquidityPool(liquidityPool: liquidityPoolId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? LiquidityPoolWithdrewEffectResponse {
                        print("liquidity pool id: " + effect.liquidityPool.poolId)
                        print("shares redeemed: " + effect.sharesRedeemed)
                        if (effect.reservesReceived.first?.asset.code == "COOL") {
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"testPoolShareWithdraw Test - stream", horizonRequestError:horizonRequestError)
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
                        let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                        print ("Muxed source account id: \(muxSource.accountId)")
                        
                        let liquidityPoolWithdrawOp = LiquidityPoolWithdrawOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: self.liquidityPoolId, amount: 100.0, minAmountA: 100.0, minAmountB: 100.0)
                        let transaction = try Transaction(sourceAccount: muxSource,
                                                          operations: [liquidityPoolWithdrawOp],
                                                          memo: Memo.none,
                                                          timeBounds:nil)
                        try transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                        
                        try self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                            switch response {
                            case .success(let response):
                                print("pool share withdraw: Transaction successfully sent. Hash:\(response.transactionHash)")
                            case .destinationRequiresMemo(let destinationAccountId):
                                print("pool share withdraw: Destination requires memo \(destinationAccountId)")
                                XCTAssert(false)
                                expectation.fulfill()
                            case .failure(let error):
                                StellarSDKLog.printHorizonRequestErrorMessage(tag:"pool share withdraw", horizonRequestError:error)
                                XCTAssert(false)
                                expectation.fulfill()
                            }
                        }
                    } catch {
                        XCTAssert(false)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"ppool share withdraw", horizonRequestError:error)
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
    
    func testGetEffectsForLiquidityPool() {
        let expectation = XCTestExpectation(description: "Get effects for liquidity ppol and parse their details successfuly")
        
        sdk.effects.getEffects(forLiquidityPool: liquidityPoolId, order:Order.descending) { (response) -> (Void) in
            switch response {
            case .success(_):
                XCTAssert(true)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetEffectsForLiquidityPool Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetOperationsForLiquidityPool() {
        let expectation = XCTestExpectation(description: "Get operations for liquidity ppol and parse their details successfuly")
        sdk.operations.getOperations(forLiquidityPool: liquidityPoolId, from: nil, order: Order.descending, includeFailed: true, join: "transactions") { (response) -> (Void) in
            switch response {
            case .success(let ops):
                if let operation = ops.records.first {
                    XCTAssert(operation.transactionSuccessful)
                } else {
                    XCTAssert(false)
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetOperationsForLiquidityPool Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
