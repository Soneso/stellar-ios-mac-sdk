//
//  Ed25519FixtureEmitter.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Emits the shared Ed25519 auth-digest fixture used as a byte-equivalence
//  reference for downstream consumers.
//
//  The fixture is written to a repo-relative path inside the SDK test tree:
//
//    stellarsdk/stellarsdkUnitTests/smartaccount/oz/fixtures/ed25519_cross_sdk_fixture.json
//
//  This test is gated behind the REGENERATE_ED25519_FIXTURE environment
//  variable. Under normal CI and local runs it is skipped automatically.
//  To regenerate:
//
//    REGENERATE_ED25519_FIXTURE=1 \
//    swift test --filter "stellarsdkUnitTests.*Ed25519Fixture"
//
//  After regenerating, copy the file to any downstream SDK that consumes the
//  same byte-equivalence fixture (for example the Flutter SDK at
//  stellar_flutter_sdk/test/fixtures/ed25519_cross_sdk_fixture.json) and commit
//  both copies together to keep them in sync.
//

import XCTest
@testable import stellarsdk
final class Ed25519FixtureEmitter: XCTestCase {

    // MARK: - Fixture constants

    private let networkPassphrase = "Test SDF Network ; September 2015"

    // Valid C-strkeys — base32 alphabet A-Z + 2-7, no 0/1/8/9.
    private static let verifierAddressAlpha = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private static let verifierAddressBeta  = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"

    // Fixed nonce and expiration (deterministic, not tied to live network).
    private static let nonce: Int64 = 987654321
    private static let signatureExpirationLedger: UInt32 = 500000

    // MARK: - Helpers

    private func buildInvocation(contractAddress: String) throws -> SorobanAuthorizedInvocationXDR {
        let scAddress = try SCAddressXDR(contractId: contractAddress)
        let invokeArgs = InvokeContractArgsXDR(
            contractAddress: scAddress,
            functionName: "noop",
            args: []
        )
        return SorobanAuthorizedInvocationXDR(
            function: .contractFn(invokeArgs),
            subInvocations: []
        )
    }

    private func invocationBase64(_ invocation: SorobanAuthorizedInvocationXDR) throws -> String {
        return Data(try XDREncoder.encode(invocation)).base64EncodedString()
    }

    private func computeAuthDigest(
        nonce: Int64,
        signatureExpirationLedger: UInt32,
        invocation: SorobanAuthorizedInvocationXDR,
        networkPassphrase: String,
        contextRuleIds: [UInt32]
    ) throws -> (
        preimageXdrBase64: String,
        authDigestHex: String,
        payloadHash: Data
    ) {
        let networkIdBytes = networkPassphrase.sha256Hash
        let authPreimage = HashIDPreimageSorobanAuthorizationXDR(
            networkID: HashXDR(networkIdBytes),
            nonce: nonce,
            signatureExpirationLedger: signatureExpirationLedger,
            invocation: invocation
        )
        let preimage = HashIDPreimageXDR.sorobanAuthorization(authPreimage)
        let preimageBytes = try XDREncoder.encode(preimage)
        let preimageXdrBase64 = Data(preimageBytes).base64EncodedString()
        let payloadHash = Data(preimageBytes).sha256Hash

        let ruleIdsScVal: SCValXDR = .vec(contextRuleIds.map { SCValXDR.u32($0) })
        let ruleIdsXdr = Data(try XDREncoder.encode(ruleIdsScVal))
        var concatenated = Data()
        concatenated.append(payloadHash)
        concatenated.append(ruleIdsXdr)
        let authDigest = concatenated.sha256Hash
        let authDigestHex = authDigest.map { String(format: "%02x", $0) }.joined()

        return (preimageXdrBase64, authDigestHex, payloadHash)
    }

    private func buildAuthPayloadScvalBase64(
        keypair: KeyPair,
        verifierAddress: String,
        authDigest: Data,
        nonce: Int64,
        expirationLedger: UInt32,
        invocation: SorobanAuthorizedInvocationXDR,
        contextRuleIds: [UInt32]
    ) async throws -> String {
        let publicKeyBytes = Data(keypair.publicKey.bytes)
        let sigBytes = keypair.sign([UInt8](authDigest))
        let rawSig = Data(sigBytes)

        let ed25519Sig = try OZEd25519Signature(publicKey: publicKeyBytes, signature: rawSig)
        let ed25519Signer = try OZExternalSigner.ed25519(verifierAddress: verifierAddress, publicKey: publicKeyBytes)

        let entryAddress = try SCAddressXDR(contractId: verifierAddress)
        let emptyCredentials = SorobanAddressCredentialsXDR(
            address: entryAddress,
            nonce: nonce,
            signatureExpirationLedger: expirationLedger,
            signature: .map([])
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .address(emptyCredentials),
            rootInvocation: invocation
        )

        let signedEntry = try await OZSmartAccountAuth.signAuthEntry(
            entry: entry,
            signer: ed25519Signer,
            signature: ed25519Sig,
            expirationLedger: expirationLedger,
            contextRuleIds: contextRuleIds
        )

        guard case .address(let creds) = signedEntry.credentials else {
            XCTFail("Expected address credentials in signed entry")
            return ""
        }
        return Data(try XDREncoder.encode(creds.signature)).base64EncodedString()
    }

    // MARK: - Fixture emission

    func test_emitEd25519FixtureFile_runOnceToRegenerate() async throws {
        guard ProcessInfo.processInfo.environment["REGENERATE_ED25519_FIXTURE"] != nil else {
            throw XCTSkip(
                "Set REGENERATE_ED25519_FIXTURE=1 to regenerate the shared Ed25519 " +
                "auth-digest fixture file at " +
                "stellarsdk/stellarsdkUnitTests/smartaccount/oz/fixtures/ed25519_cross_sdk_fixture.json."
            )
        }
        let fixturePath = "stellarsdk/stellarsdkUnitTests/smartaccount/oz/fixtures/ed25519_cross_sdk_fixture.json"

        // Generate a deterministic keypair from raw seed bytes 0x00..0x1F.
        // Bytes are identical to ed25519SecretBytes used throughout the unit tests.
        let rawSeedA = Data(0x00 ..< 0x20)
        let seedA = try Seed(bytes: [UInt8](rawSeedA))
        let keypairA = KeyPair(seed: seedA)
        let pubKeyA = Data(keypairA.publicKey.bytes)
        let pubKeyHexA = pubKeyA.map { String(format: "%02x", $0) }.joined()
        let secretKeyHexA = rawSeedA.map { String(format: "%02x", $0) }.joined()

        let invAlpha = try buildInvocation(contractAddress: Ed25519FixtureEmitter.verifierAddressAlpha)
        let invBeta  = try buildInvocation(contractAddress: Ed25519FixtureEmitter.verifierAddressBeta)

        // Row 1: single signer, verifierAddressAlpha, contextRuleIds=[0].
        let (pre1, dig1, payloadHash1) = try computeAuthDigest(
            nonce: Ed25519FixtureEmitter.nonce,
            signatureExpirationLedger: Ed25519FixtureEmitter.signatureExpirationLedger,
            invocation: invAlpha,
            networkPassphrase: networkPassphrase,
            contextRuleIds: [0]
        )
        let ruleIds1ScVal: SCValXDR = .vec([.u32(0)])
        let ruleIds1Xdr = Data(try XDREncoder.encode(ruleIds1ScVal))
        var conc1 = Data(); conc1.append(payloadHash1); conc1.append(ruleIds1Xdr)
        let authDigestData1 = conc1.sha256Hash
        let payload1 = try await buildAuthPayloadScvalBase64(
            keypair: keypairA,
            verifierAddress: Ed25519FixtureEmitter.verifierAddressAlpha,
            authDigest: authDigestData1,
            nonce: Ed25519FixtureEmitter.nonce,
            expirationLedger: Ed25519FixtureEmitter.signatureExpirationLedger,
            invocation: invAlpha,
            contextRuleIds: [0]
        )

        // Row 2: two signers same verifier, contextRuleIds=[0,1], nonce+1.
        let (pre2, dig2, payloadHash2) = try computeAuthDigest(
            nonce: Ed25519FixtureEmitter.nonce + 1,
            signatureExpirationLedger: Ed25519FixtureEmitter.signatureExpirationLedger,
            invocation: invAlpha,
            networkPassphrase: networkPassphrase,
            contextRuleIds: [0, 1]
        )
        let ruleIds2ScVal: SCValXDR = .vec([.u32(0), .u32(1)])
        let ruleIds2Xdr = Data(try XDREncoder.encode(ruleIds2ScVal))
        var conc2 = Data(); conc2.append(payloadHash2); conc2.append(ruleIds2Xdr)
        let authDigestData2 = conc2.sha256Hash
        let payload2 = try await buildAuthPayloadScvalBase64(
            keypair: keypairA,
            verifierAddress: Ed25519FixtureEmitter.verifierAddressAlpha,
            authDigest: authDigestData2,
            nonce: Ed25519FixtureEmitter.nonce + 1,
            expirationLedger: Ed25519FixtureEmitter.signatureExpirationLedger,
            invocation: invAlpha,
            contextRuleIds: [0, 1]
        )

        // Row 3: same pubkey, different verifier (verifierAddressBeta), contextRuleIds=[0], nonce+2.
        let (pre3, dig3, payloadHash3) = try computeAuthDigest(
            nonce: Ed25519FixtureEmitter.nonce + 2,
            signatureExpirationLedger: Ed25519FixtureEmitter.signatureExpirationLedger,
            invocation: invBeta,
            networkPassphrase: networkPassphrase,
            contextRuleIds: [0]
        )
        let ruleIds3ScVal: SCValXDR = .vec([.u32(0)])
        let ruleIds3Xdr = Data(try XDREncoder.encode(ruleIds3ScVal))
        var conc3 = Data(); conc3.append(payloadHash3); conc3.append(ruleIds3Xdr)
        let authDigestData3 = conc3.sha256Hash
        let payload3 = try await buildAuthPayloadScvalBase64(
            keypair: keypairA,
            verifierAddress: Ed25519FixtureEmitter.verifierAddressBeta,
            authDigest: authDigestData3,
            nonce: Ed25519FixtureEmitter.nonce + 2,
            expirationLedger: Ed25519FixtureEmitter.signatureExpirationLedger,
            invocation: invBeta,
            contextRuleIds: [0]
        )

        let fixture: [[String: Any]] = [
            [
                "description": "single Ed25519 signer, verifierAddressAlpha, contextRuleIds=[0]",
                "inputs": [
                    "networkPassphrase": networkPassphrase,
                    "nonce": Ed25519FixtureEmitter.nonce,
                    "signatureExpirationLedger": Ed25519FixtureEmitter.signatureExpirationLedger,
                    "invocationXdrBase64": try invocationBase64(invAlpha),
                    "contextRuleIds": [0]
                ] as [String: Any],
                "signerInfo": [
                    "verifierAddress": Ed25519FixtureEmitter.verifierAddressAlpha,
                    "publicKeyHex": pubKeyHexA,
                    "secretKeyHex": secretKeyHexA
                ] as [String: Any],
                "outputs": [
                    "authPreimageXdrBase64": pre1,
                    "authDigestSha256Hex": dig1,
                    "authPayloadSignatureScvalXdrBase64": payload1
                ] as [String: Any]
            ],
            [
                "description": "two signers same verifier, contextRuleIds=[0,1]",
                "inputs": [
                    "networkPassphrase": networkPassphrase,
                    "nonce": Ed25519FixtureEmitter.nonce + 1,
                    "signatureExpirationLedger": Ed25519FixtureEmitter.signatureExpirationLedger,
                    "invocationXdrBase64": try invocationBase64(invAlpha),
                    "contextRuleIds": [0, 1]
                ] as [String: Any],
                "signerInfo": [
                    "verifierAddress": Ed25519FixtureEmitter.verifierAddressAlpha,
                    "publicKeyHex": pubKeyHexA,
                    "secretKeyHex": secretKeyHexA
                ] as [String: Any],
                "outputs": [
                    "authPreimageXdrBase64": pre2,
                    "authDigestSha256Hex": dig2,
                    "authPayloadSignatureScvalXdrBase64": payload2
                ] as [String: Any]
            ],
            [
                "description": "same pubkey different verifier (verifierAddressBeta), contextRuleIds=[0]",
                "inputs": [
                    "networkPassphrase": networkPassphrase,
                    "nonce": Ed25519FixtureEmitter.nonce + 2,
                    "signatureExpirationLedger": Ed25519FixtureEmitter.signatureExpirationLedger,
                    "invocationXdrBase64": try invocationBase64(invBeta),
                    "contextRuleIds": [0]
                ] as [String: Any],
                "signerInfo": [
                    "verifierAddress": Ed25519FixtureEmitter.verifierAddressBeta,
                    "publicKeyHex": pubKeyHexA,
                    "secretKeyHex": secretKeyHexA
                ] as [String: Any],
                "outputs": [
                    "authPreimageXdrBase64": pre3,
                    "authDigestSha256Hex": dig3,
                    "authPayloadSignatureScvalXdrBase64": payload3
                ] as [String: Any]
            ]
        ]

        let jsonData = try JSONSerialization.data(
            withJSONObject: fixture,
            options: [.prettyPrinted, .sortedKeys]
        )
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            XCTFail("Failed to encode fixture JSON as UTF-8")
            return
        }

        let fixtureDir = (fixturePath as NSString).deletingLastPathComponent
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fixtureDir, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            XCTFail(
                "Destination directory does not exist: \(fixtureDir). " +
                "Create it before running the fixture emitter."
            )
            return
        }
        try jsonString.write(toFile: fixturePath, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fixturePath))
        XCTAssertFalse(dig1.isEmpty)
        XCTAssertFalse(dig2.isEmpty)
        XCTAssertFalse(dig3.isEmpty)
        // The three rows must produce distinct auth digests.
        XCTAssertNotEqual(dig1, dig2)
        XCTAssertNotEqual(dig1, dig3)
        XCTAssertNotEqual(dig2, dig3)
    }
}
