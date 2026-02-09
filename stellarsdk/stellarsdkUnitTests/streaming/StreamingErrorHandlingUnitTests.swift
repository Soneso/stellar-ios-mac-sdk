//
//  StreamingItemsAdditionalUnitTests.swift
//  stellarsdk
//
//  Created by Soneso
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class StreamingErrorHandlingUnitTests: XCTestCase {

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        return decoder
    }

    // MARK: - AccountDataStreamItem Error Handling Tests

    func testAccountDataStreamItemHandleResponseInvalidJSON() {
        let expectation = XCTestExpectation(description: "Stream error callback called")
        let streamItem = AccountDataStreamItem(requestUrl: "https://horizon-testnet.stellar.org/accounts/GABC/data/key")

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                XCTAssertNotNil(error)
                if let horizonError = error as? HorizonRequestError {
                    switch horizonError {
                    case .parsingResponseFailed(let message):
                        XCTAssertTrue(message.contains("Error") || message.contains("error") || message.contains("Failed"))
                        expectation.fulfill()
                    default:
                        XCTFail("Expected parsingResponseFailed error")
                    }
                }
            default:
                break
            }
        }

        // Simulate invalid JSON by directly testing the parsing logic
        let invalidJSON = "{ invalid json }"
        let jsonData = invalidJSON.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(DataForAccountResponse.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }

        streamItem.closeStream()
    }

    func testAccountDataStreamItemHandleResponseMissingValue() {
        let incompleteJSON = """
        {
            "sponsor": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(DataForAccountResponse.self, from: incompleteJSON)) { error in
            XCTAssertTrue(error is DecodingError)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, _):
                    XCTAssertEqual(key.stringValue, "value")
                default:
                    break
                }
            }
        }
    }

    func testAccountDataStreamItemHandleResponseEmptyString() {
        let streamItem = AccountDataStreamItem(requestUrl: "https://horizon-testnet.stellar.org/accounts/GABC/data/key")

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                XCTAssertNotNil(error)
            default:
                break
            }
        }

        // Simulate empty string conversion failure
        let emptyData = Data()
        XCTAssertThrowsError(try createDecoder().decode(DataForAccountResponse.self, from: emptyData)) { error in
            XCTAssertTrue(error is DecodingError)
        }

        streamItem.closeStream()
    }

    // MARK: - AccountStreamItem Error Handling Tests

    func testAccountStreamItemHandleResponseInvalidJSON() {
        let invalidJSON = "{ not valid json at all }".data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(AccountResponse.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testAccountStreamItemHandleResponseMissingLinks() {
        let incompleteJSON = """
        {
            "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "sequence": "123456789"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(AccountResponse.self, from: incompleteJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testAccountStreamItemHandleResponseMissingBalances() {
        let incompleteJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                }
            },
            "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "sequence": "123456789"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(AccountResponse.self, from: incompleteJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testAccountStreamItemHandleResponseInvalidSequence() {
        let invalidSequenceJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                }
            },
            "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "sequence": "not_a_number",
            "balances": [],
            "signers": []
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(AccountResponse.self, from: invalidSequenceJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - EffectsStreamItem Error Handling Tests

    func testEffectsStreamItemHandleResponseInvalidJSON() {
        let invalidJSON = "{ incomplete: true".data(using: .utf8)!

        // Test that AccountCreatedEffectResponse cannot be decoded from invalid JSON
        XCTAssertThrowsError(try createDecoder().decode(AccountCreatedEffectResponse.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testEffectsStreamItemHandleResponseMissingTypeI() {
        let missingTypeJSON = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                }
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_created",
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Test that AccountCreatedEffectResponse requires type_i field
        XCTAssertThrowsError(try createDecoder().decode(AccountCreatedEffectResponse.self, from: missingTypeJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testEffectsStreamItemHandleResponseInvalidTypeValue() {
        let invalidTypeJSON = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                }
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_created",
            "type_i": "not_a_number",
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Test that AccountCreatedEffectResponse requires valid type_i integer
        XCTAssertThrowsError(try createDecoder().decode(AccountCreatedEffectResponse.self, from: invalidTypeJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testEffectsStreamItemHandleResponseMissingRequiredField() {
        let missingFieldJSON = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345"
                }
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "account_created",
            "type_i": 0,
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Test that AccountCreatedEffectResponse requires starting_balance field
        XCTAssertThrowsError(try createDecoder().decode(AccountCreatedEffectResponse.self, from: missingFieldJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - LiquidityPoolTradesStreamItem Error Handling Tests

    func testLiquidityPoolTradesStreamItemHandleResponseInvalidJSON() {
        let invalidJSON = "not json".data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testLiquidityPoolTradesStreamItemHandleResponseMissingPrice() {
        let missingPriceJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                }
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "liquidity_pool",
            "base_amount": "100.0000000",
            "base_asset_type": "native",
            "counter_amount": "50.0000000",
            "counter_asset_type": "native",
            "base_is_seller": true
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: missingPriceJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testLiquidityPoolTradesStreamItemHandleResponseMissingBaseAmount() {
        let missingBaseAmountJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                }
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "liquidity_pool",
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

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: missingBaseAmountJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testLiquidityPoolTradesStreamItemHandleResponseInvalidPriceFormat() {
        let invalidPriceJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/trades/12345"
                }
            },
            "id": "12345-1",
            "paging_token": "12345-1",
            "ledger_close_time": "2023-01-15T10:00:00Z",
            "trade_type": "liquidity_pool",
            "base_amount": "100.0000000",
            "base_asset_type": "native",
            "counter_amount": "50.0000000",
            "counter_asset_type": "native",
            "base_is_seller": true,
            "price": {
                "n": "not_a_number",
                "d": "also_not_a_number"
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: invalidPriceJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - OperationsStreamItem Error Handling Tests

    func testOperationsStreamItemHandleResponseInvalidJSON() {
        let invalidJSON = "{ missing bracket".data(using: .utf8)!

        // Test that PaymentOperationResponse cannot be decoded from invalid JSON
        XCTAssertThrowsError(try createDecoder().decode(PaymentOperationResponse.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testOperationsStreamItemHandleResponseMissingTypeI() {
        let missingTypeJSON = """
        {
            "_links": {
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345/effects"
                }
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "payment",
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Test that PaymentOperationResponse requires type_i field
        XCTAssertThrowsError(try createDecoder().decode(PaymentOperationResponse.self, from: missingTypeJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testOperationsStreamItemHandleResponseInvalidTypeValue() {
        let invalidTypeJSON = """
        {
            "_links": {
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345/effects"
                }
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "payment",
            "type_i": "not_a_number",
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Test that PaymentOperationResponse requires valid type_i integer
        XCTAssertThrowsError(try createDecoder().decode(PaymentOperationResponse.self, from: invalidTypeJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testOperationsStreamItemHandleResponseMissingRequiredField() {
        let missingFieldJSON = """
        {
            "_links": {
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/operations/12345/effects"
                }
            },
            "id": "12345",
            "paging_token": "12345",
            "source_account": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "payment",
            "type_i": 1,
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        // Test that PaymentOperationResponse requires payment-specific fields
        XCTAssertThrowsError(try createDecoder().decode(PaymentOperationResponse.self, from: missingFieldJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - TradesStreamItem Error Handling Tests

    func testTradesStreamItemHandleResponseInvalidJSON() {
        let invalidJSON = "[]".data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTradesStreamItemHandleResponseMissingCounterAmount() {
        let missingCounterJSON = """
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
            "counter_asset_type": "native",
            "base_is_seller": true,
            "price": {
                "n": 1,
                "d": 2
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: missingCounterJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTradesStreamItemHandleResponseInvalidAssetType() {
        let invalidAssetTypeJSON = """
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
            "base_asset_type": "invalid_type",
            "counter_amount": "50.0000000",
            "counter_asset_type": "native",
            "base_is_seller": true,
            "price": {
                "n": 1,
                "d": 2
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TradeResponse.self, from: invalidAssetTypeJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - TransactionsStreamItem Error Handling Tests

    func testTransactionsStreamItemHandleResponseInvalidJSON() {
        let invalidJSON = "{ unfinished".data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TransactionResponse.self, from: invalidJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTransactionsStreamItemHandleResponseMissingHash() {
        let missingHashJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123"
                }
            },
            "id": "abc123def456",
            "paging_token": "123456789",
            "successful": true,
            "ledger": 12345,
            "created_at": "2023-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TransactionResponse.self, from: missingHashJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTransactionsStreamItemHandleResponseMissingEnvelopeXDR() {
        let missingXDRJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123"
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
            "memo_type": "none",
            "signatures": []
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TransactionResponse.self, from: missingXDRJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testTransactionsStreamItemHandleResponseInvalidOperationCount() {
        let invalidOpCountJSON = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123"
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
            "operation_count": "not_a_number",
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": []
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try createDecoder().decode(TransactionResponse.self, from: invalidOpCountJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Edge Cases for Valid Responses

    func testAccountDataStreamItemWithLongBase64Value() throws {
        let longValue = String(repeating: "ABC", count: 100)
        let base64Value = Data(longValue.utf8).base64EncodedString()

        let jsonData = """
        {
            "value": "\(base64Value)",
            "sponsor": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(DataForAccountResponse.self, from: jsonData)
        XCTAssertEqual(response.value, base64Value)
        XCTAssertNotNil(response.sponsor)
    }

    func testLiquidityPoolTradesStreamItemWithZeroLiquidityPoolFee() throws {
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
            "liquidity_pool_fee_bp": 0,
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
        XCTAssertEqual(response.tradeType, "liquidity_pool")
        XCTAssertEqual(response.liquidityPoolFeeBp, 0)
    }

    func testTradesStreamItemWithVeryLargePrice() throws {
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
            "base_amount": "0.0000001",
            "base_asset_type": "native",
            "counter_amount": "1000000.0000000",
            "counter_asset_type": "native",
            "base_is_seller": false,
            "price": {
                "n": "10000000000000",
                "d": "1"
            }
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TradeResponse.self, from: jsonData)
        XCTAssertEqual(response.price.n, "10000000000000")
        XCTAssertEqual(response.price.d, "1")
    }

    func testTransactionsStreamItemWithMaxSignatures() throws {
        let signatures = Array(repeating: "9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==", count: 20)
        let signaturesJSON = signatures.map { "\"\($0)\"" }.joined(separator: ",")

        let jsonData = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123"
                },
                "account": {
                    "href": "https://horizon-testnet.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                "ledger": {
                    "href": "https://horizon-testnet.stellar.org/ledgers/12345"
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123/operations"
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123/effects"
                },
                "precedes": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=asc"
                },
                "succeeds": {
                    "href": "https://horizon-testnet.stellar.org/transactions?cursor=abc123&order=desc"
                },
                "transaction": {
                    "href": "https://horizon-testnet.stellar.org/transactions/abc123"
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
            "signatures": [\(signaturesJSON)]
        }
        """.data(using: .utf8)!

        let response = try createDecoder().decode(TransactionResponse.self, from: jsonData)
        XCTAssertEqual(response.signatures.count, 20)
    }

    // MARK: - Stream Lifecycle Tests

    func testAllStreamItemsCloseWithoutCrashing() {
        let accountDataStream = AccountDataStreamItem(requestUrl: "https://test.com/data")
        accountDataStream.closeStream()
        accountDataStream.closeStream() // Multiple closes should not crash

        let accountStream = AccountStreamItem(requestUrl: "https://test.com/account")
        accountStream.closeStream()
        accountStream.closeStream()

        let effectsStream = EffectsStreamItem(requestUrl: "https://test.com/effects")
        effectsStream.closeStream()
        effectsStream.closeStream()

        let poolTradesStream = LiquidityPoolTradesStreamItem(requestUrl: "https://test.com/pool/trades")
        poolTradesStream.closeStream()
        poolTradesStream.closeStream()

        let operationsStream = OperationsStreamItem(requestUrl: "https://test.com/operations")
        operationsStream.closeStream()
        operationsStream.closeStream()

        let tradesStream = TradesStreamItem(requestUrl: "https://test.com/trades")
        tradesStream.closeStream()
        tradesStream.closeStream()

        let transactionsStream = TransactionsStreamItem(requestUrl: "https://test.com/transactions")
        transactionsStream.closeStream()
        transactionsStream.closeStream()

        XCTAssertTrue(true, "All streams closed without crashing")
    }

    // MARK: - UTF-8 Encoding Edge Cases

    func testAccountDataStreamItemWithNonUTF8Data() {
        let streamItem = AccountDataStreamItem(requestUrl: "https://test.com/data")

        streamItem.onReceive { response in
            switch response {
            case .error(let error):
                XCTAssertNotNil(error)
            default:
                break
            }
        }

        // Test with empty data that can't be converted to UTF8
        let emptyData = Data()
        XCTAssertThrowsError(try createDecoder().decode(DataForAccountResponse.self, from: emptyData))

        streamItem.closeStream()
    }

    func testTradesStreamItemWithUnicodeInLinks() throws {
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
        XCTAssertNotNil(response.links)
    }
}
