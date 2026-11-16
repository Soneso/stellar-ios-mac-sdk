//
//  OZAuthDigestLiveIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import CryptoKit
import Security
import XCTest
@testable import stellarsdk

/// Live gate for signing on OpenZeppelin stellar-accounts wallets on testnet.
///
/// Every case deploys a wallet of its own from a Friendbot-funded deployer, with one signer on
/// the Default rule, and funds it with native asset through the asset contract before it signs.
/// A case passes only when the network accepts the signatures the SDK produced, so a passing
/// transfer proves that the signer signed the digest the wallet's code checks.
///
/// - Case A: passkey signer created through `createWallet`, one transfer through `submit`.
/// - Case B: Ed25519 External signer set by the constructor, one transfer through the
///   multi-signer path. On a 0.8.0 wallet, case F follows on the entry B signed: the wallet's
///   `auth_digest` view is simulated for that entry and compared with the local digest.
/// - Case C: Delegated signer (a Friendbot-funded account) set by the constructor, one transfer
///   through the multi-signer path.
/// - Case D: as B; the signer adds a `CallContract` rule for the native asset contract with a
///   second Ed25519 signer and a spending-limit policy, the second signer transfers under the
///   limit with that rule selected explicitly, and a transfer over the limit is rejected.
/// - Case E (0.8.0 only): as B; the signer adds a `CreateContractExternalRef` rule with a second
///   Ed25519 signer, and the second signer deploys a contract by that external reference with
///   the rule found by resolution.
///
/// The 0.7 regression runs cases A to D on wallets of the stellar-accounts 0.7.0 build. The
/// smoke test runs a deployment and a transfer through the Soneso relayer proxy and two lookups
/// on the Mercury indexer.
///
/// The passkey of case A is a CryptoKit P-256 key behind ``SoftwareP256WebAuthnProvider``; the
/// in-memory signer registry of the kit holds the Ed25519 keys and the delegate account. Every
/// key is generated at run time and never printed; the `RESULT` lines name the case, the wallet
/// and the transaction hash or the error.
final class OZAuthDigestLiveIntegrationTests: XCTestCase {

    /// An account build with the spending-limit policy its rules use.
    private struct AccountBuild: Sendable {
        let label: String
        let wasmHash: String
        let spendingLimitPolicy: String
    }

    /// A wallet with the auth entry its Ed25519 signer signed in a confirmed transaction.
    private struct SignedWalletEntry {
        let walletId: String
        let source: KeyPair
        let entry: SorobanAuthorizationEntryXDR
        let ed25519PublicKey: Data
    }

    private let rpcUrl = "https://soroban-testnet.stellar.org"
    private let network = Network.testnet
    private let webauthnVerifier = "CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY"
    private let ed25519Verifier = "CAW2Z46INPO5VIJEILMYSSEOLBVJIIII5GOE3TN5EUURSRM2FJCF7AJ6"
    private let relayerUrl = "https://smart-account-relayer-proxy.soneso.workers.dev"

    private let v080 = AccountBuild(
        label: "0.8.0",
        wasmHash: "c514d35ea67eaea9bfc1fb3327854c0c06111bc1ddebd4fe217c504c1004b9e1",
        spendingLimitPolicy: "CC3CEYQAP6NPNFIYSWL5MVZRCPJZGWX4XO7WDEJOUVGO2FZX5OONYPA5"
    )
    private let v070 = AccountBuild(
        label: "0.7.0",
        wasmHash: "86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28",
        spendingLimitPolicy: "CBQE7L3UNP5IR4I7IBKLS7NV256WHR5TTH26HTMUIK7WXJC6J64RSE2L"
    )

    /// The 0.7.0 build with the 0.8.0 spending-limit policy on its rule.
    private var v070WithV080Policy: AccountBuild {
        AccountBuild(
            label: "0.7.0 with the 0.8.0 spending limit",
            wasmHash: v070.wasmHash,
            spendingLimitPolicy: v080.spendingLimitPolicy
        )
    }

    /// Spending limit of case D: 10 XLM in stroops per day.
    private let spendingLimitStroops = "100000000"
    private let spendingPeriodLedgers: UInt32 = 17_280

    // ========================================================================
    // MARK: - 0.8.0 cases
    // ========================================================================

    func testV080CaseA_passkeyTransfer() async throws {
        try await caseA(v080)
    }

    func testV080CaseB_ed25519Transfer_thenCaseF_authDigestView() async throws {
        let signed = try await caseB(v080)
        try await caseF(signed)
    }

    func testV080CaseC_delegatedTransfer() async throws {
        try await caseC(v080)
    }

    func testV080CaseD_ruleWithSpendingLimit() async throws {
        try await caseD(v080)
    }

    func testV080CaseE_externalRefRuleDeploysByReference() async throws {
        try await caseE(v080)
    }

    // ========================================================================
    // MARK: - 0.7 regression
    // ========================================================================

    func testV070CaseA_passkeyTransfer() async throws {
        try await caseA(v070)
    }

    func testV070CaseB_ed25519Transfer() async throws {
        _ = try await caseB(v070)
    }

    func testV070CaseC_delegatedTransfer() async throws {
        try await caseC(v070)
    }

    func testV070CaseD_ruleWithSpendingLimit() async throws {
        try await caseD(v070)
    }

    func testV070CaseD_ruleWithV080SpendingLimit() async throws {
        try await caseD(v070WithV080Policy)
    }

    // ========================================================================
    // MARK: - Relayer proxy and indexer
    // ========================================================================

    func testSmoke_relayerDeployAndTransfer_indexerLookups() async throws {
        let deployer = try await fundedAccount()

        // A passkey wallet deployed by createWallet through the relayer.
        let provider = SoftwareP256WebAuthnProvider()
        let passkeyWallet = try await withKit(v080, deployer, webauthnProvider: provider, relayerUrl: relayerUrl) { kit in
            let created = try await kit.walletOperations.createWallet(userName: "Relayer smoke", autoSubmit: true)
            self.result("smoke-relayer-deploy", self.v080, created.contractId, hash: created.transactionHash)
            XCTAssertNotNil(created.transactionHash, "the relayer deployment must report a transaction hash")
            return created
        }

        // An Ed25519 wallet deployed through the relayer and one transfer through it.
        let ed25519Wallet = try await withKit(v080, deployer, relayerUrl: relayerUrl) { kit in
            let publicKey = try await kit.externalSigners.addEd25519FromRawKey(
                secretKeyBytes: try self.randomBytes(32),
                verifierAddress: self.ed25519Verifier
            )
            let walletId = try await self.deployWallet(
                deployer,
                self.v080,
                [try OZExternalSigner.ed25519(verifierAddress: self.ed25519Verifier, publicKey: publicKey)],
                relayer: try OZRelayerClient(relayerUrl: self.relayerUrl)
            )
            _ = try await kit.walletOperations.connectToContract(contractId: walletId)
            _ = try await kit.transactionOperations.fundWallet(nativeTokenContract: try self.nativeAssetContract())
            let transfer = try await kit.multiSignerManager.multiSignerTransfer(
                tokenContract: try self.nativeAssetContract(),
                recipient: deployer.accountId,
                amount: "1",
                selectedSigners: [.ed25519(verifierAddress: self.ed25519Verifier, publicKey: publicKey)]
            )
            _ = try self.requireSuccess("smoke-relayer-transfer", self.v080, walletId, transfer)
            return walletId
        }

        // The indexer returns the Ed25519 wallet under its verifier and the passkey wallet
        // under its credential.
        let indexer = try XCTUnwrap(OZIndexerClient.forNetwork(networkPassphrase: network.passphrase))
        defer { indexer.close() }
        try await awaitIndexed("smoke-indexer-address", ed25519Wallet) {
            try await indexer.lookupByAddress(address: self.ed25519Verifier).contracts.map { $0.contractId }
        }
        try await awaitIndexed("smoke-indexer-credential", passkeyWallet.contractId) {
            try await indexer.lookupByCredentialId(credentialId: passkeyWallet.credentialId).contracts.map { $0.contractId }
        }
    }

    // ========================================================================
    // MARK: - Cases
    // ========================================================================

    private func caseA(_ build: AccountBuild) async throws {
        let deployer = try await fundedAccount()
        let provider = SoftwareP256WebAuthnProvider()
        try await withKit(build, deployer, webauthnProvider: provider) { kit in
            let created = try await kit.walletOperations.createWallet(
                userName: "Case A",
                autoSubmit: true,
                autoFund: true,
                nativeTokenContract: try self.nativeAssetContract()
            )
            let transfer = try await kit.transactionOperations.transfer(
                tokenContract: try self.nativeAssetContract(),
                recipient: deployer.accountId,
                amount: "1"
            )
            _ = try self.requireSuccess("A", build, created.contractId, transfer)
        }
    }

    /// Runs case B and returns the wallet with the auth entry its signer signed.
    private func caseB(_ build: AccountBuild) async throws -> SignedWalletEntry {
        let deployer = try await fundedAccount()
        return try await withKit(build, deployer) { kit in
            let publicKey = try await kit.externalSigners.addEd25519FromRawKey(
                secretKeyBytes: try self.randomBytes(32),
                verifierAddress: self.ed25519Verifier
            )
            let walletId = try await self.deployWallet(
                deployer,
                build,
                [try OZExternalSigner.ed25519(verifierAddress: self.ed25519Verifier, publicKey: publicKey)]
            )
            _ = try await kit.walletOperations.connectToContract(contractId: walletId)
            _ = try await kit.transactionOperations.fundWallet(nativeTokenContract: try self.nativeAssetContract())
            let transfer = try await kit.multiSignerManager.multiSignerTransfer(
                tokenContract: try self.nativeAssetContract(),
                recipient: deployer.accountId,
                amount: "1",
                selectedSigners: [.ed25519(verifierAddress: self.ed25519Verifier, publicKey: publicKey)]
            )
            let hash = try self.requireSuccess("B", build, walletId, transfer)
            return SignedWalletEntry(
                walletId: walletId,
                source: deployer,
                entry: try await self.walletEntry(of: hash, walletId: walletId),
                ed25519PublicKey: publicKey
            )
        }
    }

    private func caseC(_ build: AccountBuild) async throws {
        let deployer = try await fundedAccount()
        let delegate = try await fundedAccount()
        try await withKit(build, deployer) { kit in
            _ = try await kit.externalSigners.addFromSecret(secretKey: try XCTUnwrap(delegate.secretSeed))
            let walletId = try await self.deployWallet(
                deployer,
                build,
                [try OZDelegatedSigner(address: delegate.accountId)]
            )
            _ = try await kit.walletOperations.connectToContract(contractId: walletId)
            _ = try await kit.transactionOperations.fundWallet(nativeTokenContract: try self.nativeAssetContract())
            let transfer = try await kit.multiSignerManager.multiSignerTransfer(
                tokenContract: try self.nativeAssetContract(),
                recipient: deployer.accountId,
                amount: "1",
                selectedSigners: [.wallet(accountId: delegate.accountId)]
            )
            _ = try self.requireSuccess("C", build, walletId, transfer)
        }
    }

    private func caseD(_ build: AccountBuild) async throws {
        let deployer = try await fundedAccount()
        try await withKit(build, deployer) { kit in
            let firstKey = try await kit.externalSigners.addEd25519FromRawKey(
                secretKeyBytes: try self.randomBytes(32),
                verifierAddress: self.ed25519Verifier
            )
            let secondKey = try await kit.externalSigners.addEd25519FromRawKey(
                secretKeyBytes: try self.randomBytes(32),
                verifierAddress: self.ed25519Verifier
            )
            let walletId = try await self.deployWallet(
                deployer,
                build,
                [try OZExternalSigner.ed25519(verifierAddress: self.ed25519Verifier, publicKey: firstKey)]
            )
            _ = try await kit.walletOperations.connectToContract(contractId: walletId)
            _ = try await kit.transactionOperations.fundWallet(nativeTokenContract: try self.nativeAssetContract())

            let ruleName = "Case D spending"
            let added = try await kit.contextRuleManager.addContextRule(
                contextType: .callContract(contractAddress: try self.nativeAssetContract()),
                name: ruleName,
                signers: [try OZExternalSigner.ed25519(verifierAddress: self.ed25519Verifier, publicKey: secondKey)],
                policies: [
                    build.spendingLimitPolicy: try OZPolicyInstallParams.spendingLimit(
                        spendingLimit: self.spendingLimitStroops,
                        periodLedgers: self.spendingPeriodLedgers
                    ).toScVal()
                ],
                selectedSigners: [.ed25519(verifierAddress: self.ed25519Verifier, publicKey: firstKey)]
            )
            _ = try self.requireSuccess("D-add-rule", build, walletId, added)

            let rules = try await kit.contextRuleManager.listContextRules().filter { $0.name == ruleName }
            XCTAssertEqual(rules.count, 1, "exactly one rule must carry the name \(ruleName)")
            let rule = try XCTUnwrap(rules.first)
            XCTAssertEqual(rule.policies, [build.spendingLimitPolicy], "the rule must carry the spending limit")
            let ruleId = rule.id
            let secondSigner: [OZSelectedSigner] = [.ed25519(verifierAddress: self.ed25519Verifier, publicKey: secondKey)]

            let underLimit = try await kit.multiSignerManager.multiSignerTransfer(
                tokenContract: try self.nativeAssetContract(),
                recipient: deployer.accountId,
                amount: "1",
                selectedSigners: secondSigner,
                resolveContextRuleIds: { _, _ in [ruleId] }
            )
            _ = try self.requireSuccess("D-under-limit", build, walletId, underLimit)

            var failure: String?
            var accepted: OZTransactionResult?
            do {
                let overLimit = try await kit.multiSignerManager.multiSignerTransfer(
                    tokenContract: try self.nativeAssetContract(),
                    recipient: deployer.accountId,
                    amount: "20",
                    selectedSigners: secondSigner,
                    resolveContextRuleIds: { _, _ in [ruleId] }
                )
                if overLimit.success {
                    accepted = overLimit
                } else {
                    failure = overLimit.error
                }
            } catch {
                failure = SmartAccountException.messageOf(error) ?? String(describing: error)
            }
            self.result(
                "D-over-limit",
                build,
                walletId,
                error: failure ?? "accepted: \(String(describing: accepted?.hash))"
            )
            let rejection = try XCTUnwrap(failure, "a transfer over the limit must be rejected, got: \(String(describing: accepted))")
            let decoded = try XCTUnwrap(
                OZContractErrorCodes.decodeFromMessage(rejection),
                "the rejection must name a contract error, got: \(rejection)"
            )
            XCTAssertEqual(decoded.code, 3221, "the rejection must be SpendingLimitExceeded, got: \(rejection)")
        }
    }

    private func caseE(_ build: AccountBuild) async throws {
        let deployer = try await fundedAccount()
        try await withKit(build, deployer) { kit in
            let firstKey = try await kit.externalSigners.addEd25519FromRawKey(
                secretKeyBytes: try self.randomBytes(32),
                verifierAddress: self.ed25519Verifier
            )
            let secondKey = try await kit.externalSigners.addEd25519FromRawKey(
                secretKeyBytes: try self.randomBytes(32),
                verifierAddress: self.ed25519Verifier
            )
            let walletId = try await self.deployWallet(
                deployer,
                build,
                [try OZExternalSigner.ed25519(verifierAddress: self.ed25519Verifier, publicKey: firstKey)]
            )
            _ = try await kit.walletOperations.connectToContract(contractId: walletId)

            // The owner fixture holds the tag for the hello world contract's code.
            let ownerWasmHash = try await SorobanClient.install(installRequest: InstallRequest(
                rpcUrl: self.rpcUrl,
                network: self.network,
                sourceAccountKeyPair: deployer,
                wasmBytes: try self.wasm("p28_owner_fixture"),
                enableServerLogging: false
            ))
            let owner = try await SorobanClient.deploy(deployRequest: DeployRequest(
                rpcUrl: self.rpcUrl,
                network: self.network,
                sourceAccountKeyPair: deployer,
                wasmHash: ownerWasmHash,
                enableServerLogging: false
            ))
            let helloWasmHash = try await SorobanClient.install(installRequest: InstallRequest(
                rpcUrl: self.rpcUrl,
                network: self.network,
                sourceAccountKeyPair: deployer,
                wasmBytes: try self.wasm("soroban_hello_world_contract"),
                enableServerLogging: false
            ))
            let tag = "sa08-live-\(try self.randomBytes(4).base16EncodedString())"
            _ = try await owner.invokeMethod(name: "set_executable", args: [
                .string(tag),
                .bytes(try Data(base16Encoded: helloWasmHash))
            ])

            let ruleName = "Case E reference"
            let added = try await kit.contextRuleManager.addContextRule(
                contextType: try OZBuilders.createCreateContractExternalRefContextType(owner: owner.contractId, tag: tag),
                name: ruleName,
                signers: [try OZExternalSigner.ed25519(verifierAddress: self.ed25519Verifier, publicKey: secondKey)],
                selectedSigners: [.ed25519(verifierAddress: self.ed25519Verifier, publicKey: firstKey)]
            )
            _ = try self.requireSuccess("E-add-rule", build, walletId, added)

            let rules = try await kit.contextRuleManager.listContextRules().filter { $0.name == ruleName }
            XCTAssertEqual(rules.count, 1, "exactly one rule must carry the name \(ruleName)")
            let rule = try XCTUnwrap(rules.first)
            guard case .createContractExternalRef(let listedOwner, let listedTag) = rule.contextType else {
                return XCTFail("the listed rule must be a CreateContractExternalRef rule, got: \(rule.contextType)")
            }
            XCTAssertEqual(listedOwner, owner.contractId, "the listed rule must name the owner")
            XCTAssertEqual(listedTag, tag, "the listed rule must name the tag")

            let salt = try self.randomBytes(32)
            let deployment = try InvokeHostFunctionOperation.forCreatingContractFromExternalRef(
                executableOwner: try SCAddressXDR(contractId: owner.contractId),
                tag: tag,
                address: try SCAddressXDR(contractId: walletId),
                salt: WrappedData32(salt)
            )
            let deployed = try await kit.multiSignerManager.submitWithMultipleSigners(
                hostFunction: deployment.hostFunction,
                selectedSigners: [.ed25519(verifierAddress: self.ed25519Verifier, publicKey: secondKey)]
            )
            _ = try self.requireSuccess("E-deploy-by-reference", build, walletId, deployed)

            let createdId = try ContractIdUtils.deriveContractId(
                deployer: try SCAddressXDR(contractId: walletId),
                salt: salt,
                network: self.network
            )
            let hello = try await SorobanClient.forClientOptions(options: ClientOptions(
                sourceAccountKeyPair: deployer,
                contractId: createdId,
                network: self.network,
                rpcUrl: self.rpcUrl
            ))
            let answer = try await hello.invokeMethod(name: "hello", args: [.symbol("friend")])
            guard case .vec(let words) = answer else {
                return XCTFail("hello must return a Vec, got: \(answer)")
            }
            let symbols = (words ?? []).compactMap { word -> String? in
                if case .symbol(let symbol) = word { return symbol }
                return nil
            }
            XCTAssertEqual(symbols, ["Hello", "friend"], "the contract deployed by reference must answer")
            print("RESULT case=E-hello build=\(build.label) contract=\(createdId) answer=\(symbols)")
        }
    }

    /// Case F: the wallet's `auth_digest` view, simulated for the preimage of the entry case B
    /// signed, returns the digest the SDK computes for that entry, the digest built from the
    /// stellar-accounts definition, and the digest the entry's Ed25519 signature verifies over.
    private func caseF(_ signed: SignedWalletEntry) async throws {
        let credentials = try XCTUnwrap(
            signed.entry.credentials.addressCredentials,
            "the wallet entry must carry address credentials"
        )
        let payload = try OZSmartAccountAuthPayloadCodec.read(credentials.signature)
        let local = try await OZSmartAccountAuth.computeEntryAuthDigest(
            entry: signed.entry,
            expirationLedger: credentials.signatureExpirationLedger,
            networkPassphrase: network.passphrase,
            contextRuleIds: payload.contextRuleIds,
            scheme: .preimageV1
        )
        let preimage = try independentPreimage(
            account: signed.walletId,
            signaturePayload: local.signaturePayload,
            contextRuleIds: payload.contextRuleIds
        )
        let independent = Data(try XDREncoder.encode(preimage)).sha256Hash

        let view = try await simulateView(
            contractId: signed.walletId,
            functionName: "auth_digest",
            arguments: [preimage],
            source: signed.source
        )
        guard case .bytes(let contractDigest) = view else {
            return XCTFail("auth_digest must return bytes, got: \(view)")
        }

        XCTAssertEqual(payload.signers.count, 1, "the entry carries the one Ed25519 signature")
        let signature = try XCTUnwrap(payload.signers.first).signatureBytes
        let verifier = KeyPair(publicKey: try PublicKey([UInt8](signed.ed25519PublicKey)), privateKey: nil)
        let signatureVerifies = try verifier.verify(signature: [UInt8](signature), message: [UInt8](contractDigest))

        print(
            "RESULT case=F build=0.8.0 wallet=\(signed.walletId) ruleIds=\(payload.contextRuleIds) " +
                "signaturePayload=\(local.signaturePayload.base16EncodedString()) " +
                "contract=\(contractDigest.base16EncodedString()) local=\(local.authDigest.base16EncodedString()) " +
                "independent=\(independent.base16EncodedString()) signatureVerifies=\(signatureVerifies)"
        )
        XCTAssertEqual(contractDigest, local.authDigest, "the SDK digest must equal the contract's")
        XCTAssertEqual(contractDigest, independent, "the definition's digest must equal the contract's")
        XCTAssertEqual(
            try local.delegatedAuthArgs.map { Data(try XDREncoder.encode($0)) },
            [Data(try XDREncoder.encode(preimage))],
            "a Delegated signer authorizes the preimage"
        )
        XCTAssertTrue(signatureVerifies, "the signer's signature must verify over the contract's digest")
    }

    // ========================================================================
    // MARK: - Helpers
    // ========================================================================

    /// `AuthDigestPreimage` of stellar-accounts 0.8.0, built from its definition: a Map with the
    /// Symbol keys in name order.
    private func independentPreimage(account: String, signaturePayload: Data, contextRuleIds: [UInt32]) throws -> SCValXDR {
        return .map([
            SCMapEntryXDR(key: .symbol("account"), val: .address(try SCAddressXDR(contractId: account))),
            SCMapEntryXDR(key: .symbol("context_rule_ids"), val: .vec(contextRuleIds.map { SCValXDR.u32($0) })),
            SCMapEntryXDR(key: .symbol("signature_payload"), val: .bytes(signaturePayload))
        ])
    }

    /// Runs `body` with a kit for `build` and closes the kit afterwards.
    private func withKit<T>(
        _ build: AccountBuild,
        _ deployer: KeyPair,
        webauthnProvider: WebAuthnProvider? = nil,
        relayerUrl: String? = nil,
        _ body: (OZSmartAccountKit) async throws -> T
    ) async throws -> T {
        let kit = OZSmartAccountKit.create(config: try OZSmartAccountConfig(
            rpcUrl: rpcUrl,
            networkPassphrase: network.passphrase,
            accountWasmHash: build.wasmHash,
            webauthnVerifierAddress: webauthnVerifier,
            deployerKeypair: deployer,
            relayerUrl: relayerUrl,
            webauthnProvider: webauthnProvider
        ))
        do {
            let value = try await body(kit)
            await kit.close()
            return value
        } catch {
            await kit.close()
            throw error
        }
    }

    private func fundedAccount() async throws -> KeyPair {
        let account = try KeyPair.generateRandomKeyPair()
        try await fundTestAccountAndAwaitVisibility(accountId: account.accountId, rpc: SorobanServer(endpoint: rpcUrl))
        return account
    }

    /// The contract address of the native asset on testnet.
    private func nativeAssetContract() throws -> String {
        let preimage = HashIDPreimageXDR.contractID(
            HashIDPreimageContractIDXDR(
                networkID: HashXDR(network.networkId),
                contractIDPreimage: .fromAsset(.native)
            )
        )
        return try Data(try XDREncoder.encode(preimage)).sha256Hash.encodeContractId()
    }

    private func randomBytes(_ count: Int) throws -> Data {
        var bytes = Data(count: count)
        let status = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!) }
        guard status == errSecSuccess else {
            throw LiveGateFailure("SecRandomCopyBytes failed with status \(status)")
        }
        return bytes
    }

    private func wasm(_ name: String) throws -> Data {
        let path = try XCTUnwrap(Bundle.module.path(forResource: name, ofType: "wasm"), "\(name).wasm must be a test resource")
        return try XCTUnwrap(FileManager.default.contents(atPath: path), "\(name).wasm must be readable")
    }

    /// Deploys a wallet of `build` whose Default rule holds `signers`, from `deployer` with a
    /// random salt, directly or through `relayer`, and returns its address once it is confirmed.
    private func deployWallet(
        _ deployer: KeyPair,
        _ build: AccountBuild,
        _ signers: [any OZSmartAccountSigner],
        relayer: OZRelayerClient? = nil
    ) async throws -> String {
        let salt = try randomBytes(32)
        let deployerAddress = try SCAddressXDR(accountId: deployer.accountId)
        let operation = try InvokeHostFunctionOperation.forCreatingContractWithConstructor(
            wasmId: build.wasmHash,
            address: deployerAddress,
            constructorArguments: [.vec(try signers.map { try $0.toScVal() }), try OZPolicyManager.policiesToScVal([:])],
            salt: WrappedData32(salt)
        )
        let walletId = try ContractIdUtils.deriveContractId(deployer: deployerAddress, salt: salt, network: network)
        let server = SorobanServer(endpoint: rpcUrl)
        let account: Account
        switch await server.getAccount(accountId: deployer.accountId) {
        case .success(let response):
            account = response
        case .failure(let error):
            throw LiveGateFailure("the deployer account \(deployer.accountId) could not be read: \(error)")
        }
        // The relayer refuses transactions valid for more than 60 seconds.
        let transaction = try Transaction(
            sourceAccount: account,
            operations: [operation],
            memo: Memo.none,
            preconditions: TransactionPreconditions(timeBounds: TimeBounds(
                minTime: 0,
                maxTime: UInt64(Date().timeIntervalSince1970) + UInt64(OZConstants.defaultTimeoutSeconds)
            ))
        )
        let simulation: SimulateTransactionResponse
        switch await server.simulateTransaction(simulateTxRequest: SimulateTransactionRequest(transaction: transaction)) {
        case .success(let response):
            simulation = response
        case .failure(let error):
            XCTFail("the deployment of \(walletId) must simulate, got: \(error)")
            throw error
        }
        XCTAssertNil(simulation.error, "the deployment of \(walletId) must simulate")
        // The relayer wraps the transaction in a fee bump, so its own fee is the resource fee.
        try OZTransactionOperations.applySimulation(
            simulation: simulation,
            transaction: transaction,
            signedAuthEntries: simulation.sorobanAuth ?? [],
            relayerMode: relayer != nil
        )
        try transaction.sign(keyPair: deployer, network: network)

        let hash: String
        if let relayer = relayer {
            let response = await relayer.sendXdr(transactionEnvelope: try transaction.transactionXDR.toEnvelopeXDR())
            XCTAssertTrue(response.success, "the relayer must accept the deployment of \(walletId), got: \(String(describing: response.error))")
            hash = try XCTUnwrap(response.hash, "the relayer must report the deployment hash, got: \(String(describing: response.error))")
        } else {
            switch await server.sendTransaction(transaction: transaction) {
            case .success(let response):
                XCTAssertNotEqual(response.status, SendTransactionResponse.STATUS_ERROR, "the deployment of \(walletId) must be accepted")
                hash = response.transactionId
            case .failure(let error):
                XCTFail("the deployment of \(walletId) must be accepted, got: \(error)")
                throw error
            }
        }
        let status = try await confirmedTransaction(hash, server: server).status
        XCTAssertEqual(
            status,
            GetTransactionResponse.STATUS_SUCCESS,
            "the deployment \(hash) of \(walletId) must succeed, got: \(status)"
        )
        print("RESULT case=deploy build=\(build.label) wallet=\(walletId) tx=\(hash)\(relayer != nil ? " via=relayer" : "")")
        return walletId
    }

    private func confirmedTransaction(_ hash: String, server: SorobanServer) async throws -> GetTransactionResponse {
        switch await server.pollTransaction(hash: hash, maxAttempts: 60) {
        case .success(let response):
            return response
        case .failure(let error):
            XCTFail("transaction \(hash) must be readable, got: \(error)")
            throw error
        }
    }

    /// The entry of `walletId` in the confirmed transaction `hash`, as the network received it.
    private func walletEntry(of hash: String, walletId: String) async throws -> SorobanAuthorizationEntryXDR {
        let response = try await confirmedTransaction(hash, server: SorobanServer(endpoint: rpcUrl))
        let envelope = try XCTUnwrap(response.transactionEnvelope, "transaction \(hash) must carry its envelope")
        let transaction: TransactionXDR
        switch envelope {
        case .v1(let v1):
            transaction = v1.tx
        case .feeBump(let feeBump):
            guard case .v1(let inner) = feeBump.tx.innerTx else {
                throw LiveGateFailure("transaction \(hash) wraps no v1 transaction")
            }
            transaction = inner.tx
        case .v0:
            throw LiveGateFailure("transaction \(hash) is a v0 envelope")
        }
        XCTAssertEqual(transaction.operations.count, 1, "transaction \(hash) carries one operation")
        guard case .invokeHostFunctionOp(let invocation) = try XCTUnwrap(transaction.operations.first).body else {
            throw LiveGateFailure("transaction \(hash) carries no host function invocation")
        }
        let entries = invocation.auth.filter { entry in
            guard let address = entry.credentials.addressCredentials?.address else { return false }
            return OZAddressStrKey.fromXdr(address) == walletId
        }
        XCTAssertEqual(entries.count, 1, "transaction \(hash) carries one entry of \(walletId)")
        return try XCTUnwrap(entries.first)
    }

    /// Simulates a call of `functionName` on `contractId` and returns its result.
    private func simulateView(
        contractId: String,
        functionName: String,
        arguments: [SCValXDR],
        source: KeyPair
    ) async throws -> SCValXDR {
        let server = SorobanServer(endpoint: rpcUrl)
        let account: Account
        switch await server.getAccount(accountId: source.accountId) {
        case .success(let response):
            account = response
        case .failure(let error):
            XCTFail("the source account must be readable, got: \(error)")
            throw error
        }
        let operation = try InvokeHostFunctionOperation.forInvokingContract(
            contractId: contractId,
            functionName: functionName,
            functionArguments: arguments
        )
        let transaction = try Transaction(sourceAccount: account, operations: [operation], memo: Memo.none)
        switch await server.simulateTransaction(simulateTxRequest: SimulateTransactionRequest(transaction: transaction)) {
        case .success(let response):
            XCTAssertNil(response.error, "\(functionName) must simulate, got: \(String(describing: response.error))")
            return try XCTUnwrap(response.results?.first?.value, "\(functionName) must return a value")
        case .failure(let error):
            XCTFail("\(functionName) must simulate, got: \(error)")
            throw error
        }
    }

    /// Polls the indexer until `lookup` lists `contractId`, for at most three minutes.
    private func awaitIndexed(
        _ caseName: String,
        _ contractId: String,
        _ lookup: () async throws -> [String]
    ) async throws {
        var listed: [String] = []
        for attempt in 1...18 {
            listed = try await lookup()
            if listed.contains(contractId) {
                print("RESULT case=\(caseName) wallet=\(contractId) listedAfterAttempts=\(attempt) count=\(listed.count)")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
        print("RESULT case=\(caseName) wallet=\(contractId) error=not listed after 18 lookups, count=\(listed.count)")
        XCTFail("the indexer must list \(contractId), got \(listed.count) contracts without it")
    }

    private func requireSuccess(
        _ caseName: String,
        _ build: AccountBuild,
        _ walletId: String,
        _ outcome: OZTransactionResult
    ) throws -> String {
        result(caseName, build, walletId, hash: outcome.hash, error: outcome.success ? nil : outcome.error)
        XCTAssertTrue(outcome.success, "case \(caseName) on \(build.label) must succeed, got: \(String(describing: outcome.error))")
        return try XCTUnwrap(outcome.hash, "case \(caseName) on \(build.label) must report a transaction hash")
    }

    private func result(
        _ caseName: String,
        _ build: AccountBuild,
        _ walletId: String,
        hash: String? = nil,
        error: String? = nil
    ) {
        let outcome = error.map { "error=\($0)" } ?? "tx=\(hash ?? "none")"
        print("RESULT case=\(caseName) build=\(build.label) wallet=\(walletId) \(outcome)")
    }
}

/// A state the live gate cannot continue from; the test fails with its message.
private struct LiveGateFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

/// A WebAuthn authenticator in software: a CryptoKit P-256 key generated per registration,
/// assertions with the user present and user verified flags over client data that carries the
/// challenge as given.
private final class SoftwareP256WebAuthnProvider: WebAuthnProvider, @unchecked Sendable {

    private let lock = NSLock()
    private var credentialId: Data?
    private var privateKey: P256.Signing.PrivateKey?

    func register(challenge: Data, userId: Data, userName: String) async throws -> WebAuthnRegistrationResult {
        let key = P256.Signing.PrivateKey()
        var id = Data(count: 16)
        let status = id.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        guard status == errSecSuccess else {
            throw WebAuthnException.RegistrationFailed(message: "SecRandomCopyBytes failed with status \(status)")
        }
        store(credentialId: id, privateKey: key)
        return WebAuthnRegistrationResult(
            credentialId: id,
            publicKey: key.publicKey.x963Representation,
            attestationObject: Data(),
            transports: ["internal"],
            deviceType: "singleDevice",
            backedUp: false
        )
    }

    func authenticate(challenge: Data, allowCredentials: [WebAuthnAllowCredential]?) async throws -> WebAuthnAuthenticationResult {
        guard let (id, key) = registered() else {
            throw WebAuthnException.AuthenticationFailed(message: "authenticate called before register")
        }
        if let allowed = allowCredentials, !allowed.contains(where: { $0.id == id }) {
            throw WebAuthnException.AuthenticationFailed(message: "the allowed credentials do not include the registered one")
        }
        let clientDataJSON = Data(
            ("{\"type\":\"webauthn.get\",\"challenge\":\"\(challenge.base64URLEncodedString())\"," +
                "\"origin\":\"https://localhost\",\"crossOrigin\":false}").utf8
        )
        // rpIdHash, flags user present and user verified, sign count 1.
        let authenticatorData = Data(SHA256.hash(data: Data("localhost".utf8))) + Data([0x05, 0, 0, 0, 1])
        let signature = try key.signature(for: authenticatorData + Data(SHA256.hash(data: clientDataJSON)))
        return WebAuthnAuthenticationResult(
            credentialId: id,
            authenticatorData: authenticatorData,
            clientDataJSON: clientDataJSON,
            signature: signature.derRepresentation
        )
    }

    private func store(credentialId: Data, privateKey: P256.Signing.PrivateKey) {
        lock.lock(); defer { lock.unlock() }
        self.credentialId = credentialId
        self.privateKey = privateKey
    }

    private func registered() -> (Data, P256.Signing.PrivateKey)? {
        lock.lock(); defer { lock.unlock() }
        guard let id = credentialId, let key = privateKey else { return nil }
        return (id, key)
    }
}
