//
//  HorizonSecretSeedRefusalUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 12.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The Horizon request and stream methods refuse a strkey or id argument that starts with
/// "S" or "s" before any request, without the value in the error, and send every other value
/// as given.
final class HorizonSecretSeedRefusalUnitTests: XCTestCase {

    /// Records the URL of every request the mock servers are asked to serve.
    private final class URLRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var urls = [String]()

        func record(_ url: String) {
            lock.lock()
            defer { lock.unlock() }
            urls.append(url)
        }

        func reset() {
            lock.lock()
            defer { lock.unlock() }
            urls.removeAll()
        }

        var recorded: [String] {
            lock.lock()
            defer { lock.unlock() }
            return urls
        }
    }

    /// Holds the first event a stream hands its receiver and whether it arrived on the main
    /// thread; the event arrives outside the test's isolation.
    private final class EventBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Error?
        private var storedOnMainThread = false
        private var filled = false

        func store(_ error: Error?, onMainThread: Bool) {
            lock.lock()
            defer { lock.unlock() }
            if !filled {
                stored = error
                storedOnMainThread = onMainThread
                filled = true
            }
        }

        var error: Error? {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }

        var arrivedOnMainThread: Bool {
            lock.lock()
            defer { lock.unlock() }
            return storedOnMainThread
        }

        var isFilled: Bool {
            lock.lock()
            defer { lock.unlock() }
            return filled
        }
    }

    /// Stands for a stream event other than an error.
    private struct UnexpectedEvent: Error {}

    /// A request method with one strkey or id argument under test.
    private struct RequestCase {
        /// The method and argument, for failure messages.
        let label: String
        /// The argument name the refusal names.
        let name: String
        /// A value Horizon takes for the argument, which the request URL then carries.
        let valid: String
        let call: (StellarSDK, String) async -> HorizonRequestError?
    }

    /// A stream method with one strkey or id argument under test. `start` opens the stream
    /// for the value, hands its first event to the closure and returns the stream's close.
    private struct StreamCase {
        let label: String
        let name: String
        let start: (StellarSDK, String, @escaping @Sendable (Error?) -> Void) -> () -> Void
    }

    private static let accountG = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    private static let poolHex = "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
    private static let transactionHash = "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889"
    private let seedText = "a secret seed (S...)"
    private let sValueText = "a value starting with S (not shown, it may be a secret seed)"

    private var sdk: StellarSDK!
    private var recorder: URLRecorder!
    private var variants: SeedVariants!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sdk = StellarSDK()
        variants = try SeedVariants()
        recorder = URLRecorder()
        URLProtocol.registerClass(ServerMock.self)
        let recorder = recorder!
        for host in ["horizon-testnet.stellar.org", "friendbot-futurenet.stellar.org"] {
            ServerMock.add(mock: RequestMock(host: host, path: "*", httpMethod: "GET", mockHandler: { _, request in
                recorder.record(request.url?.absoluteString ?? "")
                return "{}"
            }))
        }
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    private func keyText(_ variant: String) -> String {
        return variant == variants.seed ? seedText : sValueText
    }

    private func refusal(_ name: String, _ variant: String) -> String {
        return "\(name) is \(keyText(variant)); the request is not sent"
    }

    // MARK: - Request methods

    func testRequestMethodsRefuseASeedBeforeAnyRequest() async {
        for requestCase in requestCases {
            for variant in variants.all {
                let error = await requestCase.call(sdk, variant)
                guard case .badRequest(let message, let response)? = error else {
                    XCTFail("\(requestCase.label): expected badRequest, got \(String(describing: error))")
                    continue
                }
                XCTAssertNil(response, requestCase.label)
                XCTAssertEqual(message, refusal(requestCase.name, variant), requestCase.label)
            }
        }
        XCTAssertEqual(recorder.recorded.count, 0, "no request may be sent for a value that starts with S")
    }

    func testRequestMethodsSendEveryOtherValue() async {
        for requestCase in requestCases {
            recorder.reset()
            let error = await requestCase.call(sdk, requestCase.valid)
            if case .badRequest(let message, _)? = error {
                XCTFail("\(requestCase.label): \(requestCase.valid) was refused: \(message)")
            }
            let urls = recorder.recorded
            XCTAssertEqual(urls.count, 1, "\(requestCase.label): \(urls)")
            XCTAssertTrue(urls.first?.contains(requestCase.valid) ?? false, "\(requestCase.label): \(urls)")
        }
    }

    /// Only strkey and hex id arguments are checked. Canonical asset strings, asset codes and
    /// account data names, whose valid values may start with "S", and decimal ids go to
    /// Horizon as given.
    func testArgumentsThatAreNoStrkeyOrHexIdAreSentAsGiven() async {
        let asset = "SRT:\(Self.accountG)"
        let account = Self.accountG
        let ledger = "123456"
        let operation = "12884905984"
        let offer = "12345"
        let calls: [(String, String, () async -> HorizonRequestError?)] = [
            ("getAccounts asset", asset, { Self.failure(of: await self.sdk.accounts.getAccounts(asset: asset)) }),
            ("strictReceive sourceAssets", asset, {
                Self.failure(of: await self.sdk.paymentPaths.strictReceive(sourceAssets: "\(asset),native")) }),
            ("strictSend destinationAssets", asset, {
                Self.failure(of: await self.sdk.paymentPaths.strictSend(destinationAssets: "native,\(asset)")) }),
            ("getAssets assetCode", "SRT", { Self.failure(of: await self.sdk.assets.getAssets(for: "SRT", assetIssuer: account)) }),
            ("getDataForAccount key", "Seed", {
                Self.failure(of: await self.sdk.accounts.getDataForAccount(accountId: account, key: "Seed")) }),
            ("getLedger", ledger, { Self.failure(of: await self.sdk.ledgers.getLedger(sequenceNumber: ledger)) }),
            ("getEffects forLedger", ledger, { Self.failure(of: await self.sdk.effects.getEffects(forLedger: ledger)) }),
            ("getOperations forLedger", ledger, { Self.failure(of: await self.sdk.operations.getOperations(forLedger: ledger)) }),
            ("getPayments forLedger", ledger, { Self.failure(of: await self.sdk.payments.getPayments(forLedger: ledger)) }),
            ("getTransactions forLedger", ledger, {
                Self.failure(of: await self.sdk.transactions.getTransactions(forLedger: ledger)) }),
            ("getEffects forOperation", operation, {
                Self.failure(of: await self.sdk.effects.getEffects(forOperation: operation)) }),
            ("getOperationDetails", operation, {
                Self.failure(of: await self.sdk.operations.getOperationDetails(operationId: operation)) }),
            ("getOfferDetails", offer, { Self.failure(of: await self.sdk.offers.getOfferDetails(offerId: offer)) }),
            ("offers getTrades forOffer", offer, { Self.failure(of: await self.sdk.offers.getTrades(forOffer: offer)) }),
            ("getTrades offerId", offer, { Self.failure(of: await self.sdk.trades.getTrades(baseAssetType: nil, offerId: offer)) }),
        ]
        for (label, value, call) in calls {
            recorder.reset()
            let error = await call()
            if case .badRequest(let message, _)? = error {
                XCTFail("\(label) was refused: \(message)")
            }
            let urls = recorder.recorded
            XCTAssertEqual(urls.count, 1, "\(label): \(urls)")
            XCTAssertTrue(urls.first?.removingPercentEncoding?.contains(value) ?? false, "\(label): \(urls)")
        }
    }

    /// The claimable balance id routes refuse every spelling that is no id before the request.
    func testClaimableBalanceIdsHoldingASeedAreRefusedBeforeAnyRequest() async {
        let calls: [(String, (String) async -> HorizonRequestError?)] = [
            ("getClaimableBalance", { Self.failure(of: await self.sdk.claimableBalances.getClaimableBalance(balanceId: $0)) }),
            ("getOperations", { Self.failure(of: await self.sdk.operations.getOperations(forClaimableBalance: $0)) }),
            ("getTransactions", { Self.failure(of: await self.sdk.transactions.getTransactions(forClaimableBalance: $0)) }),
        ]
        for (label, call) in calls {
            for variant in variants.all {
                let error = await call(variant)
                guard case .badRequest(let message, _)? = error else {
                    XCTFail("\(label): expected badRequest, got \(String(describing: error))")
                    continue
                }
                XCTAssertFalse(message.contains(variant), label)
            }
        }
        XCTAssertEqual(recorder.recorded.count, 0, "no request may be sent for a value that starts with S")
    }

    // MARK: - Stream methods

    func testStreamMethodsRefuseASeedWithoutConnecting() {
        // A stream that connected anyway would reach this closed local port, never a server.
        let localSdk = StellarSDK(withHorizonUrl: "http://127.0.0.1:9")
        for streamCase in streamCases {
            for variant in variants.all {
                let box = EventBox()
                let received = expectation(description: "\(streamCase.label) reports the refusal")
                received.assertForOverFulfill = false
                let close = streamCase.start(localSdk, variant) { error in
                    box.store(error, onMainThread: Thread.isMainThread)
                    received.fulfill()
                }
                // The refusal reaches the receiver on the main queue after the call returned,
                // as a stream event does, so a receiver that reopens a stream does not recurse.
                XCTAssertFalse(box.isFilled, "\(streamCase.label): the refusal arrived during the call")
                wait(for: [received], timeout: 2)
                close()
                XCTAssertTrue(box.arrivedOnMainThread, streamCase.label)
                guard let horizonError = box.error as? HorizonRequestError,
                      case .badRequest(let message, let response) = horizonError else {
                    XCTFail("\(streamCase.label): expected badRequest, got \(String(describing: box.error))")
                    continue
                }
                XCTAssertNil(response, streamCase.label)
                XCTAssertEqual(message, refusal(streamCase.name, variant), streamCase.label)
            }
        }
    }

    func testStreamsBuildNoUrlForASeedAndTheirUrlForEveryOtherValue() {
        let base = StellarSDK.testNetUrl
        let account = Self.accountG
        let seed = variants.seed
        XCTAssertEqual(sdk.transactions.stream(for: .transactionsForAccount(account: account, cursor: nil)).requestUrl,
                       "\(base)/accounts/\(account)/transactions")
        XCTAssertEqual(sdk.transactions.stream(for: .transactionsForLedger(ledger: "123456", cursor: nil)).requestUrl,
                       "\(base)/ledgers/123456/transactions")
        XCTAssertEqual(sdk.operations.stream(for: .operationsForAccount(account: account, cursor: nil)).requestUrl,
                       "\(base)/accounts/\(account)/operations")
        XCTAssertEqual(sdk.operations.stream(for: .operationsForLedger(ledger: "123456", cursor: nil)).requestUrl,
                       "\(base)/ledgers/123456/operations")
        XCTAssertEqual(sdk.operations.stream(for: .operationsForTransaction(transaction: Self.transactionHash, cursor: nil)).requestUrl,
                       "\(base)/transactions/\(Self.transactionHash)/operations")
        XCTAssertEqual(sdk.operations.stream(for: .operationsForLiquidityPool(liquidityPoolId: Self.poolHex, cursor: nil)).requestUrl,
                       "\(base)/liquidity_pools/\(Self.poolHex)/operations")
        XCTAssertEqual(sdk.payments.stream(for: .paymentsForAccount(account: account, cursor: nil)).requestUrl,
                       "\(base)/accounts/\(account)/payments")
        XCTAssertEqual(sdk.payments.stream(for: .paymentsForLedger(ledger: "123456", cursor: nil)).requestUrl,
                       "\(base)/ledgers/123456/payments")
        XCTAssertEqual(sdk.payments.stream(for: .paymentsForTransaction(transaction: Self.transactionHash, cursor: nil)).requestUrl,
                       "\(base)/transactions/\(Self.transactionHash)/payments")

        let refused = [
            sdk.transactions.stream(for: .transactionsForAccount(account: seed, cursor: nil)).requestUrl,
            sdk.operations.stream(for: .operationsForAccount(account: seed, cursor: nil)).requestUrl,
            sdk.operations.stream(for: .operationsForTransaction(transaction: seed, cursor: nil)).requestUrl,
            sdk.operations.stream(for: .operationsForLiquidityPool(liquidityPoolId: seed, cursor: nil)).requestUrl,
            sdk.payments.stream(for: .paymentsForAccount(account: seed, cursor: nil)).requestUrl,
            sdk.payments.stream(for: .paymentsForTransaction(transaction: seed, cursor: nil)).requestUrl,
        ]
        XCTAssertEqual(refused, Array(repeating: "", count: refused.count))
    }

    // MARK: - The cases

    private var requestCases: [RequestCase] {
        let account = Self.accountG
        let pool = Self.poolHex
        let hash = Self.transactionHash
        return [
            RequestCase(label: "getAccountDetails", name: "accountId", valid: account) {
                Self.failure(of: await $0.accounts.getAccountDetails(accountId: $1)) },
            RequestCase(label: "getDataForAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.accounts.getDataForAccount(accountId: $1, key: "name")) },
            RequestCase(label: "createTestAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.accounts.createTestAccount(accountId: $1)) },
            RequestCase(label: "createFutureNetTestAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.accounts.createFutureNetTestAccount(accountId: $1)) },
            RequestCase(label: "getAccounts signer", name: "signer", valid: account) {
                Self.failure(of: await $0.accounts.getAccounts(signer: $1)) },
            RequestCase(label: "getAccounts sponsor", name: "sponsor", valid: account) {
                Self.failure(of: await $0.accounts.getAccounts(sponsor: $1)) },
            RequestCase(label: "getAccounts liquidityPoolId", name: "liquidityPoolId", valid: pool) {
                Self.failure(of: await $0.accounts.getAccounts(liquidityPoolId: $1)) },
            RequestCase(label: "getAssets", name: "assetIssuer", valid: account) {
                Self.failure(of: await $0.assets.getAssets(for: "USD", assetIssuer: $1)) },
            RequestCase(label: "getClaimableBalances claimant", name: "claimantAccountId", valid: account) {
                Self.failure(of: await $0.claimableBalances.getClaimableBalances(claimantAccountId: $1)) },
            RequestCase(label: "getClaimableBalances sponsor", name: "sponsorAccountId", valid: account) {
                Self.failure(of: await $0.claimableBalances.getClaimableBalances(sponsorAccountId: $1)) },
            RequestCase(label: "getEffects forAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.effects.getEffects(forAccount: $1)) },
            RequestCase(label: "getEffects forTransaction", name: "hash", valid: hash) {
                Self.failure(of: await $0.effects.getEffects(forTransaction: $1)) },
            RequestCase(label: "getEffects forLiquidityPool", name: "liquidityPoolId", valid: pool) {
                Self.failure(of: await $0.effects.getEffects(forLiquidityPool: $1)) },
            RequestCase(label: "getLiquidityPool", name: "poolId", valid: pool) {
                Self.failure(of: await $0.liquidityPools.getLiquidityPool(poolId: $1)) },
            RequestCase(label: "getLiquidityPools account", name: "account", valid: account) {
                Self.failure(of: await $0.liquidityPools.getLiquidityPools(account: $1)) },
            RequestCase(label: "getLiquidityPoolTrades", name: "poolId", valid: pool) {
                Self.failure(of: await $0.liquidityPools.getLiquidityPoolTrades(poolId: $1)) },
            RequestCase(label: "getOffers forAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.offers.getOffers(forAccount: $1)) },
            RequestCase(label: "getOffers seller", name: "seller", valid: account) {
                Self.failure(of: await $0.offers.getOffers(seller: $1, sellingAssetType: "native", buyingAssetType: "native")) },
            RequestCase(label: "getOffers sellingAssetIssuer", name: "sellingAssetIssuer", valid: account) {
                Self.failure(of: await $0.offers.getOffers(seller: nil, sellingAssetType: "credit_alphanum4", sellingAssetCode: "USD",
                                                           sellingAssetIssuer: $1, buyingAssetType: "native")) },
            RequestCase(label: "getOffers buyingAssetIssuer", name: "buyingAssetIssuer", valid: account) {
                Self.failure(of: await $0.offers.getOffers(seller: nil, sellingAssetType: "native", buyingAssetType: "credit_alphanum4",
                                                           buyingAssetCode: "USD", buyingAssetIssuer: $1)) },
            RequestCase(label: "getOffers sponsor", name: "sponsor", valid: account) {
                Self.failure(of: await $0.offers.getOffers(seller: nil, sellingAssetType: "native", buyingAssetType: "native", sponsor: $1)) },
            RequestCase(label: "getOperations forAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.operations.getOperations(forAccount: $1)) },
            RequestCase(label: "getOperations forTransaction", name: "hash", valid: hash) {
                Self.failure(of: await $0.operations.getOperations(forTransaction: $1)) },
            RequestCase(label: "getOperations forLiquidityPool", name: "liquidityPoolId", valid: pool) {
                Self.failure(of: await $0.operations.getOperations(forLiquidityPool: $1)) },
            RequestCase(label: "getOrderbook sellingAssetIssuer", name: "sellingAssetIssuer", valid: account) {
                Self.failure(of: await $0.orderbooks.getOrderbook(sellingAssetType: "credit_alphanum4", sellingAssetCode: "USD",
                                                                  sellingAssetIssuer: $1, buyingAssetType: "native")) },
            RequestCase(label: "getOrderbook buyingAssetIssuer", name: "buyingAssetIssuer", valid: account) {
                Self.failure(of: await $0.orderbooks.getOrderbook(sellingAssetType: "native", buyingAssetType: "credit_alphanum4",
                                                                  buyingAssetCode: "USD", buyingAssetIssuer: $1)) },
            RequestCase(label: "findPaymentPaths destinationAccount", name: "destinationAccount", valid: account) {
                Self.failure(of: await $0.paymentPaths.findPaymentPaths(destinationAccount: $1, destinationAssetType: "native",
                                                                        destinationAmount: "1", sourceAccount: account)) },
            RequestCase(label: "findPaymentPaths destinationAssetIssuer", name: "destinationAssetIssuer", valid: account) {
                Self.failure(of: await $0.paymentPaths.findPaymentPaths(destinationAccount: account, destinationAssetType: "credit_alphanum4",
                                                                        destinationAssetCode: "USD", destinationAssetIssuer: $1,
                                                                        destinationAmount: "1", sourceAccount: account)) },
            RequestCase(label: "findPaymentPaths sourceAccount", name: "sourceAccount", valid: account) {
                Self.failure(of: await $0.paymentPaths.findPaymentPaths(destinationAccount: account, destinationAssetType: "native",
                                                                        destinationAmount: "1", sourceAccount: $1)) },
            RequestCase(label: "strictReceive sourceAccount", name: "sourceAccount", valid: account) {
                Self.failure(of: await $0.paymentPaths.strictReceive(sourceAccount: $1, destinationAssetType: "native", destinationAmount: "1")) },
            RequestCase(label: "strictReceive destinationAccount", name: "destinationAccount", valid: account) {
                Self.failure(of: await $0.paymentPaths.strictReceive(sourceAssets: "native", destinationAccount: $1,
                                                                     destinationAssetType: "native", destinationAmount: "1")) },
            RequestCase(label: "strictReceive destinationAssetIssuer", name: "destinationAssetIssuer", valid: account) {
                Self.failure(of: await $0.paymentPaths.strictReceive(sourceAccount: account, destinationAssetType: "credit_alphanum4",
                                                                     destinationAssetCode: "USD", destinationAssetIssuer: $1,
                                                                     destinationAmount: "1")) },
            RequestCase(label: "strictSend sourceAssetIssuer", name: "sourceAssetIssuer", valid: account) {
                Self.failure(of: await $0.paymentPaths.strictSend(sourceAmount: "1", sourceAssetType: "credit_alphanum4",
                                                                  sourceAssetCode: "USD", sourceAssetIssuer: $1, destinationAccount: account)) },
            RequestCase(label: "strictSend destinationAccount", name: "destinationAccount", valid: account) {
                Self.failure(of: await $0.paymentPaths.strictSend(sourceAmount: "1", sourceAssetType: "native", destinationAccount: $1)) },
            RequestCase(label: "getPayments forAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.payments.getPayments(forAccount: $1)) },
            RequestCase(label: "getPayments forTransaction", name: "hash", valid: hash) {
                Self.failure(of: await $0.payments.getPayments(forTransaction: $1)) },
            RequestCase(label: "getTradeAggregations baseAssetIssuer", name: "baseAssetIssuer", valid: account) {
                Self.failure(of: await $0.tradeAggregations.getTradeAggregations(baseAssetType: "credit_alphanum4", baseAssetCode: "USD",
                                                                                 baseAssetIssuer: $1, counterAssetType: "native")) },
            RequestCase(label: "getTradeAggregations counterAssetIssuer", name: "counterAssetIssuer", valid: account) {
                Self.failure(of: await $0.tradeAggregations.getTradeAggregations(baseAssetType: "native", counterAssetType: "credit_alphanum4",
                                                                                 counterAssetCode: "USD", counterAssetIssuer: $1)) },
            RequestCase(label: "getTrades baseAssetIssuer", name: "baseAssetIssuer", valid: account) {
                Self.failure(of: await $0.trades.getTrades(baseAssetType: "credit_alphanum4", baseAssetCode: "USD", baseAssetIssuer: $1)) },
            RequestCase(label: "getTrades counterAssetIssuer", name: "counterAssetIssuer", valid: account) {
                Self.failure(of: await $0.trades.getTrades(counterAssetType: "credit_alphanum4", counterAssetCode: "USD",
                                                           counterAssetIssuer: $1)) },
            RequestCase(label: "getTrades forAccount filter", name: "forAccount", valid: account) {
                Self.failure(of: await $0.trades.getTrades(baseAssetType: nil, forAccount: $1)) },
            RequestCase(label: "getTrades forLiquidityPool", name: "forLiquidityPool", valid: pool) {
                Self.failure(of: await $0.trades.getTrades(baseAssetType: nil, forLiquidityPool: $1)) },
            RequestCase(label: "getTrades forAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.trades.getTrades(forAccount: $1, from: nil)) },
            RequestCase(label: "getTransactions forAccount", name: "accountId", valid: account) {
                Self.failure(of: await $0.transactions.getTransactions(forAccount: $1)) },
            RequestCase(label: "getTransactions forLiquidityPool", name: "liquidityPoolId", valid: pool) {
                Self.failure(of: await $0.transactions.getTransactions(forLiquidityPool: $1)) },
            RequestCase(label: "getTransactionDetails", name: "transactionHash", valid: hash) {
                Self.failure(of: await $0.transactions.getTransactionDetails(transactionHash: $1)) },
        ]
    }

    private var streamCases: [StreamCase] {
        return [
            StreamCase(label: "streamAccount", name: "accountId") { sdk, value, deliver in
                let item = sdk.accounts.streamAccount(accountId: value)
                item.onReceive { Self.forward($0, to: deliver) }
                return { item.closeStream() }
            },
            StreamCase(label: "streamAccountData", name: "accountId") { sdk, value, deliver in
                let item = sdk.accounts.streamAccountData(accountId: value, key: "name")
                item.onReceive { Self.forward($0, to: deliver) }
                return { item.closeStream() }
            },
            effectsCase("effectsForAccount", "account") { .effectsForAccount(account: $0, cursor: nil) },
            effectsCase("effectsForTransaction", "transaction") { .effectsForTransaction(transaction: $0, cursor: nil) },
            effectsCase("effectsForLiquidityPool", "liquidityPool") { .effectsForLiquidityPool(liquidityPool: $0, cursor: nil) },
            StreamCase(label: "liquidityPools.streamTrades", name: "poolId") { sdk, value, deliver in
                let item = sdk.liquidityPools.streamTrades(forPoolId: value)
                item.onReceive { Self.forward($0, to: deliver) }
                return { item.closeStream() }
            },
            offersCase("allOffers seller", "seller") {
                .allOffers(seller: $0, sellingAssetType: "native", sellingAssetCode: nil, sellingAssetIssuer: nil,
                           buyingAssetType: "native", buyingAssetCode: nil, buyingAssetIssuer: nil, sponsor: nil, cursor: nil, order: nil)
            },
            offersCase("allOffers sellingAssetIssuer", "sellingAssetIssuer") {
                .allOffers(seller: nil, sellingAssetType: "credit_alphanum4", sellingAssetCode: "USD", sellingAssetIssuer: $0,
                           buyingAssetType: "native", buyingAssetCode: nil, buyingAssetIssuer: nil, sponsor: nil, cursor: nil, order: nil)
            },
            offersCase("allOffers buyingAssetIssuer", "buyingAssetIssuer") {
                .allOffers(seller: nil, sellingAssetType: "native", sellingAssetCode: nil, sellingAssetIssuer: nil,
                           buyingAssetType: "credit_alphanum4", buyingAssetCode: "USD", buyingAssetIssuer: $0, sponsor: nil,
                           cursor: nil, order: nil)
            },
            offersCase("allOffers sponsor", "sponsor") {
                .allOffers(seller: nil, sellingAssetType: "native", sellingAssetCode: nil, sellingAssetIssuer: nil,
                           buyingAssetType: "native", buyingAssetCode: nil, buyingAssetIssuer: nil, sponsor: $0, cursor: nil, order: nil)
            },
            offersCase("offersForAccount", "account") { .offersForAccount(account: $0, cursor: nil) },
            operationsCase("operationsForAccount", "account") { .operationsForAccount(account: $0, cursor: nil) },
            operationsCase("operationsForTransaction", "transaction") { .operationsForTransaction(transaction: $0, cursor: nil) },
            operationsCase("operationsForLiquidityPool", "liquidityPoolId") {
                .operationsForLiquidityPool(liquidityPoolId: $0, cursor: nil)
            },
            orderbookCase("orderbook sellingAssetIssuer", "sellingAssetIssuer") {
                .orderbook(sellingAssetType: "credit_alphanum4", sellingAssetCode: "USD", sellingAssetIssuer: $0,
                           buyingAssetType: "native", buyingAssetCode: nil, buyingAssetIssuer: nil, limit: nil, cursor: nil)
            },
            orderbookCase("orderbook buyingAssetIssuer", "buyingAssetIssuer") {
                .orderbook(sellingAssetType: "native", sellingAssetCode: nil, sellingAssetIssuer: nil,
                           buyingAssetType: "credit_alphanum4", buyingAssetCode: "USD", buyingAssetIssuer: $0, limit: nil, cursor: nil)
            },
            paymentsCase("paymentsForAccount", "account") { .paymentsForAccount(account: $0, cursor: nil) },
            paymentsCase("paymentsForTransaction", "transaction") { .paymentsForTransaction(transaction: $0, cursor: nil) },
            tradesCase("allTrades baseAssetIssuer", "baseAssetIssuer") {
                .allTrades(baseAssetType: "credit_alphanum4", baseAssetCode: "USD", baseAssetIssuer: $0, counterAssetType: nil,
                           counterAssetCode: nil, counterAssetIssuer: nil, cursor: nil, order: nil, limit: nil)
            },
            tradesCase("allTrades counterAssetIssuer", "counterAssetIssuer") {
                .allTrades(baseAssetType: nil, baseAssetCode: nil, baseAssetIssuer: nil, counterAssetType: "credit_alphanum4",
                           counterAssetCode: "USD", counterAssetIssuer: $0, cursor: nil, order: nil, limit: nil)
            },
            tradesCase("tradesForAccount", "account") { .tradesForAccount(account: $0, cursor: nil) },
            transactionsCase("transactionsForAccount", "account") { .transactionsForAccount(account: $0, cursor: nil) },
        ]
    }

    private func effectsCase(_ label: String, _ name: String, _ change: @escaping (String) -> EffectsChange) -> StreamCase {
        return StreamCase(label: label, name: name) { sdk, value, deliver in
            let item = sdk.effects.stream(for: change(value))
            item.onReceive { Self.forward($0, to: deliver) }
            return { item.closeStream() }
        }
    }

    private func offersCase(_ label: String, _ name: String, _ change: @escaping (String) -> OffersChange) -> StreamCase {
        return StreamCase(label: label, name: name) { sdk, value, deliver in
            let item = sdk.offers.stream(for: change(value))
            item.onReceive { Self.forward($0, to: deliver) }
            return { item.closeStream() }
        }
    }

    private func operationsCase(_ label: String, _ name: String, _ change: @escaping (String) -> OperationsChange) -> StreamCase {
        return StreamCase(label: label, name: name) { sdk, value, deliver in
            let item = sdk.operations.stream(for: change(value))
            item.onReceive { Self.forward($0, to: deliver) }
            return { item.closeStream() }
        }
    }

    private func orderbookCase(_ label: String, _ name: String, _ change: @escaping (String) -> OrderbookChange) -> StreamCase {
        return StreamCase(label: label, name: name) { sdk, value, deliver in
            let item = sdk.orderbooks.stream(for: change(value))
            item.onReceive { Self.forward($0, to: deliver) }
            return { item.closeStream() }
        }
    }

    private func paymentsCase(_ label: String, _ name: String, _ change: @escaping (String) -> PaymentsChange) -> StreamCase {
        return StreamCase(label: label, name: name) { sdk, value, deliver in
            let item = sdk.payments.stream(for: change(value))
            item.onReceive { Self.forward($0, to: deliver) }
            return { item.closeStream() }
        }
    }

    private func tradesCase(_ label: String, _ name: String, _ change: @escaping (String) -> TradesChange) -> StreamCase {
        return StreamCase(label: label, name: name) { sdk, value, deliver in
            let item = sdk.trades.stream(for: change(value))
            item.onReceive { Self.forward($0, to: deliver) }
            return { item.closeStream() }
        }
    }

    private func transactionsCase(_ label: String, _ name: String,
                                  _ change: @escaping (String) -> TransactionsChange) -> StreamCase {
        return StreamCase(label: label, name: name) { sdk, value, deliver in
            let item = sdk.transactions.stream(for: change(value))
            item.onReceive { Self.forward($0, to: deliver) }
            return { item.closeStream() }
        }
    }

    // MARK: - Helpers

    private static func forward<T>(_ response: StreamResponseEnum<T>, to deliver: @Sendable (Error?) -> Void) {
        if case .error(let error) = response {
            deliver(error)
        } else {
            deliver(UnexpectedEvent())
        }
    }

    private static func failure(of response: AccountResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: DataForAccountResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: CreateTestAccountResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure<T>(of response: PageResponse<T>.ResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: ClaimableBalanceDetailsResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: LedgerDetailsResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: LiquidityPoolDetailsResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: LiquidityPoolTradesResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: OfferResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: OperationDetailsResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: OrderbookResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: PaymentPathsResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }

    private static func failure(of response: TransactionDetailsResponseEnum) -> HorizonRequestError? {
        if case .failure(let error) = response { return error }
        return nil
    }
}
