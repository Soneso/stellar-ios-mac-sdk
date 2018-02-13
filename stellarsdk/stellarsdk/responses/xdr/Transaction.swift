//
//  Transaction.swift
//  stellarsdk
//
//  Created by Razvan Chelemen on 09/02/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import UIKit

public enum MemoType: Int {
    case none = 0
    case text = 1
    case id = 2
    case hash = 3
    case `return` = 4
}

public enum Memo: XDRCodable {
    case none
    case text (String)
    case id (UInt64)
    case hash (WrappedData32)
    case `return` (WrappedData32)
    
    private func type() -> Int32 {
        switch self {
            case .none: return Int32(MemoType.none.rawValue)
            case .text: return Int32(MemoType.text.rawValue)
            case .id: return Int32(MemoType.id.rawValue)
            case .hash: return Int32(MemoType.hash.rawValue)
            case .`return`: return Int32(MemoType.`return`.rawValue)
        }
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        _ = try container.decode(Int32.self)
        
        self = .none
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
            case .none: break
            case .text(let text): try container.encode(text)
            case .id(let id): try container.encode(id)
            case .hash(let hash): try container.encode(hash)
            case .`return`(let hash): try container.encode(hash)
        }
    }
}

public struct TimeBounds: XDRCodable {
    public let minTime: UInt64
    public let maxTime: UInt64
}

public struct Transaction: XDRCodable {
    public let sourceAccount: PublicKey
    public let fee: UInt32
    public let seqNum: UInt64
    public let timeBounds: TimeBounds?
    public let memo: Memo
    public let operations: [Operation]
    public let reserved: Int32 = 0
    
    public init(sourceAccount: PublicKey, seqNum: UInt64, timeBounds: TimeBounds?, memo: Memo, operations: [Operation]) {
        self.sourceAccount = sourceAccount
        self.seqNum = seqNum
        self.timeBounds = timeBounds
        self.memo = memo
        self.operations = operations
        
        self.fee = UInt32(100 * operations.count)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        sourceAccount = try container.decode(PublicKey.self)
        fee = try container.decode(UInt32.self)
        seqNum = try container.decode(UInt64.self)
        timeBounds = try container.decode(Array<TimeBounds>.self).first
        memo = try container.decode(Memo.self)
        operations = try container.decode(Array<Operation>.self)
        _ = try container.decode(Int32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(sourceAccount)
        try container.encode(fee)
        try container.encode(seqNum)
        try container.encode(timeBounds)
        try container.encode(memo)
        try container.encode(operations)
        try container.encode(reserved)
    }
}
