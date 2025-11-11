import Foundation

/// Request parameters for initiating a withdrawal with asset exchange via SEP-0006.
///
/// This struct encapsulates all the parameters needed to start a withdrawal flow where asset
/// conversion occurs between non-equivalent assets. For example, a user can send USDC on the
/// Stellar network and withdraw fiat BRL to their bank account. This endpoint requires the
/// anchor to implement SEP-38 for quotes.
///
/// The flow supports both market rate conversions (using indicative quotes) and firm quote
/// conversions (where the exchange rate is guaranteed if payment is made before quote expiration).
///
/// See also:
/// - [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
/// - [SEP-0038](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)
public struct WithdrawExchangeRequest {

    /// Code of the on-chain asset the user wants to withdraw.
    /// The value passed must match one of the codes listed in the /info response's withdraw-exchange object.
    public var sourceAsset:String

    /// The off-chain asset the anchor will deliver to the user's account.
    /// The value must match one of the asset values included in a SEP-38
    /// GET /prices?sell_asset=stellar:<source_asset>:<asset_issuer> response
    /// using SEP-38 Asset Identification Format.
    public var destinationAsset:String

    /// The amount of the on-chain asset (source_asset) the user would like to send to the anchor's
    /// Stellar account. This field may be necessary for the anchor to determine what KYC information
    /// is necessary to collect. Should be equal to quote.sell_amount if a quote_id was used.
    public var amount:String

    /// Type of withdrawal.
    /// Can be: crypto, bank_account, cash, mobile, bill_payment or other custom values.
    /// This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var type:String

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String?

    /// The id returned from a SEP-38 POST /quote response.
    /// If this parameter is provided and the Stellar transaction used to send the asset to the anchor
    /// has a created_at timestamp earlier than the quote's expires_at attribute, the anchor should
    /// respect the conversion rate agreed in that quote. If the values of destination_asset, source_asset
    /// and amount conflict with the ones used to create the SEP-38 quote, this request should be rejected with a 400.
    public var quoteId:String?
    
    /// The account that the user wants to withdraw their funds to.
    /// This can be a crypto account, a bank account number, IBAN, mobile number, or email address.
    /// Deprecated: Anchors should use SEP-12 to collect this information.
    public var dest:String?

    /// Extra information to specify withdrawal location.
    /// For crypto it may be a memo in addition to the dest address. It can also be a routing number
    /// for a bank, a BIC, or the name of a partner handling the withdrawal.
    /// Deprecated: Anchors should use SEP-12 to collect this information.
    public var destExtra:String?

    /// The Stellar (G...), muxed (M...), or contract (C...) account of the user that wants to do the withdrawal.
    /// This is only needed if the anchor requires KYC information for withdrawal and SEP-10 authentication
    /// is not used. Instead, the anchor can use account to look up the user's KYC information.
    /// Note that the account specified in this request could differ from the account authenticated via SEP-10.
    public var account:String?

    /// This field should only be used if SEP-10 authentication is not.
    /// It was originally intended to distinguish users of the same Stellar account. However if SEP-10
    /// is supported, the anchor should use the sub value included in the decoded SEP-10 JWT instead.
    public var memo:String?

    /// Type of memo. One of text, id or hash.
    /// Deprecated because memos used to identify users of the same Stellar account should always be of type id.
    public var memoType:String?

    /// In communications about the withdrawal, anchor should display the wallet name to the user
    /// to explain where funds are coming from. However, anchors should use client_domain (for non-custodial)
    /// and sub value of JWT (for custodial) to determine wallet information.
    public var walletName:String?

    /// Anchor can show this to the user when referencing the wallet involved in the withdrawal.
    /// However, anchors should use client_domain (for non-custodial) and sub value of JWT (for custodial)
    /// to determine wallet information.
    public var walletUrl:String?

    /// Language code specified using RFC 4646. Defaults to en if not specified.
    /// Error fields and other human readable messages in the response should be in this language.
    public var lang:String?

    /// A URL that the anchor should POST a JSON message to when the status property of the
    /// transaction created as a result of this request changes. The JSON message should be
    /// identical to the response format for the /transaction endpoint. The callback needs to
    /// be signed by the anchor and the signature needs to be verified by the wallet according
    /// to the callback signature specification.
    public var onChangeCallback:String?

    /// The ISO 3166-1 alpha-3 code of the user's current address.
    /// This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var countryCode:String?

    /// The memo the anchor must use when sending refund payments back to the user.
    /// If not specified, the anchor should use the same memo used by the user to send the original payment.
    /// If specified, refund_memo_type must also be specified.
    public var refundMemo:String?

    /// The type of the refund_memo. Can be id, text, or hash.
    /// If specified, refund_memo must also be specified.
    public var refundMemoType:String?

    /// ID of an off-chain account (managed by the anchor) associated with this user's Stellar account
    /// (identified by the JWT's sub field). If the anchor supports SEP-12, the customer_id field should
    /// match the SEP-12 customer's id. customer_id should be passed only when the off-chain id is known
    /// to the client, but the relationship between this id and the user's Stellar account is not known
    /// to the anchor.
    public var customerId:String?

    /// ID of the chosen location to pick up cash.
    public var locationId:String?

    /// Additional custom fields that can be used to provide extra information for the request.
    /// For example, required fields from the /info endpoint that are not covered by the standard parameters.
    public var extraFields: [String : String]?

    /// Creates a new withdrawal exchange request.
    ///
    /// - Parameters:
    ///   - sourceAsset: The on-chain asset the user wants to withdraw
    ///   - destinationAsset: The off-chain asset the anchor will deliver
    ///   - amount: The amount of source_asset to send
    ///   - type: The type of withdrawal (crypto, bank_account, cash, etc)
    ///   - jwt: Optional JWT token from SEP-10 authentication
    public init(sourceAsset:String, destinationAsset:String, amount:String, type:String, jwt:String? = nil) {
        self.type = type
        self.sourceAsset = sourceAsset
        self.destinationAsset = destinationAsset
        self.amount = amount
        self.jwt = jwt
    }

}
