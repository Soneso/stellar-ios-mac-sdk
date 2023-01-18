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

public enum ConfigSettingType: Int32 {
    case uint32 = 0
}


public enum ConfigSettingXDR: XDRCodable {
    case uint32Val (UInt32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(Int32.self)
        
        switch type {
            case ConfigSettingType.uint32.rawValue:
                self = .uint32Val(try container.decode(UInt32.self))
            default:
                self = .uint32Val(try container.decode(UInt32.self))
        }
        
    }
    
    public func type() -> Int32 {
        switch self {
            case .uint32Val: return ConfigSettingType.uint32.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        
        switch self {
        case .uint32Val (let uint32Val):
            try container.encode(uint32Val)
        }
    }
}


public struct ConfigSettingEntryXDR: XDRCodable {
    public var ext: ConfigSettingEntryExtXDR
    public var configSettingID: Int32
    public var setting: ConfigSettingXDR
    
    public init(ext: ConfigSettingEntryExtXDR, configSettingID: Int32, setting:ConfigSettingXDR) {
        self.ext = ext
        self.configSettingID = configSettingID
        self.setting = setting
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        ext = try container.decode(ConfigSettingEntryExtXDR.self)
        configSettingID = try container.decode(Int32.self)
        setting = try container.decode(ConfigSettingXDR.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(ext)
        try container.encode(configSettingID)
        try container.encode(setting)
    }
}

public enum ConfigSettingEntryExtXDR: XDRCodable {
    case void
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let code = try container.decode(Int32.self)
        
        switch code {
        case 0:
            self = .void
        default:
            self = .void
        }
    }
    
    private func type() -> Int32 {
        switch self {
        case .void: return 0
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type())
        
        switch self {
        case .void:
            return
        }
    }
}
