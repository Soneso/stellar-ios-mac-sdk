//
//  ClaimableBalanceClaimantCreatedEffectResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 02.10.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claimable balance claimant creation effect.
/// This effect occurs for each claimant specified when a claimable balance is created.
/// It includes the predicate conditions that must be met for the claimant to claim the balance.
/// Triggered by the Create Claimable Balance operation.
/// See [Horizon API](https://developers.stellar.org/api/horizon/reference/resources/effect.html "Effect")
/// See [Stellar Documentation](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/claimable-balances "Claimable Balances")
public class ClaimableBalanceClaimantCreatedEffectResponse: EffectResponse {

    /// The unique identifier of the claimable balance.
    public var balanceId:String

    /// The asset available to be claimed.
    public var asset:Asset

    /// The amount available to be claimed.
    public var amount:String

    /// The predicate conditions that must be met for the claimant to claim the balance.
    public var predicate:ClaimantPredicateResponse
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case balanceId = "balance_id"
        case asset
        case amount
        case predicate
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
        predicate = try values.decode(ClaimantPredicateResponse.self, forKey: .predicate)
        try super.init(from: decoder)
    }
}
