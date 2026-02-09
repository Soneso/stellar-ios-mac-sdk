//
//  SorobanFiltersResponsesUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class SorobanFiltersResponsesUnitTests: XCTestCase {

    // MARK: - EventFilter Tests

    func testEventFilterInitialization() {
        let filter = EventFilter(type: "contract", contractIds: ["CCONTRACT1", "CCONTRACT2"], topics: nil)
        XCTAssertEqual(filter.type, "contract")
        XCTAssertEqual(filter.contractIds?.count, 2)
        XCTAssertNil(filter.topics)
    }

    func testEventFilterInitializationWithAllNil() {
        let filter = EventFilter()
        XCTAssertNil(filter.type)
        XCTAssertNil(filter.contractIds)
        XCTAssertNil(filter.topics)
    }

    func testEventFilterBuildRequestParamsWithType() {
        let filter = EventFilter(type: "system")
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "system")
        XCTAssertNil(params["contractIds"])
        XCTAssertNil(params["topics"])
    }

    func testEventFilterBuildRequestParamsWithContractIds() {
        let filter = EventFilter(type: "contract", contractIds: ["CCONTRACT1", "CCONTRACT2", "CCONTRACT3"])
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "contract")
        let contractIds = params["contractIds"] as? [String]
        XCTAssertNotNil(contractIds)
        XCTAssertEqual(contractIds?.count, 3)
        XCTAssertEqual(contractIds?[0], "CCONTRACT1")
        XCTAssertEqual(contractIds?[1], "CCONTRACT2")
        XCTAssertEqual(contractIds?[2], "CCONTRACT3")
    }

    func testEventFilterBuildRequestParamsWithEmptyContractIds() {
        let filter = EventFilter(type: "contract", contractIds: [])
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "contract")
        XCTAssertNil(params["contractIds"])
    }

    func testEventFilterBuildRequestParamsWithTopics() {
        let topic1 = TopicFilter(segmentMatchers: ["transfer", "*", "GADDR1"])
        let topic2 = TopicFilter(segmentMatchers: ["mint", "GADDR2"])
        let filter = EventFilter(type: "contract", contractIds: nil, topics: [topic1, topic2])
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "contract")
        let topics = params["topics"] as? [[String]]
        XCTAssertNotNil(topics)
        XCTAssertEqual(topics?.count, 2)
        XCTAssertEqual(topics?[0], ["transfer", "*", "GADDR1"])
        XCTAssertEqual(topics?[1], ["mint", "GADDR2"])
    }

    func testEventFilterBuildRequestParamsWithEmptyTopics() {
        let filter = EventFilter(type: "contract", contractIds: nil, topics: [])
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "contract")
        XCTAssertNil(params["topics"])
    }

    func testEventFilterBuildRequestParamsWithAllParameters() {
        let topic = TopicFilter(segmentMatchers: ["transfer"])
        let filter = EventFilter(type: "contract", contractIds: ["CCONTRACT1"], topics: [topic])
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "contract")
        XCTAssertNotNil(params["contractIds"])
        XCTAssertNotNil(params["topics"])
    }

    // MARK: - PaginationOptions Tests

    func testPaginationOptionsInitialization() {
        let options = PaginationOptions(cursor: "1234567890", limit: 100)
        XCTAssertEqual(options.cursor, "1234567890")
        XCTAssertEqual(options.limit, 100)
    }

    func testPaginationOptionsInitializationWithAllNil() {
        let options = PaginationOptions()
        XCTAssertNil(options.cursor)
        XCTAssertNil(options.limit)
    }

    func testPaginationOptionsInitializationWithCursorOnly() {
        let options = PaginationOptions(cursor: "cursor123")
        XCTAssertEqual(options.cursor, "cursor123")
        XCTAssertNil(options.limit)
    }

    func testPaginationOptionsInitializationWithLimitOnly() {
        let options = PaginationOptions(limit: 50)
        XCTAssertNil(options.cursor)
        XCTAssertEqual(options.limit, 50)
    }

    func testPaginationOptionsBuildRequestParamsWithBoth() {
        let options = PaginationOptions(cursor: "cursor456", limit: 200)
        let params = options.buildRequestParams()

        XCTAssertEqual(params["cursor"] as? String, "cursor456")
        XCTAssertEqual(params["limit"] as? Int, 200)
    }

    func testPaginationOptionsBuildRequestParamsWithCursorOnly() {
        let options = PaginationOptions(cursor: "cursor789")
        let params = options.buildRequestParams()

        XCTAssertEqual(params["cursor"] as? String, "cursor789")
        XCTAssertNil(params["limit"])
    }

    func testPaginationOptionsBuildRequestParamsWithLimitOnly() {
        let options = PaginationOptions(limit: 25)
        let params = options.buildRequestParams()

        XCTAssertNil(params["cursor"])
        XCTAssertEqual(params["limit"] as? Int, 25)
    }

    func testPaginationOptionsBuildRequestParamsWithNone() {
        let options = PaginationOptions()
        let params = options.buildRequestParams()

        XCTAssertTrue(params.isEmpty)
    }

    // MARK: - ResourceConfig Tests

    func testResourceConfigInitialization() {
        let config = ResourceConfig(instructionLeeway: 1000000)
        XCTAssertEqual(config.instructionLeeway, 1000000)
    }

    func testResourceConfigInitializationWithZero() {
        let config = ResourceConfig(instructionLeeway: 0)
        XCTAssertEqual(config.instructionLeeway, 0)
    }

    func testResourceConfigInitializationWithLargeValue() {
        let config = ResourceConfig(instructionLeeway: 10000000)
        XCTAssertEqual(config.instructionLeeway, 10000000)
    }

    func testResourceConfigBuildRequestParams() {
        let config = ResourceConfig(instructionLeeway: 5000000)
        let params = config.buildRequestParams()

        XCTAssertEqual(params["instructionLeeway"] as? Int, 5000000)
    }

    func testResourceConfigBuildRequestParamsWithZero() {
        let config = ResourceConfig(instructionLeeway: 0)
        let params = config.buildRequestParams()

        XCTAssertEqual(params["instructionLeeway"] as? Int, 0)
    }

    // MARK: - SegmentFilter Tests

    func testSegmentFilterInitializationWithWildcard() {
        let filter = SegmentFilter(wildcard: "*")
        XCTAssertEqual(filter.wildcard, "*")
        XCTAssertNil(filter.scval)
    }

    func testSegmentFilterInitializationWithScval() throws {
        let val1 = SCValXDR.u32(12345)
        let val2 = SCValXDR.u32(67890)
        let filter = SegmentFilter(scval: [val1, val2])

        XCTAssertNil(filter.wildcard)
        XCTAssertEqual(filter.scval?.count, 2)
    }

    func testSegmentFilterInitializationWithBoth() throws {
        let val = SCValXDR.u32(12345)
        let filter = SegmentFilter(wildcard: "*", scval: [val])

        XCTAssertEqual(filter.wildcard, "*")
        XCTAssertEqual(filter.scval?.count, 1)
    }

    func testSegmentFilterInitializationWithNone() {
        let filter = SegmentFilter()
        XCTAssertNil(filter.wildcard)
        XCTAssertNil(filter.scval)
    }

    func testSegmentFilterBuildRequestParamsWithWildcard() {
        let filter = SegmentFilter(wildcard: "*")
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["wildcard"] as? String, "*")
        XCTAssertNil(params["scval"])
    }

    func testSegmentFilterBuildRequestParamsWithScval() throws {
        let val1 = SCValXDR.u32(12345)
        let val2 = SCValXDR.i32(-67890)
        let filter = SegmentFilter(scval: [val1, val2])
        let params = filter.buildRequestParams()

        XCTAssertNil(params["wildcard"])
        let scvalArray = params["scval"] as? [String]
        XCTAssertNotNil(scvalArray)
        XCTAssertEqual(scvalArray?.count, 2)
    }

    func testSegmentFilterBuildRequestParamsWithEmptyScval() {
        let filter = SegmentFilter(scval: [])
        let params = filter.buildRequestParams()

        XCTAssertNil(params["wildcard"])
        XCTAssertNil(params["scval"])
    }

    func testSegmentFilterBuildRequestParamsWithNone() {
        let filter = SegmentFilter()
        let params = filter.buildRequestParams()

        XCTAssertTrue(params.isEmpty)
    }

    func testSegmentFilterBuildRequestParamsWithVariousScvalTypes() throws {
        let val1 = SCValXDR.bool(true)
        let val2 = SCValXDR.u32(100)
        let val3 = SCValXDR.i64(-200)
        let filter = SegmentFilter(scval: [val1, val2, val3])
        let params = filter.buildRequestParams()

        let scvalArray = params["scval"] as? [String]
        XCTAssertNotNil(scvalArray)
        XCTAssertEqual(scvalArray?.count, 3)

        // Verify all values are base64 encoded
        for val in scvalArray ?? [] {
            XCTAssertFalse(val.isEmpty)
        }
    }

    // MARK: - SimulateTransactionRequest Tests

    func testSimulateTransactionRequestInitialization() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)

        let request = SimulateTransactionRequest(transaction: transaction)

        XCTAssertNotNil(request.transaction)
        XCTAssertNil(request.resourceConfig)
        XCTAssertNil(request.authMode)
    }

    func testSimulateTransactionRequestInitializationWithResourceConfig() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)
        let resourceConfig = ResourceConfig(instructionLeeway: 3000000)

        let request = SimulateTransactionRequest(transaction: transaction, resourceConfig: resourceConfig)

        XCTAssertNotNil(request.transaction)
        XCTAssertNotNil(request.resourceConfig)
        XCTAssertEqual(request.resourceConfig?.instructionLeeway, 3000000)
        XCTAssertNil(request.authMode)
    }

    func testSimulateTransactionRequestInitializationWithAuthMode() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)

        let request = SimulateTransactionRequest(transaction: transaction, authMode: "enforce")

        XCTAssertNotNil(request.transaction)
        XCTAssertNil(request.resourceConfig)
        XCTAssertEqual(request.authMode, "enforce")
    }

    func testSimulateTransactionRequestInitializationWithAllParameters() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)
        let resourceConfig = ResourceConfig(instructionLeeway: 5000000)

        let request = SimulateTransactionRequest(transaction: transaction, resourceConfig: resourceConfig, authMode: "record")

        XCTAssertNotNil(request.transaction)
        XCTAssertNotNil(request.resourceConfig)
        XCTAssertEqual(request.resourceConfig?.instructionLeeway, 5000000)
        XCTAssertEqual(request.authMode, "record")
    }

    func testSimulateTransactionRequestBuildRequestParams() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)

        let request = SimulateTransactionRequest(transaction: transaction)
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertNil(params["resourceConfig"])
        XCTAssertNil(params["authMode"])
    }

    func testSimulateTransactionRequestBuildRequestParamsWithResourceConfig() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)
        let resourceConfig = ResourceConfig(instructionLeeway: 2000000)

        let request = SimulateTransactionRequest(transaction: transaction, resourceConfig: resourceConfig)
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertNotNil(params["resourceConfig"])
        let rcParams = params["resourceConfig"] as? [String: Any]
        XCTAssertEqual(rcParams?["instructionLeeway"] as? Int, 2000000)
        XCTAssertNil(params["authMode"])
    }

    func testSimulateTransactionRequestBuildRequestParamsWithAuthMode() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)

        let request = SimulateTransactionRequest(transaction: transaction, authMode: "record_allow_nonroot")
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertNil(params["resourceConfig"])
        XCTAssertEqual(params["authMode"] as? String, "record_allow_nonroot")
    }

    func testSimulateTransactionRequestBuildRequestParamsWithAllParameters() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!, amount: 100.0)
        let transaction = try Transaction(sourceAccount: account, operations: [paymentOp], memo: Memo.none)
        let resourceConfig = ResourceConfig(instructionLeeway: 4000000)

        let request = SimulateTransactionRequest(transaction: transaction, resourceConfig: resourceConfig, authMode: "enforce")
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertNotNil(params["resourceConfig"])
        XCTAssertNotNil(params["authMode"])

        let rcParams = params["resourceConfig"] as? [String: Any]
        XCTAssertEqual(rcParams?["instructionLeeway"] as? Int, 4000000)
        XCTAssertEqual(params["authMode"] as? String, "enforce")
    }

    // MARK: - TopicFilter Tests

    func testTopicFilterInitialization() {
        let filter = TopicFilter(segmentMatchers: ["transfer", "*", "GADDR1"])
        XCTAssertEqual(filter.segmentMatchers.count, 3)
        XCTAssertEqual(filter.segmentMatchers[0], "transfer")
        XCTAssertEqual(filter.segmentMatchers[1], "*")
        XCTAssertEqual(filter.segmentMatchers[2], "GADDR1")
    }

    func testTopicFilterInitializationWithSingleMatcher() {
        let filter = TopicFilter(segmentMatchers: ["mint"])
        XCTAssertEqual(filter.segmentMatchers.count, 1)
        XCTAssertEqual(filter.segmentMatchers[0], "mint")
    }

    func testTopicFilterInitializationWithEmptyArray() {
        let filter = TopicFilter(segmentMatchers: [])
        XCTAssertEqual(filter.segmentMatchers.count, 0)
    }

    func testTopicFilterInitializationWithMultipleWildcards() {
        let filter = TopicFilter(segmentMatchers: ["*", "*", "*"])
        XCTAssertEqual(filter.segmentMatchers.count, 3)
        XCTAssertEqual(filter.segmentMatchers[0], "*")
        XCTAssertEqual(filter.segmentMatchers[1], "*")
        XCTAssertEqual(filter.segmentMatchers[2], "*")
    }

    func testTopicFilterInitializationWithMixedPatterns() {
        let filter = TopicFilter(segmentMatchers: ["transfer", "GADDR1", "*", "GADDR2"])
        XCTAssertEqual(filter.segmentMatchers.count, 4)
        XCTAssertEqual(filter.segmentMatchers[0], "transfer")
        XCTAssertEqual(filter.segmentMatchers[1], "GADDR1")
        XCTAssertEqual(filter.segmentMatchers[2], "*")
        XCTAssertEqual(filter.segmentMatchers[3], "GADDR2")
    }

    // MARK: - GetLedgersResponse Tests

    func testGetLedgersResponseDecoding() throws {
        let json = """
        {
            "ledgers": [
                {
                    "hash": "a1b2c3d4e5f6",
                    "sequence": 1000000,
                    "ledgerCloseTime": "1700000000",
                    "headerXdr": "AAAAAAAAAAA=",
                    "metadataXdr": "BBBBBBBBBBB="
                },
                {
                    "hash": "f6e5d4c3b2a1",
                    "sequence": 1000001,
                    "ledgerCloseTime": "1700000005",
                    "headerXdr": "CCCCCCCCCCC=",
                    "metadataXdr": "DDDDDDDDDDD="
                }
            ],
            "latestLedger": 1000100,
            "latestLedgerCloseTime": 1700001000,
            "oldestLedger": 900000,
            "oldestLedgerCloseTime": 1690000000,
            "cursor": "cursor123456"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetLedgersResponse.self, from: jsonData)

        XCTAssertEqual(response.ledgers.count, 2)
        XCTAssertEqual(response.ledgers[0].ledgerHash, "a1b2c3d4e5f6")
        XCTAssertEqual(response.ledgers[0].sequence, 1000000)
        XCTAssertEqual(response.ledgers[0].ledgerCloseTime, "1700000000")
        XCTAssertEqual(response.ledgers[0].headerXdr, "AAAAAAAAAAA=")
        XCTAssertEqual(response.ledgers[0].metadataXdr, "BBBBBBBBBBB=")

        XCTAssertEqual(response.ledgers[1].ledgerHash, "f6e5d4c3b2a1")
        XCTAssertEqual(response.ledgers[1].sequence, 1000001)
        XCTAssertEqual(response.ledgers[1].ledgerCloseTime, "1700000005")
        XCTAssertEqual(response.ledgers[1].headerXdr, "CCCCCCCCCCC=")
        XCTAssertEqual(response.ledgers[1].metadataXdr, "DDDDDDDDDDD=")

        XCTAssertEqual(response.latestLedger, 1000100)
        XCTAssertEqual(response.latestLedgerCloseTime, 1700001000)
        XCTAssertEqual(response.oldestLedger, 900000)
        XCTAssertEqual(response.oldestLedgerCloseTime, 1690000000)
        XCTAssertEqual(response.cursor, "cursor123456")
    }

    func testGetLedgersResponseDecodingWithEmptyLedgers() throws {
        let json = """
        {
            "ledgers": [],
            "latestLedger": 1000100,
            "latestLedgerCloseTime": 1700001000,
            "oldestLedger": 900000,
            "oldestLedgerCloseTime": 1690000000,
            "cursor": "cursor789"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetLedgersResponse.self, from: jsonData)

        XCTAssertEqual(response.ledgers.count, 0)
        XCTAssertEqual(response.latestLedger, 1000100)
        XCTAssertEqual(response.cursor, "cursor789")
    }

    func testGetLedgersResponseDecodingWithOptionalFieldsMissing() throws {
        let json = """
        {
            "ledgers": [
                {
                    "hash": "a1b2c3d4e5f6",
                    "sequence": 1000000,
                    "ledgerCloseTime": "1700000000"
                }
            ],
            "latestLedger": 1000100,
            "latestLedgerCloseTime": 1700001000,
            "oldestLedger": 900000,
            "oldestLedgerCloseTime": 1690000000,
            "cursor": "cursor123"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetLedgersResponse.self, from: jsonData)

        XCTAssertEqual(response.ledgers.count, 1)
        XCTAssertNil(response.ledgers[0].headerXdr)
        XCTAssertNil(response.ledgers[0].metadataXdr)
    }

    // MARK: - GetTransactionsResponse Tests

    func testGetTransactionsResponseDecoding() throws {
        let json = """
        {
            "transactions": [
                {
                    "status": "SUCCESS",
                    "applicationOrder": 1,
                    "feeBump": false,
                    "envelopeXdr": "AAAAAAAAAA==",
                    "resultXdr": "BBBBBBBBBB==",
                    "resultMetaXdr": "CCCCCCCCCC==",
                    "ledger": 1000000,
                    "createdAt": 1700000000,
                    "txHash": "abc123def456"
                }
            ],
            "latestLedger": 1000100,
            "latestLedgerCloseTimestamp": 1700001000,
            "oldestLedger": 900000,
            "oldestLedgerCloseTimestamp": 1690000000,
            "cursor": "cursor123"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetTransactionsResponse.self, from: jsonData)

        XCTAssertEqual(response.transactions.count, 1)
        XCTAssertEqual(response.transactions[0].status, "SUCCESS")
        XCTAssertEqual(response.transactions[0].applicationOrder, 1)
        XCTAssertEqual(response.transactions[0].feeBump, false)
        XCTAssertEqual(response.transactions[0].envelopeXdr, "AAAAAAAAAA==")
        XCTAssertEqual(response.transactions[0].resultXdr, "BBBBBBBBBB==")
        XCTAssertEqual(response.transactions[0].resultMetaXdr, "CCCCCCCCCC==")
        XCTAssertEqual(response.transactions[0].ledger, 1000000)
        XCTAssertEqual(response.transactions[0].createdAt, 1700000000)
        XCTAssertEqual(response.transactions[0].txHash, "abc123def456")

        XCTAssertEqual(response.latestLedger, 1000100)
        XCTAssertEqual(response.latestLedgerCloseTimestamp, 1700001000)
        XCTAssertEqual(response.oldestLedger, 900000)
        XCTAssertEqual(response.oldestLedgerCloseTimestamp, 1690000000)
        XCTAssertEqual(response.cursor, "cursor123")
    }

    func testGetTransactionsResponseDecodingWithEmptyTransactions() throws {
        let json = """
        {
            "transactions": [],
            "latestLedger": 1000100,
            "latestLedgerCloseTimestamp": 1700001000,
            "oldestLedger": 900000,
            "oldestLedgerCloseTimestamp": 1690000000
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetTransactionsResponse.self, from: jsonData)

        XCTAssertEqual(response.transactions.count, 0)
        XCTAssertNil(response.cursor)
    }

    func testGetTransactionsResponseDecodingWithMultipleTransactions() throws {
        let json = """
        {
            "transactions": [
                {
                    "status": "SUCCESS",
                    "applicationOrder": 1,
                    "feeBump": false,
                    "envelopeXdr": "AAAA",
                    "resultXdr": "BBBB",
                    "resultMetaXdr": "CCCC",
                    "ledger": 1000000,
                    "createdAt": 1700000000
                },
                {
                    "status": "FAILED",
                    "applicationOrder": 2,
                    "feeBump": true,
                    "envelopeXdr": "DDDD",
                    "resultXdr": "EEEE",
                    "resultMetaXdr": "FFFF",
                    "ledger": 1000000,
                    "createdAt": 1700000001
                }
            ],
            "latestLedger": 1000100,
            "latestLedgerCloseTimestamp": 1700001000,
            "oldestLedger": 900000,
            "oldestLedgerCloseTimestamp": 1690000000,
            "cursor": "cursor456"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetTransactionsResponse.self, from: jsonData)

        XCTAssertEqual(response.transactions.count, 2)
        XCTAssertEqual(response.transactions[0].status, "SUCCESS")
        XCTAssertEqual(response.transactions[0].feeBump, false)
        XCTAssertEqual(response.transactions[1].status, "FAILED")
        XCTAssertEqual(response.transactions[1].feeBump, true)
    }

    // MARK: - TransactionInfo Tests

    func testTransactionInfoDecodingWithAllFields() throws {
        let json = """
        {
            "status": "SUCCESS",
            "applicationOrder": 1,
            "feeBump": false,
            "envelopeXdr": "AAAAAAAAAA==",
            "resultXdr": "BBBBBBBBBB==",
            "resultMetaXdr": "CCCCCCCCCC==",
            "diagnosticEventsXdr": ["DDDD", "EEEE"],
            "ledger": 1000000,
            "createdAt": 1700000000,
            "txHash": "abc123",
            "events": {
                "diagnosticEventsXdr": ["FFFF"],
                "transactionEventsXdr": ["GGGG"],
                "contractEventsXdr": [["HHHH", "IIII"]]
            }
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let txInfo = try decoder.decode(TransactionInfo.self, from: jsonData)

        XCTAssertEqual(txInfo.status, "SUCCESS")
        XCTAssertEqual(txInfo.applicationOrder, 1)
        XCTAssertEqual(txInfo.feeBump, false)
        XCTAssertEqual(txInfo.envelopeXdr, "AAAAAAAAAA==")
        XCTAssertEqual(txInfo.resultXdr, "BBBBBBBBBB==")
        XCTAssertEqual(txInfo.resultMetaXdr, "CCCCCCCCCC==")
        XCTAssertEqual(txInfo.diagnosticEventsXdr?.count, 2)
        XCTAssertEqual(txInfo.diagnosticEventsXdr?[0], "DDDD")
        XCTAssertEqual(txInfo.diagnosticEventsXdr?[1], "EEEE")
        XCTAssertEqual(txInfo.ledger, 1000000)
        XCTAssertEqual(txInfo.createdAt, 1700000000)
        XCTAssertEqual(txInfo.txHash, "abc123")
        XCTAssertNotNil(txInfo.events)
    }

    func testTransactionInfoDecodingWithOptionalFieldsMissing() throws {
        let json = """
        {
            "status": "FAILED",
            "applicationOrder": 2,
            "feeBump": true,
            "envelopeXdr": "AAAA",
            "resultXdr": "BBBB",
            "resultMetaXdr": "CCCC",
            "ledger": 1000001,
            "createdAt": 1700000001
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let txInfo = try decoder.decode(TransactionInfo.self, from: jsonData)

        XCTAssertEqual(txInfo.status, "FAILED")
        XCTAssertEqual(txInfo.applicationOrder, 2)
        XCTAssertEqual(txInfo.feeBump, true)
        XCTAssertNil(txInfo.diagnosticEventsXdr)
        XCTAssertNil(txInfo.txHash)
        XCTAssertNil(txInfo.events)
    }

    func testTransactionInfoDecodingWithCreatedAtAsString() throws {
        let json = """
        {
            "status": "SUCCESS",
            "applicationOrder": 1,
            "feeBump": false,
            "envelopeXdr": "AAAA",
            "resultXdr": "BBBB",
            "resultMetaXdr": "CCCC",
            "ledger": 1000000,
            "createdAt": "1700000000"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let txInfo = try decoder.decode(TransactionInfo.self, from: jsonData)

        XCTAssertEqual(txInfo.createdAt, 1700000000)
    }

    func testTransactionInfoDecodingWithCreatedAtAsInt() throws {
        let json = """
        {
            "status": "SUCCESS",
            "applicationOrder": 1,
            "feeBump": false,
            "envelopeXdr": "AAAA",
            "resultXdr": "BBBB",
            "resultMetaXdr": "CCCC",
            "ledger": 1000000,
            "createdAt": 1700000000
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let txInfo = try decoder.decode(TransactionInfo.self, from: jsonData)

        XCTAssertEqual(txInfo.createdAt, 1700000000)
    }

    // MARK: - LedgerInfo Tests

    func testLedgerInfoDecodingWithAllFields() throws {
        let json = """
        {
            "hash": "a1b2c3d4e5f6",
            "sequence": 1000000,
            "ledgerCloseTime": "1700000000",
            "headerXdr": "AAAAAAAAAAA=",
            "metadataXdr": "BBBBBBBBBBB="
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let ledgerInfo = try decoder.decode(LedgerInfo.self, from: jsonData)

        XCTAssertEqual(ledgerInfo.ledgerHash, "a1b2c3d4e5f6")
        XCTAssertEqual(ledgerInfo.sequence, 1000000)
        XCTAssertEqual(ledgerInfo.ledgerCloseTime, "1700000000")
        XCTAssertEqual(ledgerInfo.headerXdr, "AAAAAAAAAAA=")
        XCTAssertEqual(ledgerInfo.metadataXdr, "BBBBBBBBBBB=")
    }

    func testLedgerInfoDecodingWithOptionalFieldsMissing() throws {
        let json = """
        {
            "hash": "a1b2c3d4e5f6",
            "sequence": 1000000,
            "ledgerCloseTime": "1700000000"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let ledgerInfo = try decoder.decode(LedgerInfo.self, from: jsonData)

        XCTAssertEqual(ledgerInfo.ledgerHash, "a1b2c3d4e5f6")
        XCTAssertEqual(ledgerInfo.sequence, 1000000)
        XCTAssertEqual(ledgerInfo.ledgerCloseTime, "1700000000")
        XCTAssertNil(ledgerInfo.headerXdr)
        XCTAssertNil(ledgerInfo.metadataXdr)
    }

    func testLedgerInfoDecodingWithLargeSequenceNumber() throws {
        let json = """
        {
            "hash": "f6e5d4c3b2a1",
            "sequence": 4294967295,
            "ledgerCloseTime": "1800000000"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let ledgerInfo = try decoder.decode(LedgerInfo.self, from: jsonData)

        XCTAssertEqual(ledgerInfo.sequence, 4294967295)
    }

    // MARK: - TransactionEvents Tests

    func testTransactionEventsDecodingWithAllFields() throws {
        let json = """
        {
            "diagnosticEventsXdr": ["AAAA", "BBBB", "CCCC"],
            "transactionEventsXdr": ["DDDD", "EEEE"],
            "contractEventsXdr": [["FFFF", "GGGG"], ["HHHH"]]
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let events = try decoder.decode(TransactionEvents.self, from: jsonData)

        XCTAssertEqual(events.diagnosticEventsXdr?.count, 3)
        XCTAssertEqual(events.diagnosticEventsXdr?[0], "AAAA")
        XCTAssertEqual(events.diagnosticEventsXdr?[1], "BBBB")
        XCTAssertEqual(events.diagnosticEventsXdr?[2], "CCCC")

        XCTAssertEqual(events.transactionEventsXdr?.count, 2)
        XCTAssertEqual(events.transactionEventsXdr?[0], "DDDD")
        XCTAssertEqual(events.transactionEventsXdr?[1], "EEEE")

        XCTAssertEqual(events.contractEventsXdr?.count, 2)
        XCTAssertEqual(events.contractEventsXdr?[0].count, 2)
        XCTAssertEqual(events.contractEventsXdr?[0][0], "FFFF")
        XCTAssertEqual(events.contractEventsXdr?[0][1], "GGGG")
        XCTAssertEqual(events.contractEventsXdr?[1].count, 1)
        XCTAssertEqual(events.contractEventsXdr?[1][0], "HHHH")
    }

    func testTransactionEventsDecodingWithAllFieldsMissing() throws {
        let json = """
        {}
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let events = try decoder.decode(TransactionEvents.self, from: jsonData)

        XCTAssertNil(events.diagnosticEventsXdr)
        XCTAssertNil(events.transactionEventsXdr)
        XCTAssertNil(events.contractEventsXdr)
    }

    func testTransactionEventsDecodingWithDiagnosticEventsOnly() throws {
        let json = """
        {
            "diagnosticEventsXdr": ["AAAA", "BBBB"]
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let events = try decoder.decode(TransactionEvents.self, from: jsonData)

        XCTAssertEqual(events.diagnosticEventsXdr?.count, 2)
        XCTAssertNil(events.transactionEventsXdr)
        XCTAssertNil(events.contractEventsXdr)
    }

    func testTransactionEventsDecodingWithEmptyArrays() throws {
        let json = """
        {
            "diagnosticEventsXdr": [],
            "transactionEventsXdr": [],
            "contractEventsXdr": []
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let events = try decoder.decode(TransactionEvents.self, from: jsonData)

        XCTAssertEqual(events.diagnosticEventsXdr?.count, 0)
        XCTAssertEqual(events.transactionEventsXdr?.count, 0)
        XCTAssertEqual(events.contractEventsXdr?.count, 0)
    }

    // MARK: - Integration Tests

    func testEventFilterWithComplexTopicFilters() {
        let topic1 = TopicFilter(segmentMatchers: ["transfer"])
        let topic2 = TopicFilter(segmentMatchers: ["mint", "*"])

        let filter = EventFilter(type: "contract", contractIds: ["CCONTRACT1", "CCONTRACT2"], topics: [topic1, topic2])
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "contract")
        XCTAssertNotNil(params["contractIds"])
        XCTAssertNotNil(params["topics"])

        let contractIds = params["contractIds"] as? [String]
        XCTAssertEqual(contractIds?.count, 2)

        let topics = params["topics"] as? [[String]]
        XCTAssertEqual(topics?.count, 2)
        XCTAssertEqual(topics?[0], ["transfer"])
        XCTAssertEqual(topics?[1], ["mint", "*"])
    }

    func testPaginationWithEventFilter() {
        let pagination = PaginationOptions(cursor: "cursor123", limit: 50)
        let filter = EventFilter(type: "contract")

        let paginationParams = pagination.buildRequestParams()
        let filterParams = filter.buildRequestParams()

        XCTAssertNotNil(paginationParams["cursor"])
        XCTAssertNotNil(paginationParams["limit"])
        XCTAssertNotNil(filterParams["type"])
    }

    func testGetTransactionsResponseWithTransactionEvents() throws {
        let json = """
        {
            "transactions": [
                {
                    "status": "SUCCESS",
                    "applicationOrder": 1,
                    "feeBump": false,
                    "envelopeXdr": "AAAA",
                    "resultXdr": "BBBB",
                    "resultMetaXdr": "CCCC",
                    "ledger": 1000000,
                    "createdAt": 1700000000,
                    "txHash": "abc123",
                    "events": {
                        "diagnosticEventsXdr": ["DDDD"],
                        "transactionEventsXdr": ["EEEE"],
                        "contractEventsXdr": [["FFFF"]]
                    }
                }
            ],
            "latestLedger": 1000100,
            "latestLedgerCloseTimestamp": 1700001000,
            "oldestLedger": 900000,
            "oldestLedgerCloseTimestamp": 1690000000
        }
        """

        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetTransactionsResponse.self, from: jsonData)

        XCTAssertEqual(response.transactions.count, 1)
        XCTAssertNotNil(response.transactions[0].events)
        XCTAssertEqual(response.transactions[0].events?.diagnosticEventsXdr?.count, 1)
        XCTAssertEqual(response.transactions[0].events?.transactionEventsXdr?.count, 1)
        XCTAssertEqual(response.transactions[0].events?.contractEventsXdr?.count, 1)
    }
}
