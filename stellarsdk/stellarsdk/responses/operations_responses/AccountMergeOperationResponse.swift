//
//  AccountMergeOperationResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 07.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class AccountMergeOperationResponse: OperationResponse {
    
    public var account:String
    public var into:String
    
    private enum CodingKeys: String, CodingKey {
        case account
        case into
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        account = try values.decode(String.self, forKey: .account)
        into = try values.decode(String.self, forKey: .into)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(account, forKey: .account)
        try container.encode(into, forKey: .into)
    }
    
}
