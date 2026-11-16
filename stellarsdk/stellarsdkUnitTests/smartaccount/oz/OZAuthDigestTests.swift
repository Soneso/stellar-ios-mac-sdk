//
//  OZAuthDigestTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The two auth digest schemes of OpenZeppelin smart accounts, the stellar-accounts 0.8.0
/// `AuthDigestPreimage` and the 0.7 concatenation, against `auth_digest_cross_sdk_fixture.json`.
///
/// The fixture's preimage vectors are the smart-account-kit vectors, generated with
/// `AuthDigestPreimage { .. }.to_xdr()` and `.digest()` from OpenZeppelin/stellar-contracts@6eb047d5,
/// and the digest the `auth_digest` view of a 0.8.0 wallet on testnet returned. Its entry values
/// were computed outside the SDK with the Stellar CLI, SHA-256 and an Ed25519 library, and the
/// fixture key of `ed25519_cross_sdk_fixture.json` signed each digest.
final class OZAuthDigestTests: XCTestCase {

    private let kitAccount = "CC7EKIHQP3TN4CARQDND6CEOY2UXLWWC2X5GHTD5NLAT7BG5GPZIOM3F"
    private let otherAccount = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"

    private var fixture: [String: Any] = [:]
    private var entryFixture: [String: Any] = [:]

    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "auth_digest_cross_sdk_fixture", withExtension: "json"),
            "auth_digest_cross_sdk_fixture.json must be a resource of the test target"
        )
        fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        entryFixture = try XCTUnwrap(fixture["entry"] as? [String: Any])
    }

    // MARK: - Fixture access

    private func string(_ object: [String: Any], _ key: String) throws -> String {
        return try XCTUnwrap(object[key] as? String, "fixture field \(key)")
    }

    private func ruleIds(_ object: [String: Any]) throws -> [UInt32] {
        let values = try XCTUnwrap(object["contextRuleIds"] as? [NSNumber], "fixture field contextRuleIds")
        return values.map { $0.uint32Value }
    }

    private func scheme(_ name: String) throws -> [String: Any] {
        return try XCTUnwrap(entryFixture[name] as? [String: Any], "fixture scheme \(name)")
    }

    private func entry() throws -> SorobanAuthorizationEntryXDR {
        return try SorobanAuthorizationEntryXDR(fromBase64: try string(entryFixture, "entryXdrBase64"))
    }

    private var entryExpiration: UInt32 {
        get throws {
            return try XCTUnwrap(entryFixture["signatureExpirationLedger"] as? NSNumber).uint32Value
        }
    }

    private func digest(
        _ entry: SorobanAuthorizationEntryXDR,
        scheme: OZAuthDigestScheme,
        contextRuleIds: [UInt32]? = nil
    ) async throws -> OZEntryAuthDigest {
        return try await OZSmartAccountAuth.computeEntryAuthDigest(
            entry: entry,
            expirationLedger: try entryExpiration,
            networkPassphrase: try string(entryFixture, "networkPassphrase"),
            contextRuleIds: try contextRuleIds ?? ruleIds(entryFixture),
            scheme: scheme
        )
    }

    /// The fixture key's signature over `digest` verifies, so `digest` is the digest the
    /// fixture signed.
    private func assertFixtureSignatureVerifies(
        _ scheme: [String: Any],
        digest: Data,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let publicKey = try PublicKey([UInt8](try Data(base16Encoded: try string(entryFixture, "ed25519PublicKeyHex"))))
        let signature = try Data(base16Encoded: try string(scheme, "ed25519SignatureHex"))
        let verifier = KeyPair(publicKey: publicKey, privateKey: nil)
        XCTAssertTrue(
            try verifier.verify(signature: [UInt8](signature), message: [UInt8](digest)),
            "the fixture signature must verify over \(digest.base16EncodedString())",
            file: file,
            line: line
        )
    }

    private func xdrBase64(_ values: [SCValXDR]) throws -> [String] {
        return try values.map { try OZIndependentAuthDigest.xdr($0).base64EncodedString() }
    }

    // MARK: - Preimage builder against the kit vectors and the live view

    func test_buildAuthDigestPreimage_fixtureVectors_matchContractEncodingAndDigest() throws {
        let vectors = try XCTUnwrap(fixture["preimageVectors"] as? [[String: Any]])
        XCTAssertEqual(vectors.count, 4, "three kit vectors and the live auth_digest reading")
        for vector in vectors {
            let name = try string(vector, "name")
            let preimage = try OZSmartAccountAuth.buildAuthDigestPreimage(
                account: try SCAddressXDR(contractId: try string(vector, "account")),
                signaturePayload: try Data(base16Encoded: try string(vector, "signaturePayloadHex")),
                contextRuleIds: try ruleIds(vector)
            )
            let preimageXdr = try OZIndependentAuthDigest.xdr(preimage)
            XCTAssertEqual(preimageXdr.base16EncodedString(), try string(vector, "preimageXdrHex"), "preimage XDR for \(name)")
            XCTAssertEqual(preimageXdr.sha256Hash.base16EncodedString(), try string(vector, "authDigestHex"), "preimage digest for \(name)")
        }
    }

    func test_buildAuthDigestPreimage_ruleIdsZeroAndUInt32Max_areEncodedAsU32() throws {
        let payload = Data(repeating: 0x5A, count: 32)
        let preimage = try OZSmartAccountAuth.buildAuthDigestPreimage(
            account: try SCAddressXDR(contractId: kitAccount),
            signaturePayload: payload,
            contextRuleIds: [0, UInt32.max]
        )
        XCTAssertEqual(
            try OZIndependentAuthDigest.xdr(preimage),
            try OZIndependentAuthDigest.xdr(
                try OZIndependentAuthDigest.preimage(account: kitAccount, signaturePayload: payload, contextRuleIds: [0, UInt32.max])
            )
        )
    }

    func test_buildAuthDigestPreimage_payloadNot32Bytes_throwsInvalidInput() throws {
        for size in [0, 31, 33] {
            XCTAssertThrowsError(
                try OZSmartAccountAuth.buildAuthDigestPreimage(
                    account: try SCAddressXDR(contractId: kitAccount),
                    signaturePayload: Data(count: size),
                    contextRuleIds: [0]
                )
            ) { error in
                guard let invalid = error as? SmartAccountValidationException.InvalidInput else {
                    return XCTFail("expected InvalidInput for \(size) bytes, got \(error)")
                }
                XCTAssertEqual(invalid.message, "Invalid input for signaturePayload: Signature payload must be 32 bytes, got \(size)")
            }
        }
    }

    // MARK: - computeEntryAuthDigest against the entry fixture

    func test_computeEntryAuthDigest_preimageScheme_matchesIndependentlyComputedValues() async throws {
        let preimageV1 = try scheme("preimageV1")
        let digest = try await digest(try entry(), scheme: .preimageV1)

        XCTAssertEqual(digest.signaturePayload.base16EncodedString(), try string(entryFixture, "signaturePayloadHex"))
        XCTAssertEqual(digest.authDigest.base16EncodedString(), try string(preimageV1, "authDigestHex"))
        XCTAssertEqual(
            try xdrBase64(digest.delegatedAuthArgs),
            try XCTUnwrap(preimageV1["delegatedAuthArgsXdrBase64"] as? [String]),
            "the delegated __check_auth argument is the preimage"
        )
        try assertFixtureSignatureVerifies(preimageV1, digest: digest.authDigest)
    }

    func test_computeEntryAuthDigest_legacyScheme_matchesIndependentlyComputedValues() async throws {
        let legacyConcat = try scheme("legacyConcat")
        let digest = try await digest(try entry(), scheme: .legacyConcat)

        XCTAssertEqual(digest.signaturePayload.base16EncodedString(), try string(entryFixture, "signaturePayloadHex"))
        XCTAssertEqual(digest.authDigest.base16EncodedString(), try string(legacyConcat, "authDigestHex"))
        XCTAssertEqual(
            try xdrBase64(digest.delegatedAuthArgs),
            try XCTUnwrap(legacyConcat["delegatedAuthArgsXdrBase64"] as? [String]),
            "the legacy delegated __check_auth argument is Bytes(auth_digest)"
        )
        try assertFixtureSignatureVerifies(legacyConcat, digest: digest.authDigest)
    }

    func test_computeEntryAuthDigest_preimageScheme_bindsTheCredentialAddressOfEveryArm() async throws {
        let fixtureEntry = try entry()
        guard case .addressV2(let credentials) = fixtureEntry.credentials else {
            return XCTFail("the fixture entry carries ADDRESS_V2 credentials")
        }
        var otherCredentials = credentials
        otherCredentials.address = try SCAddressXDR(contractId: otherAccount)
        let arms: [(String, SorobanCredentialsXDR)] = [
            ("ADDRESS", .address(otherCredentials)),
            ("ADDRESS_V2", .addressV2(otherCredentials)),
            ("ADDRESS_WITH_DELEGATES", .addressWithDelegates(
                SorobanAddressCredentialsWithDelegatesXDR(addressCredentials: otherCredentials, delegates: [])
            ))
        ]
        let ruleIds = try ruleIds(entryFixture)
        for (arm, armCredentials) in arms {
            var armEntry = fixtureEntry
            armEntry.credentials = armCredentials
            let digest = try await digest(armEntry, scheme: .preimageV1)

            let expectedPreimage = try OZIndependentAuthDigest.preimage(
                account: otherAccount,
                signaturePayload: digest.signaturePayload,
                contextRuleIds: ruleIds
            )
            XCTAssertEqual(try xdrBase64(digest.delegatedAuthArgs), try xdrBase64([expectedPreimage]), "preimage of \(arm)")
            XCTAssertEqual(
                digest.authDigest,
                try OZIndependentAuthDigest.preimageDigest(
                    account: otherAccount,
                    signaturePayload: digest.signaturePayload,
                    contextRuleIds: ruleIds
                ),
                "digest of \(arm)"
            )
            XCTAssertNotEqual(digest.authDigest.base16EncodedString(), try string(try scheme("preimageV1"), "authDigestHex"))
        }
    }

    func test_computeEntryAuthDigest_sourceAccountCredentials_throwsSigningFailed() async throws {
        var sourceEntry = try entry()
        sourceEntry.credentials = .sourceAccount
        for scheme in [OZAuthDigestScheme.legacyConcat, .preimageV1] {
            do {
                _ = try await digest(sourceEntry, scheme: scheme)
                XCTFail("expected SigningFailed for \(scheme)")
            } catch let error as SmartAccountTransactionException.SigningFailed {
                XCTAssertTrue(
                    error.message.contains("Credentials must be of an address type"),
                    "unexpected message: \(error.message)"
                )
            }
        }
    }

    @available(*, deprecated)
    func test_buildAuthDigest_equalsTheLegacySchemeDigest() async throws {
        let payload = try Data(base16Encoded: try string(entryFixture, "signaturePayloadHex"))
        let digest = try await OZSmartAccountAuth.buildAuthDigest(
            signaturePayload: payload,
            contextRuleIds: try ruleIds(entryFixture)
        )
        XCTAssertEqual(digest.base16EncodedString(), try string(try scheme("legacyConcat"), "authDigestHex"))
    }
}
