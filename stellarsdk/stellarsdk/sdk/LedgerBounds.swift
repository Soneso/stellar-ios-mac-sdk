//
//  LedgerBounds.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 29.04.22.
//  Copyright © 2022 Soneso. All rights reserved.
//

import Foundation

/**
 * LedgerBounds are Preconditions of a transaction per <a href="https://github.com/stellar/stellar-protocol/blob/master/core/cap-0021.md#specification">CAP-21<a/>
 */
final public class LedgerBounds: Sendable {

    /// The minimum ledger number (inclusive) for transaction validity.
    final public let minLedger:UInt32
    /// The maximum ledger number (inclusive) for transaction validity.
    final public let maxLedger:UInt32

    /// Creates ledger bounds specifying the ledger number range for transaction validity.
    public init(minLedger:UInt32, maxLedger:UInt32) {
        self.minLedger = minLedger
        self.maxLedger = maxLedger
    }

    /// Creates ledger bounds from XDR representation.
    public init(lederbounds:LedgerBoundsXDR) {
        self.minLedger = lederbounds.minLedger
        self.maxLedger = lederbounds.maxLedger
    }

    /// Converts this LedgerBounds to its XDR representation.
    public func toXdr() -> LedgerBoundsXDR {
        return LedgerBoundsXDR(minLedger:minLedger, maxLedger:maxLedger)
    }
}
