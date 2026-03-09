//
//  Sep45DocTest.swift
//  stellarsdkIntegrationTests
//
//  Tests for SEP-45 documentation code examples.
//  Uses the existing ServerMock/RequestMock/ResponsesMock infrastructure
//  with mock HTTP responses for the stellar.toml, challenge, and submit endpoints.
//

import XCTest
import stellarsdk

class Sep45DocTest: XCTestCase {

    // Test configuration — mirrors WebAuthForContractsTestCase values
    let domain = "example.stellar.org"
    let authServer = "https://auth.example.stellar.org"
    let webAuthContractId = "CA7A3N2BB35XMTFPAYWVZEF4TEYXW7DAEWDXJNQGUPR5SWSM2UVZCJM2"
    let serverAccountId = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let serverSecretSeed = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"
    let clientContractId = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"
    let clientDomainTestId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
    let clientDomainSecretSeed = "SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L"

    var tomlServerMock: WebAuthForContractsTomlMock!
    var clientDomainTomlMock: WebAuthForContractsClientDomainTomlMock!
    var challengeServerMock: WebAuthForContractsChallengeMock!
    var sendChallengeServerMock: WebAuthForContractsSendChallengeMock!
    var serverKeyPair: KeyPair!

    override func setUp() {
        URLProtocol.registerClass(ServerMock.self)

        serverKeyPair = try! KeyPair(secretSeed: serverSecretSeed)

        tomlServerMock = WebAuthForContractsTomlMock(
            address: domain,
            serverSigningKey: serverAccountId,
            authServer: authServer,
            webAuthContractId: webAuthContractId
        )

        let clientDomainKeyPair = try! KeyPair(secretSeed: clientDomainSecretSeed)
        clientDomainTomlMock = WebAuthForContractsClientDomainTomlMock(
            address: "client.example.com",
            serverSigningKey: clientDomainKeyPair.accountId
        )

        challengeServerMock = WebAuthForContractsChallengeMock(
            address: "auth.example.stellar.org",
            serverKeyPair: serverKeyPair,
            webAuthContractId: webAuthContractId,
            domain: domain
        )

        sendChallengeServerMock = WebAuthForContractsSendChallengeMock(
            address: "auth.example.stellar.org"
        )
    }

    // MARK: - Quick example (Snippet 1)

    func testQuickExample() async {
        // Mirrors: Quick example — fromDomain + jwtToken one-liner
        let authResult = await WebAuthForContracts.from(domain: domain, network: Network.testnet)
        switch authResult {
        case .success(let webAuth):
            let signer = try! KeyPair.generateRandomKeyPair()
            let jwtResult = await webAuth.jwtToken(
                forContractAccount: clientContractId,
                signers: [signer]
            )
            switch jwtResult {
            case .success(let jwtToken):
                XCTAssertFalse(jwtToken.isEmpty)
                XCTAssertTrue(jwtToken.starts(with: "eyJ"))
            case .failure(let error):
                XCTFail("jwtToken failed: \(error)")
            }
        case .failure(let error):
            XCTFail("from(domain:) failed: \(error)")
        }
    }

    // MARK: - From stellar.toml (Snippet 2)

    func testFromStellarToml() async {
        let authResult = await WebAuthForContracts.from(domain: domain, network: Network.testnet)
        switch authResult {
        case .success(let webAuth):
            XCTAssertEqual(webAuth.authEndpoint, authServer)
            XCTAssertEqual(webAuth.webAuthContractId, webAuthContractId)
            XCTAssertEqual(webAuth.serverSigningKey, serverAccountId)
        case .failure(let error):
            XCTFail("from(domain:) failed: \(error)")
        }
    }

    // MARK: - Manual configuration (Snippet 3)

    func testManualConfiguration() {
        do {
            let webAuth = try WebAuthForContracts(
                authEndpoint: authServer,
                webAuthContractId: webAuthContractId,
                serverSigningKey: serverAccountId,
                serverHomeDomain: domain,
                network: Network.testnet
            )
            XCTAssertEqual(webAuth.authEndpoint, authServer)
            XCTAssertEqual(webAuth.webAuthContractId, webAuthContractId)
            XCTAssertEqual(webAuth.serverSigningKey, serverAccountId)
            XCTAssertEqual(webAuth.serverHomeDomain, domain)
        } catch {
            XCTFail("Constructor threw: \(error)")
        }
    }

    // MARK: - Custom Soroban RPC URL (Snippet 4)

    func testCustomSorobanRpcUrl() {
        do {
            let customRpc = "https://your-custom-rpc.example.com"
            let webAuth = try WebAuthForContracts(
                authEndpoint: authServer,
                webAuthContractId: webAuthContractId,
                serverSigningKey: serverAccountId,
                serverHomeDomain: domain,
                network: Network.testnet,
                sorobanRpcUrl: customRpc
            )
            XCTAssertEqual(webAuth.sorobanRpcUrl, customRpc)
        } catch {
            XCTFail("Constructor threw: \(error)")
        }
    }

    // MARK: - Basic authentication (Snippet 5)

    func testBasicAuthentication() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let signer = try! KeyPair.generateRandomKeyPair()
        let jwtResult = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [signer]
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("jwtToken failed: \(error)")
        }
    }

    // MARK: - Automatic expiration (Snippet 6)

    func testAutomaticExpiration() async {
        // Same as basic auth — expiration is auto-filled
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let signer = try! KeyPair.generateRandomKeyPair()
        let jwtResult = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [signer]
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
        case .failure(let error):
            XCTFail("jwtToken with auto-expiration failed: \(error)")
        }
    }

    // MARK: - Custom expiration (Snippet 7)

    func testCustomExpiration() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let signer = try! KeyPair.generateRandomKeyPair()
        let jwtResult = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [signer],
            signatureExpirationLedger: 1500000
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
        case .failure(let error):
            XCTFail("jwtToken with custom expiration failed: \(error)")
        }
    }

    // MARK: - Contracts without signature requirements (Snippet 8)

    func testNoSignatureRequired() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        // Empty signers list — no signatures will be added
        let jwtResult = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: []
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
        case .failure(let error):
            XCTFail("jwtToken with empty signers failed: \(error)")
        }
    }

    // MARK: - Client domain verification — local signing (Snippet 9)

    func testClientDomainLocalSigning() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let signer = try! KeyPair.generateRandomKeyPair()
        let clientDomainKeyPair = try! KeyPair(secretSeed: clientDomainSecretSeed)

        let jwtResult = await webAuth.jwtToken(
            forContractAccount: clientDomainTestId,
            signers: [signer],
            homeDomain: domain,
            clientDomain: "client.example.com",
            clientDomainAccountKeyPair: clientDomainKeyPair
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Client domain local signing failed: \(error)")
        }
    }

    // MARK: - Client domain verification — remote signing callback (Snippet 10)

    func testClientDomainCallbackSigning() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let signer = try! KeyPair.generateRandomKeyPair()
        let clientDomainSigner = try! KeyPair(secretSeed: clientDomainSecretSeed)

        let signingCallback: (SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR = { entry in
            // Simulate remote signing — sign locally in the callback
            var signedEntry = entry
            try signedEntry.sign(signer: clientDomainSigner, network: .testnet)
            return signedEntry
        }

        let jwtResult = await webAuth.jwtToken(
            forContractAccount: clientDomainTestId,
            signers: [signer],
            homeDomain: domain,
            clientDomain: "client.example.com",
            clientDomainSigningCallback: signingCallback
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Client domain callback signing failed: \(error)")
        }
    }

    // MARK: - Step-by-step authentication (Snippet 11)

    func testStepByStepAuthentication() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let signerKeyPair = try! KeyPair.generateRandomKeyPair()

        // Step 1: Get challenge from server
        let challengeResponse = await webAuth.getChallenge(
            forContractAccount: clientContractId,
            homeDomain: domain
        )

        switch challengeResponse {
        case .success(let response):
            do {
                // Step 2: Decode authorization entries from base64 XDR
                let authEntries = try webAuth.decodeAuthorizationEntries(base64Xdr: response.authorizationEntries)
                XCTAssertFalse(authEntries.isEmpty)

                // Step 3: Validate challenge (security checks)
                try webAuth.validateChallenge(
                    authEntries: authEntries,
                    clientAccountId: clientContractId,
                    homeDomain: domain
                )

                // Step 4: Use a fixed expiration ledger (no Soroban RPC needed in mock)
                let expirationLedger: UInt32 = 1500000

                // Step 5: Sign authorization entries
                let signedEntries = try await webAuth.signAuthorizationEntries(
                    authEntries: authEntries,
                    clientAccountId: clientContractId,
                    signers: [signerKeyPair],
                    signatureExpirationLedger: expirationLedger,
                    clientDomainKeyPair: nil,
                    clientDomainAccountId: nil,
                    clientDomainSigningCallback: nil
                )
                XCTAssertEqual(signedEntries.count, authEntries.count)

                // Step 6: Submit signed entries for JWT token
                let submitResult = await webAuth.sendSignedChallenge(signedEntries: signedEntries)
                switch submitResult {
                case .success(let jwtToken):
                    XCTAssertFalse(jwtToken.isEmpty)
                    XCTAssertTrue(jwtToken.starts(with: "eyJ"))
                case .failure(let error):
                    XCTFail("sendSignedChallenge failed: \(error)")
                }
            } catch {
                XCTFail("Step-by-step error: \(error)")
            }
        case .failure(let error):
            XCTFail("getChallenge failed: \(error)")
        }
    }

    // MARK: - Request format configuration (Snippet 12)

    func testJsonRequestFormat() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        // Use JSON format instead of form-urlencoded
        webAuth.useFormUrlEncoded = false

        let signer = try! KeyPair.generateRandomKeyPair()
        let jwtResult = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [signer]
        )

        switch jwtResult {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
        case .failure(let error):
            XCTFail("JSON format jwtToken failed: \(error)")
        }
    }

    // MARK: - Error handling (Snippet 13)

    func testErrorHandlingResultPattern() async {
        // Test that error types are correctly propagated through the result enum.
        // Use an invalid contract address (G... instead of C...) to trigger a parsing error.
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let signer = try! KeyPair.generateRandomKeyPair()

        // Pass a G... address instead of C... — triggers parsingError
        let jwtResult = await webAuth.jwtToken(
            forContractAccount: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP",
            signers: [signer]
        )

        switch jwtResult {
        case .success(_):
            XCTFail("Expected failure for G... account, got success")
        case .failure(let error):
            // Verify we get a proper error — should be parsingError about C... address
            switch error {
            case .parsingError(let message):
                XCTAssertTrue(message.contains("contract address"))
            default:
                // Any failure is acceptable here, the point is it didn't succeed
                break
            }
        }
    }

    // MARK: - Network support (Snippet 14 + 15)

    func testNetworkSupportTestnet() async {
        // Verify that testnet configuration works
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: Network.testnet
        )
        XCTAssertEqual(webAuth.sorobanRpcUrl, "https://soroban-testnet.stellar.org")
    }

    func testNetworkSupportPublic() {
        // Verify that public network sets the correct RPC URL
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: Network.public
        )
        XCTAssertEqual(webAuth.sorobanRpcUrl, "https://soroban.stellar.org")
    }

    // MARK: - Constructor validation

    func testConstructorValidatesWebAuthContractId() {
        // webAuthContractId must start with 'C'
        XCTAssertThrowsError(try WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: "GABC...",
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        ))
    }

    func testConstructorValidatesServerSigningKey() {
        // serverSigningKey must start with 'G'
        XCTAssertThrowsError(try WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: "CABC...",
            serverHomeDomain: domain,
            network: .testnet
        ))
    }

    func testConstructorValidatesEmptyHomeDomain() {
        // serverHomeDomain must not be empty
        XCTAssertThrowsError(try WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: "",
            network: .testnet
        ))
    }

    // MARK: - useFormUrlEncoded property

    func testUseFormUrlEncodedDefault() {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )
        XCTAssertTrue(webAuth.useFormUrlEncoded)
    }
}
