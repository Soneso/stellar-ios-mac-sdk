//
//  LiquidityPoolTradesStreamingTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 07.01.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class LiquidityPoolTradesStreamingTestCase: XCTestCase {

    static let testOn = "testnet"
    let sdk = testOn == "testnet" ? StellarSDK.testNet() : StellarSDK.futureNet()
    let network = testOn == "testnet" ? Network.testnet : Network.futurenet

    var tradesStreamItem: LiquidityPoolTradesStreamItem? = nil

    let testKeyPair = try! KeyPair.generateRandomKeyPair()
    let issuingKeyPair = try! KeyPair.generateRandomKeyPair()
    var liquidityPoolId: String? = nil
    var customAsset: ChangeTrustAsset? = nil

    override func setUp() async throws {
        try await super.setUp()

        let testAccountId = testKeyPair.accountId
        let issuingAccountId = issuingKeyPair.accountId

        // Create test accounts
        var response = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: testAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: testAccountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create test account: \(testAccountId)")
        }

        response = network.passphrase == Network.testnet.passphrase ? await sdk.accounts.createTestAccount(accountId: issuingAccountId) : await sdk.accounts.createFutureNetTestAccount(accountId: issuingAccountId)
        switch response {
        case .success(_):
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"setUp()", horizonRequestError: error)
            XCTFail("could not create issuing account: \(issuingAccountId)")
        }

        // Create custom asset and establish trustline
        customAsset = ChangeTrustAsset(canonicalForm: "TEST:" + issuingAccountId)!
        let changeTrustOp = ChangeTrustOperation(sourceAccountId: testAccountId, asset: customAsset!, limit: 100000)
        let paymentOp = try! PaymentOperation(sourceAccountId: issuingAccountId, destinationAccountId: testAccountId, asset: customAsset!, amount: 5000)

        let accDetailsRes = await sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsRes {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp, paymentOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: testKeyPair, network: network)
            try! transaction.sign(keyPair: issuingKeyPair, network: network)

            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction)
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

        // Create liquidity pool
        await createLiquidityPool()
    }

    override func tearDown() {
        tradesStreamItem?.closeStream()
        super.tearDown()
    }

    func testAll() async {
        await testStreamLiquidityPoolTrades()
    }

    func createLiquidityPool() async {
        guard let customAsset = customAsset else {
            XCTFail("Custom asset not initialized")
            return
        }

        let testAccountId = testKeyPair.accountId
        let nativeAsset = ChangeTrustAsset(type: AssetType.ASSET_TYPE_NATIVE)!

        // Create pool share asset (assetA must be < assetB in lexicographic order)
        // Native < AlphaNum4 < AlphaNum12, so native comes first
        let poolShareAsset = try! ChangeTrustAsset(assetA: nativeAsset, assetB: customAsset)!

        // Get pool ID from canonical form (format: "poolId:lp")
        let canonicalForm = poolShareAsset.toCanonicalForm()
        liquidityPoolId = String(canonicalForm.dropLast(3)) // Remove ":lp" suffix

        // Create pool share trustline
        let changeTrustOp = ChangeTrustOperation(sourceAccountId: testAccountId, asset: poolShareAsset, limit: 100000)

        let accDetailsRes = await sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsRes {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [changeTrustOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: testKeyPair, network: network)

            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createLiquidityPool()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createLiquidityPool()", horizonRequestError: error)
            XCTFail("could not load account details")
        }

        // Deposit to pool
        let depositOp = LiquidityPoolDepositOperation(sourceAccountId: testAccountId,
                                                     liquidityPoolId: liquidityPoolId!,
                                                     maxAmountA: 10,
                                                     maxAmountB: 10,
                                                     minPrice: Price(numerator: 1, denominator: 1),
                                                     maxPrice: Price(numerator: 1, denominator: 1))

        let accDetailsRes2 = await sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsRes2 {
        case .success(let accountResponse):
            let transaction = try! Transaction(sourceAccount: accountResponse,
                                              operations: [depositOp],
                                              memo: Memo.none)
            try! transaction.sign(keyPair: testKeyPair, network: network)

            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResponse {
            case .success(let details):
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"createLiquidityPool()", horizonRequestError: error)
                XCTFail("submit transaction error")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"createLiquidityPool()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }

    func testStreamLiquidityPoolTrades() async {
        guard let liquidityPoolId = liquidityPoolId else {
            XCTFail("Liquidity pool not created")
            return
        }

        let expectation = XCTestExpectation(description: "Liquidity pool trades stream receives update")

        nonisolated(unsafe) var streamOpened = false
        nonisolated(unsafe) var tradeReceived = false

        tradesStreamItem = sdk.liquidityPools.streamTrades(forPoolId: liquidityPoolId)
        tradesStreamItem?.onReceive { response in
            switch response {
            case .open:
                streamOpened = true
                print("Liquidity pool trades stream opened")
            case .response(id: let id, data: let trade):
                print("Trade received - id: \(id), type: \(trade.tradeType)")
                print("Base: \(trade.baseAmount) \(trade.baseAssetCode ?? "XLM")")
                print("Counter: \(trade.counterAmount) \(trade.counterAssetCode ?? "XLM")")

                // Check if this trade involves our liquidity pool
                if trade.baseLiquidityPoolId == liquidityPoolId || trade.counterLiquidityPoolId == liquidityPoolId {
                    tradeReceived = true
                    expectation.fulfill()
                }
            case .error(let error):
                if let horizonRequestError = error as? HorizonRequestError {
                    StellarSDKLog.printHorizonRequestErrorMessage(tag:"testStreamLiquidityPoolTrades", horizonRequestError:horizonRequestError)
                } else {
                    print("Error \(error?.localizedDescription ?? "")")
                }
                XCTFail("Stream error occurred")
                expectation.fulfill()
            }
        }

        // Wait for stream to open
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Execute a path payment to trigger a trade through the liquidity pool
        await executeTrade()

        await fulfillment(of: [expectation], timeout: 30.0)

        XCTAssertTrue(streamOpened, "Stream should have opened")
        XCTAssertTrue(tradeReceived, "Should have received trade update")

        tradesStreamItem?.closeStream()
        tradesStreamItem = nil
    }

    func executeTrade() async {
        guard let customAsset = customAsset else {
            XCTFail("Custom asset not initialized")
            return
        }

        let testAccountId = testKeyPair.accountId
        let nativeAsset = Asset(type: AssetType.ASSET_TYPE_NATIVE)!

        // Execute path payment to create a trade through the pool
        let pathPaymentStrictReceiveOp = try! PathPaymentStrictReceiveOperation(
            sourceAccountId: testAccountId,
            sendAsset: nativeAsset,
            sendMax: 2.0,
            destinationAccountId: testAccountId,
            destAsset: customAsset,
            destAmount: 1.0,
            path: []
        )

        let accDetailsRes = await sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsRes {
        case .success(let accountResponse):
            let transaction = try! Transaction(
                sourceAccount: accountResponse,
                operations: [pathPaymentStrictReceiveOp],
                memo: Memo.none
            )
            try! transaction.sign(keyPair: testKeyPair, network: network)

            let submitTxResponse = await sdk.transactions.submitTransaction(transaction: transaction)
            switch submitTxResponse {
            case .success(let details):
                print("Trade executed successfully - operations: \(details.operationCount)")
                XCTAssert(details.operationCount > 0)
            case .destinationRequiresMemo(destinationAccountId: let destinationAccountId):
                XCTFail("destination account \(destinationAccountId) requires memo")
            case .failure(error: let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"executeTrade()", horizonRequestError: error)
                // Note: Trade might fail if pool doesn't have enough liquidity
                // This is acceptable for the test as long as we get streaming updates
                print("Trade execution failed (may be expected)")
            }
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"executeTrade()", horizonRequestError: error)
            XCTFail("could not load account details")
        }
    }
}
