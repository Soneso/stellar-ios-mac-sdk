//
//  BumpSequenceOperation.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 29/08/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class BumpSequenceOperation: Operation {

    public let bumpTo:Int64
    
    /// Creates a new BumpSequenceOperation object.
    ///
    /// - Parameter bumpTo: Value to bump sequence.
    ///
    public init(bumpTo:Int64, sourceAccount:KeyPair? = nil) {
        self.bumpTo = bumpTo
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new BumpSequenceOperation object from the given SetOptionsOperationXDR object.
    ///
    /// - Parameter fromXDR: the SetOptionsOperationXDR object to be used to create a new SetOptionsOperation object.
    ///
    public init(fromXDR:BumpSequenceOperationXDR, sourceAccount:KeyPair? = nil) {
        bumpTo = fromXDR.bumpTo
        super.init(sourceAccount: sourceAccount)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        
        return OperationBodyXDR.bumpSequence(BumpSequenceOperationXDR(bumpTo: bumpTo))
    }
    
}
