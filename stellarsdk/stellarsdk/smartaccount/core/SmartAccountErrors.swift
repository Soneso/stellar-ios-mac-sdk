//
//  SmartAccountErrors.swift
//  stellarsdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Foundation

/// Stable numeric identifier for every Smart Account error condition.
///
/// Error code ranges:
/// - `1xxx`: Configuration errors
/// - `2xxx`: Wallet state errors
/// - `3xxx`: Credential errors
/// - `4xxx`: WebAuthn errors
/// - `5xxx`: Transaction errors
/// - `6xxx`: Signer errors
/// - `7xxx`: Validation errors
/// - `8xxx`: Storage errors
/// - `9xxx`: Session errors
/// - `10xxx`: Indexer errors
public enum SmartAccountErrorCode: Int, Sendable, CaseIterable {

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

    /// Deploying a credential-backed wallet contract failed.
    case credentialDeploymentFailed = 3004

    // 4xxx: WebAuthn errors

    /// WebAuthn registration failed before a credential was created.
    case webAuthnRegistrationFailed = 4001

    case webAuthnAuthenticationFailed = 4002
    case webAuthnNotSupported = 4003
    case webAuthnCancelled = 4004

    // 5xxx: Transaction errors

    case transactionSimulationFailed = 5001
    case transactionSigningFailed = 5002
    case transactionSubmissionFailed = 5003

    /// Polling for transaction completion timed out.
    case transactionTimeout = 5004

    // 6xxx: Signer errors

    case signerNotFound = 6001
    case signerInvalid = 6002

    // 7xxx: Validation errors

    /// The supplied address is not a valid Stellar `G…` or `C…` strkey.
    case invalidAddress = 7001

    case invalidAmount = 7002
    case invalidInput = 7003

    // 8xxx: Storage errors

    case storageReadFailed = 8001
    case storageWriteFailed = 8002

    // 9xxx: Session errors

    /// The session has expired and must be re-established.
    case sessionExpired = 9001

    case sessionInvalid = 9002

    // 10xxx: Indexer errors

    case indexerRequestFailed = 10001
    case indexerTimeout = 10002

    /// Stable numeric error code.
    ///
    /// Equivalent to `rawValue`; provided as a named accessor so callers can refer to
    /// the error code by name without depending on the underlying enum representation.
    public var code: Int { rawValue }
}

/// Base class for every error surfaced by the Smart Account Kit.
///
/// Every error path in the kit funnels into a `SmartAccountException` subclass so callers
/// can rely on a single typed channel for error handling and can map errors back to a
/// stable numeric `SmartAccountErrorCode`.
///
/// Every concrete leaf subclass declares the same `init(message: String, cause: Error? = nil)`.
///
/// Example:
/// ```swift
/// do {
///     try await kit.createWallet(name: "My Wallet")
/// } catch let error as WebAuthnException.Cancelled {
///     print("User cancelled authentication")
/// } catch let error as CredentialException.DeploymentFailed {
///     print("Deployment failed: \(error.message)")
/// } catch let error as SmartAccountException {
///     print("Smart account error \(error.code.code): \(error.message)")
/// }
/// ```
public class SmartAccountException: Error, CustomStringConvertible, @unchecked Sendable {

    /// Stable numeric error code identifying the condition that triggered this exception.
    public let code: SmartAccountErrorCode

    /// Human-readable description of the condition.
    public let message: String

    /// Optional underlying error that caused this exception, preserved for diagnostics.
    public let cause: Error?

    /// Initializes a new `SmartAccountException`.
    ///
    /// - Parameters:
    ///   - code: The stable numeric error code for the condition.
    ///   - message: Human-readable description of the condition.
    ///   - cause: Optional underlying error that triggered this exception.
    fileprivate init(code: SmartAccountErrorCode, message: String, cause: Error? = nil) {
        self.code = code
        self.message = message
        self.cause = cause
    }

    /// Stable string representation including the numeric code and message, plus the cause's
    /// message when one is present.
    public var description: String {
        var output = "SmartAccountException [\(code.code)]: \(message)"
        if let causeMessage = SmartAccountException.message(of: cause) {
            output += " (caused by: \(causeMessage))"
        }
        return output
    }

    /// Wraps an arbitrary error into a `SmartAccountException`.
    ///
    /// If `err` is already a `SmartAccountException`, it is returned unchanged so the original
    /// typed information is preserved through pass-through layers. Otherwise a new exception
    /// subclass matching `defaultCode` is constructed, with the original error preserved as
    /// `cause` for diagnostics.
    ///
    /// - Parameters:
    ///   - err: The error to wrap.
    ///   - defaultCode: The error code to use when wrapping a non-`SmartAccountException`
    ///     error. Defaults to `.invalidInput`.
    /// - Returns: A `SmartAccountException` representing the original error.
    public static func wrapError(
        _ err: Error,
        defaultCode: SmartAccountErrorCode = .invalidInput
    ) -> SmartAccountException {
        if let smartAccountError = err as? SmartAccountException {
            return smartAccountError
        }
        let message = SmartAccountException.message(of: err) ?? String(describing: err)
        switch defaultCode {
        case .invalidConfig:
            return ConfigurationException.InvalidConfig(message: message, cause: err)
        case .missingConfig:
            return ConfigurationException.MissingConfig(message: message, cause: err)
        case .walletNotConnected:
            return WalletException.NotConnected(message: message, cause: err)
        case .walletAlreadyExists:
            return WalletException.AlreadyExists(message: message, cause: err)
        case .walletNotFound:
            return WalletException.NotFound(message: message, cause: err)
        case .credentialNotFound:
            return CredentialException.NotFound(message: message, cause: err)
        case .credentialAlreadyExists:
            return CredentialException.AlreadyExists(message: message, cause: err)
        case .credentialInvalid:
            return CredentialException.Invalid(message: message, cause: err)
        case .credentialDeploymentFailed:
            return CredentialException.DeploymentFailed(message: message, cause: err)
        case .webAuthnRegistrationFailed:
            return WebAuthnException.RegistrationFailed(message: message, cause: err)
        case .webAuthnAuthenticationFailed:
            return WebAuthnException.AuthenticationFailed(message: message, cause: err)
        case .webAuthnNotSupported:
            return WebAuthnException.NotSupported(message: message, cause: err)
        case .webAuthnCancelled:
            return WebAuthnException.Cancelled(message: message, cause: err)
        case .transactionSimulationFailed:
            return TransactionException.SimulationFailed(message: message, cause: err)
        case .transactionSigningFailed:
            return TransactionException.SigningFailed(message: message, cause: err)
        case .transactionSubmissionFailed:
            return TransactionException.SubmissionFailed(message: message, cause: err)
        case .transactionTimeout:
            return TransactionException.Timeout(message: message, cause: err)
        case .signerNotFound:
            return SignerException.NotFound(message: message, cause: err)
        case .signerInvalid:
            return SignerException.Invalid(message: message, cause: err)
        case .invalidAddress:
            return ValidationException.InvalidAddress(message: message, cause: err)
        case .invalidAmount:
            return ValidationException.InvalidAmount(message: message, cause: err)
        case .invalidInput:
            return ValidationException.InvalidInput(message: message, cause: err)
        case .storageReadFailed:
            return StorageException.ReadFailed(message: message, cause: err)
        case .storageWriteFailed:
            return StorageException.WriteFailed(message: message, cause: err)
        case .sessionExpired:
            return SessionException.Expired(message: message, cause: err)
        case .sessionInvalid:
            return SessionException.Invalid(message: message, cause: err)
        case .indexerRequestFailed:
            return IndexerException.RequestFailed(message: message, cause: err)
        case .indexerTimeout:
            return IndexerException.Timeout(message: message, cause: err)
        }
    }

    /// Best-effort message extraction for an arbitrary error, used when formatting `cause`
    /// information without losing the underlying description.
    private static func message(of error: Error?) -> String? {
        guard let error = error else { return nil }
        if let smartAccountError = error as? SmartAccountException {
            return smartAccountError.message
        }
        let localized = error.localizedDescription
        if !localized.isEmpty {
            return localized
        }
        return String(describing: error)
    }
}

/// Configuration-related errors (1xxx range).
public class ConfigurationException: SmartAccountException, @unchecked Sendable {

    /// Indicates that a supplied configuration value is malformed or rejected.
    public final class InvalidConfig: ConfigurationException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .invalidConfig, message: message, cause: cause)
        }
    }

    /// Indicates that a required configuration parameter is missing.
    public final class MissingConfig: ConfigurationException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .missingConfig, message: message, cause: cause)
        }
    }

    public static func invalidConfig(details: String, cause: Error? = nil) -> InvalidConfig {
        return InvalidConfig(message: "Invalid configuration: \(details)", cause: cause)
    }

    public static func missingConfig(param: String, cause: Error? = nil) -> MissingConfig {
        return MissingConfig(message: "Missing required configuration: \(param)", cause: cause)
    }
}

/// Wallet state-related errors (2xxx range).
public class WalletException: SmartAccountException, @unchecked Sendable {

    /// Indicates that no wallet is currently connected.
    public final class NotConnected: WalletException, @unchecked Sendable {

        public init(message: String = "Wallet is not connected", cause: Error? = nil) {
            super.init(code: .walletNotConnected, message: message, cause: cause)
        }
    }

    /// Indicates that a wallet with the same identifier already exists.
    public final class AlreadyExists: WalletException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .walletAlreadyExists, message: message, cause: cause)
        }
    }

    /// Indicates that the requested wallet was not found.
    public final class NotFound: WalletException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .walletNotFound, message: message, cause: cause)
        }
    }

    public static func notConnected(details: String? = nil, cause: Error? = nil) -> NotConnected {
        return NotConnected(message: details ?? "Wallet is not connected", cause: cause)
    }

    public static func alreadyExists(identifier: String, cause: Error? = nil) -> AlreadyExists {
        return AlreadyExists(message: "Wallet already exists: \(identifier)", cause: cause)
    }

    public static func notFound(identifier: String, cause: Error? = nil) -> NotFound {
        return NotFound(message: "Wallet not found: \(identifier)", cause: cause)
    }
}

/// Credential-related errors (3xxx range).
public class CredentialException: SmartAccountException, @unchecked Sendable {

    /// Indicates that the requested credential was not found.
    public final class NotFound: CredentialException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .credentialNotFound, message: message, cause: cause)
        }
    }

    /// Indicates that a credential with the same identifier already exists.
    public final class AlreadyExists: CredentialException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .credentialAlreadyExists, message: message, cause: cause)
        }
    }

    /// Indicates that the credential is malformed or rejected during validation.
    public final class Invalid: CredentialException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .credentialInvalid, message: message, cause: cause)
        }
    }

    /// Indicates that deploying a credential-backed wallet contract failed.
    public final class DeploymentFailed: CredentialException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .credentialDeploymentFailed, message: message, cause: cause)
        }
    }

    public static func notFound(credentialId: String, cause: Error? = nil) -> NotFound {
        return NotFound(message: "Credential not found: \(credentialId)", cause: cause)
    }

    public static func alreadyExists(credentialId: String, cause: Error? = nil) -> AlreadyExists {
        return AlreadyExists(message: "Credential already exists: \(credentialId)", cause: cause)
    }

    public static func invalid(reason: String, cause: Error? = nil) -> Invalid {
        return Invalid(message: "Invalid credential: \(reason)", cause: cause)
    }

    public static func deploymentFailed(reason: String, cause: Error? = nil) -> DeploymentFailed {
        return DeploymentFailed(message: "Credential deployment failed: \(reason)", cause: cause)
    }
}

/// WebAuthn-related errors (4xxx range).
public class WebAuthnException: SmartAccountException, @unchecked Sendable {

    /// Indicates that WebAuthn registration failed before a credential was created.
    public final class RegistrationFailed: WebAuthnException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .webAuthnRegistrationFailed, message: message, cause: cause)
        }
    }

    /// Indicates that WebAuthn authentication failed.
    public final class AuthenticationFailed: WebAuthnException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .webAuthnAuthenticationFailed, message: message, cause: cause)
        }
    }

    /// Indicates that the platform does not support WebAuthn for this operation.
    public final class NotSupported: WebAuthnException, @unchecked Sendable {

        public init(message: String = "WebAuthn is not supported on this platform", cause: Error? = nil) {
            super.init(code: .webAuthnNotSupported, message: message, cause: cause)
        }
    }

    /// Indicates that the user cancelled the WebAuthn operation.
    public final class Cancelled: WebAuthnException, @unchecked Sendable {

        public init(message: String = "User cancelled WebAuthn operation", cause: Error? = nil) {
            super.init(code: .webAuthnCancelled, message: message, cause: cause)
        }
    }

    public static func registrationFailed(reason: String, cause: Error? = nil) -> RegistrationFailed {
        return RegistrationFailed(message: "WebAuthn registration failed: \(reason)", cause: cause)
    }

    public static func authenticationFailed(reason: String, cause: Error? = nil) -> AuthenticationFailed {
        return AuthenticationFailed(message: "WebAuthn authentication failed: \(reason)", cause: cause)
    }

    public static func notSupported(details: String? = nil, cause: Error? = nil) -> NotSupported {
        return NotSupported(message: details ?? "WebAuthn is not supported on this platform", cause: cause)
    }

    public static func cancelled(cause: Error? = nil) -> Cancelled {
        return Cancelled(cause: cause)
    }
}

/// Transaction-related errors (5xxx range).
public class TransactionException: SmartAccountException, @unchecked Sendable {

    /// Indicates that transaction simulation against the RPC failed.
    public final class SimulationFailed: TransactionException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .transactionSimulationFailed, message: message, cause: cause)
        }
    }

    /// Indicates that producing or attaching a signature failed.
    public final class SigningFailed: TransactionException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .transactionSigningFailed, message: message, cause: cause)
        }
    }

    /// Indicates that submitting the signed transaction failed.
    public final class SubmissionFailed: TransactionException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .transactionSubmissionFailed, message: message, cause: cause)
        }
    }

    /// Indicates that polling for transaction completion timed out.
    public final class Timeout: TransactionException, @unchecked Sendable {

        public init(message: String = "Transaction timed out", cause: Error? = nil) {
            super.init(code: .transactionTimeout, message: message, cause: cause)
        }
    }

    public static func simulationFailed(reason: String, cause: Error? = nil) -> SimulationFailed {
        return SimulationFailed(message: "Transaction simulation failed: \(reason)", cause: cause)
    }

    public static func signingFailed(reason: String, cause: Error? = nil) -> SigningFailed {
        return SigningFailed(message: "Transaction signing failed: \(reason)", cause: cause)
    }

    public static func submissionFailed(reason: String, cause: Error? = nil) -> SubmissionFailed {
        return SubmissionFailed(message: "Transaction submission failed: \(reason)", cause: cause)
    }

    public static func timeout(details: String? = nil, cause: Error? = nil) -> Timeout {
        return Timeout(message: details ?? "Transaction timed out", cause: cause)
    }
}

/// Signer-related errors (6xxx range).
public class SignerException: SmartAccountException, @unchecked Sendable {

    /// Indicates that the requested signer is not registered on the wallet.
    public final class NotFound: SignerException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .signerNotFound, message: message, cause: cause)
        }
    }

    /// Indicates that the signer is malformed or rejected during validation.
    public final class Invalid: SignerException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .signerInvalid, message: message, cause: cause)
        }
    }

    public static func notFound(signerId: String, cause: Error? = nil) -> NotFound {
        return NotFound(message: "Signer not found: \(signerId)", cause: cause)
    }

    public static func invalid(reason: String, cause: Error? = nil) -> Invalid {
        return Invalid(message: "Invalid signer: \(reason)", cause: cause)
    }
}

/// Validation-related errors (7xxx range).
public class ValidationException: SmartAccountException, @unchecked Sendable {

    /// Indicates that the supplied address is not a valid Stellar `G…` or `C…` strkey.
    public final class InvalidAddress: ValidationException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .invalidAddress, message: message, cause: cause)
        }
    }

    /// Indicates that the supplied amount is malformed or out of range.
    public final class InvalidAmount: ValidationException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .invalidAmount, message: message, cause: cause)
        }
    }

    /// Indicates that a user-supplied input failed validation.
    public final class InvalidInput: ValidationException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .invalidInput, message: message, cause: cause)
        }
    }

    public static func invalidAddress(address: String, cause: Error? = nil) -> InvalidAddress {
        return InvalidAddress(message: "Invalid address: \(address)", cause: cause)
    }

    /// Builds an `InvalidAmount` error with a uniform `"Invalid amount: <amount>"` message,
    /// optionally suffixed with `" - <reason>"` when a reason is provided.
    public static func invalidAmount(
        amount: String,
        reason: String? = nil,
        cause: Error? = nil
    ) -> InvalidAmount {
        let suffix = reason.map { " - \($0)" } ?? ""
        return InvalidAmount(message: "Invalid amount: \(amount)\(suffix)", cause: cause)
    }

    public static func invalidInput(
        field: String,
        reason: String,
        cause: Error? = nil
    ) -> InvalidInput {
        return InvalidInput(message: "Invalid input for \(field): \(reason)", cause: cause)
    }
}

/// Storage-related errors (8xxx range).
public class StorageException: SmartAccountException, @unchecked Sendable {

    /// Indicates that reading from the storage backend failed.
    public final class ReadFailed: StorageException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .storageReadFailed, message: message, cause: cause)
        }
    }

    /// Indicates that writing to the storage backend failed.
    public final class WriteFailed: StorageException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .storageWriteFailed, message: message, cause: cause)
        }
    }

    public static func readFailed(key: String, cause: Error? = nil) -> ReadFailed {
        return ReadFailed(message: "Storage read failed for key: \(key)", cause: cause)
    }

    public static func writeFailed(key: String, cause: Error? = nil) -> WriteFailed {
        return WriteFailed(message: "Storage write failed for key: \(key)", cause: cause)
    }
}

/// Session-related errors (9xxx range).
public class SessionException: SmartAccountException, @unchecked Sendable {

    /// Indicates that the session has expired.
    public final class Expired: SessionException, @unchecked Sendable {

        public init(message: String = "Session has expired", cause: Error? = nil) {
            super.init(code: .sessionExpired, message: message, cause: cause)
        }
    }

    /// Indicates that the session is malformed or rejected during validation.
    public final class Invalid: SessionException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .sessionInvalid, message: message, cause: cause)
        }
    }

    /// Builds an `Expired` error.
    ///
    /// When `sessionId` is provided the message is `"Session expired: <sessionId>"`; otherwise
    /// the default `"Session has expired"` message is used.
    public static func expired(sessionId: String? = nil, cause: Error? = nil) -> Expired {
        let message = sessionId.map { "Session expired: \($0)" } ?? "Session has expired"
        return Expired(message: message, cause: cause)
    }

    public static func invalid(reason: String, cause: Error? = nil) -> Invalid {
        return Invalid(message: "Invalid session: \(reason)", cause: cause)
    }
}

/// Indexer-related errors (10xxx range).
public class IndexerException: SmartAccountException, @unchecked Sendable {

    /// Indicates that an indexer request failed (network error or non-success HTTP status).
    public final class RequestFailed: IndexerException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .indexerRequestFailed, message: message, cause: cause)
        }
    }

    /// Indicates that an indexer request timed out.
    public final class Timeout: IndexerException, @unchecked Sendable {

        public init(message: String, cause: Error? = nil) {
            super.init(code: .indexerTimeout, message: message, cause: cause)
        }
    }

    public static func requestFailed(reason: String, cause: Error? = nil) -> RequestFailed {
        return RequestFailed(message: "Indexer request failed: \(reason)", cause: cause)
    }

    public static func timeout(url: String, cause: Error? = nil) -> Timeout {
        return Timeout(message: "Indexer request timed out: \(url)", cause: cause)
    }
}
