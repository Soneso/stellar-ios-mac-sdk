//
//  SmartAccountErrors.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 23.01.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import Foundation

/// Error codes for Smart Account operations.
///
/// Error code ranges:
/// - 1xxx: Configuration errors
/// - 2xxx: Wallet state errors
/// - 3xxx: Credential errors
/// - 4xxx: WebAuthn errors
/// - 5xxx: Transaction errors
/// - 6xxx: Signer errors
/// - 7xxx: Validation errors
/// - 8xxx: Storage errors
/// - 9xxx: Session errors
public enum SmartAccountErrorCode: Int, Sendable {
    // 1xxx: Configuration errors
    case invalidConfig = 1001
    case missingConfig = 1002

    // 2xxx: Wallet state errors
    case walletNotConnected = 2001
    case walletAlreadyExists = 2002
    case walletNotFound = 2003

    // 3xxx: Credential errors
    case credentialNotFound = 3001
    case credentialAlreadyExists = 3002
    case credentialInvalid = 3003
    case credentialDeploymentFailed = 3004

    // 4xxx: WebAuthn errors
    case webAuthnRegistrationFailed = 4001
    case webAuthnAuthenticationFailed = 4002
    case webAuthnNotSupported = 4003
    case webAuthnCancelled = 4004

    // 5xxx: Transaction errors
    case transactionSimulationFailed = 5001
    case transactionSigningFailed = 5002
    case transactionSubmissionFailed = 5003
    case transactionTimeout = 5004

    // 6xxx: Signer errors
    case signerNotFound = 6001
    case signerInvalid = 6002

    // 7xxx: Validation errors
    case invalidAddress = 7001
    case invalidAmount = 7002
    case invalidInput = 7003

    // 8xxx: Storage errors
    case storageReadFailed = 8001
    case storageWriteFailed = 8002

    // 9xxx: Session errors
    case sessionExpired = 9001
    case sessionInvalid = 9002
}

/// Errors that occur during Smart Account operations.
///
/// SmartAccountError provides detailed error information including error codes,
/// descriptive messages, and optional underlying causes. It conforms to Error
/// and Sendable for safe concurrent usage.
///
/// Example error handling:
/// ```swift
/// do {
///     let wallet = try await smartAccountKit.createWallet(name: "My Wallet")
///     print("Wallet created: \(wallet.address)")
/// } catch let error as SmartAccountError {
///     switch error.code {
///     case .webAuthnCancelled:
///         print("User cancelled authentication")
///     case .credentialDeploymentFailed:
///         print("Failed to deploy contract: \(error.message)")
///     default:
///         print("Error \(error.code.rawValue): \(error.message)")
///     }
/// } catch {
///     print("Unexpected error: \(error)")
/// }
/// ```
public struct SmartAccountError: Error, Sendable {
    /// The specific error code identifying the type of failure.
    public let code: SmartAccountErrorCode
    /// A human-readable description of the error.
    public let message: String
    /// An optional underlying error that caused this error.
    public let cause: Error?

    /// Creates a new SmartAccountError.
    ///
    /// - Parameters:
    ///   - code: The error code identifying the type of failure
    ///   - message: A descriptive error message
    ///   - cause: An optional underlying error that caused this failure
    public init(code: SmartAccountErrorCode, message: String, cause: Error? = nil) {
        self.code = code
        self.message = message
        self.cause = cause
    }

    // MARK: - Configuration Errors

    /// Creates an error indicating invalid configuration.
    public static func invalidConfig(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .invalidConfig, message: message, cause: cause)
    }

    /// Creates an error indicating missing required configuration.
    public static func missingConfig(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .missingConfig, message: message, cause: cause)
    }

    // MARK: - Wallet State Errors

    /// Creates an error indicating the wallet is not connected.
    public static func walletNotConnected(_ message: String = "Wallet is not connected", cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .walletNotConnected, message: message, cause: cause)
    }

    /// Creates an error indicating the wallet already exists.
    public static func walletAlreadyExists(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .walletAlreadyExists, message: message, cause: cause)
    }

    /// Creates an error indicating the wallet was not found.
    public static func walletNotFound(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .walletNotFound, message: message, cause: cause)
    }

    // MARK: - Credential Errors

    /// Creates an error indicating the credential was not found.
    public static func credentialNotFound(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .credentialNotFound, message: message, cause: cause)
    }

    /// Creates an error indicating the credential already exists.
    public static func credentialAlreadyExists(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .credentialAlreadyExists, message: message, cause: cause)
    }

    /// Creates an error indicating the credential is invalid.
    public static func credentialInvalid(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .credentialInvalid, message: message, cause: cause)
    }

    /// Creates an error indicating credential deployment failed.
    public static func credentialDeploymentFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .credentialDeploymentFailed, message: message, cause: cause)
    }

    // MARK: - WebAuthn Errors

    /// Creates an error indicating WebAuthn registration failed.
    public static func webAuthnRegistrationFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .webAuthnRegistrationFailed, message: message, cause: cause)
    }

    /// Creates an error indicating WebAuthn authentication failed.
    public static func webAuthnAuthenticationFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .webAuthnAuthenticationFailed, message: message, cause: cause)
    }

    /// Creates an error indicating WebAuthn is not supported on this platform.
    public static func webAuthnNotSupported(_ message: String = "WebAuthn is not supported on this platform", cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .webAuthnNotSupported, message: message, cause: cause)
    }

    /// Creates an error indicating the user cancelled the WebAuthn operation.
    public static func webAuthnCancelled(_ message: String = "User cancelled WebAuthn operation", cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .webAuthnCancelled, message: message, cause: cause)
    }

    // MARK: - Transaction Errors

    /// Creates an error indicating transaction simulation failed.
    public static func transactionSimulationFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .transactionSimulationFailed, message: message, cause: cause)
    }

    /// Creates an error indicating transaction signing failed.
    public static func transactionSigningFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .transactionSigningFailed, message: message, cause: cause)
    }

    /// Creates an error indicating transaction submission failed.
    public static func transactionSubmissionFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .transactionSubmissionFailed, message: message, cause: cause)
    }

    /// Creates an error indicating the transaction timed out.
    public static func transactionTimeout(_ message: String = "Transaction timed out", cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .transactionTimeout, message: message, cause: cause)
    }

    // MARK: - Signer Errors

    /// Creates an error indicating the signer was not found.
    public static func signerNotFound(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .signerNotFound, message: message, cause: cause)
    }

    /// Creates an error indicating the signer is invalid.
    public static func signerInvalid(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .signerInvalid, message: message, cause: cause)
    }

    // MARK: - Validation Errors

    /// Creates an error indicating an invalid address.
    public static func invalidAddress(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .invalidAddress, message: message, cause: cause)
    }

    /// Creates an error indicating an invalid amount.
    public static func invalidAmount(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .invalidAmount, message: message, cause: cause)
    }

    /// Creates an error indicating invalid input.
    public static func invalidInput(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .invalidInput, message: message, cause: cause)
    }

    // MARK: - Storage Errors

    /// Creates an error indicating storage read operation failed.
    public static func storageReadFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .storageReadFailed, message: message, cause: cause)
    }

    /// Creates an error indicating storage write operation failed.
    public static func storageWriteFailed(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .storageWriteFailed, message: message, cause: cause)
    }

    // MARK: - Session Errors

    /// Creates an error indicating the session has expired.
    public static func sessionExpired(_ message: String = "Session has expired", cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .sessionExpired, message: message, cause: cause)
    }

    /// Creates an error indicating the session is invalid.
    public static func sessionInvalid(_ message: String, cause: Error? = nil) -> SmartAccountError {
        SmartAccountError(code: .sessionInvalid, message: message, cause: cause)
    }
}

// MARK: - LocalizedError Conformance

extension SmartAccountError: LocalizedError {
    public var errorDescription: String? {
        var description = "SmartAccountError [\(code.rawValue)]: \(message)"
        if let cause = cause {
            description += " (caused by: \(cause.localizedDescription))"
        }
        return description
    }
}

// MARK: - Smart Account Constants

/// Constants used throughout Smart Account operations.
public struct SmartAccountConstants: Sendable {
    /// Size in bytes of an uncompressed secp256r1 public key.
    public static let SECP256R1_PUBLIC_KEY_SIZE: Int = 65

    /// Prefix byte for uncompressed public keys (0x04).
    public static let UNCOMPRESSED_PUBKEY_PREFIX: UInt8 = 0x04

    /// Number of stroops (smallest unit) per XLM.
    public static let STROOPS_PER_XLM: Int64 = 10_000_000

    /// Base fee in stroops for Stellar transactions.
    public static let BASE_FEE: UInt32 = 100

    /// Average number of ledgers closed per hour on the Stellar network.
    public static let LEDGERS_PER_HOUR: Int = 720

    /// Average number of ledgers closed per day on the Stellar network.
    public static let LEDGERS_PER_DAY: Int = 17_280

    /// Buffer (in ledgers) to add when calculating auth entry expiration.
    public static let AUTH_ENTRY_EXPIRATION_BUFFER: Int = 100

    /// Default session expiry time in milliseconds (7 days).
    public static let DEFAULT_SESSION_EXPIRY_MS: Int64 = 604_800_000

    /// Default timeout for indexer requests in milliseconds (10 seconds).
    public static let DEFAULT_INDEXER_TIMEOUT_MS: Int64 = 10_000

    /// Default timeout for relayer requests in milliseconds (6 minutes).
    public static let DEFAULT_RELAYER_TIMEOUT_MS: Int64 = 360_000

    /// WebAuthn operation timeout in milliseconds (60 seconds).
    public static let WEBAUTHN_TIMEOUT_MS: Int64 = 60_000

    /// Amount of XLM reserved by Friendbot for test accounts.
    public static let FRIENDBOT_RESERVE_XLM: Int = 5

    /// URL of the Stellar Friendbot service for testnet funding.
    public static let FRIENDBOT_URL: String = "https://friendbot.stellar.org"

    /// Default timeout for general operations in seconds.
    public static let DEFAULT_TIMEOUT_SECONDS: Int = 30

    /// Maximum number of signers allowed per context rule.
    public static let MAX_SIGNERS: Int = 15

    /// Maximum number of policies allowed per context rule.
    public static let MAX_POLICIES: Int = 5

    /// Maximum number of context rules allowed per smart account.
    public static let MAX_CONTEXT_RULES: Int = 15

    /// Maximum number of transaction history entries to keep in storage.
    public static let MAX_HISTORY_ENTRIES: Int = 1000

    private init() {}
}
