//
//  ClaimableBalanceCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimable balance creation effect.
/// This effect occurs when a new claimable balance is created on the ledger.
/// Claimable balances allow an account to set aside funds to be claimed by specific recipients at a later time.
/// Triggered by the Create Claimable Balance operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClaimableBalanceCreatedEffectResponse: EffectResponse, @unchecked Sendable {

    /// The unique identifier of the claimable balance.
    public let balanceId:String

    /// The asset available to be claimed.
    public let asset:Asset

    /// The amount available to be claimed.
    public let amount:String
    
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
