import Foundation

/// Request parameters for registering a callback URL via SEP-0012.
///
/// This struct encapsulates all the parameters needed to register a callback URL with the anchor.
/// The anchor will issue POST requests to the provided callback URL whenever the customer's
/// KYC status changes. This allows wallets to receive real-time updates about the customer's
/// KYC process without polling.
///
/// The anchor will send POST requests with the same payload format as the GET /customer endpoint
/// until the customer's status changes to ACCEPTED or REJECTED. The callback must be properly
/// signed by the anchor according to the callback signature specification.
///
/// See also:
/// - [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)
public struct PutCustomerCallbackRequest: Sendable {

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String

    /// A callback URL that the SEP-12 server will POST to when the state of the customer changes.
    /// The provided callback URL will replace any previously-set callback URL for this account.
    public var url:String

    /// The ID of the customer as returned in the response of a previous PUT request.
    /// If the customer has not been registered, they do not yet have an id.
    public var id:String?

    /// The server should infer the account from the sub value in the SEP-10 JWT to identify the customer.
    /// The account parameter is only used for backwards compatibility, and if explicitly provided in
    /// the request body it should match the sub value of the decoded SEP-10 JWT.
    public var account:String?

    /// The client-generated memo that uniquely identifies the customer.
    /// If a memo is present in the decoded SEP-10 JWT's sub value, it must match this parameter value.
    /// If a muxed account is used as the JWT's sub value, memos sent in requests must match the
    /// 64-bit integer subaccount ID of the muxed account.
    public var memo:String?

    /// Type of memo. One of text, id or hash.
    /// Deprecated because memos should always be of type id, although anchors should continue to
    /// support this parameter for outdated clients. If hash, memo should be base64-encoded.
    /// If a memo is present in the decoded SEP-10 JWT's sub value, this parameter can be ignored.
    public var memoType:String?

    /// Creates a new callback registration request.
    ///
    /// - Parameters:
    ///   - url: The callback URL that will receive status update notifications
    ///   - jwt: JWT previously received from the anchor via SEP-10 authentication
    public init(url:String, jwt:String) {
        self.url = url
        self.jwt = jwt
    }

    /// Converts the request parameters to a dictionary of data for form submission.
    ///
    /// - Returns: Dictionary mapping parameter names to their Data representations
    public func toParameters() -> [String:Data] {
        var parameters = [String:Data]()
        if let id = id {
            parameters["id"] = id.data(using: .utf8)
        }
        if let account = account {
            parameters["account"] = account.data(using: .utf8)
        }
        if let memo = memo {
            parameters["memo"] = memo.data(using: .utf8)
        }
        if let memoType = memoType {
            parameters["memo_type"] = memoType.data(using: .utf8)
        }

        parameters["url"] = url.data(using: .utf8)

        return parameters
    }

}
