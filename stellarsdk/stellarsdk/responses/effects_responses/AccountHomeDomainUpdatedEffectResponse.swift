//
//  AccountHomeDomainUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents an account home domain updated effect response.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/effect.html "Effect")
///  See [Stellar guides](https://www.stellar.org/developers/guides/concepts/accounts.html#home-domain "Home Domain")
public class AccountHomeDomainUpdatedEffectResponse: EffectResponse {
    
    /// The home domain of the account.
    public var homeDomain:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case homeDomain = "home_domain"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        homeDomain = try values.decode(String.self, forKey: .homeDomain)
        
        try super.init(from: decoder)
    }
}

