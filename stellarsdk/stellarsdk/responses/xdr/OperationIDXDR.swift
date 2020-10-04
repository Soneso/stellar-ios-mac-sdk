//
//  OperationIDXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum OperationIDXDR: XDRCodable {
    case id(OperationIDId)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case EnvelopeType.ENVELOPE_TYPE_OP_ID:
            let value = try container.decode(OperationIDId.self)
            self = .id(value)
        default:
            let value = try container.decode(OperationIDId.self)
            self = .id(value)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .id: return EnvelopeType.ENVELOPE_TYPE_OP_ID
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .id(let value):
            try container.encode(value)
        }
    }
}


public struct OperationIDId: XDRCodable {
    let sourceAccount: MuxedAccountXDR
    let seqNum: Int64
    let opNum: UInt64
    
    init(sourceAccount: MuxedAccountXDR, seqNum:Int64, opNum:UInt64) {
        self.sourceAccount = sourceAccount
        self.seqNum = seqNum
        self.opNum = opNum
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sourceAccount)
        try container.encode(seqNum)
        try container.encode(opNum)
    }
}
