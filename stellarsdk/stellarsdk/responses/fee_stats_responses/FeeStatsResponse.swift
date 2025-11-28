//
//  FeeStatsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 09.02.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

/// Represents fee statistics from the Horizon API.
/// This endpoint provides information about transaction fees and network capacity usage
/// from the last ledger, helping clients determine appropriate fee levels for transactions.
/// See [Stellar developer docs](https://developers.stellar.org)
public struct FeeStatsResponse: Decodable, Sendable {

    /// The sequence number of the last ledger.
    public let lastLedger:String

    /// The base fee as defined in the last ledger, in stroops.
    public let lastLedgerBaseFee:String

    /// The capacity usage of the ledger, from 0 to 1 representing the percentage of maximum capacity.
    public let ledgerCapacityUsage:String

    /// Statistics about fees actually charged in recent ledgers.
    public let feeCharged:FeeChargedResponse

    /// Statistics about maximum fees willing to be paid in recent ledgers.
    public let maxFee:MaxFeeResponse
    
    // Properties to encode and decode
    enum CodingKeys: String, CodingKey {
        case lastLedger = "last_ledger"
        case lastLedgerBaseFee = "last_ledger_base_fee"
        case ledgerCapacityUsage = "ledger_capacity_usage"
        case feeCharged = "fee_charged"
        case maxFee = "max_fee"
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lastLedger = try values.decode(String.self, forKey: .lastLedger)
        lastLedgerBaseFee = try values.decode(String.self, forKey: .lastLedgerBaseFee)
        ledgerCapacityUsage = try values.decode(String.self, forKey: .ledgerCapacityUsage)
        feeCharged = try values.decode(FeeChargedResponse.self, forKey: .feeCharged)
        maxFee = try values.decode(MaxFeeResponse.self, forKey: .maxFee)
    }
}
