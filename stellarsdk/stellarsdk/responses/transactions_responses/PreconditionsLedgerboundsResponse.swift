//
//  PreconditionsLedgerBoundsResponse.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

/// Represents ledger sequence constraints for when a transaction can be included.
///
/// Ledger bounds restrict transaction validity to a specific range of ledger sequence numbers.
/// Validators will reject transactions with ledger bounds that don't include the current ledger.
///
/// Use cases:
/// - Transactions that should execute within specific ledger windows
/// - Coordinating transactions across multiple parties with ledger-based timing
/// - Ensuring transactions execute before significant network state changes
///
/// Unlike time bounds, ledger bounds use deterministic ledger sequence numbers rather than
/// wall-clock time, providing more predictable execution windows.
///
/// See also:
/// - [Ledger Bounds](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/transaction-preconditions#ledger-bounds)
/// - TransactionPreconditionsResponse for all precondition types
/// - PreconditionsTimeBoundsResponse for time-based constraints
public class PreconditionsLedgerBoundsResponse: NSObject, Decodable {

    /// Minimum ledger sequence number. Transaction invalid before this ledger. Value 0 means no minimum.
    public var minLedger:Int

    /// Maximum ledger sequence number. Transaction invalid after this ledger. Value 0 means no maximum.
    public var maxLedger:Int
    
    private enum CodingKeys: String, CodingKey {
        case minLedger = "min_ledger"
        case maxLedger = "max_ledger"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        minLedger = try values.decode(Int.self, forKey: .minLedger)
        maxLedger = try values.decode(Int.self, forKey: .maxLedger)
    }
}
