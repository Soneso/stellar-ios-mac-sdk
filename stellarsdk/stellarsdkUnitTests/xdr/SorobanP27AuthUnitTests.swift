//
//  SorobanP27AuthUnitTests.swift
//  stellarsdkUnitTests
//
//  Unit tests for the protocol-27 (CAP-71) signing and delegation primitives added to
//  SorobanAuthorizationEntryXDR+Helpers.swift, SorobanCredentialsXDR+Helpers.swift,
//  SorobanAddressCredentialsXDR+Helpers.swift, and SorobanDelegateTreeXDR+Helpers.swift.
//

import XCTest
@testable import stellarsdk

// MARK: - Golden vector constants

private enum GoldenVectors {
    // Network: "Test SDF Network ; September 2015"
    static let network = Network.testnet

    // Signer seed: SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE
    // Signer account: GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D
    static let signerSeed = "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE"
    static let signerAccountId = "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D"

    // Invocation target: CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE
    static let contractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"

    static let nonce: Int64 = 123456789101112
    static let expirationLedger: UInt32 = 4242

    // XDR-encoded preimage, SHA-256 of it, and the expected ed25519 signature.
    // The preimage depends only on (networkID, nonce, expiration, invocation) for the
    // legacy arm, so credentials.address does not influence it.
    static let legacyPreimageB64 = "AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAABwSIYPOjgAABCSAAAAAAAAAAE2Pqo4Z4QfutD07YjHeeT+ZuVqJHDcmMDsnAc9BcexAwAAAAVoZWxsbwAAAAAAAAEAAAAFAAAAAAAABNIAAAAA"
    static let payloadSha256Hex = "120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe"
    static let signatureHex = "3c69ceefc532f97e1d0e0eb9f204c9aa85cb2b68cf293bce832590b01455e060e89900ea3ba2c45257908769a1a71f25b6d3befbadffd220f896dc0058699008"

    // Full signed entry: credentials.address = signerAccountId, invocation targets contractId.
    // sign() called with stale expiration 0 in credentials; new value 4242 passed to sign().
    static let signedEntryB64 = "AAAAAQAAAAAAAAAAsnuvp7wv0ARs15Z8RFDPXJKdbnrzfn7EC/ddPL0FSq0AAHBIhg86OAAAEJIAAAAQAAAAAQAAAAEAAAARAAAAAQAAAAIAAAAPAAAACnB1YmxpY19rZXkAAAAAAA0AAAAgsnuvp7wv0ARs15Z8RFDPXJKdbnrzfn7EC/ddPL0FSq0AAAAPAAAACXNpZ25hdHVyZQAAAAAAAA0AAABAPGnO78Uy+X4dDg658gTJqoXLK2jPKTvOgyWQsBRV4GDomQDqO6LEUleQh2mhpx8lttO++63/0iD4ltwAWGmQCAAAAAAAAAABNj6qOGeEH7rQ9O2Ix3nk/mblaiRw3JjA7JwHPQXHsQMAAAAFaGVsbG8AAAAAAAABAAAABQAAAAAAAATSAAAAAA=="

    // ADDRESS_V2 golden vector: same fixed inputs with the signer's G-address as the
    // credential address. The WITH_ADDRESS preimage includes the address field; the hash
    // is different from the legacy preimage above.
    //
    // Computed from:
    //   ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS (discriminant 10),
    //   networkID = SHA-256("Test SDF Network ; September 2015"),
    //   nonce = 123456789101112, expiration = 4242,
    //   address = SCAddress.account(GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D),
    //   invocation = same as legacy vector.
    static let v2PreimageB64 =
        "AAAACs7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAABwSIYPOjgAABCSAAAAAAAAAACye6+nvC/QBGzXlnxEUM9ckp1uevN+fsQL9108vQVKrQAAAAAAAAABNj6qOGeEH7rQ9O2Ix3nk/mblaiRw3JjA7JwHPQXHsQMAAAAFaGVsbG8AAAAAAAABAAAABQAAAAAAAATSAAAAAA=="
    static let v2PayloadSha256Hex = "252a0d6117840dff37b765839810fb6ecc446198e73062e01bc961e49355b7b9"
}

// MARK: - Test fixture builders

/// Builds an authorization entry with separate credentials address and invocation contract.
///
/// `credentialsAddress` is the account or contract that owns the authorization
/// (written into `SorobanAddressCredentialsXDR.address`). `invocationContractId` is the
/// target of the root invocation and may differ from `credentialsAddress`.
private func makeTestEntry(
    credentialsAddress: String,
    invocationContractId: String,
    nonce: Int64,
    expirationLedger: UInt32,
    functionName: String = "hello",
    args: [SCValXDR] = [.u64(1234)],
    credentialArm: CredentialArm = .legacy
) throws -> SorobanAuthorizationEntryXDR {
    let credsAddr = try scAddressXDR(fromStrkey: credentialsAddress)
    let contractAddress = try SCAddressXDR(contractId: invocationContractId)
    let function = SorobanAuthorizedFunctionXDR.contractFn(
        InvokeContractArgsXDR(
            contractAddress: contractAddress,
            functionName: functionName,
            args: args
        )
    )
    let invocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
    let creds = SorobanAddressCredentialsXDR(
        address: credsAddr,
        nonce: nonce,
        signatureExpirationLedger: expirationLedger,
        signature: .void
    )
    let credentials: SorobanCredentialsXDR
    switch credentialArm {
    case .legacy:
        credentials = .address(creds)
    case .v2:
        credentials = .addressV2(creds)
    case .withDelegates:
        credentials = .addressWithDelegates(
            SorobanAddressCredentialsWithDelegatesXDR(addressCredentials: creds, delegates: [])
        )
    }
    return SorobanAuthorizationEntryXDR(credentials: credentials, rootInvocation: invocation)
}

/// Builds the golden-vector entry: credentials.address = signerAccountId,
/// invocation target = golden contractId, nonce and expiration from GoldenVectors.
private func makeGoldenEntry(
    expirationLedger: UInt32,
    credentialArm: CredentialArm = .legacy
) throws -> SorobanAuthorizationEntryXDR {
    return try makeTestEntry(
        credentialsAddress: GoldenVectors.signerAccountId,
        invocationContractId: GoldenVectors.contractId,
        nonce: GoldenVectors.nonce,
        expirationLedger: expirationLedger,
        credentialArm: credentialArm
    )
}

/// Builds a test entry where the contract is used both as credentials address and invocation
/// target. Used for arm/discriminant/signing tests that do not need specific address structure.
private func makeContractEntry(
    contractId: String = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE",
    nonce: Int64 = 1,
    expirationLedger: UInt32 = 100,
    functionName: String = "hello",
    args: [SCValXDR] = [.u64(1234)],
    credentialArm: CredentialArm = .legacy
) throws -> SorobanAuthorizationEntryXDR {
    return try makeTestEntry(
        credentialsAddress: contractId,
        invocationContractId: contractId,
        nonce: nonce,
        expirationLedger: expirationLedger,
        functionName: functionName,
        args: args,
        credentialArm: credentialArm
    )
}

private enum CredentialArm {
    case legacy
    case v2
    case withDelegates
}

// MARK: - Tests

final class SorobanP27AuthUnitTests: XCTestCase {

    // MARK: - Golden-vector: legacy preimage byte identity

    func testLegacyPreimageByteIdentity() throws {
        // Preimage depends only on (networkID, nonce, expiration, invocation) for the
        // legacy arm, so it is independent of credentials.address. Use makeContractEntry
        // to keep the test focused on the preimage structure.
        let entry = try makeTestEntry(
            credentialsAddress: GoldenVectors.signerAccountId,
            invocationContractId: GoldenVectors.contractId,
            nonce: GoldenVectors.nonce,
            expirationLedger: GoldenVectors.expirationLedger
        )

        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        let encoded = try XDREncoder.encode(preimage)
        let actualB64 = Data(encoded).base64EncodedString()
        XCTAssertEqual(actualB64, GoldenVectors.legacyPreimageB64,
                       "XDR-encoded legacy preimage must match the golden vector")
    }

    func testLegacyPayloadHashByteIdentity() throws {
        let entry = try makeTestEntry(
            credentialsAddress: GoldenVectors.signerAccountId,
            invocationContractId: GoldenVectors.contractId,
            nonce: GoldenVectors.nonce,
            expirationLedger: GoldenVectors.expirationLedger
        )

        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        let encoded = try XDREncoder.encode(preimage)
        let hash = Data(bytes: encoded, count: encoded.count).sha256Hash
        let actualHex = hash.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(actualHex, GoldenVectors.payloadSha256Hex,
                       "SHA-256 of the legacy preimage must match the golden vector")
    }

    func testLegacySignatureByteIdentity() throws {
        let entry = try makeTestEntry(
            credentialsAddress: GoldenVectors.signerAccountId,
            invocationContractId: GoldenVectors.contractId,
            nonce: GoldenVectors.nonce,
            expirationLedger: GoldenVectors.expirationLedger
        )

        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        let encoded = try XDREncoder.encode(preimage)
        let payload = Data(bytes: encoded, count: encoded.count).sha256Hash
        let sig = signer.sign([UInt8](payload))
        let actualHex = sig.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(actualHex, GoldenVectors.signatureHex,
                       "Ed25519 signature over the legacy payload must match the golden vector")
    }

    func testSignedEntryByteIdentity() throws {
        // Stale expiration 0 in credentials; sign() stamps the new value 4242.
        var entry = try makeGoldenEntry(expirationLedger: 0)

        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try entry.sign(signer: signer, network: GoldenVectors.network,
                       signatureExpirationLedger: GoldenVectors.expirationLedger)

        let encoded = try XDREncoder.encode(entry)
        let actualB64 = Data(encoded).base64EncodedString()
        XCTAssertEqual(actualB64, GoldenVectors.signedEntryB64,
                       "Full signed entry XDR must match the golden vector")
    }

    // MARK: - Preimage discriminant per arm

    func testPreimageDiscriminantLegacy() throws {
        let entry = try makeContractEntry(credentialArm: .legacy)
        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        if case .sorobanAuthorization = preimage { /* correct */ } else {
            XCTFail("Legacy arm must produce sorobanAuthorization preimage")
        }
    }

    func testPreimageDiscriminantV2() throws {
        let entry = try makeContractEntry(credentialArm: .v2)
        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        if case .sorobanAuthorizationWithAddress = preimage { /* correct */ } else {
            XCTFail("V2 arm must produce sorobanAuthorizationWithAddress preimage")
        }
    }

    func testPreimageDiscriminantWithDelegates() throws {
        let entry = try makeContractEntry(credentialArm: .withDelegates)
        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        if case .sorobanAuthorizationWithAddress = preimage { /* correct */ } else {
            XCTFail("WITH_DELEGATES arm must produce sorobanAuthorizationWithAddress preimage")
        }
    }

    // MARK: - ADDRESS vs ADDRESS_V2 preimages differ for identical fields

    func testAddressAndV2PreimagesDiffer() throws {
        let legacyEntry = try makeContractEntry(nonce: 42, expirationLedger: 100, credentialArm: .legacy)
        let v2Entry = try makeContractEntry(nonce: 42, expirationLedger: 100, credentialArm: .v2)
        let legacyPreimage = try legacyEntry.buildPreimage(network: GoldenVectors.network)
        let v2Preimage = try v2Entry.buildPreimage(network: GoldenVectors.network)
        let legacyBytes = try XDREncoder.encode(legacyPreimage)
        let v2Bytes = try XDREncoder.encode(v2Preimage)
        XCTAssertNotEqual(Data(legacyBytes), Data(v2Bytes),
                          "ADDRESS and ADDRESS_V2 preimages must differ (different discriminants)")
    }

    // MARK: - Preimage address == TOP-LEVEL credential address for WITH_DELEGATES

    func testWithDelegatesPreimageUsesTopLevelAddress() throws {
        // Top-level credentials address is a CONTRACT; the delegate is an ACCOUNT.
        // The preimage must bind the top-level contract address, not the delegate's.
        let topContractId = GoldenVectors.contractId
        let delegateAccountId = GoldenVectors.signerAccountId

        let sourceEntry = try makeContractEntry(
            contractId: topContractId, nonce: 77, expirationLedger: 500
        )
        let treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [SorobanDelegateDescriptor(address: delegateAccountId)],
            expirationLedger: 500
        )

        let preimage = try treeEntry.buildPreimage(network: GoldenVectors.network)
        guard case .sorobanAuthorizationWithAddress(let body) = preimage else {
            XCTFail("WITH_DELEGATES preimage must be sorobanAuthorizationWithAddress")
            return
        }

        let topAddress = try SCAddressXDR(contractId: topContractId)
        let topAddressBytes = try XDREncoder.encode(topAddress)
        let preimageAddressBytes = try XDREncoder.encode(body.address)
        XCTAssertEqual(Data(topAddressBytes), Data(preimageAddressBytes),
                       "Preimage address must be the top-level credential address, not a delegate's")
    }

    // MARK: - Expiration-before-hash regression

    func testExpirationStampedBeforeHash() throws {
        // Build entry with stale expiration 0.
        var entry = try makeGoldenEntry(expirationLedger: 0)

        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try entry.sign(signer: signer, network: GoldenVectors.network,
                       signatureExpirationLedger: GoldenVectors.expirationLedger)

        // The credentials now carry the updated expiration. Extract the signature from
        // the signed entry and confirm it equals the golden value, which proves that sign()
        // hashed the UPDATED expiration (not the stale one that was in the entry beforehand).

        // Extract the signature from the signed entry.
        guard let creds = entry.credentials.address,
              let sigVec = creds.signature.vec,
              let firstSig = sigVec.first,
              let sigMapEntries = firstSig.map,
              let sigEntry = sigMapEntries.first(where: { $0.key.symbol == "signature" }),
              let sigData = sigEntry.val.bytes else {
            XCTFail("Could not extract signature from signed entry")
            return
        }

        // Verify ed25519 signature against the payload built from the UPDATED credentials.
        let actualHex = [UInt8](sigData).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(actualHex, GoldenVectors.signatureHex,
                       "Signature must verify against the preimage built with the updated expiration")
        XCTAssertEqual(creds.signatureExpirationLedger, GoldenVectors.expirationLedger)
    }

    // MARK: - Credential extraction helpers

    func testAddressCredentialsExtractedFromAllArms() throws {
        let legacyEntry = try makeContractEntry(credentialArm: .legacy)
        XCTAssertNotNil(legacyEntry.credentials.addressCredentials, "Legacy arm must return addressCredentials")
        XCTAssertNotNil(legacyEntry.credentials.address, "Legacy arm must return .address property")

        let v2Entry = try makeContractEntry(credentialArm: .v2)
        XCTAssertNotNil(v2Entry.credentials.addressCredentials, "V2 arm must return addressCredentials")
        XCTAssertNil(v2Entry.credentials.address, ".address property must be nil for V2 arm")

        let withDelegatesEntry = try makeContractEntry(credentialArm: .withDelegates)
        XCTAssertNotNil(withDelegatesEntry.credentials.addressCredentials,
                        "WITH_DELEGATES arm must return addressCredentials")
        XCTAssertNil(withDelegatesEntry.credentials.address,
                     ".address property must be nil for WITH_DELEGATES arm")
    }

    func testAddressCredentialsNilForSourceAccount() {
        let creds = SorobanCredentialsXDR.sourceAccount
        XCTAssertNil(creds.addressCredentials, "sourceAccount must return nil addressCredentials")
        XCTAssertNil(creds.address, "sourceAccount must return nil .address")
    }

    func testWithAddressCredentialsPreservesArm() throws {
        let newCreds = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: GoldenVectors.contractId),
            nonce: 99,
            signatureExpirationLedger: 200,
            signature: .void
        )

        let legacyCreds = SorobanCredentialsXDR.address(newCreds)
        let updatedLegacy = try legacyCreds.withAddressCredentials(newCreds)
        if case .address = updatedLegacy { /* correct */ } else {
            XCTFail("withAddressCredentials must preserve the legacy arm")
        }

        let v2Creds = SorobanCredentialsXDR.addressV2(newCreds)
        let updatedV2 = try v2Creds.withAddressCredentials(newCreds)
        if case .addressV2 = updatedV2 { /* correct */ } else {
            XCTFail("withAddressCredentials must preserve the V2 arm")
        }

        let withDelegatesCreds = SorobanCredentialsXDR.addressWithDelegates(
            SorobanAddressCredentialsWithDelegatesXDR(addressCredentials: newCreds, delegates: [])
        )
        let updatedWithDelegates = try withDelegatesCreds.withAddressCredentials(newCreds)
        if case .addressWithDelegates(let inner) = updatedWithDelegates {
            XCTAssertEqual(inner.delegates.count, 0, "Delegates must be preserved when replacing addressCredentials")
        } else {
            XCTFail("withAddressCredentials must preserve the WITH_DELEGATES arm")
        }
    }

    func testWithAddressCredentialsThrowsForSourceAccount() {
        let creds = SorobanCredentialsXDR.sourceAccount
        let newInner = SorobanAddressCredentialsXDR(
            address: .contract(WrappedData32(Data(repeating: 0, count: 32))),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        XCTAssertThrowsError(try creds.withAddressCredentials(newInner))
    }

    // MARK: - Source-account sign attempt throws descriptively

    func testSignThrowsForSourceAccountCredentials() throws {
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: GoldenVectors.contractId),
                functionName: "f",
                args: []
            )),
            subInvocations: []
        )
        var entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )
        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        XCTAssertThrowsError(
            try entry.sign(signer: signer, network: GoldenVectors.network,
                           signatureExpirationLedger: 100)
        ) { error in
            guard case StellarSDKError.invalidArgument = error else {
                XCTFail("Expected StellarSDKError.invalidArgument, got \(error)")
                return
            }
        }
    }

    func testBuildPreimageThrowsForSourceAccount() throws {
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: GoldenVectors.contractId),
                functionName: "f",
                args: []
            )),
            subInvocations: []
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )
        XCTAssertThrowsError(try entry.buildPreimage(network: GoldenVectors.network))
    }

    // MARK: - Void top-level signature preserved

    func testVoidTopLevelSignaturePreservedForWithDelegates() throws {
        let sourceEntry = try makeContractEntry(credentialArm: .legacy)
        let treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [SorobanDelegateDescriptor(address: GoldenVectors.signerAccountId)],
            expirationLedger: 100
        )

        if case .addressWithDelegates(let wd) = treeEntry.credentials {
            XCTAssertTrue(wd.addressCredentials.signature.isVoid,
                          "Top-level signature must be void on a freshly-built WITH_DELEGATES entry")
        } else {
            XCTFail("Expected WITH_DELEGATES credentials")
        }
    }

    // MARK: - Append semantics

    func testAppendToVoidSignatureYieldsOneElementVector() throws {
        var entry = try makeGoldenEntry(expirationLedger: 100)
        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try entry.sign(signer: signer, network: GoldenVectors.network,
                       signatureExpirationLedger: 100)

        guard let creds = entry.credentials.address,
              let vec = creds.signature.vec else {
            XCTFail("Expected vec signature after first sign")
            return
        }
        XCTAssertEqual(vec.count, 1, "Appending to void must yield a one-element vector")
    }

    func testAppendToExistingVectorGrowsIt() throws {
        var entry = try makeGoldenEntry(expirationLedger: 100)
        let signer1 = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        let signer2 = try KeyPair.generateRandomKeyPair()

        try entry.sign(signer: signer1, network: GoldenVectors.network, signatureExpirationLedger: 100)
        try entry.sign(signer: signer2, network: GoldenVectors.network)

        guard let creds = entry.credentials.address,
              let vec = creds.signature.vec else {
            XCTFail("Expected vec signature")
            return
        }
        XCTAssertEqual(vec.count, 2, "Second sign must grow the vector to 2 elements")
    }

    // MARK: - forAddress routing

    func testForAddressThrowsWhenNoNodeMatches() throws {
        var entry = try makeContractEntry()
        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        // The entry's credentials address is a C-address; the G-address won't match.
        XCTAssertThrowsError(
            try entry.sign(signer: signer, network: GoldenVectors.network,
                           signatureExpirationLedger: 100,
                           forAddress: GoldenVectors.signerAccountId)
        ) { error in
            guard case StellarSDKError.invalidArgument = error else {
                XCTFail("Expected StellarSDKError.invalidArgument for unmatched forAddress")
                return
            }
        }
    }

    func testForAddressSignsTopLevelWhenItMatches() throws {
        // Credentials address is the signer's account; pass it as forAddress.
        var entry = try makeGoldenEntry(expirationLedger: 100)
        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try entry.sign(signer: signer, network: GoldenVectors.network,
                       signatureExpirationLedger: 100,
                       forAddress: GoldenVectors.signerAccountId)

        guard let creds = entry.credentials.address,
              let vec = creds.signature.vec else {
            XCTFail("Expected vec signature after forAddress sign")
            return
        }
        XCTAssertEqual(vec.count, 1, "Signature must land on the top-level node when addresses match")
    }

    // MARK: - Nested tree: signing into delegate nodes

    func testNestedTreeSignDelegateViaForAddress() throws {
        // Top-level credentials: contract address; delegate: signer's account address.
        let sourceEntry = try makeContractEntry(nonce: 55, expirationLedger: 200)
        var treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [SorobanDelegateDescriptor(address: GoldenVectors.signerAccountId)],
            expirationLedger: 200
        )

        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try treeEntry.sign(signer: signer, network: GoldenVectors.network,
                           signatureExpirationLedger: 200,
                           forAddress: GoldenVectors.signerAccountId)

        guard case .addressWithDelegates(let wd) = treeEntry.credentials else {
            XCTFail("Expected WITH_DELEGATES credentials")
            return
        }
        // Top-level must remain void; delegate must have a signature.
        XCTAssertTrue(wd.addressCredentials.signature.isVoid,
                      "Top-level must remain void when forAddress targets a delegate")
        guard let delegateVec = wd.delegates.first?.signature.vec else {
            XCTFail("Expected delegate signature vector")
            return
        }
        XCTAssertEqual(delegateVec.count, 1, "Delegate must have exactly one signature element")
    }

    func testNestedTreeAllSignersSeeTheSamePayloadHash() throws {
        // Build a WITH_DELEGATES entry: top-level signer (nil forAddress = top-level node)
        // and a delegate signer (forAddress = GoldenVectors.signerAccountId).
        // Both must sign and verify against exactly the same preimage hash.
        let sourceEntry = try makeTestEntry(
            credentialsAddress: GoldenVectors.signerAccountId,
            invocationContractId: GoldenVectors.contractId,
            nonce: GoldenVectors.nonce,
            expirationLedger: GoldenVectors.expirationLedger,
            credentialArm: .v2
        )
        let delegateAccountId = GoldenVectors.signerAccountId
        var treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [SorobanDelegateDescriptor(address: delegateAccountId)],
            expirationLedger: GoldenVectors.expirationLedger
        )

        // Build the canonical preimage hash once from the final credentials.
        let preimage = try treeEntry.buildPreimage(network: GoldenVectors.network)
        let encoded = try XDREncoder.encode(preimage)
        let payloadHash = Data(bytes: encoded, count: encoded.count).sha256Hash

        // Sign as top-level (nil forAddress).
        let topSigner = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try treeEntry.sign(signer: topSigner, network: GoldenVectors.network,
                           signatureExpirationLedger: GoldenVectors.expirationLedger)

        // Sign as delegate (forAddress = signerAccountId).
        let delegateSigner = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try treeEntry.sign(signer: delegateSigner, network: GoldenVectors.network,
                           signatureExpirationLedger: GoldenVectors.expirationLedger,
                           forAddress: delegateAccountId)

        // Extract top-level signature from the WITH_DELEGATES credentials.
        guard case .addressWithDelegates(let wd) = treeEntry.credentials,
              let topSigVec = wd.addressCredentials.signature.vec,
              let topSigEntry = topSigVec.first,
              let topSigMap = topSigEntry.map,
              let topSigEntry2 = topSigMap.first(where: { $0.key.symbol == "signature" }),
              let topSigBytes = topSigEntry2.val.bytes else {
            XCTFail("Cannot extract top-level signature from WITH_DELEGATES entry")
            return
        }

        // Extract delegate signature.
        guard let delegateNode = wd.delegates.first,
              let delegateSigVec = delegateNode.signature.vec,
              let delegateSigEntry = delegateSigVec.first,
              let delegateSigMap = delegateSigEntry.map,
              let delegateSigEntry2 = delegateSigMap.first(where: { $0.key.symbol == "signature" }),
              let delegateSigBytes = delegateSigEntry2.val.bytes else {
            XCTFail("Cannot extract delegate signature from WITH_DELEGATES entry")
            return
        }

        // Verify both signatures against the SAME payload hash.
        let verified = try topSigner.verify(
            signature: [UInt8](topSigBytes),
            message: [UInt8](payloadHash)
        )
        XCTAssertTrue(verified,
                      "Top-level signature must verify against the preimage hash")

        let delegateVerified = try delegateSigner.verify(
            signature: [UInt8](delegateSigBytes),
            message: [UInt8](payloadHash)
        )
        XCTAssertTrue(delegateVerified,
                      "Delegate signature must verify against the same preimage hash")
    }

    // MARK: - Delegate tree sorting by XDR bytes (account before contract)

    func testDelegateSortingPutsAccountBeforeContract() throws {
        // G-address (account, SCAddressType discriminant 0) must sort BEFORE C-address
        // (contract, SCAddressType discriminant 1) when delegates are sorted by XDR bytes.
        // Strkey ordering would place the C-address first ("C" < "G"); XDR byte ordering
        // places accounts first (discriminant 0 < 1).
        let accountId = GoldenVectors.signerAccountId
        let contractAddress = GoldenVectors.contractId

        let sourceEntry = try makeContractEntry()
        // Supply contract BEFORE account; after sort the account must come first.
        let treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [
                SorobanDelegateDescriptor(address: contractAddress),
                SorobanDelegateDescriptor(address: accountId)
            ],
            expirationLedger: 100
        )

        guard case .addressWithDelegates(let wd) = treeEntry.credentials else {
            XCTFail("Expected WITH_DELEGATES")
            return
        }
        XCTAssertEqual(wd.delegates.count, 2)
        if case .account = wd.delegates[0].address { /* correct */ } else {
            XCTFail("Account address must sort before contract address (XDR-byte ordering)")
        }
    }

    // MARK: - Duplicate rejection

    func testDuplicateDelegateInSameArrayThrows() throws {
        let sourceEntry = try makeContractEntry()
        XCTAssertThrowsError(
            try SorobanAuthorizationEntryXDR.withDelegates(
                entry: sourceEntry,
                delegates: [
                    SorobanDelegateDescriptor(address: GoldenVectors.signerAccountId),
                    SorobanDelegateDescriptor(address: GoldenVectors.signerAccountId)
                ],
                expirationLedger: 100
            )
        ) { error in
            guard case StellarSDKError.invalidArgument = error else {
                XCTFail("Expected StellarSDKError.invalidArgument for duplicate delegate")
                return
            }
        }
    }

    func testSameAddressAtDifferentNestingLevelsIsAccepted() throws {
        // The same address appearing at two different nesting levels is legal.
        // Only within-array duplicates are rejected.
        let accountId = GoldenVectors.signerAccountId
        let sourceEntry = try makeContractEntry()
        XCTAssertNoThrow(
            try SorobanAuthorizationEntryXDR.withDelegates(
                entry: sourceEntry,
                delegates: [
                    SorobanDelegateDescriptor(
                        address: accountId,
                        nestedDelegates: [SorobanDelegateDescriptor(address: accountId)]
                    )
                ],
                expirationLedger: 100
            )
        )
    }

    // MARK: - withDelegates rejects already-WITH_DELEGATES source

    func testWithDelegatesRejectsAlreadyWithDelegatesInput() throws {
        let sourceEntry = try makeContractEntry(credentialArm: .withDelegates)
        XCTAssertThrowsError(
            try SorobanAuthorizationEntryXDR.withDelegates(
                entry: sourceEntry,
                delegates: [],
                expirationLedger: 100
            )
        ) { error in
            guard case StellarSDKError.invalidArgument = error else {
                XCTFail("Expected StellarSDKError.invalidArgument for WITH_DELEGATES source")
                return
            }
        }
    }

    // MARK: - Arm preservation through sign

    func testSignPreservesLegacyArm() throws {
        var entry = try makeGoldenEntry(expirationLedger: 100, credentialArm: .legacy)
        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try entry.sign(signer: signer, network: GoldenVectors.network,
                       signatureExpirationLedger: 100)
        if case .address = entry.credentials { /* correct */ } else {
            XCTFail("sign() must preserve the legacy arm")
        }
    }

    func testSignPreservesV2Arm() throws {
        var entry = try makeGoldenEntry(expirationLedger: 100, credentialArm: .v2)
        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try entry.sign(signer: signer, network: GoldenVectors.network,
                       signatureExpirationLedger: 100)
        if case .addressV2 = entry.credentials { /* correct */ } else {
            XCTFail("sign() must preserve the V2 arm")
        }
    }

    func testSignPreservesWithDelegatesArm() throws {
        let sourceEntry = try makeContractEntry()
        var treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [SorobanDelegateDescriptor(address: GoldenVectors.signerAccountId)],
            expirationLedger: 100
        )
        let signer = try KeyPair(secretSeed: GoldenVectors.signerSeed)
        try treeEntry.sign(signer: signer, network: GoldenVectors.network,
                           signatureExpirationLedger: 100)
        if case .addressWithDelegates = treeEntry.credentials { /* correct */ } else {
            XCTFail("sign() must preserve the WITH_DELEGATES arm")
        }
    }

    // MARK: - Delegate node appendSignature semantics

    func testDelegateAppendToVoidYieldsOneElementVector() throws {
        var node = SorobanDelegateSignatureXDR(
            address: try SCAddressXDR(contractId: GoldenVectors.contractId),
            signature: .void,
            nestedDelegates: []
        )
        let sigVal = SCValXDR.bytes(Data(repeating: 0xAA, count: 64))
        node.appendSignature(signature: sigVal)
        guard let vec = node.signature.vec else {
            XCTFail("Expected vec after appendSignature on void delegate")
            return
        }
        XCTAssertEqual(vec.count, 1)
    }

    func testDelegateAppendToExistingVectorGrowsIt() throws {
        let sig1 = SCValXDR.bytes(Data(repeating: 0xAA, count: 64))
        var node = SorobanDelegateSignatureXDR(
            address: try SCAddressXDR(contractId: GoldenVectors.contractId),
            signature: .vec([sig1]),
            nestedDelegates: []
        )
        let sig2 = SCValXDR.bytes(Data(repeating: 0xBB, count: 64))
        node.appendSignature(signature: sig2)
        guard let vec = node.signature.vec else {
            XCTFail("Expected vec")
            return
        }
        XCTAssertEqual(vec.count, 2)
    }

    // MARK: - EnvelopeType+Helpers backward-compat constant

    func testEnvelopeTypeWithAddressConstantValue() {
        XCTAssertEqual(
            EnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS,
            Int32(10),
            "ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS must equal 10"
        )
    }

    // MARK: - XDR address comparator covers account-before-contract case

    func testXDRAddressComparatorAccountBeforeContract() throws {
        let accountAddress = try SCAddressXDR(accountId: GoldenVectors.signerAccountId)
        let contractAddress = try SCAddressXDR(contractId: GoldenVectors.contractId)

        // Account (discriminant 0) must sort before contract (discriminant 1).
        XCTAssertTrue(sorobanAddressXDRLessThan(accountAddress, contractAddress),
                      "Account address must sort before contract address via XDR-byte comparator")
        XCTAssertFalse(sorobanAddressXDRLessThan(contractAddress, accountAddress),
                       "Contract address must not sort before account address")
    }

    // MARK: - Empty delegate array is valid

    func testEmptyDelegateArrayIsValid() throws {
        let sourceEntry = try makeContractEntry()
        let treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [],
            expirationLedger: 100
        )
        if case .addressWithDelegates(let wd) = treeEntry.credentials {
            XCTAssertTrue(wd.delegates.isEmpty, "Empty delegate array must be preserved")
        } else {
            XCTFail("Expected WITH_DELEGATES credentials")
        }
    }

    // MARK: - Sort and validation helpers

    func testWithDelegatesMixedAddressTypes() throws {
        let sourceEntry = try makeContractEntry()
        let treeEntry = try SorobanAuthorizationEntryXDR.withDelegates(
            entry: sourceEntry,
            delegates: [
                SorobanDelegateDescriptor(address: GoldenVectors.contractId),
                SorobanDelegateDescriptor(address: GoldenVectors.signerAccountId)
            ],
            expirationLedger: 100
        )
        guard case .addressWithDelegates(let wd) = treeEntry.credentials else {
            XCTFail("Expected WITH_DELEGATES"); return
        }
        XCTAssertEqual(wd.delegates.count, 2)
    }

    func testSortTwoAddressesDirect() throws {
        let accountAddr = try SCAddressXDR(accountId: GoldenVectors.signerAccountId)
        let contractAddr = try SCAddressXDR(contractId: GoldenVectors.contractId)
        let accountNode = SorobanDelegateSignatureXDR(address: accountAddr, signature: .void, nestedDelegates: [])
        let contractNode = SorobanDelegateSignatureXDR(address: contractAddr, signature: .void, nestedDelegates: [])
        let sorted = try sortAndValidateDelegates([contractNode, accountNode])
        XCTAssertEqual(sorted.count, 2)
        if case .account = sorted[0].address { /* correct */ } else {
            XCTFail("Account must come first after sort")
        }
    }

    func testSignerAccountIdIsValid() throws {
        let addr = try SCAddressXDR(accountId: GoldenVectors.signerAccountId)
        if case .account(let pk) = addr {
            XCTAssertEqual(pk.bytes.count, 32)
        } else {
            XCTFail("Expected account address")
        }
    }

    // MARK: - Golden vector: ADDRESS_V2 (WITH_ADDRESS) preimage byte identity

    /// Verifies the XDR-encoded WITH_ADDRESS preimage matches the cross-SDK golden vector
    /// exactly. The V2 preimage differs from the legacy preimage by discriminant (10 vs 9)
    /// and by the presence of the credential address field between the expiration and
    /// invocation fields. This byte-identity test pins the field-order invariant.
    func testV2PreimageByteIdentity() throws {
        // Entry: credentials address = signerAccountId (G-address), V2 arm.
        let entry = try makeTestEntry(
            credentialsAddress: GoldenVectors.signerAccountId,
            invocationContractId: GoldenVectors.contractId,
            nonce: GoldenVectors.nonce,
            expirationLedger: GoldenVectors.expirationLedger,
            credentialArm: .v2
        )

        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        let encoded = try XDREncoder.encode(preimage)
        let actualB64 = Data(encoded).base64EncodedString()
        XCTAssertEqual(actualB64, GoldenVectors.v2PreimageB64,
                       "XDR-encoded V2 (WITH_ADDRESS) preimage must match the golden vector")
    }

    /// Verifies the SHA-256 of the WITH_ADDRESS preimage matches the cross-SDK golden
    /// constant. This is the payload that a signer's ed25519 key signs for ADDRESS_V2 and
    /// WITH_DELEGATES entries. Sibling SDK implementations must produce the same value.
    func testV2PayloadHashByteIdentity() throws {
        let entry = try makeTestEntry(
            credentialsAddress: GoldenVectors.signerAccountId,
            invocationContractId: GoldenVectors.contractId,
            nonce: GoldenVectors.nonce,
            expirationLedger: GoldenVectors.expirationLedger,
            credentialArm: .v2
        )

        let preimage = try entry.buildPreimage(network: GoldenVectors.network)
        let encoded = try XDREncoder.encode(preimage)
        let hash = Data(bytes: encoded, count: encoded.count).sha256Hash
        let actualHex = hash.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(actualHex, GoldenVectors.v2PayloadSha256Hex,
                       "SHA-256 of the V2 (WITH_ADDRESS) preimage must match the golden vector")
    }

    // MARK: - Deep-recursion XDR roundtrip (3-level nested delegates)

    /// Verifies that a delegate tree with 3 levels of nesting encodes to XDR and decodes
    /// back identically. The generated TxRep roundtrip tests use empty delegate arrays;
    /// this test exercises the recursive XDR codecs under real nesting depth.
    func testDeepNestedDelegatesXDRRoundtrip() throws {
        // Level 3 (deepest)
        let level3Address = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
        let level3Addr = try SCAddressXDR(contractId: level3Address)
        let level3Node = SorobanDelegateSignatureXDR(
            address: level3Addr,
            signature: .void,
            nestedDelegates: []
        )

        // Level 2
        let level2Addr = try SCAddressXDR(accountId: GoldenVectors.signerAccountId)
        let level2Node = SorobanDelegateSignatureXDR(
            address: level2Addr,
            signature: .void,
            nestedDelegates: [level3Node]
        )

        // Level 1 (top-level delegate in the WITH_DELEGATES entry)
        let level1ContractId = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
        let level1Addr = try SCAddressXDR(contractId: level1ContractId)
        let level1Node = SorobanDelegateSignatureXDR(
            address: level1Addr,
            signature: .void,
            nestedDelegates: [level2Node]
        )

        let innerCreds = SorobanAddressCredentialsXDR(
            address: level1Addr,
            nonce: 42,
            signatureExpirationLedger: 1000,
            signature: .void
        )
        let withDelegates = SorobanAddressCredentialsWithDelegatesXDR(
            addressCredentials: innerCreds,
            delegates: [level1Node]
        )

        // XDR roundtrip: encode then decode and compare.
        let encodedBytes = try XDREncoder.encode(withDelegates)
        let decoded = try SorobanAddressCredentialsWithDelegatesXDR(
            from: XDRDecoder(data: encodedBytes)
        )
        let reEncodedBytes = try XDREncoder.encode(decoded)
        XCTAssertEqual(Data(encodedBytes), Data(reEncodedBytes),
                       "3-level nested delegate tree must survive XDR encode/decode roundtrip")

        // Verify the nesting depth survived.
        XCTAssertEqual(decoded.delegates.count, 1, "Top-level must have 1 delegate")
        XCTAssertEqual(decoded.delegates[0].nestedDelegates.count, 1, "Level 1 must have 1 nested delegate")
        XCTAssertEqual(decoded.delegates[0].nestedDelegates[0].nestedDelegates.count, 1,
                       "Level 2 must have 1 nested delegate")
        XCTAssertTrue(decoded.delegates[0].nestedDelegates[0].nestedDelegates[0].nestedDelegates.isEmpty,
                      "Level 3 (deepest) must have an empty nestedDelegates array")
    }

    // MARK: - sign() rejects signer without private key

    /// Exercises the `signer.privateKey == nil` guard in `sign()`, confirming the error
    /// is descriptive and that a public-key-only KeyPair cannot produce a signature.
    func testSignThrowsForPublicKeyOnlySigner() throws {
        var entry = try makeGoldenEntry(expirationLedger: 100)
        // Build a public-key-only KeyPair from the account ID (no private key).
        let publicOnlyPair = try KeyPair(accountId: GoldenVectors.signerAccountId)
        XCTAssertNil(publicOnlyPair.privateKey, "Expected nil privateKey on public-key-only KeyPair")
        XCTAssertThrowsError(
            try entry.sign(signer: publicOnlyPair, network: GoldenVectors.network,
                           signatureExpirationLedger: 100)
        ) { error in
            guard case StellarSDKError.invalidArgument = error else {
                XCTFail("Expected StellarSDKError.invalidArgument, got \(error)")
                return
            }
        }
    }

    // MARK: - withDelegates() rejects sourceAccount credentials

    /// Exercises the `sourceCreds == nil` guard in `withDelegates(entry:delegates:expirationLedger:)`.
    /// Calling `withDelegates` on a source-account entry must throw `invalidArgument`.
    func testWithDelegatesThrowsForSourceAccountEntry() throws {
        let invocation = SorobanAuthorizedInvocationXDR(
            function: .contractFn(InvokeContractArgsXDR(
                contractAddress: try SCAddressXDR(contractId: GoldenVectors.contractId),
                functionName: "f",
                args: []
            )),
            subInvocations: []
        )
        let sourceEntry = SorobanAuthorizationEntryXDR(
            credentials: .sourceAccount,
            rootInvocation: invocation
        )
        XCTAssertThrowsError(
            try SorobanAuthorizationEntryXDR.withDelegates(
                entry: sourceEntry,
                delegates: [],
                expirationLedger: 100
            )
        ) { error in
            guard case StellarSDKError.invalidArgument = error else {
                XCTFail("Expected StellarSDKError.invalidArgument for source-account entry, got \(error)")
                return
            }
        }
    }

    // MARK: - scAddressXDR(fromStrkey:) rejects unsupported prefixes

    /// Exercises the `throw invalidArgument` path in `scAddressXDR(fromStrkey:)` for a
    /// strkey that is neither a G-address nor a C-address.
    func testScAddressXDRThrowsForUnsupportedPrefix() {
        // M-addresses (muxed accounts) are not supported.
        XCTAssertThrowsError(
            try scAddressXDR(fromStrkey: "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAPZFBVAI")
        ) { error in
            guard case StellarSDKError.invalidArgument = error else {
                XCTFail("Expected StellarSDKError.invalidArgument for M-address prefix, got \(error)")
                return
            }
        }
        // Arbitrary non-Stellar strings also must throw.
        XCTAssertThrowsError(try scAddressXDR(fromStrkey: "not-a-strkey"))
    }

    // MARK: - appendSignatureToMatchingDelegates: match only in nested delegates

    /// Exercises lines 169-170 in `appendSignatureToMatchingDelegates`: a node's address
    /// does NOT match the target at the top level but DOES match in its `nestedDelegates`.
    /// The function must report `.found` and set `anyFound = true` via the recursive path.
    func testAppendSignatureMatchOnlyInNestedDelegates() throws {
        let topContractId = GoldenVectors.contractId
        let nestedAccountId = GoldenVectors.signerAccountId

        let topAddress = try SCAddressXDR(contractId: topContractId)
        let nestedAddress = try SCAddressXDR(accountId: nestedAccountId)

        // Inner delegate whose address MATCHES the target.
        let nestedNode = SorobanDelegateSignatureXDR(
            address: nestedAddress,
            signature: .void,
            nestedDelegates: []
        )
        // Outer delegate whose address does NOT match the target, but contains the matching node.
        var outerNode = SorobanDelegateSignatureXDR(
            address: topAddress,
            signature: .void,
            nestedDelegates: [nestedNode]
        )

        // The target is the nested account address; the outer node is different.
        let sig = SCValXDR.bytes(Data(repeating: 0xBE, count: 64))
        var nodes = [outerNode]
        let result = appendSignatureToMatchingDelegates(
            nodes: &nodes,
            targetAddress: nestedAddress,
            signature: sig
        )

        XCTAssertEqual(result, .found,
                       "appendSignatureToMatchingDelegates must return .found when only nested node matches")
        // The nested node must now carry the signature; the outer node must be unchanged.
        XCTAssertTrue(nodes[0].signature.isVoid,
                      "Outer node address did not match; its signature must remain void")
        guard let nestedVec = nodes[0].nestedDelegates[0].signature.vec else {
            XCTFail("Nested node must have a signature vector after appendSignature")
            return
        }
        XCTAssertEqual(nestedVec.count, 1, "Nested node must have exactly one signature element")
    }
}
