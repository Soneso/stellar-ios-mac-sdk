//
//  ContractXDR.swift
//  stellarsdk
//
//  Created by Christian Rogobete.
//  Copyright © 2023 Soneso. All rights reserved.
//

import Foundation

public enum SCErrorXDR: XDRCodable, Sendable {

    case contract(UInt32)
    case wasmVm
    case context
    case storage
    case object
    case crypto
    case events
    case budget
    case value
    case auth(Int32) //SCErrorCode
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCErrorType(rawValue: discriminant)
        
        switch type {
        case .contract:
            let contractCode = try container.decode(UInt32.self)
            self = .contract(contractCode)
        case .wasmVm:
            self = .wasmVm
        case .context:
            self = .context
        case .storage:
            self = .storage
        case .object:
            self = .object
        case .crypto:
            self = .crypto
        case .events:
            self = .events
        case .budget:
            self = .budget
        case .value:
            self = .value
        case .auth:
            let errCode = try container.decode(Int32.self)
            self = .auth(errCode)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SCErrorXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .contract: return SCErrorType.contract.rawValue
        case .wasmVm: return SCErrorType.wasmVm.rawValue
        case .context: return SCErrorType.context.rawValue
        case .storage: return SCErrorType.storage.rawValue
        case .object: return SCErrorType.object.rawValue
        case .crypto: return SCErrorType.crypto.rawValue
        case .events: return SCErrorType.events.rawValue
        case .budget: return SCErrorType.budget.rawValue
        case .value: return SCErrorType.value.rawValue
        case .auth: return SCErrorType.auth.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .contract (let contractCode):
            try container.encode(contractCode)
            break
        case .wasmVm:
            break
        case .context:
            break
        case .storage:
            break
        case .object:
            break
        case .crypto:
            break
        case .events:
            break
        case .budget:
            break
        case .value:
            break
        case .auth (let errCode):
            try container.encode(errCode)
            break
        }
    }
}

public enum SCValXDR: XDRCodable, Sendable {

    case bool(Bool)
    case void
    case error(SCErrorXDR)
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
    case address(SCAddressXDR)
    case ledgerKeyContractInstance
    case contractInstance(SCContractInstanceXDR)
    case ledgerKeyNonce(SCNonceKeyXDR)

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCValType(rawValue: discriminant)
        
        switch type {
        case .bool:
            let b = try container.decode(Bool.self)
            self = .bool(b)
        case .void:
            self = .void
        case .error:
            let error = try container.decode(SCErrorXDR.self)
            self = .error(error)
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
        case .address:
            let address = try container.decode(SCAddressXDR.self)
            self = .address(address)
            
        case .ledgerKeyContractInstance:
            self = .ledgerKeyContractInstance
            break
        case .contractInstance:
            let contractInstance = try container.decode(SCContractInstanceXDR.self)
            self = .contractInstance(contractInstance)
        case .ledgerKeyNonce:
            let ledgerKeyNonce = try container.decode(SCNonceKeyXDR.self)
            self = .ledgerKeyNonce(ledgerKeyNonce)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SCValXDR discriminant")
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
        case .void: return SCValType.void.rawValue
        case .error: return SCValType.error.rawValue
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
        case .address: return SCValType.address.rawValue
        case .ledgerKeyContractInstance: return SCValType.ledgerKeyContractInstance.rawValue
        case .contractInstance: return SCValType.contractInstance.rawValue
        case .ledgerKeyNonce: return SCValType.ledgerKeyNonce.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .bool (let bool):
            try container.encode(bool)
        case .void:
            break
        case .error (let error):
            try container.encode(error)
        case .u32 (let u32):
            try container.encode(u32)
        case .i32 (let i32):
            try container.encode(i32)
        case .u64 (let u64):
            try container.encode(u64)
        case .i64 (let i64):
            try container.encode(i64)
        case .timepoint (let timepoint):
            try container.encode(timepoint)
        case .duration (let duration):
            try container.encode(duration)
        case .u128 (let u128):
            try container.encode(u128)
        case .i128 (let i128):
            try container.encode(i128)
        case .u256 (let u256):
            try container.encode(u256)
        case .i256 (let i256):
            try container.encode(i256)
        case .bytes (let bytes):
            try container.encode(bytes)
        case .string (let string):
            try container.encode(string)
        case .symbol (let symbol):
            try container.encode(symbol)
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
        case .address(let address):
            try container.encode(address)
            break
        case .ledgerKeyContractInstance:
            break
        case .contractInstance(let val):
            try container.encode(val)
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
    
    public var isError:Bool {
        return type() == SCValType.error.rawValue
    }
    
    public var error:SCErrorXDR? {
        switch self {
        case .error(let val):
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
    
    public var isContractInstance: Bool {
        return type() == SCValType.contractInstance.rawValue
    }
    
    public var contractInstance:SCContractInstanceXDR? {
        switch self {
        case .contractInstance(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isLedgerKeyContractInstance: Bool {
        return type() == SCValType.ledgerKeyContractInstance.rawValue
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

// MARK: - BigInt Support Extension
extension SCValXDR {
    
    // MARK: - Creation from String
    
    /// Creates an SCValXDR with u128 type from a string representation of an unsigned 128-bit integer
    public static func u128(stringValue: String) throws -> SCValXDR {
        let parts = try bigInt128Parts(from: stringValue, signed: false)
        return .u128(UInt128PartsXDR(hi: parts.hi, lo: parts.lo))
    }
    
    /// Creates an SCValXDR with i128 type from a string representation of a signed 128-bit integer
    public static func i128(stringValue: String) throws -> SCValXDR {
        let parts = try bigInt128Parts(from: stringValue, signed: true)
        return .i128(Int128PartsXDR(hi: Int64(bitPattern: parts.hi), lo: parts.lo))
    }
    
    /// Creates an SCValXDR with u256 type from a string representation of an unsigned 256-bit integer
    public static func u256(stringValue: String) throws -> SCValXDR {
        let parts = try bigInt256Parts(from: stringValue, signed: false)
        return .u256(UInt256PartsXDR(hiHi: parts.hiHi, hiLo: parts.hiLo, loHi: parts.loHi, loLo: parts.loLo))
    }
    
    /// Creates an SCValXDR with i256 type from a string representation of a signed 256-bit integer
    public static func i256(stringValue: String) throws -> SCValXDR {
        let parts = try bigInt256Parts(from: stringValue, signed: true)
        return .i256(Int256PartsXDR(hiHi: Int64(bitPattern: parts.hiHi), hiLo: parts.hiLo, loHi: parts.loHi, loLo: parts.loLo))
    }
    
    // MARK: - Creation from Data
    
    /// Creates an SCValXDR with u128 type from a Data representation (big-endian)
    public static func u128(data: Data) throws -> SCValXDR {
        guard data.count <= 16 else {
            throw StellarSDKError.invalidArgument(message: "Data too large for u128")
        }
        let paddedData = padData(data, targetSize: 16, signed: false)
        let parts = dataTo128Parts(paddedData)
        return .u128(UInt128PartsXDR(hi: parts.hi, lo: parts.lo))
    }
    
    /// Creates an SCValXDR with i128 type from a Data representation (big-endian, two's complement)
    public static func i128(data: Data) throws -> SCValXDR {
        guard data.count <= 16 else {
            throw StellarSDKError.invalidArgument(message: "Data too large for i128")
        }
        let paddedData = padData(data, targetSize: 16, signed: true)
        let parts = dataTo128Parts(paddedData)
        return .i128(Int128PartsXDR(hi: Int64(bitPattern: parts.hi), lo: parts.lo))
    }
    
    /// Creates an SCValXDR with u256 type from a Data representation (big-endian)
    public static func u256(data: Data) throws -> SCValXDR {
        guard data.count <= 32 else {
            throw StellarSDKError.invalidArgument(message: "Data too large for u256")
        }
        let paddedData = padData(data, targetSize: 32, signed: false)
        let parts = dataTo256Parts(paddedData)
        return .u256(UInt256PartsXDR(hiHi: parts.hiHi, hiLo: parts.hiLo, loHi: parts.loHi, loLo: parts.loLo))
    }
    
    /// Creates an SCValXDR with i256 type from a Data representation (big-endian, two's complement)
    public static func i256(data: Data) throws -> SCValXDR {
        guard data.count <= 32 else {
            throw StellarSDKError.invalidArgument(message: "Data too large for i256")
        }
        let paddedData = padData(data, targetSize: 32, signed: true)
        let parts = dataTo256Parts(paddedData)
        return .i256(Int256PartsXDR(hiHi: Int64(bitPattern: parts.hiHi), hiLo: parts.hiLo, loHi: parts.loHi, loLo: parts.loLo))
    }
    
    // MARK: - Conversion to String
    
    /// Returns the string representation of a u128 value
    public var u128String: String? {
        guard case .u128(let parts) = self else { return nil }
        let data = Self.partsToData128(hi: parts.hi, lo: parts.lo)
        return Self.stringFromData(data, signed: false)
    }
    
    /// Returns the string representation of an i128 value
    public var i128String: String? {
        guard case .i128(let parts) = self else { return nil }
        let data = Self.partsToData128(hi: UInt64(bitPattern: parts.hi), lo: parts.lo)
        return Self.stringFromData(data, signed: true)
    }
    
    /// Returns the string representation of a u256 value
    public var u256String: String? {
        guard case .u256(let parts) = self else { return nil }
        let data = Self.partsToData256(hiHi: parts.hiHi, hiLo: parts.hiLo, loHi: parts.loHi, loLo: parts.loLo)
        return Self.stringFromData(data, signed: false)
    }
    
    /// Returns the string representation of an i256 value
    public var i256String: String? {
        guard case .i256(let parts) = self else { return nil }
        let data = Self.partsToData256(hiHi: UInt64(bitPattern: parts.hiHi), hiLo: parts.hiLo, loHi: parts.loHi, loLo: parts.loLo)
        return Self.stringFromData(data, signed: true)
    }
    
    // MARK: - Private Helper Methods
    
    private static func bigInt128Parts(from string: String, signed: Bool) throws -> (hi: UInt64, lo: UInt64) {
        let data = try stringToData(string, bitSize: 128, signed: signed)
        // Data is already properly sized from stringToData
        let bytes = [UInt8](data)
        
        var hi: UInt64 = 0
        for i in 0..<8 {
            hi = (hi << 8) | UInt64(bytes[i])
        }
        
        var lo: UInt64 = 0
        for i in 8..<16 {
            lo = (lo << 8) | UInt64(bytes[i])
        }
        
        return (hi, lo)
    }
    
    private static func bigInt256Parts(from string: String, signed: Bool) throws -> (hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        let data = try stringToData(string, bitSize: 256, signed: signed)
        // Data is already properly sized from stringToData
        let bytes = [UInt8](data)
        
        var hiHi: UInt64 = 0
        for i in 0..<8 {
            hiHi = (hiHi << 8) | UInt64(bytes[i])
        }
        
        var hiLo: UInt64 = 0
        for i in 8..<16 {
            hiLo = (hiLo << 8) | UInt64(bytes[i])
        }
        
        var loHi: UInt64 = 0
        for i in 16..<24 {
            loHi = (loHi << 8) | UInt64(bytes[i])
        }
        
        var loLo: UInt64 = 0
        for i in 24..<32 {
            loLo = (loLo << 8) | UInt64(bytes[i])
        }
        
        return (hiHi, hiLo, loHi, loLo)
    }
    
    private static func stringToData(_ string: String, bitSize: Int, signed: Bool) throws -> Data {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle negative numbers
        let isNegative = trimmed.hasPrefix("-")
        let absoluteString = isNegative ? String(trimmed.dropFirst()) : trimmed
        
        // Validate string contains only digits
        guard !absoluteString.isEmpty, absoluteString.allSatisfy({ $0.isNumber }) else {
            throw StellarSDKError.invalidArgument(message: "Invalid number string: \(string)")
        }
        
        // Special case for "0"
        if absoluteString == "0" {
            let byteSize = bitSize / 8
            return Data(repeating: 0, count: byteSize)
        }
        
        // Convert string to bytes using division method
        var value = Array(absoluteString.utf8).map { $0 - 48 } // Convert ASCII to digits
        var bytes: [UInt8] = []
        
        while !value.isEmpty && !(value.count == 1 && value[0] == 0) {
            var remainder = 0
            var newValue: [UInt8] = []
            
            for digit in value {
                let temp = remainder * 10 + Int(digit)
                newValue.append(UInt8(temp / 256))
                remainder = temp % 256
            }
            
            bytes.insert(UInt8(remainder), at: 0)
            
            // Remove leading zeros
            while !newValue.isEmpty && newValue[0] == 0 {
                newValue.removeFirst()
            }
            value = newValue
        }
        
        // Handle negative numbers using two's complement
        if isNegative && signed {
            // Invert all bits
            bytes = bytes.map { ~$0 }
            
            // Add 1
            var carry = true
            for i in (0..<bytes.count).reversed() {
                if carry {
                    if bytes[i] == 255 {
                        bytes[i] = 0
                    } else {
                        bytes[i] += 1
                        carry = false
                    }
                }
            }
        }
        
        // Always pad to the correct size
        let byteSize = bitSize / 8
        if bytes.count < byteSize {
            let paddingByte: UInt8 = (isNegative && signed) ? 0xFF : 0x00
            let padding = Array(repeating: paddingByte, count: byteSize - bytes.count)
            bytes = padding + bytes
        } else if bytes.count > byteSize {
            // Take only the last byteSize bytes if we have too many
            bytes = Array(bytes.suffix(byteSize))
        }
        
        return Data(bytes)
    }
    
    private static func padData(_ data: Data, targetSize: Int, signed: Bool) -> Data {
        if data.count >= targetSize {
            // Take the last targetSize bytes
            return data.suffix(targetSize)
        }
        
        // Determine padding byte based on sign
        let paddingByte: UInt8
        if signed && !data.isEmpty && (data[0] & 0x80) != 0 {
            // Negative number in two's complement
            paddingByte = 0xFF
        } else {
            paddingByte = 0x00
        }
        
        let padding = Data(repeating: paddingByte, count: targetSize - data.count)
        return padding + data
    }
    
    private static func dataTo128Parts(_ data: Data) -> (hi: UInt64, lo: UInt64) {
        // Ensure data is padded to 16 bytes
        let paddedData = padData(data, targetSize: 16, signed: false)
        let bytes = [UInt8](paddedData)
        
        var hi: UInt64 = 0
        for i in 0..<8 {
            hi = (hi << 8) | UInt64(bytes[i])
        }
        
        var lo: UInt64 = 0
        for i in 8..<16 {
            lo = (lo << 8) | UInt64(bytes[i])
        }
        
        return (hi, lo)
    }
    
    private static func dataTo256Parts(_ data: Data) -> (hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        // Ensure data is padded to 32 bytes
        let paddedData = padData(data, targetSize: 32, signed: false)
        let bytes = [UInt8](paddedData)
        
        var hiHi: UInt64 = 0
        for i in 0..<8 {
            hiHi = (hiHi << 8) | UInt64(bytes[i])
        }
        
        var hiLo: UInt64 = 0
        for i in 8..<16 {
            hiLo = (hiLo << 8) | UInt64(bytes[i])
        }
        
        var loHi: UInt64 = 0
        for i in 16..<24 {
            loHi = (loHi << 8) | UInt64(bytes[i])
        }
        
        var loLo: UInt64 = 0
        for i in 24..<32 {
            loLo = (loLo << 8) | UInt64(bytes[i])
        }
        
        return (hiHi, hiLo, loHi, loLo)
    }
    
    private static func partsToData128(hi: UInt64, lo: UInt64) -> Data {
        var bytes: [UInt8] = []
        
        // Convert hi to bytes (big-endian)
        for i in (0..<8).reversed() {
            bytes.append(UInt8((hi >> (i * 8)) & 0xFF))
        }
        
        // Convert lo to bytes (big-endian)
        for i in (0..<8).reversed() {
            bytes.append(UInt8((lo >> (i * 8)) & 0xFF))
        }
        
        return Data(bytes)
    }
    
    private static func partsToData256(hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) -> Data {
        var bytes: [UInt8] = []
        
        // Convert each part to bytes (big-endian)
        for value in [hiHi, hiLo, loHi, loLo] {
            for i in (0..<8).reversed() {
                bytes.append(UInt8((value >> (i * 8)) & 0xFF))
            }
        }
        
        return Data(bytes)
    }
    
    private static func stringFromData(_ data: Data, signed: Bool) -> String {
        let bytes = [UInt8](data)
        
        // Check if negative (for signed types)
        let isNegative = signed && !bytes.isEmpty && (bytes[0] & 0x80) != 0
        
        var workingBytes = bytes
        
        if isNegative {
            // Convert from two's complement
            // Subtract 1
            var borrow = true
            for i in (0..<workingBytes.count).reversed() {
                if borrow {
                    if workingBytes[i] == 0 {
                        workingBytes[i] = 0xFF
                    } else {
                        workingBytes[i] -= 1
                        borrow = false
                    }
                }
            }
            
            // Invert all bits
            workingBytes = workingBytes.map { ~$0 }
        }
        
        // Convert bytes to decimal string
        var result = [0]
        
        for byte in workingBytes {
            // Multiply result by 256 and add byte
            var carry = Int(byte)
            for i in (0..<result.count).reversed() {
                let temp = result[i] * 256 + carry
                result[i] = temp % 10
                carry = temp / 10
            }
            
            while carry > 0 {
                result.insert(carry % 10, at: 0)
                carry /= 10
            }
        }
        
        // Remove leading zeros
        while result.count > 1 && result[0] == 0 {
            result.removeFirst()
        }
        
        // Convert to string
        let numberString = result.map { String($0) }.joined()
        return isNegative ? "-" + numberString : numberString
    }
}
