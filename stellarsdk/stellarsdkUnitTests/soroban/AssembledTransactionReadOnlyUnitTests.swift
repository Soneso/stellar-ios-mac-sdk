//
//  AssembledTransactionReadOnlyUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Soneso on 22.11.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Tests the read-only state of `AssembledTransaction`, set through
/// `SorobanClient.forSpecEntries(specEntries:options:readOnly:)`.
///
/// A read-only transaction builds without loading its source account, on sequence number 0,
/// allows authorization entry signing, and refuses to sign its envelope, to submit, and to
/// restore. The state follows the flag, not the source account, so every read-only case runs
/// on three sources: the placeholder account, a random keypair, and a public-only keypair.
///
/// The RPC is `SACMockRPC` on a host that resolves nowhere; `tearDown` fails a test whose
/// requests the mock did not expect or that left the mock.
final class AssembledTransactionReadOnlyUnitTests: XCTestCase {

    private let sacId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
    private let holderId = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ"
    private let receiverId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"

    private var rpc: SACMockRPC!

    override func setUp() {
        super.setUp()
        rpc = SACMockRPC(host: "read-only-unit-tests.mock", contractId: sacId)
    }

    override func tearDown() {
        rpc.tearDown()
        rpc = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func client(source: KeyPair, readOnly: Bool = true) throws -> SorobanClient {
        let options = ClientOptions(sourceAccountKeyPair: source,
                                    contractId: sacId,
                                    network: Network.testnet,
                                    rpcUrl: rpc.rpcUrl,
                                    urlSession: rpc.session)
        return try SorobanClient.forSpecEntries(specEntries: try SACClient.specEntries(), options: options, readOnly: readOnly)
    }

    /// Runs `body` with a read-only client for each of the three sources, on an empty request log.
    private func forEachSource(_ body: (KeyPair, SorobanClient) async throws -> Void) async throws {
        let sources = [
            try KeyPair(accountId: SACClient.READ_ONLY_SOURCE_ACCOUNT_ID),
            try KeyPair.generateRandomKeyPair(),
            try KeyPair(accountId: try KeyPair.generateRandomKeyPair().accountId),
        ]
        for source in sources {
            rpc.clearRequests()
            try await body(source, try client(source: source))
        }
    }

    private func balanceArgs() throws -> [SCValXDR] {
        return [SCValXDR.address(try SCAddressXDR(accountId: holderId))]
    }

    private func transferArgs() throws -> [SCValXDR] {
        return [
            SCValXDR.address(try SCAddressXDR(accountId: holderId)),
            SCValXDR.address(try SCAddressXDR(contractId: receiverId)),
            try SCValXDR.i128(stringValue: "5"),
        ]
    }

    /// A transfer the mock simulates as a write.
    private func simulatedTransfer(_ client: SorobanClient, auth: [SorobanAuthorizationEntryXDR] = []) async throws -> AssembledTransaction {
        rpc.serveSimulations([.write(contractId: sacId, auth: auth)])
        return try await client.buildInvokeMethodTx(name: "transfer", args: try transferArgs())
    }

    private func restorePreamble() throws -> RestorePreamble {
        let json: [String: Any] = [
            "transactionData": try XCTUnwrap(SACMockRPC.transactionData(contractId: sacId, writes: true).xdrEncoded),
            "minResourceFee": "100",
        ]
        return try JSONDecoder().decode(RestorePreamble.self, from: try JSONSerialization.data(withJSONObject: json))
    }

    private func assertRefusal(_ error: Error?, source: KeyPair, file: StaticString = #filePath, line: UInt = #line) {
        guard case AssembledTransactionError.missingPrivateKey(let message)? = error else {
            XCTFail("expected AssembledTransactionError.missingPrivateKey, got \(String(describing: error))", file: file, line: line)
            return
        }
        XCTAssertEqual(message, "This transaction was built by a read-only client for source account \(source.accountId), which has no keypair to sign with; build it from a client opened with the submitting account's keypair", file: file, line: line)
    }

    private func assertNotYetSimulated(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) {
        guard case AssembledTransactionError.notYetSimulated(let message)? = error else {
            XCTFail("expected AssembledTransactionError.notYetSimulated, got \(String(describing: error))", file: file, line: line)
            return
        }
        XCTAssertEqual(message, "Transaction has not yet been simulated", file: file, line: line)
    }

    // MARK: - Building and simulating

    /// A read-only build and a second `simulate()` each send one simulation of the given
    /// source at sequence number 1, and no account request.
    func testReadOnlyBuildAndSecondSimulateSendOnlySimulations() async throws {
        try await forEachSource { source, client in
            self.rpc.serveSimulations([.read(contractId: self.sacId, returning: try SCValXDR.i128(stringValue: "42"))])

            let tx = try await client.buildInvokeMethodTx(name: "balance", args: try self.balanceArgs())

            XCTAssertTrue(tx.options.readOnly)
            XCTAssertEqual(self.rpc.requestNames, ["simulate"])
            XCTAssertEqual(try tx.getSimulationData().returnedValue.i128String, "42")

            try await tx.simulate()

            XCTAssertEqual(self.rpc.requestNames, ["simulate", "simulate"])
            for request in self.rpc.requests {
                try SACAssert.invocation(request, source: source.accountId, sequenceNumber: 1,
                                         contractId: self.sacId, function: "balance", args: try self.balanceArgs())
            }
        }
    }

    /// With `simulate: false` a read-only build sends no request; `sign()` and
    /// `signAndSend()` report the missing simulation, and `send()` the refusal.
    func testReadOnlyUnsimulatedPrecedence() async throws {
        try await forEachSource { source, client in
            let tx = try await client.buildInvokeMethodTx(name: "transfer", args: try self.transferArgs(),
                                                          methodOptions: MethodOptions(simulate: false))

            XCTAssertNil(tx.tx)
            self.assertNotYetSimulated(await SACAssert.error { try tx.sign() })
            self.assertNotYetSimulated(await SACAssert.error { _ = try await tx.signAndSend() })
            self.assertRefusal(await SACAssert.error { _ = try await tx.send() }, source: source)
            XCTAssertNil(tx.signed)
            XCTAssertEqual(self.rpc.requestNames, [])
        }
    }

    // MARK: - Refusals

    /// After a write simulation, signing in each form, `signAndSend()`, and
    /// `restoreFootprint(restorePreamble:)` throw the refusal and send nothing.
    func testReadOnlyWriteRefusals() async throws {
        try await forEachSource { source, client in
            let tx = try await self.simulatedTransfer(client)
            let otherKeyPair = try KeyPair.generateRandomKeyPair()
            let preamble = try self.restorePreamble()

            self.assertRefusal(await SACAssert.error { try tx.sign() }, source: source)
            self.assertRefusal(await SACAssert.error { try tx.sign(force: true) }, source: source)
            self.assertRefusal(await SACAssert.error { try tx.sign(sourceAccountKeyPair: otherKeyPair) }, source: source)
            self.assertRefusal(await SACAssert.error { _ = try await tx.signAndSend() }, source: source)
            self.assertRefusal(await SACAssert.error { _ = try await tx.restoreFootprint(restorePreamble: preamble) }, source: source)

            XCTAssertNil(tx.signed)
            XCTAssertEqual(self.rpc.requestNames, ["simulate"])
            try SACAssert.invocation(try self.rpc.request(0), source: source.accountId, sequenceNumber: 1,
                                     contractId: self.sacId, function: "transfer", args: try self.transferArgs())
        }
    }

    /// `send()` throws the refusal, not the not-signed error, while `signed` is nil.
    func testReadOnlySendWithoutSigned() async throws {
        try await forEachSource { source, client in
            let tx = try await self.simulatedTransfer(client)

            self.assertRefusal(await SACAssert.error { _ = try await tx.send() }, source: source)

            XCTAssertNil(tx.signed)
            XCTAssertEqual(self.rpc.requestNames, ["simulate"])
        }
    }

    /// With `signed` set by hand, `send()` and `signAndSend()` still throw the refusal and
    /// send nothing.
    func testReadOnlySignAndSendWithHandSetSigned() async throws {
        try await forEachSource { source, client in
            let tx = try await self.simulatedTransfer(client)
            let signed = try Transaction(envelopeXdr: try XCTUnwrap(tx.tx).encodedEnvelope())
            try signed.sign(keyPair: try KeyPair.generateRandomKeyPair(), network: Network.testnet)
            tx.signed = signed

            self.assertRefusal(await SACAssert.error { _ = try await tx.send() }, source: source)
            self.assertRefusal(await SACAssert.error { _ = try await tx.signAndSend() }, source: source)

            XCTAssertTrue(tx.signed === signed)
            XCTAssertEqual(self.rpc.requestNames, ["simulate"])
        }
    }

    /// After a read simulation, `sign()` keeps the read-call error, and forcing throws the refusal.
    func testReadOnlyForceRead() async throws {
        try await forEachSource { source, client in
            self.rpc.serveSimulations([.read(contractId: self.sacId, returning: try SCValXDR.i128(stringValue: "42"))])
            let tx = try await client.buildInvokeMethodTx(name: "balance", args: try self.balanceArgs())

            let readCallError = await SACAssert.error { try tx.sign() }
            guard case AssembledTransactionError.isReadCall(let message)? = readCallError else {
                XCTFail("expected AssembledTransactionError.isReadCall, got \(String(describing: readCallError))")
                return
            }
            XCTAssertEqual(message, "This is a read call. It requires no signature or sending. Use `force: true` to sign and send anyway.")
            self.assertRefusal(await SACAssert.error { try tx.sign(force: true) }, source: source)
            self.assertRefusal(await SACAssert.error { _ = try await tx.signAndSend(force: true) }, source: source)

            XCTAssertNil(tx.signed)
            XCTAssertEqual(self.rpc.requestNames, ["simulate"])
        }
    }

    /// A restore preamble with `restore: true` throws the refusal, also on the public-only
    /// source, where the private-key check would fire next, and sends no further request.
    func testReadOnlyRestoreThrowsTheRefusal() async throws {
        try await forEachSource { source, client in
            var simulation = SACMockRPC.Simulation.write(contractId: self.sacId)
            simulation.restorePreamble = (SACMockRPC.transactionData(contractId: self.sacId, writes: true), 100)
            self.rpc.serveSimulations([simulation])

            let error = await SACAssert.error {
                _ = try await client.buildInvokeMethodTx(name: "transfer", args: try self.transferArgs(),
                                                         methodOptions: MethodOptions(restore: true))
            }

            self.assertRefusal(error, source: source)
            XCTAssertEqual(self.rpc.requestNames, ["simulate"])
            try SACAssert.invocation(try self.rpc.request(0), source: source.accountId, sequenceNumber: 1,
                                     contractId: self.sacId, function: "transfer", args: try self.transferArgs())
        }
    }

    // MARK: - Authorization entries

    /// `signAuthEntries` with the keypair of an entry's account and an explicit expiration
    /// signs the entry and sends no request.
    func testReadOnlySignAuthEntriesSignsWithoutRequest() async throws {
        try await forEachSource { _, client in
            let authorizer = try KeyPair.generateRandomKeyPair()
            let entry = SACMockRPC.addressAuthEntry(address: try SCAddressXDR(accountId: authorizer.accountId),
                                                    contractId: self.sacId,
                                                    function: "transfer",
                                                    args: try self.transferArgs())
            let tx = try await self.simulatedTransfer(client, auth: [entry])
            XCTAssertEqual(try tx.needsNonInvokerSigningBy(), [authorizer.accountId])

            try await tx.signAuthEntries(signerKeyPair: authorizer, validUntilLedgerSeq: 5000)

            XCTAssertEqual(try tx.needsNonInvokerSigningBy(), [])
            let operation = try XCTUnwrap(tx.tx?.operations.first as? InvokeHostFunctionOperation)
            XCTAssertEqual(operation.auth.count, 1)
            let credentials = try XCTUnwrap(operation.auth.first?.credentials.addressCredentials)
            XCTAssertEqual(credentials.signatureExpirationLedger, 5000)
            XCTAssertTrue(SorobanAuthorizationEntryXDR.carriesSignature(credentials.signature))
            XCTAssertEqual(self.rpc.requestNames, ["simulate"])
        }
    }

    // MARK: - Without the flag

    /// The placeholder account as the source of a client that is not read-only is an account
    /// like any other: the build loads it first and uses its sequence number.
    func testUnflaggedZeroKeySourceLoadsTheAccount() async throws {
        let source = try KeyPair(accountId: SACClient.READ_ONLY_SOURCE_ACCOUNT_ID)
        rpc.serveAccount(of: source, sequenceNumbers: [12345])
        rpc.serveSimulations([.read(contractId: sacId, returning: SCValXDR.u32(7))])

        let tx = try await client(source: source, readOnly: false).buildInvokeMethodTx(name: "decimals")

        XCTAssertFalse(tx.options.readOnly)
        XCTAssertEqual(rpc.requestNames, ["account", "simulate"])
        try SACAssert.invocation(try rpc.request(1), source: source.accountId, sequenceNumber: 12346,
                                 contractId: sacId, function: "decimals", args: [])
    }

    func testFiveParameterInitGivesReadOnlyFalse() throws {
        let clientOptions = ClientOptions(sourceAccountKeyPair: try KeyPair.generateRandomKeyPair(),
                                          contractId: sacId,
                                          network: Network.testnet,
                                          rpcUrl: rpc.rpcUrl)

        let options = AssembledTransactionOptions(clientOptions: clientOptions,
                                                  methodOptions: MethodOptions(),
                                                  method: "balance",
                                                  arguments: try balanceArgs(),
                                                  enableServerLogging: false)

        XCTAssertFalse(options.readOnly)
        XCTAssertFalse(AssembledTransactionOptions(clientOptions: clientOptions, methodOptions: MethodOptions(), method: "balance").readOnly)
        XCTAssertTrue(AssembledTransactionOptions(clientOptions: clientOptions, methodOptions: MethodOptions(), method: "balance", readOnly: true).readOnly)
    }
}
