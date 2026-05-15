//
//  KeychainStorageAdapter.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import Security

// ============================================================================
// KeychainStorageAdapter
// ============================================================================

/// Persistent `StorageAdapter` backed by the iOS / macOS Keychain Services API.
///
/// Stores credential and session payloads as `kSecClassGenericPassword` items
/// using the Security framework's `SecItem*` primitives. Each entry is a UTF-8
/// JSON document keyed by a stable account name:
///
/// - `cred_<credentialId>` for individual stored credentials,
/// - `credential_index` for the JSON-encoded list of known credential IDs,
/// - `session_current` for the active session.
///
/// All items are written with `kSecAttrAccessibleAfterFirstUnlock` so they
/// survive app restarts but become inaccessible until the device is unlocked
/// after a reboot. The credentials persisted by this adapter are public-key
/// material (no secrets), so additional biometric `SecAccessControl` flags are
/// intentionally not configured — biometric gating would require a UI prompt
/// on every read and add no security value for public data.
///
/// Thread safety is provided by Swift Concurrency `actor` isolation, so all
/// operations serialize even when invoked from multiple tasks. The actor
/// holds JSON encoder / decoder instances configured once at init.
///
/// Example:
/// ```swift
/// let storage = KeychainStorageAdapter()
/// try await storage.save(credential: credential)
/// let loaded = try await storage.get(credentialId: credential.credentialId)
/// ```
///
/// - Important: On iOS Simulator and unsigned macOS test binaries, Keychain
///   access requires the `keychain-access-groups` entitlement to be configured.
///   Tests should probe availability and skip when the host environment lacks
///   the required entitlement.
@available(iOS 13.0, macOS 10.15, *)
public final actor KeychainStorageAdapter: StorageAdapter {

    // ========================================================================
    // Companion Constants
    // ========================================================================

    /// Default Keychain service name used as `kSecAttrService` for every item.
    ///
    /// Consumers can override this via the initializer to scope the adapter to
    /// a different service identifier — useful when multiple isolated stores
    /// must coexist within the same app (for example, separate test scopes or
    /// per-tenant scoping).
    public static let defaultServiceName: String = "com.soneso.stellar.smartaccount"

    /// Account-name prefix for individual credential entries.
    private static let credentialKeyPrefix: String = "cred_"

    /// Fixed account name for the credential ID index entry.
    private static let credentialIndexKey: String = "credential_index"

    /// Fixed account name for the active session entry.
    private static let sessionKey: String = "session_current"

    // ========================================================================
    // State
    // ========================================================================

    /// `kSecAttrService` value used for every Keychain query issued by this
    /// adapter instance.
    private let serviceName: String

    /// Indirection over the Security framework's `SecItem*` C functions. The
    /// production conformance forwards directly; tests substitute a fake to
    /// simulate failure-mode `OSStatus` values without needing a real Keychain.
    private let shim: SecItemShim

    /// Cached JSON encoder used for every persisted payload.
    private let encoder: JSONEncoder

    /// Cached JSON decoder used for every read payload.
    private let decoder: JSONDecoder

    // ========================================================================
    // Initialization
    // ========================================================================

    /// Initializes a new `KeychainStorageAdapter`.
    ///
    /// - Parameters:
    ///   - serviceName: Keychain service identifier (`kSecAttrService`).
    ///     Defaults to `KeychainStorageAdapter.defaultServiceName`.
    ///   - shim: Optional `SecItemShim` to use for all Security framework
    ///     calls. The default conformance forwards every call to the system
    ///     `SecItem*` functions; tests substitute a fake to drive failure
    ///     paths deterministically.
    public init(
        serviceName: String = KeychainStorageAdapter.defaultServiceName,
        shim: SecItemShim = RealSecItemShim()
    ) {
        self.serviceName = serviceName
        self.shim = shim
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // ========================================================================
    // StorageAdapter — Credential Operations
    // ========================================================================

    public func save(credential: StoredCredential) async throws {
        do {
            let serializable = credential.toSerializable()
            let jsonString = try encodeToString(serializable)
            let account = Self.credentialKeyPrefix + credential.credentialId

            try keychainUpsert(account: account, data: jsonString)

            // Append the credential ID to the index when not already present so
            // enumeration via the index entry stays consistent with stored items.
            let index = try readIndex()
            if !index.ids.contains(credential.credentialId) {
                let updated = CredentialIndex(ids: index.ids + [credential.credentialId])
                try writeIndex(updated)
            }
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.WriteFailed(
                message: "Storage write failed for key: \(credential.credentialId)",
                cause: error
            )
        }
    }

    public func get(credentialId: String) async throws -> StoredCredential? {
        do {
            return try readCredential(credentialId)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.ReadFailed(
                message: "Storage read failed for key: \(credentialId)",
                cause: error
            )
        }
    }

    public func getByContract(contractId: String) async throws -> [StoredCredential] {
        do {
            let index = try readIndex()
            var matches: [StoredCredential] = []
            for id in index.ids {
                if let credential = try readCredential(id), credential.contractId == contractId {
                    matches.append(credential)
                }
            }
            return matches
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.ReadFailed(
                message: "Storage read failed for contract: \(contractId)",
                cause: error
            )
        }
    }

    public func getAll() async throws -> [StoredCredential] {
        do {
            let index = try readIndex()
            var all: [StoredCredential] = []
            for id in index.ids {
                if let credential = try readCredential(id) {
                    all.append(credential)
                }
            }
            return all
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.ReadFailed(
                message: "Storage read failed for key: all credentials",
                cause: error
            )
        }
    }

    public func delete(credentialId: String) async throws {
        do {
            let account = Self.credentialKeyPrefix + credentialId
            try keychainDelete(account: account)

            // Shrink the index even when the credential entry was already
            // missing — the index must not retain stale IDs.
            let index = try readIndex()
            let updated = CredentialIndex(ids: index.ids.filter { $0 != credentialId })
            try writeIndex(updated)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.WriteFailed(
                message: "Storage write failed for key: \(credentialId)",
                cause: error
            )
        }
    }

    public func update(credentialId: String, updates: StoredCredentialUpdate) async throws {
        do {
            guard let existing = try readCredential(credentialId) else {
                throw CredentialException.notFound(credentialId: credentialId)
            }
            let updated = existing.applyUpdate(updates)

            let serializable = updated.toSerializable()
            let jsonString = try encodeToString(serializable)
            let account = Self.credentialKeyPrefix + credentialId

            try keychainUpsert(account: account, data: jsonString)
        } catch let error as CredentialException {
            throw error
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.WriteFailed(
                message: "Storage write failed for key: \(credentialId)",
                cause: error
            )
        }
    }

    public func clear() async throws {
        do {
            let index = try readIndex()
            for id in index.ids {
                try keychainDelete(account: Self.credentialKeyPrefix + id)
            }
            try keychainDelete(account: Self.credentialIndexKey)
            try keychainDelete(account: Self.sessionKey)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.WriteFailed(
                message: "Storage write failed for key: clear all",
                cause: error
            )
        }
    }

    // ========================================================================
    // StorageAdapter — Session Operations
    // ========================================================================

    public func saveSession(_ session: StoredSession) async throws {
        do {
            let serializable = session.toSerializable()
            let jsonString = try encodeToString(serializable)
            try keychainUpsert(account: Self.sessionKey, data: jsonString)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.WriteFailed(
                message: "Storage write failed for key: session",
                cause: error
            )
        }
    }

    public func getSession() async throws -> StoredSession? {
        do {
            guard let jsonString = try keychainRead(account: Self.sessionKey) else {
                return nil
            }
            let serializable = try decodeFromString(SerializableSession.self, jsonString)
            let session = serializable.toStoredSession()

            // why: an expired session is treated as if no session exists; it is
            // also dropped from storage on read so a subsequent read does not
            // need to re-evaluate expiry against the same stale entry. Callers
            // receive the simple "valid session OR nil" contract.
            if session.isExpired {
                try keychainDelete(account: Self.sessionKey)
                return nil
            }
            return session
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.ReadFailed(
                message: "Storage read failed for key: session",
                cause: error
            )
        }
    }

    public func clearSession() async throws {
        do {
            try keychainDelete(account: Self.sessionKey)
        } catch let error as StorageException {
            throw error
        } catch {
            throw StorageException.WriteFailed(
                message: "Storage write failed for key: session",
                cause: error
            )
        }
    }

    // ========================================================================
    // Internal Helpers — Credential I/O
    // ========================================================================

    /// Reads and decodes a single credential by ID. Returns `nil` when the
    /// underlying Keychain entry does not exist. Must be called from within
    /// the actor's serialized context.
    private func readCredential(_ credentialId: String) throws -> StoredCredential? {
        let account = Self.credentialKeyPrefix + credentialId
        guard let jsonString = try keychainRead(account: account) else {
            return nil
        }
        let serializable = try decodeFromString(SerializableCredential.self, jsonString)
        return try serializable.toStoredCredential()
    }

    /// Reads the credential ID index, returning an empty index when absent.
    /// Must be called from within the actor's serialized context.
    private func readIndex() throws -> CredentialIndex {
        guard let jsonString = try keychainRead(account: Self.credentialIndexKey) else {
            return CredentialIndex(ids: [])
        }
        return try decodeFromString(CredentialIndex.self, jsonString)
    }

    /// Persists the credential ID index. Must be called from within the actor's
    /// serialized context.
    private func writeIndex(_ index: CredentialIndex) throws {
        let jsonString = try encodeToString(index)
        try keychainUpsert(account: Self.credentialIndexKey, data: jsonString)
    }

    // ========================================================================
    // Internal Helpers — JSON
    // ========================================================================

    private func encodeToString<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw StorageException.WriteFailed(
                message: "Failed to encode JSON payload as UTF-8 string"
            )
        }
        return string
    }

    private func decodeFromString<T: Decodable>(_ type: T.Type, _ jsonString: String) throws -> T {
        guard let data = jsonString.data(using: .utf8) else {
            throw StorageException.ReadFailed(
                message: "Failed to decode UTF-8 bytes from stored JSON payload"
            )
        }
        return try decoder.decode(type, from: data)
    }

    // ========================================================================
    // Keychain Primitives
    // ========================================================================

    /// Builds the base query dictionary shared by every primitive: class,
    /// service identifier, and account name.
    private func baseQuery(account: String) -> [CFString: Any] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: account,
        ]
    }

    /// Reads the UTF-8 string value stored at the given account.
    ///
    /// - Returns: The stored string, or `nil` when the entry does not exist.
    /// - Throws: `StorageException.ReadFailed` for any non-success, non-not-found
    ///   `OSStatus`. This includes `errSecInteractionNotAllowed` (device
    ///   locked), `errSecMissingEntitlement` (CI / unsigned binary without
    ///   Keychain entitlement), and other transport-level failures.
    private func keychainRead(account: String) throws -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var resultRef: CFTypeRef?
        let status = shim.copyMatching(
            query: query as CFDictionary,
            result: &resultRef
        )

        switch status {
        case errSecSuccess:
            guard let data = resultRef as? Data else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw StorageException.ReadFailed(
                message: "Keychain read failed for account '\(account)' with OSStatus: \(status)"
            )
        }
    }

    /// Writes (upserts) the UTF-8 bytes of `data` at the given account.
    ///
    /// First attempts `SecItemAdd`. If the item already exists
    /// (`errSecDuplicateItem`), falls back to `SecItemUpdate` with the new
    /// value. Any other `OSStatus` becomes a `StorageException.WriteFailed`.
    ///
    /// - Throws: `StorageException.WriteFailed` for any failure that is not the
    ///   benign `errSecDuplicateItem` arm.
    private func keychainUpsert(account: String, data: String) throws {
        guard let payload = data.data(using: .utf8) else {
            throw StorageException.WriteFailed(
                message: "Failed to encode string data for account '\(account)'"
            )
        }

        // why: items are tagged `kSecAttrAccessibleAfterFirstUnlock` because
        // the stored payloads are public-key material plus metadata — there is
        // no secret to protect with biometric `SecAccessControl` flags, and
        // requiring biometric prompts on every read would degrade UX without
        // any security benefit. Items therefore survive app restarts but are
        // unreadable until the device is unlocked once after boot.
        var addQuery = baseQuery(account: account)
        addQuery[kSecValueData] = payload
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock

        let addStatus = shim.add(query: addQuery as CFDictionary, result: nil)

        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let searchQuery = baseQuery(account: account)
            let updateAttributes: [CFString: Any] = [
                kSecValueData: payload,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            ]
            let updateStatus = shim.update(
                query: searchQuery as CFDictionary,
                attributesToUpdate: updateAttributes as CFDictionary
            )
            if updateStatus != errSecSuccess {
                throw StorageException.WriteFailed(
                    message: "Keychain update failed for account '\(account)' with OSStatus: \(updateStatus)"
                )
            }
        default:
            throw StorageException.WriteFailed(
                message: "Keychain add failed for account '\(account)' with OSStatus: \(addStatus)"
            )
        }
    }

    /// Deletes the entry at the given account. Treats both `errSecSuccess` and
    /// `errSecItemNotFound` as success so the operation is idempotent.
    ///
    /// - Throws: `StorageException.WriteFailed` for any other `OSStatus`.
    private func keychainDelete(account: String) throws {
        let query = baseQuery(account: account)
        let status = shim.delete(query: query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw StorageException.WriteFailed(
                message: "Keychain delete failed for account '\(account)' with OSStatus: \(status)"
            )
        }
    }
}
