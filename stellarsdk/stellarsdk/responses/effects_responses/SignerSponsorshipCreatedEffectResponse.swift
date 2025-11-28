//
//  SignerSponsorshipCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a signer sponsorship creation effect.
/// This effect occurs when a signer's reserve requirement begins being sponsored by another account.
/// Sponsorship allows one account to pay the base reserve for another account's signer.
/// Triggered by the Begin Sponsoring Future Reserves and End Sponsoring Future Reserves operations.
/// See [Stellar developer docs](https://developers.stellar.org)
public class SignerSponsorshipCreatedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The public key of the signer being sponsored.
    public let signer:String

    /// The account ID of the sponsor paying the signer's base reserve.
    public let sponsor:String
    
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case signer
        case sponsor
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signer = try values.decode(String.self, forKey: .signer)
        sponsor = try values.decode(String.self, forKey: .sponsor)
        try super.init(from: decoder)
    }
}
