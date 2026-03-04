//
//  SCValXDR+Helpers.swift
//  stellarsdk
//
//  Convenience initializers, computed properties, and BigInt support
//  preserved from the original hand-written SCValXDR implementation.
//

import Foundation

// MARK: - Convenience Initializers and Computed Properties

extension SCValXDR {

    public init(accountEd25519Signature: AccountEd25519Signature) {
        let pkBytes = Data(accountEd25519Signature.publicKey.bytes)
        let sigBytes = Data(accountEd25519Signature.signature)
        let pkMapEntry = SCMapEntryXDR(key: SCValXDR.symbol("public_key"), val: SCValXDR.bytes(pkBytes))
        let sigMapEntry = SCMapEntryXDR(key: SCValXDR.symbol("signature"), val: SCValXDR.bytes(sigBytes))
        self = .map([pkMapEntry,sigMapEntry])
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

        let isNegative = trimmed.hasPrefix("-")
        let absoluteString = isNegative ? String(trimmed.dropFirst()) : trimmed

        guard !absoluteString.isEmpty, absoluteString.allSatisfy({ $0.isNumber }) else {
            throw StellarSDKError.invalidArgument(message: "Invalid number string: \(string)")
        }

        if absoluteString == "0" {
            let byteSize = bitSize / 8
            return Data(repeating: 0, count: byteSize)
        }

        var value = Array(absoluteString.utf8).map { $0 - 48 }
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

            while !newValue.isEmpty && newValue[0] == 0 {
                newValue.removeFirst()
            }
            value = newValue
        }

        if isNegative && signed {
            bytes = bytes.map { ~$0 }

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

        let byteSize = bitSize / 8
        if bytes.count < byteSize {
            let paddingByte: UInt8 = (isNegative && signed) ? 0xFF : 0x00
            let padding = Array(repeating: paddingByte, count: byteSize - bytes.count)
            bytes = padding + bytes
        } else if bytes.count > byteSize {
            bytes = Array(bytes.suffix(byteSize))
        }

        return Data(bytes)
    }

    private static func padData(_ data: Data, targetSize: Int, signed: Bool) -> Data {
        if data.count >= targetSize {
            return data.suffix(targetSize)
        }

        let paddingByte: UInt8
        if signed && !data.isEmpty && (data[0] & 0x80) != 0 {
            paddingByte = 0xFF
        } else {
            paddingByte = 0x00
        }

        let padding = Data(repeating: paddingByte, count: targetSize - data.count)
        return padding + data
    }

    private static func dataTo128Parts(_ data: Data) -> (hi: UInt64, lo: UInt64) {
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

        for i in (0..<8).reversed() {
            bytes.append(UInt8((hi >> (i * 8)) & 0xFF))
        }

        for i in (0..<8).reversed() {
            bytes.append(UInt8((lo >> (i * 8)) & 0xFF))
        }

        return Data(bytes)
    }

    private static func partsToData256(hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) -> Data {
        var bytes: [UInt8] = []

        for value in [hiHi, hiLo, loHi, loLo] {
            for i in (0..<8).reversed() {
                bytes.append(UInt8((value >> (i * 8)) & 0xFF))
            }
        }

        return Data(bytes)
    }

    private static func stringFromData(_ data: Data, signed: Bool) -> String {
        let bytes = [UInt8](data)

        let isNegative = signed && !bytes.isEmpty && (bytes[0] & 0x80) != 0

        var workingBytes = bytes

        if isNegative {
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

            workingBytes = workingBytes.map { ~$0 }
        }

        var result = [0]

        for byte in workingBytes {
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

        while result.count > 1 && result[0] == 0 {
            result.removeFirst()
        }

        let numberString = result.map { String($0) }.joined()
        return isNegative ? "-" + numberString : numberString
    }
}
