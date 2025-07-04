//
//  SimulateTransactionRequest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 18.12.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class SimulateTransactionRequest {
    
    public var transaction: Transaction
    
    /// allows budget instruction leeway used in preflight calculations to be configured. If not provided the leeway defaults to 3000000 instructions.
    public var resourceConfig: ResourceConfig?
    
    /// Support for non-root authorization. Only available for protocol >= 23
    /// Possible values: "enforce" | "record" | "record_allow_nonroot"
    public var authMode:String?

    
    public init(transaction:Transaction, resourceConfig:ResourceConfig? = nil, authMode:String? = nil) {
        self.transaction = transaction
        self.resourceConfig = resourceConfig
        self.authMode = authMode
    }
    
    public func buildRequestParams() -> [String : Any] {
        var result: [String : Any] = [:]
        result["transaction"] = try? transaction.encodedEnvelope()
        if let rC = resourceConfig {
            result["resourceConfig"] = rC.buildRequestParams()
        }
        if let rAuthMode = authMode {
            result["authMode"] = authMode
        }
        return result;
    }
}
