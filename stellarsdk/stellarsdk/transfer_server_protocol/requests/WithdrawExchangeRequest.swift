//
//  WithdrawExchangeRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 27.02.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

public struct WithdrawExchangeRequest {

    /// Code of the on-chain asset the user wants to withdraw. The value passed must match one of the codes listed in the /info response's withdraw-exchange object.
    public var sourceAsset:String
    
    /// The off-chain asset the Anchor will deliver to the user's account. The value must match one of the asset values included in a SEP-38 GET /prices?sell_asset=stellar:<source_asset>:<asset_issuer> response using SEP-38 Asset Identification Format.
    public var destinationAsset:String
    
    /// (optional) The id returned from a SEP-38 POST /quote response. If this parameter is provided and the Stellar transaction used to send the asset to the Anchor has a created_at timestamp earlier than the quote's expires_at attribute, the Anchor should respect the conversion rate agreed in that quote. If the values of destination_asset, source_asset and amount conflict with the ones used to create the SEP-38 quote, this request should be rejected with a 400.
    public var quoteId:String?
    
    /// The amount of the on-chain asset (source_asset) the user would like to send to the anchor's Stellar account. This field may be necessary for the anchor to determine what KYC information is necessary to collect. Should be equals to quote.sell_amount if a quote_id was used.
    public var amount:String
    
    /// Type of withdrawal. Can be: crypto, bank_account, cash, mobile, bill_payment or other custom values. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var type:String
    
    /// (Deprecated) The account that the user wants to withdraw their funds to. This can be a crypto account, a bank account number, IBAN, mobile number, or email address.
    public var dest:String?
    
    /// (Deprecated) Extra information to specify withdrawal location. For crypto it may be a memo in addition to the dest address. It can also be a routing number for a bank, a BIC, or the name of a partner handling the withdrawal.
    public var destExtra:String?
    
    /// (optional) The Stellar or muxed account of the user that wants to do the withdrawal. This is only needed if the anchor requires KYC information for withdrawal and SEP-10 authentication is not used. Instead, the anchor can use account to look up the user's KYC information. Note that the account specified in this request could differ from the account authenticated via SEP-10.
    public var account:String?
    
    ///(optional) This field should only be used if SEP-10 authentication is not. It was originally intended to distinguish users of the same Stellar account. However if SEP-10 is supported, the anchor should use the sub value included in the decoded SEP-10 JWT instead. See the Shared Account Authentication section for more information.
    public var memo:String?
    
    /// (Deprecated, optional) Type of memo. One of text, id or hash. Deprecated because memos used to identify users of the same Stellar account should always be of type of id.
    public var memoType:String?
    
    /// (optional) In communications / pages about the withdrawal, anchor should display the wallet name to the user to explain where funds are coming from.
    public var walletName:String?
    
    /// (deprecated,optional) Anchor can show this to the user when referencing the wallet involved in the withdrawal (ex. in the anchor's transaction history). However, anchors should use client_domain (for non-custodial) and sub value of JWT (for custodial) to determine wallet information.
    public var walletUrl:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported. Language code specified using RFC 4646. error fields and other human readable messages in the response should be in this language.
    public var lang:String?
    
    /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint. The callback needs to be signed by the anchor and the signature needs to be verified by the wallet according to the callback signature specification.
    public var onChangeCallback:String?
    
    /// (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var countryCode:String?
    
    /// (optional) The memo the anchor must use when sending refund payments back to the user. If not specified, the anchor should use the same memo used by the user to send the original payment. If specified, refund_memo_type must also be specified.
    public var refundMemo:String?
    
    /// (optional) The type of the refund_memo. Can be id, text, or hash. See the memos documentation for more information. If specified, refund_memo must also be specified.
    public var refundMemoType:String?
    
    /// (optional) id of an off-chain account (managed by the anchor) associated with this user's Stellar account (identified by the JWT's sub field). If the anchor supports SEP-12, the customer_id field should match the SEP-12 customer's id. customer_id should be passed only when the off-chain id is know to the client, but the relationship between this id and the user's Stellar account is not known to the Anchor.
    public var customerId:String?
    
    /// (optional) id of the chosen location to pick up cash
    public var locationId:String?
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String?
    
    public init(sourceAsset:String, destinationAsset:String, amount:String, type:String, jwt:String? = nil) {
        self.type = type
        self.sourceAsset = sourceAsset
        self.destinationAsset = destinationAsset
        self.amount = amount
        self.jwt = jwt
    }
    
}
