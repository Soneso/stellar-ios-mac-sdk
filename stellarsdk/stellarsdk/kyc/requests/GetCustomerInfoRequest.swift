import Foundation

/// Request parameters for retrieving customer information via SEP-0012.
///
/// This struct encapsulates all the parameters needed to check the status of a customer's KYC
/// information or to fetch the fields required by the anchor for customer registration.
/// The endpoint allows clients to either fetch requirements for a new customer or check
/// the status of an existing customer's KYC process.
///
/// See also:
/// - [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)
public struct GetCustomerInfoRequest: Sendable {

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String

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

    /// The type of action the customer is being KYCd for.
    /// Different types of customers may have different KYC requirements. For example, a customer
    /// could have an ACCEPTED status for one type but require additional information for another type.
    public var type:String?

    /// The transaction id with which the customer's info is associated.
    /// This is used when information from the customer depends on the transaction,
    /// such as when more information is required for larger amounts.
    public var transactionId:String?

    /// Language code specified using ISO 639-1. Defaults to en if not specified.
    /// Human readable descriptions, choices, and messages should be in this language.
    public var lang:String?

    /// Creates a new customer information request.
    ///
    /// - Parameters:
    ///   - jwt: JWT previously received from the anchor via SEP-10 authentication
    public init(jwt:String) {
        self.jwt = jwt
    }
}
