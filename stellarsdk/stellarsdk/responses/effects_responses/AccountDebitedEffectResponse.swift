//
//  AccountDebitedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account debit effect.
/// This effect occurs when an account sends a payment or other debit operation.
/// Triggered by Payment, Path Payment, Create Claimable Balance, and other operations that reduce an account balance.
/// See [Stellar developer docs](https://developers.stellar.org)
public class AccountDebitedEffectResponse: EffectResponse {

    /// The amount debited from this account.
    public var amount:String

    /// The asset type debited from the account (e.g., native, credit_alphanum4, credit_alphanum12).
    public var assetType:String

    /// The asset code debited from the account. Nil for native assets.
    public var assetCode:String?

    /// The issuer account ID of the asset debited from the account. Nil for native assets.
    public var assetIssuer:String?
    
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

