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
    case error = 2
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
    case address = 18
    case contractInstance = 19
    case ledgerKeyContractInstance = 20
    case ledgerKeyNonce = 21
}

public enum SCErrorType: Int32 {
    case contract = 0
    case wasmVm = 1
    case context = 2
    case storage = 3
    case object = 4
    case crypto = 5
    case events = 6
    case budget = 7
    case value = 8
    case auth = 9
}

public enum SCErrorCode: Int32 {
    case arithDomain = 0
    case indexBounds = 1
    case invalidInput = 2
    case missingValue = 3
    case existingValue = 4
    case exceededLimit = 5
    case invalidAction = 6
    case internalError = 7
    case unexpectedType = 8
    case unexpectedSize = 9
}

public enum ContractCostType: Int32 {
    case wasmInsnExec = 0
    case memAlloc = 1
    case memCpy = 2
    case memCmp = 3
    case dispatchHostFunction = 4
    case visitObject = 5
    case valSer = 6
    case valDeser = 7
    case computeSha256Hash = 8
    case computeEd25519PubKey = 9
    case verifyEd25519Sig = 10
    case vmInstantiation = 11
    case vmCachedInstantiation = 12
    case invokeVmFunction = 13
    case computeKeccak256Hash = 14
    case decodeEcdsaCurve256Sig = 15
    case recoverEcdsaSecp256k1Key = 16
    case int256AddSub = 17
    case int256Mul = 18
    case int256Div = 19
    case int256Pow = 20
    case int256Shift = 21
    case chaCha20DrawBytes = 22
    case parseWasmInstructions = 23
    // Cost of parsing a known number of wasm functions.
    case parseWasmFunctions = 24
    // Cost of parsing a known number of wasm globals.
    case parseWasmGlobals = 25
    // Cost of parsing a known number of wasm table entries.
    case parseWasmTableEntries = 26
    // Cost of parsing a known number of wasm types.
    case parseWasmTypes = 27
    // Cost of parsing a known number of wasm data segments.
    case parseWasmDataSegments = 28
    // Cost of parsing a known number of wasm element segments.
    case parseWasmElemSegments = 29
    // Cost of parsing a known number of wasm imports.
    case parseWasmImports = 30
    // Cost of parsing a known number of wasm exports.
    case parseWasmExports = 31
    // Cost of parsing a known number of data segment bytes.
    case parseWasmDataSegmentBytes = 32
    // Cost of instantiating wasm bytes that only encode instructions.
    case instantiateWasmInstructions = 33
    // Cost of instantiating a known number of wasm functions.
    case instantiateWasmFunctions = 34
    // Cost of instantiating a known number of wasm globals.
    case instantiateWasmGlobals = 35
    // Cost of instantiating a known number of wasm table entries.
    case instantiateWasmTableEntries = 36
    // Cost of instantiating a known number of wasm types.
    case instantiateWasmTypes = 37
    // Cost of instantiating a known number of wasm data segments.
    case instantiateWasmDataSegments = 38
    // Cost of instantiating a known number of wasm element segments.
    case instantiateWasmElemSegments = 39
    // Cost of instantiating a known number of wasm imports.
    case instantiateWasmImports = 40
    // Cost of instantiating a known number of wasm exports.
    case instantiateWasmExports = 41
    // Cost of instantiating a known number of data segment bytes.
    case instantiateWasmDataSegmentBytes = 42
    // Cost of decoding a bytes array representing an uncompressed SEC-1 encoded
    // point on a 256-bit elliptic curve
    case sec1DecodePointUncompressed = 43
    // Cost of verifying an ECDSA Secp256r1 signature
    case verifyEcdsaSecp256r1Sig = 44
    // Cost of encoding a BLS12-381 Fp (base field element)
    case bls12381EncodeFp = 45
    // Cost of decoding a BLS12-381 Fp (base field element)
    case bls12381DecodeFp = 46
    // Cost of checking a G1 point lies on the curve
    case bls12381G1CheckPointOnCurve = 47
    // Cost of checking a G1 point belongs to the correct subgroup
    case bls12381G1CheckPointInSubgroup = 48
    // Cost of checking a G2 point lies on the curve
    case bls12381G2CheckPointOnCurve = 49
    // Cost of checking a G2 point belongs to the correct subgroup
    case bls12381G2CheckPointInSubgroup = 50
    // Cost of converting a BLS12-381 G1 point from projective to affine coordinates
    case bls12381G1ProjectiveToAffine = 51
    // Cost of converting a BLS12-381 G2 point from projective to affine coordinates
    case bls12381G2ProjectiveToAffine = 52
    // Cost of performing BLS12-381 G1 point addition
    case bls12381G1Add = 53
    // Cost of performing BLS12-381 G1 scalar multiplication
    case bls12381G1Mul = 54
    // Cost of performing BLS12-381 G1 multi-scalar multiplication (MSM)
    case bls12381G1Msm = 55
    // Cost of mapping a BLS12-381 Fp field element to a G1 point
    case bls12381MapFpToG1 = 56
    // Cost of hashing to a BLS12-381 G1 point
    case bls12381HashToG1 = 57
    // Cost of performing BLS12-381 G2 point addition
    case bls12381G2Add = 58
    // Cost of performing BLS12-381 G2 scalar multiplication
    case bls12381G2Mul = 59
    // Cost of performing BLS12-381 G2 multi-scalar multiplication (MSM)
    case bls12381G2Msm = 60
    // Cost of mapping a BLS12-381 Fp2 field element to a G2 point
    case bls12381MapFp2ToG2 = 61
    // Cost of hashing to a BLS12-381 G2 point
    case bls12381HashToG2 = 62
    // Cost of performing BLS12-381 pairing operation
    case bls12381Pairing = 63
    // Cost of converting a BLS12-381 scalar element from U256
    case bls12381FrFromU256 = 64
    // Cost of converting a BLS12-381 scalar element to U256
    case bls12381FrToU256 = 65
    // Cost of performing BLS12-381 scalar element addition/subtraction
    case bls12381FrAddSub = 66
    // Cost of performing BLS12-381 scalar element multiplication
    case bls12381FrMul = 67
    // Cost of performing BLS12-381 scalar element exponentiation
    case bls12381FrPow = 68
    // Cost of performing BLS12-381 scalar element inversion
    case bls12381FrInv = 69

}

public enum SCErrorXDR: XDRCodable {

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

public enum SCAddressType: Int32 {
    case account = 0
    case contract = 1
    case muxedAccount = 2
    case claimableBalance = 3
    case liquidityPool = 4
}

public enum SCAddressXDR: XDRCodable {
    case account(PublicKey)
    case contract(WrappedData32)
    case muxedAccount(MuxedAccountMed25519XDR)
    case claimableBalanceId(ClaimableBalanceIDXDR)
    case liquidityPoolId(LiquidityPoolIDXDR)
    
    public init(accountId: String) throws {
        if accountId.hasPrefix("G") {
            self = .account(try PublicKey(accountId: accountId))
            return
        } else if accountId.hasPrefix("M") {
            let muxl = try accountId.decodeMuxedAccount()
            switch muxl {
            case .med25519(let inner):
                self = .muxedAccount(inner)
                return
            default:
                break
            }
        }
        throw StellarSDKError.encodingError(message: "error xdr encoding SCAddressXDR, invalid account id")
    }
    
    public init(contractId: String) throws {
        var contractIdHex = contractId
        if contractId.hasPrefix("C") {
            contractIdHex = try contractId.decodeContractIdToHex()
        }
        if let contractIdData = contractIdHex.data(using: .hexadecimal) {
            self = .contract(WrappedData32(contractIdData))
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding SCAddressXDR, invalid contract id")
        }
    }
    
    public init(claimableBalanceId: String) throws {
        var claimableBalanceIdHex = claimableBalanceId
        if claimableBalanceId.hasPrefix("B") {
            claimableBalanceIdHex = try claimableBalanceId.decodeClaimableBalanceIdToHex()
        }
        if let _ = claimableBalanceIdHex.data(using: .hexadecimal) {
            let value = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(claimableBalanceIdHex.wrappedData32FromHex())
            self = .claimableBalanceId(value)
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding SCAddressXDR, invalid claimable balance id")
        }
    }
    
    public init(liquidityPoolId: String) throws {
        var liquidityPoolIdHex = liquidityPoolId
        if liquidityPoolId.hasPrefix("L") {
            liquidityPoolIdHex = try liquidityPoolId.decodeLiquidityPoolIdToHex()
        }
        if let _ = liquidityPoolIdHex.data(using: .hexadecimal) {
            let value = LiquidityPoolIDXDR(id: liquidityPoolIdHex.wrappedData32FromHex())
            self = .liquidityPoolId(value)
        } else {
            throw StellarSDKError.encodingError(message: "error xdr encoding SCAddressXDR, invalid liquidity pool id")
        }
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = SCAddressType(rawValue: discriminant)
        
        switch type {
        case .account:
            let account = try container.decode(PublicKey.self)
            self = .account(account)
        case .contract:
            let contract = try container.decode(WrappedData32.self)
            self = .contract(contract)
        case .muxedAccount:
            let muxedAccount = try container.decode(MuxedAccountMed25519XDR.self)
            self = .muxedAccount(muxedAccount)
        case .claimableBalance:
            let claimableBalanceId = try container.decode(ClaimableBalanceIDXDR.self)
            self = .claimableBalanceId(claimableBalanceId)
        case .liquidityPool:
            let liquidityPoolId = try container.decode(LiquidityPoolIDXDR.self)
            self = .liquidityPoolId(liquidityPoolId)
        case .none:
            throw StellarSDKError.decodingError(message: "invaid SCAddressXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .account: return SCAddressType.account.rawValue
        case .contract: return SCAddressType.contract.rawValue
        case .muxedAccount: return SCAddressType.muxedAccount.rawValue
        case .claimableBalanceId: return SCAddressType.claimableBalance.rawValue
        case .liquidityPoolId: return SCAddressType.liquidityPool.rawValue
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
        case .muxedAccount(let muxedAccount):
            try container.encode(muxedAccount)
            break
        case .claimableBalanceId(let claimableBalanceId):
            try container.encode(claimableBalanceId)
            break
        case .liquidityPoolId(let liquidityPoolId):
            try container.encode(liquidityPoolId)
            break
        }
    }
    
    public var accountId:String? {
        switch self {
        case .account(let pk):
            return pk.accountId
        case .muxedAccount(let xdr):
            if !xdr.accountId.isEmpty {
                return xdr.accountId
            }
            return nil
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
    
    public var claimableBalanceId:String? {
        switch self {
        case .claimableBalanceId(let xdr):
            return xdr.claimableBalanceIdString
        default:
            return nil
        }
    }
    
    public var liquidityPoolId:String? {
        switch self {
        case .liquidityPoolId(let xdr):
            return xdr.poolIDString
        default:
            return nil
        }
    }
}

public struct SCNonceKeyXDR: XDRCodable {
    public let nonce: Int64
    
    public init(nonce:Int64) {
        self.nonce = nonce
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        nonce = try container.decode(Int64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(nonce)
    }
}

public enum SCValXDR: XDRCodable {

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

public enum ContractExecutableType: Int32 {
    case wasm = 0
    case stellarAsset = 1
}

public enum ContractExecutableXDR: XDRCodable {
    case wasm(WrappedData32)
    case token
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let discriminant = try container.decode(Int32.self)
        let type = ContractExecutableType(rawValue: discriminant)
        
        switch type {
        case .wasm:
            let wasmHash = try container.decode(WrappedData32.self)
            self = .wasm(wasmHash)
        case .stellarAsset:
            self = .token
        case .none:
            throw StellarSDKError.decodingError(message: "invaid ContractExecutableXDR discriminant")
        }
    }
    
    public func type() -> Int32 {
        switch self {
        case .wasm: return ContractExecutableType.wasm.rawValue
        case .token: return ContractExecutableType.stellarAsset.rawValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(type())
        switch self {
        case .wasm (let wasmHash):
            try container.encode(wasmHash)
            break
        case .token:
            break
        }
    }
    
    public var isWasm:Bool? {
        return type() == ContractExecutableType.wasm.rawValue
    }
    
    public var wasm:WrappedData32? {
        switch self {
        case .wasm(let val):
            return val
        default:
            return nil
        }
    }
    
    public var isStellarAsset:Bool? {
        return type() == ContractExecutableType.stellarAsset.rawValue
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

public struct SCContractInstanceXDR: XDRCodable {
    public let executable: ContractExecutableXDR
    public let storage: [SCMapEntryXDR]?
    
    public init(executable: ContractExecutableXDR, storage: [SCMapEntryXDR]?) {
        self.executable = executable
        self.storage = storage
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        executable = try container.decode(ContractExecutableXDR.self)
        let present = try container.decode(Int32.self) == 1
        if (present) {
            storage = try decodeArray(type: SCMapEntryXDR.self, dec: decoder)
        } else {
            storage = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(executable)
        if let sm = storage {
            try container.encode(Int32(1))
            try container.encode(sm)
        }
        else {
            try container.encode(Int32(0))
        }
    }
}
