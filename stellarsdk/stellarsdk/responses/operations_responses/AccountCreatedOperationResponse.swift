//
//  AccountCreatedOperationResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account created operation response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/operation.html#create-account "Create Account Operation")
public class AccountCreatedOperationResponse: OperationResponse {

    /// Amount the account was funded.
    public var startingBalance:Decimal
    
    /// Account that funded a new account.
    public var funder:String
    
    /// A new account that was funded.
    public var account:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case startingBalance = "starting_balance"
        case funder
        case account
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let balanceString = try values.decode(String.self, forKey: .startingBalance)
        startingBalance = Decimal(string: balanceString)!
        funder = try values.decode(String.self, forKey: .funder)
        account = try values.decode(String.self, forKey: .account)
        
        try super.init(from: decoder)
    }
}
