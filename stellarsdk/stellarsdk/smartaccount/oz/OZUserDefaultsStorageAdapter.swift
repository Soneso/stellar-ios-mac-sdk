//
//  OZUserDefaultsStorageAdapter.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Persistent `OZStorageAdapter` backed by an isolated `UserDefaults` suite.
///
/// Stores credential and session payloads as UTF-8 JSON strings under stable
/// keys:
///
/// - `cred_<credentialId>` for individual stored credentials,
/// - `credential_index` for the JSON-encoded list of known credential IDs,
/// - `session_current` for the active session.
///
/// The adapter scopes every read and write to a `UserDefaults(suiteName:)`
/// instance so multiple adapter instances configured with different suites do
/// not interfere with one another. Stored credentials contain only public
/// key material plus metadata, so `UserDefaults` provides adequate isolation
/// for typical use cases. Applications requiring stronger at-rest protection
/// should use `OZKeychainStorageAdapter` instead.
///
/// Thread safety is provided by Swift Concurrency `actor` isolation, which
/// serializes all operations against the underlying `UserDefaults` instance.
///
/// Example:
/// ```swift
/// let storage = try OZUserDefaultsStorageAdapter()
/// try await storage.save(credential: credential)
/// let loaded = try await storage.get(credentialId: credential.credentialId)
/// ```
///
/// - Important: Not encrypted at rest. `UserDefaults` persists payloads to a
///   plaintext property-list file in the application container; on a
///   jailbroken device or via an unencrypted iTunes/Finder backup, the
///   contents are recoverable. The credentials persisted by this adapter
///   contain only public-key material and non-secret metadata; applications
///   storing session data or anything sensitive should use
///   `OZKeychainStorageAdapter` instead.
public final actor OZUserDefaultsStorageAdapter: OZStorageAdapter {

    // ========================================================================
    // Companion Constants
    // ========================================================================

    /// Default suite name passed to `UserDefaults(suiteName:)`.
    ///
    /// Consumers can override this via the initializer to scope the adapter to
    /// a different suite — useful when multiple isolated stores must coexist
    /// within the same process.
    public static let defaultSuiteName: String = "com.soneso.stellar.smartaccount"

    // ========================================================================
    // State
    // ========================================================================

    /// `UserDefaults` instance scoped to the configured suite name.
    private let defaults: UserDefaults

    // ========================================================================
    // Initialization
    // ========================================================================

    /// Initializes a new `OZUserDefaultsStorageAdapter` scoped to `suiteName`.
    ///
    /// - Parameter suiteName: Name of the `UserDefaults` suite to use as the
    ///   backing store. Defaults to
    ///   `OZUserDefaultsStorageAdapter.defaultSuiteName`.
    /// - Throws: `SmartAccountStorageException.WriteFailed` when
    ///   `UserDefaults(suiteName:)` returns `nil`. This happens when the
    ///   supplied suite name is reserved (for example the empty string) or
    ///   otherwise rejected by the system.
    public init(suiteName: String = OZUserDefaultsStorageAdapter.defaultSuiteName) throws {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw SmartAccountStorageException.WriteFailed(
                message: "Failed to create UserDefaults with suite: \(suiteName)"
            )
        }
        self.defaults = defaults
    }

    // ========================================================================
    // OZStorageAdapter — Credential Operations
    // ========================================================================

    public func save(credential: OZStoredCredential) async throws {
        do {
            let serializable = credential.toSerializable()
            let jsonString = try encodeToString(serializable)
            let key = OZStorageKeys.credentialKeyPrefix + credential.credentialId

            defaults.set(jsonString, forKey: key)

            // Append the credential ID to the index when not already present so
            // enumeration via the index entry stays consistent with stored
            // items.
            let index = try readIndex()
            if !index.ids.contains(credential.credentialId) {
                let updated = CredentialIndex(ids: index.ids + [credential.credentialId])
                try writeIndex(updated)
            }
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.WriteFailed(
                message: "Storage write failed for key: \(credential.credentialId)",
                cause: error
            )
        }
    }

    public func get(credentialId: String) async throws -> OZStoredCredential? {
        do {
            return try readCredential(credentialId)
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.ReadFailed(
                message: "Storage read failed for key: \(credentialId)",
                cause: error
            )
        }
    }

    public func getByContract(contractId: String) async throws -> [OZStoredCredential] {
        do {
            let index = try readIndex()
            var matches: [OZStoredCredential] = []
            for id in index.ids {
                if let credential = try readCredential(id), credential.contractId == contractId {
                    matches.append(credential)
                }
            }
            return matches
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.ReadFailed(
                message: "Storage read failed for contract: \(contractId)",
                cause: error
            )
        }
    }

    public func getAll() async throws -> [OZStoredCredential] {
        do {
            let index = try readIndex()
            var all: [OZStoredCredential] = []
            for id in index.ids {
                if let credential = try readCredential(id) {
                    all.append(credential)
                }
            }
            return all
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.ReadFailed(
                message: "Storage read failed for key: all credentials",
                cause: error
            )
        }
    }

    public func delete(credentialId: String) async throws {
        do {
            let key = OZStorageKeys.credentialKeyPrefix + credentialId
            defaults.removeObject(forKey: key)

            // Shrink the index even when the credential entry was already
            // missing — the index must not retain stale IDs.
            let index = try readIndex()
            let updated = CredentialIndex(ids: index.ids.filter { $0 != credentialId })
            try writeIndex(updated)
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.WriteFailed(
                message: "Storage write failed for key: \(credentialId)",
                cause: error
            )
        }
    }

    public func update(credentialId: String, updates: OZStoredCredentialUpdate) async throws {
        do {
            guard let existing = try readCredential(credentialId) else {
                throw SmartAccountCredentialException.notFound(credentialId: credentialId)
            }
            let updated = existing.applyUpdate(updates)

            let serializable = updated.toSerializable()
            let jsonString = try encodeToString(serializable)
            let key = OZStorageKeys.credentialKeyPrefix + credentialId

            defaults.set(jsonString, forKey: key)
        } catch let error as SmartAccountCredentialException {
            throw error
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.WriteFailed(
                message: "Storage write failed for key: \(credentialId)",
                cause: error
            )
        }
    }

    public func clear() async throws {
        do {
            let index = try readIndex()
            for id in index.ids {
                defaults.removeObject(forKey: OZStorageKeys.credentialKeyPrefix + id)
            }
            defaults.removeObject(forKey: OZStorageKeys.credentialIndexKey)
            defaults.removeObject(forKey: OZStorageKeys.sessionKey)
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.WriteFailed(
                message: "Storage write failed for key: clear all",
                cause: error
            )
        }
    }

    // ========================================================================
    // OZStorageAdapter — Session Operations
    // ========================================================================

    public func saveSession(_ session: OZStoredSession) async throws {
        do {
            let serializable = session.toSerializable()
            let jsonString = try encodeToString(serializable)
            defaults.set(jsonString, forKey: OZStorageKeys.sessionKey)
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.WriteFailed(
                message: "Storage write failed for key: session",
                cause: error
            )
        }
    }

    public func getSession() async throws -> OZStoredSession? {
        do {
            guard let jsonString = defaults.string(forKey: OZStorageKeys.sessionKey) else {
                return nil
            }
            let serializable = try decodeFromString(SerializableSession.self, jsonString)
            let session = serializable.toStoredSession()

            // why: an expired session is treated as if no session exists; it is
            // also dropped from storage on read so a subsequent read does not
            // need to re-evaluate expiry against the same stale entry. Callers
            // receive the simple "valid session OR nil" contract.
            if session.isExpired {
                defaults.removeObject(forKey: OZStorageKeys.sessionKey)
                return nil
            }
            return session
        } catch let error as SmartAccountStorageException {
            throw error
        } catch {
            throw SmartAccountStorageException.ReadFailed(
                message: "Storage read failed for key: session",
                cause: error
            )
        }
    }

    public func clearSession() async throws {
        defaults.removeObject(forKey: OZStorageKeys.sessionKey)
    }

    // ========================================================================
    // Internal Helpers — Credential I/O
    // ========================================================================

    /// Reads and decodes a single credential by ID. Returns `nil` when the
    /// underlying entry does not exist. Must be called from within the actor's
    /// serialized context.
    private func readCredential(_ credentialId: String) throws -> OZStoredCredential? {
        let key = OZStorageKeys.credentialKeyPrefix + credentialId
        guard let jsonString = defaults.string(forKey: key) else {
            return nil
        }
        let serializable = try decodeFromString(SerializableCredential.self, jsonString)
        return try serializable.toStoredCredential()
    }

    /// Reads the credential ID index, returning an empty index when absent.
    /// Must be called from within the actor's serialized context.
    private func readIndex() throws -> CredentialIndex {
        guard let jsonString = defaults.string(forKey: OZStorageKeys.credentialIndexKey) else {
            return CredentialIndex(ids: [])
        }
        return try decodeFromString(CredentialIndex.self, jsonString)
    }

    /// Persists the credential ID index. Must be called from within the actor's
    /// serialized context.
    private func writeIndex(_ index: CredentialIndex) throws {
        let jsonString = try encodeToString(index)
        defaults.set(jsonString, forKey: OZStorageKeys.credentialIndexKey)
    }
}
