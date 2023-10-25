//
//  LedgerExtryDataXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum LedgerEntryDataXDR: XDRCodable {
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

public struct ContractDataEntryXDR: XDRCodable {
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

public struct ContractCodeEntryXDR: XDRCodable {
    public var ext: ExtensionPoint
    public var hash: WrappedData32
    public var code: Data
    
    public init(ext: ExtensionPoint, hash: WrappedData32, code:Data) {
        self.ext = ext
        self.hash = hash
        self.code = code
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        hash = try container.decode(WrappedData32.self)
        code = try container.decode(Data.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(ext)
        try container.encode(hash)
        try container.encode(code)
    }
}

public struct ConfigSettingContractBandwidthV0XDR: XDRCodable {
    
    public var ledgerMaxTxsSizeBytes: UInt32
    public var txMaxSizeBytes: UInt32
    public var feeTxSize1KB: Int64

    public init(ledgerMaxTxsSizeBytes: UInt32, txMaxSizeBytes: UInt32, feeTxSize1KB: Int64) {
        self.ledgerMaxTxsSizeBytes = ledgerMaxTxsSizeBytes
        self.txMaxSizeBytes = txMaxSizeBytes
        self.feeTxSize1KB = feeTxSize1KB
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerMaxTxsSizeBytes = try container.decode(UInt32.self)
        txMaxSizeBytes = try container.decode(UInt32.self)
        feeTxSize1KB = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerMaxTxsSizeBytes)
        try container.encode(txMaxSizeBytes)
        try container.encode(feeTxSize1KB)
    }
}

public struct ConfigSettingContractComputeV0XDR: XDRCodable {

    public var ledgerMaxInstructions: Int64
    public var txMaxInstructions: Int64
    public var feeRatePerInstructionsIncrement: Int64
    public var txMemoryLimit: UInt32

    public init(ledgerMaxInstructions: Int64, txMaxInstructions: Int64, feeRatePerInstructionsIncrement: Int64, txMemoryLimit: UInt32) {
        self.ledgerMaxInstructions = ledgerMaxInstructions
        self.txMaxInstructions = txMaxInstructions
        self.feeRatePerInstructionsIncrement = feeRatePerInstructionsIncrement
        self.txMemoryLimit = txMemoryLimit
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerMaxInstructions = try container.decode(Int64.self)
        txMaxInstructions = try container.decode(Int64.self)
        feeRatePerInstructionsIncrement = try container.decode(Int64.self)
        txMemoryLimit = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerMaxInstructions)
        try container.encode(txMaxInstructions)
        try container.encode(feeRatePerInstructionsIncrement)
        try container.encode(txMemoryLimit)
    }
}

public struct ConfigSettingContractHistoricalDataV0XDR: XDRCodable {
    public var feeHistorical1KB: Int64

    public init(feeHistorical1KB: Int64) {
        self.feeHistorical1KB = feeHistorical1KB
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        feeHistorical1KB = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(feeHistorical1KB)
    }
}

public struct ConfigSettingContractLedgerCostV0XDR: XDRCodable {

    public var ledgerMaxReadLedgerEntries: UInt32
    public var ledgerMaxReadBytes: UInt32
    public var ledgerMaxWriteLedgerEntries: UInt32
    public var ledgerMaxWriteBytes: UInt32
    public var txMaxReadLedgerEntries: UInt32
    public var txMaxReadBytes: UInt32
    public var txMaxWriteLedgerEntries: UInt32
    public var txMaxWriteBytes: UInt32
    public var feeReadLedgerEntry: Int64
    public var feeWriteLedgerEntry: Int64
    public var feeRead1KB: Int64
    public var bucketListTargetSizeBytes: Int64
    public var writeFee1KBBucketListLow: Int64
    public var writeFee1KBBucketListHigh: Int64
    public var bucketListWriteFeeGrowthFactor: UInt32

    public init(ledgerMaxReadLedgerEntries: UInt32, ledgerMaxReadBytes: UInt32, ledgerMaxWriteLedgerEntries: UInt32, ledgerMaxWriteBytes: UInt32, txMaxReadLedgerEntries: UInt32, txMaxReadBytes: UInt32, txMaxWriteLedgerEntries: UInt32, txMaxWriteBytes: UInt32, feeReadLedgerEntry: Int64, feeWriteLedgerEntry: Int64, feeRead1KB: Int64, bucketListTargetSizeBytes: Int64, writeFee1KBBucketListLow: Int64, writeFee1KBBucketListHigh: Int64, bucketListWriteFeeGrowthFactor: UInt32) {
        self.ledgerMaxReadLedgerEntries = ledgerMaxReadLedgerEntries
        self.ledgerMaxReadBytes = ledgerMaxReadBytes
        self.ledgerMaxWriteLedgerEntries = ledgerMaxWriteLedgerEntries
        self.ledgerMaxWriteBytes = ledgerMaxWriteBytes
        self.txMaxReadLedgerEntries = txMaxReadLedgerEntries
        self.txMaxReadBytes = txMaxReadBytes
        self.txMaxWriteLedgerEntries = txMaxWriteLedgerEntries
        self.txMaxWriteBytes = txMaxWriteBytes
        self.feeReadLedgerEntry = feeReadLedgerEntry
        self.feeWriteLedgerEntry = feeWriteLedgerEntry
        self.feeRead1KB = feeRead1KB
        self.bucketListTargetSizeBytes = bucketListTargetSizeBytes
        self.writeFee1KBBucketListLow = writeFee1KBBucketListLow
        self.writeFee1KBBucketListHigh = writeFee1KBBucketListHigh
        self.bucketListWriteFeeGrowthFactor = bucketListWriteFeeGrowthFactor
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerMaxReadLedgerEntries = try container.decode(UInt32.self)
        ledgerMaxReadBytes = try container.decode(UInt32.self)
        ledgerMaxWriteLedgerEntries = try container.decode(UInt32.self)
        ledgerMaxWriteBytes = try container.decode(UInt32.self)
        txMaxReadLedgerEntries = try container.decode(UInt32.self)
        txMaxReadBytes = try container.decode(UInt32.self)
        txMaxWriteLedgerEntries = try container.decode(UInt32.self)
        txMaxWriteBytes = try container.decode(UInt32.self)
        feeReadLedgerEntry = try container.decode(Int64.self)
        feeWriteLedgerEntry = try container.decode(Int64.self)
        feeRead1KB = try container.decode(Int64.self)
        bucketListTargetSizeBytes = try container.decode(Int64.self)
        writeFee1KBBucketListLow = try container.decode(Int64.self)
        writeFee1KBBucketListHigh = try container.decode(Int64.self)
        bucketListWriteFeeGrowthFactor = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerMaxReadLedgerEntries)
        try container.encode(ledgerMaxReadBytes)
        try container.encode(ledgerMaxWriteLedgerEntries)
        try container.encode(ledgerMaxWriteBytes)
        try container.encode(txMaxReadLedgerEntries)
        try container.encode(txMaxReadBytes)
        try container.encode(txMaxWriteLedgerEntries)
        try container.encode(txMaxWriteBytes)
        try container.encode(feeReadLedgerEntry)
        try container.encode(feeWriteLedgerEntry)
        try container.encode(feeRead1KB)
        try container.encode(bucketListTargetSizeBytes)
        try container.encode(writeFee1KBBucketListLow)
        try container.encode(writeFee1KBBucketListHigh)
        try container.encode(bucketListWriteFeeGrowthFactor)
    }
}

public struct ConfigSettingContractEventsV0XDR: XDRCodable {
    public var txMaxContractEventsSizeBytes: UInt32
    public var feeContractEvents1KB: Int64

    public init(txMaxContractEventsSizeBytes: UInt32, feeContractEvents1KB: Int64) {
        self.txMaxContractEventsSizeBytes = txMaxContractEventsSizeBytes
        self.feeContractEvents1KB = feeContractEvents1KB
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        txMaxContractEventsSizeBytes = try container.decode(UInt32.self)
        feeContractEvents1KB = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(txMaxContractEventsSizeBytes)
        try container.encode(feeContractEvents1KB)
    }
}

public struct ContractCostParamEntryXDR: XDRCodable {
    public var ext: ExtensionPoint
    public var constTerm: Int64
    public var linearTerm: Int64

    public init(ext:ExtensionPoint, constTerm: Int64, linearTerm: Int64) {
        self.ext = ext
        self.constTerm = constTerm
        self.linearTerm = linearTerm
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        constTerm = try container.decode(Int64.self)
        linearTerm = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(constTerm)
        try container.encode(linearTerm)
    }
}

public struct ContractCostParamsXDR: XDRCodable {
    public var entries:[ContractCostParamEntryXDR]
    
    public init(entries: [ContractCostParamEntryXDR]) {
        self.entries = entries
    }
    
    public init(from decoder: Decoder) throws {
        entries = try decodeArray(type: ContractCostParamEntryXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(entries)
    }
}

public struct EvictionIteratorXDR: XDRCodable {

    public var bucketListLevel: UInt32
    public var isCurrBucket: Bool
    public var bucketFileOffset: UInt64

    public init(bucketListLevel: UInt32, isCurrBucket: Bool, bucketFileOffset: UInt64) {
        self.bucketListLevel = bucketListLevel
        self.isCurrBucket = isCurrBucket
        self.bucketFileOffset = bucketFileOffset
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        bucketListLevel = try container.decode(UInt32.self)
        isCurrBucket = try container.decode(Bool.self)
        bucketFileOffset = try container.decode(UInt64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(bucketListLevel)
        try container.encode(isCurrBucket)
        try container.encode(bucketFileOffset)
    }
}


public enum ConfigSettingEntryXDR: XDRCodable {
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
    case bucketListSizeWindow([UInt64])
    case evictionIterator(EvictionIteratorXDR)
    
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
            case ConfigSettingID.bucketListSizeWindow.rawValue:
                self = .bucketListSizeWindow(try decodeArray(type: UInt64.self, dec: decoder))
            case ConfigSettingID.evictionIterator.rawValue:
                self = .evictionIterator(try container.decode(EvictionIteratorXDR.self))
            default:
                self = .bucketListSizeWindow(try decodeArray(type: UInt64.self, dec: decoder))
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
            case .bucketListSizeWindow: return ConfigSettingID.bucketListSizeWindow.rawValue
            case .evictionIterator: return ConfigSettingID.evictionIterator.rawValue
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
        case .bucketListSizeWindow (let val):
            try container.encode(val)
        case .evictionIterator(let val):
            try container.encode(val)
        }
    }
}

public struct StateArchivalSettingsXDR: XDRCodable {

    public var maxEntryTTL: UInt32
    public var minTemporaryTTL: UInt32
    public var minPersistentTTL: UInt32
    public var persistentRentRateDenominator: Int64
    public var tempRentRateDenominator: Int64
    public var maxEntriesToArchive: UInt32
    public var bucketListSizeWindowSampleSize: UInt32
    public var evictionScanSize: UInt64
    public var startingEvictionScanLevel: UInt32

    public init(maxEntryTTL: UInt32, minTemporaryTTL: UInt32, minPersistentTTL: UInt32, persistentRentRateDenominator: Int64, tempRentRateDenominator: Int64, maxEntriesToArchive: UInt32, bucketListSizeWindowSampleSize: UInt32, evictionScanSize: UInt64, startingEvictionScanLevel: UInt32) {
        self.maxEntryTTL = maxEntryTTL
        self.minTemporaryTTL = minTemporaryTTL
        self.minPersistentTTL = minPersistentTTL
        self.persistentRentRateDenominator = persistentRentRateDenominator
        self.tempRentRateDenominator = tempRentRateDenominator
        self.maxEntriesToArchive = maxEntriesToArchive
        self.bucketListSizeWindowSampleSize = bucketListSizeWindowSampleSize
        self.evictionScanSize = evictionScanSize
        self.startingEvictionScanLevel = startingEvictionScanLevel
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        maxEntryTTL = try container.decode(UInt32.self)
        minTemporaryTTL = try container.decode(UInt32.self)
        minPersistentTTL = try container.decode(UInt32.self)
        persistentRentRateDenominator = try container.decode(Int64.self)
        tempRentRateDenominator = try container.decode(Int64.self)
        maxEntriesToArchive = try container.decode(UInt32.self)
        bucketListSizeWindowSampleSize = try container.decode(UInt32.self)
        evictionScanSize = try container.decode(UInt64.self)
        startingEvictionScanLevel = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(maxEntryTTL)
        try container.encode(minTemporaryTTL)
        try container.encode(minPersistentTTL)
        try container.encode(persistentRentRateDenominator)
        try container.encode(tempRentRateDenominator)
        try container.encode(maxEntriesToArchive)
        try container.encode(bucketListSizeWindowSampleSize)
        try container.encode(evictionScanSize)
        try container.encode(startingEvictionScanLevel)
    }
}

public struct ConfigSettingContractExecutionLanesV0XDR: XDRCodable {

    public var ledgerMaxTxCount: UInt32

    public init(ledgerMaxTxCount: UInt32) {
        self.ledgerMaxTxCount = ledgerMaxTxCount
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerMaxTxCount = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerMaxTxCount)
    }
}

public struct ConfigUpgradeSetKeyXDR: XDRCodable {

    public var contractID: WrappedData32
    public var contentHash: WrappedData32

    public init(contractID: WrappedData32, contentHash: WrappedData32) {
        self.contractID = contractID
        self.contentHash = contentHash
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contractID = try container.decode(WrappedData32.self)
        contentHash = try container.decode(WrappedData32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contractID)
        try container.encode(contentHash)
    }
}
