//
//  SignerSponsorshipRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a signer sponsorship removal effect.
/// This effect occurs when sponsorship for a signer's base reserve is revoked.
/// The account becomes responsible for paying the signer's base reserve.
/// Triggered by the Revoke Sponsorship operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SignerSponsorshipRemovedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The public key of the signer whose sponsorship is being removed.
    public let signer:String

    /// The account ID of the former sponsor.
    public let formerSponsor:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case signer
        case formerSponsor = "former_sponsor"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signer = try values.decode(String.self, forKey: .signer)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        try super.init(from: decoder)
    }
}
