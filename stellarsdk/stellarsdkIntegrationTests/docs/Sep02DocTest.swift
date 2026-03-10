//
//  Sep02DocTest.swift
//  stellarsdkTests
//
//  Created for documentation validation.
//

import XCTest
import stellarsdk

/// Tests for SEP-02 Federation documentation code examples.
/// Uses ServerMock/RequestMock/ResponsesMock infrastructure to mock HTTP responses.
final class Sep02DocTest: XCTestCase {

    let federationHost = "127.0.0.1"
    let mockDomain = "mockdomain.test"
    var federationMock: Sep02FederationResponseMock!
    var tomlMock: Sep02TomlMock!

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
        federationMock = Sep02FederationResponseMock(host: federationHost)
        tomlMock = Sep02TomlMock(
            domain: mockDomain,
            federationServer: "https://\(federationHost)/federation"
        )
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Quick example (Snippet 1)

    func testQuickExample() async {
        let result = await Federation.resolve(stellarAddress: "bob*\(mockDomain)")

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.accountId)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            print("Account: \(response.accountId ?? "nil")")
            print("Memo: \(response.memo ?? "none")")
        case .failure(let error):
            XCTFail("Resolution failed: \(error)")
        }
    }

    // MARK: - Resolving Stellar addresses (Snippet 2)

    func testResolveStellarAddress() async {
        let result = await Federation.resolve(stellarAddress: "bob*\(mockDomain)")

        switch result {
        case .success(let response):
            // The destination account for payments
            let accountId = response.accountId
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", accountId)

            // Include memo if provided (required for some destinations)
            let memo = response.memo
            let memoType = response.memoType
            XCTAssertEqual("text", memoType)
            XCTAssertEqual("hello memo text", memo)

            if let memo = memo {
                print("Memo (\(memoType ?? "unknown")): \(memo)")
            }

            // Original address for confirmation
            let address = response.stellarAddress
            XCTAssertEqual("bob*\(mockDomain)", address)
        case .failure(let error):
            XCTFail("Resolution failed: \(error)")
        }
    }

    // MARK: - Reverse lookup (Snippet 3)

    func testReverseLookup() async {
        let accountId = "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI"

        let federation = Federation(federationAddress: "https://\(federationHost)/federation")
        let result = await federation.resolve(account_id: accountId)

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.stellarAddress)
            XCTAssertEqual("bob*\(mockDomain)", response.stellarAddress)
            print("Address: \(response.stellarAddress ?? "unknown")")
        case .failure(let error):
            XCTFail("Reverse lookup failed: \(error)")
        }
    }

    // MARK: - Transaction lookup (Snippet 4)

    func testTransactionLookup() async {
        let txId = "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a"

        let federation = Federation(federationAddress: "https://\(federationHost)/federation")
        let result = await federation.resolve(transaction_id: txId)

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.stellarAddress)
            if let sender = response.stellarAddress {
                print("Sender: \(sender)")
            }
        case .failure(let error):
            XCTFail("Transaction lookup failed: \(error)")
        }
    }

    // MARK: - Forward federation (Snippet 5)

    func testForwardFederation() async {
        var params = Dictionary<String, String>()
        params["forward_type"] = "bank_account"
        params["swift"] = "BOPBPHMM"
        params["acct"] = "2382376"

        let federation = Federation(federationAddress: "https://\(federationHost)/federation")
        let result = await federation.resolve(forwardParams: params)

        switch result {
        case .success(let response):
            XCTAssertNotNil(response.accountId)
            print("Deposit to: \(response.accountId ?? "nil")")

            if let memo = response.memo {
                print("Memo (\(response.memoType ?? "unknown")): \(memo)")
            }
        case .failure(let error):
            XCTFail("Forward federation failed: \(error)")
        }
    }

    // MARK: - Error handling (Snippet 7)

    func testErrorHandlingInvalidAddress() async {
        // Invalid address format (missing *)
        let invalidResult = await Federation.resolve(stellarAddress: "invalid-no-asterisk")
        switch invalidResult {
        case .success(_):
            XCTFail("Expected failure for invalid address format")
        case .failure(let error):
            if case .invalidAddress = error {
                // Expected
            } else {
                XCTFail("Expected .invalidAddress error but got \(error)")
            }
        }
    }

    func testErrorHandlingMultipleAsterisks() async {
        let result = await Federation.resolve(stellarAddress: "bob*server*example.com")
        switch result {
        case .success(_):
            XCTFail("Expected failure for address with multiple asterisks")
        case .failure(let error):
            if case .invalidAddress = error {
                // Expected
            } else {
                XCTFail("Expected .invalidAddress error but got \(error)")
            }
        }
    }

    // MARK: - Finding the federation server (Snippet 8)

    func testFindingFederationServer() async {
        let domainResult = await Federation.forDomain(domain: mockDomain)
        switch domainResult {
        case .success(let federation):
            XCTAssertEqual("https://\(federationHost)/federation", federation.federationAddress)
            print("Federation Server: \(federation.federationAddress)")
        case .failure(let error):
            XCTFail("Failed to discover federation server: \(error)")
        }
    }

    // MARK: - Memo types

    func testMemoTypeId() async {
        let memoIdMock = Sep02MemoIdResponseMock(host: "memoid.test")
        _ = memoIdMock

        let federation = Federation(federationAddress: "https://memoid.test/federation")
        let result = await federation.resolve(address: "alice*memoid.test")

        switch result {
        case .success(let response):
            XCTAssertEqual("id", response.memoType)
            XCTAssertEqual("12345678", response.memo)
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)

            // Verify id memo can be parsed
            if let memoValue = response.memo, let memoId = UInt64(memoValue) {
                XCTAssertEqual(UInt64(12345678), memoId)
            } else {
                XCTFail("Could not parse memo as UInt64")
            }
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func testMemoTypeHash() async {
        let memoHashMock = Sep02MemoHashResponseMock(host: "memohash.test")
        _ = memoHashMock

        let federation = Federation(federationAddress: "https://memohash.test/federation")
        let result = await federation.resolve(address: "alice*memohash.test")

        switch result {
        case .success(let response):
            XCTAssertEqual("hash", response.memoType)
            XCTAssertNotNil(response.memo)

            // Verify base64 decoding works as described in docs
            if let memoValue = response.memo, let memoData = Data(base64Encoded: memoValue) {
                XCTAssertEqual(32, memoData.count)
            } else {
                XCTFail("Could not base64-decode hash memo")
            }
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    // MARK: - ResolveAddressResponse properties

    func testMinimalResponse() async {
        let minimalMock = Sep02MinimalResponseMock(host: "minimal.test")
        _ = minimalMock

        let federation = Federation(federationAddress: "https://minimal.test/federation")
        let result = await federation.resolve(address: "alice*minimal.test")

        switch result {
        case .success(let response):
            XCTAssertEqual("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", response.accountId)
            XCTAssertNil(response.stellarAddress)
            XCTAssertNil(response.memoType)
            XCTAssertNil(response.memo)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
}

// MARK: - Mock Classes

/// Mock for federation server responses.
class Sep02FederationResponseMock: ResponsesMock {
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
                    if let q = mock.variables["q"],
                       q == "c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a" {
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
                    if let q = mock.variables["q"],
                       q == "GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI" {
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
class Sep02TomlMock: ResponsesMock {
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

/// Mock for federation response with memo_type: id.
class Sep02MemoIdResponseMock: ResponsesMock {
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
class Sep02MemoHashResponseMock: ResponsesMock {
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
class Sep02MinimalResponseMock: ResponsesMock {
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
