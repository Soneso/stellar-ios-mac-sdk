//
//  OZIndexerIntegrationTests.swift
//  stellarsdkIntegrationTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Live tests against the default testnet indexer (Mercury). They verify the endpoint is up
/// and speaks the wire format the SDK expects: the health probe, the stats route, and the
/// lookup routes with their response DTO shapes.
///
/// Lookups use freshly generated identifiers (a random credential ID, a random keypair's
/// G-address, a C-address derived from a random keypair), which are valid by construction and
/// cannot collide with indexed data, so the expected results are deterministic: well-formed
/// empty responses for the lookup routes and the typed failure for an unknown contract.
final class OZIndexerIntegrationTests: XCTestCase {

    // MARK: - Tests

    func testDefaultIndexerIsHealthy() async throws {
        let client = try makeClient()
        defer { client.close() }
        let healthy = await client.isHealthy()
        XCTAssertTrue(healthy, "the default testnet indexer must report healthy")
    }

    func testStatsReturnsLiveData() async throws {
        let client = try makeClient()
        defer { client.close() }
        let stats = try await client.getStats().stats
        XCTAssertGreaterThan(
            stats.totalEvents, 0,
            "the indexer must have processed events, got: \(stats.totalEvents)"
        )
        XCTAssertGreaterThan(
            stats.uniqueContracts, 0,
            "the indexer must have indexed contracts, got: \(stats.uniqueContracts)"
        )
    }

    func testLookupByUnknownCredentialIdReturnsWellFormedEmptyResult() async throws {
        let client = try makeClient()
        defer { client.close() }
        // The client takes a base64url credential ID and queries the API by its hex form,
        // which the response echoes.
        let credentialBytes = randomBytes(count: 16)
        let response = try await client.lookupByCredentialId(
            credentialId: credentialBytes.base64URLEncodedString()
        )
        XCTAssertEqual(
            credentialBytes.base16EncodedString(), response.credentialId,
            "response must echo the queried credential ID as hex"
        )
        XCTAssertEqual(0, response.count)
        XCTAssertTrue(response.contracts.isEmpty)
    }

    func testLookupByUnknownAddressReturnsWellFormedEmptyResult() async throws {
        let client = try makeClient()
        defer { client.close() }
        let address = try KeyPair.generateRandomKeyPair().accountId
        let response = try await client.lookupByAddress(address: address)
        XCTAssertEqual(
            address, response.signerAddress,
            "response must echo the queried address"
        )
        XCTAssertEqual(0, response.count)
        XCTAssertTrue(response.contracts.isEmpty)
    }

    func testGetContractUnknownContractThrowsTyped() async throws {
        let client = try makeClient()
        defer { client.close() }
        // A fresh keypair's raw 32-byte public key encodes to a contract strkey that is
        // valid by construction and cannot collide with an indexed contract.
        let contractId = try Data(KeyPair.generateRandomKeyPair().publicKey.bytes).encodeContractId()
        var thrown: Error?
        do {
            _ = try await client.getContract(contractId: contractId)
        } catch {
            thrown = error
        }
        let exception = try XCTUnwrap(
            thrown as? SmartAccountIndexerException.RequestFailed,
            "an unindexed contract must surface the typed indexer failure, got: \(String(describing: thrown))"
        )
        XCTAssertTrue(
            exception.message.contains("404"),
            "the failure must be the service not-found, not a transport error, got: \(exception.message)"
        )
    }

    // MARK: - Helpers

    private func makeClient() throws -> OZIndexerClient {
        let client = OZIndexerClient.forNetwork(networkPassphrase: Network.testnet.passphrase)
        return try XCTUnwrap(client, "testnet must have a default indexer")
    }

    /// Cryptographically random bytes for lookup identifiers.
    private func randomBytes(count: Int) -> Data {
        var data = Data(count: count)
        for i in 0..<count {
            data[i] = UInt8.random(in: .min ... .max)
        }
        return data
    }

}
