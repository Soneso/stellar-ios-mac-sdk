//
//  MiscResponsesAdditionalUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MiscResponsesAdditionalUnitTests: XCTestCase {

    // MARK: - Properties

    let sdk = StellarSDK()
    var mockRegistered = false

    override func setUp() {
        super.setUp()

        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - AccountResponse Sequence Number Tests

    func testAccountResponseSequenceNumberMethods() async {
        let testAccountId = "GBZ3VAAP2T2WMKF6226FTC6OSQN6KKGAGPVCCCMDDVLCHYQMXTMNHLB3"

        let mockResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)"
                },
                "transactions": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)/transactions{?cursor,limit,order}",
                    "templated": true
                },
                "operations": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)/operations{?cursor,limit,order}",
                    "templated": true
                },
                "payments": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)/payments{?cursor,limit,order}",
                    "templated": true
                },
                "effects": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)/effects{?cursor,limit,order}",
                    "templated": true
                },
                "offers": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)/offers{?cursor,limit,order}",
                    "templated": true
                },
                "trades": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)/trades{?cursor,limit,order}",
                    "templated": true
                },
                "data": {
                    "href": "https://horizon-testnet.stellar.org/accounts/\(testAccountId)/data/{key}",
                    "templated": true
                }
            },
            "id": "\(testAccountId)",
            "account_id": "\(testAccountId)",
            "sequence": "30232549674450945",
            "subentry_count": 0,
            "last_modified_ledger": 12345,
            "last_modified_time": "2022-01-01T00:00:00Z",
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
                    "balance": "100.0000000",
                    "asset_type": "native",
                    "buying_liabilities": "0.0000000",
                    "selling_liabilities": "0.0000000"
                }
            ],
            "signers": [
                {
                    "key": "\(testAccountId)",
                    "public_key": "\(testAccountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {},
            "num_sponsoring": 0,
            "num_sponsored": 0,
            "paging_token": "\(testAccountId)"
        }
        """

        let handler: MockHandler = { mock, request in
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                      path: "/accounts/\(testAccountId)",
                                      httpMethod: "GET",
                                      mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let accDetailsResEnum = await sdk.accounts.getAccountDetails(accountId: testAccountId)
        switch accDetailsResEnum {
        case .success(let accountDetails):
            let initialSequence = accountDetails.sequenceNumber
            XCTAssertEqual(initialSequence, 30232549674450945)

            let incrementedSeq = accountDetails.incrementedSequenceNumber()
            XCTAssertEqual(incrementedSeq, initialSequence + 1)
            XCTAssertEqual(accountDetails.sequenceNumber, initialSequence)

            accountDetails.incrementSequenceNumber()
            XCTAssertEqual(accountDetails.sequenceNumber, initialSequence + 1)

            accountDetails.decrementSequenceNumber()
            XCTAssertEqual(accountDetails.sequenceNumber, initialSequence)
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testAccountResponseSequenceNumberMethods()", horizonRequestError: error)
            XCTFail()
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - ClaimantPredicateResponse Tests

    func testParseClaimantPredicateResponseUnconditional() throws {
        let jsonResponse = """
        {
            "unconditional": true
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertTrue(response.unconditional ?? false)
        XCTAssertNil(response.and)
        XCTAssertNil(response.or)
        XCTAssertNil(response.not)
        XCTAssertNil(response.beforeAbsoluteTime)
        XCTAssertNil(response.beforeRelativeTime)
    }

    func testParseClaimantPredicateResponseAbsBeforeSnakeCase() throws {
        let jsonResponse = """
        {
            "abs_before": "2025-12-31T23:59:59Z"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNil(response.unconditional)
        XCTAssertEqual(response.beforeAbsoluteTime, "2025-12-31T23:59:59Z")
        XCTAssertNil(response.beforeRelativeTime)
        XCTAssertNil(response.and)
        XCTAssertNil(response.or)
        XCTAssertNil(response.not)
    }

    func testParseClaimantPredicateResponseAbsBeforeCamelCase() throws {
        let jsonResponse = """
        {
            "absBefore": "2026-01-15T12:00:00Z"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNil(response.unconditional)
        XCTAssertEqual(response.beforeAbsoluteTime, "2026-01-15T12:00:00Z")
        XCTAssertNil(response.beforeRelativeTime)
    }

    func testParseClaimantPredicateResponseRelBeforeSnakeCase() throws {
        let jsonResponse = """
        {
            "rel_before": "86400"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNil(response.unconditional)
        XCTAssertNil(response.beforeAbsoluteTime)
        XCTAssertEqual(response.beforeRelativeTime, "86400")
        XCTAssertNil(response.and)
        XCTAssertNil(response.or)
        XCTAssertNil(response.not)
    }

    func testParseClaimantPredicateResponseRelBeforeCamelCase() throws {
        let jsonResponse = """
        {
            "relBefore": "3600"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNil(response.unconditional)
        XCTAssertNil(response.beforeAbsoluteTime)
        XCTAssertEqual(response.beforeRelativeTime, "3600")
    }

    func testParseClaimantPredicateResponseAndCombination() throws {
        let jsonResponse = """
        {
            "and": [
                {
                    "abs_before": "2025-12-31T23:59:59Z"
                },
                {
                    "rel_before": "86400"
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNil(response.unconditional)
        XCTAssertNotNil(response.and)
        XCTAssertEqual(response.and?.count, 2)
        XCTAssertEqual(response.and?[0].beforeAbsoluteTime, "2025-12-31T23:59:59Z")
        XCTAssertEqual(response.and?[1].beforeRelativeTime, "86400")
        XCTAssertNil(response.or)
        XCTAssertNil(response.not)
    }

    func testParseClaimantPredicateResponseOrCombination() throws {
        let jsonResponse = """
        {
            "or": [
                {
                    "abs_before": "2025-06-15T00:00:00Z"
                },
                {
                    "unconditional": true
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNil(response.unconditional)
        XCTAssertNil(response.and)
        XCTAssertNotNil(response.or)
        XCTAssertEqual(response.or?.count, 2)
        XCTAssertEqual(response.or?[0].beforeAbsoluteTime, "2025-06-15T00:00:00Z")
        XCTAssertTrue(response.or?[1].unconditional ?? false)
        XCTAssertNil(response.not)
    }

    func testParseClaimantPredicateResponseNotPredicate() throws {
        let jsonResponse = """
        {
            "not": {
                "abs_before": "2025-03-01T00:00:00Z"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNil(response.unconditional)
        XCTAssertNil(response.and)
        XCTAssertNil(response.or)
        XCTAssertNotNil(response.not)
        XCTAssertEqual(response.not?.beforeAbsoluteTime, "2025-03-01T00:00:00Z")
    }

    func testParseClaimantPredicateResponseComplexNestedPredicate() throws {
        let jsonResponse = """
        {
            "and": [
                {
                    "or": [
                        {
                            "abs_before": "2025-12-31T23:59:59Z"
                        },
                        {
                            "rel_before": "86400"
                        }
                    ]
                },
                {
                    "not": {
                        "unconditional": true
                    }
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        XCTAssertNotNil(response.and)
        XCTAssertEqual(response.and?.count, 2)

        // First AND element is an OR
        let firstAndElement = response.and?[0]
        XCTAssertNotNil(firstAndElement?.or)
        XCTAssertEqual(firstAndElement?.or?.count, 2)
        XCTAssertEqual(firstAndElement?.or?[0].beforeAbsoluteTime, "2025-12-31T23:59:59Z")
        XCTAssertEqual(firstAndElement?.or?[1].beforeRelativeTime, "86400")

        // Second AND element is a NOT
        let secondAndElement = response.and?[1]
        XCTAssertNotNil(secondAndElement?.not)
        XCTAssertTrue(secondAndElement?.not?.unconditional ?? false)
    }

    func testClaimantPredicateResponsePrintPredicate() throws {
        // This test verifies that printPredicate() doesn't crash
        let jsonResponse = """
        {
            "and": [
                {
                    "abs_before": "2025-12-31T23:59:59Z"
                },
                {
                    "rel_before": "86400"
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ClaimantPredicateResponse.self, from: jsonData)

        // Should not crash
        response.printPredicate()
    }

    // MARK: - ErrorResponse Tests

    func testParseErrorResponseBadRequest() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/bad_request",
            "title": "Bad Request",
            "status": 400,
            "detail": "The request you sent was invalid in some way."
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonData)

        XCTAssertEqual(response.type, "https://stellar.org/horizon-errors/bad_request")
        XCTAssertEqual(response.title, "Bad Request")
        XCTAssertEqual(response.httpStatusCode, 400)
        XCTAssertEqual(response.detail, "The request you sent was invalid in some way.")
        XCTAssertNil(response.instance)
        XCTAssertNil(response.extras)
    }

    func testParseErrorResponseNotFound() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/not_found",
            "title": "Resource Missing",
            "status": 404,
            "detail": "The resource at the url requested was not found.",
            "instance": "horizon-testnet-001/abc123"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonData)

        XCTAssertEqual(response.type, "https://stellar.org/horizon-errors/not_found")
        XCTAssertEqual(response.title, "Resource Missing")
        XCTAssertEqual(response.httpStatusCode, 404)
        XCTAssertEqual(response.detail, "The resource at the url requested was not found.")
        XCTAssertEqual(response.instance, "horizon-testnet-001/abc123")
        XCTAssertNil(response.extras)
    }

    func testParseErrorResponseRateLimitExceeded() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/rate_limit_exceeded",
            "title": "Rate Limit Exceeded",
            "status": 429,
            "detail": "Rate limit exceeded. Please wait before making another request.",
            "instance": "horizon-mainnet-001/xyz789"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonData)

        XCTAssertEqual(response.type, "https://stellar.org/horizon-errors/rate_limit_exceeded")
        XCTAssertEqual(response.title, "Rate Limit Exceeded")
        XCTAssertEqual(response.httpStatusCode, 429)
        XCTAssertEqual(response.detail, "Rate limit exceeded. Please wait before making another request.")
        XCTAssertEqual(response.instance, "horizon-mainnet-001/xyz789")
    }

    func testParseErrorResponseInternalServerError() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/server_error",
            "title": "Internal Server Error",
            "status": 500,
            "detail": "An unexpected error occurred while processing your request."
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonData)

        XCTAssertEqual(response.type, "https://stellar.org/horizon-errors/server_error")
        XCTAssertEqual(response.title, "Internal Server Error")
        XCTAssertEqual(response.httpStatusCode, 500)
        XCTAssertEqual(response.detail, "An unexpected error occurred while processing your request.")
    }

    func testParseErrorResponseWithExtras() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/transaction_failed",
            "title": "Transaction Failed",
            "status": 400,
            "detail": "The transaction failed when submitted to the Stellar network.",
            "extras": {
                "envelope_xdr": "AAAAAgAAAAB...",
                "result_xdr": "AAAAAAAAAGT...",
                "hash": "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889",
                "result_codes": {
                    "transaction": "tx_failed",
                    "operations": ["op_underfunded"]
                }
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonData)

        XCTAssertEqual(response.type, "https://stellar.org/horizon-errors/transaction_failed")
        XCTAssertEqual(response.title, "Transaction Failed")
        XCTAssertEqual(response.httpStatusCode, 400)
        XCTAssertEqual(response.detail, "The transaction failed when submitted to the Stellar network.")

        XCTAssertNotNil(response.extras)
        XCTAssertEqual(response.extras?.envelopeXdr, "AAAAAgAAAAB...")
        XCTAssertEqual(response.extras?.resultXdr, "AAAAAAAAAGT...")
        XCTAssertEqual(response.extras?.txHash, "3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889")

        XCTAssertNotNil(response.extras?.resultCodes)
        XCTAssertEqual(response.extras?.resultCodes?.transaction, "tx_failed")
        XCTAssertEqual(response.extras?.resultCodes?.operations?.count, 1)
        XCTAssertEqual(response.extras?.resultCodes?.operations?[0], "op_underfunded")
    }

    func testParseErrorResponseExtrasWithMultipleOperationErrors() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/transaction_failed",
            "title": "Transaction Failed",
            "status": 400,
            "detail": "The transaction failed when submitted to the Stellar network.",
            "extras": {
                "result_codes": {
                    "transaction": "tx_failed",
                    "operations": ["op_underfunded", "op_line_full", "op_no_trust"]
                }
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonData)

        XCTAssertNotNil(response.extras?.resultCodes)
        XCTAssertEqual(response.extras?.resultCodes?.transaction, "tx_failed")
        XCTAssertEqual(response.extras?.resultCodes?.operations?.count, 3)
        XCTAssertEqual(response.extras?.resultCodes?.operations?[0], "op_underfunded")
        XCTAssertEqual(response.extras?.resultCodes?.operations?[1], "op_line_full")
        XCTAssertEqual(response.extras?.resultCodes?.operations?[2], "op_no_trust")
    }

    func testParseErrorResponseExtrasBadSeq() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/transaction_failed",
            "title": "Transaction Failed",
            "status": 400,
            "detail": "The transaction failed when submitted to the Stellar network.",
            "extras": {
                "result_codes": {
                    "transaction": "tx_bad_seq"
                }
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponse.self, from: jsonData)

        XCTAssertNotNil(response.extras?.resultCodes)
        XCTAssertEqual(response.extras?.resultCodes?.transaction, "tx_bad_seq")
        XCTAssertNil(response.extras?.resultCodes?.operations)
    }

    func testParseTimeoutErrorResponse() throws {
        let jsonResponse = """
        {
            "type": "https://stellar.org/horizon-errors/timeout",
            "title": "Gateway Timeout",
            "status": 504,
            "detail": "Your request timed out before completing."
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(TimeoutErrorResponse.self, from: jsonData)

        XCTAssertEqual(response.type, "https://stellar.org/horizon-errors/timeout")
        XCTAssertEqual(response.title, "Gateway Timeout")
        XCTAssertEqual(response.httpStatusCode, 504)
        XCTAssertEqual(response.detail, "Your request timed out before completing.")
    }

    // MARK: - ErrorResponseExtras Tests

    func testParseErrorResponseExtrasPartial() throws {
        let jsonResponse = """
        {
            "envelope_xdr": "AAAAAGL8HQvQkbK2HA3WVjRrKmjX00fG8sLI7m0ERwJW/AX3AAAAZAAiII0AAAAtAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAACXK8doPx27P6IReQlRRuweSSUiUfjqgyswxiu3Sh2R+AAAAAAAAAAAAu67gAAAAAAAAAAHWVUoAAAAAQNUEhOvRi/P8KKLvGT8W8q0J8j8JhqJLKE1Xr3tI2/cJMEKGGBCxLKkY7Mj7Vj6S8Rd4Bz5YMYQDlMEI2Vk6sAM=",
            "result_xdr": "AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+gAAAAA="
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponseExtras.self, from: jsonData)

        XCTAssertNotNil(response.envelopeXdr)
        XCTAssertNotNil(response.resultXdr)
        XCTAssertNil(response.resultCodes)
        XCTAssertNil(response.txHash)
    }

    func testParseErrorResponseExtrasEmpty() throws {
        let jsonResponse = """
        {}
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResponseExtras.self, from: jsonData)

        XCTAssertNil(response.envelopeXdr)
        XCTAssertNil(response.resultXdr)
        XCTAssertNil(response.resultCodes)
        XCTAssertNil(response.txHash)
    }

    // MARK: - ErrorResultCodes Tests

    func testParseErrorResultCodesTransactionOnly() throws {
        let jsonResponse = """
        {
            "transaction": "tx_insufficient_balance"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResultCodes.self, from: jsonData)

        XCTAssertEqual(response.transaction, "tx_insufficient_balance")
        XCTAssertNil(response.operations)
    }

    func testParseErrorResultCodesOperationsOnly() throws {
        let jsonResponse = """
        {
            "operations": ["op_success", "op_low_reserve"]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResultCodes.self, from: jsonData)

        XCTAssertNil(response.transaction)
        XCTAssertEqual(response.operations?.count, 2)
        XCTAssertEqual(response.operations?[0], "op_success")
        XCTAssertEqual(response.operations?[1], "op_low_reserve")
    }

    func testParseErrorResultCodesEmpty() throws {
        let jsonResponse = """
        {}
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ErrorResultCodes.self, from: jsonData)

        XCTAssertNil(response.transaction)
        XCTAssertNil(response.operations)
    }

    // MARK: - HealthService Response Parsing Tests

    func testHealthServiceGetHealthSuccess() async throws {
        let healthJSON = """
        {
            "database_connected": true,
            "core_up": true,
            "core_synced": true
        }
        """

        // Test the response parsing directly
        let decoder = JSONDecoder()
        let healthResponse = try decoder.decode(HealthCheckResponse.self, from: healthJSON.data(using: .utf8)!)

        XCTAssertTrue(healthResponse.databaseConnected)
        XCTAssertTrue(healthResponse.coreUp)
        XCTAssertTrue(healthResponse.coreSynced)
        XCTAssertTrue(healthResponse.isHealthy)
    }

    func testHealthServiceGetHealthUnhealthy() async throws {
        let healthJSON = """
        {
            "database_connected": true,
            "core_up": false,
            "core_synced": false
        }
        """

        let jsonData = healthJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let healthResponse = try decoder.decode(HealthCheckResponse.self, from: jsonData)

        XCTAssertTrue(healthResponse.databaseConnected)
        XCTAssertFalse(healthResponse.coreUp)
        XCTAssertFalse(healthResponse.coreSynced)
        XCTAssertFalse(healthResponse.isHealthy)
    }

    func testHealthServiceGetHealthDatabaseDisconnected() async throws {
        let healthJSON = """
        {
            "database_connected": false,
            "core_up": true,
            "core_synced": true
        }
        """

        let jsonData = healthJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let healthResponse = try decoder.decode(HealthCheckResponse.self, from: jsonData)

        XCTAssertFalse(healthResponse.databaseConnected)
        XCTAssertTrue(healthResponse.coreUp)
        XCTAssertTrue(healthResponse.coreSynced)
        XCTAssertFalse(healthResponse.isHealthy)
    }

    // MARK: - FeeStatsService Response Parsing Tests

    func testFeeStatsServiceGetFeeStatsSuccess() async throws {
        let feeStatsJSON = """
        {
            "last_ledger": "12345678",
            "last_ledger_base_fee": "100",
            "ledger_capacity_usage": "0.47",
            "fee_charged": {
                "max": "100000",
                "min": "100",
                "mode": "100",
                "p10": "100",
                "p20": "100",
                "p30": "100",
                "p40": "100",
                "p50": "100",
                "p60": "100",
                "p70": "100",
                "p80": "100",
                "p90": "100",
                "p95": "200",
                "p99": "1000"
            },
            "max_fee": {
                "max": "500000",
                "min": "100",
                "mode": "100",
                "p10": "100",
                "p20": "100",
                "p30": "100",
                "p40": "100",
                "p50": "100",
                "p60": "100",
                "p70": "100",
                "p80": "150",
                "p90": "200",
                "p95": "300",
                "p99": "500"
            }
        }
        """

        let jsonData = feeStatsJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let feeStatsResponse = try decoder.decode(FeeStatsResponse.self, from: jsonData)

        XCTAssertEqual(feeStatsResponse.lastLedger, "12345678")
        XCTAssertEqual(feeStatsResponse.lastLedgerBaseFee, "100")
        XCTAssertEqual(feeStatsResponse.ledgerCapacityUsage, "0.47")

        // Verify fee_charged
        XCTAssertEqual(feeStatsResponse.feeCharged.max, "100000")
        XCTAssertEqual(feeStatsResponse.feeCharged.min, "100")
        XCTAssertEqual(feeStatsResponse.feeCharged.mode, "100")
        XCTAssertEqual(feeStatsResponse.feeCharged.p50, "100")
        XCTAssertEqual(feeStatsResponse.feeCharged.p99, "1000")

        // Verify max_fee
        XCTAssertEqual(feeStatsResponse.maxFee.max, "500000")
        XCTAssertEqual(feeStatsResponse.maxFee.min, "100")
        XCTAssertEqual(feeStatsResponse.maxFee.mode, "100")
        XCTAssertEqual(feeStatsResponse.maxFee.p80, "150")
        XCTAssertEqual(feeStatsResponse.maxFee.p99, "500")
    }

    func testFeeStatsServiceGetFeeStatsHighCapacity() async throws {
        let feeStatsJSON = """
        {
            "last_ledger": "99999999",
            "last_ledger_base_fee": "100",
            "ledger_capacity_usage": "0.98",
            "fee_charged": {
                "max": "1000000",
                "min": "500",
                "mode": "750",
                "p10": "550",
                "p20": "600",
                "p30": "650",
                "p40": "700",
                "p50": "750",
                "p60": "800",
                "p70": "850",
                "p80": "900",
                "p90": "950",
                "p95": "975",
                "p99": "999"
            },
            "max_fee": {
                "max": "2000000",
                "min": "1000",
                "mode": "1500",
                "p10": "1100",
                "p20": "1200",
                "p30": "1300",
                "p40": "1400",
                "p50": "1500",
                "p60": "1600",
                "p70": "1700",
                "p80": "1800",
                "p90": "1900",
                "p95": "1950",
                "p99": "1999"
            }
        }
        """

        let jsonData = feeStatsJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let feeStatsResponse = try decoder.decode(FeeStatsResponse.self, from: jsonData)

        XCTAssertEqual(feeStatsResponse.lastLedger, "99999999")
        XCTAssertEqual(feeStatsResponse.ledgerCapacityUsage, "0.98")
        XCTAssertEqual(feeStatsResponse.feeCharged.max, "1000000")
        XCTAssertEqual(feeStatsResponse.feeCharged.min, "500")
        XCTAssertEqual(feeStatsResponse.maxFee.max, "2000000")
        XCTAssertEqual(feeStatsResponse.maxFee.min, "1000")
    }

    func testFeeStatsServiceGetFeeStatsLowCapacity() async throws {
        let feeStatsJSON = """
        {
            "last_ledger": "11111111",
            "last_ledger_base_fee": "100",
            "ledger_capacity_usage": "0.05",
            "fee_charged": {
                "max": "100",
                "min": "100",
                "mode": "100",
                "p10": "100",
                "p20": "100",
                "p30": "100",
                "p40": "100",
                "p50": "100",
                "p60": "100",
                "p70": "100",
                "p80": "100",
                "p90": "100",
                "p95": "100",
                "p99": "100"
            },
            "max_fee": {
                "max": "100",
                "min": "100",
                "mode": "100",
                "p10": "100",
                "p20": "100",
                "p30": "100",
                "p40": "100",
                "p50": "100",
                "p60": "100",
                "p70": "100",
                "p80": "100",
                "p90": "100",
                "p95": "100",
                "p99": "100"
            }
        }
        """

        let jsonData = feeStatsJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let feeStatsResponse = try decoder.decode(FeeStatsResponse.self, from: jsonData)

        XCTAssertEqual(feeStatsResponse.lastLedger, "11111111")
        XCTAssertEqual(feeStatsResponse.ledgerCapacityUsage, "0.05")
        XCTAssertEqual(feeStatsResponse.feeCharged.max, "100")
        XCTAssertEqual(feeStatsResponse.feeCharged.min, "100")
        XCTAssertEqual(feeStatsResponse.maxFee.max, "100")
        XCTAssertEqual(feeStatsResponse.maxFee.min, "100")
    }

    // MARK: - ClaimableBalanceResponse Tests

    func testClaimableBalanceResponse() throws {
        let balanceJson = """
        {
          "_links": {
            "self": {
              "href": "https://horizon-testnet.stellar.org/claimable_balances/00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
            }
          },
          "id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
          "asset": "EUR:GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6LVEFLLLKPDL",
          "amount": "250.5000000",
          "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
          "last_modified_ledger": 632370,
          "last_modified_time": "2021-08-04T20:01:24Z",
          "claimants": [
            {
              "destination": "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML",
              "predicate": {
                "unconditional": true
              }
            }
          ],
          "paging_token": "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
        }
        """

        let jsonData = balanceJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        let balance = try decoder.decode(ClaimableBalanceResponse.self, from: jsonData)

        XCTAssertNotNil(balance.links)
        XCTAssertEqual(balance.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        XCTAssertTrue(balance.asset.type == AssetType.ASSET_TYPE_CREDIT_ALPHANUM4)
        XCTAssertEqual(balance.asset.code, "EUR")
        XCTAssertEqual(balance.asset.issuer?.accountId, "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6LVEFLLLKPDL")
        XCTAssertEqual(balance.amount, "250.5000000")
        XCTAssertEqual(balance.sponsor, "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL")
        XCTAssertEqual(balance.lastModifiedLedger, 632370)
        XCTAssertEqual(balance.lastModifiedTime, "2021-08-04T20:01:24Z")
        XCTAssertEqual(balance.pagingToken, "632370-00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        XCTAssertEqual(balance.claimants.count, 1)
        XCTAssertEqual(balance.claimants[0].destination, "GC3C4AKRBQLHOJ45U4XG35ESVWRDECWO5XLDGYADO6DPR3L7KIDVUMML")
        XCTAssertTrue(balance.claimants[0].predicate.unconditional ?? false)
    }

    // MARK: - Effect Response Edge Case Tests

    func testUnknownEffectType() async {
        let jsonData = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon.stellar.org/operations/123"
                },
                "succeeds": {
                    "href": "https://horizon.stellar.org/effects?order=desc&cursor=123-1"
                },
                "precedes": {
                    "href": "https://horizon.stellar.org/effects?order=asc&cursor=123-1"
                }
            },
            "id": "0000000123-0000000001",
            "paging_token": "123-1",
            "account": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "type": "unknown_effect_type",
            "type_i": 9999,
            "created_at": "2023-09-19T05:43:12Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        do {
            _ = try decoder.decode(EffectResponse.self, from: jsonData)
            XCTFail("Expected decoding to fail with unknown effect type")
        } catch {
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

    func testClaimableBalanceClaimantCreatedInvalidAsset() async {
        let jsonData = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon.stellar.org/operations/150684654087864322"
                },
                "succeeds": {
                    "href": "https://horizon.stellar.org/effects?order=desc&cursor=150684654087864322-3"
                },
                "precedes": {
                    "href": "https://horizon.stellar.org/effects?order=asc&cursor=150684654087864322-3"
                }
            },
            "id": "0150684654087864322-0000000003",
            "paging_token": "150684654087864322-3",
            "account": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "type": "claimable_balance_claimant_created",
            "type_i": 51,
            "created_at": "2021-04-24T14:16:59Z",
            "asset": "invalid_asset_format",
            "balance_id": "0000000048a70acdec712be9547d19f7e58adc22e35e0f5bcf3897a0353ab5dd4c5d61f4",
            "amount": "900.0000000",
            "predicate": {
                "unconditional": true
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        do {
            _ = try decoder.decode(ClaimableBalanceClaimantCreatedEffectResponse.self, from: jsonData)
            XCTFail("Expected decoding to fail with invalid asset")
        } catch {
            if let sdkError = error as? StellarSDKError {
                switch sdkError {
                case .decodingError(let message):
                    XCTAssertTrue(message.contains("not a valid asset"))
                default:
                    XCTFail("Expected decodingError")
                }
            } else {
                XCTFail("Expected StellarSDKError")
            }
        }
    }

    func testClaimableBalanceClaimedInvalidAsset() async {
        let jsonData = """
        {
            "_links": {
                "operation": {
                    "href": "https://horizon.stellar.org/operations/150803053451329538"
                },
                "succeeds": {
                    "href": "https://horizon.stellar.org/effects?order=desc&cursor=150803053451329538-1"
                },
                "precedes": {
                    "href": "https://horizon.stellar.org/effects?order=asc&cursor=150803053451329538-1"
                }
            },
            "id": "0150803053451329538-0000000001",
            "paging_token": "150803053451329538-1",
            "account": "GANVXZ2DQ2FFLVCBSVMBBNVWSXS6YVEDP247EN4C3CM3I32XR4U3OU2I",
            "type": "claimable_balance_claimed",
            "type_i": 52,
            "created_at": "2021-04-26T07:35:19Z",
            "asset": "invalid_asset_format",
            "balance_id": "0000000016cbeff27945d389e9123231ec916f7bb848c0579ceca12e2bfab5c34ce0da24",
            "amount": "1.0000000"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        do {
            _ = try decoder.decode(ClaimableBalanceClaimedEffectResponse.self, from: jsonData)
            XCTFail("Expected decoding to fail with invalid asset")
        } catch {
            if let sdkError = error as? StellarSDKError {
                switch sdkError {
                case .decodingError(let message):
                    XCTAssertTrue(message.contains("not a valid asset"))
                default:
                    XCTFail("Expected decodingError")
                }
            } else {
                XCTFail("Expected StellarSDKError")
            }
        }
    }

    // MARK: - Effect Type Parsing Tests (Coverage Recovery)

    /// Helper to create base effect JSON
    private func makeEffectJson(typeI: Int, type: String, extraFields: String = "") -> Data {
        return """
        {
            "_links": {
                "operation": { "href": "https://horizon.stellar.org/operations/123" },
                "succeeds": { "href": "https://horizon.stellar.org/effects?order=desc&cursor=123-1" },
                "precedes": { "href": "https://horizon.stellar.org/effects?order=asc&cursor=123-1" }
            },
            "id": "0000000123-0000000001",
            "paging_token": "123-1",
            "account": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "type": "\(type)",
            "type_i": \(typeI),
            "created_at": "2023-09-19T05:43:12Z"\(extraFields.isEmpty ? "" : ",\n            \(extraFields)")
        }
        """.data(using: .utf8)!
    }

    // MARK: - Account Effects

    func testAccountCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 0, type: "account_created", extraFields: """
"starting_balance": "10000.0000000"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.startingBalance, "10000.0000000")
        XCTAssertEqual(effect.effectType, .accountCreated)
        XCTAssertEqual(effect.account, "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54")
    }

    func testAccountRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 1, type: "account_removed")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .accountRemoved)
    }

    func testAccountCreditedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 2, type: "account_credited", extraFields: """
"amount": "100.5000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountCreditedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.amount, "100.5000000")
        XCTAssertEqual(effect.assetType, "credit_alphanum4")
        XCTAssertEqual(effect.assetCode, "USD")
        XCTAssertEqual(effect.assetIssuer, "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX")
    }

    func testAccountCreditedEffectNativeAssetParsing() throws {
        let jsonData = makeEffectJson(typeI: 2, type: "account_credited", extraFields: """
"amount": "50.0000000",
            "asset_type": "native"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountCreditedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.amount, "50.0000000")
        XCTAssertEqual(effect.assetType, "native")
        XCTAssertNil(effect.assetCode)
        XCTAssertNil(effect.assetIssuer)
    }

    func testAccountDebitedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 3, type: "account_debited", extraFields: """
"amount": "25.0000000",
            "asset_type": "native"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountDebitedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.amount, "25.0000000")
        XCTAssertEqual(effect.effectType, .accountDebited)
    }

    func testAccountThresholdsUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 4, type: "account_thresholds_updated", extraFields: """
"low_threshold": 1,
            "med_threshold": 2,
            "high_threshold": 3
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountThresholdsUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.lowThreshold, 1)
        XCTAssertEqual(effect.medThreshold, 2)
        XCTAssertEqual(effect.highThreshold, 3)
    }

    func testAccountHomeDomainUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 5, type: "account_home_domain_updated", extraFields: """
"home_domain": "stellar.org"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountHomeDomainUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.homeDomain, "stellar.org")
    }

    func testAccountFlagsUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 6, type: "account_flags_updated", extraFields: """
"auth_required": true,
            "auth_revocable": false
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountFlagsUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.authRequired, true)
        XCTAssertEqual(effect.authRevocable, false)
    }

    func testAccountInflationDestinationUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 7, type: "account_inflation_destination_updated")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountInflationDestinationUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .accountInflationDestinationUpdated)
    }

    // MARK: - Signer Effects

    func testSignerCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 10, type: "signer_created", extraFields: """
"public_key": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "weight": 1
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(SignerCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.publicKey, "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54")
        XCTAssertEqual(effect.weight, 1)
    }

    func testSignerRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 11, type: "signer_removed", extraFields: """
"public_key": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "weight": 0
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(SignerRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .signerRemoved)
    }

    func testSignerUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 12, type: "signer_updated", extraFields: """
"public_key": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "weight": 5
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(SignerUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.weight, 5)
    }

    // MARK: - Trustline Effects

    func testTrustlineCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 20, type: "trustline_created", extraFields: """
"limit": "1000.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "EUR",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.limit, "1000.0000000")
        XCTAssertEqual(effect.assetCode, "EUR")
    }

    func testTrustlineRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 21, type: "trustline_removed", extraFields: """
"limit": "0.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "EUR",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .trustlineRemoved)
    }

    func testTrustlineUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 22, type: "trustline_updated", extraFields: """
"limit": "5000.0000000",
            "asset_type": "credit_alphanum12",
            "asset_code": "TESTASSET123",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.limit, "5000.0000000")
        XCTAssertEqual(effect.assetType, "credit_alphanum12")
    }

    func testTrustlineAuthorizedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 23, type: "trustline_authorized", extraFields: """
"limit": "1000.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "trustor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineAuthorizedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.trustor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
    }

    func testTrustlineDeauthorizedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 24, type: "trustline_deauthorized", extraFields: """
"limit": "1000.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "trustor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineDeauthorizedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .trustlineDeauthorized)
    }

    func testTrustlineFlagsUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 26, type: "trustline_flags_updated", extraFields: """
"trustor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "authorized_flag": true,
            "authorized_to_maintain_liabilites_flag": false,
            "clawback_enabled_flag": true
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustLineFlagsUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.authorizedFlag, true)
        XCTAssertEqual(effect.authorizedToMaintainLiabilitiesFlag, false)
        XCTAssertEqual(effect.clawbackEnabledFlag, true)
    }

    // MARK: - Offer Effects

    func testOfferCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 30, type: "offer_created")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(OfferCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .offerCreated)
    }

    func testOfferRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 31, type: "offer_removed")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(OfferRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .offerRemoved)
    }

    func testOfferUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 32, type: "offer_updated")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(OfferUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .offerUpdated)
    }

    // MARK: - Trade Effect

    func testTradeEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 33, type: "trade", extraFields: """
"seller": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "offer_id": "12345",
            "sold_amount": "100.0000000",
            "sold_asset_type": "credit_alphanum4",
            "sold_asset_code": "USD",
            "sold_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "bought_amount": "50.0000000",
            "bought_asset_type": "native"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TradeEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.seller, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
        XCTAssertEqual(effect.offerId, "12345")
        XCTAssertEqual(effect.soldAmount, "100.0000000")
        XCTAssertEqual(effect.soldAssetCode, "USD")
        XCTAssertEqual(effect.boughtAmount, "50.0000000")
        XCTAssertEqual(effect.boughtAssetType, "native")
    }

    // MARK: - Data Effects

    func testDataCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 40, type: "data_created", extraFields: """
"name": "test_key",
            "value": "dGVzdF92YWx1ZQ=="
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(DataCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.name, "test_key")
        XCTAssertEqual(effect.value, "dGVzdF92YWx1ZQ==")
    }

    func testDataRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 41, type: "data_removed", extraFields: """
"name": "test_key"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(DataRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.name, "test_key")
    }

    func testDataUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 42, type: "data_updated", extraFields: """
"name": "test_key",
            "value": "bmV3X3ZhbHVl"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(DataUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.name, "test_key")
        XCTAssertEqual(effect.value, "bmV3X3ZhbHVl")
    }

    // MARK: - Sequence Bumped Effect

    func testSequenceBumpedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 43, type: "sequence_bumped", extraFields: """
"new_seq": "12345678901234567"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(SequenceBumpedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.newSequence, "12345678901234567")
    }

    // MARK: - Claimable Balance Effects

    func testClaimableBalanceCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 50, type: "claimable_balance_created", extraFields: """
"balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
            "asset": "native",
            "amount": "100.0000000"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ClaimableBalanceCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        XCTAssertEqual(effect.amount, "100.0000000")
        XCTAssertTrue(effect.asset.type == AssetType.ASSET_TYPE_NATIVE)
    }

    func testClaimableBalanceClaimantCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 51, type: "claimable_balance_claimant_created", extraFields: """
"balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
            "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "amount": "500.0000000",
            "predicate": { "unconditional": true }
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ClaimableBalanceClaimantCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        XCTAssertEqual(effect.amount, "500.0000000")
        XCTAssertEqual(effect.asset.code, "USD")
        XCTAssertTrue(effect.predicate.unconditional ?? false)
    }

    func testClaimableBalanceClaimedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 52, type: "claimable_balance_claimed", extraFields: """
"balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
            "asset": "EUR:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "amount": "250.0000000"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ClaimableBalanceClaimedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        XCTAssertEqual(effect.amount, "250.0000000")
    }

    func testClaimableBalanceClawedBackEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 80, type: "claimable_balance_clawed_back", extraFields: """
"balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ClaimableBalanceClawedBackEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
    }

    // MARK: - Sponsorship Effects

    func testAccountSponsorshipCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 60, type: "account_sponsorship_created", extraFields: """
"sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountSponsorshipCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sponsor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
    }

    func testAccountSponsorshipUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 61, type: "account_sponsorship_updated", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "new_sponsor": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountSponsorshipUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.formerSponsor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
        XCTAssertEqual(effect.newSponsor, "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX")
    }

    func testAccountSponsorshipRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 62, type: "account_sponsorship_removed", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountSponsorshipRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.formerSponsor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
    }

    // MARK: - Additional Sponsorship Effects

    func testTrustlineSponsorshipCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 63, type: "trustline_sponsorship_created", extraFields: """
"sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineSponsorshipCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sponsor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
    }

    func testTrustlineSponsorshipUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 64, type: "trustline_sponsorship_updated", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "new_sponsor": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineSponsorshipUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .trustlineSponsorshipUpdated)
    }

    func testTrustlineSponsorshipRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 65, type: "trustline_sponsorship_removed", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineSponsorshipRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .trustlineSponsorshipRemoved)
    }

    func testDataSponsorshipCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 66, type: "data_sponsorship_created", extraFields: """
"sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "data_name": "test_data"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(DataSponsorshipCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sponsor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
        XCTAssertEqual(effect.dataName, "test_data")
    }

    func testDataSponsorshipUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 67, type: "data_sponsorship_updated", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "new_sponsor": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "data_name": "test_data"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(DataSponsorshipUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .dataSponsorshipUpdated)
    }

    func testDataSponsorshipRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 68, type: "data_sponsorship_removed", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "data_name": "test_data"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(DataSponsorshipRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .dataSponsorshipRemoved)
    }

    func testClaimableBalanceSponsorshipCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 69, type: "claimable_balance_sponsorship_created", extraFields: """
"sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ClaimableBalanceSponsorshipCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sponsor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
    }

    func testClaimableBalanceSponsorshipUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 70, type: "claimable_balance_sponsorship_updated", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "new_sponsor": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ClaimableBalanceSponsorshipUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .claimableBalanceSponsorshipUpdated)
    }

    func testClaimableBalanceSponsorshipRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 71, type: "claimable_balance_sponsorship_removed", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ClaimableBalanceSponsorshipRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .claimableBalanceSponsorshipRemoved)
    }

    func testSignerSponsorshipCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 72, type: "signer_sponsorship_created", extraFields: """
"sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "signer": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(SignerSponsorshipCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sponsor, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
        XCTAssertEqual(effect.signer, "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54")
    }

    func testSignerSponsorshipUpdatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 73, type: "signer_sponsorship_updated", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "new_sponsor": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "signer": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(SignerSponsorshipUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .signerBalanceSponsorshipUpdated)
    }

    func testSignerSponsorshipRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 74, type: "signer_sponsorship_removed", extraFields: """
"former_sponsor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "signer": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(SignerSponsorshipRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .signerBalanceSponsorshipRemoved)
    }

    // MARK: - Liquidity Pool Effects

    func testLiquidityPoolDepositedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 90, type: "liquidity_pool_deposited", extraFields: """
"liquidity_pool": {
                "id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
                "fee_bp": 30,
                "type": "constant_product",
                "total_trustlines": "1",
                "total_shares": "100.0000000",
                "reserves": [
                    { "asset": "native", "amount": "100.0000000" },
                    { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "100.0000000" }
                ]
            },
            "reserves_deposited": [
                { "asset": "native", "amount": "50.0000000" },
                { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "50.0000000" }
            ],
            "shares_received": "50.0000000"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(LiquidityPoolDepositedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.liquidityPool.poolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
        XCTAssertEqual(effect.liquidityPool.fee, 30)
        XCTAssertEqual(effect.sharesReceived, "50.0000000")
        XCTAssertEqual(effect.reservesDeposited.count, 2)
    }

    func testLiquidityPoolWithdrewEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 91, type: "liquidity_pool_withdrew", extraFields: """
"liquidity_pool": {
                "id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
                "fee_bp": 30,
                "type": "constant_product",
                "total_trustlines": "1",
                "total_shares": "50.0000000",
                "reserves": [
                    { "asset": "native", "amount": "50.0000000" },
                    { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "50.0000000" }
                ]
            },
            "reserves_received": [
                { "asset": "native", "amount": "25.0000000" },
                { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "25.0000000" }
            ],
            "shares_redeemed": "25.0000000"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(LiquidityPoolWithdrewEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sharesRedeemed, "25.0000000")
        XCTAssertEqual(effect.reservesReceived.count, 2)
    }

    func testLiquidityPoolTradeEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 92, type: "liquidity_pool_trade", extraFields: """
"liquidity_pool": {
                "id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
                "fee_bp": 30,
                "type": "constant_product",
                "total_trustlines": "1",
                "total_shares": "100.0000000",
                "reserves": [
                    { "asset": "native", "amount": "100.0000000" },
                    { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "100.0000000" }
                ]
            },
            "sold": { "asset": "native", "amount": "10.0000000" },
            "bought": { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "9.9700000" }
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(LiquidityPoolTradeEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sold.amount, "10.0000000")
        XCTAssertEqual(effect.bought.amount, "9.9700000")
    }

    func testLiquidityPoolCreatedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 93, type: "liquidity_pool_created", extraFields: """
"liquidity_pool": {
                "id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
                "fee_bp": 30,
                "type": "constant_product",
                "total_trustlines": "1",
                "total_shares": "0.0000000",
                "reserves": [
                    { "asset": "native", "amount": "0.0000000" },
                    { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "0.0000000" }
                ]
            }
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(LiquidityPoolCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.liquidityPool.poolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
    }

    func testLiquidityPoolRemovedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 94, type: "liquidity_pool_removed", extraFields: """
"liquidity_pool_id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(LiquidityPoolRemovedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.liquidityPoolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
    }

    func testLiquidityPoolRevokedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 95, type: "liquidity_pool_revoked", extraFields: """
"liquidity_pool": {
                "id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
                "fee_bp": 30,
                "type": "constant_product",
                "total_trustlines": "0",
                "total_shares": "0.0000000",
                "reserves": [
                    { "asset": "native", "amount": "0.0000000" },
                    { "asset": "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX", "amount": "0.0000000" }
                ]
            },
            "reserves_revoked": [
                {
                    "asset": "native",
                    "amount": "10.0000000",
                    "claimable_balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
                }
            ],
            "shares_revoked": "10.0000000"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(LiquidityPoolRevokedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.sharesRevoked, "10.0000000")
        XCTAssertEqual(effect.reservesRevoked.count, 1)
    }

    // MARK: - Contract/Soroban Effects

    func testContractCreditedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 96, type: "contract_credited", extraFields: """
"contract": "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK",
            "amount": "1000.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USDC",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ContractCreditedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.contract, "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK")
        XCTAssertEqual(effect.amount, "1000.0000000")
        XCTAssertEqual(effect.assetCode, "USDC")
    }

    func testContractDebitedEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 97, type: "contract_debited", extraFields: """
"contract": "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK",
            "amount": "500.0000000",
            "asset_type": "native"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(ContractDebitedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.contract, "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK")
        XCTAssertEqual(effect.amount, "500.0000000")
        XCTAssertEqual(effect.assetType, "native")
    }

    // MARK: - TrustlineAuthorizedToMaintainLiabilities Effect

    func testTrustlineAuthorizedToMaintainLiabilitiesEffectParsing() throws {
        let jsonData = makeEffectJson(typeI: 25, type: "trustline_authorized_to_maintain_liabilities", extraFields: """
"limit": "1000.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "trustor": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineAuthorizedToMaintainLiabilitiesEffecResponse.self, from: jsonData)

        XCTAssertEqual(effect.effectType, .trustlineAuthorizedToMaintainLiabilities)
    }

    // MARK: - AccountInflationDestinationUpdated Effect

    func testAccountInflationDestinationWithValueParsing() throws {
        let jsonData = makeEffectJson(typeI: 7, type: "account_inflation_destination_updated")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountInflationDestinationUpdatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.id, "0000000123-0000000001")
        XCTAssertEqual(effect.pagingToken, "123-1")
    }

    // MARK: - Effect with Muxed Account Tests

    func testEffectWithMuxedAccountParsing() throws {
        let jsonData = """
        {
            "_links": {
                "operation": { "href": "https://horizon.stellar.org/operations/123" },
                "succeeds": { "href": "https://horizon.stellar.org/effects?order=desc&cursor=123-1" },
                "precedes": { "href": "https://horizon.stellar.org/effects?order=asc&cursor=123-1" }
            },
            "id": "0000000123-0000000001",
            "paging_token": "123-1",
            "account": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "account_muxed": "MDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2AAAAAAAAAAAPN7BA",
            "account_muxed_id": "1234567890",
            "type": "account_credited",
            "type_i": 2,
            "created_at": "2023-09-19T05:43:12Z",
            "amount": "100.0000000",
            "asset_type": "native"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let effect = try decoder.decode(AccountCreditedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.account, "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54")
        XCTAssertEqual(effect.accountMuxed, "MDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2AAAAAAAAAAAPN7BA")
        XCTAssertEqual(effect.accountMuxedId, "1234567890")
    }

    // MARK: - Trustline with Liquidity Pool Tests

    func testTrustlineCreatedWithLiquidityPoolParsing() throws {
        let jsonData = makeEffectJson(typeI: 20, type: "trustline_created", extraFields: """
"limit": "922337203685.4775807",
            "asset_type": "liquidity_pool_shares",
            "liquidity_pool_id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
""")
        let decoder = JSONDecoder()
        let effect = try decoder.decode(TrustlineCreatedEffectResponse.self, from: jsonData)

        XCTAssertEqual(effect.assetType, "liquidity_pool_shares")
        XCTAssertEqual(effect.liquidityPoolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
    }

    // MARK: - Account Substructure Tests

    func testParseAccountBalanceResponseNative() throws {
        let json = """
        {
            "balance": "100.0000000",
            "buying_liabilities": "0.0000000",
            "selling_liabilities": "0.0000000",
            "asset_type": "native"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountBalanceResponse.self, from: data)

        XCTAssertEqual(response.balance, "100.0000000")
        XCTAssertEqual(response.buyingLiabilities, "0.0000000")
        XCTAssertEqual(response.sellingLiabilities, "0.0000000")
        XCTAssertEqual(response.assetType, "native")
        XCTAssertNil(response.assetCode)
        XCTAssertNil(response.assetIssuer)
        XCTAssertNil(response.limit)
        XCTAssertNil(response.sponsor)
        XCTAssertNil(response.isAuthorized)
        XCTAssertNil(response.liquidityPoolId)
    }

    func testParseAccountBalanceResponseCreditAlphanum4() throws {
        let json = """
        {
            "balance": "500.2500000",
            "buying_liabilities": "10.0000000",
            "selling_liabilities": "25.5000000",
            "limit": "1000000.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
            "is_authorized": true,
            "is_authorized_to_maintain_liabilities": true,
            "is_clawback_enabled": false,
            "last_modified_ledger": 12345678,
            "last_modified_time": "2025-01-15T12:00:00Z"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountBalanceResponse.self, from: data)

        XCTAssertEqual(response.balance, "500.2500000")
        XCTAssertEqual(response.buyingLiabilities, "10.0000000")
        XCTAssertEqual(response.sellingLiabilities, "25.5000000")
        XCTAssertEqual(response.limit, "1000000.0000000")
        XCTAssertEqual(response.assetType, "credit_alphanum4")
        XCTAssertEqual(response.assetCode, "USD")
        XCTAssertEqual(response.assetIssuer, "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX")
        XCTAssertEqual(response.isAuthorized, true)
        XCTAssertEqual(response.isAuthorizedToMaintainLiabilities, true)
        XCTAssertEqual(response.isClawbackEnabled, false)
        XCTAssertEqual(response.lastModifiedLedger, 12345678)
        XCTAssertEqual(response.lastModifiedTime, "2025-01-15T12:00:00Z")
    }

    func testParseAccountBalanceResponseCreditAlphanum12() throws {
        let json = """
        {
            "balance": "9999999.9999999",
            "buying_liabilities": "0.0000000",
            "selling_liabilities": "0.0000000",
            "limit": "922337203685.4775807",
            "asset_type": "credit_alphanum12",
            "asset_code": "TESTASSET123",
            "asset_issuer": "GCNY5OXYSY4FKHOPT2SPOQZAOEIGXB5LBYW3HVU3OWSTQITS65M5RCNY",
            "is_authorized": false,
            "is_authorized_to_maintain_liabilities": true
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountBalanceResponse.self, from: data)

        XCTAssertEqual(response.balance, "9999999.9999999")
        XCTAssertEqual(response.limit, "922337203685.4775807")
        XCTAssertEqual(response.assetType, "credit_alphanum12")
        XCTAssertEqual(response.assetCode, "TESTASSET123")
        XCTAssertEqual(response.assetIssuer, "GCNY5OXYSY4FKHOPT2SPOQZAOEIGXB5LBYW3HVU3OWSTQITS65M5RCNY")
        XCTAssertEqual(response.isAuthorized, false)
        XCTAssertEqual(response.isAuthorizedToMaintainLiabilities, true)
    }

    func testParseAccountBalanceResponseLiquidityPoolShares() throws {
        let json = """
        {
            "balance": "1000.0000000",
            "limit": "922337203685.4775807",
            "buying_liabilities": "0.0000000",
            "selling_liabilities": "0.0000000",
            "asset_type": "liquidity_pool_shares",
            "liquidity_pool_id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
            "last_modified_ledger": 87654321
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountBalanceResponse.self, from: data)

        XCTAssertEqual(response.balance, "1000.0000000")
        XCTAssertEqual(response.assetType, "liquidity_pool_shares")
        XCTAssertEqual(response.liquidityPoolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
        XCTAssertNil(response.assetCode)
        XCTAssertNil(response.assetIssuer)
        XCTAssertEqual(response.lastModifiedLedger, 87654321)
    }

    func testParseAccountBalanceResponseSponsored() throws {
        let json = """
        {
            "balance": "250.0000000",
            "buying_liabilities": "0.0000000",
            "selling_liabilities": "0.0000000",
            "limit": "1000.0000000",
            "asset_type": "credit_alphanum4",
            "asset_code": "EUR",
            "asset_issuer": "GDTNXRLOJD2YEBPKK7KCMR7J33AAG5VZXHAJTHIG736D6LVEFLLLKPDL",
            "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL",
            "is_authorized": true
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountBalanceResponse.self, from: data)

        XCTAssertEqual(response.balance, "250.0000000")
        XCTAssertEqual(response.assetCode, "EUR")
        XCTAssertEqual(response.sponsor, "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL")
        XCTAssertEqual(response.isAuthorized, true)
    }

    func testParseAccountFlagsResponseAllFalse() throws {
        let json = """
        {
            "auth_required": false,
            "auth_revocable": false,
            "auth_immutable": false,
            "auth_clawback_enabled": false
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountFlagsResponse.self, from: data)

        XCTAssertFalse(response.authRequired)
        XCTAssertFalse(response.authRevocable)
        XCTAssertFalse(response.authImmutable)
        XCTAssertFalse(response.authClawbackEnabled)
    }

    func testParseAccountFlagsResponseAllTrue() throws {
        let json = """
        {
            "auth_required": true,
            "auth_revocable": true,
            "auth_immutable": true,
            "auth_clawback_enabled": true
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountFlagsResponse.self, from: data)

        XCTAssertTrue(response.authRequired)
        XCTAssertTrue(response.authRevocable)
        XCTAssertTrue(response.authImmutable)
        XCTAssertTrue(response.authClawbackEnabled)
    }

    func testParseAccountFlagsResponseMixed() throws {
        let json = """
        {
            "auth_required": true,
            "auth_revocable": true,
            "auth_immutable": false,
            "auth_clawback_enabled": true
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountFlagsResponse.self, from: data)

        XCTAssertTrue(response.authRequired)
        XCTAssertTrue(response.authRevocable)
        XCTAssertFalse(response.authImmutable)
        XCTAssertTrue(response.authClawbackEnabled)
    }

    func testParseAccountFlagsResponseMissingFields() throws {
        // When fields are missing, they should default to false
        let json = """
        {}
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountFlagsResponse.self, from: data)

        XCTAssertFalse(response.authRequired)
        XCTAssertFalse(response.authRevocable)
        XCTAssertFalse(response.authImmutable)
        XCTAssertFalse(response.authClawbackEnabled)
    }

    func testParseAccountThresholdsResponseDefault() throws {
        let json = """
        {
            "low_threshold": 0,
            "med_threshold": 0,
            "high_threshold": 0
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountThresholdsResponse.self, from: data)

        XCTAssertEqual(response.lowThreshold, 0)
        XCTAssertEqual(response.medThreshold, 0)
        XCTAssertEqual(response.highThreshold, 0)
    }

    func testParseAccountThresholdsResponseMultiSig() throws {
        let json = """
        {
            "low_threshold": 1,
            "med_threshold": 2,
            "high_threshold": 3
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountThresholdsResponse.self, from: data)

        XCTAssertEqual(response.lowThreshold, 1)
        XCTAssertEqual(response.medThreshold, 2)
        XCTAssertEqual(response.highThreshold, 3)
    }

    func testParseAccountThresholdsResponseMaxValues() throws {
        let json = """
        {
            "low_threshold": 255,
            "med_threshold": 255,
            "high_threshold": 255
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountThresholdsResponse.self, from: data)

        XCTAssertEqual(response.lowThreshold, 255)
        XCTAssertEqual(response.medThreshold, 255)
        XCTAssertEqual(response.highThreshold, 255)
    }

    func testParseAccountSignerResponseEd25519() throws {
        let json = """
        {
            "weight": 1,
            "key": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "type": "ed25519_public_key"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountSignerResponse.self, from: data)

        XCTAssertEqual(response.weight, 1)
        XCTAssertEqual(response.key, "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54")
        XCTAssertEqual(response.type, "ed25519_public_key")
        XCTAssertNil(response.sponsor)
    }

    func testParseAccountSignerResponseSha256Hash() throws {
        let json = """
        {
            "weight": 2,
            "key": "XDQZ3GCQFNNWK7L72WOGKXHWABVBMJXZ6AQWMFVVR5R7XZQZ7VSA",
            "type": "sha256_hash"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountSignerResponse.self, from: data)

        XCTAssertEqual(response.weight, 2)
        XCTAssertEqual(response.key, "XDQZ3GCQFNNWK7L72WOGKXHWABVBMJXZ6AQWMFVVR5R7XZQZ7VSA")
        XCTAssertEqual(response.type, "sha256_hash")
    }

    func testParseAccountSignerResponsePreAuthTx() throws {
        let json = """
        {
            "weight": 1,
            "key": "TDNA2V62PVEFBZ74CDJKTUHLY4Y7PL5UAV2MAM4VWF6USFE3SH235FXL",
            "type": "preauth_tx"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountSignerResponse.self, from: data)

        XCTAssertEqual(response.weight, 1)
        XCTAssertEqual(response.type, "preauth_tx")
    }

    func testParseAccountSignerResponseSponsored() throws {
        let json = """
        {
            "weight": 5,
            "key": "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT",
            "type": "ed25519_public_key",
            "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountSignerResponse.self, from: data)

        XCTAssertEqual(response.weight, 5)
        XCTAssertEqual(response.key, "GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT")
        XCTAssertEqual(response.type, "ed25519_public_key")
        XCTAssertEqual(response.sponsor, "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL")
    }

    func testParseAccountSignerResponseZeroWeight() throws {
        // Weight 0 means signer is being removed
        let json = """
        {
            "weight": 0,
            "key": "GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54",
            "type": "ed25519_public_key"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(AccountSignerResponse.self, from: data)

        XCTAssertEqual(response.weight, 0)
    }

    // MARK: - LiquidityPoolTradesResponse Tests

    func testParseLiquidityPoolTradesResponse() throws {
        let json = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/liquidity_pools/67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9/trades?cursor=&limit=10&order=desc"
                }
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": { "href": "" },
                            "base": { "href": "https://horizon.stellar.org/accounts/GCBMP2WKIAX7KVDRCSFXJWFM5P7HDCGTCC76U5XR52OYII6AOWS7G3DT" },
                            "counter": { "href": "" },
                            "operation": { "href": "https://horizon.stellar.org/operations/12345678" }
                        },
                        "id": "12345678-0",
                        "paging_token": "12345678-0",
                        "ledger_close_time": "2025-01-15T12:00:00Z",
                        "trade_type": "liquidity_pool",
                        "base_liquidity_pool_id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
                        "liquidity_pool_fee_bp": 30,
                        "base_amount": "100.0000000",
                        "base_asset_type": "native",
                        "counter_account": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                        "counter_amount": "99.7000000",
                        "counter_asset_type": "credit_alphanum4",
                        "counter_asset_code": "USD",
                        "counter_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                        "price": {
                            "n": 997,
                            "d": 1000
                        },
                        "base_is_seller": true
                    }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let response = try decoder.decode(LiquidityPoolTradesResponse.self, from: data)

        XCTAssertNotNil(response.links)
        XCTAssertNotNil(response.links.selflink)
        XCTAssertEqual(response.records.count, 1)

        let trade = response.records[0]
        XCTAssertEqual(trade.id, "12345678-0")
        XCTAssertEqual(trade.pagingToken, "12345678-0")
        XCTAssertEqual(trade.tradeType, "liquidity_pool")
        XCTAssertEqual(trade.baseLiquidityPoolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
        XCTAssertEqual(trade.liquidityPoolFeeBp, 30)
        XCTAssertEqual(trade.baseAmount, "100.0000000")
        XCTAssertEqual(trade.baseAssetType, "native")
        XCTAssertEqual(trade.counterAmount, "99.7000000")
        XCTAssertEqual(trade.counterAssetCode, "USD")
        XCTAssertEqual(trade.baseIsSeller, true)
        XCTAssertEqual(trade.price.n, "997")
        XCTAssertEqual(trade.price.d, "1000")
    }

    func testParseLiquidityPoolTradesResponseEmpty() throws {
        let json = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/liquidity_pools/67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9/trades"
                }
            },
            "_embedded": {
                "records": []
            }
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(LiquidityPoolTradesResponse.self, from: data)

        XCTAssertNotNil(response.links)
        XCTAssertEqual(response.records.count, 0)
    }

    // MARK: - LiquidityPoolTradesLinksResponse Tests

    func testParseLiquidityPoolTradesLinksResponse() throws {
        let json = """
        {
            "self": {
                "href": "https://horizon.stellar.org/liquidity_pools/67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9/trades?cursor=&limit=10&order=desc"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(LiquidityPoolTradesLinksResponse.self, from: data)

        XCTAssertNotNil(response.selflink)
        XCTAssertEqual(response.selflink.href, "https://horizon.stellar.org/liquidity_pools/67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9/trades?cursor=&limit=10&order=desc")
    }

    // MARK: - DataForAccountResponse Tests

    func testParseDataForAccountResponse() throws {
        let json = """
        {
            "value": "dGVzdF92YWx1ZQ=="
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(DataForAccountResponse.self, from: data)

        XCTAssertEqual(response.value, "dGVzdF92YWx1ZQ==")
        XCTAssertNil(response.sponsor)
    }

    func testParseDataForAccountResponseWithSponsor() throws {
        let json = """
        {
            "value": "c3BvbnNvcmVkX2RhdGE=",
            "sponsor": "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(DataForAccountResponse.self, from: data)

        XCTAssertEqual(response.value, "c3BvbnNvcmVkX2RhdGE=")
        XCTAssertEqual(response.sponsor, "GBVFLWXYCIGPO3455XVFIKHS66FCT5AI64ZARKS7QJN4NF7K5FOXTJNL")
    }
}

// MARK: - AccountResponsesMock

class AccountResponsesMock: ResponsesMock {
    var accounts = [String: String]()

    func addAccount(key: String, accountResponse: String) {
        accounts[key] = accountResponse
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard
                let key = mock.variables["account"],
                let accountResponse = self?.accounts[key] else {
                    mock.statusCode = 404
                    return self?.resourceMissingResponse()
                }

            return accountResponse
        }

        return RequestMock(host: "horizon-testnet.stellar.org",
                           path: "/accounts/${account}",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
