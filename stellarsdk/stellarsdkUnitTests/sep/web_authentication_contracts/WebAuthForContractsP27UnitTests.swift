//
//  WebAuthForContractsP27UnitTests.swift
//  stellarsdkUnitTests
//
//  Unit tests for the protocol-27 (CAP-71) updates to WebAuthForContracts (SEP-45).
//  Covers:
//  - Validation path accepts ADDRESS_V2 and WITH_DELEGATES credential arms.
//  - Verification rejects a V2 entry signed over the wrong (legacy) preimage.
//  - Legacy preimage produces the documented byte-identical SHA-256 golden hash.
//  - Arm preservation through signAuthorizationEntries().
//  - Source-account credentials produce a descriptive error where an address arm is required.
//

import XCTest
@testable import stellarsdk

final class WebAuthForContractsP27UnitTests: XCTestCase {

    // MARK: - Constants

    // Golden vector from the protocol-27 (CAP-71) test suite.
    // Inputs: TESTNET, nonce 123456789101112, expiration 4242,
    //   contract CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE, fn hello(u64 1234).
    // This SHA-256 is the payload that a signer hashes for the legacy ADDRESS arm.
    private static let legacyPayloadSha256Hex =
        "120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe"

    private let serverDomain = "auth.stellar.org"
    private let authEndpoint = "http://auth.stellar.org/auth"

    private let serverPublicKey  = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
    private let serverPrivateKey = "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W"

    private let webAuthContractId   = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"
    private let clientContractId    = "CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV"
    private let signerSeed = "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE"

    // Invocation target used in the golden vector.
    private let goldenContractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ServerMock.self)
    }

    // MARK: - Helper: build WebAuthForContracts

    private func makeWebAuth() throws -> WebAuthForContracts {
        return try WebAuthForContracts(
            authEndpoint: authEndpoint,
            webAuthContractId: webAuthContractId,
            serverSigningKey: serverPublicKey,
            serverHomeDomain: serverDomain,
            network: .testnet
        )
    }

    private enum CredentialArm27 {
        case legacy
        case v2
        case withDelegates
    }

    // MARK: - Helper: build args map

    private func makeArgsMap(nonce: String = "test_nonce") -> SCValXDR {
        return SCValXDR.map([
            SCMapEntryXDR(key: .symbol("account"),               val: .string(clientContractId)),
            SCMapEntryXDR(key: .symbol("home_domain"),           val: .string(serverDomain)),
            SCMapEntryXDR(key: .symbol("web_auth_domain"),       val: .string(serverDomain)),
            SCMapEntryXDR(key: .symbol("web_auth_domain_account"), val: .string(serverPublicKey)),
            SCMapEntryXDR(key: .symbol("nonce"),                 val: .string(nonce)),
        ])
    }

    // MARK: - Helper: build a full challenge entry with the correct contract/function/args structure

    private func makeChallengeEntry(
        credentialsAddress: String,
        nonce: Int64 = 12345,
        expirationLedger: UInt32 = 1_000_000,
        arm: CredentialArm27 = .legacy,
        signWith: KeyPair? = nil
    ) throws -> SorobanAuthorizationEntryXDR {
        let credsAddr: SCAddressXDR
        if credentialsAddress.hasPrefix("C") {
            let data = try credentialsAddress.decodeContractId()
            credsAddr = .contract(WrappedData32(data))
        } else if credentialsAddress.hasPrefix("G") {
            credsAddr = .account(try PublicKey(accountId: credentialsAddress))
        } else {
            throw NSError(domain: "Invalid address prefix", code: 0)
        }

        let contractData = try webAuthContractId.decodeContractId()
        let contractAddress = SCAddressXDR.contract(WrappedData32(contractData))

        let argsMap = makeArgsMap()
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "web_auth_verify",
                args: [argsMap]
            )),
            subInvocations: []
        )

        let innerCreds = SorobanAddressCredentialsXDR(
            address: credsAddr,
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            signature: .vec([])
        )

        let credentials: SorobanCredentialsXDR
        switch arm {
        case .legacy:
            credentials = .address(innerCreds)
        case .v2:
            credentials = .addressV2(innerCreds)
        case .withDelegates:
            credentials = .addressWithDelegates(
                SorobanAddressCredentialsWithDelegatesXDR(
                    addressCredentials: innerCreds,
                    delegates: []
                )
            )
        }

        var entry = SorobanAuthorizationEntryXDR(
            credentials: credentials,
            rootInvocation: invocation
        )

        if let signer = signWith {
            try entry.sign(signer: signer, network: .testnet)
        }

        return entry
    }

    // MARK: - Golden vector: legacy preimage byte identity

    /// Verifies the SHA-256 payload hash for the legacy ADDRESS arm equals the documented
    /// golden constant. This proves the legacy code path is byte-identical to pre-change behavior.
    func testLegacyPreimagePayloadHashGoldenVector() throws {
        // Build the golden-vector entry: TESTNET, nonce 123456789101112, expiration 4242,
        // contract CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE, fn hello(u64 1234).
        let contractData = try goldenContractId.decodeContractId()
        let contractAddress = SCAddressXDR.contract(WrappedData32(contractData))
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "hello",
                args: [.u64(1234)]
            )),
            subInvocations: []
        )
        let signerKey = try KeyPair(secretSeed: signerSeed)
        let signerAddr = SCAddressXDR.account(signerKey.publicKey)
        let innerCreds = SorobanAddressCredentialsXDR(
            address: signerAddr,
            nonce: 123456789101112,
            signatureExpirationLedger: 4242,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(innerCreds),
            rootInvocation: invocation
        )

        let preimage = try entry.buildPreimage(network: .testnet)
        let encoded = try XDREncoder.encode(preimage)
        let hash = Data(bytes: encoded, count: encoded.count).sha256Hash
        let actualHex = hash.map { String(format: "%02x", $0) }.joined()

        XCTAssertEqual(
            actualHex,
            WebAuthForContractsP27UnitTests.legacyPayloadSha256Hex,
            "Legacy ADDRESS preimage payload hash must equal the golden constant"
        )
    }

    // MARK: - Validation: ADDRESS_V2 entry accepted

    /// validateChallenge must accept an ADDRESS_V2 entry (e.g. server entry signed with V2).
    func testValidateChallengeAcceptsAddressV2ServerEntry() throws {
        let webAuth = try makeWebAuth()
        let serverKeyPair = try KeyPair(secretSeed: serverPrivateKey)

        // Server entry: ADDRESS_V2, signed.
        let serverEntry = try makeChallengeEntry(
            credentialsAddress: serverPublicKey,
            arm: .v2,
            signWith: serverKeyPair
        )
        // Client entry: legacy.
        let clientEntry = try makeChallengeEntry(credentialsAddress: clientContractId, arm: .legacy)

        // Must not throw — ADDRESS_V2 is accepted.
        XCTAssertNoThrow(
            try webAuth.validateChallenge(
                authEntries: [serverEntry, clientEntry],
                clientAccountId: clientContractId,
                homeDomain: serverDomain
            )
        )
    }

    /// validateChallenge must accept a WITH_DELEGATES (empty delegates) server entry.
    func testValidateChallengeAcceptsWithDelegatesServerEntry() throws {
        let webAuth = try makeWebAuth()
        let serverKeyPair = try KeyPair(secretSeed: serverPrivateKey)

        // Server entry: WITH_DELEGATES (empty), signed.
        let serverEntry = try makeChallengeEntry(
            credentialsAddress: serverPublicKey,
            arm: .withDelegates,
            signWith: serverKeyPair
        )
        let clientEntry = try makeChallengeEntry(credentialsAddress: clientContractId, arm: .legacy)

        XCTAssertNoThrow(
            try webAuth.validateChallenge(
                authEntries: [serverEntry, clientEntry],
                clientAccountId: clientContractId,
                homeDomain: serverDomain
            )
        )
    }

    /// validateChallenge must accept a legacy ADDRESS server entry (existing behavior preserved).
    func testValidateChallengeAcceptsLegacyServerEntry() throws {
        let webAuth = try makeWebAuth()
        let serverKeyPair = try KeyPair(secretSeed: serverPrivateKey)

        let serverEntry = try makeChallengeEntry(
            credentialsAddress: serverPublicKey,
            arm: .legacy,
            signWith: serverKeyPair
        )
        let clientEntry = try makeChallengeEntry(credentialsAddress: clientContractId, arm: .legacy)

        XCTAssertNoThrow(
            try webAuth.validateChallenge(
                authEntries: [serverEntry, clientEntry],
                clientAccountId: clientContractId,
                homeDomain: serverDomain
            )
        )
    }

    // MARK: - Verification: V2 signed over wrong (legacy) preimage is rejected

    /// An ADDRESS_V2 entry signed over the legacy (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION)
    /// preimage instead of the correct WITH_ADDRESS preimage must fail signature verification.
    func testVerifyRejectsV2EntrySignedOverLegacyPreimage() throws {
        let webAuth = try makeWebAuth()
        let serverKeyPair = try KeyPair(secretSeed: serverPrivateKey)

        // Build a V2 entry but sign it using the legacy preimage (wrong).
        // We do this by constructing the entry as legacy, signing it, then rewriting
        // the credential arm to V2 — the signature bytes remain those of the legacy preimage.
        var legacyEntry = try makeChallengeEntry(
            credentialsAddress: serverPublicKey,
            arm: .legacy,
            signWith: serverKeyPair
        )
        // Extract the inner credentials and the (wrong) legacy signature.
        guard case .address(let legacyCreds) = legacyEntry.credentials else {
            XCTFail("Expected legacy credentials after signing"); return
        }
        // Rewrite to V2 while keeping the signature bytes from the legacy-preimage signing.
        legacyEntry.credentials = .addressV2(legacyCreds)

        // The client entry is normal.
        let clientEntry = try makeChallengeEntry(credentialsAddress: clientContractId, arm: .legacy)

        // Validation must fail because the V2 entry carries a signature computed over
        // the wrong (legacy) preimage.
        XCTAssertThrowsError(
            try webAuth.validateChallenge(
                authEntries: [legacyEntry, clientEntry],
                clientAccountId: clientContractId,
                homeDomain: serverDomain
            )
        ) { error in
            guard case ContractChallengeValidationError.invalidServerSignature = error else {
                XCTFail("Expected invalidServerSignature, got: \(error)")
                return
            }
        }
    }

    /// An ADDRESS_V2 entry signed over the correct WITH_ADDRESS preimage must pass verification.
    func testVerifyAcceptsV2EntrySignedOverCorrectPreimage() throws {
        let webAuth = try makeWebAuth()
        let serverKeyPair = try KeyPair(secretSeed: serverPrivateKey)

        // Build and sign the V2 entry with the correct preimage (entry.sign() uses the builder).
        let serverEntry = try makeChallengeEntry(
            credentialsAddress: serverPublicKey,
            arm: .v2,
            signWith: serverKeyPair
        )
        let clientEntry = try makeChallengeEntry(credentialsAddress: clientContractId, arm: .legacy)

        XCTAssertNoThrow(
            try webAuth.validateChallenge(
                authEntries: [serverEntry, clientEntry],
                clientAccountId: clientContractId,
                homeDomain: serverDomain
            )
        )
    }

    // MARK: - Source-account credentials: descriptive error

    /// validateChallenge must throw an invalidArgs error when an entry carries
    /// source-account credentials, not silently pass or cause a nil-dereference.
    func testValidateChallengeRejectsSourceAccountCredentials() throws {
        let webAuth = try makeWebAuth()
        let serverKeyPair = try KeyPair(secretSeed: serverPrivateKey)

        let serverEntry = try makeChallengeEntry(
            credentialsAddress: serverPublicKey,
            arm: .legacy,
            signWith: serverKeyPair
        )

        // An entry with source-account credentials (no address field).
        let contractData = try webAuthContractId.decodeContractId()
        let contractAddress = SCAddressXDR.contract(WrappedData32(contractData))
        let argsMap = makeArgsMap()
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "web_auth_verify",
                args: [argsMap]
            )),
            subInvocations: []
        )
        let sourceAccountEntry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )

        XCTAssertThrowsError(
            try webAuth.validateChallenge(
                authEntries: [serverEntry, sourceAccountEntry],
                clientAccountId: clientContractId,
                homeDomain: serverDomain
            )
        ) { error in
            guard case ContractChallengeValidationError.invalidArgs(let message) = error else {
                XCTFail("Expected invalidArgs, got: \(error)")
                return
            }
            XCTAssertTrue(
                message.contains("source-account"),
                "Error message must mention 'source-account'; got: \(message)"
            )
        }
    }

    // MARK: - signAuthorizationEntries: source-account credentials pass through

    /// Source-account entries must be passed through unchanged in signAuthorizationEntries,
    /// not discarded or replaced.
    func testSignAuthorizationEntriesPassesThroughSourceAccount() async throws {
        let webAuth = try makeWebAuth()

        let contractData = try webAuthContractId.decodeContractId()
        let contractAddress = SCAddressXDR.contract(WrappedData32(contractData))
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "web_auth_verify",
                args: []
            )),
            subInvocations: []
        )
        let sourceAccountEntry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )

        let result = try await webAuth.signAuthorizationEntries(
            authEntries: [sourceAccountEntry],
            clientAccountId: clientContractId,
            signers: [],
            signatureExpirationLedger: nil,
            clientDomainKeyPair: nil,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(result.count, 1, "Source-account entry must be passed through")
        if case .sourceAccount = result[0].credentials { /* correct */ } else {
            XCTFail("Source-account arm must be preserved when passing through")
        }
    }

    // MARK: - signAuthorizationEntries: arm preservation (V2)

    /// signAuthorizationEntries must preserve the ADDRESS_V2 arm when stamping
    /// the expiration and signing. The arm must not be coerced to legacy ADDRESS.
    func testSignAuthorizationEntriesPreservesV2Arm() async throws {
        let webAuth = try makeWebAuth()
        let clientKeyPair = try KeyPair(secretSeed: signerSeed)

        // Build a client V2 entry whose credentials address matches the clientContractId.
        let v2Entry = try makeChallengeEntry(
            credentialsAddress: clientContractId,
            nonce: 12346,
            expirationLedger: 0,
            arm: .v2
        )

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: [v2Entry],
            clientAccountId: clientContractId,
            signers: [clientKeyPair],
            signatureExpirationLedger: 2_000_000,
            clientDomainKeyPair: nil,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 1)
        guard case .addressV2(let creds) = signedEntries[0].credentials else {
            XCTFail("ADDRESS_V2 arm must be preserved after signAuthorizationEntries")
            return
        }
        XCTAssertEqual(creds.signatureExpirationLedger, 2_000_000,
                       "Expiration must be stamped into the V2 credentials")

        // The entry must have been signed (non-void/non-empty signature vector).
        if let sigVec = creds.signature.vec {
            XCTAssertFalse(sigVec.isEmpty, "V2 entry must carry a signature after signing")
        } else {
            XCTFail("V2 entry signature must be a vec after signing")
        }
    }

    // MARK: - signAuthorizationEntries: arm preservation (WITH_DELEGATES)

    /// signAuthorizationEntries must preserve the WITH_DELEGATES arm when stamping the
    /// expiration. The delegates array must survive the credential write-back.
    func testSignAuthorizationEntriesPreservesWithDelegatesArm() async throws {
        let webAuth = try makeWebAuth()

        // Manually construct a WITH_DELEGATES entry targeting clientContractId.
        let contractData = try clientContractId.decodeContractId()
        let credsAddr = SCAddressXDR.contract(WrappedData32(contractData))
        let webAuthData = try webAuthContractId.decodeContractId()
        let contractAddress = SCAddressXDR.contract(WrappedData32(webAuthData))
        let argsMap = makeArgsMap()
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: contractAddress,
                functionName: "web_auth_verify",
                args: [argsMap]
            )),
            subInvocations: []
        )

        let signerKey = try KeyPair(secretSeed: signerSeed)
        let delegateAddr = SCAddressXDR.account(signerKey.publicKey)
        let delegateNode = SorobanDelegateSignatureXDR(
            address: delegateAddr,
            signature: .void,
            nestedDelegates: []
        )
        let innerCreds = SorobanAddressCredentialsXDR(
            address: credsAddr,
            nonce: 12346,
            signatureExpirationLedger: 0,
            signature: .void
        )
        let withDelegatesEntry = SorobanAuthorizationEntryXDR(
            credentials: .addressWithDelegates(
                SorobanAddressCredentialsWithDelegatesXDR(
                    addressCredentials: innerCreds,
                    delegates: [delegateNode]
                )
            ),
            rootInvocation: invocation
        )

        // Sign with no signers — the entry is still stamped with expiration.
        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: [withDelegatesEntry],
            clientAccountId: clientContractId,
            signers: [],
            signatureExpirationLedger: 3_000_000,
            clientDomainKeyPair: nil,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 1)
        guard case .addressWithDelegates(let wd) = signedEntries[0].credentials else {
            XCTFail("WITH_DELEGATES arm must be preserved after signAuthorizationEntries")
            return
        }
        XCTAssertEqual(wd.addressCredentials.signatureExpirationLedger, 3_000_000,
                       "Expiration must be stamped into the WITH_DELEGATES inner credentials")
        XCTAssertEqual(wd.delegates.count, 1, "Delegates array must survive credential write-back")
    }

    // MARK: - signAuthorizationEntries: client-domain keypair branch with non-nil expiration (line 668)

    /// signAuthorizationEntries must stamp the expiration into the credentials (line 668) and
    /// preserve the ADDRESS_V2 arm when the entry belongs to the client-domain keypair.
    ///
    /// Conditions that reach line 668:
    ///   - credentialsAddress matches clientDomainKeyPair.accountId
    ///   - signatureExpirationLedger is non-nil
    func testSignAuthorizationEntries_clientDomainKeyPair_v2_stampsExpirationAndPreservesArm() async throws {
        let webAuth = try makeWebAuth()
        let clientDomainKeyPair = try KeyPair(secretSeed: signerSeed)

        // Build a V2 entry whose credential address is the client-domain keypair's account.
        let domainEntry = try makeChallengeEntry(
            credentialsAddress: clientDomainKeyPair.accountId,
            nonce: 55_555,
            expirationLedger: 0,
            arm: .v2
        )

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: [domainEntry],
            clientAccountId: clientContractId,   // no entry matches this → loop falls through to domain branch
            signers: [],
            signatureExpirationLedger: 3_000_000,
            clientDomainKeyPair: clientDomainKeyPair,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 1, "Client-domain entry must be returned")
        guard case .addressV2(let creds) = signedEntries[0].credentials else {
            XCTFail("ADDRESS_V2 arm must be preserved through the client-domain keypair branch")
            return
        }
        XCTAssertEqual(creds.signatureExpirationLedger, 3_000_000,
                       "Expiration must be stamped into the V2 credentials via withAddressCredentials (line 668)")
        if case .void = creds.signature {
            XCTFail("Entry must carry a signature after signing with clientDomainKeyPair")
        }
    }

    // MARK: - signAuthorizationEntries: client-domain callback branch with non-nil expiration (line 683)

    /// signAuthorizationEntries must stamp the expiration into the credentials (line 683) before
    /// handing the entry to the signing callback, and preserve the ADDRESS_V2 arm.
    ///
    /// Conditions that reach line 683:
    ///   - credentialsAddress matches clientDomainAccountId
    ///   - clientDomainSigningCallback is non-nil
    ///   - signatureExpirationLedger is non-nil
    func testSignAuthorizationEntries_clientDomainCallback_v2_stampsExpirationAndPreservesArm() async throws {
        let webAuth = try makeWebAuth()
        let clientDomainKeyPair = try KeyPair(secretSeed: signerSeed)
        let clientDomainAccountId = clientDomainKeyPair.accountId

        // Build a V2 entry whose credential address is the client-domain account.
        let domainEntry = try makeChallengeEntry(
            credentialsAddress: clientDomainAccountId,
            nonce: 66_666,
            expirationLedger: 0,
            arm: .v2
        )

        // The callback receives the entry after the expiration has been stamped; it just
        // returns the entry as-is so we can inspect the stamped credentials directly.
        var callbackReceivedExpiration: UInt32 = 0
        let signingCallback: (SorobanAuthorizationEntryXDR) async throws -> SorobanAuthorizationEntryXDR = { entry in
            if case .addressV2(let c) = entry.credentials {
                callbackReceivedExpiration = c.signatureExpirationLedger
            }
            return entry
        }

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: [domainEntry],
            clientAccountId: clientContractId,   // no entry matches this → loop falls through to callback branch
            signers: [],
            signatureExpirationLedger: 4_000_000,
            clientDomainKeyPair: nil,
            clientDomainAccountId: clientDomainAccountId,
            clientDomainSigningCallback: signingCallback
        )

        XCTAssertEqual(signedEntries.count, 1, "Client-domain entry must be returned from callback")
        XCTAssertEqual(callbackReceivedExpiration, 4_000_000,
                       "Callback must receive the entry with expiration already stamped (line 683)")
        guard case .addressV2 = signedEntries[0].credentials else {
            XCTFail("ADDRESS_V2 arm must be preserved through the client-domain callback branch")
            return
        }
    }

    // MARK: - signAuthorizationEntries: legacy arm preservation (regression)

    func testSignAuthorizationEntriesPreservesLegacyArm() async throws {
        let webAuth = try makeWebAuth()
        let clientKeyPair = try KeyPair(secretSeed: signerSeed)

        let legacyEntry = try makeChallengeEntry(
            credentialsAddress: clientContractId,
            nonce: 12346,
            expirationLedger: 0,
            arm: .legacy
        )

        let signedEntries = try await webAuth.signAuthorizationEntries(
            authEntries: [legacyEntry],
            clientAccountId: clientContractId,
            signers: [clientKeyPair],
            signatureExpirationLedger: 2_000_000,
            clientDomainKeyPair: nil,
            clientDomainAccountId: nil,
            clientDomainSigningCallback: nil
        )

        XCTAssertEqual(signedEntries.count, 1)
        guard case .address(let creds) = signedEntries[0].credentials else {
            XCTFail("Legacy ADDRESS arm must be preserved after signAuthorizationEntries")
            return
        }
        XCTAssertEqual(creds.signatureExpirationLedger, 2_000_000)
    }
}
