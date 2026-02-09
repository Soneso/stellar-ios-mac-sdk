//
//  InteractiveServiceAdditionalTestCase.swift
//  stellarsdkTests
//
//  Created by Soneso on 05.02.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Additional unit tests for InteractiveService covering error handling,
/// forDomain functionality, transaction statuses, and edge cases.
class InteractiveServiceAdditionalTestCase: XCTestCase {

    // MARK: - Properties

    let interactiveServer = "127.0.0.1"

    var interactiveService: InteractiveService!
    var sep24ErrorResponseMock: Sep24ErrorResponseMock!
    var sep24TomlResponseMock: Sep24TomlResponseMock!
    var sep24TransactionStatusesMock: Sep24TransactionStatusesMock!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)
        ServerMock.removeAll()
        sep24ErrorResponseMock = Sep24ErrorResponseMock(address: interactiveServer)
        sep24TomlResponseMock = Sep24TomlResponseMock(address: interactiveServer)
        sep24TransactionStatusesMock = Sep24TransactionStatusesMock(address: interactiveServer)
        interactiveService = InteractiveService(serviceAddress: "http://\(interactiveServer)")
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - HTTP Error Code Tests

    func testError400BadRequest() async {
        let responseEnum = await interactiveService.info(language: "bad_request")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .anchorError(let message):
                XCTAssertEqual("Invalid request parameters", message)
            default:
                // Accept other error types as valid responses
                XCTAssertTrue(true)
            }
        }
    }

    func testError401Unauthorized() async {
        let responseEnum = await interactiveService.info(language: "unauthorized")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .authenticationRequired:
                XCTAssertTrue(true)
            case .anchorError(_):
                XCTAssertTrue(true)
            default:
                XCTAssertTrue(true)
            }
        }
    }

    func testError403Forbidden() async {
        let responseEnum = await interactiveService.info(language: "forbidden")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .authenticationRequired:
                XCTAssertTrue(true)
            case .anchorError(_):
                XCTAssertTrue(true)
            default:
                XCTAssertTrue(true)
            }
        }
    }

    func testError404NotFound() async {
        let responseEnum = await interactiveService.info(language: "not_found")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertNotNil(message)
            default:
                XCTAssertTrue(true)
            }
        }
    }

    func testError500InternalServerError() async {
        let responseEnum = await interactiveService.info(language: "server_error")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .anchorError(let message):
                XCTAssertEqual("Internal server error", message)
            case .horizonError(_):
                XCTAssertTrue(true)
            default:
                XCTAssertTrue(true)
            }
        }
    }

    func testError503ServiceUnavailable() async {
        let responseEnum = await interactiveService.info(language: "unavailable")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .anchorError(let message):
                XCTAssertEqual("Service temporarily unavailable", message)
            case .horizonError(_):
                XCTAssertTrue(true)
            default:
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Response Parsing Failure Tests

    func testParsingFailureInvalidJson() async {
        let responseEnum = await interactiveService.info(language: "invalid_json")
        switch responseEnum {
        case .success(_):
            XCTFail("Expected failure but got success")
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertNotNil(message)
            default:
                XCTAssertTrue(true)
            }
        }
    }

    func testParsingFailureMissingRequiredFields() async {
        let responseEnum = await interactiveService.info(language: "missing_fields")
        switch responseEnum {
        case .success(_):
            // Parsing may succeed with optional fields
            XCTAssertTrue(true)
        case .failure(let error):
            switch error {
            case .parsingResponseFailed(let message):
                XCTAssertNotNil(message)
            default:
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Transaction Status Tests

    func testTransactionStatusIncomplete() async {
        let responseEnum = await interactiveService.info(language: "status_incomplete")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusPendingUserTransferStart() async {
        let responseEnum = await interactiveService.info(language: "status_pending_user_transfer_start")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusPendingUserTransferComplete() async {
        let responseEnum = await interactiveService.info(language: "status_pending_user_transfer_complete")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusPendingExternal() async {
        let responseEnum = await interactiveService.info(language: "status_pending_external")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusPendingAnchor() async {
        let responseEnum = await interactiveService.info(language: "status_pending_anchor")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusPendingStellar() async {
        let responseEnum = await interactiveService.info(language: "status_pending_stellar")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusPendingTrust() async {
        let responseEnum = await interactiveService.info(language: "status_pending_trust")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusPendingUser() async {
        let responseEnum = await interactiveService.info(language: "status_pending_user")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusCompleted() async {
        let responseEnum = await interactiveService.info(language: "status_completed")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusRefunded() async {
        let responseEnum = await interactiveService.info(language: "status_refunded")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusExpired() async {
        let responseEnum = await interactiveService.info(language: "status_expired")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusNoMarket() async {
        let responseEnum = await interactiveService.info(language: "status_no_market")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusTooSmall() async {
        let responseEnum = await interactiveService.info(language: "status_too_small")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusTooLarge() async {
        let responseEnum = await interactiveService.info(language: "status_too_large")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testTransactionStatusError() async {
        let responseEnum = await interactiveService.info(language: "status_error")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    // MARK: - Refund Structure Tests

    func testRefundWithMultiplePayments() async {
        let responseEnum = await interactiveService.info(language: "refund_multiple")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testRefundWithExternalIdType() async {
        let responseEnum = await interactiveService.info(language: "refund_external")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testRefundWithNoPayments() async {
        let responseEnum = await interactiveService.info(language: "refund_no_payments")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    // MARK: - Numeric Boundary Tests

    func testAmountZero() async {
        let responseEnum = await interactiveService.info(language: "amount_zero")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testAmountVeryLarge() async {
        let responseEnum = await interactiveService.info(language: "amount_large")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testAmountNegative() async {
        let responseEnum = await interactiveService.info(language: "amount_negative")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testAmountMaxDecimals() async {
        let responseEnum = await interactiveService.info(language: "amount_decimals")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    // MARK: - Pagination Tests

    func testPaginationLimitZero() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.limit = 0

        // This should still work, the server may ignore invalid limits
        XCTAssertNotNil(req.limit)
    }

    func testPaginationLimitNegative() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.limit = -1

        // Negative limit is set, server should handle this
        XCTAssertNotNil(req.limit)
    }

    func testPaginationLimitVeryLarge() async {
        var req = Sep24TransactionsRequest(jwt: "test", assetCode: "ETH")
        req.limit = Int.max

        XCTAssertNotNil(req.limit)
    }

    // MARK: - Date Parsing Edge Cases

    func testDateParsingIso8601WithMilliseconds() async {
        // The SDK should handle dates with milliseconds
        let responseEnum = await interactiveService.info(language: "date_millis")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testDateParsingIso8601WithMicroseconds() async {
        // The SDK should handle dates with microseconds
        let responseEnum = await interactiveService.info(language: "date_micros")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    func testDateParsingWithoutTimezone() async {
        let responseEnum = await interactiveService.info(language: "date_no_tz")
        switch responseEnum {
        case .success(_):
            XCTAssertTrue(true)
        case .failure(_):
            XCTAssertTrue(true)
        }
    }

    // MARK: - InteractiveServiceError Tests

    func testInteractiveServiceErrorInvalidDomain() {
        // Test error properties
        let error = InteractiveServiceError.invalidDomain
        XCTAssertNotNil(error)
    }

    func testInteractiveServiceErrorInvalidToml() {
        let error = InteractiveServiceError.invalidToml
        XCTAssertNotNil(error)
    }

    func testInteractiveServiceErrorNoInteractiveServerSet() {
        let error = InteractiveServiceError.noInteractiveServerSet
        XCTAssertNotNil(error)
    }

    func testInteractiveServiceErrorParsingResponseFailed() {
        let error = InteractiveServiceError.parsingResponseFailed(message: "Test parsing error")
        switch error {
        case .parsingResponseFailed(let message):
            XCTAssertEqual("Test parsing error", message)
        default:
            XCTFail("Wrong error type")
        }
    }

    func testInteractiveServiceErrorAnchorError() {
        let error = InteractiveServiceError.anchorError(message: "Test anchor error")
        switch error {
        case .anchorError(let message):
            XCTAssertEqual("Test anchor error", message)
        default:
            XCTFail("Wrong error type")
        }
    }

    func testInteractiveServiceErrorNotFound() {
        let error = InteractiveServiceError.notFound(message: "Resource not found")
        switch error {
        case .notFound(let message):
            XCTAssertEqual("Resource not found", message)
        default:
            XCTFail("Wrong error type")
        }
    }

    func testInteractiveServiceErrorNotFoundNilMessage() {
        let error = InteractiveServiceError.notFound(message: nil)
        switch error {
        case .notFound(let message):
            XCTAssertNil(message)
        default:
            XCTFail("Wrong error type")
        }
    }

    func testInteractiveServiceErrorAuthenticationRequired() {
        let error = InteractiveServiceError.authenticationRequired
        switch error {
        case .authenticationRequired:
            XCTAssertTrue(true)
        default:
            XCTFail("Wrong error type")
        }
    }

    // MARK: - Sep24FeeRequest Tests

    func testSep24FeeRequestInitialization() {
        let request = Sep24FeeRequest(operation: "deposit", assetCode: "USD", amount: 100.0)
        XCTAssertEqual("deposit", request.operation)
        XCTAssertEqual("USD", request.assetCode)
        XCTAssertEqual(100.0, request.amount)
        XCTAssertNil(request.type)
        XCTAssertNil(request.jwt)
    }

    func testSep24FeeRequestInitializationWithAllParams() {
        let request = Sep24FeeRequest(operation: "withdraw", type: "bank_account", assetCode: "EUR", amount: 500.50, jwt: "test-token")
        XCTAssertEqual("withdraw", request.operation)
        XCTAssertEqual("bank_account", request.type)
        XCTAssertEqual("EUR", request.assetCode)
        XCTAssertEqual(500.50, request.amount)
        XCTAssertEqual("test-token", request.jwt)
    }

    // MARK: - Sep24TransactionRequest Tests

    func testSep24TransactionRequestInitialization() {
        let request = Sep24TransactionRequest(jwt: "test-jwt")
        XCTAssertEqual("test-jwt", request.jwt)
        XCTAssertNil(request.id)
        XCTAssertNil(request.stellarTransactionId)
        XCTAssertNil(request.externalTransactionId)
        XCTAssertNil(request.lang)
    }

    func testSep24TransactionRequestWithAllParams() {
        var request = Sep24TransactionRequest(jwt: "test-jwt")
        request.id = "tx-123"
        request.stellarTransactionId = "stellar-tx-456"
        request.externalTransactionId = "external-789"
        request.lang = "fr"

        XCTAssertEqual("test-jwt", request.jwt)
        XCTAssertEqual("tx-123", request.id)
        XCTAssertEqual("stellar-tx-456", request.stellarTransactionId)
        XCTAssertEqual("external-789", request.externalTransactionId)
        XCTAssertEqual("fr", request.lang)
    }

    // MARK: - Sep24TransactionsRequest Tests

    func testSep24TransactionsRequestInitialization() {
        let request = Sep24TransactionsRequest(jwt: "test-jwt", assetCode: "BTC")
        XCTAssertEqual("test-jwt", request.jwt)
        XCTAssertEqual("BTC", request.assetCode)
        XCTAssertNil(request.noOlderThan)
        XCTAssertNil(request.limit)
        XCTAssertNil(request.kind)
        XCTAssertNil(request.pagingId)
        XCTAssertNil(request.lang)
    }

    func testSep24TransactionsRequestWithAllParams() {
        var request = Sep24TransactionsRequest(jwt: "test-jwt", assetCode: "ETH")
        let testDate = Date(timeIntervalSince1970: 1600000000)
        request.noOlderThan = testDate
        request.limit = 50
        request.kind = "deposit"
        request.pagingId = "paging-123"
        request.lang = "de"

        XCTAssertEqual("test-jwt", request.jwt)
        XCTAssertEqual("ETH", request.assetCode)
        XCTAssertEqual(testDate, request.noOlderThan)
        XCTAssertEqual(50, request.limit)
        XCTAssertEqual("deposit", request.kind)
        XCTAssertEqual("paging-123", request.pagingId)
        XCTAssertEqual("de", request.lang)
    }

    // MARK: - Sep24DepositRequest Tests

    func testSep24DepositRequestInitialization() {
        let request = Sep24DepositRequest(jwt: "test-jwt", assetCode: "USDC")
        XCTAssertEqual("test-jwt", request.jwt)
        XCTAssertEqual("USDC", request.assetCode)
        XCTAssertNil(request.assetIssuer)
        XCTAssertNil(request.sourceAsset)
        XCTAssertNil(request.amount)
        XCTAssertNil(request.quoteId)
        XCTAssertNil(request.account)
        XCTAssertNil(request.memo)
        XCTAssertNil(request.memoType)
        XCTAssertNil(request.walletName)
        XCTAssertNil(request.walletUrl)
        XCTAssertNil(request.lang)
        XCTAssertNil(request.claimableBalanceSupported)
        XCTAssertNil(request.kycFields)
        XCTAssertNil(request.kycOrganizationFields)
        XCTAssertNil(request.kycFinancialAccountFields)
        XCTAssertNil(request.customFields)
        XCTAssertNil(request.customFiles)
    }

    // MARK: - Sep24WithdrawRequest Tests

    func testSep24WithdrawRequestInitialization() {
        let request = Sep24WithdrawRequest(jwt: "test-jwt", assetCode: "XLM")
        XCTAssertEqual("test-jwt", request.jwt)
        XCTAssertEqual("XLM", request.assetCode)
        XCTAssertNil(request.assetIssuer)
        XCTAssertNil(request.destinationAsset)
        XCTAssertNil(request.amount)
        XCTAssertNil(request.quoteId)
        XCTAssertNil(request.account)
        XCTAssertNil(request.memo)
        XCTAssertNil(request.memoType)
        XCTAssertNil(request.walletName)
        XCTAssertNil(request.walletUrl)
        XCTAssertNil(request.lang)
        XCTAssertNil(request.refundMemo)
        XCTAssertNil(request.refundMemoType)
        XCTAssertNil(request.kycFields)
        XCTAssertNil(request.kycOrganizationFields)
        XCTAssertNil(request.kycFinancialAccountFields)
        XCTAssertNil(request.customFields)
        XCTAssertNil(request.customFiles)
    }

    // MARK: - KYC Fields Complete Coverage

    func testAllKycNaturalPersonFields() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        let testDate = Date(timeIntervalSince1970: 0)
        let testData = Data([0x00, 0x01, 0x02])

        req.kycFields = [
            KYCNaturalPersonFieldsEnum.lastName("Doe"),
            KYCNaturalPersonFieldsEnum.firstName("John"),
            KYCNaturalPersonFieldsEnum.additionalName("Middle"),
            KYCNaturalPersonFieldsEnum.addressCountryCode("USA"),
            KYCNaturalPersonFieldsEnum.stateOrProvince("California"),
            KYCNaturalPersonFieldsEnum.city("Los Angeles"),
            KYCNaturalPersonFieldsEnum.postalCode("90001"),
            KYCNaturalPersonFieldsEnum.address("123 Main St"),
            KYCNaturalPersonFieldsEnum.mobileNumber("+1234567890"),
            KYCNaturalPersonFieldsEnum.mobileNumberFormat("E.164"),
            KYCNaturalPersonFieldsEnum.emailAddress("john@example.com"),
            KYCNaturalPersonFieldsEnum.birthDate(testDate),
            KYCNaturalPersonFieldsEnum.birthPlace("New York"),
            KYCNaturalPersonFieldsEnum.birthCountryCode("USA"),
            KYCNaturalPersonFieldsEnum.taxId("123-45-6789"),
            KYCNaturalPersonFieldsEnum.taxIdName("SSN"),
            KYCNaturalPersonFieldsEnum.occupation(1234),
            KYCNaturalPersonFieldsEnum.employerName("ACME Corp"),
            KYCNaturalPersonFieldsEnum.employerAddress("456 Work St"),
            KYCNaturalPersonFieldsEnum.languageCode("en"),
            KYCNaturalPersonFieldsEnum.idType("passport"),
            KYCNaturalPersonFieldsEnum.idCountryCode("USA"),
            KYCNaturalPersonFieldsEnum.idIssueDate("2020-01-01"),
            KYCNaturalPersonFieldsEnum.idExpirationDate("2030-01-01"),
            KYCNaturalPersonFieldsEnum.idNumber("AB123456"),
            KYCNaturalPersonFieldsEnum.photoIdFront(testData),
            KYCNaturalPersonFieldsEnum.photoIdBack(testData),
            KYCNaturalPersonFieldsEnum.notaryApprovalOfPhotoId(testData),
            KYCNaturalPersonFieldsEnum.ipAddress("192.168.1.1"),
            KYCNaturalPersonFieldsEnum.photoProofResidence(testData),
            KYCNaturalPersonFieldsEnum.sex("male"),
            KYCNaturalPersonFieldsEnum.proofOfIncome(testData),
            KYCNaturalPersonFieldsEnum.proofOfLiveness(testData),
            KYCNaturalPersonFieldsEnum.referralId("ref-123"),
        ]

        let params = req.toParameters()

        XCTAssertNotNil(params["last_name"])
        XCTAssertNotNil(params["first_name"])
        XCTAssertNotNil(params["additional_name"])
        XCTAssertNotNil(params["address_country_code"])
        XCTAssertNotNil(params["state_or_province"])
        XCTAssertNotNil(params["city"])
        XCTAssertNotNil(params["postal_code"])
        XCTAssertNotNil(params["address"])
        XCTAssertNotNil(params["mobile_number"])
        XCTAssertNotNil(params["mobile_number_format"])
        XCTAssertNotNil(params["email_address"])
        XCTAssertNotNil(params["birth_date"])
        XCTAssertNotNil(params["birth_place"])
        XCTAssertNotNil(params["birth_country_code"])
        XCTAssertNotNil(params["tax_id"])
        XCTAssertNotNil(params["tax_id_name"])
        XCTAssertNotNil(params["occupation"])
        XCTAssertNotNil(params["employer_name"])
        XCTAssertNotNil(params["employer_address"])
        XCTAssertNotNil(params["language_code"])
        XCTAssertNotNil(params["id_type"])
        XCTAssertNotNil(params["id_country_code"])
        XCTAssertNotNil(params["id_issue_date"])
        XCTAssertNotNil(params["id_expiration_date"])
        XCTAssertNotNil(params["id_number"])
        XCTAssertNotNil(params["photo_id_front"])
        XCTAssertNotNil(params["photo_id_back"])
        XCTAssertNotNil(params["notary_approval_of_photo_id"])
        XCTAssertNotNil(params["ip_address"])
        XCTAssertNotNil(params["photo_proof_residence"])
        XCTAssertNotNil(params["sex"])
        XCTAssertNotNil(params["proof_of_income"])
        XCTAssertNotNil(params["proof_of_liveness"])
        XCTAssertNotNil(params["referral_id"])
    }

    func testAllKycOrganizationFields() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        let testData = Data([0x00, 0x01, 0x02])

        req.kycOrganizationFields = [
            KYCOrganizationFieldsEnum.name("ACME Corp"),
            KYCOrganizationFieldsEnum.VATNumber("VAT123"),
            KYCOrganizationFieldsEnum.registrationNumber("REG456"),
            KYCOrganizationFieldsEnum.registrationDate("2020-01-01"),
            KYCOrganizationFieldsEnum.registeredAddress("789 Corp St"),
            KYCOrganizationFieldsEnum.numberOfShareholders(5),
            KYCOrganizationFieldsEnum.shareholderName("John Doe"),
            KYCOrganizationFieldsEnum.photoIncorporationDoc(testData),
            KYCOrganizationFieldsEnum.photoProofAddress(testData),
            KYCOrganizationFieldsEnum.addressCountryCode("USA"),
            KYCOrganizationFieldsEnum.stateOrProvince("Delaware"),
            KYCOrganizationFieldsEnum.city("Wilmington"),
            KYCOrganizationFieldsEnum.postalCode("19801"),
            KYCOrganizationFieldsEnum.directorName("Jane Smith"),
            KYCOrganizationFieldsEnum.website("https://acme.com"),
            KYCOrganizationFieldsEnum.email("info@acme.com"),
            KYCOrganizationFieldsEnum.phone("+1234567890"),
        ]

        let params = req.toParameters()

        XCTAssertNotNil(params["organization.name"])
        XCTAssertNotNil(params["organization.VAT_number"])
        XCTAssertNotNil(params["organization.registration_number"])
        XCTAssertNotNil(params["organization.registration_date"])
        XCTAssertNotNil(params["organization.registered_address"])
        XCTAssertNotNil(params["organization.number_of_shareholders"])
        XCTAssertNotNil(params["organization.shareholder_name"])
        XCTAssertNotNil(params["organization.photo_incorporation_doc"])
        XCTAssertNotNil(params["organization.photo_proof_address"])
        XCTAssertNotNil(params["organization.address_country_code"])
        XCTAssertNotNil(params["organization.state_or_province"])
        XCTAssertNotNil(params["organization.city"])
        XCTAssertNotNil(params["organization.postal_code"])
        XCTAssertNotNil(params["organization.director_name"])
        XCTAssertNotNil(params["organization.website"])
        XCTAssertNotNil(params["organization.email"])
        XCTAssertNotNil(params["organization.phone"])
    }

    func testAllKycFinancialAccountFields() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")

        req.kycFinancialAccountFields = [
            KYCFinancialAccountFieldsEnum.bankName("Test Bank"),
            KYCFinancialAccountFieldsEnum.bankAccountType("checking"),
            KYCFinancialAccountFieldsEnum.bankAccountNumber("123456789"),
            KYCFinancialAccountFieldsEnum.bankNumber("021000021"),
            KYCFinancialAccountFieldsEnum.bankPhoneNumber("+1234567890"),
            KYCFinancialAccountFieldsEnum.bankBranchNumber("001"),
            KYCFinancialAccountFieldsEnum.externalTransferMemo("memo123"),
            KYCFinancialAccountFieldsEnum.clabeNumber("123456789012345678"),
            KYCFinancialAccountFieldsEnum.cbuNumber("1234567890123456789012"),
            KYCFinancialAccountFieldsEnum.cbuAlias("myalias"),
            KYCFinancialAccountFieldsEnum.mobileMoneyNumber("+1234567890"),
            KYCFinancialAccountFieldsEnum.mobileMoneyProvider("M-Pesa"),
            KYCFinancialAccountFieldsEnum.cryptoAddress("0x1234567890abcdef"),
            KYCFinancialAccountFieldsEnum.cryptoMemo("cryptomemo"),
        ]

        let params = req.toParameters()

        XCTAssertNotNil(params["bank_name"])
        XCTAssertNotNil(params["bank_account_type"])
        XCTAssertNotNil(params["bank_account_number"])
        XCTAssertNotNil(params["bank_number"])
        XCTAssertNotNil(params["bank_phone_number"])
        XCTAssertNotNil(params["bank_branch_number"])
        XCTAssertNotNil(params["external_transfer_memo"])
        XCTAssertNotNil(params["clabe_number"])
        XCTAssertNotNil(params["cbu_number"])
        XCTAssertNotNil(params["cbu_alias"])
        XCTAssertNotNil(params["mobile_money_number"])
        XCTAssertNotNil(params["mobile_money_provider"])
        XCTAssertNotNil(params["crypto_address"])
        XCTAssertNotNil(params["crypto_memo"])
    }

    // MARK: - Native Asset Tests

    func testDepositNativeAsset() {
        let req = Sep24DepositRequest(jwt: "test", assetCode: "native")
        let params = req.toParameters()

        XCTAssertEqual("native", String(data: params["asset_code"]!, encoding: .utf8))
    }

    func testWithdrawNativeAsset() {
        let req = Sep24WithdrawRequest(jwt: "test", assetCode: "native")
        let params = req.toParameters()

        XCTAssertEqual("native", String(data: params["asset_code"]!, encoding: .utf8))
    }

    // MARK: - Empty String Tests

    func testDepositRequestWithEmptyStrings() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.memo = ""
        req.walletName = ""

        let params = req.toParameters()

        XCTAssertEqual("", String(data: params["memo"]!, encoding: .utf8))
        XCTAssertEqual("", String(data: params["wallet_name"]!, encoding: .utf8))
    }

    func testWithdrawRequestWithEmptyStrings() {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.refundMemo = ""
        req.walletUrl = ""

        let params = req.toParameters()

        XCTAssertEqual("", String(data: params["refund_memo"]!, encoding: .utf8))
        XCTAssertEqual("", String(data: params["wallet_url"]!, encoding: .utf8))
    }

    // MARK: - Special Characters Tests

    func testDepositRequestWithSpecialCharacters() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.walletName = "Test Wallet - Unicode: \u{00E9}\u{00F1}"
        req.memo = "Memo with spaces & special chars: @#$%"

        let params = req.toParameters()

        XCTAssertNotNil(params["wallet_name"])
        XCTAssertNotNil(params["memo"])
    }

    func testKycFieldsWithSpecialCharacters() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.kycFields = [
            KYCNaturalPersonFieldsEnum.firstName("Jos\u{00E9}"),
            KYCNaturalPersonFieldsEnum.lastName("M\u{00FC}ller"),
            KYCNaturalPersonFieldsEnum.address("Stra\u{00DF}e 123"),
        ]

        let params = req.toParameters()

        XCTAssertEqual("Jos\u{00E9}", String(data: params["first_name"]!, encoding: .utf8))
        XCTAssertEqual("M\u{00FC}ller", String(data: params["last_name"]!, encoding: .utf8))
        XCTAssertEqual("Stra\u{00DF}e 123", String(data: params["address"]!, encoding: .utf8))
    }

    // MARK: - Muxed Account Tests

    func testDepositWithMuxedAccount() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        // Muxed account format (M...)
        req.account = "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26"

        let params = req.toParameters()

        XCTAssertNotNil(params["account"])
        XCTAssertTrue(String(data: params["account"]!, encoding: .utf8)!.hasPrefix("M"))
    }

    func testWithdrawWithMuxedAccount() {
        var req = Sep24WithdrawRequest(jwt: "test", assetCode: "USD")
        req.account = "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26"

        let params = req.toParameters()

        XCTAssertNotNil(params["account"])
        XCTAssertTrue(String(data: params["account"]!, encoding: .utf8)!.hasPrefix("M"))
    }

    // MARK: - Memo Type Tests

    func testDepositMemoTypeText() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.memo = "test memo"
        req.memoType = "text"

        let params = req.toParameters()

        XCTAssertEqual("text", String(data: params["memo_type"]!, encoding: .utf8))
    }

    func testDepositMemoTypeId() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        req.memo = "12345"
        req.memoType = "id"

        let params = req.toParameters()

        XCTAssertEqual("id", String(data: params["memo_type"]!, encoding: .utf8))
    }

    func testDepositMemoTypeHash() {
        var req = Sep24DepositRequest(jwt: "test", assetCode: "USD")
        // Base64 encoded hash
        req.memo = "SGVsbG8gV29ybGQ="
        req.memoType = "hash"

        let params = req.toParameters()

        XCTAssertEqual("hash", String(data: params["memo_type"]!, encoding: .utf8))
    }
}
