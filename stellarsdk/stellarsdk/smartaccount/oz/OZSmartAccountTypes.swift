//
//  OZSmartAccountTypes.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// ============================================================================
// Signer Types
// ============================================================================

/// Represents a signer that can authorize OpenZeppelin Smart Account transactions.
///
/// Smart account signers describe who can authorize transactions on the wallet contract.
/// Two concrete signer types exist:
/// - `OZDelegatedSigner`: A Soroban address (`G…` for accounts or `C…` for contracts) using
///   the host's built-in `require_auth` verification.
/// - `OZExternalSigner`: A verifier-contract address combined with public-key bytes that
///   describe a custom signature scheme (e.g. WebAuthn / secp256r1, Ed25519).
///
/// Example:
/// ```swift
/// let delegated = try OZDelegatedSigner(address: "GA7Q...")
/// let webAuthn = try OZExternalSigner.webAuthn(
///     verifierAddress: "CBCD...",
///     publicKey: publicKeyBytes,
///     credentialId: credentialIdBytes
/// )
/// let scVal = try delegated.toScVal()
/// ```
public protocol OZSmartAccountSigner: Sendable {

    /// Converts this signer to its on-chain `SCValXDR` representation for contract calls.
    ///
    /// - Returns: An `SCValXDR` describing the signer in the format the wallet contract expects.
    /// - Throws: `ValidationException.InvalidInput` if conversion fails (for example, when
    ///   address strkey decoding fails).
    func toScVal() throws -> SCValXDR

    /// Stable string identifying this signer for deduplication and lookup.
    ///
    /// Format varies by signer type:
    /// - Delegated: `"delegated:<address>"`
    /// - External: `"external:<verifierAddress>:<keyDataHex>"`
    var uniqueKey: String { get }
}

// ============================================================================
// OZDelegatedSigner
// ============================================================================

/// A signer authorized through a Soroban address using the host's `require_auth` mechanism.
///
/// Delegated signers are Stellar accounts (`G…` strkey) or smart contracts (`C…` strkey) that
/// use the native Soroban authorization mechanism. The wallet contract calls
/// `require_auth_for_args()` on the address to verify authorization, so no custom
/// signature-verification logic is required.
///
/// Example:
/// ```swift
/// let accountSigner = try OZDelegatedSigner(address: "GA7QYNF7SOWQ...")
/// let contractSigner = try OZDelegatedSigner(address: "CBCD1234...")
/// ```
public struct OZDelegatedSigner: OZSmartAccountSigner, Equatable, Hashable {

    /// The Stellar address of the signer (`G…` for accounts, `C…` for contracts).
    public let address: String

    /// Initializes a new `OZDelegatedSigner`.
    ///
    /// - Parameter address: The Stellar address of the signer; must be a valid `G…` strkey
    ///   or `C…` strkey.
    /// - Throws: `ValidationException.InvalidAddress` when `address` is neither a valid
    ///   Ed25519 public key strkey nor a valid contract id strkey.
    public init(address: String) throws {
        if !address.isValidEd25519PublicKey() && !address.isValidContractId() {
            throw ValidationException.invalidAddress(
                address: "Address must be a valid Stellar address (G... or C...), got: \(address)"
            )
        }
        self.address = address
    }

    /// Converts the delegated signer to its on-chain representation.
    ///
    /// Returns an `SCValXDR.vec([Symbol("Delegated"), Address(address)])`.
    ///
    /// - Returns: The `SCValXDR` representation of this signer.
    /// - Throws: `ValidationException.InvalidInput` if the address cannot be encoded into
    ///   an `SCAddressXDR`.
    public func toScVal() throws -> SCValXDR {
        do {
            let scAddress: SCAddressXDR
            if address.isValidEd25519PublicKey() {
                scAddress = try SCAddressXDR(accountId: address)
            } else {
                scAddress = try SCAddressXDR(contractId: address)
            }
            let elements: [SCValXDR] = [
                .symbol("Delegated"),
                .address(scAddress)
            ]
            return .vec(elements)
        } catch {
            throw ValidationException.InvalidInput(
                message: "Failed to convert OZDelegatedSigner to ScVal: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Unique identifier for deduplication, formatted as `"delegated:<address>"`.
    public var uniqueKey: String { "delegated:\(address)" }
}

// ============================================================================
// OZExternalSigner
// ============================================================================

/// A signer that delegates signature verification to a custom verifier contract.
///
/// External signers point at a verifier contract (`C…` strkey) and carry the public-key
/// bytes (and any auxiliary authentication data) the verifier needs. This enables
/// non-native signature schemes such as WebAuthn (secp256r1) and Ed25519 to drive Smart
/// Account authorization.
///
/// Use the `webAuthn` and `ed25519` factory methods for the two well-known schemes; the
/// raw initializer is available when integrating with a custom verifier.
///
/// Example:
/// ```swift
/// let webAuthn = try OZExternalSigner.webAuthn(
///     verifierAddress: "CBCD1234...",
///     publicKey: secp256r1PublicKey,
///     credentialId: credentialId
/// )
/// let ed25519 = try OZExternalSigner.ed25519(
///     verifierAddress: "CDEF5678...",
///     publicKey: ed25519PublicKey
/// )
/// ```
public struct OZExternalSigner: OZSmartAccountSigner, Equatable, Hashable {

    /// Contract address (`C…` strkey) of the signature verifier.
    public let verifierAddress: String

    /// Public-key bytes plus any auxiliary authentication data (for example, a WebAuthn
    /// credential id appended to the public key).
    public let keyData: Data

    /// Initializes a new `OZExternalSigner` with raw verifier address and key data.
    ///
    /// Most callers should prefer the `webAuthn` or `ed25519` factories, which validate the
    /// concrete public-key format before constructing the signer.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the signature verifier.
    ///   - keyData: Public-key bytes plus any auxiliary authentication data; must not be empty.
    /// - Throws: `ValidationException.InvalidAddress` if `verifierAddress` is not a valid
    ///   contract strkey; `ValidationException.InvalidInput` if `keyData` is empty.
    public init(verifierAddress: String, keyData: Data) throws {
        if !verifierAddress.isValidContractId() {
            throw ValidationException.invalidAddress(
                address: "Verifier address must be a valid contract address (C...), got: \(verifierAddress)"
            )
        }
        if keyData.isEmpty {
            throw ValidationException.invalidInput(field: "keyData", reason: "Key data cannot be empty")
        }
        self.verifierAddress = verifierAddress
        self.keyData = keyData
    }

    /// Converts the external signer to its on-chain representation.
    ///
    /// Returns an `SCValXDR.vec([Symbol("External"), Address(verifierAddress), Bytes(keyData)])`.
    ///
    /// - Returns: The `SCValXDR` representation of this signer.
    /// - Throws: `ValidationException.InvalidInput` if the verifier address cannot be encoded
    ///   into an `SCAddressXDR`.
    public func toScVal() throws -> SCValXDR {
        do {
            let scAddress = try SCAddressXDR(contractId: verifierAddress)
            let elements: [SCValXDR] = [
                .symbol("External"),
                .address(scAddress),
                .bytes(keyData)
            ]
            return .vec(elements)
        } catch {
            throw ValidationException.InvalidInput(
                message: "Failed to convert OZExternalSigner to ScVal: \(error.localizedDescription)",
                cause: error
            )
        }
    }

    /// Unique identifier for deduplication, formatted as `"external:<verifierAddress>:<keyDataHex>"`.
    public var uniqueKey: String {
        "external:\(verifierAddress):\(keyData.base16EncodedString())"
    }

    /// Equality implemented with constant-time comparison over `keyData` to avoid leaking
    /// information about the byte content through a timing side channel.
    ///
    /// - Parameters:
    ///   - lhs: The first signer to compare.
    ///   - rhs: The second signer to compare.
    /// - Returns: `true` when both `verifierAddress` and `keyData` match.
    public static func == (lhs: OZExternalSigner, rhs: OZExternalSigner) -> Bool {
        let addressMatch = lhs.verifierAddress == rhs.verifierAddress
        let keyMatch = OZExternalSigner.constantTimeEquals(lhs.keyData, rhs.keyData)
        // Use bitwise AND (Bool conversion via Int) to avoid short-circuit evaluation,
        // so both comparisons always run regardless of the address result.
        return (addressMatch ? 1 : 0) & (keyMatch ? 1 : 0) == 1
    }

    /// Hashes the signer using content-based hashing of `keyData` so two signers with
    /// equal byte contents hash identically.
    ///
    /// - Parameter hasher: The hasher to feed.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(verifierAddress)
        hasher.combine(keyData)
    }

    /// Creates a WebAuthn external signer using an uncompressed secp256r1 public key.
    ///
    /// The resulting signer's `keyData` is `publicKey || credentialId`, matching the layout
    /// expected by WebAuthn verifier contracts.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the WebAuthn verifier.
    ///   - publicKey: Uncompressed secp256r1 public key (`SmartAccountConstants.secp256r1PublicKeySize`
    ///     bytes; first byte must equal `SmartAccountConstants.uncompressedPubkeyPrefix`).
    ///   - credentialId: WebAuthn credential identifier; must not be empty.
    /// - Returns: An `OZExternalSigner` configured for WebAuthn signature verification.
    /// - Throws:
    ///   - `ValidationException.InvalidInput` if `publicKey` is the wrong size, has the
    ///     wrong leading byte, or `credentialId` is empty.
    ///   - `ValidationException.InvalidAddress` if `verifierAddress` is not a valid `C…` strkey.
    public static func webAuthn(
        verifierAddress: String,
        publicKey: Data,
        credentialId: Data
    ) throws -> OZExternalSigner {
        if publicKey.count != SmartAccountConstants.secp256r1PublicKeySize {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "WebAuthn public key must be \(SmartAccountConstants.secp256r1PublicKeySize) bytes (uncompressed secp256r1), got: \(publicKey.count)"
            )
        }
        if publicKey[publicKey.startIndex] != SmartAccountConstants.uncompressedPubkeyPrefix {
            let firstByteHex = String(format: "%02x", publicKey[publicKey.startIndex])
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "WebAuthn public key must start with 0x04 (uncompressed format), got: 0x\(firstByteHex)"
            )
        }
        if credentialId.isEmpty {
            throw ValidationException.invalidInput(field: "credentialId", reason: "WebAuthn credential ID cannot be empty")
        }
        var keyData = Data()
        keyData.append(publicKey)
        keyData.append(credentialId)
        return try OZExternalSigner(verifierAddress: verifierAddress, keyData: keyData)
    }

    /// Creates an Ed25519 external signer using a 32-byte Ed25519 public key.
    ///
    /// - Parameters:
    ///   - verifierAddress: Contract address (`C…` strkey) of the Ed25519 verifier.
    ///   - publicKey: Ed25519 public key (`SmartAccountConstants.ed25519PublicKeySize` bytes).
    /// - Returns: An `OZExternalSigner` configured for Ed25519 signature verification.
    /// - Throws:
    ///   - `ValidationException.InvalidInput` if `publicKey` is not 32 bytes long.
    ///   - `ValidationException.InvalidAddress` if `verifierAddress` is not a valid `C…` strkey.
    public static func ed25519(
        verifierAddress: String,
        publicKey: Data
    ) throws -> OZExternalSigner {
        if publicKey.count != SmartAccountConstants.ed25519PublicKeySize {
            throw ValidationException.invalidInput(
                field: "publicKey",
                reason: "Ed25519 public key must be \(SmartAccountConstants.ed25519PublicKeySize) bytes, got: \(publicKey.count)"
            )
        }
        return try OZExternalSigner(verifierAddress: verifierAddress, keyData: publicKey)
    }

    /// Constant-time byte comparison.
    ///
    /// Folds a length-difference flag with the XOR of every byte pair across the common
    /// prefix into a single accumulator, so the comparison cost does not depend on where
    /// the first differing byte sits. This avoids leaking information about cryptographic
    /// key contents through timing measurements. The length-difference flag is a Boolean
    /// indicator (0 or 1) rather than a narrowed XOR of the lengths, which both keeps the
    /// helper trap-free for any input sizes and prevents two different-length inputs from
    /// collapsing to a zero-difference accumulator through integer overflow truncation.
    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        var diff: UInt8 = (lhs.count == rhs.count) ? 0 : 1
        let length = min(lhs.count, rhs.count)
        let lhsStart = lhs.startIndex
        let rhsStart = rhs.startIndex
        for i in 0..<length {
            diff |= lhs[lhsStart + i] ^ rhs[rhsStart + i]
        }
        return diff == 0
    }
}

// ============================================================================
// Submission Method
// ============================================================================

/// Determines how a Smart Account transaction is submitted to the network.
///
/// By default, the SDK submits via the relayer when one is configured and falls back to
/// direct RPC submission otherwise. Pass an explicit `SubmissionMethod` to a transaction
/// method's `forceMethod` parameter to override this default for a single call.
///
/// Example:
/// ```swift
/// let result = try await txOps.transfer(
///     tokenContract: "CBCD...",
///     recipient: "GA7Q...",
///     amount: "10",
///     forceMethod: .rpc
/// )
/// ```
public enum SubmissionMethod: Sendable {

    /// Submit via the relayer proxy for fee-sponsored transactions. Fails if no relayer is
    /// configured.
    case relayer

    /// Submit directly via Soroban RPC. Always available.
    case rpc
}
