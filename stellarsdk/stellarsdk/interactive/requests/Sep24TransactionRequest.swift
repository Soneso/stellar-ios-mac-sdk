import Foundation

/// Request parameters for querying a single transaction via SEP-0024.
///
/// This struct encapsulates the parameters needed to retrieve the status and details
/// of a specific deposit or withdrawal transaction. At least one of the transaction
/// identifiers (id, stellarTransactionId, or externalTransactionId) must be provided.
///
/// See also:
/// - [InteractiveService.getTransaction] for the method that uses this request
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24TransactionRequest {

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String

    /// The id of the transaction.
    public var id:String?

    /// The stellar transaction id of the transaction.
    public var stellarTransactionId:String?

    /// The external transaction id of the transaction.
    public var externalTransactionId:String?

    /// Defaults to en if not specified or if the specified language is not supported.
    /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
    public var lang:String?

    /// Creates a new transaction request.
    ///
    /// - Parameter jwt: JWT previously received from the anchor via SEP-10 authentication
    public init(jwt:String) {
        self.jwt = jwt
    }
}
