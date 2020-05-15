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
    public let fee: UInt32
    public let innerTx:InnerTransactionXDR
    public let reserved: Int32
    
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
    
    public init(sourceAccount: MuxedAccountXDR, innerTx:InnerTransactionXDR, fee:UInt32) {
        self.sourceAccount = sourceAccount
        self.innerTx = innerTx
        self.fee = fee
        reserved = 0
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try container.decode(MuxedAccountXDR.self)
        fee = try container.decode(UInt32.self)
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
}


