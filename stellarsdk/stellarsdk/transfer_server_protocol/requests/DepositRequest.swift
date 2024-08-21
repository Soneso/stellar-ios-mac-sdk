//
//  DepositRequest.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct DepositRequest {

    /// The code of the on-chain asset the user wants to get from the Anchor after doing an off-chain deposit. The value passed must match one of the codes listed in the /info response's deposit object.
    public var assetCode:String
    
    /// The stellar or muxed account ID of the user that wants to deposit. This is where the asset token will be sent. Note that the account specified in this request could differ from the account authenticated via SEP-10.
    public var account:String
    
    /// (optional) Type of memo that the anchor should attach to the Stellar payment transaction, one of text, id or hash.
    public var memoType:String?
    
    /// (optional) Value of memo to attach to transaction, for hash this should be base64-encoded. Because a memo can be specified in the SEP-10 JWT for Shared Accounts, this field as well as memo_type can be different than the values included in the SEP-10 JWT. For example, a client application could use the value passed for this parameter as a reference number used to match payments made to account.
    public var memo:String?
    
    /// (optional) Email address of depositor. If desired, an anchor can use this to send email updates to the user about the deposit.
    public var emailAddress:String?
    
    /// (optional) Type of deposit. If the anchor supports multiple deposit methods (e.g. SEPA or SWIFT), the wallet should specify type. This field may be necessary for the anchor to determine which KYC fields to collect.
    public var type:String?
    
    /// (deprecated,optional) In communications / pages about the deposit, anchor should display the wallet name to the user to explain where funds are going. However, anchors should use client_domain (for non-custodial) and sub value of JWT (for custodial) to determine wallet information.
    public var walletName:String?
    
    /// (deprecated,optional) Anchor should link to this when notifying the user that the transaction has completed. However, anchors should use client_domain (for non-custodial) and sub value of JWT (for custodial) to determine wallet information.
    public var walletUrl:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported. Language code specified using RFC 4646. error fields and other human readable messages in the response should be in this language.
    public var lang:String?
    
    /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint. The callback needs to be signed by the anchor and the signature needs to be verified by the wallet according to the callback signature specification.
    public var onChangeCallback:String?
    
    /// (optional) The amount of the asset the user would like to deposit with the anchor. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var amount:String?
    
    /// (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect..
    public var countryCode:String?
    
    /// (optional) true if the client supports receiving deposit transactions as a claimable balance, false otherwise.
    public var claimableBalanceSupported:String?
    
    /// (optional) id of an off-chain account (managed by the anchor) associated with this user's Stellar account (identified by the JWT's sub field). If the anchor supports SEP-12, the customer_id field should match the SEP-12 customer's id. customer_id should be passed only when the off-chain id is know to the client, but the relationship between this id and the user's Stellar account is not known to the Anchor.
    public var customerId:String?
    
    /// (optional)  id of the chosen location to drop off cash
    public var locationId:String?
    
    /// (optional) can be used to provide extra fields for the request.
    /// E.g. required fields from the /info endpoint that are not covered by the standard parameters.
    public var extraFields: [String : String]?
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String?
    
    public init(assetCode:String, account:String, jwt:String? = nil) {
        self.assetCode = assetCode
        self.account = account
        self.jwt = jwt
    }
    
}
