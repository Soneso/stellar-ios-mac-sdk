//
//  TrustlineSponsorshipRemovedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline sponsorship removal effect.
/// This effect occurs when sponsorship for a trustline's base reserve is revoked.
/// The account becomes responsible for paying the trustline's base reserve.
/// Triggered by the Revoke Sponsorship operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustlineSponsorshipRemovedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The account ID of the former sponsor.
    public let formerSponsor:String

    /// The asset identifier for the trustline.
    public let asset:String?

    /// The asset type for the trustline.
    public let assetType:String?

    /// The liquidity pool ID if the trustline is for liquidity pool shares.
    public let liquidityPoolId:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case formerSponsor = "former_sponsor"
        case asset
        case assetType = "asset_type"
        case liquidityPoolId = "liquidity_pool_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        formerSponsor = try values.decode(String.self, forKey: .formerSponsor)
        asset = try values.decodeIfPresent(String.self, forKey: .asset)
        assetType = try values.decodeIfPresent(String.self, forKey: .assetType)
        liquidityPoolId = try values.decodeIfPresent(String.self, forKey: .liquidityPoolId)
        try super.init(from: decoder)
    }
}
