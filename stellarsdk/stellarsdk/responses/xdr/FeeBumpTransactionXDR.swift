//
//  FeeBumpTransactionXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 12.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation



public struct FeeBumpTransactionXDR: XDRCodable {
    public let sourceAccount: MuxedAccountXDR
    public let fee: UInt64
    public let innerTx:InnerTransactionXDR
    public let reserved: Int32
    
    private var signatures = [DecoratedSignatureXDR]()
    
    public enum InnerTransactionXDR: XDRCodable {
        case v1 (TransactionV1EnvelopeXDR)
        
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            
            let type = try container.decode(Int32.self)
            
            switch type {
            default:
                let tv1 = try container.decode(TransactionV1EnvelopeXDR.self)
                self = .v1(tv1)
            }
        }
        
        public var tx: TransactionV1EnvelopeXDR {
            switch self {
            case .v1(let txv1):
                return txv1
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            try container.encode(EnvelopeType.ENVELOPE_TYPE_TX)
            
            switch self {
            case .v1 (let tx): try container.encode(tx)
            }
        }
    }
    
    public init(sourceAccount: MuxedAccountXDR, innerTx:InnerTransactionXDR, fee:UInt64) {
        self.sourceAccount = sourceAccount
        self.innerTx = innerTx
        self.fee = fee
        reserved = 0
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try container.decode(MuxedAccountXDR.self)
        fee = try container.decode(UInt64.self)
        innerTx = try container.decode(InnerTransactionXDR.self)
        reserved = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(sourceAccount)
        try container.encode(fee)
        try container.encode(innerTx)
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
        let payload = TransactionSignaturePayload(networkId: WrappedData32(network.networkId), taggedTransaction: .typeFeeBump(self))
        
        return try Data(bytes: XDREncoder.encode(payload))
    }
    
    public func hash(network:Network) throws -> Data {
        return try signatureBase(network: network).sha256()
    }
    
    public func toEnvelopeXDR() throws -> TransactionEnvelopeXDR {
        return try TransactionEnvelopeXDR.feeBump(toFBEnvelopeXDR())
    }
    
    public func toFBEnvelopeXDR() throws -> FeeBumpTransactionEnvelopeXDR {
        guard !signatures.isEmpty else {
            throw StellarSDKError.invalidArgument(message: "Transaction must be signed by at least one signer. Use transaction.sign().")
        }
        
        return FeeBumpTransactionEnvelopeXDR(tx: self, signatures: signatures)
    }
    
    public func encodedEnvelope() throws -> String {
        
        let envelope = try toEnvelopeXDR()
        var encodedEnvelope = try XDREncoder.encode(envelope)

        return Data(bytes: &encodedEnvelope, count: encodedEnvelope.count).base64EncodedString()
    }
}


