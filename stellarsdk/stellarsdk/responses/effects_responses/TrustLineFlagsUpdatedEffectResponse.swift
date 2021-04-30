//
//  TrustLineFlagsUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 30.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class TrustLineFlagsUpdatedEffectResponse: EffectResponse {
    
    public var trustor:String
    public var assetType:String
    public var assetCode:String
    public var assetIssuer:String
    public var authorizedFlag:Bool?
    public var authorizedToMaintainLiabilitiesFlag:Bool?
    public var clawbackEnabledFlag:Bool?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case trustor = "trustor"
        case assetType = "asset_type"
        case assetCode = "asset_code"
        case assetIssuer = "asset_issuer"
        case authorizedFlag = "authorized_flag"
        case authorizedToMaintainLiabilitiesFlag = "authorized_to_maintain_liabilites_flag"
        case clawbackEnabledFlag = "clawback_enabled_flag"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        trustor = try values.decode(String.self, forKey: .trustor)
        assetType = try values.decode(String.self, forKey: .assetType)
        assetCode = try values.decode(String.self, forKey: .assetCode)
        assetIssuer = try values.decode(String.self, forKey: .assetIssuer)
        authorizedFlag = try values.decodeIfPresent(Bool.self, forKey: .authorizedFlag)
        authorizedToMaintainLiabilitiesFlag = try values.decodeIfPresent(Bool.self, forKey: .authorizedToMaintainLiabilitiesFlag)
        clawbackEnabledFlag = try values.decodeIfPresent(Bool.self, forKey: .clawbackEnabledFlag)
        try super.init(from: decoder)
    }
}
