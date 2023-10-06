import Foundation

public struct Sep24TransactionsRequest {

    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String
    
    /// The code of the asset of interest. E.g. BTC, ETH, USD, INR, etc.
    public var assetCode:String
    
    /// (optional) The response should contain transactions starting on or after this date & time.
    public var noOlderThan:Date?
    
    /// (optional) The response should contain at most limit transactions.
    public var limit:Int?
    
    /// (optional) The kind of transaction that is desired. Should be either deposit or withdrawal.
    public var kind:String?
    
    /// (optional) The response should contain transactions starting prior to this ID (exclusive).
    public var pagingId:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported.
    /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
    public var lang:String?
    
    public init(jwt:String, assetCode:String) {
        self.jwt = jwt
        self.assetCode = assetCode
    }
}
