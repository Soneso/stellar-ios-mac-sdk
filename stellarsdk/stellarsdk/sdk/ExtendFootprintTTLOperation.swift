//
//  ExtendFootprintTTLOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Extends the time-to-live of contract state entries in Soroban by the specified number of ledgers.
public class ExtendFootprintTTLOperation:Operation, @unchecked Sendable {

    /// The number of ledgers past the LCL by which to extend the validity of the ledger keys in this transaction.
    public let extendTo:UInt32

    /// Creates a new extend footprint TTL operation to extend contract state entry validity.
    public init(ledgersToExpire:UInt32, sourceAccountId:String? = nil) {
        self.extendTo = ledgersToExpire;
        super.init(sourceAccountId: sourceAccountId)
    }

    /// Creates an extend footprint TTL operation from XDR representation.
    public init(fromXDR:ExtendFootprintTTLOpXDR, sourceAccountId:String?) {
        
        self.extendTo = fromXDR.extendTo
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.extendFootprintTTL(ExtendFootprintTTLOpXDR(ext: ExtensionPoint.void, extendTo: extendTo))
    }
}
