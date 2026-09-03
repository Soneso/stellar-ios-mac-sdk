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

    public var isExecutableTag: Bool {
        return type() == SCValType.executableTag.rawValue
    }

    @available(*, deprecated, renamed: "executableTagString")
    public var executableTag: String? {
        switch self {
        case .executableTag(let val):
            return String(data: val, encoding: .utf8)
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
        try XdrWideInteger.parts128(fromDecimalString: string, signed: signed)
    }

    private static func bigInt256Parts(from string: String, signed: Bool) throws -> (hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        try XdrWideInteger.parts256(fromDecimalString: string, signed: signed)
    }

    private static func padData(_ data: Data, targetSize: Int, signed: Bool) -> Data {
        XdrWideInteger.pad(data, targetSize: targetSize, signed: signed)
    }

    private static func dataTo128Parts(_ data: Data) -> (hi: UInt64, lo: UInt64) {
        XdrWideInteger.parts128(from: data)
    }

    private static func dataTo256Parts(_ data: Data) -> (hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) {
        XdrWideInteger.parts256(from: data)
    }

    private static func partsToData128(hi: UInt64, lo: UInt64) -> Data {
        XdrWideInteger.data128(hi: hi, lo: lo)
    }

    private static func partsToData256(hiHi: UInt64, hiLo: UInt64, loHi: UInt64, loLo: UInt64) -> Data {
        XdrWideInteger.data256(hiHi: hiHi, hiLo: hiLo, loHi: loHi, loLo: loLo)
    }

    private static func stringFromData(_ data: Data, signed: Bool) -> String {
        XdrWideInteger.decimalString(from: data, signed: signed)
    }
}

// MARK: - Native Swift Value Conversion

extension SCValXDR {

    /// Converts this contract value to native Swift values, as far as one exists for it.
    ///
    /// The conversion walks the whole value tree and never throws:
    /// - `bool`, `u32`, `i32`, `u64`, `i64`, `timepoint` and `duration` become their
    ///   exact width Swift counterpart, `void` becomes nil
    /// - `u128`, `i128`, `u256` and `i256` become their decimal `String`
    /// - `address` becomes its strkey `String`
    /// - `bytes` becomes `Data`, `string` and `symbol` become `String`
    /// - `vec` becomes `[Any?]` in element order, `map` becomes `[AnyHashable: Any?]`
    ///
    /// A value with no native counterpart comes back as the `SCValXDR` itself, which a
    /// caller tells apart with `is SCValXDR`: the `error`, `contractInstance`,
    /// `ledgerKeyContractInstance`, `ledgerKeyNonce` and `executableTag` arms, an address
    /// whose bytes have no strkey encoding, and a map that no Swift dictionary holds.
    ///
    /// A map converts as a whole or not at all. It falls back when a key has no `Hashable`
    /// counterpart (a `void`, `vec` or `map` key, a key of one of the arms listed above,
    /// or an address key with no strkey), and when two of its keys turn out equal. Keys
    /// compare as `AnyHashable`, which reads the fixed width integers as one number, so a
    /// `u32` key and a `u64` key of the same value are equal and collide. A 128 or 256 bit
    /// key and the `symbol` of the same digits collide too, since the wide key is its
    /// decimal `String`. A dictionary carries no ordering, so the entry order of the map
    /// is not preserved.
    ///
    /// - Returns: the native value, nil for `void`, or the `SCValXDR` itself where no
    /// native representation exists
    public func toNative() -> Any? {
        switch self {
        case .bool(let value):
            return value
        case .void:
            return nil
        case .error:
            return self
        case .u32(let value):
            return value
        case .i32(let value):
            return value
        case .u64(let value):
            return value
        case .i64(let value):
            return value
        case .timepoint(let value):
            return value
        case .duration(let value):
            return value
        case .u128:
            return u128String
        case .i128:
            return i128String
        case .u256:
            return u256String
        case .i256:
            return i256String
        case .bytes(let value):
            return value
        case .string(let value):
            return value
        case .symbol(let value):
            return value
        case .vec(let values):
            return (values ?? []).map { $0.toNative() }
        case .map(let entries):
            guard let converted = Self.mapToNative(entries ?? []) else { return self }
            return converted
        case .address(let address):
            do {
                return try address.toStrKey()
            } catch {
                return self
            }
        case .contractInstance:
            return self
        case .ledgerKeyContractInstance:
            return self
        case .ledgerKeyNonce:
            return self
        case .executableTag:
            return self
        }
    }

    /// The dictionary the given map entries make, nil when no dictionary holds them.
    ///
    /// Entries are taken in order and stored with `updateValue(_:forKey:)`, which keeps an
    /// entry whose value converts to nil. A key with no dictionary form leaves the map
    /// unconverted, and so does a pair of keys that turn out equal, which the count of the
    /// dictionary reports: the later entry takes the place of the earlier one.
    private static func mapToNative(_ entries: [SCMapEntryXDR]) -> [AnyHashable: Any?]? {
        var converted: [AnyHashable: Any?] = [:]
        converted.reserveCapacity(entries.count)
        for entry in entries {
            guard let key = mapKeyToNative(entry.key) else { return nil }
            converted.updateValue(entry.val.toNative(), forKey: key)
        }
        guard converted.count == entries.count else { return nil }
        return converted
    }

    /// The dictionary key the given map key spells, nil when no `Hashable` value spells it.
    ///
    /// Keys take the conversion of the values wherever `Hashable` allows it, so addresses
    /// read as their strkey and byte keys stay `Data`. The arms that carry no key are
    /// named one by one, so an arm added later has to be placed here before this file
    /// compiles again.
    private static func mapKeyToNative(_ key: SCValXDR) -> AnyHashable? {
        switch key {
        case .bool(let value):
            return value
        case .u32(let value):
            return value
        case .i32(let value):
            return value
        case .u64(let value):
            return value
        case .i64(let value):
            return value
        case .timepoint(let value):
            return value
        case .duration(let value):
            return value
        case .u128:
            return key.u128String
        case .i128:
            return key.i128String
        case .u256:
            return key.u256String
        case .i256:
            return key.i256String
        case .bytes(let value):
            return value
        case .string(let value):
            return value
        case .symbol(let value):
            return value
        case .address(let address):
            do {
                return try address.toStrKey()
            } catch {
                return nil
            }
        case .void, .error, .vec, .map, .contractInstance, .ledgerKeyContractInstance,
             .ledgerKeyNonce, .executableTag:
            return nil
        }
    }
}
