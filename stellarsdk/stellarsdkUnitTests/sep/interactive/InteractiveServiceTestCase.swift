//
//  InteractiveServiceTestCase.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class InteractiveServiceTestCase: XCTestCase {

    // MARK: - Properties

    let interactiveServer = "127.0.0.1"

    var interactiveService: InteractiveService!
    var sep24InfoResponseMock: Sep24InfoResponseMock!
    var sep24FeeResponseMock: Sep24FeeResponseMock!
    var sep24DepositResponseMock: Sep24DepositResponseMock!
    var sep24WithdrawResponseMock: Sep24WithdrawResponseMock!
    var sep24TransactionsResponseMock: Sep24TransactionsResponseMock!
    var sep24TransactionResponseMock: Sep24TransactionResponseMock!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)
        ServerMock.removeAll()
        sep24InfoResponseMock = Sep24InfoResponseMock(address: interactiveServer)
        sep24FeeResponseMock = Sep24FeeResponseMock(address: interactiveServer)
        sep24DepositResponseMock = Sep24DepositResponseMock(address: interactiveServer)
        sep24WithdrawResponseMock = Sep24WithdrawResponseMock(address: interactiveServer)
        sep24TransactionsResponseMock = Sep24TransactionsResponseMock(address: interactiveServer)
        sep24TransactionResponseMock = Sep24TransactionResponseMock(address: interactiveServer)
        interactiveService = InteractiveService(serviceAddress: "http://\(interactiveServer)")
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - Info Endpoint Tests

    func testInfo() async {
        let responseEnum = await interactiveService.info(language: "en")
        switch responseEnum {
        case .success(let info):
            XCTAssert(info.depositAssets?.count == 3)
            let depositAssetUSD = info.depositAssets!["USD"]!;
            XCTAssertTrue(depositAssetUSD.enabled)
            XCTAssertEqual(5.0, depositAssetUSD.feeFixed)
            XCTAssertEqual(1.0, depositAssetUSD.feePercent)
            XCTAssertNil(depositAssetUSD.feeMinimum)
            XCTAssertEqual(0.1, depositAssetUSD.minAmount)
            XCTAssertEqual(1000.0, depositAssetUSD.maxAmount)

            let depositAssetETH = info.depositAssets!["ETH"]!;
            XCTAssertTrue(depositAssetETH.enabled)
            XCTAssertEqual(0.002, depositAssetETH.feeFixed)
            XCTAssertEqual(0.0, depositAssetETH.feePercent)
            XCTAssertNil(depositAssetETH.feeMinimum)
            XCTAssertNil(depositAssetETH.minAmount)
            XCTAssertNil(depositAssetETH.maxAmount)

            let depositAssetNative = info.depositAssets!["native"]!;
            XCTAssertTrue(depositAssetNative.enabled)
            XCTAssertEqual(0.00001, depositAssetNative.feeFixed)
            XCTAssertEqual(0.0, depositAssetNative.feePercent)
            XCTAssertNil(depositAssetETH.feeMinimum)
            XCTAssertNil(depositAssetETH.minAmount)
            XCTAssertNil(depositAssetETH.maxAmount)

            XCTAssert(info.withdrawAssets?.count == 3)
            let withdrawAssetUSD = info.withdrawAssets!["USD"]!;
            XCTAssertTrue(withdrawAssetUSD.enabled)
            XCTAssertEqual(5.0, withdrawAssetUSD.feeMinimum)
            XCTAssertEqual(0.5, withdrawAssetUSD.feePercent)
            XCTAssertNil(withdrawAssetUSD.feeFixed)
            XCTAssertEqual(0.1, withdrawAssetUSD.minAmount)
            XCTAssertEqual(1000.0, withdrawAssetUSD.maxAmount)

            let withdrawAssetETH = info.withdrawAssets!["ETH"]!;
            XCTAssertFalse(withdrawAssetETH.enabled)

            let withdrawAssetNative = info.withdrawAssets!["native"]!;
            XCTAssertTrue(withdrawAssetNative.enabled)

            XCTAssertFalse(info.feeEndpointInfo!.enabled)
            XCTAssertTrue(info.featureFlags!.accountCreation)
            XCTAssertTrue(info.featureFlags!.claimableBalances)
        case .failure(_):
            XCTFail()
        }
    }

    func testInfoWithoutLanguage() async {
        let responseEnum = await interactiveService.info()
        switch responseEnum {
        case .success(let info):
            XCTAssertNotNil(info.depositAssets)
            XCTAssertNotNil(info.withdrawAssets)
            XCTAssertNotNil(info.feeEndpointInfo)
            XCTAssertNotNil(info.featureFlags)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Fee Endpoint Tests

    func testFee() async {
        let rUsd = Sep24FeeRequest(operation: "deposit", assetCode: "USD", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: rUsd)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0.013, result.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testFeeErr() async {
        let rEth = Sep24FeeRequest(operation: "deposit", assetCode: "ETH", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: rEth)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err{
            case .anchorError(let message):
                XCTAssertEqual("This anchor doesn't support the given currency code: ETH", message)
            default:
                XCTFail()
            }
        }
    }

    func testFeeWithType() async {
        let request = Sep24FeeRequest(operation: "deposit", type: "SEPA", assetCode: "USD", amount: 100.0)
        let responseEnum = await interactiveService.fee(request: request)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0.013, result.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testFeeWithJwt() async {
        let request = Sep24FeeRequest(operation: "withdraw", assetCode: "USD", amount: 50.0, jwt: "test-jwt")
        let responseEnum = await interactiveService.fee(request: request)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0.013, result.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testFeeZeroAmount() async {
        let request = Sep24FeeRequest(operation: "deposit", assetCode: "USD", amount: 0.0)
        let responseEnum = await interactiveService.fee(request: request)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0.013, result.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testFeeLargeAmount() async {
        let request = Sep24FeeRequest(operation: "deposit", assetCode: "USD", amount: 999999999.99)
        let responseEnum = await interactiveService.fee(request: request)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0.013, result.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Deposit Tests

    func testDeposit() async {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.customFields = [String:String]()
        req.customFields!["have"] = "fun"
        req.kycFields = [KYCNaturalPersonFieldsEnum.firstName("John"),
                         KYCNaturalPersonFieldsEnum.lastName("Doe"),
                         KYCNaturalPersonFieldsEnum.emailAddress("john.doe@gmail.com"),];

        let responseEnum = await interactiveService.deposit(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual("82fhs729f63dh0v4", result.id)
            XCTAssertEqual("completed", result.type)
            XCTAssertEqual("https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI", result.url)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testDepositWithMinimalParameters() async {
        let req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        let responseEnum = await interactiveService.deposit(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
            XCTAssertNotNil(result.url)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testDepositWithAllOptionalParameters() async {
        var req = Sep24DepositRequest(jwt: "test-jwt-token", assetCode: "USD")
        req.assetIssuer = "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
        req.sourceAsset = "iso4217:USD"
        req.amount = "100.50"
        req.quoteId = "quote-123"
        req.account = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        req.memo = "12345"
        req.memoType = "id"
        req.walletName = "Test Wallet"
        req.walletUrl = "https://testwallet.example.com"
        req.lang = "en"
        req.claimableBalanceSupported = "true"

        let responseEnum = await interactiveService.deposit(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
            XCTAssertNotNil(result.url)
            XCTAssertNotNil(result.type)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testDepositWithKycOrganizationFields() async {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.kycOrganizationFields = [
            KYCOrganizationFieldsEnum.name("Acme Corp"),
            KYCOrganizationFieldsEnum.VATNumber("VAT123456"),
            KYCOrganizationFieldsEnum.registrationNumber("REG789"),
            KYCOrganizationFieldsEnum.addressCountryCode("USA"),
            KYCOrganizationFieldsEnum.city("New York"),
        ]

        let responseEnum = await interactiveService.deposit(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testDepositWithKycFinancialAccountFields() async {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.kycFinancialAccountFields = [
            KYCFinancialAccountFieldsEnum.bankName("Test Bank"),
            KYCFinancialAccountFieldsEnum.bankAccountNumber("123456789"),
            KYCFinancialAccountFieldsEnum.bankNumber("021000021"),
            KYCFinancialAccountFieldsEnum.bankAccountType("checking"),
        ]

        let responseEnum = await interactiveService.deposit(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testDepositWithCustomFiles() async {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.customFiles = [String:Data]()
        req.customFiles!["document"] = "test file content".data(using: .utf8)!

        let responseEnum = await interactiveService.deposit(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Withdraw Tests

    func testWithdraw() async {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.customFields = [String:String]()
        req.customFields!["have"] = "fun"
        req.kycFields = [KYCNaturalPersonFieldsEnum.firstName("John"),
                         KYCNaturalPersonFieldsEnum.lastName("Doe"),
                         KYCNaturalPersonFieldsEnum.emailAddress("john.doe@gmail.com"),];

        let responseEnum = await interactiveService.withdraw(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual("82fhs729f63dh0v4", result.id)
            XCTAssertEqual("completed", result.type)
            XCTAssertEqual("https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI", result.url)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testWithdrawWithMinimalParameters() async {
        let req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        let responseEnum = await interactiveService.withdraw(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
            XCTAssertNotNil(result.url)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testWithdrawWithAllOptionalParameters() async {
        var req = Sep24WithdrawRequest(jwt: "test-jwt-token", assetCode: "USD")
        req.assetIssuer = "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
        req.destinationAsset = "iso4217:USD"
        req.amount = "100.50"
        req.quoteId = "quote-456"
        req.account = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        req.memo = "67890"
        req.memoType = "id"
        req.walletName = "Test Wallet"
        req.walletUrl = "https://testwallet.example.com"
        req.lang = "de"
        req.refundMemo = "refund-memo-123"
        req.refundMemoType = "text"

        let responseEnum = await interactiveService.withdraw(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
            XCTAssertNotNil(result.url)
            XCTAssertNotNil(result.type)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testWithdrawWithKycOrganizationFields() async {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.kycOrganizationFields = [
            KYCOrganizationFieldsEnum.name("Acme Corp"),
            KYCOrganizationFieldsEnum.email("contact@acme.com"),
            KYCOrganizationFieldsEnum.phone("+1234567890"),
        ]

        let responseEnum = await interactiveService.withdraw(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testWithdrawWithKycFinancialAccountFields() async {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.kycFinancialAccountFields = [
            KYCFinancialAccountFieldsEnum.bankName("Receiving Bank"),
            KYCFinancialAccountFieldsEnum.bankAccountNumber("987654321"),
            KYCFinancialAccountFieldsEnum.bankBranchNumber("001"),
        ]

        let responseEnum = await interactiveService.withdraw(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testWithdrawWithCustomFiles() async {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.customFiles = [String:Data]()
        req.customFiles!["proof_document"] = "binary data".data(using: .utf8)!

        let responseEnum = await interactiveService.withdraw(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.id)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Transaction List Tests

    func testTransactions() async {
        let req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(4, result.transactions.count)
            let tx = result.transactions[0]
            XCTAssertEqual("82fhs729f63dh0v4", tx.id)
            XCTAssertEqual("deposit", tx.kind)
            XCTAssertEqual("pending_external", tx.status)
            XCTAssertEqual(3600, tx.statusEta)
            XCTAssertEqual("2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093", tx.externalTransactionId)
            XCTAssertEqual("18.34", tx.amountIn)
            XCTAssertEqual("18.24", tx.amountOut)
            XCTAssertEqual("0.1", tx.amountFee)
            XCTAssertEqual("2017-03-20T17:05:32Z", tx.startedAt.ISO8601Format())
            XCTAssertEqual("2024-03-20T17:05:32Z", tx.userActionRequiredBy?.ISO8601Format())
            XCTAssertNil(tx.claimableBalanceId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testEmptyTransactions() async {
        let req = Sep24TransactionsRequest(jwt: "test", assetCode: "USD")
        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertEqual(0, result.transactions.count)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionsWithPagination() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.limit = 2
        req.pagingId = "82fhs729f63dh0v4"

        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transactions)
            XCTAssertGreaterThan(result.transactions.count, 0)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionsWithKindFilter() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.kind = "deposit"

        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transactions)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionsWithNoOlderThanFilter() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.noOlderThan = Date(timeIntervalSince1970: 1489000000)

        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transactions)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionsWithLanguage() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.lang = "de"

        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transactions)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionsWithAllFilters() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.limit = 10
        req.pagingId = "start-id"
        req.kind = "withdrawal"
        req.noOlderThan = Date(timeIntervalSince1970: 1489000000)
        req.lang = "en"

        let responseEnum = await interactiveService.getTransactions(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transactions)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Single Transaction Tests

    func testTransaction() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.id = "82fhs729f63dh0v4"

        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(let result):
            let tx = result.transaction
            XCTAssertEqual("82fhs729f63dh0v4", tx.id)
            XCTAssertEqual("withdrawal", tx.kind)
            XCTAssertEqual("completed", tx.status)
            XCTAssertEqual("17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a", tx.stellarTransactionId)
            XCTAssertEqual("1941491", tx.externalTransactionId)
            XCTAssertEqual("510", tx.amountIn)
            XCTAssertEqual("490", tx.amountOut)
            XCTAssertEqual("5", tx.amountFee)
            XCTAssertEqual("2025-01-14T14:22:06Z", tx.startedAt.ISO8601Format())
            XCTAssertEqual("2025-01-14T14:22:07Z", tx.updatedAt!.ISO8601Format())
            XCTAssertEqual("2025-01-14T14:22:08Z", tx.completedAt!.ISO8601Format())
            XCTAssertEqual("https://youranchor.com/tx/242523523", tx.moreInfoUrl)
            XCTAssertNil(tx.claimableBalanceId)
            XCTAssertNil(tx.refunded)
            XCTAssertEqual("186384", tx.withdrawMemo)
            XCTAssertEqual("id", tx.withdrawMemoType)
            XCTAssertNotNil(tx.refunds)
            let refunds = tx.refunds!
            XCTAssertEqual("10", refunds.amountRefunded)
            XCTAssertEqual("5", refunds.amountFee)
            XCTAssertEqual(1, refunds.payments?.count)
            let payment = refunds.payments![0]
            XCTAssertEqual("b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020", payment.id)
            XCTAssertEqual("stellar", payment.idType)
            XCTAssertEqual("10", payment.amount)
            XCTAssertEqual("5", payment.fee)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionNotFound() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.id = "1234"

        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
                case .notFound(let message):
                    XCTAssertEqual("Transaction not found", message)
                default:
                    XCTFail(err.localizedDescription)
            }
        }
    }

    func testTransactionByExternalId() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.externalTransactionId = "1941491"

        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transaction)
            XCTAssertEqual("1941491", result.transaction.externalTransactionId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionByStellarTxId() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a"

        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transaction)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionWithLanguage() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.id = "82fhs729f63dh0v4"
        req.lang = "es"

        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transaction)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTransactionWithMultipleIdentifiers() async {
        var req = Sep24TransactionRequest(jwt: "test")
        req.id = "82fhs729f63dh0v4"
        req.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a"
        req.externalTransactionId = "1941491"

        let responseEnum = await interactiveService.getTransaction(request: req)
        switch responseEnum {
        case .success(let result):
            XCTAssertNotNil(result.transaction)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Error Handling Tests

    func testForbidden() async {
        let req = Sep24FeeRequest(operation: "deposit", assetCode: "XYZ", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: req)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
                case .authenticationRequired:
                    XCTAssertTrue(true)
                default:
                    XCTFail(err.localizedDescription)
            }
        }
    }

    func testRequestError() async {
        let req = Sep24FeeRequest(operation: "deposit", assetCode: "ABC", amount: 10.0)
        let responseEnum = await interactiveService.fee(request: req)
        switch responseEnum {
        case .success(_):
            XCTFail()
        case .failure(let err):
            switch err {
                case .anchorError(let message):
                    XCTAssertEqual("This anchor doesn't support the given currency code: ABC", message)
                default:
                    XCTFail(err.localizedDescription)
            }
        }
    }

    // MARK: - Request Parameter Validation Tests

    func testDepositRequestToParametersMinimal() {
        let req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        let params = req.toParameters()

        XCTAssertEqual("USD", String(data: params["asset_code"]!, encoding: .utf8))
        XCTAssertNil(params["asset_issuer"])
        XCTAssertNil(params["source_asset"])
        XCTAssertNil(params["amount"])
        XCTAssertNil(params["quote_id"])
        XCTAssertNil(params["account"])
        XCTAssertNil(params["memo"])
        XCTAssertNil(params["memo_type"])
        XCTAssertNil(params["wallet_name"])
        XCTAssertNil(params["wallet_url"])
        XCTAssertNil(params["lang"])
        XCTAssertNil(params["claimable_balance_supported"])
    }

    func testDepositRequestToParametersFull() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.assetIssuer = "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
        req.sourceAsset = "iso4217:USD"
        req.amount = "100.50"
        req.quoteId = "quote-123"
        req.account = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        req.memo = "12345"
        req.memoType = "id"
        req.walletName = "Test Wallet"
        req.walletUrl = "https://wallet.example.com"
        req.lang = "en"
        req.claimableBalanceSupported = "true"
        req.customFields = ["custom_field": "custom_value"]

        let params = req.toParameters()

        XCTAssertEqual("USD", String(data: params["asset_code"]!, encoding: .utf8))
        XCTAssertEqual("GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG", String(data: params["asset_issuer"]!, encoding: .utf8))
        XCTAssertEqual("iso4217:USD", String(data: params["source_asset"]!, encoding: .utf8))
        XCTAssertEqual("100.50", String(data: params["amount"]!, encoding: .utf8))
        XCTAssertEqual("quote-123", String(data: params["quote_id"]!, encoding: .utf8))
        XCTAssertEqual("GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI", String(data: params["account"]!, encoding: .utf8))
        XCTAssertEqual("12345", String(data: params["memo"]!, encoding: .utf8))
        XCTAssertEqual("id", String(data: params["memo_type"]!, encoding: .utf8))
        XCTAssertEqual("Test Wallet", String(data: params["wallet_name"]!, encoding: .utf8))
        XCTAssertEqual("https://wallet.example.com", String(data: params["wallet_url"]!, encoding: .utf8))
        XCTAssertEqual("en", String(data: params["lang"]!, encoding: .utf8))
        XCTAssertEqual("true", String(data: params["claimable_balance_supported"]!, encoding: .utf8))
        XCTAssertEqual("custom_value", String(data: params["custom_field"]!, encoding: .utf8))
    }

    func testDepositRequestToParametersWithKycFields() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.kycFields = [
            KYCNaturalPersonFieldsEnum.firstName("John"),
            KYCNaturalPersonFieldsEnum.lastName("Doe"),
            KYCNaturalPersonFieldsEnum.emailAddress("john@example.com"),
        ]

        let params = req.toParameters()

        XCTAssertEqual("John", String(data: params["first_name"]!, encoding: .utf8))
        XCTAssertEqual("Doe", String(data: params["last_name"]!, encoding: .utf8))
        XCTAssertEqual("john@example.com", String(data: params["email_address"]!, encoding: .utf8))
    }

    func testWithdrawRequestToParametersMinimal() {
        let req = Sep24WithdrawRequest(jwt: "test", assetCode: "ETH")
        let params = req.toParameters()

        XCTAssertEqual("ETH", String(data: params["asset_code"]!, encoding: .utf8))
        XCTAssertNil(params["asset_issuer"])
        XCTAssertNil(params["destination_asset"])
        XCTAssertNil(params["amount"])
        XCTAssertNil(params["quote_id"])
        XCTAssertNil(params["account"])
        XCTAssertNil(params["memo"])
        XCTAssertNil(params["memo_type"])
        XCTAssertNil(params["wallet_name"])
        XCTAssertNil(params["wallet_url"])
        XCTAssertNil(params["lang"])
        XCTAssertNil(params["refund_memo"])
        XCTAssertNil(params["refund_memo_type"])
    }

    func testWithdrawRequestToParametersFull() {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "ETH")
        req.assetIssuer = "GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG"
        req.destinationAsset = "iso4217:EUR"
        req.amount = "50.25"
        req.quoteId = "quote-456"
        req.account = "GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"
        req.memo = "67890"
        req.memoType = "text"
        req.walletName = "My Wallet"
        req.walletUrl = "https://mywallet.example.com"
        req.lang = "de"
        req.refundMemo = "refund-123"
        req.refundMemoType = "id"
        req.customFields = ["custom_key": "custom_val"]

        let params = req.toParameters()

        XCTAssertEqual("ETH", String(data: params["asset_code"]!, encoding: .utf8))
        XCTAssertEqual("GCKFBEIYV2U22IO2BJ4KVJOIP7XPWQGQFKKWXR6DOSJBV7STMAQSMTGG", String(data: params["asset_issuer"]!, encoding: .utf8))
        XCTAssertEqual("iso4217:EUR", String(data: params["destination_asset"]!, encoding: .utf8))
        XCTAssertEqual("50.25", String(data: params["amount"]!, encoding: .utf8))
        XCTAssertEqual("quote-456", String(data: params["quote_id"]!, encoding: .utf8))
        XCTAssertEqual("GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI", String(data: params["account"]!, encoding: .utf8))
        XCTAssertEqual("67890", String(data: params["memo"]!, encoding: .utf8))
        XCTAssertEqual("text", String(data: params["memo_type"]!, encoding: .utf8))
        XCTAssertEqual("My Wallet", String(data: params["wallet_name"]!, encoding: .utf8))
        XCTAssertEqual("https://mywallet.example.com", String(data: params["wallet_url"]!, encoding: .utf8))
        XCTAssertEqual("de", String(data: params["lang"]!, encoding: .utf8))
        XCTAssertEqual("refund-123", String(data: params["refund_memo"]!, encoding: .utf8))
        XCTAssertEqual("id", String(data: params["refund_memo_type"]!, encoding: .utf8))
        XCTAssertEqual("custom_val", String(data: params["custom_key"]!, encoding: .utf8))
    }

    func testWithdrawRequestToParametersWithKycFields() {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.kycFields = [
            KYCNaturalPersonFieldsEnum.firstName("Jane"),
            KYCNaturalPersonFieldsEnum.lastName("Smith"),
            KYCNaturalPersonFieldsEnum.address("123 Main St"),
            KYCNaturalPersonFieldsEnum.city("New York"),
        ]

        let params = req.toParameters()

        XCTAssertEqual("Jane", String(data: params["first_name"]!, encoding: .utf8))
        XCTAssertEqual("Smith", String(data: params["last_name"]!, encoding: .utf8))
        XCTAssertEqual("123 Main St", String(data: params["address"]!, encoding: .utf8))
        XCTAssertEqual("New York", String(data: params["city"]!, encoding: .utf8))
    }

    // MARK: - KYC Fields Edge Cases

    func testDepositRequestWithPhotoIdFields() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        let frontImageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes
        let backImageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header bytes

        req.kycFields = [
            KYCNaturalPersonFieldsEnum.photoIdFront(frontImageData),
            KYCNaturalPersonFieldsEnum.photoIdBack(backImageData),
        ]

        let params = req.toParameters()

        XCTAssertEqual(frontImageData, params["photo_id_front"])
        XCTAssertEqual(backImageData, params["photo_id_back"])
    }

    func testDepositRequestWithBirthDateField() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        let birthDate = Date(timeIntervalSince1970: 0) // January 1, 1970

        req.kycFields = [
            KYCNaturalPersonFieldsEnum.birthDate(birthDate),
        ]

        let params = req.toParameters()

        XCTAssertNotNil(params["birth_date"])
    }

    func testDepositRequestWithOccupationField() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")

        req.kycFields = [
            KYCNaturalPersonFieldsEnum.occupation(1234), // ISCO code
        ]

        let params = req.toParameters()

        XCTAssertNotNil(params["occupation"])
    }

    func testDepositRequestWithOrganizationNumberOfShareholders() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")

        req.kycOrganizationFields = [
            KYCOrganizationFieldsEnum.numberOfShareholders(5),
        ]

        let params = req.toParameters()

        XCTAssertNotNil(params["organization.number_of_shareholders"])
    }

    // MARK: - Service Initialization Tests

    func testServiceInitialization() {
        let service = InteractiveService(serviceAddress: "https://example.anchor.com")
        XCTAssertEqual("https://example.anchor.com", service.serviceAddress)
    }

    func testServiceAddressWithTrailingSlash() {
        let service = InteractiveService(serviceAddress: "https://example.anchor.com/")
        XCTAssertEqual("https://example.anchor.com/", service.serviceAddress)
    }

    func testServiceAddressWithPath() {
        let service = InteractiveService(serviceAddress: "https://example.anchor.com/sep24")
        XCTAssertEqual("https://example.anchor.com/sep24", service.serviceAddress)
    }
}
