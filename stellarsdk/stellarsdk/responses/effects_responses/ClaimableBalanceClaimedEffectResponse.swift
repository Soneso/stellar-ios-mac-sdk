//
//  ClaimableBalanceClaimedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class ClaimableBalanceClaimedEffectResponse: EffectResponse {
    
    // unique ID of claimable balance
    public var balanceId:String
    
    /// asset available to be claimed (in canonical form)
    public var asset:Asset
    
    /// amount available to be claimed
    public var amount:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case balanceId = "balance_id"
        case asset
        case amount
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        balanceId = try values.decode(String.self, forKey: .balanceId)
        let canonicalAsset = try values.decode(String.self, forKey: .asset)
        if let a = Asset(canonicalForm: canonicalAsset) {
            asset = a
        } else {
            throw StellarSDKError.decodingError(message: "not a valid asset in horizon response")
        }
        amount = try values.decode(String.self, forKey: .amount)
        try super.init(from: decoder)
    }
}
