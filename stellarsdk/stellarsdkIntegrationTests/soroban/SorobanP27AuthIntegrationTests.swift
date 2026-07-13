//
//  SorobanP27AuthIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Integration tests for the Protocol-27 (CAP-71) ADDRESS_V2 credential arm.
//
//  What is tested here:
//  - ADDRESS_V2 XDR encode/decode round-trip with no network dependency.
//  - buildPreimage() selects ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS for V2.
//  - signAuthEntries() preserves the ADDRESS_V2 arm and signs with the correct preimage.
//  - When testnet runs protocol >= 27: a contract call whose auth entry is returned as
//    ADDRESS_V2 by simulation (useUpgradedAuth) signs and submits successfully.
//
//  The XDR round-trip and preimage tests run without network access on any testnet.
//  The arm-preservation and submit tests require a testnet RPC that honors
//  useUpgradedAuth (stellar-rpc v27.1.0+); the submit test additionally skips on
//  networks whose ledger protocol is below 27.
//

import XCTest
import stellarsdk

final class SorobanP27AuthIntegrationTests: XCTestCase {

    // MARK: - Configuration

    static let testOn = "testnet"
    let sorobanServer = SorobanServer(endpoint: "https://soroban-testnet.stellar.org")
    let sdk = StellarSDK.testNet()
    let network = Network.testnet
    let rpcUrl = "https://soroban-testnet.stellar.org"

    let authContractFileName = "soroban_auth_contract"

    var sourceAccountKeyPair: KeyPair!

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        sorobanServer.enableLogging = true
        sourceAccountKeyPair = try KeyPair.generateRandomKeyPair()
        let testAccountId = sourceAccountKeyPair.accountId
        let responseEnum = await sdk.accounts.createTestAccount(accountId: testAccountId)
        switch responseEnum {
        case .success:
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(
                tag: "SorobanP27AuthIntegrationTests.setUp()",
                horizonRequestError: error
            )
            XCTFail("could not create test account: \(testAccountId)")
        }
    }

    // MARK: - Tests

    /// Runs all sub-tests in sequence so each builds on the previous setup.
    func testP27AddressV2() async throws {
        try addressV2XDRRoundtrip()
        try addressV2PreimageUsesWithAddressEnvelopeType()
        try await signAuthEntriesPreservesAddressV2Arm()
        try await submitWithAddressV2CredentialsOnP27Testnet()
    }

    // MARK: - Standalone network-free tests (run independently of testnet)

    /// ADDRESS_V2 credentials must survive XDR encode/decode without mutation.
    /// Standalone version: runs without network, independent of testnet availability.
    func testAddressV2XDRRoundtrip() throws {
        try addressV2XDRRoundtrip()
    }

    /// buildPreimage() must produce .sorobanAuthorizationWithAddress for ADDRESS_V2.
    /// Standalone version: runs without network, independent of testnet availability.
    func testAddressV2PreimageUsesWithAddressEnvelopeType() throws {
        try addressV2PreimageUsesWithAddressEnvelopeType()
    }

    // MARK: - XDR round-trip (no network)

    /// ADDRESS_V2 credentials must survive XDR encode/decode without mutation.
    ///
    /// This is a pure serialisation check; no network access is required.
    func addressV2XDRRoundtrip() throws {
        let signerKeyPair = try KeyPair.generateRandomKeyPair()
        let signerAddr = SCAddressXDR.account(signerKeyPair.publicKey)

        let innerCreds = SorobanAddressCredentialsXDR(
            address: signerAddr,
            nonce: 123_456_789,
            signatureExpirationLedger: 5_000,
            signature: .void
        )
        let original = SorobanAuthorizationEntryXDR(
            credentials: .addressV2(innerCreds),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: .contractFn(InvokeContractArgsXDR(
                    contractAddress: try SCAddressXDR(contractId: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"),
                    functionName: "increment",
                    args: []
                )),
                subInvocations: []
            )
        )

        let encoded = try XDREncoder.encode(original)
        let decoded = try SorobanAuthorizationEntryXDR(from: XDRDecoder(data: encoded))
        let reEncoded = try XDREncoder.encode(decoded)

        XCTAssertEqual(
            Data(encoded), Data(reEncoded),
            "ADDRESS_V2 SorobanAuthorizationEntryXDR must survive XDR encode/decode round-trip"
        )

        guard case .addressV2(let decodedCreds) = decoded.credentials else {
            XCTFail("Decoded entry must carry .addressV2 credentials")
            return
        }
        XCTAssertEqual(decodedCreds.nonce, 123_456_789, "Nonce must survive round-trip")
        XCTAssertEqual(decodedCreds.signatureExpirationLedger, 5_000,
                       "Expiration ledger must survive round-trip")
    }

    // MARK: - Preimage envelope type (no network)

    /// buildPreimage() must select the ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS arm
    /// for ADDRESS_V2 credentials, not the legacy ENVELOPE_TYPE_SOROBAN_AUTHORIZATION arm.
    func addressV2PreimageUsesWithAddressEnvelopeType() throws {
        let signerKeyPair = try KeyPair.generateRandomKeyPair()
        let signerAddr = SCAddressXDR.account(signerKeyPair.publicKey)

        let innerCreds = SorobanAddressCredentialsXDR(
            address: signerAddr,
            nonce: 99,
            signatureExpirationLedger: 1_000,
            signature: .void
        )
        let entry = SorobanAuthorizationEntryXDR(
            credentials: .addressV2(innerCreds),
            rootInvocation: SorobanAuthorizedInvocationXDR(
                function: .contractFn(InvokeContractArgsXDR(
                    contractAddress: try SCAddressXDR(contractId: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"),
                    functionName: "fn",
                    args: []
                )),
                subInvocations: []
            )
        )

        let preimage = try entry.buildPreimage(network: .testnet)

        guard case .sorobanAuthorizationWithAddress = preimage else {
            XCTFail(
                "ADDRESS_V2 credentials must produce a .sorobanAuthorizationWithAddress preimage, " +
                "got: \(preimage)"
            )
            return
        }
    }

    // MARK: - signAuthEntries arm preservation (live testnet)

    /// signAuthEntries() must preserve the ADDRESS_V2 arm and stamp the expiration
    /// into the inner address credentials.
    ///
    /// Procedure: install and deploy the auth contract, build a transaction where the
    /// invoker differs from the submitter with useUpgradedAuth set, hard-assert that
    /// simulation returned the invoker's entry with the ADDRESS_V2 arm, then call
    /// signAuthEntries(). The arm must remain ADDRESS_V2 after signing.
    func signAuthEntriesPreservesAddressV2Arm() async throws {
        let (client, invokerKeyPair) = try await buildAuthContractSetup()

        let spec = client.getContractSpec()
        let methodName = "increment"
        let invokerAccountId = invokerKeyPair.accountId
        let args = try spec.funcArgsToXdrSCValues(name: methodName,
                                                  args: ["user": invokerAccountId, "value": 1])

        // useUpgradedAuth: true requests ADDRESS_V2 credential arms from the RPC.
        // stellar-rpc v27.1.0+ honors the flag in recording mode and records ADDRESS_V2
        // entries; servers without support silently ignore it and return legacy ADDRESS.
        let assembledTx = try await client.buildInvokeMethodTx(name: methodName, args: args,
                                                               methodOptions: MethodOptions(useUpgradedAuth: true))

        // Testnet runs stellar-rpc v27.1.0+, so the invoker's entry must come back from
        // simulation with the ADDRESS_V2 arm already set — this proves the flag was sent
        // on the wire and honored by the server.
        try assertSimulationReturnedAddressV2(assembledTx: assembledTx, signerAccountId: invokerAccountId)

        // Sign with ADDRESS_V2 credentials.
        try await assembledTx.signAuthEntries(signerKeyPair: invokerKeyPair)

        // Verify the arm was preserved.
        guard let tx = assembledTx.tx,
              let invokeOp = tx.operations.first as? InvokeHostFunctionOperation else {
            XCTFail("Expected assembled transaction with InvokeHostFunctionOperation")
            return
        }

        var foundV2 = false
        for entry in invokeOp.auth {
            guard case .addressV2(let creds) = entry.credentials else { continue }
            guard creds.address.accountId == invokerAccountId else { continue }
            foundV2 = true
            XCTAssertGreaterThan(creds.signatureExpirationLedger, 0,
                                 "Expiration ledger must be stamped during signAuthEntries")
            // Verify signature is non-void (was signed).
            if case .void = creds.signature {
                XCTFail("ADDRESS_V2 entry must be signed after signAuthEntries()")
            }
        }

        XCTAssertTrue(foundV2, "At least one ADDRESS_V2 auth entry must be present after signing")
    }

    // MARK: - Submit with ADDRESS_V2 on P27 testnet

    /// When testnet runs protocol >= 27, a contract invocation whose auth entry is
    /// returned as ADDRESS_V2 by simulation (useUpgradedAuth) must succeed end-to-end.
    ///
    /// When the protocol version is < 27 the test is skipped because the network does not
    /// yet accept the ADDRESS_V2 credential arm in submitted transactions.
    func submitWithAddressV2CredentialsOnP27Testnet() async throws {
        let protocolVersion = try await fetchProtocolVersion()
        guard protocolVersion >= 27 else {
            throw XCTSkip("Testnet runs protocol \(protocolVersion); skipping P27 submit test")
        }

        let (client, invokerKeyPair) = try await buildAuthContractSetup()

        let spec = client.getContractSpec()
        let methodName = "increment"
        let invokerAccountId = invokerKeyPair.accountId
        let args = try spec.funcArgsToXdrSCValues(name: methodName,
                                                  args: ["user": invokerAccountId, "value": 5])

        let assembledTx = try await client.buildInvokeMethodTx(name: methodName, args: args,
                                                               methodOptions: MethodOptions(useUpgradedAuth: true))

        // Simulation must return the ADDRESS_V2 arm (stellar-rpc v27.1.0+); the entry is
        // then signed with the address-bound preimage and submitted.
        try assertSimulationReturnedAddressV2(assembledTx: assembledTx, signerAccountId: invokerAccountId)

        try await assembledTx.signAuthEntries(signerKeyPair: invokerKeyPair)

        let response = try await assembledTx.signAndSend()
        guard let resultValue = response.resultValue else {
            XCTFail("No result value from P27 auth contract invocation with ADDRESS_V2 credentials")
            return
        }
        XCTAssertEqual(5, resultValue.u32,
                       "Auth contract must return the incremented value when signed with ADDRESS_V2")
    }

    // MARK: - Helpers

    /// Installs the auth contract and deploys it; returns a `SorobanClient` and a funded
    /// invoker keypair that differs from the source account.
    private func buildAuthContractSetup() async throws -> (SorobanClient, KeyPair) {
        let wasmHash = try await installContract(fileName: authContractFileName)
        let client = try await deployContract(wasmHash: wasmHash)

        let invokerKeyPair = try KeyPair.generateRandomKeyPair()
        await fundTestnetAccount(accountId: invokerKeyPair.accountId)

        return (client, invokerKeyPair)
    }

    /// Hard-asserts that simulation returned at least one `.addressV2` auth entry for
    /// `signerAccountId` — proving the useUpgradedAuth flag was sent on the wire and
    /// honored by the server (requires stellar-rpc v27.1.0+).
    private func assertSimulationReturnedAddressV2(
        assembledTx: AssembledTransaction,
        signerAccountId: String
    ) throws {
        guard let tx = assembledTx.tx,
              let invokeOp = tx.operations.first as? InvokeHostFunctionOperation else {
            XCTFail("Expected assembled transaction with InvokeHostFunctionOperation")
            return
        }

        let hasV2 = invokeOp.auth.contains { entry in
            if case .addressV2(let creds) = entry.credentials {
                return creds.address.accountId == signerAccountId
            }
            return false
        }
        XCTAssertTrue(
            hasV2,
            "Simulation must return an ADDRESS_V2 auth entry for the invoker when useUpgradedAuth is set "
            + "(requires stellar-rpc v27.1.0+)"
        )
    }

    /// Returns the current ledger protocol version from the testnet RPC.
    private func fetchProtocolVersion() async throws -> Int {
        let response = await sorobanServer.getLatestLedger()
        switch response {
        case .success(let ledger):
            return ledger.protocolVersion
        case .failure(let error):
            XCTFail("getLatestLedger failed: \(error)")
            return 0
        }
    }

    private func installContract(fileName: String) async throws -> String {
        guard let path = Bundle.module.path(forResource: fileName, ofType: "wasm") else {
            XCTFail("\(fileName).wasm not found in test bundle")
            return ""
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("\(fileName).wasm could not be loaded")
            return ""
        }
        let installRequest = InstallRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: sourceAccountKeyPair,
            wasmBytes: contractCode,
            enableServerLogging: true
        )
        return try await SorobanClient.install(installRequest: installRequest)
    }

    private func deployContract(wasmHash: String) async throws -> SorobanClient {
        let deployRequest = DeployRequest(
            rpcUrl: rpcUrl,
            network: network,
            sourceAccountKeyPair: sourceAccountKeyPair,
            wasmHash: wasmHash,
            enableServerLogging: true
        )
        return try await SorobanClient.deploy(deployRequest: deployRequest)
    }

    private func fundTestnetAccount(accountId: String) async {
        let responseEnum = await sdk.accounts.createTestAccount(accountId: accountId)
        switch responseEnum {
        case .success:
            break
        case .failure(let error):
            StellarSDKLog.printHorizonRequestErrorMessage(
                tag: "SorobanP27AuthIntegrationTests.fundTestnetAccount(\(accountId))",
                horizonRequestError: error
            )
            XCTFail("could not fund account: \(accountId)")
        }
    }
}
