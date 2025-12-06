//
//  TrustLineFlagsUpdatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 30.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a trustline flags update effect.
/// This effect occurs when an asset issuer modifies the authorization flags for a trustline through a Set Trust Line Flags operation.
/// Flags control authorization status, liability maintenance, and clawback capabilities.
/// See [Stellar developer docs](https://developers.stellar.org)
public class TrustLineFlagsUpdatedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The account ID of the account holding the trustline.
    public let trustor:String

    /// The asset type of the trustline.
    public let assetType:String

    /// The asset code of the trustline.
    public let assetCode:String

    /// The issuer account ID of the asset.
    public let assetIssuer:String

    /// Indicates whether the trustline is fully authorized.
    public let authorizedFlag:Bool?

    /// Indicates whether the trustline can maintain liabilities only.
    public let authorizedToMaintainLiabilitiesFlag:Bool?

    /// Indicates whether clawback is enabled for the trustline.
    public let clawbackEnabledFlag:Bool?
    
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
