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
    
    /// The stellar account ID involved in the transactions
    public var account:String
    
    /// (optional) The response should contain transactions starting on or after this date & time
    public var noOlderThan:Date?
    
    /// (optional) the response should contain at most limit transactions
    public var limit:Int?
    
    /// (optional) the response should contain transactions starting prior to this ID (exclusive)
    public var pagingId:String?
    
    public init(assetCode:String, account:String) {
        self.assetCode = assetCode
        self.account = account
    }
}
