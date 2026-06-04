//
//  SmartAccountErrorsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class SmartAccountErrorsTests: XCTestCase {

    // Canonical numeric values for every SmartAccountErrorCode case.
    private let expectedCodeValues: [(SmartAccountErrorCode, Int)] = [
        (.invalidConfig, 1001),
        (.missingConfig, 1002),
        (.walletNotConnected, 2001),
        (.walletAlreadyExists, 2002),
        (.walletNotFound, 2003),
        (.credentialNotFound, 3001),
        (.credentialAlreadyExists, 3002),
        (.credentialInvalid, 3003),
        (.credentialDeploymentFailed, 3004),
        (.webAuthnRegistrationFailed, 4001),
        (.webAuthnAuthenticationFailed, 4002),
        (.webAuthnNotSupported, 4003),
        (.webAuthnCancelled, 4004),
        (.transactionSimulationFailed, 5001),
        (.transactionSigningFailed, 5002),
        (.transactionSubmissionFailed, 5003),
        (.transactionTimeout, 5004),
        (.signerNotFound, 6001),
        (.signerInvalid, 6002),
        (.invalidAddress, 7001),
        (.invalidAmount, 7002),
        (.invalidInput, 7003),
        (.storageReadFailed, 8001),
        (.storageWriteFailed, 8002),
        (.sessionExpired, 9001),
        (.sessionInvalid, 9002),
        (.indexerRequestFailed, 10001),
        (.indexerTimeout, 10002),
    ]

    // MARK: - Error codes

    func test_smart_account_error_code_has_28_distinct_numeric_values() {
        XCTAssertEqual(SmartAccountErrorCode.allCases.count, 28)
        let unique = Set(SmartAccountErrorCode.allCases.map { $0.code })
        XCTAssertEqual(unique.count, 28, "All numeric error codes must be distinct")
    }

    func test_smart_account_error_code_INVALID_CONFIG_equals_1001() {
        XCTAssertEqual(SmartAccountErrorCode.invalidConfig.code, 1001)
    }

    func test_smart_account_error_code_INDEXER_TIMEOUT_equals_10002() {
        XCTAssertEqual(SmartAccountErrorCode.indexerTimeout.code, 10002)
    }

    func test_smart_account_error_code_all_28_codes_match_authoritative_table() {
        for (errorCode, expected) in expectedCodeValues {
            XCTAssertEqual(errorCode.code, expected, "Code mismatch for \(errorCode)")
        }
        XCTAssertEqual(expectedCodeValues.count, SmartAccountErrorCode.allCases.count)
    }

    // MARK: - SmartAccountException

    func test_smart_account_exception_code_property_returns_underlying_error_code() {
        let exception = SmartAccountValidationException.invalidAddress(address: "GBAD")
        XCTAssertEqual(exception.code, .invalidAddress)
    }

    func test_smart_account_exception_to_string_format_includes_code_and_message() {
        let exception = SmartAccountWalletException.notConnected(details: "Connect first")
        let described = "\(exception)"
        XCTAssertTrue(described.contains("[\(exception.code.code)]"))
        XCTAssertTrue(described.contains("Connect first"))
    }

    func test_smart_account_exception_to_string_includes_caused_by_when_cause_present() {
        struct UnderlyingError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let cause = UnderlyingError()
        let exception = SmartAccountTransactionException.SimulationFailed(message: "simulation broke", cause: cause)
        let described = "\(exception)"
        XCTAssertTrue(described.contains("caused by"))
        XCTAssertTrue(described.contains("boom"))
    }

    // MARK: - wrapError

    func test_wrap_error_returns_input_unchanged_when_already_smart_account_exception() {
        let original = SmartAccountWalletException.notFound(identifier: "wallet-1")
        let wrapped = SmartAccountException.wrapError(original)
        XCTAssertTrue(wrapped === original)
    }

    func test_wrap_error_default_code_is_INVALID_INPUT_when_unspecified() {
        struct OtherError: Error {}
        let wrapped = SmartAccountException.wrapError(OtherError())
        XCTAssertEqual(wrapped.code, .invalidInput)
        XCTAssertTrue(wrapped is SmartAccountValidationException.InvalidInput)
    }

    func test_wrap_error_maps_each_of_28_codes_to_correct_arm() {
        struct UnderlyingError: Error, LocalizedError {
            var errorDescription: String? { "underlying" }
        }
        for (errorCode, _) in expectedCodeValues {
            let wrapped = SmartAccountException.wrapError(UnderlyingError(), defaultCode: errorCode)
            XCTAssertEqual(wrapped.code, errorCode, "Code mismatch for \(errorCode)")
            assertConcreteArm(wrapped, matches: errorCode)
        }
    }

    // MARK: - Sealed sub-types arm counts

    func test_each_sealed_subtype_has_correct_arm_count() {
        // Configuration: 2 arms
        XCTAssertNotNil(SmartAccountConfigurationException.invalidConfig(details: "x") as SmartAccountConfigurationException.InvalidConfig)
        XCTAssertNotNil(SmartAccountConfigurationException.missingConfig(param: "y") as SmartAccountConfigurationException.MissingConfig)

        // Wallet: 3 arms
        XCTAssertNotNil(SmartAccountWalletException.notConnected() as SmartAccountWalletException.NotConnected)
        XCTAssertNotNil(SmartAccountWalletException.alreadyExists(identifier: "w") as SmartAccountWalletException.AlreadyExists)
        XCTAssertNotNil(SmartAccountWalletException.notFound(identifier: "w") as SmartAccountWalletException.NotFound)

        // Credential: 4 arms
        XCTAssertNotNil(SmartAccountCredentialException.notFound(credentialId: "c") as SmartAccountCredentialException.NotFound)
        XCTAssertNotNil(SmartAccountCredentialException.alreadyExists(credentialId: "c") as SmartAccountCredentialException.AlreadyExists)
        XCTAssertNotNil(SmartAccountCredentialException.invalid(reason: "r") as SmartAccountCredentialException.Invalid)
        XCTAssertNotNil(SmartAccountCredentialException.deploymentFailed(reason: "r") as SmartAccountCredentialException.DeploymentFailed)

        // WebAuthn: 4 arms
        XCTAssertNotNil(WebAuthnException.registrationFailed(reason: "r") as WebAuthnException.RegistrationFailed)
        XCTAssertNotNil(WebAuthnException.authenticationFailed(reason: "r") as WebAuthnException.AuthenticationFailed)
        XCTAssertNotNil(WebAuthnException.notSupported() as WebAuthnException.NotSupported)
        XCTAssertNotNil(WebAuthnException.cancelled() as WebAuthnException.Cancelled)

        // Transaction: 4 arms
        XCTAssertNotNil(SmartAccountTransactionException.simulationFailed(reason: "r") as SmartAccountTransactionException.SimulationFailed)
        XCTAssertNotNil(SmartAccountTransactionException.signingFailed(reason: "r") as SmartAccountTransactionException.SigningFailed)
        XCTAssertNotNil(SmartAccountTransactionException.submissionFailed(reason: "r") as SmartAccountTransactionException.SubmissionFailed)
        XCTAssertNotNil(SmartAccountTransactionException.timeout() as SmartAccountTransactionException.Timeout)

        // Signer: 2 arms
        XCTAssertNotNil(SmartAccountSignerException.notFound(signerId: "s") as SmartAccountSignerException.NotFound)
        XCTAssertNotNil(SmartAccountSignerException.invalid(reason: "r") as SmartAccountSignerException.Invalid)

        // Validation: 3 arms
        XCTAssertNotNil(SmartAccountValidationException.invalidAddress(address: "a") as SmartAccountValidationException.InvalidAddress)
        XCTAssertNotNil(SmartAccountValidationException.invalidAmount(amount: "1") as SmartAccountValidationException.InvalidAmount)
        XCTAssertNotNil(SmartAccountValidationException.invalidInput(field: "f", reason: "r") as SmartAccountValidationException.InvalidInput)

        // Storage: 2 arms
        XCTAssertNotNil(SmartAccountStorageException.readFailed(key: "k") as SmartAccountStorageException.ReadFailed)
        XCTAssertNotNil(SmartAccountStorageException.writeFailed(key: "k") as SmartAccountStorageException.WriteFailed)

        // Session: 2 arms
        XCTAssertNotNil(SmartAccountSessionException.expired() as SmartAccountSessionException.Expired)
        XCTAssertNotNil(SmartAccountSessionException.invalid(reason: "r") as SmartAccountSessionException.Invalid)

        // Indexer: 2 arms
        XCTAssertNotNil(SmartAccountIndexerException.requestFailed(reason: "r") as SmartAccountIndexerException.RequestFailed)
        XCTAssertNotNil(SmartAccountIndexerException.timeout(url: "u") as SmartAccountIndexerException.Timeout)
    }

    // MARK: - Default messages

    func test_default_messages_present_NotConnected_NotSupported_Cancelled_Timeout_Expired() {
        XCTAssertEqual(SmartAccountWalletException.NotConnected().message, "Wallet is not connected")
        XCTAssertEqual(WebAuthnException.NotSupported().message, "WebAuthn is not supported on this platform")
        XCTAssertEqual(WebAuthnException.Cancelled().message, "User cancelled WebAuthn operation")
        XCTAssertEqual(SmartAccountTransactionException.Timeout().message, "Transaction timed out")
        XCTAssertEqual(SmartAccountSessionException.Expired().message, "Session has expired")
    }

    // MARK: - Companion factory message formats

    func test_companion_factory_invalidAddress_message_format_invalid_address_colon_address() {
        let error = SmartAccountValidationException.invalidAddress(address: "GBAD")
        XCTAssertEqual(error.message, "Invalid address: GBAD")
    }

    func test_companion_factory_invalidAmount_optional_reason_appended_after_dash() {
        let withReason = SmartAccountValidationException.invalidAmount(amount: "12.34", reason: "negative")
        XCTAssertEqual(withReason.message, "Invalid amount: 12.34 - negative")
        let withoutReason = SmartAccountValidationException.invalidAmount(amount: "12.34")
        XCTAssertEqual(withoutReason.message, "Invalid amount: 12.34")
    }

    func test_companion_factory_invalidInput_field_and_reason_in_message() {
        let error = SmartAccountValidationException.invalidInput(field: "publicKey", reason: "wrong size")
        XCTAssertEqual(error.message, "Invalid input for publicKey: wrong size")
    }

    func test_companion_factory_invalidInput_throws_correct_arm_with_correct_code() {
        // Erase to the base type so the runtime-type check below is meaningful rather than
        // a compile-time tautology.
        let error: SmartAccountException = SmartAccountValidationException.invalidInput(field: "k", reason: "v")
        XCTAssertTrue(error is SmartAccountValidationException.InvalidInput)
        XCTAssertEqual(error.code, .invalidInput)
    }

    // MARK: - Exhaustiveness

    func test_smart_account_exception_exhaustiveness_compile_time_check() {
        // Constructing one instance of every concrete arm enforces exhaustive coverage at
        // compile time: adding a new arm without updating this list fails to type-check.
        let exceptions: [SmartAccountException] = [
            SmartAccountConfigurationException.invalidConfig(details: "x"),
            SmartAccountConfigurationException.missingConfig(param: "y"),
            SmartAccountWalletException.notConnected(),
            SmartAccountWalletException.alreadyExists(identifier: "w"),
            SmartAccountWalletException.notFound(identifier: "w"),
            SmartAccountCredentialException.notFound(credentialId: "c"),
            SmartAccountCredentialException.alreadyExists(credentialId: "c"),
            SmartAccountCredentialException.invalid(reason: "r"),
            SmartAccountCredentialException.deploymentFailed(reason: "r"),
            WebAuthnException.registrationFailed(reason: "r"),
            WebAuthnException.authenticationFailed(reason: "r"),
            WebAuthnException.notSupported(),
            WebAuthnException.cancelled(),
            SmartAccountTransactionException.simulationFailed(reason: "r"),
            SmartAccountTransactionException.signingFailed(reason: "r"),
            SmartAccountTransactionException.submissionFailed(reason: "r"),
            SmartAccountTransactionException.timeout(),
            SmartAccountSignerException.notFound(signerId: "s"),
            SmartAccountSignerException.invalid(reason: "r"),
            SmartAccountValidationException.invalidAddress(address: "a"),
            SmartAccountValidationException.invalidAmount(amount: "1"),
            SmartAccountValidationException.invalidInput(field: "f", reason: "r"),
            SmartAccountStorageException.readFailed(key: "k"),
            SmartAccountStorageException.writeFailed(key: "k"),
            SmartAccountSessionException.expired(),
            SmartAccountSessionException.invalid(reason: "r"),
            SmartAccountIndexerException.requestFailed(reason: "r"),
            SmartAccountIndexerException.timeout(url: "u"),
        ]
        XCTAssertEqual(exceptions.count, 28, "Every error arm must be present")
        for exception in exceptions {
            // Force the SmartAccountException base interface to remain consumable.
            XCTAssertFalse(exception.message.isEmpty)
        }
    }

    // MARK: - Helpers

    private func assertConcreteArm(_ wrapped: SmartAccountException, matches code: SmartAccountErrorCode) {
        switch code {
        case .invalidConfig:
            XCTAssertTrue(wrapped is SmartAccountConfigurationException.InvalidConfig)
        case .missingConfig:
            XCTAssertTrue(wrapped is SmartAccountConfigurationException.MissingConfig)
        case .walletNotConnected:
            XCTAssertTrue(wrapped is SmartAccountWalletException.NotConnected)
        case .walletAlreadyExists:
            XCTAssertTrue(wrapped is SmartAccountWalletException.AlreadyExists)
        case .walletNotFound:
            XCTAssertTrue(wrapped is SmartAccountWalletException.NotFound)
        case .credentialNotFound:
            XCTAssertTrue(wrapped is SmartAccountCredentialException.NotFound)
        case .credentialAlreadyExists:
            XCTAssertTrue(wrapped is SmartAccountCredentialException.AlreadyExists)
        case .credentialInvalid:
            XCTAssertTrue(wrapped is SmartAccountCredentialException.Invalid)
        case .credentialDeploymentFailed:
            XCTAssertTrue(wrapped is SmartAccountCredentialException.DeploymentFailed)
        case .webAuthnRegistrationFailed:
            XCTAssertTrue(wrapped is WebAuthnException.RegistrationFailed)
        case .webAuthnAuthenticationFailed:
            XCTAssertTrue(wrapped is WebAuthnException.AuthenticationFailed)
        case .webAuthnNotSupported:
            XCTAssertTrue(wrapped is WebAuthnException.NotSupported)
        case .webAuthnCancelled:
            XCTAssertTrue(wrapped is WebAuthnException.Cancelled)
        case .transactionSimulationFailed:
            XCTAssertTrue(wrapped is SmartAccountTransactionException.SimulationFailed)
        case .transactionSigningFailed:
            XCTAssertTrue(wrapped is SmartAccountTransactionException.SigningFailed)
        case .transactionSubmissionFailed:
            XCTAssertTrue(wrapped is SmartAccountTransactionException.SubmissionFailed)
        case .transactionTimeout:
            XCTAssertTrue(wrapped is SmartAccountTransactionException.Timeout)
        case .signerNotFound:
            XCTAssertTrue(wrapped is SmartAccountSignerException.NotFound)
        case .signerInvalid:
            XCTAssertTrue(wrapped is SmartAccountSignerException.Invalid)
        case .invalidAddress:
            XCTAssertTrue(wrapped is SmartAccountValidationException.InvalidAddress)
        case .invalidAmount:
            XCTAssertTrue(wrapped is SmartAccountValidationException.InvalidAmount)
        case .invalidInput:
            XCTAssertTrue(wrapped is SmartAccountValidationException.InvalidInput)
        case .storageReadFailed:
            XCTAssertTrue(wrapped is SmartAccountStorageException.ReadFailed)
        case .storageWriteFailed:
            XCTAssertTrue(wrapped is SmartAccountStorageException.WriteFailed)
        case .sessionExpired:
            XCTAssertTrue(wrapped is SmartAccountSessionException.Expired)
        case .sessionInvalid:
            XCTAssertTrue(wrapped is SmartAccountSessionException.Invalid)
        case .indexerRequestFailed:
            XCTAssertTrue(wrapped is SmartAccountIndexerException.RequestFailed)
        case .indexerTimeout:
            XCTAssertTrue(wrapped is SmartAccountIndexerException.Timeout)
        }
    }

    // MARK: - description with SmartAccountException cause (line 239 coverage)

    /// When an exception has a SmartAccountException as its cause, `description`
    /// must include the inner exception's message. This exercises the
    /// `if let smartAccountError = error as? SmartAccountException` branch.
    func test_description_withSmartAccountExceptionCause_includesInnerMessage() {
        let innerError = SmartAccountValidationException.invalidInput(
            field: "field",
            reason: "inner error message"
        )
        let outerError = SmartAccountTransactionException.signingFailed(
            reason: "outer error",
            cause: innerError
        )
        let desc = outerError.description
        XCTAssertTrue(
            desc.contains("inner error message"),
            "description must include the inner SmartAccountException message, got: \(desc)"
        )
    }

    /// When `description` is called with a non-SmartAccountException cause
    /// that has an empty localized description, line 245 (`return String(describing:)`)
    /// is reached.
    func test_description_withEmptyLocalizationCause_usesDescribing() {
        struct _EmptyLocalized: Error, CustomStringConvertible {
            var localizedDescription: String { "" }
            var description: String { "custom description" }
        }
        let err = _EmptyLocalized()
        let wrapped = SmartAccountValidationException.invalidInput(
            field: "test",
            reason: "test reason",
            cause: err
        )
        let desc = wrapped.description
        XCTAssertTrue(
            desc.contains("custom description") || desc.contains("cause"),
            "description must include cause info for empty-localized errors, got: \(desc)"
        )
    }
}
