//
//  ClaimableBalanceClawedBackEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 30.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimable balance clawback effect.
/// This effect occurs when an asset issuer claws back a claimable balance of their asset.
/// Clawback allows issuers to revoke assets they have issued.
/// Triggered by the Clawback Claimable Balance operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClaimableBalanceClawedBackEffectResponse: EffectResponse {

    /// The unique identifier of the claimable balance that was clawed back.
    public var balanceId:String
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case balanceId = "balance_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        balanceId = try values.decode(String.self, forKey: .balanceId)
        try super.init(from: decoder)
    }
}
