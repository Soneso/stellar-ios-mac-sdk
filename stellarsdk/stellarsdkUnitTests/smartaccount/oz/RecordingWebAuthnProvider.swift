//
//  RecordingWebAuthnProvider.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
@testable import stellarsdk

/// Scriptable WebAuthn provider used by the OZ smart-account pipeline tests.
///
/// Distinct from the `MockWebAuthnProvider` shipped under
/// `smartaccount/core/`: that mock holds a single configurable result; this
/// one supports an ordered queue of responses with errors interleaved, so a
/// test can drive multiple `authenticate` ceremonies through one provider
/// instance and assert on call ordering / arguments.
///
/// Tests populate the `authenticateResponses` and `registerResponses` queues
/// with canned outcomes (typed result values for the success path, errors for
/// the failure path); the recorder captures every call in the corresponding
/// `*Calls` array so tests can assert on call ordering, arguments, and counts.
///
/// Both responses queues accept either a typed result struct or an `Error`.
/// When the next entry is an `Error`, the provider throws it from `register`
/// / `authenticate`; otherwise the typed result is returned.
final class RecordingWebAuthnProvider: WebAuthnProvider, @unchecked Sendable {

    // MARK: - Recorded invocations

    /// Captures every `register(challenge:userId:userName:)` invocation in
    /// arrival order.
    struct RegisterCall {
        let challenge: Data
        let userId: Data
        let userName: String
    }

    /// Captures every `authenticate(challenge:allowCredentials:)` invocation.
    struct AuthenticateCall {
        let challenge: Data
        let allowCredentials: [AllowCredential]?
    }

    private let stateQueue = DispatchQueue(label: "RecordingWebAuthnProvider.state")
    private var _registerCalls: [RegisterCall] = []
    private var _authenticateCalls: [AuthenticateCall] = []
    private var _registerResponses: [Swift.Result<WebAuthnRegistrationResult, Error>] = []
    private var _authenticateResponses: [Swift.Result<WebAuthnAuthenticationResult, Error>] = []

    var registerCalls: [RegisterCall] {
        return stateQueue.sync { _registerCalls }
    }

    var authenticateCalls: [AuthenticateCall] {
        return stateQueue.sync { _authenticateCalls }
    }

    // MARK: - Script API

    /// Enqueues a successful registration response.
    func enqueueRegister(_ result: WebAuthnRegistrationResult) {
        stateQueue.sync { _registerResponses.append(.success(result)) }
    }

    /// Enqueues a registration error.
    func enqueueRegisterError(_ error: Error) {
        stateQueue.sync { _registerResponses.append(.failure(error)) }
    }

    /// Enqueues a successful authentication response.
    func enqueueAuthenticate(_ result: WebAuthnAuthenticationResult) {
        stateQueue.sync { _authenticateResponses.append(.success(result)) }
    }

    /// Enqueues an authentication error.
    func enqueueAuthenticateError(_ error: Error) {
        stateQueue.sync { _authenticateResponses.append(.failure(error)) }
    }

    // MARK: - WebAuthnProvider

    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult {
        let outcome: Swift.Result<WebAuthnRegistrationResult, Error>? = stateQueue.sync {
            _registerCalls.append(
                RegisterCall(
                    challenge: challenge,
                    userId: userId,
                    userName: userName
                )
            )
            if _registerResponses.isEmpty {
                return nil
            }
            return _registerResponses.removeFirst()
        }
        guard let resolved = outcome else {
            throw WebAuthnException.registrationFailed(
                reason: "RecordingWebAuthnProvider.register called but no response was queued"
            )
        }
        switch resolved {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func authenticate(
        challenge: Data,
        allowCredentials: [AllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult {
        let outcome: Swift.Result<WebAuthnAuthenticationResult, Error>? = stateQueue.sync {
            _authenticateCalls.append(
                AuthenticateCall(
                    challenge: challenge,
                    allowCredentials: allowCredentials
                )
            )
            if _authenticateResponses.isEmpty {
                return nil
            }
            return _authenticateResponses.removeFirst()
        }
        guard let resolved = outcome else {
            throw WebAuthnException.authenticationFailed(
                reason: "RecordingWebAuthnProvider.authenticate called but no response was queued"
            )
        }
        switch resolved {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

// ============================================================================
// Test helpers for building WebAuthn results
// ============================================================================

enum RecordingWebAuthnFixtures {

    /// Builds a syntactically-valid 70-byte DER ECDSA signature wrapping two
    /// 32-byte INTEGER components. The `SmartAccountUtils.normalizeSignature`
    /// helper requires a well-formed DER signature; constant byte values keep
    /// the output deterministic across test runs.
    static func validDerSignature(
        rSeed: UInt8 = 0x11,
        sSeed: UInt8 = 0x22
    ) -> Data {
        var bytes: [UInt8] = []
        bytes.append(0x30)
        bytes.append(0x44)
        bytes.append(0x02)
        bytes.append(0x20)
        bytes.append(contentsOf: [UInt8](repeating: rSeed, count: 32))
        bytes.append(0x02)
        bytes.append(0x20)
        bytes.append(contentsOf: [UInt8](repeating: sSeed, count: 32))
        return Data(bytes)
    }

    /// Builds an authenticator-data buffer (37 bytes minimum: 32-byte rpIdHash
    /// + 1 flags + 4 signCount).
    static func validAuthenticatorData(seed: UInt8 = 0x33) -> Data {
        return Data([UInt8](repeating: seed, count: 37))
    }

    /// Builds a `clientDataJSON` with a deterministic shape and the supplied
    /// challenge as Base64URL.
    static func clientDataJson(challengeBase64URL: String = "abc") -> Data {
        let json = "{\"type\":\"webauthn.get\",\"challenge\":\"\(challengeBase64URL)\",\"origin\":\"https://test\"}"
        return Data(json.utf8)
    }

    /// Builds a complete `WebAuthnAuthenticationResult` with the supplied
    /// credential id and default fixtures for the rest of the fields.
    static func authenticationResult(
        credentialId: Data,
        signature: Data? = nil
    ) -> WebAuthnAuthenticationResult {
        return WebAuthnAuthenticationResult(
            credentialId: credentialId,
            authenticatorData: validAuthenticatorData(),
            clientDataJSON: clientDataJson(),
            signature: signature ?? validDerSignature()
        )
    }
}
