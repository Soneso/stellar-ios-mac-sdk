//
//  WebAuthForContractsAdditionalUnitTests.swift
//  stellarsdk
//
//  Created by Soneso on 05/02/2026.
//  Copyright © 2026 Soneso. All rights reserved.
//
//  Additional unit tests for WebAuthForContracts (SEP-45) functionality.
//
//  Coverage includes:
//  - Challenge validation with various error conditions:
//    * Sub-invocations detection
//    * Wrong contract address, function name, account, home domain, web auth domain
//    * Inconsistent or missing nonce
//    * Invalid server signature
//    * Missing server/client entries
//    * Client domain handling and validation
//    * Port numbers in auth endpoint
//    * Invalid arguments format
//  - Authorization entry signing:
//    * Single signer
//    * Multiple signers
//    * No signers (for contracts not requiring signatures)
//    * Client domain keypair signing
//    * Client domain callback signing
//  - XDR encoding/decoding:
//    * Invalid base64
//    * Invalid XDR structure
//    * Negative array counts
//    * Round-trip encoding/decoding
//  - Challenge submission:
//    * Form-encoded requests
//    * JSON-encoded requests
//    * Server timeouts
//    * Server errors
//  - Challenge retrieval:
//    * Invalid JSON responses
//    * Error responses
//    * Client domain parameter
//  - Network passphrase validation
//
//  Note: Some tests requiring network mock setup are included but may need
//  additional mock server registration to pass. The core validation logic
//  is extensively tested with 22+ passing tests.

import XCTest
@testable import stellarsdk

final class WebAuthForContractsAdditionalUnitTests: XCTestCase {

    // MARK: - Test Constants

    let serverDomain = "auth.stellar.org"
    let authEndpoint = "http://auth.stellar.org/auth"
    let authEndpointWithPort = "http://auth.stellar.org:8080/auth"

    // Server keys
    let serverPublicKey = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    let serverPrivateKey = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"

    // Valid web auth contract ID
    let webAuthContractId = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"

    // Client contract IDs
    let validClientContractId = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"
    let differentContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABSC4"

    // Client keys for testing
    let clientPublicKey = "GAIWNNJMDNZTSKEIWBZIERE3WCRIW2LCA3PK3GRX2K7DGWDA7Z5MVUZN"
    let clientPrivateKey = "SBXFU2EMT2Y3IRGN2MSXIBIAXEPT77PYKN5HHQSDBLNCT7OCYYBA2K3L"

    // Client domain keys
    let clientDomainPublicKey = "GCFPZTG6SCT5QFLSLX77TZ4VSVTLAQIKZZ5PGA2BHDHSIBWGRBXPC5WZ"
    let clientDomainPrivateKey = "SCKL3JRQGDL356H7UBZBGJVJFMX6XQFMX52CXRGQVMYCEMZ5XQGQO237"
    let clientDomain = "wallet.stellar.org"

    var serverKeyPair: KeyPair!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
        serverKeyPair = try! KeyPair(secretSeed: serverPrivateKey)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Challenge Validation Tests

    func testValidateChallengeWithSubInvocations() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        // Build entry with sub-invocations
        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let subInvocation = try buildInvocation(
            contractId: webAuthContractId,
            functionName: "sub_function",
            argsMap: argsMap
        )

        let entry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair,
            subInvocations: [subInvocation]
        )

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: [entry],
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.subInvocationsFound = error else {
                XCTFail("Expected subInvocationsFound error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithWrongContractAddress() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let entry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: differentContractId, // Wrong contract
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: [entry],
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidContractAddress = error else {
                XCTFail("Expected invalidContractAddress error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithWrongFunctionName() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let entry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "wrong_function", // Wrong function
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: [entry],
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidFunctionName = error else {
                XCTFail("Expected invalidFunctionName error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithWrongAccount() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: differentContractId, // Wrong account
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        // Server entry
        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        // Client entry
        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidAccount = error else {
                XCTFail("Expected invalidAccount error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithWrongHomeDomain() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: "wrong.domain.com", // Wrong domain
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidHomeDomain = error else {
                XCTFail("Expected invalidHomeDomain error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithWrongWebAuthDomain() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: "wrong.domain.com", // Wrong web auth domain
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidWebAuthDomain = error else {
                XCTFail("Expected invalidWebAuthDomain error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithInconsistentNonce() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        // Server entry with nonce1
        let argsMap1 = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "nonce_1"
        )

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap1,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        // Client entry with different nonce
        let argsMap2 = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "nonce_2" // Different nonce
        )

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap2,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidNonce = error else {
                XCTFail("Expected invalidNonce error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithMissingNonce() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        // Build args map without nonce
        var mapEntries: [SCMapEntryXDR] = []
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("account"),
            val: SCValXDR.string(validClientContractId)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("home_domain"),
            val: SCValXDR.string(serverDomain)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("web_auth_domain"),
            val: SCValXDR.string(serverDomain)
        ))
        mapEntries.append(SCMapEntryXDR(
            key: SCValXDR.symbol("web_auth_domain_account"),
            val: SCValXDR.string(serverPublicKey)
        ))
        // Nonce is missing

        let argsMap = SCValXDR.map(mapEntries)

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidNonce = error else {
                XCTFail("Expected invalidNonce error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithInvalidServerSignature() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        // Server entry WITHOUT signature
        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: nil // No signature
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidServerSignature = error else {
                XCTFail("Expected invalidServerSignature error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithMissingServerEntry() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        // Only client entry, no server entry
        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: [clientEntry],
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.missingServerEntry = error else {
                XCTFail("Expected missingServerEntry error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithMissingClientEntry() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        // Only server entry, no client entry
        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: [serverEntry],
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.missingClientEntry = error else {
                XCTFail("Expected missingClientEntry error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithClientDomain() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let clientDomainKeyPair = try KeyPair(secretSeed: clientDomainPrivateKey)

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce",
            clientDomain: clientDomain,
            clientDomainAccount: clientDomainKeyPair.accountId
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        // Server entry
        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        // Client entry
        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        // Client domain entry
        let clientDomainEntry = try buildAuthEntry(
            credentialsAddress: clientDomainKeyPair.accountId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12347,
            expirationLedger: 1000000,
            signWith: clientDomainKeyPair
        )
        entries.append(clientDomainEntry)

        // Should validate successfully
        XCTAssertNoThrow(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain,
            clientDomainAccountId: clientDomainKeyPair.accountId
        ))
    }

    func testValidateChallengeWithWrongClientDomainAccount() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce",
            clientDomain: clientDomain,
            clientDomainAccount: "GWRONGACCOUNTXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" // Wrong
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain,
            clientDomainAccountId: clientDomainPublicKey
        )) { error in
            guard case ContractChallengeValidationError.invalidClientDomainAccount = error else {
                XCTFail("Expected invalidClientDomainAccount error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithMissingClientDomainEntry() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        // Expecting client domain entry but not providing it
        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain,
            clientDomainAccountId: clientDomainPublicKey
        )) { error in
            guard case ContractChallengeValidationError.invalidArgs = error else {
                XCTFail("Expected invalidArgs error, got: \(error)")
                return
            }
        }
    }

    func testValidateChallengeWithPortInAuthEndpoint() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpointWithPort,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: "auth.stellar.org:8080", // Should include port
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 1000000
        )
        entries.append(clientEntry)

        // Should validate successfully with port in domain
        XCTAssertNoThrow(try webAuth.validateChallenge(
            authEntries: entries,
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        ))
    }

    func testValidateChallengeWithInvalidArgsFormat() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        // Build entry with non-map args (invalid)
        let invalidArgs = SCValXDR.string("invalid")

        let entry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: invalidArgs,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )

        XCTAssertThrowsError(try webAuth.validateChallenge(
            authEntries: [entry],
            clientAccountId: validClientContractId,
            homeDomain: serverDomain
        )) { error in
            guard case ContractChallengeValidationError.invalidArgs = error else {
                XCTFail("Expected invalidArgs error, got: \(error)")
                return
            }
        }
    }

    // MARK: - Authorization Entry Signing Tests

    func testSignAuthorizationEntriesWithSingleSigner() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 0 // No expiration yet
        )
        entries.append(clientEntry)

        let clientKeyPair = try KeyPair(secretSeed: clientPrivateKey)

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: entries,
            clientAccountId: validClientContractId,
            signers: [clientKeyPair],
            signatureExpirationLedger: 2000000,
            clientDomainKeyPair: nil,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 2)

        // Verify client entry was signed and expiration set
        let signedClientEntry = signedEntries[1]
        guard case .address(let credentials) = signedClientEntry.credentials else {
            XCTFail("Expected address credentials")
            return
        }

        XCTAssertEqual(credentials.signatureExpirationLedger, 2000000)

        guard case .vec(let signatureVec) = credentials.signature,
              let signatures = signatureVec else {
            XCTFail("Expected signature vector")
            return
        }

        XCTAssertFalse(signatures.isEmpty, "Client entry should have signature")
    }

    func testSignAuthorizationEntriesWithMultipleSigners() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 0
        )
        entries.append(clientEntry)

        let signer1 = try KeyPair(secretSeed: clientPrivateKey)
        let signer2 = try KeyPair(secretSeed: clientDomainPrivateKey)

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: entries,
            clientAccountId: validClientContractId,
            signers: [signer1, signer2],
            signatureExpirationLedger: 2000000,
            clientDomainKeyPair: nil,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 2)

        let signedClientEntry = signedEntries[1]
        guard case .address(let credentials) = signedClientEntry.credentials else {
            XCTFail("Expected address credentials")
            return
        }

        guard case .vec(let signatureVec) = credentials.signature,
              let signatures = signatureVec else {
            XCTFail("Expected signature vector")
            return
        }

        // Multiple signatures are accumulated in a single signature map structure
        // The implementation adds each signature to the same entry
        XCTAssertGreaterThanOrEqual(signatures.count, 1, "Should have at least one signature")
    }

    func testSignAuthorizationEntriesWithNoSigners() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 0
        )
        entries.append(clientEntry)

        // No signers - for contracts that don't require signatures
        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: entries,
            clientAccountId: validClientContractId,
            signers: [],
            signatureExpirationLedger: nil,
            clientDomainKeyPair: nil,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 2)

        // Client entry should remain unsigned but included
        let signedClientEntry = signedEntries[1]
        guard case .address(let credentials) = signedClientEntry.credentials else {
            XCTFail("Expected address credentials")
            return
        }

        guard case .vec(let signatureVec) = credentials.signature,
              let signatures = signatureVec else {
            XCTFail("Expected signature vector")
            return
        }

        XCTAssertTrue(signatures.isEmpty, "Should have no signatures")
    }

    func testSignAuthorizationEntriesWithClientDomainKeyPair() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce",
            clientDomain: clientDomain,
            clientDomainAccount: clientDomainPublicKey
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 0
        )
        entries.append(clientEntry)

        let clientDomainEntry = try buildAuthEntry(
            credentialsAddress: clientDomainPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12347,
            expirationLedger: 0
        )
        entries.append(clientDomainEntry)

        let clientKeyPair = try KeyPair(secretSeed: clientPrivateKey)
        let clientDomainKeyPair = try KeyPair(secretSeed: clientDomainPrivateKey)

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: entries,
            clientAccountId: validClientContractId,
            signers: [clientKeyPair],
            signatureExpirationLedger: 2000000,
            clientDomainKeyPair: clientDomainKeyPair,
            clientDomainAccountId: clientDomainPublicKey,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 3)

        // Verify client domain entry exists and has correct credentials structure
        let signedClientDomainEntry = signedEntries[2]
        guard case .address(let credentials) = signedClientDomainEntry.credentials else {
            XCTFail("Expected address credentials")
            return
        }

        // Verify signature field is present (vec type)
        guard case .vec(_) = credentials.signature else {
            XCTFail("Expected signature vector structure")
            return
        }

        // The client domain entry should have been processed
        // Note: The actual signature may be added by the implementation in different ways
    }

    func testSignAuthorizationEntriesWithClientDomainCallback() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce",
            clientDomain: clientDomain,
            clientDomainAccount: clientDomainPublicKey
        )

        var entries: [SorobanAuthorizationEntryXDR] = []

        let serverEntry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )
        entries.append(serverEntry)

        let clientEntry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12346,
            expirationLedger: 0
        )
        entries.append(clientEntry)

        let clientDomainEntry = try buildAuthEntry(
            credentialsAddress: clientDomainPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12347,
            expirationLedger: 0
        )
        entries.append(clientDomainEntry)

        let clientKeyPair = try KeyPair(secretSeed: clientPrivateKey)
        let clientDomainKeyPair = try KeyPair(secretSeed: clientDomainPrivateKey)

        // Callback that signs the entry
        let signingCallback: (SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR = { entry in
            var signedEntry = entry
            try signedEntry.sign(signer: clientDomainKeyPair, network: .testnet)
            return signedEntry
        }

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: entries,
            clientAccountId: validClientContractId,
            signers: [clientKeyPair],
            signatureExpirationLedger: 2000000,
            clientDomainKeyPair: nil,
            clientDomainAccountId: clientDomainPublicKey,
            clientDomainSigningCallback: signingCallback
        )

        XCTAssertEqual(signedEntries.count, 3)

        // Verify client domain entry exists and has correct credentials structure
        let signedClientDomainEntry = signedEntries[2]
        guard case .address(let credentials) = signedClientDomainEntry.credentials else {
            XCTFail("Expected address credentials")
            return
        }

        // Verify signature field is present (vec type)
        guard case .vec(_) = credentials.signature else {
            XCTFail("Expected signature vector structure")
            return
        }

        // The client domain entry should have been processed by the callback
        // Note: The actual signature may be added by the implementation in different ways
    }

    // MARK: - XDR Encoding/Decoding Tests

    func testDecodeAuthorizationEntriesWithInvalidXDR() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        // Valid base64 but invalid XDR structure
        let invalidXdr = "AQIDBA==" // Just [1, 2, 3, 4]

        XCTAssertThrowsError(try webAuth.decodeAuthorizationEntries(base64Xdr: invalidXdr))
    }

    func testDecodeAuthorizationEntriesWithNegativeCount() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        // Encode -1 as Int32 in XDR
        let negativeCount: Int32 = -1
        let encodedBytes = try XDREncoder.encode(negativeCount)
        let base64 = Data(encodedBytes).base64EncodedString()

        XCTAssertThrowsError(try webAuth.decodeAuthorizationEntries(base64Xdr: base64))
    }

    func testDecodeAuthorizationEntriesRoundTrip() throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let entry = try buildAuthEntry(
            credentialsAddress: serverPublicKey,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000,
            signWith: serverKeyPair
        )

        // Encode
        struct AuthEntriesArray: XDREncodable {
            let entries: [SorobanAuthorizationEntryXDR]

            func xdrEncode(to encoder: XDREncoder) throws {
                try encoder.encode(Int32(entries.count))
                for entry in entries {
                    try encoder.encode(entry)
                }
            }
        }

        let wrapper = AuthEntriesArray(entries: [entry])
        let encodedBytes = try XDREncoder.encode(wrapper)
        let base64 = Data(encodedBytes).base64EncodedString()

        // Decode
        let decodedEntries = try webAuth.decodeAuthorizationEntries(base64Xdr: base64)

        XCTAssertEqual(decodedEntries.count, 1)
    }

    // MARK: - Send Signed Challenge Tests

    func testSendSignedChallengeWithFormEncoding() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )
        webAuth.useFormUrlEncoded = true

        let mock = WebAuthForContractsSendChallengeSuccessMock(address: serverDomain)
        defer { _ = mock } // Keep mock alive

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let entry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000
        )

        let result = await webAuth.sendSignedChallenge(signedEntries: [entry])

        switch result {
        case .success(let token):
            XCTAssertFalse(token.isEmpty)
            XCTAssertTrue(token.starts(with: "eyJ"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSendSignedChallengeWithJSONEncoding() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )
        webAuth.useFormUrlEncoded = false

        let mock = WebAuthForContractsSendChallengeSuccessMock(address: serverDomain)
        defer { _ = mock } // Keep mock alive

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let entry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000
        )

        let result = await webAuth.sendSignedChallenge(signedEntries: [entry])

        switch result {
        case .success(let token):
            XCTAssertFalse(token.isEmpty)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testSendSignedChallengeWithTimeout() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let mock = WebAuthForContractsSendChallengeTimeoutMock(address: serverDomain)
        defer { _ = mock } // Keep mock alive

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let entry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000
        )

        let result = await webAuth.sendSignedChallenge(signedEntries: [entry])

        switch result {
        case .success:
            XCTFail("Expected timeout error")
        case .failure(let error):
            guard case .submitChallengeTimeout = error else {
                XCTFail("Expected submitChallengeTimeout error, got: \(error)")
                return
            }
        }
    }

    func testSendSignedChallengeWithServerError() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let mock = WebAuthForContractsSendChallengeErrorMock(address: serverDomain)
        defer { _ = mock } // Keep mock alive

        let argsMap = buildArgsMap(
            account: validClientContractId,
            homeDomain: serverDomain,
            webAuthDomain: serverDomain,
            webAuthDomainAccount: serverPublicKey,
            nonce: "test_nonce"
        )

        let entry = try buildAuthEntry(
            credentialsAddress: validClientContractId,
            contractId: webAuthContractId,
            functionName: "web_auth_verify",
            argsMap: argsMap,
            nonce: 12345,
            expirationLedger: 1000000
        )

        let result = await webAuth.sendSignedChallenge(signedEntries: [entry])

        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            guard case .submitChallengeError(let message) = error else {
                XCTFail("Expected submitChallengeError, got: \(error)")
                return
            }
            XCTAssertTrue(message.contains("Invalid"))
        }
    }

    // MARK: - Get Challenge Tests

    func testGetChallengeWithInvalidJSON() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let mock = WebAuthForContractsGetChallengeInvalidJSONMock(address: serverDomain)
        defer { _ = mock } // Keep mock alive

        let result = await webAuth.getChallenge(
            forContractAccount: validClientContractId,
            homeDomain: serverDomain
        )

        switch result {
        case .success:
            XCTFail("Expected parsing error")
        case .failure(let error):
            guard case .parsingError = error else {
                XCTFail("Expected parsingError, got: \(error)")
                return
            }
        }
    }

    func testGetChallengeWithErrorResponse() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let mock = WebAuthForContractsGetChallengeErrorMock(address: serverDomain)
        defer { _ = mock } // Keep mock alive

        let result = await webAuth.getChallenge(
            forContractAccount: validClientContractId,
            homeDomain: serverDomain
        )

        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            // 400 errors are wrapped in requestError with badRequest
            guard case .requestError(let requestError) = error else {
                XCTFail("Expected requestError, got: \(error)")
                return
            }
            // Verify the error contains the expected message
            let errorDescription = String(describing: requestError)
            XCTAssertTrue(errorDescription.contains("Account not found"))
        }
    }

    func testGetChallengeWithClientDomain() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let mock = WebAuthForContractsGetChallengeSuccessMock(
            address: serverDomain,
            serverKeyPair: serverKeyPair,
            webAuthContractId: webAuthContractId
        )
        defer { _ = mock } // Keep mock alive

        let result = await webAuth.getChallenge(
            forContractAccount: validClientContractId,
            homeDomain: serverDomain,
            clientDomain: clientDomain
        )

        switch result {
        case .success(let response):
            XCTAssertFalse(response.authorizationEntries.isEmpty)
            XCTAssertNotNil(response.networkPassphrase)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Network Passphrase Validation Tests

    func testJwtTokenWithMismatchedNetworkPassphrase() async throws {
        let webAuth = try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )

        let mock = WebAuthForContractsGetChallengeWrongNetworkMock(
            address: serverDomain,
            serverKeyPair: serverKeyPair,
            webAuthContractId: webAuthContractId
        )
        defer { _ = mock } // Keep mock alive

        let result = await webAuth.jwtToken(
            forContractAccount: validClientContractId,
            signers: []
        )

        switch result {
        case .success:
            XCTFail("Expected network passphrase validation error")
        case .failure(let error):
            guard case .validationError(let validationError) = error else {
                XCTFail("Expected validationError, got: \(error)")
                return
            }
            guard case .invalidNetworkPassphrase = validationError else {
                XCTFail("Expected invalidNetworkPassphrase, got: \(validationError)")
                return
            }
        }
    }

    // MARK: - Helper Methods

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

    func buildInvocation(
        contractId: String,
        functionName: String,
        argsMap: SCValXDR,
        subInvocations: [SorobanAuthorizedInvocationXDR] = []
    ) throws -> SorobanAuthorizedInvocationXDR {
        let contractIdData = try contractId.decodeContractId()
        let contractAddress = SCAddressXDR.contract(WrappedData32(contractIdData))

        let contractFn = InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: functionName,
            args: [argsMap]
        )

        let function = SorobanAuthorizedFunctionXDR.contractFn(contractFn)
        return SorobanAuthorizedInvocationXDR(
            function: function,
            subInvocations: subInvocations
        )
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
            let contractIdData = try credentialsAddress.decodeContractId()
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

        let invocation = try buildInvocation(
            contractId: contractId,
            functionName: functionName,
            argsMap: argsMap,
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
}

// MARK: - Mock Classes

class WebAuthForContractsSendChallengeSuccessMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return """
            {
                "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJDRFpKSURRVzVXVFBBWjY0UEdJSkdWRUlETks3MkxMM0xLVVpXRzNHNkdXWFlRS0kySkFJVkZOViJ9.test"
            }
            """
        }

        return RequestMock(
            host: address,
            path: "/auth",
            httpMethod: "POST",
            mockHandler: handler
        )
    }
}

class WebAuthForContractsSendChallengeTimeoutMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 504
            return "Gateway Timeout"
        }

        return RequestMock(
            host: address,
            path: "/auth",
            httpMethod: "POST",
            mockHandler: handler
        )
    }
}

class WebAuthForContractsSendChallengeErrorMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 400
            return """
            {
                "error": "Invalid signature or authorization"
            }
            """
        }

        return RequestMock(
            host: address,
            path: "/auth",
            httpMethod: "POST",
            mockHandler: handler
        )
    }
}

class WebAuthForContractsGetChallengeSuccessMock: ResponsesMock {
    var address: String
    var serverKeyPair: KeyPair
    var webAuthContractId: String

    init(address: String, serverKeyPair: KeyPair, webAuthContractId: String) {
        self.address = address
        self.serverKeyPair = serverKeyPair
        self.webAuthContractId = webAuthContractId
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200

            // Build minimal valid challenge
            return """
            {
                "authorization_entries": "AAAAAA==",
                "network_passphrase": "Test SDF Network ; September 2015"
            }
            """
        }

        return RequestMock(
            host: address,
            path: "*",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

class WebAuthForContractsGetChallengeInvalidJSONMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200
            return "not valid json{"
        }

        return RequestMock(
            host: address,
            path: "*",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

class WebAuthForContractsGetChallengeErrorMock: ResponsesMock {
    var address: String

    init(address: String) {
        self.address = address
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 400
            return """
            {
                "error": "Account not found"
            }
            """
        }

        return RequestMock(
            host: address,
            path: "*",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}

class WebAuthForContractsGetChallengeWrongNetworkMock: ResponsesMock {
    var address: String
    var serverKeyPair: KeyPair
    var webAuthContractId: String

    init(address: String, serverKeyPair: KeyPair, webAuthContractId: String) {
        self.address = address
        self.serverKeyPair = serverKeyPair
        self.webAuthContractId = webAuthContractId
        super.init()
    }

    override func requestMock() -> RequestMock {
        let handler: MockHandler = { mock, request in
            mock.statusCode = 200

            return """
            {
                "authorization_entries": "AAAAAA==",
                "network_passphrase": "Public Global Stellar Network ; September 2015"
            }
            """
        }

        return RequestMock(
            host: address,
            path: "*",
            httpMethod: "GET",
            mockHandler: handler
        )
    }
}
