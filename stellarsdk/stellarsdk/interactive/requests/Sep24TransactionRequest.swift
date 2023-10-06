import Foundation

public struct Sep24TransactionRequest {

    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String
    
    /// (optional) The id of the transaction.
    public var id:String?
    
    /// (optional) The stellar transaction id of the transaction.
    public var stellarTransactionId:String?
    
    /// (optional) The stellar transaction id of the transaction.
    public var externalTransactionId:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported.
    /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
    public var lang:String?
    
    public init(jwt:String) {
        self.jwt = jwt
    }
}
