//
//  Sep30DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-30 documentation code examples.
//  Uses ServerMock/RequestMock/ResponsesMock infrastructure for HTTP mocking.
//

import XCTest
import stellarsdk

// MARK: - Mock helpers (scoped to this file)

/// Mock for POST /accounts/{address} (register account) returning a single owner identity.
private class Sep30DocRegisterMock: ResponsesMock {
    let host: String
    let address: String

    init(host: String, address: String) {
        self.host = host
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                // Body received
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "POST",
                           mockHandler: handler)
    }

    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "owner" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
      ]
    }
    """
}

/// Mock for POST /accounts/{address} (register) returning sender + receiver identities.
private class Sep30DocRegisterSharedMock: ResponsesMock {
    let host: String
    let address: String

    init(host: String, address: String) {
        self.host = host
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                // Body received
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "POST",
                           mockHandler: handler)
    }

    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "sender" },
        { "role": "receiver" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
      ]
    }
    """
}

/// Mock for PUT /accounts/{address} (update identities).
private class Sep30DocUpdateMock: ResponsesMock {
    let host: String
    let address: String

    init(host: String, address: String) {
        self.host = host
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                // Body received
            }
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "PUT",
                           mockHandler: handler)
    }

    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "owner" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
      ]
    }
    """
}

/// Mock for GET /accounts/{address} (account details) with authenticated identity.
private class Sep30DocDetailsMock: ResponsesMock {
    let host: String
    let address: String

    init(host: String, address: String) {
        self.host = host
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "owner", "authenticated": true },
        { "role": "sender" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
      ]
    }
    """
}

/// Mock for DELETE /accounts/{address} (delete account).
private class Sep30DocDeleteMock: ResponsesMock {
    let host: String
    let address: String

    init(host: String, address: String) {
        self.host = host
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "DELETE",
                           mockHandler: handler)
    }

    let success = """
    {
      "address": "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
      "identities": [
        { "role": "owner" }
      ],
      "signers": [
        { "key": "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA" }
      ]
    }
    """
}

/// Mock for GET /accounts (list accounts).
private class Sep30DocListAccountsMock: ResponsesMock {
    let host: String

    init(host: String) {
        self.host = host
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.success
        }

        return RequestMock(host: host,
                           path: "/accounts",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    let success = """
    {
      "accounts": [
        {
          "address": "GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD",
          "identities": [
            { "role": "owner", "authenticated": true }
          ],
          "signers": [
            { "key": "GBTPAH6NWK25GESZYJ3XWPTNQUIMYNK7VU7R4NSTMZXOEKCOBKJVJ2XY" }
          ]
        },
        {
          "address": "GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ",
          "identities": [
            { "role": "sender", "authenticated": true },
            { "role": "receiver" }
          ],
          "signers": [
            { "key": "GAOCJE4737GYN2EGCGWPNNCDVDKX7XKC4UKOKIF7CRRYIFLPZLH3U3UN" }
          ]
        },
        {
          "address": "GD62WD2XTOCAENMB34FB2SEW6JHPB7AFYQAJ5OCQ3TYRW5MOJXLKGTMM",
          "identities": [
            { "role": "sender" },
            { "role": "receiver", "authenticated": true }
          ],
          "signers": [
            { "key": "GDFPM46I2L2DXB3TWAKPMLUMEW226WXLRWJNS4QHXXKJXEUW3M6OAFBY" }
          ]
        }
      ]
    }
    """
}

/// Mock for POST /accounts/{address}/sign/{signingAddress} (sign transaction).
private class Sep30DocSignMock: ResponsesMock {
    let host: String
    let address: String
    let signingAddress: String

    init(host: String, address: String, signingAddress: String) {
        self.host = host
        self.address = address
        self.signingAddress = signingAddress
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let _ = request.httpBodyStream?.readfully() {
                // Body received
            }
            mock.statusCode = 200
            return self?.signSuccess
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)/sign/\(signingAddress)",
                           httpMethod: "POST",
                           mockHandler: handler)
    }

    let signSuccess = """
    {
      "signature": "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS",
      "network_passphrase": "Test SDF Network ; September 2015"
    }
    """
}

/// Mock for error responses on POST /accounts/{address}.
private class Sep30DocErrorMock: ResponsesMock {
    let host: String
    let address: String
    let statusCode: Int
    let errorMessage: String

    init(host: String, address: String, statusCode: Int, errorMessage: String) {
        self.host = host
        self.address = address
        self.statusCode = statusCode
        self.errorMessage = errorMessage
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }
            if let _ = request.httpBodyStream?.readfully() {
                // Body received
            }
            mock.statusCode = self.statusCode
            return """
                {
                  "error": "\(self.errorMessage)"
                }
                """
        }

        return RequestMock(host: host,
                           path: "/accounts/\(address)",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
}

// MARK: - Test class

class Sep30DocTest: XCTestCase {

    let recoveryHost = "127.0.0.1"
    let accountAddress = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let signingAddress = "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA"
    let jwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0"

    override func setUp() {
        URLProtocol.registerClass(ServerMock.self)
    }

    override func tearDown() {
        ServerMock.removeAll()
    }

    // MARK: - Snippet 1: Quick Example (register account)

    func testQuickExample() async {
        let mock = Sep30DocRegisterMock(host: recoveryHost, address: accountAddress)

        // Snippet 1: Quick Example
        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        let authMethods = [
            Sep30AuthMethod(type: "email", value: "user@example.com"),
            Sep30AuthMethod(type: "phone_number", value: "+14155551234"),
        ]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)

        let request = Sep30Request(identities: [identity])
        let responseEnum = await service.registerAccount(
            address: accountAddress,
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(accountAddress, response.address)
            XCTAssertEqual(1, response.signers.count)
            let signerKey = response.signers[0].key
            XCTAssertEqual(signingAddress, signerKey)
        case .failure(let error):
            XCTFail("Quick example failed: \(error)")
        }
        _ = mock
    }

    // MARK: - Snippet 2: Creating the Recovery Service

    func testCreateRecoveryService() {
        // Snippet 2: Service creation (no network call needed)
        let service = RecoveryService(serviceAddress: "https://recovery.example.com")
        XCTAssertEqual("https://recovery.example.com", service.serviceAddress)
    }

    // MARK: - Snippet 3: Registering an Account

    func testRegisterAccount() async {
        let mock = Sep30DocRegisterMock(host: recoveryHost, address: accountAddress)

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        let authMethods = [
            Sep30AuthMethod(type: "stellar_address", value: "GXXXX..."),
            Sep30AuthMethod(type: "email", value: "user@example.com"),
            Sep30AuthMethod(type: "phone_number", value: "+14155551234"),
        ]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
        let request = Sep30Request(identities: [identity])

        let responseEnum = await service.registerAccount(
            address: accountAddress,
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(accountAddress, response.address)
            XCTAssertFalse(response.signers.isEmpty)
            XCTAssertFalse(response.identities.isEmpty)
            for signer in response.signers {
                XCTAssertFalse(signer.key.isEmpty)
            }
            for identity in response.identities {
                XCTAssertNotNil(identity.role)
            }
        case .failure(let error):
            XCTFail("Registration failed: \(error)")
        }
        _ = mock
    }

    // MARK: - Snippet 4: Adding the Recovery Signer (SetOptionsOperation construction)

    func testSetOptionsOperationConstruction() throws {
        // Snippet 4: Verify SetOptionsOperation can be constructed correctly
        // (We cannot submit to testnet from a mock test, so we verify object creation.)
        let signerKey = signingAddress

        let addSignerOp = try SetOptionsOperation(
            sourceAccountId: nil,
            signer: Signer.ed25519PublicKey(keyPair: try KeyPair(accountId: signerKey)),
            signerWeight: 1
        )
        XCTAssertNotNil(addSignerOp)

        let setThresholdsOp = try SetOptionsOperation(
            sourceAccountId: nil,
            lowThreshold: 2,
            mediumThreshold: 2,
            highThreshold: 2
        )
        XCTAssertNotNil(setThresholdsOp)
    }

    // MARK: - Snippet 5: Multi-Server Recovery (register with two services)

    func testMultiServerRegistration() async {
        // Use different address tokens so the two mocks don't conflict.
        let address1 = "SERVER1_ADDR"
        let address2 = "SERVER2_ADDR"

        let mock1 = Sep30DocRegisterMock(host: recoveryHost, address: address1)
        let mock2 = Sep30DocRegisterMock(host: recoveryHost, address: address2)

        let authMethods = [Sep30AuthMethod(type: "email", value: "user@example.com")]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
        let request = Sep30Request(identities: [identity])

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        // Register with first server
        let responseEnum1 = await service.registerAccount(
            address: address1,
            request: request,
            jwt: jwtToken
        )
        guard case .success(let response1) = responseEnum1 else {
            XCTFail("First registration failed")
            return
        }
        XCTAssertFalse(response1.signers.isEmpty)
        let signerKey1 = response1.signers[0].key

        // Register with second server
        let responseEnum2 = await service.registerAccount(
            address: address2,
            request: request,
            jwt: jwtToken
        )
        guard case .success(let response2) = responseEnum2 else {
            XCTFail("Second registration failed")
            return
        }
        XCTAssertFalse(response2.signers.isEmpty)
        let signerKey2 = response2.signers[0].key

        // Both should return valid signer keys
        XCTAssertFalse(signerKey1.isEmpty)
        XCTAssertFalse(signerKey2.isEmpty)

        _ = mock1
        _ = mock2
    }

    // MARK: - Snippet 6: Recovering an Account (sign transaction)

    func testSignTransaction() async {
        let detailsMock = Sep30DocDetailsMock(host: recoveryHost, address: accountAddress)
        let signMock = Sep30DocSignMock(host: recoveryHost, address: accountAddress, signingAddress: signingAddress)

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        // Get account details
        let accountDetailsEnum = await service.accountDetails(
            address: accountAddress,
            jwt: jwtToken
        )
        guard case .success(let accountDetails) = accountDetailsEnum else {
            XCTFail("Failed to get account details")
            return
        }
        let sigAddress = accountDetails.signers[0].key
        XCTAssertEqual(signingAddress, sigAddress)

        // Build a transaction XDR (use a known valid envelope for the mock)
        let txBase64 = "AAAAAgAAAABswQhbaeSlgckYVKxb8pH08s5tqVVpGXYw1kCpbqv6lQAAAGQAIa4PAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACWhlbGxvLmNvbQAAAAAAAAAAAAAAAAAAAA=="

        // Request recovery server to sign
        let signEnum = await service.signTransaction(
            address: accountAddress,
            signingAddress: sigAddress,
            transaction: txBase64,
            jwt: jwtToken
        )

        switch signEnum {
        case .success(let signatureResponse):
            XCTAssertFalse(signatureResponse.signature.isEmpty)
            XCTAssertEqual("Test SDF Network ; September 2015", signatureResponse.networkPassphrase)
        case .failure(let error):
            XCTFail("Sign transaction failed: \(error)")
        }
        _ = detailsMock
        _ = signMock
    }

    // MARK: - Snippet 7: Updating Identity Information

    func testUpdateIdentities() async {
        let mock = Sep30DocUpdateMock(host: recoveryHost, address: accountAddress)

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        let newAuthMethods = [
            Sep30AuthMethod(type: "email", value: "newemail@example.com"),
            Sep30AuthMethod(type: "phone_number", value: "+14155559999"),
            Sep30AuthMethod(type: "stellar_address", value: "GNEWADDRESS..."),
        ]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: newAuthMethods)
        let request = Sep30Request(identities: [identity])

        let responseEnum = await service.updateIdentitiesForAccount(
            address: accountAddress,
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(accountAddress, response.address)
            XCTAssertFalse(response.identities.isEmpty)
        case .failure(let error):
            XCTFail("Update identities failed: \(error)")
        }
        _ = mock
    }

    // MARK: - Snippet 8: Shared Account Access

    func testSharedAccountAccess() async {
        let sharedAddress = "SHARED_ACCT"
        let mock = Sep30DocRegisterSharedMock(host: recoveryHost, address: sharedAddress)

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        let ownerAuth = [
            Sep30AuthMethod(type: "email", value: "owner@example.com"),
            Sep30AuthMethod(type: "phone_number", value: "+14155551111"),
        ]
        let ownerIdentity = Sep30RequestIdentity(role: "sender", authMethods: ownerAuth)

        let receiverAuth = [
            Sep30AuthMethod(type: "email", value: "partner@example.com"),
            Sep30AuthMethod(type: "phone_number", value: "+14155552222"),
        ]
        let receiverIdentity = Sep30RequestIdentity(role: "receiver", authMethods: receiverAuth)

        let request = Sep30Request(identities: [ownerIdentity, receiverIdentity])
        let responseEnum = await service.registerAccount(
            address: sharedAddress,
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(2, response.identities.count)
            XCTAssertEqual("sender", response.identities[0].role)
            XCTAssertEqual("receiver", response.identities[1].role)
        case .failure(let error):
            XCTFail("Shared account registration failed: \(error)")
        }
        _ = mock
    }

    // MARK: - Snippet 9: Getting Account Details

    func testAccountDetails() async {
        let mock = Sep30DocDetailsMock(host: recoveryHost, address: accountAddress)

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        let responseEnum = await service.accountDetails(
            address: accountAddress,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(accountAddress, response.address)
            XCTAssertFalse(response.identities.isEmpty)
            XCTAssertFalse(response.signers.isEmpty)

            // Verify authenticated flag
            XCTAssertTrue(response.identities[0].authenticated == true)
            XCTAssertNil(response.identities[1].authenticated)

            // Verify signers
            let latestSigner = response.signers[0].key
            XCTAssertEqual(signingAddress, latestSigner)
        case .failure(let error):
            XCTFail("Account details failed: \(error)")
        }
        _ = mock
    }

    // MARK: - Snippet 10: Listing Registered Accounts

    func testListAccounts() async {
        let mock = Sep30DocListAccountsMock(host: recoveryHost)

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        let responseEnum = await service.accounts(jwt: jwtToken)

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(3, response.accounts.count)
            XCTAssertEqual("GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD", response.accounts[0].address)
            XCTAssertEqual("GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ", response.accounts[1].address)
            XCTAssertEqual("GD62WD2XTOCAENMB34FB2SEW6JHPB7AFYQAJ5OCQ3TYRW5MOJXLKGTMM", response.accounts[2].address)

            // Verify pagination pattern
            if let lastAddress = response.accounts.last?.address {
                XCTAssertEqual("GD62WD2XTOCAENMB34FB2SEW6JHPB7AFYQAJ5OCQ3TYRW5MOJXLKGTMM", lastAddress)
            }
        case .failure(let error):
            XCTFail("List accounts failed: \(error)")
        }
        _ = mock
    }

    // MARK: - Snippet 11: Deleting Registration

    func testDeleteAccount() async {
        // Details mock is needed because we call accountDetails before delete
        let detailsMock = Sep30DocDetailsMock(host: recoveryHost, address: accountAddress)
        let deleteMock = Sep30DocDeleteMock(host: recoveryHost, address: accountAddress)

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")

        // First get details (as in the doc example)
        let detailsEnum = await service.accountDetails(
            address: accountAddress,
            jwt: jwtToken
        )
        guard case .success(let details) = detailsEnum else {
            XCTFail("Failed to get account details before deletion")
            return
        }
        let signerToRemove = details.signers[0].key
        XCTAssertEqual(signingAddress, signerToRemove)

        // Then delete
        let responseEnum = await service.deleteAccount(
            address: accountAddress,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(let response):
            XCTAssertEqual(accountAddress, response.address)
        case .failure(let error):
            XCTFail("Delete account failed: \(error)")
        }
        _ = detailsMock
        _ = deleteMock
    }

    // MARK: - Snippet 12: Error Handling

    func testErrorHandlingBadRequest() async {
        let mock = Sep30DocErrorMock(
            host: recoveryHost,
            address: "BAD_REQ_DOC",
            statusCode: 400,
            errorMessage: "bad request"
        )

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")
        let authMethods = [Sep30AuthMethod(type: "email", value: "user@example.com")]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
        let request = Sep30Request(identities: [identity])

        let responseEnum = await service.registerAccount(
            address: "BAD_REQ_DOC",
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected bad request error but got success")
        case .failure(let error):
            switch error {
            case .badRequest(let message):
                XCTAssertEqual("bad request", message)
            default:
                XCTFail("Expected badRequest but got: \(error)")
            }
        }
        _ = mock
    }

    func testErrorHandlingUnauthorized() async {
        let mock = Sep30DocErrorMock(
            host: recoveryHost,
            address: "UNAUTH_DOC",
            statusCode: 401,
            errorMessage: "unauthorized"
        )

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")
        let authMethods = [Sep30AuthMethod(type: "email", value: "user@example.com")]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
        let request = Sep30Request(identities: [identity])

        let responseEnum = await service.registerAccount(
            address: "UNAUTH_DOC",
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected unauthorized error but got success")
        case .failure(let error):
            switch error {
            case .unauthorized(let message):
                XCTAssertEqual("unauthorized", message)
            default:
                XCTFail("Expected unauthorized but got: \(error)")
            }
        }
        _ = mock
    }

    func testErrorHandlingNotFound() async {
        let mock = Sep30DocErrorMock(
            host: recoveryHost,
            address: "NOT_FOUND_DOC",
            statusCode: 404,
            errorMessage: "not found"
        )

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")
        let authMethods = [Sep30AuthMethod(type: "email", value: "user@example.com")]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
        let request = Sep30Request(identities: [identity])

        let responseEnum = await service.registerAccount(
            address: "NOT_FOUND_DOC",
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected not found error but got success")
        case .failure(let error):
            switch error {
            case .notFound(let message):
                XCTAssertEqual("not found", message)
            default:
                XCTFail("Expected notFound but got: \(error)")
            }
        }
        _ = mock
    }

    func testErrorHandlingConflict() async {
        let mock = Sep30DocErrorMock(
            host: recoveryHost,
            address: "CONFLICT_DOC",
            statusCode: 409,
            errorMessage: "account already exists"
        )

        let service = RecoveryService(serviceAddress: "http://\(recoveryHost)")
        let authMethods = [Sep30AuthMethod(type: "email", value: "user@example.com")]
        let identity = Sep30RequestIdentity(role: "owner", authMethods: authMethods)
        let request = Sep30Request(identities: [identity])

        let responseEnum = await service.registerAccount(
            address: "CONFLICT_DOC",
            request: request,
            jwt: jwtToken
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected conflict error but got success")
        case .failure(let error):
            switch error {
            case .conflict(let message):
                XCTAssertEqual("account already exists", message)
            default:
                XCTFail("Expected conflict but got: \(error)")
            }
        }
        _ = mock
    }

    // MARK: - Snippet 13: Phone Number Format (auth method construction)

    func testPhoneNumberFormat() {
        // Snippet 13: Verify auth method construction
        let phoneAuth = Sep30AuthMethod(type: "phone_number", value: "+14155551234")
        XCTAssertEqual("phone_number", phoneAuth.type)
        XCTAssertEqual("+14155551234", phoneAuth.value)

        // Verify JSON output
        let json = phoneAuth.toJson()
        XCTAssertEqual("phone_number", json["type"] as? String)
        XCTAssertEqual("+14155551234", json["value"] as? String)
    }

    // MARK: - Snippet 14: Request model construction (Sep30Request.toJson)

    func testRequestModelConstruction() {
        // Verify the full request model chain: AuthMethod -> Identity -> Request
        let emailAuth = Sep30AuthMethod(type: "email", value: "user@example.com")
        let phoneAuth = Sep30AuthMethod(type: "phone_number", value: "+14155551234")
        let stellarAuth = Sep30AuthMethod(type: "stellar_address", value: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP")

        let ownerIdentity = Sep30RequestIdentity(role: "owner", authMethods: [emailAuth, phoneAuth, stellarAuth])
        let request = Sep30Request(identities: [ownerIdentity])

        let json = request.toJson()
        let identitiesJson = json["identities"] as! [[String: Any]]
        XCTAssertEqual(1, identitiesJson.count)

        let identityJson = identitiesJson[0]
        XCTAssertEqual("owner", identityJson["role"] as? String)

        let authMethodsJson = identityJson["auth_methods"] as! [[String: Any]]
        XCTAssertEqual(3, authMethodsJson.count)
        XCTAssertEqual("email", authMethodsJson[0]["type"] as? String)
        XCTAssertEqual("phone_number", authMethodsJson[1]["type"] as? String)
        XCTAssertEqual("stellar_address", authMethodsJson[2]["type"] as? String)
    }
}
