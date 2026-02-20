//
//  SimulateHostFunctionResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

/// Result of simulating a Soroban host function invocation containing auth entries and return values.
public final class SimulateHostFunctionResult: Sendable {

    /// Authorization entries required for multi-party transaction signing.
    public let auth:[SorobanAuthorizationEntryXDR]?

    /// Soroban transaction data including resource limits and ledger footprint.
    public let transactionData:SorobanTransactionDataXDR

    /// The return value from the contract function call as an XDR-encoded SCVal.
    public let returnedValue: SCValXDR
    
    public init(transactionData: SorobanTransactionDataXDR, returnedValue: SCValXDR, auth: [SorobanAuthorizationEntryXDR]? = nil) {
        self.auth = auth
        self.transactionData = transactionData
        self.returnedValue = returnedValue
    }
    
}
