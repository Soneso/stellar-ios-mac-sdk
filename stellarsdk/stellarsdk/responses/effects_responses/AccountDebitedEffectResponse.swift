//
//  AccountDebitedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account debited effect response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
public class AccountDebitedEffectResponse: EffectResponse {
    
    /// The amount debited from this account.
    public var amount:String
    
    /// The asset type of the asset debited from the account. E.g. native
    public var assetType:String
    
    /// The asset code of the asset debited from the account. E.g. BTC, nil if native
    public var assetCode:String?
    
    /// The issuer of the asset debited from the account. Nil if asset type is "native"
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

