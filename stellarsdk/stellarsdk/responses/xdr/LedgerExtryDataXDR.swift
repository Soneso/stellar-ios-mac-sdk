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
        }
    }
}

public struct ContractDataEntryXDR: XDRCodable {
    public let contractId: WrappedData32
    public let key: SCValXDR
    public let val: SCValXDR
    
    public init(contractId: WrappedData32,key:SCValXDR, val:SCValXDR) {
        self.contractId = contractId
        self.key = key
        self.val = val
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contractId = try container.decode(WrappedData32.self)
        key = try container.decode(SCValXDR.self)
        val = try container.decode(SCValXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contractId)
        try container.encode(key)
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
    
    public var ledgerMaxPropagateSizeBytes: UInt32
    public var txMaxSizeBytes: UInt32
    public var feePropagateData1KB: Int64

    public init(ledgerMaxPropagateSizeBytes: UInt32, txMaxSizeBytes: UInt32, feePropagateData1KB: Int64) {
        self.ledgerMaxPropagateSizeBytes = ledgerMaxPropagateSizeBytes
        self.txMaxSizeBytes = txMaxSizeBytes
        self.feePropagateData1KB = feePropagateData1KB
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerMaxPropagateSizeBytes = try container.decode(UInt32.self)
        txMaxSizeBytes = try container.decode(UInt32.self)
        feePropagateData1KB = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerMaxPropagateSizeBytes)
        try container.encode(txMaxSizeBytes)
        try container.encode(feePropagateData1KB)
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
    public var feeWrite1KB: Int64
    public var bucketListSizeBytes: Int64
    public var bucketListFeeRateLow: Int64
    public var bucketListFeeRateHigh: Int64
    public var bucketListGrowthFactor: UInt32

    public init(ledgerMaxReadLedgerEntries: UInt32, ledgerMaxReadBytes: UInt32, ledgerMaxWriteLedgerEntries: UInt32, ledgerMaxWriteBytes: UInt32, txMaxReadLedgerEntries: UInt32, txMaxReadBytes: UInt32, txMaxWriteLedgerEntries: UInt32, txMaxWriteBytes: UInt32, feeReadLedgerEntry: Int64, feeWriteLedgerEntry: Int64, feeRead1KB: Int64, feeWrite1KB: Int64, bucketListSizeBytes: Int64, bucketListFeeRateLow: Int64, bucketListFeeRateHigh: Int64, bucketListGrowthFactor: UInt32) {
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
        self.feeWrite1KB = feeWrite1KB
        self.bucketListSizeBytes = bucketListSizeBytes
        self.bucketListFeeRateLow = bucketListFeeRateLow
        self.bucketListFeeRateHigh = bucketListFeeRateHigh
        self.bucketListGrowthFactor = bucketListGrowthFactor
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
        feeWrite1KB = try container.decode(Int64.self)
        bucketListSizeBytes = try container.decode(Int64.self)
        bucketListFeeRateLow = try container.decode(Int64.self)
        bucketListFeeRateHigh = try container.decode(Int64.self)
        bucketListGrowthFactor = try container.decode(UInt32.self)
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
        try container.encode(feeWrite1KB)
        try container.encode(bucketListSizeBytes)
        try container.encode(bucketListFeeRateLow)
        try container.encode(bucketListFeeRateHigh)
        try container.encode(bucketListGrowthFactor)
    }
}

public struct ConfigSettingContractMetaDataV0XDR: XDRCodable {
    public var txMaxExtendedMetaDataSizeBytes: UInt32
    public var feeExtendedMetaData1KB: Int64

    public init(txMaxExtendedMetaDataSizeBytes: UInt32, feeExtendedMetaData1KB: Int64) {
        self.txMaxExtendedMetaDataSizeBytes = txMaxExtendedMetaDataSizeBytes
        self.feeExtendedMetaData1KB = feeExtendedMetaData1KB
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        txMaxExtendedMetaDataSizeBytes = try container.decode(UInt32.self)
        feeExtendedMetaData1KB = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(txMaxExtendedMetaDataSizeBytes)
        try container.encode(feeExtendedMetaData1KB)
    }
}

public struct ContractCostParamEntryXDR: XDRCodable {
    public var constTerm: Int64
    public var linearTerm: Int64
    public var ext: ExtensionPoint

    public init(constTerm: Int64, linearTerm: Int64, ext:ExtensionPoint) {
        self.constTerm = constTerm
        self.linearTerm = linearTerm
        self.ext = ext
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        constTerm = try container.decode(Int64.self)
        linearTerm = try container.decode(Int64.self)
        ext = try container.decode(ExtensionPoint.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(constTerm)
        try container.encode(linearTerm)
        try container.encode(ext)
    }
}

public struct ContractCostParamsXDR: XDRCodable {
    public var entries:[ContractCostParamEntryXDR]
    
    public init(entries: [ContractCostParamEntryXDR]) {
        self.entries = entries
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        entries = try decodeArray(type: ContractCostParamEntryXDR.self, dec: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(entries)
    }
}

public struct ConfigSettingEntryXDR: XDRCodable {
    
    public var configSettingID: Int32
    public var contractMaxSizeBytes : UInt32
    public var contractCompute: ConfigSettingContractComputeV0XDR
    public var contractHistoricalData : ConfigSettingContractHistoricalDataV0XDR
    public var contractMetaData : ConfigSettingContractMetaDataV0XDR
    public var contractBandwidth : ConfigSettingContractBandwidthV0XDR
    public var contractCostParamsCpuInsns : ContractCostParamsXDR
    public var contractCostParamsMemBytes : ContractCostParamsXDR
    public var contractDataKeySizeBytes : UInt32
    public var contractDataEntrySizeBytes : UInt32
    
    public init(configSettingID: Int32, contractMaxSizeBytes: UInt32, contractCompute: ConfigSettingContractComputeV0XDR, contractHistoricalData: ConfigSettingContractHistoricalDataV0XDR, contractMetaData: ConfigSettingContractMetaDataV0XDR, contractBandwidth: ConfigSettingContractBandwidthV0XDR, contractCostParamsCpuInsns: ContractCostParamsXDR, contractCostParamsMemBytes: ContractCostParamsXDR, contractDataKeySizeBytes: UInt32, contractDataEntrySizeBytes: UInt32) {
        self.configSettingID = configSettingID
        self.contractMaxSizeBytes = contractMaxSizeBytes
        self.contractCompute = contractCompute
        self.contractHistoricalData = contractHistoricalData
        self.contractMetaData = contractMetaData
        self.contractBandwidth = contractBandwidth
        self.contractCostParamsCpuInsns = contractCostParamsCpuInsns
        self.contractCostParamsMemBytes = contractCostParamsMemBytes
        self.contractDataKeySizeBytes = contractDataKeySizeBytes
        self.contractDataEntrySizeBytes = contractDataEntrySizeBytes
    }

    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        configSettingID = try container.decode(Int32.self)
        contractMaxSizeBytes = try container.decode(UInt32.self)
        contractCompute = try container.decode(ConfigSettingContractComputeV0XDR.self)
        contractHistoricalData = try container.decode(ConfigSettingContractHistoricalDataV0XDR.self)
        contractMetaData = try container.decode(ConfigSettingContractMetaDataV0XDR.self)
        contractBandwidth = try container.decode(ConfigSettingContractBandwidthV0XDR.self)
        contractCostParamsCpuInsns = try container.decode(ContractCostParamsXDR.self)
        contractCostParamsMemBytes = try container.decode(ContractCostParamsXDR.self)
        contractDataKeySizeBytes = try container.decode(UInt32.self)
        contractDataEntrySizeBytes = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(configSettingID)
        try container.encode(contractMaxSizeBytes)
        try container.encode(contractCompute)
        try container.encode(contractHistoricalData)
        try container.encode(contractMetaData)
        try container.encode(contractBandwidth)
        try container.encode(contractCostParamsCpuInsns)
        try container.encode(contractCostParamsMemBytes)
        try container.encode(contractDataEntrySizeBytes)
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
