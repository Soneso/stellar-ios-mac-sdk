//
//  ContractXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class ContractXDRUnitTests: XCTestCase {

    // MARK: - SCErrorXDR Tests

    func testSCErrorXDRContract() throws {
        let error = SCErrorXDR.contract(12345)
        let encoded = try XDREncoder.encode(error)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        switch decoded {
        case .contract(let code):
            XCTAssertEqual(code, 12345)
        default:
            XCTFail("Expected contract error")
        }
    }

    func testSCErrorXDRAllSimpleTypes() throws {
        let errors: [SCErrorXDR] = [
            .wasmVm, .context, .storage, .object, .crypto, .events, .budget, .value
        ]

        for error in errors {
            let encoded = try XDREncoder.encode(error)
            let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)
            XCTAssertEqual(decoded.type(), error.type())
        }
    }

    func testSCErrorXDRAuth() throws {
        let error = SCErrorXDR.auth(SCErrorCode.invalidInput.rawValue)
        let encoded = try XDREncoder.encode(error)
        let decoded = try XDRDecoder.decode(SCErrorXDR.self, data: encoded)

        switch decoded {
        case .auth(let code):
            XCTAssertEqual(code, SCErrorCode.invalidInput.rawValue)
        default:
            XCTFail("Expected auth error")
        }
    }

    func testSCErrorXDRTypeDiscriminants() {
        XCTAssertEqual(SCErrorXDR.contract(0).type(), SCErrorType.contract.rawValue)
        XCTAssertEqual(SCErrorXDR.wasmVm.type(), SCErrorType.wasmVm.rawValue)
        XCTAssertEqual(SCErrorXDR.context.type(), SCErrorType.context.rawValue)
        XCTAssertEqual(SCErrorXDR.storage.type(), SCErrorType.storage.rawValue)
        XCTAssertEqual(SCErrorXDR.object.type(), SCErrorType.object.rawValue)
        XCTAssertEqual(SCErrorXDR.crypto.type(), SCErrorType.crypto.rawValue)
        XCTAssertEqual(SCErrorXDR.events.type(), SCErrorType.events.rawValue)
        XCTAssertEqual(SCErrorXDR.budget.type(), SCErrorType.budget.rawValue)
        XCTAssertEqual(SCErrorXDR.value.type(), SCErrorType.value.rawValue)
        XCTAssertEqual(SCErrorXDR.auth(0).type(), SCErrorType.auth.rawValue)
    }

    // MARK: - SCAddressXDR Tests

    func testSCAddressXDRAccount() throws {
        let accountId = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let address = try SCAddressXDR(accountId: accountId)
        let encoded = try XDREncoder.encode(address)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertEqual(decoded.accountId, accountId)
        XCTAssertNil(decoded.contractId)
        XCTAssertNil(decoded.claimableBalanceId)
        XCTAssertNil(decoded.liquidityPoolId)
    }

    func testSCAddressXDRContractHex() throws {
        let contractIdHex = "0000000000000000000000000000000000000000000000000000000000000001"
        let address = try SCAddressXDR(contractId: contractIdHex)
        let encoded = try XDREncoder.encode(address)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertNotNil(decoded.contractId)
        XCTAssertNil(decoded.accountId)
    }

    func testSCAddressXDRContractStrKey() throws {
        let contractIdStrKey = "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABSC4"
        let address = try SCAddressXDR(contractId: contractIdStrKey)
        let encoded = try XDREncoder.encode(address)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertNotNil(decoded.contractId)
    }

    func testSCAddressXDRMuxedAccount() throws {
        let muxedAccountId = "MAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY"
        let address = try SCAddressXDR(accountId: muxedAccountId)
        let encoded = try XDREncoder.encode(address)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertNotNil(decoded.accountId)
    }

    func testSCAddressXDRLiquidityPoolId() throws {
        let poolIdHex = "dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7"
        let address = try SCAddressXDR(liquidityPoolId: poolIdHex)
        let encoded = try XDREncoder.encode(address)
        let decoded = try XDRDecoder.decode(SCAddressXDR.self, data: encoded)

        XCTAssertNotNil(decoded.liquidityPoolId)
    }

    func testSCAddressXDRTypeDiscriminants() throws {
        let accountAddress = try SCAddressXDR(accountId: "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ")
        XCTAssertEqual(accountAddress.type(), SCAddressType.account.rawValue)

        let contractAddress = try SCAddressXDR(contractId: "0000000000000000000000000000000000000000000000000000000000000001")
        XCTAssertEqual(contractAddress.type(), SCAddressType.contract.rawValue)
    }

    // MARK: - SCNonceKeyXDR Tests

    func testSCNonceKeyXDR() throws {
        let nonce: Int64 = 123456789
        let nonceKey = SCNonceKeyXDR(nonce: nonce)
        let encoded = try XDREncoder.encode(nonceKey)
        let decoded = try XDRDecoder.decode(SCNonceKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.nonce, nonce)
    }

    func testSCNonceKeyXDRNegativeNonce() throws {
        let nonce: Int64 = -9876543210
        let nonceKey = SCNonceKeyXDR(nonce: nonce)
        let encoded = try XDREncoder.encode(nonceKey)
        let decoded = try XDRDecoder.decode(SCNonceKeyXDR.self, data: encoded)

        XCTAssertEqual(decoded.nonce, nonce)
    }

    // MARK: - SCValXDR Basic Types Tests

    func testSCValXDRBool() throws {
        let testCases: [(Bool, Bool)] = [(true, true), (false, false)]

        for (input, expected) in testCases {
            let val = SCValXDR.bool(input)
            let encoded = try XDREncoder.encode(val)
            let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

            XCTAssertTrue(decoded.isBool)
            XCTAssertEqual(decoded.bool, expected)
        }
    }

    func testSCValXDRVoid() throws {
        let val = SCValXDR.void
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isVoid)
    }

    func testSCValXDRU32() throws {
        let testCases: [UInt32] = [0, 12345, UInt32.max]

        for input in testCases {
            let val = SCValXDR.u32(input)
            let encoded = try XDREncoder.encode(val)
            let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

            XCTAssertTrue(decoded.isU32)
            XCTAssertEqual(decoded.u32, input)
        }
    }

    func testSCValXDRI32() throws {
        let testCases: [Int32] = [0, 12345, -12345, Int32.min, Int32.max]

        for input in testCases {
            let val = SCValXDR.i32(input)
            let encoded = try XDREncoder.encode(val)
            let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

            XCTAssertTrue(decoded.isI32)
            XCTAssertEqual(decoded.i32, input)
        }
    }

    func testSCValXDRU64() throws {
        let testCases: [UInt64] = [0, 9876543210, UInt64.max]

        for input in testCases {
            let val = SCValXDR.u64(input)
            let encoded = try XDREncoder.encode(val)
            let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

            XCTAssertTrue(decoded.isU64)
            XCTAssertEqual(decoded.u64, input)
        }
    }

    func testSCValXDRI64() throws {
        let testCases: [Int64] = [0, 9876543210, -9876543210, Int64.min, Int64.max]

        for input in testCases {
            let val = SCValXDR.i64(input)
            let encoded = try XDREncoder.encode(val)
            let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

            XCTAssertTrue(decoded.isI64)
            XCTAssertEqual(decoded.i64, input)
        }
    }

    func testSCValXDRTimepoint() throws {
        let timepoint: UInt64 = 1234567890
        let val = SCValXDR.timepoint(timepoint)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isTimepoint)
        XCTAssertEqual(decoded.timepoint, timepoint)
    }

    func testSCValXDRDuration() throws {
        let duration: UInt64 = 3600
        let val = SCValXDR.duration(duration)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isDuration)
        XCTAssertEqual(decoded.duration, duration)
    }

    // MARK: - SCValXDR Big Integer Tests

    func testSCValXDRU128() throws {
        let u128 = UInt128PartsXDR(hi: 100, lo: 200)
        let val = SCValXDR.u128(u128)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isU128)
        XCTAssertEqual(decoded.u128?.hi, 100)
        XCTAssertEqual(decoded.u128?.lo, 200)
    }

    func testSCValXDRI128() throws {
        let i128 = Int128PartsXDR(hi: -100, lo: 200)
        let val = SCValXDR.i128(i128)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isI128)
        XCTAssertEqual(decoded.i128?.hi, -100)
        XCTAssertEqual(decoded.i128?.lo, 200)
    }

    func testSCValXDRU256() throws {
        let u256 = UInt256PartsXDR(hiHi: 10, hiLo: 20, loHi: 30, loLo: 40)
        let val = SCValXDR.u256(u256)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isU256)
        XCTAssertEqual(decoded.u256?.hiHi, 10)
        XCTAssertEqual(decoded.u256?.hiLo, 20)
        XCTAssertEqual(decoded.u256?.loHi, 30)
        XCTAssertEqual(decoded.u256?.loLo, 40)
    }

    func testSCValXDRI256() throws {
        let i256 = Int256PartsXDR(hiHi: -10, hiLo: 20, loHi: 30, loLo: 40)
        let val = SCValXDR.i256(i256)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isI256)
        XCTAssertEqual(decoded.i256?.hiHi, -10)
        XCTAssertEqual(decoded.i256?.hiLo, 20)
        XCTAssertEqual(decoded.i256?.loHi, 30)
        XCTAssertEqual(decoded.i256?.loLo, 40)
    }

    func testSCValXDRU128StringConversion() throws {
        let val = try SCValXDR.u128(stringValue: "340282366920938463463374607431768211455")
        XCTAssertTrue(val.isU128)

        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertNotNil(decoded.u128String)
    }

    func testSCValXDRI128StringConversion() throws {
        let val = try SCValXDR.i128(stringValue: "-170141183460469231731687303715884105728")
        XCTAssertTrue(val.isI128)

        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertNotNil(decoded.i128String)
    }

    func testSCValXDRU256StringConversion() throws {
        let val = try SCValXDR.u256(stringValue: "12345678901234567890")
        XCTAssertTrue(val.isU256)

        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertNotNil(decoded.u256String)
    }

    func testSCValXDRI256StringConversion() throws {
        let val = try SCValXDR.i256(stringValue: "-12345678901234567890")
        XCTAssertTrue(val.isI256)

        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertNotNil(decoded.i256String)
    }

    func testSCValXDRU128DataConversion() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
        let val = try SCValXDR.u128(data: data)
        XCTAssertTrue(val.isU128)

        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertNotNil(decoded.u128)
    }

    func testSCValXDRI128DataConversion() throws {
        let data = Data([0x01, 0x02, 0x03, 0x04])
        let val = try SCValXDR.i128(data: data)
        XCTAssertTrue(val.isI128)

        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertNotNil(decoded.i128)
    }

    // MARK: - SCValXDR Data Types Tests

    func testSCValXDRBytes() throws {
        let bytes = Data([0x01, 0x02, 0x03, 0x04])
        let val = SCValXDR.bytes(bytes)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isBytes)
        XCTAssertEqual(decoded.bytes, bytes)
    }

    func testSCValXDRBytesEmpty() throws {
        let bytes = Data()
        let val = SCValXDR.bytes(bytes)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isBytes)
        XCTAssertEqual(decoded.bytes, bytes)
    }

    func testSCValXDRString() throws {
        let string = "Hello Stellar"
        let val = SCValXDR.string(string)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isString)
        XCTAssertEqual(decoded.string, string)
    }

    func testSCValXDRStringEmpty() throws {
        let string = ""
        let val = SCValXDR.string(string)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isString)
        XCTAssertEqual(decoded.string, string)
    }

    func testSCValXDRSymbol() throws {
        let symbol = "USDC"
        let val = SCValXDR.symbol(symbol)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isSymbol)
        XCTAssertEqual(decoded.symbol, symbol)
    }

    // MARK: - SCValXDR Collection Types Tests

    func testSCValXDRVec() throws {
        let vec = [SCValXDR.u32(1), SCValXDR.u32(2), SCValXDR.u32(3)]
        let val = SCValXDR.vec(vec)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isVec)
        XCTAssertEqual(decoded.vec?.count, 3)
    }

    func testSCValXDRVecNil() throws {
        let val = SCValXDR.vec(nil)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isVec)
        XCTAssertNil(decoded.vec)
    }

    func testSCValXDRVecEmpty() throws {
        let val = SCValXDR.vec([])
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isVec)
        XCTAssertEqual(decoded.vec?.count, 0)
    }

    func testSCValXDRMap() throws {
        let map = [
            SCMapEntryXDR(key: SCValXDR.symbol("key1"), val: SCValXDR.u32(100)),
            SCMapEntryXDR(key: SCValXDR.symbol("key2"), val: SCValXDR.u32(200))
        ]
        let val = SCValXDR.map(map)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isMap)
        XCTAssertEqual(decoded.map?.count, 2)
    }

    func testSCValXDRMapNil() throws {
        let val = SCValXDR.map(nil)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isMap)
        XCTAssertNil(decoded.map)
    }

    func testSCValXDRMapEmpty() throws {
        let val = SCValXDR.map([])
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isMap)
        XCTAssertEqual(decoded.map?.count, 0)
    }

    // MARK: - SCValXDR Address Tests

    func testSCValXDRAddress() throws {
        let accountId = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let address = try SCAddressXDR(accountId: accountId)
        let val = SCValXDR.address(address)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isAddress)
        XCTAssertEqual(decoded.address?.accountId, accountId)
    }

    // MARK: - SCValXDR Contract Instance Tests

    func testSCValXDRContractInstance() throws {
        let wasmHash = WrappedData32(Data(repeating: 0xFF, count: 32))
        let executable = ContractExecutableXDR.wasm(wasmHash)
        let contractInstance = SCContractInstanceXDR(executable: executable, storage: nil)
        let val = SCValXDR.contractInstance(contractInstance)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isContractInstance)
        XCTAssertNotNil(decoded.contractInstance)
    }

    func testSCValXDRLedgerKeyContractInstance() throws {
        let val = SCValXDR.ledgerKeyContractInstance
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isLedgerKeyContractInstance)
    }

    func testSCValXDRLedgerKeyNonce() throws {
        let nonceKey = SCNonceKeyXDR(nonce: 999)
        let val = SCValXDR.ledgerKeyNonce(nonceKey)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isLedgerKeyNonce)
        XCTAssertEqual(decoded.ledgerKeyNonce?.nonce, 999)
    }

    func testSCValXDRError() throws {
        let error = SCErrorXDR.budget
        let val = SCValXDR.error(error)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isError)
        XCTAssertNotNil(decoded.error)
    }

    func testSCValXDRFromBase64() throws {
        let val = SCValXDR.u32(12345)
        let encoded = try XDREncoder.encode(val)
        let base64 = Data(encoded).base64EncodedString()

        let decoded = try SCValXDR.fromXdr(base64: base64)
        XCTAssertTrue(decoded.isU32)
        XCTAssertEqual(decoded.u32, 12345)
    }

    func testSCValXDRAccountEd25519Signature() throws {
        let accountId = "GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ"
        let publicKey = try PublicKey(accountId: accountId)
        let signature = Data(repeating: 0xAB, count: 64)
        let accountSig = AccountEd25519Signature(publicKey: publicKey, signature: [UInt8](signature))

        let val = SCValXDR(accountEd25519Signature: accountSig)
        let encoded = try XDREncoder.encode(val)
        let decoded = try XDRDecoder.decode(SCValXDR.self, data: encoded)

        XCTAssertTrue(decoded.isMap)
        XCTAssertEqual(decoded.map?.count, 2)
    }

    // MARK: - SCMapEntryXDR Tests

    func testSCMapEntryXDR() throws {
        let entry = SCMapEntryXDR(key: SCValXDR.symbol("name"), val: SCValXDR.string("value"))
        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCMapEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.key.symbol, "name")
        XCTAssertEqual(decoded.val.string, "value")
    }

    // MARK: - ContractExecutableXDR Tests

    func testContractExecutableXDRWasm() throws {
        let wasmHash = WrappedData32(Data(repeating: 0xAB, count: 32))
        let executable = ContractExecutableXDR.wasm(wasmHash)
        let encoded = try XDREncoder.encode(executable)
        let decoded = try XDRDecoder.decode(ContractExecutableXDR.self, data: encoded)

        XCTAssertEqual(decoded.isWasm, true)
        XCTAssertEqual(decoded.wasm?.wrapped, wasmHash.wrapped)
        XCTAssertEqual(decoded.isStellarAsset, false)
    }

    func testContractExecutableXDRToken() throws {
        let executable = ContractExecutableXDR.token
        let encoded = try XDREncoder.encode(executable)
        let decoded = try XDRDecoder.decode(ContractExecutableXDR.self, data: encoded)

        XCTAssertEqual(decoded.isWasm, false)
        XCTAssertEqual(decoded.isStellarAsset, true)
        XCTAssertNil(decoded.wasm)
    }

    func testContractExecutableXDRTypeDiscriminants() {
        let wasmExec = ContractExecutableXDR.wasm(WrappedData32(Data(repeating: 0, count: 32)))
        XCTAssertEqual(wasmExec.type(), ContractExecutableType.wasm.rawValue)

        let tokenExec = ContractExecutableXDR.token
        XCTAssertEqual(tokenExec.type(), ContractExecutableType.stellarAsset.rawValue)
    }

    // MARK: - Int128PartsXDR Tests

    func testInt128PartsXDR() throws {
        let parts = Int128PartsXDR(hi: -123, lo: 456)
        let encoded = try XDREncoder.encode(parts)
        let decoded = try XDRDecoder.decode(Int128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, -123)
        XCTAssertEqual(decoded.lo, 456)
    }

    // MARK: - UInt128PartsXDR Tests

    func testUInt128PartsXDR() throws {
        let parts = UInt128PartsXDR(hi: 123, lo: 456)
        let encoded = try XDREncoder.encode(parts)
        let decoded = try XDRDecoder.decode(UInt128PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hi, 123)
        XCTAssertEqual(decoded.lo, 456)
    }

    // MARK: - Int256PartsXDR Tests

    func testInt256PartsXDR() throws {
        let parts = Int256PartsXDR(hiHi: -10, hiLo: 20, loHi: 30, loLo: 40)
        let encoded = try XDREncoder.encode(parts)
        let decoded = try XDRDecoder.decode(Int256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, -10)
        XCTAssertEqual(decoded.hiLo, 20)
        XCTAssertEqual(decoded.loHi, 30)
        XCTAssertEqual(decoded.loLo, 40)
    }

    // MARK: - UInt256PartsXDR Tests

    func testUInt256PartsXDR() throws {
        let parts = UInt256PartsXDR(hiHi: 10, hiLo: 20, loHi: 30, loLo: 40)
        let encoded = try XDREncoder.encode(parts)
        let decoded = try XDRDecoder.decode(UInt256PartsXDR.self, data: encoded)

        XCTAssertEqual(decoded.hiHi, 10)
        XCTAssertEqual(decoded.hiLo, 20)
        XCTAssertEqual(decoded.loHi, 30)
        XCTAssertEqual(decoded.loLo, 40)
    }

    // MARK: - SCContractInstanceXDR Tests

    func testSCContractInstanceXDRWithWasm() throws {
        let wasmHash = WrappedData32(Data(repeating: 0xCD, count: 32))
        let executable = ContractExecutableXDR.wasm(wasmHash)
        let storage = [SCMapEntryXDR(key: SCValXDR.symbol("key"), val: SCValXDR.u32(100))]
        let instance = SCContractInstanceXDR(executable: executable, storage: storage)

        let encoded = try XDREncoder.encode(instance)
        let decoded = try XDRDecoder.decode(SCContractInstanceXDR.self, data: encoded)

        XCTAssertNotNil(decoded.storage)
        XCTAssertEqual(decoded.storage?.count, 1)
    }

    func testSCContractInstanceXDRWithToken() throws {
        let executable = ContractExecutableXDR.token
        let instance = SCContractInstanceXDR(executable: executable, storage: nil)

        let encoded = try XDREncoder.encode(instance)
        let decoded = try XDRDecoder.decode(SCContractInstanceXDR.self, data: encoded)

        XCTAssertNil(decoded.storage)
        XCTAssertEqual(decoded.executable.isStellarAsset, true)
    }

    func testSCContractInstanceXDRWithEmptyStorage() throws {
        let executable = ContractExecutableXDR.token
        let instance = SCContractInstanceXDR(executable: executable, storage: [])

        let encoded = try XDREncoder.encode(instance)
        let decoded = try XDRDecoder.decode(SCContractInstanceXDR.self, data: encoded)

        XCTAssertNotNil(decoded.storage)
        XCTAssertEqual(decoded.storage?.count, 0)
    }

    // MARK: - SCValXDR Type Checking Tests

    func testSCValXDRTypeCheckers() throws {
        let testCases: [(SCValXDR, String)] = [
            (.bool(true), "isBool"),
            (.void, "isVoid"),
            (.u32(0), "isU32"),
            (.i32(0), "isI32"),
            (.u64(0), "isU64"),
            (.i64(0), "isI64"),
            (.timepoint(0), "isTimepoint"),
            (.duration(0), "isDuration"),
            (.u128(UInt128PartsXDR(hi: 0, lo: 0)), "isU128"),
            (.i128(Int128PartsXDR(hi: 0, lo: 0)), "isI128"),
            (.u256(UInt256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 0)), "isU256"),
            (.i256(Int256PartsXDR(hiHi: 0, hiLo: 0, loHi: 0, loLo: 0)), "isI256"),
            (.bytes(Data()), "isBytes"),
            (.string(""), "isString"),
            (.symbol(""), "isSymbol"),
            (.vec(nil), "isVec"),
            (.map(nil), "isMap"),
            (.ledgerKeyContractInstance, "isLedgerKeyContractInstance"),
            (.ledgerKeyNonce(SCNonceKeyXDR(nonce: 0)), "isLedgerKeyNonce")
        ]

        for (val, expectedType) in testCases {
            switch expectedType {
            case "isBool": XCTAssertTrue(val.isBool)
            case "isVoid": XCTAssertTrue(val.isVoid)
            case "isU32": XCTAssertTrue(val.isU32)
            case "isI32": XCTAssertTrue(val.isI32)
            case "isU64": XCTAssertTrue(val.isU64)
            case "isI64": XCTAssertTrue(val.isI64)
            case "isTimepoint": XCTAssertTrue(val.isTimepoint)
            case "isDuration": XCTAssertTrue(val.isDuration)
            case "isU128": XCTAssertTrue(val.isU128)
            case "isI128": XCTAssertTrue(val.isI128)
            case "isU256": XCTAssertTrue(val.isU256)
            case "isI256": XCTAssertTrue(val.isI256)
            case "isBytes": XCTAssertTrue(val.isBytes)
            case "isString": XCTAssertTrue(val.isString)
            case "isSymbol": XCTAssertTrue(val.isSymbol)
            case "isVec": XCTAssertTrue(val.isVec)
            case "isMap": XCTAssertTrue(val.isMap)
            case "isLedgerKeyContractInstance": XCTAssertTrue(val.isLedgerKeyContractInstance)
            case "isLedgerKeyNonce": XCTAssertTrue(val.isLedgerKeyNonce)
            default: XCTFail("Unknown type: \(expectedType)")
            }
        }
    }
}
