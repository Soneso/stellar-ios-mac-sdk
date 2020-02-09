//
//  FeeStatsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 09.02.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public class FeeStatsResponse: NSObject, Decodable {

    public var lastLedger:String
    public var lastLedgerBaseFee:String
    public var ledgerCapacityUsage:String
    public var feeCharged:FeeChargedResponse
    public var maxFee:MaxFeeResponse
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case lastLedger = "last_ledger"
        case lastLedgerBaseFee = "last_ledger_base_fee"
        case ledgerCapacityUsage = "ledger_capacity_usage"
        case feeCharged = "fee_charged"
        case maxFee = "max_fee"
    }
    
    public required init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lastLedger = try values.decode(String.self, forKey: .lastLedger)
        lastLedgerBaseFee = try values.decode(String.self, forKey: .lastLedgerBaseFee)
        ledgerCapacityUsage = try values.decode(String.self, forKey: .ledgerCapacityUsage)
        feeCharged = try values.decode(FeeChargedResponse.self, forKey: .feeCharged)
        maxFee = try values.decode(MaxFeeResponse.self, forKey: .maxFee)
    }
}
