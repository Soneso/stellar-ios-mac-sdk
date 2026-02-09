//
//  StreamingItemsUnitTests.swift
//  stellarsdk
//
//  Created by Soneso
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class StreamingParsingUnitTests: XCTestCase {

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        return decoder
    }

    // MARK: - AccountDataStreamItem Tests

    func testAccountDataStreamItemInitialization() {
        let streamItem = AccountDataStreamItem(requestUrl: "https://horizon-testnet.stellar.org/accounts/GABC/data/key")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testAccountDataStreamItemParseValidResponse() throws {
        let jsonData = """
        {
            "value": "dGVzdF92YWx1ZQ==",
            "sponsor": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(DataForAccountResponse.self, from: jsonData)
        XCTAssertEqual(response.value, "dGVzdF92YWx1ZQ==")
        XCTAssertEqual(response.sponsor, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
    }

    func testAccountDataStreamItemParseWithoutSponsor() throws {
        let jsonData = """
        {
            "value": "YW5vdGhlcl92YWx1ZQ=="
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(DataForAccountResponse.self, from: jsonData)
        XCTAssertEqual(response.value, "YW5vdGhlcl92YWx1ZQ==")
        XCTAssertNil(response.sponsor)
    }

    func testAccountDataStreamItemCloseStream() {
        let streamItem = AccountDataStreamItem(requestUrl: "https://horizon-testnet.stellar.org/accounts/GABC/data/key")
        streamItem.closeStream()
        streamItem.closeStream() // Test passes if no exception thrown on multiple closeStream() calls
    }

    // MARK: - AccountStreamItem Tests

    func testAccountStreamItemInitialization() {
        let streamItem = AccountStreamItem(requestUrl: "https://horizon-testnet.stellar.org/accounts/GABC")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testAccountStreamItemParseValidResponse() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "transactions": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/transactions{?cursor,limit,order}",
                    "templated": true
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/operations{?cursor,limit,order}",
                    "templated": true
                },
                "payments": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/payments{?cursor,limit,order}",
                    "templated": true
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/effects{?cursor,limit,order}",
                    "templated": true
                },
                "offers": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/offers{?cursor,limit,order}",
                    "templated": true
                },
                "trades": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/trades{?cursor,limit,order}",
                    "templated": true
                },
                "data": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/data/{key}",
                    "templated": true
                }
            },
            "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "sequence": "123456789",
            "subentry_count": 5,
            "last_modified_ledger": 12345,
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
            "balances": [
                {
                    "balance": "10000.0000000",
                    "limit": "922337203685.4775807",
                    "buying_liabilities": "0.0000000",
                    "selling_liabilities": "0.0000000",
                    "last_modified_ledger": 12345,
                    "is_authorized": true,
                    "is_authorized_to_maintain_liabilities": true,
                    "asset_type": "credit_alphanum4",
                    "asset_code": "USD",
                    "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
                },
                {
                    "balance": "100000.0000000",
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
            "data": {},
            "num_sponsoring": 0,
            "num_sponsored": 0,
            "paging_token": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(AccountResponse.self, from: jsonData)
        XCTAssertEqual(response.accountId, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.sequenceNumber, 123456789)
        XCTAssertEqual(response.subentryCount, 5)
        XCTAssertEqual(response.balances.count, 2)
        XCTAssertEqual(response.signers.count, 1)
    }

    func testAccountStreamItemCloseStream() {
        let streamItem = AccountStreamItem(requestUrl: "https://horizon-testnet.stellar.org/accounts/GABC")
        streamItem.closeStream()
        streamItem.closeStream() // Test passes if no exception thrown on multiple closeStream() calls
    }

    // MARK: - EffectsStreamItem Tests

    func testEffectsStreamItemInitialization() {
        let streamItem = EffectsStreamItem(requestUrl: "https://horizon-testnet.stellar.org/effects")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testEffectsStreamItemParseAccountCreatedEffect() throws {
        let jsonData = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=12345&order=asc"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=12345&order=desc"
                }
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let effect = try decoder.decode(AccountCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.id, "12345-1")
        XCTAssertEqual(effect.account, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(effect.effectTypeString, "account_created")
        XCTAssertEqual(effect.startingBalance, "10000.0000000")
    }

    func testEffectsStreamItemParseAccountCreditedEffect() throws {
        let jsonData = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=12345&order=asc"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/effects?cursor=12345&order=desc"
                }
            },
            "id": "12345-2",
            "paging_token": "12345-2",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_credited",
            "type_i": 2,
            "created_at": "2023-01-15T10:00:00Z",
            "amount": "100.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let effect = try decoder.decode(AccountCreditedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.id, "12345-2")
        XCTAssertEqual(effect.effectTypeString, "account_credited")
        XCTAssertEqual(effect.amount, "100.0000000")
        XCTAssertEqual(effect.assetCode, "USD")
    }

    func testEffectsStreamItemCloseStream() {
        let streamItem = EffectsStreamItem(requestUrl: "https://horizon-testnet.stellar.org/effects")
        streamItem.closeStream()
        streamItem.closeStream() // Test passes if no exception thrown on multiple closeStream() calls
    }

    // MARK: - LiquidityPoolTradesStreamItem Tests

    func testLiquidityPoolTradesStreamItemInitialization() {
        let streamItem = LiquidityPoolTradesStreamItem(requestUrl: "https://horizon-testnet.stellar.org/liquidity_pools/LABC/trades")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testLiquidityPoolTradesStreamItemParseValidResponse() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                },
                "base": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "counter": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
                },
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                }
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
            "counter_asset_type": "credit_alphanum4",
            "counter_asset_code": "EUR",
            "counter_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "base_is_seller": true,
            "price": {
                "n": 1,
                "d": 2
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TradeResponse.self, from: jsonData)
        XCTAssertEqual(response.id, "12345-1")
        XCTAssertEqual(response.tradeType, "liquidity_pool")
        XCTAssertEqual(response.baseLiquidityPoolId, "abcdef1234567890")
        XCTAssertEqual(response.liquidityPoolFeeBp, 30)
        XCTAssertEqual(response.baseAmount, "100.0000000")
        XCTAssertEqual(response.counterAmount, "50.0000000")
        XCTAssertTrue(response.baseIsSeller)
        XCTAssertEqual(response.price.n, "1")
        XCTAssertEqual(response.price.d, "2")
    }

    func testLiquidityPoolTradesStreamItemCloseStream() {
        let streamItem = LiquidityPoolTradesStreamItem(requestUrl: "https://horizon-testnet.stellar.org/liquidity_pools/LABC/trades")
        streamItem.closeStream()
        streamItem.closeStream() // Test passes if no exception thrown on multiple closeStream() calls
    }

    // MARK: - OperationsStreamItem Tests

    func testOperationsStreamItemInitialization() {
        let streamItem = OperationsStreamItem(requestUrl: "https://horizon-testnet.stellar.org/operations")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testOperationsStreamItemParsePaymentOperation() throws {
        let jsonData = """
        {
            "_links": {
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345/effects{?cursor,limit,order}",
                    "templated": true
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/operations?cursor=12345&order=asc"
                },
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/operations?cursor=12345&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123"
                }
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
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let payment = try decoder.decode(PaymentOperationResponse.self, from: jsonData)

        XCTAssertEqual(payment.id, "12345")
        XCTAssertEqual(payment.operationTypeString, "payment")
        XCTAssertEqual(payment.from, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(payment.to, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(payment.amount, "100.0000000")
        XCTAssertEqual(payment.assetCode, "USD")
    }

    func testOperationsStreamItemParseCreateAccountOperation() throws {
        let jsonData = """
        {
            "_links": {
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345/effects{?cursor,limit,order}",
                    "templated": true
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/operations?cursor=12345&order=asc"
                },
                "self": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/operations?cursor=12345&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123"
                }
            },
            "id": "12345",
            "paging_token": "12345",
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let createAccount = try decoder.decode(AccountCreatedOperationResponse.self, from: jsonData)

        XCTAssertEqual(createAccount.id, "12345")
        XCTAssertEqual(createAccount.operationTypeString, "create_account")
        XCTAssertEqual(createAccount.account, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(createAccount.startingBalance, Decimal(string: "10000.0000000"))
    }

    func testOperationsStreamItemCloseStream() {
        let streamItem = OperationsStreamItem(requestUrl: "https://horizon-testnet.stellar.org/operations")
        streamItem.closeStream()
        streamItem.closeStream() // Test passes if no exception thrown on multiple closeStream() calls
    }

    // MARK: - TradesStreamItem Tests

    func testTradesStreamItemInitialization() {
        let streamItem = TradesStreamItem(requestUrl: "https://horizon-testnet.stellar.org/trades")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testTradesStreamItemParseOrderbookTrade() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                },
                "base": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "counter": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
                },
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                }
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
            "counter_asset_type": "credit_alphanum4",
            "counter_asset_code": "EUR",
            "counter_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "base_is_seller": true,
            "price": {
                "n": 1,
                "d": 2
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TradeResponse.self, from: jsonData)
        XCTAssertEqual(response.id, "12345-1")
        XCTAssertEqual(response.tradeType, "orderbook")
        XCTAssertEqual(response.offerId, "67890")
        XCTAssertEqual(response.baseOfferId, "67890")
        XCTAssertEqual(response.counterOfferId, "11111")
        XCTAssertEqual(response.baseAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.counterAccount, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertTrue(response.baseIsSeller)
    }

    func testTradesStreamItemParseNativeAssetTrade() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                },
                "base": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "counter": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
                },
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                }
            },
            "id": "12345-2",
            "paging_token": "12345-2",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "orderbook",
            "offer_id": "99999",
            "base_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "base_amount": "500.0000000",
            "base_asset_type": "native",
            "counter_account": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "counter_amount": "100.0000000",
            "counter_asset_type": "credit_alphanum4",
            "counter_asset_code": "USD",
            "counter_asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "base_is_seller": false,
            "price": {
                "n": 5,
                "d": 1
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TradeResponse.self, from: jsonData)
        XCTAssertEqual(response.baseAssetType, "native")
        XCTAssertNil(response.baseAssetCode)
        XCTAssertNil(response.baseAssetIssuer)
        XCTAssertEqual(response.counterAssetCode, "USD")
        XCTAssertFalse(response.baseIsSeller)
    }

    func testTradesStreamItemCloseStream() {
        let streamItem = TradesStreamItem(requestUrl: "https://horizon-testnet.stellar.org/trades")
        streamItem.closeStream()
        streamItem.closeStream() // Test passes if no exception thrown on multiple closeStream() calls
    }

    // MARK: - TransactionsStreamItem Tests

    func testTransactionsStreamItemInitialization() {
        let streamItem = TransactionsStreamItem(requestUrl: "https://horizon-testnet.stellar.org/transactions")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testTransactionsStreamItemParseValidResponse() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                },
                "account": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "ledger": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345"
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/operations{?cursor,limit,order}",
                    "templated": true
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/effects{?cursor,limit,order}",
                    "templated": true
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=asc"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                }
            },
            "id": "abc123def456",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456789",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "123456789",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAbAAAAAAAAAAAAAAABAAAAAAAAAAMAAAABRVVSAAAAAABWsKIm44ZManGkwOIyDdbzRjPLfb6ZrVXWOGIi9S2tRwAAAAJDVTEyMzQ1AAAAAAAAAAAAwjUbmH7LrvIY/NDZcKS9j6Dl/dg6KCJgC1GiKwWkdaMAAAAAL68IAAAAAAEAAAPoAAAAAAAAAAAAAAAAAAAAAdNn6woAAABAioDroKPUAZn2Pp4OTksPKmitQTZpsFSAN259vcI0E3YtCbOWUQkpOJV68myqgL62CPzK3YIsg+Kok4lQ6ys5Ag==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAADAAAAAAAAAAEAAAAAURqP8nUKuuavLDttwWMCdPjCAiTp+vu5leob71ZdvIAAAAAAAAGcvwAAAAJDVTEyMzQ1AAAAAAAAAAAAwjUbmH7LrvIY/NDZcKS9j6Dl/dg6KCJgC1GiKwWkdaMAAAAAAAw1AAAAAAFFVVIAAAAAAFawoibjhkxqcaTA4jIN1vNGM8t9vpmtVdY4YiL1La1HAAAAAC+vCAAAAAACAAAAAA==",
            "result_meta_xdr": "AAAAAAAAAAEAAAAMAAAAAwByhRcAAAAAAAAAAFEaj/J1Crrmryw7bcFjAnT4wgIk6fr7uZXqG+9WXbyAAAAAF0h24PgAcm6LAAAAEgAAAAsAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAIAAAAAAAAAAAAAAAEAcoUeAAAAAAAAAABRGo/ydQq65q8sO23BYwJ0+MICJOn6+7mV6hvvVl28gAAAABdIduD4AHJuiwAAABIAAAAKAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAwjUbmH7LrvIY/NDZcKS9j6Dl/dg6KCJgC1GiKwWkdaMAAAACAAAAAAAAAAAAAAADAHKBWgAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAABRVVSAAAAAABWsKIm44ZManGkwOIyDdbzRjPLfb6ZrVXWOGIi9S2tRwAAAAGhO4YAf/////////8AAAABAAAAAAAAAAAAAAABAHKFHgAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAABRVVSAAAAAABWsKIm44ZManGkwOIyDdbzRjPLfb6ZrVXWOGIi9S2tRwAAAAFxjH4Af/////////8AAAABAAAAAAAAAAAAAAADAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAAAAAAEAcoUeAAAAAQAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAAAJDVTEyMzQ1AAAAAAAAAAAAwjUbmH7LrvIY/NDZcKS9j6Dl/dg6KCJgC1GiKwWkdaMAAAAAABhqAAFjRXhdigAAAAAAAQAAAAAAAAAAAAAAAwBygVoAAAABAAAAAFEaj/J1Crrmryw7bcFjAnT4wgIk6fr7uZXqG+9WXbyAAAAAAUVVUgAAAAAAVrCiJuOGTGpxpMDiMg3W80Yzy32+ma1V1jhiIvUtrUcAAAAAvrwgAAFjRXhdigAAAAAAAQAAAAAAAAAAAAAAAQByhR4AAAABAAAAAFEaj/J1Crrmryw7bcFjAnT4wgIk6fr7uZXqG+9WXbyAAAAAAUVVUgAAAAAAVrCiJuOGTGpxpMDiMg3W80Yzy32+ma1V1jhiIvUtrUcAAAAA7msoAAFjRXhdigAAAAAAAQAAAAAAAAAAAAAAAwByfvQAAAABAAAAAFEaj/J1Crrmryw7bcFjAnT4wgIk6fr7uZXqG+9WXbyAAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAAjGGAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHgAAAAEAAAAAURqP8nUKuuavLDttwWMCdPjCAiTp+vu5leob71ZdvIAAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAACALIABY0V4XYoAAAAAAAEAAAAAAAAAAAAAAAMAcoUXAAAAAgAAAABRGo/ydQq65q8sO23BYwJ0+MICJOn6+7mV6hvvVl28gAAAAAAAAZy/AAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAFFVVIAAAAAAFawoibjhkxqcaTA4jIN1vNGM8t9vpmtVdY4YiL1La1HAAAAAAAMNQAAAAPoAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAACAAAAAFEaj/J1Crrmryw7bcFjAnT4wgIk6fr7uZXqG+9WXbyAAAAAAAABnL8=",
            "fee_meta_xdr": "AAAAAgAAAAMAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUeAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdtysAG+MfAAAABsAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": [
                "ioDroKPUAZn2Pp4OTksPKmitQTZpsFSAN259vcI0E3YtCbOWUQkpOJV68myqgL62CPzK3YIsg+Kok4lQ6ys5Ag=="
            ]
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TransactionResponse.self, from: jsonData)
        XCTAssertEqual(response.id, "abc123def456")
        XCTAssertEqual(response.transactionHash, "abc123def456789")
        XCTAssertEqual(response.ledger, 12345)
        XCTAssertEqual(response.sourceAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.sourceAccountSequence, "123456789")
        XCTAssertEqual(response.feeCharged, "100")
        XCTAssertEqual(response.maxFee, "1000")
        XCTAssertEqual(response.operationCount, 1)
        XCTAssertEqual(response.memoType, "none")
        XCTAssertEqual(response.signatures.count, 1)
    }

    func testTransactionsStreamItemParseWithTextMemo() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                },
                "account": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "ledger": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345"
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/operations{?cursor,limit,order}",
                    "templated": true
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/effects{?cursor,limit,order}",
                    "templated": true
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=asc"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                }
            },
            "id": "abc123def456",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456789",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "123456789",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "text",
            "memo": "Test payment",
            "signatures": [
                "9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="
            ]
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TransactionResponse.self, from: jsonData)
        XCTAssertEqual(response.memoType, "text")
        XCTAssertNotNil(response.memo)
        if let memo = response.memo {
            switch memo {
            case .text(let text):
                XCTAssertEqual(text, "Test payment")
            default:
                XCTFail("Expected text memo")
            }
        }
    }

    func testTransactionsStreamItemCloseStream() {
        let streamItem = TransactionsStreamItem(requestUrl: "https://horizon-testnet.stellar.org/transactions")
        streamItem.closeStream()
        streamItem.closeStream() // Test passes if no exception thrown on multiple closeStream() calls
    }

    // MARK: - Error Handling Tests

    func testAccountDataStreamItemParseInvalidJSON() {
        let invalidJSON = "{ invalid json }"
        let jsonData = invalidJSON.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(DataForAccountResponse.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testAccountStreamItemParseMissingRequiredFields() {
        let incompleteJSON = """
        {
            "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(AccountResponse.self, from: incompleteJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTradeStreamItemParseMissingPrice() {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                }
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
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTransactionStreamItemParseInvalidXDR() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                },
                "account": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "ledger": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345"
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/operations{?cursor,limit,order}",
                    "templated": true
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/effects{?cursor,limit,order}",
                    "templated": true
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=asc"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                }
            },
            "id": "abc123def456",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456789",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "123456789",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "invalid_xdr_data",
            "result_xdr": "invalid_xdr_data",
            "result_meta_xdr": "invalid_xdr_data",
            "fee_meta_xdr": "invalid_xdr_data",
            "memo_type": "none",
            "signatures": []
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TransactionResponse.self, from: jsonData)) { error in
            // XDR decoding should fail
            XCTAssertTrue(error is DecodingError || error is HorizonRequestError)
        }
    }

    // MARK: - Edge Cases

    func testAccountDataStreamItemEmptyValue() throws {
        let jsonData = """
        {
            "value": ""
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(DataForAccountResponse.self, from: jsonData)
        XCTAssertEqual(response.value, "")
        XCTAssertNil(response.sponsor)
    }

    func testTradeStreamItemDefaultTradeType() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                },
                "base": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "counter": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
                },
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                }
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "base_amount": "100.0000000",
            "base_asset_type": "native",
            "counter_amount": "50.0000000",
            "counter_asset_type": "native",
            "base_is_seller": true,
            "price": {
                "n": 1,
                "d": 2
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TradeResponse.self, from: jsonData)
        XCTAssertEqual(response.tradeType, "orderbook") // Default value
    }

    func testTransactionStreamItemMultipleSignatures() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                },
                "account": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "ledger": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345"
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/operations{?cursor,limit,order}",
                    "templated": true
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456/effects{?cursor,limit,order}",
                    "templated": true
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=asc"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123def456"
                }
            },
            "id": "abc123def456",
            "paging_token": "123456789",
            "successful": true,
            "hash": "abc123def456789",
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "source_account_sequence": "123456789",
            "fee_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": [
                "9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
                "5gN99x3wKec2pxCsl5scZYGGPYC6+SGUNBSEktpo5h+rpzZZ9CPYKhVz/+qYRbZKc7E3YoaY3IkxRXKq4ZffDx==",
                "7hP11y4xLfd3qyCtu6tdaZHHQZD7+THVOCTFlurq6i+sqzaZ0DQaLiWz/+raScaLd8F4ZpbZ4JlyRYLr5aggEy=="
            ]
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TransactionResponse.self, from: jsonData)
        XCTAssertEqual(response.signatures.count, 3)
    }

    // MARK: - LedgersStreamItem Tests

    func testLedgersStreamItemInitialization() {
        let streamItem = LedgersStreamItem(requestUrl: "https://horizon-testnet.stellar.org/ledgers")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testLedgersStreamItemParseValidResponse() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345"
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345/effects{?cursor,limit,order}",
                    "templated": true
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345/operations{?cursor,limit,order}",
                    "templated": true
                },
                "payments": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345/payments{?cursor,limit,order}",
                    "templated": true
                },
                "transactions": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345/transactions{?cursor,limit,order}",
                    "templated": true
                }
            },
            "id": "abcdef123456789",
            "paging_token": "12345",
            "hash": "abc123def456789",
            "prev_hash": "xyz789abc123456",
            "sequence": 12345,
            "successful_transaction_count": 10,
            "failed_transaction_count": 2,
            "operation_count": 25,
            "tx_set_operation_count": 27,
            "closed_at": "2023-01-15T10:00:00Z",
            "total_coins": "100000000000.0000000",
            "fee_pool": "12345.6789012",
            "base_fee_in_stroops": 100,
            "base_reserve_in_stroops": 5000000,
            "max_tx_set_size": 500,
            "protocol_version": 21,
            "header_xdr": "AAAAAA=="
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(LedgerResponse.self, from: jsonData)
        XCTAssertEqual(response.id, "abcdef123456789")
        XCTAssertEqual(response.pagingToken, "12345")
        XCTAssertEqual(response.hashXdr, "abc123def456789")
        XCTAssertEqual(response.previousHashXdr, "xyz789abc123456")
        XCTAssertEqual(response.sequenceNumber, 12345)
        XCTAssertEqual(response.successfulTransactionCount, 10)
        XCTAssertEqual(response.failedTransactionCount, 2)
        XCTAssertEqual(response.operationCount, 25)
        XCTAssertEqual(response.txSetOperationCount, 27)
        XCTAssertEqual(response.totalCoins, "100000000000.0000000")
        XCTAssertEqual(response.feePool, "12345.6789012")
        XCTAssertEqual(response.baseFeeInStroops, 100)
        XCTAssertEqual(response.baseReserveInStroops, 5000000)
        XCTAssertEqual(response.maxTxSetSize, 500)
        XCTAssertEqual(response.protocolVersion, 21)
        XCTAssertEqual(response.headerXdr, "AAAAAA==")
    }

    func testLedgersStreamItemParseLinks() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/99999"
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/99999/effects{?cursor,limit,order}",
                    "templated": true
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/99999/operations{?cursor,limit,order}",
                    "templated": true
                },
                "payments": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/99999/payments{?cursor,limit,order}",
                    "templated": true
                },
                "transactions": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/99999/transactions{?cursor,limit,order}",
                    "templated": true
                }
            },
            "id": "ledger99999",
            "paging_token": "99999",
            "hash": "hash99999",
            "prev_hash": "hash99998",
            "sequence": 99999,
            "successful_transaction_count": 50,
            "failed_transaction_count": 5,
            "operation_count": 120,
            "tx_set_operation_count": 125,
            "closed_at": "2023-06-20T15:30:00Z",
            "total_coins": "105000000000.0000000",
            "fee_pool": "98765.4321098",
            "base_fee_in_stroops": 100,
            "base_reserve_in_stroops": 5000000,
            "max_tx_set_size": 1000,
            "protocol_version": 21,
            "header_xdr": "AQAAAA=="
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(LedgerResponse.self, from: jsonData)
        XCTAssertEqual(response.links.selflink.href, "https://horizon-testnet.stellar.org/ledgers/99999")
        XCTAssertEqual(response.links.effects.templated, true)
        XCTAssertEqual(response.links.operations.templated, true)
        XCTAssertEqual(response.links.payments.templated, true)
        XCTAssertEqual(response.links.transactions.templated, true)
    }

    func testLedgersStreamItemCloseStream() {
        let streamItem = LedgersStreamItem(requestUrl: "https://horizon-testnet.stellar.org/ledgers")
        streamItem.closeStream()
        streamItem.closeStream() // Should not crash on multiple calls
    }

    // MARK: - OffersStreamItem Tests

    func testOffersStreamItemInitialization() {
        let streamItem = OffersStreamItem(requestUrl: "https://horizon-testnet.stellar.org/offers")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testOffersStreamItemParseValidResponse() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers/12345"
                },
                "offer_maker": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                }
            },
            "id": "12345",
            "paging_token": "12345",
            "seller": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "selling": {
                "asset_type": "credit_alphanum4",
                "asset_code": "USD",
                "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
            },
            "buying": {
                "asset_type": "native"
            },
            "amount": "1000.0000000",
            "price_r": {
                "n": 1,
                "d": 10
            },
            "price": "0.1000000",
            "last_modified_ledger": 54321
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(OfferResponse.self, from: jsonData)
        XCTAssertEqual(response.id, "12345")
        XCTAssertEqual(response.pagingToken, "12345")
        XCTAssertEqual(response.seller, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.selling.assetType, "credit_alphanum4")
        XCTAssertEqual(response.selling.assetCode, "USD")
        XCTAssertEqual(response.selling.assetIssuer, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.buying.assetType, "native")
        XCTAssertNil(response.buying.assetCode)
        XCTAssertNil(response.buying.assetIssuer)
        XCTAssertEqual(response.amount, "1000.0000000")
        XCTAssertEqual(response.priceR.numerator, 1)
        XCTAssertEqual(response.priceR.denominator, 10)
        XCTAssertEqual(response.price, "0.1000000")
        XCTAssertEqual(response.lastModifiedLedger, 54321)
        XCTAssertNil(response.sponsor)
    }

    func testOffersStreamItemParseWithSponsor() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers/67890"
                },
                "offer_maker": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                }
            },
            "id": "67890",
            "paging_token": "67890",
            "seller": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "selling": {
                "asset_type": "credit_alphanum12",
                "asset_code": "TESTASSET123",
                "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
            },
            "buying": {
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
            },
            "amount": "500.0000000",
            "price_r": {
                "n": 5,
                "d": 2
            },
            "price": "2.5000000",
            "sponsor": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "last_modified_ledger": 98765,
            "last_modified_time": "2023-05-15T12:30:00Z"
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(OfferResponse.self, from: jsonData)
        XCTAssertEqual(response.id, "67890")
        XCTAssertEqual(response.selling.assetType, "credit_alphanum12")
        XCTAssertEqual(response.selling.assetCode, "TESTASSET123")
        XCTAssertEqual(response.buying.assetType, "credit_alphanum4")
        XCTAssertEqual(response.buying.assetCode, "EUR")
        XCTAssertEqual(response.sponsor, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.lastModifiedTime, "2023-05-15T12:30:00Z")
    }

    func testOffersStreamItemParseNativeToNative() throws {
        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/offers/11111"
                },
                "offer_maker": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                }
            },
            "id": "11111",
            "paging_token": "11111",
            "seller": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "selling": {
                "asset_type": "native"
            },
            "buying": {
                "asset_type": "credit_alphanum4",
                "asset_code": "BTC",
                "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
            },
            "amount": "10000.0000000",
            "price_r": {
                "n": 1,
                "d": 50000
            },
            "price": "0.0000200",
            "last_modified_ledger": 12000
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(OfferResponse.self, from: jsonData)
        XCTAssertEqual(response.selling.assetType, "native")
        XCTAssertNil(response.selling.assetCode)
        XCTAssertNil(response.selling.assetIssuer)
        XCTAssertEqual(response.buying.assetCode, "BTC")
        XCTAssertEqual(response.priceR.numerator, 1)
        XCTAssertEqual(response.priceR.denominator, 50000)
    }

    func testOffersStreamItemCloseStream() {
        let streamItem = OffersStreamItem(requestUrl: "https://horizon-testnet.stellar.org/offers")
        streamItem.closeStream()
        streamItem.closeStream() // Should not crash on multiple calls
    }

    // MARK: - OrderbookStreamItem Tests

    func testOrderbookStreamItemInitialization() {
        let streamItem = OrderbookStreamItem(requestUrl: "https://horizon-testnet.stellar.org/order_book")
        XCTAssertNotNil(streamItem)
        streamItem.closeStream()
    }

    func testOrderbookStreamItemParseValidResponse() throws {
        let jsonData = """
        {
            "bids": [
                {
                    "price_r": {
                        "n": 10,
                        "d": 1
                    },
                    "price": "10.0000000",
                    "amount": "100.0000000"
                },
                {
                    "price_r": {
                        "n": 95,
                        "d": 10
                    },
                    "price": "9.5000000",
                    "amount": "50.0000000"
                }
            ],
            "asks": [
                {
                    "price_r": {
                        "n": 11,
                        "d": 1
                    },
                    "price": "11.0000000",
                    "amount": "200.0000000"
                }
            ],
            "base": {
                "asset_type": "credit_alphanum4",
                "asset_code": "USD",
                "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
            },
            "counter": {
                "asset_type": "native"
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(OrderbookResponse.self, from: jsonData)
        XCTAssertEqual(response.bids.count, 2)
        XCTAssertEqual(response.asks.count, 1)
        XCTAssertEqual(response.selling.assetType, "credit_alphanum4")
        XCTAssertEqual(response.selling.assetCode, "USD")
        XCTAssertEqual(response.selling.assetIssuer, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.buying.assetType, "native")
        XCTAssertNil(response.buying.assetCode)

        // Verify bid details
        XCTAssertEqual(response.bids[0].priceR.numerator, 10)
        XCTAssertEqual(response.bids[0].priceR.denominator, 1)
        XCTAssertEqual(response.bids[0].price, "10.0000000")
        XCTAssertEqual(response.bids[0].amount, "100.0000000")
        XCTAssertEqual(response.bids[1].price, "9.5000000")
        XCTAssertEqual(response.bids[1].amount, "50.0000000")

        // Verify ask details
        XCTAssertEqual(response.asks[0].priceR.numerator, 11)
        XCTAssertEqual(response.asks[0].priceR.denominator, 1)
        XCTAssertEqual(response.asks[0].price, "11.0000000")
        XCTAssertEqual(response.asks[0].amount, "200.0000000")
    }

    func testOrderbookStreamItemParseEmptyOrderbook() throws {
        let jsonData = """
        {
            "bids": [],
            "asks": [],
            "base": {
                "asset_type": "credit_alphanum4",
                "asset_code": "XYZ",
                "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
            },
            "counter": {
                "asset_type": "credit_alphanum12",
                "asset_code": "TESTASSET123",
                "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(OrderbookResponse.self, from: jsonData)
        XCTAssertEqual(response.bids.count, 0)
        XCTAssertEqual(response.asks.count, 0)
        XCTAssertEqual(response.selling.assetCode, "XYZ")
        XCTAssertEqual(response.buying.assetType, "credit_alphanum12")
        XCTAssertEqual(response.buying.assetCode, "TESTASSET123")
    }

    func testOrderbookStreamItemParseDeepOrderbook() throws {
        let jsonData = """
        {
            "bids": [
                {"price_r": {"n": 100, "d": 10}, "price": "10.0000000", "amount": "1000.0000000"},
                {"price_r": {"n": 99, "d": 10}, "price": "9.9000000", "amount": "500.0000000"},
                {"price_r": {"n": 98, "d": 10}, "price": "9.8000000", "amount": "750.0000000"},
                {"price_r": {"n": 97, "d": 10}, "price": "9.7000000", "amount": "250.0000000"},
                {"price_r": {"n": 96, "d": 10}, "price": "9.6000000", "amount": "100.0000000"}
            ],
            "asks": [
                {"price_r": {"n": 101, "d": 10}, "price": "10.1000000", "amount": "800.0000000"},
                {"price_r": {"n": 102, "d": 10}, "price": "10.2000000", "amount": "600.0000000"},
                {"price_r": {"n": 103, "d": 10}, "price": "10.3000000", "amount": "400.0000000"}
            ],
            "base": {
                "asset_type": "native"
            },
            "counter": {
                "asset_type": "credit_alphanum4",
                "asset_code": "EUR",
                "asset_issuer": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(OrderbookResponse.self, from: jsonData)
        XCTAssertEqual(response.bids.count, 5)
        XCTAssertEqual(response.asks.count, 3)
        XCTAssertEqual(response.selling.assetType, "native")
        XCTAssertEqual(response.buying.assetCode, "EUR")

        // Verify first and last bids
        XCTAssertEqual(response.bids[0].amount, "1000.0000000")
        XCTAssertEqual(response.bids[4].price, "9.6000000")

        // Verify asks ordering
        XCTAssertEqual(response.asks[0].price, "10.1000000")
        XCTAssertEqual(response.asks[2].amount, "400.0000000")
    }

    func testOrderbookStreamItemCloseStream() {
        let streamItem = OrderbookStreamItem(requestUrl: "https://horizon-testnet.stellar.org/order_book")
        streamItem.closeStream()
        streamItem.closeStream() // Should not crash on multiple calls
    }
}
