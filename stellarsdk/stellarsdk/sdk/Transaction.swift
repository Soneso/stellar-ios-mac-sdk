//
//  Transaction.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 17.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class Transaction {
    
    let baseFee = 100
    let fee:UInt32
    let sourceAccount:KeyPair
    let sequenceNumber:UInt64
    let operations:[Operation]
    let memo:Memo
    let timeBounds:TimeBounds?
    var signatures = [DecoratedSignatureXDR]()
    
    
    public init(sourceAccount:KeyPair, sequenceNumber:String, operations:[Operation], memo:Memo?, timeBounds:TimeBounds?) throws {
        
        if operations.count == 0 {
            throw StellarSDKError.invalidArgument(message: "At least one operation required")
        }
        
        self.sourceAccount = sourceAccount
        self.operations = operations
        self.timeBounds = timeBounds
        self.sequenceNumber = UInt64(sequenceNumber)!
        self.fee = UInt32(operations.count * baseFee)
        if (memo != nil) {
            self.memo = memo!
        } else {
            self.memo = Memo.none
        }
    }
    
    public func toXDR() throws -> TransactionXDR {
        
        var operationsXDR = [OperationXDR]()
        
        for operation in self.operations {
            try operationsXDR.append(operation.toXDR())
        }
        
        return TransactionXDR(sourceAccount: self.sourceAccount.publicKey,
                              seqNum: self.sequenceNumber,
                              timeBounds: self.timeBounds?.toXdr(),
                              memo: self.memo.toXDR(),
                              operations: operationsXDR)
    }
    
}
