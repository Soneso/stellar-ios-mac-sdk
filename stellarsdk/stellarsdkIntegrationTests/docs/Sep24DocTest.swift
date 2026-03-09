//
//  Sep24DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-24 documentation code examples.
//  Uses ServerMock/RequestMock/ResponsesMock infrastructure for HTTP mocking.
//

import XCTest
import stellarsdk

// MARK: - Mock helpers (scoped to this file)

/// Provides GET /info mock response for SEP-24 interactive service.
private class Sep24DocInfoResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.infoSuccess
        }

        return RequestMock(
            host: address,
            path: "/info",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    let infoSuccess = """
    {
      "deposit": {
        "USD": {
          "enabled": true,
          "fee_fixed": 5,
          "fee_percent": 1,
          "min_amount": 0.1,
          "max_amount": 1000
        },
        "ETH": {
          "enabled": true,
          "fee_fixed": 0.002,
          "fee_percent": 0
        },
        "native": {
          "enabled": true,
          "fee_fixed": 0.00001,
          "fee_percent": 0
        }
      },
      "withdraw": {
        "USD": {
          "enabled": true,
          "fee_minimum": 5,
          "fee_percent": 0.5,
          "min_amount": 0.1,
          "max_amount": 1000
        },
        "ETH": {
          "enabled": false
        },
        "native": {
          "enabled": true
        }
      },
      "fee": {
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

/// Provides GET /fee mock response.
private class Sep24DocFeeResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let assetCode = mock.variables["asset_code"] {
                if assetCode == "ETH" {
                    mock.statusCode = 400
                    return self?.feeError
                } else if assetCode == "XYZ" {
                    mock.statusCode = 403
                    return self?.authRequired
                }
            }
            mock.statusCode = 200
            return self?.feeSuccess
        }

        return RequestMock(
            host: address,
            path: "/fee",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    let feeSuccess = """
    {
      "fee": 0.013
    }
    """

    let feeError = """
    {
      "error": "This anchor doesn't support the given currency code: ETH"
    }
    """

    let authRequired = """
    {
      "type": "authentication_required"
    }
    """
}

/// Provides POST /transactions/deposit/interactive mock response.
private class Sep24DocDepositResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.depositSuccess
        }

        return RequestMock(
            host: address,
            path: "/transactions/deposit/interactive",
            httpMethod: "POST",
            mockHandler: handler
        )
    }

    let depositSuccess = """
    {
        "type": "interactive_customer_info_needed",
        "url": "https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
        "id": "82fhs729f63dh0v4"
    }
    """
}

/// Provides POST /transactions/withdraw/interactive mock response.
private class Sep24DocWithdrawResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.withdrawSuccess
        }

        return RequestMock(
            host: address,
            path: "/transactions/withdraw/interactive",
            httpMethod: "POST",
            mockHandler: handler
        )
    }

    let withdrawSuccess = """
    {
        "type": "interactive_customer_info_needed",
        "url": "https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
        "id": "wdraw729f63dh0v4"
    }
    """
}

/// Provides GET /transaction mock response.
private class Sep24DocTransactionResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let id = mock.variables["id"], id == "not-found-id" {
                mock.statusCode = 404
                return "Transaction not found"
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(
            host: address,
            path: "/transaction",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    let success = """
    {
        "transaction": {
          "id": "82fhs729f63dh0v4",
          "kind": "withdrawal",
          "status": "completed",
          "amount_in": "510",
          "amount_out": "490",
          "amount_fee": "5",
          "started_at": "2025-01-14T14:22:06.391779Z",
          "completed_at": "2025-01-14T14:22:08.491Z",
          "updated_at": "2025-01-14T14:22:07Z",
          "more_info_url": "https://youranchor.com/tx/242523523",
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "1941491",
          "withdraw_anchor_account": "GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL",
          "withdraw_memo": "186384",
          "withdraw_memo_type": "id",
          "refunds": {
            "amount_refunded": "10",
            "amount_fee": "5",
            "payments": [
              {
                "id": "b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020",
                "id_type": "stellar",
                "amount": "10",
                "fee": "5"
              }
            ]
          }
        }
    }
    """
}

/// Provides GET /transactions mock response.
private class Sep24DocTransactionsResponseMock: ResponsesMock {
    let address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let assetCode = mock.variables["asset_code"], assetCode == "EMPTY" {
                return self?.empty
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(
            host: address,
            path: "/transactions",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    let success = """
    {
      "transactions": [
        {
          "id": "82fhs729f63dh0v4",
          "kind": "deposit",
          "status": "pending_external",
          "status_eta": 3600,
          "external_transaction_id": "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093",
          "more_info_url": "https://youranchor.com/tx/242523523",
          "amount_in": "18.34",
          "amount_out": "18.24",
          "amount_fee": "0.1",
          "started_at": "2017-03-20T17:05:32Z",
          "user_action_required_by": "2024-03-20T17:05:32Z"
        },
        {
          "id": "72fhs729f63dh0v5",
          "kind": "withdrawal",
          "status": "completed",
          "amount_in": "510",
          "amount_out": "490",
          "amount_fee": "5",
          "started_at": "2017-03-20T17:00:02Z",
          "completed_at": "2017-03-20T17:09:58Z",
          "updated_at": "2017-03-20T17:09:58Z",
          "stellar_transaction_id": "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a",
          "external_transaction_id": "1941491",
          "withdraw_anchor_account": "GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL",
          "withdraw_memo": "186384",
          "withdraw_memo_type": "id",
          "refunds": {
            "amount_refunded": "10",
            "amount_fee": "5",
            "payments": [
              {
                "id": "b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020",
                "id_type": "stellar",
                "amount": "10",
                "fee": "5"
              }
            ]
          }
        }
      ]
    }
    """

    let empty = """
    {
      "transactions": []
    }
    """
}

// MARK: - Test class

class Sep24DocTest: XCTestCase {

    let interactiveServer = "127.0.0.1"
    var interactiveService: InteractiveService!

    // Mock instances — retained for lifetime of test
    private var infoMock: Sep24DocInfoResponseMock!
    private var feeMock: Sep24DocFeeResponseMock!
    private var depositMock: Sep24DocDepositResponseMock!
    private var withdrawMock: Sep24DocWithdrawResponseMock!
    private var transactionMock: Sep24DocTransactionResponseMock!
    private var transactionsMock: Sep24DocTransactionsResponseMock!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
        ServerMock.removeAll()

        infoMock = Sep24DocInfoResponseMock(address: interactiveServer)
        feeMock = Sep24DocFeeResponseMock(address: interactiveServer)
        depositMock = Sep24DocDepositResponseMock(address: interactiveServer)
        withdrawMock = Sep24DocWithdrawResponseMock(address: interactiveServer)
        transactionMock = Sep24DocTransactionResponseMock(address: interactiveServer)
        transactionsMock = Sep24DocTransactionsResponseMock(address: interactiveServer)

        interactiveService = InteractiveService(serviceAddress: "http://\(interactiveServer)")
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - Snippet 1: Quick example (deposit)

    func testQuickExample() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            let interactiveUrl = response.url
            let transactionId = response.id
            XCTAssertFalse(interactiveUrl.isEmpty)
            XCTAssertFalse(transactionId.isEmpty)
        case .failure(let error):
            XCTFail("Quick example failed: \(error)")
        }
    }

    // MARK: - Snippet 2: Creating from domain (tested via direct URL since mock)

    func testCreateServiceFromDirectUrl() {
        // Snippet 3: From a direct URL
        let service = InteractiveService(serviceAddress: "https://api.anchor.com/sep24")
        XCTAssertEqual("https://api.anchor.com/sep24", service.serviceAddress)
    }

    // MARK: - Snippet 4: Getting anchor information (info endpoint)

    func testGetAnchorInfo() async {
        let infoResult = await interactiveService.info(language: "en")
        switch infoResult {
        case .success(let info):
            // Check deposit assets
            XCTAssertNotNil(info.depositAssets)
            if let depositAssets = info.depositAssets {
                for (code, asset) in depositAssets {
                    XCTAssertFalse(code.isEmpty)
                    // asset.enabled is Bool, asset.minAmount/maxAmount are Double?
                    if code == "USD" {
                        XCTAssertTrue(asset.enabled)
                        XCTAssertEqual(0.1, asset.minAmount)
                        XCTAssertEqual(1000.0, asset.maxAmount)
                        XCTAssertEqual(5.0, asset.feeFixed)
                        XCTAssertEqual(1.0, asset.feePercent)
                    }
                }
            }

            // Check withdrawal assets
            XCTAssertNotNil(info.withdrawAssets)

            // Check feature flags
            if let flags = info.featureFlags {
                XCTAssertTrue(flags.accountCreation)
                XCTAssertTrue(flags.claimableBalances)
            } else {
                XCTFail("Feature flags should be present")
            }

            // Check fee endpoint info
            if let feeInfo = info.feeEndpointInfo {
                XCTAssertTrue(feeInfo.enabled)
                XCTAssertTrue(feeInfo.authenticationRequired)
            } else {
                XCTFail("Fee endpoint info should be present")
            }
        case .failure(let error):
            XCTFail("Info failed: \(error)")
        }
    }

    // MARK: - Snippet 5: Basic deposit

    func testBasicDeposit() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            let url = response.url
            let transactionId = response.id
            XCTAssertFalse(url.isEmpty)
            XCTAssertEqual("82fhs729f63dh0v4", transactionId)
        case .failure(let error):
            XCTFail("Basic deposit failed: \(error)")
        }
    }

    // MARK: - Snippet 6: Deposit with amount and account options

    func testDepositWithAmountAndAccount() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
        request.amount = "100.0"
        request.account = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        request.memo = "12345"
        request.memoType = "id"
        request.lang = "en-US"

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
            XCTAssertNotNil(response.url)
        case .failure(let error):
            XCTFail("Deposit with options failed: \(error)")
        }
    }

    // MARK: - Snippet 7: Deposit with asset issuer

    func testDepositWithAssetIssuer() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
        request.assetIssuer = "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit with issuer failed: \(error)")
        }
    }

    // MARK: - Snippet 8: Deposit with SEP-38 quote

    func testDepositWithSep38Quote() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USDC")
        request.quoteId = "quote-abc-123"
        request.sourceAsset = "iso4217:EUR"
        request.amount = "100.0"

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit with quote failed: \(error)")
        }
    }

    // MARK: - Snippet 9: Pre-filling KYC data

    func testDepositWithKycData() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
        request.kycFields = [
            KYCNaturalPersonFieldsEnum.firstName("Jane"),
            KYCNaturalPersonFieldsEnum.lastName("Doe"),
            KYCNaturalPersonFieldsEnum.emailAddress("jane@example.com"),
            KYCNaturalPersonFieldsEnum.mobileNumber("+1234567890"),
        ]

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit with KYC failed: \(error)")
        }
    }

    // MARK: - Snippet 10: Pre-filling organization KYC data

    func testDepositWithOrganizationKyc() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
        request.kycOrganizationFields = [
            KYCOrganizationFieldsEnum.name("Acme Corporation"),
            KYCOrganizationFieldsEnum.registeredAddress("123 Business St, Suite 100"),
            KYCOrganizationFieldsEnum.email("contact@acme.com"),
        ]

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit with org KYC failed: \(error)")
        }
    }

    // MARK: - Snippet 11: Custom fields and files

    func testDepositWithCustomFieldsAndFiles() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
        request.customFields = [
            "employer_name": "Tech Corp",
            "occupation": "Software Engineer",
        ]
        request.customFiles = [
            "proof_of_income": "test file content".data(using: .utf8)!,
        ]

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit with custom fields failed: \(error)")
        }
    }

    // MARK: - Snippet 12: Deposit with claimable balance support

    func testDepositWithClaimableBalance() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")
        request.claimableBalanceSupported = "true"

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit with claimable balance failed: \(error)")
        }
    }

    // MARK: - Snippet 13: Deposit native XLM

    func testDepositNativeXlm() async {
        let jwtToken = "test-jwt"
        var request = Sep24DepositRequest(jwt: jwtToken, assetCode: "native")
        // Do not set assetIssuer for native assets

        let result = await interactiveService.deposit(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Deposit native XLM failed: \(error)")
        }
    }

    // MARK: - Snippet 14: Basic withdrawal

    func testBasicWithdrawal() async {
        let jwtToken = "test-jwt"
        var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")

        let result = await interactiveService.withdraw(request: request)
        switch result {
        case .success(let response):
            let url = response.url
            let transactionId = response.id
            XCTAssertFalse(url.isEmpty)
            XCTAssertFalse(transactionId.isEmpty)
        case .failure(let error):
            XCTFail("Basic withdrawal failed: \(error)")
        }
    }

    // MARK: - Snippet 15: Withdrawal with options

    func testWithdrawalWithOptions() async {
        let jwtToken = "test-jwt"
        var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")
        request.amount = "500.0"
        request.account = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        request.lang = "de"

        let result = await interactiveService.withdraw(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Withdrawal with options failed: \(error)")
        }
    }

    // MARK: - Snippet 16: Withdrawal with refund memo

    func testWithdrawalWithRefundMemo() async {
        let jwtToken = "test-jwt"
        var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")
        request.amount = "500.0"
        request.refundMemo = "refund-123"
        request.refundMemoType = "text"

        let result = await interactiveService.withdraw(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Withdrawal with refund memo failed: \(error)")
        }
    }

    // MARK: - Snippet 17: Withdrawal with SEP-38 quote

    func testWithdrawalWithSep38Quote() async {
        let jwtToken = "test-jwt"
        var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USDC")
        request.quoteId = "quote-xyz-789"
        request.destinationAsset = "iso4217:EUR"
        request.amount = "500.0"

        let result = await interactiveService.withdraw(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Withdrawal with quote failed: \(error)")
        }
    }

    // MARK: - Snippet 18: Withdrawal with KYC data

    func testWithdrawalWithKycData() async {
        let jwtToken = "test-jwt"
        var request = Sep24WithdrawRequest(jwt: jwtToken, assetCode: "USD")
        request.kycFields = [
            KYCNaturalPersonFieldsEnum.firstName("John"),
            KYCNaturalPersonFieldsEnum.lastName("Smith"),
            KYCNaturalPersonFieldsEnum.emailAddress("john@example.com"),
        ]
        request.kycFinancialAccountFields = [
            KYCFinancialAccountFieldsEnum.bankAccountNumber("123456789"),
            KYCFinancialAccountFieldsEnum.bankNumber("987654321"),
        ]

        let result = await interactiveService.withdraw(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.id)
        case .failure(let error):
            XCTFail("Withdrawal with KYC failed: \(error)")
        }
    }

    // MARK: - Snippet 19: Completing a withdrawal payment (transaction query)

    func testGetTransactionForWithdrawalPayment() async {
        let jwtToken = "test-jwt"

        var txRequest = Sep24TransactionRequest(jwt: jwtToken)
        txRequest.id = "82fhs729f63dh0v4"

        let txResult = await interactiveService.getTransaction(request: txRequest)
        switch txResult {
        case .success(let txResponse):
            let tx = txResponse.transaction
            XCTAssertEqual("82fhs729f63dh0v4", tx.id)
            XCTAssertEqual("withdrawal", tx.kind)
            XCTAssertEqual("completed", tx.status)
            XCTAssertNotNil(tx.withdrawAnchorAccount)
            XCTAssertNotNil(tx.withdrawMemo)
            XCTAssertNotNil(tx.amountIn)
        case .failure(let error):
            XCTFail("Get transaction failed: \(error)")
        }
    }

    // MARK: - Snippet 20: Get a single transaction by ID

    func testGetTransactionById() async {
        let jwtToken = "test-jwt"

        var request = Sep24TransactionRequest(jwt: jwtToken)
        request.id = "82fhs729f63dh0v4"

        let result = await interactiveService.getTransaction(request: request)
        switch result {
        case .success(let response):
            let tx = response.transaction
            XCTAssertEqual("82fhs729f63dh0v4", tx.id)
            XCTAssertEqual("withdrawal", tx.kind)
            XCTAssertEqual("completed", tx.status)
            XCTAssertNotNil(tx.startedAt)
            XCTAssertEqual("510", tx.amountIn)
            XCTAssertEqual("490", tx.amountOut)
            XCTAssertEqual("5", tx.amountFee)
            XCTAssertNotNil(tx.moreInfoUrl)
        case .failure(let error):
            XCTFail("Get transaction by ID failed: \(error)")
        }
    }

    // MARK: - Snippet 21: Get transaction by Stellar transaction ID

    func testGetTransactionByStellarTxId() async {
        let jwtToken = "test-jwt"

        var request = Sep24TransactionRequest(jwt: jwtToken)
        request.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a"

        let result = await interactiveService.getTransaction(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.transaction)
        case .failure(let error):
            XCTFail("Get transaction by stellar tx id failed: \(error)")
        }
    }

    // MARK: - Snippet 22: Get transaction by external transaction ID

    func testGetTransactionByExternalTxId() async {
        let jwtToken = "test-jwt"

        var request = Sep24TransactionRequest(jwt: jwtToken)
        request.externalTransactionId = "BANK-REF-123456"

        let result = await interactiveService.getTransaction(request: request)
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.transaction)
        case .failure(let error):
            XCTFail("Get transaction by external tx id failed: \(error)")
        }
    }

    // MARK: - Snippet 23: Get transaction history

    func testGetTransactionHistory() async {
        let jwtToken = "test-jwt"

        var request = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "ETH")
        request.limit = 10
        request.kind = "deposit"
        request.noOlderThan = Date(timeIntervalSince1970: 1704067200)
        request.lang = "en"

        let result = await interactiveService.getTransactions(request: request)
        switch result {
        case .success(let response):
            XCTAssertGreaterThan(response.transactions.count, 0)
            for tx in response.transactions {
                XCTAssertFalse(tx.id.isEmpty)
                XCTAssertFalse(tx.kind.isEmpty)
                XCTAssertFalse(tx.status.isEmpty)
            }
        case .failure(let error):
            XCTFail("Get transaction history failed: \(error)")
        }
    }

    // MARK: - Snippet 24: Pagination with paging ID

    func testPaginationWithPagingId() async {
        let jwtToken = "test-jwt"

        // First page
        var request = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "ETH")
        request.limit = 10

        let result = await interactiveService.getTransactions(request: request)
        switch result {
        case .success(let response):
            let transactions = response.transactions
            XCTAssertGreaterThan(transactions.count, 0)

            // Get next page using the last transaction's ID
            if let lastTx = transactions.last {
                var nextRequest = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "ETH")
                nextRequest.pagingId = lastTx.id

                let nextResult = await interactiveService.getTransactions(request: nextRequest)
                switch nextResult {
                case .success(let nextResponse):
                    XCTAssertNotNil(nextResponse.transactions)
                case .failure(let error):
                    XCTFail("Pagination second page failed: \(error)")
                }
            }
        case .failure(let error):
            XCTFail("Pagination first page failed: \(error)")
        }
    }

    // MARK: - Snippet 25: Reading transaction fields

    func testReadingTransactionFields() async {
        let jwtToken = "test-jwt"

        var request = Sep24TransactionRequest(jwt: jwtToken)
        request.id = "82fhs729f63dh0v4"

        let result = await interactiveService.getTransaction(request: request)
        guard case .success(let response) = result else {
            XCTFail("Get transaction failed")
            return
        }
        let tx = response.transaction

        // Core fields
        XCTAssertFalse(tx.id.isEmpty)
        XCTAssertFalse(tx.kind.isEmpty)
        XCTAssertFalse(tx.status.isEmpty)
        XCTAssertNotNil(tx.startedAt)

        // Withdrawal-specific fields
        if tx.kind == "withdrawal" && tx.status == "pending_user_transfer_start" {
            if let anchorAccount = tx.withdrawAnchorAccount,
               let memo = tx.withdrawMemo {
                XCTAssertFalse(anchorAccount.isEmpty)
                XCTAssertFalse(memo.isEmpty)
            }
        }

        // For this mock, the transaction is a completed withdrawal
        XCTAssertEqual("withdrawal", tx.kind)
        XCTAssertNotNil(tx.withdrawAnchorAccount)
        XCTAssertNotNil(tx.withdrawMemo)
        XCTAssertEqual("id", tx.withdrawMemoType)
    }

    // MARK: - Snippet 26: Handling refunds

    func testHandlingRefunds() async {
        let jwtToken = "test-jwt"

        var request = Sep24TransactionRequest(jwt: jwtToken)
        request.id = "82fhs729f63dh0v4"

        let result = await interactiveService.getTransaction(request: request)
        guard case .success(let response) = result else {
            XCTFail("Get transaction failed")
            return
        }
        let tx = response.transaction

        // The mock transaction has refunds
        XCTAssertNotNil(tx.refunds)
        if let refunds = tx.refunds {
            XCTAssertEqual("10", refunds.amountRefunded)
            XCTAssertEqual("5", refunds.amountFee)

            if let payments = refunds.payments {
                XCTAssertEqual(1, payments.count)
                let payment = payments[0]
                XCTAssertEqual("b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020", payment.id)
                XCTAssertEqual("stellar", payment.idType)
                XCTAssertEqual("10", payment.amount)
                XCTAssertEqual("5", payment.fee)
            } else {
                XCTFail("Refund payments should be present")
            }
        }
    }

    // MARK: - Snippet 27: Error handling (deposit errors)

    func testErrorHandlingDeposit() async {
        let jwtToken = "test-jwt"
        var depositRequest = Sep24DepositRequest(jwt: jwtToken, assetCode: "USD")

        let result = await interactiveService.deposit(request: depositRequest)
        switch result {
        case .success(let response):
            // In our mock, deposits succeed
            XCTAssertFalse(response.url.isEmpty)
        case .failure(let error):
            // Demonstrates error switch pattern
            switch error {
            case .authenticationRequired:
                XCTAssertTrue(true)
            case .anchorError(let message):
                XCTAssertFalse(message.isEmpty)
            case .notFound(let message):
                XCTAssertNotNil(message)
            default:
                break
            }
        }
    }

    // MARK: - Snippet 27 cont: Error handling (transaction not found)

    func testErrorHandlingTransactionNotFound() async {
        let jwtToken = "test-jwt"

        var txRequest = Sep24TransactionRequest(jwt: jwtToken)
        txRequest.id = "not-found-id"

        let txResult = await interactiveService.getTransaction(request: txRequest)
        switch txResult {
        case .success(_):
            XCTFail("Should have returned not found")
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("Transaction not found", message)
            default:
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    // MARK: - Snippet 28: Fee information (deprecated)

    func testFeeEndpoint() async {
        let jwtToken = "test-jwt"

        // First check info to see if fee endpoint is available
        let infoResult = await interactiveService.info()
        guard case .success(let info) = infoResult,
              let feeInfo = info.feeEndpointInfo,
              feeInfo.enabled else {
            XCTFail("Fee endpoint should be enabled in mock")
            return
        }

        let jwtIfRequired = feeInfo.authenticationRequired ? jwtToken : nil

        let feeRequest = Sep24FeeRequest(
            operation: "deposit",
            type: "bank_account",
            assetCode: "USD",
            amount: 1000.0,
            jwt: jwtIfRequired
        )

        let feeResult = await interactiveService.fee(request: feeRequest)
        switch feeResult {
        case .success(let feeResponse):
            XCTAssertEqual(0.013, feeResponse.fee)
        case .failure(let error):
            XCTFail("Fee request failed: \(error)")
        }
    }

    // MARK: - Snippet 28 cont: Fee error handling

    func testFeeEndpointError() async {
        let feeRequest = Sep24FeeRequest(
            operation: "deposit",
            assetCode: "ETH",
            amount: 10.0
        )

        let feeResult = await interactiveService.fee(request: feeRequest)
        switch feeResult {
        case .success(_):
            XCTFail("Should have returned error for ETH")
        case .failure(let error):
            switch error {
            case .anchorError(let message):
                XCTAssertEqual("This anchor doesn't support the given currency code: ETH", message)
            default:
                XCTFail("Expected anchorError, got: \(error)")
            }
        }
    }

    // MARK: - Snippet 28 cont: Fee authentication required

    func testFeeEndpointAuthRequired() async {
        let feeRequest = Sep24FeeRequest(
            operation: "deposit",
            assetCode: "XYZ",
            amount: 10.0
        )

        let feeResult = await interactiveService.fee(request: feeRequest)
        switch feeResult {
        case .success(_):
            XCTFail("Should have returned auth required")
        case .failure(let error):
            switch error {
            case .authenticationRequired:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected authenticationRequired, got: \(error)")
            }
        }
    }

    // MARK: - Snippet 29: Polling strategy (structure test)

    func testPollingStrategy() async {
        // Test the structure of the polling function from the docs
        let jwtToken = "test-jwt"
        let terminalStatuses = ["completed", "refunded", "expired", "error", "no_market", "too_small", "too_large"]

        var request = Sep24TransactionRequest(jwt: jwtToken)
        request.id = "82fhs729f63dh0v4"

        // Single poll iteration
        let result = await interactiveService.getTransaction(request: request)
        guard case .success(let response) = result else {
            XCTFail("Poll failed")
            return
        }
        let tx = response.transaction
        XCTAssertTrue(terminalStatuses.contains(tx.status), "Status '\(tx.status)' should be terminal")
    }

    // MARK: - Additional: Request parameter verification

    func testDepositRequestParameters() {
        // Verify request serialization matches docs patterns
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.amount = "100.0"
        req.account = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        req.memo = "12345"
        req.memoType = "id"
        req.lang = "en"
        req.claimableBalanceSupported = "true"
        req.customFields = ["employer_name": "Tech Corp"]

        let params = req.toParameters()
        XCTAssertEqual("USD", String(data: params["asset_code"]!, encoding: .utf8))
        XCTAssertEqual("100.0", String(data: params["amount"]!, encoding: .utf8))
        XCTAssertEqual("12345", String(data: params["memo"]!, encoding: .utf8))
        XCTAssertEqual("id", String(data: params["memo_type"]!, encoding: .utf8))
        XCTAssertEqual("en", String(data: params["lang"]!, encoding: .utf8))
        XCTAssertEqual("true", String(data: params["claimable_balance_supported"]!, encoding: .utf8))
        XCTAssertEqual("Tech Corp", String(data: params["employer_name"]!, encoding: .utf8))
    }

    func testWithdrawRequestParameters() {
        // Verify request serialization matches docs patterns
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USDC")
        req.destinationAsset = "iso4217:EUR"
        req.quoteId = "quote-xyz-789"
        req.amount = "500.0"
        req.refundMemo = "refund-123"
        req.refundMemoType = "text"

        let params = req.toParameters()
        XCTAssertEqual("USDC", String(data: params["asset_code"]!, encoding: .utf8))
        XCTAssertEqual("iso4217:EUR", String(data: params["destination_asset"]!, encoding: .utf8))
        XCTAssertEqual("quote-xyz-789", String(data: params["quote_id"]!, encoding: .utf8))
        XCTAssertEqual("500.0", String(data: params["amount"]!, encoding: .utf8))
        XCTAssertEqual("refund-123", String(data: params["refund_memo"]!, encoding: .utf8))
        XCTAssertEqual("text", String(data: params["refund_memo_type"]!, encoding: .utf8))
    }

    // MARK: - Additional: Empty transactions response

    func testEmptyTransactionsResponse() async {
        let jwtToken = "test-jwt"
        let request = Sep24TransactionsRequest(jwt: jwtToken, assetCode: "EMPTY")

        let result = await interactiveService.getTransactions(request: request)
        switch result {
        case .success(let response):
            XCTAssertEqual(0, response.transactions.count)
        case .failure(let error):
            XCTFail("Empty transactions failed: \(error)")
        }
    }
}
