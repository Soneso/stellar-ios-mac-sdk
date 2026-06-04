//
//  OZSmartAccountAuthPayload.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// In-memory representation of the AuthPayload used by the OpenZeppelin Smart Account contract.
///
/// The signature payload is a Map-based named struct with two fields: `context_rule_ids` and
/// `signers`. The contract representation is:
///
/// ```
/// ScVal::Map([
///   { key: Symbol("context_rule_ids"), val: Vec([U32(id), ...]) },
///   { key: Symbol("signers"),
///     val: Map([{ key: signer.toScVal(), val: Bytes(sig) }, ...]) }
/// ])
/// ```
///
/// The `signers` map is mutable so callers and codecs can add or replace entries in place
/// before encoding back to an `SCValXDR`.
///
/// Thread-safety: instances are not thread-safe. Each payload is intended to be owned by
/// a single sign-then-encode sequence; do not share an instance across actor or task
/// boundaries while it is being mutated. Construct a new payload (copying the signer
/// entries and rule IDs) when crossing isolation boundaries.
public final class OZSmartAccountAuthPayload {

    /// Mutable list of signer entries.
    ///
    /// Each entry carries verifier-appropriate signature bytes: WebAuthn and Policy
    /// entries contain XDR-encoded `SCValXDR`; Ed25519 entries carry the raw
    /// 64-byte signature (no XDR wrapper). See `OZSmartAccountSignature.toAuthPayloadBytes()`.
    public var signers: [SignerEntry]

    /// Context rule IDs bound into the signing digest.
    public let contextRuleIds: [UInt32]

    public init(signers: [SignerEntry], contextRuleIds: [UInt32]) {
        self.signers = signers
        self.contextRuleIds = contextRuleIds
    }

    /// One key-value pair in the `signers` map of the AuthPayload.
    ///
    /// Stored as a list rather than a Swift dictionary so that codecs can preserve insertion
    /// order, perform deterministic upserts, and treat repeated insertions of the same key
    /// as in-place updates rather than reorderings. Swift protocol existentials
    /// (`any OZSmartAccountSigner`) cannot satisfy `Hashable`, which prevents using the signer
    /// as a dictionary key; the list-of-pairs form is the idiomatic Swift equivalent of a
    /// mutable signer-to-bytes map.
    ///
    /// The struct conforms to `Sendable` because both stored properties are Sendable:
    /// `OZSmartAccountSigner` is declared `: Sendable` and `Data` is unconditionally Sendable.
    /// Passing individual `SignerEntry` values across actor boundaries is safe; sharing the
    /// mutable `OZSmartAccountAuthPayload.signers` array across boundaries is not (see the
    /// thread-safety note on `OZSmartAccountAuthPayload`).
    public struct SignerEntry: Sendable {

        /// The signer for this entry.
        public let signer: any OZSmartAccountSigner

        /// The signature bytes for this signer, as stored in the on-wire `AuthPayload.signers`
        /// `Map<Signer, Bytes>` value. See ``OZSmartAccountSignature/toAuthPayloadBytes()``
        /// for the per-variant byte format.
        public let signatureBytes: Data

        public init(signer: any OZSmartAccountSigner, signatureBytes: Data) {
            self.signer = signer
            self.signatureBytes = signatureBytes
        }
    }
}

/// Codec for reading and writing `OZSmartAccountAuthPayload` to/from `SCValXDR`.
///
/// Handles the AuthPayload format accepted by the OpenZeppelin Smart Account contract,
/// which is a named struct (Map-based) with fields `context_rule_ids` and `signers`. The
/// outer struct map keys are inserted in alphabetical order (matching the Soroban Rust
/// `#[contracttype]` derive convention); the inner dynamic-Map signer entries are sorted
/// by lowercase-hex of their XDR-encoded keys so the encoding is deterministic.
public enum OZSmartAccountAuthPayloadCodec {

    /// Reads an `OZSmartAccountAuthPayload` from its `SCValXDR` representation.
    ///
    /// Accepts `SCValXDR.void` (returns an empty payload) or `SCValXDR.map` (the full
    /// payload). Throws when the input is not Void or Map, or when a signer entry has a
    /// value that is not a `Bytes` ScVal.
    ///
    /// - Parameter signatureScVal: The ScVal stored in the authorization entry credentials
    ///                             signature field.
    /// - Returns: The decoded `OZSmartAccountAuthPayload`.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when the input shape is wrong.
    public static func read(_ signatureScVal: SCValXDR) throws -> OZSmartAccountAuthPayload {
        switch signatureScVal {
        case .void:
            return OZSmartAccountAuthPayload(signers: [], contextRuleIds: [])
        case .map(let optionalEntries):
            let entries = optionalEntries ?? []
            var contextRuleIds: [UInt32] = []
            var signers: [OZSmartAccountAuthPayload.SignerEntry] = []
            for entry in entries {
                guard case .symbol(let keyName) = entry.key else {
                    // Skip non-Symbol keys; they cannot carry meaningful struct field names.
                    continue
                }
                switch keyName {
                case "context_rule_ids":
                    if case .vec(let optionalElements) = entry.val {
                        let elements = optionalElements ?? []
                        var ids: [UInt32] = []
                        for element in elements {
                            if case .u32(let value) = element {
                                ids.append(value)
                            }
                        }
                        contextRuleIds = ids
                    }
                case "signers":
                    if case .map(let optionalSignerEntries) = entry.val {
                        let signerEntries = optionalSignerEntries ?? []
                        for signerEntry in signerEntries {
                            let signer = try signerFromScVal(signerEntry.key)
                            guard case .bytes(let sigBytes) = signerEntry.val else {
                                throw SmartAccountTransactionException.signingFailed(
                                    reason: "Signer signature value is not encoded as Bytes in AuthPayload"
                                )
                            }
                            signers.append(
                                OZSmartAccountAuthPayload.SignerEntry(
                                    signer: signer,
                                    signatureBytes: sigBytes
                                )
                            )
                        }
                    }
                default:
                    // Unknown keys are ignored to remain forward-compatible.
                    break
                }
            }
            return OZSmartAccountAuthPayload(signers: signers, contextRuleIds: contextRuleIds)
        default:
            throw SmartAccountTransactionException.signingFailed(
                reason: "Smart account auth signature is not encoded as AuthPayload"
            )
        }
    }

    /// Writes an `OZSmartAccountAuthPayload` to its `SCValXDR` representation.
    ///
    /// Builds the outer map with exactly two entries in alphabetical insertion order
    /// (`context_rule_ids`, then `signers`), matching the Soroban Rust `#[contracttype]`
    /// derive ordering for the contract's `AuthPayload` struct. Inner signer entries are
    /// sorted by lowercase-hex of their XDR-encoded keys so the encoding is deterministic
    /// and the host-side dynamic-Map ordering check is satisfied.
    ///
    /// - Parameter payload: Payload to encode.
    /// - Returns: The `SCValXDR` representation of the payload.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when XDR encoding of a signer key fails.
    public static func write(_ payload: OZSmartAccountAuthPayload) throws -> SCValXDR {
        // Build signer map entries, wrapping each raw signature byte array in an
        // `SCValXDR.bytes` value before sorting.
        var signerEntries: [SCMapEntryXDR] = []
        signerEntries.reserveCapacity(payload.signers.count)
        for entry in payload.signers {
            let key: SCValXDR
            do {
                key = try entry.signer.toScVal()
            } catch {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Failed to convert signer to SCVal",
                    cause: error
                )
            }
            signerEntries.append(SCMapEntryXDR(key: key, val: .bytes(entry.signatureBytes)))
        }

        // Sort signer entries by lowercase-hex of their XDR-encoded key bytes. The hex
        // representation is monotone in the underlying byte sequence, so the resulting
        // order matches a raw byte lexicographic sort.
        let sortedSignerEntries: [SCMapEntryXDR]
        do {
            // Precompute the sort keys so the sort itself does not encode the same key
            // repeatedly and so encoding errors surface deterministically.
            var keyed: [(hex: String, entry: SCMapEntryXDR)] = []
            keyed.reserveCapacity(signerEntries.count)
            for entry in signerEntries {
                let encoded = try XDREncoder.encode(entry.key)
                let hex = Data(encoded).base16EncodedString()
                keyed.append((hex: hex, entry: entry))
            }
            keyed.sort { $0.hex < $1.hex }
            sortedSignerEntries = keyed.map { $0.entry }
        } catch {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Failed to XDR-encode signer key for sorting: \(error.localizedDescription)",
                cause: error
            )
        }

        let signersMapScVal: SCValXDR = .map(sortedSignerEntries)

        let ruleIdEntries: [SCValXDR] = payload.contextRuleIds.map { SCValXDR.u32($0) }
        let contextRuleIdsScVal: SCValXDR = .vec(ruleIdEntries)

        // Outer struct map keys insert in alphabetical order to match the Soroban Rust
        // `#[contracttype]` derive convention. Inner dynamic-map keys are sorted above by
        // XDR-byte order.
        let outerEntries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("context_rule_ids"), val: contextRuleIdsScVal),
            SCMapEntryXDR(key: .symbol("signers"), val: signersMapScVal)
        ]
        return .map(outerEntries)
    }

    /// Upserts a signer entry in the payload.
    ///
    /// If a signer matching `signer` already exists (compared by signer type and field
    /// values), the old entry is removed before the new one is appended. The payload's
    /// `signers` list is mutated in place.
    ///
    /// - Parameters:
    ///   - payload: Payload to update.
    ///   - signer: Signer to add or replace.
    ///   - signatureBytes: Signature bytes from `OZSmartAccountSignature.toAuthPayloadBytes()`.
    public static func upsertSigner(
        payload: OZSmartAccountAuthPayload,
        signer: any OZSmartAccountSigner,
        signatureBytes: Data
    ) {
        if let index = payload.signers.firstIndex(where: { OZSmartAccountBuilders.signersEqual($0.signer, signer) }) {
            payload.signers.remove(at: index)
        }
        payload.signers.append(
            OZSmartAccountAuthPayload.SignerEntry(signer: signer, signatureBytes: signatureBytes)
        )
    }

    /// Parses an `OZSmartAccountSigner` from its `SCValXDR` representation.
    ///
    /// Supported formats:
    /// - `Vec([Symbol("Delegated"), Address(...)])` returns an `OZDelegatedSigner`.
    /// - `Vec([Symbol("External"), Address(...), Bytes(...)])` returns an `OZExternalSigner`.
    ///
    /// - Parameter scVal: The ScVal to parse.
    /// - Returns: The parsed signer.
    /// - Throws: `SmartAccountTransactionException.SigningFailed` when the shape is unrecognised.
    public static func signerFromScVal(_ scVal: SCValXDR) throws -> any OZSmartAccountSigner {
        guard case .vec(let optionalElements) = scVal else {
            throw SmartAccountTransactionException.signingFailed(reason: "Signer ScVal is not a Vec")
        }
        guard let elements = optionalElements else {
            throw SmartAccountTransactionException.signingFailed(reason: "Signer ScVal Vec is null or empty")
        }
        if elements.isEmpty {
            throw SmartAccountTransactionException.signingFailed(reason: "Signer ScVal Vec is empty")
        }

        guard case .symbol(let tag) = elements[0] else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "First element of signer Vec is not a Symbol"
            )
        }

        switch tag {
        case "Delegated":
            if elements.count < 2 {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Delegated signer Vec must have at least 2 elements"
                )
            }
            guard case .address(let scAddress) = elements[1] else {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Delegated signer second element is not an Address"
                )
            }
            let addressStr = try addressString(from: scAddress)
            do {
                return try OZDelegatedSigner(address: addressStr)
            } catch {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "Delegated signer address is not a valid Stellar address: \(error.localizedDescription)",
                    cause: error
                )
            }
        case "External":
            if elements.count < 3 {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "External signer Vec must have at least 3 elements"
                )
            }
            guard case .address(let scAddress) = elements[1] else {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "External signer second element is not an Address"
                )
            }
            guard case .bytes(let keyData) = elements[2] else {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "External signer third element is not Bytes"
                )
            }
            let verifierAddress = try addressString(from: scAddress)
            do {
                return try OZExternalSigner(verifierAddress: verifierAddress, keyData: keyData)
            } catch {
                throw SmartAccountTransactionException.signingFailed(
                    reason: "External signer construction failed: \(error.localizedDescription)",
                    cause: error
                )
            }
        default:
            throw SmartAccountTransactionException.signingFailed(
                reason: "Unknown signer type tag: '\(tag)'"
            )
        }
    }

    // ========================================================================
    // Internal helpers
    // ========================================================================

    /// Converts an `SCAddressXDR` back to its strkey representation. Supports `G…` accounts
    /// and `C…` contracts (decoded from the 32-byte contract id).
    private static func addressString(from scAddress: SCAddressXDR) throws -> String {
        guard let address = OZAddressStrKey.fromXdr(scAddress) else {
            throw SmartAccountTransactionException.signingFailed(
                reason: "Unsupported signer address type"
            )
        }
        return address
    }
}
