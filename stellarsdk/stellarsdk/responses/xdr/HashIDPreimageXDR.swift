//
//  HashIDPreimageXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 25.09.20.
//  Copyright © 2020 Soneso. All rights reserved.
//

import Foundation

public enum HashIDPreimageXDR: XDRCodable {
    case operationId(OperationID)
    case revokeId(RevokeID)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case EnvelopeType.ENVELOPE_TYPE_OP_ID:
            let value = try container.decode(OperationID.self)
            self = .operationId(value)
        case EnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID:
            let value = try container.decode(RevokeID.self)
            self = .revokeId(value)
        default:
            let value = try container.decode(OperationID.self)
            self = .operationId(value)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .operationId: return EnvelopeType.ENVELOPE_TYPE_OP_ID
        case .revokeId: return EnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .operationId(let value):
            try container.encode(value)
        case .revokeId(let value):
            try container.encode(value)
        }
    }
}


public struct OperationID: XDRCodable {
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

public struct RevokeID: XDRCodable {
    let sourceAccount: MuxedAccountXDR
    let seqNum: Int64
    let opNum: UInt64
    let liquidityPoolID:WrappedData32
    let asset:AssetXDR
    
    init(sourceAccount: MuxedAccountXDR, seqNum:Int64, opNum:UInt64, liquidityPoolID:WrappedData32, asset:AssetXDR) {
        self.sourceAccount = sourceAccount
        self.seqNum = seqNum
        self.opNum = opNum
        self.liquidityPoolID = liquidityPoolID
        self.asset = asset
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sourceAccount)
        try container.encode(seqNum)
        try container.encode(opNum)
        try container.encode(liquidityPoolID)
        try container.encode(asset)
    }
}
