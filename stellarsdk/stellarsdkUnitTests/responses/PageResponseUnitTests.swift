//
//  PageResponseUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class PageResponseUnitTests: XCTestCase {

    // MARK: - JSON Decoding Tests

    func testParsePageResponseWithTransactions() throws {
        let jsonResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/transactions?limit=2&order=desc"
                },
                "next": {
                    "href": "https://horizon.stellar.org/transactions?cursor=123456&limit=2&order=desc"
                },
                "prev": {
                    "href": "https://horizon.stellar.org/transactions?cursor=123450&limit=2&order=asc"
                }
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon.stellar.org/transactions/tx1"
                            },
                            "account": {
                                "href": "https://horizon.stellar.org/accounts/GABC"
                            },
                            "ledger": {
                                "href": "https://horizon.stellar.org/ledgers/1234"
                            },
                            "operations": {
                                "href": "https://horizon.stellar.org/transactions/tx1/operations{?cursor,limit,order}",
                                "templated": true
                            },
                            "effects": {
                                "href": "https://horizon.stellar.org/transactions/tx1/effects{?cursor,limit,order}",
                                "templated": true
                            },
                            "precedes": {
                                "href": "https://horizon.stellar.org/transactions?order=asc&cursor=tx1"
                            },
                            "succeeds": {
                                "href": "https://horizon.stellar.org/transactions?order=desc&cursor=tx1"
                            }
                        },
                        "id": "tx1",
                        "paging_token": "123456",
                        "successful": true,
                        "hash": "hash1",
                        "ledger": 1234,
                        "created_at": "2024-01-01T00:00:00Z",
                        "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "source_account_sequence": "1",
                        "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "fee_charged": "100",
                        "max_fee": "1000",
                        "operation_count": 1,
                        "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
                        "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
                        "memo_type": "none",
                        "signatures": ["sig1"],
                        "valid_after": "1970-01-01T00:00:00Z",
                        "valid_before": "2030-01-01T00:00:00Z",
                        "preconditions": {
                            "timebounds": {
                                "min_time": "0",
                                "max_time": "0"
                            }
                        }
                    },
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon.stellar.org/transactions/tx2"
                            },
                            "account": {
                                "href": "https://horizon.stellar.org/accounts/GDEF"
                            },
                            "ledger": {
                                "href": "https://horizon.stellar.org/ledgers/1233"
                            },
                            "operations": {
                                "href": "https://horizon.stellar.org/transactions/tx2/operations{?cursor,limit,order}",
                                "templated": true
                            },
                            "effects": {
                                "href": "https://horizon.stellar.org/transactions/tx2/effects{?cursor,limit,order}",
                                "templated": true
                            },
                            "precedes": {
                                "href": "https://horizon.stellar.org/transactions?order=asc&cursor=tx2"
                            },
                            "succeeds": {
                                "href": "https://horizon.stellar.org/transactions?order=desc&cursor=tx2"
                            }
                        },
                        "id": "tx2",
                        "paging_token": "123455",
                        "successful": true,
                        "hash": "hash2",
                        "ledger": 1233,
                        "created_at": "2023-12-31T23:59:59Z",
                        "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "source_account_sequence": "2",
                        "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "fee_charged": "200",
                        "max_fee": "2000",
                        "operation_count": 2,
                        "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
                        "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
                        "memo_type": "text",
                        "memo": "test",
                        "signatures": ["sig2"],
                        "valid_after": "1970-01-01T00:00:00Z",
                        "valid_before": "2030-01-01T00:00:00Z",
                        "preconditions": {
                            "timebounds": {
                                "min_time": "0",
                                "max_time": "0"
                            }
                        }
                    }
                ]
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let response = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)

        // Verify records
        XCTAssertEqual(response.records.count, 2)
        XCTAssertEqual(response.records[0].id, "tx1")
        XCTAssertEqual(response.records[0].transactionHash, "hash1")
        XCTAssertEqual(response.records[0].sourceAccount, "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN")
        XCTAssertEqual(response.records[0].feeCharged, "100")

        XCTAssertEqual(response.records[1].id, "tx2")
        XCTAssertEqual(response.records[1].transactionHash, "hash2")
        XCTAssertEqual(response.records[1].sourceAccount, "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN")
        XCTAssertEqual(response.records[1].feeCharged, "200")

        // Verify pagination links
        XCTAssertEqual(response.links.selflink.href, "https://horizon.stellar.org/transactions?limit=2&order=desc")
        XCTAssertNotNil(response.links.next)
        XCTAssertEqual(response.links.next?.href, "https://horizon.stellar.org/transactions?cursor=123456&limit=2&order=desc")
        XCTAssertNotNil(response.links.prev)
        XCTAssertEqual(response.links.prev?.href, "https://horizon.stellar.org/transactions?cursor=123450&limit=2&order=asc")
    }

    func testParsePageResponseEmptyRecords() throws {
        let jsonResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/transactions?limit=10"
                }
            },
            "_embedded": {
                "records": []
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 0)
        XCTAssertEqual(response.links.selflink.href, "https://horizon.stellar.org/transactions?limit=10")
        XCTAssertNil(response.links.next)
        XCTAssertNil(response.links.prev)
    }

    func testParsePageResponseWithoutNextLink() throws {
        let jsonResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/transactions?limit=2"
                },
                "prev": {
                    "href": "https://horizon.stellar.org/transactions?cursor=123450&limit=2&order=asc"
                }
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon.stellar.org/transactions/tx1"
                            },
                            "account": {
                                "href": "https://horizon.stellar.org/accounts/GABC"
                            },
                            "ledger": {
                                "href": "https://horizon.stellar.org/ledgers/1234"
                            },
                            "operations": {
                                "href": "https://horizon.stellar.org/transactions/tx1/operations{?cursor,limit,order}",
                                "templated": true
                            },
                            "effects": {
                                "href": "https://horizon.stellar.org/transactions/tx1/effects{?cursor,limit,order}",
                                "templated": true
                            },
                            "precedes": {
                                "href": "https://horizon.stellar.org/transactions?order=asc&cursor=tx1"
                            },
                            "succeeds": {
                                "href": "https://horizon.stellar.org/transactions?order=desc&cursor=tx1"
                            }
                        },
                        "id": "tx1",
                        "paging_token": "123456",
                        "successful": true,
                        "hash": "hash1",
                        "ledger": 1234,
                        "created_at": "2024-01-01T00:00:00Z",
                        "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "source_account_sequence": "1",
                        "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "fee_charged": "100",
                        "max_fee": "1000",
                        "operation_count": 1,
                        "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
                        "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
                        "memo_type": "none",
                        "signatures": ["sig1"],
                        "valid_after": "1970-01-01T00:00:00Z",
                        "valid_before": "2030-01-01T00:00:00Z",
                        "preconditions": {
                            "timebounds": {
                                "min_time": "0",
                                "max_time": "0"
                            }
                        }
                    }
                ]
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let response = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 1)
        XCTAssertNil(response.links.next)
        XCTAssertNotNil(response.links.prev)
    }

    func testParsePageResponseWithoutPrevLink() throws {
        let jsonResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/transactions?limit=2"
                },
                "next": {
                    "href": "https://horizon.stellar.org/transactions?cursor=123456&limit=2&order=desc"
                }
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon.stellar.org/transactions/tx1"
                            },
                            "account": {
                                "href": "https://horizon.stellar.org/accounts/GABC"
                            },
                            "ledger": {
                                "href": "https://horizon.stellar.org/ledgers/1234"
                            },
                            "operations": {
                                "href": "https://horizon.stellar.org/transactions/tx1/operations{?cursor,limit,order}",
                                "templated": true
                            },
                            "effects": {
                                "href": "https://horizon.stellar.org/transactions/tx1/effects{?cursor,limit,order}",
                                "templated": true
                            },
                            "precedes": {
                                "href": "https://horizon.stellar.org/transactions?order=asc&cursor=tx1"
                            },
                            "succeeds": {
                                "href": "https://horizon.stellar.org/transactions?order=desc&cursor=tx1"
                            }
                        },
                        "id": "tx1",
                        "paging_token": "123456",
                        "successful": true,
                        "hash": "hash1",
                        "ledger": 1234,
                        "created_at": "2024-01-01T00:00:00Z",
                        "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "source_account_sequence": "1",
                        "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "fee_charged": "100",
                        "max_fee": "1000",
                        "operation_count": 1,
                        "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
                        "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
                        "memo_type": "none",
                        "signatures": ["sig1"],
                        "valid_after": "1970-01-01T00:00:00Z",
                        "valid_before": "2030-01-01T00:00:00Z",
                        "preconditions": {
                            "timebounds": {
                                "min_time": "0",
                                "max_time": "0"
                            }
                        }
                    }
                ]
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let response = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 1)
        XCTAssertNotNil(response.links.next)
        XCTAssertNil(response.links.prev)
    }

    func testParsePageResponseWithLedgers() throws {
        let jsonResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/ledgers?limit=1"
                },
                "next": {
                    "href": "https://horizon.stellar.org/ledgers?cursor=456&limit=1"
                }
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon.stellar.org/ledgers/1"
                            },
                            "transactions": {
                                "href": "https://horizon.stellar.org/ledgers/1/transactions{?cursor,limit,order}",
                                "templated": true
                            },
                            "operations": {
                                "href": "https://horizon.stellar.org/ledgers/1/operations{?cursor,limit,order}",
                                "templated": true
                            },
                            "payments": {
                                "href": "https://horizon.stellar.org/ledgers/1/payments{?cursor,limit,order}",
                                "templated": true
                            },
                            "effects": {
                                "href": "https://horizon.stellar.org/ledgers/1/effects{?cursor,limit,order}",
                                "templated": true
                            }
                        },
                        "id": "ledger1",
                        "paging_token": "456",
                        "hash": "ledger_hash",
                        "prev_hash": "prev_ledger_hash",
                        "sequence": 1,
                        "successful_transaction_count": 5,
                        "failed_transaction_count": 1,
                        "operation_count": 10,
                        "tx_set_operation_count": 10,
                        "closed_at": "2024-01-01T00:00:00Z",
                        "total_coins": "100000000000",
                        "fee_pool": "1000",
                        "base_fee_in_stroops": 100,
                        "base_reserve_in_stroops": 5000000,
                        "max_tx_set_size": 1000,
                        "protocol_version": 20,
                        "header_xdr": "AAAA"
                    }
                ]
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let response = try decoder.decode(PageResponse<LedgerResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 1)
        XCTAssertEqual(response.records[0].id, "ledger1")
        XCTAssertEqual(response.records[0].sequenceNumber, 1)
        XCTAssertEqual(response.records[0].successfulTransactionCount, 5)
        XCTAssertNotNil(response.links.next)
        XCTAssertNil(response.links.prev)
    }

    func testParsePageResponseWithAccounts() throws {
        let jsonResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/accounts?limit=1"
                }
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                            },
                            "transactions": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/transactions{?cursor,limit,order}",
                                "templated": true
                            },
                            "operations": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/operations{?cursor,limit,order}",
                                "templated": true
                            },
                            "payments": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/payments{?cursor,limit,order}",
                                "templated": true
                            },
                            "effects": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/effects{?cursor,limit,order}",
                                "templated": true
                            },
                            "offers": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/offers{?cursor,limit,order}",
                                "templated": true
                            },
                            "trades": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/trades{?cursor,limit,order}",
                                "templated": true
                            },
                            "data": {
                                "href": "https://horizon.stellar.org/accounts/GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY/data/{key}",
                                "templated": true
                            }
                        },
                        "id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                        "account_id": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                        "sequence": "12345",
                        "subentry_count": 0,
                        "last_modified_ledger": 100,
                        "last_modified_time": "2024-01-01T00:00:00Z",
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
                ]
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let response = try decoder.decode(PageResponse<AccountResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 1)
        XCTAssertEqual(response.records[0].accountId, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.records[0].sequenceNumber, 12345)
    }

    // MARK: - Pagination Methods Tests

    func testHasNextPage() throws {
        let jsonWithNext = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/transactions"},
                "next": {"href": "https://horizon.stellar.org/transactions?cursor=123"}
            },
            "_embedded": {"records": []}
        }
        """

        let jsonData = jsonWithNext.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)

        XCTAssertTrue(response.hasNextPage())

        let jsonWithoutNext = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/transactions"}
            },
            "_embedded": {"records": []}
        }
        """

        let jsonData2 = jsonWithoutNext.data(using: .utf8)!
        let response2 = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData2)

        XCTAssertFalse(response2.hasNextPage())
    }

    func testHasPreviousPage() throws {
        let jsonWithPrev = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/transactions"},
                "prev": {"href": "https://horizon.stellar.org/transactions?cursor=123"}
            },
            "_embedded": {"records": []}
        }
        """

        let jsonData = jsonWithPrev.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)

        XCTAssertTrue(response.hasPreviousPage())

        let jsonWithoutPrev = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/transactions"}
            },
            "_embedded": {"records": []}
        }
        """

        let jsonData2 = jsonWithoutPrev.data(using: .utf8)!
        let response2 = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData2)

        XCTAssertFalse(response2.hasPreviousPage())
    }

    // MARK: - Initializer Tests

    func testInitWithRecordsAndLinks() {
        // Create mock link response
        let selfLink = createMockLinkResponse(href: "https://horizon.stellar.org/test")
        let nextLink = createMockLinkResponse(href: "https://horizon.stellar.org/test?cursor=next")
        let prevLink = createMockLinkResponse(href: "https://horizon.stellar.org/test?cursor=prev")

        let pagingLinks = createMockPagingLinksResponse(
            selflink: selfLink,
            next: nextLink,
            prev: prevLink
        )

        // Create page response with empty records for simplicity
        let page = PageResponse<TransactionResponse>(records: [], links: pagingLinks)

        XCTAssertEqual(page.records.count, 0)
        XCTAssertEqual(page.links.selflink.href, "https://horizon.stellar.org/test")
        XCTAssertEqual(page.links.next?.href, "https://horizon.stellar.org/test?cursor=next")
        XCTAssertEqual(page.links.prev?.href, "https://horizon.stellar.org/test?cursor=prev")
        XCTAssertTrue(page.hasNextPage())
        XCTAssertTrue(page.hasPreviousPage())
    }

    // MARK: - Edge Cases

    func testParsePageResponseWithTemplatedLinks() throws {
        let jsonResponse = """
        {
            "_links": {
                "self": {
                    "href": "https://horizon.stellar.org/transactions?limit={limit}&cursor={cursor}",
                    "templated": true
                },
                "next": {
                    "href": "https://horizon.stellar.org/transactions?cursor=123&limit=10",
                    "templated": false
                }
            },
            "_embedded": {
                "records": []
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)

        XCTAssertEqual(response.links.selflink.templated, true)
        XCTAssertEqual(response.links.next?.templated, false)
    }

    func testParsePageResponseWithMultipleRecordTypes() throws {
        // Test with OfferResponse
        let offersJson = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/offers"}
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon.stellar.org/offers/1"},
                            "offer_maker": {"href": "https://horizon.stellar.org/accounts/GABC"}
                        },
                        "id": "1",
                        "paging_token": "1",
                        "seller": "GABC",
                        "selling": {
                            "asset_type": "native"
                        },
                        "buying": {
                            "asset_type": "credit_alphanum4",
                            "asset_code": "USD",
                            "asset_issuer": "GDEF"
                        },
                        "amount": "100.0000000",
                        "price_r": {
                            "n": 1,
                            "d": 1
                        },
                        "price": "1.0000000",
                        "last_modified_ledger": 100,
                        "last_modified_time": "2024-01-01T00:00:00Z"
                    }
                ]
            }
        }
        """

        let jsonData = offersJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PageResponse<OfferResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 1)
        XCTAssertEqual(response.records[0].id, "1")
        XCTAssertEqual(response.records[0].seller, "GABC")
    }

    func testParsePageResponseWithAssets() throws {
        let assetsJson = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/assets"}
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "toml": {"href": "https://example.com/.well-known/stellar.toml"}
                        },
                        "asset_type": "credit_alphanum4",
                        "asset_code": "USD",
                        "asset_issuer": "GABC",
                        "paging_token": "USD_GABC_credit_alphanum4",
                        "num_accounts": 100,
                        "num_claimable_balances": 5,
                        "num_liquidity_pools": 2,
                        "amount": "1000000.0000000",
                        "accounts": {
                            "authorized": 100,
                            "authorized_to_maintain_liabilities": 0,
                            "unauthorized": 0
                        },
                        "claimable_balances_amount": "5000.0000000",
                        "liquidity_pools_amount": "2000.0000000",
                        "balances": {
                            "authorized": "1000000.0000000",
                            "authorized_to_maintain_liabilities": "0.0000000",
                            "unauthorized": "0.0000000"
                        },
                        "flags": {
                            "auth_required": false,
                            "auth_revocable": false,
                            "auth_immutable": false,
                            "auth_clawback_enabled": false
                        }
                    }
                ]
            }
        }
        """

        let jsonData = assetsJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(PageResponse<AssetResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 1)
        XCTAssertEqual(response.records[0].assetCode, "USD")
        XCTAssertEqual(response.records[0].assetIssuer, "GABC")
    }

    func testParsePageResponseWithTrades() throws {
        let tradesJson = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/trades"}
            },
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon.stellar.org/trades/1"},
                            "base": {"href": "https://horizon.stellar.org/accounts/GABC"},
                            "counter": {"href": "https://horizon.stellar.org/accounts/GDEF"},
                            "operation": {"href": "https://horizon.stellar.org/operations/123"}
                        },
                        "id": "trade1",
                        "paging_token": "trade1",
                        "ledger_close_time": "2024-01-01T00:00:00Z",
                        "offer_id": "1",
                        "base_offer_id": "1",
                        "base_account": "GABC",
                        "base_amount": "100.0000000",
                        "base_asset_type": "native",
                        "counter_offer_id": "2",
                        "counter_account": "GDEF",
                        "counter_amount": "100.0000000",
                        "counter_asset_type": "credit_alphanum4",
                        "counter_asset_code": "USD",
                        "counter_asset_issuer": "GISSUER",
                        "base_is_seller": true,
                        "price": {
                            "n": 1,
                            "d": 1
                        }
                    }
                ]
            }
        }
        """

        let jsonData = tradesJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        let response = try decoder.decode(PageResponse<TradeResponse>.self, from: jsonData)

        XCTAssertEqual(response.records.count, 1)
        XCTAssertEqual(response.records[0].id, "trade1")
        XCTAssertEqual(response.records[0].baseAccount, "GABC")
        XCTAssertEqual(response.records[0].counterAccount, "GDEF")
    }

    func testParsePageResponseMissingEmbedded() {
        let jsonResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon.stellar.org/transactions"}
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testParsePageResponseMissingLinks() {
        let jsonResponse = """
        {
            "_embedded": {
                "records": []
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(PageResponse<TransactionResponse>.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Helper Methods

    private func createMockLinkResponse(href: String, templated: Bool = false) -> LinkResponse {
        let json = """
        {
            "href": "\(href)",
            "templated": \(templated)
        }
        """
        let jsonData = json.data(using: .utf8)!
        return try! JSONDecoder().decode(LinkResponse.self, from: jsonData)
    }

    private func createMockPagingLinksResponse(
        selflink: LinkResponse,
        next: LinkResponse?,
        prev: LinkResponse?
    ) -> PagingLinksResponse {
        var json = "{\n\"self\": {\"href\": \"\(selflink.href)\"}"

        if let next = next {
            json += ",\n\"next\": {\"href\": \"\(next.href)\"}"
        }

        if let prev = prev {
            json += ",\n\"prev\": {\"href\": \"\(prev.href)\"}"
        }

        json += "\n}"

        let jsonData = json.data(using: .utf8)!
        return try! JSONDecoder().decode(PagingLinksResponse.self, from: jsonData)
    }
}
