//
//  OZIndexerClientTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZIndexerClientTests: XCTestCase {

    // Valid Stellar test addresses (56 characters with valid checksum).
    private let testAccountId = "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D"
    private let testContractId = "CA2LVQXQLGPWHV2QO5ENVAGWM2TYICRMWXW4UXBPVKV26WLKU2V3UTH5"

    /// Reusable JSON snippet describing one indexed contract summary.
    private let contractSummaryJson = """
    {
        "contract_id": "CA2LVQXQLGPWHV2QO5ENVAGWM2TYICRMWXW4UXBPVKV26WLKU2V3UTH5",
        "context_rule_count": 2,
        "external_signer_count": 1,
        "delegated_signer_count": 1,
        "native_signer_count": 0,
        "first_seen_ledger": 100000,
        "last_seen_ledger": 200000,
        "context_rule_ids": [0, 1]
    }
    """

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Helpers

    /// Returns a `URLSession` configured to intercept every request via
    /// `MockURLProtocol`. No real network sockets are opened.
    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Installs a static handler that returns the supplied JSON body with the given
    /// HTTP status code and content type for every intercepted request.
    private func installResponder(
        body: String,
        statusCode: Int = 200,
        contentType: String = "application/json"
    ) {
        MockURLProtocol.requestHandler = { request in
            let url = request.url ?? URL(string: "https://placeholder")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": contentType]
            )!
            return .success((response, body.data(using: .utf8)))
        }
    }

    /// Installs a handler that records the captured URL and then returns the supplied
    /// JSON body with the given HTTP status code.
    private func installCapturingResponder(
        body: String,
        statusCode: Int = 200,
        urlCapture: @escaping (String) -> Void
    ) {
        MockURLProtocol.requestHandler = { request in
            urlCapture(request.url?.absoluteString ?? "")
            let url = request.url ?? URL(string: "https://placeholder")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return .success((response, body.data(using: .utf8)))
        }
    }

    /// Installs a handler that surfaces the supplied error to the URL loading stack.
    private func installThrowingResponder(error: Error) {
        MockURLProtocol.requestHandler = { _ in
            return .failure(error)
        }
    }

    // MARK: - Constructor validation

    func testConstructor_blankUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZIndexerClient(indexerUrl: "")) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_whitespaceUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZIndexerClient(indexerUrl: "   ")) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_httpUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZIndexerClient(indexerUrl: "http://indexer.example.com")) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_httpsUrlSucceeds() throws {
        let client = try OZIndexerClient(indexerUrl: "https://indexer.example.com")
        client.close()
    }

    func testConstructor_localhostHttpUrlSucceeds() throws {
        let client = try OZIndexerClient(indexerUrl: "http://localhost:8080")
        client.close()
    }

    func testConstructor_ftpSchemeThrows() {
        XCTAssertThrowsError(try OZIndexerClient(indexerUrl: "ftp://indexer.example.com")) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_noSchemeThrows() {
        XCTAssertThrowsError(try OZIndexerClient(indexerUrl: "indexer.example.com")) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_leadingWhitespaceUrl_succeedsAfterTrim() throws {
        let client = try OZIndexerClient(indexerUrl: "  https://indexer.example.com")
        client.close()
    }

    func testConstructor_trailingNewlineUrl_succeedsAfterTrim() throws {
        let client = try OZIndexerClient(indexerUrl: "https://indexer.example.com\n")
        client.close()
    }

    func testConstructor_schemeOnlyUrl_throwsConfigurationException() {
        XCTAssertThrowsError(try OZIndexerClient(indexerUrl: "https://")) { error in
            XCTAssertTrue(error is SmartAccountConfigurationException.InvalidConfig)
        }
    }

    func testConstructor_trailingSlashNormalization_resolvesCanonicalRequestUrl() async throws {
        // why: a base URL supplied with trailing slashes must be normalised
        // so the outbound request URL is the canonical form (no doubled
        // slashes). Captures the actual request URL via `requestInspector`
        // and asserts the canonical health endpoint was used.
        var capturedUrl: String?
        MockURLProtocol.requestInspector = { request in
            capturedUrl = request.url?.absoluteString
        }
        installResponder(body: #"{"status":"ok"}"#)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com///",
            urlSession: session
        )
        defer { indexer.close() }

        _ = await indexer.isHealthy()
        XCTAssertEqual(
            "https://indexer.example.com/",
            capturedUrl,
            "Trailing slashes must be normalised away in the outbound request URL"
        )
    }

    func testConstructor_ownsSession_disallowsHttpRedirects() throws {
        // why: when the client owns its `URLSession` it must attach an
        // `OZNoRedirectDelegate` so a 3xx response from the configured host
        // cannot redirect outbound requests to a third-party URL. This would
        // otherwise bypass the HTTPS-only constructor check and leak the pinned
        // `X-Client-*` identification headers.
        let client = try OZIndexerClient(indexerUrl: "https://indexer.example.com")
        defer { client.close() }

        XCTAssertNotNil(
            client.noRedirectDelegateForTesting,
            "Client that owns its URLSession must attach a no-redirect delegate"
        )
    }

    func testConstructor_injectedSession_doesNotOwnRedirectDelegate() throws {
        // why: when the caller injects a `URLSession`, the redirect-handling
        // policy belongs to the caller — the client does not attach its own
        // delegate. Verified by asserting the test-only accessor is `nil`.
        let injected = URLSession(configuration: .ephemeral)
        let client = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: injected
        )
        defer { client.close() }

        XCTAssertNil(
            client.noRedirectDelegateForTesting,
            "Client with injected URLSession must not attach its own redirect delegate"
        )
    }

    // MARK: - DEFAULT_INDEXER_URLS

    func testDefaultIndexerUrls_testnetHasUrl() {
        let url = OZIndexerClient.defaultIndexerUrls[Network.testnet.passphrase]
        XCTAssertNotNil(url, "Testnet should have a default indexer URL configured")
        XCTAssertTrue(url!.hasPrefix("https://"), "Default indexer URL must use HTTPS")
    }

    func testDefaultIndexerUrls_unknownNetworkReturnsNull() {
        let url = OZIndexerClient.defaultIndexerUrls["Custom Network ; 2026"]
        XCTAssertNil(url, "Unknown network must not have a default indexer URL")
    }

    // MARK: - getDefaultUrl

    func testGetDefaultUrl_testnetReturnsUrl() {
        let url = OZIndexerClient.getDefaultUrl(networkPassphrase: Network.testnet.passphrase)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.hasPrefix("https://"))
    }

    func testGetDefaultUrl_unknownNetworkReturnsNull() {
        let url = OZIndexerClient.getDefaultUrl(networkPassphrase: "Unknown Network ; January 2099")
        XCTAssertNil(url)
    }

    func testGetDefaultUrl_mainnetReturnsNullOrUrl() {
        let url = OZIndexerClient.getDefaultUrl(networkPassphrase: Network.public.passphrase)
        if let url = url {
            XCTAssertTrue(url.hasPrefix("https://"), "If mainnet URL is set, it must use HTTPS")
        }
    }

    // MARK: - forNetwork

    func testForNetwork_testnetReturnsClient() {
        let client = OZIndexerClient.forNetwork(networkPassphrase: Network.testnet.passphrase)
        XCTAssertNotNil(client, "forNetwork must return a client for testnet")
        client?.close()
    }

    func testForNetwork_unknownNetworkReturnsNull() {
        let client = OZIndexerClient.forNetwork(networkPassphrase: "Unknown Network ; 2099")
        XCTAssertNil(client, "forNetwork must return null for unknown networks")
    }

    func testForNetwork_mainnetReturnsNullCurrently() {
        let url = OZIndexerClient.getDefaultUrl(networkPassphrase: Network.public.passphrase)
        let client = OZIndexerClient.forNetwork(networkPassphrase: Network.public.passphrase)
        if url == nil {
            XCTAssertNil(client, "forNetwork must return null when no default URL exists")
        } else {
            XCTAssertNotNil(client)
            client?.close()
        }
    }

    // MARK: - lookupByCredentialId

    func testLookupByCredentialId_success() async throws {
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [\(contractSummaryJson)],
            "count": 1
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
        XCTAssertEqual("aabbccdd", result.credentialId)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(1, result.contracts.count)
        XCTAssertEqual(testContractId, result.contracts[0].contractId)
        XCTAssertEqual(2, result.contracts[0].contextRuleCount)
    }

    func testLookupByCredentialId_verifiesUrlPath() async throws {
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [],
            "count": 0
        }
        """
        var capturedUrl: String?
        installCapturingResponder(body: responseJson) { capturedUrl = $0 }
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
        XCTAssertNotNil(capturedUrl)
        XCTAssertTrue(
            capturedUrl!.contains("/api/lookup/"),
            "Request URL must contain /api/lookup/ path"
        )
        XCTAssertTrue(
            capturedUrl!.hasSuffix("aabbccdd"),
            "Request URL must end with hex-encoded credential ID"
        )
    }

    func testLookupByCredentialId_invalidBase64url_throwsValidationException() async throws {
        installResponder(body: "{}")
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "!!!invalid-base64url!!!")
            XCTFail("Expected SmartAccountValidationException.InvalidInput")
        } catch is SmartAccountValidationException.InvalidInput {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLookupByCredentialId_http404_throwsIndexerException() async throws {
        installResponder(body: #"{"error": "not found"}"#, statusCode: 404)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(error.message.contains("404"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLookupByCredentialId_http500_throwsIndexerException() async throws {
        installResponder(body: #"{"error": "internal server error"}"#, statusCode: 500)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(error.message.contains("500"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLookupByCredentialId_nonJsonResponse_throwsIndexerException() async throws {
        installResponder(body: "<html>Not JSON</html>", contentType: "text/html")
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch is SmartAccountIndexerException.RequestFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLookupByCredentialId_nonJsonContentTypeWithJsonBody_throwsContentTypeError() async throws {
        // why: even when the body happens to be valid JSON, a non-JSON
        // `Content-Type` (here `text/html`) indicates a proxy / gateway
        // error page. The guard must short-circuit so the surfaced error
        // names the transport failure rather than the (otherwise parseable)
        // body.
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [],
            "count": 0
        }
        """
        installResponder(body: responseJson, contentType: "text/html")
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(
                error.message.contains("Unexpected Content-Type"),
                "Surfaced error must name the unexpected Content-Type header"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - lookupByAddress

    func testLookupByAddress_successWithGAddress() async throws {
        let responseJson = """
        {
            "signerAddress": "\(testAccountId)",
            "contracts": [\(contractSummaryJson)],
            "count": 1
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.lookupByAddress(address: testAccountId)
        XCTAssertEqual(testAccountId, result.signerAddress)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(1, result.contracts.count)
    }

    func testLookupByAddress_successWithCAddress() async throws {
        let responseJson = """
        {
            "signerAddress": "\(testContractId)",
            "contracts": [\(contractSummaryJson)],
            "count": 1
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.lookupByAddress(address: testContractId)
        XCTAssertEqual(testContractId, result.signerAddress)
        XCTAssertEqual(1, result.count)
    }

    func testLookupByAddress_verifiesUrlPath() async throws {
        let responseJson = """
        {
            "signerAddress": "\(testAccountId)",
            "contracts": [],
            "count": 0
        }
        """
        var capturedUrl: String?
        installCapturingResponder(body: responseJson) { capturedUrl = $0 }
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        _ = try await indexer.lookupByAddress(address: testAccountId)
        XCTAssertNotNil(capturedUrl)
        XCTAssertTrue(
            capturedUrl!.contains("/api/lookup/address/"),
            "Request URL must contain /api/lookup/address/ path"
        )
        XCTAssertTrue(
            capturedUrl!.hasSuffix(testAccountId),
            "Request URL must end with the address"
        )
    }

    func testLookupByAddress_invalidAddress_throwsValidationException() async throws {
        installResponder(body: "{}")
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByAddress(address: "INVALID_ADDRESS")
            XCTFail("Expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLookupByAddress_httpError_throwsIndexerException() async throws {
        installResponder(body: #"{"error": "service unavailable"}"#, statusCode: 503)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByAddress(address: testAccountId)
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch is SmartAccountIndexerException.RequestFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - getContract

    func testGetContract_success() async throws {
        let responseJson = """
        {
            "contractId": "\(testContractId)",
            "summary": \(contractSummaryJson),
            "contextRules": [
                {
                    "context_rule_id": 0,
                    "signers": [
                        {
                            "signer_type": "External",
                            "credential_id": "aabbccdd"
                        },
                        {
                            "signer_type": "Delegated",
                            "signer_address": "\(testAccountId)"
                        }
                    ],
                    "policies": [
                        {
                            "policy_address": "\(testContractId)",
                            "install_params": {"limit": "1000000000"}
                        }
                    ]
                },
                {
                    "context_rule_id": 1,
                    "signers": [
                        {
                            "signer_type": "Native"
                        }
                    ],
                    "policies": []
                }
            ]
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.getContract(contractId: testContractId)
        XCTAssertEqual(testContractId, result.contractId)
        XCTAssertEqual(2, result.summary.contextRuleCount)
        XCTAssertEqual(1, result.summary.externalSignerCount)
        XCTAssertEqual(1, result.summary.delegatedSignerCount)
        XCTAssertEqual(0, result.summary.nativeSignerCount)
        XCTAssertEqual(100000, result.summary.firstSeenLedger)
        XCTAssertEqual(200000, result.summary.lastSeenLedger)
        XCTAssertEqual([0, 1], result.summary.contextRuleIds)

        let rule0 = result.contextRules[0]
        XCTAssertEqual(0, rule0.contextRuleId)
        XCTAssertEqual(2, rule0.signers.count)
        XCTAssertEqual("External", rule0.signers[0].signerType)
        XCTAssertEqual("aabbccdd", rule0.signers[0].credentialId)
        XCTAssertEqual("Delegated", rule0.signers[1].signerType)
        XCTAssertEqual(testAccountId, rule0.signers[1].signerAddress)
        XCTAssertEqual(1, rule0.policies.count)
        XCTAssertEqual(testContractId, rule0.policies[0].policyAddress)
        XCTAssertNotNil(rule0.policies[0].installParams)

        let rule1 = result.contextRules[1]
        XCTAssertEqual(1, rule1.contextRuleId)
        XCTAssertEqual(1, rule1.signers.count)
        XCTAssertEqual("Native", rule1.signers[0].signerType)
        XCTAssertEqual(0, rule1.policies.count)
    }

    func testGetContract_verifiesUrlPath() async throws {
        let responseJson = """
        {
            "contractId": "\(testContractId)",
            "summary": \(contractSummaryJson),
            "contextRules": []
        }
        """
        var capturedUrl: String?
        installCapturingResponder(body: responseJson) { capturedUrl = $0 }
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        _ = try await indexer.getContract(contractId: testContractId)
        XCTAssertNotNil(capturedUrl)
        XCTAssertTrue(
            capturedUrl!.contains("/api/contract/"),
            "Request URL must contain /api/contract/ path"
        )
        XCTAssertTrue(
            capturedUrl!.hasSuffix(testContractId),
            "Request URL must end with the contract ID"
        )
    }

    func testGetContract_invalidContractId_throwsValidationException() async throws {
        installResponder(body: "{}")
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.getContract(contractId: testAccountId)
            XCTFail("Expected SmartAccountValidationException.InvalidAddress")
        } catch is SmartAccountValidationException.InvalidAddress {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetContract_httpError_throwsIndexerException() async throws {
        installResponder(body: #"{"error": "not found"}"#, statusCode: 404)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.getContract(contractId: testContractId)
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch is SmartAccountIndexerException.RequestFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - getStats

    func testGetStats_success() async throws {
        let responseJson = """
        {
            "stats": {
                "total_events": 15234,
                "unique_contracts": 842,
                "unique_credentials": 1203,
                "first_ledger": 50000,
                "last_ledger": 250000,
                "eventTypes": [
                    {"event_type": "signer_added", "count": 5000},
                    {"event_type": "signer_removed", "count": 1200},
                    {"event_type": "policy_added", "count": 3500}
                ]
            }
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.getStats()
        XCTAssertEqual(Int64(15234), result.stats.totalEvents)
        XCTAssertEqual(Int64(842), result.stats.uniqueContracts)
        XCTAssertEqual(Int64(1203), result.stats.uniqueCredentials)
        XCTAssertEqual(Int64(50000), result.stats.firstLedger)
        XCTAssertEqual(Int64(250000), result.stats.lastLedger)
        XCTAssertEqual(3, result.stats.eventTypes.count)
        XCTAssertEqual("signer_added", result.stats.eventTypes[0].eventType)
        XCTAssertEqual(Int64(5000), result.stats.eventTypes[0].count)
        XCTAssertEqual("signer_removed", result.stats.eventTypes[1].eventType)
        XCTAssertEqual(Int64(1200), result.stats.eventTypes[1].count)
        XCTAssertEqual("policy_added", result.stats.eventTypes[2].eventType)
        XCTAssertEqual(Int64(3500), result.stats.eventTypes[2].count)
    }

    func testGetStats_verifiesUrlPath() async throws {
        let responseJson = """
        {
            "stats": {
                "total_events": 0,
                "unique_contracts": 0,
                "unique_credentials": 0,
                "first_ledger": 0,
                "last_ledger": 0,
                "eventTypes": []
            }
        }
        """
        var capturedUrl: String?
        installCapturingResponder(body: responseJson) { capturedUrl = $0 }
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        _ = try await indexer.getStats()
        XCTAssertNotNil(capturedUrl)
        XCTAssertTrue(
            capturedUrl!.hasSuffix("/api/stats"),
            "Request URL must end with /api/stats"
        )
    }

    func testGetStats_httpError_throwsIndexerException() async throws {
        installResponder(body: #"{"error": "internal server error"}"#, statusCode: 500)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.getStats()
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(error.message.contains("500"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - performRequest: error body truncation

    func testPerformRequest_truncatesLongErrorBody() async throws {
        let longBody = String(repeating: "x", count: 300)
        installResponder(body: longBody, statusCode: 400)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(
                error.message.contains("..."),
                "Long error body must be truncated with ellipsis"
            )
            XCTAssertFalse(
                error.message.contains(String(repeating: "x", count: 201)),
                "Error body must be truncated to at most 200 characters"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPerformRequest_shortErrorBodyNotTruncated() async throws {
        installResponder(body: "short error", statusCode: 400)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(error.message.contains("short error"))
            XCTAssertFalse(
                error.message.hasSuffix("..."),
                "Short error body must not be truncated"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - performRequest: oversize response

    func testPerformRequest_oversizeResponseBody_throwsIndexerException() async throws {
        // why: the indexer must refuse to buffer arbitrarily large bodies returned
        // by a compromised remote endpoint; this exercises the explicit byte cap.
        let oversizeBytes = OZConstants.maxIndexerResponseBytes + 1024
        let oversizeBody = String(repeating: "a", count: oversizeBytes)
        installResponder(body: oversizeBody, contentType: "application/json")
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.getStats()
            XCTFail("Expected SmartAccountIndexerException.RequestFailed for oversize body")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(
                error.message.contains("exceeds maximum size"),
                "Error message must indicate the body exceeded the configured cap"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - performRequest: timeout

    func testPerformRequest_timeout_throwsIndexerTimeoutException() async throws {
        installThrowingResponder(error: MockURLProtocol.timeoutError)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.getStats()
            XCTFail("Expected SmartAccountIndexerException.Timeout")
        } catch let error as SmartAccountIndexerException.Timeout {
            XCTAssertTrue(
                error.message.contains("timed out"),
                "Timeout exception message must indicate timeout"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - performRequest: generic exception wrapping

    func testPerformRequest_genericException_wrappedAsRequestFailed() async throws {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: URLError.notConnectedToInternet.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "unexpected network failure"]
        )
        installThrowingResponder(error: networkError)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(
                error.message.contains("unexpected network failure"),
                "Generic exception must surface the original message"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - isHealthy

    func testIsHealthy_returnsTrue_whenStatusOk() async throws {
        installResponder(body: #"{"status": "ok"}"#)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let healthy = await indexer.isHealthy()
        XCTAssertTrue(healthy)
    }

    func testIsHealthy_returnsFalse_whenStatusError() async throws {
        installResponder(body: #"{"status": "error"}"#)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let healthy = await indexer.isHealthy()
        XCTAssertFalse(healthy)
    }

    func testIsHealthy_returnsFalse_whenNetworkError() async throws {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: URLError.cannotConnectToHost.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Connection refused"]
        )
        installThrowingResponder(error: networkError)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let healthy = await indexer.isHealthy()
        XCTAssertFalse(healthy)
    }

    func testIsHealthy_returnsFalse_whenNon2xxStatus() async throws {
        installResponder(body: #"{"status": "ok"}"#, statusCode: 500)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let healthy = await indexer.isHealthy()
        XCTAssertFalse(healthy)
    }

    func testIsHealthy_verifiesUrlPath() async throws {
        var capturedUrl: String?
        installCapturingResponder(body: #"{"status": "ok"}"#) { capturedUrl = $0 }
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        _ = await indexer.isHealthy()
        XCTAssertEqual(
            "https://indexer.example.com/",
            capturedUrl,
            "Health check URL must be the canonical root endpoint"
        )
    }

    // MARK: - Request: missing Content-Type

    func testRequest_missingContentType_fallsThroughToJsonParse() async throws {
        // why: a missing `Content-Type` header must be treated as JSON so
        // well-behaved endpoints that omit the header on short success
        // responses are not surfaced as transport failures. Builds a
        // 200 response with an empty `headerFields` map and asserts the
        // success path returns the decoded response.
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [],
            "count": 0
        }
        """
        MockURLProtocol.requestHandler = { request in
            let url = request.url ?? URL(string: "https://placeholder")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
            return .success((response, responseJson.data(using: .utf8)))
        }
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let response = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
        XCTAssertEqual("aabbccdd", response.credentialId)
        XCTAssertEqual(0, response.count)
    }

    // MARK: - SDK identification headers

    func testPerformRequest_attachesSdkIdentificationHeaders() async throws {
        // why: every outbound indexer request must carry the SDK
        // identification headers so the server can attribute traffic.
        // Captures the inbound `URLRequest.allHTTPHeaderFields` via
        // `MockURLProtocol.requestInspector` and asserts the two SDK
        // identification headers are present and non-empty.
        var capturedHeaders: [String: String]?
        MockURLProtocol.requestInspector = { request in
            capturedHeaders = request.allHTTPHeaderFields
        }
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [],
            "count": 0
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
        XCTAssertNotNil(capturedHeaders)
        let clientName = capturedHeaders?[OZConstants.clientNameHeader]
        let clientVersion = capturedHeaders?[OZConstants.clientVersionHeader]
        XCTAssertNotNil(clientName, "Client-name header must be attached")
        XCTAssertFalse(clientName?.isEmpty ?? true, "Client-name header must be non-empty")
        XCTAssertNotNil(clientVersion, "Client-version header must be attached")
        XCTAssertFalse(clientVersion?.isEmpty ?? true, "Client-version header must be non-empty")
    }

    // MARK: - close

    func testClose_clientIsAutoCloseable() throws {
        let indexer = try OZIndexerClient(indexerUrl: "https://indexer.example.com")
        indexer.close()
    }

    func testClose_doubleCloseDoesNotThrow() throws {
        let indexer = try OZIndexerClient(indexerUrl: "https://indexer.example.com")
        indexer.close()
        indexer.close()
    }

    // MARK: - String-encoded numeric fields

    /// The production indexer serialises every numeric column as a JSON
    /// string so values that exceed JavaScript's safe-integer range can
    /// round-trip without precision loss. Every decoder site must accept
    /// either a JSON number or a numeric string.
    func testLookupByCredentialId_acceptsStringEncodedNumerics() async throws {
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [
                {
                    "contract_id": "\(testContractId)",
                    "context_rule_count": "2",
                    "external_signer_count": "1",
                    "delegated_signer_count": "1",
                    "native_signer_count": "0",
                    "first_seen_ledger": "100000",
                    "last_seen_ledger": "200000",
                    "context_rule_ids": ["0", "1"]
                }
            ],
            "count": "1"
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
        XCTAssertEqual("aabbccdd", result.credentialId)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(1, result.contracts.count)
        let summary = result.contracts[0]
        XCTAssertEqual(testContractId, summary.contractId)
        XCTAssertEqual(2, summary.contextRuleCount)
        XCTAssertEqual(1, summary.externalSignerCount)
        XCTAssertEqual(1, summary.delegatedSignerCount)
        XCTAssertEqual(0, summary.nativeSignerCount)
        XCTAssertEqual(100000, summary.firstSeenLedger)
        XCTAssertEqual(200000, summary.lastSeenLedger)
        XCTAssertEqual([0, 1], summary.contextRuleIds)
    }

    func testLookupByAddress_acceptsStringEncodedNumerics() async throws {
        let responseJson = """
        {
            "signerAddress": "\(testAccountId)",
            "contracts": [
                {
                    "contract_id": "\(testContractId)",
                    "context_rule_count": "3",
                    "external_signer_count": "0",
                    "delegated_signer_count": "2",
                    "native_signer_count": "1",
                    "first_seen_ledger": "1808254",
                    "last_seen_ledger": "2689784",
                    "context_rule_ids": ["7", "11", "42"]
                }
            ],
            "count": "1"
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.lookupByAddress(address: testAccountId)
        XCTAssertEqual(testAccountId, result.signerAddress)
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(1, result.contracts.count)
        let summary = result.contracts[0]
        XCTAssertEqual(3, summary.contextRuleCount)
        XCTAssertEqual(0, summary.externalSignerCount)
        XCTAssertEqual(2, summary.delegatedSignerCount)
        XCTAssertEqual(1, summary.nativeSignerCount)
        XCTAssertEqual(1808254, summary.firstSeenLedger)
        XCTAssertEqual(2689784, summary.lastSeenLedger)
        XCTAssertEqual([7, 11, 42], summary.contextRuleIds)
    }

    func testGetContract_acceptsStringEncodedNumerics() async throws {
        let responseJson = """
        {
            "contractId": "\(testContractId)",
            "summary": {
                "contract_id": "\(testContractId)",
                "context_rule_count": "2",
                "external_signer_count": "1",
                "delegated_signer_count": "0",
                "native_signer_count": "1",
                "first_seen_ledger": "100000",
                "last_seen_ledger": "200000",
                "context_rule_ids": ["0", "1"]
            },
            "contextRules": [
                {
                    "context_rule_id": "0",
                    "signers": [
                        {"signer_type": "Native"}
                    ],
                    "policies": []
                },
                {
                    "context_rule_id": "1",
                    "signers": [
                        {"signer_type": "External", "credential_id": "aabbccdd"}
                    ],
                    "policies": []
                }
            ]
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.getContract(contractId: testContractId)
        XCTAssertEqual(testContractId, result.contractId)
        XCTAssertEqual(2, result.summary.contextRuleCount)
        XCTAssertEqual(1, result.summary.externalSignerCount)
        XCTAssertEqual(0, result.summary.delegatedSignerCount)
        XCTAssertEqual(1, result.summary.nativeSignerCount)
        XCTAssertEqual(100000, result.summary.firstSeenLedger)
        XCTAssertEqual(200000, result.summary.lastSeenLedger)
        XCTAssertEqual([0, 1], result.summary.contextRuleIds)

        XCTAssertEqual(2, result.contextRules.count)
        XCTAssertEqual(0, result.contextRules[0].contextRuleId)
        XCTAssertEqual(1, result.contextRules[1].contextRuleId)
    }

    func testGetStats_acceptsStringEncodedNumerics() async throws {
        let responseJson = """
        {
            "stats": {
                "total_events": "7348",
                "unique_contracts": "4217",
                "unique_credentials": "1590",
                "first_ledger": "1808254",
                "last_ledger": "2689784",
                "eventTypes": [
                    {"event_type": "context_rule_added", "count": "6567"},
                    {"event_type": "signer_added", "count": "5000"}
                ]
            }
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.getStats()
        XCTAssertEqual(Int64(7348), result.stats.totalEvents)
        XCTAssertEqual(Int64(4217), result.stats.uniqueContracts)
        XCTAssertEqual(Int64(1590), result.stats.uniqueCredentials)
        XCTAssertEqual(Int64(1808254), result.stats.firstLedger)
        XCTAssertEqual(Int64(2689784), result.stats.lastLedger)
        XCTAssertEqual(2, result.stats.eventTypes.count)
        XCTAssertEqual("context_rule_added", result.stats.eventTypes[0].eventType)
        XCTAssertEqual(Int64(6567), result.stats.eventTypes[0].count)
        XCTAssertEqual("signer_added", result.stats.eventTypes[1].eventType)
        XCTAssertEqual(Int64(5000), result.stats.eventTypes[1].count)
    }

    func testGetStats_acceptsMixedNumericAndStringEncoding() async throws {
        // A single response can mix JSON numbers and numeric strings; the
        // decoder must accept either representation per field.
        let responseJson = """
        {
            "stats": {
                "total_events": 7348,
                "unique_contracts": "4217",
                "unique_credentials": 1590,
                "first_ledger": "1808254",
                "last_ledger": 2689784,
                "eventTypes": [
                    {"event_type": "context_rule_added", "count": "6567"},
                    {"event_type": "signer_added", "count": 5000}
                ]
            }
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let result = try await indexer.getStats()
        XCTAssertEqual(Int64(7348), result.stats.totalEvents)
        XCTAssertEqual(Int64(4217), result.stats.uniqueContracts)
        XCTAssertEqual(Int64(1590), result.stats.uniqueCredentials)
        XCTAssertEqual(Int64(1808254), result.stats.firstLedger)
        XCTAssertEqual(Int64(2689784), result.stats.lastLedger)
        XCTAssertEqual(Int64(6567), result.stats.eventTypes[0].count)
        XCTAssertEqual(Int64(5000), result.stats.eventTypes[1].count)
    }

    func testLookupByCredentialId_rejectsNonNumericString() async throws {
        // A non-numeric string for a numeric field must surface as a
        // decoding failure mapped to SmartAccountIndexerException.RequestFailed.
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [],
            "count": "not-a-number"
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch is SmartAccountIndexerException.RequestFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Oversized response body

    func test_lookupByCredentialId_oversizedBody_throwsIndexerException() async throws {
        // Build a body that exceeds the maximum allowed response size.
        let bigBody = String(repeating: "x", count: OZConstants.maxIndexerResponseBytes + 1)
        MockURLProtocol.requestHandler = { request in
            let url = request.url ?? URL(string: "https://placeholder")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return .success((response, bigBody.data(using: .utf8)))
        }
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed for oversized body")
        } catch let error as SmartAccountIndexerException.RequestFailed {
            XCTAssertTrue(
                error.message.lowercased().contains("size") ||
                error.message.lowercased().contains("maximum") ||
                error.message.lowercased().contains("bytes"),
                "Error message must describe the size constraint, got: \(error.message)"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - isHealthy — additional branches

    func test_isHealthy_oversizedBody_returnsFalse() async throws {
        let bigBody = String(repeating: "y", count: OZConstants.maxIndexerResponseBytes + 1)
        installResponder(body: bigBody)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let healthy = await indexer.isHealthy()
        XCTAssertFalse(healthy, "isHealthy must return false when response body exceeds the size limit")
    }

    func test_isHealthy_nonJsonContentType_returnsFalse() async throws {
        installResponder(body: #"{"status":"ok"}"#, contentType: "text/html")
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        let healthy = await indexer.isHealthy()
        XCTAssertFalse(healthy, "isHealthy must return false when Content-Type is not JSON")
    }

    func test_isHealthy_closeBeforeCall_doesNotCrash() async throws {
        installResponder(body: #"{"status":"ok"}"#)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        indexer.close()
        // Calling isHealthy after close should not crash; the underlying session
        // is invalidated. The result may be true or false depending on whether
        // the URLSession has already released its resources.
        _ = await indexer.isHealthy()
        // Reaching here without a crash or unhandled exception is the assertion.
    }

    // MARK: - Model memberwise inits (direct construction paths)

    /// Constructs `OZCredentialLookupResponse` via the memberwise init to
    /// exercise its stored-property assignment path (lines 99-103 in the source).
    func test_credentialLookupResponse_memberwiseInit_storesFields() {
        let summary = OZIndexedContractSummary(
            contractId: testContractId,
            contextRuleCount: 2,
            externalSignerCount: 1,
            delegatedSignerCount: 0,
            nativeSignerCount: 0,
            firstSeenLedger: 100,
            lastSeenLedger: 200,
            contextRuleIds: [0, 1]
        )
        let response = OZCredentialLookupResponse(
            credentialId: "aabb",
            contracts: [summary],
            count: 1
        )
        XCTAssertEqual("aabb", response.credentialId)
        XCTAssertEqual(1, response.contracts.count)
        XCTAssertEqual(1, response.count)
    }

    /// Constructs `OZAddressLookupResponse` via the memberwise init.
    func test_addressLookupResponse_memberwiseInit_storesFields() {
        let response = OZAddressLookupResponse(
            signerAddress: testAccountId,
            contracts: [],
            count: 0
        )
        XCTAssertEqual(testAccountId, response.signerAddress)
        XCTAssertEqual(0, response.contracts.count)
        XCTAssertEqual(0, response.count)
    }

    // MARK: - Flexible Int64 decode error path

    /// The stats response with a non-numeric string in an Int64 field must
    /// surface as `SmartAccountIndexerException.RequestFailed` (exercises `decodeFlexibleInt64`
    /// error throw path).
    func test_getStats_nonNumericStringForInt64Field_throwsIndexerException() async throws {
        let responseJson = """
        {
            "stats": {
                "total_events": "not-a-number",
                "unique_contracts": 1,
                "unique_credentials": 1,
                "first_ledger": 1,
                "last_ledger": 1,
                "eventTypes": []
            }
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.getStats()
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch is SmartAccountIndexerException.RequestFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// The `lookupByCredentialId` response with a non-numeric string for a
    /// contract_id array element must surface as `SmartAccountIndexerException.RequestFailed`
    /// (exercises `UnkeyedDecodingContainer.decodeFlexibleInt` error path).
    func test_lookupByCredentialId_nonNumericContextRuleId_throwsIndexerException() async throws {
        let responseJson = """
        {
            "credentialId": "aabbccdd",
            "contracts": [
                {
                    "contract_id": "\(testContractId)",
                    "context_rule_count": 1,
                    "external_signer_count": 0,
                    "delegated_signer_count": 0,
                    "native_signer_count": 0,
                    "first_seen_ledger": 1,
                    "last_seen_ledger": 2,
                    "context_rule_ids": ["not-a-number"]
                }
            ],
            "count": 1
        }
        """
        installResponder(body: responseJson)
        let session = makeMockSession()
        let indexer = try OZIndexerClient(
            indexerUrl: "https://indexer.example.com",
            urlSession: session
        )
        defer { indexer.close() }

        do {
            _ = try await indexer.lookupByCredentialId(credentialId: "qrvM3Q")
            XCTFail("Expected SmartAccountIndexerException.RequestFailed")
        } catch is SmartAccountIndexerException.RequestFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Model memberwise inits (remaining stored-property assignment paths)

    /// Constructs `OZContractDetailsResponse` via its memberwise init to exercise
    /// the stored-property assignment body. The decode-based tests above always
    /// route through the synthesized `Decodable` init, so the public memberwise
    /// init body is only reached by direct construction.
    func test_contractDetailsResponse_memberwiseInit_storesFields() {
        let summary = OZIndexedContractSummary(
            contractId: testContractId,
            contextRuleCount: 1,
            externalSignerCount: 1,
            delegatedSignerCount: 0,
            nativeSignerCount: 0,
            firstSeenLedger: 10,
            lastSeenLedger: 20,
            contextRuleIds: [0]
        )
        let rule = OZIndexedContextRule(
            contextRuleId: 0,
            signers: [OZIndexedSigner(signerType: "Native")],
            policies: []
        )
        let response = OZContractDetailsResponse(
            contractId: testContractId,
            summary: summary,
            contextRules: [rule]
        )
        XCTAssertEqual(testContractId, response.contractId)
        XCTAssertEqual(testContractId, response.summary.contractId)
        XCTAssertEqual(1, response.contextRules.count)
        XCTAssertEqual(0, response.contextRules[0].contextRuleId)
    }

    /// Constructs `OZIndexedContextRule` via its memberwise init.
    func test_indexedContextRule_memberwiseInit_storesFields() {
        let signer = OZIndexedSigner(signerType: "External", credentialId: "aabbccdd")
        let policy = OZIndexedPolicy(policyAddress: testContractId)
        let rule = OZIndexedContextRule(
            contextRuleId: 7,
            signers: [signer],
            policies: [policy]
        )
        XCTAssertEqual(7, rule.contextRuleId)
        XCTAssertEqual(1, rule.signers.count)
        XCTAssertEqual("External", rule.signers[0].signerType)
        XCTAssertEqual(1, rule.policies.count)
        XCTAssertEqual(testContractId, rule.policies[0].policyAddress)
    }

    /// Constructs `OZIndexedSigner` via its memberwise init, covering all three
    /// stored properties including the optional address and credential fields.
    func test_indexedSigner_memberwiseInit_storesFields() {
        let external = OZIndexedSigner(signerType: "External", credentialId: "deadbeef")
        XCTAssertEqual("External", external.signerType)
        XCTAssertNil(external.signerAddress)
        XCTAssertEqual("deadbeef", external.credentialId)

        let delegated = OZIndexedSigner(signerType: "Delegated", signerAddress: testAccountId)
        XCTAssertEqual("Delegated", delegated.signerType)
        XCTAssertEqual(testAccountId, delegated.signerAddress)
        XCTAssertNil(delegated.credentialId)

        let native = OZIndexedSigner(signerType: "Native")
        XCTAssertEqual("Native", native.signerType)
        XCTAssertNil(native.signerAddress)
        XCTAssertNil(native.credentialId)
    }

    /// Constructs `OZIndexedPolicy` via its memberwise init, covering both the
    /// default-nil install-params path and an explicit install-params dictionary.
    func test_indexedPolicy_memberwiseInit_storesFields() {
        let withoutParams = OZIndexedPolicy(policyAddress: testContractId)
        XCTAssertEqual(testContractId, withoutParams.policyAddress)
        XCTAssertNil(withoutParams.installParams)

        let withParams = OZIndexedPolicy(
            policyAddress: testContractId,
            installParams: ["limit": .integer(1000)]
        )
        XCTAssertEqual(testContractId, withParams.policyAddress)
        XCTAssertEqual(.integer(1000), withParams.installParams?["limit"])
    }

    /// Constructs `OZIndexerStatsResponse` via its memberwise init.
    func test_indexerStatsResponse_memberwiseInit_storesFields() {
        let stats = OZIndexerStats(
            totalEvents: 1,
            uniqueContracts: 2,
            uniqueCredentials: 3,
            firstLedger: 4,
            lastLedger: 5,
            eventTypes: []
        )
        let response = OZIndexerStatsResponse(stats: stats)
        XCTAssertEqual(Int64(1), response.stats.totalEvents)
        XCTAssertEqual(Int64(5), response.stats.lastLedger)
    }

    /// Constructs `OZIndexerStats` via its memberwise init, covering every
    /// stored property assignment.
    func test_indexerStats_memberwiseInit_storesFields() {
        let eventType = OZEventTypeCount(eventType: "signer_added", count: 9)
        let stats = OZIndexerStats(
            totalEvents: 100,
            uniqueContracts: 200,
            uniqueCredentials: 300,
            firstLedger: 400,
            lastLedger: 500,
            eventTypes: [eventType]
        )
        XCTAssertEqual(Int64(100), stats.totalEvents)
        XCTAssertEqual(Int64(200), stats.uniqueContracts)
        XCTAssertEqual(Int64(300), stats.uniqueCredentials)
        XCTAssertEqual(Int64(400), stats.firstLedger)
        XCTAssertEqual(Int64(500), stats.lastLedger)
        XCTAssertEqual(1, stats.eventTypes.count)
        XCTAssertEqual("signer_added", stats.eventTypes[0].eventType)
    }

    /// Constructs `OZEventTypeCount` via its memberwise init.
    func test_eventTypeCount_memberwiseInit_storesFields() {
        let eventType = OZEventTypeCount(eventType: "policy_added", count: 42)
        XCTAssertEqual("policy_added", eventType.eventType)
        XCTAssertEqual(Int64(42), eventType.count)
    }

    /// Constructs `OZIndexerHealthCheckResponse` via its memberwise init.
    func test_healthCheckResponse_memberwiseInit_storesField() {
        let response = OZIndexerHealthCheckResponse(status: "ok")
        XCTAssertEqual("ok", response.status)
    }

    // MARK: - OZJSONValue decode branches

    /// Decodes a `null` install-params value, covering the `.null` decode branch.
    func test_jsonValue_decodesNull() throws {
        let json = #"{"v": null}"#.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode([String: OZJSONValue].self, from: json)
        XCTAssertEqual(.null, wrapper["v"])
    }

    /// Decodes a boolean value, covering the `.bool` decode branch.
    func test_jsonValue_decodesBool() throws {
        let json = #"{"v": true}"#.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode([String: OZJSONValue].self, from: json)
        XCTAssertEqual(.bool(true), wrapper["v"])
    }

    /// Decodes an integer value, covering the `.integer` decode branch.
    func test_jsonValue_decodesInteger() throws {
        let json = #"{"v": 9007199254740993}"#.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode([String: OZJSONValue].self, from: json)
        XCTAssertEqual(.integer(9007199254740993), wrapper["v"])
    }

    /// Decodes a fractional value, covering the `.double` decode branch.
    func test_jsonValue_decodesDouble() throws {
        let json = #"{"v": 1.5}"#.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode([String: OZJSONValue].self, from: json)
        XCTAssertEqual(.double(1.5), wrapper["v"])
    }

    /// Decodes a string value, covering the `.string` decode branch.
    func test_jsonValue_decodesString() throws {
        let json = #"{"v": "hello"}"#.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode([String: OZJSONValue].self, from: json)
        XCTAssertEqual(.string("hello"), wrapper["v"])
    }

    /// Decodes a heterogeneous array value, covering the `.array` decode branch
    /// and recursion into the per-element decode.
    func test_jsonValue_decodesArray() throws {
        let json = #"{"v": [1, "two", true, null]}"#.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode([String: OZJSONValue].self, from: json)
        XCTAssertEqual(
            .array([.integer(1), .string("two"), .bool(true), .null]),
            wrapper["v"]
        )
    }

    /// Decodes a nested object value, covering the `.object` decode branch.
    func test_jsonValue_decodesObject() throws {
        let json = #"{"v": {"inner": 7}}"#.data(using: .utf8)!
        let wrapper = try JSONDecoder().decode([String: OZJSONValue].self, from: json)
        XCTAssertEqual(.object(["inner": .integer(7)]), wrapper["v"])
    }

    /// Decodes an `OZIndexedPolicy` whose `install_params` exercises every
    /// `OZJSONValue` case in a single nested structure, then asserts the parsed
    /// shape end to end.
    func test_jsonValue_decodesNestedInstallParams() throws {
        let json = """
        {
            "policy_address": "\(testContractId)",
            "install_params": {
                "limit": 1000000000,
                "ratio": 0.25,
                "label": "spending",
                "enabled": true,
                "fallback": null,
                "signers": ["a", "b"],
                "nested": {"k": 1}
            }
        }
        """.data(using: .utf8)!
        let policy = try JSONDecoder().decode(OZIndexedPolicy.self, from: json)
        XCTAssertEqual(testContractId, policy.policyAddress)
        let params = try XCTUnwrap(policy.installParams)
        XCTAssertEqual(.integer(1000000000), params["limit"])
        XCTAssertEqual(.double(0.25), params["ratio"])
        XCTAssertEqual(.string("spending"), params["label"])
        XCTAssertEqual(.bool(true), params["enabled"])
        XCTAssertEqual(.null, params["fallback"])
        XCTAssertEqual(.array([.string("a"), .string("b")]), params["signers"])
        XCTAssertEqual(.object(["k": .integer(1)]), params["nested"])
    }

    // MARK: - OZJSONValue hash branches

    /// Hashes one value of every `OZJSONValue` case so the per-case discriminant
    /// combination in `hash(into:)` is exercised. Equal values must hash equally
    /// and the dictionary lookups below force `Hashable` evaluation.
    func test_jsonValue_hashCoversEveryCase() {
        let values: [OZJSONValue] = [
            .null,
            .bool(true),
            .integer(5),
            .double(2.5),
            .string("s"),
            .array([.integer(1), .null]),
            .object(["k": .string("v")]),
        ]
        // Insert every case into a Set: this routes each value through
        // `hash(into:)` and `==`.
        var set = Set<OZJSONValue>()
        for value in values {
            set.insert(value)
            set.insert(value)
        }
        XCTAssertEqual(values.count, set.count, "Distinct cases must not collide in a Set")

        // Equal values must produce equal hashes.
        XCTAssertEqual(OZJSONValue.null.hashValue, OZJSONValue.null.hashValue)
        XCTAssertEqual(OZJSONValue.double(2.5).hashValue, OZJSONValue.double(2.5).hashValue)
        XCTAssertEqual(OZJSONValue.array([.integer(1)]).hashValue, OZJSONValue.array([.integer(1)]).hashValue)
    }

    /// The `.object` hash branch sorts keys before hashing so two dictionaries
    /// with identical contents but different insertion order hash equally.
    func test_jsonValue_objectHashIsKeyOrderIndependent() {
        let a: OZJSONValue = .object(["x": .integer(1), "y": .integer(2)])
        let b: OZJSONValue = .object(["y": .integer(2), "x": .integer(1)])
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue, "Object hash must be key-order independent")
    }
}
