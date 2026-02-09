//
//  StreamingHelperUnitTests.swift
//  stellarsdk
//
//  Created by Claude Code
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

class StreamingHelperUnitTests: XCTestCase {

    // MARK: - StreamingHelper Direct Tests

    func testStreamingHelperInitialization() {
        let helper = StreamingHelper()
        XCTAssertNotNil(helper)
        helper.close()
    }

    func testStreamingHelperClose() {
        let helper = StreamingHelper()
        helper.close()
        // Helper should be closed without error
    }

    func testStreamingHelperCloseIdempotency() {
        // Test that multiple close calls are safe
        let helper = StreamingHelper()
        helper.close()
        helper.close()
        helper.close()
        // Should not crash on multiple close() calls
    }

    func testStreamingHelperSendableConformance() {
        // Test that StreamingHelper conforms to Sendable
        let helper = StreamingHelper()

        // Verify Sendable conformance by using in concurrent context
        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = helper
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        helper.close()
    }

    func testStreamingHelperCanBeCreatedMultipleTimes() {
        // Verify multiple instances can be created and managed independently
        let helper1 = StreamingHelper()
        let helper2 = StreamingHelper()
        let helper3 = StreamingHelper()

        XCTAssertNotNil(helper1)
        XCTAssertNotNil(helper2)
        XCTAssertNotNil(helper3)

        // Each instance is independent
        helper1.close()
        helper2.close()
        helper3.close()
    }

    func testStreamingHelperCloseAfterStreamFromDoesNotCrash() {
        let helper = StreamingHelper()

        // Start a stream with a callback
        helper.streamFrom(requestUrl: "https://horizon-testnet.stellar.org/ledgers?cursor=now") { _ in
            // Ignore response
        }

        // Close immediately after starting stream
        helper.close()
        // Should not crash
    }

    func testStreamingHelperThreadSafety() {
        // Test thread safety by closing from multiple threads
        let helper = StreamingHelper()
        let group = DispatchGroup()

        for _ in 0..<10 {
            group.enter()
            DispatchQueue.global().async {
                helper.close()
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 5.0)
        XCTAssertEqual(result, .success, "Thread safety test should complete without deadlock")
    }

    func testStreamingHelperCloseBeforeStreamFrom() {
        // Test that close before streamFrom is safe
        let helper = StreamingHelper()
        helper.close()
        // Should not crash when closed without ever starting a stream
    }

    // MARK: - EffectsFactory Direct Tests

    func testEffectsFactoryAccountCreatedEffect() throws {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "operation": {"href": "https://horizon.stellar.org/operations/12345"},
                "precedes": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=asc"},
                "succeeds": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=desc"}
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_created",
            "type_i": 0,
            "created_at": "2023-01-15T10:00:00Z",
            "starting_balance": "10000.0000000"
        }
        """.data(using: .utf8)!

        let effect = try factory.effectFromData(data: jsonData)

        XCTAssertTrue(effect is AccountCreatedEffectResponse)
        XCTAssertEqual(effect.id, "12345-1")
        XCTAssertEqual(effect.account, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(effect.effectType, .accountCreated)

        if let accountCreatedEffect = effect as? AccountCreatedEffectResponse {
            XCTAssertEqual(accountCreatedEffect.startingBalance, "10000.0000000")
        } else {
            XCTFail("Expected AccountCreatedEffectResponse")
        }
    }

    func testEffectsFactoryAccountRemovedEffect() throws {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "operation": {"href": "https://horizon.stellar.org/operations/12345"},
                "precedes": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=asc"},
                "succeeds": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=desc"}
            },
            "id": "12345-2",
            "paging_token": "12345-2",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_removed",
            "type_i": 1,
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let effect = try factory.effectFromData(data: jsonData)

        XCTAssertTrue(effect is AccountRemovedEffectResponse)
        XCTAssertEqual(effect.effectType, .accountRemoved)
    }

    func testEffectsFactorySignerCreatedEffect() throws {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "operation": {"href": "https://horizon.stellar.org/operations/12345"},
                "precedes": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=asc"},
                "succeeds": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=desc"}
            },
            "id": "12345-3",
            "paging_token": "12345-3",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "signer_created",
            "type_i": 10,
            "created_at": "2023-01-15T10:00:00Z",
            "weight": 1,
            "public_key": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
        }
        """.data(using: .utf8)!

        let effect = try factory.effectFromData(data: jsonData)

        XCTAssertTrue(effect is SignerCreatedEffectResponse)
        XCTAssertEqual(effect.effectType, .signerCreated)

        if let signerEffect = effect as? SignerCreatedEffectResponse {
            XCTAssertEqual(signerEffect.weight, 1)
            XCTAssertEqual(signerEffect.publicKey, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        } else {
            XCTFail("Expected SignerCreatedEffectResponse")
        }
    }

    func testEffectsFactoryTrustlineCreatedEffect() throws {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "operation": {"href": "https://horizon.stellar.org/operations/12345"},
                "precedes": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=asc"},
                "succeeds": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=desc"}
            },
            "id": "12345-4",
            "paging_token": "12345-4",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "trustline_created",
            "type_i": 20,
            "created_at": "2023-01-15T10:00:00Z",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "limit": "1000000.0000000"
        }
        """.data(using: .utf8)!

        let effect = try factory.effectFromData(data: jsonData)

        XCTAssertTrue(effect is TrustlineCreatedEffectResponse)
        XCTAssertEqual(effect.effectType, .trustlineCreated)

        if let trustlineEffect = effect as? TrustlineCreatedEffectResponse {
            XCTAssertEqual(trustlineEffect.assetCode, "USD")
            XCTAssertEqual(trustlineEffect.assetIssuer, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
            XCTAssertEqual(trustlineEffect.limit, "1000000.0000000")
        } else {
            XCTFail("Expected TrustlineCreatedEffectResponse")
        }
    }

    func testEffectsFactoryTradeEffect() throws {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "operation": {"href": "https://horizon.stellar.org/operations/12345"},
                "precedes": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=asc"},
                "succeeds": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=desc"}
            },
            "id": "12345-5",
            "paging_token": "12345-5",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "trade",
            "type_i": 33,
            "created_at": "2023-01-15T10:00:00Z",
            "seller": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "offer_id": "12345",
            "sold_amount": "100.0000000",
            "sold_asset_type": "credit_alphanum4",
            "sold_asset_code": "USD",
            "sold_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "bought_amount": "50.0000000",
            "bought_asset_type": "native"
        }
        """.data(using: .utf8)!

        let effect = try factory.effectFromData(data: jsonData)

        XCTAssertTrue(effect is TradeEffectResponse)
        XCTAssertEqual(effect.effectType, .tradeEffect)

        if let tradeEffect = effect as? TradeEffectResponse {
            XCTAssertEqual(tradeEffect.seller, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
            XCTAssertEqual(tradeEffect.offerId, "12345")
            XCTAssertEqual(tradeEffect.soldAmount, "100.0000000")
            XCTAssertEqual(tradeEffect.boughtAmount, "50.0000000")
        } else {
            XCTFail("Expected TradeEffectResponse")
        }
    }

    func testEffectsFactoryUnknownType() {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "operation": {"href": "https://horizon.stellar.org/operations/12345"},
                "precedes": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=asc"},
                "succeeds": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=desc"}
            },
            "id": "12345-6",
            "paging_token": "12345-6",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "unknown_effect_type",
            "type_i": 9999,
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try factory.effectFromData(data: jsonData)) { error in
            if let horizonError = error as? HorizonRequestError {
                switch horizonError {
                case .parsingResponseFailed(let message):
                    XCTAssertTrue(message.contains("Unknown effect type"))
                default:
                    XCTFail("Expected parsingResponseFailed error")
                }
            } else {
                XCTFail("Expected HorizonRequestError")
            }
        }
    }

    func testEffectsFactoryInvalidJSON() {
        let factory = EffectsFactory()

        let invalidJSON = "{ not valid json".data(using: .utf8)!

        XCTAssertThrowsError(try factory.effectFromData(data: invalidJSON)) { error in
            // The factory wraps errors as HorizonRequestError.parsingResponseFailed
            if let horizonError = error as? HorizonRequestError {
                switch horizonError {
                case .parsingResponseFailed:
                    // Expected
                    break
                default:
                    XCTFail("Expected parsingResponseFailed error, got \(horizonError)")
                }
            } else {
                // Some JSON errors might be thrown directly
                XCTAssertNotNil(error)
            }
        }
    }

    func testEffectsFactoryMissingTypeField() {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "operation": {"href": "https://horizon.stellar.org/operations/12345"}
            },
            "id": "12345-7",
            "paging_token": "12345-7",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_created",
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Missing type_i field
        XCTAssertThrowsError(try factory.effectFromData(data: jsonData)) { error in
            XCTAssertTrue(error is HorizonRequestError)
        }
    }

    func testEffectsFactorySendableConformance() {
        let factory = EffectsFactory()

        // Verify Sendable conformance
        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = factory
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - OperationsFactory Direct Tests

    func testOperationsFactoryPaymentOperation() throws {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_links": {
                "effects": {"href": "https://horizon.stellar.org/operations/12345/effects", "templated": true},
                "precedes": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=asc"},
                "self": {"href": "https://horizon.stellar.org/operations/12345"},
                "succeeds": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=desc"},
                "transaction": {"href": "https://horizon.stellar.org/transactions/abc123"}
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "payment",
            "type_i": 1,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123def456789",
            "transaction_successful": true,
            "from": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "amount": "100.0000000",
            "asset_type": "native"
        }
        """.data(using: .utf8)!

        let operation = try factory.operationFromData(data: jsonData)

        XCTAssertTrue(operation is PaymentOperationResponse)
        XCTAssertEqual(operation.id, "12345")
        XCTAssertEqual(operation.operationTypeString, "payment")

        if let payment = operation as? PaymentOperationResponse {
            XCTAssertEqual(payment.from, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
            XCTAssertEqual(payment.to, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
            XCTAssertEqual(payment.amount, "100.0000000")
            XCTAssertEqual(payment.assetType, "native")
        } else {
            XCTFail("Expected PaymentOperationResponse")
        }
    }

    func testOperationsFactoryCreateAccountOperation() throws {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_links": {
                "effects": {"href": "https://horizon.stellar.org/operations/12345/effects", "templated": true},
                "precedes": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=asc"},
                "self": {"href": "https://horizon.stellar.org/operations/12345"},
                "succeeds": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=desc"},
                "transaction": {"href": "https://horizon.stellar.org/transactions/abc123"}
            },
            "id": "12346",
            "paging_token": "12346",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "create_account",
            "type_i": 0,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123def456789",
            "transaction_successful": true,
            "account": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "funder": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "starting_balance": "10000.0000000"
        }
        """.data(using: .utf8)!

        let operation = try factory.operationFromData(data: jsonData)

        XCTAssertTrue(operation is AccountCreatedOperationResponse)
        XCTAssertEqual(operation.operationTypeString, "create_account")

        if let createAccount = operation as? AccountCreatedOperationResponse {
            XCTAssertEqual(createAccount.account, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
            XCTAssertEqual(createAccount.funder, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
            XCTAssertEqual(createAccount.startingBalance, Decimal(string: "10000.0000000"))
        } else {
            XCTFail("Expected AccountCreatedOperationResponse")
        }
    }

    func testOperationsFactoryManageBuyOfferOperation() throws {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_links": {
                "effects": {"href": "https://horizon.stellar.org/operations/12345/effects", "templated": true},
                "precedes": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=asc"},
                "self": {"href": "https://horizon.stellar.org/operations/12345"},
                "succeeds": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=desc"},
                "transaction": {"href": "https://horizon.stellar.org/transactions/abc123"}
            },
            "id": "12347",
            "paging_token": "12347",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "manage_buy_offer",
            "type_i": 12,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123def456789",
            "transaction_successful": true,
            "amount": "100.0000000",
            "price": "0.5",
            "price_r": {"n": 1, "d": 2},
            "buying_asset_type": "credit_alphanum4",
            "buying_asset_code": "USD",
            "buying_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "selling_asset_type": "native",
            "offer_id": "0"
        }
        """.data(using: .utf8)!

        let operation = try factory.operationFromData(data: jsonData)

        XCTAssertTrue(operation is ManageBuyOfferOperationResponse)
        XCTAssertEqual(operation.operationTypeString, "manage_buy_offer")

        if let manageBuyOffer = operation as? ManageBuyOfferOperationResponse {
            XCTAssertEqual(manageBuyOffer.amount, "100.0000000")
            XCTAssertEqual(manageBuyOffer.buyingAssetCode, "USD")
            XCTAssertEqual(manageBuyOffer.sellingAssetType, "native")
        } else {
            XCTFail("Expected ManageBuyOfferOperationResponse")
        }
    }

    func testOperationsFactorySetOptionsOperation() throws {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_links": {
                "effects": {"href": "https://horizon.stellar.org/operations/12345/effects", "templated": true},
                "precedes": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=asc"},
                "self": {"href": "https://horizon.stellar.org/operations/12345"},
                "succeeds": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=desc"},
                "transaction": {"href": "https://horizon.stellar.org/transactions/abc123"}
            },
            "id": "12348",
            "paging_token": "12348",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "set_options",
            "type_i": 5,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123def456789",
            "transaction_successful": true,
            "home_domain": "example.com",
            "low_threshold": 1,
            "med_threshold": 2,
            "high_threshold": 3
        }
        """.data(using: .utf8)!

        let operation = try factory.operationFromData(data: jsonData)

        XCTAssertTrue(operation is SetOptionsOperationResponse)
        XCTAssertEqual(operation.operationTypeString, "set_options")

        if let setOptions = operation as? SetOptionsOperationResponse {
            XCTAssertEqual(setOptions.homeDomain, "example.com")
            XCTAssertEqual(setOptions.lowThreshold, 1)
            XCTAssertEqual(setOptions.medThreshold, 2)
            XCTAssertEqual(setOptions.highThreshold, 3)
        } else {
            XCTFail("Expected SetOptionsOperationResponse")
        }
    }

    func testOperationsFactoryUnknownType() {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_links": {
                "effects": {"href": "https://horizon.stellar.org/operations/12345/effects"}
            },
            "id": "12349",
            "paging_token": "12349",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "unknown_operation_type",
            "type_i": 9999,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123def456789",
            "transaction_successful": true
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try factory.operationFromData(data: jsonData)) { error in
            if let horizonError = error as? HorizonRequestError {
                switch horizonError {
                case .parsingResponseFailed(let message):
                    XCTAssertTrue(message.contains("Unknown operation type"))
                default:
                    XCTFail("Expected parsingResponseFailed error")
                }
            } else {
                XCTFail("Expected HorizonRequestError")
            }
        }
    }

    func testOperationsFactoryInvalidJSON() {
        let factory = OperationsFactory()

        let invalidJSON = "not json at all".data(using: .utf8)!

        XCTAssertThrowsError(try factory.operationFromData(data: invalidJSON)) { error in
            // The factory wraps errors as HorizonRequestError.parsingResponseFailed
            if let horizonError = error as? HorizonRequestError {
                switch horizonError {
                case .parsingResponseFailed:
                    // Expected
                    break
                default:
                    XCTFail("Expected parsingResponseFailed error, got \(horizonError)")
                }
            } else {
                // Some JSON errors might be thrown directly
                XCTAssertNotNil(error)
            }
        }
    }

    func testOperationsFactoryMissingTypeField() {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_links": {
                "effects": {"href": "https://horizon.stellar.org/operations/12345/effects"}
            },
            "id": "12350",
            "paging_token": "12350",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "payment",
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Missing type_i field
        XCTAssertThrowsError(try factory.operationFromData(data: jsonData)) { error in
            XCTAssertTrue(error is HorizonRequestError)
        }
    }

    func testOperationsFactorySendableConformance() {
        let factory = OperationsFactory()

        // Verify Sendable conformance
        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = factory
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Protocol Conformance Tests

    func testStreamResponseEnumSendable() {
        // Test that StreamResponseEnum conforms to Sendable
        let openResponse: StreamResponseEnum<String> = .open
        let dataResponse: StreamResponseEnum<String> = .response(id: "123", data: "test")
        let errorResponse: StreamResponseEnum<String> = .error(error: nil)

        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            // These should compile without error due to Sendable conformance
            let _: Sendable = openResponse
            let _: Sendable = dataResponse
            let _: Sendable = errorResponse
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testEffectsStreamItemSendable() {
        let streamItem = EffectsStreamItem(requestUrl: "https://horizon.stellar.org/effects")

        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = streamItem
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        streamItem.closeStream()
    }

    func testOperationsStreamItemSendable() {
        let streamItem = OperationsStreamItem(requestUrl: "https://horizon.stellar.org/operations")

        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = streamItem
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        streamItem.closeStream()
    }

    func testTransactionsStreamItemSendable() {
        let streamItem = TransactionsStreamItem(requestUrl: "https://horizon.stellar.org/transactions")

        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = streamItem
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        streamItem.closeStream()
    }

    func testLedgersStreamItemSendable() {
        let streamItem = LedgersStreamItem(requestUrl: "https://horizon.stellar.org/ledgers")

        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = streamItem
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        streamItem.closeStream()
    }

    func testTradesStreamItemSendable() {
        let streamItem = TradesStreamItem(requestUrl: "https://horizon.stellar.org/trades")

        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let _: Sendable = streamItem
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        streamItem.closeStream()
    }

    // MARK: - EffectsFactory Page Response Tests

    func testEffectsFactoryEffectsFromResponseData() throws {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "operation": {"href": "https://horizon.stellar.org/operations/12345"},
                            "precedes": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=asc"},
                            "succeeds": {"href": "https://horizon.stellar.org/effects?cursor=12345&order=desc"}
                        },
                        "id": "12345-1",
                        "paging_token": "12345-1",
                        "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                        "type": "account_created",
                        "type_i": 0,
                        "created_at": "2023-01-15T10:00:00Z",
                        "starting_balance": "10000.0000000"
                    }
                ]
            },
            "_links": {
                "next": {"href": "https://horizon.stellar.org/effects?cursor=12345-1"},
                "prev": {"href": "https://horizon.stellar.org/effects?cursor=12345-1&order=desc"},
                "self": {"href": "https://horizon.stellar.org/effects"}
            }
        }
        """.data(using: .utf8)!

        let pageResponse = try factory.effectsFromResponseData(data: jsonData)

        XCTAssertEqual(pageResponse.records.count, 1)
        XCTAssertTrue(pageResponse.records[0] is AccountCreatedEffectResponse)
        XCTAssertEqual(pageResponse.records[0].id, "12345-1")
    }

    func testEffectsFactoryEffectsFromResponseDataInvalidEmbedded() {
        let factory = EffectsFactory()

        let jsonData = """
        {
            "_links": {
                "next": {"href": "https://horizon.stellar.org/effects?cursor=12345-1"}
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try factory.effectsFromResponseData(data: jsonData)) { error in
            XCTAssertTrue(error is HorizonRequestError)
        }
    }

    // MARK: - OperationsFactory Page Response Tests

    func testOperationsFactoryOperationsFromResponseData() throws {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "effects": {"href": "https://horizon.stellar.org/operations/12345/effects", "templated": true},
                            "precedes": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=asc"},
                            "self": {"href": "https://horizon.stellar.org/operations/12345"},
                            "succeeds": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=desc"},
                            "transaction": {"href": "https://horizon.stellar.org/transactions/abc123"}
                        },
                        "id": "12345",
                        "paging_token": "12345",
                        "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                        "type": "payment",
                        "type_i": 1,
                        "created_at": "2023-01-15T10:00:00Z",
                        "transaction_hash": "abc123def456789",
                        "transaction_successful": true,
                        "from": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                        "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
                        "amount": "100.0000000",
                        "asset_type": "native"
                    }
                ]
            },
            "_links": {
                "next": {"href": "https://horizon.stellar.org/operations?cursor=12345"},
                "prev": {"href": "https://horizon.stellar.org/operations?cursor=12345&order=desc"},
                "self": {"href": "https://horizon.stellar.org/operations"}
            }
        }
        """.data(using: .utf8)!

        let pageResponse = try factory.operationsFromResponseData(data: jsonData)

        XCTAssertEqual(pageResponse.records.count, 1)
        XCTAssertTrue(pageResponse.records[0] is PaymentOperationResponse)
        XCTAssertEqual(pageResponse.records[0].id, "12345")
    }

    func testOperationsFactoryOperationsFromResponseDataMissingLinks() {
        let factory = OperationsFactory()

        let jsonData = """
        {
            "_embedded": {
                "records": []
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try factory.operationsFromResponseData(data: jsonData)) { error in
            XCTAssertTrue(error is HorizonRequestError)
        }
    }
}
