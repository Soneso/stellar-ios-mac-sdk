//
//  ContractXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SCValType: Int32 {
    case bool = 0
    case void = 1
    case status = 2
    case u32 = 3
    case i32 = 4
    case u64 = 5
    case i64 = 6
    case timepoint = 7
    case duration = 8
    case u128 = 9
    case i128 = 10
    case u256 = 11
    case i256 = 12
    case bytes = 13
    case string = 14
    case symbol = 15
    case vec = 16
    case map = 17
    case contractExecutable = 18
    case address = 19
    case ledgerKeyContractExecutable = 20
    case ledgerKeyNonce = 21
}

public enum SCStatusType: Int32 {
    case ok = 0
    case unknownError = 1
    case hostValueError = 2
    case hostObjectError = 3
    case hostFunctionError = 4
    case hostStorageError = 5
    case hostContextError = 6
    case vmError = 7
    case contractError = 8
    case hostAuthError = 9
}

public enum SCHostAuthErrorCode: Int32 {
    case unknownError = 0
    case nonceError = 1
    case duplicateAthorization = 2
    case authNotAuthorized = 3
}

public enum SCHostValErrorCode: Int32 {
    case unknownError = 0
    case reservedTagValue = 1
    case unexpectedValType = 2
    case u63OutOfRange = 3
    case u32OutOfRange = 4
    case staticUnknown = 5
    case missingObject = 6
    case symbolTooLong = 7
    case symbolBadChar = 8
    case symbolContainsNonUTF8 = 9
    case bitsetTooManyBits = 10
    case statusUnknown = 11
}

public enum SCHostObjErrorCode: Int32 {
    case unknownError = 0
    case unknownReference = 1
    case unexpectedType = 2
    case objectCountExceedsU32Max = 3
    case objectNotExists = 4
    case vecIndexOutOfBound = 5
    case contractHashWrongLenght = 6
}

public enum SCHostFnErrorCode: Int32 {
    case unknownError = 0
    case hostFunctionAction = 1
    case inputArgsWrongLenght = 2
    case inputArgsWrongType = 3
    case inputArgsInvalid = 4
}

public enum SCHostStorageErrorCode: Int32 {
    case unknownError = 0
    case expectContractData = 1
    case readwriteAccessToReadonlyEntry = 2
    case accessToUnknownEntry = 3
    case missingKeyInGet = 4
    case getOnDeletedKey = 5
}

public enum SCHostContextErrorCode: Int32 {
    case unknownError = 0
    case noContractRunning = 1
}

public enum SCVmErrorCode: Int32 {
    case unknownError = 0
    case validation = 1
    case instantiation = 2
    case function = 3
    case table = 4
    case memory = 5
    case global = 6
    case value = 7
    case trapUnreachable = 8
    case memoryAccessOutOfBounds = 9
    case tableAccessOutOfBounds = 10
    case elemUnitialized = 11
    case divisionByZero = 12
    case integerOverflow = 13
    case invalidConversionToInt = 14
    case stackOverflow = 15
    case unexpectedSignature = 16
    case memLimitExceeded = 17
    case cpuLimitExceeded = 18
}

public enum SCUnknownErrorCode: Int32 {
    case errorGeneral = 0
    case errorXDR = 1
}

public enum ContractCostType: Int32 {
    case wasmInsnExec = 0
    case wasmMemAlloc = 1
    case hostMemAlloc = 2
    case hostMemCpy = 3
    case hostMemCmp = 4
    case invokeHostFunction = 5
    case visitObject = 6
    case valXdrConv = 7
    case valSer = 8
    case valDeser = 9
    case computeSha256Hash = 10
    case computeEd25519PubKey = 11
    case mapEntry = 12
    case vecEntry = 13
    case guardFrame = 14
    case verifyEd25519Sig = 15
    case vmMemRead = 16
    case vmMemWrite = 17
    case vmInstantiation = 18
    case invokeVmFunction = 19
    case chargeBudget = 20
}

public enum SCStatusXDR: XDRCodable {

    case ok
    case unknownError(Int32)
    case hostValueError(Int32)
    case hostObjectError(Int32)
    case hostFunctionError(Int32)
    case hostStorageError(Int32)
    case hostContextError(Int32)
    case vmError(Int32)
    case contractError(Int32)
    case hostAuthError(Int32)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCStatusType(rawValue: discriminant)!
        
        switch type {
        case .ok:
            self = .ok
        case .unknownError:
            let unknownError = try container.decode(Int32.self)
            self = .unknownError(unknownError)
        case .hostValueError:
            let hostValueError = try container.decode(Int32.self)
            self = .hostValueError(hostValueError)
        case .hostObjectError:
            let hostObjectError = try container.decode(Int32.self)
            self = .hostObjectError(hostObjectError)
        case .hostFunctionError:
            let hostFunctionError = try container.decode(Int32.self)
            self = .hostFunctionError(hostFunctionError)
        case .hostStorageError:
            let hostStorageError = try container.decode(Int32.self)
            self = .hostStorageError(hostStorageError)
        case .hostContextError:
            let hostContextError = try container.decode(Int32.self)
            self = .hostContextError(hostContextError)
        case .vmError:
            let vmError = try container.decode(Int32.self)
            self = .vmError(vmError)
        case .contractError:
            let contractError = try container.decode(Int32.self)
            self = .contractError(contractError)
        case .hostAuthError:
            let contractError = try container.decode(Int32.self)
            self = .hostAuthError(contractError)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .ok: return SCStatusType.ok.rawValue
        case .unknownError: return SCStatusType.unknownError.rawValue
        case .hostValueError: return SCStatusType.hostValueError.rawValue
        case .hostObjectError: return SCStatusType.hostObjectError.rawValue
        case .hostFunctionError: return SCStatusType.hostFunctionError.rawValue
        case .hostStorageError: return SCStatusType.hostStorageError.rawValue
        case .hostContextError: return SCStatusType.hostContextError.rawValue
        case .vmError: return SCStatusType.vmError.rawValue
        case .contractError: return SCStatusType.contractError.rawValue
        case .hostAuthError: return SCStatusType.hostAuthError.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .ok:
            break
        case .unknownError (let unknownError):
            try container.encode(unknownError)
            break
        case .hostValueError (let hostValueError):
            try container.encode(hostValueError)
            break
        case .hostObjectError (let hostObjectError):
            try container.encode(hostObjectError)
            break
        case .hostFunctionError (let hostFunctionError):
            try container.encode(hostFunctionError)
            break
        case .hostStorageError (let hostStorageError):
            try container.encode(hostStorageError)
            break
        case .hostContextError (let hostContextError):
            try container.encode(hostContextError)
            break
        case .vmError (let vmError):
            try container.encode(vmError)
            break
        case .contractError (let contractError):
            try container.encode(contractError)
            break
        case .hostAuthError (let hostAuthError):
            try container.encode(hostAuthError)
            break
        }
    }
    
    public var isOk:Bool {
        return type() == SCStatusType.ok.rawValue
    }
    
    public var isUnknownError:Bool {
        return type() == SCStatusType.unknownError.rawValue
    }
    
    public var unknownError:Int32? {
        switch self {
        case .unknownError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isHostValueError:Bool {
        return type() == SCStatusType.hostValueError.rawValue
    }
    
    public var hostValueError:Int32? {
        switch self {
        case .hostValueError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isHostObjectError:Bool {
        return type() == SCStatusType.hostObjectError.rawValue
    }
    
    public var hostObjectError:Int32? {
        switch self {
        case .hostObjectError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isHostFunctionError:Bool {
        return type() == SCStatusType.hostFunctionError.rawValue
    }
    
    public var hostFunctionError:Int32? {
        switch self {
        case .hostFunctionError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isHostStorageError:Bool {
        return type() == SCStatusType.hostStorageError.rawValue
    }
    
    public var hostStorageError:Int32? {
        switch self {
        case .hostStorageError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isHostContextError:Bool {
        return type() == SCStatusType.hostContextError.rawValue
    }
    
    public var hostContextError:Int32? {
        switch self {
        case .hostContextError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isVmError:Bool {
        return type() == SCStatusType.vmError.rawValue
    }
    
    public var vmError:Int32? {
        switch self {
        case .vmError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isContractError:Bool {
        return type() == SCStatusType.contractError.rawValue
    }
    
    public var contractError:Int32? {
        switch self {
        case .contractError(let val):
            return val
        default:
            return nil
        }
    }
    
    public var hostAuthError:Int32? {
        switch self {
        case .hostAuthError(let val):
            return val
        default:
            return nil
        }
    }
}

public enum SCAddressType: Int32 {
    case account = 0
    case contract = 1
}

public enum SCAddressXDR: XDRCodable {
    case account(PublicKey)
    case contract(WrappedData32)
    
    public init(address: Address) throws {
        switch address {
        case .accountId(let accountId):
            self = .account(try PublicKey(accountId: accountId))
        case .contractId(let contractId):
            if let contractIdData = contractId.data(using: .hexadecimal) {
                self = .contract(WrappedData32(contractIdData))
            } else {
                throw StellarSDKError.encodingError(message: "error xdr encoding invoke host function operation, invalid contract id")
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCAddressType(rawValue: discriminant)!
        
        switch type {
        case .account:
            let account = try container.decode(PublicKey.self)
            self = .account(account)
        case .contract:
            let contract = try container.decode(WrappedData32.self)
            self = .contract(contract)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .account: return SCAddressType.account.rawValue
        case .contract: return SCAddressType.contract.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .account (let account):
            try container.encode(account)
            break
        case .contract (let contract):
            try container.encode(contract)
            break
        }
    }
    
    public var accountId:String? {
        switch self {
        case .account(let pk):
            return pk.accountId
        default:
            return nil
        }
    }
    
    public var contractId:String? {
        switch self {
        case .contract(let data):
            return data.wrapped.hexEncodedString()
        default:
            return nil
        }
    }
}

public struct SCNonceKeyXDR: XDRCodable {
    public let nonceAddress: SCAddressXDR
    
    public init(nonceAddress:SCAddressXDR) {
        self.nonceAddress = nonceAddress
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        nonceAddress = try container.decode(SCAddressXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(nonceAddress)
    }
}

public enum SCValXDR: XDRCodable {

    case bool(Bool)
    case void
    case status(SCStatusXDR)
    case u32(UInt32)
    case i32(Int32)
    case u64(UInt64)
    case i64(Int64)
    case timepoint(UInt64)
    case duration(UInt64)
    case u128(UInt128PartsXDR)
    case i128(Int128PartsXDR)
    case u256(UInt256PartsXDR)
    case i256(Int256PartsXDR)
    case bytes(Data)
    case string(String)
    case symbol(String)
    case vec([SCValXDR]?)
    case map([SCMapEntryXDR]?)
    case contractExecutable(SCContractExecutableXDR)
    case address(SCAddressXDR)
    case ledgerKeyContractExecutable
    case ledgerKeyNonce(SCNonceKeyXDR)
    
    public init(address: Address) throws {
        self = .address(try SCAddressXDR(address: address))
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCValType(rawValue: discriminant)!
        
        switch type {
        case .bool:
            let b = try container.decode(Bool.self)
            self = .bool(b)
        case .void:
            self = .void
            break
        case .status:
            let status = try container.decode(SCStatusXDR.self)
            self = .status(status)
        case .u32:
            let u32 = try container.decode(UInt32.self)
            self = .u32(u32)
        case .i32:
            let i32 = try container.decode(Int32.self)
            self = .i32(i32)
        case .u64:
            let u64 = try container.decode(UInt64.self)
            self = .u64(u64)
        case .i64:
            let i64 = try container.decode(Int64.self)
            self = .i64(i64)
        case .timepoint:
            let timepoint = try container.decode(UInt64.self)
            self = .timepoint(timepoint)
        case .duration:
            let duration = try container.decode(UInt64.self)
            self = .duration(duration)
        case .u128:
            let u128 = try container.decode(UInt128PartsXDR.self)
            self = .u128(u128)
        case .i128:
            let i128 = try container.decode(Int128PartsXDR.self)
            self = .i128(i128)
        case .u256:
            let u256 = try container.decode(UInt256PartsXDR.self)
            self = .u256(u256)
        case .i256:
            let i256 = try container.decode(Int256PartsXDR.self)
            self = .i256(i256)
        case .bytes:
            let bytes = try container.decode(Data.self)
            self = .bytes(bytes)
        case .string:
            let string = try container.decode(String.self)
            self = .string(string)
        case .symbol:
            let symbol = try container.decode(String.self)
            self = .symbol(symbol)
        case .vec:
            let vecPresent = try container.decode(UInt32.self)
            if vecPresent != 0 {
                let vec = try decodeArray(type: SCValXDR.self, dec: decoder)
                self = .vec(vec)
            } else {
                self = .vec(nil)
            }
        case .map:
            let mapPresent = try container.decode(UInt32.self)
            if mapPresent != 0 {
                let map = try decodeArray(type: SCMapEntryXDR.self, dec: decoder)
                self = .map(map)
            } else {
                self = .map(nil)
            }
        case .contractExecutable:
            let contractExecutable = try container.decode(SCContractExecutableXDR.self)
            self = .contractExecutable(contractExecutable)
        case .address:
            let address = try container.decode(SCAddressXDR.self)
            self = .address(address)
        case .ledgerKeyContractExecutable:
            self = .ledgerKeyContractExecutable
            break
        case .ledgerKeyNonce:
            let ledgerKeyNonce = try container.decode(SCNonceKeyXDR.self)
            self = .ledgerKeyNonce(ledgerKeyNonce)
        }
    }
    
    public init(accountEd25519Signature: AccountEd25519Signature) {
        let pkBytes = Data(accountEd25519Signature.publicKey.bytes)
        let sigBytes = Data(accountEd25519Signature.signature)
        let pkMapEntry = SCMapEntryXDR(key: SCValXDR.symbol("public_key"), val: SCValXDR.bytes(pkBytes))
        let sigMapEntry = SCMapEntryXDR(key: SCValXDR.symbol("signature"), val: SCValXDR.bytes(sigBytes))
        self = .map([pkMapEntry,sigMapEntry])
    }
    
    public func type() -> Int32 {
        switch self {
        case .bool: return SCValType.bool.rawValue
        case .void: return SCValType.bool.rawValue
        case .status: return SCValType.status.rawValue
        case .u32: return SCValType.u32.rawValue
        case .i32: return SCValType.i32.rawValue
        case .u64: return SCValType.u64.rawValue
        case .i64: return SCValType.i64.rawValue
        case .timepoint: return SCValType.timepoint.rawValue
        case .duration: return SCValType.duration.rawValue
        case .u128: return SCValType.u128.rawValue
        case .i128: return SCValType.i128.rawValue
        case .u256: return SCValType.u256.rawValue
        case .i256: return SCValType.i256.rawValue
        case .bytes: return SCValType.bytes.rawValue
        case .string: return SCValType.string.rawValue
        case .symbol: return SCValType.symbol.rawValue
        case .vec: return SCValType.vec.rawValue
        case .map: return SCValType.map.rawValue
        case .contractExecutable: return SCValType.contractExecutable.rawValue
        case .ledgerKeyContractExecutable: return SCValType.ledgerKeyContractExecutable.rawValue
        case .address: return SCValType.address.rawValue
        case .ledgerKeyNonce: return SCValType.ledgerKeyNonce.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .bool (let bool):
            try container.encode(bool)
            break
        case .void:
            break
        case .status (let status):
            try container.encode(status)
            break
        case .u32 (let u32):
            try container.encode(u32)
            break
        case .i32 (let i32):
            try container.encode(i32)
            break
        case .u64 (let u64):
            try container.encode(u64)
            break
        case .i64 (let i64):
            try container.encode(i64)
            break
        case .timepoint (let timepoint):
            try container.encode(timepoint)
            break
        case .duration (let duration):
            try container.encode(duration)
            break
        case .u128 (let u128):
            try container.encode(u128)
            break
        case .i128 (let i128):
            try container.encode(i128)
            break
        case .u256 (let u256):
            try container.encode(u256)
            break
        case .i256 (let i256):
            try container.encode(i256)
            break
        case .bytes (let bytes):
            try container.encode(bytes)
            break
        case .string (let string):
            try container.encode(string)
            break
        case .symbol (let symbol):
            try container.encode(symbol)
            break
        case .vec (let vec):
            if let vec = vec {
                let flag: Int32 = 1
                try container.encode(flag)
                try container.encode(vec)
            } else {
                let flag: Int32 = 0
                try container.encode(flag)
            }
            break
        case .map (let map):
            if let map = map {
                let flag: Int32 = 1
                try container.encode(flag)
                try container.encode(map)
            } else {
                let flag: Int32 = 0
                try container.encode(flag)
            }
            break
        case .contractExecutable(let exec):
            try container.encode(exec)
            break
        case .address(let address):
            try container.encode(address)
            break
        case .ledgerKeyContractExecutable:
            break
        case .ledgerKeyNonce (let nonceKey):
            try container.encode(nonceKey)
            break
        }
    }
    
    public static func fromXdr(base64:String) throws -> SCValXDR {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: base64))
        return try SCValXDR(from: xdrDecoder)
    }
    

    public var isBool:Bool {
        return type() == SCValType.bool.rawValue
    }
    
    public var bool:Bool? {
        switch self {
        case .bool(let bool):
            return bool
        default:
            return nil
        }
    }
    
    public var isVoid:Bool {
        return type() == SCValType.void.rawValue
    }
    
    public var isU32:Bool {
        return type() == SCValType.u32.rawValue
    }
    
    public var u32:UInt32? {
        switch self {
        case .u32(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isI32: Bool {
        return type() == SCValType.i32.rawValue
    }
    
    public var i32:Int32? {
        switch self {
        case .i32(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isStatus:Bool {
        return type() == SCValType.status.rawValue
    }
    
    public var status:SCStatusXDR? {
        switch self {
        case .status(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isU64: Bool {
        return type() == SCValType.u64.rawValue
    }
    
    public var u64:UInt64? {
        switch self {
        case .u64(let u64):
            return u64
        default:
            return nil
        }
    }
    
    public var isI64: Bool {
        return type() == SCValType.i64.rawValue
    }
    
    public var i64:Int64? {
        switch self {
        case .i64(let i64):
            return i64
        default:
            return nil
        }
    }
    
    public var isTimepoint: Bool {
        return type() == SCValType.timepoint.rawValue
    }
    
    public var timepoint:UInt64? {
        switch self {
        case .timepoint(let timepoint):
            return timepoint
        default:
            return nil
        }
    }
    
    public var isDuration: Bool {
        return type() == SCValType.duration.rawValue
    }
    
    public var duration:UInt64? {
        switch self {
        case .duration(let duration):
            return duration
        default:
            return nil
        }
    }
    
    public var isU128: Bool {
        return type() == SCValType.u128.rawValue
    }
    
    public var u128:UInt128PartsXDR? {
        switch self {
        case .u128(let u128):
            return u128
        default:
            return nil
        }
    }
    
    public var isI128: Bool {
        return type() == SCValType.i128.rawValue
    }
    
    public var i128:Int128PartsXDR? {
        switch self {
        case .i128(let i128):
            return i128
        default:
            return nil
        }
    }
    
    public var isU256: Bool {
        return type() == SCValType.u256.rawValue
    }
    
    public var u256:UInt256PartsXDR? {
        switch self {
        case .u256(let u256):
            return u256
        default:
            return nil
        }
    }
    
    public var isI256: Bool {
        return type() == SCValType.i256.rawValue
    }
    
    public var i256:Int256PartsXDR? {
        switch self {
        case .i256(let i256):
            return i256
        default:
            return nil
        }
    }
    
    public var isBytes:Bool {
        return type() == SCValType.bytes.rawValue
    }
    
    public var bytes:Data? {
        switch self {
        case .bytes(let bytes):
            return bytes
        default:
            return nil
        }
    }
    
    public var isString:Bool {
        return type() == SCValType.string.rawValue
    }
    
    public var string:String? {
        switch self {
        case .string(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isSymbol:Bool {
        return type() == SCValType.symbol.rawValue
    }
    
    public var symbol:String? {
        switch self {
        case .symbol(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isVec: Bool {
        return type() == SCValType.vec.rawValue
    }
    
    public var vec:[SCValXDR]? {
        switch self {
        case .vec(let vec):
            return vec
        default:
            return nil
        }
    }
    
    public var isMap: Bool {
        return type() == SCValType.map.rawValue
    }
    
    public var map:[SCMapEntryXDR]? {
        switch self {
        case .map(let map):
            return map
        default:
            return nil
        }
    }
    
    public var isContractExecutable: Bool {
        return type() == SCValType.contractExecutable.rawValue
    }
    
    public var contractExecutable:SCContractExecutableXDR? {
        switch self {
        case .contractExecutable(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isAddress: Bool {
        return type() == SCValType.address.rawValue
    }
    
    public var address:SCAddressXDR? {
        switch self {
        case .address(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isLedgerKeyContractExecutable: Bool {
        return type() == SCValType.ledgerKeyContractExecutable.rawValue
    }
    
    public var isLedgerKeyNonce: Bool {
        return type() == SCValType.ledgerKeyNonce.rawValue
    }
    
    public var ledgerKeyNonce:SCNonceKeyXDR? {
        switch self {
        case .ledgerKeyNonce(let val):
            return val
        default:
            return nil
        }
    }
}


public struct SCMapEntryXDR: XDRCodable {
    public let key: SCValXDR
    public let val: SCValXDR
    
    public init(key:SCValXDR, val:SCValXDR) {
        self.key = key
        self.val = val
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        key = try container.decode(SCValXDR.self)
        val = try container.decode(SCValXDR.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(key)
        try container.encode(val)
    }
}

public enum SCContractCodeType: Int32 {
    case wasmRef = 0
    case token = 1
}

public enum SCContractExecutableXDR: XDRCodable {

    case wasmRef(WrappedData32)
    case token
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCContractCodeType(rawValue: discriminant)!
        
        switch type {
        case .wasmRef:
            let wasmRef = try container.decode(WrappedData32.self)
            self = .wasmRef(wasmRef)
        case .token:
            self = .token
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .wasmRef: return SCContractCodeType.wasmRef.rawValue
        case .token: return SCContractCodeType.token.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .wasmRef (let wasmRef):
            try container.encode(wasmRef)
            break
        case .token:
            break
        }
    }
    
    public var isWasmRef:Bool? {
        return type() == SCContractCodeType.wasmRef.rawValue
    }
    
    public var wasmRef:WrappedData32? {
        switch self {
        case .wasmRef(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isToken:Bool? {
        return type() == SCContractCodeType.token.rawValue
    }
}

public struct Int128PartsXDR: XDRCodable {
    public let hi: Int64
    public let lo: UInt64
    
    public init(hi:Int64, lo:UInt64) {
        self.hi = hi
        self.lo = lo
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        hi = try container.decode(Int64.self)
        lo = try container.decode(UInt64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hi)
        try container.encode(lo)
    }
}

public struct UInt128PartsXDR: XDRCodable {
    public let hi: UInt64
    public let lo: UInt64
    
    public init(hi:UInt64, lo:UInt64) {
        self.hi = hi
        self.lo = lo
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        hi = try container.decode(UInt64.self)
        lo = try container.decode(UInt64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hi)
        try container.encode(lo)
    }
}

public struct Int256PartsXDR: XDRCodable {

    public let hiHi: Int64
    public let hiLo: UInt64
    public let loHi: UInt64
    public let loLo: UInt64
    
    public init(hiHi: Int64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        self.hiHi = hiHi
        self.hiLo = hiLo
        self.loHi = loHi
        self.loLo = loLo
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        hiHi = try container.decode(Int64.self)
        hiLo = try container.decode(UInt64.self)
        loHi = try container.decode(UInt64.self)
        loLo = try container.decode(UInt64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hiHi)
        try container.encode(hiLo)
        try container.encode(loHi)
        try container.encode(loLo)
    }
}

public struct UInt256PartsXDR: XDRCodable {

    public let hiHi: UInt64
    public let hiLo: UInt64
    public let loHi: UInt64
    public let loLo: UInt64
    
    public init(hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        self.hiHi = hiHi
        self.hiLo = hiLo
        self.loHi = loHi
        self.loLo = loLo
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        hiHi = try container.decode(UInt64.self)
        hiLo = try container.decode(UInt64.self)
        loHi = try container.decode(UInt64.self)
        loLo = try container.decode(UInt64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(hiHi)
        try container.encode(hiLo)
        try container.encode(loHi)
        try container.encode(loLo)
    }
}

