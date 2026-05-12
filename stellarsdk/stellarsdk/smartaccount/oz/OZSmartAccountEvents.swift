//
//  OZSmartAccountEvents.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// SmartAccountEvent
// ============================================================================

/// Events emitted by the Smart Account Kit during wallet lifecycle operations.
///
/// These events provide hooks for monitoring and responding to key operations:
/// - Wallet connection and disconnection
/// - Credential lifecycle (creation, deletion)
/// - Transaction lifecycle (signing, submission)
/// - Session management (expiration)
///
/// Example:
/// ```swift
/// kit.events.addListener { event in
///     switch event {
///     case .walletConnected(let contractId, _):
///         print("Connected to \(contractId)")
///     case .transactionSubmitted(let hash, _):
///         print("Transaction \(hash) submitted")
///     default:
///         break
///     }
/// }
/// ```
public enum SmartAccountEvent: Sendable, Equatable, Hashable {

    /// Emitted when a wallet is connected.
    ///
    /// This event is fired when connecting to an existing wallet, either through
    /// automatic session restoration or an explicit wallet connection call.
    ///
    /// - Parameters:
    ///   - contractId: The smart account contract address (`C…` strkey).
    ///   - credentialId: The Base64URL-encoded credential ID.
    case walletConnected(contractId: String, credentialId: String)

    /// Emitted when a wallet is disconnected.
    ///
    /// This event is fired when `disconnect()` is called. The session is cleared,
    /// but stored credentials remain for future reconnection.
    ///
    /// - Parameter contractId: The smart account contract address that was disconnected.
    case walletDisconnected(contractId: String)

    /// Emitted when a new credential is created (passkey registered).
    ///
    /// This event is fired after successful WebAuthn credential creation, whether
    /// during initial wallet setup or when adding a new signer to an existing wallet.
    /// Note that the wallet may not be deployed yet.
    ///
    /// - Parameter credential: The stored credential data.
    case credentialCreated(credential: StoredCredential)

    /// Emitted when a credential is deleted from storage.
    ///
    /// This event is fired when a credential is removed via the credential
    /// management API. If the credential was connected, the wallet is automatically
    /// disconnected first.
    ///
    /// - Parameter credentialId: The Base64URL-encoded credential ID.
    case credentialDeleted(credentialId: String)

    /// Emitted when a session expires during a connection attempt.
    ///
    /// This event is fired when attempting to restore a session that has expired.
    /// The application should prompt the user to reconnect.
    ///
    /// - Parameters:
    ///   - contractId: The smart account contract address.
    ///   - credentialId: The Base64URL-encoded credential ID.
    case sessionExpired(contractId: String, credentialId: String)

    /// Emitted when a transaction is signed.
    ///
    /// This event is fired after successfully collecting all required signatures
    /// for a transaction, before submission to the network.
    ///
    /// - Parameters:
    ///   - contractId: The smart account contract address.
    ///   - credentialId: The credential ID used for signing (`nil` if only external
    ///     signers contributed).
    case transactionSigned(contractId: String, credentialId: String?)

    /// Emitted when a transaction is submitted to the network.
    ///
    /// This event is fired after sending the signed transaction to Soroban RPC or
    /// the relayer service. The success flag indicates whether the transaction was
    /// successfully sent to the network node, not whether it was included in a
    /// ledger.
    ///
    /// - Parameters:
    ///   - hash: The transaction hash.
    ///   - success: `true` if submitted successfully, `false` if submission failed.
    case transactionSubmitted(hash: String, success: Bool)

    // MARK: - Type tag

    /// Stable type tag used for type-keyed listener registration and lookup.
    ///
    /// The tag is the un-namespaced arm name (`"WalletConnected"`, `"WalletDisconnected"`, etc.)
    /// and matches the strings consumed by ``SmartAccountEventEmitter/removeAllListeners(eventType:)``
    /// and ``SmartAccountEventEmitter/listenerCount(eventType:)``.
    public var eventTypeTag: String {
        switch self {
        case .walletConnected:
            return SmartAccountEventType.walletConnected.tag
        case .walletDisconnected:
            return SmartAccountEventType.walletDisconnected.tag
        case .credentialCreated:
            return SmartAccountEventType.credentialCreated.tag
        case .credentialDeleted:
            return SmartAccountEventType.credentialDeleted.tag
        case .sessionExpired:
            return SmartAccountEventType.sessionExpired.tag
        case .transactionSigned:
            return SmartAccountEventType.transactionSigned.tag
        case .transactionSubmitted:
            return SmartAccountEventType.transactionSubmitted.tag
        }
    }
}

// ============================================================================
// SmartAccountEventType
// ============================================================================

/// Type-tag enumeration used to register typed subscriptions on
/// ``SmartAccountEventEmitter``.
///
/// Swift enum cases do not have nested types, so a parallel enum carries the
/// per-arm type tag used by ``SmartAccountEventEmitter/on(_:listener:)`` and
/// ``SmartAccountEventEmitter/once(_:listener:)``. The raw value is the stable
/// string key consumed by ``SmartAccountEventEmitter/removeAllListeners(eventType:)``
/// and ``SmartAccountEventEmitter/listenerCount(eventType:)``.
///
/// Example:
/// ```swift
/// let unsubscribe = emitter.on(.walletConnected) { event in
///     if case let .walletConnected(contractId, _) = event {
///         print("Connected to \(contractId)")
///     }
/// }
/// ```
public enum SmartAccountEventType: String, Sendable, CaseIterable {
    case walletConnected = "WalletConnected"
    case walletDisconnected = "WalletDisconnected"
    case credentialCreated = "CredentialCreated"
    case credentialDeleted = "CredentialDeleted"
    case sessionExpired = "SessionExpired"
    case transactionSigned = "TransactionSigned"
    case transactionSubmitted = "TransactionSubmitted"

    /// Stable string tag used as the listener-map key.
    public var tag: String { return rawValue }
}

// ============================================================================
// SmartAccountEventListener
// ============================================================================

/// Listener invoked for each emitted Smart Account event.
///
/// The closure may throw to signal failure; the emitter catches the error and
/// routes it to the configured error handler so a failing listener never aborts
/// dispatch to its siblings.
///
/// Closures of this type are registered with ``SmartAccountEventEmitter/addListener(_:)``,
/// ``SmartAccountEventEmitter/on(_:listener:)`` and
/// ``SmartAccountEventEmitter/once(_:listener:)``.
///
/// Example:
/// ```swift
/// let listener: SmartAccountEventListener = { event in
///     print("Received event: \(event)")
/// }
/// kit.events.addListener(listener)
/// ```
public typealias SmartAccountEventListener = @Sendable (SmartAccountEvent) throws -> Void

/// Closure invoked when a registered listener throws while handling an event.
///
/// Receives the event that was being dispatched and the error thrown by the
/// failing listener.
public typealias SmartAccountEventErrorHandler = @Sendable (SmartAccountEvent, Error) -> Void

/// Closure returned by listener registration; invoke to unsubscribe.
public typealias SmartAccountEventUnsubscribe = @Sendable () -> Void

// ============================================================================
// SmartAccountEventEmitter
// ============================================================================

/// Event emitter for Smart Account lifecycle events.
///
/// Manages event subscriptions and dispatches events to all registered listeners.
/// Subscription management and event emission are thread-safe; listener callbacks
/// are invoked outside the internal lock so that a listener may freely call back
/// into the emitter (for example to unsubscribe itself) without deadlocking.
///
/// Features:
/// - Thread-safe listener management via an internal `NSLock`.
/// - Multiple listeners per event type, plus global listeners that receive every
///   event.
/// - Listener error isolation: an error thrown by one listener never prevents
///   sibling listeners from running and never propagates out of `emit`.
/// - Optional error handler for diagnosing listener failures.
/// - Synchronous public API so listeners may safely re-enter the emitter during
///   emission.
///
/// Example:
/// ```swift
/// let emitter = SmartAccountEventEmitter()
///
/// // Typed subscription via a SmartAccountEventType tag
/// let unsubscribe = emitter.on(.walletConnected) { event in
///     if case let .walletConnected(contractId, _) = event {
///         print("Connected to \(contractId)")
///     }
/// }
///
/// // Global subscription
/// let unsub = emitter.addListener { event in
///     // dispatch as needed
/// }
///
/// // One-time listener
/// _ = emitter.once(.transactionSubmitted) { event in
///     if case let .transactionSubmitted(hash, _) = event {
///         print("First transaction: \(hash)")
///     }
/// }
///
/// unsubscribe()
/// ```
public final class SmartAccountEventEmitter: @unchecked Sendable {

    // why: a synchronous `NSLock` keeps the public surface non-async, which is
    // required for the listener-self-unsubscribe contract. An `actor` would
    // force every method to be `async`, breaking re-entrancy because a listener
    // running inside `emit` could not call back into `addListener` /
    // `removeAllListeners` without an extra suspension that loses ordering.
    private let stateLock = NSLock()

    /// A unique identifier assigned to every registered listener so that the
    /// unsubscribe closure can locate the right entry without relying on closure
    /// identity (Swift closures are not equatable).
    private final class ListenerHandle: @unchecked Sendable {
        let id: UUID
        let callback: SmartAccountEventListener
        init(id: UUID = UUID(), callback: @escaping SmartAccountEventListener) {
            self.id = id
            self.callback = callback
        }
    }

    private var typeListeners: [String: [ListenerHandle]] = [:]
    private var globalListeners: [ListenerHandle] = []
    private var errorHandler: SmartAccountEventErrorHandler? = nil

    /// Initializes a new emitter with no listeners and no error handler.
    public init() {}

    // MARK: - setErrorHandler

    /// Sets the error handler invoked when a listener throws while handling an
    /// event.
    ///
    /// The error handler receives both the event being dispatched and the error
    /// thrown by the failing listener. Pass `nil` to disable error reporting; in
    /// that case listener errors are silently caught so a single failing listener
    /// cannot abort emission to its siblings.
    ///
    /// - Parameter handler: Error handler closure, or `nil` to disable.
    public func setErrorHandler(_ handler: SmartAccountEventErrorHandler?) {
        stateLock.lock()
        errorHandler = handler
        stateLock.unlock()
    }

    // MARK: - addListener

    /// Subscribes a listener to receive every emitted event.
    ///
    /// Unlike ``on(_:listener:)``, this method registers a global listener that
    /// receives all event arms regardless of type. Use it from call sites that
    /// dispatch with a `switch` over the event itself.
    ///
    /// - Parameter listener: The closure invoked for every event.
    /// - Returns: A closure that unsubscribes the listener when called. Calling
    ///   the returned closure more than once is a no-op.
    @discardableResult
    public func addListener(_ listener: @escaping SmartAccountEventListener) -> SmartAccountEventUnsubscribe {
        let handle = ListenerHandle(callback: listener)
        stateLock.lock()
        globalListeners.append(handle)
        stateLock.unlock()
        return { [weak self] in
            guard let self = self else { return }
            self.stateLock.lock()
            self.globalListeners.removeAll { $0.id == handle.id }
            self.stateLock.unlock()
        }
    }

    // MARK: - on

    /// Subscribes to events of a specific type.
    ///
    /// The listener is invoked only when an event matching `eventType` is emitted.
    /// The returned closure unsubscribes the listener when called.
    ///
    /// - Parameters:
    ///   - eventType: The ``SmartAccountEventType`` tag identifying which event
    ///     arm to subscribe to.
    ///   - listener: The closure invoked for each matching event.
    /// - Returns: A closure that unsubscribes the listener when called.
    @discardableResult
    public func on(
        _ eventType: SmartAccountEventType,
        listener: @escaping SmartAccountEventListener
    ) -> SmartAccountEventUnsubscribe {
        let tag = eventType.tag
        let handle = ListenerHandle(callback: listener)
        stateLock.lock()
        typeListeners[tag, default: []].append(handle)
        stateLock.unlock()
        return { [weak self] in
            guard let self = self else { return }
            self.stateLock.lock()
            if var handles = self.typeListeners[tag] {
                handles.removeAll { $0.id == handle.id }
                if handles.isEmpty {
                    self.typeListeners.removeValue(forKey: tag)
                } else {
                    self.typeListeners[tag] = handles
                }
            }
            self.stateLock.unlock()
        }
    }

    // MARK: - once

    /// Subscribes to an event of a specific type, but only triggers once.
    ///
    /// The listener is automatically unsubscribed before its body runs, so even
    /// if the listener throws, the once-subscription is still removed. The
    /// returned closure unsubscribes the listener before it ever fires; calling
    /// it after the event has already fired is a no-op.
    ///
    /// - Parameters:
    ///   - eventType: The ``SmartAccountEventType`` tag identifying which event
    ///     arm to subscribe to.
    ///   - listener: The closure invoked for the first matching event.
    /// - Returns: A closure that unsubscribes the listener if called before the
    ///   first matching event.
    @discardableResult
    public func once(
        _ eventType: SmartAccountEventType,
        listener: @escaping SmartAccountEventListener
    ) -> SmartAccountEventUnsubscribe {
        // why: the wrapper invokes the unsubscribe closure BEFORE the user
        // listener body so that a throwing listener still gets removed exactly
        // once. Calling unsubscribe afterwards would leak the listener whenever
        // the body raised on its first invocation.
        let unsubscribeBox = UnsubscribeBox()
        let unsub = self.on(eventType) { event in
            unsubscribeBox.callOnce()
            try listener(event)
        }
        unsubscribeBox.set(unsub)
        return { unsubscribeBox.callOnce() }
    }

    /// Holds a single unsubscribe closure and ensures it is invoked at most
    /// once, regardless of how many times callers fire it.
    private final class UnsubscribeBox: @unchecked Sendable {
        private let lock = NSLock()
        private var unsubscribe: SmartAccountEventUnsubscribe? = nil
        private var fired: Bool = false

        func set(_ unsubscribe: @escaping SmartAccountEventUnsubscribe) {
            lock.lock()
            if fired {
                lock.unlock()
                unsubscribe()
                return
            }
            self.unsubscribe = unsubscribe
            lock.unlock()
        }

        func callOnce() {
            lock.lock()
            if fired {
                lock.unlock()
                return
            }
            fired = true
            let captured = unsubscribe
            unsubscribe = nil
            lock.unlock()
            captured?()
        }
    }

    // MARK: - removeAllListeners

    /// Removes registered listeners.
    ///
    /// When `eventType` is non-`nil`, only type-specific listeners registered via
    /// ``on(_:listener:)`` for that event type are removed; global listeners
    /// registered via ``addListener(_:)`` are left intact. Passing `nil` removes
    /// every type-specific listener and every global listener.
    ///
    /// - Parameter eventType: The event tag to clear, or `nil` to clear all
    ///   listeners (both typed and global).
    public func removeAllListeners(eventType: String? = nil) {
        stateLock.lock()
        if let eventType = eventType {
            // why: targeted removal preserves global listeners. A caller that
            // wants to drop everything must pass `nil` (or call the no-argument
            // overload), which is verified by the test suite.
            typeListeners.removeValue(forKey: eventType)
        } else {
            typeListeners.removeAll()
            globalListeners.removeAll()
        }
        stateLock.unlock()
    }

    /// Convenience overload that removes both type-specific and global listeners.
    public func removeAllListeners() {
        removeAllListeners(eventType: nil)
    }

    // MARK: - listenerCount

    /// Returns the number of listeners currently registered for the supplied
    /// event tag.
    ///
    /// The count is the sum of type-specific listeners registered via
    /// ``on(_:listener:)`` for `eventType` plus every global listener registered
    /// via ``addListener(_:)``.
    ///
    /// - Parameter eventType: The event tag to query (for example `"WalletConnected"`).
    /// - Returns: The number of registered listeners (type-specific plus global).
    public func listenerCount(eventType: String) -> Int {
        stateLock.lock()
        let count = (typeListeners[eventType]?.count ?? 0) + globalListeners.count
        stateLock.unlock()
        return count
    }

    // MARK: - emit (internal)

    /// Emits an event to every registered listener.
    ///
    /// Dispatches to all type-specific listeners registered for the event arm,
    /// plus every global listener registered via ``addListener(_:)``. The
    /// listener list is snapshotted under the internal lock and listeners are
    /// invoked outside the lock; this avoids deadlock when a listener calls
    /// back into the emitter (for example to unsubscribe itself).
    ///
    /// Listener errors are caught and routed to the error handler, when set,
    /// so one failing listener cannot prevent its siblings from receiving the
    /// event.
    ///
    /// - Parameter event: The event to emit.
    internal func emit(_ event: SmartAccountEvent) {
        let tag = event.eventTypeTag
        stateLock.lock()
        let typed = typeListeners[tag] ?? []
        let combined = typed + globalListeners
        let capturedHandler = errorHandler
        stateLock.unlock()

        for handle in combined {
            do {
                try handle.callback(event)
            } catch {
                capturedHandler?(event, error)
            }
        }
    }
}
