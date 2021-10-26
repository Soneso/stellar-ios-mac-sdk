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

    let sdk = StellarSDK()
    let network = Network.testnet
    let seed = "SDSGMMWD5NNF5GEWP6V7Z37FVRCU3AZKK6JCYFET57QAV2MWC3NM52SB"
    let assetAIssuingAccount = "GAZKB7OEYRUVL6TSBXI74D2IZS4JRCPBXJZ37MDDYAEYBOMHXUYIX5YL"
    let assetBIssuingAccount = "GAOF7ARG3ZAVUA63GCLXG5JQTMBAH3ZFYHGLGJLDXGDSXQRHD72LLGOB"
    var effectsStreamItem:EffectsStreamItem? = nil
    var operationsStreamItem:OperationsStreamItem? = nil
    let liquidityPoolId = "2c0bfa623845dd101cbf074a1ca1ae4b2458cc8d0104ad65939ebe2cd9054355"
    let assetNative = Asset(type: AssetType.ASSET_TYPE_NATIVE)
    let nativeLiquidityPoolId = "246c5bef46e7540348777afc28d75b6aceecc8034937a017e33969aca62b0d08"
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreatePoolShareTrustlineNotNative() {
        
        let expectation = XCTestExpectation(description: "pool share trustline created")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
        
            let issuingAccountAKeyPair = try KeyPair(accountId: assetAIssuingAccount)
            let assetA = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "COOL", issuer: issuingAccountAKeyPair)
            
            let issuingAccountBKeyPair = try KeyPair(accountId: assetBIssuingAccount)
            let assetB = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "SONESO", issuer: issuingAccountBKeyPair)
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? TrustlineCreatedEffectResponse {
                        if let poolId = effect.liquidityPoolId {
                            print("trustline created: \(poolId)")
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
    
    func testCreatePoolShareTrustlineNative() {
        
        let expectation = XCTestExpectation(description: "pool share trustline created")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
        
            let issuingAccountAKeyPair = try KeyPair(accountId: assetAIssuingAccount)
            let assetA = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "COOL", issuer: issuingAccountAKeyPair)
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? TrustlineCreatedEffectResponse {
                        if let poolId = effect.liquidityPoolId {
                            print("trustline created: \(poolId)")
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
                        
                        let changeTrustAsset = try ChangeTrustAsset(assetA:self.assetNative!, assetB:assetA!);
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
    
    func testPoolShareDepositNonNative() {
        
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
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"pool share deposit - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("pool share deposit stream error \(error?.localizedDescription ?? "")")
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
    
    func testPoolShareDepositNative() {
        
        let expectation = XCTestExpectation(description: "pool share deposit native")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForLiquidityPool(liquidityPool: self.nativeLiquidityPoolId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? LiquidityPoolDepositedEffectResponse {
                        print("liquidity pool id: " + effect.liquidityPool.poolId)
                        print("shares received: " + effect.sharesReceived)
                        if (effect.reservesDeposited.last?.asset.code == "COOL") {
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"pool share deposit - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("pool share deposit stream error \(error?.localizedDescription ?? "")")
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
                        
                        let liquidityPoolDepositOp = LiquidityPoolDepositOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: self.nativeLiquidityPoolId, maxAmountA: 5.0, maxAmountB: 5.0, minPrice: minPrice, maxPrice: maxPrice)
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
    
    func testPoolShareWithdrawNonNative() {
        
        let expectation = XCTestExpectation(description: "pool share withdraw")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            
            operationsStreamItem = sdk.operations.stream(for: .operationsForLiquidityPool(liquidityPoolId: liquidityPoolId, cursor: "now"))
            operationsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let operationResponse):
                    if let operation = operationResponse as? LiquidityPoolWithdrawOperationResponse {
                        print("liquidity pool id: " + operation.liquidityPoolId)
                        print("shares: " + operation.shares)
                        if (operation.reservesReceived.first?.asset.code == "COOL") {
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
    
    func testPoolShareWithdrawNative() {
        
        let expectation = XCTestExpectation(description: "pool share withdraw")
        
        do {
            let sourceAccountKeyPair = try KeyPair(secretSeed:seed)
            
            operationsStreamItem = sdk.operations.stream(for: .operationsForLiquidityPool(liquidityPoolId: nativeLiquidityPoolId, cursor: "now"))
            operationsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let operationResponse):
                    if let operation = operationResponse as? LiquidityPoolWithdrawOperationResponse {
                        print("liquidity pool id: " + operation.liquidityPoolId)
                        print("shares: " + operation.shares)
                        if (operation.reservesReceived.last?.asset.code == "COOL") {
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
                        
                        let liquidityPoolWithdrawOp = LiquidityPoolWithdrawOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: self.nativeLiquidityPoolId, amount: 1.0, minAmountA: 1.0, minAmountB: 1.0)
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
    
    
    func testGetLiquidityPools() {
        let expectation = XCTestExpectation(description: "Get liquidity pools and parse their details successfuly")
        sdk.liquidityPools.getLiquidityPools() { (response) -> (Void) in
            switch response {
            case .success(let pools):
                var found = false
                for pool in pools.records {
                    if pool.poolId == self.liquidityPoolId {
                        found = true
                    }
                }
                XCTAssert(found)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetLiquidityPool() {
        let expectation = XCTestExpectation(description: "Get liquidity pool and parse details successfuly")
        sdk.liquidityPools.getLiquidityPool(poolId:self.liquidityPoolId) { (response) -> (Void) in
            switch response {
            case .success(let pool):
                if pool.poolId == self.liquidityPoolId {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetLiquidityPoolsByReserves() {
        let expectation = XCTestExpectation(description: "Get liquidity pools by reserves and parse their details successfuly")
        
        let issuingAccountAKeyPair = try! KeyPair(accountId: assetAIssuingAccount)
        let assetA = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "COOL", issuer: issuingAccountAKeyPair)
        
        let issuingAccountBKeyPair = try! KeyPair(accountId: assetBIssuingAccount)
        let assetB = Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: "SONESO", issuer: issuingAccountBKeyPair)
        
        sdk.liquidityPools.getLiquidityPools(reserveAssetA:assetA!, reserveAssetB:assetB!) { (response) -> (Void) in
            switch response {
            case .success(let pools):
                var found = false
                for pool in pools.records {
                    if pool.poolId == self.liquidityPoolId {
                        found = true
                    }
                }
                XCTAssert(found)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetAccountDetails() {
        
        let expectation = XCTestExpectation(description: "Get account details and parse them successfully")
        
        let sourceAccountKeyPair = try! KeyPair(secretSeed:seed)
        
        sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let accountDetails):
                var found = false
                print("Account-ID: \(accountDetails.accountId)")
                print("Sequence Nr: \(accountDetails.sequenceNumber)")
                for balance in accountDetails.balances {
                    if balance.assetType == "liquidity_pool_shares" {
                        print("Liquidity pool id \(balance.liquidityPoolId!)")
                        print("Balance \(balance.balance)")
                        found = true
                    }
                }
                XCTAssert(found)
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"Get account details test", horizonRequestError: error)
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetLiquidityPoolTrades() {
        let expectation = XCTestExpectation(description: "Get liquidity pool trades and parse details successfuly")
        sdk.liquidityPools.getLiquidityPoolTrades(poolId:self.liquidityPoolId) { (response) -> (Void) in
            switch response {
            case .success(let trades):
                if trades.records.first?.counterLiquidityPoolId == self.liquidityPoolId {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}
