//
//  WithdrawRequest.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct WithdrawRequest {

    /// Type of withdrawal. Can be: crypto, bank_account, cash, mobile, bill_payment or other custom values. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var type:String
    
    /// Code of the on-chain asset the user wants to withdraw. The value passed must match one of the codes listed in the /info response's withdraw object.
    public var assetCode:String
    
    /// (Deprecated) The account that the user wants to withdraw their funds to. This can be a crypto account, a bank account number, IBAN, mobile number, or email address.
    public var dest:String?
    
    /// (Deprecated,  optional) Extra information to specify withdrawal location. For crypto it may be a memo in addition to the dest address. It can also be a routing number for a bank, a BIC, or the name of a partner handling the withdrawal.
    public var destExtra:String?
    
    /// (optional) The Stellar or muxed account the client will use as the source of the withdrawal payment to the anchor. If SEP-10 authentication is not used, the anchor can use account to look up the user's KYC information. Note that the account specified in this request could differ from the account authenticated via SEP-10.
    public var account:String?
    
    /// (optional) This field should only be used if SEP-10 authentication is not. It was originally intended to distinguish users of the same Stellar account. However if SEP-10 is supported, the anchor should use the sub value included in the decoded SEP-10 JWT instead. See the Shared Account Authentication section for more information.
    public var memo:String?
    
    /// (Deprecated, optional) Type of memo. One of text, id or hash. Deprecated because memos used to identify users of the same Stellar account should always be of type of id.
    public var memoType:String?
    
    /// (deprecated, optional) In communications / pages about the withdrawal, anchor should display the wallet name to the user to explain where funds are coming from. However, anchors should use client_domain (for non-custodial) and sub value of JWT (for custodial) to determine wallet information.
    public var walletName:String?
    
    /// (deprecated, optional) Anchor can show this to the user when referencing the wallet involved in the withdrawal (ex. in the anchor's transaction history). However, anchors should use client_domain (for non-custodial) and sub value of JWT (for custodial) to determine wallet information.
    public var walletUrl:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported. Language code specified using RFC 4646. error fields and other human readable messages in the response should be in this language.
    public var lang:String?
    
    /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint. The callback needs to be signed by the anchor and the signature needs to be verified by the wallet according to the callback signature specification.
    public var onChangeCallback:String?
    
    /// (optional) The amount of the asset the user would like to withdraw. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var amount:String?
    
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
    
    public init(type:String, assetCode:String, jwt:String? = nil) {
        self.type = type
        self.assetCode = assetCode
        self.jwt = jwt
    }
    
}

