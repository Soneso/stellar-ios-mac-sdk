//
//  Sep10DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-10 documentation code examples.
//  Uses ServerMock/RequestMock infrastructure for HTTP mocking.
//

import XCTest
import stellarsdk

// MARK: - Test class

class Sep10DocTest: XCTestCase {

    let domain = "place.domain.com"
    let authServer = "http://api.stellar.org/auth"

    let serverPublicKey = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let serverPrivateKey = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"

    let clientPublicKey = "GB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375V44V"
    let clientPrivateKey = "SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX"

    let clientDomainAccountSeed = "SBE64KCQLJXJPMYLF22YCUSTH7WXJ7VZSCTPHXY3VDSIF3QUHJDBE6R6"

    let muxedAccountIdM = "MC6PZZU7XEYLCV7XW5LZC3J72HKQ7CABZCLVGPXCPLLRPZ4SJHC2UAAAAAAACMICQPLEG"
    let muxedAccountIdG = "GC6PZZU7XEYLCV7XW5LZC3J72HKQ7CABZCLVGPXCPLLRPZ4SJHC2US3P"
    let muxedAccountMemo: UInt64 = 19989123
    let muxedAccountSeed = "SB7BORUWGKD6QVQMMOB556OPCIU6PXC4KOJ7WNQJGYK724XZA6IFRJL3"

    override func setUp() {
        URLProtocol.registerClass(ServerMock.self)
        ServerMock.removeAll()
    }

    override func tearDown() {
        ServerMock.removeAll()
    }

    // MARK: - Mock builders
    // Use ServerMock.add(mock:) directly to avoid the ResponsesMock deinit clearing all mocks.

    private func generateNonce(length: Int) -> String? {
        let nonce = NSMutableData(length: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, nonce!.length, nonce!.mutableBytes)
        if result == errSecSuccess {
            return (nonce! as Data).base64EncodedString()
        } else {
            return nil
        }
    }

    private func buildChallenge(
        serverKeyPair: KeyPair,
        accountId: String,
        memo: UInt64? = nil
    ) -> String {
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)
        let timeBounds = TimeBounds(
            minTime: UInt64(Date().timeIntervalSince1970),
            maxTime: UInt64(Date().timeIntervalSince1970 + 300)
        )
        let operation1 = ManageDataOperation(
            sourceAccountId: accountId,
            name: domain + " auth",
            data: generateNonce(length: 64)?.data(using: .utf8)
        )
        let operation2 = ManageDataOperation(
            sourceAccountId: serverKeyPair.accountId,
            name: "web_auth_domain",
            data: "api.stellar.org".data(using: .utf8)
        )
        var txMemo = Memo.none
        if let memoVal = memo {
            txMemo = Memo.id(memoVal)
        }
        let preconditions = TransactionPreconditions(timeBounds: timeBounds)
        let transaction = try! Transaction(
            sourceAccount: transactionAccount,
            operations: [operation1, operation2],
            memo: txMemo,
            preconditions: preconditions
        )
        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        return """
        {"transaction": "\(try! transaction.encodedEnvelope())"}
        """
    }

    private func buildChallengeWithClientDomain(
        serverKeyPair: KeyPair,
        accountId: String,
        clientDomainAccountId: String
    ) -> String {
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)
        let timeBounds = TimeBounds(
            minTime: UInt64(Date().timeIntervalSince1970),
            maxTime: UInt64(Date().timeIntervalSince1970 + 300)
        )
        let operation1 = ManageDataOperation(
            sourceAccountId: accountId,
            name: domain + " auth",
            data: generateNonce(length: 64)?.data(using: .utf8)
        )
        let operation2 = ManageDataOperation(
            sourceAccountId: serverKeyPair.accountId,
            name: "web_auth_domain",
            data: "api.stellar.org".data(using: .utf8)
        )
        let clientDomainOp = ManageDataOperation(
            sourceAccountId: clientDomainAccountId,
            name: "client_domain",
            data: "mywallet.com".data(using: .utf8)
        )
        let preconditions = TransactionPreconditions(timeBounds: timeBounds)
        let transaction = try! Transaction(
            sourceAccount: transactionAccount,
            operations: [operation1, operation2, clientDomainOp],
            memo: Memo.none,
            preconditions: preconditions
        )
        try! transaction.sign(keyPair: serverKeyPair, network: .testnet)
        return """
        {"transaction": "\(try! transaction.encodedEnvelope())"}
        """
    }

    private func registerChallengeMock(serverKeyPair: KeyPair) {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else {
                mock.statusCode = 400
                return "{\"error\": \"Missing self\"}"
            }
            guard let account = mock.variables["account"] else {
                mock.statusCode = 400
                return "{\"error\": \"Missing account parameter\"}"
            }
            mock.statusCode = 200
            let memo: UInt64? = mock.variables["memo"].flatMap { UInt64($0) }
            return self.buildChallenge(serverKeyPair: serverKeyPair, accountId: account, memo: memo)
        }
        ServerMock.add(mock: RequestMock(
            host: "api.stellar.org",
            path: "/auth",
            httpMethod: "GET",
            mockHandler: handler
        ))
    }

    private func registerClientDomainChallengeMock(
        serverKeyPair: KeyPair,
        clientDomainAccountId: String
    ) {
        let handler: MockHandler = { [weak self] mock, request in
            guard let self = self else {
                mock.statusCode = 400
                return "{\"error\": \"Missing self\"}"
            }
            guard let account = mock.variables["account"] else {
                mock.statusCode = 400
                return "{\"error\": \"Missing account parameter\"}"
            }
            mock.statusCode = 200
            return self.buildChallengeWithClientDomain(
                serverKeyPair: serverKeyPair,
                accountId: account,
                clientDomainAccountId: clientDomainAccountId
            )
        }
        ServerMock.add(mock: RequestMock(
            host: "api.stellar.org",
            path: "/auth",
            httpMethod: "GET",
            mockHandler: handler
        ))
    }

    private func registerSendChallengeMock(validClientPublicKeys: [String]) {
        let handler: MockHandler = { mock, request in
            if let data = request.httpBodyStream?.readfully(),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let txXdr = json["transaction"] as? String {
                let envelope = try! TransactionEnvelopeXDR(xdr: txXdr)
                let transactionHash = try! [UInt8](envelope.txHash(network: .testnet))
                var clientSignatureValid = false
                for signature in envelope.txSignatures {
                    let sign = signature.signature
                    for pubKey in validClientPublicKeys {
                        let kp = try! KeyPair(accountId: pubKey)
                        if (try? kp.verify(signature: [UInt8](sign), message: transactionHash)) == true {
                            clientSignatureValid = true
                            break
                        }
                    }
                    if clientSignatureValid { break }
                }
                if clientSignatureValid {
                    mock.statusCode = 200
                    return """
                    {"token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0"}
                    """
                }
            }
            mock.statusCode = 400
            return "{\"error\": \"The provided transaction is not valid\"}"
        }
        ServerMock.add(mock: RequestMock(
            host: "api.stellar.org",
            path: "/auth",
            httpMethod: "POST",
            mockHandler: handler
        ))
    }

    private func registerTomlMock(address: String, serverSigningKey: String, authServer: String) {
        let toml = """
        # Sample stellar.toml
        WEB_AUTH_ENDPOINT="\(authServer)"
        SIGNING_KEY="\(serverSigningKey)"
        """
        let handler: MockHandler = { mock, request in
            return toml
        }
        ServerMock.add(mock: RequestMock(
            host: address,
            path: "/.well-known/stellar.toml",
            httpMethod: "GET",
            mockHandler: handler
        ))
    }

    // MARK: - Snippet 1 & 4: Standard authentication (Quick Example + Standard auth)

    func testStandardAuthentication() async {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientPrivateKey)

        registerChallengeMock(serverKeyPair: serverKeyPair)
        registerSendChallengeMock(validClientPublicKeys: [clientPublicKey])

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        let jwtResult = await webAuth.jwtToken(
            forUserAccount: clientKeyPair.accountId,
            signers: [clientKeyPair]
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"), "JWT token should start with 'eyJ'")
        case .failure(let error):
            XCTFail("Standard authentication failed: \(error)")
        }
    }

    // MARK: - Snippet 2 & 3: Creating WebAuthenticator from domain and manually

    func testWebAuthenticatorFromDomain() async {
        registerTomlMock(
            address: domain,
            serverSigningKey: serverPublicKey,
            authServer: authServer
        )

        let authResult = await WebAuthenticator.from(domain: domain, network: .testnet)
        switch authResult {
        case .success(let webAuth):
            XCTAssertEqual(authServer, webAuth.authEndpoint)
            XCTAssertEqual(serverPublicKey, webAuth.serverSigningKey)
        case .failure(let error):
            XCTFail("WebAuthenticator.from(domain:) failed: \(error)")
        }
    }

    func testWebAuthenticatorManualConstruction() {
        // Snippet 3: Manual construction
        let webAuth = WebAuthenticator(
            authEndpoint: "https://testanchor.stellar.org/auth",
            network: Network.testnet,
            serverSigningKey: "GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS",
            serverHomeDomain: "testanchor.stellar.org"
        )

        XCTAssertEqual("https://testanchor.stellar.org/auth", webAuth.authEndpoint)
        XCTAssertEqual("GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS", webAuth.serverSigningKey)
        XCTAssertEqual("testanchor.stellar.org", webAuth.serverHomeDomain)
    }

    // MARK: - Snippet 5: Multi-signature authentication

    func testMultiSignatureAuthentication() async {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let signer1 = try! KeyPair(secretSeed: clientPrivateKey)
        let signer2 = try! KeyPair.generateRandomKeyPair()

        registerChallengeMock(serverKeyPair: serverKeyPair)
        registerSendChallengeMock(validClientPublicKeys: [signer1.accountId, signer2.accountId])

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        let jwtResult = await webAuth.jwtToken(
            forUserAccount: signer1.accountId,
            signers: [signer1, signer2]
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"), "JWT should start with 'eyJ'")
        case .failure(let error):
            XCTFail("Multi-sig authentication failed: \(error)")
        }
    }

    // MARK: - Snippet 6: Muxed account authentication

    func testMuxedAccountAuthentication() async {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let userKeyPair = try! KeyPair(secretSeed: muxedAccountSeed)

        registerChallengeMock(serverKeyPair: serverKeyPair)
        registerSendChallengeMock(validClientPublicKeys: [muxedAccountIdG])

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        // Authenticate using M... address
        let jwtResult = await webAuth.jwtToken(
            forUserAccount: muxedAccountIdM,
            signers: [userKeyPair]
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"))
        case .failure(let error):
            XCTFail("Muxed account authentication failed: \(error)")
        }
    }

    // MARK: - Snippet 7: Memo-based user separation

    func testMemoBasedAuthentication() async {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let userKeyPair = try! KeyPair(secretSeed: muxedAccountSeed)

        registerChallengeMock(serverKeyPair: serverKeyPair)
        registerSendChallengeMock(validClientPublicKeys: [muxedAccountIdG])

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        let jwtResult = await webAuth.jwtToken(
            forUserAccount: muxedAccountIdG,
            memo: muxedAccountMemo,
            signers: [userKeyPair]
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"))
        case .failure(let error):
            XCTFail("Memo-based authentication failed: \(error)")
        }
    }

    // MARK: - Snippet 7b: Memo + muxed account should fail

    func testMemoWithMuxedAccountFails() async {
        let userKeyPair = try! KeyPair(secretSeed: muxedAccountSeed)

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        // Using both M... address and memo should fail — SDK rejects before making any network request
        let jwtResult = await webAuth.jwtToken(
            forUserAccount: muxedAccountIdM,
            memo: muxedAccountMemo,
            signers: [userKeyPair]
        )

        switch jwtResult {
        case .success:
            XCTFail("Should have failed: memo with M... address is not allowed")
        case .failure(let error):
            switch error {
            case .requestError:
                // Expected: memo + muxed account results in requestError
                break
            default:
                XCTFail("Expected requestError, got: \(error)")
            }
        }
    }

    // MARK: - Snippet 8: Client domain with local signing

    func testClientDomainLocalSigning() async {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientPrivateKey)
        let clientDomainKeyPair = try! KeyPair(secretSeed: clientDomainAccountSeed)

        registerClientDomainChallengeMock(
            serverKeyPair: serverKeyPair,
            clientDomainAccountId: clientDomainKeyPair.accountId
        )
        registerSendChallengeMock(
            validClientPublicKeys: [clientPublicKey, clientDomainKeyPair.accountId]
        )

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        let jwtResult = await webAuth.jwtToken(
            forUserAccount: clientKeyPair.accountId,
            signers: [clientKeyPair],
            clientDomain: "mywallet.com",
            clientDomainAccountKeyPair: clientDomainKeyPair
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"))
        case .failure(let error):
            XCTFail("Client domain local signing failed: \(error)")
        }
    }

    // MARK: - Snippet 9: Client domain with remote signing callback

    func testClientDomainRemoteSigning() async {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientPrivateKey)
        let clientDomainSigningKeyPair = try! KeyPair(secretSeed: clientDomainAccountSeed)
        // Public-key-only keypair (no private key) - triggers use of signing function
        let clientDomainAccountKeyPair = try! KeyPair(accountId: clientDomainSigningKeyPair.accountId)

        registerClientDomainChallengeMock(
            serverKeyPair: serverKeyPair,
            clientDomainAccountId: clientDomainSigningKeyPair.accountId
        )
        registerSendChallengeMock(
            validClientPublicKeys: [clientPublicKey, clientDomainSigningKeyPair.accountId]
        )

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        // Remote signing function that simulates a signing server
        let signingFunction: (String) async throws -> String = { txEnvelopeXdr in
            let envelopeXDR = try TransactionEnvelopeXDR(xdr: txEnvelopeXdr)
            let transactionHash = try [UInt8](envelopeXDR.txHash(network: .testnet))
            let signingKey = try KeyPair(secretSeed: "SBE64KCQLJXJPMYLF22YCUSTH7WXJ7VZSCTPHXY3VDSIF3QUHJDBE6R6")
            let signature = signingKey.signDecorated(transactionHash)
            envelopeXDR.appendSignature(signature: signature)
            let encoded = try XDREncoder.encode(envelopeXDR)
            return Data(bytes: encoded, count: encoded.count).base64EncodedString()
        }

        let jwtResult = await webAuth.jwtToken(
            forUserAccount: clientKeyPair.accountId,
            signers: [clientKeyPair],
            clientDomain: "mywallet.com",
            clientDomainAccountKeyPair: clientDomainAccountKeyPair,
            clientDomainSigningFunction: signingFunction
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"))
        case .failure(let error):
            XCTFail("Client domain remote signing failed: \(error)")
        }
    }

    // MARK: - Snippet 10: Multiple home domains

    func testMultipleHomeDomains() async {
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientPrivateKey)

        registerChallengeMock(serverKeyPair: serverKeyPair)
        registerSendChallengeMock(validClientPublicKeys: [clientPublicKey])

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        // The homeDomain parameter is passed to the server as a query parameter.
        // Our mock does not filter on it, so it still returns a valid challenge for domain.
        let jwtResult = await webAuth.jwtToken(
            forUserAccount: clientKeyPair.accountId,
            signers: [clientKeyPair],
            homeDomain: "other-domain.com"
        )

        // The challenge is built with our mock domain so validation of homeDomain
        // against the challenge's first ManageData key will use "place.domain.com auth".
        // Since the WebAuthenticator's serverHomeDomain is "place.domain.com", this passes.
        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"))
        case .failure(let error):
            XCTFail("Home domain override authentication failed: \(error)")
        }
    }

    // MARK: - Snippet 11: Error handling

    func testErrorHandlingValidationErrors() async {
        // Test that specific validation errors are correctly reported.
        // We build a challenge with a non-zero sequence number to trigger sequenceNumberNot0.
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientPrivateKey)

        // Custom mock that returns an invalid challenge (non-zero sequence number)
        let invalidChallengeHandler: MockHandler = { [self] mock, request in
            mock.statusCode = 200
            let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: 123) // NOT -1

            let timeBounds = TimeBounds(
                minTime: UInt64(Date().timeIntervalSince1970),
                maxTime: UInt64(Date().timeIntervalSince1970 + 300)
            )

            let operation = ManageDataOperation(
                sourceAccountId: clientKeyPair.accountId,
                name: self.domain + " auth",
                data: "nonce".data(using: .utf8)
            )

            let preconditions = TransactionPreconditions(timeBounds: timeBounds)
            let transaction = try! Transaction(
                sourceAccount: transactionAccount,
                operations: [operation],
                memo: Memo.none,
                preconditions: preconditions
            )
            try! transaction.sign(keyPair: serverKeyPair, network: .testnet)

            return "{\"transaction\": \"\(try! transaction.encodedEnvelope())\"}"
        }

        let challengeMock = RequestMock(
            host: "api.stellar.org",
            path: "/auth",
            httpMethod: "GET",
            mockHandler: invalidChallengeHandler
        )
        ServerMock.add(mock: challengeMock)

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        let jwtResult = await webAuth.jwtToken(
            forUserAccount: clientKeyPair.accountId,
            signers: [clientKeyPair]
        )

        switch jwtResult {
        case .success:
            XCTFail("Should have failed with sequenceNumberNot0")
        case .failure(let error):
            switch error {
            case .validationErrorError(let validationError):
                XCTAssertEqual(validationError, .sequenceNumberNot0,
                               "Expected sequenceNumberNot0 but got \(validationError)")
            default:
                XCTFail("Expected validationErrorError, got: \(error)")
            }
        }
    }

    // MARK: - Snippet 12: Retry logic (tests the concept, not actual retries)

    func testRetryLogicConcept() async {
        // This tests that the retry logic function pattern from the docs compiles
        // and works with a successful first attempt.
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientPrivateKey)

        registerChallengeMock(serverKeyPair: serverKeyPair)
        registerSendChallengeMock(validClientPublicKeys: [clientPublicKey])

        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        // Use the retry pattern from the documentation
        let result = await authenticateWithRetry(
            webAuth: webAuth,
            accountId: clientKeyPair.accountId,
            signers: [clientKeyPair]
        )

        switch result {
        case .success(let jwtToken):
            XCTAssertTrue(jwtToken.hasPrefix("eyJ"))
        case .failure(let error):
            XCTFail("Retry logic test failed: \(error)")
        }
    }

    // MARK: - Snippet 13: Test mock pattern (building challenge manually)

    func testBuildChallengeManually() throws {
        // Verifies the mock testing pattern from the documentation:
        // manually building a challenge and validating it.
        let serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
        let clientKeyPair = try! KeyPair(secretSeed: clientPrivateKey)

        // Build challenge manually (as documented)
        let transactionAccount = Account(keyPair: serverKeyPair, sequenceNumber: -1)

        let timeBounds = TimeBounds(
            minTime: UInt64(Date().timeIntervalSince1970),
            maxTime: UInt64(Date().timeIntervalSince1970 + 300)
        )

        let authOp = ManageDataOperation(
            sourceAccountId: clientKeyPair.accountId,
            name: domain + " auth",
            data: "nonce_data_here".data(using: .utf8)
        )

        let webAuthDomainOp = ManageDataOperation(
            sourceAccountId: serverKeyPair.accountId,
            name: "web_auth_domain",
            data: "api.stellar.org".data(using: .utf8)
        )

        let preconditions = TransactionPreconditions(timeBounds: timeBounds)
        let transaction = try Transaction(
            sourceAccount: transactionAccount,
            operations: [authOp, webAuthDomainOp],
            memo: Memo.none,
            preconditions: preconditions
        )
        try transaction.sign(keyPair: serverKeyPair, network: .testnet)
        let challengeXdr = try transaction.encodedEnvelope()

        // Validate the challenge using WebAuthenticator
        let webAuth = WebAuthenticator(
            authEndpoint: authServer,
            network: .testnet,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: domain
        )

        let transactionEnvelope = try TransactionEnvelopeXDR(xdr: challengeXdr)
        let validationResult = webAuth.isValidChallenge(
            transactionEnvelopeXDR: transactionEnvelope,
            userAccountId: clientKeyPair.accountId,
            memo: nil,
            serverSigningKey: serverPublicKey,
            clientDomainAccount: nil,
            timeBoundsGracePeriod: 300
        )

        switch validationResult {
        case .success:
            break // Expected
        case .failure(let error):
            XCTFail("Challenge validation failed: \(error)")
        }

        // Sign the challenge
        let signedXdr = webAuth.signTransaction(
            transactionEnvelopeXDR: transactionEnvelope,
            keyPairs: [clientKeyPair]
        )
        XCTAssertNotNil(signedXdr, "signTransaction should return non-nil signed XDR")
    }

    // MARK: - Helper: Retry logic (from documentation snippet 12)

    private func authenticateWithRetry(
        webAuth: WebAuthenticator,
        accountId: String,
        signers: [KeyPair],
        maxRetries: Int = 3
    ) async -> GetJWTTokenResponseEnum {
        var attempt = 0
        var lastResult: GetJWTTokenResponseEnum?

        while attempt < maxRetries {
            let result = await webAuth.jwtToken(forUserAccount: accountId, signers: signers)
            switch result {
            case .success:
                return result
            case .failure(let error):
                lastResult = result
                switch error {
                case .validationErrorError(.invalidTimeBounds):
                    attempt += 1
                case .requestError:
                    attempt += 1
                    try? await Task.sleep(nanoseconds: UInt64(1 << attempt) * 1_000_000_000)
                default:
                    return result
                }
            }
        }

        return lastResult ?? .failure(error: .signingError)
    }
}
