//
//  PreconditionsTimeBoundsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

/// Represents time constraints for when a transaction can be included in a ledger.
///
/// Time bounds restrict transaction validity to a specific time window using Unix timestamps.
/// Validators will reject transactions with time bounds that don't include the current time.
///
/// Use cases:
/// - Time-limited offers or escrow releases
/// - Scheduled operations that should only execute after a specific time
/// - Expiring transactions that become invalid after a deadline
///
/// Both bounds are optional:
/// - If only minTime is set, transaction valid from that time onward
/// - If only maxTime is set, transaction valid until that time
/// - If both set, transaction valid only within the time window
/// - If neither set (both nil or 0), transaction has no time restrictions
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - TransactionPreconditionsResponse for all precondition types
public class PreconditionsTimeBoundsResponse: NSObject, Decodable {

    /// Minimum Unix timestamp (seconds since epoch). Transaction invalid before this time. Nil or "0" for no minimum.
    public var minTime:String?

    /// Maximum Unix timestamp (seconds since epoch). Transaction invalid after this time. Nil or "0" for no maximum.
    public var maxTime:String?
    
    private enum CodingKeys: String, CodingKey {
        case minTime = "min_time"
        case maxTime = "max_time"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        minTime = try values.decodeIfPresent(String.self, forKey: .minTime)
        maxTime = try values.decodeIfPresent(String.self, forKey: .maxTime)
    }
}
