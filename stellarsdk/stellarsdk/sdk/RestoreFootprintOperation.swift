//
//  RestoreFootprintOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

/// Restores archived contract state entries in Soroban to active state.
public class RestoreFootprintOperation:Operation, @unchecked Sendable {
    
    public override init(sourceAccountId:String? = nil) {
        super.init(sourceAccountId: sourceAccountId)
    }

    /// Creates a restore footprint operation from XDR representation.
    public init(fromXDR:RestoreFootprintOpXDR, sourceAccountId:String?) {
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.restoreFootprintOp(RestoreFootprintOpXDR(ext: ExtensionPoint.void))
    }
}
