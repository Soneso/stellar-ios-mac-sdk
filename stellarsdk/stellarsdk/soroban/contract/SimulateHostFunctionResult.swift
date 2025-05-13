//
//  SimulateHostFunctionResult.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.05.25.
//  Copyright © 2025 Soneso. All rights reserved.
//

import Foundation

public class SimulateHostFunctionResult {

    /// Auth entries
    public let auth:[SorobanAuthorizationEntryXDR]?
    
    public let transactionData:SorobanTransactionDataXDR
    public let returnedValue: SCValXDR
    
    internal init(transactionData: SorobanTransactionDataXDR, returnedValue: SCValXDR, auth: [SorobanAuthorizationEntryXDR]? = nil) {
        self.auth = auth
        self.transactionData = transactionData
        self.returnedValue = returnedValue
    }
    
}
