//
//  CreateClaimableBalanceOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a create claimable balance operation response.
/// This operation creates a claimable balance entry that can be claimed by specified claimants, enabling conditional payments on the Stellar network.
/// See [Stellar developer docs](https://developers.stellar.org)
public class CreateClaimableBalanceOperationResponse: OperationResponse {

    /// Account ID that sponsors the claimable balance reserves (if sponsored).
    public var sponsor:String?

    /// Asset held in the claimable balance.
    public var asset:Asset

    /// Amount of the asset in the claimable balance.
    public var amount:String

    /// List of claimants who can claim this balance.
    public var claimants: [ClaimantResponse]
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case sponsor
        case asset
        case amount
        case claimants
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sponsor = try values.decodeIfPresent(String.self, forKey: .sponsor)
        let canonicalAsset = try values.decode(String.self, forKey: .asset)
        if let a = Asset(canonicalForm: canonicalAsset) {
            asset = a
        } else {
            throw StellarSDKError.decodingError(message: "not a valid asset in horizon response")
        }
        amount = try values.decode(String.self, forKey: .amount)
        claimants = try values.decode([ClaimantResponse].self, forKey: .claimants)
        try super.init(from: decoder)
    }
}

