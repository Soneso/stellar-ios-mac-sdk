//
//  AccountCreditedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account credit effect.
/// This effect occurs when an account receives a payment or other credit operation.
/// Triggered by Payment, Path Payment, Create Claimable Balance claim, and other operations.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AccountCreditedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The amount credited to the account.
    public let amount:String

    /// The asset type credited to this account (e.g., native, credit_alphanum4, credit_alphanum12).
    public let assetType:String

    /// The asset code credited to the account. Nil for native assets.
    public let assetCode:String?

    /// The issuer account ID of the asset credited to the account. Nil for native assets.
    public let assetIssuer:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case amount
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(String.self, forKey: .amount)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decodeIfPresent(String.self, forKey: .assetCode)
        assetIssuer = try values.decodeIfPresent(String.self, forKey: .assetIssuer)
        
        try super.init(from: decoder)
    }
}
