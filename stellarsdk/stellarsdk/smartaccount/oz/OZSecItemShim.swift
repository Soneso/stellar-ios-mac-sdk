//
//  OZSecItemShim.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security

/// Indirection layer over the Security framework's `SecItem*` C functions.
///
/// `OZKeychainStorageAdapter` calls this protocol instead of `SecItemAdd` /
/// `SecItemCopyMatching` / `SecItemUpdate` / `SecItemDelete` directly so unit
/// tests can substitute a fake that returns deterministic `OSStatus` values
/// (e.g. `errSecDuplicateItem` to drive the upsert fallback) without a real
/// Keychain. `Sendable` so it can be held by the actor-isolated adapter.
internal protocol OZSecItemShim: Sendable {

    func add(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func copyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func update(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus
    func delete(query: CFDictionary) -> OSStatus
}

/// Default `OZSecItemShim` conformance that forwards every call to the
/// Security framework's C functions unchanged.
internal struct OZRealSecItemShim: OZSecItemShim {

    internal init() {}

    // LCOV_EXCL_START
    internal func add(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        return SecItemAdd(query, result)
    }

    internal func copyMatching(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        return SecItemCopyMatching(query, result)
    }

    internal func update(
        query: CFDictionary,
        attributesToUpdate: CFDictionary
    ) -> OSStatus {
        return SecItemUpdate(query, attributesToUpdate)
    }

    internal func delete(query: CFDictionary) -> OSStatus {
        return SecItemDelete(query)
    }
    // LCOV_EXCL_STOP
}
