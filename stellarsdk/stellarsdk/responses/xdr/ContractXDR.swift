//
//  ContractXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SCValType: Int32 {
    case u63 = 0
    case u32 = 1
    case i32 = 2
    case sstatic = 3
    case object = 4
    case symbol = 5
    case bitset = 6
    case status = 7
}

public enum SCStatic: Int32 {
    case void = 0
    case strue = 1
    case sfalse = 2
    case ledgerKeyContractCode = 3
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
    case devisionByZero = 12
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

public enum SCStatusXDR: XDRCodable {

    case ok
    case unknownError(Int32)
    case hostValueError(Int32)
    case hostObjectError(Int32)
    case hostFunctionError(Int32)
    case hostStorageError(Int32)
    case hostContextError(Int32)
    case vmError(Int32)
    case contractError(UInt32)
    
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
            let contractError = try container.decode(UInt32.self)
            self = .contractError(contractError)
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
    
    public var contractError:UInt32? {
        switch self {
        case .contractError(let val):
            return val
        default:
            return nil
        }
    }
}

public enum SCValXDR: XDRCodable {

    case u63(UInt64)
    case u32(UInt32)
    case i32(Int32)
    case sstatic(Int32)
    case object(SCObjectXDR?)
    case symbol(String)
    case bitset(UInt64)
    case status(SCStatusXDR)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCValType(rawValue: discriminant)!
        
        switch type {
        case .u63:
            let u63 = try container.decode(UInt64.self)
            self = .u63(u63)
        case .u32:
            let u32 = try container.decode(UInt32.self)
            self = .u32(u32)
        case .i32:
            let i32 = try container.decode(Int32.self)
            self = .i32(i32)
        case .sstatic:
            let sstatic = try container.decode(Int32.self)
            self = .sstatic(sstatic)
        case .object:
            let objectPresent = try container.decode(UInt32.self)
            if objectPresent != 0 {
                let object = try container.decode(SCObjectXDR.self)
                self = .object(object)
            } else {
                self = .object(nil)
            }
        case .symbol:
            let symbol = try container.decode(String.self)
            self = .symbol(symbol)
        case .bitset:
            let bitset = try container.decode(UInt64.self)
            self = .bitset(bitset)
        case .status:
            let status = try container.decode(SCStatusXDR.self)
            self = .status(status)
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .u63: return SCValType.u63.rawValue
        case .u32: return SCValType.u32.rawValue
        case .i32: return SCValType.i32.rawValue
        case .sstatic: return SCValType.sstatic.rawValue
        case .object: return SCValType.object.rawValue
        case .symbol: return SCValType.symbol.rawValue
        case .bitset: return SCValType.bitset.rawValue
        case .status: return SCValType.status.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .u63 (let u63):
            try container.encode(u63)
            break
        case .u32 (let u32):
            try container.encode(u32)
            break
        case .i32 (let i32):
            try container.encode(i32)
            break
        case .sstatic (let sstatic):
            try container.encode(sstatic)
            break
        case .object (let object):
            if let object = object {
                let flag: Int32 = 1
                try container.encode(flag)
                try container.encode(object)
            } else {
                let flag: Int32 = 0
                try container.encode(flag)
            }
            break
        case .symbol (let symbol):
            try container.encode(symbol)
            break
        case .bitset (let bitset):
            try container.encode(bitset)
            break
        case .status (let status):
            try container.encode(status)
            break

        }
    }
    
    public static func fromXdr(base64:String) throws -> SCValXDR {
        let xdrDecoder = XDRDecoder.init(data: [UInt8].init(base64: base64))
        return try SCValXDR(from: xdrDecoder)
    }
    
    public var vec:[SCValXDR]? {
        switch self {
        case .object(let obj):
            return obj?.vec
        default:
            return nil
        }
    }
    
    public var map:[SCMapEntryXDR]? {
        switch self {
        case .object(let obj):
            return obj?.map
        default:
            return nil
        }
    }
    
    public var u64:UInt64? {
        switch self {
        case .object(let obj):
            return obj?.u64
        default:
            return nil
        }
    }
    
    public var i64:Int64? {
        switch self {
        case .object(let obj):
            return obj?.i64
        default:
            return nil
        }
    }
    
    public var u128:Int128PartsXDR? {
        switch self {
        case .object(let obj):
            return obj?.u128
        default:
            return nil
        }
    }
    
    public var bytes:Data? {
        switch self {
        case .object(let obj):
            return obj?.bytes
        default:
            return nil
        }
    }
    
    public var contractCode:SCContractCodeXDR? {
        switch self {
        case .object(let obj):
            return obj?.contractCode
        default:
            return nil
        }
    }
    
    public var accountId:PublicKey? {
        switch self {
        case .object(let obj):
            return obj?.accountId
        default:
            return nil
        }
    }
    
    public var isU63: Bool {
        return type() == SCValType.u63.rawValue
    }
    
    public var u63:UInt64? {
        switch self {
        case .u63(let val):
            return val
        default:
            return nil
        }
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
    
    public var isStatic:Bool {
        return type() == SCValType.sstatic.rawValue
    }
    
    public var sstatic:Int32? {
        switch self {
        case .sstatic(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isObj:Bool {
        return type() == SCValType.object.rawValue
    }
    
    public var hasObject:Bool {
        switch self {
        case .object(let optional):
            return optional != nil
        default:
            return false
        }
    }
    
    public var object:SCObjectXDR? {
        switch self {
        case .object(let optional):
            return optional
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
    
    public var isBitset:Bool {
        return type() == SCValType.bitset.rawValue
    }
    
    public var bitset:UInt64? {
        switch self {
        case .bitset(let val):
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
}

public enum SCObjectType: Int32 {
    case vec = 0
    case map = 1
    case u64 = 2
    case i64 = 3
    case u128 = 4
    case i128 = 5
    case bytes = 6
    case contractCode = 7
    case accountId = 8
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

public enum SCContractCodeXDR: XDRCodable {

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
    public let lo: UInt64
    public let hi: UInt64
    
    public init(lo:UInt64, hi:UInt64) {
        self.lo = lo
        self.hi = hi
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lo = try container.decode(UInt64.self)
        hi = try container.decode(UInt64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lo)
        try container.encode(hi)
    }
}

public enum SCObjectXDR: XDRCodable {

    case vec([SCValXDR])
    case map([SCMapEntryXDR])
    case u64(UInt64)
    case i64(Int64)
    case u128(Int128PartsXDR)
    case i128(Int128PartsXDR)
    case bytes(Data)
    case contractCode(SCContractCodeXDR)
    case accountId(PublicKey)
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCObjectType(rawValue: discriminant)!
        
        switch type {
        case .vec:
            let vec = try decodeArray(type: SCValXDR.self, dec: decoder)
            self = .vec(vec)
        case .map:
            let map = try decodeArray(type: SCMapEntryXDR.self, dec: decoder)
            self = .map(map)
        case .u64:
            let u64 = try container.decode(UInt64.self)
            self = .u64(u64)
        case .i64:
            let i64 = try container.decode(Int64.self)
            self = .i64(i64)
        case .u128:
            let u128 = try container.decode(Int128PartsXDR.self)
            self = .u128(u128)
        case .i128:
            let i128 = try container.decode(Int128PartsXDR.self)
            self = .i128(i128)
        case .bytes:
            let bytes = try container.decode(Data.self)
            self = .bytes(bytes)
        case .contractCode:
            let contractCode = try container.decode(SCContractCodeXDR.self)
            self = .contractCode(contractCode)
        case .accountId:
            let accountId = try container.decode(PublicKey.self)
            self = .accountId(accountId)
        
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .vec: return SCObjectType.vec.rawValue
        case .map: return SCObjectType.map.rawValue
        case .u64: return SCObjectType.u64.rawValue
        case .i64: return SCObjectType.i64.rawValue
        case .u128: return SCObjectType.u128.rawValue
        case .i128: return SCObjectType.i128.rawValue
        case .bytes: return SCObjectType.bytes.rawValue
        case .contractCode: return SCObjectType.contractCode.rawValue
        case .accountId: return SCObjectType.accountId.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .vec (let vec):
            try container.encode(vec)
            break
        case .map (let map):
            try container.encode(map)
            break
        case .u64 (let u64):
            try container.encode(u64)
            break
        case .i64 (let i64):
            try container.encode(i64)
            break
        case .u128 (let u128):
            try container.encode(u128)
            break
        case .i128 (let i128):
            try container.encode(i128)
            break
        case .bytes (let bytes):
            try container.encode(bytes)
            break
        case .contractCode (let contractCode):
            try container.encode(contractCode)
            break
        case .accountId (let accountId):
            try container.encode(accountId)
            break
        }
    }
    
    public var isVec:Bool {
        return type() == SCObjectType.vec.rawValue
    }
    
    public var vec:[SCValXDR]? {
        switch self {
        case .vec(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isMap:Bool {
        return type() == SCObjectType.map.rawValue
    }
    
    public var map:[SCMapEntryXDR]? {
        switch self {
        case .map(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isU64:Bool {
        return type() == SCObjectType.u64.rawValue
    }
    
    public var u64:UInt64? {
        switch self {
        case .u64(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isI64:Bool {
        return type() == SCObjectType.i64.rawValue
    }
    
    public var i64:Int64? {
        switch self {
        case .i64(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isU128:Bool {
        return type() == SCObjectType.u128.rawValue
    }
    
    public var u128:Int128PartsXDR? {
        switch self {
        case .u128(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isI128:Bool {
        return type() == SCObjectType.i128.rawValue
    }
    
    public var i128:Int128PartsXDR? {
        switch self {
        case .i128(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isBytes:Bool {
        return type() == SCObjectType.bytes.rawValue
    }
    
    public var bytes:Data? {
        switch self {
        case .bytes(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isContractCode:Bool {
        return type() == SCObjectType.contractCode.rawValue
    }
    
    public var contractCode:SCContractCodeXDR? {
        switch self {
        case .contractCode(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isAccountId:Bool {
        return type() == SCObjectType.accountId.rawValue
    }
    
    public var accountId:PublicKey? {
        switch self {
        case .accountId(let val):
            return val
        default:
            return nil
        }
    }
}
