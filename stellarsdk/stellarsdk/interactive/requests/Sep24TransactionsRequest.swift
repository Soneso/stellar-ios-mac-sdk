import Foundation

/// Request parameters for querying multiple transactions via SEP-0024.
///
/// This struct encapsulates the parameters needed to retrieve a list of deposit
/// or withdrawal transactions for a specific asset, with optional filtering and pagination.
///
/// See also:
/// - [InteractiveService.getTransactions] for the method that uses this request
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
public struct Sep24TransactionsRequest {

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String

    /// The code of the asset of interest. E.g. BTC, ETH, USD, INR, etc.
    public var assetCode:String

    /// The response should contain transactions starting on or after this date and time.
    public var noOlderThan:Date?

    /// The response should contain at most limit transactions.
    public var limit:Int?

    /// The kind of transaction that is desired. Should be either deposit or withdrawal.
    public var kind:String?

    /// The response should contain transactions starting prior to this ID (exclusive).
    public var pagingId:String?

    /// Defaults to en if not specified or if the specified language is not supported.
    /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
    public var lang:String?

    /// Creates a new transactions request.
    ///
    /// - Parameters:
    ///   - jwt: JWT previously received from the anchor via SEP-10 authentication
    ///   - assetCode: The code of the asset of interest
    public init(jwt:String, assetCode:String) {
        self.jwt = jwt
        self.assetCode = assetCode
    }
}
