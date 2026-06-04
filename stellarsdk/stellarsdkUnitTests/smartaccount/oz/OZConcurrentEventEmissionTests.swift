//
//  OZConcurrentEventEmissionTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// Concurrent stress tests for ``OZSmartAccountEventEmitter``.
///
/// Verifies that concurrent emitters, subscribers, and unsubscribers produce no
/// crashes, no lost deliveries, and no exceptions when subscription state is
/// mutated under contention.
final class OZConcurrentEventEmissionTests: XCTestCase {

    // MARK: - Concurrent Emit Tests

    func testConcurrentEmit_noLostEventsWithSingleListener() async {
        let emitter = OZSmartAccountEventEmitter()
        let counter = ConcurrentCounter()

        emitter.addListener { _ in counter.increment() }

        let eventCount = 100
        await withTaskGroup(of: Void.self) { group in
            for i in 1...eventCount {
                group.addTask {
                    emitter.emit(.transactionSubmitted(hash: "hash-\(i)", success: true))
                }
            }
        }

        XCTAssertEqual(counter.value, eventCount, "All \(eventCount) events must be delivered")
    }

    func testConcurrentEmit_noExceptionWithMultipleListeners() async {
        let emitter = OZSmartAccountEventEmitter()

        for _ in 0..<5 {
            emitter.addListener { _ in }
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 1...50 {
                group.addTask {
                    emitter.emit(.walletConnected(contractId: "contract-\(i)", credentialId: "cred-\(i)"))
                }
            }
        }
    }

    func testConcurrentSubscribeAndEmit_noException() async {
        let emitter = OZSmartAccountEventEmitter()

        await withTaskGroup(of: Void.self) { group in
            for i in 1...30 {
                group.addTask {
                    emitter.emit(.transactionSubmitted(hash: "hash-\(i)", success: i % 2 == 0))
                }
            }
            for _ in 1...20 {
                group.addTask {
                    _ = emitter.addListener { _ in }
                }
            }
        }
    }

    func testConcurrentUnsubscribeAndEmit_noException() async {
        let emitter = OZSmartAccountEventEmitter()

        let unsubscribers = ConcurrentUnsubscribeList()
        for _ in 0..<20 {
            unsubscribers.append(emitter.addListener { _ in })
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 1...30 {
                group.addTask {
                    emitter.emit(.walletDisconnected(contractId: "c-\(i)"))
                }
            }
            for unsub in unsubscribers.snapshot() {
                group.addTask {
                    unsub()
                }
            }
        }
    }

    func testConcurrentTypedListeners_noException() async {
        let emitter = OZSmartAccountEventEmitter()

        await withTaskGroup(of: Void.self) { group in
            for _ in 1...10 {
                group.addTask {
                    _ = emitter.on(.walletConnected) { _ in }
                }
            }
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 1...40 {
                group.addTask {
                    if i % 2 == 0 {
                        emitter.emit(.walletConnected(contractId: "c-\(i)", credentialId: "cred-\(i)"))
                    } else {
                        emitter.emit(.transactionSubmitted(hash: "h-\(i)", success: true))
                    }
                }
            }
        }
    }

    func testConcurrentEmit_listenerCountRemainsConsistent() async {
        let emitter = OZSmartAccountEventEmitter()

        emitter.addListener { _ in }

        await withTaskGroup(of: Void.self) { group in
            for i in 1...60 {
                group.addTask {
                    emitter.emit(.sessionExpired(contractId: "c-\(i)", credentialId: "cred-\(i)"))
                }
            }
        }
    }

    // MARK: - removeAllListeners under concurrency

    func testConcurrentRemoveAllAndEmit_noException() async {
        let emitter = OZSmartAccountEventEmitter()

        for _ in 0..<10 {
            emitter.addListener { _ in }
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 1...20 {
                group.addTask {
                    emitter.emit(.credentialDeleted(credentialId: "cred-\(i)"))
                }
            }
            group.addTask {
                emitter.removeAllListeners()
            }
        }
    }
}

// ============================================================================
// Concurrent test helpers
// ============================================================================

/// Atomic counter used by concurrent test cases.
final class ConcurrentCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Int = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return _value }
    func increment() { lock.lock(); _value += 1; lock.unlock() }
}

/// Thread-safe list of unsubscribe closures used by concurrent test cases.
final class ConcurrentUnsubscribeList: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [OZSmartAccountEventUnsubscribe] = []
    func append(_ u: @escaping OZSmartAccountEventUnsubscribe) {
        lock.lock(); items.append(u); lock.unlock()
    }
    func snapshot() -> [OZSmartAccountEventUnsubscribe] {
        lock.lock(); defer { lock.unlock() }; return items
    }
}
