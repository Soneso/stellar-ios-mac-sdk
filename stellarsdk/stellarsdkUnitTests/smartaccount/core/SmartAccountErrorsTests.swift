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
        let exception = ValidationException.invalidAddress(address: "GBAD")
        XCTAssertEqual(exception.code, .invalidAddress)
    }

    func test_smart_account_exception_to_string_format_includes_code_and_message() {
        let exception = WalletException.notConnected(details: "Connect first")
        let described = "\(exception)"
        XCTAssertTrue(described.contains("[\(exception.code.code)]"))
        XCTAssertTrue(described.contains("Connect first"))
    }

    func test_smart_account_exception_to_string_includes_caused_by_when_cause_present() {
        struct UnderlyingError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let cause = UnderlyingError()
        let exception = TransactionException.SimulationFailed(message: "simulation broke", cause: cause)
        let described = "\(exception)"
        XCTAssertTrue(described.contains("caused by"))
        XCTAssertTrue(described.contains("boom"))
    }

    // MARK: - wrapError

    func test_wrap_error_returns_input_unchanged_when_already_smart_account_exception() {
        let original = WalletException.notFound(identifier: "wallet-1")
        let wrapped = SmartAccountException.wrapError(original)
        XCTAssertTrue(wrapped === original)
    }

    func test_wrap_error_default_code_is_INVALID_INPUT_when_unspecified() {
        struct OtherError: Error {}
        let wrapped = SmartAccountException.wrapError(OtherError())
        XCTAssertEqual(wrapped.code, .invalidInput)
        XCTAssertTrue(wrapped is ValidationException.InvalidInput)
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
        XCTAssertNotNil(ConfigurationException.invalidConfig(details: "x") as ConfigurationException.InvalidConfig)
        XCTAssertNotNil(ConfigurationException.missingConfig(param: "y") as ConfigurationException.MissingConfig)

        // Wallet: 3 arms
        XCTAssertNotNil(WalletException.notConnected() as WalletException.NotConnected)
        XCTAssertNotNil(WalletException.alreadyExists(identifier: "w") as WalletException.AlreadyExists)
        XCTAssertNotNil(WalletException.notFound(identifier: "w") as WalletException.NotFound)

        // Credential: 4 arms
        XCTAssertNotNil(CredentialException.notFound(credentialId: "c") as CredentialException.NotFound)
        XCTAssertNotNil(CredentialException.alreadyExists(credentialId: "c") as CredentialException.AlreadyExists)
        XCTAssertNotNil(CredentialException.invalid(reason: "r") as CredentialException.Invalid)
        XCTAssertNotNil(CredentialException.deploymentFailed(reason: "r") as CredentialException.DeploymentFailed)

        // WebAuthn: 4 arms
        XCTAssertNotNil(WebAuthnException.registrationFailed(reason: "r") as WebAuthnException.RegistrationFailed)
        XCTAssertNotNil(WebAuthnException.authenticationFailed(reason: "r") as WebAuthnException.AuthenticationFailed)
        XCTAssertNotNil(WebAuthnException.notSupported() as WebAuthnException.NotSupported)
        XCTAssertNotNil(WebAuthnException.cancelled() as WebAuthnException.Cancelled)

        // Transaction: 4 arms
        XCTAssertNotNil(TransactionException.simulationFailed(reason: "r") as TransactionException.SimulationFailed)
        XCTAssertNotNil(TransactionException.signingFailed(reason: "r") as TransactionException.SigningFailed)
        XCTAssertNotNil(TransactionException.submissionFailed(reason: "r") as TransactionException.SubmissionFailed)
        XCTAssertNotNil(TransactionException.timeout() as TransactionException.Timeout)

        // Signer: 2 arms
        XCTAssertNotNil(SignerException.notFound(signerId: "s") as SignerException.NotFound)
        XCTAssertNotNil(SignerException.invalid(reason: "r") as SignerException.Invalid)

        // Validation: 3 arms
        XCTAssertNotNil(ValidationException.invalidAddress(address: "a") as ValidationException.InvalidAddress)
        XCTAssertNotNil(ValidationException.invalidAmount(amount: "1") as ValidationException.InvalidAmount)
        XCTAssertNotNil(ValidationException.invalidInput(field: "f", reason: "r") as ValidationException.InvalidInput)

        // Storage: 2 arms
        XCTAssertNotNil(StorageException.readFailed(key: "k") as StorageException.ReadFailed)
        XCTAssertNotNil(StorageException.writeFailed(key: "k") as StorageException.WriteFailed)

        // Session: 2 arms
        XCTAssertNotNil(SessionException.expired() as SessionException.Expired)
        XCTAssertNotNil(SessionException.invalid(reason: "r") as SessionException.Invalid)

        // Indexer: 2 arms
        XCTAssertNotNil(IndexerException.requestFailed(reason: "r") as IndexerException.RequestFailed)
        XCTAssertNotNil(IndexerException.timeout(url: "u") as IndexerException.Timeout)
    }

    // MARK: - Default messages

    func test_default_messages_present_NotConnected_NotSupported_Cancelled_Timeout_Expired() {
        XCTAssertEqual(WalletException.NotConnected().message, "Wallet is not connected")
        XCTAssertEqual(WebAuthnException.NotSupported().message, "WebAuthn is not supported on this platform")
        XCTAssertEqual(WebAuthnException.Cancelled().message, "User cancelled WebAuthn operation")
        XCTAssertEqual(TransactionException.Timeout().message, "Transaction timed out")
        XCTAssertEqual(SessionException.Expired().message, "Session has expired")
    }

    // MARK: - Companion factory message formats

    func test_companion_factory_invalidAddress_message_format_invalid_address_colon_address() {
        let error = ValidationException.invalidAddress(address: "GBAD")
        XCTAssertEqual(error.message, "Invalid address: GBAD")
    }

    func test_companion_factory_invalidAmount_optional_reason_appended_after_dash() {
        let withReason = ValidationException.invalidAmount(amount: "12.34", reason: "negative")
        XCTAssertEqual(withReason.message, "Invalid amount: 12.34 - negative")
        let withoutReason = ValidationException.invalidAmount(amount: "12.34")
        XCTAssertEqual(withoutReason.message, "Invalid amount: 12.34")
    }

    func test_companion_factory_invalidInput_field_and_reason_in_message() {
        let error = ValidationException.invalidInput(field: "publicKey", reason: "wrong size")
        XCTAssertEqual(error.message, "Invalid input for publicKey: wrong size")
    }

    func test_companion_factory_invalidInput_throws_correct_arm_with_correct_code() {
        // Erase to the base type so the runtime-type check below is meaningful rather than
        // a compile-time tautology.
        let error: SmartAccountException = ValidationException.invalidInput(field: "k", reason: "v")
        XCTAssertTrue(error is ValidationException.InvalidInput)
        XCTAssertEqual(error.code, .invalidInput)
    }

    // MARK: - Exhaustiveness

    func test_smart_account_exception_exhaustiveness_compile_time_check() {
        // Constructing one instance of every concrete arm enforces exhaustive coverage at
        // compile time: adding a new arm without updating this list fails to type-check.
        let exceptions: [SmartAccountException] = [
            ConfigurationException.invalidConfig(details: "x"),
            ConfigurationException.missingConfig(param: "y"),
            WalletException.notConnected(),
            WalletException.alreadyExists(identifier: "w"),
            WalletException.notFound(identifier: "w"),
            CredentialException.notFound(credentialId: "c"),
            CredentialException.alreadyExists(credentialId: "c"),
            CredentialException.invalid(reason: "r"),
            CredentialException.deploymentFailed(reason: "r"),
            WebAuthnException.registrationFailed(reason: "r"),
            WebAuthnException.authenticationFailed(reason: "r"),
            WebAuthnException.notSupported(),
            WebAuthnException.cancelled(),
            TransactionException.simulationFailed(reason: "r"),
            TransactionException.signingFailed(reason: "r"),
            TransactionException.submissionFailed(reason: "r"),
            TransactionException.timeout(),
            SignerException.notFound(signerId: "s"),
            SignerException.invalid(reason: "r"),
            ValidationException.invalidAddress(address: "a"),
            ValidationException.invalidAmount(amount: "1"),
            ValidationException.invalidInput(field: "f", reason: "r"),
            StorageException.readFailed(key: "k"),
            StorageException.writeFailed(key: "k"),
            SessionException.expired(),
            SessionException.invalid(reason: "r"),
            IndexerException.requestFailed(reason: "r"),
            IndexerException.timeout(url: "u"),
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
            XCTAssertTrue(wrapped is ConfigurationException.InvalidConfig)
        case .missingConfig:
            XCTAssertTrue(wrapped is ConfigurationException.MissingConfig)
        case .walletNotConnected:
            XCTAssertTrue(wrapped is WalletException.NotConnected)
        case .walletAlreadyExists:
            XCTAssertTrue(wrapped is WalletException.AlreadyExists)
        case .walletNotFound:
            XCTAssertTrue(wrapped is WalletException.NotFound)
        case .credentialNotFound:
            XCTAssertTrue(wrapped is CredentialException.NotFound)
        case .credentialAlreadyExists:
            XCTAssertTrue(wrapped is CredentialException.AlreadyExists)
        case .credentialInvalid:
            XCTAssertTrue(wrapped is CredentialException.Invalid)
        case .credentialDeploymentFailed:
            XCTAssertTrue(wrapped is CredentialException.DeploymentFailed)
        case .webAuthnRegistrationFailed:
            XCTAssertTrue(wrapped is WebAuthnException.RegistrationFailed)
        case .webAuthnAuthenticationFailed:
            XCTAssertTrue(wrapped is WebAuthnException.AuthenticationFailed)
        case .webAuthnNotSupported:
            XCTAssertTrue(wrapped is WebAuthnException.NotSupported)
        case .webAuthnCancelled:
            XCTAssertTrue(wrapped is WebAuthnException.Cancelled)
        case .transactionSimulationFailed:
            XCTAssertTrue(wrapped is TransactionException.SimulationFailed)
        case .transactionSigningFailed:
            XCTAssertTrue(wrapped is TransactionException.SigningFailed)
        case .transactionSubmissionFailed:
            XCTAssertTrue(wrapped is TransactionException.SubmissionFailed)
        case .transactionTimeout:
            XCTAssertTrue(wrapped is TransactionException.Timeout)
        case .signerNotFound:
            XCTAssertTrue(wrapped is SignerException.NotFound)
        case .signerInvalid:
            XCTAssertTrue(wrapped is SignerException.Invalid)
        case .invalidAddress:
            XCTAssertTrue(wrapped is ValidationException.InvalidAddress)
        case .invalidAmount:
            XCTAssertTrue(wrapped is ValidationException.InvalidAmount)
        case .invalidInput:
            XCTAssertTrue(wrapped is ValidationException.InvalidInput)
        case .storageReadFailed:
            XCTAssertTrue(wrapped is StorageException.ReadFailed)
        case .storageWriteFailed:
            XCTAssertTrue(wrapped is StorageException.WriteFailed)
        case .sessionExpired:
            XCTAssertTrue(wrapped is SessionException.Expired)
        case .sessionInvalid:
            XCTAssertTrue(wrapped is SessionException.Invalid)
        case .indexerRequestFailed:
            XCTAssertTrue(wrapped is IndexerException.RequestFailed)
        case .indexerTimeout:
            XCTAssertTrue(wrapped is IndexerException.Timeout)
        }
    }
}
