//
//  LedgerExtryDataXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerEntryDataXDR: XDRCodable, Sendable {
    case account (AccountEntryXDR)
    case trustline (TrustlineEntryXDR)
    case offer (OfferEntryXDR)
    case data (DataEntryXDR)
    case claimableBalance (ClaimableBalanceEntryXDR)
    case liquidityPool (LiquidityPoolEntryXDR)
    case contractData (ContractDataEntryXDR)
    case contractCode (ContractCodeEntryXDR)
    case configSetting (ConfigSettingEntryXDR)
    case ttl (TTLEntryXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case LedgerEntryType.account.rawValue:
                self = .account(try container.decode(AccountEntryXDR.self))
            case LedgerEntryType.trustline.rawValue:
                self = .trustline(try container.decode(TrustlineEntryXDR.self))
            case LedgerEntryType.offer.rawValue:
                self = .offer(try container.decode(OfferEntryXDR.self))
            case LedgerEntryType.data.rawValue:
                self = .data(try container.decode(DataEntryXDR.self))
            case LedgerEntryType.claimableBalance.rawValue:
                self = .claimableBalance(try container.decode(ClaimableBalanceEntryXDR.self))
            case LedgerEntryType.liquidityPool.rawValue:
                self = .liquidityPool(try container.decode(LiquidityPoolEntryXDR.self))
            case LedgerEntryType.contractData.rawValue:
                self = .contractData(try container.decode(ContractDataEntryXDR.self))
            case LedgerEntryType.contractCode.rawValue:
                self = .contractCode(try container.decode(ContractCodeEntryXDR.self))
            case LedgerEntryType.configSetting.rawValue:
                self = .configSetting(try container.decode(ConfigSettingEntryXDR.self))
            case LedgerEntryType.ttl.rawValue:
                self = .ttl(try container.decode(TTLEntryXDR.self))
            default:
                self = .account(try container.decode(AccountEntryXDR.self))
        }
        
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
        case .account (let op):
            try container.encode(op)
        case .trustline (let op):
            try container.encode(op)
        case .offer (let op):
            try container.encode(op)
        case .data (let op):
            try container.encode(op)
        case .claimableBalance (let op):
            try container.encode(op)
        case .liquidityPool (let op):
            try container.encode(op)
        case .contractData (let contractData):
            try container.encode(contractData)
        case .contractCode (let contractCode):
            try container.encode(contractCode)
        case .configSetting (let configSetting):
            try container.encode(configSetting)
        case .ttl(let value):
            try container.encode(value)
        }
    }
    
    public init(fromBase64 xdr:String) throws {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: xdr))
        self = try LedgerEntryDataXDR(from: xdrDecoder)
    }
    
    public var isBool:Bool {
        return type() == SCValType.bool.rawValue
    }
    
    public var account:AccountEntryXDR? {
        switch self {
        case .account(let val):
            return val
        default:
            return nil
        }
    }
    
    public var trustline:TrustlineEntryXDR? {
        switch self {
        case .trustline(let val):
            return val
        default:
            return nil
        }
    }
    
    public var offer:OfferEntryXDR? {
        switch self {
        case .offer(let val):
            return val
        default:
            return nil
        }
    }
    
    public var data:DataEntryXDR? {
        switch self {
        case .data(let val):
            return val
        default:
            return nil
        }
    }
    
    public var claimableBalance:ClaimableBalanceEntryXDR? {
        switch self {
        case .claimableBalance(let val):
            return val
        default:
            return nil
        }
    }
    
    public var liquidityPool:LiquidityPoolEntryXDR? {
        switch self {
        case .liquidityPool(let val):
            return val
        default:
            return nil
        }
    }
    
    public var contractData:ContractDataEntryXDR? {
        switch self {
        case .contractData(let val):
            return val
        default:
            return nil
        }
    }
    
    public var contractCode:ContractCodeEntryXDR? {
        switch self {
        case .contractCode(let val):
            return val
        default:
            return nil
        }
    }
    
    public var configSetting:ConfigSettingEntryXDR? {
        switch self {
        case .configSetting(let val):
            return val
        default:
            return nil
        }
    }
    
    public var ttl:TTLEntryXDR? {
        switch self {
        case .ttl(let val):
            return val
        default:
            return nil
        }
    }
}

public struct ContractDataEntryXDR: XDRCodable, Sendable {
    public let ext: ExtensionPoint
    public let contract: SCAddressXDR
    public let key: SCValXDR
    public let durability: ContractDataDurability
    public let val: SCValXDR
    
    public init(ext: ExtensionPoint,contract: SCAddressXDR, key:SCValXDR, durability:ContractDataDurability, val:SCValXDR) {
        self.ext = ext
        self.contract = contract
        self.key = key
        self.durability = durability
        self.val = val
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        contract = try container.decode(SCAddressXDR.self)
        key = try container.decode(SCValXDR.self)
        let durabilityVal = try container.decode(Int32.self)
        switch durabilityVal {
            case ContractDataDurability.temporary.rawValue:
                durability = ContractDataDurability.temporary
            default:
                durability = ContractDataDurability.persistent
        }
        
        val = try container.decode(SCValXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(contract)
        try container.encode(key)
        try container.encode(durability.rawValue)
        try container.encode(val)
    }
}

public enum ConfigSettingEntryXDR: XDRCodable, Sendable {
    case contractMaxSizeBytes(Int32)
    case contractCompute(ConfigSettingContractComputeV0XDR)
    case contractLedgerCost(ConfigSettingContractLedgerCostV0XDR)
    case contractHistoricalData(ConfigSettingContractHistoricalDataV0XDR)
    case contractEvents(ConfigSettingContractEventsV0XDR)
    case contractBandwidth(ConfigSettingContractBandwidthV0XDR)
    case contractCostParamsCpuInsns(ContractCostParamsXDR)
    case contractCostParamsMemBytes(ContractCostParamsXDR)
    case contractDataKeySizeBytes(UInt32)
    case contractDataEntrySizeBytes(UInt32)
    case stateArchivalSettings(StateArchivalSettingsXDR)
    case contractExecutionLanes(ConfigSettingContractExecutionLanesV0XDR)
    case liveSorobanStateSizeWindow([UInt64])
    case evictionIterator(EvictionIteratorXDR)
    case contractParallelCompute(ConfigSettingContractParallelComputeV0)
    case contractLedgerCostExt(ConfigSettingContractLedgerCostExtV0)
    case contractSCPTiming(ConfigSettingSCPTiming)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case ConfigSettingID.contractMaxSizeBytes.rawValue:
                self = .contractMaxSizeBytes(try container.decode(Int32.self))
            case ConfigSettingID.contractComputeV0.rawValue:
                self = .contractCompute(try container.decode(ConfigSettingContractComputeV0XDR.self))
            case ConfigSettingID.contractLedgerCostV0.rawValue:
                self = .contractLedgerCost(try container.decode(ConfigSettingContractLedgerCostV0XDR.self))
            case ConfigSettingID.contractHistoricalDataV0.rawValue:
                self = .contractHistoricalData(try container.decode(ConfigSettingContractHistoricalDataV0XDR.self))
            case ConfigSettingID.contractEventsV0.rawValue:
                self = .contractEvents(try container.decode(ConfigSettingContractEventsV0XDR.self))
            case ConfigSettingID.contractBandwidthV0.rawValue:
                self = .contractBandwidth(try container.decode(ConfigSettingContractBandwidthV0XDR.self))
            case ConfigSettingID.contractCostParamsCpuInstructions.rawValue:
                self = .contractCostParamsCpuInsns(try container.decode(ContractCostParamsXDR.self))
            case ConfigSettingID.contractCostParamsMemoryBytes.rawValue:
                self = .contractCostParamsMemBytes(try container.decode(ContractCostParamsXDR.self))
            case ConfigSettingID.contractDataKeySizeBytes.rawValue:
                self = .contractDataKeySizeBytes(try container.decode(UInt32.self))
            case ConfigSettingID.contractDataEntrySizeBytes.rawValue:
                self = .contractDataEntrySizeBytes(try container.decode(UInt32.self))
            case ConfigSettingID.stateArchival.rawValue:
                self = .stateArchivalSettings(try container.decode(StateArchivalSettingsXDR.self))
            case ConfigSettingID.contractExecutionLanes.rawValue:
                self = .contractExecutionLanes(try container.decode(ConfigSettingContractExecutionLanesV0XDR.self))
            case ConfigSettingID.liveSorobanStateSizeWindow.rawValue:
                self = .liveSorobanStateSizeWindow(try decodeArray(type: UInt64.self, dec: decoder))
            case ConfigSettingID.evictionIterator.rawValue:
                self = .evictionIterator(try container.decode(EvictionIteratorXDR.self))
            case ConfigSettingID.contractParallelComputeV0.rawValue:
                self = .contractParallelCompute(try container.decode(ConfigSettingContractParallelComputeV0.self))
            case ConfigSettingID.contractLedgerCostExtV0.rawValue:
                self = .contractLedgerCostExt(try container.decode(ConfigSettingContractLedgerCostExtV0.self))
            case ConfigSettingID.scpTiming.rawValue:
                self = .contractSCPTiming(try container.decode(ConfigSettingSCPTiming.self))
            default:
                self = .liveSorobanStateSizeWindow(try decodeArray(type: UInt64.self, dec: decoder))
        }
        
    }
    
    public func type() -> Int32 {
        switch self {
            case .contractMaxSizeBytes: return ConfigSettingID.contractMaxSizeBytes.rawValue
            case .contractCompute: return ConfigSettingID.contractComputeV0.rawValue
            case .contractLedgerCost: return ConfigSettingID.contractLedgerCostV0.rawValue
            case .contractHistoricalData: return ConfigSettingID.contractHistoricalDataV0.rawValue
            case .contractEvents: return ConfigSettingID.contractEventsV0.rawValue
            case .contractBandwidth: return ConfigSettingID.contractBandwidthV0.rawValue
            case .contractCostParamsCpuInsns: return ConfigSettingID.contractCostParamsCpuInstructions.rawValue
            case .contractCostParamsMemBytes: return ConfigSettingID.contractCostParamsMemoryBytes.rawValue
            case .contractDataKeySizeBytes: return ConfigSettingID.contractDataKeySizeBytes.rawValue
            case .contractDataEntrySizeBytes: return ConfigSettingID.contractDataEntrySizeBytes.rawValue
            case .stateArchivalSettings: return ConfigSettingID.stateArchival.rawValue
            case .contractExecutionLanes: return ConfigSettingID.contractExecutionLanes.rawValue
            case .liveSorobanStateSizeWindow: return ConfigSettingID.liveSorobanStateSizeWindow.rawValue
            case .evictionIterator: return ConfigSettingID.evictionIterator.rawValue
            case .contractParallelCompute: return ConfigSettingID.contractParallelComputeV0.rawValue
            case .contractLedgerCostExt: return ConfigSettingID.contractLedgerCostExtV0.rawValue
            case .contractSCPTiming: return ConfigSettingID.scpTiming.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .contractMaxSizeBytes (let val):
            try container.encode(val)
        case .contractCompute (let val):
            try container.encode(val)
        case .contractLedgerCost (let val):
            try container.encode(val)
        case .contractHistoricalData (let val):
            try container.encode(val)
        case .contractEvents (let val):
            try container.encode(val)
        case .contractBandwidth (let val):
            try container.encode(val)
        case .contractCostParamsCpuInsns (let val):
            try container.encode(val)
        case .contractCostParamsMemBytes (let val):
            try container.encode(val)
        case .contractDataKeySizeBytes (let val):
            try container.encode(val)
        case .contractDataEntrySizeBytes(let val):
            try container.encode(val)
        case .stateArchivalSettings (let val):
            try container.encode(val)
        case .contractExecutionLanes (let val):
            try container.encode(val)
        case .liveSorobanStateSizeWindow (let val):
            try container.encode(val)
        case .evictionIterator(let val):
            try container.encode(val)
        case .contractParallelCompute(let val):
            try container.encode(val)
        case .contractLedgerCostExt(let val):
            try container.encode(val)
        case .contractSCPTiming(let val):
            try container.encode(val)
        }
    }
}
