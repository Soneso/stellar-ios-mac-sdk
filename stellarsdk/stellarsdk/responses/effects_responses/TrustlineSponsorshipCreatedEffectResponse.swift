//
//  TrustlineSponsorshipCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline sponsorship creation effect.
/// This effect occurs when a trustline's reserve requirement begins being sponsored by another account.
/// Sponsorship allows one account to pay the base reserve for another account's trustline.
/// Triggered by the Begin Sponsoring Future Reserves and End Sponsoring Future Reserves operations.
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustlineSponsorshipCreatedEffectResponse: EffectResponse {

    /// The account ID of the sponsor paying the trustline's base reserve.
    public var sponsor:String

    /// The asset identifier for the trustline.
    public var asset:String?

    /// The asset type for the trustline.
    public var assetType:String?

    /// The liquidity pool ID if the trustline is for liquidity pool shares.
    public var liquidityPoolId:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case sponsor
        case asset
        case assetType = "asset_type"
        case liquidityPoolId = "liquidity_pool_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sponsor = try values.decode(String.self, forKey: .sponsor)
        asset = try values.decodeIfPresent(String.self, forKey: .asset)
        assetType = try values.decodeIfPresent(String.self, forKey: .assetType)
        liquidityPoolId = try values.decodeIfPresent(String.self, forKey: .liquidityPoolId)
        try super.init(from: decoder)
    }
}
