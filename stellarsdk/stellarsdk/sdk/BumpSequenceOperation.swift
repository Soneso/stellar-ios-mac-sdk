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
    @available(*, deprecated, message: "use init(bumpTo:Int64, sourceAccountId:String?) instead")
    public init(bumpTo:Int64, sourceAccount:KeyPair? = nil) {
        self.bumpTo = bumpTo
        super.init(sourceAccount:sourceAccount)
    }
    
    /// Creates a new BumpSequenceOperation object.
    ///
    /// - Parameter bumpTo: Value to bump sequence.
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    ///
    public init(bumpTo:Int64, sourceAccountId:String?) {
        self.bumpTo = bumpTo
        super.init(sourceAccountId:sourceAccountId)
    }
    
    /// Creates a new BumpSequenceOperation object from the given SetOptionsOperationXDR object.
    ///
    /// - Parameter fromXDR: the SetOptionsOperationXDR object to be used to create a new SetOptionsOperation object.
    @available(*, deprecated, message: "use init(..., sourceAccountId:String?) instead")
    public init(fromXDR:BumpSequenceOperationXDR, sourceAccount:KeyPair? = nil) {
        bumpTo = fromXDR.bumpTo
        super.init(sourceAccount: sourceAccount)
    }
    
    /// Creates a new BumpSequenceOperation object from the given SetOptionsOperationXDR object.
    ///
    /// - Parameter fromXDR: the SetOptionsOperationXDR object to be used to create a new SetOptionsOperation object.
    /// - Parameter sourceAccountId: (optional) source account Id. must start with "G" and must be valid, otherwise it will be ignored.
    ///
    public init(fromXDR:BumpSequenceOperationXDR, sourceAccountId:String?) {
        bumpTo = fromXDR.bumpTo
        super.init(sourceAccountId: sourceAccountId)
    }
    
    override func getOperationBodyXDR() throws -> OperationBodyXDR {
        
        return OperationBodyXDR.bumpSequence(BumpSequenceOperationXDR(bumpTo: bumpTo))
    }
    
}
