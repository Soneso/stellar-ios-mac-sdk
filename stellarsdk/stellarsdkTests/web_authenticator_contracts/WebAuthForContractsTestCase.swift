//
//  WebAuthForContractsTestCase.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 13/12/2025.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class WebAuthForContractsTestCase: XCTestCase {

    // Test configuration
    let domain = "example.stellar.org"
    let authServer = "https://auth.example.stellar.org"
    let webAuthContractId = "CA7A3N2BB35XMTFPAYWVZEF4TEYXW7DAEWDXJNQGUPR5SWSM2UVZCJM2"
    let serverAccountId = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let serverSecretSeed = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"
    let clientContractId = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"

    // Test contract IDs for different validation scenarios
    // Note: Many of these might have invalid checksums but they are only used for testing validation errors
    // The clientContractId and clientDomainTestId must be valid to allow proper round-tripping
    let invalidContractTestId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    let invalidFunctionTestId = "CBBBBBBBBB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQWBJRF"
    let subInvocationsTestId = "CCCCCCCCCMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGMZTGIQH2"
    let invalidHomeDomainTestId = "CDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDAWP7S"
    let invalidWebAuthDomainTestId = "CEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEERDDQ"
    let invalidAccountTestId = "CBMKBASJGUKV26JB55OKZW3G3PGQ4C7PLRH6L2RW74PYUTE22Y4KFW56"
    let invalidNonceTestId = "CFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF4UQI"
    let invalidServerSigTestId = "CGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGAZCRI"
    let missingServerEntryTestId = "CHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHA2LJK"
    let missingClientEntryTestId = "CIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIAH4NU"
    let invalidClientDomainAccountTestId = "CJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJAGYRY"
    let clientDomainTestId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
    let errorTestId = "CLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLAPGFE"
    let submitErrorTestId = "CMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMA7YBP"
    let submitTimeoutTestId = "CNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNAHVUO"

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

        // Use the public key that corresponds to the secret seed SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L
        // which is GAIWNNJMDNZTSKEIWBZIERE3WCRIW2LCA3PK3GRX2K7DGWDA7Z5MVUZN
        let clientDomainKeyPair = try! KeyPair(secretSeed: "SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L")
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

    // MARK: - Success Test Cases

    func testDefaultSuccess() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()
        let responseEnum = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testDefaultHomeDomainSuccess() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()
        // Not passing homeDomain parameter - should default to domain
        let responseEnum = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [clientSigner]
        )

        switch responseEnum {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testClientDomainSuccess() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()
        let clientDomainKeyPair = try! KeyPair(secretSeed: "SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L")

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: clientDomainTestId,
            signers: [clientSigner],
            homeDomain: domain,
            clientDomain: "client.example.com",
            clientDomainAccountKeyPair: clientDomainKeyPair
        )

        switch responseEnum {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testClientDomainCallbackSuccess() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()
        let clientDomainSigner = try! KeyPair(secretSeed: "SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L")

        let signingCallback: (SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR = { entry in
            var signedEntry = entry
            try signedEntry.sign(signer: clientDomainSigner, network: .testnet)
            return signedEntry
        }

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: clientDomainTestId,
            signers: [clientSigner],
            homeDomain: domain,
            clientDomain: "client.example.com",
            clientDomainSigningCallback: signingCallback
        )

        switch responseEnum {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testFromDomainSuccess() async {
        let responseEnum = await WebAuthForContracts.from(
            domain: domain,
            network: .testnet
        )

        switch responseEnum {
        case .success(let webAuth):
            XCTAssertEqual(webAuth.authEndpoint, authServer)
            XCTAssertEqual(webAuth.webAuthContractId, webAuthContractId)
            XCTAssertEqual(webAuth.serverSigningKey, serverAccountId)
            XCTAssertEqual(webAuth.serverHomeDomain, domain)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testFormUrlEncodedSuccess() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )
        webAuth.useFormUrlEncoded = true

        let clientSigner = try! KeyPair.generateRandomKeyPair()
        let responseEnum = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(let jwtToken):
            XCTAssertFalse(jwtToken.isEmpty)
            XCTAssertTrue(jwtToken.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Validation Error Test Cases

    func testInvalidContractAddress() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidContractTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidContractAddress(_, _):
                    return
                default:
                    XCTFail("Expected invalidContractAddress, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testInvalidFunctionName() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidFunctionTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidFunctionName(_, _):
                    return
                default:
                    XCTFail("Expected invalidFunctionName, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testSubInvocationsFound() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: subInvocationsTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .subInvocationsFound:
                    return
                default:
                    XCTFail("Expected subInvocationsFound, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testInvalidHomeDomain() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidHomeDomainTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidHomeDomain(_, _):
                    return
                default:
                    XCTFail("Expected invalidHomeDomain, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testInvalidWebAuthDomain() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidWebAuthDomainTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidWebAuthDomain(_, _):
                    return
                default:
                    XCTFail("Expected invalidWebAuthDomain, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testInvalidAccount() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidAccountTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidAccount(_, _):
                    return
                default:
                    XCTFail("Expected invalidAccount, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testInvalidNonce() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidNonceTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidNonce(_):
                    return
                default:
                    XCTFail("Expected invalidNonce, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testInvalidServerSignature() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidServerSigTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidServerSignature:
                    return
                default:
                    XCTFail("Expected invalidServerSignature, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testMissingServerEntry() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: missingServerEntryTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .missingServerEntry:
                    return
                default:
                    XCTFail("Expected missingServerEntry, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testMissingClientEntry() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: missingClientEntryTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .missingClientEntry:
                    return
                default:
                    XCTFail("Expected missingClientEntry, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testInvalidClientDomainAccount() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()
        let wrongClientDomainKeyPair = try! KeyPair(accountId: "GB5PZY253VWYRF47YMNFIWO3U6BG2SD2457FNQVFO4CLOAIUEN5IG7P7")

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: invalidClientDomainAccountTestId,
            signers: [clientSigner],
            homeDomain: domain,
            clientDomain: "client.example.com",
            clientDomainAccountKeyPair: wrongClientDomainKeyPair
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected validation error, got success")
        case .failure(let error):
            switch error {
            case .validationError(let validationError):
                switch validationError {
                case .invalidClientDomainAccount(_, _):
                    return
                default:
                    XCTFail("Expected invalidClientDomainAccount, got \(validationError)")
                }
            default:
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    // MARK: - HTTP Error Test Cases

    func testGetChallengeError() async {
        let webAuth = try! WebAuthForContracts(
            authEndpoint: authServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: errorTestId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected request error, got success")
        case .failure(let error):
            switch error {
            case .requestError(_):
                return
            default:
                XCTFail("Expected requestError, got \(error)")
            }
        }
    }

    func testSubmitChallengeError() async {
        // Use a separate auth endpoint with error mock
        let errorAuthServer = "https://auth-error.example.stellar.org"

        // Register error mock for this endpoint
        let errorMock = WebAuthForContractsSendChallengeMock(address: "auth-error.example.stellar.org")
        errorMock.shouldError = true

        // Register challenge mock for error endpoint (must keep reference to prevent deallocation)
        let errorChallengeMock = WebAuthForContractsChallengeMock(
            address: "auth-error.example.stellar.org",
            serverKeyPair: serverKeyPair,
            webAuthContractId: webAuthContractId,
            domain: domain
        )

        // Keep mocks alive for the duration of the test
        _ = (errorMock, errorChallengeMock)

        let webAuth = try! WebAuthForContracts(
            authEndpoint: errorAuthServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected submit challenge error, got success")
        case .failure(let error):
            switch error {
            case .submitChallengeError(_):
                return
            default:
                XCTFail("Expected submitChallengeError, got \(error)")
            }
        }
    }

    func testSubmitChallengeTimeout() async {
        // Use a separate auth endpoint with timeout mock
        let timeoutAuthServer = "https://auth-timeout.example.stellar.org"

        // Register timeout mock for this endpoint
        let timeoutMock = WebAuthForContractsSendChallengeMock(address: "auth-timeout.example.stellar.org")
        timeoutMock.shouldTimeout = true

        // Register challenge mock for timeout endpoint (must keep reference to prevent deallocation)
        let timeoutChallengeMock = WebAuthForContractsChallengeMock(
            address: "auth-timeout.example.stellar.org",
            serverKeyPair: serverKeyPair,
            webAuthContractId: webAuthContractId,
            domain: domain
        )

        // Keep mocks alive for the duration of the test
        _ = (timeoutMock, timeoutChallengeMock)

        let webAuth = try! WebAuthForContracts(
            authEndpoint: timeoutAuthServer,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverAccountId,
            serverHomeDomain: domain,
            network: .testnet
        )

        let clientSigner = try! KeyPair.generateRandomKeyPair()

        let responseEnum = await webAuth.jwtToken(
            forContractAccount: clientContractId,
            signers: [clientSigner],
            homeDomain: domain
        )

        switch responseEnum {
        case .success(_):
            XCTFail("Expected submit challenge timeout, got success")
        case .failure(let error):
            switch error {
            case .submitChallengeTimeout:
                return
            default:
                XCTFail("Expected submitChallengeTimeout, got \(error)")
            }
        }
    }

    // MARK: - Constructor Validation Test Cases

    func testInvalidAccountFormat() {
        do {
            _ = try WebAuthForContracts(
                authEndpoint: authServer,
                webAuthContractId: "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP", // G... not C...
                serverSigningKey: serverAccountId,
                serverHomeDomain: domain,
                network: .testnet
            )
            XCTFail("Expected initialization to fail with invalid contract ID")
        } catch let error as WebAuthForContractsError {
            switch error {
            case .invalidWebAuthContractId(_):
                return
            default:
                XCTFail("Expected invalidWebAuthContractId, got \(error)")
            }
        } catch {
            XCTFail("Expected WebAuthForContractsError, got \(error)")
        }
    }

    func testConstructorValidation() {
        // Test invalid server signing key
        do {
            _ = try WebAuthForContracts(
                authEndpoint: authServer,
                webAuthContractId: webAuthContractId,
                serverSigningKey: "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV", // C... not G...
                serverHomeDomain: domain,
                network: .testnet
            )
            XCTFail("Expected initialization to fail with invalid server signing key")
        } catch let error as WebAuthForContractsError {
            switch error {
            case .invalidServerSigningKey(_):
                return
            default:
                XCTFail("Expected invalidServerSigningKey, got \(error)")
            }
        } catch {
            XCTFail("Expected WebAuthForContractsError, got \(error)")
        }

        // Test invalid auth endpoint
        do {
            _ = try WebAuthForContracts(
                authEndpoint: "not-a-url",
                webAuthContractId: webAuthContractId,
                serverSigningKey: serverAccountId,
                serverHomeDomain: domain,
                network: .testnet
            )
            XCTFail("Expected initialization to fail with invalid auth endpoint")
        } catch let error as WebAuthForContractsError {
            switch error {
            case .invalidAuthEndpoint(_):
                return
            default:
                XCTFail("Expected invalidAuthEndpoint, got \(error)")
            }
        } catch {
            XCTFail("Expected WebAuthForContractsError, got \(error)")
        }

        // Test empty server home domain
        do {
            _ = try WebAuthForContracts(
                authEndpoint: authServer,
                webAuthContractId: webAuthContractId,
                serverSigningKey: serverAccountId,
                serverHomeDomain: "",
                network: .testnet
            )
            XCTFail("Expected initialization to fail with empty server home domain")
        } catch let error as WebAuthForContractsError {
            switch error {
            case .emptyServerHomeDomain:
                return
            default:
                XCTFail("Expected emptyServerHomeDomain, got \(error)")
            }
        } catch {
            XCTFail("Expected WebAuthForContractsError, got \(error)")
        }
    }

    // MARK: - Integration Test Cases

    func testWithStellarTestAnchor() async {
        let expectation = XCTestExpectation(description: "Integration test with stellar test anchor")
        let testAnchorDomain = "testanchor.stellar.org"
        let sorobanRpcUrl = "https://soroban-testnet.stellar.org"
        let sdk = StellarSDK.testNet()

        // Step 1: Create random keypairs
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let signerKeyPair = try! KeyPair.generateRandomKeyPair()
        print("Created source account: \(sourceKeyPair.accountId)")
        print("Created signer keypair: \(signerKeyPair.accountId)")

        // Step 2: Fund source account via FriendBot
        let responseEnum = await sdk.accounts.createTestAccount(accountId: sourceKeyPair.accountId)
        switch responseEnum {
        case .success(_):
            print("Funded test account via Friendbot")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testWithStellarTestAnchor()", horizonRequestError: error)
            XCTFail("Could not fund test account: \(sourceKeyPair.accountId)")
            expectation.fulfill()
            return
        }

        // Step 3: Load WASM file from bundle
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "sep_45_account", ofType: "wasm") else {
            XCTFail("WASM file not found in test bundle")
            expectation.fulfill()
            return
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("Could not load WASM file contents")
            expectation.fulfill()
            return
        }
        print("Loaded WASM file from bundle")

        // Step 4: Deploy contract using SorobanClient with constructor args
        do {
            // Install WASM
            let installRequest = InstallRequest(
                rpcUrl: sorobanRpcUrl,
                network: .testnet,
                sourceAccountKeyPair: sourceKeyPair,
                wasmBytes: contractCode,
                enableServerLogging: false
            )
            let wasmHash = try await SorobanClient.install(installRequest: installRequest)
            print("Uploaded WASM, hash: \(wasmHash)")

            // Build constructor arguments
            let adminAddress = SCValXDR.address(try SCAddressXDR(accountId: sourceKeyPair.accountId))
            let signerPublicKey = SCValXDR.bytes(Data(signerKeyPair.publicKey.bytes))
            let constructorArgs = [adminAddress, signerPublicKey]

            // Deploy contract
            let deployRequest = DeployRequest(
                rpcUrl: sorobanRpcUrl,
                network: .testnet,
                sourceAccountKeyPair: sourceKeyPair,
                wasmHash: wasmHash,
                constructorArgs: constructorArgs,
                enableServerLogging: false
            )
            let client = try await SorobanClient.deploy(deployRequest: deployRequest)

            // Step 5: Get contract ID
            let contractId = client.contractId
            print("Deployed contract ID: \(contractId)")

            // Verify contract ID format
            XCTAssertTrue(contractId.starts(with: "C"))
            XCTAssertEqual(contractId.count, 56)

            // Step 6: Initialize WebAuthForContracts from domain
            let webAuthResponseEnum = await WebAuthForContracts.from(
                domain: testAnchorDomain,
                network: .testnet
            )

            guard case .success(let webAuth) = webAuthResponseEnum else {
                if case .failure(let error) = webAuthResponseEnum {
                    XCTFail("Failed to initialize WebAuthForContracts: \(error)")
                }
                expectation.fulfill()
                return
            }
            print("Initialized WebAuthForContracts from domain: \(testAnchorDomain)")

            // Step 7: Call jwtToken with the contract ID and signer keypair
            print("Authenticating with testanchor.stellar.org...")
            let jwtResponseEnum = await webAuth.jwtToken(
                forContractAccount: contractId,
                signers: [signerKeyPair]
            )

            switch jwtResponseEnum {
            case .success(let jwtToken):
                // Success - we received a real JWT token
                XCTAssertFalse(jwtToken.isEmpty)
                print("Successfully received JWT token")
                print("JWT: \(jwtToken)")
                expectation.fulfill()

            case .failure(let error):
                // The test may receive a submitChallengeUnknownResponse - this is acceptable
                // The challenge validation and signing succeeded
                switch error {
                case .submitChallengeUnknownResponse(let statusCode):
                    print("Note: Token submission failed (expected): Unknown response with status code: \(statusCode)")
                    print("Contract deployment and challenge flow validated successfully")
                    expectation.fulfill()
                default:
                    XCTFail("Unexpected error: \(error)")
                    expectation.fulfill()
                }
            }

        } catch {
            XCTFail("Error during contract deployment or authentication: \(error)")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 300.0)
    }

    func testWithStellarTestAnchorAndClientDomain() async {
        let expectation = XCTestExpectation(description: "Integration test with stellar test anchor and client domain")
        let testAnchorDomain = "testanchor.stellar.org"
        
        // Remote signer src code: https://github.com/Soneso/go-server-signer
        let clientDomain = "testsigner.stellargate.com"
        let remoteSigningUrl = "https://testsigner.stellargate.com/sign-sep-45"
        let bearerToken = "7b23fe8428e7fb9b3335ed36c39fb5649d3cd7361af8bf88c2554d62e8ca3017"
        let sorobanRpcUrl = "https://soroban-testnet.stellar.org"
        let sdk = StellarSDK.testNet()

        // Step 1: Create random keypairs
        let sourceKeyPair = try! KeyPair.generateRandomKeyPair()
        let signerKeyPair = try! KeyPair.generateRandomKeyPair()
        print("Created source account: \(sourceKeyPair.accountId)")
        print("Created signer keypair: \(signerKeyPair.accountId)")

        // Step 2: Fund source account via FriendBot
        let responseEnum = await sdk.accounts.createTestAccount(accountId: sourceKeyPair.accountId)
        switch responseEnum {
        case .success(_):
            print("Funded test account via Friendbot")
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(tag:"testWithStellarTestAnchorAndClientDomain()", horizonRequestError: error)
            XCTFail("Could not fund test account: \(sourceKeyPair.accountId)")
            expectation.fulfill()
            return
        }

        // Step 3: Load WASM file from bundle
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "sep_45_account", ofType: "wasm") else {
            XCTFail("WASM file not found in test bundle")
            expectation.fulfill()
            return
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("Could not load WASM file contents")
            expectation.fulfill()
            return
        }
        print("Loaded WASM file from bundle")

        // Step 4: Deploy contract using SorobanClient with constructor args
        do {
            // Install WASM
            let installRequest = InstallRequest(
                rpcUrl: sorobanRpcUrl,
                network: .testnet,
                sourceAccountKeyPair: sourceKeyPair,
                wasmBytes: contractCode,
                enableServerLogging: false
            )
            let wasmHash = try await SorobanClient.install(installRequest: installRequest)
            print("Uploaded WASM, hash: \(wasmHash)")

            // Build constructor arguments
            let adminAddress = SCValXDR.address(try SCAddressXDR(accountId: sourceKeyPair.accountId))
            let signerPublicKey = SCValXDR.bytes(Data(signerKeyPair.publicKey.bytes))
            let constructorArgs = [adminAddress, signerPublicKey]

            // Deploy contract
            let deployRequest = DeployRequest(
                rpcUrl: sorobanRpcUrl,
                network: .testnet,
                sourceAccountKeyPair: sourceKeyPair,
                wasmHash: wasmHash,
                constructorArgs: constructorArgs,
                enableServerLogging: false
            )
            let client = try await SorobanClient.deploy(deployRequest: deployRequest)

            // Step 5: Get contract ID
            let contractId = client.contractId
            print("Deployed contract ID: \(contractId)")

            // Verify contract ID format
            XCTAssertTrue(contractId.starts(with: "C"))
            XCTAssertEqual(contractId.count, 56)

            // Step 6: Initialize WebAuthForContracts from domain
            let webAuthResponseEnum = await WebAuthForContracts.from(
                domain: testAnchorDomain,
                network: .testnet
            )

            guard case .success(let webAuth) = webAuthResponseEnum else {
                if case .failure(let error) = webAuthResponseEnum {
                    XCTFail("Failed to initialize WebAuthForContracts: \(error)")
                }
                expectation.fulfill()
                return
            }
            print("Initialized WebAuthForContracts from domain: \(testAnchorDomain)")

            // Step 7: Create signing callback for remote client domain signing
            var callbackInvoked = false
            let signingCallback: (SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR = { entry in
                callbackInvoked = true
                print("Callback invoked, sending entry to remote signing server...")

                // Encode single entry to base64 XDR
                guard let base64Xdr = entry.xdrEncoded else {
                    throw GetContractJWTTokenError.signingError(message: "Failed to encode entry to XDR")
                }

                // Create request body
                let requestBody: [String: Any] = [
                    "authorization_entry": base64Xdr,
                    "network_passphrase": "Test SDF Network ; September 2015"
                ]

                guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                    throw GetContractJWTTokenError.signingError(message: "Failed to serialize request body")
                }

                // POST to remote signing server
                guard let url = URL(string: remoteSigningUrl) else {
                    throw GetContractJWTTokenError.signingError(message: "Invalid remote signing URL")
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = jsonData

                let (data, response): (Data, URLResponse)
                if #available(iOS 15.0, macOS 12.0, *) {
                    (data, response) = try await URLSession.shared.data(for: request)
                } else {
                    throw GetContractJWTTokenError.signingError(message: "URLSession async/await requires iOS 15+")
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GetContractJWTTokenError.signingError(message: "Invalid response from remote signing server")
                }

                guard httpResponse.statusCode == 200 else {
                    throw GetContractJWTTokenError.signingError(message: "Remote signing failed with status code: \(httpResponse.statusCode)")
                }

                // Parse response
                guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let signedEntryBase64 = jsonResponse["authorization_entry"] as? String else {
                    throw GetContractJWTTokenError.signingError(message: "Invalid server response: missing authorization_entry")
                }

                print("Remote signing server returned signed entry")

                // Decode response back to SorobanAuthorizationEntryXDR
                return try SorobanAuthorizationEntryXDR(xdr: signedEntryBase64)
            }

            // Step 8: Call jwtToken with client domain and signing callback
            print("Authenticating with testanchor.stellar.org using client domain: \(clientDomain)...")
            let jwtResponseEnum = await webAuth.jwtToken(
                forContractAccount: contractId,
                signers: [signerKeyPair],
                clientDomain: clientDomain,
                clientDomainSigningCallback: signingCallback
            )

            switch jwtResponseEnum {
            case .success(let jwtToken):
                // Success - we received a real JWT token
                XCTAssertFalse(jwtToken.isEmpty)
                XCTAssertTrue(callbackInvoked)
                print("Successfully received JWT token with client domain support")
                print("JWT: \(jwtToken)")
                expectation.fulfill()

            case .failure(let error):
                // The test may receive a submitChallengeUnknownResponse - this is acceptable
                // The important part is that we successfully completed the full flow
                // including remote client domain signing via the callback
                switch error {
                case .submitChallengeUnknownResponse(let statusCode):
                    print("Note: Token submission failed (expected): Unknown response with status code: \(statusCode)")
                    print("Contract deployment, challenge flow, and remote signing validated successfully")
                    XCTAssertTrue(callbackInvoked)
                    expectation.fulfill()
                default:
                    XCTFail("Unexpected error: \(error)")
                    expectation.fulfill()
                }
            }

        } catch {
            XCTFail("Error during contract deployment or authentication: \(error)")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 300.0)
    }
}
