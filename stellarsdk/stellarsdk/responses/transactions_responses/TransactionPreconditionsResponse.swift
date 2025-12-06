//
//  TransactionPreconditions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

/// Represents transaction preconditions that must be met for a transaction to be valid.
///
/// Preconditions allow fine-grained control over when and how a transaction can be submitted
/// and executed. They provide advanced features like time windows, ledger bounds, sequence
/// constraints, and additional signing requirements.
///
/// All preconditions are optional. If not specified, the transaction has no constraints beyond
/// the standard requirements (valid signatures, sufficient fee, correct sequence number).
///
/// Common use cases:
/// - Time-locked transactions that can only execute within specific time windows
/// - Ledger-locked transactions valid only for specific ledger ranges
/// - Sequence-gated transactions requiring specific account age or sequence progression
/// - Multi-party transactions requiring additional signers beyond the account's configured signers
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - PreconditionsTimeBoundsResponse for time constraints
/// - PreconditionsLedgerBoundsResponse for ledger constraints
public struct TransactionPreconditionsResponse: Decodable, Sendable {

    /// Time window (Unix timestamps) during which this transaction is valid. Nil if no time constraints.
    public var timeBounds:PreconditionsTimeBoundsResponse?

    /// Ledger sequence range during which this transaction is valid. Nil if no ledger constraints.
    public var ledgerBounds:PreconditionsLedgerBoundsResponse?

    /// Minimum source account sequence number required. Transaction invalid if account sequence is less. Nil if no constraint.
    public var minAccountSequence:String?

    /// Minimum age (in seconds) the source account must have existed. Nil if no age requirement.
    public var minAccountSequenceAge:String?

    /// Minimum ledger gap since the source account's sequence number was last modified. Nil if no gap requirement.
    public var minAccountSequenceLedgerGap:Int?

    /// Additional signer keys required beyond the account's configured signers. Array of public keys. Nil if none required.
    public var extraSigners:[String]?
    
    private enum CodingKeys: String, CodingKey {
        case timeBounds = "timebounds"
        case ledgerBounds = "ledgerbounds"
        case minAccountSequence = "min_account_sequence"
        case minAccountSequenceAge = "min_account_sequence_age"
        case minAccountSequenceLedgerGap = "min_account_sequence_ledger_gap"
        case extraSigners = "extra_signers"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        timeBounds = try values.decodeIfPresent(PreconditionsTimeBoundsResponse.self, forKey: .timeBounds)
        ledgerBounds = try values.decodeIfPresent(PreconditionsLedgerBoundsResponse.self, forKey: .ledgerBounds)
        minAccountSequence = try values.decodeIfPresent(String.self, forKey: .minAccountSequence)
        minAccountSequenceAge = try values.decodeIfPresent(String.self, forKey: .minAccountSequenceAge)
        minAccountSequenceLedgerGap = try values.decodeIfPresent(Int.self, forKey: .minAccountSequenceLedgerGap)
        extraSigners = try values.decodeIfPresent(Array.self, forKey: .extraSigners)
    }
}
