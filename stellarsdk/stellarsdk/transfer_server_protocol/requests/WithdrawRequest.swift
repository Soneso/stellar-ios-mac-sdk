//
//  WithdrawRequest.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct WithdrawRequest {

    /// Type of withdrawal. Can be: crypto, bank_account, cash, mobile, bill_payment or other custom values
    public var type:String
    
    /// Code of the asset the user wants to withdraw
    public var assetCode:String
    
    /// The account that the user wants to withdraw their funds to. This can be a crypto account, a bank account number, IBAN, mobile number, or email address.
    public var dest:String
    
    /// (optional) Extra information to specify withdrawal location. For crypto it may be a memo in addition to the dest address. It can also be a routing number for a bank, a BIC, or the name of a partner handling the withdrawal.
    public var destExtra:String?
    
    /// (optional) The stellar account ID of the user that wants to do the withdrawal. This is only needed if the anchor requires KYC information for withdrawal. The anchor can use account to look up the user's KYC information.
    public var account:String?
    
    /// (optional) A wallet will send this to uniquely identify a user if the wallet has multiple users sharing one Stellar account. The anchor can use this along with account to look up the user's KYC info.
    public var memo:String?
    
    /// (optional) type of memo. One of text, id or hash
    public var memoType:String?
    
    /// (optional) In communications / pages about the withdrawal, anchor should display the wallet name to the user to explain where funds are coming from.
    public var walletName:String?
    
    /// (optional) Anchor can show this to the user when referencing the wallet involved in the withdrawal (ex. in the anchor's transaction history).
    public var walletUrl:String?
    
    /// (optional) Defaults to en. Language code specified using ISO 639-1. error fields in the response should be in this language.
    public var lang:String?
    
    /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint.
    public var onChangeCallback:String?
    
    /// (optional) The amount of the asset the user would like to withdraw. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var amount:String?
    
    /// (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var countryCode:String?
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String?
    
    public init(type:String, assetCode:String, dest:String, jwt:String? = nil) {
        self.type = type
        self.assetCode = assetCode
        self.dest = dest
        self.jwt = jwt
    }
    
}

