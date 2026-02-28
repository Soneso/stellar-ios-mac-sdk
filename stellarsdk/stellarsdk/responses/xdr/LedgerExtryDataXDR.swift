//
//  LedgerExtryDataXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

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
