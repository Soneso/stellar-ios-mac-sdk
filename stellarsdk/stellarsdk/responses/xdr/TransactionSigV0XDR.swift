//
//  TransactionSigV0XDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 17.05.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation


public struct TransactionSigV0XDR: XDRCodable {
    public let sourceAccountEd25519: PublicKey
    public let fee: UInt32
    public let seqNum: Int64
    public let timeBounds: TimeBoundsXDR?
    public let memo: MemoXDR
    public let operations: [OperationXDR]
    public let reserved: Int32
    
    private var signatures = [DecoratedSignatureXDR]()
    
    public init(sourceAccount: PublicKey, seqNum: Int64, timeBounds: TimeBoundsXDR?, memo: MemoXDR, operations: [OperationXDR], maxOperationFee:UInt32 = 100) {
        self.sourceAccountEd25519 = sourceAccount
        self.seqNum = seqNum
        self.timeBounds = timeBounds
        self.memo = memo
        self.operations = operations
        
        self.fee = maxOperationFee * UInt32(operations.count)
        
        reserved = 0
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
    
        self.sourceAccountEd25519 = try container.decode(PublicKey.self)
        fee = try container.decode(UInt32.self)
        seqNum = try container.decode(Int64.self)
        timeBounds = try decodeArray(type: TimeBoundsXDR.self, dec: decoder).first
        memo = try container.decode(MemoXDR.self)
        operations = try decodeArray(type: OperationXDR.self, dec: decoder)
        reserved = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sourceAccountEd25519)
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

}
