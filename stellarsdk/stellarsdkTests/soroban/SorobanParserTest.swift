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
        XCTAssertTrue(contractInfo.specEntries.count == 25)
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
            case .eventV0(let sSCSpecEventV0XDR):
                printEvent(event:sSCSpecEventV0XDR)
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
    
    func printEvent(event:SCSpecEventV0XDR) {
        print("Event: \(event.name)")
        print("lib: \(event.lib)")
        
        var index = 0
        for prefixTopic in event.prefixTopics {
            print("prefixTopic[\(index)]: \(prefixTopic)")
            index += 1
        }
        index = 0
        for param in event.params {
            print("param[\(index)] name: \(param.name)")
            if (param.doc.count > 0) {
                print("param[\(index)] doc: \(param.doc)")
            }
            print("param[\(index)] type: \(getSpecTypeInfo(specType: param.type))")
            var location = "unknown"
            switch param.location {
            case .data:
                location = "data"
            case .topicList:
                location = "topic list"
            }
            print("param[\(index)] location: \(location)")
            index += 1
        }
        var dataFormat = "unknown"
        switch event.dataFormat {
        case .singleValue:
            dataFormat = "single value"
        case .vec:
            dataFormat = "vec"
        case .map:
            dataFormat = "map"
        }
        print("data format : \(dataFormat)")
        
        if (event.doc.count > 0) {
            print("doc : \(event.doc)")
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
        case .muxedAddress:
            return "muxedAddress"
        }
    }

    func testSorobanContractInfoSupportedSepsParsing() {
        // Test with multiple SEPs
        let metaWithMultipleSeps = [
            "sep": "1, 10, 24",
            "other": "value"
        ]
        let info1 = SorobanContractInfo(envInterfaceVersion: 1, specEntries: [], metaEntries: metaWithMultipleSeps)
        XCTAssertEqual(info1.supportedSeps, ["1", "10", "24"])

        // Test with single SEP
        let metaWithSingleSep = ["sep": "47"]
        let info2 = SorobanContractInfo(envInterfaceVersion: 1, specEntries: [], metaEntries: metaWithSingleSep)
        XCTAssertEqual(info2.supportedSeps, ["47"])

        // Test with no SEP meta entry
        let metaWithoutSep = ["other": "value"]
        let info3 = SorobanContractInfo(envInterfaceVersion: 1, specEntries: [], metaEntries: metaWithoutSep)
        XCTAssertTrue(info3.supportedSeps.isEmpty)

        // Test with empty SEP value
        let metaWithEmptySep = ["sep": ""]
        let info4 = SorobanContractInfo(envInterfaceVersion: 1, specEntries: [], metaEntries: metaWithEmptySep)
        XCTAssertTrue(info4.supportedSeps.isEmpty)

        // Test with SEPs containing extra spaces
        let metaWithSpaces = ["sep": "  1  ,  2  ,  3  "]
        let info5 = SorobanContractInfo(envInterfaceVersion: 1, specEntries: [], metaEntries: metaWithSpaces)
        XCTAssertEqual(info5.supportedSeps, ["1", "2", "3"])

        // Test with trailing/leading commas
        let metaWithCommas = ["sep": ",1,2,"]
        let info6 = SorobanContractInfo(envInterfaceVersion: 1, specEntries: [], metaEntries: metaWithCommas)
        XCTAssertEqual(info6.supportedSeps, ["1", "2"])

        // Test with duplicate SEPs (should be deduplicated, preserving first occurrence)
        let metaWithDuplicates = ["sep": "1, 10, 1, 24, 10"]
        let info7 = SorobanContractInfo(envInterfaceVersion: 1, specEntries: [], metaEntries: metaWithDuplicates)
        XCTAssertEqual(info7.supportedSeps, ["1", "10", "24"])
    }

    func testTokenContractValidation() throws {
        // Load and parse the token contract
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "soroban_token_contract", ofType: "wasm") else {
            XCTFail("Failed to load soroban_token_contract.wasm")
            return
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("Failed to read contract byte code")
            return
        }
        let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: contractCode)

        // Validate environment interface version
        XCTAssertGreaterThan(contractInfo.envInterfaceVersion, 0,
                             "Environment interface version should be greater than 0")

        // Validate meta entries
        XCTAssertEqual(contractInfo.metaEntries.count, 2,
                       "Contract should have exactly 2 meta entries")
        XCTAssertTrue(contractInfo.metaEntries.keys.contains("rsver"),
                      "Meta entries should contain rsver key")
        XCTAssertTrue(contractInfo.metaEntries.keys.contains("rssdkver"),
                      "Meta entries should contain rssdkver key")

        // Validate total spec entries count
        XCTAssertEqual(contractInfo.specEntries.count, 25,
                       "Contract should have exactly 25 spec entries")

        // Validate functions count and specific function names
        XCTAssertEqual(contractInfo.funcs.count, 13,
                       "Contract should have exactly 13 functions")

        let functionNames = contractInfo.funcs.map { $0.name }

        // Validate critical token functions exist
        XCTAssertTrue(functionNames.contains("__constructor"),
                      "Contract should have __constructor function")
        XCTAssertTrue(functionNames.contains("mint"),
                      "Contract should have mint function")
        XCTAssertTrue(functionNames.contains("burn"),
                      "Contract should have burn function")
        XCTAssertTrue(functionNames.contains("transfer"),
                      "Contract should have transfer function")
        XCTAssertTrue(functionNames.contains("transfer_from"),
                      "Contract should have transfer_from function")
        XCTAssertTrue(functionNames.contains("balance"),
                      "Contract should have balance function")
        XCTAssertTrue(functionNames.contains("approve"),
                      "Contract should have approve function")
        XCTAssertTrue(functionNames.contains("allowance"),
                      "Contract should have allowance function")
        XCTAssertTrue(functionNames.contains("decimals"),
                      "Contract should have decimals function")
        XCTAssertTrue(functionNames.contains("name"),
                      "Contract should have name function")
        XCTAssertTrue(functionNames.contains("symbol"),
                      "Contract should have symbol function")
        XCTAssertTrue(functionNames.contains("set_admin"),
                      "Contract should have set_admin function")
        XCTAssertTrue(functionNames.contains("burn_from"),
                      "Contract should have burn_from function")

        // Validate UDT structs count and specific struct names
        XCTAssertEqual(contractInfo.udtStructs.count, 3,
                       "Contract should have exactly 3 UDT structs")

        let structNames = contractInfo.udtStructs.map { $0.name }
        XCTAssertTrue(structNames.contains("AllowanceDataKey"),
                      "Contract should have AllowanceDataKey struct")
        XCTAssertTrue(structNames.contains("AllowanceValue"),
                      "Contract should have AllowanceValue struct")
        XCTAssertTrue(structNames.contains("TokenMetadata"),
                      "Contract should have TokenMetadata struct")

        // Validate AllowanceDataKey struct fields
        let allowanceDataKey = contractInfo.udtStructs.first { $0.name == "AllowanceDataKey" }
        XCTAssertNotNil(allowanceDataKey,
                        "AllowanceDataKey struct should be found")
        XCTAssertEqual(allowanceDataKey!.fields.count, 2,
                       "AllowanceDataKey should have 2 fields")
        XCTAssertEqual(allowanceDataKey!.fields[0].name, "from",
                       "First field of AllowanceDataKey should be named 'from'")
        XCTAssertEqual(allowanceDataKey!.fields[1].name, "spender",
                       "Second field of AllowanceDataKey should be named 'spender'")

        // Validate TokenMetadata struct fields
        let tokenMetadata = contractInfo.udtStructs.first { $0.name == "TokenMetadata" }
        XCTAssertNotNil(tokenMetadata,
                        "TokenMetadata struct should be found")
        XCTAssertEqual(tokenMetadata!.fields.count, 3,
                       "TokenMetadata should have 3 fields")
        XCTAssertEqual(tokenMetadata!.fields[0].name, "decimal",
                       "First field of TokenMetadata should be named 'decimal'")
        XCTAssertEqual(tokenMetadata!.fields[1].name, "name",
                       "Second field of TokenMetadata should be named 'name'")
        XCTAssertEqual(tokenMetadata!.fields[2].name, "symbol",
                       "Third field of TokenMetadata should be named 'symbol'")

        // Validate UDT unions count and specific union names
        XCTAssertEqual(contractInfo.udtUnions.count, 1,
                       "Contract should have exactly 1 UDT union")

        let unionNames = contractInfo.udtUnions.map { $0.name }
        XCTAssertTrue(unionNames.contains("DataKey"),
                      "Contract should have DataKey union")

        // Validate DataKey union cases
        let dataKey = contractInfo.udtUnions[0]
        XCTAssertEqual(dataKey.name, "DataKey",
                       "Union should be named DataKey")
        XCTAssertEqual(dataKey.cases.count, 4,
                       "DataKey union should have 4 cases")

        // Validate UDT enums count (should be zero for this contract)
        XCTAssertEqual(contractInfo.udtEnums.count, 0,
                       "Contract should have 0 UDT enums")

        // Validate UDT error enums count (should be zero for this contract)
        XCTAssertEqual(contractInfo.udtErrorEnums.count, 0,
                       "Contract should have 0 UDT error enums")

        // Validate events count and specific event names
        XCTAssertEqual(contractInfo.events.count, 8,
                       "Contract should have exactly 8 events")

        let eventNames = contractInfo.events.map { $0.name }
        XCTAssertTrue(eventNames.contains("SetAdmin"),
                      "Contract should have SetAdmin event")
        XCTAssertTrue(eventNames.contains("Approve"),
                      "Contract should have Approve event")
        XCTAssertTrue(eventNames.contains("Transfer"),
                      "Contract should have Transfer event")
        XCTAssertTrue(eventNames.contains("TransferWithAmountOnly"),
                      "Contract should have TransferWithAmountOnly event")
        XCTAssertTrue(eventNames.contains("Burn"),
                      "Contract should have Burn event")
        XCTAssertTrue(eventNames.contains("Mint"),
                      "Contract should have Mint event")
        XCTAssertTrue(eventNames.contains("MintWithAmountOnly"),
                      "Contract should have MintWithAmountOnly event")
        XCTAssertTrue(eventNames.contains("Clawback"),
                      "Contract should have Clawback event")

        // Validate Transfer event structure
        let transferEvent = contractInfo.events.first { $0.name == "Transfer" }
        XCTAssertNotNil(transferEvent,
                        "Transfer event should be found")
        XCTAssertEqual(transferEvent!.prefixTopics.count, 1,
                       "Transfer event should have 1 prefix topic")
        XCTAssertEqual(transferEvent!.prefixTopics[0], "transfer",
                       "Transfer event prefix topic should be 'transfer'")
        XCTAssertEqual(transferEvent!.params.count, 4,
                       "Transfer event should have 4 parameters")

        // Validate Approve event structure
        let approveEvent = contractInfo.events.first { $0.name == "Approve" }
        XCTAssertNotNil(approveEvent,
                        "Approve event should be found")
        XCTAssertEqual(approveEvent!.prefixTopics.count, 1,
                       "Approve event should have 1 prefix topic")
        XCTAssertEqual(approveEvent!.prefixTopics[0], "approve",
                       "Approve event prefix topic should be 'approve'")
        XCTAssertEqual(approveEvent!.params.count, 4,
                       "Approve event should have 4 parameters")

        // Validate balance function signature
        let balanceFunc = contractInfo.funcs.first { $0.name == "balance" }
        XCTAssertNotNil(balanceFunc,
                        "balance function should be found")
        XCTAssertEqual(balanceFunc!.inputs.count, 1,
                       "balance function should have 1 input parameter")
        XCTAssertEqual(balanceFunc!.inputs[0].name, "id",
                       "balance function input should be named 'id'")
        XCTAssertEqual(balanceFunc!.outputs.count, 1,
                       "balance function should have 1 output")

        // Validate mint function signature
        let mintFunc = contractInfo.funcs.first { $0.name == "mint" }
        XCTAssertNotNil(mintFunc,
                        "mint function should be found")
        XCTAssertEqual(mintFunc!.inputs.count, 2,
                       "mint function should have 2 input parameters")
        XCTAssertEqual(mintFunc!.inputs[0].name, "to",
                       "First parameter of mint function should be named 'to'")
        XCTAssertEqual(mintFunc!.inputs[1].name, "amount",
                       "Second parameter of mint function should be named 'amount'")
        XCTAssertEqual(mintFunc!.outputs.count, 0,
                       "mint function should have no outputs (void return)")
    }

    func testContractSpecMethods() throws {
        // Load and parse the token contract
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "soroban_token_contract", ofType: "wasm") else {
            XCTFail("Failed to load soroban_token_contract.wasm")
            return
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("Failed to read contract byte code")
            return
        }
        let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: contractCode)

        // Create a ContractSpec instance from the parsed spec entries
        let contractSpec = ContractSpec(entries: contractInfo.specEntries)

        // Test funcs() method - should return 13 functions
        let functions = contractSpec.funcs()
        XCTAssertEqual(functions.count, 13,
                       "ContractSpec funcs() should return exactly 13 functions")

        // Validate specific function names exist
        let functionNames = functions.map { $0.name }
        XCTAssertTrue(functionNames.contains("__constructor"),
                      "Functions should include __constructor")
        XCTAssertTrue(functionNames.contains("mint"),
                      "Functions should include mint")
        XCTAssertTrue(functionNames.contains("burn"),
                      "Functions should include burn")
        XCTAssertTrue(functionNames.contains("transfer"),
                      "Functions should include transfer")
        XCTAssertTrue(functionNames.contains("transfer_from"),
                      "Functions should include transfer_from")
        XCTAssertTrue(functionNames.contains("balance"),
                      "Functions should include balance")
        XCTAssertTrue(functionNames.contains("approve"),
                      "Functions should include approve")
        XCTAssertTrue(functionNames.contains("allowance"),
                      "Functions should include allowance")
        XCTAssertTrue(functionNames.contains("decimals"),
                      "Functions should include decimals")
        XCTAssertTrue(functionNames.contains("name"),
                      "Functions should include name")
        XCTAssertTrue(functionNames.contains("symbol"),
                      "Functions should include symbol")
        XCTAssertTrue(functionNames.contains("set_admin"),
                      "Functions should include set_admin")
        XCTAssertTrue(functionNames.contains("burn_from"),
                      "Functions should include burn_from")

        // Test udtStructs() method - should return 3 structs
        let structs = contractSpec.udtStructs()
        XCTAssertEqual(structs.count, 3,
                       "ContractSpec udtStructs() should return exactly 3 structs")

        // Validate specific struct names exist
        let structNames = structs.map { $0.name }
        XCTAssertTrue(structNames.contains("AllowanceDataKey"),
                      "Structs should include AllowanceDataKey")
        XCTAssertTrue(structNames.contains("AllowanceValue"),
                      "Structs should include AllowanceValue")
        XCTAssertTrue(structNames.contains("TokenMetadata"),
                      "Structs should include TokenMetadata")

        // Validate AllowanceDataKey struct has expected fields
        let allowanceDataKey = structs.first { $0.name == "AllowanceDataKey" }
        XCTAssertNotNil(allowanceDataKey,
                        "AllowanceDataKey struct should be found")
        XCTAssertEqual(allowanceDataKey!.fields.count, 2,
                       "AllowanceDataKey should have 2 fields")
        XCTAssertEqual(allowanceDataKey!.fields[0].name, "from",
                       "First field should be named 'from'")
        XCTAssertEqual(allowanceDataKey!.fields[1].name, "spender",
                       "Second field should be named 'spender'")

        // Test udtUnions() method - should return 1 union
        let unions = contractSpec.udtUnions()
        XCTAssertEqual(unions.count, 1,
                       "ContractSpec udtUnions() should return exactly 1 union")

        // Validate specific union names exist
        let unionNames = unions.map { $0.name }
        XCTAssertTrue(unionNames.contains("DataKey"),
                      "Unions should include DataKey")

        // Validate DataKey union has expected cases
        let dataKey = unions[0]
        XCTAssertEqual(dataKey.name, "DataKey",
                       "Union should be named DataKey")
        XCTAssertEqual(dataKey.cases.count, 4,
                       "DataKey union should have 4 cases")

        // Test udtEnums() method - should return 0 enums
        let enums = contractSpec.udtEnums()
        XCTAssertEqual(enums.count, 0,
                       "ContractSpec udtEnums() should return 0 enums for this contract")

        // Test udtErrorEnums() method - should return 0 error enums
        let errorEnums = contractSpec.udtErrorEnums()
        XCTAssertEqual(errorEnums.count, 0,
                       "ContractSpec udtErrorEnums() should return 0 error enums for this contract")

        // Test events() method - should return 8 events
        let events = contractSpec.events()
        XCTAssertEqual(events.count, 8,
                       "ContractSpec events() should return exactly 8 events")

        // Validate specific event names exist
        let eventNames = events.map { $0.name }
        XCTAssertTrue(eventNames.contains("SetAdmin"),
                      "Events should include SetAdmin")
        XCTAssertTrue(eventNames.contains("Approve"),
                      "Events should include Approve")
        XCTAssertTrue(eventNames.contains("Transfer"),
                      "Events should include Transfer")
        XCTAssertTrue(eventNames.contains("TransferWithAmountOnly"),
                      "Events should include TransferWithAmountOnly")
        XCTAssertTrue(eventNames.contains("Burn"),
                      "Events should include Burn")
        XCTAssertTrue(eventNames.contains("Mint"),
                      "Events should include Mint")
        XCTAssertTrue(eventNames.contains("MintWithAmountOnly"),
                      "Events should include MintWithAmountOnly")
        XCTAssertTrue(eventNames.contains("Clawback"),
                      "Events should include Clawback")

        // Validate Transfer event structure from ContractSpec
        let transferEvent = events.first { $0.name == "Transfer" }
        XCTAssertNotNil(transferEvent,
                        "Transfer event should be found")
        XCTAssertEqual(transferEvent!.prefixTopics.count, 1,
                       "Transfer event should have 1 prefix topic")
        XCTAssertEqual(transferEvent!.prefixTopics[0], "transfer",
                       "Transfer event prefix topic should be 'transfer'")
        XCTAssertEqual(transferEvent!.params.count, 4,
                       "Transfer event should have 4 parameters")

        // Validate that ContractSpec can find specific functions by name using getFunc()
        let balanceFunc = contractSpec.getFunc(name: "balance")
        XCTAssertNotNil(balanceFunc,
                        "ContractSpec getFunc() should find balance function")
        XCTAssertEqual(balanceFunc!.name, "balance",
                       "Found function should have correct name")
        XCTAssertEqual(balanceFunc!.inputs.count, 1,
                       "balance function should have 1 input parameter")

        // Validate that getFunc() returns nil for non-existent function
        let nonExistentFunc = contractSpec.getFunc(name: "non_existent_function")
        XCTAssertNil(nonExistentFunc,
                     "ContractSpec getFunc() should return nil for non-existent function")

        // Validate that findEntry() can locate entries by name
        let mintEntry = contractSpec.findEntry(name: "mint")
        XCTAssertNotNil(mintEntry,
                        "ContractSpec findEntry() should find mint entry")
        if case .functionV0(_) = mintEntry! {
            // Success - mint entry is a function type
        } else {
            XCTFail("mint entry should be a function type")
        }

        let dataKeyEntry = contractSpec.findEntry(name: "DataKey")
        XCTAssertNotNil(dataKeyEntry,
                        "ContractSpec findEntry() should find DataKey entry")
        if case .unionV0(_) = dataKeyEntry! {
            // Success - DataKey entry is a union type
        } else {
            XCTFail("DataKey entry should be a union type")
        }

        let transferEventEntry = contractSpec.findEntry(name: "Transfer")
        XCTAssertNotNil(transferEventEntry,
                        "ContractSpec findEntry() should find Transfer entry")
        if case .eventV0(_) = transferEventEntry! {
            // Success - Transfer entry is an event type
        } else {
            XCTFail("Transfer entry should be an event type")
        }

        // Validate that findEntry() returns nil for non-existent entry
        let nonExistentEntry = contractSpec.findEntry(name: "NonExistentEntry")
        XCTAssertNil(nonExistentEntry,
                     "ContractSpec findEntry() should return nil for non-existent entry")
    }

}
