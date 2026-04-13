//
//  TxRepSCValDirectTestCase.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete on 12.04.2026.
//  Copyright © 2026 Soneso. All rights reserved.
//
//  Direct unit tests for SCValXDR.toTxRep / fromTxRep.
//  Each test targets a specific SCVal arm not exercised by the existing
//  TxRepSorobanTestCase tests. Existing tests cover:
//    .bool, .u32, .i32, .u64, .i64, .symbol, .string (via facade)
//  This file covers the remaining arms directly.
//

import XCTest
import stellarsdk

final class TxRepSCValDirectTestCase: XCTestCase {

    // MARK: - Helper

    /// Roundtrip: toTxRep → fromTxRep.
    private func roundtrip(_ val: SCValXDR, prefix: String = "v") throws -> SCValXDR {
        var lines = [String]()
        try val.toTxRep(prefix: prefix, lines: &lines)
        let text = lines.joined(separator: "\n")
        let map = TxRepHelper.parse(text)
        return try SCValXDR.fromTxRep(map, prefix: prefix)
    }

    // MARK: - .bool

    func testBoolTrue() throws {
        var lines = [String]()
        try SCValXDR.bool(true).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_BOOL"))
        XCTAssertTrue(lines.contains("v.b: true"))

        let restored = try roundtrip(.bool(true))
        if case .bool(let v) = restored { XCTAssertTrue(v) } else { XCTFail("Expected .bool") }
    }

    func testBoolFalse() throws {
        let restored = try roundtrip(.bool(false))
        if case .bool(let v) = restored { XCTAssertFalse(v) } else { XCTFail("Expected .bool") }
    }

    // MARK: - .void

    func testVoid() throws {
        var lines = [String]()
        try SCValXDR.void.toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_VOID"))
        XCTAssertEqual(lines.count, 1)

        let restored = try roundtrip(.void)
        if case .void = restored {} else { XCTFail("Expected .void") }
    }

    // MARK: - .error

    func testErrorContractArm() throws {
        let err = SCErrorXDR.contract(42)
        let restored = try roundtrip(.error(err))
        if case .error(let e) = restored, case .contract(let code) = e {
            XCTAssertEqual(code, 42)
        } else {
            XCTFail("Expected .error(.contract(42))")
        }
    }

    func testErrorWasmVmArm() throws {
        let err = SCErrorXDR.wasmVm(.invalidInput)
        let restored = try roundtrip(.error(err))
        if case .error(let e) = restored, case .wasmVm(let code) = e {
            XCTAssertEqual(code, .invalidInput)
        } else {
            XCTFail("Expected .error(.wasmVm(.invalidInput))")
        }
    }

    func testErrorValueArm() throws {
        let err = SCErrorXDR.value(.arithDomain)
        let restored = try roundtrip(.error(err))
        if case .error(let e) = restored, case .value(let code) = e {
            XCTAssertEqual(code, .arithDomain)
        } else {
            XCTFail("Expected .error(.value(.arithDomain))")
        }
    }

    // MARK: - .timepoint

    func testTimepoint() throws {
        var lines = [String]()
        try SCValXDR.timepoint(1_700_000_000).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_TIMEPOINT"))
        XCTAssertTrue(lines.contains("v.timepoint: 1700000000"))

        let restored = try roundtrip(.timepoint(1_700_000_000))
        if case .timepoint(let t) = restored { XCTAssertEqual(t, 1_700_000_000) } else { XCTFail("Expected .timepoint") }
    }

    func testTimepointZero() throws {
        let restored = try roundtrip(.timepoint(0))
        if case .timepoint(let t) = restored { XCTAssertEqual(t, 0) } else { XCTFail("Expected .timepoint") }
    }

    // MARK: - .duration

    func testDuration() throws {
        var lines = [String]()
        try SCValXDR.duration(86400).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_DURATION"))
        XCTAssertTrue(lines.contains("v.duration: 86400"))

        let restored = try roundtrip(.duration(86400))
        if case .duration(let d) = restored { XCTAssertEqual(d, 86400) } else { XCTFail("Expected .duration") }
    }

    // MARK: - .u128

    func testU128() throws {
        let parts = UInt128PartsXDR(hi: 0x0102030405060708, lo: 0x090a0b0c0d0e0f10)
        var lines = [String]()
        try SCValXDR.u128(parts).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_U128"))

        let restored = try roundtrip(.u128(parts))
        if case .u128(let p) = restored {
            XCTAssertEqual(p.hi, parts.hi)
            XCTAssertEqual(p.lo, parts.lo)
        } else {
            XCTFail("Expected .u128")
        }
    }

    func testU128Zero() throws {
        let parts = UInt128PartsXDR(hi: 0, lo: 0)
        let restored = try roundtrip(.u128(parts))
        if case .u128(let p) = restored {
            XCTAssertEqual(p.hi, 0)
            XCTAssertEqual(p.lo, 0)
        } else {
            XCTFail("Expected .u128")
        }
    }

    // MARK: - .i128

    func testI128Positive() throws {
        let parts = Int128PartsXDR(hi: 0, lo: 999_999_999)
        var lines = [String]()
        try SCValXDR.i128(parts).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_I128"))

        let restored = try roundtrip(.i128(parts))
        if case .i128(let p) = restored {
            XCTAssertEqual(p.hi, 0)
            XCTAssertEqual(p.lo, 999_999_999)
        } else {
            XCTFail("Expected .i128")
        }
    }

    func testI128Negative() throws {
        // Represent -1: hi = -1 (all bits set), lo = UInt64.max
        let parts = Int128PartsXDR(hi: -1, lo: UInt64.max)
        let restored = try roundtrip(.i128(parts))
        if case .i128(let p) = restored {
            XCTAssertEqual(p.hi, -1)
            XCTAssertEqual(p.lo, UInt64.max)
        } else {
            XCTFail("Expected .i128")
        }
    }

    // MARK: - .u256

    func testU256() throws {
        let parts = UInt256PartsXDR(hiHi: 1, hiLo: 2, loHi: 3, loLo: 4)
        var lines = [String]()
        try SCValXDR.u256(parts).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_U256"))

        let restored = try roundtrip(.u256(parts))
        if case .u256(let p) = restored {
            XCTAssertEqual(p.hiHi, 1)
            XCTAssertEqual(p.hiLo, 2)
            XCTAssertEqual(p.loHi, 3)
            XCTAssertEqual(p.loLo, 4)
        } else {
            XCTFail("Expected .u256")
        }
    }

    func testU256AllZeros() throws {
        let parts = UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 0)
        let restored = try roundtrip(.u256(parts))
        if case .u256(let p) = restored {
            XCTAssertEqual(p.hiHi, 0)
            XCTAssertEqual(p.hiLo, 0)
            XCTAssertEqual(p.loHi, 0)
            XCTAssertEqual(p.loLo, 0)
        } else {
            XCTFail("Expected .u256")
        }
    }

    // MARK: - .i256

    func testI256Positive() throws {
        let parts = Int256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 42)
        var lines = [String]()
        try SCValXDR.i256(parts).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_I256"))

        let restored = try roundtrip(.i256(parts))
        if case .i256(let p) = restored {
            XCTAssertEqual(p.hiHi, 0)
            XCTAssertEqual(p.loLo, 42)
        } else {
            XCTFail("Expected .i256")
        }
    }

    func testI256Negative() throws {
        // -1 in two's complement 256-bit
        let parts = Int256PartsXDR(hiHi: -1, hiLo: UInt64.max, loHi: UInt64.max, loLo: UInt64.max)
        let restored = try roundtrip(.i256(parts))
        if case .i256(let p) = restored {
            XCTAssertEqual(p.hiHi, -1)
            XCTAssertEqual(p.hiLo, UInt64.max)
            XCTAssertEqual(p.loHi, UInt64.max)
            XCTAssertEqual(p.loLo, UInt64.max)
        } else {
            XCTFail("Expected .i256")
        }
    }

    // MARK: - .bytes

    func testBytes() throws {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        var lines = [String]()
        try SCValXDR.bytes(data).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_BYTES"))
        XCTAssertTrue(lines.contains { $0.hasPrefix("v.bytes:") })

        let restored = try roundtrip(.bytes(data))
        if case .bytes(let b) = restored {
            XCTAssertEqual(b, data)
        } else {
            XCTFail("Expected .bytes")
        }
    }

    func testBytesEmpty() throws {
        let data = Data()
        let restored = try roundtrip(.bytes(data))
        if case .bytes(let b) = restored {
            XCTAssertEqual(b, data)
        } else {
            XCTFail("Expected .bytes with empty data")
        }
    }

    // MARK: - .string (direct, not via facade)

    func testStringDirect() throws {
        var lines = [String]()
        try SCValXDR.string("hello world").toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_STRING"))
        XCTAssertTrue(lines.contains { $0.hasPrefix("v.str:") })

        let restored = try roundtrip(.string("hello world"))
        if case .string(let s) = restored {
            XCTAssertEqual(s, "hello world")
        } else {
            XCTFail("Expected .string")
        }
    }

    func testStringWithSpecialChars() throws {
        let s = "line1\nline2\ttabbed"
        let restored = try roundtrip(.string(s))
        if case .string(let r) = restored {
            XCTAssertEqual(r, s)
        } else {
            XCTFail("Expected .string with special chars")
        }
    }

    // MARK: - .symbol (direct)

    func testSymbolDirect() throws {
        var lines = [String]()
        try SCValXDR.symbol("my_sym").toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_SYMBOL"))
        XCTAssertTrue(lines.contains { $0.hasPrefix("v.sym:") })

        let restored = try roundtrip(.symbol("my_sym"))
        if case .symbol(let s) = restored {
            XCTAssertEqual(s, "my_sym")
        } else {
            XCTFail("Expected .symbol")
        }
    }

    // MARK: - .vec

    func testVecNil() throws {
        var lines = [String]()
        try SCValXDR.vec(nil).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_VEC"))
        XCTAssertTrue(lines.contains("v.vec._present: false"))

        let restored = try roundtrip(.vec(nil))
        if case .vec(let inner) = restored {
            XCTAssertNil(inner)
        } else {
            XCTFail("Expected .vec(nil)")
        }
    }

    func testVecWithElements() throws {
        let elements: [SCValXDR] = [.u32(1), .u32(2), .u32(3)]
        var lines = [String]()
        try SCValXDR.vec(elements).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_VEC"))
        XCTAssertTrue(lines.contains("v.vec._present: true"))
        XCTAssertTrue(lines.contains("v.vec.len: 3"))

        let restored = try roundtrip(.vec(elements))
        if case .vec(let inner) = restored, let arr = inner {
            XCTAssertEqual(arr.count, 3)
            for item in arr {
                if case .u32 = item {} else { XCTFail("Expected .u32 in vec") }
            }
        } else {
            XCTFail("Expected .vec with 3 elements")
        }
    }

    func testVecEmpty() throws {
        let elements: [SCValXDR] = []
        let restored = try roundtrip(.vec(elements))
        if case .vec(let inner) = restored, let arr = inner {
            XCTAssertEqual(arr.count, 0)
        } else {
            XCTFail("Expected .vec with empty array")
        }
    }

    func testVecNested() throws {
        // Nested vec: [[u32(1)], [u32(2)]]
        let inner1: SCValXDR = .vec([.u32(1)])
        let inner2: SCValXDR = .vec([.u32(2)])
        let outer: SCValXDR = .vec([inner1, inner2])

        let restored = try roundtrip(outer)
        if case .vec(let outerArr) = restored, let arr = outerArr {
            XCTAssertEqual(arr.count, 2)
            if case .vec(let sub) = arr[0], let s = sub {
                XCTAssertEqual(s.count, 1)
                if case .u32(let n) = s[0] { XCTAssertEqual(n, 1) } else { XCTFail("inner[0][0] mismatch") }
            } else {
                XCTFail("Expected inner vec at [0]")
            }
        } else {
            XCTFail("Expected nested vec")
        }
    }

    // MARK: - .map

    func testMapNil() throws {
        var lines = [String]()
        try SCValXDR.map(nil).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_MAP"))
        XCTAssertTrue(lines.contains("v.map._present: false"))

        let restored = try roundtrip(.map(nil))
        if case .map(let inner) = restored {
            XCTAssertNil(inner)
        } else {
            XCTFail("Expected .map(nil)")
        }
    }

    func testMapWithEntries() throws {
        let entry = SCMapEntryXDR(key: .symbol("key"), val: .u32(100))
        let entries: [SCMapEntryXDR] = [entry]

        var lines = [String]()
        try SCValXDR.map(entries).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_MAP"))
        XCTAssertTrue(lines.contains("v.map._present: true"))
        XCTAssertTrue(lines.contains("v.map.len: 1"))

        let restored = try roundtrip(.map(entries))
        if case .map(let inner) = restored, let arr = inner {
            XCTAssertEqual(arr.count, 1)
            if case .symbol(let k) = arr[0].key { XCTAssertEqual(k, "key") } else { XCTFail("key mismatch") }
            if case .u32(let vv) = arr[0].val { XCTAssertEqual(vv, 100) } else { XCTFail("val mismatch") }
        } else {
            XCTFail("Expected .map with 1 entry")
        }
    }

    func testMapWithMultipleEntries() throws {
        let entries: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("a"), val: .u32(1)),
            SCMapEntryXDR(key: .symbol("b"), val: .i32(-1)),
            SCMapEntryXDR(key: .symbol("c"), val: .bool(true)),
        ]
        let restored = try roundtrip(.map(entries))
        if case .map(let inner) = restored, let arr = inner {
            XCTAssertEqual(arr.count, 3)
        } else {
            XCTFail("Expected .map with 3 entries")
        }
    }

    // MARK: - .address (account)

    func testAddressAccount() throws {
        let kp = try KeyPair(accountId: "GDW6AUTBXTOC7FIKUO5BOO3OGLK4SF7ZPOBLMQHMZDI45J2Z6VXRB5NR")
        let addr = SCAddressXDR.account(kp.publicKey)

        var lines = [String]()
        try SCValXDR.address(addr).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_ADDRESS"))
        XCTAssertTrue(lines.contains("v.address.type: SC_ADDRESS_TYPE_ACCOUNT"))

        let restored = try roundtrip(.address(addr))
        if case .address(let a) = restored, case .account(let pk) = a {
            XCTAssertEqual(pk.accountId, kp.accountId)
        } else {
            XCTFail("Expected .address(.account(...))")
        }
    }

    // MARK: - .address (contract)

    func testAddressContract() throws {
        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let addr = try SCAddressXDR(contractId: contractId)

        var lines = [String]()
        try SCValXDR.address(addr).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_ADDRESS"))
        XCTAssertTrue(lines.contains("v.address.type: SC_ADDRESS_TYPE_CONTRACT"))

        let restored = try roundtrip(.address(addr))
        if case .address(let a) = restored, case .contract = a {
            // contract address restored correctly
        } else {
            XCTFail("Expected .address(.contract(...))")
        }
    }

    // MARK: - .ledgerKeyContractInstance

    func testLedgerKeyContractInstance() throws {
        var lines = [String]()
        try SCValXDR.ledgerKeyContractInstance.toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_LEDGER_KEY_CONTRACT_INSTANCE"))
        XCTAssertEqual(lines.count, 1)

        let restored = try roundtrip(.ledgerKeyContractInstance)
        if case .ledgerKeyContractInstance = restored {} else { XCTFail("Expected .ledgerKeyContractInstance") }
    }

    // MARK: - .ledgerKeyNonce

    func testLedgerKeyNonce() throws {
        let nonce = SCNonceKeyXDR(nonce: 42)
        var lines = [String]()
        try SCValXDR.ledgerKeyNonce(nonce).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_LEDGER_KEY_NONCE"))
        XCTAssertTrue(lines.contains("v.nonce_key.nonce: 42"))

        let restored = try roundtrip(.ledgerKeyNonce(nonce))
        if case .ledgerKeyNonce(let n) = restored {
            XCTAssertEqual(n.nonce, 42)
        } else {
            XCTFail("Expected .ledgerKeyNonce")
        }
    }

    func testLedgerKeyNonceNegative() throws {
        let nonce = SCNonceKeyXDR(nonce: -999)
        let restored = try roundtrip(.ledgerKeyNonce(nonce))
        if case .ledgerKeyNonce(let n) = restored {
            XCTAssertEqual(n.nonce, -999)
        } else {
            XCTFail("Expected .ledgerKeyNonce")
        }
    }

    // MARK: - .contractInstance

    func testContractInstanceToken() throws {
        let instance = SCContractInstanceXDR(executable: .token, storage: nil)
        var lines = [String]()
        try SCValXDR.contractInstance(instance).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_CONTRACT_INSTANCE"))
        XCTAssertTrue(lines.contains("v.instance.executable.type: CONTRACT_EXECUTABLE_STELLAR_ASSET"))
        XCTAssertTrue(lines.contains("v.instance.storage._present: false"))

        let restored = try roundtrip(.contractInstance(instance))
        if case .contractInstance(let inst) = restored {
            if case .token = inst.executable {} else { XCTFail("Expected .token executable") }
            XCTAssertNil(inst.storage)
        } else {
            XCTFail("Expected .contractInstance")
        }
    }

    func testContractInstanceWasmWithStorage() throws {
        // HashXDR is a typealias for WrappedData32
        let hashXDR = HashXDR(Data(repeating: 0xAB, count: 32))
        let storage: [SCMapEntryXDR] = [
            SCMapEntryXDR(key: .symbol("counter"), val: .u64(100)),
        ]
        let instance = SCContractInstanceXDR(executable: .wasm(hashXDR), storage: storage)

        var lines = [String]()
        try SCValXDR.contractInstance(instance).toTxRep(prefix: "v", lines: &lines)
        XCTAssertTrue(lines.contains("v.type: SCV_CONTRACT_INSTANCE"))
        XCTAssertTrue(lines.contains("v.instance.executable.type: CONTRACT_EXECUTABLE_WASM"))
        XCTAssertTrue(lines.contains("v.instance.storage._present: true"))
        XCTAssertTrue(lines.contains("v.instance.storage.len: 1"))

        let restored = try roundtrip(.contractInstance(instance))
        if case .contractInstance(let inst) = restored {
            if case .wasm = inst.executable {} else { XCTFail("Expected .wasm executable") }
            XCTAssertNotNil(inst.storage)
            XCTAssertEqual(inst.storage?.count, 1)
        } else {
            XCTFail("Expected .contractInstance with wasm and storage")
        }
    }

    // MARK: - Error handling: fromTxRep with unknown discriminant

    func testFromTxRepUnknownDiscriminantThrows() {
        let map = ["v.type": "SCV_UNKNOWN_BOGUS_TYPE"]
        XCTAssertThrowsError(try SCValXDR.fromTxRep(map, prefix: "v")) { error in
            if case TxRepError.invalidValue(let key) = error {
                XCTAssertEqual(key, "v.type")
            } else {
                XCTFail("Expected TxRepError.invalidValue, got \(error)")
            }
        }
    }

    func testFromTxRepMissingTypeKeyThrows() {
        XCTAssertThrowsError(try SCValXDR.fromTxRep([:], prefix: "v")) { error in
            if case TxRepError.missingValue(let key) = error {
                XCTAssertEqual(key, "v.type")
            } else {
                XCTFail("Expected TxRepError.missingValue, got \(error)")
            }
        }
    }

    // MARK: - Cross-arm roundtrip composite: vec containing every scalar arm

    func testVecWithAllScalarArms() throws {
        // Exercises coverage for multiple arms in a single roundtrip
        let elements: [SCValXDR] = [
            .bool(true),
            .void,
            .u32(UInt32.max),
            .i32(Int32.min),
            .u64(UInt64.max),
            .i64(Int64.min),
            .timepoint(0),
            .duration(UInt64.max),
            .bytes(Data([0x01, 0x02])),
            .string("composite"),
            .symbol("sym"),
        ]
        let restored = try roundtrip(.vec(elements))
        if case .vec(let inner) = restored, let arr = inner {
            XCTAssertEqual(arr.count, elements.count)
        } else {
            XCTFail("Expected .vec with all scalar arms")
        }
    }
}
