//
//  SACClientUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests `SACClient`: the factories, the amount helper, the typed reads, and the writes.
/// One test checks the catcher of the test session, which records and fails a request no
/// mock answers.
///
/// The RPC is `SACMockRPC` on a host that resolves nowhere. Every simulation and every sent
/// transaction is decoded and compared with the contract, the function, and the full
/// argument list the call must produce. `tearDown` fails a test whose requests the mock did
/// not expect, whose sent envelope or polled hash differs, or that left the mock.
final class SACClientUnitTests: XCTestCase {

    /// The id of the native asset's contract on testnet, and the same id as hex.
    private let sacId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let sacIdHex = "d7928b72c2703ccfeaf7eb9ff4ef4d504a55a8b979fc9b450ea2c842b4d1ce61"
    private let xlmPublicId = "CAS3J7GYLGXMF6TDJBBYYSE3HQ6BBSMLNUQ34T6TZMYMW2EVH34XOWMA"
    private let usdcPublicId = "CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75"
    private let usdc = "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"

    private let accountG = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    private let muxedAccountM = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ"
    private let contractC = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
    private let muxedContractW = "WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG"
    private let claimableBalanceB = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"
    private let liquidityPoolL = "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"
    private let otherAccountG = "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"

    private let placeholder = "GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"
    private let maxI128 = "170141183460469231731687303715884105727"

    /// The 17 functions in the order of the embedded spec.
    private let methodNames = [
        "allowance", "authorized", "approve", "balance", "burn", "burn_from", "clawback", "decimals",
        "mint", "name", "set_admin", "admin", "set_authorized", "symbol", "transfer", "transfer_from",
        "trust",
    ]

    private var rpc: SACMockRPC!
    private var factoryRpc: SACMockRPC?
    private var source: KeyPair!

    override func setUpWithError() throws {
        try super.setUpWithError()
        rpc = SACMockRPC(host: "sac-client-unit-tests.mock", contractId: sacId)
        source = try KeyPair.generateRandomKeyPair()
    }

    override func tearDown() {
        factoryRpc?.tearDown()
        factoryRpc = nil
        rpc.tearDown()
        rpc = nil
        source = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// A client for `source`, whose account the mock serves at each of `sequenceNumbers`, one
    /// per request; the last one repeats.
    private func keyedClient(sequenceNumbers: [Int64] = [12345]) throws -> SACClient {
        rpc.serveAccount(of: source, sequenceNumbers: sequenceNumbers)
        return try SACClient.forContractId(contractId: sacId,
                                           sourceAccountKeyPair: source,
                                           network: Network.testnet,
                                           rpcUrl: rpc.rpcUrl,
                                           urlSession: rpc.session)
    }

    private func readOnlyClient() throws -> SACClient {
        return try SACClient.readOnlyForContractId(contractId: sacId,
                                                   network: Network.testnet,
                                                   rpcUrl: rpc.rpcUrl,
                                                   urlSession: rpc.session)
    }

    private func address(_ strKey: String) throws -> SCAddressXDR {
        switch strKey.first {
        case "C":
            return try SCAddressXDR(contractId: strKey)
        case "W":
            return try SCAddressXDR(muxedContractId: strKey)
        case "B":
            return try SCAddressXDR(claimableBalanceId: strKey)
        case "L":
            return try SCAddressXDR(liquidityPoolId: strKey)
        default:
            return try SCAddressXDR(accountId: strKey)
        }
    }

    private func transferArgs(from: String, to: String, amount: String) throws -> [SCValXDR] {
        return [
            SCValXDR.address(try address(from)),
            SCValXDR.address(try address(to)),
            try SCValXDR.i128(stringValue: amount),
        ]
    }

    /// The seed of a random keypair, bare and with the whitespace a pasted seed can carry.
    private func seedForms() throws -> (seed: String, forms: [String]) {
        let seed = try XCTUnwrap(try KeyPair.generateRandomKeyPair().secretSeed)
        return (seed, [seed, seed + "\n", "  " + seed, "\t" + seed, seed + "\r\n"])
    }

    private func simulationWithPreamble(transactionData: Bool, error: String? = nil) -> SACMockRPC.Simulation {
        var simulation = SACMockRPC.Simulation(error: error)
        if transactionData {
            simulation.transactionData = SACMockRPC.transactionData(contractId: sacId, writes: true)
            simulation.minResourceFee = 1000
        }
        simulation.restorePreamble = (SACMockRPC.transactionData(contractId: sacId, writes: true), 100)
        return simulation
    }

    private func invalidArgument(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard case StellarSDKError.invalidArgument(let message)? = error else {
            XCTFail("expected StellarSDKError.invalidArgument, got \(String(describing: error))", file: file, line: line)
            return nil
        }
        return message
    }

    private func invalidType(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard case ContractSpecError.invalidType(let message)? = error else {
            XCTFail("expected ContractSpecError.invalidType, got \(String(describing: error))", file: file, line: line)
            return nil
        }
        return message
    }

    private func invokeFailed(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard case SorobanClientError.invokeFailed(let message)? = error else {
            XCTFail("expected SorobanClientError.invokeFailed, got \(String(describing: error))", file: file, line: line)
            return nil
        }
        return message
    }

    private func missingPrivateKey(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard case AssembledTransactionError.missingPrivateKey(let message)? = error else {
            XCTFail("expected AssembledTransactionError.missingPrivateKey, got \(String(describing: error))", file: file, line: line)
            return nil
        }
        return message
    }

    private func simulationFailed(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard case AssembledTransactionError.simulationFailed(let message)? = error else {
            XCTFail("expected AssembledTransactionError.simulationFailed, got \(String(describing: error))", file: file, line: line)
            return nil
        }
        return message
    }

    private func restoreNeeded(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard case AssembledTransactionError.restoreNeeded(let message)? = error else {
            XCTFail("expected AssembledTransactionError.restoreNeeded, got \(String(describing: error))", file: file, line: line)
            return nil
        }
        return message
    }

    private func now() -> UInt64 {
        return UInt64(Date().timeIntervalSince1970)
    }

    /// Asserts the options a write's simulation request carries: the envelope fee, the upper
    /// time bound `timeout` seconds after the call, made between `before` and `after`, and
    /// the `useUpgradedAuth` flag.
    private func assertWriteOptions(_ request: SACMockRPC.Request, fee: UInt32, timeout: UInt64, before: UInt64, after: UInt64,
                                    useUpgradedAuth: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        let invocation = try request.invocation()
        XCTAssertEqual(invocation.envelope.fee, fee, file: file, line: line)
        let maxTime = try XCTUnwrap(invocation.maxTime, file: file, line: line)
        XCTAssertGreaterThanOrEqual(maxTime, before + timeout, file: file, line: line)
        XCTAssertLessThanOrEqual(maxTime, after + timeout, file: file, line: line)
        XCTAssertEqual(try request.params()["useUpgradedAuth"] as? Bool, useUpgradedAuth, file: file, line: line)
    }

    // MARK: - Factories

    /// Asserts what every factory gives: no request, the 17 method names, and, through an
    /// unsimulated transfer, the contract, the source, the network, the RPC URL, the session,
    /// and the read-only state. A keyed client's build loads its account from the custom host.
    private func assertFactory(_ client: SACClient, contractId: String, sourceAccountId: String, readOnly: Bool,
                               on factoryRpc: SACMockRPC, file: StaticString = #filePath, line: UInt = #line) async throws {
        XCTAssertEqual(factoryRpc.requestNames, [], file: file, line: line)
        XCTAssertEqual(client.contractId, contractId, file: file, line: line)
        XCTAssertEqual(client.sorobanClient.contractId, contractId, file: file, line: line)
        XCTAssertEqual(client.sorobanClient.methodNames, methodNames, file: file, line: line)

        let tx = try await client.transfer(from: try address(accountG), to: try address(otherAccountG), amount: "1",
                                           methodOptions: MethodOptions(simulate: false))

        let options = tx.options.clientOptions
        XCTAssertEqual(options.contractId, contractId, file: file, line: line)
        XCTAssertEqual(options.sourceAccountKeyPair.accountId, sourceAccountId, file: file, line: line)
        XCTAssertEqual(options.network.passphrase, Network.public.passphrase, file: file, line: line)
        XCTAssertEqual(options.rpcUrl, "https://sac-client-factories.mock", file: file, line: line)
        XCTAssertTrue(options.urlSession === factoryRpc.session, file: file, line: line)
        XCTAssertEqual(tx.options.readOnly, readOnly, file: file, line: line)
        XCTAssertEqual(factoryRpc.requestNames, readOnly ? [] : ["account"], file: file, line: line)
        XCTAssertEqual(rpc.requestNames, [], file: file, line: line)
    }

    private func makeFactoryRpc(contractId: String) -> SACMockRPC {
        let factoryRpc = SACMockRPC(host: "sac-client-factories.mock", contractId: contractId, network: Network.public)
        self.factoryRpc = factoryRpc
        return factoryRpc
    }

    func testForAsset() async throws {
        let factoryRpc = makeFactoryRpc(contractId: usdcPublicId)
        factoryRpc.serveAccount(of: source)

        let client = try SACClient.forAsset(asset: try XCTUnwrap(Asset(canonicalForm: usdc)),
                                            sourceAccountKeyPair: source,
                                            network: Network.public,
                                            rpcUrl: factoryRpc.rpcUrl,
                                            urlSession: factoryRpc.session)

        try await assertFactory(client, contractId: usdcPublicId, sourceAccountId: source.accountId, readOnly: false, on: factoryRpc)
    }

    func testForContractId() async throws {
        let factoryRpc = makeFactoryRpc(contractId: usdcPublicId)
        factoryRpc.serveAccount(of: source)

        let client = try SACClient.forContractId(contractId: usdcPublicId,
                                                 sourceAccountKeyPair: source,
                                                 network: Network.public,
                                                 rpcUrl: factoryRpc.rpcUrl,
                                                 urlSession: factoryRpc.session)

        try await assertFactory(client, contractId: usdcPublicId, sourceAccountId: source.accountId, readOnly: false, on: factoryRpc)
    }

    func testReadOnlyForAsset() async throws {
        let factoryRpc = makeFactoryRpc(contractId: xlmPublicId)

        let client = try SACClient.readOnlyForAsset(asset: try XCTUnwrap(Asset(type: AssetType.ASSET_TYPE_NATIVE)),
                                                    network: Network.public,
                                                    rpcUrl: factoryRpc.rpcUrl,
                                                    urlSession: factoryRpc.session)

        try await assertFactory(client, contractId: xlmPublicId, sourceAccountId: placeholder, readOnly: true, on: factoryRpc)
    }

    func testReadOnlyForContractId() async throws {
        let factoryRpc = makeFactoryRpc(contractId: xlmPublicId)

        let client = try SACClient.readOnlyForContractId(contractId: xlmPublicId,
                                                         network: Network.public,
                                                         rpcUrl: factoryRpc.rpcUrl,
                                                         urlSession: factoryRpc.session)

        try await assertFactory(client, contractId: xlmPublicId, sourceAccountId: placeholder, readOnly: true, on: factoryRpc)
    }

    func testReadOnlySourceAccountIdIsTheZeroKey() throws {
        XCTAssertEqual(SACClient.READ_ONLY_SOURCE_ACCOUNT_ID, placeholder)
        XCTAssertEqual(try KeyPair(accountId: SACClient.READ_ONLY_SOURCE_ACCOUNT_ID).publicKey.bytes, [UInt8](repeating: 0, count: 32))
    }

    func testAssetFactoriesRejectAPoolShare() throws {
        let poolShare = try XCTUnwrap(try ChangeTrustAsset(assetA: try XCTUnwrap(Asset(type: AssetType.ASSET_TYPE_NATIVE)),
                                                           assetB: try XCTUnwrap(Asset(canonicalForm: usdc))))
        let expected = "A liquidity pool share has no Stellar Asset Contract; contractId(network:) takes the native asset or an issued asset"

        XCTAssertThrowsError(try SACClient.forAsset(asset: poolShare, sourceAccountKeyPair: source, network: Network.testnet,
                                                    rpcUrl: rpc.rpcUrl, urlSession: rpc.session)) { error in
            guard case StellarSDKError.xdrEncodingError(let message) = error else {
                XCTFail("expected StellarSDKError.xdrEncodingError, got \(error)")
                return
            }
            XCTAssertEqual(message, expected)
        }
        XCTAssertThrowsError(try SACClient.readOnlyForAsset(asset: poolShare, network: Network.testnet,
                                                            rpcUrl: rpc.rpcUrl, urlSession: rpc.session)) { error in
            guard case StellarSDKError.xdrEncodingError(let message) = error else {
                XCTFail("expected StellarSDKError.xdrEncodingError, got \(error)")
                return
            }
            XCTAssertEqual(message, expected)
        }
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testContractIdFactoriesTurnAHexIdIntoItsStrKey() throws {
        let keyed = try SACClient.forContractId(contractId: sacIdHex, sourceAccountKeyPair: source, network: Network.testnet,
                                                rpcUrl: rpc.rpcUrl, urlSession: rpc.session)
        let readOnly = try SACClient.readOnlyForContractId(contractId: sacIdHex, network: Network.testnet,
                                                           rpcUrl: rpc.rpcUrl, urlSession: rpc.session)

        XCTAssertEqual(keyed.contractId, sacId)
        XCTAssertEqual(keyed.sorobanClient.contractId, sacId)
        XCTAssertEqual(readOnly.contractId, sacId)
        XCTAssertEqual(readOnly.sorobanClient.contractId, sacId)
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testContractIdFactoriesRejectAMuxedContract() throws {
        let expected = "The contract to invoke must be a contract (C...) address, got a muxed contract (W...) address: WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; use its base contract (C...) address"

        XCTAssertThrowsError(try SACClient.forContractId(contractId: muxedContractW, sourceAccountKeyPair: source, network: Network.testnet,
                                                         rpcUrl: rpc.rpcUrl, urlSession: rpc.session)) { error in
            XCTAssertEqual(self.invalidArgument(error), expected)
        }
        XCTAssertThrowsError(try SACClient.readOnlyForContractId(contractId: muxedContractW, network: Network.testnet,
                                                                 rpcUrl: rpc.rpcUrl, urlSession: rpc.session)) { error in
            XCTAssertEqual(self.invalidArgument(error), expected)
        }
        XCTAssertEqual(rpc.requestNames, [])
    }

    /// A seed as the contract id, bare and with a trailing newline, leading spaces, a leading
    /// tab, and a trailing carriage return and newline, is named by its kind and never shown.
    func testContractIdFactoriesRejectASecretSeed() throws {
        let (seed, forms) = try seedForms()
        let expected = "The contract to invoke must be a contract (C...) address, got a secret seed (S...) instead of an address"

        for form in forms {
            XCTAssertThrowsError(try SACClient.forContractId(contractId: form, sourceAccountKeyPair: source, network: Network.testnet,
                                                             rpcUrl: rpc.rpcUrl, urlSession: rpc.session)) { error in
                let message = self.invalidArgument(error)
                XCTAssertEqual(message, expected)
                SACAssert.holdsNoPartOfSeed(message ?? "", seed: seed)
            }
            XCTAssertThrowsError(try SACClient.readOnlyForContractId(contractId: form, network: Network.testnet,
                                                                     rpcUrl: rpc.rpcUrl, urlSession: rpc.session)) { error in
                let message = self.invalidArgument(error)
                XCTAssertEqual(message, expected)
                SACAssert.holdsNoPartOfSeed(message ?? "", seed: seed)
            }
        }
        XCTAssertEqual(rpc.requestNames, [])
    }

    // MARK: - toBaseUnits

    func testToBaseUnitsConvertsDecimalAmounts() throws {
        XCTAssertEqual(try SACClient.toBaseUnits("0"), "0")
        XCTAssertEqual(try SACClient.toBaseUnits("1"), "10000000")
        XCTAssertEqual(try SACClient.toBaseUnits("12.5"), "125000000")
        XCTAssertEqual(try SACClient.toBaseUnits("0.0000001"), "1")
        XCTAssertEqual(try SACClient.toBaseUnits("1.2345678"), "12345678")
        XCTAssertEqual(try SACClient.toBaseUnits("007"), "70000000")
        XCTAssertEqual(try SACClient.toBaseUnits("922337203685.4775807"), "9223372036854775807")
        XCTAssertEqual(try SACClient.toBaseUnits("17014118346046923173168730371588.4105727"), "170141183460469231731687303715884105727")
    }

    /// Every rejected amount, with the text the message shows for it.
    func testToBaseUnitsRejectsOtherText() {
        let rejected: [(amount: String, preview: String)] = [
            ("1.12345678", "1.12345678"),
            ("-1", "-1"),
            ("+1", "+1"),
            (" 1", " 1"),
            ("1 ", "1 "),
            ("1\n", "1\\x0a"),
            ("", ""),
            ("1.", "1."),
            (".5", ".5"),
            ("1e7", "1e7"),
            ("1,5", "1,5"),
            ("\u{0661}", "\u{0661}"),
            ("\u{FF11}", "\u{FF11}"),
            ("1\u{7F}", "1\\x7f"),
            (String(repeating: "a", count: 100), String(repeating: "a", count: 80) + "..."),
        ]
        for (amount, preview) in rejected {
            XCTAssertThrowsError(try SACClient.toBaseUnits(amount), amount) { error in
                XCTAssertEqual(self.invalidArgument(error),
                               "Invalid amount \"\(preview)\": expected decimal digits with at most 7 fractional digits, such as 12.5")
            }
        }
    }

    func testToBaseUnitsRejectsAnAmountAboveTheLargest() {
        XCTAssertThrowsError(try SACClient.toBaseUnits("17014118346046923173168730371588.4105728")) { error in
            XCTAssertEqual(self.invalidArgument(error),
                           "Amount 17014118346046923173168730371588.4105728 exceeds the largest i128 amount, 17014118346046923173168730371588.4105727")
        }
        XCTAssertThrowsError(try SACClient.toBaseUnits("100000000000000000000000000000000")) { error in
            XCTAssertEqual(self.invalidArgument(error),
                           "Amount 100000000000000000000000000000000 exceeds the largest i128 amount, 17014118346046923173168730371588.4105727")
        }
    }

    /// A seed as the amount, bare and with a trailing newline, leading spaces, a leading tab,
    /// and a trailing carriage return and newline, is named by its kind and never shown.
    func testToBaseUnitsNamesASecretSeedByItsKind() throws {
        let (seed, forms) = try seedForms()
        for form in forms {
            XCTAssertThrowsError(try SACClient.toBaseUnits(form)) { error in
                let message = self.invalidArgument(error)
                XCTAssertEqual(message, "Invalid amount: got a secret seed (S...) instead of a decimal amount")
                SACAssert.holdsNoPartOfSeed(message ?? "", seed: seed)
            }
        }
    }

    /// A seed after other text is redacted in the preview.
    func testToBaseUnitsRedactsASecretSeedInThePreview() throws {
        let seed = try XCTUnwrap(try KeyPair.generateRandomKeyPair().secretSeed)

        XCTAssertThrowsError(try SACClient.toBaseUnits("1 " + seed)) { error in
            let message = self.invalidArgument(error)
            XCTAssertEqual(message, "Invalid amount \"1 a secret seed (S...)\": expected decimal digits with at most 7 fractional digits, such as 12.5")
            SACAssert.holdsNoPartOfSeed(message ?? "", seed: seed)
        }
    }

    // MARK: - Reads

    func testDecimalsReturnsSeven() async throws {
        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.u32(7))])

        let decimals = try await readOnlyClient().decimals()

        XCTAssertEqual(decimals, 7)
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "decimals", args: [])
    }

    func testNameReturnsTheString() async throws {
        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.string(usdc))])

        let name = try await readOnlyClient().name()

        XCTAssertEqual(name, "USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN")
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "name", args: [])
    }

    func testSymbolReturnsTheString() async throws {
        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.string("USDC"))])

        let symbol = try await readOnlyClient().symbol()

        XCTAssertEqual(symbol, "USDC")
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "symbol", args: [])
    }

    /// A read-only client reads the balance 2^100 of an account with one simulation.
    func testBalanceOfAnAccountOnAReadOnlyClient() async throws {
        rpc.serveSimulations([.read(contractId: sacId, returning: try SCValXDR.i128(stringValue: "1267650600228229401496703205376"))])

        let balance = try await readOnlyClient().balance(holder: try address(accountG))

        XCTAssertEqual(balance, "1267650600228229401496703205376")
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId,
                                 function: "balance", args: [SCValXDR.address(try address(accountG))])
    }

    /// A keyed client reads the balance 2^127 - 1 of a contract; its build loads the account first.
    func testBalanceOfAContractOnAKeyedClient() async throws {
        rpc.serveSimulations([.read(contractId: sacId, returning: try SCValXDR.i128(stringValue: maxI128))])

        let balance = try await keyedClient().balance(holder: try address(contractC))

        XCTAssertEqual(balance, "170141183460469231731687303715884105727")
        XCTAssertEqual(rpc.requestNames, ["account", "simulate"])
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId,
                                 function: "balance", args: [SCValXDR.address(try address(contractC))])
    }

    func testBalanceOfAMissingAccountThrowsTheContractError() async throws {
        rpc.serveSimulations([.failure("HostError: Error(Contract, #6)")])
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.accountG)) }

        XCTAssertEqual(simulationFailed(error), "Simulation failed with error: HostError: Error(Contract, #6)")
        XCTAssertEqual((error as? AssembledTransactionError)?.reportedContractError?.code, 6)
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId,
                                 function: "balance", args: [SCValXDR.address(try address(accountG))])
    }

    func testBalanceWithoutATrustlineThrowsTheContractError() async throws {
        rpc.serveSimulations([.failure("HostError: Error(Contract, #13)")])
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.accountG)) }

        XCTAssertEqual(simulationFailed(error), "Simulation failed with error: HostError: Error(Contract, #13)")
        XCTAssertEqual((error as? AssembledTransactionError)?.reportedContractError?.code, 13)
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId,
                                 function: "balance", args: [SCValXDR.address(try address(accountG))])
    }

    func testUncodedSimulationError() async throws {
        rpc.serveSimulations([.failure("HostError: Error(Value, UnexpectedType)")])
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.accountG)) }

        XCTAssertEqual(simulationFailed(error), "Simulation failed with error: HostError: Error(Value, UnexpectedType)")
        XCTAssertNil((error as? AssembledTransactionError)?.reportedContractError)
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId,
                                 function: "balance", args: [SCValXDR.address(try address(accountG))])
    }

    func testBalanceRejectsAMuxedAccountHolder() async throws {
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.muxedAccountM)) }

        XCTAssertEqual(invalidArgument(error), "The balance holder must be an account (G...) or contract (C...) address, got a muxed account (M...) address: MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ; query its base account GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testBalanceRejectsAMuxedContractHolder() async throws {
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.muxedContractW)) }

        XCTAssertEqual(invalidArgument(error), "The balance holder must be an account (G...) or contract (C...) address, got a muxed contract (W...) address: WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; query its base contract CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE")
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testBalanceRejectsAClaimableBalanceHolder() async throws {
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.claimableBalanceB)) }

        XCTAssertEqual(invalidType(error), "Address takes an account (G...) or contract (C...) address, got the claimable balance address BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU, which is produced by the host and is not a contract input")
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testBalanceRejectsALiquidityPoolHolder() async throws {
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.liquidityPoolL)) }

        XCTAssertEqual(invalidType(error), "Address takes an account (G...) or contract (C...) address, got the liquidity pool address LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN, which is produced by the host and is not a contract input")
        XCTAssertEqual(rpc.requestNames, [])
    }

    /// Each read names the arm it got and the arm it expects.
    func testReadsRejectAnotherArm() async throws {
        let client = try readOnlyClient()
        let prefix = "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC returned "

        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.u32(7))])
        var error = await SACAssert.error { _ = try await client.balance(holder: try self.address(self.accountG)) }
        XCTAssertEqual(invokeFailed(error), prefix + "SCV_U32 from balance, expected SCV_I128")

        rpc.serveSimulations([.read(contractId: sacId, returning: try SCValXDR.i128(stringValue: "7"))])
        error = await SACAssert.error { _ = try await client.decimals() }
        XCTAssertEqual(invokeFailed(error), prefix + "SCV_I128 from decimals, expected SCV_U32")

        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.symbol("native"))])
        error = await SACAssert.error { _ = try await client.name() }
        XCTAssertEqual(invokeFailed(error), prefix + "SCV_SYMBOL from name, expected SCV_STRING")

        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.void)])
        error = await SACAssert.error { _ = try await client.symbol() }
        XCTAssertEqual(invokeFailed(error), prefix + "SCV_VOID from symbol, expected SCV_STRING")

        XCTAssertEqual(rpc.requestNames, ["simulate", "simulate", "simulate", "simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId,
                                 function: "balance", args: [SCValXDR.address(try address(accountG))])
        try SACAssert.invocation(try rpc.request(1), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "decimals", args: [])
        try SACAssert.invocation(try rpc.request(2), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "name", args: [])
        try SACAssert.invocation(try rpc.request(3), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "symbol", args: [])
    }

    /// Each read throws its own restore error for a restore preamble and sends nothing more,
    /// on a read-only client and on a keyed one.
    func testReadsRejectARestorePreamble() async throws {
        let readOnly = try readOnlyClient()
        let keyed = try keyedClient()
        rpc.serveSimulations([simulationWithPreamble(transactionData: true)])
        let prefix = "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC cannot run "
        let suffix = ": ledger entries it needs are archived; restore them from a client opened with a funded account's keypair"

        var error = await SACAssert.error { _ = try await readOnly.balance(holder: try self.address(self.accountG)) }
        XCTAssertEqual(restoreNeeded(error), prefix + "balance" + suffix)
        error = await SACAssert.error { _ = try await readOnly.decimals() }
        XCTAssertEqual(restoreNeeded(error), prefix + "decimals" + suffix)
        error = await SACAssert.error { _ = try await readOnly.name() }
        XCTAssertEqual(restoreNeeded(error), prefix + "name" + suffix)
        error = await SACAssert.error { _ = try await readOnly.symbol() }
        XCTAssertEqual(restoreNeeded(error), prefix + "symbol" + suffix)
        error = await SACAssert.error { _ = try await keyed.balance(holder: try self.address(self.accountG)) }
        XCTAssertEqual(restoreNeeded(error), prefix + "balance" + suffix)
        error = await SACAssert.error { _ = try await keyed.decimals() }
        XCTAssertEqual(restoreNeeded(error), prefix + "decimals" + suffix)
        error = await SACAssert.error { _ = try await keyed.name() }
        XCTAssertEqual(restoreNeeded(error), prefix + "name" + suffix)
        error = await SACAssert.error { _ = try await keyed.symbol() }
        XCTAssertEqual(restoreNeeded(error), prefix + "symbol" + suffix)

        XCTAssertEqual(rpc.requestNames, ["simulate", "simulate", "simulate", "simulate",
                                          "account", "simulate", "account", "simulate", "account", "simulate", "account", "simulate"])
        let balanceArgs = [SCValXDR.address(try address(accountG))]
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "balance", args: balanceArgs)
        try SACAssert.invocation(try rpc.request(1), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "decimals", args: [])
        try SACAssert.invocation(try rpc.request(2), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "name", args: [])
        try SACAssert.invocation(try rpc.request(3), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "symbol", args: [])
        try SACAssert.invocation(try rpc.request(5), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "balance", args: balanceArgs)
        try SACAssert.invocation(try rpc.request(7), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "decimals", args: [])
        try SACAssert.invocation(try rpc.request(9), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "name", args: [])
        try SACAssert.invocation(try rpc.request(11), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "symbol", args: [])
    }

    func testNameRejectsBytesThatAreNotUTF8() async throws {
        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.string(Data([0xff, 0xfe])))])
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.name() }

        XCTAssertEqual(invokeFailed(error), "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC returned a string from name whose bytes are not valid UTF-8: \"\\xff\\xfe\"")
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "name", args: [])
    }

    func testSymbolRejectsBytesThatAreNotUTF8() async throws {
        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.string(Data([0xff, 0xfe])))])
        let client = try readOnlyClient()

        let error = await SACAssert.error { _ = try await client.symbol() }

        XCTAssertEqual(invokeFailed(error), "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC returned a string from symbol whose bytes are not valid UTF-8: \"\\xff\\xfe\"")
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "symbol", args: [])
    }

    // MARK: - transfer

    /// A transfer from an account to a muxed account, a muxed contract, a contract, and an
    /// account passes each address in its own case, and signs and sends nothing.
    func testTransferPassesEachAddressKind() async throws {
        let client = try readOnlyClient()
        rpc.serveSimulations([.write(contractId: sacId)])

        for receiver in [muxedAccountM, muxedContractW, contractC, otherAccountG] {
            rpc.clearRequests()

            let tx = try await client.transfer(from: try address(accountG), to: try address(receiver), amount: "125000000")

            XCTAssertNil(tx.signed)
            XCTAssertEqual(rpc.requestNames, ["simulate"], receiver)
            try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "transfer",
                                     args: try transferArgs(from: accountG, to: receiver, amount: "125000000"))
        }

        guard case .account = try address(accountG),
              case .muxedAccount = try address(muxedAccountM),
              case .muxedContract = try address(muxedContractW),
              case .contract = try address(contractC) else {
            XCTFail("an address has another case than its strkey names")
            return
        }
    }

    func testTransferAcceptsTheAmountVectors() async throws {
        let client = try readOnlyClient()
        rpc.serveSimulations([.write(contractId: sacId)])

        for (amount, baseUnits) in [("0", "0"), ("007", "7"), (maxI128, maxI128), ("0" + maxI128, maxI128)] {
            rpc.clearRequests()

            _ = try await client.transfer(from: try address(accountG), to: try address(otherAccountG), amount: amount)

            XCTAssertEqual(rpc.requestNames, ["simulate"], amount)
            try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "transfer",
                                     args: try transferArgs(from: accountG, to: otherAccountG, amount: baseUnits))
        }
    }

    /// A contract as the sender goes in as a contract address, and its unsigned entry is
    /// reported as the contract's hex id.
    func testTransferFromAContract() async throws {
        let args = try transferArgs(from: contractC, to: accountG, amount: "5")
        let entry = SACMockRPC.addressAuthEntry(address: try address(contractC), contractId: sacId, function: "transfer", args: args)
        rpc.serveSimulations([.write(contractId: sacId, auth: [entry])])

        let tx = try await readOnlyClient().transfer(from: try address(contractC), to: try address(accountG), amount: "5")

        XCTAssertEqual(try tx.needsNonInvokerSigningBy(), ["363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103"])
        XCTAssertEqual(try contractC.decodeContractIdToHex(), "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103")
        XCTAssertNil(tx.signed)
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "transfer", args: args)
    }

    func testTransferRejectsAMuxedSender() async throws {
        let client = try readOnlyClient()

        let error = await SACAssert.error {
            _ = try await client.transfer(from: try self.address(self.muxedAccountM), to: try self.address(self.accountG), amount: "1")
        }

        XCTAssertEqual(invalidType(error), "Address takes an account (G...) or contract (C...) address, got the muxed address MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ, which needs a MuxedAddress parameter")
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testTransferRejectsAClaimableBalanceReceiver() async throws {
        let client = try readOnlyClient()

        let error = await SACAssert.error {
            _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.claimableBalanceB), amount: "1")
        }

        XCTAssertEqual(invalidType(error), "MuxedAddress takes an account (G...), muxed account (M...), contract (C...) or muxed contract (W...) address, got the claimable balance address BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU, which is produced by the host and is not a contract input")
        XCTAssertEqual(rpc.requestNames, [])
    }

    func testTransferRejectsALiquidityPoolReceiver() async throws {
        let client = try readOnlyClient()

        let error = await SACAssert.error {
            _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.liquidityPoolL), amount: "1")
        }

        XCTAssertEqual(invalidType(error), "MuxedAddress takes an account (G...), muxed account (M...), contract (C...) or muxed contract (W...) address, got the liquidity pool address LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN, which is produced by the host and is not a contract input")
        XCTAssertEqual(rpc.requestNames, [])
    }

    /// Every rejected transfer amount throws before any request.
    func testTransferRejectsOtherAmounts() async throws {
        let client = try keyedClient()

        for (amount, preview) in [("-1", "-1"), ("1.5", "1.5"), (" 1", " 1"), ("", "")] {
            let error = await SACAssert.error {
                _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.otherAccountG), amount: amount)
            }
            XCTAssertEqual(invalidArgument(error), "The transfer amount must be a whole number of base units, got \"\(preview)\"; convert a decimal amount with SACClient.toBaseUnits(_:)")
        }
        let error = await SACAssert.error {
            _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.otherAccountG),
                                          amount: "170141183460469231731687303715884105728")
        }
        XCTAssertEqual(invalidArgument(error), "The transfer amount must be from 0 to 170141183460469231731687303715884105727 base units, got 170141183460469231731687303715884105728")
        let errorWithLeadingZero = await SACAssert.error {
            _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.otherAccountG),
                                          amount: "0170141183460469231731687303715884105728")
        }
        XCTAssertEqual(invalidArgument(errorWithLeadingZero), "The transfer amount must be from 0 to 170141183460469231731687303715884105727 base units, got 0170141183460469231731687303715884105728")
        XCTAssertEqual(rpc.requestNames, [])
    }

    /// A seed as the transfer amount, bare and with a trailing newline, leading spaces, a
    /// leading tab, and a trailing carriage return and newline, is named by its kind and
    /// never shown; a seed after other text is redacted in the preview.
    func testTransferNamesASecretSeedByItsKind() async throws {
        let client = try keyedClient()
        let (seed, forms) = try seedForms()

        for form in forms {
            let error = await SACAssert.error {
                _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.otherAccountG), amount: form)
            }
            let message = invalidArgument(error)
            XCTAssertEqual(message, "Invalid transfer amount: got a secret seed (S...) instead of a whole number of base units")
            SACAssert.holdsNoPartOfSeed(message ?? "", seed: seed)
        }
        let error = await SACAssert.error {
            _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.otherAccountG), amount: "1 " + seed)
        }
        let message = invalidArgument(error)
        XCTAssertEqual(message, "The transfer amount must be a whole number of base units, got \"1 a secret seed (S...)\"; convert a decimal amount with SACClient.toBaseUnits(_:)")
        SACAssert.holdsNoPartOfSeed(message ?? "", seed: seed)
        XCTAssertEqual(rpc.requestNames, [])
    }

    /// With `restore: true` and a restore preamble, a read-only transfer refuses to restore.
    func testReadOnlyTransferRefusesToRestore() async throws {
        rpc.serveSimulations([simulationWithPreamble(transactionData: true)])
        let client = try readOnlyClient()

        let error = await SACAssert.error {
            _ = try await client.transfer(from: try self.address(self.accountG), to: try self.address(self.otherAccountG), amount: "5",
                                          methodOptions: MethodOptions(restore: true))
        }

        XCTAssertEqual(missingPrivateKey(error), "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair")
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "transfer",
                                 args: try transferArgs(from: accountG, to: otherAccountG, amount: "5"))
    }

    func testReadOnlyTransferRefusesSignAndSend() async throws {
        rpc.serveSimulations([.write(contractId: sacId)])
        let tx = try await readOnlyClient().transfer(from: try address(accountG), to: try address(otherAccountG), amount: "5")

        let error = await SACAssert.error { _ = try await tx.signAndSend() }

        XCTAssertEqual(missingPrivateKey(error), "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair")
        XCTAssertNil(tx.signed)
        XCTAssertEqual(rpc.requestNames, ["simulate"])
        try SACAssert.invocation(try rpc.request(0), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "transfer",
                                 args: try transferArgs(from: accountG, to: otherAccountG, amount: "5"))
    }

    // MARK: - transfer: options

    func testTransferDefaultOptions() async throws {
        rpc.serveSimulations([.write(contractId: sacId)])
        let client = try keyedClient()

        let before = now()
        let tx = try await client.transfer(from: try address(source.accountId), to: try address(otherAccountG), amount: "5")
        let after = now()

        XCTAssertNotNil(tx.tx)
        XCTAssertNil(tx.signed)
        XCTAssertEqual(rpc.requestNames, ["account", "simulate"])
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer",
                                 args: try transferArgs(from: source.accountId, to: otherAccountG, amount: "5"))
        try assertWriteOptions(try rpc.request(1), fee: 100, timeout: 300, before: before, after: after, useUpgradedAuth: true)
    }

    func testTransferCustomOptions() async throws {
        rpc.serveSimulations([.write(contractId: sacId)])
        let client = try keyedClient()

        let before = now()
        _ = try await client.transfer(from: try address(source.accountId), to: try address(otherAccountG), amount: "5",
                                      methodOptions: MethodOptions(fee: 1234, timeoutInSeconds: 60, useUpgradedAuth: false))
        let after = now()

        XCTAssertEqual(rpc.requestNames, ["account", "simulate"])
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer",
                                 args: try transferArgs(from: source.accountId, to: otherAccountG, amount: "5"))
        try assertWriteOptions(try rpc.request(1), fee: 1234, timeout: 60, before: before, after: after, useUpgradedAuth: false)
    }

    /// With `simulate: false`, `transfer` returns the transaction unsimulated.
    func testTransferUnsimulated() async throws {
        let tx = try await keyedClient().transfer(from: try address(source.accountId), to: try address(otherAccountG), amount: "5",
                                                 methodOptions: MethodOptions(simulate: false))

        XCTAssertNil(tx.tx)
        XCTAssertNil(tx.simulationResponse)
        XCTAssertNotNil(tx.raw)
        XCTAssertEqual(rpc.requestNames, ["account"])
    }

    /// With `restore: false`, `signAndSend()` on a keyed and on a read-only transfer whose
    /// simulation answered `simulation` throws through the read-call check and sends nothing.
    private func signAndSendErrors(after simulation: SACMockRPC.Simulation) async throws -> (keyed: Error?, readOnly: Error?) {
        rpc.serveSimulations([simulation])
        let keyedTx = try await keyedClient().transfer(from: try address(source.accountId), to: try address(otherAccountG), amount: "5")
        let keyedError = await SACAssert.error { _ = try await keyedTx.signAndSend() }
        let readOnlyTx = try await readOnlyClient().transfer(from: try address(accountG), to: try address(otherAccountG), amount: "5")
        let readOnlyError = await SACAssert.error { _ = try await readOnlyTx.signAndSend() }

        XCTAssertNil(keyedTx.signed)
        XCTAssertNil(readOnlyTx.signed)
        XCTAssertEqual(rpc.requestNames, ["account", "simulate", "simulate"])
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer",
                                 args: try transferArgs(from: source.accountId, to: otherAccountG, amount: "5"))
        try SACAssert.invocation(try rpc.request(2), source: placeholder, sequenceNumber: 1, contractId: sacId, function: "transfer",
                                 args: try transferArgs(from: accountG, to: otherAccountG, amount: "5"))
        return (keyedError, readOnlyError)
    }

    func testSignAndSendAfterAPreambleWithoutTransactionDataSendsNothing() async throws {
        let errors = try await signAndSendErrors(after: simulationWithPreamble(transactionData: false))

        XCTAssertEqual(simulationFailed(errors.keyed), "Transaction simulation failed")
        XCTAssertEqual(simulationFailed(errors.readOnly), "Transaction simulation failed")
    }

    func testSignAndSendAfterAnErrorWithAPreambleSendsNothing() async throws {
        let errors = try await signAndSendErrors(after: simulationWithPreamble(transactionData: true, error: "HostError: Error(Storage, MissingValue)"))

        XCTAssertEqual(simulationFailed(errors.keyed), "Transaction simulation failed. Error: HostError: Error(Storage, MissingValue)")
        XCTAssertEqual(simulationFailed(errors.readOnly), "Transaction simulation failed. Error: HostError: Error(Storage, MissingValue)")
    }

    func testSignAndSendAfterAPreambleWithTransactionDataSendsNothing() async throws {
        let errors = try await signAndSendErrors(after: simulationWithPreamble(transactionData: true))
        let expected = "You need to restore some contract state before you can invoke this method. You can set `restore` to true in the options in order to automatically restore the contract state when needed."

        XCTAssertEqual(restoreNeeded(errors.keyed), expected)
        XCTAssertEqual(restoreNeeded(errors.readOnly), expected)
    }

    // MARK: - transferAndSend

    /// The transfer uses the source as the sender with the default options, sends the
    /// simulated transaction signed by the source, and returns the `SUCCESS` response.
    func testTransferAndSendReturnsTheSuccessResponse() async throws {
        rpc.serveSimulations([.write(contractId: sacId, minResourceFee: 1000)])
        rpc.serveSend(.status("PENDING"))
        rpc.serveTransaction([.status("SUCCESS")])
        let client = try keyedClient()

        let before = now()
        let response = try await client.transferAndSend(to: try address(muxedAccountM), amount: "125000000")
        let after = now()

        XCTAssertEqual(response.status, "SUCCESS")
        XCTAssertEqual(rpc.requestNames, ["account", "simulate", "send", "getTx"])
        let args = try transferArgs(from: source.accountId, to: muxedAccountM, amount: "125000000")
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
        try assertWriteOptions(try rpc.request(1), fee: 100, timeout: 300, before: before, after: after, useUpgradedAuth: true)
        try SACAssert.invocation(try rpc.request(2), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
        let sent = try rpc.request(2).invocation()
        XCTAssertEqual(sent.envelope.fee, 1100)
        XCTAssertEqual(sent.envelope.signatures.count, 1)
        XCTAssertEqual(try rpc.request(3).params()["hash"] as? String, try XCTUnwrap(rpc.sentHash))
    }

    func testTransferAndSendCustomOptions() async throws {
        rpc.serveSimulations([.write(contractId: sacId, minResourceFee: 1000)])
        rpc.serveSend(.status("PENDING"))
        rpc.serveTransaction([.status("SUCCESS")])
        let client = try keyedClient()

        let before = now()
        let response = try await client.transferAndSend(to: try address(otherAccountG), amount: "5",
                                                        methodOptions: MethodOptions(fee: 1234, timeoutInSeconds: 60, useUpgradedAuth: false))
        let after = now()

        XCTAssertEqual(response.status, "SUCCESS")
        XCTAssertEqual(rpc.requestNames, ["account", "simulate", "send", "getTx"])
        let args = try transferArgs(from: source.accountId, to: otherAccountG, amount: "5")
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
        try assertWriteOptions(try rpc.request(1), fee: 1234, timeout: 60, before: before, after: after, useUpgradedAuth: false)
        try SACAssert.invocation(try rpc.request(2), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
        XCTAssertEqual(try rpc.request(2).invocation().envelope.fee, 2234)
    }

    /// With `simulate: false`, a keyed `transferAndSend` throws the not-simulated error of `sign()`.
    func testTransferAndSendUnsimulatedThrowsNotYetSimulated() async throws {
        let client = try keyedClient()

        let error = await SACAssert.error {
            _ = try await client.transferAndSend(to: try self.address(self.otherAccountG), amount: "5", methodOptions: MethodOptions(simulate: false))
        }

        guard case AssembledTransactionError.notYetSimulated(let message)? = error else {
            XCTFail("expected AssembledTransactionError.notYetSimulated, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(message, "Transaction has not yet been simulated")
        XCTAssertEqual(rpc.requestNames, ["account"])
    }

    /// Runs a keyed `transferAndSend` of 5 base units that must throw, with a one second
    /// timeout, and asserts the simulated and the sent invocation.
    private func failingTransferAndSend(expectedRequests: [String], file: StaticString = #filePath, line: UInt = #line) async throws -> Error? {
        rpc.serveSimulations([.write(contractId: sacId)])
        let client = try keyedClient()

        let error = await SACAssert.error(file: file, line: line) {
            _ = try await client.transferAndSend(to: try self.address(self.otherAccountG), amount: "5", methodOptions: MethodOptions(timeoutInSeconds: 1))
        }

        XCTAssertEqual(rpc.requestNames, expectedRequests, file: file, line: line)
        let args = try transferArgs(from: source.accountId, to: otherAccountG, amount: "5")
        for request in rpc.requests(named: "simulate") + rpc.requests(named: "send") {
            try SACAssert.invocation(request, source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer",
                                     args: args, file: file, line: line)
        }
        return error
    }

    func testTransferAndSendFailedWithResultXdr() async throws {
        rpc.serveSend(.status("PENDING"))
        rpc.serveTransaction([.status("FAILED", resultXdr: "AAAAAAAAAGT////7AAAAAA==")])

        let error = try await failingTransferAndSend(expectedRequests: ["account", "simulate", "send", "getTx"])

        XCTAssertEqual(invokeFailed(error), "The transfer did not succeed: status FAILED, transaction result xdr: AAAAAAAAAGT////7AAAAAA==")
    }

    func testTransferAndSendFailedWithoutResultXdr() async throws {
        rpc.serveSend(.status("PENDING"))
        rpc.serveTransaction([.status("FAILED")])

        let error = try await failingTransferAndSend(expectedRequests: ["account", "simulate", "send", "getTx"])

        XCTAssertEqual(invokeFailed(error), "The transfer did not succeed: status FAILED, transaction result xdr: not available")
    }

    func testTransferAndSendSendStatusError() async throws {
        rpc.serveSend(.status("ERROR"))

        let error = try await failingTransferAndSend(expectedRequests: ["account", "simulate", "send"])

        guard case AssembledTransactionError.sendFailed(let message)? = error else {
            XCTFail("expected AssembledTransactionError.sendFailed, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(message, "Send transaction failed with status: ERROR")
    }

    /// A JSON-RPC error answer to `sendTransaction` throws the request error, and nothing is polled.
    func testTransferAndSendSendRpcError() async throws {
        rpc.serveSend(.rpcError(code: -32603, message: "internal error"))

        let error = try await failingTransferAndSend(expectedRequests: ["account", "simulate", "send"])

        guard case SorobanRpcRequestError.errorResponse(let rpcError)? = error else {
            XCTFail("expected SorobanRpcRequestError.errorResponse, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(rpcError.code, -32603)
        XCTAssertEqual(rpcError.message, "internal error")
    }

    /// With `restore: true`, a keyed transfer whose simulation answers a restore preamble
    /// restores first: it builds a restore transaction on the source account with the
    /// preamble's Soroban data and fee, simulates it, signs and sends it, and waits for its
    /// success. Then it builds the transfer again on the account's new sequence number and
    /// simulates it.
    func testKeyedTransferRestoresFirst() async throws {
        let preambleData = SACMockRPC.transactionData(contractId: sacId, writes: true, resourceFee: 777)
        var archived = SACMockRPC.Simulation.write(contractId: sacId)
        archived.restorePreamble = (preambleData, 100)
        let restoreSimulation = SACMockRPC.Simulation(transactionData: preambleData, minResourceFee: 300)
        rpc.serveSimulations([archived, restoreSimulation, .write(contractId: sacId, minResourceFee: 1000)])
        rpc.serveSend(.status("PENDING"))
        rpc.serveTransaction([.status("SUCCESS")])
        let client = try keyedClient(sequenceNumbers: [12345, 12345, 12346])

        let tx = try await client.transfer(from: try address(source.accountId), to: try address(otherAccountG), amount: "5",
                                           methodOptions: MethodOptions(timeoutInSeconds: 1, restore: true))

        XCTAssertEqual(rpc.requestNames, ["account", "simulate", "account", "simulate", "send", "getTx", "account", "simulate"])
        let args = try transferArgs(from: source.accountId, to: otherAccountG, amount: "5")
        let preambleDataXdr = try SACTestXdr.base64(preambleData)

        // The transfer, whose simulation answers the preamble.
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)

        // The restore transaction as simulated: the preamble's data and fee, unsigned.
        let simulatedRestore = try rpc.request(3).envelopeFields()
        XCTAssertTrue(simulatedRestore.isRestoreFootprint)
        XCTAssertEqual(simulatedRestore.source, source.accountId)
        XCTAssertEqual(simulatedRestore.sequenceNumber, 12346)
        XCTAssertEqual(simulatedRestore.fee, 100)
        XCTAssertEqual(simulatedRestore.sorobanData, preambleDataXdr)
        XCTAssertEqual(simulatedRestore.signatures, [])

        // The restore transaction as sent: the data and the resource fee of its simulation, signed once.
        let sentRestore = try rpc.request(4).envelopeFields()
        XCTAssertTrue(sentRestore.isRestoreFootprint)
        XCTAssertEqual(sentRestore.source, source.accountId)
        XCTAssertEqual(sentRestore.sequenceNumber, 12346)
        XCTAssertEqual(sentRestore.fee, 400)
        XCTAssertEqual(sentRestore.sorobanData, preambleDataXdr)
        XCTAssertEqual(sentRestore.signatures.count, 1)
        XCTAssertEqual(try rpc.request(5).params()["hash"] as? String, try XCTUnwrap(rpc.sentHash))

        // The transfer again, on the sequence number the account has after the restore.
        try SACAssert.invocation(try rpc.request(7), source: source.accountId, sequenceNumber: 12347, contractId: sacId, function: "transfer", args: args)
        XCTAssertEqual(try rpc.request(7).invocation().envelope.fee, 100)
        XCTAssertEqual(tx.tx?.fee, 1100)
        XCTAssertNil(tx.signed)
        XCTAssertFalse(try tx.isReadCall())
    }

    /// A failed status request is retried, and the `SUCCESS` answer after it returns.
    func testTransferAndSendRetriesAFailedStatusRequest() async throws {
        rpc.serveSimulations([.write(contractId: sacId)])
        rpc.serveSend(.status("PENDING"))
        rpc.serveTransaction([.rpcError(code: -32603, message: "busy"), .status("SUCCESS")])
        let client = try keyedClient()

        let response = try await client.transferAndSend(to: try address(otherAccountG), amount: "5", methodOptions: MethodOptions(timeoutInSeconds: 4))

        XCTAssertEqual(response.status, "SUCCESS")
        XCTAssertEqual(rpc.requestNames, ["account", "simulate", "send", "getTx", "getTx"])
        let args = try transferArgs(from: source.accountId, to: otherAccountG, amount: "5")
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
        try SACAssert.invocation(try rpc.request(2), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
    }

    /// `NOT_FOUND` on every poll until the timeout throws `pollInterrupted` naming the hash
    /// of the sent transaction.
    func testTransferAndSendPollInterrupted() async throws {
        rpc.serveSimulations([.write(contractId: sacId)])
        rpc.serveSend(.status("PENDING"))
        rpc.serveTransaction([.status("NOT_FOUND")])
        let client = try keyedClient()

        let error = await SACAssert.error {
            _ = try await client.transferAndSend(to: try self.address(self.otherAccountG), amount: "5", methodOptions: MethodOptions(timeoutInSeconds: 2))
        }

        XCTAssertEqual(rpc.requestNames, ["account", "simulate", "send", "getTx"])
        let args = try transferArgs(from: source.accountId, to: otherAccountG, amount: "5")
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
        try SACAssert.invocation(try rpc.request(2), source: source.accountId, sequenceNumber: 12346, contractId: sacId, function: "transfer", args: args)
        let hash = try Transaction(envelopeXdr: try rpc.request(2).envelope()).getTransactionHash(network: Network.testnet)
        XCTAssertEqual(hash.count, 64)
        guard case AssembledTransactionError.pollInterrupted(let message)? = error else {
            XCTFail("expected AssembledTransactionError.pollInterrupted, got \(String(describing: error))")
            return
        }
        XCTAssertEqual(message, "Interrupted after waiting 2 seconds (options->timeoutInSeconds) for the transaction \(hash) to complete.")
    }

    /// A read-only `transferAndSend` throws before the amount check and before any request,
    /// whatever the options.
    func testReadOnlyTransferAndSendThrowsBeforeAnyRequest() async throws {
        let client = try readOnlyClient()
        let expected = "transferAndSend needs the sending account's keypair, and this SACClient is read-only; open the client with SACClient.forAsset or SACClient.forContractId"

        var error = await SACAssert.error { _ = try await client.transferAndSend(to: try self.address(self.accountG), amount: "-1") }
        XCTAssertEqual(missingPrivateKey(error), expected)
        error = await SACAssert.error {
            _ = try await client.transferAndSend(to: try self.address(self.accountG), amount: "5", methodOptions: MethodOptions(simulate: false))
        }
        XCTAssertEqual(missingPrivateKey(error), expected)
        XCTAssertEqual(rpc.requestNames, [])
    }

    // MARK: - The test session

    /// A request to another host and a `GET` to the mock host match no mock: the catcher
    /// records each and fails it without a connection.
    func testCatcherRecordsAndFailsUnmatchedRequests() async throws {
        let requests = [
            URLRequest(url: try XCTUnwrap(URL(string: "https://another-host.mock/path"))),
            URLRequest(url: try XCTUnwrap(URL(string: rpc.rpcUrl))),
        ]

        for request in requests {
            do {
                _ = try await rpc.session.data(for: request)
                XCTFail("the request must fail")
            } catch {
                XCTAssertEqual((error as? URLError)?.code, URLError.Code.cannotConnectToHost)
            }
        }

        XCTAssertEqual(SACUnmatchedRequestCatcher.records, ["GET https://another-host.mock/path", "GET https://sac-client-unit-tests.mock"])
        SACUnmatchedRequestCatcher.clear()
        XCTAssertEqual(rpc.requestNames, [])
    }
}
