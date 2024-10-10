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
    
    override func setUp() async throws {
        try await super.setUp()
        
        let testAccountId = testKeyPair.accountId
        let SONESOIssuingAccountId = SONESOIssuingAccountKeyPair.accountId
        let COOLIssuingAccountId = COOLIssuingAccountKeyPair.accountId
        let SONESOAsset = ChangeTrustAsset(canonicalForm: "SONESO:" + SONESOIssuingAccountId)!
        let COOLAsset = ChangeTrustAsset(canonicalForm: "COOL:" + COOLIssuingAccountId)!
        let changeTrustOp1 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:SONESOAsset, limit: 100000000)
        let changeTrustOp2 = ChangeTrustOperation(sourceAccountId:testAccountId, asset:COOLAsset, limit: 100000000)
        let payOp1 = try! PaymentOperation(sourceAccountId: SONESOIssuingAccountId, destinationAccountId: testAccountId, asset: SONESOAsset, amount: 50000)
        let payOp2 = try! PaymentOperation(sourceAccountId: COOLIssuingAccountId, destinationAccountId: testAccountId, asset: COOLAsset, amount: 50000)
        
        var responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: SONESOIssuingAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(SONESOIssuingAccountId)")
        }
        
        responseEnum = await sdk.accounts.createTestAccount(accountId: COOLIssuingAccountId)
        switch responseEnum {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(COOLIssuingAccountId)")
        }
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: testAccountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp1, changeTrustOp2, payOp1, payOp2],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: self.testKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.SONESOIssuingAccountKeyPair, network: Network.testnet)
            try! transaction.sign(keyPair: self.COOLIssuingAccountKeyPair, network: Network.testnet)
            
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
        await createPoolShareTrustlineNotNative()
        await createPoolShareTrustlineNative()
        await poolShareDepositNonNative()
        await poolShareDepositNative()
        await poolShareWithdrawNonNative()
        await poolShareWithdrawNative()
        await getEffectsForLiquidityPool()
        await getOperationsForLiquidityPool()
        await getLiquidityPools()
        await getLiquidityPool()
        await getLiquidityPoolsByReserves()
        await getAccountDetails()
    }

    func createPoolShareTrustlineNotNative() async {
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
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            
            let changeTrustAsset = try! ChangeTrustAsset(assetA:assetA, assetB:assetB);
            let changeTrustOperation = ChangeTrustOperation(sourceAccountId: muxSource.accountId, asset:changeTrustAsset!)
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [changeTrustOperation],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
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
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func createPoolShareTrustlineNative() async {
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
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            print ("Muxed source account id: \(muxSource.accountId)")
            
            let changeTrustAsset = try! ChangeTrustAsset(assetA:self.assetNative!, assetB:assetA);
            let changeTrustOperation = ChangeTrustOperation(sourceAccountId: muxSource.accountId, asset:changeTrustAsset!)
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [changeTrustOperation],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
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
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func poolShareDepositNonNative() async {
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
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            let minPrice = Price.fromString(price: "1.0")
            let maxPrice = Price.fromString(price: "2.0")
            
            let liquidityPoolDepositOp = LiquidityPoolDepositOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: poolId, maxAmountA: 250.0, maxAmountB: 250.0, minPrice: minPrice, maxPrice: maxPrice)
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [liquidityPoolDepositOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
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
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
    }
    
    func poolShareDepositNative() async {
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
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            
            let minPrice = Price.fromString(price: "1.0")
            let maxPrice = Price.fromString(price: "2.0")
            
            let liquidityPoolDepositOp = LiquidityPoolDepositOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: poolId, maxAmountA: 5.0, maxAmountB: 5.0, minPrice: minPrice, maxPrice: maxPrice)
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [liquidityPoolDepositOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
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
        await fulfillment(of: [expectation], timeout: 15.0)
        
    }
    
    func poolShareWithdrawNonNative() async {
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
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            print ("Muxed source account id: \(muxSource.accountId)")
            
            let liquidityPoolWithdrawOp = LiquidityPoolWithdrawOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: poolId, amount: 100.0, minAmountA: 100.0, minAmountB: 100.0)
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [liquidityPoolWithdrawOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
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
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func poolShareWithdrawNative() async {
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
        
        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: sourceAccountKeyPair.accountId);
        switch accDetailsResEnum {
        case .success(let accountResponse):
            let muxSource = MuxedAccount(keyPair: sourceAccountKeyPair, sequenceNumber: accountResponse.sequenceNumber, id: 1278881)
            print ("Muxed source account id: \(muxSource.accountId)")
            
            let liquidityPoolWithdrawOp = LiquidityPoolWithdrawOperation(sourceAccountId: muxSource.accountId, liquidityPoolId: self.nativeLiquidityPoolId!, amount: 1.0, minAmountA: 1.0, minAmountB: 1.0)
            let transaction = try! Transaction(sourceAccount: muxSource,
                                              operations: [liquidityPoolWithdrawOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: sourceAccountKeyPair, network: self.network)
            
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
        await fulfillment(of: [expectation], timeout: 15.0)
    
    }
    
    func getEffectsForLiquidityPool() async {
        guard let poolId = self.nonNativeLiquidityPoolId else {
            print("one must run all tests")
            XCTFail()
            return
        }
        
        let response = await sdk.effects.getEffects(forLiquidityPool: poolId, order:Order.descending);
        switch response {
        case .success(_):
            XCTAssert(true)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetEffectsForLiquidityPool Test", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getOperationsForLiquidityPool() async {
        guard let poolId = self.nonNativeLiquidityPoolId else {
            print("one must run all tests")
            XCTFail()
            return
        }
        
        let response = await sdk.operations.getOperations(forLiquidityPool: poolId, from: nil, order: Order.descending, includeFailed: true, join: "transactions")
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
    }
    
    func getLiquidityPools() async {
        let response = await sdk.liquidityPools.getLiquidityPools(order:Order.ascending, limit: 4)
        switch response {
        case .success(let pools):
            XCTAssert(pools.records.count == 4)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getLiquidityPool() async {
        guard let poolId = self.nonNativeLiquidityPoolId else {
            print("one must run all tests")
            XCTFail()
            return
        }
        let response = await sdk.liquidityPools.getLiquidityPool(poolId:poolId)
        switch response {
        case .success(let pool):
            if pool.poolId != poolId {
                XCTFail()
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testGetLiquidityPools Test", horizonRequestError: error)
            XCTFail()
        }
    }
    
    func getLiquidityPoolsByReserves() async {
        let assetB = ChangeTrustAsset(canonicalForm: "SONESO:" + SONESOIssuingAccountKeyPair.accountId)!
        let assetA = ChangeTrustAsset(canonicalForm: "COOL:" + COOLIssuingAccountKeyPair.accountId)!
        
        guard let poolId = self.nonNativeLiquidityPoolId else {
            print("one must run all tests")
            XCTFail()
            return
        }
        
        let response = await sdk.liquidityPools.getLiquidityPools(reserveAssetA:assetA, reserveAssetB:assetB)
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
        
    }
    
    func getAccountDetails() async {

        let response = await sdk.accounts.getAccountDetails(accountId: testKeyPair.accountId)
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
