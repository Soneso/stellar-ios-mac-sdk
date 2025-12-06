//
//  AccountFlagsResponse.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 02.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents account authorization flags set on asset issuer accounts.
///
/// These flags control how the issuer can manage who holds their asset. Issuers can require
/// authorization, enable revocation, make flags immutable, or enable clawback functionality.
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - AccountResponse for complete account information
public struct AccountFlagsResponse: Decodable, Sendable {

    /// If true, requires the issuer to explicitly authorize accounts before they can hold this asset.
    /// Used for regulated assets requiring KYC/AML compliance.
    public let authRequired:Bool

    /// If true, allows the issuer to revoke authorization and freeze assets held by accounts.
    /// The account can no longer perform operations with the frozen asset.
    public let authRevocable:Bool

    /// If true, none of the authorization flags can be changed and the account cannot be deleted.
    /// This provides permanent guarantees about asset behavior.
    public let authImmutable:Bool

    /// If true, enables the issuer to clawback (burn) asset balances from other accounts.
    /// Used for regulated assets requiring recovery or compliance enforcement.
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
    public init(from decoder: Decoder) throws {
        
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
