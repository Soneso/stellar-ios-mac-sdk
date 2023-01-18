//
//  LedgerKeyXDR.swift
//  stellarsdk
//
//  Created by Rogobete Christian on 13.02.18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum ConfigSettingID: Int32 {
    case contractMaxSize = 0
}


public enum LedgerKeyXDR: XDRCodable {
    case account (LedgerKeyAccountXDR)
    case trustline (LedgerKeyTrustLineXDR)
    case offer (LedgerKeyOfferXDR)
    case data (LedgerKeyDataXDR)
    case claimableBalance (ClaimableBalanceIDXDR)
    case liquidityPool(LiquidityPoolIDXDR)
    case contractData(WrappedData32, SCValXDR)
    case contractCode(WrappedData32)
    case configSetting(Int32)
    
    
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
            let contractId = try container.decode(WrappedData32.self)
            let key = try container.decode(SCValXDR.self)
            self = .contractData (contractId, key)
        case LedgerEntryType.contractCode.rawValue:
            let hash = try container.decode(WrappedData32.self)
            self = .contractCode (hash)
        case LedgerEntryType.configSetting.rawValue:
            let configSettingId = try container.decode(Int32.self)
            self = .configSetting (configSettingId)
        default:
            let acc = try container.decode(LedgerKeyAccountXDR.self)
            self = .account(acc)
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
        case .contractData (let contractId, let key):
            try container.encode(contractId)
            try container.encode(key)
        case .contractCode (let hash):
            try container.encode(hash)
        case .configSetting (let configSettingId):
            try container.encode(configSettingId)
        }
    }
}

public struct LiquidityPoolIDXDR: XDRCodable {
    public let liquidityPoolID:WrappedData32
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        liquidityPoolID = try container.decode(WrappedData32.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(liquidityPoolID)
    }
    
    public var poolIDString: String {
        return liquidityPoolID.wrapped.hexEncodedString()
    }
}
