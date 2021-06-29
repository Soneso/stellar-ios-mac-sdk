//
//  ClaimClaimableBalanceOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class ClaimClaimableBalanceOperationResponse: OperationResponse {
    
    public var balanceId:String
    public var claimantAccountId:String
    public var claimantMuxed:String?
    public var claimantMuxedId:String?
    
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
