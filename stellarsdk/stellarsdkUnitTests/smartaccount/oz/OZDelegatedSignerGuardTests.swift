//
//  OZDelegatedSignerGuardTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// The delegated signer guard (GHSA-jpg9-m7w4-c7wc): a delegated signer the SDK adds, or signs
/// an addition of, must be a Stellar account other than the shared default deployer, and never
/// the wallet itself. Signers that are already on chain are read without a check.
final class OZDelegatedSignerGuardTests: XCTestCase {

    private let wallet = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let otherContract = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"
    private let verifier = "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
    private let account = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"

    /// The SEP-23 muxed account of `account` with id 0.
    private let muxedAccount = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"

    /// A SEP-23 muxed contract address (`W…`).
    private let muxedContract = "WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG"

    private let claimableBalance = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
    private let liquidityPool = "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"

    private var passkeyKey: Data {
        var bytes = [UInt8](repeating: 0x42, count: 65)
        bytes[0] = SmartAccountConstants.uncompressedPubkeyPrefix
        return Data(bytes)
    }

    // MARK: - Raw signer values and calls

    private func address(_ strKey: String) throws -> SCAddressXDR {
        return try SCAddressXDR.fromXdrJsonValue(.string(strKey))
    }

    private func delegated(_ strKey: String) throws -> SCValXDR {
        return OZPipelineFixtures.rawDelegatedSigner(try address(strKey))
    }

    private func external(_ keyData: Data, verifierAddress: String? = nil) throws -> SCValXDR {
        return OZPipelineFixtures.rawExternalSigner(try address(verifierAddress ?? verifier), keyData: keyData)
    }

    private func call(_ target: String, _ functionName: String, _ args: [SCValXDR]) throws -> SorobanAuthorizedFunctionXDR {
        return .contractFn(
            InvokeContractArgsXDR(contractAddress: try SCAddressXDR(contractId: target), functionName: functionName, args: args)
        )
    }

    private func addSigner(_ signer: SCValXDR, target: String? = nil) throws -> SorobanAuthorizedFunctionXDR {
        return try call(target ?? wallet, "add_signer", [.u32(0), signer])
    }

    private func batchAddSigner(_ signers: [SCValXDR]) throws -> SorobanAuthorizedFunctionXDR {
        return try call(wallet, "batch_add_signer", [.u32(0), .vec(signers)])
    }

    private func addContextRule(_ signers: SCValXDR) throws -> SorobanAuthorizedFunctionXDR {
        return try call(wallet, "add_context_rule", [.vec([.symbol("Default")]), .string("rule"), .void, signers, .map([])])
    }

    private func entry(
        _ function: SorobanAuthorizedFunctionXDR,
        subInvocations: [SorobanAuthorizedInvocationXDR] = []
    ) throws -> SorobanAuthorizationEntryXDR {
        let credentials = SorobanAddressCredentialsXDR(
            address: try SCAddressXDR(contractId: wallet),
            nonce: 1,
            signatureExpirationLedger: 0,
            signature: .void
        )
        return SorobanAuthorizationEntryXDR(
            credentials: .address(credentials),
            rootInvocation: SorobanAuthorizedInvocationXDR(function: function, subInvocations: subInvocations)
        )
    }

    private func check(_ function: SorobanAuthorizedFunctionXDR) async throws {
        try await requireValidAddedSigners(entry: try entry(function), walletContractId: wallet)
    }

    private func defaultDeployer() async throws -> String {
        return try await OZSmartAccountConfig.createDefaultDeployer().accountId
    }

    private func contractDelegateMessage(_ strKey: String) -> String {
        return "A delegated signer must be a Stellar account (G-address), got: \(strKey). Delegating to a contract can let anyone authorize the account."
    }

    private func ownDelegateMessage() -> String {
        return "The smart account \(wallet) cannot be its own delegated signer"
    }

    private func deployerMessage(_ deployer: String) -> String {
        return "The shared default deployer \(deployer) cannot be a delegated signer: its secret derives from a public string, so anyone could authorize the account through it"
    }

    /// Runs `block` and asserts it throws an error of type `E` whose message contains `expected`.
    private func assertThrows<E: SmartAccountException>(
        _ type: E.Type,
        containing expected: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: () async throws -> Void
    ) async {
        do {
            try await block()
            XCTFail("expected \(E.self) containing \"\(expected)\"", file: file, line: line)
        } catch let error as E {
            XCTAssertTrue(error.message.contains(expected), "unexpected message: \(error.message)", file: file, line: line)
        } catch {
            XCTFail("expected \(E.self), got \(error)", file: file, line: line)
        }
    }

    // MARK: - requireValidAddedSigners

    func test_rawAddSigner_contractDelegate_isRefusedNamingIt() async {
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            try await self.check(try self.addSigner(try self.delegated(self.otherContract)))
        }
    }

    func test_rawAddSigner_walletAsItsOwnDelegate_isRefused() async {
        await assertThrows(SmartAccountValidationException.InvalidInput.self, containing: ownDelegateMessage()) {
            try await self.check(try self.addSigner(try self.delegated(self.wallet)))
        }
    }

    func test_rawAddSigner_defaultDeployer_isRefused() async throws {
        let deployer = try await defaultDeployer()
        await assertThrows(SmartAccountValidationException.InvalidInput.self, containing: deployerMessage(deployer)) {
            try await self.check(try self.addSigner(try self.delegated(deployer)))
        }
    }

    func test_rawAddSigner_accountDelegateAndExternalSigner_pass() async throws {
        try await check(try addSigner(try delegated(account)))
        try await check(try addSigner(try external(passkeyKey)))
    }

    func test_rawAddSigner_externalSignerWithOversizedKey_isRefused() async {
        await assertThrows(
            SmartAccountValidationException.InvalidInput.self,
            containing: "External signer key data cannot exceed \(OZConstants.maxExternalKeySize) bytes, got: 257"
        ) {
            try await self.check(try self.addSigner(try self.external(Data(count: 257))))
        }
    }

    func test_rawAddSigner_externalSignerAtTheKeySizeLimit_passes() async throws {
        try await check(try addSigner(try external(Data(count: OZConstants.maxExternalKeySize))))
    }

    func test_rawBatchAddSigner_oneContractDelegateAmongAccounts_isRefused() async throws {
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            try await self.check(try self.batchAddSigner([try self.delegated(self.account), try self.delegated(self.otherContract)]))
        }
        try await check(try batchAddSigner([try delegated(account), try external(passkeyKey)]))
    }

    func test_rawAddContextRule_signersArgument_isChecked() async throws {
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            try await self.check(try self.addContextRule(.vec([try self.delegated(self.otherContract)])))
        }
        try await check(try addContextRule(.vec([try delegated(account)])))
    }

    // The raw path applies the contract's and the kit's rules to the signer fields, not the
    // checks of the typed signers.

    func test_rawExternalSignerWithEmptyKeyData_passesInEverySignerAddingCall() async throws {
        let empty = try external(Data())
        try await check(try addSigner(empty))
        try await check(try batchAddSigner([empty]))
        try await check(try addContextRule(.vec([empty])))
    }

    func test_rawExternalSignerWithAnAccountVerifier_passes() async throws {
        try await check(try addSigner(try external(passkeyKey, verifierAddress: account)))
    }

    func test_rawDelegatedMuxedAccount_isRefusedByTheAccountRule() async {
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(muxedAccount)) {
            try await self.check(try self.addSigner(try self.delegated(self.muxedAccount)))
        }
    }

    func test_rawDelegatedMuxedContract_isRefusedAsAnUnsupportedAddressType() async {
        await assertThrows(
            SmartAccountValidationException.InvalidInput.self,
            containing: "Delegated signer address has an unsupported address type: SC_ADDRESS_TYPE_MUXED_CONTRACT, got: \(muxedContract)"
        ) {
            try await self.check(try self.addSigner(try self.delegated(self.muxedContract)))
        }
    }

    func test_rawExternalVerifierMuxedContract_isRefusedAsAnUnsupportedAddressType() async throws {
        let signer = try external(passkeyKey, verifierAddress: muxedContract)
        for function in [try addSigner(signer), try batchAddSigner([signer]), try addContextRule(.vec([signer]))] {
            await assertThrows(
                SmartAccountValidationException.InvalidInput.self,
                containing: "External signer verifier address has an unsupported address type: SC_ADDRESS_TYPE_MUXED_CONTRACT, got: \(muxedContract)"
            ) {
                try await self.check(function)
            }
        }
    }

    func test_rawSignerAddressTypesTheKitConverts_pass() async throws {
        for verifierAddress in [account, verifier, muxedAccount, claimableBalance, liquidityPool] {
            try await check(try addSigner(try external(passkeyKey, verifierAddress: verifierAddress)))
        }
        try await check(try addSigner(try delegated(account)))
    }

    func test_rawAddSigner_nestedInASubInvocation_isRefused() async throws {
        let nested = SorobanAuthorizedInvocationXDR(
            function: try call(otherContract, "route", []),
            subInvocations: [
                SorobanAuthorizedInvocationXDR(function: try addSigner(try delegated(otherContract)), subInvocations: [])
            ]
        )
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            try await requireValidAddedSigners(
                entry: try self.entry(try self.call(self.otherContract, "execute", []), subInvocations: [nested]),
                walletContractId: self.wallet
            )
        }
    }

    func test_rawAddSigner_underACreateContractInvocation_isRefused() async throws {
        let deploy = SorobanAuthorizedFunctionXDR.createContractV2HostFn(
            CreateContractV2ArgsXDR(
                contractIDPreimage: .fromAddress(
                    ContractIDPreimageFromAddressXDR(
                        address: try SCAddressXDR(contractId: wallet),
                        salt: WrappedData32(Data(count: 32))
                    )
                ),
                executable: .wasm(WrappedData32(Data(repeating: 1, count: 32))),
                constructorArgs: []
            )
        )
        let nested = SorobanAuthorizedInvocationXDR(function: try addSigner(try delegated(otherContract)), subInvocations: [])
        try await requireValidAddedSigners(entry: try entry(deploy), walletContractId: wallet)
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            try await requireValidAddedSigners(entry: try self.entry(deploy, subInvocations: [nested]), walletContractId: self.wallet)
        }
    }

    func test_rawAddSigner_onAnotherContract_isIgnored() async throws {
        try await check(try addSigner(try delegated(otherContract), target: otherContract))
    }

    func test_otherWalletFunctions_areIgnored() async throws {
        try await check(try call(wallet, "remove_signer", [.u32(0), try delegated(otherContract)]))
    }

    func test_rawCallWithAFunctionNameThatIsNotUTF8_isIgnored() async throws {
        let args: [SCValXDR] = [.u32(0), try delegated(otherContract)]
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            try await self.check(try self.call(self.wallet, "add_signer", args))
        }
        let name = Data("add_signer".utf8) + Data([0xFF])
        try await check(.contractFn(
            InvokeContractArgsXDR(contractAddress: try SCAddressXDR(contractId: wallet), functionName: name, args: args)
        ))
    }

    func test_rawListArgumentThatIsNoVec_isRefusedNamingTheCall() async throws {
        await assertThrows(
            SmartAccountValidationException.InvalidInput.self,
            containing: "batch_add_signer on \(wallet) carries SCV_U32 at argument 1, where a Vec of signers is expected"
        ) {
            try await self.check(try self.call(self.wallet, "batch_add_signer", [.u32(0), .u32(5)]))
        }
        await assertThrows(
            SmartAccountValidationException.InvalidInput.self,
            containing: "add_context_rule on \(wallet) carries SCV_STRING at argument 3, where a Vec of signers is expected"
        ) {
            try await self.check(try self.addContextRule(.string("signers")))
        }
    }

    func test_rawCallWithoutTheSignerArgument_isLeftToTheContract() async throws {
        try await check(try call(wallet, "add_signer", [.u32(0)]))
        try await check(try call(wallet, "add_context_rule", [.vec([.symbol("Default")])]))
    }

    func test_rawVecWithoutValue_countsAsEmpty() async throws {
        try await check(try call(wallet, "batch_add_signer", [.u32(0), .vec(nil)]))
    }

    func test_rawMalformedSigner_isRefused() async {
        await assertThrows(
            SmartAccountTransactionException.SigningFailed.self,
            containing: "Delegated signer second element is not an Address"
        ) {
            try await self.check(try self.addSigner(.vec([.symbol("Delegated")])))
        }
        await assertThrows(SmartAccountTransactionException.SigningFailed.self, containing: "Signer ScVal is not a non-empty Vec") {
            try await self.check(try self.addSigner(.u32(1)))
        }
        await assertThrows(SmartAccountTransactionException.SigningFailed.self, containing: "Signer ScVal is not a non-empty Vec") {
            try await self.check(try self.addSigner(.vec([])))
        }
        await assertThrows(SmartAccountTransactionException.SigningFailed.self, containing: "First element of signer Vec is not a Symbol") {
            try await self.check(try self.addSigner(.vec([.u32(0)])))
        }
        await assertThrows(SmartAccountTransactionException.SigningFailed.self, containing: "External signer Vec must hold an Address and Bytes") {
            try await self.check(try self.addSigner(.vec([.symbol("External"), .address(try SCAddressXDR(contractId: self.verifier))])))
        }
        await assertThrows(SmartAccountTransactionException.SigningFailed.self, containing: "Unknown signer type tag: 'Native'") {
            try await self.check(try self.addSigner(.vec([.symbol("Native")])))
        }
    }

    func test_rawSignerThatIsNoVec_isRefusedShowingTheValue() async throws {
        let cases: [(SCValXDR, String)] = [
            (.string("say \"hi\"\né"), #"string("say \"hi\"\né")"#),
            (.string(Data([0xFF, 0xFE]) + Data(" abc".utf8)), #"string("\xff\xfe abc")"#),
            (.u32(7), "u32(7)"),
        ]
        for (signer, shown) in cases {
            do {
                try await check(try addSigner(signer))
                XCTFail("expected SigningFailed for \(shown)")
            } catch let error as SmartAccountTransactionException.SigningFailed {
                XCTAssertEqual(error.message, "Transaction signing failed: Signer ScVal is not a non-empty Vec, got: \(shown)")
            }
        }
    }

    func test_rawSignerWithANestedString_isRefusedShowingTheString() async throws {
        let delegatedReason = "Transaction signing failed: Delegated signer second element is not an Address, got: "
        let externalReason = "Transaction signing failed: External signer Vec must hold an Address and Bytes, got: "
        let cases: [(signer: SCValXDR, message: String)] = [
            (.vec([.symbol("Delegated"), .string("x")]),
             delegatedReason + #"vec(Optional([stellarsdk.SCValXDR.symbol("Delegated"), stellarsdk.SCValXDR.string("x")]))"#),
            (.vec([.symbol("Delegated"), .string(Data([0xff]))]),
             delegatedReason + #"vec(Optional([stellarsdk.SCValXDR.symbol("Delegated"), stellarsdk.SCValXDR.string("\xff")]))"#),
            (.vec([.symbol("External"), .string("x")]),
             externalReason + #"vec(Optional([stellarsdk.SCValXDR.symbol("External"), stellarsdk.SCValXDR.string("x")]))"#),
            (.vec([.symbol("External"), .string(Data([0xff]))]),
             externalReason + #"vec(Optional([stellarsdk.SCValXDR.symbol("External"), stellarsdk.SCValXDR.string("\xff")]))"#),
        ]
        for testCase in cases {
            do {
                try await check(try addSigner(testCase.signer))
                XCTFail("expected SigningFailed for \(testCase.message)")
            } catch let error as SmartAccountTransactionException.SigningFailed {
                XCTAssertEqual(error.message, testCase.message)
            }
        }
    }

    // MARK: - requireValidSigners (typed signers)

    func test_typedSigners_contractWalletOrDefaultDeployer_areRefused() async throws {
        let deployer = try await defaultDeployer()
        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            try await requireValidSigners([try OZDelegatedSigner(address: self.otherContract)], walletContractId: self.wallet)
        }
        await assertThrows(SmartAccountValidationException.InvalidInput.self, containing: ownDelegateMessage()) {
            try await requireValidSigners([try OZDelegatedSigner(address: self.wallet)], walletContractId: self.wallet)
        }
        await assertThrows(SmartAccountValidationException.InvalidInput.self, containing: deployerMessage(deployer)) {
            try await requireValidSigners([try OZDelegatedSigner(address: deployer)], walletContractId: self.wallet)
        }
    }

    func test_typedSigners_accountDelegateAndExternalSigner_pass() async throws {
        try await requireValidSigners(
            [try OZDelegatedSigner(address: account), try OZExternalSigner(verifierAddress: verifier, keyData: passkeyKey)],
            walletContractId: wallet
        )
    }

    // MARK: - Manager entry points

    /// A connected kit on the mock RPC whose deployer account resolves and whose first
    /// simulation fails with `simulation reached`.
    private func kitReachingSimulation(script: MockSorobanServerScript) throws -> MockOZSmartAccountKit {
        let deployer = try KeyPair.generateRandomKeyPair()
        let kit = MockOZSmartAccountKit(config: try config(deployer: deployer), sorobanServer: MockSorobanServer.makeMockedSorobanServer())
        kit.configuredDeployer = deployer
        kit.setConnectedState(credentialId: "test-credential-id", contractId: wallet)
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        script.enqueueSimulateError("simulation reached")
        return kit
    }

    private func config(
        deployer: KeyPair? = nil,
        webauthnProvider: WebAuthnProvider? = nil,
        storage: OZStorageAdapter = OZInMemoryStorageAdapter()
    ) throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: "https://mock-rpc.invalid/rpc",
            networkPassphrase: Network.testnet.passphrase,
            accountWasmHash: "a" + String(repeating: "0", count: 63),
            webauthnVerifierAddress: verifier,
            deployerKeypair: deployer,
            webauthnProvider: webauthnProvider,
            storage: storage
        )
    }

    private func assertNoRequest(_ script: MockSorobanServerScript, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(script.getLedgerEntriesCallCount, 0, "no account or ledger read", file: file, line: line)
        XCTAssertEqual(script.simulateCallCount, 0, "no simulation", file: file, line: line)
        XCTAssertEqual(script.getLatestLedgerCallCount, 0, "no latest ledger read", file: file, line: line)
        XCTAssertEqual(script.sendCallCount, 0, "no submission", file: file, line: line)
    }

    func test_addDelegated_contractWalletOrDefaultDeployer_isRefusedBeforeAnyRequest() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }
        let kit = try kitReachingSimulation(script: script)
        let deployer = try await defaultDeployer()

        await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
            _ = try await kit.signerManager.addDelegated(contextRuleId: 0, address: self.otherContract)
        }
        await assertThrows(SmartAccountValidationException.InvalidInput.self, containing: ownDelegateMessage()) {
            _ = try await kit.signerManager.addDelegated(contextRuleId: 0, address: self.wallet)
        }
        await assertThrows(SmartAccountValidationException.InvalidInput.self, containing: deployerMessage(deployer)) {
            _ = try await kit.signerManager.addDelegated(contextRuleId: 0, address: deployer)
        }
        assertNoRequest(script)
    }

    func test_addDelegated_accountAddress_reachesSimulation() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }
        let kit = try kitReachingSimulation(script: script)

        await assertThrows(SmartAccountTransactionException.SimulationFailed.self, containing: "simulation reached") {
            _ = try await kit.signerManager.addDelegated(contextRuleId: 0, address: self.account)
        }
        XCTAssertEqual(script.simulateCallCount, 1)
    }

    func test_addContextRule_refusedDelegates_areRefusedBeforeAnyRequest() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }
        let manager = OZContextRuleManager(kit: try kitReachingSimulation(script: script))
        let passkey = try OZExternalSigner(verifierAddress: verifier, keyData: passkeyKey)
        let deployer = try await defaultDeployer()
        let refusals: [(OZDelegatedSigner, String)] = [
            (try OZDelegatedSigner(address: otherContract), contractDelegateMessage(otherContract)),
            (try OZDelegatedSigner(address: wallet), ownDelegateMessage()),
            (try OZDelegatedSigner(address: deployer), deployerMessage(deployer))
        ]
        for (refused, expected) in refusals {
            do {
                _ = try await manager.addContextRule(contextType: .defaultRule, name: "rule", signers: [passkey, refused])
                XCTFail("expected a refusal of \(refused.address)")
            } catch let error as SmartAccountValidationException {
                XCTAssertTrue(error.message.contains(expected), "unexpected message: \(error.message)")
                XCTAssertEqual(
                    error is SmartAccountValidationException.InvalidAddress,
                    refused.address == otherContract,
                    "a contract delegate is an InvalidAddress, the wallet and the deployer an InvalidInput"
                )
            }
        }
        assertNoRequest(script)
    }

    func test_addContextRule_accountDelegate_reachesSimulation() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }
        let manager = OZContextRuleManager(kit: try kitReachingSimulation(script: script))

        await assertThrows(SmartAccountTransactionException.SimulationFailed.self, containing: "simulation reached") {
            _ = try await manager.addContextRule(
                contextType: .defaultRule,
                name: "rule",
                signers: [try OZDelegatedSigner(address: self.account)]
            )
        }
        XCTAssertEqual(script.simulateCallCount, 1)
    }

    // MARK: - Signing pipelines refuse before any signer

    private let target = "CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK"

    private var noopHostFunction: HostFunctionXDR {
        get throws {
            return .invokeContract(InvokeContractArgsXDR(contractAddress: try SCAddressXDR(contractId: target), functionName: "noop", args: []))
        }
    }

    private func benignWalletEntry() throws -> SorobanAuthorizationEntryXDR {
        return try OZPipelineFixtures.addressCredentialsAuthEntry(contractAddress: wallet, targetContract: target)
    }

    /// Wallet entries that add a contract delegate: a root `add_signer`, a root
    /// `batch_add_signer`, and an `add_context_rule` nested under a call to another contract.
    private func refusedWalletEntries() throws -> [SorobanAuthorizationEntryXDR] {
        let contractDelegate = try delegated(otherContract)
        return [
            try OZPipelineFixtures.walletCallAuthEntry(
                wallet: wallet,
                functionName: "add_signer",
                args: [.u32(0), contractDelegate]
            ),
            try OZPipelineFixtures.walletCallAuthEntry(
                wallet: wallet,
                functionName: "batch_add_signer",
                args: [.u32(0), .vec([try delegated(account), contractDelegate])]
            ),
            try OZPipelineFixtures.walletCallAuthEntry(
                wallet: wallet,
                target: target,
                functionName: "execute",
                args: [],
                subInvocations: [
                    SorobanAuthorizedInvocationXDR(function: try addContextRule(.vec([contractDelegate])), subInvocations: [])
                ]
            )
        ]
    }

    /// Each refused entry alone, after a benign wallet entry, and after a foreign account entry.
    private func refusedOrders(foreignAccount: String) throws -> [[SorobanAuthorizationEntryXDR]] {
        return try refusedWalletEntries().flatMap { refused in
            [
                [refused],
                [try benignWalletEntry(), refused],
                [try OZPipelineFixtures.accountAuthEntry(accountId: foreignAccount, target: target), refused]
            ]
        }
    }

    func test_submit_rawContractDelegate_isRefusedBeforeAnyPasskey() async throws {
        let orders = try refusedOrders(foreignAccount: account)
        XCTAssertEqual(orders.count, 9)
        for (index, entries) in orders.enumerated() {
            let script = MockSorobanServerScript()
            MockSorobanServer.activate(script: script)
            defer {
                MockSorobanServer.deactivate()
                MockURLProtocol.reset()
            }
            let provider = RecordingWebAuthnProvider()
            let storage = OZInMemoryStorageAdapter()
            let credentialId = "aGVsbG8tc21hcnQtYWNjb3VudA"
            try await storage.save(credential: OZStoredCredential(credentialId: credentialId, publicKey: passkeyKey, contractId: wallet))
            let deployer = try KeyPair.generateRandomKeyPair()
            let kit = MockOZSmartAccountKit(
                config: try config(deployer: deployer, webauthnProvider: provider, storage: storage),
                sorobanServer: MockSorobanServer.makeMockedSorobanServer()
            )
            kit.configuredDeployer = deployer
            kit.setConnectedState(credentialId: credentialId, contractId: wallet)
            script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
            script.enqueueSimulate(authEntries: entries)
            try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.v080)

            await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
                _ = try await OZTransactionOperations(kit: kit).submit(hostFunction: try self.noopHostFunction, auth: [])
            }
            XCTAssertEqual(provider.authenticateCalls.count, 0, "no passkey for order \(index)")
            XCTAssertEqual(try script.walletInstanceReadCount(contractId: wallet), 0, "no instance read for order \(index)")
            XCTAssertEqual(script.simulateCallCount, 1, "no re-simulation for order \(index)")
        }
    }

    func test_submitWithMultipleSigners_rawContractDelegate_isRefusedBeforeAnySigner() async throws {
        let ed25519Adapter = try OZRecordingEd25519Adapter()
        let walletAdapter = try OZRecordingWalletAdapter()
        let orders = try refusedOrders(foreignAccount: walletAdapter.address)
        XCTAssertEqual(orders.count, 9)
        for (index, entries) in orders.enumerated() {
            let script = MockSorobanServerScript()
            MockSorobanServer.activate(script: script)
            defer {
                MockSorobanServer.deactivate()
                MockURLProtocol.reset()
            }
            let deployer = try KeyPair.generateRandomKeyPair()
            let kit = MockOZSmartAccountKit(config: try config(deployer: deployer), sorobanServer: MockSorobanServer.makeMockedSorobanServer())
            kit.configuredDeployer = deployer
            kit.setConnectedState(credentialId: "test-cred", contractId: wallet)
            kit.externalSignersOverride = OZExternalSignerManager(
                networkPassphrase: Network.testnet.passphrase,
                walletAdapter: walletAdapter,
                ed25519Adapter: ed25519Adapter
            )
            script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
            script.enqueueSimulate(authEntries: entries)
            try script.setWalletInstanceResponse(contractId: wallet, executable: OZAuthDigestWasm.v080)

            await assertThrows(SmartAccountValidationException.InvalidAddress.self, containing: contractDelegateMessage(otherContract)) {
                _ = try await OZMultiSignerManager(kit: kit).submitWithMultipleSigners(
                    hostFunction: try self.noopHostFunction,
                    selectedSigners: [
                        .wallet(accountId: walletAdapter.address),
                        .ed25519(verifierAddress: self.verifier, publicKey: ed25519Adapter.publicKey)
                    ]
                )
            }
            XCTAssertEqual(walletAdapter.preimages.count, 0, "no wallet signature for order \(index)")
            XCTAssertEqual(ed25519Adapter.digests.count, 0, "no Ed25519 signature for order \(index)")
            XCTAssertEqual(try script.walletInstanceReadCount(contractId: wallet), 0, "no instance read for order \(index)")
            XCTAssertEqual(script.simulateCallCount, 1, "no re-simulation for order \(index)")
        }
    }

    // MARK: - Reads stay open

    func test_listContextRules_ruleWithAContractDelegate_parses() async throws {
        let script = MockSorobanServerScript()
        MockSorobanServer.activate(script: script)
        defer {
            MockSorobanServer.deactivate()
            MockURLProtocol.reset()
        }
        let deployer = try KeyPair.generateRandomKeyPair()
        let kit = MockOZSmartAccountKit(config: try config(deployer: deployer), sorobanServer: MockSorobanServer.makeMockedSorobanServer())
        kit.configuredDeployer = deployer
        kit.setConnectedState(credentialId: "test-credential-id", contractId: wallet)
        script.setGetAccountResponse(accountId: deployer.accountId, sequence: 1)
        let rule: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("context_type"), val: .vec([.symbol("Default")])),
            SCMapEntryXDR(key: .symbol("id"), val: .u32(0)),
            SCMapEntryXDR(key: .symbol("name"), val: .string("legacy")),
            SCMapEntryXDR(key: .symbol("policies"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("policy_ids"), val: .vec([])),
            SCMapEntryXDR(key: .symbol("signer_ids"), val: .vec([.u32(0)])),
            SCMapEntryXDR(key: .symbol("signers"), val: .vec([try delegated(otherContract)])),
            SCMapEntryXDR(key: .symbol("valid_until"), val: .void)
        ])
        script.enqueueSimulate(resultXdr: SCValXDR.u32(1).xdrEncoded ?? "")
        script.enqueueSimulate(resultXdr: rule.xdrEncoded ?? "")

        let rules = try await OZContextRuleManager(kit: kit).listContextRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.signers.count, 1)
        XCTAssertEqual((rules.first?.signers.first as? OZDelegatedSigner)?.address, otherContract)
    }

    func test_delegatedSignerType_holdsAContractAddress() throws {
        XCTAssertEqual(try OZDelegatedSigner(address: otherContract).address, otherContract)
    }
}
