//
//  AnchorTransactionsRequest.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 08/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct AnchorTransactionsRequest {
    
    /// The code of the asset of interest. E.g. BTC,ETH,USD,INR,etc
    public var assetCode:String
    
    /// The stellar account ID involved in the transactions. If the service requires SEP-10 authentication, this parameter must match the authenticated account.
    public var account:String
    
    /// (optional) The response should contain transactions starting on or after this date & time
    public var noOlderThan:Date?
    
    /// (optional) the response should contain at most limit transactions
    public var limit:Int?
    
    /// (optional) A list containing the desired transaction kinds. The possible values are deposit, deposit-exchange, withdrawal and withdrawal-exchange.
    public var kind:String?
    
    /// (optional) the response should contain transactions starting prior to this ID (exclusive)
    public var pagingId:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported. Language code specified using RFC 4646. error fields and other human readable messages in the response should be in this language.
    public var lang:String?
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String?
    
    public init(assetCode:String, account:String, jwt:String? = nil) {
        self.assetCode = assetCode
        self.account = account
        self.jwt = jwt
    }
}

public struct AnchorTransactionRequest {
    
    /// The id of the transaction.
    public var id:String?
    
    /// The stellar transaction id of the transaction.
    public var stellarTransactionId:String?
    
    /// The external transaction id of the transaction.
    public var externalTransactionId:String?
    
    /// (optional) Defaults to en if not specified or if the specified language is not supported. Language code specified using RFC 4646. error fields and other human readable messages in the response should be in this language.
    public var lang:String?
    
    /// jwt previously received from the anchor via the SEP-10 authentication flow
    public var jwt:String?
    
    /// One of id, stellar_transaction_id or external_transaction_id is required.
    public init(id:String? = nil, stellarTransactionId:String? = nil, externalTransactionId:String? = nil, jwt:String? = nil) {
        self.id = id
        self.stellarTransactionId = stellarTransactionId
        self.externalTransactionId = externalTransactionId
        self.jwt = jwt
    }
}
