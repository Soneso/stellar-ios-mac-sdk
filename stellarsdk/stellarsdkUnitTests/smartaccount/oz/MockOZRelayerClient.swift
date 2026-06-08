//
//  MockOZRelayerClient.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
@testable import stellarsdk

/// Recording test double for ``OZRelayerClient`` used by kit lifecycle
/// tests.
///
/// Subclasses the real client so the kit's `internal init(...)` accepts the
/// mock wherever it expects an ``OZRelayerClient?`` property. Overrides
/// ``close()`` to increment a thread-safe counter that the close-releases
/// resources test asserts against. The mock does not intercept any HTTP
/// submission methods — the kit close-flow tests never call into them.
final class MockOZRelayerClient: OZRelayerClient, @unchecked Sendable {

    /// Synchronization for ``closeCallCount`` so the counter is safe to read
    /// from arbitrary threads.
    private let counterLock = NSLock()

    /// Backing store for ``closeCallCount``.
    private var _closeCallCount: Int = 0

    /// Number of times ``close()`` has been invoked on this instance.
    ///
    /// Thread-safe.
    var closeCallCount: Int {
        counterLock.lock()
        defer { counterLock.unlock() }
        return _closeCallCount
    }

    /// Creates a recording mock with a fake-but-valid relayer URL.
    ///
    /// The constructor passes a syntactically valid `https://` URL through
    /// to the real client so its URL-validation step succeeds. The mock
    /// never reaches the network because every test exercising close-call
    /// recording avoids triggering an HTTP submission.
    convenience init() throws {
        try self.init(
            relayerUrl: "https://mock-relayer.example.test",
            timeoutMs: OZConstants.defaultRelayerTimeoutMs
        )
    }

    /// Increments ``closeCallCount`` then forwards to the real client so
    /// the owned `URLSession` is invalidated as a real consumer would
    /// experience.
    override func close() {
        counterLock.lock()
        _closeCallCount += 1
        counterLock.unlock()
        super.close()
    }
}
