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
final public class LedgerBounds {
    
    final public let minLedger:UInt32
    final public let maxLedger:UInt32
    

    public init(minLedger:UInt32, maxLedger:UInt32) {
        self.minLedger = minLedger
        self.maxLedger = maxLedger
    }
    
    public init(lederbounds:LedgerBoundsXDR) {
        self.minLedger = lederbounds.minLedger
        self.maxLedger = lederbounds.maxLedger
    }
    
    public func toXdr() -> LedgerBoundsXDR {
        return LedgerBoundsXDR(minLedger:minLedger, maxLedger:maxLedger)
    }
}
