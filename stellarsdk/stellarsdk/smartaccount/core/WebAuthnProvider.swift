//
//  WebAuthnProvider.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

// MARK: - Constant-time byte comparison (file-private; used by DTO equality below)

/// Constant-time byte equality for two `Data` values.
///
/// Length comparison short-circuits (length is not a secret in the WebAuthn DTO threat model),
/// then a fixed-time XOR-OR loop accumulates per-byte differences so the runtime does not
/// reveal which byte index differs.
///
/// - Parameters:
///   - a: First byte buffer.
///   - b: Second byte buffer.
/// - Returns: `true` when `a` and `b` are byte-identical; `false` otherwise.
private func constantTimeEquals(_ a: Data, _ b: Data) -> Bool {
    if a.count != b.count { return false }

    var acc: UInt8 = 0
    let aBase = a.startIndex
    let bBase = b.startIndex
    for i in 0..<a.count {
        acc |= a[aBase + i] ^ b[bBase + i]
    }
    return acc == 0
}

/// Combines per-field constant-time comparison results without short-circuiting at the
/// boolean-AND layer.
///
/// Built on bitwise `&` over `UInt8` so all four flags are evaluated unconditionally,
/// matching the constant-time guarantee at the per-field byte comparison.
private func combineConstantTime(_ flags: Bool...) -> Bool {
    var acc: UInt8 = 1
    for f in flags {
        acc &= f ? 1 : 0
    }
    return acc == 1
}

// MARK: - WebAuthnAuthenticationResult

/// WebAuthn authentication result from a passkey ceremony.
///
/// Contains the complete attestation data required to verify biometric or security-key
/// authentication. The `signature` field is in DER format; normalize it to a 64-byte compact
/// low-S signature via `SmartAccountUtils.normalizeSignature` before on-chain submission.
public struct WebAuthnAuthenticationResult: Equatable, Hashable, Sendable {

    /// WebAuthn credential identifier (raw bytes).
    public let credentialId: Data

    /// Raw authenticator data bytes from the WebAuthn assertion ceremony.
    public let authenticatorData: Data

    /// Raw `clientDataJSON` bytes from the WebAuthn assertion ceremony.
    public let clientDataJSON: Data

    /// ECDSA signature in DER format produced by the authenticator over the
    /// `authenticatorData || sha256(clientDataJSON)` payload.
    public let signature: Data

    public init(
        credentialId: Data,
        authenticatorData: Data,
        clientDataJSON: Data,
        signature: Data
    ) {
        self.credentialId = credentialId
        self.authenticatorData = authenticatorData
        self.clientDataJSON = clientDataJSON
        self.signature = signature
    }

    /// All four `Data` fields use constant-time byte comparison via `constantTimeEquals`;
    /// see `Data.constantTimeEquals` for the timing-attack rationale.
    public static func == (lhs: WebAuthnAuthenticationResult, rhs: WebAuthnAuthenticationResult) -> Bool {
        let a = constantTimeEquals(lhs.credentialId, rhs.credentialId)
        let b = constantTimeEquals(lhs.authenticatorData, rhs.authenticatorData)
        let c = constantTimeEquals(lhs.clientDataJSON, rhs.clientDataJSON)
        let d = constantTimeEquals(lhs.signature, rhs.signature)
        return combineConstantTime(a, b, c, d)
    }

    /// Hashes all four byte fields. `Hasher.combine(Data)` hashes byte content.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(credentialId)
        hasher.combine(authenticatorData)
        hasher.combine(clientDataJSON)
        hasher.combine(signature)
    }
}

// MARK: - WebAuthnRegistrationResult

/// WebAuthn registration result from a passkey creation ceremony.
///
/// Contains the public key and credential information needed to deploy a smart-account
/// contract, plus optional metadata about the authenticator and passkey characteristics.
///
/// **Primary path:** providers populate `publicKey` directly with the 65-byte uncompressed
/// secp256r1 key (`0x04 || X || Y`). Most platform WebAuthn APIs expose the public key via
/// `getPublicKey()` or equivalent.
///
/// **Fallback:** if the provider cannot extract the public key directly, supply the raw bytes
/// in `publicKey` along with `attestationObject`. Pass the result to
/// `SmartAccountUtils.extractPublicKeyFromRegistration`, which tries direct validation,
/// authenticator-data parsing, and attestation-object pattern matching in order.
public struct WebAuthnRegistrationResult: Equatable, Hashable, Sendable {

    /// WebAuthn credential identifier (raw bytes).
    public let credentialId: Data

    /// Uncompressed secp256r1 public key (65 bytes, starting with `0x04`), or the raw bytes
    /// returned by the platform WebAuthn API when direct extraction is not possible.
    public let publicKey: Data

    /// Raw attestation object from the WebAuthn registration ceremony.
    public let attestationObject: Data

    /// Authenticator transport hints (e.g. `usb`, `nfc`, `ble`, `internal`). Optional.
    public let transports: [String]?

    /// `singleDevice` for hardware security keys or `multiDevice` for synced / cloud-backed
    /// passkeys. `nil` when device type cannot be determined.
    public let deviceType: String?

    /// Whether the passkey is backed up or synced to a cloud provider. `nil` when backup
    /// state cannot be determined.
    public let backedUp: Bool?

    public init(
        credentialId: Data,
        publicKey: Data,
        attestationObject: Data,
        transports: [String]? = nil,
        deviceType: String? = nil,
        backedUp: Bool? = nil
    ) {
        self.credentialId = credentialId
        self.publicKey = publicKey
        self.attestationObject = attestationObject
        self.transports = transports
        self.deviceType = deviceType
        self.backedUp = backedUp
    }

    /// The three `Data` fields (`credentialId`, `publicKey`, `attestationObject`) use
    /// constant-time comparison via `constantTimeEquals`; optional scalar/list fields use
    /// ordinary value equality. See `Data.constantTimeEquals` for the timing-attack rationale.
    public static func == (lhs: WebAuthnRegistrationResult, rhs: WebAuthnRegistrationResult) -> Bool {
        let a = constantTimeEquals(lhs.credentialId, rhs.credentialId)
        let b = constantTimeEquals(lhs.publicKey, rhs.publicKey)
        let c = constantTimeEquals(lhs.attestationObject, rhs.attestationObject)
        let bytesEqual = combineConstantTime(a, b, c)
        return bytesEqual
            && lhs.transports == rhs.transports
            && lhs.deviceType == rhs.deviceType
            && lhs.backedUp == rhs.backedUp
    }

    /// Hashes all six fields. `Data` fields are hashed by byte content.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(credentialId)
        hasher.combine(publicKey)
        hasher.combine(attestationObject)
        hasher.combine(transports)
        hasher.combine(deviceType)
        hasher.combine(backedUp)
    }
}

// MARK: - WebAuthnProvider

/// Platform-specific WebAuthn provider interface.
///
/// Implementations trigger platform biometric / security-key prompts, handle WebAuthn
/// credential creation and assertion, and return properly formatted byte-array results.
///
/// `Sendable` is required because the protocol crosses actor / task boundaries when invoked
/// from the smart-account transaction pipeline.
///
/// Errors thrown from `register` or `authenticate` are subclasses of `WebAuthnException`
/// (defined in the smart-account error module): `RegistrationFailed`, `AuthenticationFailed`,
/// `NotSupported`, or `Cancelled`.
///
/// Example:
/// ```swift
/// let provider: WebAuthnProvider = MyApplePasskeyProvider()
/// let registration = try await provider.register(
///     challenge: challenge,
///     userId: userIdBytes,
///     userName: "user@example.com"
/// )
/// ```
public protocol WebAuthnProvider: Sendable {

    /// Registers a new WebAuthn credential (passkey creation).
    ///
    /// Triggers the platform's credential-creation flow, prompts the user to create a new
    /// passkey using biometric authentication or a security key, generates a secp256r1
    /// keypair and credential ID, and returns the public key plus attestation data.
    ///
    /// The challenge MUST be used as-is in the registration request — it is a cryptographic
    /// hash that binds the credential to the smart-account deployment.
    ///
    /// - Parameters:
    ///   - challenge: Challenge bytes to sign (typically 32 bytes).
    ///   - userId: User identifier bytes (typically random; used for discoverable credentials).
    ///   - userName: User-friendly name for the credential.
    /// - Returns: A `WebAuthnRegistrationResult` containing credential ID, public key, and
    ///   attestation data.
    /// - Throws: `WebAuthnException.RegistrationFailed`, `WebAuthnException.Cancelled`, or
    ///   `WebAuthnException.NotSupported`.
    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult

    /// Authenticates with an existing WebAuthn credential (passkey assertion).
    ///
    /// Triggers the platform's credential-assertion flow, prompts the user to authenticate,
    /// signs the challenge with the private key, and returns the signature plus
    /// authenticator data.
    ///
    /// The challenge MUST be used as-is in the authentication request — it is the
    /// authorization-payload hash that authorizes the transaction.
    ///
    /// - Parameters:
    ///   - challenge: Challenge bytes to sign (typically the 32-byte authorization-payload hash).
    ///   - allowCredentials: Optional list of credential descriptors with transport hints.
    ///     Constrains which passkey the authenticator uses and indicates how the client can
    ///     reach the authenticator. When `nil`, discoverable-credential selection is used —
    ///     the user picks which passkey to use. Including transport hints (e.g., `hybrid`)
    ///     enables cross-device authentication flows such as QR-code scanning.
    /// - Returns: A `WebAuthnAuthenticationResult` containing signature and assertion data.
    /// - Throws: `WebAuthnException.AuthenticationFailed`, `WebAuthnException.Cancelled`, or
    ///   `WebAuthnException.NotSupported`.
    func authenticate(
        challenge: Data,
        allowCredentials: [AllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult
}
