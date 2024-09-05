//
//  SorobanParserTest.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.09.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class SorobanParserTest: XCTestCase {


    func testParseTokenContract() throws {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "soroban_token_contract", ofType: "wasm") else {
            // File not found
            XCTFail()
            return
        }
        let byteCode = FileManager.default.contents(atPath: path)
        let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: byteCode!)
        XCTAssertTrue(contractInfo.specEntries.count == 17)
        XCTAssertTrue(contractInfo.metaEntries.count == 2)
        
        print("--------------------------------")
        print("Env Meta:")
        print("")
        print("Interface version: \(contractInfo.envInterfaceVersion)")
        print("--------------------------------")
        
        print("Contract Meta:")
        print("")
        let metaEntries = contractInfo.metaEntries
        for (key, value) in metaEntries {
            print("\(key): \(value)")
        }
        print("--------------------------------")
        
        print("Contract Spec:")
        print("")
        let sepcEntries = contractInfo.specEntries
        for sepcEntry in sepcEntries {
            switch sepcEntry {
            case .functionV0(let sCSpecFunctionV0XDR):
                printFunction(function: sCSpecFunctionV0XDR);
            case .structV0(let sCSpecUDTStructV0XDR):
                printUdtStruct(udtStruct: sCSpecUDTStructV0XDR)
            case .unionV0(let sCSpecUDTUnionV0XDR):
                printUdtUnion(udtUnion: sCSpecUDTUnionV0XDR)
            case .enumV0(let sCSpecUDTEnumV0XDR):
                printUdtEnum(udtEnum: sCSpecUDTEnumV0XDR)
            case .errorEnumV0(let sCSpecUDTErrorEnumV0XDR):
                printUdtErrorEnum(udtErrorEnum: sCSpecUDTErrorEnumV0XDR)
            }
            print("")
        }
        
        print("--------------------------------")
        
    }
    
    func printFunction(function:SCSpecFunctionV0XDR) {
        print("Function: \(function.name)")
        var index = 0
        for input in function.inputs {
            print("input[\(index)] name: \(input.name)")
            print("input[\(index)] type: \(getSpecTypeInfo(specType: input.type))")
            if (input.doc.count > 0) {
                print("input[\(index)] doc: \(input.doc)")
            }
            index += 1
        }
        index = 0
        for output in function.outputs {
            print("output[\(index)] type: \(getSpecTypeInfo(specType: output))")
            index += 1
        }
        if (function.doc.count > 0) {
            print("doc : \(function.doc)")
        }
    }
    
    func printUdtStruct(udtStruct:SCSpecUDTStructV0XDR) {
        print("UDT Struct: \(udtStruct.name)")
        if (udtStruct.lib.count > 0) {
            print("lib : \(udtStruct.lib)")
        }
        var index = 0
        for field in udtStruct.fields {
            print("field[\(index)] name: \(field.name)")
            print("field[\(index)] type: \(getSpecTypeInfo(specType: field.type))")
            if (field.doc.count > 0) {
                print("field[\(index)] doc: \(field.doc)")
            }
            index += 1
        }
        if (udtStruct.doc.count > 0) {
            print("doc : \(udtStruct.doc)")
        }
    }
    
    func printUdtUnion(udtUnion:SCSpecUDTUnionV0XDR) {
        print("UDT Union: \(udtUnion.name)")
        if (udtUnion.lib.count > 0) {
            print("lib : \(udtUnion.lib)")
        }
        var index = 0
        for ucase in udtUnion.cases {
            switch ucase {
            case .voidV0(let voidV0):
                print("case[\(index)] is voidV0")
                print("case[\(index)] name: \(voidV0.name)")
                if (voidV0.doc.count > 0) {
                    print("case[\(index)] doc: \(voidV0.doc)")
                }
            case .tupleV0(let tupleV0):
                print("case[\(index)] is tupleV0")
                print("case[\(index)] name: \(tupleV0.name)")
                var valueTypesStr = "["
                for valueType in tupleV0.type {
                    valueTypesStr += "\(getSpecTypeInfo(specType:valueType)),"
                }
                valueTypesStr += "]"
                print("case[\(index)] types: \(valueTypesStr)")
                if (tupleV0.doc.count > 0) {
                    print("case[\(index)] doc: \(tupleV0.doc)")
                }
            }
            index += 1
        }
        if (udtUnion.doc.count > 0) {
            print("doc : \(udtUnion.doc)")
        }
    }
    
    func printUdtEnum(udtEnum:SCSpecUDTEnumV0XDR) {
        print("UDT Enum : \(udtEnum.name)")
        if (udtEnum.lib.count > 0) {
            print("lib : \(udtEnum.lib)")
        }
        var index = 0
        for ucase in udtEnum.cases {
            print("case[\(index)] name: \(ucase.name)")
            print("case[\(index)] value: \(ucase.value)")
            if (ucase.doc.count > 0) {
                print("case[\(index)] doc: \(ucase.doc)")
            }
            index += 1
        }
        if (udtEnum.doc.count > 0) {
            print("doc : \(udtEnum.doc)")
        }
    }
    
    func printUdtErrorEnum(udtErrorEnum:SCSpecUDTErrorEnumV0XDR) {
        print("UDT Error Enum : \(udtErrorEnum.name)")
        if (udtErrorEnum.lib.count > 0) {
            print("lib : \(udtErrorEnum.lib)")
        }
        var index = 0
        for ucase in udtErrorEnum.cases {
            print("case[\(index)] name: \(ucase.name)")
            print("case[\(index)] value: \(ucase.value)")
            if (ucase.doc.count > 0) {
                print("case[\(index)] doc: \(ucase.doc)")
            }
            index += 1
        }
        if (udtErrorEnum.doc.count > 0) {
            print("doc : \(udtErrorEnum.doc)")
        }
    }
    
    func getSpecTypeInfo(specType: SCSpecTypeDefXDR) -> String {
        switch specType {
        case .val:
            return "val"
        case .bool:
            return "bool"
        case .void:
            return "void"
        case .error:
            return "error"
        case .u32:
            return "u32"
        case .i32:
            return "132"
        case .u64:
            return "u64"
        case .i64:
            return "i64"
        case .timepoint:
            return "timepoint"
        case .duration:
            return "duration"
        case .u128:
            return "u128"
        case .i128:
            return "i128"
        case .u256:
            return "u256"
        case .i256:
            return "i256"
        case .bytes:
            return "bytes"
        case .string:
            return "string"
        case .symbol:
            return "symbol"
        case .address:
            return "address"
        case .option(let sCSpecTypeOptionXDR):
            let valueType = getSpecTypeInfo(specType: sCSpecTypeOptionXDR.valueType)
            return "option (value type: \(valueType))"
        case .result(let sCSpecTypeResultXDR):
            let okType = getSpecTypeInfo(specType: sCSpecTypeResultXDR.okType)
            let errorType = getSpecTypeInfo(specType: sCSpecTypeResultXDR.errorType)
            return "result (ok type: \(okType) , error type: \(errorType))"
        case .vec(let sCSpecTypeVecXDR):
            let elementType = getSpecTypeInfo(specType: sCSpecTypeVecXDR.elementType)
            return "vec (element type: \(elementType))"
        case .map(let sCSpecTypeMapXDR):
            let keyType = getSpecTypeInfo(specType: sCSpecTypeMapXDR.keyType)
            let valueType = getSpecTypeInfo(specType: sCSpecTypeMapXDR.valueType)
            return "map (key type: \(keyType) , value type: \(valueType))"
        case .tuple(let sCSpecTypeTupleXDR):
            var valueTypesStr = "["
            for valueType in sCSpecTypeTupleXDR.valueTypes {
                valueTypesStr += "\(getSpecTypeInfo(specType:valueType)),"
            }
            valueTypesStr += "]"
            return "tuple (value types: \(valueTypesStr))"
        case .bytesN(let sCSpecTypeBytesNXDR):
            return "bytesN (n: \(sCSpecTypeBytesNXDR.n))"
        case .udt(let sCSpecTypeUDTXDR):
            return "udt (name: \(sCSpecTypeUDTXDR.name))"
        }
    }


}
