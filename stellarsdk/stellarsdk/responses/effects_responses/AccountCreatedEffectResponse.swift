//
//  AccountCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 02/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account creation effect.
/// This effect occurs when a new account is created on the Stellar network through a Create Account operation.
/// The source account must fund the new account with a minimum balance to cover the base reserve.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AccountCreatedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The starting balance of the newly created account in lumens (XLM).
    public let startingBalance:String
    
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
