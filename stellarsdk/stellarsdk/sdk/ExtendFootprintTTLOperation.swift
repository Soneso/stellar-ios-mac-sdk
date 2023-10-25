//
//  ExtendFootprintTTLOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class ExtendFootprintTTLOperation:Operation {
    
    public let extendTo:UInt32

    public init(ledgersToExpire:UInt32, sourceAccountId:String? = nil) {
        self.extendTo = ledgersToExpire;
        super.init(sourceAccountId: sourceAccountId)
    }
    
    public init(fromXDR:ExtendFootprintTTLOpXDR, sourceAccountId:String?) {
        
        self.extendTo = fromXDR.extendTo
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.extendFootprintTTL(ExtendFootprintTTLOpXDR(ext: ExtensionPoint.void, extendTo: extendTo))
    }
}
