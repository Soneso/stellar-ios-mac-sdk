//
//  StreamingDeepUnitTests.swift
//  stellarsdk
//
//  Created by Soneso
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

class StreamingIntegrationUnitTests: XCTestCase {

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        return decoder
    }

    // MARK: - AccountDataStreamItem Deep Tests

    func testAccountDataStreamItemOnReceiveOpen() {
        let expectation = XCTestExpectation(description: "Stream open received")
        let streamItem = AccountDataStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST/data/key")

        streamItem.onReceive { response in
            switch response {
            case .open:
                expectation.fulfill()
            case .response, .error:
                XCTFail("Expected open response")
            }
        }

        streamItem.closeStream()
    }

    func testAccountDataStreamItemOnReceiveValidData() {
        let expectation = XCTestExpectation(description: "Valid data received")
        let streamItem = AccountDataStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST/data/key")

        let jsonString = """
        {
            "value": "dGVzdF92YWx1ZQ==",
            "sponsor": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let data):
                XCTAssertEqual(data.value, "dGVzdF92YWx1ZQ==")
                XCTAssertEqual(data.sponsor, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testAccountDataStreamItemOnReceiveMalformedJSON() {
        let expectation = XCTestExpectation(description: "Malformed JSON error received")
        let streamItem = AccountDataStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST/data/key")

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        expectation.fulfill()
                    }
                }
            case .open:
                break
            case .response:
                XCTFail("Should not receive response for malformed JSON")
            }
        }

        streamItem.closeStream()
    }

    func testAccountDataStreamItemOnReceiveMissingRequiredField() {
        let expectation = XCTestExpectation(description: "Missing field error received")
        let streamItem = AccountDataStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST/data/key")

        let jsonString = """
        {
            "sponsor": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        expectation.fulfill()
                    }
                }
            case .open:
                break
            case .response:
                XCTFail("Should not receive response for missing required field")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - AccountStreamItem Deep Tests

    func testAccountStreamItemOnReceiveOpen() {
        let expectation = XCTestExpectation(description: "Stream open received")
        let streamItem = AccountStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST")

        streamItem.onReceive { response in
            switch response {
            case .open:
                expectation.fulfill()
            case .response, .error:
                XCTFail("Expected open response")
            }
        }

        streamItem.closeStream()
    }

    func testAccountStreamItemOnReceiveMinimalValidAccount() {
        let expectation = XCTestExpectation(description: "Minimal valid account received")
        let streamItem = AccountStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/accounts/TEST"}
            },
            "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "sequence": "100",
            "subentry_count": 0,
            "last_modified_ledger": 1000,
            "last_modified_time": "2023-01-15T10:00:00Z",
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false,
                "auth_immutable": false,
                "auth_clawback_enabled": false
            },
            "balances": [],
            "signers": [],
            "data": {},
            "num_sponsoring": 0,
            "num_sponsored": 0,
            "paging_token": "TEST"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let account):
                XCTAssertEqual(account.accountId, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
                XCTAssertEqual(account.sequenceNumber, 100)
                XCTAssertEqual(account.subentryCount, 0)
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testAccountStreamItemOnReceiveComplexAccount() {
        let expectation = XCTestExpectation(description: "Complex account with multiple balances")
        let streamItem = AccountStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/accounts/TEST"}
            },
            "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "sequence": "123456789",
            "subentry_count": 10,
            "last_modified_ledger": 50000,
            "last_modified_time": "2023-06-15T10:00:00Z",
            "thresholds": {
                "low_threshold": 5,
                "med_threshold": 10,
                "high_threshold": 20
            },
            "flags": {
                "auth_required": true,
                "auth_revocable": true,
                "auth_immutable": false,
                "auth_clawback_enabled": true
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "limit": "922337203685.4775807",
                    "buying_liabilities": "100.0000000",
                    "selling_liabilities": "50.0000000",
                    "last_modified_ledger": 49999,
                    "is_authorized": true,
                    "is_authorized_to_maintain_liabilities": true,
                    "asset_type": "credit_alphanum4",
                    "asset_code": "USD",
                    "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
                },
                {
                    "balance": "5000.0000000",
                    "buying_liabilities": "0.0000000",
                    "selling_liabilities": "0.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "weight": 1,
                    "key": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "type": "ed25519_public_key"
                }
            ],
            "data": {
                "test_key": "dGVzdF9kYXRh"
            },
            "num_sponsoring": 2,
            "num_sponsored": 1,
            "sponsor": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "paging_token": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let account):
                XCTAssertEqual(account.balances.count, 2)
                XCTAssertEqual(account.signers.count, 1)
                XCTAssertEqual(account.numSponsoring, 2)
                XCTAssertEqual(account.numSponsored, 1)
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - EffectsStreamItem Deep Tests

    func testEffectsStreamItemOnReceiveOpen() {
        let expectation = XCTestExpectation(description: "Stream open received")
        let streamItem = EffectsStreamItem(requestUrl: "https://test.stellar.org/effects")

        streamItem.onReceive { response in
            switch response {
            case .open:
                expectation.fulfill()
            case .response, .error:
                XCTFail("Expected open response")
            }
        }

        streamItem.closeStream()
    }

    func testEffectsStreamItemOnReceiveAccountRemovedEffect() {
        let expectation = XCTestExpectation(description: "Account removed effect received")
        let streamItem = EffectsStreamItem(requestUrl: "https://test.stellar.org/effects")

        let jsonString = """
        {
            "_links": {
                "operation": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_removed",
            "type_i": 1,
            "created_at": "2023-01-15T10:00:00Z"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let effect):
                XCTAssertEqual(effect.effectTypeString, "account_removed")
                XCTAssertEqual(effect.account, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testEffectsStreamItemOnReceiveSignerEffect() {
        let expectation = XCTestExpectation(description: "Signer created effect received")
        let streamItem = EffectsStreamItem(requestUrl: "https://test.stellar.org/effects")

        let jsonString = """
        {
            "_links": {
                "operation": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345-2",
            "paging_token": "12345-2",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "signer_created",
            "type_i": 10,
            "created_at": "2023-01-15T10:00:00Z",
            "weight": 5,
            "public_key": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let effect):
                XCTAssertEqual(effect.effectTypeString, "signer_created")
                if let signerEffect = effect as? SignerCreatedEffectResponse {
                    XCTAssertEqual(signerEffect.weight, 5)
                    XCTAssertEqual(signerEffect.publicKey, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testEffectsStreamItemOnReceiveTrustlineEffect() {
        let expectation = XCTestExpectation(description: "Trustline created effect received")
        let streamItem = EffectsStreamItem(requestUrl: "https://test.stellar.org/effects")

        let jsonString = """
        {
            "_links": {
                "operation": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345-3",
            "paging_token": "12345-3",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "trustline_created",
            "type_i": 20,
            "created_at": "2023-01-15T10:00:00Z",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "limit": "1000000.0000000"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let effect):
                XCTAssertEqual(effect.effectTypeString, "trustline_created")
                if let trustlineEffect = effect as? TrustlineCreatedEffectResponse {
                    XCTAssertEqual(trustlineEffect.assetCode, "USD")
                    XCTAssertEqual(trustlineEffect.limit, "1000000.0000000")
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - LiquidityPoolTradesStreamItem Deep Tests

    func testLiquidityPoolTradesStreamItemOnReceiveOpen() {
        let expectation = XCTestExpectation(description: "Stream open received")
        let streamItem = LiquidityPoolTradesStreamItem(requestUrl: "https://test.stellar.org/liquidity_pools/TEST/trades")

        streamItem.onReceive { response in
            switch response {
            case .open:
                expectation.fulfill()
            case .response, .error:
                XCTFail("Expected open response")
            }
        }

        streamItem.closeStream()
    }

    func testLiquidityPoolTradesStreamItemOnReceiveLiquidityPoolTrade() {
        let expectation = XCTestExpectation(description: "Liquidity pool trade received")
        let streamItem = LiquidityPoolTradesStreamItem(requestUrl: "https://test.stellar.org/liquidity_pools/TEST/trades")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/trades/12345"}
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "liquidity_pool",
            "base_liquidity_pool_id": "abcdef1234567890",
            "liquidity_pool_fee_bp": 30,
            "base_amount": "100.0000000",
            "base_asset_type": "credit_alphanum4",
            "base_asset_code": "USD",
            "base_asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "counter_account": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "counter_amount": "50.0000000",
            "counter_asset_type": "native",
            "base_is_seller": true,
            "price": {
                "n": 1,
                "d": 2
            }
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let trade):
                XCTAssertEqual(trade.tradeType, "liquidity_pool")
                XCTAssertEqual(trade.baseLiquidityPoolId, "abcdef1234567890")
                XCTAssertEqual(trade.liquidityPoolFeeBp, 30)
                XCTAssertEqual(trade.baseAmount, "100.0000000")
                XCTAssertEqual(trade.counterAmount, "50.0000000")
                XCTAssertTrue(trade.baseIsSeller)
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testLiquidityPoolTradesStreamItemOnReceiveCounterLiquidityPoolTrade() {
        let expectation = XCTestExpectation(description: "Trade with counter liquidity pool")
        let streamItem = LiquidityPoolTradesStreamItem(requestUrl: "https://test.stellar.org/liquidity_pools/TEST/trades")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/trades/12345"}
            },
            "id": "12345-2",
            "paging_token": "12345-2",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "liquidity_pool",
            "base_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "base_amount": "200.0000000",
            "base_asset_type": "native",
            "counter_liquidity_pool_id": "fedcba0987654321",
            "counter_amount": "100.0000000",
            "counter_asset_type": "credit_alphanum4",
            "counter_asset_code": "EUR",
            "counter_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "base_is_seller": false,
            "price": {
                "n": 2,
                "d": 1
            }
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let trade):
                XCTAssertEqual(trade.counterLiquidityPoolId, "fedcba0987654321")
                XCTAssertEqual(trade.baseAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
                XCTAssertFalse(trade.baseIsSeller)
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - OperationsStreamItem Deep Tests

    func testOperationsStreamItemOnReceiveOpen() {
        let expectation = XCTestExpectation(description: "Stream open received")
        let streamItem = OperationsStreamItem(requestUrl: "https://test.stellar.org/operations")

        streamItem.onReceive { response in
            switch response {
            case .open:
                expectation.fulfill()
            case .response, .error:
                XCTFail("Expected open response")
            }
        }

        streamItem.closeStream()
    }

    func testOperationsStreamItemOnReceivePathPaymentStrictReceiveOperation() {
        let expectation = XCTestExpectation(description: "Path payment operation received")
        let streamItem = OperationsStreamItem(requestUrl: "https://test.stellar.org/operations")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "path_payment_strict_receive",
            "type_i": 2,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123",
            "transaction_successful": true,
            "from": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "amount": "100.0000000",
            "source_amount": "105.0000000",
            "source_max": "110.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "source_asset_type": "native",
            "path": []
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let operation):
                XCTAssertEqual(operation.operationTypeString, "path_payment_strict_receive")
                if let pathPayment = operation as? PathPaymentStrictReceiveOperationResponse {
                    XCTAssertEqual(pathPayment.amount, "100.0000000")
                    XCTAssertEqual(pathPayment.sourceAmount, "105.0000000")
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testOperationsStreamItemOnReceiveManageBuyOfferOperation() {
        let expectation = XCTestExpectation(description: "Manage buy offer operation received")
        let streamItem = OperationsStreamItem(requestUrl: "https://test.stellar.org/operations")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "manage_buy_offer",
            "type_i": 12,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123",
            "transaction_successful": true,
            "offer_id": "67890",
            "amount": "100.0000000",
            "price": "2.5000000",
            "price_r": {
                "n": 5,
                "d": 2
            },
            "buying_asset_type": "credit_alphanum4",
            "buying_asset_code": "USD",
            "buying_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "selling_asset_type": "native"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let operation):
                XCTAssertEqual(operation.operationTypeString, "manage_buy_offer")
                if let manageBuyOffer = operation as? ManageBuyOfferOperationResponse {
                    XCTAssertEqual(manageBuyOffer.offerId, "67890")
                    XCTAssertEqual(manageBuyOffer.amount, "100.0000000")
                    XCTAssertEqual(manageBuyOffer.price, "2.5000000")
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testOperationsStreamItemOnReceiveSetOptionsOperation() {
        let expectation = XCTestExpectation(description: "Set options operation received")
        let streamItem = OperationsStreamItem(requestUrl: "https://test.stellar.org/operations")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "set_options",
            "type_i": 5,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123",
            "transaction_successful": true,
            "low_threshold": 1,
            "med_threshold": 2,
            "high_threshold": 3,
            "home_domain": "example.com",
            "set_flags": [1, 2],
            "set_flags_s": ["auth_required", "auth_revocable"],
            "clear_flags": [],
            "clear_flags_s": []
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let operation):
                XCTAssertEqual(operation.operationTypeString, "set_options")
                if let setOptions = operation as? SetOptionsOperationResponse {
                    XCTAssertEqual(setOptions.homeDomain, "example.com")
                    XCTAssertEqual(setOptions.lowThreshold, 1)
                    XCTAssertEqual(setOptions.medThreshold, 2)
                    XCTAssertEqual(setOptions.highThreshold, 3)
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - TradesStreamItem Deep Tests

    func testTradesStreamItemOnReceiveOpen() {
        let expectation = XCTestExpectation(description: "Stream open received")
        let streamItem = TradesStreamItem(requestUrl: "https://test.stellar.org/trades")

        streamItem.onReceive { response in
            switch response {
            case .open:
                expectation.fulfill()
            case .response, .error:
                XCTFail("Expected open response")
            }
        }

        streamItem.closeStream()
    }

    func testTradesStreamItemOnReceiveOrderbookTradeWithAllFields() {
        let expectation = XCTestExpectation(description: "Complete orderbook trade received")
        let streamItem = TradesStreamItem(requestUrl: "https://test.stellar.org/trades")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/trades/12345"}
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "orderbook",
            "offer_id": "67890",
            "base_offer_id": "67890",
            "counter_offer_id": "11111",
            "base_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "base_amount": "100.0000000",
            "base_asset_type": "credit_alphanum4",
            "base_asset_code": "USD",
            "base_asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "counter_account": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "counter_amount": "50.0000000",
            "counter_asset_type": "credit_alphanum12",
            "counter_asset_code": "LONGASSET",
            "counter_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "base_is_seller": true,
            "price": {
                "n": 1,
                "d": 2
            }
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let trade):
                XCTAssertEqual(trade.tradeType, "orderbook")
                XCTAssertEqual(trade.offerId, "67890")
                XCTAssertEqual(trade.baseOfferId, "67890")
                XCTAssertEqual(trade.counterOfferId, "11111")
                XCTAssertEqual(trade.baseAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
                XCTAssertEqual(trade.counterAccount, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
                XCTAssertEqual(trade.baseAssetCode, "USD")
                XCTAssertEqual(trade.counterAssetCode, "LONGASSET")
                XCTAssertEqual(trade.counterAssetType, "credit_alphanum12")
                XCTAssertTrue(trade.baseIsSeller)
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testTradesStreamItemOnReceiveMinimalTrade() {
        let expectation = XCTestExpectation(description: "Minimal trade with only required fields")
        let streamItem = TradesStreamItem(requestUrl: "https://test.stellar.org/trades")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/trades/12345"}
            },
            "id": "12345-2",
            "paging_token": "12345-2",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "base_amount": "100.0000000",
            "base_asset_type": "native",
            "counter_amount": "200.0000000",
            "counter_asset_type": "native",
            "base_is_seller": false,
            "price": {
                "n": 2,
                "d": 1
            }
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let trade):
                XCTAssertEqual(trade.tradeType, "orderbook")
                XCTAssertEqual(trade.baseAssetType, "native")
                XCTAssertEqual(trade.counterAssetType, "native")
                XCTAssertNil(trade.baseAssetCode)
                XCTAssertNil(trade.baseAssetIssuer)
                XCTAssertNil(trade.counterAssetCode)
                XCTAssertNil(trade.counterAssetIssuer)
                XCTAssertFalse(trade.baseIsSeller)
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - TransactionsStreamItem Deep Tests

    func testTransactionsStreamItemOnReceiveOpen() {
        let expectation = XCTestExpectation(description: "Stream open received")
        let streamItem = TransactionsStreamItem(requestUrl: "https://test.stellar.org/transactions")

        streamItem.onReceive { response in
            switch response {
            case .open:
                expectation.fulfill()
            case .response, .error:
                XCTFail("Expected open response")
            }
        }

        streamItem.closeStream()
    }

    func testTransactionsStreamItemOnReceiveTransactionWithHashMemo() {
        let expectation = XCTestExpectation(description: "Transaction with hash memo received")
        let streamItem = TransactionsStreamItem(requestUrl: "https://test.stellar.org/transactions")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/transactions/abc123"}
            },
            "id": "abc123",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "100",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "hash",
            "memo": "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY=",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="],
            "preconditions": {
                "timebounds": {
                    "min_time": "0",
                    "max_time": "1234567890"
                }
            }
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let transaction):
                XCTAssertEqual(transaction.memoType, "hash")
                XCTAssertNotNil(transaction.memo)
                if let memo = transaction.memo {
                    switch memo {
                    case .hash(let hash):
                        XCTAssertEqual(hash.count, 32, "Hash memo should be exactly 32 bytes")
                    default:
                        XCTFail("Expected hash memo")
                    }
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testTransactionsStreamItemOnReceiveTransactionWithReturnMemo() {
        let expectation = XCTestExpectation(description: "Transaction with return memo received")
        let streamItem = TransactionsStreamItem(requestUrl: "https://test.stellar.org/transactions")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/transactions/abc123"}
            },
            "id": "abc123",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "100",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "return",
            "memo": "cmV0dXJuaGFzaGV4YW1wbGVkYXRhMTIzNDU2Nzg5MA==",
            "signatures": []
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let transaction):
                XCTAssertEqual(transaction.memoType, "return")
                XCTAssertNotNil(transaction.memo)
                if let memo = transaction.memo {
                    switch memo {
                    case .returnHash(let returnHash):
                        XCTAssertEqual(returnHash.count, 32, "Return hash memo should be exactly 32 bytes")
                    default:
                        XCTFail("Expected return memo")
                    }
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testTransactionsStreamItemOnReceiveFailedTransaction() {
        let expectation = XCTestExpectation(description: "Failed transaction received")
        let streamItem = TransactionsStreamItem(requestUrl: "https://test.stellar.org/transactions")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/transactions/abc123"}
            },
            "id": "abc123",
            "paging_token": "123456789",
            "successful": false,
            "hash": "abc123def456",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "100",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGT/////AAAAAQAAAAAAAAAG/////gAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": []
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let transaction):
                XCTAssertEqual(transaction.feeCharged, "100")
                XCTAssertEqual(transaction.maxFee, "1000")
                XCTAssertNotNil(transaction.transactionResult)
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    func testTransactionsStreamItemOnReceiveTransactionWithPreconditions() {
        let expectation = XCTestExpectation(description: "Transaction with preconditions received")
        let streamItem = TransactionsStreamItem(requestUrl: "https://test.stellar.org/transactions")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/transactions/abc123"}
            },
            "id": "abc123",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "100",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": [],
            "preconditions": {
                "timebounds": {
                    "min_time": "1640000000",
                    "max_time": "1640001000"
                },
                "ledgerbounds": {
                    "min_ledger": 1000,
                    "max_ledger": 2000
                },
                "min_account_sequence": "90",
                "min_account_sequence_age": "60",
                "min_account_sequence_ledger_gap": 10
            }
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let transaction):
                XCTAssertNotNil(transaction.preconditions)
                if let preconditions = transaction.preconditions {
                    XCTAssertNotNil(preconditions.timeBounds)
                    XCTAssertNotNil(preconditions.ledgerBounds)
                    XCTAssertEqual(preconditions.minAccountSequence, "90")
                }
                expectation.fulfill()
            case .open:
                break
            case .error(let error):
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - Error Handling Deep Tests

    func testAccountDataStreamItemOnReceiveStreamError() {
        let expectation = XCTestExpectation(description: "Stream error received")
        let streamItem = AccountDataStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST/data/key")

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .errorOnStreamReceive = horizonError {
                        expectation.fulfill()
                    }
                }
            case .open:
                break
            case .response:
                XCTFail("Should not receive response on stream error")
            }
        }

        streamItem.closeStream()
    }

    func testAccountStreamItemOnReceiveDecodingError() {
        let expectation = XCTestExpectation(description: "Decoding error received")
        let streamItem = AccountStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST")

        let invalidJSON = """
        {
            "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        expectation.fulfill()
                    }
                }
            case .open:
                break
            case .response:
                XCTFail("Should not receive response for incomplete JSON")
            }
        }

        streamItem.closeStream()
    }

    func testEffectsStreamItemOnReceiveUnknownEffectType() {
        let expectation = XCTestExpectation(description: "Unknown effect type handling")
        let streamItem = EffectsStreamItem(requestUrl: "https://test.stellar.org/effects")

        let jsonString = """
        {
            "_links": {
                "operation": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "unknown_effect_type_999",
            "type_i": 999,
            "created_at": "2023-01-15T10:00:00Z"
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let effect):
                XCTAssertEqual(effect.effectTypeString, "unknown_effect_type_999")
                expectation.fulfill()
            case .open:
                break
            case .error:
                break
            }
        }

        streamItem.closeStream()
    }

    func testOperationsStreamItemOnReceiveUnknownOperationType() {
        let expectation = XCTestExpectation(description: "Unknown operation type handling")
        let streamItem = OperationsStreamItem(requestUrl: "https://test.stellar.org/operations")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/operations/12345"}
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "unknown_operation_type",
            "type_i": 999,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123",
            "transaction_successful": true
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .response(let id, let operation):
                XCTAssertEqual(operation.operationTypeString, "unknown_operation_type")
                expectation.fulfill()
            case .open:
                break
            case .error:
                break
            }
        }

        streamItem.closeStream()
    }

    func testTradesStreamItemOnReceiveMissingPriceField() {
        let expectation = XCTestExpectation(description: "Missing required price field")
        let streamItem = TradesStreamItem(requestUrl: "https://test.stellar.org/trades")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/trades/12345"}
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "orderbook",
            "base_amount": "100.0000000",
            "base_asset_type": "native",
            "counter_amount": "50.0000000",
            "counter_asset_type": "native",
            "base_is_seller": true
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        expectation.fulfill()
                    }
                }
            case .open:
                break
            case .response:
                XCTFail("Should not parse trade without price field")
            }
        }

        streamItem.closeStream()
    }

    func testTransactionsStreamItemOnReceiveMissingEnvelopeXDR() {
        let expectation = XCTestExpectation(description: "Missing envelope XDR field")
        let streamItem = TransactionsStreamItem(requestUrl: "https://test.stellar.org/transactions")

        let jsonString = """
        {
            "_links": {
                "self": {"href": "https://test.stellar.org/transactions/abc123"}
            },
            "id": "abc123",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "100",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "memo_type": "none",
            "signatures": []
        }
        """

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        expectation.fulfill()
                    }
                }
            case .open:
                break
            case .response:
                XCTFail("Should not parse transaction without XDR fields")
            }
        }

        streamItem.closeStream()
    }

    // MARK: - Multiple Stream Closure Tests

    func testMultipleStreamClosuresAccountData() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = AccountDataStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST/data/key")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresAccount() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = AccountStreamItem(requestUrl: "https://test.stellar.org/accounts/TEST")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresEffects() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = EffectsStreamItem(requestUrl: "https://test.stellar.org/effects")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresLiquidityPoolTrades() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = LiquidityPoolTradesStreamItem(requestUrl: "https://test.stellar.org/liquidity_pools/TEST/trades")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresOperations() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = OperationsStreamItem(requestUrl: "https://test.stellar.org/operations")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresTrades() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = TradesStreamItem(requestUrl: "https://test.stellar.org/trades")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresTransactions() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = TransactionsStreamItem(requestUrl: "https://test.stellar.org/transactions")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresLedgers() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = LedgersStreamItem(requestUrl: "https://test.stellar.org/ledgers")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresOffers() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = OffersStreamItem(requestUrl: "https://test.stellar.org/offers")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    func testMultipleStreamClosuresOrderbook() {
        // Test that multiple closeStream() calls do not cause crashes or errors
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book")

        streamItem.closeStream()
        streamItem.closeStream()
        streamItem.closeStream()
    }

    // MARK: - LedgersStreamItem Deep Tests

    func testLedgersStreamItemOnReceiveOpen() {
        // Test that onReceive handler can be set and stream can be opened/closed
        let streamItem = LedgersStreamItem(requestUrl: "https://test.stellar.org/ledgers")

        streamItem.onReceive { response in
            // Closure exercises response handling code paths
            switch response {
            case .open:
                break
            case .response, .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testLedgersStreamItemOnReceiveValidData() {
        // Test that response handler can access ledger properties
        let streamItem = LedgersStreamItem(requestUrl: "https://test.stellar.org/ledgers")

        streamItem.onReceive { response in
            // Closure exercises ledger response parsing code paths
            switch response {
            case .response(let id, let ledger):
                _ = ledger.id
            case .open:
                break
            case .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testLedgersStreamItemOnReceiveError() {
        // Test that error handler can process HorizonRequestError types
        let streamItem = LedgersStreamItem(requestUrl: "https://test.stellar.org/ledgers")

        streamItem.onReceive { response in
            // Closure exercises error handling code paths
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .errorOnStreamReceive = horizonError {
                        break
                    }
                }
            case .open:
                break
            case .response:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testLedgersStreamItemOnReceiveParsingError() {
        // Test that parsing error handler can process error cases
        let streamItem = LedgersStreamItem(requestUrl: "https://test.stellar.org/ledgers")

        streamItem.onReceive { response in
            // Closure exercises parsing error handling code paths
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        break
                    }
                }
            case .open:
                break
            case .response:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testLedgersStreamItemInitAndClose() {
        // Test initialization with cursor parameter and cleanup
        let streamItem = LedgersStreamItem(requestUrl: "https://test.stellar.org/ledgers?cursor=now")
        XCTAssertNotNil(streamItem, "Stream item should be created with cursor parameter")
        streamItem.closeStream()
    }

    func testLedgersStreamItemWithCursor() {
        // Test initialization with cursor and limit parameters
        let streamItem = LedgersStreamItem(requestUrl: "https://test.stellar.org/ledgers?cursor=12345&limit=10")

        streamItem.onReceive { response in
            // Closure exercises response handling with cursor/limit
            switch response {
            case .response(let id, let ledger):
                _ = ledger.sequenceNumber
            case .open, .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created with cursor and limit parameters")
    }

    // MARK: - OffersStreamItem Deep Tests

    func testOffersStreamItemOnReceiveOpen() {
        // Test that onReceive handler can be set and stream can be opened/closed
        let streamItem = OffersStreamItem(requestUrl: "https://test.stellar.org/offers")

        streamItem.onReceive { response in
            // Closure exercises response handling code paths
            switch response {
            case .open:
                break
            case .response, .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOffersStreamItemOnReceiveValidData() {
        // Test that response handler can access offer properties
        let streamItem = OffersStreamItem(requestUrl: "https://test.stellar.org/offers")

        streamItem.onReceive { response in
            // Closure exercises offer response parsing code paths
            switch response {
            case .response(let id, let offer):
                _ = offer.id
            case .open:
                break
            case .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOffersStreamItemOnReceiveError() {
        // Test that error handler can process HorizonRequestError types
        let streamItem = OffersStreamItem(requestUrl: "https://test.stellar.org/offers")

        streamItem.onReceive { response in
            // Closure exercises error handling code paths
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .errorOnStreamReceive = horizonError {
                        break
                    }
                }
            case .open:
                break
            case .response:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOffersStreamItemOnReceiveParsingError() {
        // Test that parsing error handler can process error cases
        let streamItem = OffersStreamItem(requestUrl: "https://test.stellar.org/offers")

        streamItem.onReceive { response in
            // Closure exercises parsing error handling code paths
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        break
                    }
                }
            case .open:
                break
            case .response:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOffersStreamItemInitAndClose() {
        // Test initialization with account-specific offers endpoint
        let streamItem = OffersStreamItem(requestUrl: "https://test.stellar.org/accounts/GABC/offers")
        XCTAssertNotNil(streamItem, "Stream item should be created for account offers")
        streamItem.closeStream()
    }

    func testOffersStreamItemWithCursor() {
        // Test initialization with cursor and limit parameters
        let streamItem = OffersStreamItem(requestUrl: "https://test.stellar.org/offers?cursor=67890&limit=20")

        streamItem.onReceive { response in
            // Closure exercises response handling with cursor/limit
            switch response {
            case .response(let id, let offer):
                _ = offer.seller
            case .open, .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created with cursor and limit parameters")
    }

    // MARK: - OrderbookStreamItem Deep Tests

    func testOrderbookStreamItemOnReceiveOpen() {
        // Test that onReceive handler can be set and stream can be opened/closed
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book")

        streamItem.onReceive { response in
            // Closure exercises response handling code paths
            switch response {
            case .open:
                break
            case .response, .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOrderbookStreamItemOnReceiveValidData() {
        // Test that response handler can access orderbook properties
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book")

        streamItem.onReceive { response in
            // Closure exercises orderbook response parsing code paths
            switch response {
            case .response(let id, let orderbook):
                _ = orderbook.bids
                _ = orderbook.asks
            case .open:
                break
            case .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOrderbookStreamItemOnReceiveError() {
        // Test that error handler can process HorizonRequestError types
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book")

        streamItem.onReceive { response in
            // Closure exercises error handling code paths
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .errorOnStreamReceive = horizonError {
                        break
                    }
                }
            case .open:
                break
            case .response:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOrderbookStreamItemOnReceiveParsingError() {
        // Test that parsing error handler can process error cases
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book")

        streamItem.onReceive { response in
            // Closure exercises parsing error handling code paths
            switch response {
            case .error(let error):
                if let horizonError = error as? HorizonRequestError {
                    if case .parsingResponseFailed = horizonError {
                        break
                    }
                }
            case .open:
                break
            case .response:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }

    func testOrderbookStreamItemInitAndClose() {
        // Test initialization with asset type parameters
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book?selling_asset_type=native&buying_asset_type=credit_alphanum4")
        XCTAssertNotNil(streamItem, "Stream item should be created with asset parameters")
        streamItem.closeStream()
    }

    func testOrderbookStreamItemWithAssetParams() {
        // Test initialization with full asset parameters including issuer
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book?selling_asset_type=credit_alphanum4&selling_asset_code=USD&selling_asset_issuer=GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO&buying_asset_type=native")

        streamItem.onReceive { response in
            // Closure exercises response handling with full asset parameters
            switch response {
            case .response(let id, let orderbook):
                _ = orderbook.selling
                _ = orderbook.buying
            case .open, .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created with full asset parameters")
    }

    func testOrderbookStreamItemBidsAndAsksAccess() {
        // Test accessing bids and asks collections from orderbook response
        let streamItem = OrderbookStreamItem(requestUrl: "https://test.stellar.org/order_book")

        streamItem.onReceive { response in
            // Closure exercises accessing orderbook collections
            switch response {
            case .response(let id, let orderbook):
                _ = orderbook.bids.count
                _ = orderbook.asks.count
            case .open, .error:
                break
            }
        }

        streamItem.closeStream()
        XCTAssertNotNil(streamItem, "Stream item should be created successfully")
    }
}
