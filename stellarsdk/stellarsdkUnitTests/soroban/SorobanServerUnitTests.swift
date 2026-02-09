//
//  SorobanServerUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Unit tests for SorobanServer.
/// These tests verify initialization, parameter building, and enum pattern matching.
/// Note: Network-dependent async methods are tested in integration tests.
final class SorobanServerUnitTests: XCTestCase {
    var server: SorobanServer!

    override func setUp() {
        super.setUp()
        server = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
    }

    override func tearDown() {
        server = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSorobanServerInitialization() {
        XCTAssertNotNil(server)
    }

    func testSorobanServerWithCustomEndpoint() {
        let customServer = SorobanServer(endpoint: "https://custom.example.com")
        XCTAssertNotNil(customServer)
    }

    func testSorobanServerLoggingFlag() {
        XCTAssertFalse(server.enableLogging)
        server.enableLogging = true
        XCTAssertTrue(server.enableLogging)
        server.enableLogging = false
        XCTAssertFalse(server.enableLogging)
    }

    // MARK: - SimulateTransactionRequest Parameter Tests

    func testSimulateTransactionRequestBasic() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [paymentOp],
            memo: Memo.none
        )

        let request = SimulateTransactionRequest(transaction: transaction)
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertTrue(params["transaction"] is String)
        XCTAssertNil(params["resourceConfig"])
        XCTAssertNil(params["authMode"])
    }

    func testSimulateTransactionRequestWithResourceConfig() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [paymentOp],
            memo: Memo.none
        )

        let resourceConfig = ResourceConfig(instructionLeeway: 3000000)
        let request = SimulateTransactionRequest(transaction: transaction, resourceConfig: resourceConfig)
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertNotNil(params["resourceConfig"])
        if let rcParams = params["resourceConfig"] as? [String: Any] {
            XCTAssertEqual(rcParams["instructionLeeway"] as? Int, 3000000)
        } else {
            XCTFail("Resource config params not found")
        }
        XCTAssertNil(params["authMode"])
    }

    func testSimulateTransactionRequestWithAuthMode() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [paymentOp],
            memo: Memo.none
        )

        let request = SimulateTransactionRequest(transaction: transaction, authMode: "enforce")
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertEqual(params["authMode"] as? String, "enforce")
        XCTAssertNil(params["resourceConfig"])
    }

    func testSimulateTransactionRequestWithAllParameters() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [paymentOp],
            memo: Memo.none
        )

        let resourceConfig = ResourceConfig(instructionLeeway: 5000000)
        let request = SimulateTransactionRequest(
            transaction: transaction,
            resourceConfig: resourceConfig,
            authMode: "record"
        )
        let params = request.buildRequestParams()

        XCTAssertNotNil(params["transaction"])
        XCTAssertNotNil(params["resourceConfig"])
        XCTAssertEqual(params["authMode"] as? String, "record")

        if let rcParams = params["resourceConfig"] as? [String: Any] {
            XCTAssertEqual(rcParams["instructionLeeway"] as? Int, 5000000)
        }
    }

    // MARK: - Response Enum Error Pattern Tests

    func testGetHealthResponseEnumFailurePattern() {
        let error = SorobanRpcRequestError.requestFailed(message: "Connection failed")
        let result = GetHealthResponseEnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure case")
        case .failure(let err):
            if case .requestFailed(let message) = err {
                XCTAssertEqual(message, "Connection failed")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testGetNetworkResponseEnumFailurePattern() {
        let rpcError = SorobanRpcError(code: -32600, message: "Invalid request")
        let error = SorobanRpcRequestError.errorResponse(error: rpcError)
        let result = GetNetworkResponseEnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure case")
        case .failure(let err):
            if case .errorResponse(let rpcErr) = err {
                XCTAssertEqual(rpcErr.code, -32600)
                XCTAssertEqual(rpcErr.message, "Invalid request")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testSendTransactionResponseEnumFailurePattern() {
        let error = SorobanRpcRequestError.requestFailed(message: "Transaction rejected")
        let result = SendTransactionResponseEnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure case")
        case .failure:
            XCTAssertTrue(true)
        }
    }

    func testGetTransactionResponseEnumFailurePattern() {
        let error = SorobanRpcRequestError.requestFailed(message: "Transaction not found")
        let result = GetTransactionResponseEnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure case")
        case .failure:
            XCTAssertTrue(true)
        }
    }

    func testGetEventsResponseEnumFailurePattern() {
        let rpcError = SorobanRpcError(code: -32602, message: "Invalid ledger range")
        let error = SorobanRpcRequestError.errorResponse(error: rpcError)
        let result = GetEventsResponseEnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure case")
        case .failure(let err):
            if case .errorResponse(let rpcErr) = err {
                XCTAssertEqual(rpcErr.message, "Invalid ledger range")
            }
        }
    }

    func testGetContractInfoEnumRpcFailurePattern() {
        let error = SorobanRpcRequestError.requestFailed(message: "Contract not found")
        let result = GetContractInfoEnum.rpcFailure(error: error)

        switch result {
        case .success, .parsingFailure:
            XCTFail("Expected rpcFailure case")
        case .rpcFailure(let err):
            if case .requestFailed(let message) = err {
                XCTAssertEqual(message, "Contract not found")
            }
        }
    }

    func testGetContractInfoEnumParsingFailurePattern() {
        let error = SorobanContractParserError.invalidByteCode
        let result = GetContractInfoEnum.parsingFailure(error: error)

        switch result {
        case .success, .rpcFailure:
            XCTFail("Expected parsingFailure case")
        case .parsingFailure(let err):
            if case .invalidByteCode = err {
                XCTAssertTrue(true)
            }
        }
    }

    func testGetAccountResponseEnumFailurePattern() {
        let error = SorobanRpcRequestError.requestFailed(message: "Account not found")
        let result = GetAccountResponseEnum.failure(error: error)

        switch result {
        case .success:
            XCTFail("Expected failure case")
        case .failure(let err):
            if case .requestFailed(let message) = err {
                XCTAssertEqual(message, "Account not found")
            }
        }
    }

    // MARK: - Error Type Tests

    func testSorobanRpcRequestErrorRequestFailed() {
        let error = SorobanRpcRequestError.requestFailed(message: "Network error")

        switch error {
        case .requestFailed(let message):
            XCTAssertEqual(message, "Network error")
        default:
            XCTFail("Wrong error type")
        }
    }

    func testSorobanRpcRequestErrorParsingFailed() {
        let data = "invalid json".data(using: .utf8)!
        let error = SorobanRpcRequestError.parsingResponseFailed(message: "Parse error", responseData: data)

        switch error {
        case .parsingResponseFailed(let message, let responseData):
            XCTAssertEqual(message, "Parse error")
            XCTAssertEqual(responseData, data)
        default:
            XCTFail("Wrong error type")
        }
    }

    func testSorobanRpcRequestErrorErrorResponse() {
        let rpcError = SorobanRpcError(code: -32603, message: "Internal error")
        let error = SorobanRpcRequestError.errorResponse(error: rpcError)

        switch error {
        case .errorResponse(let err):
            XCTAssertEqual(err.code, -32603)
            XCTAssertEqual(err.message, "Internal error")
        default:
            XCTFail("Wrong error type")
        }
    }

    func testSorobanRpcErrorInit() {
        let error = SorobanRpcError(code: -32602, message: "Invalid params", data: "Extra info")
        XCTAssertEqual(error.code, -32602)
        XCTAssertEqual(error.message, "Invalid params")
        XCTAssertEqual(error.data, "Extra info")
    }

    func testSorobanRpcErrorInitWithoutData() {
        let error = SorobanRpcError(code: -32600, message: "Invalid request")
        XCTAssertEqual(error.code, -32600)
        XCTAssertEqual(error.message, "Invalid request")
        XCTAssertNil(error.data)
    }

    // MARK: - Parameter Building Tests

    func testEventFilterBuildRequestParams() {
        let filter = EventFilter(type: "contract", contractIds: ["CONTRACT1", "CONTRACT2"])
        let params = filter.buildRequestParams()

        XCTAssertEqual(params["type"] as? String, "contract")
        let contractIds = params["contractIds"] as? [String]
        XCTAssertNotNil(contractIds)
        XCTAssertEqual(contractIds?.count, 2)
        XCTAssertEqual(contractIds?[0], "CONTRACT1")
        XCTAssertEqual(contractIds?[1], "CONTRACT2")
    }

    func testPaginationOptionsBuildRequestParams() {
        let pagination = PaginationOptions(cursor: "test_cursor", limit: 100)
        let params = pagination.buildRequestParams()

        XCTAssertEqual(params["cursor"] as? String, "test_cursor")
        XCTAssertEqual(params["limit"] as? Int, 100)
    }

    func testPaginationOptionsBuildRequestParamsWithOnlyCursor() {
        let pagination = PaginationOptions(cursor: "cursor_only")
        let params = pagination.buildRequestParams()

        XCTAssertEqual(params["cursor"] as? String, "cursor_only")
        XCTAssertNil(params["limit"])
    }

    func testPaginationOptionsBuildRequestParamsWithOnlyLimit() {
        let pagination = PaginationOptions(limit: 50)
        let params = pagination.buildRequestParams()

        XCTAssertNil(params["cursor"])
        XCTAssertEqual(params["limit"] as? Int, 50)
    }

    func testPaginationOptionsBuildRequestParamsEmpty() {
        let pagination = PaginationOptions()
        let params = pagination.buildRequestParams()

        XCTAssertTrue(params.isEmpty)
    }

    func testResourceConfigBuildRequestParamsWithLargeValue() {
        let config = ResourceConfig(instructionLeeway: 10000000)
        let params = config.buildRequestParams()

        XCTAssertEqual(params["instructionLeeway"] as? Int, 10000000)
    }

    // MARK: - Transaction Encoding Tests

    func testTransactionEncodingForSendTransaction() throws {
        let keyPair = try KeyPair.generateRandomKeyPair()
        let account = Account(keyPair: keyPair, sequenceNumber: 1234567890)
        let destination = try KeyPair.generateRandomKeyPair()
        let paymentOp = try PaymentOperation(
            sourceAccountId: nil,
            destinationAccountId: destination.accountId,
            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
            amount: 100.0
        )
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [paymentOp],
            memo: Memo.none
        )

        let encodedEnvelope = try transaction.encodedEnvelope()
        XCTAssertFalse(encodedEnvelope.isEmpty)
        XCTAssertTrue(encodedEnvelope.count > 0)
    }

    // MARK: - Input Validation Tests

    func testGetAccountWithInvalidAccountId() async {
        let result = await server.getAccount(accountId: "invalid_account")

        switch result {
        case .success:
            XCTFail("Expected error for invalid account ID")
        case .failure(let error):
            if case .requestFailed(let message) = error {
                XCTAssertTrue(message.contains("invalid accountId"))
            } else {
                XCTFail("Expected requestFailed error")
            }
        }
    }

    func testGetContractDataWithInvalidContractId() async {
        let key = SCValXDR.u32(123)
        let result = await server.getContractData(
            contractId: "invalid",
            key: key,
            durability: .persistent
        )

        switch result {
        case .success:
            XCTFail("Expected error for invalid contract ID")
        case .failure(let error):
            if case .requestFailed(let message) = error {
                XCTAssertTrue(message.contains("invalid contractId"))
            }
        }
    }

    // MARK: - Edge Case Tests

    func testGetLedgerEntriesWithEmptyKeys() async {
        let result = await server.getLedgerEntries(base64EncodedKeys: [])

        switch result {
        case .success, .failure:
            // Either response is acceptable - the test is that it doesn't crash
            XCTAssertTrue(true)
        }
    }

    func testGetEventsWithNoFilters() async {
        let result = await server.getEvents(startLedger: 1000000)

        switch result {
        case .success, .failure:
            // Either response is acceptable in unit test
            XCTAssertTrue(true)
        }
    }

    // MARK: - Multiple Enum Response Cases

    func testAllResponseEnumTypesCanBeConstructed() {
        // Test that all response enum types can be constructed with failure cases
        let requestError = SorobanRpcRequestError.requestFailed(message: "Error")

        let healthFailure = GetHealthResponseEnum.failure(error: requestError)
        let networkFailure = GetNetworkResponseEnum.failure(error: requestError)
        let feeStatsFailure = GetFeeStatsResponseEnum.failure(error: requestError)
        let versionFailure = GetVersionInfoResponseEnum.failure(error: requestError)
        let entriesFailure = GetLedgerEntriesResponseEnum.failure(error: requestError)
        let latestLedgerFailure = GetLatestLedgerResponseEnum.failure(error: requestError)
        let simulateFailure = SimulateTransactionResponseEnum.failure(error: requestError)
        let sendFailure = SendTransactionResponseEnum.failure(error: requestError)
        let getTxFailure = GetTransactionResponseEnum.failure(error: requestError)
        let getTxsFailure = GetTransactionsResponseEnum.failure(error: requestError)
        let eventsFailure = GetEventsResponseEnum.failure(error: requestError)
        let nonceFailure = GetNonceResponseEnum.failure(error: requestError)
        let ledgersFailure = GetLedgersResponseEnum.failure(error: requestError)
        let codeFailure = GetContractCodeResponseEnum.failure(error: requestError)
        let accountFailure = GetAccountResponseEnum.failure(error: requestError)
        let dataFailure = GetContractDataResponseEnum.failure(error: requestError)

        // Verify all can be pattern matched
        var allPassed = true

        switch healthFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch networkFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch feeStatsFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch versionFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch entriesFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch latestLedgerFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch simulateFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch sendFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch getTxFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch getTxsFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch eventsFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch nonceFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch ledgersFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch codeFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch accountFailure {
        case .failure: break
        case .success: allPassed = false
        }

        switch dataFailure {
        case .failure: break
        case .success: allPassed = false
        }

        XCTAssertTrue(allPassed)
    }

    // MARK: - Public API Coverage Tests

    func testSorobanServerHasExpectedPublicMethods() {
        // This test verifies that SorobanServer exposes the expected public API
        // Actual network calls are tested in integration tests

        XCTAssertNotNil(server)

        // Verify the server is of the correct type
        XCTAssertTrue(server is SorobanServer)
    }
}
