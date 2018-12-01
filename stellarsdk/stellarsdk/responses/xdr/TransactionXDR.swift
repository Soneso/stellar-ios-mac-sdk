//
//  TransactionXDR.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public struct TransactionXDR: XDRCodable {
    public let sourceAccount: PublicKey
    public let fee: UInt32
    public let seqNum: Int64
    public let timeBounds: TimeBoundsXDR?
    public let memo: MemoXDR
    public let operations: [OperationXDR]
    public let reserved: Int32
    
    private var signatures = [DecoratedSignatureXDR]()
    
    public init(sourceAccount: PublicKey, seqNum: Int64, timeBounds: TimeBoundsXDR?, memo: MemoXDR, operations: [OperationXDR]) {
        self.sourceAccount = sourceAccount
        self.seqNum = seqNum
        self.timeBounds = timeBounds
        self.memo = memo
        self.operations = operations
        
        fee = UInt32(100 * operations.count)
        reserved = 0
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try container.decode(PublicKey.self)
        fee = try container.decode(UInt32.self)
        seqNum = try container.decode(Int64.self)
        timeBounds = try decodeArray(type: TimeBoundsXDR.self, dec: decoder).first
        memo = try container.decode(MemoXDR.self)
        operations = try decodeArray(type: OperationXDR.self, dec: decoder)
        reserved = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(sourceAccount)
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
    
    private func signatureBase(network:Network) throws -> Data {
        let payload = TransactionSignaturePayload(networkId: WrappedData32(network.networkId), taggedTransaction: .typeTX(self))
        
        return try Data(bytes: XDREncoder.encode(payload))
    }
    
    public func hash(network:Network) throws -> Data {
        return try signatureBase(network: network).sha256()
    }
    
    public func toEnvelopeXDR() throws -> TransactionEnvelopeXDR {
        guard !signatures.isEmpty else {
            throw StellarSDKError.invalidArgument(message: "Transaction must be signed by at least one signer. Use transaction.sign().")
        }
        
        let envelope = TransactionEnvelopeXDR(tx: self, signatures: signatures)
        
        return envelope
    }
    
    public func encodedEnvelope() throws -> String {
        let envelope = try toEnvelopeXDR()
        var encodedEnvelope = try XDREncoder.encode(envelope)
        
        return Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString()
    }
    
}
