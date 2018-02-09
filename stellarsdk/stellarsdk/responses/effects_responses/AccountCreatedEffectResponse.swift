//
//  AccountCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account created effect response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
public class AccountCreatedEffectResponse: EffectResponse {
    
    /// The starting balance of the account created.
    public var startingBalance:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case startingBalance = "starting_balance"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        startingBalance = try values.decode(String.self, forKey: .startingBalance)
        
        try super.init(from: decoder)
    }
}
