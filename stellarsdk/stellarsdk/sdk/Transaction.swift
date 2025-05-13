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
    
    public static let minBaseFee:UInt32 = 100
    public private(set) var fee:UInt32
    public let sourceAccount:TransactionAccount
    public private(set) var operations:[Operation]
    public private(set) var memo:Memo
    public private(set) var preconditions:TransactionPreconditions?
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
    /// - Parameter preconditions: Optional. Transaction preconditions as defined in CAP-21
    /// - Parameter maxOperationFee: Optional. The maximum fee in stoops you are willing to pay per operation. If not set, it will default to the network base fee which is currently set to 100 stroops (0.00001 lumens). Transaction fee is equal to operation fee times number of operations in this transaction.
    /// - Parameter sorobanTransactionData: Optional. Soroban Transaction Data
    ///
    public init(sourceAccount:TransactionAccount, operations:[Operation], memo:Memo?, preconditions:TransactionPreconditions? = nil, maxOperationFee:UInt32 = Transaction.minBaseFee, sorobanTransactionData:SorobanTransactionDataXDR? = nil) throws {
        if operations.count == 0 {
            throw StellarSDKError.invalidArgument(message: "At least one operation required")
        }
        
        self.sourceAccount = sourceAccount
        self.operations = operations
        self.preconditions = preconditions
        
        self.fee = maxOperationFee * UInt32(operations.count)
        
        self.memo = memo ?? Memo.none
        
        var operationsXDR = [OperationXDR]()
        
        for operation in self.operations {
            try operationsXDR.append(operation.toXDR())
        }
        
        let muxedAccount:MuxedAccountXDR
        if let mux = sourceAccount as? MuxedAccount {
            muxedAccount = mux.xdr
        } else {
            muxedAccount = MuxedAccountXDR.ed25519(sourceAccount.keyPair.publicKey.bytes)
        }
        
        var condXdr = PreconditionsXDR.none
        if let pc = preconditions {
            condXdr = pc.toXdr()
        }
        let tExt = sorobanTransactionData != nil ? TransactionExtXDR.sorobanTransactionData(sorobanTransactionData!) : TransactionExtXDR.void
        self.transactionXDR = TransactionXDR(sourceAccount: muxedAccount,
                                             seqNum: self.sourceAccount.incrementedSequenceNumber(),
                                             cond: condXdr,
                                             memo: self.memo.toXDR(),
                                             operations: operationsXDR,
                                             maxOperationFee: maxOperationFee,
                                             ext: tExt)
        
        self.sourceAccount.incrementSequenceNumber()
        
    }
    
    @available(*, deprecated, message: "use init with preconditions instead")
    public convenience init(sourceAccount:TransactionAccount, operations:[Operation], memo:Memo?, timeBounds:TimeBounds?, maxOperationFee:UInt32 = Transaction.minBaseFee) throws {
        let precond = TransactionPreconditions(timeBounds:timeBounds)
        try self.init(sourceAccount:sourceAccount, operations:operations, memo:memo, preconditions:precond, maxOperationFee:maxOperationFee)
    }
    
    /// Creates a new Transaction object from an XDR string.
    ///
    /// - Parameter xdr: The XDR string to be parsed into a Transaction object.
    ///
    public convenience init(xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        let transactionXDR = try TransactionXDR(fromBinary: xdrDecoder)
        let transactionSourceAccount = try MuxedAccount(accountId: transactionXDR.sourceAccount.accountId, sequenceNumber: transactionXDR.seqNum - 1, id: transactionXDR.sourceAccount.id)
        var operations = [Operation]()
        for operationXDR in transactionXDR.operations {
            let operation = try Operation.fromXDR(operationXDR: operationXDR)
            operations.append(operation)
        }
        
        let preconditions = TransactionPreconditions(preconditions: transactionXDR.cond)
        
        let txFee = transactionXDR.fee;
        let maxOperationFee = operations.count > 1 ? txFee /  UInt32(operations.count) : txFee
        
        try self.init(sourceAccount: transactionSourceAccount, operations: operations, memo: Memo(memoXDR:transactionXDR.memo), preconditions: preconditions, maxOperationFee: maxOperationFee)
    }
    
    /// Creates a new Transaction object from an Transaction Envelope XDR string.
    ///
    /// - Parameter envelopeXdr: The XDR string to be parsed into a Transaction object.
    ///
    public convenience init(envelopeXdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: envelopeXdr))
        
        let transactionEnvelopeXDR = try TransactionEnvelopeXDR(fromBinary: xdrDecoder)
        let transactionSourceAccount = try MuxedAccount(accountId:transactionEnvelopeXDR.txSourceAccountId, sequenceNumber: transactionEnvelopeXDR.txSeqNum - 1, id: transactionEnvelopeXDR.txMuxedSourceId)
        var operations = [Operation]()
        for operationXDR in transactionEnvelopeXDR.txOperations {
            let operation = try Operation.fromXDR(operationXDR: operationXDR)
            operations.append(operation)
        }
        
        let preconditions = TransactionPreconditions(preconditions: transactionEnvelopeXDR.cond)
        
        let txFee = transactionEnvelopeXDR.txFee;
        let maxOperationFee = operations.count > 1 ? txFee /  UInt32(operations.count) : txFee
        
        try self.init(sourceAccount: transactionSourceAccount, operations: operations, memo: Memo(memoXDR:transactionEnvelopeXDR.txMemo), preconditions: preconditions, maxOperationFee: maxOperationFee, sorobanTransactionData: transactionEnvelopeXDR.sorobanTransactionData)
        
        for signature in transactionEnvelopeXDR.txSignatures {
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
    
    public func addSignature(signature:DecoratedSignatureXDR) -> Void {
        self.transactionXDR.addSignature(signature: signature)
    }
    
    /// Returns the base64 encoded transaction envelope xdr to be used to post the transaction. Transaction need to have at least one signature before they can be sent to the stellar network.
    public func encodedEnvelope() throws -> String {
        return try transactionXDR.encodedEnvelope()
    }
    
    public func getTransactionHash(network:Network) throws -> String {
        let transactionHash = try [UInt8](transactionXDR.hash(network: network))
        let str = Data(transactionHash).hexEncodedString()
        return str
    }
    
    public func getTransactionHashData(network:Network) throws -> Data {
        let transactionHash = try [UInt8](transactionXDR.hash(network: network))
        let data = Data(transactionHash)
        return data
    }
    
    public func setSorobanTransactionData(data: SorobanTransactionDataXDR) {
        let ext = TransactionExtXDR.sorobanTransactionData(data)
        transactionXDR.ext = ext
    }
    
    public func addResourceFee(resourceFee:UInt32) {
        fee += resourceFee
        transactionXDR.fee = fee
    }
    
    public func setSorobanAuth(auth:[SorobanAuthorizationEntryXDR]?) {
        var authToSet = auth
        if (authToSet == nil) {
            authToSet = []
        }
        
        for operation in operations {
            if let op = operation as? InvokeHostFunctionOperation {
                op.auth = authToSet!
            }
        }
        
        for i in 0...transactionXDR.operations.count - 1 {
            transactionXDR.operations[i].setSorobanAuth(auth: authToSet!)
        }
    }
    
    public func setMemo(memo:Memo? = nil) {
        self.memo = memo ?? Memo.none
        transactionXDR.memo = self.memo.toXDR()
    }
    
    public func setPreconditions(preconditions:TransactionPreconditions? = nil) {
        self.preconditions = preconditions
        var condXdr = PreconditionsXDR.none
        if let pc = self.preconditions {
            condXdr = pc.toXdr()
        }
        transactionXDR.cond = condXdr
    }
    
    public func setFee(fee:UInt32) {
        self.fee = fee
        transactionXDR.fee = self.fee
    }
    
    public func addOperation(operation:Operation) throws {
        self.operations.append(operation)
        self.transactionXDR.operations.append(try operation.toXDR())
    }
}
