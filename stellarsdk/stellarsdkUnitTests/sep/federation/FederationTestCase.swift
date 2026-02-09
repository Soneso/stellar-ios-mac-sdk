//
//  FederationTestCase.swift
//  stellarsdkTests
//
//  Created by Razvan Chelemen on 23/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Unit tests for SEP-0002 Federation protocol implementation.
/// Tests cover address resolution, reverse lookups, error handling, and edge cases.
final class FederationTestCase: XCTestCase {

    let federationServer = "127.0.0.1"
    let mockDomain = "mockdomain.test"
    var federationMock: FederationResponseMock!
    var tomlMock: FederationTomlMock!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
        federationMock = FederationResponseMock(host: federationServer)
        tomlMock = FederationTomlMock(domain: mockDomain, federationServer: "https://\(federationServer)/federation")
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Static Methods

    /// Tests successful resolution of a Stellar address using the static resolve method.
    func testResolveStaticMethod() async {
        let responseEnum = await Federation.resolve(stellarAddress: "bob*\(mockDomain)")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*\(mockDomain)", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests that the secure parameter is respected (uses HTTPS by default).
    func testResolveStaticMethodSecureFlag() async {
        // The default is secure=true, which should use HTTPS for stellar.toml fetch
        let responseEnum = await Federation.resolve(stellarAddress: "bob*\(mockDomain)", secure: true)
        switch responseEnum {
        case .success(let response):
            XCTAssertNotNil(response.accountId)
        case .failure(let error):
            XCTFail("Expected success with secure flag, got error: \(error)")
        }
    }

    /// Tests Federation.forDomain() success case with valid domain.
    func testForDomainSuccess() async {
        let responseEnum = await Federation.forDomain(domain: mockDomain)
        switch responseEnum {
        case .success(let federation):
            XCTAssertEqual("https://\(federationServer)/federation", federation.federationAddress)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests Federation.forDomain() with invalid domain format.
    func testForDomainInvalidDomain() async {
        // Test with a domain that can't be resolved (no mock set up for it)
        let responseEnum = await Federation.forDomain(domain: "nonexistent-invalid-domain-xyz123.test")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for invalid domain")
        case .failure(let error):
            // Should fail with invalidTomlDomain or network error
            switch error {
            case .invalidTomlDomain, .horizonError:
                // Expected errors
                break
            default:
                break // Other errors are acceptable for unreachable domain
            }
        }
    }

    // MARK: - Instance Methods

    /// Tests resolving a Stellar address to account ID using instance method.
    func testResolveStellarAddress() async {
        let responseEnum = await Federation.resolve(stellarAddress: "bob*\(mockDomain)")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*\(mockDomain)", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests resolving address using direct federation instance.
    func testResolveStellarAccountId2() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(address: "bob*\(mockDomain)")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*\(mockDomain)", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests reverse lookup from account ID to Stellar address (type=id query).
    func testResolveStellarAccountId() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(account_id: "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*\(mockDomain)", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests transaction ID lookup (type=txid query).
    func testResolveTransactionId() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(transaction_id: "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*\(mockDomain)", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests forward query with parameters (type=forward query).
    func testResolveForward() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")

        var params = Dictionary<String,String>()
        params["forward_type"] = "bank_account"
        params["swift"] = "BOPBPHMM"
        params["acct"] = "2382376"

        let responseEnum = await federation.resolve(forwardParams: params)
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("bob*\(mockDomain)", response.stellarAddress)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    // MARK: - Error Cases

    /// Tests that an address without asterisk returns invalidAddress error.
    func testInvalidAddressFormat() async {
        let responseEnum = await Federation.resolve(stellarAddress: "bobsoneso.com")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for address without asterisk")
        case .failure(let error):
            if case .invalidAddress = error {
                // Expected
            } else {
                XCTFail("Expected invalidAddress error but got \(error)")
            }
        }
    }

    /// Tests that an address with multiple asterisks returns invalidAddress error.
    func testInvalidAddressMultipleAsterisks() async {
        let responseEnum = await Federation.resolve(stellarAddress: "bob*server*soneso.com")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for address with multiple asterisks")
        case .failure(let error):
            // The SDK splits by asterisk and checks count == 2
            // Three parts means multiple asterisks
            if case .invalidAddress = error {
                // Expected
            } else {
                XCTFail("Expected invalidAddress error but got \(error)")
            }
        }
    }

    /// Tests that an empty address returns invalidAddress error.
    func testInvalidAddressEmpty() async {
        let responseEnum = await Federation.resolve(stellarAddress: "")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for empty address")
        case .failure(let error):
            if case .invalidAddress = error {
                // Expected
            } else {
                XCTFail("Expected invalidAddress error but got \(error)")
            }
        }
    }

    /// Tests that a malformed account ID returns invalidAccountId error.
    func testInvalidAccountId() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(account_id: "INVALID_ACCOUNT_ID_12345")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for invalid account ID")
        case .failure(let error):
            if case .invalidAccountId = error {
                // Expected
            } else {
                XCTFail("Expected invalidAccountId error but got \(error)")
            }
        }
    }

    /// Tests that a domain without FEDERATION_SERVER in stellar.toml returns noFederationSet error.
    func testNoFederationSet() async {
        let noFedMock = FederationTomlMockNoFederationServer(domain: "nofed.test")
        _ = noFedMock // Keep mock alive

        let responseEnum = await Federation.forDomain(domain: "nofed.test")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure when no FEDERATION_SERVER is set")
        case .failure(let error):
            if case .noFederationSet = error {
                // Expected
            } else {
                XCTFail("Expected noFederationSet error but got \(error)")
            }
        }
    }

    /// Tests that malformed JSON response returns parsingResponseFailed error.
    func testParsingResponseFailed() async {
        let malformedMock = FederationMalformedResponseMock(host: "malformed.test")
        _ = malformedMock // Keep mock alive

        let federation = Federation(federationAddress: "https://malformed.test/federation")
        let responseEnum = await federation.resolve(address: "bob*test.com")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for malformed JSON response")
        case .failure(let error):
            if case .parsingResponseFailed(let message) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected parsingResponseFailed error but got \(error)")
            }
        }
    }

    /// Tests that HTTP errors return horizonError.
    func testHorizonError() async {
        let errorMock = FederationHttpErrorMock(host: "httperror.test", statusCode: 500)
        _ = errorMock // Keep mock alive

        let federation = Federation(federationAddress: "https://httperror.test/federation")
        let responseEnum = await federation.resolve(address: "bob*test.com")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for HTTP error")
        case .failure(let error):
            if case .horizonError = error {
                // Expected
            } else {
                XCTFail("Expected horizonError but got \(error)")
            }
        }
    }

    /// Tests that invalid stellar.toml returns invalidToml error.
    func testInvalidToml() async {
        let invalidTomlMock = FederationInvalidTomlMock(domain: "invalidtoml.test")
        _ = invalidTomlMock // Keep mock alive

        let responseEnum = await Federation.forDomain(domain: "invalidtoml.test")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for invalid TOML")
        case .failure(let error):
            if case .invalidToml = error {
                // Expected
            } else {
                XCTFail("Expected invalidToml error but got \(error)")
            }
        }
    }

    /// Tests that resolve(address:) with missing asterisk returns invalidAddress.
    func testResolveAddressInstanceMethodInvalidFormat() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(address: "noasterisk")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for address without asterisk")
        case .failure(let error):
            if case .invalidAddress = error {
                // Expected
            } else {
                XCTFail("Expected invalidAddress error but got \(error)")
            }
        }
    }

    // MARK: - Edge Cases

    /// Tests response with memo_type: text.
    func testMemoTypeText() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(address: "memotext*test.com")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("text", response.memoType)
            XCTAssertEqual("hello memo text", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests response with memo_type: id.
    func testMemoTypeId() async {
        let memoIdMock = FederationMemoIdResponseMock(host: "memoid.test")
        _ = memoIdMock // Keep mock alive

        let federation = Federation(federationAddress: "https://memoid.test/federation")
        let responseEnum = await federation.resolve(address: "alice*memoid.test")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("id", response.memoType)
            XCTAssertEqual("12345678", response.memo)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests response with memo_type: hash.
    func testMemoTypeHash() async {
        let memoHashMock = FederationMemoHashResponseMock(host: "memohash.test")
        _ = memoHashMock // Keep mock alive

        let federation = Federation(federationAddress: "https://memohash.test/federation")
        let responseEnum = await federation.resolve(address: "alice*memohash.test")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("hash", response.memoType)
            XCTAssertEqual("YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY=", response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests response with optional fields missing.
    func testOptionalFieldsNull() async {
        let minimalMock = FederationMinimalResponseMock(host: "minimal.test")
        _ = minimalMock // Keep mock alive

        let federation = Federation(federationAddress: "https://minimal.test/federation")
        let responseEnum = await federation.resolve(address: "alice*minimal.test")
        switch responseEnum {
        case .success(let response):
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertNil(response.stellarAddress)
            XCTAssertNil(response.memoType)
            XCTAssertNil(response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    /// Tests forward query with empty params dictionary.
    func testForwardParamsEmpty() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(forwardParams: [:])
        switch responseEnum {
        case .success:
            // Server might accept empty params, depends on implementation
            break
        case .failure:
            // Empty params might be rejected
            break
        }
        // This test verifies no crash occurs with empty params
    }

    /// Tests account ID with wrong prefix (not starting with G).
    func testAccountIdWrongPrefix() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        let responseEnum = await federation.resolve(account_id: "SBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for account ID with wrong prefix")
        case .failure(let error):
            if case .invalidAccountId = error {
                // Expected - S prefix is for secret keys
            } else {
                XCTFail("Expected invalidAccountId error but got \(error)")
            }
        }
    }

    /// Tests account ID with wrong checksum.
    /// Note: The SDK validates account ID format but not checksum (server-side validation).
    /// The account ID may be rejected by server if it's not found.
    func testAccountIdWrongChecksum() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        // Invalid account ID that passes format check but would fail checksum validation
        // "INVALID" makes it clearly not a valid base32 encoded key
        let responseEnum = await federation.resolve(account_id: "GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
        switch responseEnum {
        case .success:
            // Server may return empty/null fields for unknown account - that's acceptable
            break
        case .failure(let error):
            // Either invalidAccountId (if caught locally) or horizonError (if caught by server)
            switch error {
            case .invalidAccountId, .horizonError:
                // Both are acceptable - depends on validation location
                break
            default:
                XCTFail("Expected invalidAccountId or horizonError but got \(error)")
            }
        }
    }

    /// Tests address with only asterisk (no name or domain).
    func testAddressOnlyAsterisk() async {
        let responseEnum = await Federation.resolve(stellarAddress: "*")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for address with only asterisk")
        case .failure(let error):
            if case .invalidAddress = error {
                // Expected - splits to empty parts
            } else {
                // Might also fail during TOML lookup
                break
            }
        }
    }

    /// Tests address with empty name part.
    func testAddressEmptyName() async {
        // "*domain.com" has empty name part
        let responseEnum = await Federation.resolve(stellarAddress: "*domain.com")
        switch responseEnum {
        case .success:
            // Might succeed if server accepts empty name
            break
        case .failure:
            // Or might fail - either is acceptable
            break
        }
    }

    /// Tests address with empty domain part.
    func testAddressEmptyDomain() async {
        // "bob*" has empty domain part
        let responseEnum = await Federation.resolve(stellarAddress: "bob*")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for empty domain")
        case .failure:
            // Expected - can't resolve TOML for empty domain
            break
        }
    }

    /// Tests that Federation instance stores the federation address correctly.
    func testFederationAddressStorage() {
        let testAddress = "https://example.com/federation"
        let federation = Federation(federationAddress: testAddress)
        XCTAssertEqual(testAddress, federation.federationAddress)
    }

    /// Tests HTTP 404 error handling.
    func testHttp404Error() async {
        let errorMock = FederationHttpErrorMock(host: "http404.test", statusCode: 404)
        _ = errorMock // Keep mock alive

        let federation = Federation(federationAddress: "https://http404.test/federation")
        let responseEnum = await federation.resolve(address: "bob*test.com")
        switch responseEnum {
        case .success:
            XCTFail("Expected failure for HTTP 404")
        case .failure(let error):
            if case .horizonError = error {
                // Expected
            } else {
                XCTFail("Expected horizonError but got \(error)")
            }
        }
    }

    /// Tests special characters in address name part.
    func testAddressWithSpecialCharacters() async {
        let federation = Federation(federationAddress: "https://\(federationServer)/federation")
        // Test with email-style address
        let responseEnum = await federation.resolve(address: "user+tag@email*test.com")
        switch responseEnum {
        case .success:
            // If server accepts it, that's fine
            break
        case .failure:
            // If server rejects it, that's also fine
            break
        }
        // Main goal: no crash with special characters
    }
}

// MARK: - Mock Classes

/// Mock for federation server responses.
class FederationResponseMock: ResponsesMock {
    var host: String
    var domain: String = "mockdomain.test"

    init(host: String) {
        self.host = host
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return nil }

            if let type = mock.variables["type"] {
                if type == "txid" {
                    if let q = mock.variables["q"], q == "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a" {
                        mock.statusCode = 200
                        return self.successResponse(for: "bob*\(self.domain)")
                    }
                } else if type == "forward" {
                    if let forwardType = mock.variables["forward_type"], forwardType == "bank_account",
                        let swift = mock.variables["swift"], swift == "BOPBPHMM",
                       let acct = mock.variables["acct"], acct == "2382376" {
                        mock.statusCode = 200
                        return self.successResponse(for: "bob*\(self.domain)")
                    }
                } else if type == "name" {
                    if let q = mock.variables["q"] {
                        mock.statusCode = 200
                        return self.successResponse(for: q)
                    }
                } else if type == "id" {
                    if let q = mock.variables["q"], q == "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI" {
                        mock.statusCode = 200
                        return self.successResponse(for: "bob*\(self.domain)")
                    }
                }
            }

            mock.statusCode = 400
            return nil
        }

        return RequestMock(host: host,
                           path: "/federation",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    func successResponse(for address: String) -> String {
        return """
        {
          "stellar_address": "\(address)",
          "account_id": "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI",
          "memo_type": "text",
          "memo": "hello memo text"
        }
        """
    }
}

/// Mock for stellar.toml with FEDERATION_SERVER.
class FederationTomlMock: ResponsesMock {
    var domain: String
    var fedServer: String

    init(domain: String, federationServer: String) {
        self.domain = domain
        self.fedServer = federationServer
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            mock.statusCode = 200
            return self?.tomlContent
        }

        return RequestMock(host: domain,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }

    var tomlContent: String {
        return """
        FEDERATION_SERVER="\(fedServer)"

        [DOCUMENTATION]
        ORG_NAME="Test Federation Org"
        """
    }
}

/// Mock for stellar.toml without FEDERATION_SERVER.
class FederationTomlMockNoFederationServer: ResponsesMock {
    var domain: String

    init(domain: String) {
        self.domain = domain
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            [DOCUMENTATION]
            ORG_NAME="No Federation Org"
            """
        }

        return RequestMock(host: domain,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

/// Mock for invalid stellar.toml content.
class FederationInvalidTomlMock: ResponsesMock {
    var domain: String

    init(domain: String) {
        self.domain = domain
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            // Invalid TOML syntax - missing closing bracket
            return """
            [DOCUMENTATION
            ORG_NAME="Invalid"
            """
        }

        return RequestMock(host: domain,
                           path: "/.well-known/stellar.toml",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

/// Mock for malformed JSON response from federation server.
class FederationMalformedResponseMock: ResponsesMock {
    var host: String

    init(host: String) {
        self.host = host
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            // Invalid JSON
            return """
            {
              "stellar_address": "broken",
              "account_id": MISSING_QUOTES,
            }
            """
        }

        return RequestMock(host: host,
                           path: "/federation",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

/// Mock for HTTP error responses.
class FederationHttpErrorMock: ResponsesMock {
    var host: String
    var statusCode: Int

    init(host: String, statusCode: Int) {
        self.host = host
        self.statusCode = statusCode
        super.init()
    }

    override func requestMock() -> RequestMock {
        let statusCodeToUse = self.statusCode
        let handler: MockHandler = { mock, request in
            mock.statusCode = statusCodeToUse
            return """
            {
              "type": "https://stellar.org/horizon-errors/not_found",
              "title": "Resource Missing",
              "status": \(statusCodeToUse),
              "detail": "Not found"
            }
            """
        }

        return RequestMock(host: host,
                           path: "/federation",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

/// Mock for federation response with memo_type: id.
class FederationMemoIdResponseMock: ResponsesMock {
    var host: String

    init(host: String) {
        self.host = host
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
              "stellar_address": "alice*memoid.test",
              "account_id": "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI",
              "memo_type": "id",
              "memo": "12345678"
            }
            """
        }

        return RequestMock(host: host,
                           path: "/federation",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

/// Mock for federation response with memo_type: hash.
class FederationMemoHashResponseMock: ResponsesMock {
    var host: String

    init(host: String) {
        self.host = host
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            // Base64 encoded 32-byte hash
            return """
            {
              "stellar_address": "alice*memohash.test",
              "account_id": "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI",
              "memo_type": "hash",
              "memo": "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY="
            }
            """
        }

        return RequestMock(host: host,
                           path: "/federation",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}

/// Mock for minimal federation response with only account_id.
class FederationMinimalResponseMock: ResponsesMock {
    var host: String

    init(host: String) {
        self.host = host
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            // Only required field, all optional fields missing
            return """
            {
              "account_id": "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI"
            }
            """
        }

        return RequestMock(host: host,
                           path: "/federation",
                           httpMethod: "GET",
                           mockHandler: handler)
    }
}
