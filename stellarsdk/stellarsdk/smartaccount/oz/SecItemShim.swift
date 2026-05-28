//
//  SecItemShim.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security

/// Indirection layer over the Security framework's `SecItem*` C functions.
///
/// `KeychainStorageAdapter` calls this protocol instead of `SecItemAdd` /
/// `SecItemCopyMatching` / `SecItemUpdate` / `SecItemDelete` directly so unit
/// tests can substitute a fake that returns deterministic `OSStatus` values
/// (e.g. `errSecDuplicateItem` to drive the upsert fallback) without a real
/// Keychain. `Sendable` so it can be held by the actor-isolated adapter.
public protocol SecItemShim: Sendable {

    func add(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func copyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func update(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus
    func delete(query: CFDictionary) -> OSStatus
}

/// Default `SecItemShim` conformance that forwards every call to the
/// Security framework's C functions unchanged.
public struct RealSecItemShim: SecItemShim {

    public init() {}

    public func add(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        return SecItemAdd(query, result)
    }

    public func copyMatching(
        query: CFDictionary,
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        return SecItemCopyMatching(query, result)
    }

    public func update(
        query: CFDictionary,
        attributesToUpdate: CFDictionary
    ) -> OSStatus {
        return SecItemUpdate(query, attributesToUpdate)
    }

    public func delete(query: CFDictionary) -> OSStatus {
        return SecItemDelete(query)
    }
}
