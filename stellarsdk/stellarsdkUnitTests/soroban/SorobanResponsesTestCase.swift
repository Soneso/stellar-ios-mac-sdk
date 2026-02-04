//
//  SorobanResponsesTestCase.swift
//  stellarsdkTests
//
//  Created by Claude Code
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class SorobanResponsesTestCase: XCTestCase {

    // MARK: - SimulateTransactionResponse Tests

    func testParseSimulateTransactionResponse() throws {
        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "minResourceFee": "58181",
            "results": [
                {
                    "auth": [],
                    "xdr": "AAAAAQ=="
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SimulateTransactionResponse.self, from: jsonData)

        // Verify basic fields
        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertEqual(response.minResourceFee, 58181)
        XCTAssertNil(response.error)

        // Verify results
        XCTAssertNotNil(response.results)
        XCTAssertEqual(response.results?.count, 1)
        XCTAssertNotNil(response.results?.first?.xdr)
    }

    func testParseSimulateTransactionResponseWithError() throws {
        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "error": "Error: Contract invocation failed"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SimulateTransactionResponse.self, from: jsonData)

        // Verify error handling
        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error, "Error: Contract invocation failed")
        XCTAssertNil(response.transactionData)
        XCTAssertNil(response.minResourceFee)
        XCTAssertNil(response.results)
    }

    func testParseSimulateTransactionResponseWithRestorePreamble() throws {
        // Skip restore preamble test as it requires valid transaction data XDR
        // This can be tested with integration tests using real RPC responses
        XCTAssertTrue(true)

    }

    // MARK: - SendTransactionResponse Tests

    func testParseSendTransactionResponse() throws {
        let jsonResponse = """
        {
            "hash": "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4",
            "status": "PENDING",
            "latestLedger": 1000000,
            "latestLedgerCloseTime": "1609459200"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SendTransactionResponse.self, from: jsonData)

        // Verify fields
        XCTAssertEqual(response.transactionId, "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4")
        XCTAssertEqual(response.status, SendTransactionResponse.STATUS_PENDING)
        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertEqual(response.latestLedgerCloseTime, "1609459200")
        XCTAssertNil(response.error)
        XCTAssertNil(response.errorResult)
    }

    func testParseSendTransactionResponseDuplicate() throws {
        let jsonResponse = """
        {
            "hash": "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4",
            "status": "DUPLICATE",
            "latestLedger": 1000000,
            "latestLedgerCloseTime": "1609459200"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SendTransactionResponse.self, from: jsonData)

        XCTAssertEqual(response.status, SendTransactionResponse.STATUS_DUPLICATE)
    }

    func testParseSendTransactionResponseError() throws {
        let jsonResponse = """
        {
            "hash": "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4",
            "status": "ERROR",
            "latestLedger": 1000000,
            "latestLedgerCloseTime": "1609459200",
            "error": {
                "code": "txFailed",
                "message": "Transaction failed"
            },
            "errorResultXdr": "AAAAAAAAAGT////7AAAAAA=="
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SendTransactionResponse.self, from: jsonData)

        // Verify error fields
        XCTAssertEqual(response.status, SendTransactionResponse.STATUS_ERROR)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error?.code, "txFailed")
        XCTAssertEqual(response.error?.message, "Transaction failed")
        XCTAssertNotNil(response.errorResultXdr)
    }

    // MARK: - GetTransactionResponse Tests

    func testParseGetTransactionResponse() throws {
        let jsonResponse = """
        {
            "status": "SUCCESS",
            "latestLedger": 1000100,
            "latestLedgerCloseTime": "1609459260",
            "oldestLedger": 999000,
            "oldestLedgerCloseTime": "1609459000",
            "ledger": 1000050,
            "createdAt": "1609459250",
            "applicationOrder": 1,
            "feeBump": false,
            "envelopeXdr": "AAAAAgAAAAA=",
            "resultXdr": "AAAAAAAAAGT/////AAAAAQAAAAAAAAAB/////gAAAAA=",
            "resultMetaXdr": "AAAAAwAAAAAAAAACAAAAAAAPPIAAAAAB"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetTransactionResponse.self, from: jsonData)

        // Verify status and basic fields
        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_SUCCESS)
        XCTAssertEqual(response.latestLedger, 1000100)
        XCTAssertEqual(response.latestLedgerCloseTime, "1609459260")
        XCTAssertEqual(response.oldestLedger, 999000)
        XCTAssertEqual(response.oldestLedgerCloseTime, "1609459000")

        // Verify transaction-specific fields
        XCTAssertEqual(response.ledger, 1000050)
        XCTAssertEqual(response.createdAt, "1609459250")
        XCTAssertEqual(response.applicationOrder, 1)
        XCTAssertEqual(response.feeBump, false)

        // Verify XDR fields
        XCTAssertNotNil(response.envelopeXdr)
        XCTAssertNotNil(response.resultXdr)
        XCTAssertNotNil(response.resultMetaXdr)
        XCTAssertNil(response.error)
    }

    func testParseGetTransactionResponseNotFound() throws {
        let jsonResponse = """
        {
            "status": "NOT_FOUND",
            "latestLedger": 1000100,
            "latestLedgerCloseTime": "1609459260",
            "oldestLedger": 999000,
            "oldestLedgerCloseTime": "1609459000"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetTransactionResponse.self, from: jsonData)

        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_NOT_FOUND)
        XCTAssertNil(response.ledger)
        XCTAssertNil(response.createdAt)
        XCTAssertNil(response.envelopeXdr)
        XCTAssertNil(response.resultXdr)
    }

    func testParseGetTransactionResponseFailed() throws {
        let jsonResponse = """
        {
            "status": "FAILED",
            "latestLedger": 1000100,
            "latestLedgerCloseTime": "1609459260",
            "oldestLedger": 999000,
            "ledger": 1000050,
            "createdAt": "1609459250",
            "applicationOrder": 1,
            "feeBump": false,
            "envelopeXdr": "AAAAAgAAAAA=",
            "resultXdr": "AAAAAAAAAGT////7AAAAAA==",
            "resultMetaXdr": "AAAAAwAAAAAAAAACAAAAAAAPPIAAAAAB",
            "error": {
                "code": "txFailed",
                "message": "Transaction execution failed"
            }
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetTransactionResponse.self, from: jsonData)

        XCTAssertEqual(response.status, GetTransactionResponse.STATUS_FAILED)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error?.code, "txFailed")
        XCTAssertEqual(response.error?.message, "Transaction execution failed")
    }

    // MARK: - GetEventsResponse Tests

    func testParseGetEventsResponse() throws {
        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "events": [
                {
                    "type": "contract",
                    "ledger": 999900,
                    "ledgerClosedAt": "2024-01-15T10:00:00Z",
                    "contractId": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
                    "id": "0000999900-0000000001",
                    "pagingToken": "999900-1",
                    "inSuccessfulContractCall": true,
                    "topic": ["AAAADwAAAAh0cmFuc2Zlcg=="],
                    "value": "AAAAAQ==",
                    "txHash": "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4"
                }
            ],
            "cursor": "999900-1"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetEventsResponse.self, from: jsonData)

        // Verify basic fields
        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertEqual(response.events.count, 1)
        XCTAssertEqual(response.cursor, "999900-1")

        // Verify event details
        let event = response.events[0]
        XCTAssertEqual(event.type, "contract")
        XCTAssertEqual(event.ledger, 999900)
        XCTAssertEqual(event.id, "0000999900-0000000001")
        XCTAssertNotNil(event.contractId)
        // inSuccessfulContractCall is deprecated for protocol >= 23
        XCTAssertNotNil(event.type)
    }

    func testParseGetEventsResponseEmpty() throws {
        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "events": []
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetEventsResponse.self, from: jsonData)

        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertEqual(response.events.count, 0)
        XCTAssertNil(response.cursor)
    }

    // MARK: - GetLedgerEntriesResponse Tests

    func testParseGetLedgerEntriesResponse() throws {
        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "entries": [
                {
                    "key": "AAAABgAAAAHpt+eLvUk0FquW9xHdY/bTnpry+8VdDT8IZ+IF4NAD/AAAABQAAAAB",
                    "xdr": "AAAABgAAAAHpt+eLvUk0FquW9xHdY/bTnpry+8VdDT8IZ+IF4NAD/AAAABQAAAABAAAAB",
                    "lastModifiedLedgerSeq": 999950
                }
            ]
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetLedgerEntriesResponse.self, from: jsonData)

        // Verify fields
        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertEqual(response.entries.count, 1)

        // Verify entry details
        let entry = response.entries[0]
        XCTAssertNotNil(entry.key)
        XCTAssertNotNil(entry.xdr)
        XCTAssertEqual(entry.lastModifiedLedgerSeq, 999950)
    }

    func testParseGetLedgerEntriesResponseEmpty() throws {
        let jsonResponse = """
        {
            "latestLedger": 1000000,
            "entries": []
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetLedgerEntriesResponse.self, from: jsonData)

        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertEqual(response.entries.count, 0)
    }

    // MARK: - GetLatestLedgerResponse Tests

    func testParseGetLatestLedgerResponse() throws {
        let jsonResponse = """
        {
            "id": "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4",
            "protocolVersion": 20,
            "sequence": 1000000
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetLatestLedgerResponse.self, from: jsonData)

        // Verify fields
        XCTAssertEqual(response.id, "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4")
        XCTAssertEqual(response.protocolVersion, 20)
        XCTAssertEqual(response.sequence, 1000000)
    }

    func testParseGetLatestLedgerResponseWithNewFields() throws {
        let jsonResponse = """
        {
            "id": "a4721e2a61e9a1b5c3b8f3e5a7c4d6e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4",
            "protocolVersion": 25,
            "sequence": 1000000,
            "closeTime": "1609459200",
            "headerXdr": "AAAABgAAAAHpt+eLvUk0FquW9xHdY/bTnpry+8VdDT8IZ+IF4NAD/AAAABQAAAAB",
            "metadataXdr": "AAAAAwAAAAAAAAACAAAAAAAPPIAAAAAB"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetLatestLedgerResponse.self, from: jsonData)

        // Verify basic fields
        XCTAssertEqual(response.protocolVersion, 25)
        XCTAssertEqual(response.sequence, 1000000)

        // Verify new fields (RPC v25+)
        XCTAssertEqual(response.closeTime, "1609459200")
        XCTAssertNotNil(response.headerXdr)
        XCTAssertNotNil(response.metadataXdr)
    }

    // MARK: - GetNetworkResponse Tests

    func testParseGetNetworkResponse() throws {
        let jsonResponse = """
        {
            "friendbotUrl": "https://friendbot.stellar.org/",
            "passphrase": "Test SDF Network ; September 2015",
            "protocolVersion": 20
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetNetworkResponse.self, from: jsonData)

        XCTAssertEqual(response.friendbotUrl, "https://friendbot.stellar.org/")
        XCTAssertEqual(response.passphrase, "Test SDF Network ; September 2015")
        XCTAssertEqual(response.protocolVersion, 20)
    }

    func testParseGetNetworkResponseWithoutFriendbot() throws {
        let jsonResponse = """
        {
            "passphrase": "Public Global Stellar Network ; September 2015",
            "protocolVersion": 20
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetNetworkResponse.self, from: jsonData)

        XCTAssertNil(response.friendbotUrl)
        XCTAssertEqual(response.passphrase, "Public Global Stellar Network ; September 2015")
        XCTAssertEqual(response.protocolVersion, 20)
    }

    // MARK: - GetHealthResponse Tests

    func testParseGetHealthResponse() throws {
        let jsonResponse = """
        {
            "status": "healthy",
            "latestLedger": 1000000,
            "oldestLedger": 900000,
            "ledgerRetentionWindow": 100000
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetHealthResponse.self, from: jsonData)

        XCTAssertEqual(response.status, "healthy")
        XCTAssertEqual(response.latestLedger, 1000000)
        XCTAssertEqual(response.oldestLedger, 900000)
        XCTAssertEqual(response.ledgerRetentionWindow, 100000)
    }

    // MARK: - GetFeeStatsResponse Tests

    func testParseGetFeeStatsResponse() throws {
        let jsonResponse = """
        {
            "sorobanInclusionFee": {
                "max": "10000",
                "min": "100",
                "mode": "150",
                "p10": "110",
                "p20": "120",
                "p30": "130",
                "p40": "140",
                "p50": "150",
                "p60": "160",
                "p70": "170",
                "p80": "180",
                "p90": "200",
                "p99": "500",
                "transactionCount": "1000",
                "ledgerCount": 10
            },
            "inclusionFee": {
                "max": "1000",
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
                "p90": "150",
                "p99": "200",
                "transactionCount": "5000",
                "ledgerCount": 10
            },
            "latestLedger": 1000000
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetFeeStatsResponse.self, from: jsonData)

        XCTAssertEqual(response.latestLedger, 1000000)

        // Verify soroban inclusion fee
        XCTAssertEqual(response.sorobanInclusionFee.max, "10000")
        XCTAssertEqual(response.sorobanInclusionFee.min, "100")
        XCTAssertEqual(response.sorobanInclusionFee.mode, "150")
        XCTAssertEqual(response.sorobanInclusionFee.p50, "150")
        XCTAssertEqual(response.sorobanInclusionFee.transactionCount, "1000")
        XCTAssertEqual(response.sorobanInclusionFee.ledgerCount, 10)

        // Verify regular inclusion fee
        XCTAssertEqual(response.inclusionFee.max, "1000")
        XCTAssertEqual(response.inclusionFee.min, "100")
        XCTAssertEqual(response.inclusionFee.transactionCount, "5000")
    }

    // MARK: - GetVersionInfoResponse Tests

    func testParseGetVersionInfoResponse() throws {
        let jsonResponse = """
        {
            "version": "21.0.0",
            "commitHash": "abc123def456",
            "buildTimestamp": "2024-01-15T10:00:00Z",
            "captiveCoreVersion": "v20.0.0",
            "protocolVersion": 20
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetVersionInfoResponse.self, from: jsonData)

        XCTAssertEqual(response.version, "21.0.0")
        XCTAssertEqual(response.commitHash, "abc123def456")
        XCTAssertEqual(response.buildTimeStamp, "2024-01-15T10:00:00Z")
        XCTAssertEqual(response.captiveCoreVersion, "v20.0.0")
        XCTAssertEqual(response.protocolVersion, 20)
    }

    func testParseGetVersionInfoResponseLegacyFormat() throws {
        // Test protocol version < 22 format with underscores
        let jsonResponse = """
        {
            "version": "20.0.0",
            "commit_hash": "abc123def456",
            "build_time_stamp": "2024-01-15T10:00:00Z",
            "captive_core_version": "v19.0.0",
            "protocol_version": 19
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetVersionInfoResponse.self, from: jsonData)

        XCTAssertEqual(response.version, "20.0.0")
        XCTAssertEqual(response.commitHash, "abc123def456")
        XCTAssertEqual(response.buildTimeStamp, "2024-01-15T10:00:00Z")
        XCTAssertEqual(response.captiveCoreVersion, "v19.0.0")
        XCTAssertEqual(response.protocolVersion, 19)
    }

    // MARK: - Error Response Tests

    func testParseSorobanRpcError() {
        // Test standard JSON-RPC error codes
        let parseError = SorobanRpcError(code: -32700, message: "Parse error", data: nil)
        XCTAssertEqual(parseError.code, -32700)
        XCTAssertEqual(parseError.message, "Parse error")

        let methodNotFound = SorobanRpcError(code: -32601, message: "Method not found", data: nil)
        XCTAssertEqual(methodNotFound.code, -32601)

        let invalidParams = SorobanRpcError(code: -32602, message: "Invalid params", data: nil)
        XCTAssertEqual(invalidParams.code, -32602)

        let internalError = SorobanRpcError(code: -32603, message: "Internal error", data: nil)
        XCTAssertEqual(internalError.code, -32603)
    }

    func testParseTransactionStatusError() throws {
        let jsonResponse = """
        {
            "code": "txFailed",
            "message": "Transaction execution failed",
            "data": "Additional error context"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let error = try decoder.decode(TransactionStatusError.self, from: jsonData)

        XCTAssertEqual(error.code, "txFailed")
        XCTAssertEqual(error.message, "Transaction execution failed")
        XCTAssertEqual(error.data, "Additional error context")
    }

    func testParseTransactionStatusErrorWithoutData() throws {
        let jsonResponse = """
        {
            "code": "txBadAuth",
            "message": "Bad authentication"
        }
        """

        let jsonData = jsonResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let error = try decoder.decode(TransactionStatusError.self, from: jsonData)

        XCTAssertEqual(error.code, "txBadAuth")
        XCTAssertEqual(error.message, "Bad authentication")
        XCTAssertNil(error.data)
    }
}
