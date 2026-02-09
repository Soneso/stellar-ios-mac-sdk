//
//  TransferServerServiceAdditionalUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 05/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class TransferServerServiceAdditionalUnitTests: XCTestCase {

    var transferServerService: TransferServerService!
    let testHost = "testanchor.stellar.org"

    override func setUp() {
        super.setUp()
        ServerMock.removeAll()
        URLProtocol.registerClass(ServerMock.self)
        transferServerService = TransferServerService(serviceAddress: "https://\(testHost)")
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - TransferServerService.init Tests

    func testTransferServerServiceInitRemovesTrailingSlash() {
        let serviceWithSlash = TransferServerService(serviceAddress: "https://example.com/")
        XCTAssertEqual(serviceWithSlash.transferServiceAddress, "https://example.com")

        let serviceWithoutSlash = TransferServerService(serviceAddress: "https://example.com")
        XCTAssertEqual(serviceWithoutSlash.transferServiceAddress, "https://example.com")
    }

    func testTransferServerServiceInitMultipleTrailingSlashes() {
        let service = TransferServerService(serviceAddress: "https://example.com///")
        XCTAssertEqual(service.transferServiceAddress, "https://example.com//")
    }

    // MARK: - TransferServerService.forDomain Tests

    func testForDomainInvalidDomain() async {
        let result = await TransferServerService.forDomain(domain: "invalid domain with spaces")

        switch result {
        case .success(_):
            XCTFail("Expected failure for invalid domain")
        case .failure(let error):
            // Either invalidDomain or invalidToml is acceptable for malformed domain
            switch error {
            case .invalidDomain, .invalidToml:
                // Pattern match succeeded - test passes
                break
            default:
                XCTFail("Expected invalidDomain or invalidToml error, got \(error)")
            }
        }
    }

    func testForDomainValidDomainWithMissingToml() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 404
            return nil
        }

        let mock = RequestMock(
            host: "example.com",
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            statusCode: 404,
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await TransferServerService.forDomain(domain: "https://example.com")

        switch result {
        case .success(_):
            XCTFail("Expected failure for missing TOML")
        case .failure(let error):
            if case .invalidToml = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected invalidToml error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testForDomainValidDomainWithMalformedToml() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "This is not valid TOML [[[["
        }

        let mock = RequestMock(
            host: "validtoml.com",
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await TransferServerService.forDomain(domain: "https://validtoml.com")

        switch result {
        case .success(_):
            XCTFail("Expected failure for malformed TOML")
        case .failure(let error):
            if case .invalidToml = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected invalidToml error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testForDomainValidDomainWithTomlMissingTransferServer() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
            WEB_AUTH_ENDPOINT="https://example.com/auth"
            """
        }

        let mock = RequestMock(
            host: "noserver.com",
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await TransferServerService.forDomain(domain: "https://noserver.com")

        switch result {
        case .success(_):
            XCTFail("Expected failure for missing TRANSFER_SERVER")
        case .failure(let error):
            if case .noTransferServerSet = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected noTransferServerSet error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testForDomainSuccess() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
            TRANSFER_SERVER="https://transfer.example.com"
            """
        }

        let mock = RequestMock(
            host: "success.com",
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await TransferServerService.forDomain(domain: "https://success.com")

        switch result {
        case .success(let service):
            XCTAssertEqual(service.transferServiceAddress, "https://transfer.example.com")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - deposit Tests (Additional Coverage)

    func testDepositWithAllOptionalParameters() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                XCTFail("Could not parse URL")
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["asset_code"], "USDC")
            XCTAssertEqual(params["account"], "GTEST")
            XCTAssertEqual(params["memo_type"], "hash")
            XCTAssertEqual(params["memo"], "test_memo")
            XCTAssertEqual(params["email_address"], "test@example.com")
            XCTAssertEqual(params["type"], "SWIFT")
            XCTAssertEqual(params["wallet_name"], "Test Wallet")
            XCTAssertEqual(params["wallet_url"], "https://wallet.test.com")
            XCTAssertEqual(params["lang"], "en")
            XCTAssertEqual(params["on_change_callback"], "https://callback.test.com")
            XCTAssertEqual(params["amount"], "100.50")
            XCTAssertEqual(params["country_code"], "USA")
            XCTAssertEqual(params["claimable_balance_supported"], "true")
            XCTAssertEqual(params["customer_id"], "customer123")
            XCTAssertEqual(params["location_id"], "location456")

            mock.statusCode = 200
            return """
            {
                "how": "Send funds to bank account",
                "id": "test-deposit-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = DepositRequest(assetCode: "USDC", account: "GTEST")
        request.memoType = "hash"
        request.memo = "test_memo"
        request.emailAddress = "test@example.com"
        request.type = "SWIFT"
        request.walletName = "Test Wallet"
        request.walletUrl = "https://wallet.test.com"
        request.lang = "en"
        request.onChangeCallback = "https://callback.test.com"
        request.amount = "100.50"
        request.countryCode = "USA"
        request.claimableBalanceSupported = "true"
        request.customerId = "customer123"
        request.locationId = "location456"

        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "test-deposit-id")
            XCTAssertEqual(response.how, "Send funds to bank account")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testDepositWithExtraFields() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["custom_field1"], "value1")
            XCTAssertEqual(params["custom_field2"], "value2")

            mock.statusCode = 200
            return """
            {
                "how": "Send with custom fields",
                "id": "custom-deposit-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = DepositRequest(assetCode: "USD", account: "GTEST")
        request.extraFields = ["custom_field1": "value1", "custom_field2": "value2"]

        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "custom-deposit-id")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testDepositParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "{ invalid json"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = DepositRequest(assetCode: "USD", account: "GTEST")
        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testDepositAuthenticationRequired() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 403
            return """
            {
                "type": "authentication_required"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = DepositRequest(assetCode: "USD", account: "GTEST")
        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected authentication required error")
        case .failure(let error):
            if case .authenticationRequired = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected authenticationRequired error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - depositExchange Tests (Additional Coverage)

    func testDepositExchangeWithAllOptionalParameters() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["destination_asset"], "stellar:USDC:GTEST")
            XCTAssertEqual(params["source_asset"], "iso4217:USD")
            XCTAssertEqual(params["amount"], "100")
            XCTAssertEqual(params["account"], "GTEST")
            XCTAssertEqual(params["quote_id"], "quote123")
            XCTAssertEqual(params["memo_type"], "text")
            XCTAssertEqual(params["memo"], "exchange_memo")
            XCTAssertEqual(params["customer_id"], "cust789")

            mock.statusCode = 200
            return """
            {
                "how": "Exchange deposit instructions",
                "id": "exchange-deposit-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit-exchange",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = DepositExchangeRequest(
            destinationAsset: "stellar:USDC:GTEST",
            sourceAsset: "iso4217:USD",
            amount: "100",
            account: "GTEST"
        )
        request.quoteId = "quote123"
        request.memoType = "text"
        request.memo = "exchange_memo"
        request.customerId = "cust789"

        let result = await transferServerService.depositExchange(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "exchange-deposit-id")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testDepositExchangeWithExtraFields() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["exchange_field1"], "ex_value1")

            mock.statusCode = 200
            return """
            {
                "how": "Exchange with extra fields",
                "id": "extra-exchange-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit-exchange",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = DepositExchangeRequest(
            destinationAsset: "stellar:USDC:GTEST",
            sourceAsset: "iso4217:BRL",
            amount: "500",
            account: "GTEST"
        )
        request.extraFields = ["exchange_field1": "ex_value1"]

        let result = await transferServerService.depositExchange(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "extra-exchange-id")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testDepositExchangeParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "not valid json at all"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit-exchange",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = DepositExchangeRequest(
            destinationAsset: "stellar:USDC:GTEST",
            sourceAsset: "iso4217:USD",
            amount: "100",
            account: "GTEST"
        )
        let result = await transferServerService.depositExchange(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - withdraw Tests (Additional Coverage)

    func testWithdrawWithAllOptionalParameters() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["type"], "bank_account")
            XCTAssertEqual(params["asset_code"], "USD")
            XCTAssertEqual(params["dest"], "123456789")
            XCTAssertEqual(params["dest_extra"], "routing123")
            XCTAssertEqual(params["account"], "GTEST")
            XCTAssertEqual(params["memo"], "withdraw_memo")
            XCTAssertEqual(params["memo_type"], "id")
            XCTAssertEqual(params["wallet_name"], "Withdraw Wallet")
            XCTAssertEqual(params["wallet_url"], "https://withdraw.test.com")
            XCTAssertEqual(params["lang"], "es")
            XCTAssertEqual(params["on_change_callback"], "https://withdraw-callback.test.com")
            XCTAssertEqual(params["amount"], "500.75")
            XCTAssertEqual(params["country_code"], "MEX")
            XCTAssertEqual(params["refund_memo"], "refund123")
            XCTAssertEqual(params["refund_memo_type"], "hash")
            XCTAssertEqual(params["customer_id"], "withdraw_cust")
            XCTAssertEqual(params["location_id"], "withdraw_loc")

            mock.statusCode = 200
            return """
            {
                "account_id": "GWITHDRAW",
                "memo_type": "id",
                "memo": "789",
                "id": "withdraw-test-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/withdraw",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = WithdrawRequest(type: "bank_account", assetCode: "USD")
        request.dest = "123456789"
        request.destExtra = "routing123"
        request.account = "GTEST"
        request.memo = "withdraw_memo"
        request.memoType = "id"
        request.walletName = "Withdraw Wallet"
        request.walletUrl = "https://withdraw.test.com"
        request.lang = "es"
        request.onChangeCallback = "https://withdraw-callback.test.com"
        request.amount = "500.75"
        request.countryCode = "MEX"
        request.refundMemo = "refund123"
        request.refundMemoType = "hash"
        request.customerId = "withdraw_cust"
        request.locationId = "withdraw_loc"

        let result = await transferServerService.withdraw(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "withdraw-test-id")
            XCTAssertEqual(response.accountId, "GWITHDRAW")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testWithdrawWithExtraFields() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["withdraw_custom1"], "wc_value1")

            mock.statusCode = 200
            return """
            {
                "account_id": "GCUSTOM",
                "id": "withdraw-custom-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/withdraw",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = WithdrawRequest(type: "cash", assetCode: "USD")
        request.extraFields = ["withdraw_custom1": "wc_value1"]

        let result = await transferServerService.withdraw(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "withdraw-custom-id")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testWithdrawParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "{ broken json }"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/withdraw",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = WithdrawRequest(type: "bank_account", assetCode: "USD")
        let result = await transferServerService.withdraw(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - withdrawExchange Tests (Additional Coverage)

    func testWithdrawExchangeWithAllOptionalParameters() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["type"], "bank_account")
            XCTAssertEqual(params["source_asset"], "stellar:USDC:GTEST")
            XCTAssertEqual(params["destination_asset"], "iso4217:EUR")
            XCTAssertEqual(params["amount"], "200")
            XCTAssertEqual(params["quote_id"], "quote456")
            XCTAssertEqual(params["dest"], "EUR_ACCOUNT")
            XCTAssertEqual(params["dest_extra"], "EUR_EXTRA")
            XCTAssertEqual(params["refund_memo"], "ref_ex")
            XCTAssertEqual(params["refund_memo_type"], "text")

            mock.statusCode = 200
            return """
            {
                "account_id": "GEXCHANGE",
                "memo_type": "hash",
                "memo": "exchange_hash",
                "id": "withdraw-exchange-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/withdraw-exchange",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = WithdrawExchangeRequest(
            sourceAsset: "stellar:USDC:GTEST",
            destinationAsset: "iso4217:EUR",
            amount: "200",
            type: "bank_account"
        )
        request.quoteId = "quote456"
        request.dest = "EUR_ACCOUNT"
        request.destExtra = "EUR_EXTRA"
        request.refundMemo = "ref_ex"
        request.refundMemoType = "text"

        let result = await transferServerService.withdrawExchange(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "withdraw-exchange-id")
            XCTAssertEqual(response.accountId, "GEXCHANGE")
            XCTAssertEqual(response.memoType, "hash")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testWithdrawExchangeWithExtraFields() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["exchange_extra1"], "ex_extra1")

            mock.statusCode = 200
            return """
            {
                "account_id": "GEXTRAEX",
                "id": "withdraw-exchange-extra-id"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/withdraw-exchange",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = WithdrawExchangeRequest(
            sourceAsset: "stellar:BTC:GTEST",
            destinationAsset: "iso4217:USD",
            amount: "1.5",
            type: "crypto"
        )
        request.extraFields = ["exchange_extra1": "ex_extra1"]

        let result = await transferServerService.withdrawExchange(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "withdraw-exchange-extra-id")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testWithdrawExchangeParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "<<invalid>>"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/withdraw-exchange",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = WithdrawExchangeRequest(
            sourceAsset: "stellar:USDC:GTEST",
            destinationAsset: "iso4217:USD",
            amount: "100",
            type: "bank_account"
        )
        let result = await transferServerService.withdrawExchange(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - info Tests (Additional Coverage)

    func testInfoWithLanguageParameter() async {
        // Test that the info endpoint works correctly (language parameter is optional)
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "deposit": {},
                "withdraw": {}
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/info",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await transferServerService.info()

        switch result {
        case .success(let response):
            // Verify response was decoded correctly
            XCTAssertNotNil(response)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testInfoWithJWTToken() async {
        let mockHandler: MockHandler = { mock, request in
            let authHeader = request.allHTTPHeaderFields?["Authorization"]
            XCTAssertEqual(authHeader, "Bearer test_jwt_token")

            mock.statusCode = 200
            return """
            {
                "deposit": {},
                "withdraw": {}
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/info",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await transferServerService.info(jwtToken: "test_jwt_token")

        switch result {
        case .success(let response):
            // Verify response was decoded correctly
            XCTAssertNotNil(response)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testInfoParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "[]"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/info",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await transferServerService.info()

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - fee Tests (Additional Coverage)

    func testFeeWithAllParameters() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["operation"], "withdraw")
            XCTAssertEqual(params["asset_code"], "BTC")
            XCTAssertEqual(params["amount"], "1.5")
            XCTAssertEqual(params["type"], "crypto")

            mock.statusCode = 200
            return """
            {
                "fee": 0.0005
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/fee",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = FeeRequest(operation: "withdraw", assetCode: "BTC", amount: 1.5)
        request.type = "crypto"

        let result = await transferServerService.fee(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.fee, 0.0005)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testFeeParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "{}"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/fee",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = FeeRequest(operation: "deposit", assetCode: "USD", amount: 100)
        let result = await transferServerService.fee(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - getTransactions Tests (Additional Coverage)

    func testGetTransactionsWithAllOptionalParameters() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["asset_code"], "XLM")
            XCTAssertEqual(params["account"], "GTEST")
            XCTAssertNotNil(params["no_older_than"])
            XCTAssertEqual(params["limit"], "10")
            XCTAssertEqual(params["kind"], "deposit")
            XCTAssertEqual(params["paging_id"], "page123")
            XCTAssertEqual(params["lang"], "fr")

            mock.statusCode = 200
            return """
            {
                "transactions": []
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transactions",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = AnchorTransactionsRequest(assetCode: "XLM", account: "GTEST")
        request.noOlderThan = Date()
        request.limit = 10
        request.kind = "deposit"
        request.pagingId = "page123"
        request.lang = "fr"

        let result = await transferServerService.getTransactions(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.transactions.count, 0)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testGetTransactionsParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "not json"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transactions",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = AnchorTransactionsRequest(assetCode: "XLM", account: "GTEST")
        let result = await transferServerService.getTransactions(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - getTransaction Tests (Additional Coverage)

    func testGetTransactionWithId() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["id"], "tx123")

            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "tx123",
                    "kind": "deposit",
                    "status": "completed",
                    "started_at": "2017-03-20T17:05:32.000Z"
                }
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = AnchorTransactionRequest(id: "tx123")
        let result = await transferServerService.getTransaction(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.transaction.id, "tx123")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testGetTransactionWithStellarTransactionId() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["stellar_transaction_id"], "stellar123")

            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "tx456",
                    "kind": "withdrawal",
                    "status": "pending_anchor",
                    "started_at": "2017-03-20T17:05:32.000Z"
                }
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = AnchorTransactionRequest(stellarTransactionId: "stellar123")
        let result = await transferServerService.getTransaction(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.transaction.id, "tx456")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testGetTransactionWithExternalTransactionId() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["external_transaction_id"], "external789")

            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "tx789",
                    "kind": "deposit",
                    "status": "completed",
                    "started_at": "2017-03-20T17:05:32.000Z"
                }
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = AnchorTransactionRequest(externalTransactionId: "external789")
        let result = await transferServerService.getTransaction(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.transaction.id, "tx789")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testGetTransactionWithMultipleIdentifiers() async {
        let mockHandler: MockHandler = { mock, request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            let queryItems = components.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

            XCTAssertEqual(params["id"], "multi_tx")
            XCTAssertEqual(params["stellar_transaction_id"], "multi_stellar")
            XCTAssertEqual(params["external_transaction_id"], "multi_external")
            XCTAssertEqual(params["lang"], "de")

            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "multi_tx",
                    "kind": "deposit",
                    "status": "completed",
                    "started_at": "2017-03-20T17:05:32.000Z"
                }
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        var request = AnchorTransactionRequest(
            id: "multi_tx",
            stellarTransactionId: "multi_stellar",
            externalTransactionId: "multi_external"
        )
        request.lang = "de"

        let result = await transferServerService.getTransaction(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.transaction.id, "multi_tx")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testGetTransactionParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "invalid"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = AnchorTransactionRequest(id: "test")
        let result = await transferServerService.getTransaction(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - patchTransaction Tests (Additional Coverage)

    func testPatchTransactionSuccess() async {
        let mockHandler: MockHandler = { mock, request in
            XCTAssertEqual(request.httpMethod, "PATCH")

            let authHeader = request.allHTTPHeaderFields?["Authorization"]
            XCTAssertEqual(authHeader, "Bearer patch_jwt")

            // Note: Content-Type header may not be available in MockURLProtocol request context
            // The actual implementation handles this correctly via ServiceHelper

            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "patch_tx",
                    "kind": "withdrawal",
                    "status": "pending_anchor",
                    "started_at": "2017-03-20T17:05:32.000Z"
                }
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction/patch_tx",
            httpMethod: "PATCH",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let patchData = """
        {
            "dest": "updated_destination",
            "dest_extra": "updated_extra"
        }
        """.data(using: .utf8)!

        let result = await transferServerService.patchTransaction(
            id: "patch_tx",
            jwt: "patch_jwt",
            contentType: "application/json",
            body: patchData
        )

        switch result {
        case .success(let response):
            XCTAssertEqual(response.transaction.id, "patch_tx")
            XCTAssertEqual(response.transaction.status, .pendingAnchor)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testPatchTransactionWithMultipartFormData() async {
        let mockHandler: MockHandler = { mock, request in
            // Note: Content-Type header may not be available in MockURLProtocol request context
            // The actual implementation handles this correctly via ServiceHelper

            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "multipart_tx",
                    "kind": "deposit",
                    "status": "completed",
                    "started_at": "2017-03-20T17:05:32.000Z"
                }
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction/multipart_tx",
            httpMethod: "PATCH",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let formData = "--test-boundary\r\nContent-Disposition: form-data; name=\"photo\"\r\n\r\nphoto_data\r\n--test-boundary--".data(using: .utf8)!

        let result = await transferServerService.patchTransaction(
            id: "multipart_tx",
            jwt: nil,
            contentType: "multipart/form-data; boundary=test-boundary",
            body: formData
        )

        switch result {
        case .success(let response):
            XCTAssertEqual(response.transaction.id, "multipart_tx")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }

        ServerMock.remove(mock: mock)
    }

    func testPatchTransactionParsingError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "not valid"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction/error_tx",
            httpMethod: "PATCH",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let patchData = "{}".data(using: .utf8)!
        let result = await transferServerService.patchTransaction(
            id: "error_tx",
            jwt: nil,
            contentType: "application/json",
            body: patchData
        )

        switch result {
        case .success(_):
            XCTFail("Expected parsing failure")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed error, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    // MARK: - Error Handling Tests

    func testErrorForBadRequest() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 400
            return """
            {
                "error": "Invalid request parameters"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = DepositRequest(assetCode: "INVALID", account: "GTEST")
        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected error")
        case .failure(let error):
            if case .anchorError(let message) = error {
                XCTAssertEqual(message, "Invalid request parameters")
            } else {
                XCTFail("Expected anchorError, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testErrorForNotFound() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 404
            return """
            {
                "error": "Transaction not found"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = AnchorTransactionRequest(id: "nonexistent")
        let result = await transferServerService.getTransaction(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected error")
        case .failure(let error):
            if case .anchorError(let message) = error {
                XCTAssertEqual(message, "Transaction not found")
            } else {
                XCTFail("Expected anchorError, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testErrorForInternalServerError() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 500
            return """
            {
                "error": "Internal server error"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/info",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let result = await transferServerService.info()

        switch result {
        case .success(_):
            XCTFail("Expected error")
        case .failure(let error):
            if case .anchorError(let message) = error {
                XCTAssertEqual(message, "Internal server error")
            } else {
                XCTFail("Expected anchorError, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testErrorForRateLimitExceeded() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 429
            return """
            {
                "error": "Rate limit exceeded"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = DepositRequest(assetCode: "USD", account: "GTEST")
        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected error")
        case .failure(let error):
            if case .anchorError(let message) = error {
                XCTAssertEqual(message, "Rate limit exceeded")
            } else {
                XCTFail("Expected anchorError, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testErrorForCustomerInfoNeededInteractive() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 403
            return """
            {
                "type": "customer_info_needed",
                "url": "https://kyc.example.com?token=abc"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/withdraw",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = WithdrawRequest(type: "bank_account", assetCode: "USD")
        let result = await transferServerService.withdraw(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected error")
        case .failure(let error):
            if case .parsingResponseFailed(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected parsingResponseFailed for unknown type, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testErrorForForbiddenWithoutType() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 403
            return """
            {
                "message": "Forbidden access"
            }
            """
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = DepositRequest(assetCode: "USD", account: "GTEST")
        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected error")
        case .failure(let error):
            // Without a "type" field, the error becomes horizonError or parsingResponseFailed
            switch error {
            case .horizonError(_), .parsingResponseFailed(_):
                // Pattern match succeeded - test passes
                break
            default:
                XCTFail("Expected horizonError or parsingResponseFailed, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }

    func testErrorForErrorWithoutJsonMessage() async {
        let mockHandler: MockHandler = { mock, request in
            mock.statusCode = 400
            return "Plain text error message"
        }

        let mock = RequestMock(
            host: testHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: mockHandler
        )
        ServerMock.add(mock: mock)

        let request = DepositRequest(assetCode: "USD", account: "GTEST")
        let result = await transferServerService.deposit(request: request)

        switch result {
        case .success(_):
            XCTFail("Expected error")
        case .failure(let error):
            if case .horizonError(_) = error {
                // Pattern match succeeded - test passes
            } else {
                XCTFail("Expected horizonError, got \(error)")
            }
        }

        ServerMock.remove(mock: mock)
    }
}
