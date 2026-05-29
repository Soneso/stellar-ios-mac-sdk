//
//  OZSmartAccountEventsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class OZSmartAccountEventsTests: XCTestCase {

    // MARK: - Test fixtures

    private func makeStoredCredential(id: String = "cr", nickname: String? = nil) -> StoredCredential {
        var publicKey = Data(count: 65)
        publicKey[0] = 0x04
        for i in 1..<65 {
            publicKey[i] = UInt8(i & 0xff)
        }
        return StoredCredential(
            credentialId: id,
            publicKey: publicKey,
            createdAt: 1_700_000_000_000,
            nickname: nickname
        )
    }

    // MARK: - addListener (Global Listener) Tests

    func testAddListener_receivesAllEventTypes() {
        let emitter = SmartAccountEventEmitter()
        let recorder = EventRecorder()

        emitter.addListener { event in
            recorder.append(event)
        }

        emitter.emit(.walletConnected(
            contractId: "CABC1234" + String(repeating: "A", count: 48),
            credentialId: "cred-1"
        ))
        emitter.emit(.transactionSubmitted(hash: "tx-hash-123", success: true))
        emitter.emit(.walletDisconnected(
            contractId: "CABC1234" + String(repeating: "A", count: 48)
        ))

        let received = recorder.snapshot()
        XCTAssertEqual(received.count, 3)
        if case .walletConnected = received[0] {} else { XCTFail("expected walletConnected") }
        if case .transactionSubmitted = received[1] {} else { XCTFail("expected transactionSubmitted") }
        if case .walletDisconnected = received[2] {} else { XCTFail("expected walletDisconnected") }
    }

    func testAddListener_unsubscribeStopsReceiving() {
        let emitter = SmartAccountEventEmitter()
        let counter = Counter()

        let unsubscribe = emitter.addListener { _ in counter.increment() }

        emitter.emit(.walletDisconnected(contractId: "C1234"))
        XCTAssertEqual(counter.value, 1)

        unsubscribe()

        emitter.emit(.walletDisconnected(contractId: "C5678"))
        XCTAssertEqual(counter.value, 1, "Should not receive events after unsubscribe")
    }

    func testAddListener_multipleGlobalListenersAllReceive() {
        let emitter = SmartAccountEventEmitter()
        let c1 = Counter()
        let c2 = Counter()
        let c3 = Counter()

        emitter.addListener { _ in c1.increment() }
        emitter.addListener { _ in c2.increment() }
        emitter.addListener { _ in c3.increment() }

        emitter.emit(.walletConnected(contractId: "CONTRACT", credentialId: "cred"))

        XCTAssertEqual(c1.value, 1)
        XCTAssertEqual(c2.value, 1)
        XCTAssertEqual(c3.value, 1)
    }

    // MARK: - Error Handler Tests

    func testErrorHandler_failingListenerDoesNotAffectOthers() {
        let emitter = SmartAccountEventEmitter()
        let listener1Called = AtomicBool()
        let listener3Called = AtomicBool()

        emitter.addListener { _ in listener1Called.set(true) }
        emitter.addListener { _ in throw TestEventError(message: "Intentional failure") }
        emitter.addListener { _ in listener3Called.set(true) }
        emitter.setErrorHandler { _, _ in }

        emitter.emit(.walletDisconnected(contractId: "CONTRACT"))

        XCTAssertTrue(listener1Called.get(), "First listener should have been called")
        XCTAssertTrue(listener3Called.get(), "Third listener should still be called despite second failing")
    }

    func testSetErrorHandler_capturesEventAndError() {
        let emitter = SmartAccountEventEmitter()
        let captured = ErrorCapture()

        emitter.setErrorHandler { event, error in
            captured.set(event: event, error: error)
        }

        let errorMessage = "Test error from listener"
        emitter.addListener { _ in
            throw TestEventError(message: errorMessage)
        }

        let event: SmartAccountEvent = .transactionSubmitted(hash: "abc123", success: false)
        emitter.emit(event)

        guard let capturedEvent = captured.event, let capturedError = captured.error else {
            return XCTFail("error handler did not record event/error")
        }
        XCTAssertEqual(capturedEvent, event)
        XCTAssertEqual((capturedError as? TestEventError)?.message, errorMessage)
    }

    func testSetErrorHandler_nullDisablesHandler() {
        let emitter = SmartAccountEventEmitter()
        let handlerCalled = AtomicBool()

        emitter.setErrorHandler { _, _ in handlerCalled.set(true) }
        emitter.setErrorHandler(nil)

        emitter.addListener { _ in throw TestEventError(message: "Boom") }

        emitter.emit(.walletDisconnected(contractId: "C"))
        XCTAssertFalse(handlerCalled.get())
    }

    // MARK: - listenerCount Tests

    func testListenerCount_noListenersReturnsZero() {
        let emitter = SmartAccountEventEmitter()
        XCTAssertEqual(emitter.listenerCount(eventType: "WalletConnected"), 0)
    }

    func testListenerCount_countsTypeSpecificListeners() {
        let emitter = SmartAccountEventEmitter()
        emitter.on(.walletConnected) { _ in }
        emitter.on(.walletConnected) { _ in }
        emitter.on(.transactionSubmitted) { _ in }

        XCTAssertEqual(emitter.listenerCount(eventType: "WalletConnected"), 2)
        XCTAssertEqual(emitter.listenerCount(eventType: "TransactionSubmitted"), 1)
    }

    func testListenerCount_includesGlobalListeners() {
        let emitter = SmartAccountEventEmitter()
        emitter.on(.walletConnected) { _ in }
        emitter.addListener { _ in }

        XCTAssertEqual(emitter.listenerCount(eventType: "WalletConnected"), 2)
        XCTAssertEqual(emitter.listenerCount(eventType: "TransactionSubmitted"), 1)
    }

    // MARK: - Emit Isolation Tests

    func testEmitIsolation_typeSpecificOnlyReceivesMatchingEvents() {
        let emitter = SmartAccountEventEmitter()
        let walletConnectedCount = Counter()
        let txSubmittedCount = Counter()

        emitter.on(.walletConnected) { _ in walletConnectedCount.increment() }
        emitter.on(.transactionSubmitted) { _ in txSubmittedCount.increment() }

        emitter.emit(.walletConnected(contractId: "CONTRACT", credentialId: "cred"))

        XCTAssertEqual(walletConnectedCount.value, 1)
        XCTAssertEqual(txSubmittedCount.value, 0,
            "TransactionSubmitted listener should not receive WalletConnected events")
    }

    func testEmitIsolation_globalAndTypedMixed() {
        let emitter = SmartAccountEventEmitter()
        let globalCount = Counter()
        let typedCount = Counter()

        emitter.addListener { _ in globalCount.increment() }
        emitter.on(.credentialCreated) { _ in typedCount.increment() }

        emitter.emit(.walletDisconnected(contractId: "C"))
        XCTAssertEqual(globalCount.value, 1, "Global listener should receive all events")
        XCTAssertEqual(typedCount.value, 0, "Typed listener should not receive unmatched events")

        let credential = makeStoredCredential(id: "cred-1")
        emitter.emit(.credentialCreated(credential: credential))

        XCTAssertEqual(globalCount.value, 2)
        XCTAssertEqual(typedCount.value, 1)
    }

    // MARK: - removeAllListeners for Specific Event Type

    func testRemoveAllListeners_specificTypeOnly() {
        let emitter = SmartAccountEventEmitter()
        let walletCount = Counter()
        let txCount = Counter()

        emitter.on(.walletConnected) { _ in walletCount.increment() }
        emitter.on(.transactionSubmitted) { _ in txCount.increment() }

        emitter.removeAllListeners(eventType: "WalletConnected")

        emitter.emit(.walletConnected(contractId: "C", credentialId: "c"))
        emitter.emit(.transactionSubmitted(hash: "h", success: true))

        XCTAssertEqual(walletCount.value, 0, "WalletConnected listener should have been removed")
        XCTAssertEqual(txCount.value, 1, "TransactionSubmitted listener should still work")
    }

    func testRemoveAllListeners_allTypesAndGlobal() {
        let emitter = SmartAccountEventEmitter()
        let count = Counter()

        emitter.on(.walletConnected) { _ in count.increment() }
        emitter.on(.transactionSubmitted) { _ in count.increment() }
        emitter.addListener { _ in count.increment() }

        emitter.removeAllListeners()

        emitter.emit(.walletConnected(contractId: "C", credentialId: "c"))
        emitter.emit(.transactionSubmitted(hash: "h", success: true))

        XCTAssertEqual(count.value, 0, "No listeners should remain after removeAllListeners()")
    }

    // MARK: - on() Unsubscribe Tests

    func testOnUnsubscribe_stopsReceivingTypedEvents() {
        let emitter = SmartAccountEventEmitter()
        let count = Counter()

        let unsubscribe = emitter.on(.sessionExpired) { _ in count.increment() }

        emitter.emit(.sessionExpired(contractId: "C", credentialId: "c"))
        XCTAssertEqual(count.value, 1)

        unsubscribe()

        emitter.emit(.sessionExpired(contractId: "C2", credentialId: "c2"))
        XCTAssertEqual(count.value, 1, "Should not receive after unsubscribe")
    }

    // MARK: - SmartAccountEvent Data Class Tests

    func testWalletConnectedEvent() {
        let event = SmartAccountEvent.walletConnected(contractId: "CABC", credentialId: "cred-id")
        if case let .walletConnected(contractId, credentialId) = event {
            XCTAssertEqual(contractId, "CABC")
            XCTAssertEqual(credentialId, "cred-id")
        } else {
            XCTFail("expected walletConnected arm")
        }
    }

    func testWalletDisconnectedEvent() {
        let event = SmartAccountEvent.walletDisconnected(contractId: "CXYZ")
        if case let .walletDisconnected(contractId) = event {
            XCTAssertEqual(contractId, "CXYZ")
        } else {
            XCTFail("expected walletDisconnected arm")
        }
    }

    func testCredentialDeletedEvent() {
        let event = SmartAccountEvent.credentialDeleted(credentialId: "del-cred")
        if case let .credentialDeleted(credentialId) = event {
            XCTAssertEqual(credentialId, "del-cred")
        } else {
            XCTFail("expected credentialDeleted arm")
        }
    }

    func testSessionExpiredEvent() {
        let event = SmartAccountEvent.sessionExpired(contractId: "CSESS", credentialId: "cred-sess")
        if case let .sessionExpired(contractId, credentialId) = event {
            XCTAssertEqual(contractId, "CSESS")
            XCTAssertEqual(credentialId, "cred-sess")
        } else {
            XCTFail("expected sessionExpired arm")
        }
    }

    func testTransactionSignedEvent() {
        let event = SmartAccountEvent.transactionSigned(contractId: "CTX", credentialId: "cred-tx")
        if case let .transactionSigned(contractId, credentialId) = event {
            XCTAssertEqual(contractId, "CTX")
            XCTAssertEqual(credentialId, "cred-tx")
        } else {
            XCTFail("expected transactionSigned arm")
        }

        let eventWithNull = SmartAccountEvent.transactionSigned(contractId: "CTX", credentialId: nil)
        if case let .transactionSigned(_, credentialId) = eventWithNull {
            XCTAssertNil(credentialId)
        } else {
            XCTFail("expected transactionSigned arm")
        }
    }

    func testTransactionSubmittedEvent() {
        let successEvent = SmartAccountEvent.transactionSubmitted(hash: "tx-hash", success: true)
        if case let .transactionSubmitted(hash, success) = successEvent {
            XCTAssertEqual(hash, "tx-hash")
            XCTAssertTrue(success)
        } else {
            XCTFail("expected transactionSubmitted arm")
        }

        let failEvent = SmartAccountEvent.transactionSubmitted(hash: "fail-hash", success: false)
        if case let .transactionSubmitted(_, success) = failEvent {
            XCTAssertFalse(success)
        } else {
            XCTFail("expected transactionSubmitted arm")
        }
    }

    func testCredentialCreatedEvent() {
        let credential = makeStoredCredential(id: "new-cred", nickname: "Test Key")
        let event = SmartAccountEvent.credentialCreated(credential: credential)
        if case let .credentialCreated(captured) = event {
            XCTAssertEqual(captured.credentialId, "new-cred")
            XCTAssertEqual(captured.nickname, "Test Key")
        } else {
            XCTFail("expected credentialCreated arm")
        }
    }

    // MARK: - once() Tests

    func testOnce_firesOnFirstEventOnly() {
        let emitter = SmartAccountEventEmitter()
        let receivedHashes = StringList()

        emitter.once(.walletConnected) { event in
            if case let .walletConnected(contractId, _) = event {
                receivedHashes.append(contractId)
            }
        }

        emitter.emit(.walletConnected(contractId: "C1", credentialId: "cr1"))
        emitter.emit(.walletConnected(contractId: "C2", credentialId: "cr2"))

        let snapshot = receivedHashes.snapshot()
        XCTAssertEqual(snapshot.count, 1, "once listener should fire exactly once")
        XCTAssertEqual(snapshot.first, "C1", "once listener should receive the first event")
    }

    func testOnce_unsubscribeBeforeEventFiresCancels() {
        let emitter = SmartAccountEventEmitter()
        let callCount = Counter()

        let unsubscribe = emitter.once(.walletDisconnected) { _ in callCount.increment() }

        unsubscribe()

        emitter.emit(.walletDisconnected(contractId: "C"))
        XCTAssertEqual(callCount.value, 0, "once listener cancelled before firing should never fire")
    }

    func testOnce_listenerCountDecrementsAfterFiring() {
        let emitter = SmartAccountEventEmitter()

        emitter.once(.transactionSubmitted) { _ in }

        XCTAssertEqual(emitter.listenerCount(eventType: "TransactionSubmitted"), 1)

        emitter.emit(.transactionSubmitted(hash: "h", success: true))

        XCTAssertEqual(
            emitter.listenerCount(eventType: "TransactionSubmitted"),
            0,
            "Listener count should decrement after once listener auto-unsubscribes"
        )
    }

    func testOnce_multipleOnceListenersForSameType() {
        let emitter = SmartAccountEventEmitter()
        let c1 = Counter()
        let c2 = Counter()

        emitter.once(.sessionExpired) { _ in c1.increment() }
        emitter.once(.sessionExpired) { _ in c2.increment() }

        XCTAssertEqual(emitter.listenerCount(eventType: "SessionExpired"), 2)

        emitter.emit(.sessionExpired(contractId: "C", credentialId: "cr"))

        XCTAssertEqual(c1.value, 1, "First once listener should fire once")
        XCTAssertEqual(c2.value, 1, "Second once listener should fire once")

        emitter.emit(.sessionExpired(contractId: "C2", credentialId: "cr2"))

        XCTAssertEqual(c1.value, 1, "First once listener should not fire again")
        XCTAssertEqual(c2.value, 1, "Second once listener should not fire again")
        XCTAssertEqual(
            emitter.listenerCount(eventType: "SessionExpired"),
            0,
            "All once listeners should be removed after firing"
        )
    }

    func testOnce_doesNotAffectOtherEventTypes() {
        let emitter = SmartAccountEventEmitter()
        let onceCount = Counter()
        let permanentCount = Counter()

        emitter.once(.walletConnected) { _ in onceCount.increment() }
        emitter.on(.walletDisconnected) { _ in permanentCount.increment() }

        emitter.emit(.walletConnected(contractId: "C", credentialId: "cr"))
        emitter.emit(.walletDisconnected(contractId: "C"))
        emitter.emit(.walletDisconnected(contractId: "C2"))

        XCTAssertEqual(onceCount.value, 1)
        XCTAssertEqual(permanentCount.value, 2,
            "Permanent listener should still receive all events")
    }

    // MARK: - Error Handler with once Tests

    func testOnce_listenerThrowsOnFirstEvent_errorHandlerCalled() {
        let emitter = SmartAccountEventEmitter()
        let errorHandlerCalled = AtomicBool()
        let captured = ErrorCapture()

        emitter.setErrorHandler { event, error in
            errorHandlerCalled.set(true)
            captured.set(event: event, error: error)
        }

        emitter.once(.transactionSubmitted) { _ in
            throw TestEventError(message: "Listener failure on first event")
        }

        emitter.emit(.transactionSubmitted(hash: "h1", success: true))

        XCTAssertTrue(errorHandlerCalled.get(),
            "Error handler should be called when once listener throws")
        XCTAssertEqual((captured.error as? TestEventError)?.message, "Listener failure on first event")
    }

    func testOnce_listenerThrowsOnFirstEvent_stillAutoUnsubscribes() {
        let emitter = SmartAccountEventEmitter()
        let callCount = Counter()

        emitter.setErrorHandler { _, _ in }

        emitter.once(.walletDisconnected) { _ in
            callCount.increment()
            throw TestEventError(message: "Boom")
        }

        emitter.emit(.walletDisconnected(contractId: "C1"))
        emitter.emit(.walletDisconnected(contractId: "C2"))

        XCTAssertEqual(callCount.value, 1,
            "once listener should fire exactly once even when it throws")
        XCTAssertEqual(
            emitter.listenerCount(eventType: "WalletDisconnected"),
            0,
            "once listener should be removed even when it throws"
        )
    }

    func testErrorHandler_failingTypedListenerDoesNotAffectGlobalListener() {
        let emitter = SmartAccountEventEmitter()
        let globalCalled = AtomicBool()

        emitter.setErrorHandler { _, _ in }

        emitter.on(.walletConnected) { _ in
            throw TestEventError(message: "Typed listener failure")
        }
        emitter.addListener { _ in globalCalled.set(true) }

        emitter.emit(.walletConnected(contractId: "C", credentialId: "cr"))

        XCTAssertTrue(globalCalled.get(),
            "Global listener should still be called when typed listener throws")
    }

    // MARK: - removeAllListeners(eventType) Does Not Remove Global Listeners

    func testRemoveAllListeners_specificType_doesNotRemoveGlobalListeners() {
        let emitter = SmartAccountEventEmitter()
        let globalCount = Counter()
        let typedCount = Counter()

        emitter.addListener { _ in globalCount.increment() }
        emitter.on(.walletConnected) { _ in typedCount.increment() }

        emitter.removeAllListeners(eventType: "WalletConnected")

        emitter.emit(.walletConnected(contractId: "C", credentialId: "cr"))

        XCTAssertEqual(typedCount.value, 0, "Typed listener should have been removed")
        XCTAssertEqual(globalCount.value, 1,
            "Global listener should NOT be removed by removeAllListeners(eventType)")
    }

    func testRemoveAllListeners_specificType_globalListenerCountUnchanged() {
        let emitter = SmartAccountEventEmitter()

        emitter.addListener { _ in }
        emitter.on(.walletConnected) { _ in }

        XCTAssertEqual(emitter.listenerCount(eventType: "WalletConnected"), 2)

        emitter.removeAllListeners(eventType: "WalletConnected")

        XCTAssertEqual(emitter.listenerCount(eventType: "WalletConnected"), 1,
            "Global listener should still be counted after removeAllListeners(eventType)")
    }

    // MARK: - Edge Cases

    func testEmit_withNoListeners_doesNotThrow() {
        let emitter = SmartAccountEventEmitter()

        emitter.emit(.walletConnected(contractId: "C", credentialId: "cr"))
        emitter.emit(.transactionSubmitted(hash: "h", success: true))
        emitter.emit(.credentialDeleted(credentialId: "cr"))
        emitter.emit(.sessionExpired(contractId: "C", credentialId: "cr"))
        emitter.emit(.transactionSigned(contractId: "C", credentialId: nil))
        emitter.emit(.walletDisconnected(contractId: "C"))
        emitter.emit(.credentialCreated(credential: makeStoredCredential()))

        XCTAssertTrue(true)
    }

    func testRemoveAllListeners_whenAlreadyEmpty_doesNotThrow() {
        let emitter = SmartAccountEventEmitter()

        emitter.removeAllListeners()
        emitter.removeAllListeners(eventType: "WalletConnected")
        emitter.removeAllListeners(eventType: "NonExistentType")

        XCTAssertTrue(true)
    }

    func testUnsubscribe_calledMultipleTimes_doesNotThrow() {
        let emitter = SmartAccountEventEmitter()

        let unsubscribe = emitter.on(.walletConnected) { _ in }

        unsubscribe()
        unsubscribe()

        XCTAssertEqual(emitter.listenerCount(eventType: "WalletConnected"), 0)
    }

    func testAddListenerUnsubscribe_calledMultipleTimes_doesNotThrow() {
        let emitter = SmartAccountEventEmitter()

        let unsubscribe = emitter.addListener { _ in }

        unsubscribe()
        unsubscribe()

        XCTAssertEqual(emitter.listenerCount(eventType: "AnyType"), 0)
    }

    // MARK: - Rapid/Sequential Emission Tests

    func testRapidEmission_allEventsDeliveredInOrder() {
        let emitter = SmartAccountEventEmitter()
        let receivedHashes = StringList()

        emitter.on(.transactionSubmitted) { event in
            if case let .transactionSubmitted(hash, _) = event {
                receivedHashes.append(hash)
            }
        }

        let count = 100
        for i in 0..<count {
            emitter.emit(.transactionSubmitted(hash: "tx-\(i)", success: true))
        }

        let snapshot = receivedHashes.snapshot()
        XCTAssertEqual(snapshot.count, count, "All \(count) events should be delivered")
        for i in 0..<count {
            XCTAssertEqual(snapshot[i], "tx-\(i)", "Events should arrive in emission order")
        }
    }

    func testRapidEmission_mixedEventTypes() {
        let emitter = SmartAccountEventEmitter()
        let allEvents = EventRecorder()

        emitter.addListener { event in allEvents.append(event) }

        for i in 0..<50 {
            emitter.emit(.walletConnected(contractId: "C\(i)", credentialId: "cr\(i)"))
            emitter.emit(.transactionSubmitted(hash: "tx-\(i)", success: i % 2 == 0))
        }

        let snapshot = allEvents.snapshot()
        XCTAssertEqual(snapshot.count, 100, "All 100 mixed events should be delivered")
        for i in 0..<50 {
            if case .walletConnected = snapshot[i * 2] {} else {
                XCTFail("expected walletConnected at \(i*2)")
            }
            if case .transactionSubmitted = snapshot[i * 2 + 1] {} else {
                XCTFail("expected transactionSubmitted at \(i*2+1)")
            }
        }
    }

    // MARK: - Data Class Equality Tests

    func testWalletConnected_equalityAndCopy() {
        let event1 = SmartAccountEvent.walletConnected(contractId: "C1", credentialId: "cr1")
        let event2 = SmartAccountEvent.walletConnected(contractId: "C1", credentialId: "cr1")
        let event3 = SmartAccountEvent.walletConnected(contractId: "C2", credentialId: "cr1")

        XCTAssertEqual(event1, event2, "Same properties should be equal")
        XCTAssertEqual(event1.hashValue, event2.hashValue, "Equal objects should have equal hashCode")
        XCTAssertNotEqual(event1, event3, "Different contractId should not be equal")

        let copied = SmartAccountEvent.walletConnected(contractId: "C1", credentialId: "cr-new")
        if case let .walletConnected(contractId, credentialId) = copied {
            XCTAssertEqual(contractId, "C1", "Copy should preserve unchanged fields")
            XCTAssertEqual(credentialId, "cr-new", "Copy should update specified field")
        } else {
            XCTFail("expected walletConnected arm")
        }
    }

    func testWalletDisconnected_equalityAndCopy() {
        let event1 = SmartAccountEvent.walletDisconnected(contractId: "C1")
        let event2 = SmartAccountEvent.walletDisconnected(contractId: "C1")
        let event3 = SmartAccountEvent.walletDisconnected(contractId: "C2")

        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)
        XCTAssertNotEqual(event1, event3)

        let copied = SmartAccountEvent.walletDisconnected(contractId: "C-new")
        if case let .walletDisconnected(contractId) = copied {
            XCTAssertEqual(contractId, "C-new")
        } else {
            XCTFail("expected walletDisconnected arm")
        }
    }

    func testTransactionSubmitted_equalityAndCopy() {
        let event1 = SmartAccountEvent.transactionSubmitted(hash: "h1", success: true)
        let event2 = SmartAccountEvent.transactionSubmitted(hash: "h1", success: true)
        let event3 = SmartAccountEvent.transactionSubmitted(hash: "h1", success: false)

        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)
        XCTAssertNotEqual(event1, event3, "Different success value should not be equal")

        let copied = SmartAccountEvent.transactionSubmitted(hash: "h1", success: false)
        if case let .transactionSubmitted(hash, success) = copied {
            XCTAssertEqual(hash, "h1")
            XCTAssertFalse(success)
        } else {
            XCTFail("expected transactionSubmitted arm")
        }
    }

    func testTransactionSigned_equalityWithNullCredential() {
        let event1 = SmartAccountEvent.transactionSigned(contractId: "C1", credentialId: nil)
        let event2 = SmartAccountEvent.transactionSigned(contractId: "C1", credentialId: nil)
        let event3 = SmartAccountEvent.transactionSigned(contractId: "C1", credentialId: "cr")

        XCTAssertEqual(event1, event2, "Both with null credentialId should be equal")
        XCTAssertNotEqual(event1, event3, "Null vs non-null credentialId should not be equal")
    }

    func testSessionExpired_equalityAndCopy() {
        let event1 = SmartAccountEvent.sessionExpired(contractId: "C1", credentialId: "cr1")
        let event2 = SmartAccountEvent.sessionExpired(contractId: "C1", credentialId: "cr1")

        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)

        let copied = SmartAccountEvent.sessionExpired(contractId: "C-new", credentialId: "cr1")
        if case let .sessionExpired(contractId, credentialId) = copied {
            XCTAssertEqual(contractId, "C-new")
            XCTAssertEqual(credentialId, "cr1")
        } else {
            XCTFail("expected sessionExpired arm")
        }
    }

    func testCredentialDeleted_equalityAndCopy() {
        let event1 = SmartAccountEvent.credentialDeleted(credentialId: "cr1")
        let event2 = SmartAccountEvent.credentialDeleted(credentialId: "cr1")
        let event3 = SmartAccountEvent.credentialDeleted(credentialId: "cr2")

        XCTAssertEqual(event1, event2)
        XCTAssertNotEqual(event1, event3)

        let copied = SmartAccountEvent.credentialDeleted(credentialId: "cr-new")
        if case let .credentialDeleted(credentialId) = copied {
            XCTAssertEqual(credentialId, "cr-new")
        } else {
            XCTFail("expected credentialDeleted arm")
        }
    }

    func testDifferentEventTypes_areNeverEqual() {
        let connected = SmartAccountEvent.walletConnected(contractId: "C", credentialId: "cr")
        let disconnected = SmartAccountEvent.walletDisconnected(contractId: "C")
        let expired = SmartAccountEvent.sessionExpired(contractId: "C", credentialId: "cr")

        XCTAssertNotEqual(connected, disconnected,
            "Different event types should never be equal")
        XCTAssertNotEqual(connected, expired,
            "Different event types should never be equal even with same properties")
    }

    // MARK: - Listener Interaction During Emission

    func testListener_canUnsubscribeItselfDuringEmission() {
        let emitter = SmartAccountEventEmitter()
        let callCount = Counter()
        let unsubscribeBox = UnsubscribeReceiver()

        let unsub = emitter.on(.walletDisconnected) { _ in
            callCount.increment()
            unsubscribeBox.invoke()
        }
        unsubscribeBox.set(unsub)

        emitter.emit(.walletDisconnected(contractId: "C1"))
        emitter.emit(.walletDisconnected(contractId: "C2"))

        XCTAssertEqual(callCount.value, 1,
            "Listener that unsubscribes itself during emission should fire once")
    }

    func testOnce_combinedWithPermanentListener() {
        let emitter = SmartAccountEventEmitter()
        let onceCount = Counter()
        let permanentCount = Counter()

        emitter.once(.transactionSubmitted) { _ in onceCount.increment() }
        emitter.on(.transactionSubmitted) { _ in permanentCount.increment() }

        emitter.emit(.transactionSubmitted(hash: "tx1", success: true))
        emitter.emit(.transactionSubmitted(hash: "tx2", success: true))
        emitter.emit(.transactionSubmitted(hash: "tx3", success: true))

        XCTAssertEqual(onceCount.value, 1, "once listener should fire exactly once")
        XCTAssertEqual(permanentCount.value, 3, "Permanent listener should fire for all events")
    }
}

// ============================================================================
// Test helper types
// ============================================================================

/// Error type used by tests to signal listener failure to the emitter.
struct TestEventError: Error {
    let message: String
}

/// Thread-safe integer counter for assertions on listener invocation counts.
final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Int = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return _value }
    func increment() {
        lock.lock(); _value += 1; lock.unlock()
    }
}

/// Thread-safe boolean flag.
final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool = false
    func get() -> Bool { lock.lock(); defer { lock.unlock() }; return _value }
    func set(_ newValue: Bool) { lock.lock(); _value = newValue; lock.unlock() }
}

/// Thread-safe string list for ordered-event assertions.
final class StringList: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String] = []
    func append(_ s: String) { lock.lock(); items.append(s); lock.unlock() }
    func snapshot() -> [String] { lock.lock(); defer { lock.unlock() }; return items }
}

/// Thread-safe event recorder.
final class EventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [SmartAccountEvent] = []
    func append(_ event: SmartAccountEvent) { lock.lock(); events.append(event); lock.unlock() }
    func snapshot() -> [SmartAccountEvent] { lock.lock(); defer { lock.unlock() }; return events }
}

/// Captures the (event, error) pair surfaced by the emitter's error handler.
final class ErrorCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var _event: SmartAccountEvent?
    private var _error: Error?
    var event: SmartAccountEvent? { lock.lock(); defer { lock.unlock() }; return _event }
    var error: Error? { lock.lock(); defer { lock.unlock() }; return _error }
    func set(event: SmartAccountEvent, error: Error) {
        lock.lock(); _event = event; _error = error; lock.unlock()
    }
}

/// Receives an unsubscribe closure later than the listener body that invokes it,
/// supporting the listener-self-unsubscribe pattern.
final class UnsubscribeReceiver: @unchecked Sendable {
    private let lock = NSLock()
    private var unsubscribe: SmartAccountEventUnsubscribe?
    func set(_ u: @escaping SmartAccountEventUnsubscribe) { lock.lock(); unsubscribe = u; lock.unlock() }
    func invoke() {
        lock.lock()
        let u = unsubscribe
        lock.unlock()
        u?()
    }
}

// MARK: - SmartAccountEvent equality and hash — extra coverage

extension OZSmartAccountEventsTests {

    /// `SmartAccountEvent.credentialCreated` equality and hash coverage.
    func test_event_credentialCreated_equalityAndHash() {
        let key = Data(repeating: 0x04, count: 65)
        let cred = StoredCredential(
            credentialId: "cred-eq",
            publicKey: key,
            contractId: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
            deploymentStatus: .pending,
            createdAt: 0,
            nickname: nil,
            isPrimary: false
        )
        let event1: SmartAccountEvent = .credentialCreated(credential: cred)
        let event2: SmartAccountEvent = .credentialCreated(credential: cred)
        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)
    }

    /// `SmartAccountEvent.transactionSigned` equality and hash coverage.
    func test_event_transactionSigned_equalityAndHash() {
        let event1: SmartAccountEvent = .transactionSigned(
            contractId: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
            credentialId: "cred-ts"
        )
        let event2: SmartAccountEvent = .transactionSigned(
            contractId: "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
            credentialId: "cred-ts"
        )
        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)
    }

    /// `SmartAccountEvent.transactionSubmitted` equality and hash coverage.
    func test_event_transactionSubmitted_equalityAndHash() {
        let event1: SmartAccountEvent = .transactionSubmitted(hash: "abc", success: true)
        let event2: SmartAccountEvent = .transactionSubmitted(hash: "abc", success: true)
        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)
    }

    /// `SmartAccountEvent.credentialSyncFailed` equality and hash coverage.
    func test_event_credentialSyncFailed_equalityAndHash() {
        struct _SyncErr: Error, LocalizedError {
            var errorDescription: String? { "sync failed" }
        }
        let err = _SyncErr()
        let event1: SmartAccountEvent = .credentialSyncFailed(credentialId: "cred-sf", error: err)
        let event2: SmartAccountEvent = .credentialSyncFailed(credentialId: "cred-sf", error: err)
        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)
    }

    /// `SmartAccountEvent.credentialDeleted` hash coverage.
    func test_event_credentialDeleted_hashCoverageAndEquality() {
        let event1: SmartAccountEvent = .credentialDeleted(credentialId: "cred-del")
        let event2: SmartAccountEvent = .credentialDeleted(credentialId: "cred-del")
        XCTAssertEqual(event1, event2)
        XCTAssertEqual(event1.hashValue, event2.hashValue)
    }

    // MARK: - once — double-callOnce path (UnsubscribeBox lines 478-480)

    /// Calling the returned unsubscribe closure AFTER the event has already
    /// fired must be a no-op. This exercises the `if fired { ... return }`
    /// guard inside `UnsubscribeBox.callOnce()` (lines 478-480).
    func test_once_callingReturnedUnsubscribeAfterEventFires_isNoOp() {
        let emitter = SmartAccountEventEmitter()
        let callCount = Counter()
        let unsubscribe = emitter.once(.transactionSubmitted) { _ in
            callCount.increment()
        }
        emitter.emit(.transactionSubmitted(hash: "h1", success: true))
        XCTAssertEqual(1, callCount.value, "listener must fire exactly once")

        // Calling the returned unsubscribe after the event has already fired
        // must be a no-op (not a crash or double-invocation).
        unsubscribe()
        XCTAssertEqual(1, callCount.value, "calling unsubscribe after event fires must not increment count")
    }

    /// Calling the returned unsubscribe BEFORE the event fires prevents the
    /// listener from running. Exercises the `set` path normally and verifies
    /// `callOnce` from the event does not double-fire.
    func test_once_callingReturnedUnsubscribeBeforeEventFires_preventsListenerFromRunning() {
        let emitter = SmartAccountEventEmitter()
        let callCount = Counter()
        let unsubscribe = emitter.once(.transactionSubmitted) { _ in
            callCount.increment()
        }
        unsubscribe()
        emitter.emit(.transactionSubmitted(hash: "h2", success: false))
        XCTAssertEqual(0, callCount.value, "listener must not fire after unsubscribe is called")
    }
}
