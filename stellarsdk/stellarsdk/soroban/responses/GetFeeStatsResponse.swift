//
//  GetFeeStatsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import Foundation

/// Response containing Soroban transaction fee statistics including inclusion fees.
public struct GetFeeStatsResponse: Decodable, Sendable {

    /// Inclusion fee distribution statistics for Soroban transactions
    public let sorobanInclusionFee:InclusionFee

    /// Fee distribution statistics for Stellar (i.e. non-Soroban) transactions.
    /// Statistics are normalized per operation.
    public let inclusionFee:InclusionFee

    /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
    public let latestLedger:Int

    private enum CodingKeys: String, CodingKey {
        case sorobanInclusionFee
        case inclusionFee
        case latestLedger

    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sorobanInclusionFee = try values.decode(InclusionFee.self, forKey: .sorobanInclusionFee)
        inclusionFee = try values.decode(InclusionFee.self, forKey: .inclusionFee)
        latestLedger = try values.decode(Int.self, forKey: .latestLedger)
    }
}

/// Fee statistics showing distribution of inclusion fees across network transactions.
public struct InclusionFee: Decodable, Sendable {

    /// Maximum fee
    public let max:String

    /// Minimum fee
    public let min:String

    /// Fee value which occurs the most often
    public let mode:String

    /// 10th nearest-rank fee percentile
    public let p10:String

    /// 20th nearest-rank fee percentile
    public let p20:String

    /// 30th nearest-rank fee percentile
    public let p30:String

    /// 40th nearest-rank fee percentile
    public let p40:String

    /// 50th nearest-rank fee percentile
    public let p50:String

    /// 60th nearest-rank fee percentile
    public let p60:String

    /// 70th nearest-rank fee percentile
    public let p70:String

    /// 80th nearest-rank fee percentile
    public let p80:String

    /// 90th nearest-rank fee percentile
    public let p90:String

    /// 99th nearest-rank fee percentile
    public let p99:String

    /// How many transactions are part of the distribution
    public let transactionCount:String

    /// How many consecutive ledgers form the distribution
    public let ledgerCount:Int
    
    private enum CodingKeys: String, CodingKey {
        case max
        case min
        case mode
        case p10
        case p20
        case p30
        case p40
        case p50
        case p60
        case p70
        case p80
        case p90
        case p99
        case transactionCount
        case ledgerCount
        
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        max = try values.decode(String.self, forKey: .max)
        min = try values.decode(String.self, forKey: .min)
        mode = try values.decode(String.self, forKey: .mode)
        p10 = try values.decode(String.self, forKey: .p10)
        p20 = try values.decode(String.self, forKey: .p20)
        p30 = try values.decode(String.self, forKey: .p30)
        p40 = try values.decode(String.self, forKey: .p40)
        p50 = try values.decode(String.self, forKey: .p50)
        p60 = try values.decode(String.self, forKey: .p60)
        p70 = try values.decode(String.self, forKey: .p70)
        p80 = try values.decode(String.self, forKey: .p80)
        p90 = try values.decode(String.self, forKey: .p90)
        p99 = try values.decode(String.self, forKey: .p99)
        transactionCount = try values.decode(String.self, forKey: .transactionCount)
        ledgerCount = try values.decode(Int.self, forKey: .ledgerCount)
    }
}
