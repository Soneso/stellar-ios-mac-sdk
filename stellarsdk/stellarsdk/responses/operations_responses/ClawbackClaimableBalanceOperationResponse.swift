//
//  ClawbackClaimableBalanceOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

/// Represents a clawback claimable balance operation response.
/// This operation claws back a claimable balance, returning the funds to the asset issuer. Only the asset issuer can perform this operation.
/// See [Stellar developer docs](https://developers.stellar.org)
public class ClawbackClaimableBalanceOperationResponse: OperationResponse {

    /// ID of the claimable balance being clawed back.
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
