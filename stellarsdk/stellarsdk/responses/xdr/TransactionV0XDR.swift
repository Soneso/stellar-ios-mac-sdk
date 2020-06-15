//
//  TransactionV0XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public struct TransactionV0XDR: XDRCodable {
    public let sourceAccountEd25519: [UInt8]
    public let fee: UInt32
    public let seqNum: Int64
    public let timeBounds: TimeBoundsXDR?
    public let memo: MemoXDR
    public let operations: [OperationXDR]
    public let reserved: Int32
    
    private var signatures = [DecoratedSignatureXDR]()
    
    public init(sourceAccount: PublicKey, seqNum: Int64, timeBounds: TimeBoundsXDR?, memo: MemoXDR, operations: [OperationXDR], maxOperationFee:UInt32 = 100) {
        self.sourceAccountEd25519 = sourceAccount.bytes
        self.seqNum = seqNum
        self.timeBounds = timeBounds
        self.memo = memo
        self.operations = operations
        
        self.fee = maxOperationFee * UInt32(operations.count)
        
        reserved = 0
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let wrappedData = try container.decode(WrappedData32.self)
        self.sourceAccountEd25519 = wrappedData.wrapped.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: wrappedData.wrapped.count))
        }
        fee = try container.decode(UInt32.self)
        seqNum = try container.decode(Int64.self)
        timeBounds = try decodeArray(type: TimeBoundsXDR.self, dec: decoder).first
        memo = try container.decode(MemoXDR.self)
        operations = try decodeArray(type: OperationXDR.self, dec: decoder)
        reserved = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        var bytesArray = sourceAccountEd25519
        let wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
        try container.encode(fee)
        try container.encode(seqNum)
        if let _ = timeBounds {
            try container.encode([timeBounds])
        } else {
            try container.encode([TimeBoundsXDR]())
        }
        try container.encode(memo)
        try container.encode(operations)
        try container.encode(reserved)
    }
    
    public mutating func sign(keyPair:KeyPair, network:Network) throws {
        let transactionHash = try [UInt8](hash(network: network))
        let signature = keyPair.signDecorated(transactionHash)
        signatures.append(signature)
    }
    
    public mutating func addSignature(signature: DecoratedSignatureXDR) {
        signatures.append(signature)
    }
    
    public func hash(network:Network) throws -> Data {
        let sourcePublicKey = PublicKey(unchecked: self.sourceAccountEd25519)
        let txXdr = TransactionXDR(sourceAccount: sourcePublicKey, seqNum: self.seqNum, timeBounds: self.timeBounds, memo: self.memo, operations: self.operations,maxOperationFee: self.fee)
        return try txXdr.hash(network: network)
    }
    
    public func toEnvelopeXDR() throws -> TransactionEnvelopeXDR {
        guard !signatures.isEmpty else {
            throw StellarSDKError.invalidArgument(message: "Transaction must be signed by at least one signer. Use transaction.sign().")
        }
        
        let envelopeV0 = TransactionV0EnvelopeXDR(tx: self, signatures: signatures)
        return TransactionEnvelopeXDR.v0(envelopeV0)
    }
    public func encodedEnvelope() throws -> String {
        let envelope = try toEnvelopeXDR()
        var encodedEnvelope = try XDREncoder.encode(envelope)
        
        return Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString()
    }
    
    public func toEnvelopeV0XDR() throws -> TransactionV0EnvelopeXDR {
        guard !signatures.isEmpty else {
            throw StellarSDKError.invalidArgument(message: "Transaction must be signed by at least one signer. Use transaction.sign().")
        }
        
        let envelopeV0 = TransactionV0EnvelopeXDR(tx: self, signatures: signatures)
        return envelopeV0;
    }
    
    public func encodedV0Envelope() throws -> String {
        let envelope = try toEnvelopeV0XDR()
        var encodedEnvelope = try XDREncoder.encode(envelope)
        
        return Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString()
    }
    
    public func encodedV0Transaction() throws -> String {
        var encodedT = try XDREncoder.encode(self)
        
        return Data(bytes: &encodedT, count: encodedT.count).base64EncodedString()
    }
    
}
