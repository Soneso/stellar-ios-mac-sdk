//
//  AccountMergeOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account merge operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#account-merge "Account Merge Operation")
public class AccountMergeOperationResponse: OperationResponse {
    
    /// Account ID of the account that has been deleted.
    public var account:String
    public var accountMuxed:String?
    public var accountMuxedId:Int?
    
    /// Account ID where funds of deleted account were transferred.
    public var into:String
    public var intoMuxed:String?
    public var intoMuxedId:Int?
    
     // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case account
        case accountMuxed = "account_muxed"
        case accountMuxedId = "account_muxed_id"
        case into
        case intoMuxed = "into_muxed"
        case intoMuxedId = "into_muxed_id"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        account = try values.decode(String.self, forKey: .account)
        accountMuxed = try values.decodeIfPresent(String.self, forKey: .accountMuxed)
        accountMuxedId = try values.decodeIfPresent(Int.self, forKey: .accountMuxedId)
        into = try values.decode(String.self, forKey: .into)
        intoMuxed = try values.decodeIfPresent(String.self, forKey: .intoMuxed)
        intoMuxedId = try values.decodeIfPresent(Int.self, forKey: .intoMuxedId)
        
        try super.init(from: decoder)
    }
}
