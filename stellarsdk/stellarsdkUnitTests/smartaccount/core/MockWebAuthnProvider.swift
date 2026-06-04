//
//  MockWebAuthnProvider.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation
@testable import stellarsdk

/// Configurable mock implementation of `WebAuthnProvider` for unit testing.
///
/// The mock allows tests to:
/// - Supply predetermined registration and authentication results
/// - Configure exceptions to simulate error conditions
/// - Track call counts and captured arguments for verification
///
/// By default, the mock produces valid registration and authentication results using
/// synthetic test data. Override `registrationResult`, `authenticationResult`,
/// `registrationException`, or `authenticationException` to change behavior.
///
/// Test-only: lives under the unit-test target and is not compiled into the shipping module.
final class MockWebAuthnProvider: WebAuthnProvider, @unchecked Sendable {

    // MARK: - Configuration

    /// Result returned from `register`. If `nil` and `registrationException` is also `nil`,
    /// a default synthetic result is generated.
    var registrationResult: WebAuthnRegistrationResult?

    /// Exception thrown from `register`. Takes precedence over `registrationResult`.
    var registrationException: WebAuthnException?

    /// Result returned from `authenticate`. If `nil` and `authenticationException` is also
    /// `nil`, a default synthetic result is generated.
    var authenticationResult: WebAuthnAuthenticationResult?

    /// Exception thrown from `authenticate`. Takes precedence over `authenticationResult`.
    var authenticationException: WebAuthnException?

    // MARK: - Call tracking

    /// Number of times `register` has been called.
    private(set) var registerCallCount: Int = 0

    /// Number of times `authenticate` has been called.
    private(set) var authenticateCallCount: Int = 0

    /// Most recent `challenge` passed to `register`, or `nil` if never called.
    private(set) var lastRegisterChallenge: Data?

    /// Most recent `userId` passed to `register`, or `nil` if never called.
    private(set) var lastRegisterUserId: Data?

    /// Most recent `userName` passed to `register`, or `nil` if never called.
    private(set) var lastRegisterUserName: String?

    /// Most recent `challenge` passed to `authenticate`, or `nil` if never called.
    private(set) var lastAuthenticateChallenge: Data?

    /// Most recent `allowCredentials` passed to `authenticate`, or `nil` if never called.
    private(set) var lastAuthenticateAllowCredentials: [WebAuthnAllowCredential]?

    // MARK: - Initialization

    /// Creates a mock with default `nil` configuration. The default-results helpers are
    /// invoked lazily inside `register` / `authenticate` only when both
    /// `registrationResult` / `authenticationResult` and the corresponding exception are
    /// `nil`.
    init() {}

    // MARK: - WebAuthnProvider implementation

    func register(
        challenge: Data,
        userId: Data,
        userName: String
    ) async throws -> WebAuthnRegistrationResult {
        registerCallCount += 1
        lastRegisterChallenge = Data(challenge)
        lastRegisterUserId = Data(userId)
        lastRegisterUserName = userName

        if let exception = registrationException {
            throw exception
        }

        return registrationResult ?? Self.defaultRegistrationResult()
    }

    func authenticate(
        challenge: Data,
        allowCredentials: [WebAuthnAllowCredential]?
    ) async throws -> WebAuthnAuthenticationResult {
        authenticateCallCount += 1
        lastAuthenticateChallenge = Data(challenge)
        lastAuthenticateAllowCredentials = allowCredentials

        if let exception = authenticationException {
            throw exception
        }

        return authenticationResult ?? Self.defaultAuthenticationResult()
    }

    // MARK: - Reset

    /// Resets all call-tracking state and configured responses to their initial values.
    func reset() {
        registrationResult = nil
        registrationException = nil
        authenticationResult = nil
        authenticationException = nil
        registerCallCount = 0
        authenticateCallCount = 0
        lastRegisterChallenge = nil
        lastRegisterUserId = nil
        lastRegisterUserName = nil
        lastAuthenticateChallenge = nil
        lastAuthenticateAllowCredentials = nil
    }

    // MARK: - Synthetic-builder factories

    /// Creates a deterministic 65-byte uncompressed secp256r1 test public key.
    ///
    /// Layout: `0x04` prefix followed by 64 deterministic bytes derived from `seed`. Reusable
    /// as a stand-in for a real authenticator response in unit tests.
    ///
    /// - Parameter seed: Integer seed mixed into each byte to produce distinct fixtures.
    /// - Returns: 65-byte deterministic public key.
    static func testPublicKey(seed: Int = 0) -> Data {
        var bytes = Data(count: 65)
        bytes[0] = 0x04
        for i in 1..<65 {
            bytes[i] = UInt8((i + seed) % 256)
        }
        return bytes
    }

    /// Creates a deterministic 16-byte test credential ID.
    ///
    /// - Parameter seed: Integer seed mixed into each byte to produce distinct fixtures.
    /// - Returns: 16-byte deterministic credential ID.
    static func testCredentialId(seed: Int = 0) -> Data {
        var bytes = Data(count: 16)
        for i in 0..<16 {
            bytes[i] = UInt8((i + seed) % 256)
        }
        return bytes
    }

    /// Creates a deterministic 128-byte synthetic test attestation object.
    ///
    /// The bytes are deterministic and well-defined for fixture reuse, but they are NOT a
    /// valid CBOR attestation structure — callers needing a parser-decodable attestation
    /// must build one explicitly via the parser-test CBOR helpers.
    ///
    /// - Parameter seed: Integer seed mixed into each byte to produce distinct fixtures.
    /// - Returns: 128-byte deterministic synthetic attestation object.
    static func testAttestationObject(seed: Int = 0) -> Data {
        var bytes = Data(count: 128)
        for i in 0..<128 {
            bytes[i] = UInt8((i + seed + 0x10) % 256)
        }
        return bytes
    }

    // MARK: - Default-response helpers

    /// Default `WebAuthnRegistrationResult` returned when the mock is unconfigured.
    static func defaultRegistrationResult() -> WebAuthnRegistrationResult {
        return WebAuthnRegistrationResult(
            credentialId: testCredentialId(),
            publicKey: testPublicKey(),
            attestationObject: testAttestationObject(),
            transports: ["internal"],
            deviceType: "multiDevice",
            backedUp: true
        )
    }

    /// Default `WebAuthnAuthenticationResult` returned when the mock is unconfigured.
    static func defaultAuthenticationResult() -> WebAuthnAuthenticationResult {
        var authData = Data(count: 37)
        for i in 0..<37 { authData[i] = UInt8(i) }
        let clientData = Data(#"{"type":"webauthn.get","challenge":"test"}"#.utf8)
        var sig = Data(count: 64)
        for i in 0..<64 { sig[i] = UInt8(i) }
        return WebAuthnAuthenticationResult(
            credentialId: testCredentialId(),
            authenticatorData: authData,
            clientDataJSON: clientData,
            signature: sig
        )
    }
}
