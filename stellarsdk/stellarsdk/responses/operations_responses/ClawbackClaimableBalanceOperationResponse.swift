//
//  ClawbackClaimableBalanceOperationResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 19.04.21.
//  Copyright © 2021 Soneso. All rights reserved.
//

import Foundation

public class ClawbackClaimableBalanceOperationResponse: OperationResponse {
    
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
