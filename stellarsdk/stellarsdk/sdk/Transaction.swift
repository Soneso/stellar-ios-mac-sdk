//
//  Transaction.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 17.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

/// Represents a Transaction in Stellar network.
/// See [Stellar developer docs](https://developers.stellar.org)
public class Transaction {

    /// The minimum fee per operation in stroops. Currently set to 100 stroops.
    public static let minBaseFee:UInt32 = 100
    /// The transaction fee in stroops (1 stroop = 0.0000001 XLM).
    public private(set) var fee:UInt32
    /// The account that originates the transaction.
    public let sourceAccount:TransactionAccount
    /// The list of operations contained in this transaction.
    public private(set) var operations:[Operation]
    /// Optional extra information attached to the transaction.
    public private(set) var memo:Memo
    /// Transaction validity constraints as defined in CAP-21.
    public private(set) var preconditions:TransactionPreconditions?
    /// The XDR representation of this transaction.
    public private(set) var transactionXDR:TransactionXDR

    /// The base64-encoded XDR string of this transaction.
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
        let tExt: TransactionExtXDR
        if let sorobanData = sorobanTransactionData {
            tExt = TransactionExtXDR.sorobanTransactionData(sorobanData)
        } else {
            tExt = TransactionExtXDR.void
        }
        self.transactionXDR = TransactionXDR(sourceAccount: muxedAccount,
                                             seqNum: self.sourceAccount.incrementedSequenceNumber(),
                                             cond: condXdr,
                                             memo: self.memo.toXDR(),
                                             operations: operationsXDR,
                                             maxOperationFee: maxOperationFee,
                                             ext: tExt)
        
        self.sourceAccount.incrementSequenceNumber()

    }

    /// Deprecated initializer that uses TimeBounds instead of TransactionPreconditions.
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

    /// Adds a pre-computed signature to the transaction without requiring the private key.
    public func addSignature(signature:DecoratedSignatureXDR) -> Void {
        self.transactionXDR.addSignature(signature: signature)
    }

    /// Returns the base64-encoded transaction envelope XDR for submission to the network.
    public func encodedEnvelope() throws -> String {
        return try transactionXDR.encodedEnvelope()
    }

    /// Computes and returns the transaction hash as a hex-encoded string for the specified network.
    public func getTransactionHash(network:Network) throws -> String {
        let transactionHash = try [UInt8](transactionXDR.hash(network: network))
        let str = Data(transactionHash).base16EncodedString()
        return str
    }

    /// Computes and returns the transaction hash as Data for the specified network.
    public func getTransactionHashData(network:Network) throws -> Data {
        let transactionHash = try [UInt8](transactionXDR.hash(network: network))
        let data = Data(transactionHash)
        return data
    }

    /// Sets the Soroban transaction data extension for smart contract invocations.
    public func setSorobanTransactionData(data: SorobanTransactionDataXDR) {
        let ext = TransactionExtXDR.sorobanTransactionData(data)
        transactionXDR.ext = ext
    }

    /// Adds additional resource fee in stroops for Soroban smart contract operations.
    public func addResourceFee(resourceFee:UInt32) {
        fee += resourceFee
        transactionXDR.fee = fee
    }

    /// Sets Soroban authorization entries for all InvokeHostFunction operations in this transaction.
    public func setSorobanAuth(auth:[SorobanAuthorizationEntryXDR]?) {
        let authToSet = auth ?? []

        for operation in operations {
            if let op = operation as? InvokeHostFunctionOperation {
                op.auth = authToSet
            }
        }

        for i in 0...transactionXDR.operations.count - 1 {
            transactionXDR.operations[i].setSorobanAuth(auth: authToSet)
        }
    }

    /// Updates the transaction memo. If nil, sets memo to none.
    public func setMemo(memo:Memo? = nil) {
        self.memo = memo ?? Memo.none
        transactionXDR.memo = self.memo.toXDR()
    }

    /// Updates the transaction preconditions. If nil, removes all preconditions.
    public func setPreconditions(preconditions:TransactionPreconditions? = nil) {
        self.preconditions = preconditions
        var condXdr = PreconditionsXDR.none
        if let pc = self.preconditions {
            condXdr = pc.toXdr()
        }
        transactionXDR.cond = condXdr
    }

    /// Sets the total transaction fee in stroops. Use this to override the calculated fee.
    public func setFee(fee:UInt32) {
        self.fee = fee
        transactionXDR.fee = self.fee
    }

    /// Appends an operation to the transaction's operation list.
    public func addOperation(operation:Operation) throws {
        self.operations.append(operation)
        self.transactionXDR.operations.append(try operation.toXDR())
    }
}
