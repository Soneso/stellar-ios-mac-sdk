//
//  TransactionPreconditions.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 28.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

public class TransactionPreconditionsResponse: NSObject, Decodable {
    
    /// The id of this transaction.
    public var timeBounds:PreconditionsTimeBoundsResponse?
    public var ledgerBounds:PreconditionsLedgerBoundsResponse?
    public var minAccountSequence:String?
    public var minAccountSequenceAge:String?
    public var minAccountSequenceLedgerGap:String?
    public var extraSigners:[String]?
    
    private enum CodingKeys: String, CodingKey {
        case timeBounds
        case ledgerBounds
        case minAccountSequence = "min_account_sequence"
        case minAccountSequenceAge = "min_account_sequence_age"
        case minAccountSequenceLedgerGap = "min_account_sequence_ledger_gap"
        case extraSigners = "extra_signers"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        timeBounds = try values.decodeIfPresent(PreconditionsTimeBoundsResponse.self, forKey: .timeBounds)
        ledgerBounds = try values.decodeIfPresent(PreconditionsLedgerBoundsResponse.self, forKey: .ledgerBounds)
        minAccountSequence = try values.decodeIfPresent(String.self, forKey: .minAccountSequence)
        minAccountSequenceAge = try values.decodeIfPresent(String.self, forKey: .minAccountSequenceAge)
        minAccountSequenceLedgerGap = try values.decodeIfPresent(String.self, forKey: .minAccountSequenceLedgerGap)
        extraSigners = try values.decodeIfPresent(Array.self, forKey: .extraSigners)
    }
}
