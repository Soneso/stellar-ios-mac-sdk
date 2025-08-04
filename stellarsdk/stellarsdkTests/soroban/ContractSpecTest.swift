//
//  ContractSpecTest.swift
//  stellarsdkTests
//
//  Created by Christian Rogobete.
//  Copyright © 2025 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

class ContractSpecTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testContractSpecBasicTypes() throws {
        // Create a simple function spec for testing
        let inputs = [
            SCSpecFunctionInputV0XDR(doc: "", name: "val", type: SCSpecTypeDefXDR.bool)
        ]
        let outputs = [SCSpecTypeDefXDR.void]
        let functionSpec = SCSpecFunctionV0XDR(doc: "Test function", name: "testFunc", inputs: inputs, outputs: outputs)
        let entry = SCSpecEntryXDR.functionV0(functionSpec)
        
        let spec = ContractSpec(entries: [entry])
        
        // Test basic function finding
        XCTAssertNotNil(spec.getFunc(name: "testFunc"))
        XCTAssertNil(spec.getFunc(name: "nonExistentFunc"))
        XCTAssertEqual(spec.funcs().count, 1)
        XCTAssertEqual(spec.funcs().first?.name, "testFunc")
        
        // Test funcArgsToXdrSCValues with boolean
        let args = ["val": true]
        let scValues = try spec.funcArgsToXdrSCValues(name: "testFunc", args: args)
        XCTAssertEqual(scValues.count, 1)
        
        if case .bool(let boolVal) = scValues[0] {
            XCTAssertTrue(boolVal)
        } else {
            XCTFail("Expected boolean SCVal")
        }
    }
    
    func testContractSpecNumberTypes() throws {
        let spec = ContractSpec(entries: [])
        
        // Test u32 conversion
        let u32Val = try spec.nativeToXdrSCVal(val: 42, ty: SCSpecTypeDefXDR.u32)
        if case .u32(let val) = u32Val {
            XCTAssertEqual(val, 42)
        } else {
            XCTFail("Expected u32 SCVal")
        }
        
        // Test i32 conversion
        let i32Val = try spec.nativeToXdrSCVal(val: -42, ty: SCSpecTypeDefXDR.i32)
        if case .i32(let val) = i32Val {
            XCTAssertEqual(val, -42)
        } else {
            XCTFail("Expected i32 SCVal")
        }
        
        // Test u64 conversion
        let u64Val = try spec.nativeToXdrSCVal(val: 1000, ty: SCSpecTypeDefXDR.u64)
        if case .u64(let val) = u64Val {
            XCTAssertEqual(val, 1000)
        } else {
            XCTFail("Expected u64 SCVal")
        }
        
        // Test i64 conversion
        let i64Val = try spec.nativeToXdrSCVal(val: -1000, ty: SCSpecTypeDefXDR.i64)
        if case .i64(let val) = i64Val {
            XCTAssertEqual(val, -1000)
        } else {
            XCTFail("Expected i64 SCVal")
        }
    }
    
    func testContractSpecStringTypes() throws {
        let spec = ContractSpec(entries: [])
        
        // Test string conversion
        let stringVal = try spec.nativeToXdrSCVal(val: "hello", ty: SCSpecTypeDefXDR.string)
        if case .string(let val) = stringVal {
            XCTAssertEqual(val, "hello")
        } else {
            XCTFail("Expected string SCVal")
        }
        
        // Test symbol conversion
        let symbolVal = try spec.nativeToXdrSCVal(val: "symbol", ty: SCSpecTypeDefXDR.symbol)
        if case .symbol(let val) = symbolVal {
            XCTAssertEqual(val, "symbol")
        } else {
            XCTFail("Expected symbol SCVal")
        }
        
        // Test bytes conversion
        let bytesVal = try spec.nativeToXdrSCVal(val: "bytes", ty: SCSpecTypeDefXDR.bytes)
        if case .bytes(let val) = bytesVal {
            XCTAssertEqual(String(data: val, encoding: .utf8), "bytes")
        } else {
            XCTFail("Expected bytes SCVal")
        }
    }
    
    func testContractSpecVectorTypes() throws {
        let spec = ContractSpec(entries: [])
        
        // Test vector of strings
        let vecType = SCSpecTypeVecXDR(elementType: SCSpecTypeDefXDR.string)
        let vecTypeDefType = SCSpecTypeDefXDR.vec(vecType)
        
        let vectorVal = try spec.nativeToXdrSCVal(val: ["hello", "world"], ty: vecTypeDefType)
        if case .vec(let vec) = vectorVal {
            XCTAssertEqual(vec?.count, 2)
            if let firstVal = vec?[0], case .string(let str1) = firstVal {
                XCTAssertEqual(str1, "hello")
            } else {
                XCTFail("Expected first element to be 'hello'")
            }
            if let secondVal = vec?[1], case .string(let str2) = secondVal {
                XCTAssertEqual(str2, "world")
            } else {
                XCTFail("Expected second element to be 'world'")
            }
        } else {
            XCTFail("Expected vector SCVal")
        }
    }
    
    func testContractSpecMapTypes() throws {
        let spec = ContractSpec(entries: [])
        
        // Test map of string -> u32
        let mapType = SCSpecTypeMapXDR(keyType: SCSpecTypeDefXDR.string, valueType: SCSpecTypeDefXDR.u32)
        let mapTypeDefType = SCSpecTypeDefXDR.map(mapType)
        
        let mapVal = try spec.nativeToXdrSCVal(val: ["key1": 10, "key2": 20], ty: mapTypeDefType)
        if case .map(let map) = mapVal {
            XCTAssertEqual(map?.count, 2)
            // Note: Order is not guaranteed in maps, so we check for presence
            let keys:[String?] = map?.compactMap { entry in
                if case .string(let key) = entry.key {
                    return key
                } else {
                    return nil
                }
            } ?? []
            XCTAssertTrue(keys.contains("key1"))
            XCTAssertTrue(keys.contains("key2"))
        } else {
            XCTFail("Expected map SCVal")
        }
    }
    
    func testContractSpecOptionTypes() throws {
        let spec = ContractSpec(entries: [])
        
        // Test option with value
        let optionType = SCSpecTypeOptionXDR(valueType: SCSpecTypeDefXDR.string)
        let optionTypeDefType = SCSpecTypeDefXDR.option(optionType)
        
        let optionWithVal = try spec.nativeToXdrSCVal(val: "some_value", ty: optionTypeDefType)
        if case .string(let val) = optionWithVal {
            XCTAssertEqual(val, "some_value")
        } else {
            XCTFail("Expected string SCVal for Some case")
        }
        
        // Test option with nil
        let optionWithNil = try spec.nativeToXdrSCVal(val: nil, ty: optionTypeDefType)
        if case .void = optionWithNil {
            // Success - nil should become void for None case
        } else {
            XCTFail("Expected void SCVal for None case")
        }
    }
    
    func testContractSpecTupleTypes() throws {
        let spec = ContractSpec(entries: [])
        
        // Test tuple of (string, u32)
        let tupleType = SCSpecTypeTupleXDR(valueTypes: [SCSpecTypeDefXDR.string, SCSpecTypeDefXDR.u32])
        let tupleTypeDefType = SCSpecTypeDefXDR.tuple(tupleType)
        
        let tupleVal = try spec.nativeToXdrSCVal(val: ["hello", 42], ty: tupleTypeDefType)
        if case .vec(let vec) = tupleVal {
            XCTAssertEqual(vec?.count, 2)
            if let firstVal = vec?[0], case .string(let str) = firstVal {
                XCTAssertEqual(str, "hello")
            } else {
                XCTFail("Expected first element to be 'hello'")
            }
            if let secondVal = vec?[1], case .u32(let num) = secondVal {
                XCTAssertEqual(num, 42)
            } else {
                XCTFail("Expected second element to be 42")
            }
        } else {
            XCTFail("Expected vector SCVal for tuple")
        }
    }
    
    func testContractSpecAddressTypes() throws {
        let spec = ContractSpec(entries: [])
        
        // Note: This test would need a real account ID format to work
        // For now, we'll test the error case
        XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: "invalid_address", ty: SCSpecTypeDefXDR.address)) { error in
            XCTAssertTrue(error is ContractSpecError || error is StellarSDKError)
        }
    }
    
    func testContractSpecEnumTypes() throws {
        // Create an enum spec entry
        let enumCases = [
            SCSpecUDTEnumCaseV0XDR(doc: "", name: "optionA", value: 1),
            SCSpecUDTEnumCaseV0XDR(doc: "", name: "optionB", value: 2),
            SCSpecUDTEnumCaseV0XDR(doc: "", name: "optionC", value: 3)
        ]
        let enumSpec = SCSpecUDTEnumV0XDR(doc: "", lib: "", name: "MyEnum", cases: enumCases)
        let enumEntry = SCSpecEntryXDR.enumV0(enumSpec)
        
        let spec = ContractSpec(entries: [enumEntry])
        
        // Test enum conversion
        let enumType = SCSpecTypeUDTXDR(name: "MyEnum")
        let enumTypeDefType = SCSpecTypeDefXDR.udt(enumType)
        
        let enumVal = try spec.nativeToXdrSCVal(val: 2, ty: enumTypeDefType)
        if case .u32(let val) = enumVal {
            XCTAssertEqual(val, 2)
        } else {
            XCTFail("Expected u32 SCVal for enum")
        }
        
        // Test invalid enum value
        XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: 99, ty: enumTypeDefType)) { error in
            if let contractError = error as? ContractSpecError {
                if case .invalidEnumValue = contractError {
                    // Expected error
                } else {
                    XCTFail("Expected invalidEnumValue error")
                }
            } else {
                XCTFail("Expected ContractSpecError")
            }
        }
    }
    
    func testContractSpecUnionTypes() throws {
        // Create a union spec entry
        let unionCases = [
            SCSpecUDTUnionCaseV0XDR.voidV0(SCSpecUDTUnionCaseVoidV0XDR(doc: "", name: "none")),
            SCSpecUDTUnionCaseV0XDR.tupleV0(SCSpecUDTUnionCaseTupleV0XDR(doc: "", name: "some", type: [SCSpecTypeDefXDR.string, SCSpecTypeDefXDR.u32]))
        ]
        let unionSpec = SCSpecUDTUnionV0XDR(doc: "", lib: "", name: "MyUnion", cases: unionCases)
        let unionEntry = SCSpecEntryXDR.unionV0(unionSpec)
        
        let spec = ContractSpec(entries: [unionEntry])
        
        // Test void union case
        let unionType = SCSpecTypeUDTXDR(name: "MyUnion")
        let unionTypeDefType = SCSpecTypeDefXDR.udt(unionType)
        
        let voidUnionVal = NativeUnionVal(tag: "none")
        let voidResult = try spec.nativeToXdrSCVal(val: voidUnionVal, ty: unionTypeDefType)
        if case .vec(let vec) = voidResult {
            XCTAssertEqual(vec?.count, 1)
            if let firstVal = vec?[0], case .symbol(let symbol) = firstVal {
                XCTAssertEqual(symbol, "none")
            } else {
                XCTFail("Expected symbol 'none'")
            }
        } else {
            XCTFail("Expected vector SCVal for void union")
        }
        
        // Test tuple union case
        let tupleUnionVal = NativeUnionVal(tag: "some", values: ["hello", 42])
        let tupleResult = try spec.nativeToXdrSCVal(val: tupleUnionVal, ty: unionTypeDefType)
        if case .vec(let vec) = tupleResult {
            XCTAssertEqual(vec?.count, 3) // tag + 2 values
            if let firstVal = vec?[0], case .symbol(let symbol) = firstVal {
                XCTAssertEqual(symbol, "some")
            } else {
                XCTFail("Expected symbol 'some'")
            }
        } else {
            XCTFail("Expected vector SCVal for tuple union")
        }
    }
    
    func testContractSpecErrorHandling() throws {
        let spec = ContractSpec(entries: [])
        
        // Test function not found
        XCTAssertThrowsError(try spec.funcArgsToXdrSCValues(name: "nonExistent", args: [:])) { error in
            if let contractError = error as? ContractSpecError {
                if case .functionNotFound = contractError {
                    // Expected error
                } else {
                    XCTFail("Expected functionNotFound error")
                }
            } else {
                XCTFail("Expected ContractSpecError")
            }
        }
        
        // Test invalid type conversion
        XCTAssertThrowsError(try spec.nativeToXdrSCVal(val: "string", ty: SCSpecTypeDefXDR.u32)) { error in
            if let contractError = error as? ContractSpecError {
                if case .invalidType = contractError {
                    // Expected error
                } else {
                    XCTFail("Expected invalidType error")
                }
            } else {
                XCTFail("Expected ContractSpecError")
            }
        }
    }
    
    func testNativeUnionVal() {
        // Test void union
        let voidUnion = NativeUnionVal(tag: "voidCase")
        XCTAssertEqual(voidUnion.tag, "voidCase")
        XCTAssertNil(voidUnion.values)
        
        // Test tuple union
        let tupleUnion = NativeUnionVal(tag: "tupleCase", values: ["value1", 42])
        XCTAssertEqual(tupleUnion.tag, "tupleCase")
        XCTAssertEqual(tupleUnion.values?.count, 2)
    }
}
