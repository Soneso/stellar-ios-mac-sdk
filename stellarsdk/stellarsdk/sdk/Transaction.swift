//
//  Transaction.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 17.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a Transaction in Stellar network.
/// See [Stellar Guides] (https://www.stellar.org/developers/learn/concepts/transactions.html, "Transactions")
public class Transaction {
    
    let baseFee = 100
    let fee:UInt32
    let sourceAccount:KeyPair
    let sequenceNumber:UInt64
    let operations:[Operation]
    let memo:Memo
    let timeBounds:TimeBounds?
    var signatures = [DecoratedSignatureXDR]()
    
    /// Creates a new PaymentOperation object.
    ///
    /// - Parameter sourceAccount: KeyPair containing the public key of the account that originates the transaction.
    /// - Parameter sequenceNumber: Each transaction has a sequence number. Transactions follow a strict ordering rule when it comes to processing of transactions per account. For the transaction to be valid, the sequence number must be 1 greater than the sequence number stored in the source account entry when the transaction is applied.
    /// - Parameter operations: Transactions contain an arbitrary list of operations inside them. Typically there is just one operation, but it’s possible to have multiple. Operations are executed in order as one ACID transaction, meaning that either all operations are applied or none are.
    /// - Parameter memo: Optional. The memo contains optional extra information. It is the responsibility of the client to interpret this value.
    /// - Parameter timeBounds: Optional. The UNIX timestamp, determined by ledger time, of a lower and upper bound of when this transaction will be valid. If a transaction is submitted too early or too late, it will fail to make it into the transaction set.
    ///
    public init(sourceAccount:KeyPair, sequenceNumber:UInt64, operations:[Operation], memo:Memo?, timeBounds:TimeBounds?) throws {
        
        if operations.count == 0 {
            throw StellarSDKError.invalidArgument(message: "At least one operation required")
        }
        
        self.sourceAccount = sourceAccount
        self.operations = operations
        self.timeBounds = timeBounds
        self.sequenceNumber = sequenceNumber
        self.fee = UInt32(operations.count * baseFee)
        
        if (memo != nil) {
            self.memo = memo!
        } else {
            self.memo = Memo.none
        }
    }
    
    /// Creates an TransactionXDR object from the current Transaction object.
    ///
    /// Returns the created TransactionXDR object.
    ///
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
