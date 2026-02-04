//
//  OperationResponsesUnitTests.swift
//  stellarsdkTests
//
//  Created by Claude Code
//  Copyright 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Unit tests for operation response classes that parse Horizon API JSON responses.
/// Tests cover JSON decoding for various operation types.
class OperationResponsesUnitTests: XCTestCase {

    // MARK: - Common JSON Template

    /// Returns the base JSON structure for an operation response
    private func baseOperationJSON(typeI: Int, type: String, additionalFields: String = "") -> String {
        return """
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
            "type": "\(type)",
            "type_i": \(typeI),
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123def456789",
            "transaction_successful": true\(additionalFields.isEmpty ? "" : ",\n            \(additionalFields)")
        }
        """
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        return decoder
    }

    // MARK: - BeginSponsoringFutureReservesOperationResponse Tests

    func testParseBeginSponsoringFutureReservesOperationResponse() throws {
        let additionalFields = """
"sponsored_id": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
"""
        let json = baseOperationJSON(typeI: 16, type: "begin_sponsoring_future_reserves", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(BeginSponsoringFutureReservesOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.id, "12345")
        XCTAssertEqual(response.pagingToken, "12345")
        XCTAssertEqual(response.sourceAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.operationType, OperationType.beginSponsoringFutureReserves)
        XCTAssertEqual(response.operationTypeString, "begin_sponsoring_future_reserves")
        XCTAssertEqual(response.transactionHash, "abc123def456789")
        XCTAssertTrue(response.transactionSuccessful)

        // Verify specific fields
        XCTAssertEqual(response.sponsoredId, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
    }

    // MARK: - BumpSequenceOperationResponse Tests

    func testParseBumpSequenceOperationResponse() throws {
        let additionalFields = """
"bump_to": "123456789"
"""
        let json = baseOperationJSON(typeI: 11, type: "bump_sequence", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(BumpSequenceOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.id, "12345")
        XCTAssertEqual(response.operationType, OperationType.bumpSequence)
        XCTAssertEqual(response.operationTypeString, "bump_sequence")

        // Verify specific fields
        XCTAssertEqual(response.bumpTo, "123456789")
    }

    // MARK: - ClaimClaimableBalanceOperationResponse Tests

    func testParseClaimClaimableBalanceOperationResponse() throws {
        let additionalFields = """
"balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
            "claimant": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
"""
        let json = baseOperationJSON(typeI: 15, type: "claim_claimable_balance", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(ClaimClaimableBalanceOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.claimClaimableBalance)
        XCTAssertEqual(response.operationTypeString, "claim_claimable_balance")

        // Verify specific fields
        XCTAssertEqual(response.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        XCTAssertEqual(response.claimantAccountId, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertNil(response.claimantMuxed)
        XCTAssertNil(response.claimantMuxedId)
    }

    func testParseClaimClaimableBalanceOperationResponseWithMuxedAccount() throws {
        let additionalFields = """
"balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072",
            "claimant": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "claimant_muxed": "MBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUAAAAAAAAAPCIBQOY",
            "claimant_muxed_id": "1234567890"
"""
        let json = baseOperationJSON(typeI: 15, type: "claim_claimable_balance", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(ClaimClaimableBalanceOperationResponse.self, from: jsonData)

        // Verify muxed account fields
        XCTAssertEqual(response.claimantMuxed, "MBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUAAAAAAAAAPCIBQOY")
        XCTAssertEqual(response.claimantMuxedId, "1234567890")
    }

    // MARK: - ClawbackClaimableBalanceOperationResponse Tests

    func testParseClawbackClaimableBalanceOperationResponse() throws {
        let additionalFields = """
"balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
"""
        let json = baseOperationJSON(typeI: 20, type: "clawback_claimable_balance", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(ClawbackClaimableBalanceOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.clawbackClaimableBalance)
        XCTAssertEqual(response.operationTypeString, "clawback_claimable_balance")

        // Verify specific fields
        XCTAssertEqual(response.balanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
    }

    // MARK: - ClawbackOperationResponse Tests

    func testParseClawbackOperationResponse() throws {
        let additionalFields = """
"amount": "100.0000000",
            "from": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
"""
        let json = baseOperationJSON(typeI: 19, type: "clawback", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(ClawbackOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.clawback)
        XCTAssertEqual(response.operationTypeString, "clawback")

        // Verify specific fields
        XCTAssertEqual(response.amount, "100.0000000")
        XCTAssertEqual(response.from, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.assetType, "credit_alphanum4")
        XCTAssertEqual(response.assetCode, "USD")
        XCTAssertEqual(response.assetIssuer, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertNil(response.fromMuxed)
        XCTAssertNil(response.fromMuxedId)
    }

    func testParseClawbackOperationResponseWithMuxedAccount() throws {
        let additionalFields = """
"amount": "50.0000000",
            "from": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "from_muxed": "MBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUAAAAAAAAAPCIBQOY",
            "from_muxed_id": "9876543210",
            "asset_type": "credit_alphanum12",
            "asset_code": "USDC",
            "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
"""
        let json = baseOperationJSON(typeI: 19, type: "clawback", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(ClawbackOperationResponse.self, from: jsonData)

        // Verify muxed account fields
        XCTAssertEqual(response.fromMuxed, "MBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUAAAAAAAAAPCIBQOY")
        XCTAssertEqual(response.fromMuxedId, "9876543210")
        XCTAssertEqual(response.assetType, "credit_alphanum12")
        XCTAssertEqual(response.assetCode, "USDC")
    }

    func testParseClawbackOperationResponseWithNativeAsset() throws {
        let additionalFields = """
"amount": "10.0000000",
            "from": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "asset_type": "native"
"""
        let json = baseOperationJSON(typeI: 19, type: "clawback", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(ClawbackOperationResponse.self, from: jsonData)

        // Verify native asset
        XCTAssertEqual(response.assetType, "native")
        XCTAssertNil(response.assetCode)
        XCTAssertNil(response.assetIssuer)
    }

    // MARK: - EndSponsoringFutureReservesOperationResponse Tests

    func testParseEndSponsoringFutureReservesOperationResponse() throws {
        let additionalFields = """
"begin_sponsor": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
"""
        let json = baseOperationJSON(typeI: 17, type: "end_sponsoring_future_reserves", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(EndSponsoringFutureReservesOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.endSponsoringFutureReserves)
        XCTAssertEqual(response.operationTypeString, "end_sponsoring_future_reserves")

        // Verify specific fields
        XCTAssertEqual(response.beginSponsor, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertNil(response.beginSponsorMuxed)
        XCTAssertNil(response.beginSponsorMuxedId)
    }

    func testParseEndSponsoringFutureReservesOperationResponseWithMuxedAccount() throws {
        let additionalFields = """
"begin_sponsor": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "begin_sponsor_muxed": "MDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWAAAAAAAAAPCIBQOY",
            "begin_sponsor_muxed_id": "5555555555"
"""
        let json = baseOperationJSON(typeI: 17, type: "end_sponsoring_future_reserves", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(EndSponsoringFutureReservesOperationResponse.self, from: jsonData)

        // Verify muxed account fields
        XCTAssertEqual(response.beginSponsorMuxed, "MDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWAAAAAAAAAPCIBQOY")
        XCTAssertEqual(response.beginSponsorMuxedId, "5555555555")
    }

    // MARK: - InvokeHostFunctionOperationResponse Tests

    func testParseInvokeHostFunctionOperationResponse() throws {
        let additionalFields = """
"function": "HostFunctionTypeInvokeContract",
            "address": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
            "salt": "abc123def456"
"""
        let json = baseOperationJSON(typeI: 24, type: "invoke_host_function", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(InvokeHostFunctionOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.invokeHostFunction)
        XCTAssertEqual(response.operationTypeString, "invoke_host_function")

        // Verify specific fields
        XCTAssertEqual(response.function, "HostFunctionTypeInvokeContract")
        XCTAssertEqual(response.address, "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC")
        XCTAssertEqual(response.salt, "abc123def456")
        XCTAssertNil(response.parameters)
        XCTAssertNil(response.assetBalanceChanges)
    }

    func testParseInvokeHostFunctionOperationResponseWithParameters() throws {
        let additionalFields = """
"function": "HostFunctionTypeInvokeContract",
            "address": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
            "salt": "abc123def456",
            "parameters": [
                {
                    "type": "Address",
                    "value": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
                },
                {
                    "type": "I128",
                    "value": "1000000"
                }
            ]
"""
        let json = baseOperationJSON(typeI: 24, type: "invoke_host_function", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(InvokeHostFunctionOperationResponse.self, from: jsonData)

        // Verify parameters
        XCTAssertNotNil(response.parameters)
        XCTAssertEqual(response.parameters?.count, 2)
        XCTAssertEqual(response.parameters?[0].type, "Address")
        XCTAssertEqual(response.parameters?[0].value, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.parameters?[1].type, "I128")
        XCTAssertEqual(response.parameters?[1].value, "1000000")
    }

    func testParseInvokeHostFunctionOperationResponseWithAssetBalanceChanges() throws {
        let additionalFields = """
"function": "HostFunctionTypeInvokeContract",
            "address": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
            "salt": "abc123def456",
            "asset_balance_changes": [
                {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "USDC",
                    "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "type": "transfer",
                    "from": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
                    "amount": "100.0000000"
                },
                {
                    "asset_type": "native",
                    "type": "mint",
                    "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
                    "amount": "50.0000000"
                }
            ]
"""
        let json = baseOperationJSON(typeI: 24, type: "invoke_host_function", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(InvokeHostFunctionOperationResponse.self, from: jsonData)

        // Verify asset balance changes
        XCTAssertNotNil(response.assetBalanceChanges)
        XCTAssertEqual(response.assetBalanceChanges?.count, 2)

        let firstChange = response.assetBalanceChanges?[0]
        XCTAssertEqual(firstChange?.assetType, "credit_alphanum4")
        XCTAssertEqual(firstChange?.assetCode, "USDC")
        XCTAssertEqual(firstChange?.assetIssuer, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(firstChange?.type, "transfer")
        XCTAssertEqual(firstChange?.from, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(firstChange?.to, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(firstChange?.amount, "100.0000000")

        let secondChange = response.assetBalanceChanges?[1]
        XCTAssertEqual(secondChange?.assetType, "native")
        XCTAssertNil(secondChange?.assetCode)
        XCTAssertNil(secondChange?.assetIssuer)
        XCTAssertEqual(secondChange?.type, "mint")
        XCTAssertNil(secondChange?.from)
        XCTAssertEqual(secondChange?.to, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(secondChange?.amount, "50.0000000")
    }

    func testParseInvokeHostFunctionOperationResponseWithDestinationMuxedId() throws {
        let additionalFields = """
"function": "HostFunctionTypeInvokeContract",
            "address": "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
            "salt": "abc123def456",
            "asset_balance_changes": [
                {
                    "asset_type": "credit_alphanum4",
                    "asset_code": "USDC",
                    "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "type": "transfer",
                    "from": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
                    "amount": "100.0000000",
                    "destination_muxed_id": "1234567890"
                }
            ]
"""
        let json = baseOperationJSON(typeI: 24, type: "invoke_host_function", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(InvokeHostFunctionOperationResponse.self, from: jsonData)

        // Verify destination muxed id
        XCTAssertEqual(response.assetBalanceChanges?[0].destinationMuxedId, "1234567890")
    }

    // MARK: - LiquidityPoolDepostOperationResponse Tests

    func testParseLiquidityPoolDepositOperationResponse() throws {
        let additionalFields = """
"liquidity_pool_id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
            "reserves_max": [
                {
                    "asset": "native",
                    "amount": "1000.0000000"
                },
                {
                    "asset": "USDC:GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "amount": "500.0000000"
                }
            ],
            "min_price": "0.5000000",
            "min_price_r": {
                "n": 1,
                "d": 2
            },
            "max_price": "2.0000000",
            "max_price_r": {
                "n": 2,
                "d": 1
            },
            "reserves_deposited": [
                {
                    "asset": "native",
                    "amount": "800.0000000"
                },
                {
                    "asset": "USDC:GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "amount": "400.0000000"
                }
            ],
            "shares_received": "566.0000000"
"""
        let json = baseOperationJSON(typeI: 22, type: "liquidity_pool_deposit", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(LiquidityPoolDepostOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.liquidityPoolDeposit)
        XCTAssertEqual(response.operationTypeString, "liquidity_pool_deposit")

        // Verify specific fields
        XCTAssertEqual(response.liquidityPoolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
        XCTAssertEqual(response.minPrice, "0.5000000")
        XCTAssertEqual(response.maxPrice, "2.0000000")
        XCTAssertEqual(response.sharesReceived, "566.0000000")

        // Verify price ratios
        XCTAssertEqual(response.minPriceR.n, 1)
        XCTAssertEqual(response.minPriceR.d, 2)
        XCTAssertEqual(response.maxPriceR.n, 2)
        XCTAssertEqual(response.maxPriceR.d, 1)

        // Verify reserves deposited
        XCTAssertEqual(response.reservesDeposited.count, 2)
        XCTAssertEqual(response.reservesDeposited[0].amount, "800.0000000")
        XCTAssertEqual(response.reservesDeposited[1].amount, "400.0000000")
    }

    // MARK: - LiquidityPoolWithdrawOperationResponse Tests

    func testParseLiquidityPoolWithdrawOperationResponse() throws {
        let additionalFields = """
"liquidity_pool_id": "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9",
            "reserves_min": [
                {
                    "asset": "native",
                    "amount": "100.0000000"
                },
                {
                    "asset": "USDC:GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "amount": "50.0000000"
                }
            ],
            "shares": "200.0000000",
            "reserves_received": [
                {
                    "asset": "native",
                    "amount": "150.0000000"
                },
                {
                    "asset": "USDC:GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
                    "amount": "75.0000000"
                }
            ]
"""
        let json = baseOperationJSON(typeI: 23, type: "liquidity_pool_withdraw", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(LiquidityPoolWithdrawOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.liquidityPoolWithdraw)
        XCTAssertEqual(response.operationTypeString, "liquidity_pool_withdraw")

        // Verify specific fields
        XCTAssertEqual(response.liquidityPoolId, "67260c4c1807b262ff851b0a3fe141194936bb0215b2f77447f1df11998eabb9")
        XCTAssertEqual(response.shares, "200.0000000")

        // Verify reserves min
        XCTAssertEqual(response.reservesMin.count, 2)
        XCTAssertEqual(response.reservesMin[0].amount, "100.0000000")
        XCTAssertEqual(response.reservesMin[1].amount, "50.0000000")

        // Verify reserves received
        XCTAssertEqual(response.reservesReceived.count, 2)
        XCTAssertEqual(response.reservesReceived[0].amount, "150.0000000")
        XCTAssertEqual(response.reservesReceived[1].amount, "75.0000000")
    }

    // MARK: - RestoreFootprintOperationResponse Tests

    func testParseRestoreFootprintOperationResponse() throws {
        // RestoreFootprintOperationResponse has no additional fields beyond base OperationResponse
        let json = baseOperationJSON(typeI: 26, type: "restore_footprint")

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(RestoreFootprintOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.id, "12345")
        XCTAssertEqual(response.operationType, OperationType.restoreFootprint)
        XCTAssertEqual(response.operationTypeString, "restore_footprint")
        XCTAssertEqual(response.sourceAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.transactionHash, "abc123def456789")
        XCTAssertTrue(response.transactionSuccessful)
    }

    // MARK: - RevokeSponsorshipOperationResponse Tests

    func testParseRevokeSponsorshipOperationResponseForAccount() throws {
        let additionalFields = """
"account_id": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
"""
        let json = baseOperationJSON(typeI: 18, type: "revoke_sponsorship", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(RevokeSponsorshipOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.revokeSponsorship)
        XCTAssertEqual(response.operationTypeString, "revoke_sponsorship")

        // Verify specific fields
        XCTAssertEqual(response.accountId, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertNil(response.claimableBalanceId)
        XCTAssertNil(response.dataAccountId)
        XCTAssertNil(response.dataName)
        XCTAssertNil(response.offerId)
        XCTAssertNil(response.trustlineAccountId)
        XCTAssertNil(response.trustlineAsset)
        XCTAssertNil(response.signerAccountId)
        XCTAssertNil(response.signerKey)
    }

    func testParseRevokeSponsorshipOperationResponseForClaimableBalance() throws {
        let additionalFields = """
"claimable_balance_id": "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072"
"""
        let json = baseOperationJSON(typeI: 18, type: "revoke_sponsorship", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(RevokeSponsorshipOperationResponse.self, from: jsonData)

        // Verify specific fields
        XCTAssertEqual(response.claimableBalanceId, "00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072")
        XCTAssertNil(response.accountId)
    }

    func testParseRevokeSponsorshipOperationResponseForDataEntry() throws {
        let additionalFields = """
"data_account_id": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "data_name": "config_key"
"""
        let json = baseOperationJSON(typeI: 18, type: "revoke_sponsorship", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(RevokeSponsorshipOperationResponse.self, from: jsonData)

        // Verify specific fields
        XCTAssertEqual(response.dataAccountId, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.dataName, "config_key")
        XCTAssertNil(response.accountId)
    }

    func testParseRevokeSponsorshipOperationResponseForOffer() throws {
        let additionalFields = """
"offer_id": "12345678"
"""
        let json = baseOperationJSON(typeI: 18, type: "revoke_sponsorship", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(RevokeSponsorshipOperationResponse.self, from: jsonData)

        // Verify specific fields
        XCTAssertEqual(response.offerId, "12345678")
        XCTAssertNil(response.accountId)
    }

    func testParseRevokeSponsorshipOperationResponseForTrustline() throws {
        let additionalFields = """
"trustline_account_id": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "trustline_asset": "USDC:GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
"""
        let json = baseOperationJSON(typeI: 18, type: "revoke_sponsorship", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(RevokeSponsorshipOperationResponse.self, from: jsonData)

        // Verify specific fields
        XCTAssertEqual(response.trustlineAccountId, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.trustlineAsset, "USDC:GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertNil(response.accountId)
    }

    func testParseRevokeSponsorshipOperationResponseForSigner() throws {
        let additionalFields = """
"signer_account_id": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "signer_key": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
"""
        let json = baseOperationJSON(typeI: 18, type: "revoke_sponsorship", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(RevokeSponsorshipOperationResponse.self, from: jsonData)

        // Verify specific fields
        XCTAssertEqual(response.signerAccountId, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.signerKey, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertNil(response.accountId)
    }

    // MARK: - SetTrustLineFlagsOperationResponse Tests

    func testParseSetTrustLineFlagsOperationResponse() throws {
        let additionalFields = """
"trustor": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "set_flags": [1, 2],
            "set_flags_s": ["authorized", "authorized_to_maintain_liabilities"],
            "clear_flags": [4],
            "clear_flags_s": ["clawback_enabled"]
"""
        let json = baseOperationJSON(typeI: 21, type: "set_trust_line_flags", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(SetTrustLineFlagsOperationResponse.self, from: jsonData)

        // Verify base operation fields
        XCTAssertEqual(response.operationType, OperationType.setTrustLineFlags)
        XCTAssertEqual(response.operationTypeString, "set_trust_line_flags")

        // Verify specific fields
        XCTAssertEqual(response.trustor, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.assetType, "credit_alphanum4")
        XCTAssertEqual(response.assetCode, "USD")
        XCTAssertEqual(response.assetIssuer, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")

        // Verify flags
        XCTAssertEqual(response.setFlags, [1, 2])
        XCTAssertEqual(response.setFlagsS, ["authorized", "authorized_to_maintain_liabilities"])
        XCTAssertEqual(response.clearFlags, [4])
        XCTAssertEqual(response.clearFlagsS, ["clawback_enabled"])
    }

    func testParseSetTrustLineFlagsOperationResponseWithNoFlags() throws {
        let additionalFields = """
"trustor": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "asset_type": "credit_alphanum12",
            "asset_code": "LONGASSET",
            "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY"
"""
        let json = baseOperationJSON(typeI: 21, type: "set_trust_line_flags", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(SetTrustLineFlagsOperationResponse.self, from: jsonData)

        // Verify flags are nil
        XCTAssertNil(response.setFlags)
        XCTAssertNil(response.setFlagsS)
        XCTAssertNil(response.clearFlags)
        XCTAssertNil(response.clearFlagsS)
        XCTAssertEqual(response.assetType, "credit_alphanum12")
        XCTAssertEqual(response.assetCode, "LONGASSET")
    }

    func testParseSetTrustLineFlagsOperationResponseWithNativeAsset() throws {
        let additionalFields = """
"trustor": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "asset_type": "native"
"""
        let json = baseOperationJSON(typeI: 21, type: "set_trust_line_flags", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(SetTrustLineFlagsOperationResponse.self, from: jsonData)

        // Verify native asset handling
        XCTAssertEqual(response.assetType, "native")
        XCTAssertNil(response.assetCode)
        XCTAssertNil(response.assetIssuer)
    }

    // MARK: - Links Validation Tests

    func testOperationLinksAreParsedCorrectly() throws {
        let additionalFields = """
"sponsored_id": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO"
"""
        let json = baseOperationJSON(typeI: 16, type: "begin_sponsoring_future_reserves", additionalFields: additionalFields)

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(BeginSponsoringFutureReservesOperationResponse.self, from: jsonData)

        // Verify links
        XCTAssertEqual(response.links.selfLink.href, "https://horizon-testnet.stellar.org/operations/12345")
        XCTAssertEqual(response.links.effects.href, "https://horizon-testnet.stellar.org/operations/12345/effects{?cursor,limit,order}")
        XCTAssertEqual(response.links.effects.templated, true)
        XCTAssertEqual(response.links.transaction.href, "https://horizon-testnet.stellar.org/transactions/abc123")
        XCTAssertEqual(response.links.precedes.href, "https://horizon-testnet.stellar.org/operations?cursor=12345&order=asc")
        XCTAssertEqual(response.links.succeeds.href, "https://horizon-testnet.stellar.org/operations?cursor=12345&order=desc")
    }

    // MARK: - ParameterResponse Tests

    func testParseParameterResponse() throws {
        let json = """
        {
            "type": "Uint128",
            "value": "18446744073709551615"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ParameterResponse.self, from: jsonData)

        XCTAssertEqual(response.type, "Uint128")
        XCTAssertEqual(response.value, "18446744073709551615")
    }

    // MARK: - AssetBalanceChange Tests

    func testParseAssetBalanceChange() throws {
        let json = """
        {
            "asset_type": "credit_alphanum4",
            "asset_code": "USDC",
            "asset_issuer": "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY",
            "type": "burn",
            "to": "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO",
            "amount": "1000.0000000"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AssetBalanceChange.self, from: jsonData)

        XCTAssertEqual(response.assetType, "credit_alphanum4")
        XCTAssertEqual(response.assetCode, "USDC")
        XCTAssertEqual(response.assetIssuer, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.type, "burn")
        XCTAssertNil(response.from)
        XCTAssertEqual(response.to, "GBIA4FH6TV64KSPDAJCNUQSM7PFL4ILGUVJDPCLUOPJ7ONMKBBVUQHRO")
        XCTAssertEqual(response.amount, "1000.0000000")
        XCTAssertNil(response.destinationMuxedId)
    }

    // MARK: - Source Account Muxed Tests

    func testParseOperationWithSourceAccountMuxed() throws {
        let json = """
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
            "source_account_muxed": "MDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWAAAAAAAAAPCIBQOY",
            "source_account_muxed_id": "1234567890123",
            "type": "bump_sequence",
            "type_i": 11,
            "created_at": "2023-01-15T10:00:00Z",
            "transaction_hash": "abc123def456789",
            "transaction_successful": true,
            "bump_to": "999999999"
        }
        """

        let jsonData = json.data(using: .utf8)!
        let response = try createDecoder().decode(BumpSequenceOperationResponse.self, from: jsonData)

        XCTAssertEqual(response.sourceAccount, "GDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWPS6JY")
        XCTAssertEqual(response.sourceAccountMuxed, "MDWGJSTUVRNFTR7STPUUHFWQYAN6KBVWCZT2YN7MY276GCSSXSWAAAAAAAAAPCIBQOY")
        XCTAssertEqual(response.sourceAccountMuxedId, "1234567890123")
    }
}
