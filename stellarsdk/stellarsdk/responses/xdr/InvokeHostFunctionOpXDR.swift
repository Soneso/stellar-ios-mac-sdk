//
//  InvokeHostFunctionOpXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum HostFunctionType: Int32 {
    case invokeContract = 0
    case createContract = 1
    case installContractCode = 2
}

public enum ContractIDType: Int32 {
    case fromSourceAccount = 0
    case fromEd25519PublicKey = 1
    case fromAsset = 2
}

public enum ContractIDPublicKeyType: Int32 {
    case publicKeySourceAccount = 0
    case publicKeyEd25519 = 1
}

public struct InstallContractCodeArgsXDR: XDRCodable {
    public let code: Data
    
    public init(code:Data) {
        self.code = code
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        code = try container.decode(Data.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(code)
    }
}

public struct FromEd25519PublicKeyXDR: XDRCodable {
    public let key: WrappedData32
    public let signature: Data
    public let salt: WrappedData32
    
    public init(key: WrappedData32,signature:Data, salt:WrappedData32) {
        self.key = key
        self.signature = signature
        self.salt = salt
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        key = try container.decode(WrappedData32.self)
        signature = try container.decode(Data.self)
        salt = try container.decode(WrappedData32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(key)
        try container.encode(signature)
        try container.encode(salt)
    }
}

public enum ContractIDXDR: XDRCodable {

    case fromSourceAccount(WrappedData32)
    case fromEd25519PublicKey(FromEd25519PublicKeyXDR)
    case fromAsset(AssetXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = ContractIDType(rawValue: discriminant)!
        
        switch type {
        case .fromSourceAccount:
            let fromSourceAccount = try container.decode(WrappedData32.self)
            self = .fromSourceAccount(fromSourceAccount)
        case .fromEd25519PublicKey:
            let fromEd25519PublicKey = try container.decode(FromEd25519PublicKeyXDR.self)
            self = .fromEd25519PublicKey(fromEd25519PublicKey)
        case .fromAsset:
            let fromAsset = try container.decode(AssetXDR.self)
            self = .fromAsset(fromAsset)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .fromSourceAccount: return ContractIDType.fromSourceAccount.rawValue
        case .fromEd25519PublicKey: return ContractIDType.fromEd25519PublicKey.rawValue
        case .fromAsset: return ContractIDType.fromAsset.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .fromSourceAccount (let fromSourceAccount):
            try container.encode(fromSourceAccount)
            break
        case .fromEd25519PublicKey (let fromEd25519PublicKey):
            try container.encode(fromEd25519PublicKey)
            break
        case .fromAsset (let fromAsset):
            try container.encode(fromAsset)
            break
        }
    }
}

public struct CreateContractArgsXDR: XDRCodable {
    public let contractId: ContractIDXDR
    public let source: SCContractCodeXDR
    
    public init(contractId:ContractIDXDR, source:SCContractCodeXDR) {
        self.contractId = contractId
        self.source = source
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        contractId = try container.decode(ContractIDXDR.self)
        source = try container.decode(SCContractCodeXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contractId)
        try container.encode(source)
    }
}

public enum HostFunctionXDR: XDRCodable {

    case invokeContract([SCValXDR])
    case createContract(CreateContractArgsXDR)
    case installContractCode(InstallContractCodeArgsXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = HostFunctionType(rawValue: discriminant)!
        
        switch type {
        case .invokeContract:
            let args = try decodeArray(type: SCValXDR.self, dec: decoder)
            self = .invokeContract(args)
        case .createContract:
            let createContract = try container.decode(CreateContractArgsXDR.self)
            self = .createContract(createContract)
        case .installContractCode:
            let installContractCode = try container.decode(InstallContractCodeArgsXDR.self)
            self = .installContractCode(installContractCode)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .invokeContract: return HostFunctionType.invokeContract.rawValue
        case .createContract: return HostFunctionType.createContract.rawValue
        case .installContractCode: return HostFunctionType.installContractCode.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .invokeContract (let invokeContract):
            try container.encode(invokeContract)
            break
        case .createContract (let createContract):
            try container.encode(createContract)
            break
        case .installContractCode (let installContractCode):
            try container.encode(installContractCode)
            break
        }
    }
}

public struct LedgerFootprintXDR: XDRCodable {
    public let readOnly: [LedgerKeyXDR]
    public let readWrite: [LedgerKeyXDR]
    
    public init(readOnly:[LedgerKeyXDR], readWrite:[LedgerKeyXDR]) {
        self.readOnly = readOnly
        self.readWrite = readWrite
    }

    public init(from decoder: Decoder) throws {
        //var container = try decoder.unkeyedContainer()
        readOnly = try decodeArray(type: LedgerKeyXDR.self, dec: decoder)
        readWrite = try decodeArray(type: LedgerKeyXDR.self, dec: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(readOnly)
        try container.encode(readWrite)
    }
}

public struct InvokeHostFunctionOpXDR: XDRCodable {
    public let function: HostFunctionXDR
    public var ledgerFootprint: LedgerFootprintXDR
    
    public init(function:HostFunctionXDR, ledgerFootprint:LedgerFootprintXDR) {
        self.function = function
        self.ledgerFootprint = ledgerFootprint
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        function = try container.decode(HostFunctionXDR.self)
        ledgerFootprint = try container.decode(LedgerFootprintXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(function)
        try container.encode(ledgerFootprint)
    }
}
