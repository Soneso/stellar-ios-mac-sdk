//
//  BumpFootprintExpirationOperation.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 24.07.23.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public class BumpFootprintExpirationOperation:Operation {
    
    public let ledgersToExpire:UInt32

    public init(ledgersToExpire:UInt32, sourceAccountId:String? = nil) {
        self.ledgersToExpire = ledgersToExpire;
        super.init(sourceAccountId: sourceAccountId)
    }
    
    public init(fromXDR:BumpFootprintExpirationOpXDR, sourceAccountId:String?) {
        
        self.ledgersToExpire = fromXDR.ledgersToExpire
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        return OperationBodyXDR.bumpFootprintExpiration(BumpFootprintExpirationOpXDR(ext: ExtensionPoint.void, ledgersToExpire: ledgersToExpire))
    }
}
