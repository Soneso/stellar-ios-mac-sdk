//
//  OZContextRuleExternalRefTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The `CreateContractExternalRef` context rule type of stellar-accounts 0.8.0: its encoding,
/// parsing, builder, the extraction from both create-contract arms and the rule matching.
final class OZContextRuleExternalRefTests: XCTestCase {

    private let wallet = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"
    private let owner = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let otherOwner = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    /// One owner of every address kind the contract stores.
    private let ownersOfEveryKind = [
        "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK",
        "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
        "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU",
        "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN",
        "WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG"
    ]

    /// The same visible text in two Unicode forms: precomposed and decomposed.
    private let precomposedTag = "\u{00E9}"
    private let decomposedTag = "e\u{0301}"

    // MARK: - Helpers

    private func config() throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: owner
        )
    }

    private func manager() throws -> OZContextRuleManager {
        let kit = MockOZSmartAccountKit(config: try config())
        kit.setConnectedState(credentialId: "test-credential-id", contractId: wallet)
        return OZContextRuleManager(kit: kit)
    }

    private func rule(_ id: UInt32, _ contextType: OZContextRuleType) -> OZParsedContextRule {
        return OZParsedContextRule(
            id: id,
            contextType: contextType,
            name: "rule-\(id)",
            signers: [],
            signerIds: [],
            policies: [],
            policyIds: [],
            validUntil: nil
        )
    }

    private func ruleScVal(id: UInt32, contextType: SCValXDR) -> SCValXDR {
        return .map([
            SCMapEntryXDR(key: .symbol("context_type"), val: contextType),
            SCMapEntryXDR(key: .symbol("id"), val: .u32(id)),
            SCMapEntryXDR(key: .symbol("name"), val: .string("rule-\(id)")),
            SCMapEntryXDR(key: .symbol("policies"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policy_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("signer_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("signers"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("valid_until"), val: .void)
        ])
    }

    private func externalRefContextType(owner: SCAddressXDR, tag: String) -> SCValXDR {
        return .vec([.symbol("CreateContractExternalRef"), .address(owner), .string(tag)])
    }

    private func externalRefExecutable(owner: String, tagBytes: Data) throws -> ContractExecutableXDR {
        return .externalRef(
            ContractExecutableExternalRefXDR(
                executableOwner: try SCAddressXDR.fromXdrJsonValue(.string(owner)),
                tag: tagBytes
            )
        )
    }

    private func createEntry(
        executable: ContractExecutableXDR,
        v2: Bool = true,
        asSubInvocation: Bool = false
    ) throws -> SorobanAuthorizationEntryXDR {
        let preimage = ContractIDPreimageXDR.fromAddress(
            ContractIDPreimageFromAddressXDR(
                address: try SCAddressXDR(contractId: wallet),
                salt: WrappedData32(Data(repeating: 0, count: 32))
            )
        )
        let function: SorobanAuthorizedFunctionXDR = v2
            ? .createContractV2HostFn(
                CreateContractV2ArgsXDR(contractIDPreimage: preimage, executable: executable, constructorArgs: [])
            )
            : .createContractHostFn(CreateContractArgsXDR(contractIDPreimage: preimage, executable: executable))
        let createInvocation = SorobanAuthorizedInvocationXDR(function: function, subInvocations: [])
        let rootInvocation: SorobanAuthorizedInvocationXDR
        if asSubInvocation {
            rootInvocation = SorobanAuthorizedInvocationXDR(
                function: .contractFn(
                    InvokeContractArgsXDR(contractAddress: try SCAddressXDR(contractId: owner), functionName: "deploy", args: [])
                ),
                subInvocations: [createInvocation]
            )
        } else {
            rootInvocation = createInvocation
        }
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: wallet),
            nonce: 0,
            signatureExpirationLedger: 0,
            signature: .void
        )
        return SorobanAuthorizationEntryXDR(credentials: .address(credentials), rootInvocation: rootInvocation)
    }

    private func resolve(
        _ entry: SorobanAuthorizationEntryXDR,
        rules: [OZParsedContextRule]
    ) async throws -> [UInt32] {
        return try await manager().resolveContextRuleIdsForEntry(entry: entry, signers: [], contextRules: rules)
    }

    private func assertNoRuleMatches(
        _ entry: SorobanAuthorizationEntryXDR,
        rules: [OZParsedContextRule],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        do {
            _ = try await resolve(entry, rules: rules)
            XCTFail("expected no rule to match", file: file, line: line)
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(error.message.contains("No context rule matches"), "unexpected message: \(error.message)", file: file, line: line)
        }
    }

    // MARK: - Encoding

    func test_toScVal_encodesSymbolOwnerAndTag() throws {
        let scVal = try OZContextRuleType.createContractExternalRef(owner: owner, tag: "v1").toScVal()
        XCTAssertEqual(
            try OZIndependentAuthDigest.xdr(scVal),
            try OZIndependentAuthDigest.xdr(externalRefContextType(owner: try SCAddressXDR(contractId: owner), tag: "v1"))
        )
    }

    func test_toScVal_invalidOwner_throwsInvalidAddressNamingIt() {
        XCTAssertThrowsError(try OZContextRuleType.createContractExternalRef(owner: "not-an-address", tag: "v1").toScVal()) { error in
            guard let invalid = error as? SmartAccountValidationException.InvalidAddress else {
                return XCTFail("expected InvalidAddress, got \(error)")
            }
            XCTAssertTrue(invalid.message.contains("not-an-address"), "unexpected message: \(invalid.message)")
        }
    }

    // MARK: - Parsing

    func test_parseContextRule_externalRef_roundTripsForEveryOwnerKind() throws {
        let manager = try manager()
        for ownerStrKey in ownersOfEveryKind {
            let ruleType = OZContextRuleType.createContractExternalRef(owner: ownerStrKey, tag: "v1")
            let parsed = try manager.parseContextRule(scVal: ruleScVal(id: 3, contextType: try ruleType.toScVal()))
            XCTAssertEqual(parsed.contextType, ruleType, "round trip of owner \(ownerStrKey)")
            guard case .createContractExternalRef(let parsedOwner, _) = parsed.contextType else {
                return XCTFail("expected the external reference case for \(ownerStrKey)")
            }
            XCTAssertEqual(parsedOwner, ownerStrKey)
        }
    }

    func test_parseContextRule_tagForms_keepTheirBytes() throws {
        let manager = try manager()
        for tag in [precomposedTag, decomposedTag] {
            let encoded = try OZContextRuleType.createContractExternalRef(owner: owner, tag: tag).toScVal()
            guard case .vec(let elements)? = Optional(encoded), case .string(let encodedTag) = elements?[2] else {
                return XCTFail("the tag must be encoded as a String element")
            }
            XCTAssertEqual(Array(encodedTag.utf8), Array(tag.utf8))

            let parsed = try manager.parseContextRule(scVal: ruleScVal(id: 1, contextType: encoded))
            guard case .createContractExternalRef(_, let parsedTag) = parsed.contextType else {
                return XCTFail("expected the external reference case")
            }
            XCTAssertEqual(Array(parsedTag.utf8), Array(tag.utf8), "the round trip keeps the bytes of \(Array(tag.utf8))")
        }
    }

    func test_parseContextRule_externalRefWithoutTag_throwsNamingTheElementCount() throws {
        let contextType: SCValXDR = .vec([.symbol("CreateContractExternalRef"), .address(try SCAddressXDR(contractId: owner))])
        XCTAssertThrowsError(try manager().parseContextRule(scVal: ruleScVal(id: 1, contextType: contextType))) { error in
            guard let invalid = error as? SmartAccountValidationException.InvalidInput else {
                return XCTFail("expected InvalidInput, got \(error)")
            }
            XCTAssertTrue(
                invalid.message.contains("CreateContractExternalRef context_type needs an owner and a tag element, got 1 element(s)"),
                "unexpected message: \(invalid.message)"
            )
        }
    }

    func test_parseContextRule_externalRefOwnerNotAnAddress_throws() throws {
        let contextType: SCValXDR = .vec([.symbol("CreateContractExternalRef"), .string(owner), .string("v1")])
        XCTAssertThrowsError(try manager().parseContextRule(scVal: ruleScVal(id: 1, contextType: contextType))) { error in
            guard let invalid = error as? SmartAccountValidationException.InvalidInput else {
                return XCTFail("expected InvalidInput, got \(error)")
            }
            XCTAssertTrue(
                invalid.message.contains("Expected Address for CreateContractExternalRef owner"),
                "unexpected message: \(invalid.message)"
            )
        }
    }

    func test_parseContextRule_externalRefTagNotAString_throws() throws {
        let contextType: SCValXDR = .vec([
            .symbol("CreateContractExternalRef"),
            .address(try SCAddressXDR(contractId: owner)),
            .bytes(Data("v1".utf8))
        ])
        XCTAssertThrowsError(try manager().parseContextRule(scVal: ruleScVal(id: 1, contextType: contextType))) { error in
            guard let invalid = error as? SmartAccountValidationException.InvalidInput else {
                return XCTFail("expected InvalidInput, got \(error)")
            }
            XCTAssertTrue(
                invalid.message.contains("Expected String for CreateContractExternalRef tag"),
                "unexpected message: \(invalid.message)"
            )
        }
    }

    func test_parseContextRule_unknownDiscriminant_stillThrows() throws {
        let contextType: SCValXDR = .vec([.symbol("CreateContractFromAsset"), .string("v1")])
        XCTAssertThrowsError(try manager().parseContextRule(scVal: ruleScVal(id: 1, contextType: contextType))) { error in
            guard let invalid = error as? SmartAccountValidationException.InvalidInput else {
                return XCTFail("expected InvalidInput, got \(error)")
            }
            XCTAssertTrue(
                invalid.message.contains("Unknown context_type discriminant: CreateContractFromAsset"),
                "unexpected message: \(invalid.message)"
            )
        }
    }

    // MARK: - Builder

    func test_builder_contractOwner_buildsTheRuleType() throws {
        XCTAssertEqual(
            try OZBuilders.createCreateContractExternalRefContextType(owner: owner, tag: "v1"),
            .createContractExternalRef(owner: owner, tag: "v1")
        )
    }

    func test_builder_ownerThatIsNoContract_throwsInvalidAddress() {
        for nonContract in ownersOfEveryKind where !nonContract.hasPrefix("C") {
            XCTAssertThrowsError(try OZBuilders.createCreateContractExternalRefContextType(owner: nonContract, tag: "v1")) { error in
                guard let invalid = error as? SmartAccountValidationException.InvalidAddress else {
                    return XCTFail("expected InvalidAddress for \(nonContract), got \(error)")
                }
                XCTAssertTrue(
                    invalid.message.contains("owner must be a valid contract address (C...), got: \(nonContract)"),
                    "unexpected message: \(invalid.message)"
                )
            }
        }
    }

    // MARK: - Equality

    func test_equality_ownerAndTagBothCount() {
        let ruleType = OZContextRuleType.createContractExternalRef(owner: owner, tag: "v1")
        XCTAssertEqual(ruleType, .createContractExternalRef(owner: owner, tag: "v1"))
        XCTAssertEqual(ruleType.hashValue, OZContextRuleType.createContractExternalRef(owner: owner, tag: "v1").hashValue)
        XCTAssertNotEqual(ruleType, .createContractExternalRef(owner: otherOwner, tag: "v1"))
        XCTAssertNotEqual(ruleType, .createContractExternalRef(owner: owner, tag: "v2"))
        XCTAssertNotEqual(ruleType, .callContract(contractAddress: owner))
        XCTAssertNotEqual(ruleType, .defaultRule)
    }

    func test_equality_tagsCompareByUtf8Bytes() {
        XCTAssertEqual(precomposedTag, decomposedTag, "Swift String equality treats both forms as equal")
        let precomposed = OZContextRuleType.createContractExternalRef(owner: owner, tag: precomposedTag)
        let decomposed = OZContextRuleType.createContractExternalRef(owner: owner, tag: decomposedTag)
        XCTAssertNotEqual(precomposed, decomposed)
        XCTAssertEqual(Set([precomposed, decomposed]).count, 2)
        let samePrecomposed = OZContextRuleType.createContractExternalRef(owner: owner, tag: "\u{00E9}")
        XCTAssertEqual(precomposed, samePrecomposed)
        XCTAssertEqual(precomposed.hashValue, samePrecomposed.hashValue)
    }

    // MARK: - Resolution

    func test_resolve_createContractV1WithExternalRef_matchesTheEqualRule() async throws {
        let entry = try createEntry(executable: try externalRefExecutable(owner: owner, tagBytes: Data("v1".utf8)), v2: false)
        let ids = try await resolve(entry, rules: [
            rule(4, .createContractExternalRef(owner: otherOwner, tag: "v1")),
            rule(5, .createContractExternalRef(owner: owner, tag: "v1"))
        ])
        XCTAssertEqual(ids, [5])
    }

    func test_resolve_createContractV2WithExternalRef_matchesTheEqualRule() async throws {
        let entry = try createEntry(executable: try externalRefExecutable(owner: owner, tagBytes: Data("v1".utf8)))
        let ids = try await resolve(entry, rules: [
            rule(5, .createContractExternalRef(owner: owner, tag: "v1")),
            rule(6, .createContractExternalRef(owner: owner, tag: "v2"))
        ])
        XCTAssertEqual(ids, [5])
    }

    func test_resolve_externalRefInASubInvocation_isExtracted() async throws {
        let entry = try createEntry(
            executable: try externalRefExecutable(owner: owner, tagBytes: Data("v1".utf8)),
            asSubInvocation: true
        )
        let ids = try await resolve(entry, rules: [
            rule(1, .callContract(contractAddress: owner)),
            rule(2, .createContractExternalRef(owner: owner, tag: "v1"))
        ])
        XCTAssertEqual(ids, [1, 2])
    }

    func test_resolve_ownerOfEveryKind_isKeptAsItsStrKey() async throws {
        for ownerStrKey in ownersOfEveryKind {
            let entry = try createEntry(executable: try externalRefExecutable(owner: ownerStrKey, tagBytes: Data("v1".utf8)))
            let ids = try await resolve(entry, rules: [
                rule(7, .createContractExternalRef(owner: ownerStrKey, tag: "v1")),
                rule(8, .createContractExternalRef(owner: otherOwner, tag: "v1"))
            ])
            XCTAssertEqual(ids, [7], "owner \(ownerStrKey)")
        }
    }

    func test_resolve_tagForms_pickTheRuleWithTheSameBytes() async throws {
        let rules = [
            rule(10, .createContractExternalRef(owner: owner, tag: precomposedTag)),
            rule(11, .createContractExternalRef(owner: owner, tag: decomposedTag))
        ]
        let precomposedEntry = try createEntry(executable: try externalRefExecutable(owner: owner, tagBytes: Data(precomposedTag.utf8)))
        let decomposedEntry = try createEntry(executable: try externalRefExecutable(owner: owner, tagBytes: Data(decomposedTag.utf8)))

        let precomposedIds = try await resolve(precomposedEntry, rules: rules)
        let decomposedIds = try await resolve(decomposedEntry, rules: rules)
        XCTAssertEqual(precomposedIds, [10])
        XCTAssertEqual(decomposedIds, [11])
    }

    func test_resolve_malformedUtf8Tag_isReadWithReplacementCharacters() async throws {
        let entry = try createEntry(executable: try externalRefExecutable(owner: owner, tagBytes: Data([0x76, 0xFF, 0x31])))
        let ids = try await resolve(entry, rules: [
            rule(12, .createContractExternalRef(owner: owner, tag: "v1")),
            rule(13, .createContractExternalRef(owner: owner, tag: "v\u{FFFD}1"))
        ])
        XCTAssertEqual(ids, [13])
    }

    func test_resolve_otherOwnerOrTagOnly_matchesNoRule() async throws {
        let entry = try createEntry(executable: try externalRefExecutable(owner: owner, tagBytes: Data("v1".utf8)))
        try await assertNoRuleMatches(entry, rules: [
            rule(1, .createContractExternalRef(owner: otherOwner, tag: "v1")),
            rule(2, .createContractExternalRef(owner: owner, tag: "v2"))
        ])
    }

    func test_resolve_externalRefWithOnlyADefaultRule_usesTheDefault() async throws {
        let entry = try createEntry(executable: try externalRefExecutable(owner: owner, tagBytes: Data("v1".utf8)))
        let ids = try await resolve(entry, rules: [rule(0, .defaultRule)])
        XCTAssertEqual(ids, [0])
    }

    func test_resolve_wasmHashCreate_doesNotMatchAnExternalRefRule() async throws {
        let entry = try createEntry(executable: OZAuthDigestWasm.v080)
        try await assertNoRuleMatches(entry, rules: [rule(1, .createContractExternalRef(owner: owner, tag: "v1"))])
    }

    func test_resolve_stellarAssetCreate_stillThrows() async throws {
        let entry = try createEntry(executable: .token)
        do {
            _ = try await resolve(entry, rules: [rule(0, .defaultRule)])
            XCTFail("expected InvalidInput")
        } catch let error as SmartAccountValidationException.InvalidInput {
            XCTAssertTrue(
                error.message.contains("CreateContract invocation references a Stellar Asset Contract, not a WASM contract"),
                "unexpected message: \(error.message)"
            )
        }
    }

    // MARK: - Signing with such a rule listed

    /// A wallet that lists a `CreateContractExternalRef` rule next to its Default rule signs a
    /// contract call with the Default rule, without a resolver.
    func test_submit_withoutResolver_listedExternalRefRule_parsesAndTheDefaultRuleSigns() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }
        let deployer = try KeyPair.generateRandomKeyPair()
        let provider = RecordingWebAuthnProvider()
        let storage = OZInMemoryStorageAdapter()
        let credentialId = "aGVsbG8tc21hcnQtYWNjb3VudA"
        var publicKey = [UInt8](repeating: 0x42, count: 65)
        publicKey[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        try await storage.save(credential: OZStoredCredential(credentialId: credentialId, publicKey: Data(publicKey), contractId: wallet))
        let config = try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: owner,
            deployerKeypair: deployer,
            webauthnProvider: provider,
            storage: storage
        )
        let kit = OZSmartAccountKit(
            config: config,
            storage: storage,
            sorobanServer: MockSorobanServer.makeMockedSorobanServer(),
            relayerClient: nil,
            indexerClient: nil
        )
        kit.setConnectedState(credentialId: credentialId, contractId: wallet)

        let entry = try OZPipelineFixtures.addressCredentialsAuthEntry(contractAddress: wallet, targetContract: otherOwner)
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 3)
        script.enqueueSimulate(authEntries: [entry])
        try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.v080, latestLedger: 1000)
        script.enqueueSimulate(resultXdr: SCValXDR.u32(2).xdrEncoded ?? "")
        script.enqueueSimulate(resultXdr: ruleScVal(
            id: 0,
            contextType: externalRefContextType(owner: try SCAddressXDR(contractId: owner), tag: "v1")
        ).xdrEncoded ?? "")
        script.enqueueSimulate(resultXdr: ruleScVal(id: 1, contextType: .vec([.symbol("Default")])).xdrEncoded ?? "")
        provider.enqueueAuthenticate(
            RecordingWebAuthnFixtures.authenticationResult(credentialId: try Data(base64URLEncoded: credentialId))
        )
        script.enqueueSimulateError("stop after signing")

        do {
            _ = try await kit.transactionOperations.submit(
                hostFunction: .invokeContract(
                    InvokeContractArgsXDR(contractAddress: try SCAddressXDR(contractId: otherOwner), functionName: "noop", args: [])
                ),
                auth: []
            )
            XCTFail("expected the scripted re-simulation failure")
        } catch let error as SmartAccountTransactionException.SimulationFailed {
            XCTAssertTrue(error.message.contains("stop after signing"), "unexpected message: \(error.message)")
        }

        let payload = try await OZSmartAccountAuth.buildAuthPayloadHash(
            entry: entry,
            expirationLedger: UInt32(1000 + StellarProtocolConstants.ledgersPerHour),
            networkPassphrase: Network.testnet.passphrase
        )
        XCTAssertEqual(provider.authenticateCalls.count, 1)
        XCTAssertEqual(
            try XCTUnwrap(provider.authenticateCalls.first).challenge,
            try OZIndependentAuthDigest.preimageDigest(account: wallet, signaturePayload: payload, contextRuleIds: [1])
        )
    }
}
