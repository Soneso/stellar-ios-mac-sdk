//
//  Sep12DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-12 documentation code examples.
//  Uses ServerMock/RequestMock/ResponsesMock infrastructure for HTTP mocking.
//

import XCTest
import stellarsdk

// MARK: - Mock helpers

/// Provides GET /customer mock responses.
private class Sep12GetCustomerMock: ResponsesMock {
    let address: String
    let statusCode: Int
    let responseBody: String

    init(address: String, statusCode: Int = 200, responseBody: String) {
        self.address = address
        self.statusCode = statusCode
        self.responseBody = responseBody
        super.init()
    }

    override func requestMock() -> RequestMock {
        let body = responseBody
        let code = statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = code
            return body
        }

        return RequestMock(
            host: address,
            path: "/customer",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

/// Provides PUT /customer mock responses.
private class Sep12PutCustomerMock: ResponsesMock {
    let address: String
    let statusCode: Int
    let responseBody: String

    init(address: String, statusCode: Int = 200, responseBody: String) {
        self.address = address
        self.statusCode = statusCode
        self.responseBody = responseBody
        super.init()
    }

    override func requestMock() -> RequestMock {
        let body = responseBody
        let code = statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = code
            return body
        }

        return RequestMock(
            host: address,
            path: "/customer",
            httpMethod: "PUT",
            mockHandler: handler
        )
    }
}

/// Provides PUT /customer/verification mock responses.
private class Sep12PutVerificationMock: ResponsesMock {
    let address: String
    let statusCode: Int
    let responseBody: String

    init(address: String, statusCode: Int = 200, responseBody: String) {
        self.address = address
        self.statusCode = statusCode
        self.responseBody = responseBody
        super.init()
    }

    override func requestMock() -> RequestMock {
        let body = responseBody
        let code = statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = code
            return body
        }

        return RequestMock(
            host: address,
            path: "/customer/verification",
            httpMethod: "PUT",
            mockHandler: handler
        )
    }
}

/// Provides PUT /customer/callback mock responses.
private class Sep12PutCallbackMock: ResponsesMock {
    let address: String
    let statusCode: Int

    init(address: String, statusCode: Int = 200) {
        self.address = address
        self.statusCode = statusCode
        super.init()
    }

    override func requestMock() -> RequestMock {
        let code = statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = code
            return "{}"
        }

        return RequestMock(
            host: address,
            path: "/customer/callback",
            httpMethod: "PUT",
            mockHandler: handler
        )
    }
}

/// Provides DELETE /customer/{account} mock responses.
private class Sep12DeleteCustomerMock: ResponsesMock {
    let address: String
    let statusCode: Int

    init(address: String, statusCode: Int = 200) {
        self.address = address
        self.statusCode = statusCode
        super.init()
    }

    override func requestMock() -> RequestMock {
        let code = statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = code
            return "{}"
        }

        return RequestMock(
            host: address,
            path: "/customer/${accountId}",
            httpMethod: "DELETE",
            mockHandler: handler
        )
    }
}

/// Provides POST /customer/files mock responses.
private class Sep12PostFileMock: ResponsesMock {
    let address: String
    let statusCode: Int
    let responseBody: String

    init(address: String, statusCode: Int = 200, responseBody: String) {
        self.address = address
        self.statusCode = statusCode
        self.responseBody = responseBody
        super.init()
    }

    override func requestMock() -> RequestMock {
        let body = responseBody
        let code = statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = code
            return body
        }

        return RequestMock(
            host: address,
            path: "/customer/files",
            httpMethod: "POST",
            mockHandler: handler
        )
    }
}

/// Provides GET /customer/files mock responses.
private class Sep12GetFilesMock: ResponsesMock {
    let address: String
    let statusCode: Int
    let responseBody: String

    init(address: String, statusCode: Int = 200, responseBody: String) {
        self.address = address
        self.statusCode = statusCode
        self.responseBody = responseBody
        super.init()
    }

    override func requestMock() -> RequestMock {
        let body = responseBody
        let code = statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = code
            return body
        }

        return RequestMock(
            host: address,
            path: "/customer/files",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

// MARK: - Test class

class Sep12DocTest: XCTestCase {

    let kycHost = "api.anchor.com"
    let kycServiceAddress = "http://api.anchor.com"
    let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0"

    override func setUp() {
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        ServerMock.removeAll()
    }

    // MARK: - Snippet 1: Quick example (service creation + get + put)

    func testQuickExample() async {
        // Mock GET /customer -> NEEDS_INFO
        let getMock = Sep12GetCustomerMock(
            address: kycHost,
            responseBody: """
            {
                "status": "NEEDS_INFO",
                "fields": {
                    "first_name": {"type": "string", "description": "First name"},
                    "last_name": {"type": "string", "description": "Last name"},
                    "email_address": {"type": "string", "description": "Email"}
                }
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = GetCustomerInfoRequest(jwt: jwtToken)
        let getResult = await kycService.getCustomerInfo(request: request)
        withExtendedLifetime(getMock) {}

        switch getResult {
        case .success(let response):
            XCTAssertEqual("NEEDS_INFO", response.status)
            XCTAssertNotNil(response.fields)
            XCTAssertEqual(3, response.fields?.count)
        case .failure(let error):
            XCTFail("GET customer failed: \(error)")
        }

        ServerMock.removeAll()

        // Mock PUT /customer -> success
        let putMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_12345"}
            """
        )

        var putRequest = PutCustomerInfoRequest(jwt: jwtToken)
        putRequest.fields = [
            .firstName("Jane"),
            .lastName("Doe"),
            .emailAddress("jane@example.com"),
        ]

        let putResult = await kycService.putCustomerInfo(request: putRequest)
        withExtendedLifetime(putMock) {}
        switch putResult {
        case .success(let response):
            XCTAssertEqual("cust_12345", response.id)
        case .failure(let error):
            XCTFail("PUT customer failed: \(error)")
        }
    }

    // MARK: - Snippet 2 & 3: Creating the KYC service (from domain + direct URL)

    func testDirectConstruction() {
        let kycService = KycService(kycServiceAddress: "https://api.anchor.com/kyc")
        XCTAssertEqual("https://api.anchor.com/kyc", kycService.kycServiceAddress)
    }

    // MARK: - Snippet 4: Checking customer status

    func testCheckCustomerStatus() async {
        let statusMock = Sep12GetCustomerMock(
            address: kycHost,
            responseBody: """
            {
                "id": "cust_789",
                "status": "NEEDS_INFO",
                "message": "Please provide additional info",
                "fields": {
                    "email_address": {
                        "type": "string",
                        "description": "Email address",
                        "optional": false
                    },
                    "birth_date": {
                        "type": "date",
                        "description": "Date of birth",
                        "optional": true
                    },
                    "id_type": {
                        "type": "string",
                        "description": "ID type",
                        "choices": ["passport", "drivers_license", "id_card"]
                    }
                },
                "provided_fields": {
                    "first_name": {
                        "type": "string",
                        "description": "First name",
                        "status": "ACCEPTED"
                    },
                    "photo_id_front": {
                        "type": "binary",
                        "description": "Photo ID front",
                        "status": "REJECTED",
                        "error": "Image is blurry"
                    }
                }
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = GetCustomerInfoRequest(jwt: jwtToken)
        request.id = "cust_789"
        request.type = "sep6-deposit"
        request.lang = "de"

        let result = await kycService.getCustomerInfo(request: request)
        withExtendedLifetime(statusMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("NEEDS_INFO", response.status)
            XCTAssertEqual("cust_789", response.id)
            XCTAssertEqual("Please provide additional info", response.message)

            // Verify fields
            XCTAssertNotNil(response.fields)
            let emailField = response.fields?["email_address"]
            XCTAssertEqual("string", emailField?.type)
            XCTAssertEqual("Email address", emailField?.description)
            XCTAssertEqual(false, emailField?.optional) // "optional": false decodes as Optional(false)

            let idTypeField = response.fields?["id_type"]
            XCTAssertNotNil(idTypeField?.choices)
            XCTAssertEqual(3, idTypeField?.choices?.count)

            // Verify provided fields
            XCTAssertNotNil(response.providedFields)
            let firstName = response.providedFields?["first_name"]
            XCTAssertEqual("ACCEPTED", firstName?.status)

            let photoIdFront = response.providedFields?["photo_id_front"]
            XCTAssertEqual("REJECTED", photoIdFront?.status)
            XCTAssertEqual("Image is blurry", photoIdFront?.error)

        case .failure(let error):
            XCTFail("GET customer failed: \(error)")
        }
    }

    // MARK: - Snippet 5: Personal information

    func testSubmitPersonalInfo() async {
        let personalMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_personal_001"}
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = PutCustomerInfoRequest(jwt: jwtToken)
        request.type = "sep6-deposit"
        request.fields = [
            .firstName("Jane"),
            .lastName("Doe"),
            .emailAddress("jane@example.com"),
            .mobileNumber("+14155551234"),
            .birthDate(Date()),
        ]

        let result = await kycService.putCustomerInfo(request: request)
        withExtendedLifetime(personalMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("cust_personal_001", response.id)
        case .failure(let error):
            XCTFail("PUT customer failed: \(error)")
        }
    }

    // MARK: - Snippet 6: Complete natural person fields

    func testCompleteNaturalPersonFields() async {
        let fullMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_full_001"}
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = PutCustomerInfoRequest(jwt: jwtToken)
        request.fields = [
            .firstName("Jane"),
            .lastName("Doe"),
            .additionalName("Marie"),
            .address("123 Main St, Apt 4B"),
            .city("San Francisco"),
            .stateOrProvince("CA"),
            .postalCode("94102"),
            .addressCountryCode("USA"),
            .mobileNumber("+14155551234"),
            .mobileNumberFormat("E.164"),
            .emailAddress("jane@example.com"),
            .languageCode("en"),
            .birthDate(Date()),
            .birthPlace("New York, NY, USA"),
            .birthCountryCode("USA"),
            .taxId("123-45-6789"),
            .taxIdName("SSN"),
            .occupation(2512),
            .employerName("Acme Corp"),
            .employerAddress("456 Business Ave, New York, NY 10001"),
            .idType("passport"),
            .idNumber("AB123456"),
            .idCountryCode("USA"),
            .idIssueDate("2020-01-15"),
            .idExpirationDate("2030-01-15"),
            .sex("female"),
            .ipAddress("192.168.1.1"),
            .referralId("REF123"),
        ]

        let result = await kycService.putCustomerInfo(request: request)
        withExtendedLifetime(fullMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("cust_full_001", response.id)
        case .failure(let error):
            XCTFail("PUT customer with all fields failed: \(error)")
        }
    }

    // MARK: - Snippet 7: Financial account information

    func testFinancialAccountInfo() async {
        let finMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_fin_001"}
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = PutCustomerInfoRequest(jwt: jwtToken)
        request.fields = [.firstName("Jane"), .lastName("Doe")]
        request.financialAccountFields = [
            .bankName("First National Bank"),
            .bankAccountType("checking"),
            .bankAccountNumber("1234567890"),
            .bankNumber("021000021"),
            .bankBranchNumber("001"),
            .bankPhoneNumber("+18005551234"),
            .externalTransferMemo("WIRE-REF-12345"),
            .clabeNumber("032180000118359719"),
            .cbuNumber("0110000000001234567890"),
            .cbuAlias("mi.cuenta.arg"),
            .mobileMoneyNumber("+254712345678"),
            .mobileMoneyProvider("M-Pesa"),
            .cryptoAddress("0x742d35Cc6634C0532925a3b844Bc9e7595f0AB12"),
        ]

        let result = await kycService.putCustomerInfo(request: request)
        withExtendedLifetime(finMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("cust_fin_001", response.id)
        case .failure(let error):
            XCTFail("PUT customer with financial fields failed: \(error)")
        }
    }

    // MARK: - Snippet 8: Uploading ID documents (binary fields)

    func testUploadIdDocuments() async {
        let docMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_doc_001"}
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        // Simulate binary data
        let idFrontData = "fake-id-front-image".data(using: .utf8)!
        let idBackData = "fake-id-back-image".data(using: .utf8)!

        var request = PutCustomerInfoRequest(jwt: jwtToken)
        request.id = "cust_doc_001"
        request.fields = [
            .idType("passport"),
            .idNumber("AB123456"),
            .idCountryCode("USA"),
            .idIssueDate("2020-01-15"),
            .idExpirationDate("2030-01-15"),
            .photoIdFront(idFrontData),
            .photoIdBack(idBackData),
        ]

        let result = await kycService.putCustomerInfo(request: request)
        withExtendedLifetime(docMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("cust_doc_001", response.id)
        case .failure(let error):
            XCTFail("PUT customer with documents failed: \(error)")
        }
    }

    // MARK: - Snippet 9: Organization KYC

    func testOrganizationKyc() async {
        let orgMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_org_001"}
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = PutCustomerInfoRequest(jwt: jwtToken)
        request.organizationFields = [
            .name("Acme Corporation"),
            .VATNumber("DE123456789"),
            .registrationNumber("HRB 12345"),
            .registrationDate("2010-06-15"),
            .registeredAddress("456 Business Ave, Suite 100"),
            .city("New York"),
            .stateOrProvince("NY"),
            .postalCode("10001"),
            .addressCountryCode("USA"),
            .numberOfShareholders(3),
            .shareholderName("John Smith"),
            .directorName("Jane Doe"),
            .website("https://acme-corp.example.com"),
            .email("contact@acme-corp.example.com"),
            .phone("+12125551234"),
        ]
        request.financialAccountFields = [
            .bankName("Business Bank"),
            .bankAccountNumber("9876543210"),
            .bankNumber("021000021"),
        ]

        let result = await kycService.putCustomerInfo(request: request)
        withExtendedLifetime(orgMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("cust_org_001", response.id)
        case .failure(let error):
            XCTFail("PUT organization KYC failed: \(error)")
        }
    }

    // MARK: - Snippet 10: Custom fields

    func testCustomFields() async {
        let customMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_custom_001"}
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = PutCustomerInfoRequest(jwt: jwtToken)
        request.id = "cust_custom_001"
        request.extraFields = [
            "custom_field_1": "custom value",
            "anchor_specific_id": "ABC123",
        ]
        request.extraFiles = [
            "additional_document": "fake-pdf-data".data(using: .utf8)!,
        ]

        let result = await kycService.putCustomerInfo(request: request)
        withExtendedLifetime(customMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("cust_custom_001", response.id)
        case .failure(let error):
            XCTFail("PUT custom fields failed: \(error)")
        }
    }

    // MARK: - Snippet 11: Verifying contact information

    func testVerifyContactInfo() async {
        // First: GET customer with VERIFICATION_REQUIRED status
        let verifyGetMock = Sep12GetCustomerMock(
            address: kycHost,
            responseBody: """
            {
                "id": "cust_verify_001",
                "status": "NEEDS_INFO",
                "provided_fields": {
                    "mobile_number": {
                        "type": "string",
                        "description": "Mobile number",
                        "status": "VERIFICATION_REQUIRED"
                    }
                }
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var getRequest = GetCustomerInfoRequest(jwt: jwtToken)
        getRequest.id = "cust_verify_001"

        let getResult = await kycService.getCustomerInfo(request: getRequest)
        withExtendedLifetime(verifyGetMock) {}
        if case .success(let response) = getResult {
            let mobileField = response.providedFields?["mobile_number"]
            XCTAssertEqual("VERIFICATION_REQUIRED", mobileField?.status)
        } else {
            XCTFail("GET customer for verification check failed")
        }

        ServerMock.removeAll()

        // Second: PUT /customer with verification code
        let verifyPutMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_verify_001"}
            """
        )

        var putRequest = PutCustomerInfoRequest(jwt: jwtToken)
        putRequest.id = "cust_verify_001"
        putRequest.extraFields = [
            "mobile_number_verification": "123456",
        ]

        let putResult = await kycService.putCustomerInfo(request: putRequest)
        withExtendedLifetime(verifyPutMock) {}
        switch putResult {
        case .success(let response):
            XCTAssertEqual("cust_verify_001", response.id)
        case .failure(let error):
            XCTFail("PUT verification code failed: \(error)")
        }
    }

    // MARK: - Snippet 12: Deprecated verification endpoint

    func testDeprecatedVerificationEndpoint() async {
        let deprecatedMock = Sep12PutVerificationMock(
            address: kycHost,
            responseBody: """
            {
                "status": "ACCEPTED",
                "id": "cust_verify_002"
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        let request = PutCustomerVerificationRequest(
            id: "cust_verify_002",
            fields: [
                "mobile_number_verification": "123456",
                "email_address_verification": "ABC123",
            ],
            jwt: jwtToken
        )

        // Returns GetCustomerInfoResponseEnum
        let result = await kycService.putCustomerVerification(request: request)
        withExtendedLifetime(deprecatedMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("ACCEPTED", response.status)
        case .failure(let error):
            XCTFail("PUT verification (deprecated) failed: \(error)")
        }
    }

    // MARK: - Snippet 13: File upload

    func testFileUpload() async {
        let postFileMock = Sep12PostFileMock(
            address: kycHost,
            responseBody: """
            {
                "file_id": "file_abc123",
                "content_type": "image/jpeg",
                "size": 12345,
                "customer_id": "cust_file_001"
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        let fileData = "fake-image-data".data(using: .utf8)!
        let uploadResult = await kycService.postCustomerFile(file: fileData, jwtToken: jwtToken)
        withExtendedLifetime(postFileMock) {}

        switch uploadResult {
        case .success(let fileResponse):
            XCTAssertEqual("file_abc123", fileResponse.fileId)
            XCTAssertEqual("image/jpeg", fileResponse.contentType)
            XCTAssertEqual(12345, fileResponse.size)
            XCTAssertEqual("cust_file_001", fileResponse.customerId)
        case .failure(let error):
            XCTFail("POST customer file failed: \(error)")
        }

        ServerMock.removeAll()

        // Reference file in PUT /customer
        let fileRefMock = Sep12PutCustomerMock(
            address: kycHost,
            responseBody: """
            {"id": "cust_file_001"}
            """
        )

        var putRequest = PutCustomerInfoRequest(jwt: jwtToken)
        putRequest.id = "cust_file_001"
        putRequest.extraFields = [
            "photo_id_front_file_id": "file_abc123",
        ]

        let putResult = await kycService.putCustomerInfo(request: putRequest)
        withExtendedLifetime(fileRefMock) {}
        switch putResult {
        case .success(let response):
            XCTAssertEqual("cust_file_001", response.id)
        case .failure(let error):
            XCTFail("PUT customer with file reference failed: \(error)")
        }
    }

    // MARK: - Snippet 14: Retrieve file information

    func testGetCustomerFiles() async {
        let getFilesMock = Sep12GetFilesMock(
            address: kycHost,
            responseBody: """
            {
                "files": [
                    {
                        "file_id": "file_abc123",
                        "content_type": "image/jpeg",
                        "size": 12345,
                        "customer_id": "cust_file_001"
                    },
                    {
                        "file_id": "file_def456",
                        "content_type": "application/pdf",
                        "size": 67890
                    }
                ]
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        let result = await kycService.getCustomerFiles(fileId: "file_abc123", jwtToken: jwtToken)
        withExtendedLifetime(getFilesMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual(2, response.files.count)
            XCTAssertEqual("file_abc123", response.files[0].fileId)
            XCTAssertEqual("image/jpeg", response.files[0].contentType)
            XCTAssertEqual(12345, response.files[0].size)
            XCTAssertEqual("cust_file_001", response.files[0].customerId)
            XCTAssertEqual("file_def456", response.files[1].fileId)
            XCTAssertNil(response.files[1].customerId)
        case .failure(let error):
            XCTFail("GET customer files failed: \(error)")
        }
    }

    // MARK: - Snippet 15: Callback notifications

    func testPutCustomerCallback() async {
        let callbackMock = Sep12PutCallbackMock(address: kycHost)

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = PutCustomerCallbackRequest(
            url: "https://myapp.com/kyc-callback",
            jwt: jwtToken
        )
        request.id = "cust_callback_001"

        let result = await kycService.putCustomerCallback(request: request)
        withExtendedLifetime(callbackMock) {}
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("PUT callback failed: \(error)")
        }
    }

    // MARK: - Snippet 16: Deleting customer data

    func testDeleteCustomerData() async {
        let deleteMock = Sep12DeleteCustomerMock(address: kycHost)

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        let accountId = "GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        let result = await kycService.deleteCustomerInfo(account: accountId, jwt: jwtToken)
        withExtendedLifetime(deleteMock) {}
        switch result {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("DELETE customer failed: \(error)")
        }
    }

    // MARK: - Snippet 17: Shared/omnibus accounts

    func testSharedAccounts() async {
        let sharedMock = Sep12GetCustomerMock(
            address: kycHost,
            responseBody: """
            {
                "id": "cust_shared_001",
                "status": "ACCEPTED"
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var getRequest = GetCustomerInfoRequest(jwt: jwtToken)
        getRequest.account = "GXXXXXX..."
        getRequest.memo = "12345"
        getRequest.memoType = "id"

        let result = await kycService.getCustomerInfo(request: getRequest)
        withExtendedLifetime(sharedMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("ACCEPTED", response.status)
            XCTAssertEqual("cust_shared_001", response.id)
        case .failure(let error):
            XCTFail("GET shared account customer failed: \(error)")
        }
    }

    // MARK: - Snippet 18: Contract accounts

    func testContractAccounts() async {
        let contractMock = Sep12GetCustomerMock(
            address: kycHost,
            responseBody: """
            {
                "status": "NEEDS_INFO",
                "fields": {
                    "first_name": {"type": "string", "description": "First name"},
                    "last_name": {"type": "string", "description": "Last name"}
                }
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        let contractAccount = "CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

        var getRequest = GetCustomerInfoRequest(jwt: jwtToken)
        getRequest.account = contractAccount
        // Do NOT set memo for contract accounts

        let result = await kycService.getCustomerInfo(request: getRequest)
        withExtendedLifetime(contractMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("NEEDS_INFO", response.status)
            XCTAssertNotNil(response.fields)
        case .failure(let error):
            XCTFail("GET contract account customer failed: \(error)")
        }
    }

    // MARK: - Snippet 19: Transaction-based KYC

    func testTransactionBasedKyc() async {
        let txMock = Sep12GetCustomerMock(
            address: kycHost,
            responseBody: """
            {
                "status": "NEEDS_INFO",
                "fields": {
                    "proof_of_income": {
                        "type": "binary",
                        "description": "Proof of income for large transactions"
                    }
                }
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var getRequest = GetCustomerInfoRequest(jwt: jwtToken)
        getRequest.transactionId = "tx_abc123"
        getRequest.type = "sep6"

        let result = await kycService.getCustomerInfo(request: getRequest)
        withExtendedLifetime(txMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("NEEDS_INFO", response.status)
            XCTAssertNotNil(response.fields?["proof_of_income"])
        case .failure(let error):
            XCTFail("GET transaction-based KYC failed: \(error)")
        }
    }

    // MARK: - Snippet 20: Error handling

    func testErrorHandling() async {
        // Test successful response with status handling
        let errMock = Sep12GetCustomerMock(
            address: kycHost,
            responseBody: """
            {
                "id": "cust_err_001",
                "status": "REJECTED",
                "message": "Identity could not be verified"
            }
            """
        )

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = GetCustomerInfoRequest(jwt: jwtToken)
        request.id = "cust_err_001"

        let result = await kycService.getCustomerInfo(request: request)
        withExtendedLifetime(errMock) {}
        switch result {
        case .success(let response):
            XCTAssertEqual("REJECTED", response.status)
            XCTAssertEqual("Identity could not be verified", response.message)
        case .failure(let error):
            XCTFail("GET customer unexpectedly failed: \(error)")
        }
    }

    func testErrorHandlingBadRequest() async {
        // Simulate a 400 Bad Request
        let badRequestMock = RequestMock(
            host: kycHost,
            path: "/customer",
            httpMethod: "GET",
            statusCode: 400,
            mockHandler: { mock, request in
                return "{\"error\": \"Missing required field: first_name\"}"
            }
        )
        ServerMock.add(mock: badRequestMock)

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = GetCustomerInfoRequest(jwt: jwtToken)
        request.id = "cust_bad"

        let result = await kycService.getCustomerInfo(request: request)
        switch result {
        case .success:
            XCTFail("Should have failed with bad request")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("Missing required field: first_name", message)
            default:
                XCTFail("Expected badRequest, got: \(error)")
            }
        }
    }

    func testErrorHandlingNotFound() async {
        // Simulate a 404 Not Found
        let notFoundMock = RequestMock(
            host: kycHost,
            path: "/customer",
            httpMethod: "GET",
            statusCode: 404,
            mockHandler: { mock, request in
                return "{\"error\": \"Customer not found\"}"
            }
        )
        ServerMock.add(mock: notFoundMock)

        let kycService = KycService(kycServiceAddress: kycServiceAddress)

        var request = GetCustomerInfoRequest(jwt: jwtToken)
        request.id = "nonexistent"

        let result = await kycService.getCustomerInfo(request: request)
        switch result {
        case .success:
            XCTFail("Should have failed with not found")
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("Customer not found", message)
            default:
                XCTFail("Expected notFound, got: \(error)")
            }
        }
    }
}
