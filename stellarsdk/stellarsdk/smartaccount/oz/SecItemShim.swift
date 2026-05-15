//
//  SecItemShim.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security

// ============================================================================
// SecItemShim
// ============================================================================

/// Indirection layer over the Security framework's `SecItem*` C functions.
///
/// `KeychainStorageAdapter` calls into a `SecItemShim` instead of invoking
/// `SecItemAdd` / `SecItemCopyMatching` / `SecItemUpdate` / `SecItemDelete`
/// directly. The default conformance, `RealSecItemShim`, simply forwards every
/// call to the system implementation. The indirection exists so unit tests can
/// substitute a fake implementation that returns deterministic `OSStatus`
/// values for failure-mode coverage (for example `errSecInteractionNotAllowed`
/// when the device is locked, or `errSecDuplicateItem` to drive the upsert
/// fallback path) without needing a real Keychain.
///
/// The protocol surface is intentionally minimal — one method per primitive —
/// and is `Sendable` so it can be held by the actor-isolated
/// `KeychainStorageAdapter`. Conforming types must be value semantically
/// thread-safe; the production conformance forwards to the C functions which
/// are themselves thread-safe.
public protocol SecItemShim: Sendable {

    /// Forwards to `SecItemAdd(query, result)`.
    ///
    /// - Parameters:
    ///   - query: The Keychain query dictionary to add. Passed as
    ///     `CFDictionary` to the underlying C function.
    ///   - result: Pointer to receive the optional result reference. May be
    ///     `nil` when the caller does not need the produced reference.
    /// - Returns: The `OSStatus` returned by `SecItemAdd`.
    func add(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus

    /// Forwards to `SecItemCopyMatching(query, result)`.
    ///
    /// - Parameters:
    ///   - query: The Keychain query dictionary describing the item to read.
    ///   - result: Pointer that receives the matching item reference (typically
    ///     a `CFData` when `kSecReturnData` is set in the query). May be `nil`
    ///     when the caller only checks for existence.
    /// - Returns: The `OSStatus` returned by `SecItemCopyMatching`.
    func copyMatching(query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus

    /// Forwards to `SecItemUpdate(query, attributesToUpdate)`.
    ///
    /// - Parameters:
    ///   - query: The Keychain query dictionary identifying the item to update.
    ///   - attributesToUpdate: Dictionary of attributes to apply.
    /// - Returns: The `OSStatus` returned by `SecItemUpdate`.
    func update(query: CFDictionary, attributesToUpdate: CFDictionary) -> OSStatus

    /// Forwards to `SecItemDelete(query)`.
    ///
    /// - Parameter query: The Keychain query dictionary identifying the item
    ///   to delete.
    /// - Returns: The `OSStatus` returned by `SecItemDelete`.
    func delete(query: CFDictionary) -> OSStatus
}

// ============================================================================
// RealSecItemShim
// ============================================================================

/// Default `SecItemShim` conformance that forwards every call to the
/// Security framework's C functions unchanged.
///
/// `KeychainStorageAdapter` constructs an instance of this type when no shim is
/// supplied, so consumer code never has to mention `SecItemShim` to use the
/// adapter. Tests substitute their own conformance to drive failure paths.
public struct RealSecItemShim: SecItemShim {

    /// Initializes a new real shim. The type holds no state; multiple instances
    /// are interchangeable.
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
