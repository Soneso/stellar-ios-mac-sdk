//
//  XDRContractTypesUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class XDRContractTypesUnitTests: XCTestCase {

    // MARK: - SCValType Enum Roundtrip Tests

    func testSCValTypeAllCasesRoundTrip() throws {
        let allCases: [SCValType] = [
            .bool, .void, .error, .u32, .i32, .u64, .i64,
            .timepoint, .duration, .u128, .i128, .u256, .i256,
            .bytes, .string, .symbol, .vec, .map, .address,
            .contractInstance, .ledgerKeyContractInstance, .ledgerKeyNonce
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCValType.self, data: encoded)
            XCTAssertEqual(original, decoded, "SCValType roundtrip failed for \(original)")
        }
    }

    func testSCValTypeRawValues() {
        XCTAssertEqual(SCValType.bool.rawValue, 0)
        XCTAssertEqual(SCValType.void.rawValue, 1)
        XCTAssertEqual(SCValType.error.rawValue, 2)
        XCTAssertEqual(SCValType.u32.rawValue, 3)
        XCTAssertEqual(SCValType.i32.rawValue, 4)
        XCTAssertEqual(SCValType.u64.rawValue, 5)
        XCTAssertEqual(SCValType.i64.rawValue, 6)
        XCTAssertEqual(SCValType.timepoint.rawValue, 7)
        XCTAssertEqual(SCValType.duration.rawValue, 8)
        XCTAssertEqual(SCValType.u128.rawValue, 9)
        XCTAssertEqual(SCValType.i128.rawValue, 10)
        XCTAssertEqual(SCValType.u256.rawValue, 11)
        XCTAssertEqual(SCValType.i256.rawValue, 12)
        XCTAssertEqual(SCValType.bytes.rawValue, 13)
        XCTAssertEqual(SCValType.string.rawValue, 14)
        XCTAssertEqual(SCValType.symbol.rawValue, 15)
        XCTAssertEqual(SCValType.vec.rawValue, 16)
        XCTAssertEqual(SCValType.map.rawValue, 17)
        XCTAssertEqual(SCValType.address.rawValue, 18)
        XCTAssertEqual(SCValType.contractInstance.rawValue, 19)
        XCTAssertEqual(SCValType.ledgerKeyContractInstance.rawValue, 20)
        XCTAssertEqual(SCValType.ledgerKeyNonce.rawValue, 21)
    }

    // MARK: - SCErrorType Enum Roundtrip Tests

    func testSCErrorTypeAllCasesRoundTrip() throws {
        let allCases: [SCErrorType] = [
            .contract, .wasmVm, .context, .storage, .object,
            .crypto, .events, .budget, .value, .auth
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCErrorType.self, data: encoded)
            XCTAssertEqual(original, decoded, "SCErrorType roundtrip failed for \(original)")
        }
    }

    func testSCErrorTypeRawValues() {
        XCTAssertEqual(SCErrorType.contract.rawValue, 0)
        XCTAssertEqual(SCErrorType.wasmVm.rawValue, 1)
        XCTAssertEqual(SCErrorType.context.rawValue, 2)
        XCTAssertEqual(SCErrorType.storage.rawValue, 3)
        XCTAssertEqual(SCErrorType.object.rawValue, 4)
        XCTAssertEqual(SCErrorType.crypto.rawValue, 5)
        XCTAssertEqual(SCErrorType.events.rawValue, 6)
        XCTAssertEqual(SCErrorType.budget.rawValue, 7)
        XCTAssertEqual(SCErrorType.value.rawValue, 8)
        XCTAssertEqual(SCErrorType.auth.rawValue, 9)
    }

    // MARK: - SCErrorCode Enum Roundtrip Tests

    func testSCErrorCodeAllCasesRoundTrip() throws {
        let allCases: [SCErrorCode] = [
            .arithDomain, .indexBounds, .invalidInput, .missingValue,
            .existingValue, .exceededLimit, .invalidAction,
            .internalError, .unexpectedType, .unexpectedSize
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCErrorCode.self, data: encoded)
            XCTAssertEqual(original, decoded, "SCErrorCode roundtrip failed for \(original)")
        }
    }

    func testSCErrorCodeRawValues() {
        XCTAssertEqual(SCErrorCode.arithDomain.rawValue, 0)
        XCTAssertEqual(SCErrorCode.indexBounds.rawValue, 1)
        XCTAssertEqual(SCErrorCode.invalidInput.rawValue, 2)
        XCTAssertEqual(SCErrorCode.missingValue.rawValue, 3)
        XCTAssertEqual(SCErrorCode.existingValue.rawValue, 4)
        XCTAssertEqual(SCErrorCode.exceededLimit.rawValue, 5)
        XCTAssertEqual(SCErrorCode.invalidAction.rawValue, 6)
        XCTAssertEqual(SCErrorCode.internalError.rawValue, 7)
        XCTAssertEqual(SCErrorCode.unexpectedType.rawValue, 8)
        XCTAssertEqual(SCErrorCode.unexpectedSize.rawValue, 9)
    }

    // MARK: - ContractExecutableType Enum Roundtrip Tests

    func testContractExecutableTypeAllCasesRoundTrip() throws {
        let allCases: [ContractExecutableType] = [.wasm, .stellarAsset]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(ContractExecutableType.self, data: encoded)
            XCTAssertEqual(original, decoded, "ContractExecutableType roundtrip failed for \(original)")
        }
    }

    func testContractExecutableTypeRawValues() {
        XCTAssertEqual(ContractExecutableType.wasm.rawValue, 0)
        XCTAssertEqual(ContractExecutableType.stellarAsset.rawValue, 1)
    }

    // MARK: - SCAddressType Enum Roundtrip Tests

    func testSCAddressTypeAllCasesRoundTrip() throws {
        let allCases: [SCAddressType] = [
            .account, .contract, .muxedAccount, .claimableBalance, .liquidityPool
        ]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCAddressType.self, data: encoded)
            XCTAssertEqual(original, decoded, "SCAddressType roundtrip failed for \(original)")
        }
    }

    func testSCAddressTypeRawValues() {
        XCTAssertEqual(SCAddressType.account.rawValue, 0)
        XCTAssertEqual(SCAddressType.contract.rawValue, 1)
        XCTAssertEqual(SCAddressType.muxedAccount.rawValue, 2)
        XCTAssertEqual(SCAddressType.claimableBalance.rawValue, 3)
        XCTAssertEqual(SCAddressType.liquidityPool.rawValue, 4)
    }

    // MARK: - SCErrorXDR Union Tests (detailed code extraction)

    func testSCErrorXDRContractCodeExtraction() throws {
        let original = SCErrorXDR.contract(99999)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.contract.rawValue)
        if case .contract(let code) = decoded {
            XCTAssertEqual(code, 99999)
        } else {
            XCTFail("Expected .contract arm")
        }
    }

    func testSCErrorXDRWasmVmCodeExtraction() throws {
        let original = SCErrorXDR.wasmVm(.exceededLimit)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.wasmVm.rawValue)
        if case .wasmVm(let code) = decoded {
            XCTAssertEqual(code, .exceededLimit)
        } else {
            XCTFail("Expected .wasmVm arm")
        }
    }

    func testSCErrorXDRContextCodeExtraction() throws {
        let original = SCErrorXDR.context(.unexpectedType)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.context.rawValue)
        if case .context(let code) = decoded {
            XCTAssertEqual(code, .unexpectedType)
        } else {
            XCTFail("Expected .context arm")
        }
    }

    func testSCErrorXDRStorageCodeExtraction() throws {
        let original = SCErrorXDR.storage(.missingValue)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.storage.rawValue)
        if case .storage(let code) = decoded {
            XCTAssertEqual(code, .missingValue)
        } else {
            XCTFail("Expected .storage arm")
        }
    }

    func testSCErrorXDRObjectCodeExtraction() throws {
        let original = SCErrorXDR.object(.invalidAction)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.object.rawValue)
        if case .object(let code) = decoded {
            XCTAssertEqual(code, .invalidAction)
        } else {
            XCTFail("Expected .object arm")
        }
    }

    func testSCErrorXDRCryptoCodeExtraction() throws {
        let original = SCErrorXDR.crypto(.internalError)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.crypto.rawValue)
        if case .crypto(let code) = decoded {
            XCTAssertEqual(code, .internalError)
        } else {
            XCTFail("Expected .crypto arm")
        }
    }

    func testSCErrorXDREventsCodeExtraction() throws {
        let original = SCErrorXDR.events(.unexpectedSize)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.events.rawValue)
        if case .events(let code) = decoded {
            XCTAssertEqual(code, .unexpectedSize)
        } else {
            XCTFail("Expected .events arm")
        }
    }

    func testSCErrorXDRBudgetCodeExtraction() throws {
        let original = SCErrorXDR.budget(.exceededLimit)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.budget.rawValue)
        if case .budget(let code) = decoded {
            XCTAssertEqual(code, .exceededLimit)
        } else {
            XCTFail("Expected .budget arm")
        }
    }

    func testSCErrorXDRValueCodeExtraction() throws {
        let original = SCErrorXDR.value(.indexBounds)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.value.rawValue)
        if case .value(let code) = decoded {
            XCTAssertEqual(code, .indexBounds)
        } else {
            XCTFail("Expected .value arm")
        }
    }

    func testSCErrorXDRAuthCodeExtraction() throws {
        let original = SCErrorXDR.auth(.existingValue)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCErrorType.auth.rawValue)
        if case .auth(let code) = decoded {
            XCTAssertEqual(code, .existingValue)
        } else {
            XCTFail("Expected .auth arm")
        }
    }

    // MARK: - UInt128PartsXDR Boundary Tests

    func testUInt128PartsXDRMaxValues() throws {
        let original = UInt128PartsXDR(hi: UInt64.max, lo: UInt64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(UInt128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, UInt64.max)
        XCTAssertEqual(decoded.lo, UInt64.max)
    }

    func testUInt128PartsXDRZeroValues() throws {
        let original = UInt128PartsXDR(hi: 0, lo: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(UInt128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, 0)
        XCTAssertEqual(decoded.lo, 0)
    }

    func testUInt128PartsXDRMixedValues() throws {
        let original = UInt128PartsXDR(hi: 0xDEADBEEFCAFEBABE, lo: 0x0123456789ABCDEF)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(UInt128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, 0xDEADBEEFCAFEBABE)
        XCTAssertEqual(decoded.lo, 0x0123456789ABCDEF)
    }

    // MARK: - Int128PartsXDR Boundary Tests

    func testInt128PartsXDRMaxValues() throws {
        let original = Int128PartsXDR(hi: Int64.max, lo: UInt64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Int128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, Int64.max)
        XCTAssertEqual(decoded.lo, UInt64.max)
    }

    func testInt128PartsXDRMinValues() throws {
        let original = Int128PartsXDR(hi: Int64.min, lo: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Int128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, Int64.min)
        XCTAssertEqual(decoded.lo, 0)
    }

    func testInt128PartsXDRNegativeOne() throws {
        // -1 in two's complement: hi = -1, lo = max
        let original = Int128PartsXDR(hi: -1, lo: UInt64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Int128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, -1)
        XCTAssertEqual(decoded.lo, UInt64.max)
    }

    // MARK: - UInt256PartsXDR Boundary Tests

    func testUInt256PartsXDRMaxValues() throws {
        let original = UInt256PartsXDR(
            hiHi: UInt64.max, hiLo: UInt64.max,
            loHi: UInt64.max, loLo: UInt64.max
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(UInt256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, UInt64.max)
        XCTAssertEqual(decoded.hiLo, UInt64.max)
        XCTAssertEqual(decoded.loHi, UInt64.max)
        XCTAssertEqual(decoded.loLo, UInt64.max)
    }

    func testUInt256PartsXDRZeroValues() throws {
        let original = UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(UInt256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, 0)
        XCTAssertEqual(decoded.hiLo, 0)
        XCTAssertEqual(decoded.loHi, 0)
        XCTAssertEqual(decoded.loLo, 0)
    }

    func testUInt256PartsXDRDistinctValues() throws {
        let original = UInt256PartsXDR(
            hiHi: 0x1111111111111111, hiLo: 0x2222222222222222,
            loHi: 0x3333333333333333, loLo: 0x4444444444444444
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(UInt256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, 0x1111111111111111)
        XCTAssertEqual(decoded.hiLo, 0x2222222222222222)
        XCTAssertEqual(decoded.loHi, 0x3333333333333333)
        XCTAssertEqual(decoded.loLo, 0x4444444444444444)
    }

    // MARK: - Int256PartsXDR Boundary Tests

    func testInt256PartsXDRMaxValues() throws {
        let original = Int256PartsXDR(
            hiHi: Int64.max, hiLo: UInt64.max,
            loHi: UInt64.max, loLo: UInt64.max
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Int256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, Int64.max)
        XCTAssertEqual(decoded.hiLo, UInt64.max)
        XCTAssertEqual(decoded.loHi, UInt64.max)
        XCTAssertEqual(decoded.loLo, UInt64.max)
    }

    func testInt256PartsXDRMinValues() throws {
        let original = Int256PartsXDR(hiHi: Int64.min, hiLo: 0, loHi: 0, loLo: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Int256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, Int64.min)
        XCTAssertEqual(decoded.hiLo, 0)
        XCTAssertEqual(decoded.loHi, 0)
        XCTAssertEqual(decoded.loLo, 0)
    }

    func testInt256PartsXDRNegativeOne() throws {
        let original = Int256PartsXDR(
            hiHi: -1, hiLo: UInt64.max,
            loHi: UInt64.max, loLo: UInt64.max
        )
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(Int256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, -1)
        XCTAssertEqual(decoded.hiLo, UInt64.max)
        XCTAssertEqual(decoded.loHi, UInt64.max)
        XCTAssertEqual(decoded.loLo, UInt64.max)
    }

    // MARK: - ContractExecutableXDR Union Tests

    func testContractExecutableXDRWasmRoundTrip() throws {
        let wasmHash = WrappedData32(Data(repeating: 0x42, count: 32))
        let original = ContractExecutableXDR.wasm(wasmHash)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractExecutableXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ContractExecutableType.wasm.rawValue)
        if case .wasm(let hash) = decoded {
            XCTAssertEqual(hash.wrapped, wasmHash.wrapped)
        } else {
            XCTFail("Expected .wasm arm")
        }
    }

    func testContractExecutableXDRTokenRoundTrip() throws {
        let original = ContractExecutableXDR.token
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(ContractExecutableXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), ContractExecutableType.stellarAsset.rawValue)
        if case .token = decoded {
            // Success
        } else {
            XCTFail("Expected .token arm")
        }
    }

    // MARK: - SCAddressXDR Union Direct Construction Tests

    func testSCAddressXDRAccountDirect() throws {
        let pubKey = try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
        let original = SCAddressXDR.account(pubKey)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCAddressType.account.rawValue)
        if case .account(_) = decoded {
            // Success: account arm decoded
        } else {
            XCTFail("Expected .account arm")
        }
    }

    func testSCAddressXDRContractDirect() throws {
        let contractId = XDRTestHelpers.wrappedData32()
        let original = SCAddressXDR.contract(contractId)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCAddressType.contract.rawValue)
        if case .contract(let cid) = decoded {
            XCTAssertEqual(cid.wrapped, contractId.wrapped)
        } else {
            XCTFail("Expected .contract arm")
        }
    }

    func testSCAddressXDRMuxedAccountDirect() throws {
        let ed25519Bytes = [UInt8](repeating: 0xAB, count: 32)
        let muxed = MuxedAccountMed25519XDR(id: 12345, sourceAccountEd25519: ed25519Bytes)
        let original = SCAddressXDR.muxedAccount(muxed)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCAddressType.muxedAccount.rawValue)
        if case .muxedAccount(let m) = decoded {
            XCTAssertEqual(m.id, 12345)
            XCTAssertEqual(m.sourceAccountEd25519.count, 32)
        } else {
            XCTFail("Expected .muxedAccount arm")
        }
    }

    func testSCAddressXDRClaimableBalanceIdDirect() throws {
        let hash = XDRTestHelpers.wrappedData32()
        let cbId = ClaimableBalanceIDXDR.claimableBalanceIDTypeV0(hash)
        let original = SCAddressXDR.claimableBalanceId(cbId)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCAddressType.claimableBalance.rawValue)
        if case .claimableBalanceId(let decoded_cbId) = decoded {
            if case .claimableBalanceIDTypeV0(let h) = decoded_cbId {
                XCTAssertEqual(h.wrapped, hash.wrapped)
            } else {
                XCTFail("Expected .claimableBalanceIDTypeV0")
            }
        } else {
            XCTFail("Expected .claimableBalanceId arm")
        }
    }

    func testSCAddressXDRLiquidityPoolIdDirect() throws {
        let poolId = XDRTestHelpers.wrappedData32()
        let original = SCAddressXDR.liquidityPoolId(poolId)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCAddressType.liquidityPool.rawValue)
        if case .liquidityPoolId(let pid) = decoded {
            XCTAssertEqual(pid.wrapped, poolId.wrapped)
        } else {
            XCTFail("Expected .liquidityPoolId arm")
        }
    }

    // MARK: - SCNonceKeyXDR Tests

    func testSCNonceKeyXDRZero() throws {
        let original = SCNonceKeyXDR(nonce: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCNonceKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, 0)
    }

    func testSCNonceKeyXDRMaxNonce() throws {
        let original = SCNonceKeyXDR(nonce: Int64.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCNonceKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, Int64.max)
    }

    func testSCNonceKeyXDRMinNonce() throws {
        let original = SCNonceKeyXDR(nonce: Int64.min)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCNonceKeyXDR.self, data: encoded)
        XCTAssertEqual(decoded.nonce, Int64.min)
    }

    // MARK: - SCContractInstanceXDR Tests

    func testSCContractInstanceXDRWithMultipleStorageEntries() throws {
        let wasmHash = WrappedData32(Data(repeating: 0xBB, count: 32))
        let executable = ContractExecutableXDR.wasm(wasmHash)
        let storage = [
            SCMapEntryXDR(key: .symbol("admin"), val: .address(.account(try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")))),
            SCMapEntryXDR(key: .symbol("balance"), val: .i128(Int128PartsXDR(hi: 0, lo: 1000000))),
            SCMapEntryXDR(key: .symbol("name"), val: .string("TestToken"))
        ]
        let original = SCContractInstanceXDR(executable: executable, storage: storage)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCContractInstanceXDR.self, data: encoded)

        XCTAssertNotNil(decoded.storage)
        XCTAssertEqual(decoded.storage?.count, 3)

        // Verify first entry key
        if case .symbol(let sym) = decoded.storage?[0].key {
            XCTAssertEqual(sym, "admin")
        } else {
            XCTFail("Expected symbol key for first entry")
        }

        // Verify second entry value
        if case .i128(let parts) = decoded.storage?[1].val {
            XCTAssertEqual(parts.hi, 0)
            XCTAssertEqual(parts.lo, 1000000)
        } else {
            XCTFail("Expected i128 value for second entry")
        }

        // Verify third entry value
        if case .string(let s) = decoded.storage?[2].val {
            XCTAssertEqual(s, "TestToken")
        } else {
            XCTFail("Expected string value for third entry")
        }

        // Verify executable
        if case .wasm(let h) = decoded.executable {
            XCTAssertEqual(h.wrapped, wasmHash.wrapped)
        } else {
            XCTFail("Expected .wasm executable")
        }
    }

    func testSCContractInstanceXDRTokenNoStorage() throws {
        let original = SCContractInstanceXDR(executable: .token, storage: nil)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCContractInstanceXDR.self, data: encoded)

        XCTAssertNil(decoded.storage)
        if case .token = decoded.executable {
            // success
        } else {
            XCTFail("Expected .token executable")
        }
    }

    // MARK: - SCMapEntryXDR Tests (varied key/value types)

    func testSCMapEntryXDRWithU32KeyAndBytesValue() throws {
        let bytesData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let original = SCMapEntryXDR(key: .u32(42), val: .bytes(bytesData))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMapEntryXDR.self, data: encoded)

        if case .u32(let k) = decoded.key {
            XCTAssertEqual(k, 42)
        } else {
            XCTFail("Expected .u32 key")
        }
        if case .bytes(let v) = decoded.val {
            XCTAssertEqual(v, bytesData)
        } else {
            XCTFail("Expected .bytes value")
        }
    }

    func testSCMapEntryXDRWithI64KeyAndBoolValue() throws {
        let original = SCMapEntryXDR(key: .i64(-9876543210), val: .bool(false))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMapEntryXDR.self, data: encoded)

        if case .i64(let k) = decoded.key {
            XCTAssertEqual(k, -9876543210)
        } else {
            XCTFail("Expected .i64 key")
        }
        if case .bool(let v) = decoded.val {
            XCTAssertEqual(v, false)
        } else {
            XCTFail("Expected .bool value")
        }
    }

    func testSCMapEntryXDRWithVoidValue() throws {
        let original = SCMapEntryXDR(key: .symbol("empty"), val: .void)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMapEntryXDR.self, data: encoded)

        if case .symbol(let k) = decoded.key {
            XCTAssertEqual(k, "empty")
        } else {
            XCTFail("Expected .symbol key")
        }
        if case .void = decoded.val {
            // success
        } else {
            XCTFail("Expected .void value")
        }
    }

    // MARK: - SCValXDR Depth 0 Tests (all primitive arms)

    func testSCValXDRAllDiscriminants() throws {
        // Verify type() returns the correct discriminant for every arm
        let cases: [(SCValXDR, Int32)] = [
            (.bool(true), SCValType.bool.rawValue),
            (.void, SCValType.void.rawValue),
            (.error(.contract(0)), SCValType.error.rawValue),
            (.u32(0), SCValType.u32.rawValue),
            (.i32(0), SCValType.i32.rawValue),
            (.u64(0), SCValType.u64.rawValue),
            (.i64(0), SCValType.i64.rawValue),
            (.timepoint(0), SCValType.timepoint.rawValue),
            (.duration(0), SCValType.duration.rawValue),
            (.u128(UInt128PartsXDR(hi: 0, lo: 0)), SCValType.u128.rawValue),
            (.i128(Int128PartsXDR(hi: 0, lo: 0)), SCValType.i128.rawValue),
            (.u256(UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 0)), SCValType.u256.rawValue),
            (.i256(Int256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 0)), SCValType.i256.rawValue),
            (.bytes(Data()), SCValType.bytes.rawValue),
            (.string(""), SCValType.string.rawValue),
            (.symbol(""), SCValType.symbol.rawValue),
            (.vec(nil), SCValType.vec.rawValue),
            (.map(nil), SCValType.map.rawValue),
            (.ledgerKeyContractInstance, SCValType.ledgerKeyContractInstance.rawValue),
            (.ledgerKeyNonce(SCNonceKeyXDR(nonce: 0)), SCValType.ledgerKeyNonce.rawValue),
        ]
        for (val, expectedDiscriminant) in cases {
            XCTAssertEqual(val.type(), expectedDiscriminant,
                           "Discriminant mismatch for type rawValue \(expectedDiscriminant)")
        }
    }

    func testSCValXDRErrorWithContractCode() throws {
        let original = SCValXDR.error(.contract(42))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCValType.error.rawValue)
        if case .error(let e) = decoded {
            if case .contract(let code) = e {
                XCTAssertEqual(code, 42)
            } else {
                XCTFail("Expected .contract error")
            }
        } else {
            XCTFail("Expected .error arm")
        }
    }

    func testSCValXDRErrorWithSystemCode() throws {
        let original = SCValXDR.error(.budget(.exceededLimit))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCValType.error.rawValue)
        if case .error(let e) = decoded {
            if case .budget(let code) = e {
                XCTAssertEqual(code, .exceededLimit)
            } else {
                XCTFail("Expected .budget error")
            }
        } else {
            XCTFail("Expected .error arm")
        }
    }

    // MARK: - SCValXDR Depth 1 Tests (vec/map with primitive elements)

    func testSCValXDRVecWithMixedTypes() throws {
        let original = SCValXDR.vec([
            .bool(true),
            .u32(999),
            .i64(-777),
            .string("test"),
            .symbol("SYM"),
            .void,
            .bytes(Data([0x01, 0x02])),
            .timepoint(1609459200),
            .duration(86400)
        ])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCValType.vec.rawValue)
        guard case .vec(let elements) = decoded, let elems = elements else {
            return XCTFail("Expected .vec with elements")
        }
        XCTAssertEqual(elems.count, 9)

        if case .bool(let b) = elems[0] { XCTAssertTrue(b) }
        else { XCTFail("Expected bool at index 0") }

        if case .u32(let v) = elems[1] { XCTAssertEqual(v, 999) }
        else { XCTFail("Expected u32 at index 1") }

        if case .i64(let v) = elems[2] { XCTAssertEqual(v, -777) }
        else { XCTFail("Expected i64 at index 2") }

        if case .string(let s) = elems[3] { XCTAssertEqual(s, "test") }
        else { XCTFail("Expected string at index 3") }

        if case .symbol(let s) = elems[4] { XCTAssertEqual(s, "SYM") }
        else { XCTFail("Expected symbol at index 4") }

        if case .void = elems[5] { /* success */ }
        else { XCTFail("Expected void at index 5") }

        if case .bytes(let d) = elems[6] { XCTAssertEqual(d, Data([0x01, 0x02])) }
        else { XCTFail("Expected bytes at index 6") }

        if case .timepoint(let t) = elems[7] { XCTAssertEqual(t, 1609459200) }
        else { XCTFail("Expected timepoint at index 7") }

        if case .duration(let d) = elems[8] { XCTAssertEqual(d, 86400) }
        else { XCTFail("Expected duration at index 8") }
    }

    func testSCValXDRMapWithMultipleEntryTypes() throws {
        let original = SCValXDR.map([
            SCMapEntryXDR(key: .symbol("count"), val: .u32(42)),
            SCMapEntryXDR(key: .symbol("name"), val: .string("Hello")),
            SCMapEntryXDR(key: .symbol("active"), val: .bool(true)),
            SCMapEntryXDR(key: .u32(0), val: .void)
        ])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCValType.map.rawValue)
        guard case .map(let entries) = decoded, let mapEntries = entries else {
            return XCTFail("Expected .map with entries")
        }
        XCTAssertEqual(mapEntries.count, 4)

        if case .symbol(let k) = mapEntries[0].key { XCTAssertEqual(k, "count") }
        else { XCTFail("Expected symbol key at index 0") }
        if case .u32(let v) = mapEntries[0].val { XCTAssertEqual(v, 42) }
        else { XCTFail("Expected u32 value at index 0") }

        if case .string(let s) = mapEntries[1].val { XCTAssertEqual(s, "Hello") }
        else { XCTFail("Expected string value at index 1") }

        if case .bool(let b) = mapEntries[2].val { XCTAssertTrue(b) }
        else { XCTFail("Expected bool value at index 2") }

        if case .void = mapEntries[3].val { /* success */ }
        else { XCTFail("Expected void value at index 3") }
    }

    // MARK: - SCValXDR Depth 2 Tests (recursive nesting)

    func testSCValXDRNestedVecInVec() throws {
        let innerVec: SCValXDR = .vec([.u32(10), .u32(20), .u32(30)])
        let original = SCValXDR.vec([
            .string("outer"),
            innerVec,
            .u32(99)
        ])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .vec(let outerElems) = decoded, let outer = outerElems else {
            return XCTFail("Expected outer .vec")
        }
        XCTAssertEqual(outer.count, 3)

        if case .string(let s) = outer[0] { XCTAssertEqual(s, "outer") }
        else { XCTFail("Expected string at outer[0]") }

        guard case .vec(let innerElems) = outer[1], let inner = innerElems else {
            return XCTFail("Expected inner .vec at outer[1]")
        }
        XCTAssertEqual(inner.count, 3)
        if case .u32(let v) = inner[0] { XCTAssertEqual(v, 10) }
        else { XCTFail("Expected u32(10) at inner[0]") }
        if case .u32(let v) = inner[1] { XCTAssertEqual(v, 20) }
        else { XCTFail("Expected u32(20) at inner[1]") }
        if case .u32(let v) = inner[2] { XCTAssertEqual(v, 30) }
        else { XCTFail("Expected u32(30) at inner[2]") }
    }

    func testSCValXDRNestedMapInVec() throws {
        let innerMap: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("a"), val: .i32(1)),
            SCMapEntryXDR(key: .symbol("b"), val: .i32(2))
        ])
        let original = SCValXDR.vec([innerMap, .bool(false)])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .vec(let elems) = decoded, let vecElems = elems else {
            return XCTFail("Expected .vec")
        }
        XCTAssertEqual(vecElems.count, 2)

        guard case .map(let mapEntries) = vecElems[0], let entries = mapEntries else {
            return XCTFail("Expected .map at vecElems[0]")
        }
        XCTAssertEqual(entries.count, 2)
        if case .symbol(let k) = entries[0].key { XCTAssertEqual(k, "a") }
        else { XCTFail("Expected symbol key 'a'") }
        if case .i32(let v) = entries[0].val { XCTAssertEqual(v, 1) }
        else { XCTFail("Expected i32 value 1") }
    }

    func testSCValXDRNestedVecInMap() throws {
        let innerVec: SCValXDR = .vec([.symbol("x"), .symbol("y")])
        let original = SCValXDR.map([
            SCMapEntryXDR(key: .symbol("items"), val: innerVec)
        ])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .map(let entries) = decoded, let mapEntries = entries else {
            return XCTFail("Expected .map")
        }
        XCTAssertEqual(mapEntries.count, 1)

        guard case .vec(let innerElems) = mapEntries[0].val, let inner = innerElems else {
            return XCTFail("Expected .vec value in map entry")
        }
        XCTAssertEqual(inner.count, 2)
        if case .symbol(let s) = inner[0] { XCTAssertEqual(s, "x") }
        else { XCTFail("Expected symbol 'x'") }
        if case .symbol(let s) = inner[1] { XCTAssertEqual(s, "y") }
        else { XCTFail("Expected symbol 'y'") }
    }

    func testSCValXDRNestedMapInMap() throws {
        let innerMap: SCValXDR = .map([
            SCMapEntryXDR(key: .u32(1), val: .string("one")),
            SCMapEntryXDR(key: .u32(2), val: .string("two"))
        ])
        let original = SCValXDR.map([
            SCMapEntryXDR(key: .symbol("nested"), val: innerMap),
            SCMapEntryXDR(key: .symbol("flat"), val: .u64(42))
        ])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .map(let outerEntries) = decoded, let outer = outerEntries else {
            return XCTFail("Expected outer .map")
        }
        XCTAssertEqual(outer.count, 2)

        // Check nested map
        guard case .map(let innerEntries) = outer[0].val, let inner = innerEntries else {
            return XCTFail("Expected inner .map at outer[0].val")
        }
        XCTAssertEqual(inner.count, 2)
        if case .u32(let k) = inner[0].key { XCTAssertEqual(k, 1) }
        else { XCTFail("Expected u32 key 1") }
        if case .string(let v) = inner[0].val { XCTAssertEqual(v, "one") }
        else { XCTFail("Expected string 'one'") }

        // Check flat entry
        if case .u64(let v) = outer[1].val { XCTAssertEqual(v, 42) }
        else { XCTFail("Expected u64 value 42") }
    }

    // MARK: - SCValXDR with Address arm (depth 0)

    func testSCValXDRAddressContractRoundTrip() throws {
        let contractId = XDRTestHelpers.wrappedData32()
        let addr = SCAddressXDR.contract(contractId)
        let original = SCValXDR.address(addr)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCValType.address.rawValue)
        if case .address(let decodedAddr) = decoded {
            XCTAssertEqual(decodedAddr.type(), SCAddressType.contract.rawValue)
            if case .contract(let cid) = decodedAddr {
                XCTAssertEqual(cid.wrapped, contractId.wrapped)
            } else {
                XCTFail("Expected .contract address")
            }
        } else {
            XCTFail("Expected .address arm")
        }
    }

    // MARK: - SCValXDR with ContractInstance arm (depth 0 with storage)

    func testSCValXDRContractInstanceWithStorage() throws {
        let wasmHash = WrappedData32(Data(repeating: 0xAA, count: 32))
        let storage = [
            SCMapEntryXDR(key: .symbol("x"), val: .u32(10)),
            SCMapEntryXDR(key: .symbol("y"), val: .u32(20))
        ]
        let instance = SCContractInstanceXDR(executable: .wasm(wasmHash), storage: storage)
        let original = SCValXDR.contractInstance(instance)

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCValType.contractInstance.rawValue)
        if case .contractInstance(let inst) = decoded {
            XCTAssertEqual(inst.storage?.count, 2)
            if case .wasm(let h) = inst.executable {
                XCTAssertEqual(h.wrapped, wasmHash.wrapped)
            } else {
                XCTFail("Expected .wasm executable")
            }
        } else {
            XCTFail("Expected .contractInstance arm")
        }
    }

    // MARK: - SCValXDR with U128/I128 detailed extraction

    func testSCValXDRU128DetailedExtraction() throws {
        let parts = UInt128PartsXDR(hi: 0xFEDCBA9876543210, lo: 0x0123456789ABCDEF)
        let original = SCValXDR.u128(parts)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        if case .u128(let p) = decoded {
            XCTAssertEqual(p.hi, 0xFEDCBA9876543210)
            XCTAssertEqual(p.lo, 0x0123456789ABCDEF)
        } else {
            XCTFail("Expected .u128")
        }
    }

    func testSCValXDRI128DetailedExtraction() throws {
        let parts = Int128PartsXDR(hi: -42, lo: 1000000)
        let original = SCValXDR.i128(parts)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        if case .i128(let p) = decoded {
            XCTAssertEqual(p.hi, -42)
            XCTAssertEqual(p.lo, 1000000)
        } else {
            XCTFail("Expected .i128")
        }
    }

    // MARK: - SCValXDR with U256/I256 detailed extraction

    func testSCValXDRU256DetailedExtraction() throws {
        let parts = UInt256PartsXDR(
            hiHi: 0xAAAAAAAAAAAAAAAA,
            hiLo: 0xBBBBBBBBBBBBBBBB,
            loHi: 0xCCCCCCCCCCCCCCCC,
            loLo: 0xDDDDDDDDDDDDDDDD
        )
        let original = SCValXDR.u256(parts)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        if case .u256(let p) = decoded {
            XCTAssertEqual(p.hiHi, 0xAAAAAAAAAAAAAAAA)
            XCTAssertEqual(p.hiLo, 0xBBBBBBBBBBBBBBBB)
            XCTAssertEqual(p.loHi, 0xCCCCCCCCCCCCCCCC)
            XCTAssertEqual(p.loLo, 0xDDDDDDDDDDDDDDDD)
        } else {
            XCTFail("Expected .u256")
        }
    }

    func testSCValXDRI256DetailedExtraction() throws {
        let parts = Int256PartsXDR(
            hiHi: -999, hiLo: 12345, loHi: 67890, loLo: 11111
        )
        let original = SCValXDR.i256(parts)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        if case .i256(let p) = decoded {
            XCTAssertEqual(p.hiHi, -999)
            XCTAssertEqual(p.hiLo, 12345)
            XCTAssertEqual(p.loHi, 67890)
            XCTAssertEqual(p.loLo, 11111)
        } else {
            XCTFail("Expected .i256")
        }
    }

    // MARK: - SCValXDR LedgerKeyNonce with realistic nonce

    func testSCValXDRLedgerKeyNonceWithRealisticNonce() throws {
        let nonce: Int64 = 7890123456789
        let original = SCValXDR.ledgerKeyNonce(SCNonceKeyXDR(nonce: nonce))
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCValType.ledgerKeyNonce.rawValue)
        if case .ledgerKeyNonce(let nk) = decoded {
            XCTAssertEqual(nk.nonce, nonce)
        } else {
            XCTFail("Expected .ledgerKeyNonce arm")
        }
    }

    // MARK: - SCValXDR Bytes with large data

    func testSCValXDRBytesLargePayload() throws {
        let largeData = Data(repeating: 0xAB, count: 1024)
        let original = SCValXDR.bytes(largeData)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        if case .bytes(let d) = decoded {
            XCTAssertEqual(d.count, 1024)
            XCTAssertEqual(d, largeData)
        } else {
            XCTFail("Expected .bytes")
        }
    }

    // MARK: - SCValXDR Depth 2: Vec of vecs of maps

    func testSCValXDRVecOfVecsOfMaps() throws {
        let innerMap1: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("k1"), val: .u32(1))
        ])
        let innerMap2: SCValXDR = .map([
            SCMapEntryXDR(key: .symbol("k2"), val: .u32(2))
        ])
        let innerVec: SCValXDR = .vec([innerMap1, innerMap2])
        let original = SCValXDR.vec([innerVec, .void])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .vec(let outerElems) = decoded, let outer = outerElems else {
            return XCTFail("Expected outer vec")
        }
        XCTAssertEqual(outer.count, 2)

        guard case .vec(let midElems) = outer[0], let mid = midElems else {
            return XCTFail("Expected inner vec at outer[0]")
        }
        XCTAssertEqual(mid.count, 2)

        guard case .map(let map1Entries) = mid[0], let m1 = map1Entries else {
            return XCTFail("Expected map at mid[0]")
        }
        XCTAssertEqual(m1.count, 1)
        if case .symbol(let k) = m1[0].key { XCTAssertEqual(k, "k1") }
        else { XCTFail("Expected symbol key k1") }

        if case .void = outer[1] { /* success */ }
        else { XCTFail("Expected void at outer[1]") }
    }

    // MARK: - SCValXDR address inside map (composition test)

    func testSCValXDRMapWithAddressValues() throws {
        let pubKey = try PublicKey(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
        let addr = SCAddressXDR.account(pubKey)
        let original = SCValXDR.map([
            SCMapEntryXDR(key: .symbol("owner"), val: .address(addr)),
            SCMapEntryXDR(key: .symbol("balance"), val: .i128(Int128PartsXDR(hi: 0, lo: 5000000)))
        ])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .map(let entries) = decoded, let mapEntries = entries else {
            return XCTFail("Expected .map")
        }
        XCTAssertEqual(mapEntries.count, 2)

        if case .address(let a) = mapEntries[0].val {
            XCTAssertEqual(a.type(), SCAddressType.account.rawValue)
        } else {
            XCTFail("Expected .address value")
        }

        if case .i128(let p) = mapEntries[1].val {
            XCTAssertEqual(p.lo, 5000000)
        } else {
            XCTFail("Expected .i128 value")
        }
    }

    // MARK: - SCValXDR error inside vec (composition test)

    func testSCValXDRVecWithErrorElement() throws {
        let original = SCValXDR.vec([
            .error(.storage(.missingValue)),
            .error(.auth(.invalidInput)),
            .u32(0)
        ])

        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .vec(let elems) = decoded, let vec = elems else {
            return XCTFail("Expected .vec")
        }
        XCTAssertEqual(vec.count, 3)

        if case .error(let e) = vec[0] {
            if case .storage(let code) = e {
                XCTAssertEqual(code, .missingValue)
            } else {
                XCTFail("Expected .storage error")
            }
        } else {
            XCTFail("Expected .error at index 0")
        }

        if case .error(let e) = vec[1] {
            if case .auth(let code) = e {
                XCTAssertEqual(code, .invalidInput)
            } else {
                XCTFail("Expected .auth error")
            }
        } else {
            XCTFail("Expected .error at index 1")
        }
    }

    // MARK: - SCValXDR single-element vec and map

    func testSCValXDRSingleElementVec() throws {
        let original = SCValXDR.vec([.symbol("only")])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .vec(let elems) = decoded, let vec = elems else {
            return XCTFail("Expected .vec")
        }
        XCTAssertEqual(vec.count, 1)
        if case .symbol(let s) = vec[0] { XCTAssertEqual(s, "only") }
        else { XCTFail("Expected symbol") }
    }

    func testSCValXDRSingleElementMap() throws {
        let original = SCValXDR.map([
            SCMapEntryXDR(key: .i32(-1), val: .duration(3600))
        ])
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        guard case .map(let entries) = decoded, let mapEntries = entries else {
            return XCTFail("Expected .map")
        }
        XCTAssertEqual(mapEntries.count, 1)
        if case .i32(let k) = mapEntries[0].key { XCTAssertEqual(k, -1) }
        else { XCTFail("Expected i32 key") }
        if case .duration(let d) = mapEntries[0].val { XCTAssertEqual(d, 3600) }
        else { XCTFail("Expected duration value") }
    }
}
