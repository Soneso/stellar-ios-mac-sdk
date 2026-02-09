//
//  SCValUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class SCValUnitTests: XCTestCase {

    // MARK: - Bool Tests

    func testSCValBool() throws {
        // Test true value
        let trueVal = SCValXDR.bool(true)
        XCTAssertNotNil(trueVal.xdrEncoded)

        let trueDecoded = try SCValXDR.fromXdr(base64: trueVal.xdrEncoded!)
        if case .bool(let value) = trueDecoded {
            XCTAssertTrue(value)
        } else {
            XCTFail("Expected bool type")
        }

        // Test false value
        let falseVal = SCValXDR.bool(false)
        XCTAssertNotNil(falseVal.xdrEncoded)

        let falseDecoded = try SCValXDR.fromXdr(base64: falseVal.xdrEncoded!)
        if case .bool(let value) = falseDecoded {
            XCTAssertFalse(value)
        } else {
            XCTFail("Expected bool type")
        }
    }

    // MARK: - Void Tests

    func testSCValVoid() throws {
        let voidVal = SCValXDR.void
        XCTAssertNotNil(voidVal.xdrEncoded)

        let decoded = try SCValXDR.fromXdr(base64: voidVal.xdrEncoded!)
        if case .void = decoded {
            // Success
        } else {
            XCTFail("Expected void type")
        }
    }

    // MARK: - U32 Tests

    func testSCValU32() throws {
        // Test zero
        let zeroVal = SCValXDR.u32(0)
        XCTAssertNotNil(zeroVal.xdrEncoded)

        let zeroDecoded = try SCValXDR.fromXdr(base64: zeroVal.xdrEncoded!)
        if case .u32(let value) = zeroDecoded {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected u32 type")
        }

        // Test max value
        let maxVal = SCValXDR.u32(UInt32.max)
        XCTAssertNotNil(maxVal.xdrEncoded)

        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        if case .u32(let value) = maxDecoded {
            XCTAssertEqual(value, UInt32.max)
        } else {
            XCTFail("Expected u32 type")
        }

        // Test arbitrary value
        let arbVal = SCValXDR.u32(12345)
        XCTAssertNotNil(arbVal.xdrEncoded)

        let arbDecoded = try SCValXDR.fromXdr(base64: arbVal.xdrEncoded!)
        if case .u32(let value) = arbDecoded {
            XCTAssertEqual(value, 12345)
        } else {
            XCTFail("Expected u32 type")
        }
    }

    // MARK: - I32 Tests

    func testSCValI32() throws {
        // Test positive value
        let posVal = SCValXDR.i32(12345)
        XCTAssertNotNil(posVal.xdrEncoded)

        let posDecoded = try SCValXDR.fromXdr(base64: posVal.xdrEncoded!)
        if case .i32(let value) = posDecoded {
            XCTAssertEqual(value, 12345)
        } else {
            XCTFail("Expected i32 type")
        }

        // Test negative value
        let negVal = SCValXDR.i32(-12345)
        XCTAssertNotNil(negVal.xdrEncoded)

        let negDecoded = try SCValXDR.fromXdr(base64: negVal.xdrEncoded!)
        if case .i32(let value) = negDecoded {
            XCTAssertEqual(value, -12345)
        } else {
            XCTFail("Expected i32 type")
        }

        // Test zero
        let zeroVal = SCValXDR.i32(0)
        let zeroDecoded = try SCValXDR.fromXdr(base64: zeroVal.xdrEncoded!)
        if case .i32(let value) = zeroDecoded {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected i32 type")
        }

        // Test max value
        let maxVal = SCValXDR.i32(Int32.max)
        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        if case .i32(let value) = maxDecoded {
            XCTAssertEqual(value, Int32.max)
        } else {
            XCTFail("Expected i32 type")
        }

        // Test min value
        let minVal = SCValXDR.i32(Int32.min)
        let minDecoded = try SCValXDR.fromXdr(base64: minVal.xdrEncoded!)
        if case .i32(let value) = minDecoded {
            XCTAssertEqual(value, Int32.min)
        } else {
            XCTFail("Expected i32 type")
        }
    }

    // MARK: - U64 Tests

    func testSCValU64() throws {
        // Test zero
        let zeroVal = SCValXDR.u64(0)
        XCTAssertNotNil(zeroVal.xdrEncoded)

        let zeroDecoded = try SCValXDR.fromXdr(base64: zeroVal.xdrEncoded!)
        if case .u64(let value) = zeroDecoded {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected u64 type")
        }

        // Test max value
        let maxVal = SCValXDR.u64(UInt64.max)
        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        if case .u64(let value) = maxDecoded {
            XCTAssertEqual(value, UInt64.max)
        } else {
            XCTFail("Expected u64 type")
        }

        // Test arbitrary large value
        let arbVal = SCValXDR.u64(1234567890123456789)
        let arbDecoded = try SCValXDR.fromXdr(base64: arbVal.xdrEncoded!)
        if case .u64(let value) = arbDecoded {
            XCTAssertEqual(value, 1234567890123456789)
        } else {
            XCTFail("Expected u64 type")
        }
    }

    // MARK: - I64 Tests

    func testSCValI64() throws {
        // Test positive value
        let posVal = SCValXDR.i64(1234567890123456789)
        let posDecoded = try SCValXDR.fromXdr(base64: posVal.xdrEncoded!)
        if case .i64(let value) = posDecoded {
            XCTAssertEqual(value, 1234567890123456789)
        } else {
            XCTFail("Expected i64 type")
        }

        // Test negative value
        let negVal = SCValXDR.i64(-1234567890123456789)
        let negDecoded = try SCValXDR.fromXdr(base64: negVal.xdrEncoded!)
        if case .i64(let value) = negDecoded {
            XCTAssertEqual(value, -1234567890123456789)
        } else {
            XCTFail("Expected i64 type")
        }

        // Test zero
        let zeroVal = SCValXDR.i64(0)
        let zeroDecoded = try SCValXDR.fromXdr(base64: zeroVal.xdrEncoded!)
        if case .i64(let value) = zeroDecoded {
            XCTAssertEqual(value, 0)
        } else {
            XCTFail("Expected i64 type")
        }

        // Test max and min values
        let maxVal = SCValXDR.i64(Int64.max)
        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        if case .i64(let value) = maxDecoded {
            XCTAssertEqual(value, Int64.max)
        } else {
            XCTFail("Expected i64 type")
        }

        let minVal = SCValXDR.i64(Int64.min)
        let minDecoded = try SCValXDR.fromXdr(base64: minVal.xdrEncoded!)
        if case .i64(let value) = minDecoded {
            XCTAssertEqual(value, Int64.min)
        } else {
            XCTFail("Expected i64 type")
        }
    }

    // MARK: - U128 Tests

    func testSCValU128() throws {
        // Test small value
        let smallVal = try SCValXDR.u128(stringValue: "12345")
        XCTAssertEqual(smallVal.u128String, "12345")

        let smallDecoded = try SCValXDR.fromXdr(base64: smallVal.xdrEncoded!)
        XCTAssertEqual(smallDecoded.u128String, "12345")

        // Test max u128 value
        let maxU128 = "340282366920938463463374607431768211455"
        let maxVal = try SCValXDR.u128(stringValue: maxU128)
        XCTAssertEqual(maxVal.u128String, maxU128)

        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        XCTAssertEqual(maxDecoded.u128String, maxU128)

        // Test zero
        let zeroVal = try SCValXDR.u128(stringValue: "0")
        XCTAssertEqual(zeroVal.u128String, "0")

        let zeroDecoded = try SCValXDR.fromXdr(base64: zeroVal.xdrEncoded!)
        XCTAssertEqual(zeroDecoded.u128String, "0")
    }

    // MARK: - I128 Tests

    func testSCValI128() throws {
        // Test positive value
        let posVal = try SCValXDR.i128(stringValue: "12345")
        XCTAssertEqual(posVal.i128String, "12345")

        let posDecoded = try SCValXDR.fromXdr(base64: posVal.xdrEncoded!)
        XCTAssertEqual(posDecoded.i128String, "12345")

        // Test negative value
        let negVal = try SCValXDR.i128(stringValue: "-12345")
        XCTAssertEqual(negVal.i128String, "-12345")

        let negDecoded = try SCValXDR.fromXdr(base64: negVal.xdrEncoded!)
        XCTAssertEqual(negDecoded.i128String, "-12345")

        // Test max i128
        let maxI128 = "170141183460469231731687303715884105727"
        let maxVal = try SCValXDR.i128(stringValue: maxI128)
        XCTAssertEqual(maxVal.i128String, maxI128)

        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        XCTAssertEqual(maxDecoded.i128String, maxI128)

        // Test min i128
        let minI128 = "-170141183460469231731687303715884105728"
        let minVal = try SCValXDR.i128(stringValue: minI128)
        XCTAssertEqual(minVal.i128String, minI128)

        let minDecoded = try SCValXDR.fromXdr(base64: minVal.xdrEncoded!)
        XCTAssertEqual(minDecoded.i128String, minI128)
    }

    // MARK: - U256 Tests

    func testSCValU256() throws {
        // Test small value
        let smallVal = try SCValXDR.u256(stringValue: "12345")
        XCTAssertEqual(smallVal.u256String, "12345")

        let smallDecoded = try SCValXDR.fromXdr(base64: smallVal.xdrEncoded!)
        XCTAssertEqual(smallDecoded.u256String, "12345")

        // Test max u256 value
        let maxU256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        let maxVal = try SCValXDR.u256(stringValue: maxU256)
        XCTAssertEqual(maxVal.u256String, maxU256)

        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        XCTAssertEqual(maxDecoded.u256String, maxU256)
    }

    // MARK: - I256 Tests

    func testSCValI256() throws {
        // Test positive value
        let posVal = try SCValXDR.i256(stringValue: "12345")
        XCTAssertEqual(posVal.i256String, "12345")

        let posDecoded = try SCValXDR.fromXdr(base64: posVal.xdrEncoded!)
        XCTAssertEqual(posDecoded.i256String, "12345")

        // Test negative value
        let negVal = try SCValXDR.i256(stringValue: "-12345")
        XCTAssertEqual(negVal.i256String, "-12345")

        let negDecoded = try SCValXDR.fromXdr(base64: negVal.xdrEncoded!)
        XCTAssertEqual(negDecoded.i256String, "-12345")

        // Test max i256
        let maxI256 = "57896044618658097711785492504343953926634992332820282019728792003956564819967"
        let maxVal = try SCValXDR.i256(stringValue: maxI256)
        XCTAssertEqual(maxVal.i256String, maxI256)

        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        XCTAssertEqual(maxDecoded.i256String, maxI256)

        // Test min i256
        let minI256 = "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
        let minVal = try SCValXDR.i256(stringValue: minI256)
        XCTAssertEqual(minVal.i256String, minI256)

        let minDecoded = try SCValXDR.fromXdr(base64: minVal.xdrEncoded!)
        XCTAssertEqual(minDecoded.i256String, minI256)
    }

    // MARK: - Bytes Tests

    func testSCValBytes() throws {
        // Test empty bytes
        let emptyVal = SCValXDR.bytes(Data())
        XCTAssertNotNil(emptyVal.xdrEncoded)

        let emptyDecoded = try SCValXDR.fromXdr(base64: emptyVal.xdrEncoded!)
        if case .bytes(let data) = emptyDecoded {
            XCTAssertEqual(data.count, 0)
        } else {
            XCTFail("Expected bytes type")
        }

        // Test with actual bytes
        let testData = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let dataVal = SCValXDR.bytes(testData)
        XCTAssertNotNil(dataVal.xdrEncoded)

        let dataDecoded = try SCValXDR.fromXdr(base64: dataVal.xdrEncoded!)
        if case .bytes(let data) = dataDecoded {
            XCTAssertEqual(data, testData)
        } else {
            XCTFail("Expected bytes type")
        }

        // Test with larger byte array
        let largeData = Data(repeating: 0xFF, count: 256)
        let largeVal = SCValXDR.bytes(largeData)
        let largeDecoded = try SCValXDR.fromXdr(base64: largeVal.xdrEncoded!)
        if case .bytes(let data) = largeDecoded {
            XCTAssertEqual(data, largeData)
        } else {
            XCTFail("Expected bytes type")
        }
    }

    // MARK: - String Tests

    func testSCValString() throws {
        // Test empty string
        let emptyVal = SCValXDR.string("")
        XCTAssertNotNil(emptyVal.xdrEncoded)

        let emptyDecoded = try SCValXDR.fromXdr(base64: emptyVal.xdrEncoded!)
        if case .string(let str) = emptyDecoded {
            XCTAssertEqual(str, "")
        } else {
            XCTFail("Expected string type")
        }

        // Test simple string
        let simpleVal = SCValXDR.string("hello")
        let simpleDecoded = try SCValXDR.fromXdr(base64: simpleVal.xdrEncoded!)
        if case .string(let str) = simpleDecoded {
            XCTAssertEqual(str, "hello")
        } else {
            XCTFail("Expected string type")
        }

        // Test string with spaces and special characters
        let complexVal = SCValXDR.string("Hello World! @#$%")
        let complexDecoded = try SCValXDR.fromXdr(base64: complexVal.xdrEncoded!)
        if case .string(let str) = complexDecoded {
            XCTAssertEqual(str, "Hello World! @#$%")
        } else {
            XCTFail("Expected string type")
        }

        // Test longer string
        let longString = "This is a longer string to test encoding and decoding of SCVal string types"
        let longVal = SCValXDR.string(longString)
        let longDecoded = try SCValXDR.fromXdr(base64: longVal.xdrEncoded!)
        if case .string(let str) = longDecoded {
            XCTAssertEqual(str, longString)
        } else {
            XCTFail("Expected string type")
        }
    }

    // MARK: - Symbol Tests

    func testSCValSymbol() throws {
        // Test simple symbol
        let symbolVal = SCValXDR.symbol("token")
        XCTAssertNotNil(symbolVal.xdrEncoded)

        let symbolDecoded = try SCValXDR.fromXdr(base64: symbolVal.xdrEncoded!)
        if case .symbol(let sym) = symbolDecoded {
            XCTAssertEqual(sym, "token")
        } else {
            XCTFail("Expected symbol type")
        }

        // Test symbol with underscores
        let underscoreVal = SCValXDR.symbol("balance_of")
        let underscoreDecoded = try SCValXDR.fromXdr(base64: underscoreVal.xdrEncoded!)
        if case .symbol(let sym) = underscoreDecoded {
            XCTAssertEqual(sym, "balance_of")
        } else {
            XCTFail("Expected symbol type")
        }

        // Test empty symbol
        let emptyVal = SCValXDR.symbol("")
        let emptyDecoded = try SCValXDR.fromXdr(base64: emptyVal.xdrEncoded!)
        if case .symbol(let sym) = emptyDecoded {
            XCTAssertEqual(sym, "")
        } else {
            XCTFail("Expected symbol type")
        }
    }

    // MARK: - Vec Tests

    func testSCValVec() throws {
        // Test empty vector
        let emptyVec = SCValXDR.vec([])
        XCTAssertNotNil(emptyVec.xdrEncoded)

        let emptyDecoded = try SCValXDR.fromXdr(base64: emptyVec.xdrEncoded!)
        if case .vec(let arr) = emptyDecoded {
            XCTAssertEqual(arr?.count ?? -1, 0)
        } else {
            XCTFail("Expected vec type")
        }

        // Test vector with primitive values
        let vecWithValues = SCValXDR.vec([
            SCValXDR.u32(1),
            SCValXDR.u32(2),
            SCValXDR.u32(3)
        ])
        XCTAssertNotNil(vecWithValues.xdrEncoded)

        let vecDecoded = try SCValXDR.fromXdr(base64: vecWithValues.xdrEncoded!)
        if case .vec(let arr) = vecDecoded {
            XCTAssertEqual(arr?.count, 3)
            if let elements = arr {
                if case .u32(let val) = elements[0] {
                    XCTAssertEqual(val, 1)
                }
                if case .u32(let val) = elements[1] {
                    XCTAssertEqual(val, 2)
                }
                if case .u32(let val) = elements[2] {
                    XCTAssertEqual(val, 3)
                }
            }
        } else {
            XCTFail("Expected vec type")
        }

        // Test vector with mixed types
        let mixedVec = SCValXDR.vec([
            SCValXDR.u32(42),
            SCValXDR.string("test"),
            SCValXDR.bool(true)
        ])
        let mixedDecoded = try SCValXDR.fromXdr(base64: mixedVec.xdrEncoded!)
        if case .vec(let arr) = mixedDecoded {
            XCTAssertEqual(arr?.count, 3)
        } else {
            XCTFail("Expected vec type")
        }
    }

    // MARK: - Map Tests

    func testSCValMap() throws {
        // Test empty map
        let emptyMap = SCValXDR.map([])
        XCTAssertNotNil(emptyMap.xdrEncoded)

        let emptyDecoded = try SCValXDR.fromXdr(base64: emptyMap.xdrEncoded!)
        if case .map(let entries) = emptyDecoded {
            XCTAssertEqual(entries?.count ?? -1, 0)
        } else {
            XCTFail("Expected map type")
        }

        // Test map with entries
        let entry1 = SCMapEntryXDR(key: SCValXDR.symbol("key1"), val: SCValXDR.u32(100))
        let entry2 = SCMapEntryXDR(key: SCValXDR.symbol("key2"), val: SCValXDR.string("value"))

        let mapWithEntries = SCValXDR.map([entry1, entry2])
        XCTAssertNotNil(mapWithEntries.xdrEncoded)

        let mapDecoded = try SCValXDR.fromXdr(base64: mapWithEntries.xdrEncoded!)
        if case .map(let entries) = mapDecoded {
            XCTAssertEqual(entries?.count, 2)
            if let mapEntries = entries {
                if case .symbol(let key) = mapEntries[0].key {
                    XCTAssertEqual(key, "key1")
                }
                if case .u32(let val) = mapEntries[0].val {
                    XCTAssertEqual(val, 100)
                }
            }
        } else {
            XCTFail("Expected map type")
        }
    }

    // MARK: - Address Tests

    func testSCValAddress() throws {
        // Test account address
        let accountId = "GBDQ3KSNQ4ZRJFQFYAOBQJF7FCCR5MQUUTF6FJ6OHB4DMFK4YA5KTZLV"
        let address = try SCAddressXDR(accountId: accountId)
        let addressVal = SCValXDR.address(address)

        XCTAssertNotNil(addressVal.xdrEncoded)

        let addressDecoded = try SCValXDR.fromXdr(base64: addressVal.xdrEncoded!)
        if case .address(let addr) = addressDecoded {
            // Verify account ID is present and has correct format (starts with G)
            XCTAssertNotNil(addr.accountId)
            XCTAssertTrue(addr.accountId?.hasPrefix("G") ?? false)
        } else {
            XCTFail("Expected address type")
        }

        // Test contract address
        let contractId = "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC"
        let contractAddress = try SCAddressXDR(contractId: contractId)
        let contractVal = SCValXDR.address(contractAddress)

        XCTAssertNotNil(contractVal.xdrEncoded)

        let contractDecoded = try SCValXDR.fromXdr(base64: contractVal.xdrEncoded!)
        if case .address(let addr) = contractDecoded {
            // Contract IDs are stored as hex internally
            XCTAssertNotNil(addr.contractId)
        } else {
            XCTFail("Expected address type")
        }
    }

    // MARK: - Timepoint Tests

    func testSCValTimepoint() throws {
        // Test current timestamp
        let timestamp: UInt64 = 1609459200 // 2021-01-01 00:00:00 UTC
        let timepointVal = SCValXDR.timepoint(timestamp)

        XCTAssertNotNil(timepointVal.xdrEncoded)

        let timepointDecoded = try SCValXDR.fromXdr(base64: timepointVal.xdrEncoded!)
        if case .timepoint(let ts) = timepointDecoded {
            XCTAssertEqual(ts, timestamp)
        } else {
            XCTFail("Expected timepoint type")
        }

        // Test zero timepoint
        let zeroVal = SCValXDR.timepoint(0)
        let zeroDecoded = try SCValXDR.fromXdr(base64: zeroVal.xdrEncoded!)
        if case .timepoint(let ts) = zeroDecoded {
            XCTAssertEqual(ts, 0)
        } else {
            XCTFail("Expected timepoint type")
        }

        // Test max timepoint
        let maxVal = SCValXDR.timepoint(UInt64.max)
        let maxDecoded = try SCValXDR.fromXdr(base64: maxVal.xdrEncoded!)
        if case .timepoint(let ts) = maxDecoded {
            XCTAssertEqual(ts, UInt64.max)
        } else {
            XCTFail("Expected timepoint type")
        }
    }

    // MARK: - Duration Tests

    func testSCValDuration() throws {
        // Test duration in seconds
        let duration: UInt64 = 3600 // 1 hour
        let durationVal = SCValXDR.duration(duration)

        XCTAssertNotNil(durationVal.xdrEncoded)

        let durationDecoded = try SCValXDR.fromXdr(base64: durationVal.xdrEncoded!)
        if case .duration(let d) = durationDecoded {
            XCTAssertEqual(d, duration)
        } else {
            XCTFail("Expected duration type")
        }

        // Test zero duration
        let zeroVal = SCValXDR.duration(0)
        let zeroDecoded = try SCValXDR.fromXdr(base64: zeroVal.xdrEncoded!)
        if case .duration(let d) = zeroDecoded {
            XCTAssertEqual(d, 0)
        } else {
            XCTFail("Expected duration type")
        }

        // Test large duration
        let largeDuration: UInt64 = 31536000 // 1 year in seconds
        let largeVal = SCValXDR.duration(largeDuration)
        let largeDecoded = try SCValXDR.fromXdr(base64: largeVal.xdrEncoded!)
        if case .duration(let d) = largeDecoded {
            XCTAssertEqual(d, largeDuration)
        } else {
            XCTFail("Expected duration type")
        }
    }
}
