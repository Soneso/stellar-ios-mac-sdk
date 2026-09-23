//
//  TransactionsServiceUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class TransactionsServiceUnitTests: XCTestCase {
    var sdk: StellarSDK!
    var mockRegistered = false

    override func setUp() {
        super.setUp()
        sdk = StellarSDK()

        if !mockRegistered {
            URLProtocol.registerClass(ServerMock.self)
            mockRegistered = true
        }
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - getTransactions Tests

    func testGetTransactions() async {
        let mockResponse = """
        {
            "_embedded": {
                "records": [
                    {
                        "_links": {
                            "self": {"href": "https://horizon-testnet.stellar.org/transactions/tx1"},
                            "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                            "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/123"},
                            "operations": {"href": "https://horizon-testnet.stellar.org/transactions/tx1/operations"},
                            "effects": {"href": "https://horizon-testnet.stellar.org/transactions/tx1/effects"},
                            "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                            "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
                        },
                        "id": "tx1",
                        "paging_token": "123",
                        "hash": "tx1",
                        "ledger": 123,
                        "created_at": "2022-01-01T00:00:00Z",
                        "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "source_account_sequence": "123",
                        "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
                        "fee_charged": "100",
                        "max_fee": "1000",
                        "operation_count": 1,
                        "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
                        "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
                        "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
                        "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
                        "memo_type": "none",
                        "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
                    }
                ]
            },
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions"},
                "next": {"href": "https://horizon-testnet.stellar.org/transactions?cursor=123"},
                "prev": {"href": "https://horizon-testnet.stellar.org/transactions?cursor=123&order=desc"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions()

        switch response {
        case .success(let page):
            XCTAssertNotNil(page.records)
            XCTAssertEqual(page.records.count, 1)
            XCTAssertEqual(page.records.first?.transactionHash, "tx1")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsWithAllParameters() async {
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return mockResponse
            }
            XCTAssertTrue(url.absoluteString.contains("cursor=test123"))
            XCTAssertTrue(url.absoluteString.contains("order=desc"))
            XCTAssertTrue(url.absoluteString.contains("limit=50"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(cursor: "test123", order: .descending, limit: 50)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsForAccount() async {
        let accountId = "GACCOUNT123"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/accounts/\(accountId)/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/\(accountId)/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(forAccount: accountId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsForAccountWithPagination() async {
        let accountId = "GACCOUNT123"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            guard let url = request.url else {
                XCTFail("Invalid URL")
                return mockResponse
            }
            XCTAssertTrue(url.absoluteString.contains("/accounts/\(accountId)/transactions"))
            XCTAssertTrue(url.absoluteString.contains("cursor=cursor123"))
            XCTAssertTrue(url.absoluteString.contains("order=asc"))
            XCTAssertTrue(url.absoluteString.contains("limit=100"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/accounts/\(accountId)/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(forAccount: accountId, from: "cursor123", order: .ascending, limit: 100)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsForClaimableBalance() async {
        let cbId = "00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/claimable_balances/\(cbId)/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/claimable_balances/\(cbId)/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/claimable_balances/\(cbId)/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(forClaimableBalance: cbId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsForClaimableBalanceWithBPrefix() async {
        let cbIdHex = "00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/claimable_balances/\(cbIdHex)/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/claimable_balances/\(cbIdHex)/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/claimable_balances/\(cbIdHex)/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(forClaimableBalance: cbIdHex)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsForLiquidityPool() async {
        let lpId = "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/liquidity_pools/\(lpId)/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/liquidity_pools/\(lpId)/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/liquidity_pools/\(lpId)/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(forLiquidityPool: lpId)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsForLedger() async {
        let ledger = "12345"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/ledgers/\(ledger)/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/ledgers/\(ledger)/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/ledgers/\(ledger)/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(forLedger: ledger)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsForLedgerLatest() async {
        let ledger = "latest"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/ledgers/\(ledger)/transactions"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/ledgers/\(ledger)/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/ledgers/\(ledger)/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions(forLedger: ledger)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - getTransactionDetails Tests

    func testGetTransactionDetails() async {
        let txHash = "abc123def456"
        let mockResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions/\(txHash)"},
                "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/123"},
                "operations": {"href": "https://horizon-testnet.stellar.org/transactions/\(txHash)/operations"},
                "effects": {"href": "https://horizon-testnet.stellar.org/transactions/\(txHash)/effects"},
                "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "\(txHash)",
            "paging_token": "123",
            "hash": "\(txHash)",
            "ledger": 12345,
            "created_at": "2022-01-01T00:00:00Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 2,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "text",
            "memo": "test memo",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/transactions/\(txHash)"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions/\(txHash)",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactionDetails(transactionHash: txHash)

        switch response {
        case .success(let tx):
            XCTAssertEqual(tx.transactionHash, txHash)
            XCTAssertEqual(tx.ledger, 12345)
            XCTAssertEqual(tx.operationCount, 2)
            XCTAssertEqual(tx.memoType, "text")
            if case .text(let memoText) = tx.memo {
                XCTAssertEqual(memoText, "test memo")
            } else {
                XCTFail("Expected text memo")
            }
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionDetailsNotFound() async {
        let txHash = "notfound123"

        let handler: MockHandler = { mock, request in
            mock.statusCode = 404
            return """
            {
                "type": "https://stellar.org/horizon-errors/not_found",
                "title": "Resource Missing",
                "status": 404,
                "detail": "The resource at the url requested was not found."
            }
            """
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions/\(txHash)",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactionDetails(transactionHash: txHash)

        switch response {
        case .success(_):
            XCTFail("Expected error but got success")
        case .failure(let error):
            switch error {
            case .notFound(_, _):
                XCTAssert(true)
            default:
                XCTFail("Expected notFound error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionDetailsParsingError() async {
        let txHash = "abc123"

        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions/\(txHash)",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactionDetails(transactionHash: txHash)

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(_):
                XCTAssert(true)
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - getTransactionsFromUrl Tests

    func testGetTransactionsFromUrl() async {
        let url = "https://horizon-testnet.stellar.org/transactions?cursor=123"
        let mockResponse = """
        {
            "_embedded": {"records": []},
            "_links": {
                "self": {"href": "\(url)"}
            }
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("cursor=123"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactionsFromUrl(url: url)

        switch response {
        case .success(let page):
            XCTAssertNotNil(page)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - postTransaction Tests

    func testPostTransactionSuccess() async {
        let txEnvelope = "AAAAAgAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKgAAAGQAb4x8AAAAGgAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

        let mockResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions/abc123"},
                "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/12345"},
                "operations": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/operations"},
                "effects": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/effects"},
                "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "abc123",
            "paging_token": "123456",
            "hash": "abc123",
            "ledger": 12345,
            "created_at": "2022-01-01T00:00:00Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123456",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/transactions"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions",
                                     httpMethod: "POST",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.postTransaction(transactionEnvelope: txEnvelope, skipMemoRequiredCheck: true)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
            XCTAssertEqual(result.ledger, 12345)
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPostTransactionWithMemoRequired() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let destAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/data/{key}"}
            },
            "id": "\(destKeyPair.accountId)",
            "account_id": "\(destKeyPair.accountId)",
            "sequence": "123",
            "paging_token": "123",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "1000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(destKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {
                "config.memo_required": "MQ=="
            }
        }
        """

        let accountMock = RequestMock(host: "horizon-testnet.stellar.org",
                                      path: "/accounts/\(destKeyPair.accountId)",
                                      httpMethod: "GET",
                                      mockHandler: { mock, request in
            return destAccountResponse
        })
        ServerMock.add(mock: accountMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let paymentOp = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: false)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: accountMock)
    }

    func testPostTransactionWithMemoRequiredButHasMemo() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let mockResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions/abc123"},
                "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/12345"},
                "operations": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/operations"},
                "effects": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/effects"},
                "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "abc123",
            "paging_token": "123456",
            "hash": "abc123",
            "ledger": 12345,
            "created_at": "2022-01-01T00:00:00Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123456",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """

        let postMock = RequestMock(host: "horizon-testnet.stellar.org",
                                   path: "/transactions",
                                   httpMethod: "POST",
                                   mockHandler: { mock, request in
            return mockResponse
        })
        ServerMock.add(mock: postMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let paymentOp = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: Memo.text("test memo"))
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: false)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: postMock)
    }

    func testPostTransactionAccountNotFound() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let mockResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions/abc123"},
                "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/12345"},
                "operations": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/operations"},
                "effects": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/effects"},
                "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "abc123",
            "paging_token": "123456",
            "hash": "abc123",
            "ledger": 12345,
            "created_at": "2022-01-01T00:00:00Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123456",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """

        let accountMock = RequestMock(host: "horizon-testnet.stellar.org",
                                      path: "/accounts/\(destKeyPair.accountId)",
                                      httpMethod: "GET",
                                      mockHandler: { mock, request in
            mock.statusCode = 404
            return """
            {
                "type": "https://stellar.org/horizon-errors/not_found",
                "title": "Resource Missing",
                "status": 404
            }
            """
        })
        ServerMock.add(mock: accountMock)

        let postMock = RequestMock(host: "horizon-testnet.stellar.org",
                                   path: "/transactions",
                                   httpMethod: "POST",
                                   mockHandler: { mock, request in
            return mockResponse
        })
        ServerMock.add(mock: postMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let paymentOp = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: false)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testPostTransactionTxFailed() async {
        let txEnvelope = "AAAA"

        let handler: MockHandler = { mock, request in
            mock.statusCode = 400
            return """
            {
                "type": "https://stellar.org/horizon-errors/transaction_failed",
                "title": "Transaction Failed",
                "status": 400,
                "detail": "Transaction failed"
            }
            """
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions",
                                     httpMethod: "POST",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.postTransaction(transactionEnvelope: txEnvelope, skipMemoRequiredCheck: true)

        switch response {
        case .success(_):
            XCTFail("Expected error but got success")
        case .destinationRequiresMemo(_):
            XCTFail("Unexpected destinationRequiresMemo")
        case .failure(let error):
            switch error {
            case .badRequest(_, _):
                XCTAssert(true)
            default:
                XCTFail("Expected badRequest error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - postTransactionAsync Tests

    func testPostTransactionAsyncSuccess() async {
        let txEnvelope = "AAAAAgAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKgAAAGQAb4x8AAAAGgAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

        let mockResponse = """
        {
            "tx_status": "PENDING",
            "hash": "abc123",
            "error_result_xdr": null
        }
        """

        let handler: MockHandler = { mock, request in
            XCTAssertTrue(request.url!.absoluteString.contains("/transactions_async"))
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions_async",
                                     httpMethod: "POST",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.postTransactionAsync(transactionEnvelope: txEnvelope, skipMemoRequiredCheck: true)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.txHash, "abc123")
            XCTAssertEqual(result.txStatus, "PENDING")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPostTransactionAsyncWithError() async {
        let txEnvelope = "AAAA"

        let mockResponse = """
        {
            "tx_status": "ERROR",
            "hash": "abc123",
            "error_result_xdr": "AAAA"
        }
        """

        let handler: MockHandler = { mock, request in
            mock.statusCode = 400
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions_async",
                                     httpMethod: "POST",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.postTransactionAsync(transactionEnvelope: txEnvelope, skipMemoRequiredCheck: true)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.txHash, "abc123")
            XCTAssertEqual(result.txStatus, "ERROR")
        case .destinationRequiresMemo(_):
            XCTFail("Unexpected destinationRequiresMemo")
        case .failure(_):
            XCTFail("Expected success with ERROR status but got failure")
        }

        ServerMock.remove(mock: requestMock)
    }

    func testPostTransactionAsyncDuplicate() async {
        let txEnvelope = "AAAA"

        let mockResponse = """
        {
            "tx_status": "DUPLICATE",
            "hash": "abc123",
            "error_result_xdr": null
        }
        """

        let handler: MockHandler = { mock, request in
            mock.statusCode = 409
            return mockResponse
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions_async",
                                     httpMethod: "POST",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.postTransactionAsync(transactionEnvelope: txEnvelope, skipMemoRequiredCheck: true)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.txHash, "abc123")
            XCTAssertEqual(result.txStatus, "DUPLICATE")
        case .destinationRequiresMemo(_):
            XCTFail("Unexpected destinationRequiresMemo")
        case .failure(_):
            XCTFail("Expected success with DUPLICATE status but got failure")
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - submitTransaction Tests

    func testSubmitTransactionSuccess() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let mockResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions/abc123"},
                "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/12345"},
                "operations": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/operations"},
                "effects": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/effects"},
                "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "abc123",
            "paging_token": "123456",
            "hash": "abc123",
            "ledger": 12345,
            "created_at": "2022-01-01T00:00:00Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123456",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """

        let postMock = RequestMock(host: "horizon-testnet.stellar.org",
                                   path: "/transactions",
                                   httpMethod: "POST",
                                   mockHandler: { mock, request in
            return mockResponse
        })
        ServerMock.add(mock: postMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let paymentOp = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: true)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(_):
            XCTFail("Unexpected destinationRequiresMemo")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: postMock)
    }

    // MARK: - submitAsyncTransaction Tests

    func testSubmitAsyncTransactionSuccess() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let mockResponse = """
        {
            "tx_status": "PENDING",
            "hash": "abc123",
            "error_result_xdr": null
        }
        """

        let postMock = RequestMock(host: "horizon-testnet.stellar.org",
                                   path: "/transactions_async",
                                   httpMethod: "POST",
                                   mockHandler: { mock, request in
            return mockResponse
        })
        ServerMock.add(mock: postMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let paymentOp = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitAsyncTransaction(transaction: transaction, skipMemoRequiredCheck: true)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.txHash, "abc123")
            XCTAssertEqual(result.txStatus, "PENDING")
        case .destinationRequiresMemo(_):
            XCTFail("Unexpected destinationRequiresMemo")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: postMock)
    }

    // MARK: - submitFeeBumpTransaction Tests

    func testSubmitFeeBumpTransactionSuccess() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)
        let envelope = try! feeBump.encodedEnvelope()

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: false) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBump)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 1, "the inner transaction's destination is looked up before the fee bump is submitted")
        XCTAssertEqual(postedBodies, [postBody(envelope: envelope)], "the encoded fee bump envelope is posted unchanged")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpTransactionEncodingFailure() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! unencodableFeeBumpPayment(destinationAccountId: destKeyPair.accountId)

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: false) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            guard case .requestFailed(let message, let horizonErrorResponse) = error else {
                return XCTFail("Expected requestFailed but got \(error)")
            }
            XCTAssertEqual(message, "could not encode fee bump transaction")
            XCTAssertNil(horizonErrorResponse)
        }
        XCTAssertEqual(lookupCount, 0, "a fee bump that cannot be encoded fails before any network request")
        XCTAssertTrue(postedBodies.isEmpty, "a fee bump that cannot be encoded is not submitted")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    // MARK: - submitFeeBumpAsyncTransaction Tests

    func testSubmitFeeBumpAsyncTransactionSuccess() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)
        let envelope = try! feeBump.encodedEnvelope()

        var lookupCount = 0
        let accountMock = registerAccountNotFoundMock(accountId: destKeyPair.accountId) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions_async", response: submitTransactionAsyncResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpAsyncTransaction(transaction: feeBump)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.txHash, "abc123")
            XCTAssertEqual(result.txStatus, "PENDING")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 1, "a destination that does not exist yet is looked up once and then skipped")
        XCTAssertEqual(postedBodies, [postBody(envelope: envelope)], "the encoded fee bump envelope is posted unchanged")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpAsyncTransactionEncodingFailure() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! unencodableFeeBumpPayment(destinationAccountId: destKeyPair.accountId)

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: false) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions_async", response: submitTransactionAsyncResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpAsyncTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            guard case .requestFailed(let message, let horizonErrorResponse) = error else {
                return XCTFail("Expected requestFailed but got \(error)")
            }
            XCTAssertEqual(message, "could not encode fee bump transaction")
            XCTAssertNil(horizonErrorResponse)
        }
        XCTAssertEqual(lookupCount, 0, "a fee bump that cannot be encoded fails before any network request")
        XCTAssertTrue(postedBodies.isEmpty, "a fee bump that cannot be encoded is not submitted")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    // MARK: - SEP-29 check on fee bump transactions

    func testSubmitFeeBumpTransactionWithMemoRequired() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)

        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true)
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertTrue(postedBodies.isEmpty, "a fee bump whose inner transaction needs a memo must not be submitted")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpAsyncTransactionWithMemoRequired() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)

        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true)
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions_async", response: submitTransactionAsyncResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpAsyncTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertTrue(postedBodies.isEmpty, "a fee bump whose inner transaction needs a memo must not be submitted")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpTransactionSkipsCheckWhenRequested() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)
        let envelope = try! feeBump.encodedEnvelope()

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBump, skipMemoRequiredCheck: true)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 0, "skipMemoRequiredCheck must suppress the destination lookup")
        XCTAssertEqual(postedBodies, [postBody(envelope: envelope)])

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testPostTransactionWithFeeBumpEnvelopeMemoRequired() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let envelope = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none).encodedEnvelope()

        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true)
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.postTransaction(transactionEnvelope: envelope)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertTrue(postedBodies.isEmpty, "a fee bump envelope whose inner transaction needs a memo must not be submitted")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testPostTransactionAsyncWithFeeBumpEnvelopeMemoRequired() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let envelope = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none).encodedEnvelope()

        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true)
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions_async", response: submitTransactionAsyncResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.postTransactionAsync(transactionEnvelope: envelope)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertTrue(postedBodies.isEmpty, "a fee bump envelope whose inner transaction needs a memo must not be submitted")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpTransactionLookupErrorFailsSubmission() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)

        let accountMock = registerAccountServerErrorMock(accountId: destKeyPair.accountId)
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            guard case .internalServerError(_, _) = error else {
                return XCTFail("Expected internalServerError but got \(error)")
            }
        }
        XCTAssertTrue(postedBodies.isEmpty, "a failed destination lookup other than 404 must not submit the fee bump")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpAsyncTransactionLookupErrorFailsSubmission() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)

        let accountMock = registerAccountServerErrorMock(accountId: destKeyPair.accountId)
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions_async", response: submitTransactionAsyncResponseJson()) { postedBodies.append($0) }

        let response = await sdk.transactions.submitFeeBumpAsyncTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            guard case .internalServerError(_, _) = error else {
                return XCTFail("Expected internalServerError but got \(error)")
            }
        }
        XCTAssertTrue(postedBodies.isEmpty, "a failed destination lookup other than 404 must not submit the fee bump")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    // MARK: - SEP-29 check validates the posted fee bump payload

    func testSubmitFeeBumpTransactionChecksPostedEnvelopeAfterInnerMemoAdded() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        // The fee bump captured the memo-less inner transaction when it was built; setting a
        // memo on the retained inner object afterwards does not change the signed envelope.
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)
        feeBump.innerTransaction.setMemo(memo: Memo.text("customer 42"))
        let postedEnvelopeXdr = try! TransactionEnvelopeXDR(fromBase64: try! feeBump.encodedEnvelope())
        XCTAssertEqual(postedEnvelopeXdr.txMemo.type(), MemoXDR.none.type())

        let response = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 1)
        XCTAssertTrue(postedBodies.isEmpty, "a memo-less posted envelope must not be submitted to a memo-required destination")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpAsyncTransactionChecksPostedEnvelopeAfterInnerMemoAdded() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions_async", response: submitTransactionAsyncResponseJson()) { postedBodies.append($0) }

        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.none)
        feeBump.innerTransaction.setMemo(memo: Memo.text("customer 42"))

        let response = await sdk.transactions.submitFeeBumpAsyncTransaction(transaction: feeBump)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 1)
        XCTAssertTrue(postedBodies.isEmpty, "a memo-less posted envelope must not be submitted to a memo-required destination")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpTransactionAcceptsPostedEnvelopeAfterInnerMemoCleared() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        // The signed envelope carries the memo; clearing it on the retained inner object
        // afterwards does not change what is posted.
        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.text("customer 42"))
        let envelope = try! feeBump.encodedEnvelope()
        feeBump.innerTransaction.setMemo(memo: nil)

        let response = await sdk.transactions.submitFeeBumpTransaction(transaction: feeBump)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 0, "the posted envelope carries a memo, so no lookup is needed")
        XCTAssertEqual(postedBodies, [postBody(envelope: envelope)], "the envelope with the memo is posted unchanged")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testSubmitFeeBumpAsyncTransactionAcceptsPostedEnvelopeAfterInnerMemoCleared() async {
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: true) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions_async", response: submitTransactionAsyncResponseJson()) { postedBodies.append($0) }

        let feeBump = try! feeBumpPayment(destinationAccountId: destKeyPair.accountId, memo: Memo.text("customer 42"))
        let envelope = try! feeBump.encodedEnvelope()
        feeBump.innerTransaction.setMemo(memo: nil)

        let response = await sdk.transactions.submitFeeBumpAsyncTransaction(transaction: feeBump)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.txHash, "abc123")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 0, "the posted envelope carries a memo, so no lookup is needed")
        XCTAssertEqual(postedBodies, [postBody(envelope: envelope)], "the envelope with the memo is posted unchanged")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    // MARK: - stream Tests

    func testStreamForAllTransactions() {
        let streamItem = sdk.transactions.stream(for: .allTransactions(cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testStreamForAllTransactionsWithCursor() {
        let streamItem = sdk.transactions.stream(for: .allTransactions(cursor: "12345"))
        XCTAssertNotNil(streamItem)
    }

    func testStreamForTransactionsForAccount() {
        let accountId = "GACCOUNT123"
        let streamItem = sdk.transactions.stream(for: .transactionsForAccount(account: accountId, cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testStreamForTransactionsForClaimableBalance() {
        let cbId = "00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"
        let streamItem = sdk.transactions.stream(for: .transactionsForClaimableBalance(claimableBalanceId: cbId, cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    func testStreamForTransactionsForLedger() {
        let ledger = "12345"
        let streamItem = sdk.transactions.stream(for: .transactionsForLedger(ledger: ledger, cursor: nil))
        XCTAssertNotNil(streamItem)
    }

    // MARK: - Error Handling Tests

    func testGetTransactionsNetworkError() async {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 500
            return """
            {
                "type": "https://stellar.org/horizon-errors/server_error",
                "title": "Internal Server Error",
                "status": 500
            }
            """
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions()

        switch response {
        case .success(_):
            XCTFail("Expected error but got success")
        case .failure(_):
            XCTAssert(true)
        }

        ServerMock.remove(mock: requestMock)
    }

    func testGetTransactionsParsingError() async {
        let handler: MockHandler = { mock, request in
            return "{ invalid json"
        }

        let requestMock = RequestMock(host: "horizon-testnet.stellar.org",
                                     path: "/transactions",
                                     httpMethod: "GET",
                                     mockHandler: handler)
        ServerMock.add(mock: requestMock)

        let response = await sdk.transactions.getTransactions()

        switch response {
        case .success(_):
            XCTFail("Expected parsing error but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(_):
                XCTAssert(true)
            default:
                XCTFail("Expected parsingResponseFailed error but got: \(error)")
            }
        }

        ServerMock.remove(mock: requestMock)
    }

    // MARK: - SEP-29 destination lookup behavior

    func testCheckMemoRequiredMultipleDestinations() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let dest1KeyPair = try! KeyPair.generateRandomKeyPair()
        let dest2KeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let dest1AccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest1KeyPair.accountId)/data/{key}"}
            },
            "id": "\(dest1KeyPair.accountId)",
            "account_id": "\(dest1KeyPair.accountId)",
            "sequence": "123",
            "paging_token": "123",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "balances": [{"balance": "1000.0000000", "asset_type": "native"}],
            "thresholds": {"low_threshold": 0, "med_threshold": 0, "high_threshold": 0},
            "flags": {"auth_required": false, "auth_revocable": false},
            "signers": [{"key": "\(dest1KeyPair.accountId)", "weight": 1, "type": "ed25519_public_key"}],
            "data": {}
        }
        """

        let dest2AccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(dest2KeyPair.accountId)/data/{key}"}
            },
            "id": "\(dest2KeyPair.accountId)",
            "account_id": "\(dest2KeyPair.accountId)",
            "sequence": "123",
            "paging_token": "123",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "balances": [{"balance": "1000.0000000", "asset_type": "native"}],
            "thresholds": {"low_threshold": 0, "med_threshold": 0, "high_threshold": 0},
            "flags": {"auth_required": false, "auth_revocable": false},
            "signers": [{"key": "\(dest2KeyPair.accountId)", "weight": 1, "type": "ed25519_public_key"}],
            "data": {"config.memo_required": "MQ=="}
        }
        """

        let account1Mock = RequestMock(host: "horizon-testnet.stellar.org",
                                       path: "/accounts/\(dest1KeyPair.accountId)",
                                       httpMethod: "GET",
                                       mockHandler: { mock, request in
            return dest1AccountResponse
        })
        ServerMock.add(mock: account1Mock)

        let account2Mock = RequestMock(host: "horizon-testnet.stellar.org",
                                       path: "/accounts/\(dest2KeyPair.accountId)",
                                       httpMethod: "GET",
                                       mockHandler: { mock, request in
            return dest2AccountResponse
        })
        ServerMock.add(mock: account2Mock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let payment1Op = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: dest1KeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let payment2Op = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: dest2KeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 200.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [payment1Op, payment2Op], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: false)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, dest2KeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: account1Mock)
        ServerMock.remove(mock: account2Mock)
    }

    func testCheckMemoRequiredWithPathPayment() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let destAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/data/{key}"}
            },
            "id": "\(destKeyPair.accountId)",
            "account_id": "\(destKeyPair.accountId)",
            "sequence": "123",
            "paging_token": "123",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "balances": [{"balance": "1000.0000000", "asset_type": "native"}],
            "thresholds": {"low_threshold": 0, "med_threshold": 0, "high_threshold": 0},
            "flags": {"auth_required": false, "auth_revocable": false},
            "signers": [{"key": "\(destKeyPair.accountId)", "weight": 1, "type": "ed25519_public_key"}],
            "data": {"config.memo_required": "MQ=="}
        }
        """

        let accountMock = RequestMock(host: "horizon-testnet.stellar.org",
                                      path: "/accounts/\(destKeyPair.accountId)",
                                      httpMethod: "GET",
                                      mockHandler: { mock, request in
            return destAccountResponse
        })
        ServerMock.add(mock: accountMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let pathPaymentOp = try! PathPaymentOperation(sourceAccountId: nil, sendAsset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, sendMax: 1000.0, destinationAccountId: destKeyPair.accountId, destAsset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, destAmount: 900.0, path: [])
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [pathPaymentOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: false)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: accountMock)
    }

    func testCheckMemoRequiredWithAccountMerge() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let destAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(destKeyPair.accountId)/data/{key}"}
            },
            "id": "\(destKeyPair.accountId)",
            "account_id": "\(destKeyPair.accountId)",
            "sequence": "123",
            "paging_token": "123",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "balances": [{"balance": "1000.0000000", "asset_type": "native"}],
            "thresholds": {"low_threshold": 0, "med_threshold": 0, "high_threshold": 0},
            "flags": {"auth_required": false, "auth_revocable": false},
            "signers": [{"key": "\(destKeyPair.accountId)", "weight": 1, "type": "ed25519_public_key"}],
            "data": {"config.memo_required": "MQ=="}
        }
        """

        let accountMock = RequestMock(host: "horizon-testnet.stellar.org",
                                      path: "/accounts/\(destKeyPair.accountId)",
                                      httpMethod: "GET",
                                      mockHandler: { mock, request in
            return destAccountResponse
        })
        ServerMock.add(mock: accountMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let accountMergeOp = try! AccountMergeOperation(destinationAccountId: destKeyPair.accountId, sourceAccountId: nil)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [accountMergeOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: false)

        switch response {
        case .success(_):
            XCTFail("Expected destinationRequiresMemo but got success")
        case .destinationRequiresMemo(let accountId):
            XCTAssertEqual(accountId, destKeyPair.accountId)
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: accountMock)
    }

    func testCheckMemoRequiredSkipsNonGAddresses() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()

        let sourceAccountResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(sourceKeyPair.accountId)/data/{key}"}
            },
            "id": "\(sourceKeyPair.accountId)",
            "account_id": "\(sourceKeyPair.accountId)",
            "sequence": "12345",
            "paging_token": "12345",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {
                "low_threshold": 0,
                "med_threshold": 0,
                "high_threshold": 0
            },
            "flags": {
                "auth_required": false,
                "auth_revocable": false
            },
            "balances": [
                {
                    "balance": "10000.0000000",
                    "asset_type": "native"
                }
            ],
            "signers": [
                {
                    "key": "\(sourceKeyPair.accountId)",
                    "weight": 1,
                    "type": "ed25519_public_key"
                }
            ],
            "data": {}
        }
        """

        let mockResponse = """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions/abc123"},
                "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/12345"},
                "operations": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/operations"},
                "effects": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/effects"},
                "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "abc123",
            "paging_token": "123456",
            "hash": "abc123",
            "ledger": 12345,
            "created_at": "2022-01-01T00:00:00Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123456",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """

        let postMock = RequestMock(host: "horizon-testnet.stellar.org",
                                   path: "/transactions",
                                   httpMethod: "POST",
                                   mockHandler: { mock, request in
            return mockResponse
        })
        ServerMock.add(mock: postMock)

        let sourceAccount = try! JSONDecoder().decode(AccountResponse.self, from: sourceAccountResponse.data(using: .utf8)!)
        let muxedDest = try! MuxedAccount(accountId: "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK", id: 1234)
        let paymentOp = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: muxedDest.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction, skipMemoRequiredCheck: false)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(_):
            XCTFail("Unexpected destinationRequiresMemo for muxed address")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }

        ServerMock.remove(mock: postMock)
    }

    func testCheckMemoRequiredLooksUpEachDestinationOnce() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        var lookupCount = 0
        let accountMock = registerAccountMock(accountId: destKeyPair.accountId, memoRequired: false) { lookupCount += 1 }
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let sourceAccount = try! Account(accountId: sourceKeyPair.accountId, sequenceNumber: 12345)
        let native = Asset(type: AssetType.ASSET_TYPE_NATIVE)!
        let payment1Op = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: native, amount: 100.0)
        let payment2Op = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: native, amount: 200.0)
        let mergeOp = try! AccountMergeOperation(destinationAccountId: destKeyPair.accountId, sourceAccountId: nil)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [payment1Op, payment2Op, mergeOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction)

        switch response {
        case .success(let result):
            XCTAssertEqual(result.transactionHash, "abc123")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            XCTFail("Request failed: \(error)")
        }
        XCTAssertEqual(lookupCount, 1, "a destination named by several operations is looked up once")
        XCTAssertEqual(postedBodies, [postBody(envelope: try! transaction.encodedEnvelope())])

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    func testCheckMemoRequiredLookupErrorFailsSubmission() async {
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let destKeyPair = try! KeyPair.generateRandomKeyPair()

        let accountMock = registerAccountServerErrorMock(accountId: destKeyPair.accountId)
        var postedBodies = [String]()
        let postMock = registerPostMock(path: "/transactions", response: submitTransactionResponseJson()) { postedBodies.append($0) }

        let sourceAccount = try! Account(accountId: sourceKeyPair.accountId, sequenceNumber: 12345)
        let paymentOp = try! PaymentOperation(sourceAccountId: nil, destinationAccountId: destKeyPair.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try! Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: Memo.none)
        try! transaction.sign(keyPair: sourceKeyPair, network: .testnet)

        let response = await sdk.transactions.submitTransaction(transaction: transaction)

        switch response {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .destinationRequiresMemo(let accountId):
            XCTFail("Unexpected destinationRequiresMemo: \(accountId)")
        case .failure(let error):
            guard case .internalServerError(_, _) = error else {
                return XCTFail("Expected internalServerError but got \(error)")
            }
        }
        XCTAssertTrue(postedBodies.isEmpty, "a failed destination lookup other than 404 must not submit the transaction")

        ServerMock.remove(mock: accountMock)
        ServerMock.remove(mock: postMock)
    }

    // MARK: - SEP-29 test helpers

    /// Builds a signed fee bump around a signed single-payment inner transaction.
    private func feeBumpPayment(destinationAccountId: String, memo: Memo) throws -> FeeBumpTransaction {
        let feeSourceKeyPair = try KeyPair.generateRandomKeyPair()
        let feeSourceMuxed = try MuxedAccount(accountId: feeSourceKeyPair.accountId, id: 0)
        let innerTransaction = try signedPayment(destinationAccountId: destinationAccountId, memo: memo)
        let feeBump = try FeeBumpTransaction(sourceAccount: feeSourceMuxed, fee: 2000, innerTransaction: innerTransaction)
        try feeBump.sign(keyPair: feeSourceKeyPair, network: .testnet)
        return feeBump
    }

    /// Builds an unsigned fee bump whose envelope encoding always throws, around a signed memo-less payment.
    private func unencodableFeeBumpPayment(destinationAccountId: String) throws -> FeeBumpTransaction {
        let feeSourceMuxed = try MuxedAccount(accountId: KeyPair.generateRandomKeyPair().accountId, id: 0)
        let innerTransaction = try signedPayment(destinationAccountId: destinationAccountId, memo: Memo.none)
        return try UnencodableFeeBumpTransaction(sourceAccount: feeSourceMuxed, fee: 2000, innerTransaction: innerTransaction)
    }

    /// Builds a signed single-payment transaction from a random source account.
    private func signedPayment(destinationAccountId: String, memo: Memo) throws -> Transaction {
        let sourceKeyPair = try KeyPair.generateRandomKeyPair()
        let sourceAccount = try Account(accountId: sourceKeyPair.accountId, sequenceNumber: 12345)
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destinationAccountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: sourceAccount, operations: [paymentOp], memo: memo)
        try transaction.sign(keyPair: sourceKeyPair, network: .testnet)
        return transaction
    }

    /// Form body that the SDK posts to Horizon for the given envelope.
    private func postBody(envelope: String) -> String {
        return "tx=" + envelope.urlEncoded!
    }

    /// Registers a `GET /accounts/{accountId}` mock answering with the account, with or without
    /// the SEP-29 data entry. `onLookup` runs once per request.
    private func registerAccountMock(accountId: String, memoRequired: Bool, onLookup: @escaping () -> Void = {}) -> RequestMock {
        let body = accountResponseJson(accountId: accountId, memoRequired: memoRequired)
        return registerAccountLookupMock(accountId: accountId, statusCode: 200, body: body, onLookup: onLookup)
    }

    /// Registers a `GET /accounts/{accountId}` mock answering with Horizon's 404 problem response.
    private func registerAccountNotFoundMock(accountId: String, onLookup: @escaping () -> Void) -> RequestMock {
        let body = horizonProblemJson(type: "not_found", title: "Resource Missing", status: 404)
        return registerAccountLookupMock(accountId: accountId, statusCode: 404, body: body, onLookup: onLookup)
    }

    /// Registers a `GET /accounts/{accountId}` mock answering with Horizon's 500 problem response.
    private func registerAccountServerErrorMock(accountId: String) -> RequestMock {
        let body = horizonProblemJson(type: "server_error", title: "Internal Server Error", status: 500)
        return registerAccountLookupMock(accountId: accountId, statusCode: 500, body: body, onLookup: {})
    }

    private func registerAccountLookupMock(accountId: String, statusCode: Int, body: String, onLookup: @escaping () -> Void) -> RequestMock {
        let mock = RequestMock(host: "horizon-testnet.stellar.org",
                               path: "/accounts/\(accountId)",
                               httpMethod: "GET",
                               statusCode: statusCode,
                               mockHandler: { mock, request in
            onLookup()
            return body
        })
        ServerMock.add(mock: mock)
        return mock
    }

    /// Registers a `POST` mock on `path` answering with `response`. `onPost` receives the form
    /// body of every request.
    private func registerPostMock(path: String, response: String, onPost: @escaping (String) -> Void) -> RequestMock {
        let mock = RequestMock(host: "horizon-testnet.stellar.org",
                               path: path,
                               httpMethod: "POST",
                               mockHandler: { mock, request in
            let bodyData = request.httpBody ?? request.httpBodyStream?.readfully() ?? Data()
            onPost(String(decoding: bodyData, as: UTF8.self))
            return response
        })
        ServerMock.add(mock: mock)
        return mock
    }

    /// Horizon problem response body.
    private func horizonProblemJson(type: String, title: String, status: Int) -> String {
        return """
        {
            "type": "https://stellar.org/horizon-errors/\(type)",
            "title": "\(title)",
            "status": \(status)
        }
        """
    }

    /// Horizon account response with or without the SEP-29 data entry.
    private func accountResponseJson(accountId: String, memoRequired: Bool) -> String {
        let data = memoRequired ? "{\"config.memo_required\": \"MQ==\"}" : "{}"
        return """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)"},
                "transactions": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/transactions"},
                "operations": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/operations"},
                "payments": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/payments"},
                "effects": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/effects"},
                "offers": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/offers"},
                "trades": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/trades"},
                "data": {"href": "https://horizon-testnet.stellar.org/accounts/\(accountId)/data/{key}"}
            },
            "id": "\(accountId)",
            "account_id": "\(accountId)",
            "sequence": "123",
            "paging_token": "123",
            "subentry_count": 0,
            "last_modified_ledger": 123,
            "thresholds": {"low_threshold": 0, "med_threshold": 0, "high_threshold": 0},
            "flags": {"auth_required": false, "auth_revocable": false},
            "balances": [{"balance": "1000.0000000", "asset_type": "native"}],
            "signers": [{"key": "\(accountId)", "weight": 1, "type": "ed25519_public_key"}],
            "data": \(data)
        }
        """
    }

    /// Horizon response for a successful synchronous submission with hash "abc123".
    private func submitTransactionResponseJson() -> String {
        return """
        {
            "_links": {
                "self": {"href": "https://horizon-testnet.stellar.org/transactions/abc123"},
                "account": {"href": "https://horizon-testnet.stellar.org/accounts/GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN"},
                "ledger": {"href": "https://horizon-testnet.stellar.org/ledgers/12345"},
                "operations": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/operations"},
                "effects": {"href": "https://horizon-testnet.stellar.org/transactions/abc123/effects"},
                "precedes": {"href": "https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123"},
                "succeeds": {"href": "https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123"}
            },
            "id": "abc123",
            "paging_token": "123456",
            "hash": "abc123",
            "ledger": 12345,
            "created_at": "2022-01-01T00:00:00Z",
            "source_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "source_account_sequence": "123456",
            "fee_account": "GAJNSTFWKUKRXAHMPWG6BM4ACWNIS57S47KQZZQGQCM6H4WTM7VQUFMN",
            "fee_charged": "100",
            "max_fee": "1000",
            "operation_count": 1,
            "envelope_xdr": "AAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAZABvjHwAAAAaAAAAAAAAAAAAAAABAAAAAAAAAAYAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAWNFeF2KAAAAAAAAAAAAAdNn6woAAABA9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA==",
            "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAGAAAAAAAAAAA=",
            "result_meta_xdr": "AAAAAAAAAAEAAAACAAAAAwByfvQAAAABAAAAABLZTLZVFRuA7H2N4LOAFZqJd/Ln1QzmBoCZ4/LTZ+sKAAAAAkNVMTIzNDUAAAAAAAAAAADCNRuYfsuu8hj80NlwpL2PoOX92DooImALUaIrBaR1owAAAAAADDUAAWNFeF2KAAAAAAABAAAAAAAAAAAAAAABAHKFHQAAAAEAAAAAEtlMtlUVG4DsfY3gs4AVmol38ufVDOYGgJnj8tNn6woAAAACQ1UxMjM0NQAAAAAAAAAAAMI1G5h+y67yGPzQ2XCkvY+g5f3YOigiYAtRoisFpHWjAAAAAAAMNQABY0V4XYoAAAAAAAEAAAAAAAAAAA==",
            "fee_meta_xdr": "AAAAAgAAAAMAcoFaAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt10AG+MfAAAABkAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAcoUdAAAAAAAAAAAS2Uy2VRUbgOx9jeCzgBWaiXfy59UM5gaAmePy02frCgAAABdIdt0QAG+MfAAAABoAAAAFAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
            "memo_type": "none",
            "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """
    }

    /// Horizon response for an async submission accepted as PENDING with hash "abc123".
    private func submitTransactionAsyncResponseJson() -> String {
        return """
        {
            "tx_status": "PENDING",
            "hash": "abc123",
            "error_result_xdr": null
        }
        """
    }
}

/// Fee bump whose envelope encoding fails, for the encoding-failure path of the submit methods.
private final class UnencodableFeeBumpTransaction: FeeBumpTransaction, @unchecked Sendable {
    override func encodedEnvelope() throws -> String {
        throw StellarSDKError.encodingError(message: "envelope encoding failed")
    }
}
