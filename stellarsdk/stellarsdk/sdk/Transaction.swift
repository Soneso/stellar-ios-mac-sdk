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
    
    public let baseFee = 100
    public let fee:UInt32
    public let sourceAccount:TransactionAccount
    public let operations:[Operation]
    public let memo:Memo
    public let timeBounds:TimeBounds?
    public private(set) var transactionXDR:TransactionXDR
    
    public var xdrEncoded: String? {
        get {
            return transactionXDR.xdrEncoded
        }
    }
    
    /// Creates a new Transaction object.
    ///
    /// - Parameter sourceAccount: Account that originates the transaction.
    /// - Parameter operations: Transactions contain an arbitrary list of operations inside them. Typically there is just one operation, but it’s possible to have multiple. Operations are executed in order as one ACID transaction, meaning that either all operations are applied or none are.
    /// - Parameter memo: Optional. The memo contains optional extra information. It is the responsibility of the client to interpret this value.
    /// - Parameter timeBounds: Optional. The UNIX timestamp, determined by ledger time, of a lower and upper bound of when this transaction will be valid. If a transaction is submitted too early or too late, it will fail to make it into the transaction set.
    ///
    public init(sourceAccount:TransactionAccount, operations:[Operation], memo:Memo?, timeBounds:TimeBounds?) throws {
        
        if operations.count == 0 {
            throw StellarSDKError.invalidArgument(message: "At least one operation required")
        }
        
        self.sourceAccount = sourceAccount
        self.operations = operations
        self.timeBounds = timeBounds
        self.fee = UInt32(operations.count * baseFee)
        self.memo = memo ?? Memo.none
        
        var operationsXDR = [OperationXDR]()
        
        for operation in self.operations {
            try operationsXDR.append(operation.toXDR())
        }
        
        self.transactionXDR = TransactionXDR(sourceAccount: self.sourceAccount.keyPair.publicKey,
                                             seqNum: self.sourceAccount.incrementedSequenceNumber(),
                                             timeBounds: self.timeBounds?.toXdr(),
                                             memo: self.memo.toXDR(),
                                             operations: operationsXDR)
        
        self.sourceAccount.incrementSequenceNumber()
        
    }
    
    /// Creates a new Transaction object from an XDR string.
    ///
    /// - Parameter xdr: The XDR string to be parsed into a Transaction object.
    ///
    public convenience init(xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        
        let transactionXDR = try TransactionXDR(fromBinary: xdrDecoder)
        let keypair = KeyPair(publicKey: transactionXDR.sourceAccount)
        let transactionSourceAccount = Account(keyPair: keypair, sequenceNumber: transactionXDR.seqNum - 1)
        var operations = [Operation]()
        for operationXDR in transactionXDR.operations {
            let operation = try Operation.fromXDR(operationXDR: operationXDR)
            operations.append(operation)
        }
        
        var timebounds: TimeBounds?
        if let timeboundsXDR = transactionXDR.timeBounds {
            timebounds = TimeBounds(timebounds: timeboundsXDR)
        }
        
        try self.init(sourceAccount: transactionSourceAccount, operations: operations, memo: Memo(memoXDR:transactionXDR.memo), timeBounds: timebounds)
    }
    
    /// Creates a new Transaction object from an Transaction Envelope XDR string.
    ///
    /// - Parameter envelopeXdr: The XDR string to be parsed into a Transaction object.
    ///
    public convenience init(envelopeXdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: envelopeXdr))
        
        let transactionEnvelopeXDR = try TransactionEnvelopeXDR(fromBinary: xdrDecoder)
        let keypair = KeyPair(publicKey: transactionEnvelopeXDR.tx.sourceAccount)
        let transactionSourceAccount = Account(keyPair: keypair, sequenceNumber: transactionEnvelopeXDR.tx.seqNum - 1)
        var operations = [Operation]()
        for operationXDR in transactionEnvelopeXDR.tx.operations {
            let operation = try Operation.fromXDR(operationXDR: operationXDR)
            operations.append(operation)
        }
        
        var timebounds: TimeBounds?
        if let timeboundsXDR = transactionEnvelopeXDR.tx.timeBounds {
            timebounds = TimeBounds(timebounds: timeboundsXDR)
        }
        
        try self.init(sourceAccount: transactionSourceAccount, operations: operations, memo: Memo(memoXDR:transactionEnvelopeXDR.tx.memo), timeBounds: timebounds)
        
        for signature in transactionEnvelopeXDR.signatures {
            self.transactionXDR.addSignature(signature: signature)
        }
    }
    
    /// Each transaction needs to be signed before sending it to the stellar network.
    ///
    /// - Parameter keyPair: key pair to be used as a signer. Must containing the private key.
    /// - Parameter network: Network to specify which Stellar network you want to use.
    ///
    public func sign(keyPair:KeyPair, network:Network) throws {
        
        if (keyPair.privateKey == nil) {
            throw StellarSDKError.invalidArgument(message: "KeyPair must contain the private key to be able to sign the transaction.")
        }
        
        try self.transactionXDR.sign(keyPair: keyPair, network: network)
    }
    
    /// Returns the base64 encoded transaction envelope xdr to be used to post the transaction. Transaction need to have at least one signature before they can be sent to the stellar network.
    public func encodedEnvelope() throws -> String {
        return try transactionXDR.encodedEnvelope()
    }
    
    public func getTransactionHash(network:Network) throws -> String {
        let transactionHash = try [UInt8](transactionXDR.hash(network: network))
        let str = Data(bytes: transactionHash).hexEncodedString()
        return str
    }
    
    public func getTransactionHashData(network:Network) throws -> Data {
        let transactionHash = try [UInt8](transactionXDR.hash(network: network))
        let data = Data(bytes: transactionHash)
        return data
    }
}
