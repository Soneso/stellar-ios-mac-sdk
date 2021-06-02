//
//  DepositRequest.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 07/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct DepositRequest {

    /// The code of the asset the user is wanting to deposit with the anchor. Ex BTC,ETH,USD,INR,etc
    public var assetCode:String
    
    /// The stellar account ID of the user that wants to deposit. This is where the asset token will be sent.
    public var account:String
    
    /// (optional) type of memo that anchor should attach to the Stellar payment transaction, one of text, id or hash
    public var memoType:String?
    
    /// (optional) value of memo to attach to transaction, for hash this should be base64-encoded.
    public var memo:String?
    
    /// (optional) Email address of depositor. If desired, an anchor can use this to send email updates to the user about the deposit.
    public var emailAddress:String?
    
    /// (optional) Type of deposit. If the anchor supports multiple deposit methods (e.g. SEPA or SWIFT), the wallet should specify type. This field may be necessary for the anchor to determine which KYC fields to collect.
    public var type:String?
    
    /// (optional) In communications / pages about the deposit, anchor should display the wallet name to the user to explain where funds are going.
    public var walletName:String?
    
    /// (optional) Anchor should link to this when notifying the user that the transaction has completed.
    public var walletUrl:String?
    
    /// (optional) Defaults to en. Language code specified using ISO 639-1. error fields in the response should be in this language.
    public var lang:String?
    
    /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint.
    public var onChangeCallback:String?
    
    /// (optional) The amount of the asset the user would like to deposit with the anchor. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var amount:String?
    
    /// (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
    public var countryCode:String?
    
    /// (optional) true if the client supports receiving deposit transactions as a claimable balance, false otherwise.
    public var claimableBalanceSupported:String?
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String?
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case assetCode = "asset_code"
        case account
        case memoType = "memo_type"
        case memo
        case emailAddress = "email_address"
        case type
        case walletName = "wallet_name"
        case walletUrl = "wallet_url"
        case lang
        case onChangeCallback = "on_change_callback"
        case amount
        case countryCode = "country_code"
        case claimableBalanceSupported = "claimable_balance_supported"
    }
    
    public init(assetCode:String, account:String, jwt:String? = nil) {
        self.assetCode = assetCode
        self.account = account
        self.jwt = jwt
    }
    
}
