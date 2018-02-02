//
//  AccountCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

class AccountCreatedEffect: Effect {
    var startingBalance:String
    
    private enum CodingKeys: String, CodingKey {
        case startingBalance = "starting_balance"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        startingBalance = try values.decode(String.self, forKey: .startingBalance)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startingBalance, forKey: .startingBalance)
    }
    
}
