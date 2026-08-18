//
//  CreatedClaimableBalanceIdUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Christian Rogobete.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// The claimable balance id a submitted transaction reports for its CreateClaimableBalance
/// operations.
final class CreatedClaimableBalanceIdUnitTests: XCTestCase {

    /// Two CreateClaimableBalance operations, one at each index.
    private let twoCreates = "AAAAAAAAAMgAAAAAAAAAAgAAAAAAAAAOAAAAAAAAAAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAAAAAAAOAAAAAAAAAAD16n+z3hja6fEq+WzwdQdJAW+8umvwnpAqaeVFaHcdggAAAAA="

    /// A payment at index 0, a CreateClaimableBalance at index 1.
    private let paymentThenCreate = "AAAAAAAAAMgAAAAAAAAAAgAAAAAAAAABAAAAAAAAAAAAAAAOAAAAAAAAAAD16n+z3hja6fEq+WzwdQdJAW+8umvwnpAqaeVFaHcdggAAAAA="

    /// A fee bump wrapping a transaction whose only operation creates a claimable balance.
    private let feeBump = "AAAAAAAAAZAAAAABMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMAAAAAAAAAyAAAAAAAAAABAAAAAAAAAA4AAAAAAAAAAPXqf7PeGNrp8Sr5bPB1B0kBb7y6a/CekCpp5UVodx2CAAAAAAAAAAA="

    /// A transaction that failed, its only operation a CreateClaimableBalance that was not
    /// authorized.
    private let failed = "AAAAAAAAAMj/////AAAAAQAAAAAAAAAO/////AAAAAA="

    /// A transaction that failed on the payment at index 1, after the CreateClaimableBalance at
    /// index 0 had succeeded and its result had taken a balance id.
    private let failedAfterCreate = "AAAAAAAAAMj/////AAAAAgAAAAAAAAAOAAAAAAAAAAD16n+z3hja6fEq+WzwdQdJAW+8umvwnpAqaeVFaHcdggAAAAAAAAAB////+wAAAAA="

    /// A fee bump whose inner transaction failed, its only operation a CreateClaimableBalance
    /// whose result took a balance id.
    private let feeBumpInnerFailed = "AAAAAAAAAZD////zMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMAAAAAAAAAyP////8AAAABAAAAAAAAAA4AAAAAAAAAAPXqf7PeGNrp8Sr5bPB1B0kBb7y6a/CekCpp5UVodx2CAAAAAAAAAAA="

    /// A transaction rejected for its sequence number, a result that carries no operation
    /// results at all.
    private let badSeq = "AAAAAAAAAGT////7AAAAAA=="

    private let firstBalanceId = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
    private let secondBalanceId = "BAAPL2T7WPPBRWXJ6EVPS3HQOUDUSALPXS5GX4E6SAVGTZKFNB3R3ATZWM"

    /// Builds a submit response carrying `resultXdr`. Every other field holds what Horizon
    /// serves for a transaction; only the result is read for the balance id.
    private func response(resultXdr: String) throws -> SubmitTransactionResponse {
        let json = """
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
          "result_xdr": "\(resultXdr)",
          "memo_type": "none",
          "signatures": ["9mofj/v3nFoJpHpImh/lmmV6C3zm0IISI62arI1MurcDkDzo43iR6pNBtPGxHlcYd1ZhOHWyaWGfFrYTsxarAA=="]
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
        return try decoder.decode(SubmitTransactionResponse.self, from: Data(json.utf8))
    }

    /// Asserts the operation result at `operationIndex` took `secondBalanceId`, read past the
    /// result code the helper gates on. A nil answer from the helper for such a fixture can
    /// then only come from that gate.
    private func assertOperationResultTookTheBalanceId(_ operationResults: [OperationResultXDR],
                                                       at operationIndex: Int,
                                                       line: UInt = #line) {
        guard operationResults.indices.contains(operationIndex),
              case .tr(let operationResult) = operationResults[operationIndex],
              case .createClaimableBalanceResult(.balanceID(let balanceId)) = operationResult else {
            XCTFail("no CreateClaimableBalance result at index \(operationIndex)", line: line)
            return
        }
        XCTAssertEqual(try? balanceId.claimableBalanceIdString.encodeClaimableBalanceIdHex(),
                       secondBalanceId, line: line)
    }

    func testReportsTheBalanceIdOfEachOperation() throws {
        let response = try response(resultXdr: twoCreates)
        XCTAssertEqual(response.getCreatedClaimableBalanceId(), firstBalanceId)
        XCTAssertEqual(response.getCreatedClaimableBalanceId(operationIndex: 0), firstBalanceId)
        XCTAssertEqual(response.getCreatedClaimableBalanceId(operationIndex: 1), secondBalanceId)
    }

    func testAnswersNilForAnOperationThatCreatesNoBalance() throws {
        let response = try response(resultXdr: paymentThenCreate)
        XCTAssertNil(response.getCreatedClaimableBalanceId())
        XCTAssertEqual(response.getCreatedClaimableBalanceId(operationIndex: 1), secondBalanceId)
    }

    func testAnswersNilForAnIndexNoOperationSitsAt() throws {
        let response = try response(resultXdr: twoCreates)
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: 2))
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: Int.max))
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: -1))
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: Int.min))
    }

    func testReadsTheInnerOperationsOfAFeeBump() throws {
        let response = try response(resultXdr: feeBump)
        XCTAssertEqual(response.getCreatedClaimableBalanceId(), secondBalanceId)
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: 1))
    }

    func testAnswersNilForATransactionThatDidNotSucceed() throws {
        let response = try response(resultXdr: failed)
        XCTAssertNil(response.getCreatedClaimableBalanceId())
    }

    /// The result code alone decides: a transaction that failed reports no balance id, even
    /// where the operation result at the index took one that reads back.
    func testAnswersNilForAFailedTransactionWhoseOperationTookABalanceId() throws {
        let response = try response(resultXdr: failedAfterCreate)
        guard case .failed(let operationResults) = response.transactionResult.result else {
            XCTFail("fixture is not a failed transaction")
            return
        }
        assertOperationResultTookTheBalanceId(operationResults, at: 0)

        XCTAssertNil(response.getCreatedClaimableBalanceId())
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: 0))
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: 1))
    }

    /// The result code of the inner transaction decides for a fee bump, so a fee bump whose
    /// inner transaction failed reports no balance id.
    func testAnswersNilForAFeeBumpWhoseInnerTransactionFailed() throws {
        let response = try response(resultXdr: feeBumpInnerFailed)
        guard case .feeBumpInnerFailed(let pair) = response.transactionResult.result,
              case .failed(let operationResults) = pair.result.result else {
            XCTFail("fixture is not a fee bump wrapping a failed transaction")
            return
        }
        assertOperationResultTookTheBalanceId(operationResults, at: 0)

        XCTAssertNil(response.getCreatedClaimableBalanceId())
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: 0))
    }

    /// A result code that carries no operation results at all reports no balance id.
    func testAnswersNilForAResultThatCarriesNoOperationResults() throws {
        let response = try response(resultXdr: badSeq)
        guard case .badSeq = response.transactionResult.result else {
            XCTFail("fixture is not a bad sequence number result")
            return
        }
        XCTAssertNil(response.getCreatedClaimableBalanceId())
        XCTAssertNil(response.getCreatedClaimableBalanceId(operationIndex: 0))
    }
}
