//
//  WebAuthForContractsUnitTests.swift
//  stellarsdk
//
//  Created by Claude AI on 04/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class WebAuthForContractsUnitTests: XCTestCase {

    // MARK: - Test Constants

    let serverDomain = "auth.stellar.org"
    let authEndpoint = "http://auth.stellar.org/auth"
    let failureDomain = "fail.stellar.org"

    // Server keys
    let serverPublicKey = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let serverPrivateKey = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"

    // Valid web auth contract ID (must start with C)
    let webAuthContractId = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"

    // Client contract IDs for various test scenarios
    let validClientContractId = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"
    let challengeErrorTestClient = "CLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLAPGFE"

    // Client domain keys
    let clientDomainPublicKey = "GAIWNNJMDNZTSKEIWBZIERE3WCRIW2LCA3PK3GRX2K7DGWDA7Z5MVUZN"
    let clientDomainPrivateKey = "SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L"

    // Mock instances
    var tomlServerMock: WebAuthForContractsTomlUnitMock!
    var tomlFailServerMock: WebAuthForContractsTomlFailUnitMock!
    var challengeServerMock: WebAuthForContractsChallengUnitMock!
    var sendChallengeServerMock: WebAuthForContractsSendChallengeUnitMock!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        URLProtocol.registerClass(ServerMock.self)

        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)

        tomlServerMock = WebAuthForContractsTomlUnitMock(
            address: serverDomain,
            serverSigningKey: serverPublicKey,
            authServer: authEndpoint,
            webAuthContractId: webAuthContractId
        )

        tomlFailServerMock = WebAuthForContractsTomlFailUnitMock(address: failureDomain)

        challengeServerMock = WebAuthForContractsChallengUnitMock(
            address: serverDomain,
            serverKeyPair: serverKeyPair,
            webAuthContractId: webAuthContractId,
            domain: serverDomain
        )

        sendChallengeServerMock = WebAuthForContractsSendChallengeUnitMock(address: serverDomain)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitWithValidParameters() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        XCTAssertEqual(webAuth.authEndpoint, authEndpoint)
        XCTAssertEqual(webAuth.webAuthContractId, webAuthContractId)
        XCTAssertEqual(webAuth.serverSigningKey, serverPublicKey)
        XCTAssertEqual(webAuth.serverHomeDomain, serverDomain)
    }

    func testInitWithInvalidContractId() {
        XCTAssertThrowsError(try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: "GABC...", // Invalid - not a contract ID
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )) { error in
            guard case WebAuthForContractsError.invalidWebAuthContractId = error else {
                XCTFail("Expected invalidWebAuthContractId error")
                return
            }
        }
    }

    func testInitWithInvalidServerSigningKey() {
        XCTAssertThrowsError(try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: "CABC...", // Invalid - not a G address
            serverHomeDomain: serverDomain,
            network: .testnet
        )) { error in
            guard case WebAuthForContractsError.invalidServerSigningKey = error else {
                XCTFail("Expected invalidServerSigningKey error")
                return
            }
        }
    }

    func testInitWithInvalidAuthEndpoint() {
        XCTAssertThrowsError(try WebAuthForContracts(
            authEndpoint: "not-a-valid-url",
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )) { error in
            guard case WebAuthForContractsError.invalidAuthEndpoint = error else {
                XCTFail("Expected invalidAuthEndpoint error")
                return
            }
        }
    }

    func testInitWithEmptyServerHomeDomain() {
        XCTAssertThrowsError(try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: "   ",
            network: .testnet
        )) { error in
            guard case WebAuthForContractsError.emptyServerHomeDomain = error else {
                XCTFail("Expected emptyServerHomeDomain error")
                return
            }
        }
    }

    func testInitWithCustomSorobanRpcUrl() throws {
        let customRpcUrl = "https://custom-rpc.stellar.org"
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet,
            sorobanRpcUrl: customRpcUrl
        )

        XCTAssertEqual(webAuth.sorobanRpcUrl, customRpcUrl)
    }

    // MARK: - From Domain Tests

    func testFromDomainSuccess() async {
        let result = await WebAuthForContracts.from(
            domain: serverDomain,
            network: .testnet
        )

        switch result {
        case .success(let webAuth):
            XCTAssertEqual(webAuth.serverHomeDomain, serverDomain)
            XCTAssertEqual(webAuth.serverSigningKey, serverPublicKey)
            XCTAssertEqual(webAuth.webAuthContractId, webAuthContractId)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testFromDomainFailureInvalidToml() async {
        let result = await WebAuthForContracts.from(
            domain: failureDomain,
            network: .testnet
        )

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            // Could be invalidToml or noAuthEndpoint depending on mock
            switch error {
            case .invalidToml, .noAuthEndpoint, .noWebAuthContractId, .noSigningKey:
                return // Expected
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - JWT Token Request Tests with Invalid Client Account

    func testJwtTokenWithInvalidClientAccountId() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        // Using a G address instead of C address
        let result = await webAuth.jwtToken(
            forContractAccount: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
            signers: []
        )

        switch result {
        case .success:
            XCTFail("Expected failure for invalid client account ID")
        case .failure(let error):
            if case .parsingError(let message) = error {
                XCTAssertTrue(message.contains("contract address"))
            } else {
                XCTFail("Expected parsingError for invalid client account ID")
            }
        }
    }

    // MARK: - Response Parsing Tests

    func testContractChallengeResponseDecodingSnakeCase() throws {
        let json = """
        {
            "authorization_entries": "AAAAB...",
            "network_passphrase": "Test SDF Network ; September 2015"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ContractChallengeResponse.self, from: json)

        XCTAssertEqual(response.authorizationEntries, "AAAAB...")
        XCTAssertEqual(response.networkPassphrase, "Test SDF Network ; September 2015")
    }

    func testContractChallengeResponseDecodingCamelCase() throws {
        let json = """
        {
            "authorizationEntries": "AAAAB...",
            "networkPassphrase": "Test SDF Network ; September 2015"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ContractChallengeResponse.self, from: json)

        XCTAssertEqual(response.authorizationEntries, "AAAAB...")
        XCTAssertEqual(response.networkPassphrase, "Test SDF Network ; September 2015")
    }

    func testContractChallengeResponseDecodingWithoutNetworkPassphrase() throws {
        let json = """
        {
            "authorization_entries": "AAAAB..."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ContractChallengeResponse.self, from: json)

        XCTAssertEqual(response.authorizationEntries, "AAAAB...")
        XCTAssertNil(response.networkPassphrase)
    }

    func testContractChallengeResponseDecodingMissingEntries() {
        let json = """
        {
            "network_passphrase": "Test SDF Network ; September 2015"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(ContractChallengeResponse.self, from: json))
    }

    // MARK: - Error Enum Tests

    func testContractChallengeValidationErrorDescription() {
        let errors: [ContractChallengeValidationError] = [
            .invalidContractAddress(expected: "C123", received: "C456"),
            .invalidFunctionName(expected: "web_auth_verify", received: "other"),
            .subInvocationsFound,
            .invalidHomeDomain(expected: "example.com", received: "other.com"),
            .invalidWebAuthDomain(expected: "auth.example.com", received: "other.auth.com"),
            .invalidAccount(expected: "C123", received: "C456"),
            .invalidNonce(message: "Nonce mismatch"),
            .invalidServerSignature,
            .missingServerEntry,
            .missingClientEntry,
            .invalidArgs(message: "Invalid arguments"),
            .invalidNetworkPassphrase(expected: "Test", received: "Public"),
            .invalidClientDomainAccount(expected: "G123", received: "G456")
        ]

        // Verify all error cases exist and can be created
        XCTAssertEqual(errors.count, 13)
    }

    func testWebAuthForContractsErrorDescription() {
        let errors: [WebAuthForContractsError] = [
            .invalidDomain,
            .invalidToml,
            .noAuthEndpoint,
            .noWebAuthContractId,
            .noSigningKey,
            .invalidWebAuthContractId(message: "Invalid"),
            .invalidServerSigningKey(message: "Invalid"),
            .invalidAuthEndpoint(message: "Invalid"),
            .emptyServerHomeDomain,
            .invalidClientAccountId(message: "Invalid"),
            .missingClientDomainSigningCallback
        ]

        // Verify all error cases exist and can be created
        XCTAssertEqual(errors.count, 11)
    }

    func testGetContractJWTTokenErrorDescription() {
        let mockError = NSError(domain: "test", code: 0)
        let errors: [GetContractJWTTokenError] = [
            .requestError(error: mockError),
            .challengeRequestError(message: "Failed"),
            .submitChallengeError(message: "Failed"),
            .submitChallengeTimeout,
            .submitChallengeUnknownResponse(statusCode: 500),
            .parsingError(message: "Parse failed"),
            .validationError(error: .invalidServerSignature),
            .signingError(message: "Sign failed")
        ]

        // Verify all error cases exist and can be created
        XCTAssertEqual(errors.count, 8)
    }

    // MARK: - Properties Tests

    func testUseFormUrlEncodedDefault() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        XCTAssertTrue(webAuth.useFormUrlEncoded, "useFormUrlEncoded should default to true")
    }

    func testUseFormUrlEncodedCanBeChanged() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        webAuth.useFormUrlEncoded = false
        XCTAssertFalse(webAuth.useFormUrlEncoded)
    }

    func testSorobanRpcUrlDefaultsBasedOnNetwork() throws {
        let testnetWebAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        XCTAssertEqual(testnetWebAuth.sorobanRpcUrl, "https://soroban-testnet.stellar.org")

        let pubnetWebAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .public
        )

        XCTAssertEqual(pubnetWebAuth.sorobanRpcUrl, "https://soroban.stellar.org")
    }

    // MARK: - Authorization Entry Decoding Tests

    func testDecodeAuthorizationEntriesInvalidBase64() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        XCTAssertThrowsError(try webAuth.decodeAuthorizationEntries(base64Xdr: "not-valid-base64!@#$"))
    }

    func testDecodeAuthorizationEntriesEmptyArray() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        // XDR encoded empty array: count = 0
        let emptyArrayXdr = "AAAAAA==" // 4 bytes of zeros (Int32 = 0)
        let entries = try webAuth.decodeAuthorizationEntries(base64Xdr: emptyArrayXdr)

        XCTAssertTrue(entries.isEmpty)
    }

    // MARK: - Challenge Validation Tests

    func testValidateChallengeWithEmptyEntries() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: [],
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidArgs(let message) = error else {
                XCTFail("Expected invalidArgs error")
                return
            }
            XCTAssertTrue(message.contains("No authorization entries"))
        }
    }

    // MARK: - Response Enum Tests

    func testWebAuthForContractsForDomainEnumSuccess() {
        // This tests that the enum can hold a WebAuthForContracts instance
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let result: WebAuthForContractsForDomainEnum = .success(response: webAuth)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.serverHomeDomain, serverDomain)
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testWebAuthForContractsForDomainEnumFailure() {
        let result: WebAuthForContractsForDomainEnum = .failure(error: .noAuthEndpoint)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            guard case .noAuthEndpoint = error else {
                XCTFail("Expected noAuthEndpoint error")
                return
            }
        }
    }

    func testGetContractJWTTokenResponseEnumSuccess() {
        let result: GetContractJWTTokenResponseEnum = .success(jwtToken: "test-token")

        switch result {
        case .success(let token):
            XCTAssertEqual(token, "test-token")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testGetContractJWTTokenResponseEnumFailure() {
        let result: GetContractJWTTokenResponseEnum = .failure(error: .submitChallengeTimeout)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            guard case .submitChallengeTimeout = error else {
                XCTFail("Expected submitChallengeTimeout error")
                return
            }
        }
    }

    func testGetContractChallengeResponseEnumSuccess() {
        let mockResponse = """
        {
            "authorization_entries": "AAAA",
            "network_passphrase": "Test"
        }
        """.data(using: .utf8)!

        let challengeResponse = try! JSONDecoder().decode(ContractChallengeResponse.self, from: mockResponse)
        let result: GetContractChallengeResponseEnum = .success(response: challengeResponse)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.authorizationEntries, "AAAA")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSubmitContractChallengeResponseEnumSuccess() {
        let result: SubmitContractChallengeResponseEnum = .success(jwtToken: "jwt-token")

        switch result {
        case .success(let token):
            XCTAssertEqual(token, "jwt-token")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testSubmitContractChallengeResponseEnumFailure() {
        let result: SubmitContractChallengeResponseEnum = .failure(error: .submitChallengeError(message: "Invalid"))

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .submitChallengeError(let message) = error {
                XCTAssertEqual(message, "Invalid")
            } else {
                XCTFail("Expected submitChallengeError")
            }
        }
    }
}

// MARK: - Mock Classes

class WebAuthForContractsTomlUnitMock: ResponsesMock {
    var address: String
    var serverSigningKey: String
    var authServer: String
    var webAuthContractId: String

    init(address: String, serverSigningKey: String, authServer: String, webAuthContractId: String) {
        self.address = address
        self.serverSigningKey = serverSigningKey
        self.authServer = authServer
        self.webAuthContractId = webAuthContractId

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            return self?.stellarToml
        }

        return RequestMock(
            host: address,
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    var stellarToml: String {
        return """
        # Sample stellar.toml for SEP-45

        WEB_AUTH_FOR_CONTRACTS_ENDPOINT="\(authServer)"
        WEB_AUTH_CONTRACT_ID="\(webAuthContractId)"
        SIGNING_KEY="\(serverSigningKey)"
        """
    }
}

class WebAuthForContractsTomlFailUnitMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 404
            return "Not Found"
        }

        return RequestMock(
            host: address,
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

class WebAuthForContractsChallengUnitMock: ResponsesMock {
    var address: String
    var serverKeyPair: KeyPair
    var webAuthContractId: String
    var domain: String

    var testContractIdCache: [String: Data] = [:]

    init(address: String, serverKeyPair: KeyPair, webAuthContractId: String, domain: String) {
        self.address = address
        self.serverKeyPair = serverKeyPair
        self.webAuthContractId = webAuthContractId
        self.domain = domain

        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return "error" }

            if let account = mock.variables["account"] {
                // Success case
                if account == "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV" {
                    mock.statusCode = 200
                    return self.buildValidChallenge(
                        clientAccountId: account,
                        homeDomain: self.domain,
                        webAuthDomain: self.address,
                        signServerEntry: true
                    )
                }
                // Challenge error case
                else if account == "CLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLAPGFE" {
                    mock.statusCode = 400
                    return self.errorResponse
                }
            }

            mock.statusCode = 400
            return self.errorResponse
        }

        return RequestMock(
            host: address,
            path: "*",
            httpMethod: "GET",
            mockHandler: handler
        )
    }

    func buildArgsMap(
        account: String,
        homeDomain: String,
        webAuthDomain: String,
        webAuthDomainAccount: String,
        nonce: String,
        clientDomain: String? = nil,
        clientDomainAccount: String? = nil
    ) -> SCValXDR {
        var mapEntries: [SCMapEntryXDR] = []

        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("account"),
            val: SCValXDR.string(account)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("home_domain"),
            val: SCValXDR.string(homeDomain)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("web_auth_domain"),
            val: SCValXDR.string(webAuthDomain)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("web_auth_domain_account"),
            val: SCValXDR.string(webAuthDomainAccount)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("nonce"),
            val: SCValXDR.string(nonce)
        ))

        if let cd = clientDomain {
            mapEntries.append(SCMapEntryXDR(
                key: SCValXDR.symbol("client_domain"),
                val: SCValXDR.string(cd)
            ))
        }

        if let cda = clientDomainAccount {
            mapEntries.append(SCMapEntryXDR(
                key: SCValXDR.symbol("client_domain_account"),
                val: SCValXDR.string(cda)
            ))
        }

        return SCValXDR.map(mapEntries)
    }

    func buildAuthEntry(
        credentialsAddress: String,
        contractId: String,
        functionName: String,
        argsMap: SCValXDR,
        nonce: Int64,
        expirationLedger: UInt32,
        signWith: KeyPair? = nil,
        network: Network = .testnet,
        subInvocations: [SorobanAuthorizedInvocationXDR] = []
    ) throws -> SorobanAuthorizationEntryXDR {
        let address: SCAddressXDR
        if credentialsAddress.starts(with: "C") {
            let contractIdData: Data
            if let cachedData = testContractIdCache[credentialsAddress] {
                contractIdData = cachedData
            } else {
                do {
                    contractIdData = try credentialsAddress.decodeContractId()
                    testContractIdCache[credentialsAddress] = contractIdData
                } catch {
                    var hasher = Hasher()
                    hasher.combine(credentialsAddress)
                    let hashValue = hasher.finalize()
                    var data = Data(count: 32)
                    withUnsafeBytes(of: hashValue) { bytes in
                        data.replaceSubrange(0..<min(bytes.count, 32), with: bytes)
                    }
                    testContractIdCache[credentialsAddress] = data
                    contractIdData = data
                }
            }
            address = SCAddressXDR.contract(WrappedData32(contractIdData))
        } else if credentialsAddress.starts(with: "G") {
            let publicKey = try PublicKey(accountId: credentialsAddress)
            address = SCAddressXDR.account(publicKey)
        } else {
            throw NSError(domain: "Invalid address", code: 0)
        }

        let credentials = SorobanCredentialsXDR.address(
            SorobanAddressCredentialsXDR(
                address: address,
                nonce: nonce,
                signatureExpirationLedger: expirationLedger,
                signature: SCValXDR.vec([])
            )
        )

        let contractAddress: SCAddressXDR
        let contractIdData: Data
        if let cachedData = testContractIdCache[contractId] {
            contractIdData = cachedData
        } else {
            do {
                contractIdData = try contractId.decodeContractId()
                testContractIdCache[contractId] = contractIdData
            } catch {
                var hasher = Hasher()
                hasher.combine(contractId)
                let hashValue = hasher.finalize()
                var data = Data(count: 32)
                withUnsafeBytes(of: hashValue) { bytes in
                    data.replaceSubrange(0..<min(bytes.count, 32), with: bytes)
                }
                testContractIdCache[contractId] = data
                contractIdData = data
            }
        }
        contractAddress = SCAddressXDR.contract(WrappedData32(contractIdData))

        let contractFn = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: functionName,
            args: [argsMap]
        )

        let function = SorobanAuthorizedFunctionXDR.contractFn(contractFn)
        let invocation = SorobanAuthorizedInvocationXDR(
            function: function,
            subInvocations: subInvocations
        )

        var entry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )

        if let signer = signWith {
            try entry.sign(signer: signer, network: network)
        }

        return entry
    }

    func encodeAuthEntries(_ entries: [SorobanAuthorizationEntryXDR]) throws -> String {
        struct AuthEntriesArray: XDREncodable {
            let entries: [SorobanAuthorizationEntryXDR]

            func xdrEncode(to encoder: XDREncoder) throws {
                try encoder.encode(Int32(entries.count))
                for entry in entries {
                    try encoder.encode(entry)
                }
            }
        }

        let wrapper = AuthEntriesArray(entries: entries)
        let encodedBytes = try XDREncoder.encode(wrapper)
        return Data(encodedBytes).base64EncodedString()
    }

    func buildValidChallenge(
        clientAccountId: String,
        homeDomain: String,
        webAuthDomain: String,
        signServerEntry: Bool
    ) -> String {
        do {
            let nonce = "test_nonce_\(Int64.random(in: 1000...9999))"
            let argsMap = buildArgsMap(
                account: clientAccountId,
                homeDomain: homeDomain,
                webAuthDomain: webAuthDomain,
                webAuthDomainAccount: serverKeyPair.accountId,
                nonce: nonce
            )

            var entries: [SorobanAuthorizationEntryXDR] = []

            let serverEntry = try buildAuthEntry(
                credentialsAddress: serverKeyPair.accountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12345,
                expirationLedger: 1000000,
                signWith: signServerEntry ? serverKeyPair : nil
            )
            entries.append(serverEntry)

            let clientEntry = try buildAuthEntry(
                credentialsAddress: clientAccountId,
                contractId: webAuthContractId,
                functionName: "web_auth_verify",
                argsMap: argsMap,
                nonce: 12346,
                expirationLedger: 1000000
            )
            entries.append(clientEntry)

            let challengeXdr = try encodeAuthEntries(entries)

            return """
            {
                "authorization_entries": "\(challengeXdr)",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        } catch {
            return errorResponse
        }
    }

    var errorResponse: String {
        return """
        {
            "error": "Invalid account or request"
        }
        """
    }
}

class WebAuthForContractsSendChallengeUnitMock: ResponsesMock {
    var address: String
    var shouldTimeout: Bool = false
    var shouldError: Bool = false

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else { return "error" }

            if self.shouldTimeout {
                mock.statusCode = 504
                return "Gateway Timeout"
            }

            if self.shouldError {
                mock.statusCode = 400
                return """
                {
                    "error": "Invalid signature"
                }
                """
            }

            mock.statusCode = 200
            return self.successResponse
        }

        return RequestMock(
            host: address,
            path: "*",
            httpMethod: "POST",
            mockHandler: handler
        )
    }

    var successResponse: String {
        return """
        {
            "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJDRFpKSURRVzVXVFBBWjY0UEdJSkdWRUlETks3MkxMM0xLVVpXRzNHNkdXWFlRS0kySkFJVkZOViIsImlzcyI6ImV4YW1wbGUuc3RlbGxhci5vcmciLCJpYXQiOjE3Mzc3NjAwMDAsImV4cCI6MTczNzc2MzYwMH0.test"
        }
        """
    }
}
