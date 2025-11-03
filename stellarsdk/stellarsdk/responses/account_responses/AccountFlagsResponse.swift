//
//  AccountFlagsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

///  Represents the account flags.
///  See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/account.html "Account")
///  See [Stellar Guides] (https://developers.stellar.org/docs/concepts/accounts.html#flags "Account flags")
///  Currently there are three flags, used by issuers of assets: Authorization required, Authorization revocable and Authorization immutable.
public class AccountFlagsResponse: NSObject, Decodable {
    
    /// Requires the issuing account to give other accounts permission before they can hold the issuing account’s credit.
    public let authRequired:Bool
    
    /// Allows the issuing account to revoke its credit held by other accounts.
    public let authRevocable:Bool
    
    /// If this is set then none of the authorization flags can be set and the account can never be deleted.
    public let authImmutable:Bool
    
    public let authClawbackEnabled:Bool
    
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case authRequired = "auth_required"
        case authRevocable = "auth_revocable"
        case authImmutable = "auth_immutable"
        case authClawbackEnabled = "auth_clawback_enabled"
    }
    
    /**
        Initializer - creates a new instance by decoding from the given decoder.
     
        - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let areq = try values.decodeIfPresent(Bool.self, forKey: .authRequired) {
            authRequired = areq
        } else {
            authRequired = false
        }
        
        if let arev = try values.decodeIfPresent(Bool.self, forKey: .authRevocable) {
            authRevocable = arev
        } else {
            authRevocable = false
        }

        if let aimmu = try values.decodeIfPresent(Bool.self, forKey: .authImmutable) {
            authImmutable = aimmu
        } else {
            authImmutable = false
        }
        
        if let ace = try values.decodeIfPresent(Bool.self, forKey: .authClawbackEnabled) {
            authClawbackEnabled = ace
        } else {
            authClawbackEnabled = false
        }
    }
}
