//
//  ClaimClaimableBalanceOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents a claim claimable balance operation response.
/// This operation claims a claimable balance entry, transferring the asset amount to the claimant's account.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClaimClaimableBalanceOperationResponse: OperationResponse, @unchecked Sendable {

    /// ID of the claimable balance being claimed.
    public let balanceId:String

    /// Account ID of the claimant claiming the balance.
    public let claimantAccountId:String

    /// Multiplexed account address of the claimant (if used).
    public let claimantMuxed:String?

    /// ID of the multiplexed account (if used).
    public let claimantMuxedId:String?
    
    // Properties to encode and decode
    private enum CodingKeys: String, CodingKey {
        case balanceId = "balance_id"
        case claimantAccountId = "claimant"
        case claimantMuxed = "claimant_muxed"
        case claimantMuxedId = "claimant_muxed_id"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        balanceId = try values.decode(String.self, forKey: .balanceId)
        claimantAccountId = try values.decode(String.self, forKey: .claimantAccountId)
        claimantMuxed = try values.decodeIfPresent(String.self, forKey: .claimantMuxed)
        claimantMuxedId = try values.decodeIfPresent(String.self, forKey: .claimantMuxedId)
        try super.init(from: decoder)
    }
}
