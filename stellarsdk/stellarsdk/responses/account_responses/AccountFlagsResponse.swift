//
//  AccountFlagsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

///  Represents the account flags.
///  See [Horizon API](https://www.stellar.org/developers/horizon/reference/resources/account.html "Account")
///  See [Stellar Guides] (https://www.stellar.org/developers/guides/concepts/accounts.html#flags "Account flags")
///  Currently there are three flags, used by issuers of assets: Authorization required, Authorization revocable and Authorization immutable.
public class AccountFlagsResponse: NSObject, Decodable {
    
    /// Requires the issuing account to give other accounts permission before they can hold the issuing account’s credit.
    public var authRequired:Bool!
    
    /// Allows the issuing account to revoke its credit held by other accounts.
    public var authRevocable:Bool!
    
    /// If this is set then none of the authorization flags can be set and the account can never be deleted.
    public var authImmutable:Bool!
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case authRequired = "auth_required"
        case authRevocable = "auth_revocable"
        case authImmutable = "auth_immutable"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        authRequired = try values.decodeIfPresent(Bool.self, forKey: .authRequired)
        if authRequired == nil {
            authRequired = false
        }
        
        authRevocable = try values.decodeIfPresent(Bool.self, forKey: .authRevocable)
        if authRevocable == nil {
            authRevocable = false
        }
        
        authImmutable = try values.decodeIfPresent(Bool.self, forKey: .authImmutable)
        if authImmutable == nil {
            authImmutable = false
        }
    }
}
