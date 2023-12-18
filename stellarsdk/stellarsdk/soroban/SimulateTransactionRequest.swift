//
//  SimulateTransactionRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.12.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class SimulateTransactionRequest {
    
    public let transaction: Transaction
    
    /// allows budget instruction leeway used in preflight calculations to be configured. If not provided the leeway defaults to 3000000 instructions.
    public let resourceConfig: ResourceConfig?
    
    public init(transaction:Transaction, resourceConfig:ResourceConfig? = nil) {
        self.transaction = transaction
        self.resourceConfig = resourceConfig
    }
    
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        result["transaction"] = try? transaction.encodedEnvelope()
        if let rC = resourceConfig {
            result["resourceConfig"] = rC.buildRequestParams()
        }
        return result;
    }
}
