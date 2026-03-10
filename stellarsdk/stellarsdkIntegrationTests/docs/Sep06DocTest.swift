//
//  Sep06DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-06 documentation code examples.
//  Uses ServerMock/RequestMock/ResponsesMock infrastructure for HTTP mocking.
//

import XCTest
import stellarsdk

// MARK: - Mock helpers

/// Provides GET /.well-known/stellar.toml mock with TRANSFER_SERVER set.
private class Sep06DocTomlMock: ResponsesMock {
    let address: String
    let transferServer: String

    init(address: String, transferServer: String) {
        self.address = address
        self.transferServer = transferServer
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            return self?.tomlContent
        }
        return RequestMock(
            host: address,
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    var tomlContent: String {
        return """
        TRANSFER_SERVER="\(transferServer)"
        SIGNING_KEY="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"

        [DOCUMENTATION]
        ORG_NAME="Test Anchor"
        """
    }
}

/// Provides GET /info mock for anchor capabilities.
private class Sep06DocInfoMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "deposit": {
                    "USD": {
                        "enabled": true,
                        "authentication_required": true,
                        "fee_fixed": 5.0,
                        "fee_percent": 1.0,
                        "min_amount": 10.0,
                        "max_amount": 10000.0
                    },
                    "BTC": {
                        "enabled": true,
                        "authentication_required": true,
                        "min_amount": 0.001,
                        "max_amount": 10.0
                    }
                },
                "deposit-exchange": {
                    "USDC": {
                        "enabled": true,
                        "authentication_required": true
                    }
                },
                "withdraw": {
                    "USD": {
                        "enabled": true,
                        "authentication_required": true,
                        "fee_fixed": 5.0,
                        "fee_percent": 0.5,
                        "min_amount": 10.0,
                        "max_amount": 50000.0,
                        "types": {
                            "bank_account": {
                                "fields": {
                                    "dest": {
                                        "description": "Bank account number"
                                    },
                                    "dest_extra": {
                                        "description": "Routing number",
                                        "optional": true
                                    }
                                }
                            }
                        }
                    }
                },
                "withdraw-exchange": {
                    "USDC": {
                        "enabled": true,
                        "authentication_required": true
                    }
                },
                "fee": {
                    "enabled": true,
                    "authentication_required": true
                },
                "transactions": {
                    "enabled": true,
                    "authentication_required": true
                },
                "transaction": {
                    "enabled": true,
                    "authentication_required": true
                },
                "features": {
                    "account_creation": true,
                    "claimable_balances": true
                }
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/info",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /deposit mock for deposit requests.
private class Sep06DocDepositMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "how": "Make a payment to Bank of Example, account 1234567890, routing 021000021",
                "id": "dep-tx-001",
                "eta": 3600,
                "min_amount": 10.0,
                "max_amount": 10000.0,
                "fee_fixed": 5.0,
                "fee_percent": 1.0,
                "extra_info": {
                    "message": "Your deposit is being processed"
                },
                "instructions": {
                    "bank_number": {
                        "value": "121122676",
                        "description": "US bank routing number"
                    },
                    "bank_account_number": {
                        "value": "13719713158835300",
                        "description": "US bank account number"
                    }
                }
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /deposit-exchange mock.
private class Sep06DocDepositExchangeMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "how": "Send BRL via PIX to key abc123",
                "id": "dep-ex-001",
                "eta": 7200,
                "instructions": {
                    "pix_key": {
                        "value": "abc123@example.com",
                        "description": "PIX key for BRL transfer"
                    }
                }
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/deposit-exchange",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /withdraw mock for withdrawal requests.
private class Sep06DocWithdrawMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "account_id": "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7GQ2",
                "memo_type": "id",
                "memo": "123456",
                "id": "wth-tx-001",
                "eta": 1800,
                "min_amount": 10.0,
                "max_amount": 50000.0,
                "fee_fixed": 5.0,
                "fee_percent": 0.5
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/withdraw",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /withdraw-exchange mock.
private class Sep06DocWithdrawExchangeMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "account_id": "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7GQ2",
                "memo_type": "text",
                "memo": "wex-789",
                "id": "wex-tx-001",
                "eta": 3600
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/withdraw-exchange",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /fee mock.
private class Sep06DocFeeMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "fee": 6.0
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/fee",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /transactions mock for transaction history.
private class Sep06DocTransactionsMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "transactions": [
                    {
                        "id": "tx-001",
                        "kind": "deposit",
                        "status": "completed",
                        "amount_in": "100.00",
                        "amount_out": "95.00",
                        "amount_fee": "5.00",
                        "started_at": "2024-01-15T10:00:00Z",
                        "completed_at": "2024-01-15T11:00:00Z",
                        "fee_details": {
                            "total": "5.00",
                            "asset": "stellar:USD:GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM",
                            "details": [
                                {
                                    "name": "Service fee",
                                    "amount": "5.00",
                                    "description": "Flat service fee"
                                }
                            ]
                        }
                    },
                    {
                        "id": "tx-002",
                        "kind": "withdrawal",
                        "status": "pending_user_transfer_start",
                        "amount_in": "500.00",
                        "started_at": "2024-01-16T10:00:00Z",
                        "withdraw_anchor_account": "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7GQ2",
                        "withdraw_memo": "456789",
                        "withdraw_memo_type": "id"
                    }
                ]
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/transactions",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides GET /transaction mock for single transaction lookup.
private class Sep06DocTransactionMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "82fhs729f63dh0v4",
                    "kind": "deposit",
                    "status": "pending_user_transfer_start",
                    "amount_in": "100.00",
                    "amount_out": "95.00",
                    "started_at": "2024-01-15T10:00:00Z",
                    "instructions": {
                        "bank_number": {
                            "value": "121122676",
                            "description": "US bank routing number"
                        },
                        "bank_account_number": {
                            "value": "13719713158835300",
                            "description": "US bank account number"
                        }
                    }
                }
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides PATCH /transaction/:id mock for updating transactions.
private class Sep06DocPatchTransactionMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "transaction": {
                    "id": "82fhs729f63dh0v4",
                    "kind": "withdrawal",
                    "status": "pending_anchor",
                    "started_at": "2024-01-15T10:00:00Z"
                }
            }
            """
        }
        return RequestMock(
            host: address,
            path: "/transaction/*",
            httpMethod: "PATCH",
            mockHandler: handler
        )
    }
}

// MARK: - Test class

class Sep06DocTest: XCTestCase {

    let anchorHost = "mock.anchor.stellar.org"
    let transferServerAddress = "https://mock.anchor.stellar.org"
    let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImlhdCI6MTUzNDI1Nzk5NH0.mock"
    let testAccountId = "GA6UIXXPEWYFILTLNUIWAC37Y4QPEZAMQVDJHDKVWFZJ2KCWUBIUIXNDA"

    override func setUp() {
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        ServerMock.removeAll()
    }

    // MARK: - Snippet 1: Quick example (from domain + deposit)

    func testQuickExample() async {
        let tomlMock = Sep06DocTomlMock(address: anchorHost, transferServer: transferServerAddress)
        let depositMock = Sep06DocDepositMock(address: anchorHost)

        let serviceResult = await TransferServerService.forDomain(domain: "https://\(anchorHost)")
        guard case .success(let transferService) = serviceResult else {
            XCTFail("Failed to create transfer service from domain")
            return
        }

        let request = DepositRequest(assetCode: "USD", account: testAccountId, jwt: jwtToken)
        let responseEnum = await transferService.deposit(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertFalse(response.how.isEmpty)
            XCTAssertNotNil(response.feeFixed)
        case .failure(let error):
            XCTFail("Deposit failed: \(error)")
        }
    }

    // MARK: - Snippet 2: From domain (service creation)

    func testCreateServiceFromDomain() async {
        let tomlMock = Sep06DocTomlMock(address: anchorHost, transferServer: transferServerAddress)

        let result = await TransferServerService.forDomain(domain: "https://\(anchorHost)")
        switch result {
        case .success(let service):
            XCTAssertEqual(transferServerAddress, service.transferServiceAddress)
        case .failure(let error):
            XCTFail("Failed to create service from domain: \(error)")
        }
    }

    // MARK: - Snippet 3: Direct URL (service creation)

    func testCreateServiceDirectUrl() {
        let service = TransferServerService(serviceAddress: "https://testanchor.stellar.org/sep6")
        XCTAssertEqual("https://testanchor.stellar.org/sep6", service.transferServiceAddress)
    }

    // MARK: - Snippet 4: Info endpoint

    func testInfoEndpoint() async {
        let infoMock = Sep06DocInfoMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        let infoEnum = await service.info()
        switch infoEnum {
        case .success(let info):
            // Deposit assets
            XCTAssertNotNil(info.deposit)
            let usdDeposit = info.deposit?["USD"]
            XCTAssertNotNil(usdDeposit)
            XCTAssertTrue(usdDeposit!.enabled)
            XCTAssertEqual(true, usdDeposit!.authenticationRequired)
            XCTAssertEqual(5.0, usdDeposit!.feeFixed)
            XCTAssertEqual(1.0, usdDeposit!.feePercent)
            XCTAssertEqual(10.0, usdDeposit!.minAmount)
            XCTAssertEqual(10000.0, usdDeposit!.maxAmount)

            // Withdraw assets with types
            let usdWithdraw = info.withdraw?["USD"]
            XCTAssertNotNil(usdWithdraw)
            XCTAssertTrue(usdWithdraw!.enabled)
            XCTAssertNotNil(usdWithdraw!.types)
            let bankType = usdWithdraw!.types?["bank_account"]
            XCTAssertNotNil(bankType)
            XCTAssertNotNil(bankType?.fields?["dest"])

            // Deposit-exchange
            XCTAssertNotNil(info.depositExchange)
            XCTAssertTrue(info.depositExchange?["USDC"]?.enabled == true)

            // Withdraw-exchange
            XCTAssertNotNil(info.withdrawExchange)
            XCTAssertTrue(info.withdrawExchange?["USDC"]?.enabled == true)

            // Feature flags
            XCTAssertNotNil(info.features)
            XCTAssertTrue(info.features!.accountCreation)
            XCTAssertTrue(info.features!.claimableBalances)

            // Endpoint availability
            XCTAssertEqual(true, info.fee?.enabled)
            XCTAssertEqual(true, info.transactions?.enabled)
            XCTAssertEqual(true, info.transaction?.enabled)

        case .failure(let error):
            XCTFail("Info request failed: \(error)")
        }
    }

    // MARK: - Snippet 5: Basic deposit request

    func testBasicDeposit() async {
        let depositMock = Sep06DocDepositMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        var request = DepositRequest(assetCode: "USD", account: testAccountId, jwt: jwtToken)
        request.type = "bank_account"
        request.amount = "100.00"

        let responseEnum = await service.deposit(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertFalse(response.how.isEmpty)
            XCTAssertEqual("dep-tx-001", response.id)
            XCTAssertEqual(3600, response.eta)
            XCTAssertEqual(5.0, response.feeFixed)
            XCTAssertEqual(1.0, response.feePercent)
            XCTAssertEqual(10.0, response.minAmount)
            XCTAssertEqual(10000.0, response.maxAmount)
            XCTAssertEqual("Your deposit is being processed", response.extraInfo?.message)

            // Instructions
            XCTAssertNotNil(response.instructions)
            XCTAssertEqual("121122676", response.instructions?["bank_number"]?.value)
            XCTAssertEqual("US bank routing number", response.instructions?["bank_number"]?.description)

        case .failure(let error):
            XCTFail("Deposit failed: \(error)")
        }
    }

    // MARK: - Snippet 6: Deposit with all options

    func testDepositWithAllOptions() async {
        let depositMock = Sep06DocDepositMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        var request = DepositRequest(assetCode: "USD", account: testAccountId, jwt: jwtToken)
        request.memoType = "id"
        request.memo = "12345"
        request.emailAddress = "user@example.com"
        request.type = "SEPA"
        request.lang = "en"
        request.onChangeCallback = "https://wallet.example.com/callback"
        request.amount = "500.00"
        request.countryCode = "USA"
        request.claimableBalanceSupported = "true"
        request.customerId = "cust-123"
        request.locationId = "loc-456"
        request.extraFields = ["custom_field": "value"]

        let responseEnum = await service.deposit(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit with all options failed: \(error)")
        }
    }

    // MARK: - Snippet 7: Basic withdrawal request

    func testBasicWithdrawal() async {
        let withdrawMock = Sep06DocWithdrawMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        var request = WithdrawRequest(type: "bank_account", assetCode: "USDC", jwt: jwtToken)
        request.account = testAccountId
        request.amount = "500.00"

        let responseEnum = await service.withdraw(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7GQ2", response.accountId)
            XCTAssertEqual("id", response.memoType)
            XCTAssertEqual("123456", response.memo)
            XCTAssertEqual("wth-tx-001", response.id)
            XCTAssertEqual(1800, response.eta)
            XCTAssertEqual(5.0, response.feeFixed)
            XCTAssertEqual(0.5, response.feePercent)
            XCTAssertEqual(10.0, response.minAmount)
            XCTAssertEqual(50000.0, response.maxAmount)
        case .failure(let error):
            XCTFail("Withdrawal failed: \(error)")
        }
    }

    // MARK: - Snippet 8: Withdrawal with all options

    func testWithdrawalWithAllOptions() async {
        let withdrawMock = Sep06DocWithdrawMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        var request = WithdrawRequest(type: "bank_account", assetCode: "USDC", jwt: jwtToken)
        request.account = testAccountId
        request.lang = "en"
        request.onChangeCallback = "https://wallet.example.com/callback"
        request.amount = "1000.00"
        request.countryCode = "DEU"
        request.refundMemo = "refund-123"
        request.refundMemoType = "text"
        request.customerId = "cust-123"
        request.locationId = "loc-456"
        request.extraFields = ["bank_name": "Example Bank"]

        let responseEnum = await service.withdraw(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Withdrawal with all options failed: \(error)")
        }
    }

    // MARK: - Snippet 9: Deposit exchange

    func testDepositExchange() async {
        let depositExchangeMock = Sep06DocDepositExchangeMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        var depositExchange = DepositExchangeRequest(
            destinationAsset: "USDC",
            sourceAsset: "iso4217:BRL",
            amount: "480.00",
            account: testAccountId,
            jwt: jwtToken
        )
        depositExchange.quoteId = "282837"
        depositExchange.type = "bank_account"

        let responseEnum = await service.depositExchange(request: depositExchange)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("dep-ex-001", response.id)
            XCTAssertNotNil(response.instructions)
            XCTAssertEqual("abc123@example.com", response.instructions?["pix_key"]?.value)
        case .failure(let error):
            XCTFail("Deposit exchange failed: \(error)")
        }
    }

    // MARK: - Snippet 10: Withdraw exchange

    func testWithdrawExchange() async {
        let withdrawExchangeMock = Sep06DocWithdrawExchangeMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        var withdrawExchange = WithdrawExchangeRequest(
            sourceAsset: "USDC",
            destinationAsset: "iso4217:NGN",
            amount: "100.00",
            type: "bank_account",
            jwt: jwtToken
        )
        withdrawExchange.quoteId = "282838"
        withdrawExchange.account = testAccountId

        let responseEnum = await service.withdrawExchange(request: withdrawExchange)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("wex-tx-001", response.id)
            XCTAssertEqual("GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7GQ2", response.accountId)
            XCTAssertEqual("wex-789", response.memo)
        case .failure(let error):
            XCTFail("Withdraw exchange failed: \(error)")
        }
    }

    // MARK: - Snippet 11: Fee endpoint

    func testFeeEndpoint() async {
        let infoMock = Sep06DocInfoMock(address: anchorHost)
        let feeMock = Sep06DocFeeMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        // Check info first
        let infoEnum = await service.info()
        guard case .success(let info) = infoEnum, info.fee?.enabled == true else {
            XCTFail("Fee endpoint not enabled")
            return
        }

        var feeRequest = FeeRequest(
            operation: "deposit",
            assetCode: "USD",
            amount: 100.00,
            jwt: jwtToken
        )
        feeRequest.type = "bank_account"

        let feeEnum = await service.fee(request: feeRequest)
        switch feeEnum {
        case .success(let feeResponse):
            XCTAssertEqual(6.0, feeResponse.fee)
        case .failure(let error):
            XCTFail("Fee request failed: \(error)")
        }
    }

    // MARK: - Snippet 12: Transaction history

    func testTransactionHistory() async {
        let transactionsMock = Sep06DocTransactionsMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        var request = AnchorTransactionsRequest(assetCode: "USD", account: testAccountId, jwt: jwtToken)
        request.limit = 10
        request.kind = "deposit"

        let responseEnum = await service.getTransactions(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(2, response.transactions.count)

            let tx1 = response.transactions[0]
            XCTAssertEqual("tx-001", tx1.id)
            XCTAssertEqual(.deposit, tx1.kind)
            XCTAssertEqual(.completed, tx1.status)
            XCTAssertEqual("100.00", tx1.amountIn)
            XCTAssertEqual("95.00", tx1.amountOut)
            XCTAssertNotNil(tx1.feeDetails)
            XCTAssertEqual("5.00", tx1.feeDetails?.total)

            let tx2 = response.transactions[1]
            XCTAssertEqual("tx-002", tx2.id)
            XCTAssertEqual(.withdrawal, tx2.kind)
            XCTAssertEqual(.pendingUserTransferStart, tx2.status)

        case .failure(let error):
            XCTFail("Transactions request failed: \(error)")
        }
    }

    // MARK: - Snippet 13: Single transaction status

    func testSingleTransactionStatus() async {
        let transactionMock = Sep06DocTransactionMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        let request = AnchorTransactionRequest(id: "82fhs729f63dh0v4", jwt: jwtToken)
        let responseEnum = await service.getTransaction(request: request)
        switch responseEnum {
        case .success(let response):
            let tx = response.transaction
            XCTAssertEqual("82fhs729f63dh0v4", tx.id)
            XCTAssertEqual(.deposit, tx.kind)
            XCTAssertEqual(.pendingUserTransferStart, tx.status)
            XCTAssertNotNil(tx.instructions)
            XCTAssertEqual("121122676", tx.instructions?["bank_number"]?.value)

        case .failure(let error):
            XCTFail("Single transaction request failed: \(error)")
        }
    }

    // MARK: - Snippet 13b: Transaction by Stellar hash

    func testTransactionByStellarHash() async {
        let transactionMock = Sep06DocTransactionMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        let request = AnchorTransactionRequest(
            stellarTransactionId: "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
            jwt: jwtToken
        )
        let responseEnum = await service.getTransaction(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotNil(response.transaction.id)
        case .failure(let error):
            XCTFail("Transaction by stellar hash failed: \(error)")
        }
    }

    // MARK: - Snippet 13c: Transaction by external ID

    func testTransactionByExternalId() async {
        let transactionMock = Sep06DocTransactionMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        let request = AnchorTransactionRequest(externalTransactionId: "1238234", jwt: jwtToken)
        let responseEnum = await service.getTransaction(request: request)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotNil(response.transaction.id)
        case .failure(let error):
            XCTFail("Transaction by external ID failed: \(error)")
        }
    }

    // MARK: - Snippet 14: Patch transaction

    func testPatchTransaction() async {
        let patchMock = Sep06DocPatchTransactionMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        let updateFields: [String: String] = [
            "dest": "12345678901234",
            "dest_extra": "021000021",
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: updateFields) else {
            XCTFail("Failed to encode patch body")
            return
        }

        let patchEnum = await service.patchTransaction(
            id: "82fhs729f63dh0v4",
            jwt: jwtToken,
            contentType: "application/json",
            body: body
        )
        switch patchEnum {
        case .success(let response):
            XCTAssertEqual("82fhs729f63dh0v4", response.transaction.id)
            XCTAssertEqual(.pendingAnchor, response.transaction.status)
        case .failure(let error):
            XCTFail("Patch transaction failed: \(error)")
        }
    }

    // MARK: - Snippet 15: Error handling

    func testErrorHandlingAuthRequired() async {
        // Register a mock that returns 403 authentication_required
        let handler: MockHandler = { mock, request in
            mock.statusCode = 403
            return """
            {"type": "authentication_required"}
            """
        }
        ServerMock.add(mock: RequestMock(
            host: anchorHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: handler
        ))

        let service = TransferServerService(serviceAddress: transferServerAddress)
        let request = DepositRequest(assetCode: "USD", account: testAccountId)

        let responseEnum = await service.deposit(request: request)
        switch responseEnum {
        case .success:
            XCTFail("Expected auth required error")
        case .failure(let error):
            switch error {
            case .authenticationRequired:
                // Expected
                break
            default:
                XCTFail("Expected authenticationRequired, got \(error)")
            }
        }
    }

    func testErrorHandlingKycNeeded() async {
        // Register a mock that returns 403 non_interactive_customer_info_needed
        let handler: MockHandler = { mock, request in
            mock.statusCode = 403
            return """
            {
                "type": "non_interactive_customer_info_needed",
                "fields": ["first_name", "last_name", "email_address"]
            }
            """
        }
        ServerMock.add(mock: RequestMock(
            host: anchorHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: handler
        ))

        let service = TransferServerService(serviceAddress: transferServerAddress)
        let request = DepositRequest(assetCode: "USD", account: testAccountId, jwt: jwtToken)

        let responseEnum = await service.deposit(request: request)
        switch responseEnum {
        case .success:
            XCTFail("Expected information needed error")
        case .failure(let error):
            switch error {
            case .informationNeeded(let response):
                switch response {
                case .nonInteractive(let info):
                    XCTAssertEqual(3, info.fields.count)
                    XCTAssertTrue(info.fields.contains("first_name"))
                    XCTAssertTrue(info.fields.contains("last_name"))
                    XCTAssertTrue(info.fields.contains("email_address"))
                case .status:
                    XCTFail("Expected nonInteractive, got status")
                }
            default:
                XCTFail("Expected informationNeeded, got \(error)")
            }
        }
    }

    func testErrorHandlingKycStatus() async {
        // Register a mock that returns 403 customer_info_status
        let handler: MockHandler = { mock, request in
            mock.statusCode = 403
            return """
            {
                "type": "customer_info_status",
                "status": "denied",
                "more_info_url": "https://anchor.example.com/kyc/denied"
            }
            """
        }
        ServerMock.add(mock: RequestMock(
            host: anchorHost,
            path: "/deposit",
            httpMethod: "GET",
            mockHandler: handler
        ))

        let service = TransferServerService(serviceAddress: transferServerAddress)
        let request = DepositRequest(assetCode: "USD", account: testAccountId, jwt: jwtToken)

        let responseEnum = await service.deposit(request: request)
        switch responseEnum {
        case .success:
            XCTFail("Expected KYC status error")
        case .failure(let error):
            switch error {
            case .informationNeeded(let response):
                switch response {
                case .status(let info):
                    XCTAssertEqual("denied", info.status)
                    XCTAssertEqual("https://anchor.example.com/kyc/denied", info.moreInfoUrl)
                case .nonInteractive:
                    XCTFail("Expected status, got nonInteractive")
                }
            default:
                XCTFail("Expected informationNeeded, got \(error)")
            }
        }
    }

    // MARK: - Snippet 16: Complete deposit flow (simplified test)

    func testCompleteDepositFlow() async {
        // This test exercises the service creation, info query, deposit, and transaction lookup
        let infoMock = Sep06DocInfoMock(address: anchorHost)
        let depositMock = Sep06DocDepositMock(address: anchorHost)
        let transactionMock = Sep06DocTransactionMock(address: anchorHost)
        let service = TransferServerService(serviceAddress: transferServerAddress)

        // Step 1: Check info
        let infoEnum = await service.info()
        guard case .success(let info) = infoEnum else {
            XCTFail("Info request failed")
            return
        }
        guard let usdDeposit = info.deposit?["USD"], usdDeposit.enabled else {
            XCTFail("USD deposits not supported")
            return
        }

        // Step 2: Initiate deposit
        var depositRequest = DepositRequest(assetCode: "USD", account: testAccountId, jwt: jwtToken)
        depositRequest.type = "bank_account"
        depositRequest.amount = "100.00"
        depositRequest.claimableBalanceSupported = "true"

        let depositEnum = await service.deposit(request: depositRequest)
        guard case .success(let depositResponse) = depositEnum else {
            XCTFail("Deposit request failed")
            return
        }
        XCTAssertNotNil(depositResponse.id)
        XCTAssertNotNil(depositResponse.instructions)

        // Step 3: Check transaction status
        let txRequest = AnchorTransactionRequest(id: depositResponse.id!, jwt: jwtToken)
        let txEnum = await service.getTransaction(request: txRequest)
        guard case .success(let txResponse) = txEnum else {
            XCTFail("Transaction request failed")
            return
        }
        XCTAssertEqual(.pendingUserTransferStart, txResponse.transaction.status)
    }
}
