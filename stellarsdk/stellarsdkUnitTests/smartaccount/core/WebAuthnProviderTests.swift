//
//  WebAuthnProviderTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class WebAuthnProviderTests: XCTestCase {

    // =========================================================================
    // Test fixtures — secp256r1 generator-point coordinates (NIST P-256)
    // =========================================================================

    /// secp256r1 generator-point X coordinate, used to assemble a valid 65-byte uncompressed
    /// test public key for DTO equality fixtures.
    ///
    /// Gx = 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296
    private let testXCoordinate = Data([
        0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47,
        0xF8, 0xBC, 0xE6, 0xE5, 0x63, 0xA4, 0x40, 0xF2,
        0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0,
        0xF4, 0xA1, 0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96
    ])

    /// secp256r1 generator-point Y coordinate.
    ///
    /// Gy = 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5
    private let testYCoordinate = Data([
        0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B,
        0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 0x0F, 0x9E, 0x16,
        0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE,
        0xCB, 0xB6, 0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5
    ])

    /// 10-byte CBOR map prefix that begins an ES256 COSE key for secp256r1.
    private let coseKeyPrefix = Data([
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20
    ])

    /// CBOR-encoded -3 label and 32-byte bstr header that separates the X and Y coordinates.
    private let coseKeySeparator = Data([0x22, 0x58, 0x20])

    /// Returns the expected 65-byte uncompressed public key: `0x04 || Gx || Gy`.
    private var expectedPublicKey: Data {
        var key = Data(count: 65)
        key[0] = 0x04
        key.replaceSubrange(1..<33, with: testXCoordinate)
        key.replaceSubrange(33..<65, with: testYCoordinate)
        return key
    }

    /// Builds a minimal COSE key structure containing the test X / Y coordinates.
    ///
    /// Layout: `[prefix (10)] [X (32)] [separator (3)] [Y (32)]` = 77 bytes.
    private func buildCoseKey() -> Data {
        var key = Data()
        key.append(coseKeyPrefix)
        key.append(testXCoordinate)
        key.append(coseKeySeparator)
        key.append(testYCoordinate)
        return key
    }

    /// Builds a minimal authenticator data structure with attested credential data.
    ///
    /// Layout (per WebAuthn spec):
    /// - `[0..31]` rpIdHash (32 bytes, filled with 0xAA)
    /// - `[32]` flags (1 byte)
    /// - `[33..36]` signCount (4 bytes, big-endian, set to 0)
    /// - `[37..52]` aaguid (16 bytes, filled with 0x00)
    /// - `[53..54]` credentialIdLen (2 bytes, big-endian)
    /// - `[55..55+N-1]` credentialId (N bytes)
    /// - `[55+N..]` COSE public key (variable)
    private func buildAuthenticatorData(flags: Int = 0x41, credentialIdLength: Int = 16) -> Data {
        var data = Data()
        data.append(Data(repeating: 0xAA, count: 32))
        data.append(UInt8(flags & 0xFF))
        data.append(Data(repeating: 0x00, count: 4))
        data.append(Data(repeating: 0x00, count: 16))
        data.append(UInt8((credentialIdLength >> 8) & 0xFF))
        data.append(UInt8(credentialIdLength & 0xFF))
        data.append(Data(repeating: 0xBB, count: credentialIdLength))
        data.append(buildCoseKey())
        return data
    }

    private func buildAttestationObject() -> Data {
        return buildCoseKey()
    }

    // =========================================================================
    // Authenticator data flag parsing tests (mirrors KMP ProviderTest 405-525)
    // =========================================================================

    func test_authenticator_data_flags_user_present() {
        // Bit 0 (0x01): UP (User Present)
        let flags = 0x01
        XCTAssertEqual(1, flags & 0x01, "UP bit should be set")
        XCTAssertEqual(0, flags & 0x04, "UV bit should not be set")
        XCTAssertEqual(0, flags & 0x08, "BE bit should not be set")
        XCTAssertEqual(0, flags & 0x10, "BS bit should not be set")
        XCTAssertEqual(0, flags & 0x40, "AT bit should not be set")
    }

    func test_authenticator_data_flags_user_verified() {
        // Bit 2 (0x04): UV (User Verified)
        let flags = 0x05 // UP + UV
        XCTAssertEqual(1, flags & 0x01, "UP bit should be set")
        XCTAssertEqual(0x04, flags & 0x04, "UV bit should be set")
    }

    func test_authenticator_data_flags_backup_eligible_single_device() {
        // BE=0 → "singleDevice"
        let flags = 0x01 // UP only, no BE, no BS
        let backupEligible = (flags & 0x08) != 0
        let backedUp = (flags & 0x10) != 0
        let deviceType = backupEligible ? "multiDevice" : "singleDevice"

        XCTAssertFalse(backupEligible, "BE should not be set for singleDevice")
        XCTAssertFalse(backedUp, "BS should not be set when BE is not set")
        XCTAssertEqual("singleDevice", deviceType)
    }

    func test_authenticator_data_flags_backup_eligible_multi_device() {
        // BE=1 → "multiDevice"
        let flags = 0x09 // UP + BE
        let backupEligible = (flags & 0x08) != 0
        let backedUp = (flags & 0x10) != 0
        let deviceType = backupEligible ? "multiDevice" : "singleDevice"

        XCTAssertTrue(backupEligible, "BE should be set for multiDevice")
        XCTAssertFalse(backedUp, "BS should not be set (eligible but not yet backed up)")
        XCTAssertEqual("multiDevice", deviceType)
    }

    func test_authenticator_data_flags_backed_up() {
        // BE=1, BS=1 → multiDevice, backed up
        let flags = 0x19 // UP + BE + BS
        let backupEligible = (flags & 0x08) != 0
        let backedUp = (flags & 0x10) != 0
        let deviceType = backupEligible ? "multiDevice" : "singleDevice"

        XCTAssertTrue(backupEligible, "BE should be set")
        XCTAssertTrue(backedUp, "BS should be set (credential is backed up)")
        XCTAssertEqual("multiDevice", deviceType)
    }

    func test_authenticator_data_flags_attested_credential_data() {
        // Bit 6 (0x40): AT (Attested Credential Data present)
        let flags = 0x41 // UP + AT
        let atPresent = (flags & 0x40) != 0
        XCTAssertTrue(atPresent, "AT flag should be set")
    }

    func test_authenticator_data_flags_all_flags_set() {
        // UP=1, UV=1, BE=1, BS=1, AT=1, ED=1 (extension data)
        let flags = 0xDD // 11011101 = UP+UV+BE+BS+AT+ED
        XCTAssertEqual(0x01, flags & 0x01, "UP bit")
        XCTAssertEqual(0x04, flags & 0x04, "UV bit")
        XCTAssertEqual(0x08, flags & 0x08, "BE bit")
        XCTAssertEqual(0x10, flags & 0x10, "BS bit")
        XCTAssertEqual(0x40, flags & 0x40, "AT bit")
        XCTAssertEqual(0x80, flags & 0x80, "ED bit")
    }

    func test_device_type_from_real_authenticator_data_single_device() {
        let authData = buildAuthenticatorData(flags: 0x41) // UP + AT, no BE
        let flags = Int(authData[32])
        let backupEligible = (flags & 0x08) != 0
        let deviceType = backupEligible ? "multiDevice" : "singleDevice"

        XCTAssertEqual("singleDevice", deviceType)
    }

    func test_device_type_from_real_authenticator_data_multi_device() {
        let authData = buildAuthenticatorData(flags: 0x49) // UP + BE + AT
        let flags = Int(authData[32])
        let backupEligible = (flags & 0x08) != 0
        let deviceType = backupEligible ? "multiDevice" : "singleDevice"

        XCTAssertEqual("multiDevice", deviceType)
    }

    func test_backed_up_from_real_authenticator_data_not_backed_up() {
        let authData = buildAuthenticatorData(flags: 0x49) // UP + BE + AT, no BS
        let flags = Int(authData[32])
        let backedUp = (flags & 0x10) != 0
        XCTAssertFalse(backedUp, "Should not be backed up when BS flag is clear")
    }

    func test_backed_up_from_real_authenticator_data_backed_up() {
        let authData = buildAuthenticatorData(flags: 0x59) // UP + BE + BS + AT
        let flags = Int(authData[32])
        let backedUp = (flags & 0x10) != 0
        XCTAssertTrue(backedUp, "Should be backed up when BS flag is set")
    }

    // =========================================================================
    // WebAuthnRegistrationResult DTO tests (mirrors KMP ProviderTest 868-928)
    // =========================================================================

    func test_webauthn_registration_result_equality() {
        let credId = Data((0..<16).map { UInt8($0) })
        let pubKey = expectedPublicKey
        let attestObj = buildAttestationObject()

        let result1 = WebAuthnRegistrationResult(
            credentialId: credId,
            publicKey: pubKey,
            attestationObject: attestObj,
            transports: ["internal"],
            deviceType: "multiDevice",
            backedUp: true
        )

        let result2 = WebAuthnRegistrationResult(
            credentialId: Data(credId),
            publicKey: Data(pubKey),
            attestationObject: Data(attestObj),
            transports: ["internal"],
            deviceType: "multiDevice",
            backedUp: true
        )

        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result1.hashValue, result2.hashValue)
    }

    func test_webauthn_registration_result_inequality_different_credential_id() {
        let attestObj = buildAttestationObject()

        let result1 = WebAuthnRegistrationResult(
            credentialId: Data(repeating: 0x01, count: 16),
            publicKey: expectedPublicKey,
            attestationObject: attestObj
        )

        let result2 = WebAuthnRegistrationResult(
            credentialId: Data(repeating: 0x02, count: 16),
            publicKey: expectedPublicKey,
            attestationObject: attestObj
        )

        XCTAssertNotEqual(result1, result2)
    }

    func test_webauthn_registration_result_optional_fields_defaults() {
        let result = WebAuthnRegistrationResult(
            credentialId: Data(count: 16),
            publicKey: expectedPublicKey,
            attestationObject: buildAttestationObject()
        )

        XCTAssertNil(result.transports)
        XCTAssertNil(result.deviceType)
        XCTAssertNil(result.backedUp)
    }

    // =========================================================================
    // WebAuthnAuthenticationResult DTO tests (mirrors KMP ProviderTest 935-979)
    // =========================================================================

    func test_webauthn_authentication_result_equality() {
        let credId = Data((0..<16).map { UInt8($0) })
        let authData = Data((0..<37).map { UInt8($0) })
        let clientData = Data(#"{"type":"webauthn.get","challenge":"abc"}"#.utf8)
        let sig = Data((0..<64).map { UInt8($0) })

        let result1 = WebAuthnAuthenticationResult(
            credentialId: credId,
            authenticatorData: authData,
            clientDataJSON: clientData,
            signature: sig
        )

        let result2 = WebAuthnAuthenticationResult(
            credentialId: Data(credId),
            authenticatorData: Data(authData),
            clientDataJSON: Data(clientData),
            signature: Data(sig)
        )

        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result1.hashValue, result2.hashValue)
    }

    func test_webauthn_authentication_result_inequality_different_signature() {
        let base = WebAuthnAuthenticationResult(
            credentialId: Data(count: 16),
            authenticatorData: Data(count: 37),
            clientDataJSON: Data(count: 100),
            signature: Data(repeating: 0x01, count: 64)
        )

        let different = WebAuthnAuthenticationResult(
            credentialId: Data(count: 16),
            authenticatorData: Data(count: 37),
            clientDataJSON: Data(count: 100),
            signature: Data(repeating: 0x02, count: 64)
        )

        XCTAssertNotEqual(base, different)
    }

    // =========================================================================
    // Mock provider smoke tests (interface contract)
    // =========================================================================

    func test_mock_provider_register_returns_default_result_when_unconfigured() async throws {
        let mock = MockWebAuthnProvider()
        let result = try await mock.register(
            challenge: Data(repeating: 0xAA, count: 32),
            userId: Data(repeating: 0xBB, count: 16),
            userName: "user@example.com"
        )

        let expected = MockWebAuthnProvider.defaultRegistrationResult()
        XCTAssertEqual(result, expected)
    }

    func test_mock_provider_register_throws_configured_exception() async {
        let mock = MockWebAuthnProvider()
        mock.registrationException = WebAuthnException.cancelled()

        do {
            _ = try await mock.register(
                challenge: Data(),
                userId: Data(),
                userName: "user"
            )
            XCTFail("Expected WebAuthnException.Cancelled")
        } catch let error as WebAuthnException.Cancelled {
            XCTAssertEqual(error.code, .webAuthnCancelled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_mock_provider_register_tracks_call_count_and_args() async throws {
        let mock = MockWebAuthnProvider()

        _ = try await mock.register(
            challenge: Data([0x01]),
            userId: Data([0x02]),
            userName: "first"
        )
        _ = try await mock.register(
            challenge: Data([0x03, 0x04]),
            userId: Data([0x05, 0x06]),
            userName: "second"
        )

        XCTAssertEqual(mock.registerCallCount, 2)
        XCTAssertEqual(mock.lastRegisterChallenge, Data([0x03, 0x04]))
        XCTAssertEqual(mock.lastRegisterUserId, Data([0x05, 0x06]))
        XCTAssertEqual(mock.lastRegisterUserName, "second")
    }

    func test_mock_provider_authenticate_returns_default_result_when_unconfigured() async throws {
        let mock = MockWebAuthnProvider()
        let result = try await mock.authenticate(
            challenge: Data(repeating: 0xCC, count: 32),
            allowCredentials: nil
        )

        let expected = MockWebAuthnProvider.defaultAuthenticationResult()
        XCTAssertEqual(result, expected)
    }

    func test_mock_provider_authenticate_throws_configured_exception() async {
        let mock = MockWebAuthnProvider()
        mock.authenticationException = WebAuthnException.authenticationFailed(reason: "test")

        do {
            _ = try await mock.authenticate(challenge: Data(), allowCredentials: nil)
            XCTFail("Expected WebAuthnException.AuthenticationFailed")
        } catch let error as WebAuthnException.AuthenticationFailed {
            XCTAssertEqual(error.code, .webAuthnAuthenticationFailed)
            XCTAssertTrue(error.message.contains("test"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_mock_provider_authenticate_tracks_call_count_and_args() async throws {
        let mock = MockWebAuthnProvider()
        let allow = [AllowCredential(id: Data([0x10, 0x20]), transports: ["internal"])]

        _ = try await mock.authenticate(challenge: Data([0x01]), allowCredentials: nil)
        _ = try await mock.authenticate(challenge: Data([0xAA, 0xBB]), allowCredentials: allow)

        XCTAssertEqual(mock.authenticateCallCount, 2)
        XCTAssertEqual(mock.lastAuthenticateChallenge, Data([0xAA, 0xBB]))
        XCTAssertEqual(mock.lastAuthenticateAllowCredentials, allow)
    }

    func test_mock_provider_reset_clears_all_state() async throws {
        let mock = MockWebAuthnProvider()
        mock.registrationException = WebAuthnException.cancelled()
        do {
            _ = try await mock.register(challenge: Data(), userId: Data(), userName: "u")
        } catch {
            // expected — exception was configured
        }
        _ = try await mock.authenticate(challenge: Data(), allowCredentials: nil)

        mock.reset()

        XCTAssertEqual(mock.registerCallCount, 0)
        XCTAssertEqual(mock.authenticateCallCount, 0)
        XCTAssertNil(mock.lastRegisterChallenge)
        XCTAssertNil(mock.lastRegisterUserId)
        XCTAssertNil(mock.lastRegisterUserName)
        XCTAssertNil(mock.lastAuthenticateChallenge)
        XCTAssertNil(mock.lastAuthenticateAllowCredentials)
        XCTAssertNil(mock.registrationException)
        XCTAssertNil(mock.authenticationException)
        XCTAssertNil(mock.registrationResult)
        XCTAssertNil(mock.authenticationResult)
    }

    func test_mock_provider_test_public_key_seed_0_starts_with_0x04_and_is_65_bytes() {
        let key = MockWebAuthnProvider.testPublicKey()
        XCTAssertEqual(key.count, 65)
        XCTAssertEqual(key[0], 0x04)
    }

    func test_mock_provider_test_credential_id_seed_0_is_16_bytes() {
        let id = MockWebAuthnProvider.testCredentialId()
        XCTAssertEqual(id.count, 16)
    }

    func test_mock_provider_test_attestation_object_seed_0_is_128_bytes() {
        let obj = MockWebAuthnProvider.testAttestationObject()
        XCTAssertEqual(obj.count, 128)
    }
}
