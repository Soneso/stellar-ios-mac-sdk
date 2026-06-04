//
//  FakeSecItemShim.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security
@testable import stellarsdk

// ============================================================================
// FakeSecItemShim
// ============================================================================

/// Test-only `OZSecItemShim` conformance whose call behavior is configurable
/// per-primitive.
///
/// Each closure takes the same arguments as the corresponding `SecItem*`
/// primitive and returns the `OSStatus` the production code should observe.
/// The default closures forward to the system Security framework so a
/// `FakeSecItemShim()` with no overrides behaves identically to
/// `OZRealSecItemShim`.
///
/// Tests typically override one or two closures to inject deterministic
/// failure codes (for example `errSecInteractionNotAllowed` to simulate a
/// locked device) and leave the remaining closures untouched. The shim also
/// records the call counts and the arguments passed to each primitive so
/// tests can assert ordering and intent.
///
/// All access is guarded by an internal lock so tests that exercise
/// concurrent operations against a single shim observe consistent state.
final class FakeSecItemShim: OZSecItemShim, @unchecked Sendable {

    typealias AddHandler = (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    typealias CopyMatchingHandler = (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    typealias UpdateHandler = (CFDictionary, CFDictionary) -> OSStatus
    typealias DeleteHandler = (CFDictionary) -> OSStatus

    private let lock = NSLock()

    private var _addHandler: AddHandler
    private var _copyMatchingHandler: CopyMatchingHandler
    private var _updateHandler: UpdateHandler
    private var _deleteHandler: DeleteHandler

    private(set) var addCallCount: Int = 0
    private(set) var copyMatchingCallCount: Int = 0
    private(set) var updateCallCount: Int = 0
    private(set) var deleteCallCount: Int = 0

    init(
        addHandler: @escaping AddHandler = { query, result in SecItemAdd(query, result) },
        copyMatchingHandler: @escaping CopyMatchingHandler = { query, result in
            SecItemCopyMatching(query, result)
        },
        updateHandler: @escaping UpdateHandler = { query, attrs in SecItemUpdate(query, attrs) },
        deleteHandler: @escaping DeleteHandler = { query in SecItemDelete(query) }
    ) {
        self._addHandler = addHandler
        self._copyMatchingHandler = copyMatchingHandler
        self._updateHandler = updateHandler
        self._deleteHandler = deleteHandler
    }

    /// Replaces the `add` handler. Subsequent `add(query:result:)` calls invoke
    /// the new closure.
    func setAddHandler(_ handler: @escaping AddHandler) {
        lock.lock()
        _addHandler = handler
        lock.unlock()
    }

    /// Replaces the `copyMatching` handler.
    func setCopyMatchingHandler(_ handler: @escaping CopyMatchingHandler) {
        lock.lock()
        _copyMatchingHandler = handler
        lock.unlock()
    }

    /// Replaces the `update` handler.
    func setUpdateHandler(_ handler: @escaping UpdateHandler) {
        lock.lock()
        _updateHandler = handler
        lock.unlock()
    }

    /// Replaces the `delete` handler.
    func setDeleteHandler(_ handler: @escaping DeleteHandler) {
        lock.lock()
        _deleteHandler = handler
        lock.unlock()
    }

    func add(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        lock.lock()
        let handler = _addHandler
        addCallCount += 1
        lock.unlock()
        return handler(query, result)
    }

    func copyMatching(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        lock.lock()
        let handler = _copyMatchingHandler
        copyMatchingCallCount += 1
        lock.unlock()
        return handler(query, result)
    }

    func update(
        query: CFDictionary,
        attributesToUpdate: CFDictionary
    ) -> OSStatus {
        lock.lock()
        let handler = _updateHandler
        updateCallCount += 1
        lock.unlock()
        return handler(query, attributesToUpdate)
    }

    func delete(query: CFDictionary) -> OSStatus {
        lock.lock()
        let handler = _deleteHandler
        deleteCallCount += 1
        lock.unlock()
        return handler(query)
    }
}
