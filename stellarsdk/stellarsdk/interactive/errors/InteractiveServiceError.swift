import Foundation

/// Errors that can occur when interacting with SEP-0024 interactive anchor services.
///
/// These errors represent various failure scenarios when communicating with anchors
/// that implement the Hosted Deposit and Withdrawal protocol defined in SEP-0024.
///
/// See also:
/// - [InteractiveService] for the main interactive service implementation
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public enum InteractiveServiceError: Error, Sendable {
    /// The provided domain is invalid or malformed.
    case invalidDomain

    /// The stellar.toml file could not be parsed or contains invalid data.
    case invalidToml

    /// No transfer server URL is configured in the stellar.toml file.
    case noInteractiveServerSet

    /// Failed to parse the anchor's response. Contains the error message.
    case parsingResponseFailed(message:String)

    /// The anchor returned an error response. Contains the error message from the anchor.
    case anchorError(message:String)

    /// The requested resource was not found. Contains an optional error message.
    case notFound(message:String?)

    /// Authentication is required but credentials were not provided or are invalid.
    case authenticationRequired

    /// An error occurred when communicating with Horizon. Contains the underlying error.
    case horizonError(error: HorizonRequestError)
}
