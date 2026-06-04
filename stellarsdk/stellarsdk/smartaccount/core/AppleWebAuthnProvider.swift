//
//  AppleWebAuthnProvider.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
import AuthenticationServices

// ============================================================================
// AppleWebAuthnProvider
// ============================================================================

/// Apple-platform `WebAuthnProvider` backed by `ASAuthorizationPlatformPublicKeyCredentialProvider`.
///
/// Provides passkey registration (secp256r1 key creation via Touch ID / Face ID) and
/// assertion (passkey signing) for iOS 16+ and macOS 13+. Returns
/// ``WebAuthnRegistrationResult`` and ``WebAuthnAuthenticationResult`` respectively.
///
/// On macOS set `presentationContextProvider` before calling `register` or `authenticate`;
/// the system requires a host window reference. iOS handles presentation automatically.
///
/// The host application must declare an `Associated Domains` entitlement
/// (`webcredentials:<rpId>`) and publish a matching AASA file.
/// See `docs/smart-accounts/webauthn-ios.md` for setup details.
///
/// Example:
/// ```swift
/// let provider = try AppleWebAuthnProvider(
///     rpId: "wallet.example.com",
///     rpName: "Example Smart Wallet"
/// )
/// let registration = try await provider.register(
///     challenge: challenge32Bytes,
///     userId: userIdBytes,
///     userName: "user@example.com"
/// )
/// ```
@available(iOS 16.0, macOS 13.0, *)
public final class AppleWebAuthnProvider: NSObject, WebAuthnProvider, @unchecked Sendable {

    // ========================================================================
    // Public Properties
    // ========================================================================

    /// Default operation timeout in milliseconds (60 seconds), used when no
    /// explicit `timeout` is supplied to the initializer or factory.
    public static let defaultTimeoutMs: Int64 = 60_000

    /// WebAuthn Relying Party identifier. Must match an `Associated Domains`
    /// entitlement entry in the host application.
    public let rpId: String

    /// Human-readable Relying Party name displayed during passkey prompts.
    public let rpName: String

    /// Operation timeout in milliseconds. Applied to both `register` and
    /// `authenticate`; when exceeded, the call throws
    /// `WebAuthnException.RegistrationFailed` or
    /// `WebAuthnException.AuthenticationFailed` respectively.
    public let timeout: Int64

    /// Optional presentation context provider for the underlying
    /// `ASAuthorizationController`.
    ///
    /// On macOS, `ASAuthorizationController` requires a context provider to
    /// supply the window in which to display the passkey UI. Without it the
    /// system fails the request with ASAuthorizationError code 1004. On iOS
    /// the system handles presentation automatically and this property may
    /// remain `nil`.
    ///
    /// The provider holds a strong reference; assign before invoking `register`
    /// or `authenticate`. This property is not guarded by `delegateLock`, so
    /// mutating it concurrently with an in-flight call is undefined behavior.
    public var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?

    // ========================================================================
    // Internal State
    // ========================================================================

    /// Strong reference to the active authorization delegate.
    ///
    /// `ASAuthorizationController` retains its delegate weakly, so the
    /// provider must hold the delegate alive for the duration of the
    /// in-flight request. Cleared in both the success and error paths to
    /// avoid leaks. Mutation is serialized via `delegateLock`.
    private var activeDelegate: AuthorizationDelegate?

    /// Lock guarding mutation of `activeDelegate`. The provider itself is
    /// `@unchecked Sendable`; concurrent calls into `register` /
    /// `authenticate` from different actors would otherwise race on the
    /// stored property.
    private let delegateLock = NSLock()

    // ========================================================================
    // Initialization
    // ========================================================================

    /// Initializes a new `AppleWebAuthnProvider`.
    ///
    /// - Parameters:
    ///   - rpId: WebAuthn Relying Party identifier. Must be non-blank.
    ///   - rpName: Human-readable RP name shown during passkey prompts. Must
    ///     be non-blank.
    ///   - timeout: Operation timeout in milliseconds. Must be strictly
    ///     positive. Defaults to `defaultTimeoutMs` (60000).
    /// - Throws: `SmartAccountConfigurationException.InvalidConfig` when any input fails
    ///   validation.
    public init(
        rpId: String,
        rpName: String,
        timeout: Int64 = AppleWebAuthnProvider.defaultTimeoutMs
    ) throws {
        if rpId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SmartAccountConfigurationException.invalidConfig(details: "rpId must not be blank")
        }
        if rpName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SmartAccountConfigurationException.invalidConfig(details: "rpName must not be blank")
        }
        if timeout <= 0 {
            throw SmartAccountConfigurationException.invalidConfig(details: "timeout must be positive")
        }
        self.rpId = rpId
        self.rpName = rpName
        self.timeout = timeout
        super.init()
    }

    /// Throwing convenience factory equivalent to `init(rpId:rpName:timeout:)`.
    ///
    /// - Parameters:
    ///   - rpId: WebAuthn Relying Party identifier.
    ///   - rpName: Human-readable RP name.
    ///   - timeout: Operation timeout in milliseconds. Defaults to
    ///     `defaultTimeoutMs`.
    /// - Returns: A new configured `AppleWebAuthnProvider`.
    /// - Throws: `SmartAccountConfigurationException.InvalidConfig` for invalid inputs.
    public static func create(
        rpId: String,
        rpName: String,
        timeout: Int64 = AppleWebAuthnProvider.defaultTimeoutMs
    ) throws -> AppleWebAuthnProvider {
        return try AppleWebAuthnProvider(rpId: rpId, rpName: rpName, timeout: timeout)
    }

    // ========================================================================
    // WebAuthnProvider — Registration
    // ========================================================================

    public func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: rpId
        )
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: userName,
            userID: userId
        )
        // userVerificationPreference left at system default: the UV bit is checked at
        // assertion time (see below), not here. Requesting .direct attestation would
        // break iOS Simulator registration (its authenticators cannot produce statements).

        let authorization = try await performAuthorizationRequest(
            request: request,
            isRegistration: true
        )

        // LCOV_EXCL_START
        guard let registration = authorization.credential
            as? ASAuthorizationPlatformPublicKeyCredentialRegistration
        else {
            throw WebAuthnException.registrationFailed(
                reason: "Unexpected credential type: \(type(of: authorization.credential))"
            )
        }

        let credentialId = registration.credentialID
        guard let attestationObject = registration.rawAttestationObject else {
            throw WebAuthnException.registrationFailed(reason: "Attestation object is null")
        }

        let publicKey: Data
        do {
            publicKey = try SmartAccountUtils.extractPublicKeyFromAttestationObject(
                attestationObject
            )
        } catch {
            throw WebAuthnException.registrationFailed(
                reason: "Failed to extract public key from attestation: \(error.localizedDescription)",
                cause: error
            )
        }

        let authData = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestationObject)
        let parsedFlags = WebAuthnCborParser.parseAuthenticatorFlags(authData)

        return WebAuthnRegistrationResult(
            credentialId: credentialId,
            publicKey: publicKey,
            attestationObject: attestationObject,
            transports: ["internal"],
            deviceType: parsedFlags.deviceType,
            backedUp: parsedFlags.backedUp
        )
        // LCOV_EXCL_STOP
    }

    // ========================================================================
    // WebAuthnProvider — Authentication
    // ========================================================================

    public func authenticate(
        challenge: Data,
        allowCredentials: [WebAuthnAllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: rpId
        )
        let request = provider.createCredentialAssertionRequest(challenge: challenge)

        // why: on-chain WebAuthn verifier contracts require the User
        // Verification bit to be set and reject assertions with UV=false; a
        // "preferred" preference can return UV=false on macOS even after Touch
        // ID succeeds, so the assertion would be rejected on-chain. Forcing
        // "required" makes the authenticator set the UV bit unconditionally.
        request.userVerificationPreference = .required

        // Restrict the authenticator picker to the supplied credential IDs
        // when provided. Transport hints are intentionally not forwarded —
        // `ASAuthorizationPlatformPublicKeyCredentialDescriptor` has no
        // transport parameter and Apple selects hybrid / cross-device flows
        // at the OS level.
        if let allow = allowCredentials, !allow.isEmpty {
            request.allowedCredentials = allow.map {
                ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0.id)
            }
        }

        let authorization = try await performAuthorizationRequest(
            request: request,
            isRegistration: false
        )

        // LCOV_EXCL_START
        guard let assertion = authorization.credential
            as? ASAuthorizationPlatformPublicKeyCredentialAssertion
        else {
            throw WebAuthnException.authenticationFailed(
                reason: "Unexpected credential type: \(type(of: authorization.credential))"
            )
        }

        let credentialId = assertion.credentialID
        guard let authenticatorData = assertion.rawAuthenticatorData else {
            throw WebAuthnException.authenticationFailed(reason: "Authenticator data is null")
        }
        let clientDataJSON = assertion.rawClientDataJSON
        guard let signature = assertion.signature else {
            throw WebAuthnException.authenticationFailed(reason: "Signature is null")
        }

        return WebAuthnAuthenticationResult(
            credentialId: credentialId,
            authenticatorData: authenticatorData,
            clientDataJSON: clientDataJSON,
            signature: signature
        )
        // LCOV_EXCL_STOP
    }

    // ========================================================================
    // Internal — Authorization Request Execution
    // ========================================================================

    /// Bridges Apple's delegate-based `ASAuthorizationController` API to a
    /// Swift Concurrency continuation, applying the configured timeout.
    ///
    /// The controller is created and `performRequests()` is dispatched on the
    /// main queue — `ASAuthorizationController` rejects requests issued from
    /// background threads with ASAuthorizationError code 1004
    /// ("Told not to present authorization sheet"). The active delegate is
    /// retained via `activeDelegate` so the controller's weak reference does
    /// not deallocate it mid-flight.
    ///
    /// - Parameters:
    ///   - request: The authorization request to perform.
    ///   - isRegistration: `true` when the call originated from `register`,
    ///     `false` for `authenticate`. Selects the appropriate
    ///     `WebAuthnException` subclass when mapping errors.
    /// - Returns: The successful `ASAuthorization` result.
    /// - Throws: A `WebAuthnException` subclass selected from the underlying
    ///   `NSError` code, or a timeout-flavoured failure when the configured
    ///   `timeout` elapses before any callback fires.
    private func performAuthorizationRequest(
        request: ASAuthorizationRequest,
        isRegistration: Bool
    ) async throws -> ASAuthorization {
        // Coordinate the delegate callbacks and the timeout through a single
        // `AuthorizationContinuationHolder` so whichever event arrives first
        // completes the request and any later event is dropped.
        let holder = AuthorizationContinuationHolder()
        let timeoutMs = self.timeout

        let outcome = await withCheckedContinuation { (continuation: CheckedContinuation<AuthorizationOutcome, Never>) in
            holder.set(continuation: continuation)

            // Arm the timeout watchdog. The holder ignores any second resume
            // attempt, so the watchdog firing after a real callback is safe.
            let watchdog = Task.detached { [weak holder] in
                let nanos = UInt64(timeoutMs) * 1_000_000
                // why: handle cancellation explicitly. `Task.sleep` throws
                // `CancellationError` on cancel; bailing out on cancellation
                // keeps the watchdog from racing the winning callback path
                // when the holder cancels the task on completion.
                do {
                    try await Task.sleep(nanoseconds: nanos)
                } catch {
                    return
                }
                if Task.isCancelled { return }
                holder?.complete(with: .timeout)
            }
            holder.setWatchdog(watchdog)

            // why: `AuthorizationDelegate` is `@MainActor` because
            // `ASAuthorizationControllerDelegate` is itself main-actor
            // isolated on Swift 6. Constructing both the delegate and the
            // controller on the main thread matches Apple's threading
            // contract for `ASAuthorizationController` and ensures the system
            // delivers callbacks on the same actor.
            let providerRef = self
            DispatchQueue.main.async {
                // why: the watchdog may have completed the holder before the
                // main queue drained this work item. Skip activating the
                // controller in that case so a late-arriving delegate setup
                // does not overwrite the cleared `activeDelegate` slot.
                if holder.isCompleted {
                    providerRef.clearActiveDelegate()
                    return
                }

                let delegate = AuthorizationDelegate(
                    onSuccess: { authorization in
                        providerRef.clearActiveDelegate()
                        holder.complete(with: .success(authorization))
                    },
                    onError: { error in
                        providerRef.clearActiveDelegate()
                        holder.complete(with: .failure(error))
                    }
                )
                providerRef.setActiveDelegate(delegate)

                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = delegate
                if let presentation = providerRef.presentationContextProvider {
                    controller.presentationContextProvider = presentation
                }
                controller.performRequests()
            }
        }

        switch outcome {
        case .success(let authorization):
            return authorization
        case .failure(let error):
            throw mapAuthorizationError(error, isRegistration: isRegistration)
        case .timeout:
            clearActiveDelegate()
            let message = "WebAuthn operation timed out after \(timeoutMs)ms"
            if isRegistration {
                throw WebAuthnException.registrationFailed(reason: message)
            } else {
                throw WebAuthnException.authenticationFailed(reason: message)
            }
        }
    }

    /// Sets `activeDelegate` under `delegateLock`.
    private func setActiveDelegate(_ delegate: AuthorizationDelegate) {
        delegateLock.lock()
        activeDelegate = delegate
        delegateLock.unlock()
    }

    /// Clears `activeDelegate` under `delegateLock`. Safe to call repeatedly.
    private func clearActiveDelegate() {
        delegateLock.lock()
        activeDelegate = nil
        delegateLock.unlock()
    }

    /// Returns the current `activeDelegate` reference under `delegateLock`.
    /// Test-only accessor; production code does not need to read this.
    internal func currentActiveDelegate() -> AuthorizationDelegate? {
        delegateLock.lock()
        defer { delegateLock.unlock() }
        return activeDelegate
    }

    // ========================================================================
    // Internal — Error Mapping
    // ========================================================================

    /// Maps an `NSError` returned by `ASAuthorizationController` to the
    /// matching `WebAuthnException` subclass.
    ///
    /// The mapping covers the four canonical `ASAuthorizationError` codes:
    /// - 1001 → `WebAuthnException.Cancelled`
    /// - 1002 → `RegistrationFailed` or `AuthenticationFailed`
    ///   (invalid response)
    /// - 1003 → `WebAuthnException.NotSupported`
    /// - 1004 → `RegistrationFailed` or `AuthenticationFailed`
    ///   (authenticator failure)
    ///
    /// Any other code is treated as a generic registration / authentication
    /// failure carrying the original code in the message.
    internal func mapAuthorizationError(
        _ error: Error,
        isRegistration: Bool
    ) -> WebAuthnException {
        let nsError = error as NSError
        let localized = nsError.localizedDescription
        switch nsError.code {
        case 1001:
            return WebAuthnException.cancelled()
        case 1002:
            let message = "Invalid response from authenticator: \(localized)"
            return isRegistration
                ? WebAuthnException.registrationFailed(reason: message, cause: error)
                : WebAuthnException.authenticationFailed(reason: message, cause: error)
        case 1003:
            return WebAuthnException.notSupported(
                details: "Passkey operation not handled: \(localized)"
            )
        case 1004:
            let message = "Authenticator operation failed: \(localized)"
            return isRegistration
                ? WebAuthnException.registrationFailed(reason: message, cause: error)
                : WebAuthnException.authenticationFailed(reason: message, cause: error)
        default:
            let message = "Authorization error (code \(nsError.code)): \(localized)"
            return isRegistration
                ? WebAuthnException.registrationFailed(reason: message, cause: error)
                : WebAuthnException.authenticationFailed(reason: message, cause: error)
        }
    }
}

// ============================================================================
// AuthorizationOutcome
// ============================================================================

/// Internal sum type capturing one of the three terminal states of a
/// performed authorization request: a successful authorization, a delegate
/// error, or a timeout.
@available(iOS 16.0, macOS 13.0, *)
private enum AuthorizationOutcome: @unchecked Sendable {
    case success(ASAuthorization)
    case failure(Error)
    case timeout
}

// ============================================================================
// AuthorizationContinuationHolder
// ============================================================================

/// Coordinates the single-resume contract for the authorization continuation.
///
/// Both the `ASAuthorizationController` delegate callbacks and the timeout
/// watchdog can attempt to resume the continuation; only the first attempt
/// must take effect. The holder uses an internal lock to enforce that
/// invariant atomically and to cancel the timeout watchdog when a real
/// callback wins.
@available(iOS 16.0, macOS 13.0, *)
private final class AuthorizationContinuationHolder: @unchecked Sendable {

    private let lock = NSLock()
    private var continuation: CheckedContinuation<AuthorizationOutcome, Never>?
    private var watchdog: Task<Void, Never>?
    private var completed: Bool = false

    func set(continuation: CheckedContinuation<AuthorizationOutcome, Never>) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()
    }

    func setWatchdog(_ task: Task<Void, Never>) {
        lock.lock()
        self.watchdog = task
        lock.unlock()
    }

    /// Returns whether the holder has already been completed (delegate
    /// callback or timeout). Used by the main-queue setup closure to skip
    /// activating the controller when the watchdog has already won — without
    /// this guard the controller would set `activeDelegate` after the
    /// timeout path already cleared it.
    var isCompleted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return completed
    }

    func complete(with outcome: AuthorizationOutcome) {
        lock.lock()
        // LCOV_EXCL_START
        if completed {
            lock.unlock()
            return
        }
        // LCOV_EXCL_STOP
        completed = true
        let pending = continuation
        continuation = nil
        let pendingWatchdog = watchdog
        watchdog = nil
        lock.unlock()

        // Cancel the watchdog when a delegate callback wins so the timer does
        // not outlive the request. Cancellation is a no-op when the watchdog
        // itself is the caller.
        pendingWatchdog?.cancel()
        pending?.resume(returning: outcome)
    }
}

// ============================================================================
// AuthorizationDelegate
// ============================================================================

/// Internal `ASAuthorizationControllerDelegate` adapter that forwards
/// completion callbacks into Swift closures.
///
/// `ASAuthorizationController` retains its delegate weakly so the surrounding
/// provider must hold the delegate alive for the duration of the request.
/// The provider stores instances of this class in `activeDelegate` and clears
/// the reference once either callback fires.
// why: `ASAuthorizationControllerDelegate` inherits `@MainActor` isolation on
// Swift 6 toolchains, so the class is annotated `@MainActor` to keep its
// delegate-method conformance compatible; the surrounding async code uses
// `MainActor.run` to instantiate it from main-actor isolation.
@available(iOS 16.0, macOS 13.0, *)
@MainActor
internal final class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {

    private let onSuccess: (ASAuthorization) -> Void
    private let onError: (Error) -> Void

    init(
        onSuccess: @escaping (ASAuthorization) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
        super.init()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        onSuccess(authorization) // LCOV_EXCL_LINE
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        onError(error) // LCOV_EXCL_LINE
    }
}
