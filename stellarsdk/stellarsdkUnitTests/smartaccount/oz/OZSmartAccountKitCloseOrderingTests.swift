//
//  OZSmartAccountKitCloseOrderingTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Thread-safe ordered recorder for kit close-lifecycle tests.
final class CloseOrderTracker: @unchecked Sendable {
    enum Role: String, Sendable, Equatable, CustomStringConvertible {
        case sorobanServer
        case indexerClient
        case relayerClient
        var description: String { rawValue }
    }
    private let trackerLock = NSLock()
    private var _roles: [Role] = []
    func record(_ role: Role) {
        trackerLock.lock(); _roles.append(role); trackerLock.unlock()
    }
    var roles: [Role] {
        trackerLock.lock(); defer { trackerLock.unlock() }
        return _roles
    }
}

/// Recording `SorobanServer` subclass driving the close-order tracker.
final class RecordingSorobanServer: SorobanServer, @unchecked Sendable {
    private let counterLock = NSLock()
    private var _closeCallCount: Int = 0
    let orderTracker: CloseOrderTracker?
    var closeCallCount: Int {
        counterLock.lock(); defer { counterLock.unlock() }
        return _closeCallCount
    }
    init(endpoint: String = "https://mock-rpc.invalid/rpc", orderTracker: CloseOrderTracker? = nil) {
        self.orderTracker = orderTracker
        super.init(endpoint: endpoint)
    }
    override func close() {
        counterLock.lock(); _closeCallCount += 1; counterLock.unlock()
        orderTracker?.record(.sorobanServer)
        super.close()
    }
}

/// Recording `OZIndexerClient` subclass driving the close-order tracker.
final class RecordingOZIndexerClient: OZIndexerClient, @unchecked Sendable {
    private let counterLock = NSLock()
    private var _closeCallCount: Int = 0
    let orderTracker: CloseOrderTracker?
    var closeCallCount: Int {
        counterLock.lock(); defer { counterLock.unlock() }
        return _closeCallCount
    }
    init(orderTracker: CloseOrderTracker? = nil) throws {
        self.orderTracker = orderTracker
        try super.init(
            indexerUrl: "https://mock-indexer.example.test",
            timeoutMs: OZConstants.defaultIndexerTimeoutMs
        )
    }
    override func close() {
        counterLock.lock(); _closeCallCount += 1; counterLock.unlock()
        orderTracker?.record(.indexerClient)
        super.close()
    }
}

/// Recording `OZRelayerClient` subclass driving the close-order tracker.
final class RecordingOZRelayerClient: OZRelayerClient, @unchecked Sendable {
    private let counterLock = NSLock()
    private var _closeCallCount: Int = 0
    let orderTracker: CloseOrderTracker?
    var closeCallCount: Int {
        counterLock.lock(); defer { counterLock.unlock() }
        return _closeCallCount
    }
    init(orderTracker: CloseOrderTracker? = nil) throws {
        self.orderTracker = orderTracker
        try super.init(
            relayerUrl: "https://mock-relayer.example.test",
            timeoutMs: OZConstants.defaultRelayerTimeoutMs
        )
    }
    override func close() {
        counterLock.lock(); _closeCallCount += 1; counterLock.unlock()
        orderTracker?.record(.relayerClient)
        super.close()
    }
}

/// Close-order parity tests for ``OZSmartAccountKit`` lifecycle teardown.
///
/// The kit's documented teardown order is
/// `[sorobanServer, indexerClient, relayerClient]`, matching the
/// cross-SDK contract honored by the Flutter and KMP SDKs.
final class OZSmartAccountKitCloseOrderingTests: XCTestCase {

    private let validRpcUrl = "http://127.0.0.1:1"
    private let validPassphrase = Network.testnet.passphrase
    private let validWasmHash = "a" + String(repeating: "0", count: 63)
    private let validVerifier = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM"

    private func makeConfig(
        relayerUrl: String? = nil,
        indexerUrl: String? = nil
    ) throws -> OZSmartAccountConfig {
        return try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: validPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            relayerUrl: relayerUrl,
            indexerUrl: indexerUrl,
            storage: InMemoryStorageAdapter()
        )
    }

    func testClose_ordering_sorobanServerClosedBeforeOtherClients() async throws {
        let tracker = CloseOrderTracker()
        let config = try makeConfig(
            relayerUrl: "https://relayer.example.test",
            indexerUrl: "https://indexer.example.test"
        )
        let recordingServer = RecordingSorobanServer(
            endpoint: config.rpcUrl, orderTracker: tracker
        )
        let recordingIndexer = try RecordingOZIndexerClient(orderTracker: tracker)
        let recordingRelayer = try RecordingOZRelayerClient(orderTracker: tracker)
        let kit = OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: recordingServer,
            relayerClient: recordingRelayer,
            indexerClient: recordingIndexer
        )
        await kit.close()
        XCTAssertEqual(
            tracker.roles,
            [.sorobanServer, .indexerClient, .relayerClient]
        )
        XCTAssertEqual(recordingServer.closeCallCount, 1)
        XCTAssertEqual(recordingIndexer.closeCallCount, 1)
        XCTAssertEqual(recordingRelayer.closeCallCount, 1)
    }

    func testClose_ordering_withoutIndexerOrRelayer_stillClosesSorobanServer() async throws {
        let tracker = CloseOrderTracker()
        let customPassphrase = "Custom Network ; OZ Smart Account Tests"
        let config = try OZSmartAccountConfig(
            rpcUrl: validRpcUrl,
            networkPassphrase: customPassphrase,
            accountWasmHash: validWasmHash,
            webauthnVerifierAddress: validVerifier,
            storage: InMemoryStorageAdapter()
        )
        let recordingServer = RecordingSorobanServer(
            endpoint: config.rpcUrl, orderTracker: tracker
        )
        let kit = OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: recordingServer,
            relayerClient: nil,
            indexerClient: nil
        )
        await kit.close()
        XCTAssertEqual(tracker.roles, [.sorobanServer])
        XCTAssertEqual(recordingServer.closeCallCount, 1)
    }

    func testClose_kitIdempotency_doubleCloseClosesSorobanServerOnce() async throws {
        let tracker = CloseOrderTracker()
        let config = try makeConfig(
            relayerUrl: "https://relayer.example.test",
            indexerUrl: "https://indexer.example.test"
        )
        let recordingServer = RecordingSorobanServer(
            endpoint: config.rpcUrl, orderTracker: tracker
        )
        let recordingIndexer = try RecordingOZIndexerClient(orderTracker: tracker)
        let recordingRelayer = try RecordingOZRelayerClient(orderTracker: tracker)
        let kit = OZSmartAccountKit(
            config: config,
            storage: config.storage,
            sorobanServer: recordingServer,
            relayerClient: recordingRelayer,
            indexerClient: recordingIndexer
        )
        await kit.close()
        await kit.close()
        await kit.close()
        XCTAssertEqual(tracker.roles, [.sorobanServer, .indexerClient, .relayerClient])
        XCTAssertEqual(recordingServer.closeCallCount, 1)
        XCTAssertEqual(recordingIndexer.closeCallCount, 1)
        XCTAssertEqual(recordingRelayer.closeCallCount, 1)
    }

    func testClose_sorobanServerStandalone_isIdempotent() {
        let server = RecordingSorobanServer(endpoint: "http://127.0.0.1:1")
        server.close()
        server.close()
        server.close()
        XCTAssertEqual(server.closeCallCount, 3)
    }
}
