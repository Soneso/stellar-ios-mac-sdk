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
    case contractID(HashIDPreimageContractIDXDR)
    case sorobanAuthorization(HashIDPreimageSorobanAuthorizationXDR)
    
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
        case EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID:
            let value = try container.decode(HashIDPreimageContractIDXDR.self)
            self = .contractID(value)
        case EnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION:
            let value = try container.decode(HashIDPreimageSorobanAuthorizationXDR.self)
            self = .sorobanAuthorization(value)
        default:
            let value = try container.decode(OperationID.self)
            self = .operationId(value)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .operationId: return EnvelopeType.ENVELOPE_TYPE_OP_ID
        case .revokeId: return EnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID
        case .contractID: return EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID
        case .sorobanAuthorization: return EnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION
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
        case .contractID(let value):
            try container.encode(value)
        case .sorobanAuthorization(let value):
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

public struct HashIDPreimageContractIDXDR: XDRCodable {
    
    let networkID: WrappedData32
    let contractIDPreimage: ContractIDPreimageXDR
    
    public init(networkID: WrappedData32, contractIDPreimage: ContractIDPreimageXDR) {
        self.networkID = networkID
        self.contractIDPreimage = contractIDPreimage
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        try container.encode(contractIDPreimage)
    }
}

public struct HashIDPreimageSorobanAuthorizationXDR: XDRCodable {

    let networkID: WrappedData32
    let nonce: Int64
    let signatureExpirationLedger: UInt32
    let invocation: SorobanAuthorizedInvocationXDR
    
    public init(networkID: WrappedData32, nonce: Int64, signatureExpirationLedger: UInt32, invocation: SorobanAuthorizedInvocationXDR) {
        self.networkID = networkID
        self.nonce = nonce
        self.signatureExpirationLedger = signatureExpirationLedger
        self.invocation = invocation
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        try container.encode(nonce)
        try container.encode(signatureExpirationLedger)
        try container.encode(invocation)
    }
}
