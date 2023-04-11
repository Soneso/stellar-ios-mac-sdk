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
    case ed25519ContractID(Ed25519ContractID)
    case contractID(ContractID)
    case fromAsset(FromAsset)
    case sourceAccountContractID(SourceAccountContractID)
    case createContractArgs(CreateContractArgs)
    case contractAuth(ContractAuthPreimage)
    
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
        case EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ED25519:
            let value = try container.decode(Ed25519ContractID.self)
            self = .ed25519ContractID(value)
        case EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_CONTRACT:
            let value = try container.decode(ContractID.self)
            self = .contractID(value)
        case EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ASSET:
            let value = try container.decode(FromAsset.self)
            self = .fromAsset(value)
        case EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_SOURCE_ACCOUNT:
            let value = try container.decode(SourceAccountContractID.self)
            self = .sourceAccountContractID(value)
        case EnvelopeType.ENVELOPE_TYPE_CREATE_CONTRACT_ARGS:
            let value = try container.decode(CreateContractArgs.self)
            self = .createContractArgs(value)
        case EnvelopeType.ENVELOPE_TYPE_CONTRACT_AUTH:
            let value = try container.decode(ContractAuthPreimage.self)
            self = .contractAuth(value)
        default:
            let value = try container.decode(OperationID.self)
            self = .operationId(value)
        }
    }
  
    public func type() -> Int32 {
        switch self {
        case .operationId: return EnvelopeType.ENVELOPE_TYPE_OP_ID
        case .revokeId: return EnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID
        case .ed25519ContractID: return EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ED25519
        case .contractID: return EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_CONTRACT
        case .fromAsset: return EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_ASSET
        case .sourceAccountContractID: return EnvelopeType.ENVELOPE_TYPE_CONTRACT_ID_FROM_SOURCE_ACCOUNT
        case .createContractArgs: return EnvelopeType.ENVELOPE_TYPE_CREATE_CONTRACT_ARGS
        case .contractAuth: return EnvelopeType.ENVELOPE_TYPE_CONTRACT_AUTH
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
        case .ed25519ContractID(let value):
            try container.encode(value)
        case .contractID(let value):
            try container.encode(value)
        case .fromAsset(let value):
            try container.encode(value)
        case .sourceAccountContractID(let value):
            try container.encode(value)
        case .createContractArgs(let value):
            try container.encode(value)
        case .contractAuth(let value):
            try container.encode(value)
        }
    }
}

public struct ContractAuthPreimage: XDRCodable {
    let networkID: WrappedData32
    let nonce: UInt64
    let invocation: AuthorizedInvocationXDR
    
    init(networkID: WrappedData32, nonce: UInt64, invocation: AuthorizedInvocationXDR) {
        self.networkID = networkID
        self.nonce = nonce
        self.invocation = invocation
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        try container.encode(nonce)
        try container.encode(invocation)
    }
}

public struct CreateContractArgs: XDRCodable {
    let networkID: WrappedData32
    let source: SCContractExecutableXDR
    let salt: [UInt8]
    
    init(networkID: WrappedData32, source: SCContractExecutableXDR, salt: [UInt8]) {
        self.networkID = networkID
        self.source = source
        self.salt = salt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        try container.encode(source)
        var bytesArray = salt
        var wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
    }
}

public struct SourceAccountContractID: XDRCodable {
    let networkID: WrappedData32
    let sourceAccount: PublicKey
    let salt: [UInt8]
    
    init(networkID: WrappedData32, sourceAccount: PublicKey, salt: [UInt8]) {
        self.networkID = networkID
        self.sourceAccount = sourceAccount
        self.salt = salt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        try container.encode(sourceAccount)
        var bytesArray = salt
        var wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
    }
}

public struct FromAsset: XDRCodable {
    let networkID: WrappedData32
    let asset: AssetXDR
    
    init(networkID: WrappedData32, asset: AssetXDR) {
        self.networkID = networkID
        self.asset = asset
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        try container.encode(asset)
    }
}

public struct ContractID: XDRCodable {
    let networkID: WrappedData32
    let contractID: WrappedData32
    let salt: [UInt8]
    
    init(networkID: WrappedData32, contractID: WrappedData32, salt: [UInt8]) {
        self.networkID = networkID
        self.contractID = contractID
        self.salt = salt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        try container.encode(contractID)
        var bytesArray = salt
        var wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
    }
}

public struct Ed25519ContractID: XDRCodable {
    let networkID: WrappedData32
    let ed25519: [UInt8]
    let salt: [UInt8]
    
    init(networkID: WrappedData32, ed25519: [UInt8], salt: [UInt8]) {
        self.networkID = networkID
        self.ed25519 = ed25519
        self.salt = salt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(networkID)
        var bytesArray = ed25519
        var wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
        bytesArray = salt
        wrapped = WrappedData32(Data(bytes: &bytesArray, count: bytesArray.count))
        try container.encode(wrapped)
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
