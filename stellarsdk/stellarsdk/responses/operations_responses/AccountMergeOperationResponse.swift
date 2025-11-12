//
//  AccountMergeOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account merge operation response.
///  See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/operation.html#account-merge "Account Merge Operation")
public class AccountMergeOperationResponse: OperationResponse {
    
    /// Account ID of the account that has been merged (deleted).
    public var account:String

    /// Multiplexed account address of the merged account (if used).
    public var accountMuxed:String?

    /// ID of the multiplexed merged account (if used).
    public var accountMuxedId:String?

    /// Account ID where funds of the merged account were transferred.
    public var into:String

    /// Multiplexed account address of the destination account (if used).
    public var intoMuxed:String?

    /// ID of the multiplexed destination account (if used).
    public var intoMuxedId:String?
    
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
        accountMuxedId = try values.decodeIfPresent(String.self, forKey: .accountMuxedId)
        into = try values.decode(String.self, forKey: .into)
        intoMuxed = try values.decodeIfPresent(String.self, forKey: .intoMuxed)
        intoMuxedId = try values.decodeIfPresent(String.self, forKey: .intoMuxedId)
        
        try super.init(from: decoder)
    }
}
