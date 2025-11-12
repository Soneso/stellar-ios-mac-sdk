//
//  AccountFlagsUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 05.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents an account flags update effect.
/// This effect occurs when an account's authorization flags are modified through a Set Options operation.
/// Flags control asset issuer authorization requirements and account mutability.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/security/signatures-multisig#flags "Account Flags")
public class AccountFlagsUpdatedEffectResponse: EffectResponse {

    /// Indicates whether the account requires authorization before other accounts can hold its issued assets.
    public var authRequired:Bool!

    /// Indicates whether the account can revoke authorization for its issued assets held by other accounts.
    public var authRevocable:Bool!

    /// Indicates whether the account's authorization flags are permanently locked and the account cannot be deleted.
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
        
        try super.init(from: decoder)
    }
}

