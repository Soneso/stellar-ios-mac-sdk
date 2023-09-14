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
    var effectsStreamItem:EffectsStreamItem? = nil
    var operationsStreamItem:OperationsStreamItem? = nil
    let assetNative = Asset(type: AssetType.ASSET_TYPE_NATIVE)
    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let SONESOIssuingAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    let COOLIssuingAccountKeyPair = try! KeyPair.generateRandomKeyPair()
    var nonNativeLiquidityPoolId:String? = nil
    var nativeLiquidityPoolId:String? = nil
    
    override func setUp() {
        super.setUp()
        let expectation = XCTestExpectation(description: "accounts prepared for tests")
        let testAccountId = testKeyPair.accountId
        let SONESOIssuingAccountId = SONESOIssuingAccountKeyPair.accountId
        let COOLIssuingAccountId = COOLIssuingAccountKeyPair.accountId
        let SONESOAsset = ChangeTrustAsset(canonicalForm: "SONESO:" + SONESOIssuingAccountId)!
        let COOLAsset = ChangeTrustAsset(canonicalForm: "COOL:" + COOLIssuingAccountId)!
        let changeTrustOp1 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:SONESOAsset, limit: 100000000)
        let changeTrustOp2 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:COOLAsset, limit: 100000000)
        let payOp1 = try! PaymentOperation(sourceAccountId: SONESOIssuingAccountId, destinationAccountId: testAccountId, asset: SONESOAsset, amount: 50000)
        let payOp2 = try! PaymentOperation(sourceAccountId: COOLIssuingAccountId, destinationAccountId: testAccountId, asset: COOLAsset, amount: 50000)
        
        sdk.accounts.createTestAccount(accountId: testAccountId) { (response) -> (Void) in
            switch response {
            case .success(_):
                self.sdk.accounts.createTestAccount(accountId: SONESOIssuingAccountId) { (response) -> (Void) in
                    switch response {
                    case .success(_):
                        self.sdk.accounts.createTestAccount(accountId: COOLIssuingAccountId) { (response) -> (Void) in
                            switch response {
                            case .success(_):
                                self.sdk.accounts.getAccountDetails(accountId: testAccountId) { (response) -> (Void) in
                                    switch response {
                                    case .success(let accountResponse):
                                        let transaction = try! Transaction(sourceAccount: accountResponse,
                                                                          operations: [changeTrustOp1, changeTrustOp2, payOp1, payOp2],
                                                                          memo: Memo.none)
                                        try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
                                        try! transaction.sign(keyPair: self.SONESOIssuingAccountKeyPair, network: Network.testnet)
                                        try! transaction.sign(keyPair: self.COOLIssuingAccountKeyPair, network: Network.testnet)
                                        try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                                            switch response {
                                            case .success(let response):
                                                print("setUp: Transaction successfully sent. Hash:\(response.transactionHash)")
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
            case .failure(_):
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 55.0)
    }
    
    func testAll() {
        createPoolShareTrustlineNotNative()
        createPoolShareTrustlineNative()
        poolShareDepositNonNative()
        poolShareDepositNative()
        poolShareWithdrawNonNative()
        poolShareWithdrawNative()
        getEffectsForLiquidityPool()
        getOperationsForLiquidityPool()
        getLiquidityPools()
        getLiquidityPool()
        getLiquidityPoolsByReserves()
        getAccountDetails()
    }

    func createPoolShareTrustlineNotNative() {
        XCTContext.runActivity(named: "createPoolShareTrustlineNotNative") { activity in
            let expectation = XCTestExpectation(description: "pool share trustline created")
            
            let sourceAccountKeyPair = testKeyPair
            let assetA = ChangeTrustAsset(canonicalForm: "COOL:" + COOLIssuingAccountKeyPair.accountId)!
            let assetB = ChangeTrustAsset(canonicalForm: "SONESO:" + SONESOIssuingAccountKeyPair.accountId)!

            
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? TrustlineCreatedEffectResponse {
                        if let poolId = effect.liquidityPoolId {
                            self.nonNativeLiquidityPoolId = poolId
                            print("trustline created. pool id: \(poolId)")
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("testCreatePoolShareTrustlineNotNative stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    
                    let changeTrustAsset = try! ChangeTrustAsset(assetA:assetA, assetB:assetB);
                    let changeTrustOperation = ChangeTrustOperation(sourceAccountId: muxSource.accountId, asset:changeTrustAsset!)
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [changeTrustOperation],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("testCreatePoolShareTrustlineNotNative: Transaction successfully sent. Hash:\(response.transactionHash)")
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testCreatePoolShareTrustlineNotNative", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func createPoolShareTrustlineNative() {
        XCTContext.runActivity(named: "createPoolShareTrustlineNative") { activity in
            let expectation = XCTestExpectation(description: "pool share trustline created")
            let sourceAccountKeyPair = testKeyPair
            let assetA = ChangeTrustAsset(canonicalForm: "COOL:" + COOLIssuingAccountKeyPair.accountId)!
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForAccount(account: sourceAccountKeyPair.accountId, cursor: "now"))
            effectsStreamItem?.onReceive { (response) -> (Void) in
                switch response {
                case .open:
                    break
                case .response(_, let effectResponse):
                    if let effect = effectResponse as? TrustlineCreatedEffectResponse {
                        if let poolId = effect.liquidityPoolId {
                            print("trustline created, pool id: \(poolId)")
                            self.nativeLiquidityPoolId = poolId
                            expectation.fulfill()
                        }
                    }
                case .error(let error):
                    if let horizonRequestError = error as? HorizonRequestError {
                        StellarSDKLog.printHorizonRequestErrorMessage(tag:"CB Test - stream", horizonRequestError:horizonRequestError)
                    } else {
                        print("createPoolShareTrustlineNative stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    print ("Muxed source account id: \(muxSource.accountId)")
                    
                    let changeTrustAsset = try! ChangeTrustAsset(assetA:self.assetNative!, assetB:assetA);
                    let changeTrustOperation = ChangeTrustOperation(sourceAccountId: muxSource.accountId, asset:changeTrustAsset!)
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [changeTrustOperation],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("create poolshare test: Transaction successfully sent. Hash:\(response.transactionHash)")
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"create poolshare test", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func poolShareDepositNonNative() {
        XCTContext.runActivity(named: "poolShareDepositNonNative") { activity in
            let expectation = XCTestExpectation(description: "pool share deposit")
            guard let poolId = self.nonNativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            
            let sourceAccountKeyPair = testKeyPair
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForLiquidityPool(liquidityPool: poolId, cursor: "now"))
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
                        print("poolShareDepositNonNative stream error \(error?.localizedDescription ?? "")")
                    }
                    break
                }
            }
            sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId) { (response) -> (Void) in
                switch response {
                case .success(let accountResponse):
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    let minPrice = Price.fromString(price: "1.0")
                    let maxPrice = Price.fromString(price: "2.0")
                    
                    let liquidityPoolDepositOp = LiquidityPoolDepositOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: poolId, maxAmountA: 250.0, maxAmountB: 250.0, minPrice: minPrice, maxPrice: maxPrice)
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [liquidityPoolDepositOp],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("pool share deposit: Transaction successfully sent. Hash:\(response.transactionHash)")
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"pool share deposit", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func poolShareDepositNative() {
        XCTContext.runActivity(named: "poolShareDepositNative") { activity in
            let expectation = XCTestExpectation(description: "pool share deposit native")
            guard let poolId = self.nativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            let sourceAccountKeyPair = testKeyPair
            
            effectsStreamItem = sdk.effects.stream(for: .effectsForLiquidityPool(liquidityPool: poolId, cursor: "now"))
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
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    
                    let minPrice = Price.fromString(price: "1.0")
                    let maxPrice = Price.fromString(price: "2.0")
                    
                    let liquidityPoolDepositOp = LiquidityPoolDepositOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: poolId, maxAmountA: 5.0, maxAmountB: 5.0, minPrice: minPrice, maxPrice: maxPrice)
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [liquidityPoolDepositOp],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("pool share deposit: Transaction successfully sent. Hash:\(response.transactionHash)")
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"pool share deposit", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func poolShareWithdrawNonNative() {
        XCTContext.runActivity(named: "poolShareWithdrawNonNative") { activity in
            let expectation = XCTestExpectation(description: "pool share withdraw")
            
            guard let poolId = self.nonNativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            
            let sourceAccountKeyPair = testKeyPair
            
            operationsStreamItem = sdk.operations.stream(for: .operationsForLiquidityPool(liquidityPoolId: poolId, cursor: "now"))
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
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    print ("Muxed source account id: \(muxSource.accountId)")
                    
                    let liquidityPoolWithdrawOp = LiquidityPoolWithdrawOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: poolId, amount: 100.0, minAmountA: 100.0, minAmountB: 100.0)
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [liquidityPoolWithdrawOp],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("pool share withdraw: Transaction successfully sent. Hash:\(response.transactionHash)")
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"ppool share withdraw", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func poolShareWithdrawNative() {
        XCTContext.runActivity(named: "poolShareWithdrawNative") { activity in
            let expectation = XCTestExpectation(description: "pool share withdraw")
            let sourceAccountKeyPair = testKeyPair
            
            operationsStreamItem = sdk.operations.stream(for: .operationsForLiquidityPool(liquidityPoolId: nativeLiquidityPoolId!, cursor: "now"))
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
                    let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
                    print ("Muxed source account id: \(muxSource.accountId)")
                    
                    let liquidityPoolWithdrawOp = LiquidityPoolWithdrawOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: self.nativeLiquidityPoolId!, amount: 1.0, minAmountA: 1.0, minAmountB: 1.0)
                    let transaction = try! Transaction(sourceAccount: muxSource,
                                                      operations: [liquidityPoolWithdrawOp],
                                                      memo: Memo.none)
                    try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
                    
                    try! self.sdk.transactions.submitTransaction(transaction: transaction) { (response) -> (Void) in
                        switch response {
                        case .success(let response):
                            print("pool share withdraw: Transaction successfully sent. Hash:\(response.transactionHash)")
                        default:
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"ppool share withdraw", horizonRequestError:error)
                    XCTFail()
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getEffectsForLiquidityPool() {
        XCTContext.runActivity(named: "getEffectsForLiquidityPool") { activity in
            let expectation = XCTestExpectation(description: "Get effects for liquidity ppol and parse their details successfuly")
            
            guard let poolId = self.nonNativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            
            sdk.effects.getEffects(forLiquidityPool: poolId, order:Order.descending) { (response) -> (Void) in
                switch response {
                case .success(_):
                    XCTAssert(true)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetEffectsForLiquidityPool Test", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getOperationsForLiquidityPool() {
        XCTContext.runActivity(named: "getOperationsForLiquidityPool") { activity in
            let expectation = XCTestExpectation(description: "Get operations for liquidity ppol and parse their details successfuly")
            
            guard let poolId = self.nonNativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            
            sdk.operations.getOperations(forLiquidityPool: poolId, from: nil, order: Order.descending, includeFailed: true, join: "transactions") { (response) -> (Void) in
                switch response {
                case .success(let ops):
                    if let operation = ops.records.first {
                        XCTAssert(operation.transactionSuccessful)
                    } else {
                        XCTFail()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetOperationsForLiquidityPool Test", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getLiquidityPools() {
        XCTContext.runActivity(named: "getLiquidityPools") { activity in
            let expectation = XCTestExpectation(description: "Get liquidity pools and parse their details successfuly")
            sdk.liquidityPools.getLiquidityPools(order:Order.ascending, limit: 4) { (response) -> (Void) in
                switch response {
                case .success(let pools):
                    XCTAssert(pools.records.count == 4)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getLiquidityPool() {
        XCTContext.runActivity(named: "getLiquidityPool") { activity in
            let expectation = XCTestExpectation(description: "Get liquidity pool and parse details successfuly")
            guard let poolId = self.nonNativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            sdk.liquidityPools.getLiquidityPool(poolId:poolId) { (response) -> (Void) in
                switch response {
                case .success(let pool):
                    if pool.poolId != poolId {
                        XCTFail()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getLiquidityPoolsByReserves() {
        XCTContext.runActivity(named: "getLiquidityPoolsByReserves") { activity in
            let expectation = XCTestExpectation(description: "Get liquidity pools by reserves and parse their details successfuly")
            
            let assetB = ChangeTrustAsset(canonicalForm: "SONESO:" + SONESOIssuingAccountKeyPair.accountId)!
            let assetA = ChangeTrustAsset(canonicalForm: "COOL:" + COOLIssuingAccountKeyPair.accountId)!
            
            guard let poolId = self.nonNativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            
            sdk.liquidityPools.getLiquidityPools(reserveAssetA:assetA, reserveAssetB:assetB) { (response) -> (Void) in
                switch response {
                case .success(let pools):
                    var found = false
                    for pool in pools.records {
                        if pool.poolId == poolId {
                            found = true
                            break
                        }
                    }
                    XCTAssert(found)
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    func getAccountDetails() {
        XCTContext.runActivity(named: "getAccountDetails") { activity in
            let expectation = XCTestExpectation(description: "Get account details and parse them successfully")
            
            let sourceAccountKeyPair = testKeyPair
            
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
                    XCTFail()
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    /*func getLiquidityPoolTrades() {
        XCTContext.runActivity(named: "getLiquidityPoolTrades") { activity in
            let expectation = XCTestExpectation(description: "Get liquidity pool trades and parse details successfuly")
            
            guard let poolId = self.nonNativeLiquidityPoolId else {
                print("one must run all tests")
                XCTFail()
                return
            }
            
            sdk.liquidityPools.getLiquidityPoolTrades(poolId:poolId) { (response) -> (Void) in
                switch response {
                case .success(let trades):
                    if trades.records.first?.counterLiquidityPoolId == poolId {
                        XCTAssert(true)
                    } else {
                        XCTFail()
                    }
                case .failure(let error):
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
                    XCTFail()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }*/
}
