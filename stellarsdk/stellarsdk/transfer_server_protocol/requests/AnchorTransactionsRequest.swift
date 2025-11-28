import Foundation

/// Request parameters for retrieving transaction history via SEP-0006.
///
/// This struct encapsulates all the parameters needed to fetch a list of historical transactions
/// for a specific asset and account. The response includes details about deposits, withdrawals,
/// and their current statuses. This endpoint is useful for displaying transaction history
/// to users within a wallet application.
///
/// See also:
/// - [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
public struct AnchorTransactionsRequest: Sendable {

    /// The code of the asset of interest.
    /// Examples: BTC, ETH, USD, INR, etc.
    public var assetCode:String

    /// The stellar account ID involved in the transactions.
    /// If the service requires SEP-10 authentication, this parameter must match the authenticated account.
    public var account:String

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String?

    /// The response should contain transactions starting on or after this date and time.
    public var noOlderThan:Date?

    /// The response should contain at most this number of transactions.
    public var limit:Int?

    /// A comma-separated list of transaction kinds to filter by.
    /// Possible values are: deposit, deposit-exchange, withdrawal, withdrawal-exchange.
    public var kind:String?

    /// The response should contain transactions starting prior to this ID (exclusive).
    /// Used for pagination.
    public var pagingId:String?

    /// Language code specified using RFC 4646. Defaults to en if not specified.
    /// Error fields and other human readable messages in the response should be in this language.
    public var lang:String?

    /// Creates a new transactions history request.
    ///
    /// - Parameters:
    ///   - assetCode: The code of the asset to query transactions for
    ///   - account: The Stellar account ID involved in the transactions
    ///   - jwt: Optional JWT token from SEP-10 authentication
    public init(assetCode:String, account:String, jwt:String? = nil) {
        self.assetCode = assetCode
        self.account = account
        self.jwt = jwt
    }
}

/// Request parameters for retrieving a single transaction via SEP-0006.
///
/// This struct encapsulates the parameters needed to fetch details about a specific transaction.
/// The transaction can be identified by its internal ID, Stellar transaction ID, or external
/// transaction ID. At least one of these identifiers must be provided.
///
/// See also:
/// - [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
public struct AnchorTransactionRequest: Sendable {

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String?

    /// The internal ID of the transaction assigned by the anchor.
    public var id:String?

    /// The Stellar transaction hash of the transaction.
    public var stellarTransactionId:String?

    /// The external transaction ID assigned by external systems.
    public var externalTransactionId:String?

    /// Language code specified using RFC 4646. Defaults to en if not specified.
    /// Error fields and other human readable messages in the response should be in this language.
    public var lang:String?

    /// Creates a new single transaction request.
    ///
    /// At least one of the transaction identifiers (id, stellarTransactionId, or externalTransactionId)
    /// must be provided.
    ///
    /// - Parameters:
    ///   - id: Optional internal transaction ID
    ///   - stellarTransactionId: Optional Stellar transaction hash
    ///   - externalTransactionId: Optional external transaction ID
    ///   - jwt: Optional JWT token from SEP-10 authentication
    public init(id:String? = nil, stellarTransactionId:String? = nil, externalTransactionId:String? = nil, jwt:String? = nil) {
        self.id = id
        self.stellarTransactionId = stellarTransactionId
        self.externalTransactionId = externalTransactionId
        self.jwt = jwt
    }
}
