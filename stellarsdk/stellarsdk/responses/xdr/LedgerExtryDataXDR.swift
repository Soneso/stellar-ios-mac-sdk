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
    public var ext: ContractCodeEntryExt
    public var hash: WrappedData32
    public var code: Data
    
    public init(ext: ContractCodeEntryExt, hash: WrappedData32, code:Data) {
        self.ext = ext
        self.hash = hash
        self.code = code
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ContractCodeEntryExt.self)
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

public struct ContractCodeCostInputsXDR: XDRCodable {
    public var ext:ExtensionPoint
    public var nInstructions: UInt32
    public var nFunctions: UInt32
    public var nGlobals: UInt32
    public var nTableEntries: UInt32
    public var nTypes: UInt32
    public var nDataSegments: UInt32
    public var nElemSegments: UInt32
    public var nImports: UInt32
    public var nExports: UInt32
    public var nDataSegmentBytes: UInt32
    
    public init(ext: ExtensionPoint, nInstructions: UInt32, nFunctions: UInt32, nGlobals: UInt32, nTableEntries: UInt32, nTypes: UInt32, nDataSegments: UInt32, nElemSegments: UInt32, nImports: UInt32, nExports: UInt32, nDataSegmentBytes: UInt32) {
        self.ext = ext
        self.nInstructions = nInstructions
        self.nFunctions = nFunctions
        self.nGlobals = nGlobals
        self.nTableEntries = nTableEntries
        self.nTypes = nTypes
        self.nDataSegments = nDataSegments
        self.nElemSegments = nElemSegments
        self.nImports = nImports
        self.nExports = nExports
        self.nDataSegmentBytes = nDataSegmentBytes
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        nInstructions = try container.decode(UInt32.self)
        nFunctions = try container.decode(UInt32.self)
        nGlobals = try container.decode(UInt32.self)
        nTableEntries = try container.decode(UInt32.self)
        nTypes = try container.decode(UInt32.self)
        nDataSegments = try container.decode(UInt32.self)
        nElemSegments = try container.decode(UInt32.self)
        nImports = try container.decode(UInt32.self)
        nExports = try container.decode(UInt32.self)
        nDataSegmentBytes = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(nInstructions)
        try container.encode(nFunctions)
        try container.encode(nGlobals)
        try container.encode(nTypes)
        try container.encode(nDataSegments)
        try container.encode(nElemSegments)
        try container.encode(nImports)
        try container.encode(nExports)
        try container.encode(nInstructions)
        try container.encode(nDataSegmentBytes)
        
    }
}

public struct ContractCodeEntryExtV1: XDRCodable {
    public var ext:ExtensionPoint
    public var costInputs: ContractCodeCostInputsXDR
    
    public init(ext: ExtensionPoint, costInputs: ContractCodeCostInputsXDR) {
        self.ext = ext
        self.costInputs = costInputs
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ExtensionPoint.self)
        costInputs = try container.decode(ContractCodeCostInputsXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ext)
        try container.encode(costInputs)
    }
}

public enum ContractCodeEntryExt: XDRCodable {
    case void
    case v1 (ContractCodeEntryExtV1)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        case 1:
            self = .v1(try ContractCodeEntryExtV1(from: decoder))
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        case .v1: return 1
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        case .v1(let extV1):
            try container.encode(extV1)
        }
    }
}

// Bandwidth related data settings for contracts.
// We consider bandwidth to only be consumed by the transaction envelopes, hence
// this concerns only transaction sizes.
public struct ConfigSettingContractBandwidthV0XDR: XDRCodable {
    
    // Maximum sum of all transaction sizes in the ledger in bytes
    public var ledgerMaxTxsSizeBytes: UInt32
    
    // Maximum size in bytes for a transaction
    public var txMaxSizeBytes: UInt32
    
    // Fee for 1 KB of transaction size
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

// "Compute" settings for contracts (instructions and memory).
public struct ConfigSettingContractComputeV0XDR: XDRCodable {

    // Maximum instructions per ledger
    public var ledgerMaxInstructions: Int64
    
    // Maximum instructions per transaction
    public var txMaxInstructions: Int64
    
    // Cost of 10000 instructions
    public var feeRatePerInstructionsIncrement: Int64
    
    // Memory limit per transaction. Unlike instructions, there is no fee for memory, just the limit.
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

// Historical data (pushed to core archives) settings for contracts.
public struct ConfigSettingContractHistoricalDataV0XDR: XDRCodable {
    
    // Fee for storing 1KB in archives
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

// Ledger access settings for contracts.
public struct ConfigSettingContractLedgerCostV0XDR: XDRCodable {

    // Maximum number of disk entry read operations per ledger
    public var ledgerMaxDiskReadEntries: UInt32
    
    // Maximum number of bytes of disk reads that can be performed per ledger
    public var ledgerMaxDiskReadBytes: UInt32
    
    // Maximum number of ledger entry write operations per ledger
    public var ledgerMaxWriteLedgerEntries: UInt32
    
    // Maximum number of bytes that can be written per ledger
    public var ledgerMaxWriteBytes: UInt32
    
    // Maximum number of disk entry read operations per transaction
    public var txMaxDiskReadEntries: UInt32
    
    // Maximum number of bytes of disk reads that can be performed per transaction
    public var txMaxDiskReadBytes: UInt32
    
    // Maximum number of ledger entry write operations per transaction
    public var txMaxWriteLedgerEntries: UInt32
    
    // Maximum number of bytes that can be written per transaction
    public var txMaxWriteBytes: UInt32
    
    // Fee per disk ledger entry read
    public var feeDiskReadLedgerEntry: Int64
    
    // Fee per ledger entry write
    public var feeWriteLedgerEntry: Int64
    
    // Fee for reading 1KB disk
    public var feeDiskRead1KB: Int64
    
    // The following parameters determine the write fee per 1KB.
    
    // Rent fee grows linearly until soroban state reaches this size
    public var sorobanStateTargetSizeBytes: Int64
    
    // Fee per 1KB rent when the soroban state is empty
    public var rentFee1KBSorobanStateSizeLow: Int64
    
    // Fee per 1KB rent when the soroban state has reached `sorobanStateTargetSizeBytes`
    public var rentFee1KBSorobanStateSizeHigh: Int64
    
    // Rent fee multiplier for any additional data past the first `sorobanStateTargetSizeBytes`
    public var sorobanStateRentFeeGrowthFactor: UInt32

    public init(ledgerMaxDiskReadEntries: UInt32, ledgerMaxDiskReadBytes: UInt32, ledgerMaxWriteLedgerEntries: UInt32, ledgerMaxWriteBytes: UInt32, txMaxDiskReadEntries: UInt32, txMaxDiskReadBytes: UInt32, txMaxWriteLedgerEntries: UInt32, txMaxWriteBytes: UInt32, feeDiskReadLedgerEntry: Int64, feeWriteLedgerEntry: Int64, feeDiskRead1KB: Int64, sorobanStateTargetSizeBytes: Int64, rentFee1KBSorobanStateSizeLow: Int64, rentFee1KBSorobanStateSizeHigh: Int64, sorobanStateRentFeeGrowthFactor: UInt32) {
        self.ledgerMaxDiskReadEntries = ledgerMaxDiskReadEntries
        self.ledgerMaxDiskReadBytes = ledgerMaxDiskReadBytes
        self.ledgerMaxWriteLedgerEntries = ledgerMaxWriteLedgerEntries
        self.ledgerMaxWriteBytes = ledgerMaxWriteBytes
        self.txMaxDiskReadEntries = txMaxDiskReadEntries
        self.txMaxDiskReadBytes = txMaxDiskReadBytes
        self.txMaxWriteLedgerEntries = txMaxWriteLedgerEntries
        self.txMaxWriteBytes = txMaxWriteBytes
        self.feeDiskReadLedgerEntry = feeDiskReadLedgerEntry
        self.feeWriteLedgerEntry = feeWriteLedgerEntry
        self.feeDiskRead1KB = feeDiskRead1KB
        self.sorobanStateTargetSizeBytes = sorobanStateTargetSizeBytes
        self.rentFee1KBSorobanStateSizeLow = rentFee1KBSorobanStateSizeLow
        self.rentFee1KBSorobanStateSizeHigh = rentFee1KBSorobanStateSizeHigh
        self.sorobanStateRentFeeGrowthFactor = sorobanStateRentFeeGrowthFactor
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerMaxDiskReadEntries = try container.decode(UInt32.self)
        ledgerMaxDiskReadBytes = try container.decode(UInt32.self)
        ledgerMaxWriteLedgerEntries = try container.decode(UInt32.self)
        ledgerMaxWriteBytes = try container.decode(UInt32.self)
        txMaxDiskReadEntries = try container.decode(UInt32.self)
        txMaxDiskReadBytes = try container.decode(UInt32.self)
        txMaxWriteLedgerEntries = try container.decode(UInt32.self)
        txMaxWriteBytes = try container.decode(UInt32.self)
        feeDiskReadLedgerEntry = try container.decode(Int64.self)
        feeWriteLedgerEntry = try container.decode(Int64.self)
        feeDiskRead1KB = try container.decode(Int64.self)
        sorobanStateTargetSizeBytes = try container.decode(Int64.self)
        rentFee1KBSorobanStateSizeLow = try container.decode(Int64.self)
        rentFee1KBSorobanStateSizeHigh = try container.decode(Int64.self)
        sorobanStateRentFeeGrowthFactor = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerMaxDiskReadEntries)
        try container.encode(ledgerMaxDiskReadBytes)
        try container.encode(ledgerMaxWriteLedgerEntries)
        try container.encode(ledgerMaxWriteBytes)
        try container.encode(txMaxDiskReadEntries)
        try container.encode(txMaxDiskReadBytes)
        try container.encode(txMaxWriteLedgerEntries)
        try container.encode(txMaxWriteBytes)
        try container.encode(feeDiskReadLedgerEntry)
        try container.encode(feeWriteLedgerEntry)
        try container.encode(feeDiskRead1KB)
        try container.encode(sorobanStateTargetSizeBytes)
        try container.encode(rentFee1KBSorobanStateSizeLow)
        try container.encode(rentFee1KBSorobanStateSizeHigh)
        try container.encode(sorobanStateRentFeeGrowthFactor)
    }
}

// Contract event-related settings.
public struct ConfigSettingContractEventsV0XDR: XDRCodable {
    
    // Maximum size of events that a contract call can emit.
    public var txMaxContractEventsSizeBytes: UInt32
    
    // Fee for generating 1KB of contract events.
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

// Settings for running the contract transactions in parallel.
public struct ConfigSettingContractParallelComputeV0: XDRCodable {

    // Maximum number of clusters with dependent transactions allowed in a
    // stage of parallel tx set component.
    // This effectively sets the lower bound on the number of physical threads
    // necessary to effectively apply transaction sets in parallel.
    public var ledgerMaxDependentTxClusters: UInt32

    public init(ledgerMaxDependentTxClusters: UInt32) {
        self.ledgerMaxDependentTxClusters = ledgerMaxDependentTxClusters
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerMaxDependentTxClusters = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerMaxDependentTxClusters)
    }
}

// Ledger access settings for contracts.
public struct ConfigSettingContractLedgerCostExtV0: XDRCodable {

    // Maximum number of RO+RW entries in the transaction footprint.
    public var txMaxFootprintEntries: UInt32
    
    // Fee per 1 KB of data written to the ledger.
    // Unlike the rent fee, this is a flat fee that is charged for any ledger
    // write, independent of the type of the entry being written.
    public var feeWrite1KB: Int64

    public init(txMaxFootprintEntries: UInt32, feeWrite1KB: Int64) {
        self.txMaxFootprintEntries = txMaxFootprintEntries
        self.feeWrite1KB = feeWrite1KB
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        txMaxFootprintEntries = try container.decode(UInt32.self)
        feeWrite1KB = try container.decode(Int64.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(txMaxFootprintEntries)
        try container.encode(feeWrite1KB)
    }
}

public struct ConfigSettingSCPTiming: XDRCodable {

    public var ledgerTargetCloseTimeMilliseconds: UInt32
    public var nominationTimeoutInitialMilliseconds: UInt32
    public var nominationTimeoutIncrementMilliseconds: UInt32
    public var ballotTimeoutInitialMilliseconds: UInt32
    public var ballotTimeoutIncrementMilliseconds: UInt32

    public init(ledgerTargetCloseTimeMilliseconds: UInt32,
                nominationTimeoutInitialMilliseconds: UInt32,
                nominationTimeoutIncrementMilliseconds: UInt32,
                ballotTimeoutInitialMilliseconds: UInt32,
                ballotTimeoutIncrementMilliseconds: UInt32) {
        self.ledgerTargetCloseTimeMilliseconds = ledgerTargetCloseTimeMilliseconds
        self.nominationTimeoutInitialMilliseconds = nominationTimeoutInitialMilliseconds
        self.nominationTimeoutIncrementMilliseconds = nominationTimeoutIncrementMilliseconds
        self.ballotTimeoutInitialMilliseconds = ballotTimeoutInitialMilliseconds
        self.ballotTimeoutIncrementMilliseconds = ballotTimeoutIncrementMilliseconds
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ledgerTargetCloseTimeMilliseconds = try container.decode(UInt32.self)
        nominationTimeoutInitialMilliseconds = try container.decode(UInt32.self)
        nominationTimeoutIncrementMilliseconds = try container.decode(UInt32.self)
        ballotTimeoutInitialMilliseconds = try container.decode(UInt32.self)
        ballotTimeoutIncrementMilliseconds = try container.decode(UInt32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ledgerTargetCloseTimeMilliseconds)
        try container.encode(nominationTimeoutInitialMilliseconds)
        try container.encode(nominationTimeoutIncrementMilliseconds)
        try container.encode(ballotTimeoutInitialMilliseconds)
        try container.encode(ballotTimeoutIncrementMilliseconds)
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

public struct StateArchivalSettingsXDR: XDRCodable {

    public var maxEntryTTL: UInt32
    public var minTemporaryTTL: UInt32
    public var minPersistentTTL: UInt32
    
    // rent_fee = wfee_rate_average / rent_rate_denominator_for_type
    public var persistentRentRateDenominator: Int64
    public var tempRentRateDenominator: Int64
    
    // max number of entries that emit archival meta in a single ledger
    public var maxEntriesToArchive: UInt32
    
    // Number of snapshots to use when calculating average live Soroban State size
    public var liveSorobanStateSizeWindowSampleSize: UInt32
    
    // How often to sample the live Soroban State size for the average, in ledgers
    public var liveSorobanStateSizeWindowSamplePeriod: UInt32
    
    // Maximum number of bytes that we scan for eviction per ledger
    public var evictionScanSize: UInt32
    
    // Lowest BucketList level to be scanned to evict entries
    public var startingEvictionScanLevel: UInt32

    public init(maxEntryTTL: UInt32, minTemporaryTTL: UInt32, minPersistentTTL: UInt32, persistentRentRateDenominator: Int64, tempRentRateDenominator: Int64, maxEntriesToArchive: UInt32, liveSorobanStateSizeWindowSampleSize: UInt32, liveSorobanStateSizeWindowSamplePeriod: UInt32, evictionScanSize: UInt32, startingEvictionScanLevel: UInt32) {
        self.maxEntryTTL = maxEntryTTL
        self.minTemporaryTTL = minTemporaryTTL
        self.minPersistentTTL = minPersistentTTL
        self.persistentRentRateDenominator = persistentRentRateDenominator
        self.tempRentRateDenominator = tempRentRateDenominator
        self.maxEntriesToArchive = maxEntriesToArchive
        self.liveSorobanStateSizeWindowSampleSize = liveSorobanStateSizeWindowSampleSize
        self.liveSorobanStateSizeWindowSamplePeriod = liveSorobanStateSizeWindowSamplePeriod
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
        liveSorobanStateSizeWindowSampleSize = try container.decode(UInt32.self)
        liveSorobanStateSizeWindowSamplePeriod = try container.decode(UInt32.self)
        evictionScanSize = try container.decode(UInt32.self)
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
        try container.encode(liveSorobanStateSizeWindowSampleSize)
        try container.encode(liveSorobanStateSizeWindowSamplePeriod)
        try container.encode(evictionScanSize)
        try container.encode(startingEvictionScanLevel)
    }
}

// General “Soroban execution lane” settings
public struct ConfigSettingContractExecutionLanesV0XDR: XDRCodable {

    // maximum number of Soroban transactions per ledger
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
