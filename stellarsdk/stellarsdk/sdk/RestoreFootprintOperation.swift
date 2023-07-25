//
//  RestoreFootprintOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class RestoreFootprintOperation:Operation {
    
    public override init(sourceAccountId:String? = nil) {
        super.init(sourceAccountId: sourceAccountId)
    }
    
    public init(fromXDR:RestoreFootprintOpXDR, sourceAccountId:String?) {
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.restoreFootprint(RestoreFootprintOpXDR(ext: ExtensionPoint.void))
    }
}
