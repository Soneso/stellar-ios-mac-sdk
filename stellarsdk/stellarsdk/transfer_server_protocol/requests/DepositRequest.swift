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
    
    /// Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case assetCode = "asset_code"
        case account = "account"
        case memoType = "memo_type"
        case memo = "memo"
        case emailAddress = "email_address"
    }
    
    public init(assetCode:String, account:String) {
        self.assetCode = assetCode
        self.account = account
    }
    
}
