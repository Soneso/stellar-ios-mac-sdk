//
//  AccountCreatedOperation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class AccountCreatedOperation: Operation {

    public var startingBalance:Decimal
    public var funder:String
    public var account:String
    
    private enum CodingKeys: String, CodingKey {
        case startingBalance = "starting_balance"
        case funder
        case account
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let balanceString = try values.decode(String.self, forKey: .startingBalance)
        startingBalance = Decimal(string: balanceString)!
        funder = try values.decode(String.self, forKey: .funder)
        account = try values.decode(String.self, forKey: .account)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startingBalance, forKey: .startingBalance)
        try container.encode(funder, forKey: .funder)
        try container.encode(account, forKey: .account)
    }
    
}
