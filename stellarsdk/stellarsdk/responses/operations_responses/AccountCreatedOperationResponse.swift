//
//  AccountCreatedOperationResponse.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 06/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account created operation response.
///  See [Stellar developer docs](https://developers.stellar.org)
public class AccountCreatedOperationResponse: OperationResponse, @unchecked Sendable {

    /// Amount the account was funded with (starting balance).
    public let startingBalance:Decimal

    /// Account ID that funded the new account.
    public let funder:String

    /// Multiplexed account address of the funder (if used).
    public let funderMuxed:String?

    /// ID of the multiplexed funder account (if used).
    public let funderMuxedId:String?

    /// Account ID of the newly created account.
    public let account:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case startingBalance = "starting_balance"
        case funder
        case funderMuxed = "funder_muxed"
        case funderMuxedId = "funder_muxed_id"
        case account
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let balanceString = try values.decode(String.self, forKey: .startingBalance)
        guard let balance = Decimal(string: balanceString) else {
            throw HorizonRequestError.parsingResponseFailed(message: "Invalid starting_balance format")
        }
        startingBalance = balance
        funder = try values.decode(String.self, forKey: .funder)
        funderMuxed = try values.decodeIfPresent(String.self, forKey: .funderMuxed)
        funderMuxedId = try values.decodeIfPresent(String.self, forKey: .funderMuxedId)
        account = try values.decode(String.self, forKey: .account)
        
        try super.init(from: decoder)
    }
}
