//
//  AccountHomeDomainUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account home domain update effect.
/// This effect occurs when an account's home domain is set or changed through a Set Options operation.
/// The home domain is used to link the account to a domain name for federation and additional account information.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts#home-domain "Home Domain")
public class AccountHomeDomainUpdatedEffectResponse: EffectResponse {

    /// The updated home domain of the account.
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

