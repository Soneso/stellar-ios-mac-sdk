//
//  TrustlineSponsorshipUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class TrustlineSponsorshipUpdatedEffectResponse: EffectResponse {
    
    // new sponsor of a trustline
    public var newSponsor:String
    
    //  former sponsor of a trustline
    public var formerSponsor:String
    
    public var asset:String?
    public var assetType:String?
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
