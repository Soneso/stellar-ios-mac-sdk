//
//  LedgerKeyXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

// Identifiers of all the network settings.
public enum ConfigSettingID: Int32 {
    case contractMaxSizeBytes = 0
    case contractComputeV0 = 1
    case contractLedgerCostV0 = 2
    case contractHistoricalDataV0 = 3
    case contractEventsV0 = 4
    case contractBandwidthV0 = 5
    case contractCostParamsCpuInstructions = 6
    case contractCostParamsMemoryBytes = 7
    case contractDataKeySizeBytes = 8
    case contractDataEntrySizeBytes = 9
    case stateArchival = 10
    case contractExecutionLanes = 11
    case liveSorobanStateSizeWindow = 12
    case evictionIterator = 13
    case contractParallelComputeV0 = 14
    case contractLedgerCostExtV0 = 15
    case scpTiming = 16
}

public enum LedgerKeyXDR: XDRCodable {
    case account (LedgerKeyAccountXDR)
    case trustline (LedgerKeyTrustLineXDR)
    case offer (LedgerKeyOfferXDR)
    case data (LedgerKeyDataXDR)
    case claimableBalance (ClaimableBalanceIDXDR)
    case liquidityPool(LiquidityPoolIDXDR)
    case contractData(LedgerKeyContractDataXDR)
    case contractCode(LedgerKeyContractCodeXDR)
    case configSetting(Int32)
    case ttl(LedgerKeyTTLXDR)
    
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
        case LedgerEntryType.account.rawValue:
            let acc = try container.decode(LedgerKeyAccountXDR.self)
            self = .account(acc)
        case LedgerEntryType.trustline.rawValue:
            let trus = try container.decode(LedgerKeyTrustLineXDR.self)
            self = .trustline(trus)
        case LedgerEntryType.offer.rawValue:
            let offeru = try container.decode(LedgerKeyOfferXDR.self)
            self = .offer(offeru)
        case LedgerEntryType.data.rawValue:
            let datamu = try container.decode(LedgerKeyDataXDR.self)
            self = .data (datamu)
        case LedgerEntryType.claimableBalance.rawValue:
            let value = try container.decode(ClaimableBalanceIDXDR.self)
            self = .claimableBalance (value)
        case LedgerEntryType.liquidityPool.rawValue:
            let value = try container.decode(LiquidityPoolIDXDR.self)
            self = .liquidityPool (value)
        case LedgerEntryType.contractData.rawValue:
            let contractData = try container.decode(LedgerKeyContractDataXDR.self)
            self = .contractData (contractData)
        case LedgerEntryType.contractCode.rawValue:
            let contractCode = try container.decode(LedgerKeyContractCodeXDR.self)
            self = .contractCode (contractCode)
        case LedgerEntryType.configSetting.rawValue:
            let configSettingId = try container.decode(Int32.self)
            self = .configSetting (configSettingId)
        case LedgerEntryType.ttl.rawValue:
            let ttl = try container.decode(LedgerKeyTTLXDR.self)
            self = .ttl (ttl)
        default:
            let acc = try container.decode(LedgerKeyAccountXDR.self)
            self = .account(acc)
        }
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try LedgerKeyXDR(from: xdrDecoder)
    }
  
    public func type() -> Int32 {
        switch self {
        case .account: return LedgerEntryType.account.rawValue
        case .trustline: return LedgerEntryType.trustline.rawValue
        case .offer: return LedgerEntryType.offer.rawValue
        case .data: return LedgerEntryType.data.rawValue
        case .claimableBalance: return LedgerEntryType.claimableBalance.rawValue
        case .liquidityPool: return LedgerEntryType.liquidityPool.rawValue
        case .contractData: return LedgerEntryType.contractData.rawValue
        case .contractCode: return LedgerEntryType.contractCode.rawValue
        case .configSetting: return LedgerEntryType.configSetting.rawValue
        case .ttl: return LedgerEntryType.ttl.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .account (let acc):
            try container.encode(acc)
        case .trustline (let trust):
            try container.encode(trust)
        case .offer (let offeru):
            try container.encode(offeru)
        case .data (let datamu):
            try container.encode(datamu)
        case .claimableBalance (let value):
            try container.encode(value)
        case .liquidityPool (let value):
            try container.encode(value)
        case .contractData (let value):
            try container.encode(value)
        case .contractCode (let value):
            try container.encode(value)
        case .configSetting (let configSettingId):
            try container.encode(configSettingId)
        case .ttl (let value):
            try container.encode(value)
        }
    }
}

public struct LiquidityPoolIDXDR: XDRCodable {
    public let liquidityPoolID:WrappedData32
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        liquidityPoolID = try container.decode(WrappedData32.self)
    }
    
    public init(id: WrappedData32) {
        liquidityPoolID = id
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolID)
    }
    
    public var poolIDString: String {
        return liquidityPoolID.wrapped.hexEncodedString()
    }
}

public enum ContractDataDurability: Int32 {
    case temporary = 0
    case persistent = 1
}


public struct LedgerKeyContractDataXDR: XDRCodable {
    public var contract:SCAddressXDR
    public var key:SCValXDR
    public var durability:ContractDataDurability
    
    public init(contract: SCAddressXDR, key: SCValXDR, durability: ContractDataDurability) {
        self.contract = contract
        self.key = key
        self.durability = durability
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contract = try container.decode(SCAddressXDR.self)
        key = try container.decode(SCValXDR.self)
        let durabilityVal = try container.decode(Int32.self)
        switch durabilityVal {
            case ContractDataDurability.temporary.rawValue:
                durability = ContractDataDurability.temporary
            default:
                durability = ContractDataDurability.persistent
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contract)
        try container.encode(key)
        try container.encode(durability.rawValue)
    }
}

public struct LedgerKeyContractCodeXDR: XDRCodable {
    public var hash:WrappedData32
    
    public init(hash: WrappedData32) {
        self.hash = hash
    }
    
    public init(wasmId: String) {
        self.hash = wasmId.wrappedData32FromHex()
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        hash = try container.decode(WrappedData32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hash)
    }
}

public struct LedgerKeyTTLXDR: XDRCodable {
    public var keyHash:WrappedData32
    
    public init(keyHash: WrappedData32) {
        self.keyHash = keyHash
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        keyHash = try container.decode(WrappedData32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(keyHash)
    }
}

