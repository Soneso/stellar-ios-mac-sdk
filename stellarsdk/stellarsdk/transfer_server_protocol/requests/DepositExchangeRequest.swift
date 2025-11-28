import Foundation

/// Request parameters for initiating a deposit with asset exchange via SEP-0006.
///
/// This struct encapsulates all the parameters needed to start a deposit flow where asset
/// conversion occurs between non-equivalent assets. For example, a user can deposit fiat BRL
/// via bank transfer and receive USDC on the Stellar network. This endpoint requires the
/// anchor to implement SEP-38 for quotes.
///
/// The flow supports both market rate conversions (using indicative quotes) and firm quote
/// conversions (where the exchange rate is guaranteed if payment is made before expiration).
///
/// See also:
/// - [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
/// - [SEP-0038](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)
public struct DepositExchangeRequest: Sendable {

    /// The code of the on-chain asset the user wants to receive from the anchor after making
    /// an off-chain deposit. The value passed must match one of the codes listed in the
    /// /info response's deposit-exchange object.
    public var destinationAsset:String

    /// The off-chain asset the anchor will receive from the user.
    /// The value must match one of the asset values included in a SEP-38
    /// GET /prices?buy_asset=stellar:<destination_asset>:<asset_issuer> response
    /// using SEP-38 Asset Identification Format.
    public var sourceAsset:String

    /// The amount of the source_asset the user would like to deposit to the anchor's off-chain account.
    /// This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    /// Should be equal to quote.sell_amount if a quote_id was used.
    public var amount:String

    /// The Stellar (G...), muxed (M...), or contract (C...) account ID of the user that wants to deposit.
    /// This is where the asset token will be sent. Note that the account specified in this request
    /// could differ from the account authenticated via SEP-10.
    public var account:String

    /// JWT previously received from the anchor via the SEP-10 authentication flow.
    public var jwt:String?

    /// The id returned from a SEP-38 POST /quote response.
    /// If this parameter is provided and the user delivers the deposit funds to the anchor before
    /// the quote expiration, the anchor should respect the conversion rate agreed in that quote.
    /// If the values of destination_asset, source_asset and amount conflict with the ones used to
    /// create the SEP-38 quote, this request should be rejected with a 400.
    public var quoteId:String?
    
    
    /// Type of memo that the anchor should attach to the Stellar payment transaction.
    /// One of text, id or hash.
    public var memoType:String?

    /// Value of memo to attach to transaction, for hash this should be base64-encoded.
    /// Because a memo can be specified in the SEP-10 JWT for Shared Accounts, this field
    /// as well as memo_type can be different than the values included in the SEP-10 JWT.
    /// For example, a client application could use the value passed for this parameter as
    /// a reference number used to match payments made to account.
    public var memo:String?

    /// Email address of depositor.
    /// If desired, an anchor can use this to send email updates to the user about the deposit.
    public var emailAddress:String?

    /// Type of deposit. If the anchor supports multiple deposit methods (e.g. SEPA or SWIFT),
    /// the wallet should specify type. This field may be necessary for the anchor to determine
    /// which KYC fields to collect.
    public var type:String?

    /// In communications about the deposit, anchor should display the wallet name to the user
    /// to explain where funds are going. However, anchors should use client_domain (for non-custodial)
    /// and sub value of JWT (for custodial) to determine wallet information.
    public var walletName:String?

    /// Anchor should link to this when notifying the user that the transaction has completed.
    /// However, anchors should use client_domain (for non-custodial) and sub value of JWT
    /// (for custodial) to determine wallet information.
    public var walletUrl:String?

    /// Language code specified using RFC 4646. Defaults to en if not specified.
    /// Error fields and other human readable messages in the response should be in this language.
    public var lang:String?

    /// A URL that the anchor should POST a JSON message to when the status property of the
    /// transaction created as a result of this request changes. The JSON message should be
    /// identical to the response format for the /transaction endpoint.
    public var onChangeCallback:String?

    /// The ISO 3166-1 alpha-3 code of the user's current address.
    /// This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var countryCode:String?

    /// "true" if the client supports receiving deposit transactions as a claimable balance, false otherwise.
    public var claimableBalanceSupported:String?

    /// ID of an off-chain account (managed by the anchor) associated with this user's Stellar account
    /// (identified by the JWT's sub field). If the anchor supports SEP-12, the customer_id field should
    /// match the SEP-12 customer's id. customer_id should be passed only when the off-chain id is known
    /// to the client, but the relationship between this id and the user's Stellar account is not known
    /// to the anchor.
    public var customerId:String?

    /// ID of the chosen location to drop off cash.
    public var locationId:String?

    /// Additional custom fields that can be used to provide extra information for the request.
    /// For example, required fields from the /info endpoint that are not covered by the standard parameters.
    public var extraFields: [String : String]?

    /// Creates a new deposit exchange request.
    ///
    /// - Parameters:
    ///   - destinationAsset: The on-chain asset the user wants to receive
    ///   - sourceAsset: The off-chain asset the anchor will receive
    ///   - amount: The amount of source_asset to deposit
    ///   - account: The Stellar account ID where the asset will be sent
    ///   - jwt: Optional JWT token from SEP-10 authentication
    public init(destinationAsset:String, sourceAsset:String, amount:String, account:String, jwt:String? = nil) {
        self.destinationAsset = destinationAsset
        self.sourceAsset = sourceAsset
        self.amount = amount
        self.account = account
        self.jwt = jwt
    }

}
