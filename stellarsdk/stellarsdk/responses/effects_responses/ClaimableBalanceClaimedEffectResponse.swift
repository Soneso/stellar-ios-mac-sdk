//
//  ClaimableBalanceClaimedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimable balance claimed effect.
/// This effect occurs when a claimable balance is successfully claimed by an eligible claimant.
/// The balance is transferred to the claimant's account and removed from the ledger.
/// Triggered by the Claim Claimable Balance operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClaimableBalanceClaimedEffectResponse: EffectResponse {

    /// The unique identifier of the claimable balance that was claimed.
    public var balanceId:String

    /// The asset that was claimed.
    public var asset:Asset

    /// The amount that was claimed.
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
