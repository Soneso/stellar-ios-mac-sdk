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
public class Transaction: @unchecked Sendable {

    /// The minimum fee per operation in stroops. Currently set to 100 stroops.
    public static let minBaseFee:UInt32 = 100
    /// The transaction fee in stroops (1 stroop = 0.0000001 XLM).
    public var fee:UInt32 {
        lock.lock()
        defer { lock.unlock() }
        return _fee
    }
    /// The account that originates the transaction.
    public let sourceAccount:TransactionAccount
    /// The list of operations contained in this transaction.
    public var operations:[Operation] {
        lock.lock()
        defer { lock.unlock() }
        return _operations
    }
    /// Optional extra information attached to the transaction, for display.
    ///
    /// A text memo whose bytes are not valid UTF-8 reads with U+FFFD replacement characters, so
    /// this value cannot give the original bytes, their length or byte equality. The exact memo,
    /// which the hash and the signatures cover, is `transactionXDR.memo`.
    public var memo:Memo {
        lock.lock()
        defer { lock.unlock() }
        return _memo
    }
    /// Transaction validity constraints as defined in CAP-21.
    public var preconditions:TransactionPreconditions? {
        lock.lock()
        defer { lock.unlock() }
        return _preconditions
    }
    /// The V1 XDR representation (`TransactionXDR`) of this transaction, including when read from a V0 envelope.
    public var transactionXDR:TransactionXDR {
        lock.lock()
        defer { lock.unlock() }
        return _transactionXDR
    }

    /// The base64-encoded XDR string of this transaction.
    public var xdrEncoded: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _transactionXDR.xdrEncoded
        }
    }

    private var _fee:UInt32
    private var _operations:[Operation]
    private var _memo:Memo
    private var _preconditions:TransactionPreconditions?
    private var _transactionXDR:TransactionXDR
    private let decodedFromV0: Bool
    private let lock = NSLock()

    /// Creates a new Transaction object.
    ///
    /// - Parameter sourceAccount: Account that originates the transaction.
    /// - Parameter operations: Transactions contain an arbitrary list of operations inside them. Typically there is just one operation, but it's possible to have multiple. Operations are executed in order as one ACID transaction, meaning that either all operations are applied or none are.
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
        self._operations = operations
        self._preconditions = preconditions

        self._fee = maxOperationFee * UInt32(operations.count)

        self._memo = memo ?? Memo.none

        var operationsXDR = [OperationXDR]()

        for operation in self._operations {
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
        self._transactionXDR = TransactionXDR(sourceAccount: muxedAccount,
                                             seqNum: self.sourceAccount.incrementedSequenceNumber(),
                                             cond: condXdr,
                                             memo: self._memo.toXDR(),
                                             operations: operationsXDR,
                                             maxOperationFee: maxOperationFee,
                                             ext: tExt)
        self.decodedFromV0 = false

        self.sourceAccount.incrementSequenceNumber()

    }

    /// Creates a new Transaction object whose memo is the given XDR memo, byte for byte.
    ///
    /// Use it to carry a decoded memo, such as `transactionXDR.memo` of another transaction, into a
    /// new transaction: a text memo keeps bytes that are not valid UTF-8, which a `Memo` cannot hold.
    ///
    /// - Parameter sourceAccount: Account that originates the transaction.
    /// - Parameter operations: The operations of the transaction, executed in order; at least one.
    /// - Parameter memoXDR: The memo as it is written into the transaction.
    /// - Parameter preconditions: Optional. Transaction preconditions as defined in CAP-21
    /// - Parameter maxOperationFee: Optional. The maximum fee in stroops per operation; the transaction fee is this value times the number of operations.
    /// - Parameter sorobanTransactionData: Optional. Soroban Transaction Data
    ///
    /// - Throws: `StellarSDKError.invalidArgument` when `operations` is empty, and the errors of `Operation.toXDR()`.
    public convenience init(sourceAccount:TransactionAccount, operations:[Operation], memoXDR:MemoXDR, preconditions:TransactionPreconditions? = nil, maxOperationFee:UInt32 = Transaction.minBaseFee, sorobanTransactionData:SorobanTransactionDataXDR? = nil) throws {
        try self.init(sourceAccount: sourceAccount, operations: operations, memo: nil, preconditions: preconditions, maxOperationFee: maxOperationFee, sorobanTransactionData: sorobanTransactionData)
        self._memo = Memo(memoXDR: memoXDR) ?? Memo.none
        self._transactionXDR.memo = memoXDR
    }

    /// Deprecated initializer that uses TimeBounds instead of TransactionPreconditions.
    @available(*, deprecated, message: "use init with preconditions instead")
    public convenience init(sourceAccount:TransactionAccount, operations:[Operation], memo:Memo?, timeBounds:TimeBounds?, maxOperationFee:UInt32 = Transaction.minBaseFee) throws {
        let precond = TransactionPreconditions(timeBounds:timeBounds)
        try self.init(sourceAccount:sourceAccount, operations:operations, memo:memo, preconditions:precond, maxOperationFee:maxOperationFee)
    }

    /// Creates a new Transaction object from an XDR string.
    ///
    /// The transaction keeps the decoded XDR as it is: `transactionXDR`, the hash, new signatures
    /// and `encodedEnvelope()` give the input bytes, and `fee` is the decoded total fee.
    ///
    /// - Parameter xdr: The XDR string to be parsed into a Transaction object.
    ///
    /// - Throws: `StellarSDKError.invalidArgument` for a sequence number of `Int64.min` and for a
    ///   transaction without operations, and the errors of `Operation.fromXDR(operationXDR:)` for an
    ///   operation it cannot decode.
    public convenience init(xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        let transactionXDR = try TransactionXDR(fromBinary: xdrDecoder)
        try self.init(importing: transactionXDR, signatures: [])
    }

    /// Creates a new Transaction object from an Transaction Envelope XDR string.
    ///
    /// The transaction keeps the decoded XDR as it is, with the envelope's signatures: the hash, new
    /// signatures and `transactionXDR` give the input bytes, and `fee` is the decoded total fee. For
    /// a V0 envelope, `transactionXDR` and the hash are its V1 form, and `encodedEnvelope()` writes a
    /// V0 envelope while the transaction fits the V0 format (no Soroban transaction data and no
    /// CAP-21 V2 preconditions) and a V1 envelope otherwise. A fee bump envelope gives its inner
    /// transaction with the inner signatures. Use `FeeBumpTransaction(envelopeXdr:)` to read a fee
    /// bump envelope as a fee bump transaction.
    ///
    /// - Parameter envelopeXdr: The XDR string to be parsed into a Transaction object.
    ///
    /// - Throws: `StellarSDKError.invalidArgument` for a sequence number of `Int64.min` and for a
    ///   transaction without operations, and the errors of `Operation.fromXDR(operationXDR:)` for an
    ///   operation it cannot decode.
    public convenience init(envelopeXdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: envelopeXdr))
        let transactionEnvelopeXDR = try TransactionEnvelopeXDR(fromBinary: xdrDecoder)
        let transactionXDR: TransactionXDR
        let decodedFromV0: Bool
        switch transactionEnvelopeXDR {
        case .v0(let envelopeV0):
            transactionXDR = envelopeV0.tx.v1Equivalent
            decodedFromV0 = true
        case .v1(let envelopeV1):
            transactionXDR = envelopeV1.tx
            decodedFromV0 = false
        case .feeBump(let envelopeFeeBump):
            switch envelopeFeeBump.tx.innerTx {
            case .v1(let innerEnvelope):
                transactionXDR = innerEnvelope.tx
            }
            decodedFromV0 = false
        }
        try self.init(importing: transactionXDR, signatures: transactionEnvelopeXDR.txSignatures, decodedFromV0: decodedFromV0)
    }

    /// Creates a transaction that keeps `transactionXDR` as decoded, with `signatures` appended.
    ///
    /// The high-level properties are derived from it: the source account at the sequence number
    /// before `seqNum`, incremented once to `seqNum`, the operations, the preconditions, the fee and
    /// the display memo.
    private init(importing transactionXDR: TransactionXDR, signatures: [DecoratedSignatureXDR], decodedFromV0: Bool = false) throws {
        let transactionSourceAccount = try MuxedAccount(accountId: transactionXDR.sourceAccount.accountId, sequenceNumber: Transaction.precedingSequenceNumber(transactionXDR.seqNum), id: transactionXDR.sourceAccount.id)
        var operations = [Operation]()
        for operationXDR in transactionXDR.operations {
            let operation = try Operation.fromXDR(operationXDR: operationXDR)
            operations.append(operation)
        }
        if operations.count == 0 {
            throw StellarSDKError.invalidArgument(message: "At least one operation required")
        }

        self.sourceAccount = transactionSourceAccount
        self._operations = operations
        self._preconditions = TransactionPreconditions(preconditions: transactionXDR.cond)
        self._fee = transactionXDR.fee
        self._memo = Memo(memoXDR: transactionXDR.memo) ?? Memo.none

        var keptTransactionXDR = transactionXDR
        for signature in signatures {
            keptTransactionXDR.addSignature(signature: signature)
        }
        self._transactionXDR = keptTransactionXDR
        self.decodedFromV0 = decodedFromV0

        self.sourceAccount.incrementSequenceNumber()
    }

    /// Returns the source account sequence number that `seqNum` follows, which the imported
    /// transaction's source account carries before the transaction increments it.
    private static func precedingSequenceNumber(_ seqNum: Int64) throws -> Int64 {
        guard seqNum > Int64.min else {
            throw StellarSDKError.invalidArgument(message: "Invalid transaction sequence number \(seqNum): no account sequence number precedes it")
        }
        return seqNum - 1
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

        lock.lock()
        defer { lock.unlock() }
        try self._transactionXDR.sign(keyPair: keyPair, network: network)
    }

    /// Adds a pre-computed signature to the transaction without requiring the private key.
    public func addSignature(signature:DecoratedSignatureXDR) -> Void {
        lock.lock()
        defer { lock.unlock() }
        self._transactionXDR.addSignature(signature: signature)
    }

    /// Returns the base64-encoded transaction envelope XDR for submission to the network.
    ///
    /// Writes a V0 envelope (`ENVELOPE_TYPE_TX_V0`) when the transaction was read from a V0
    /// envelope and its current state fits the V0 format (no Soroban transaction data and no
    /// CAP-21 V2 preconditions); writes a V1 envelope (`ENVELOPE_TYPE_TX`) otherwise.
    public func encodedEnvelope() throws -> String {
        lock.lock()
        defer { lock.unlock() }
        if decodedFromV0, case .void = _transactionXDR.ext {
            let timeBounds: TimeBoundsXDR?
            switch _transactionXDR.cond {
            case .none:
                timeBounds = nil
            case .time(let tb):
                timeBounds = tb
            case .v2:
                return try _transactionXDR.encodedEnvelope()
            }
            let v0Tx = TransactionV0XDR(
                sourceAccountEd25519: sourceAccount.keyPair.publicKey.bytes,
                fee: _transactionXDR.fee,
                seqNum: _transactionXDR.seqNum,
                timeBounds: timeBounds,
                memo: _transactionXDR.memo,
                operations: _transactionXDR.operations
            )
            let envelope = TransactionEnvelopeXDR.v0(TransactionV0EnvelopeXDR(tx: v0Tx, signatures: _transactionXDR.signatures))
            let encoded = try XDREncoder.encode(envelope)
            return Data(encoded).base64EncodedString()
        }
        return try _transactionXDR.encodedEnvelope()
    }

    /// Computes and returns the transaction hash as a hex-encoded string for the specified network.
    public func getTransactionHash(network:Network) throws -> String {
        lock.lock()
        defer { lock.unlock() }
        let transactionHash = try [UInt8](_transactionXDR.hash(network: network))
        let str = Data(transactionHash).base16EncodedString()
        return str
    }

    /// Computes and returns the transaction hash as Data for the specified network.
    public func getTransactionHashData(network:Network) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        let transactionHash = try [UInt8](_transactionXDR.hash(network: network))
        let data = Data(transactionHash)
        return data
    }

    /// Sets the Soroban transaction data extension for smart contract invocations.
    public func setSorobanTransactionData(data: SorobanTransactionDataXDR) {
        lock.lock()
        defer { lock.unlock() }
        let ext = TransactionExtXDR.sorobanTransactionData(data)
        _transactionXDR.ext = ext
    }

    /// Adds additional resource fee in stroops for Soroban smart contract operations.
    public func addResourceFee(resourceFee:UInt32) {
        lock.lock()
        defer { lock.unlock() }
        _fee += resourceFee
        _transactionXDR.fee = _fee
    }

    /// Sets Soroban authorization entries for all InvokeHostFunction operations in this transaction.
    public func setSorobanAuth(auth:[SorobanAuthorizationEntryXDR]?) {
        lock.lock()
        defer { lock.unlock() }
        let authToSet = auth ?? []

        for operation in _operations {
            if let op = operation as? InvokeHostFunctionOperation {
                op.auth = authToSet
            }
        }

        for i in 0..._transactionXDR.operations.count - 1 {
            _transactionXDR.operations[i].setSorobanAuth(auth: authToSet)
        }
    }

    /// Updates the transaction memo. If nil, sets memo to none.
    ///
    /// The memo is written from its value: a text memo read from `memo` of a transaction whose memo
    /// bytes are not valid UTF-8 writes its replacement characters, not the original bytes. Use
    /// `setMemo(memoXDR:)` to keep the bytes.
    public func setMemo(memo:Memo? = nil) {
        lock.lock()
        defer { lock.unlock() }
        self._memo = memo ?? Memo.none
        _transactionXDR.memo = self._memo.toXDR()
    }

    /// Updates the transaction memo to the given XDR memo, byte for byte.
    ///
    /// Use it to carry a decoded memo, such as `transactionXDR.memo` of another transaction, into
    /// this transaction: a text memo keeps bytes that are not valid UTF-8. `memo` then reads its
    /// display value.
    public func setMemo(memoXDR:MemoXDR) {
        lock.lock()
        defer { lock.unlock() }
        self._memo = Memo(memoXDR: memoXDR) ?? Memo.none
        _transactionXDR.memo = memoXDR
    }

    /// Updates the transaction preconditions. If nil, removes all preconditions.
    public func setPreconditions(preconditions:TransactionPreconditions? = nil) {
        lock.lock()
        defer { lock.unlock() }
        self._preconditions = preconditions
        var condXdr = PreconditionsXDR.none
        if let pc = self._preconditions {
            condXdr = pc.toXdr()
        }
        _transactionXDR.cond = condXdr
    }

    /// Sets the total transaction fee in stroops. Use this to override the calculated fee.
    public func setFee(fee:UInt32) {
        lock.lock()
        defer { lock.unlock() }
        self._fee = fee
        _transactionXDR.fee = self._fee
    }

    /// Appends an operation to the transaction's operation list.
    public func addOperation(operation:Operation) throws {
        lock.lock()
        defer { lock.unlock() }
        self._operations.append(operation)
        self._transactionXDR.operations.append(try operation.toXDR())
    }
}
