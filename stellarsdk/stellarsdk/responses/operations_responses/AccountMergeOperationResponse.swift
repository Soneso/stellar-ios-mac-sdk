//
//  AccountMergeOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents an account merge operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#account-merge "Account Merge Operation")
class AccountMergeOperationResponse: OperationResponse {
    
    /// Account ID of the account that has been deleted.
    public var account:String
    
    /// Account ID where funds of deleted account were transferred.
    public var into:String
    
     // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case account
        case into
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        account = try values.decode(String.self, forKey: .account)
        into = try values.decode(String.self, forKey: .into)
        
        try super.init(from: decoder)
    }
    
    /**
        Encodes this value into the given encoder.
     
        - Parameter encoder: The encoder to receive the data
     */
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(account, forKey: .account)
        try container.encode(into, forKey: .into)
    }
}
