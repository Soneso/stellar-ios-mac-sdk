//
//  TrustlineSponsorshipUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline sponsorship update effect.
/// This effect occurs when the sponsoring account for a trustline's base reserve changes.
/// The sponsorship is transferred from one sponsor to another.
/// Triggered by the Revoke Sponsorship operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustlineSponsorshipUpdatedEffectResponse: EffectResponse {

    /// The account ID of the new sponsor.
    public var newSponsor:String

    /// The account ID of the former sponsor.
    public var formerSponsor:String

    /// The asset identifier for the trustline.
    public var asset:String?

    /// The asset type for the trustline.
    public var assetType:String?

    /// The liquidity pool ID if the trustline is for liquidity pool shares.
    public var liquidityPoolId:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case newSponsor = "new_sponsor"
        case formerSponsor = "former_sponsor"
        case asset
        case assetType = "asset_type"
        case liquidityPoolId = "liquidity_pool_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        newSponsor = try values.decode(String.self, forKey: .newSponsor)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        asset = try values.decodeIfPresent(String.self, forKey: .asset)
        assetType = try values.decodeIfPresent(String.self, forKey: .assetType)
        liquidityPoolId = try values.decodeIfPresent(String.self, forKey: .liquidityPoolId)
        try super.init(from: decoder)
    }
}
