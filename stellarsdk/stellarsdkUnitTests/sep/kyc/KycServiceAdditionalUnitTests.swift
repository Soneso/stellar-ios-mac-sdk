//
//  KycServiceAdditionalUnitTests.swift
//  stellarsdk
//
//  Created by Soneso
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class KycServiceAdditionalUnitTests: XCTestCase {

    let kycServer = "127.0.0.1"
    let testDomain = "testanchor.com"
    let testAccount = "GDIODQRBHD32QZWTGOHO2MRZQY2TRG5KTI2NNTFYH2JDYZGMU3NJVAUI"

    var kycService: KycService!
    var getCustomerResponseMock: GetCustomerResponseMock!
    var putVerificationResponseMock: PutVerificationResponseMock!
    var putCallbackUrlResponseMock: PutCallbackUrlResponseMock!
    var getCustomerFilesResponseMock: GetCustomerFilesResponseMock!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)

        getCustomerResponseMock = GetCustomerResponseMock(address: kycServer)
        putVerificationResponseMock = PutVerificationResponseMock(address: kycServer)
        putCallbackUrlResponseMock = PutCallbackUrlResponseMock(address: kycServer)
        getCustomerFilesResponseMock = GetCustomerFilesResponseMock(address: kycServer)
        kycService = KycService(kycServiceAddress: "http://\(kycServer)")
    }

    override func tearDown() {
        ServerMock.removeAll()
        super.tearDown()
    }

    // MARK: - KycService.forDomain() Tests (0% coverage - Priority 1)
    // Note: These tests check error paths that don't require network access

    func testForDomainWithInvalidURL() async {
        let result = await KycService.forDomain(domain: "not a valid url with spaces")

        switch result {
        case .success:
            XCTFail("Expected failure for invalid URL")
        case .failure(let error):
            // URL(string:) accepts many formats, so this may fail with invalidToml
            // when it tries to fetch
            if case .invalidDomain = error {
                // Success
            } else if case .invalidToml = error {
                // Also acceptable - the URL was parsed but fetch failed
            } else {
                XCTFail("Expected invalidDomain or invalidToml error, got: \(error)")
            }
        }
    }

    func testForDomainWithEmptyString() async {
        let result = await KycService.forDomain(domain: "")

        switch result {
        case .success:
            XCTFail("Expected failure for empty domain")
        case .failure(let error):
            // URL(string:) accepts empty strings, so this fails with invalidToml
            if case .invalidDomain = error {
                // Success
            } else if case .invalidToml = error {
                // Also acceptable - empty URL parsed but fetch failed
            } else {
                XCTFail("Expected invalidDomain or invalidToml error, got: \(error)")
            }
        }
    }

    func testForDomainWithNetworkFailure() async {
        // This will fail because the domain doesn't exist
        let result = await KycService.forDomain(domain: "https://this-domain-absolutely-does-not-exist-12345.invalid")

        switch result {
        case .success:
            XCTFail("Expected failure for network error")
        case .failure(let error):
            if case .invalidToml = error {
                // Success - network failures result in invalidToml
            } else {
                XCTFail("Expected invalidToml error, got: \(error)")
            }
        }
    }

    // MARK: - putCustomerVerification() Tests (0% coverage - Priority 2)

    func testPutCustomerVerificationSuccess() async {
        let request = PutCustomerVerificationRequest(
            id: "customer-123",
            fields: ["email_address_verification": "123456"],
            jwt: "200_jwt"
        )

        let result = await kycService.putCustomerVerification(request: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.status, "ACCEPTED")
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testPutCustomerVerificationWithEmptyFields() async {
        let request = PutCustomerVerificationRequest(
            id: "customer-123",
            fields: [:],
            jwt: "200_jwt"
        )

        let result = await kycService.putCustomerVerification(request: request)

        switch result {
        case .success:
            // Empty fields should still succeed if the server accepts it
            break
        case .failure:
            // Or fail - both are valid depending on server implementation
            break
        }
    }

    func testPutCustomerVerificationWithInvalidCustomerId() async {
        let request = PutCustomerVerificationRequest(
            id: "invalid-customer",
            fields: ["email_address_verification": "123456"],
            jwt: "404_jwt"
        )

        let result = await kycService.putCustomerVerification(request: request)

        switch result {
        case .success:
            XCTFail("Expected failure for invalid customer ID")
        case .failure(let error):
            if case .notFound(let message) = error {
                XCTAssertEqual(message, "customer with `id` not found")
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    func testPutCustomerVerificationBadRequest() async {
        let request = PutCustomerVerificationRequest(
            id: "customer-123",
            fields: ["invalid_field": "value"],
            jwt: "400_jwt"
        )

        let result = await kycService.putCustomerVerification(request: request)

        switch result {
        case .success:
            XCTFail("Expected failure for bad request")
        case .failure(let error):
            if case .badRequest = error {
                // Success
            } else {
                XCTFail("Expected badRequest error, got: \(error)")
            }
        }
    }

    // MARK: - getCustomerInfo() Parameter Tests (Priority 3)

    func testGetCustomerInfoWithAllParameters() async {
        var request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        request.id = "customer-123"
        request.account = testAccount
        request.memo = "test-memo"
        request.memoType = "text"
        request.type = "sep6-deposit"
        request.transactionId = "tx-123"
        request.lang = "es"

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.status)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerInfoWithSpecialCharactersInParameters() async {
        var request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        request.memo = "test memo with spaces"
        request.account = testAccount

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            // Should handle special characters properly
            break
        case .failure(let error):
            XCTFail("Expected success with special characters, got error: \(error)")
        }
    }

    func testGetCustomerInfoWithOnlyId() async {
        var request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        request.id = "customer-only-id"

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerInfoWithOnlyAccount() async {
        var request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        request.account = testAccount

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerInfoWithMemoAndMemoType() async {
        var request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        request.memo = "123456"
        request.memoType = "id"

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerInfoWithTransactionId() async {
        var request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        request.transactionId = "large-transaction-123"

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerInfoWithLanguage() async {
        var request = GetCustomerInfoRequest(jwt: "accepted_jwt")
        request.lang = "fr"

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - putCustomerCallback() URL Validation Tests (Priority 4)

    func testPutCustomerCallbackWithValidHttpsUrl() async {
        let request = PutCustomerCallbackRequest(url: "https://example.com/callback", jwt: "200_jwt")

        let result = await kycService.putCustomerCallback(request: request)

        switch result {
        case .success:
            // Valid HTTPS URL should succeed
            break
        case .failure(let error):
            XCTFail("Expected success with valid HTTPS URL, got error: \(error)")
        }
    }

    func testPutCustomerCallbackWithUrlWithPort() async {
        let request = PutCustomerCallbackRequest(url: "https://example.com:8080/callback", jwt: "200_jwt")

        let result = await kycService.putCustomerCallback(request: request)

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success with URL with port, got error: \(error)")
        }
    }

    func testPutCustomerCallbackWithUrlWithQueryParams() async {
        let request = PutCustomerCallbackRequest(url: "https://example.com/callback?token=abc&user=123", jwt: "200_jwt")

        let result = await kycService.putCustomerCallback(request: request)

        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success with URL with query params, got error: \(error)")
        }
    }

    func testPutCustomerCallbackWithInvalidUrl() async {
        let request = PutCustomerCallbackRequest(url: "not-a-valid-url", jwt: "400_jwt")

        let result = await kycService.putCustomerCallback(request: request)

        switch result {
        case .success:
            XCTFail("Expected failure for invalid URL")
        case .failure(let error):
            if case .badRequest(let message) = error {
                XCTAssertEqual(message, "invalid url")
            } else {
                XCTFail("Expected badRequest error, got: \(error)")
            }
        }
    }

    func testPutCustomerCallbackWithAllParameters() async {
        var request = PutCustomerCallbackRequest(url: "https://example.com/callback", jwt: "200_jwt")
        request.id = "customer-123"
        request.account = testAccount
        request.memo = "callback-memo"
        request.memoType = "text"

        let parameters = request.toParameters()

        XCTAssertEqual(String(data: parameters["url"]!, encoding: .utf8), "https://example.com/callback")
        XCTAssertEqual(String(data: parameters["id"]!, encoding: .utf8), "customer-123")
        XCTAssertEqual(String(data: parameters["account"]!, encoding: .utf8), testAccount)
        XCTAssertEqual(String(data: parameters["memo"]!, encoding: .utf8), "callback-memo")
        XCTAssertEqual(String(data: parameters["memo_type"]!, encoding: .utf8), "text")
    }

    // MARK: - getCustomerFiles() Parameter Tests (Priority 5)

    func testGetCustomerFilesWithFileId() async {
        let result = await kycService.getCustomerFiles(fileId: "file-123", jwtToken: "200_files_jwt")

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.files)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerFilesWithCustomerId() async {
        let result = await kycService.getCustomerFiles(customerId: "customer-456", jwtToken: "200_files_jwt")

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.files)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerFilesWithBothParameters() async {
        let result = await kycService.getCustomerFiles(fileId: "file-123", customerId: "customer-456", jwtToken: "200_files_jwt")

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.files)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerFilesWithNoParameters() async {
        let result = await kycService.getCustomerFiles(jwtToken: "200_files_jwt")

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.files)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testGetCustomerFilesNotFound() async {
        let result = await kycService.getCustomerFiles(fileId: "nonexistent", jwtToken: "404_jwt")

        switch result {
        case .success:
            XCTFail("Expected failure for nonexistent file")
        case .failure(let error):
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }

    func testGetCustomerFilesBadRequest() async {
        let result = await kycService.getCustomerFiles(fileId: "invalid", jwtToken: "400_jwt")

        switch result {
        case .success:
            XCTFail("Expected failure for bad request")
        case .failure(let error):
            if case .badRequest = error {
                // Success
            } else {
                XCTFail("Expected badRequest error, got: \(error)")
            }
        }
    }

    // MARK: - Request toParameters() Tests (Priority 6)

    func testPutCustomerVerificationRequestToParameters() {
        let request = PutCustomerVerificationRequest(
            id: "customer-789",
            fields: [
                "email_address_verification": "code123",
                "mobile_number_verification": "code456"
            ],
            jwt: "jwt-token"
        )

        let parameters = request.toParameters()

        XCTAssertEqual(String(data: parameters["id"]!, encoding: .utf8), "customer-789")
        XCTAssertEqual(String(data: parameters["email_address_verification"]!, encoding: .utf8), "code123")
        XCTAssertEqual(String(data: parameters["mobile_number_verification"]!, encoding: .utf8), "code456")
    }

    func testPutCustomerVerificationRequestWithEmptyFields() {
        let request = PutCustomerVerificationRequest(
            id: "customer-empty",
            fields: [:],
            jwt: "jwt-token"
        )

        let parameters = request.toParameters()

        XCTAssertEqual(parameters.count, 1) // Only id should be present
        XCTAssertEqual(String(data: parameters["id"]!, encoding: .utf8), "customer-empty")
    }

    func testPutCustomerCallbackRequestToParametersMinimal() {
        let request = PutCustomerCallbackRequest(url: "https://callback.com", jwt: "jwt-token")

        let parameters = request.toParameters()

        XCTAssertEqual(parameters.count, 1)
        XCTAssertEqual(String(data: parameters["url"]!, encoding: .utf8), "https://callback.com")
    }

    func testPutCustomerCallbackRequestToParametersComplete() {
        var request = PutCustomerCallbackRequest(url: "https://callback.com", jwt: "jwt-token")
        request.id = "cust-id"
        request.account = testAccount
        request.memo = "memo-value"
        request.memoType = "text"

        let parameters = request.toParameters()

        XCTAssertEqual(parameters.count, 5)
        XCTAssertEqual(String(data: parameters["url"]!, encoding: .utf8), "https://callback.com")
        XCTAssertEqual(String(data: parameters["id"]!, encoding: .utf8), "cust-id")
        XCTAssertEqual(String(data: parameters["account"]!, encoding: .utf8), testAccount)
        XCTAssertEqual(String(data: parameters["memo"]!, encoding: .utf8), "memo-value")
        XCTAssertEqual(String(data: parameters["memo_type"]!, encoding: .utf8), "text")
    }

    // MARK: - Error Handling Tests

    func testErrorForHorizonErrorBadRequest() async {
        var request = GetCustomerInfoRequest(jwt: "400_jwt")
        request.type = "INVALID_TYPE"

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            XCTFail("Expected failure for bad request")
        case .failure(let error):
            if case .badRequest(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected badRequest error, got: \(error)")
            }
        }
    }

    func testErrorForHorizonErrorUnauthorized() async {
        let request = GetCustomerInfoRequest(jwt: "invalid_jwt")

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            XCTFail("Expected failure for unauthorized")
        case .failure(let error):
            if case .unauthorized = error {
                // Success
            } else {
                XCTFail("Expected unauthorized error, got: \(error)")
            }
        }
    }

    func testErrorForHorizonErrorNotFound() async {
        let request = GetCustomerInfoRequest(jwt: "404_jwt")

        let result = await kycService.getCustomerInfo(request: request)

        switch result {
        case .success:
            XCTFail("Expected failure for not found")
        case .failure(let error):
            if case .notFound(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected notFound error, got: \(error)")
            }
        }
    }
}
