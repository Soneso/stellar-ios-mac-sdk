//
//  SorobanParserUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 04.09.24.
//  Copyright © 2024 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class SorobanParserUnitTests: XCTestCase {


    func testParseTokenContract() throws {
        guard let path = Bundle.module.path(forResource: "soroban_token_contract", ofType: "wasm") else {
            // File not found
            XCTFail()
            return
        }
        let byteCode = FileManager.default.contents(atPath: path)
        let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: byteCode!)
        XCTAssertEqual(contractInfo.specEntries.count, 25)
        XCTAssertEqual(contractInfo.metaEntries.count, 2)
        XCTAssertGreaterThan(contractInfo.envProtocolVersion, 0)
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
        let iv = SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: 0, preRelease: 1)

        // Test with multiple SEPs
        let metaWithMultipleSeps = [
            "sep": "1, 10, 24",
            "other": "value"
        ]
        let info1 = SorobanContractInfo(interfaceVersion: iv, specEntries: [], metaEntries: metaWithMultipleSeps)
        XCTAssertEqual(info1.supportedSeps, ["1", "10", "24"])

        // Test with single SEP
        let metaWithSingleSep = ["sep": "47"]
        let info2 = SorobanContractInfo(interfaceVersion: iv, specEntries: [], metaEntries: metaWithSingleSep)
        XCTAssertEqual(info2.supportedSeps, ["47"])

        // Test with no SEP meta entry
        let metaWithoutSep = ["other": "value"]
        let info3 = SorobanContractInfo(interfaceVersion: iv, specEntries: [], metaEntries: metaWithoutSep)
        XCTAssertTrue(info3.supportedSeps.isEmpty)

        // Test with empty SEP value
        let metaWithEmptySep = ["sep": ""]
        let info4 = SorobanContractInfo(interfaceVersion: iv, specEntries: [], metaEntries: metaWithEmptySep)
        XCTAssertTrue(info4.supportedSeps.isEmpty)

        // Test with SEPs containing extra spaces
        let metaWithSpaces = ["sep": "  1  ,  2  ,  3  "]
        let info5 = SorobanContractInfo(interfaceVersion: iv, specEntries: [], metaEntries: metaWithSpaces)
        XCTAssertEqual(info5.supportedSeps, ["1", "2", "3"])

        // Test with trailing/leading commas
        let metaWithCommas = ["sep": ",1,2,"]
        let info6 = SorobanContractInfo(interfaceVersion: iv, specEntries: [], metaEntries: metaWithCommas)
        XCTAssertEqual(info6.supportedSeps, ["1", "2"])

        // Test with duplicate SEPs (should be deduplicated, preserving first occurrence)
        let metaWithDuplicates = ["sep": "1, 10, 1, 24, 10"]
        let info7 = SorobanContractInfo(interfaceVersion: iv, specEntries: [], metaEntries: metaWithDuplicates)
        XCTAssertEqual(info7.supportedSeps, ["1", "10", "24"])
    }

    func testTokenContractValidation() throws {
        // Load and parse the token contract
        guard let path = Bundle.module.path(forResource: "soroban_token_contract", ofType: "wasm") else {
            XCTFail("Failed to load soroban_token_contract.wasm")
            return
        }
        guard let contractCode = FileManager.default.contents(atPath: path) else {
            XCTFail("Failed to read contract byte code")
            return
        }
        let contractInfo = try SorobanContractParser.parseContractByteCode(byteCode: contractCode)

        // Validate environment interface version
        XCTAssertGreaterThan(contractInfo.envProtocolVersion, 0,
                             "Environment protocol version should be greater than 0")

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
        guard let path = Bundle.module.path(forResource: "soroban_token_contract", ofType: "wasm") else {
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

    // MARK: - Wasm section bounds

    // The modules below are built from the sections of the token contract wasm, indexed
    // 0 to 7 (type to data), 8 contractspecv0, 9 contractenvmetav0 and 10 contractmetav0.
    // Expected entries come from decoding the original sections with the XDR types directly.

    private static let wasmHeader: [UInt8] = [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00]
    private let spec = "contractspecv0", envMeta = "contractenvmetav0", meta = "contractmetav0"

    func testSectionsParseToTheEntriesTheirContentHolds() throws {
        let sections = try tokenSections()
        XCTAssertEqual(sections.compactMap { custom($0)?.name }, [spec, envMeta, meta])
        let info = try parse(sections)
        XCTAssertEqual(try info.specEntries.map(XDREncoder.encode), try entryStream(SCSpecEntryXDR.self, content(spec, sections)))
        XCTAssertEqual(info.specEntries.count, 25)
        let envMetaEntries = try decodedStream(SCEnvMetaEntryXDR.self, content(envMeta, sections))
        guard envMetaEntries.count == 1, case .interfaceVersion(let version) = envMetaEntries[0] else {
            return XCTFail("expected one interface version entry, got \(envMetaEntries)")
        }
        XCTAssertEqual(info.envProtocolVersion, version.protocol)
        XCTAssertEqual(info.envPreReleaseVersion, version.preRelease)
        let metaPairs = try decodedStream(SCMetaEntryXDR.self, content(meta, sections)).map { entry -> String in
            guard case .v0(let pair) = entry else { return "" }
            return "\(pair.key)=\(pair.value)"
        }
        XCTAssertEqual(info.metaEntries.map { "\($0.key)=\($0.value)" }.sorted(), metaPairs.sorted())
        XCTAssertEqual(metaPairs.count, 2)

        // Values with the same metadata key are joined with a comma; for the `sep` key, this
        // implements SEP-47.
        var seps = sections
        let sepEntries = try ["1", "10"].map { try XDREncoder.encode(SCMetaEntryXDR.v0(SCMetaV0XDR(key: "sep", value: $0))) }
        seps[10] = customSection(meta, try content(meta, sections) + sepEntries.joined())
        let sepInfo = try parse(seps)
        XCTAssertEqual(sepInfo.metaEntries["sep"], "1,10")
        XCTAssertEqual(sepInfo.supportedSeps, ["1", "10"])
        XCTAssertEqual(sepInfo.metaEntries.count, 3)

        // A spec section followed by another custom section parses to the full entry list.
        var followed = sections
        followed.insert(customSection("other", [1, 2, 3, 4, 5]), at: 9)
        XCTAssertEqual(try parse(followed).specEntries.map(XDREncoder.encode), try entryStream(SCSpecEntryXDR.self, content(spec, sections)))

        // An environment meta section is read to its end; the first entry gives the version.
        var twoVersions = sections
        twoVersions[9] = customSection(envMeta, try content(envMeta, sections) + XDREncoder.encode(SCEnvMetaEntryXDR.interfaceVersion(SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: 99, preRelease: 7))))
        XCTAssertEqual(try parse(twoVersions).envProtocolVersion, version.protocol)
        var cutVersion = sections
        cutVersion[9] = customSection(envMeta, try content(envMeta, sections) + [0x00, 0x00, 0x00])
        assertInvalidEntry(cutVersion, envMeta, at: try contentOffset(9, cutVersion) + content(envMeta, sections).count, "prematureEndOfData")
    }

    func testMissingSectionsKeepTheirResults() throws {
        let sections = try tokenSections()
        assertParse(Array(sections[0...7]) + [sections[9], sections[10]], throws: .specEntriesNotFound)
        assertParse(Array(sections[0...8]) + [sections[10]], throws: .environmentMetaNotFound)
        assertParse(Array(sections[0...8]) + [customSection(envMeta, []), sections[10]], throws: .environmentMetaNotFound)
        let withoutMeta = try parse(Array(sections[0...9]))
        XCTAssertTrue(withoutMeta.metaEntries.isEmpty)
        XCTAssertEqual(withoutMeta.specEntries.count, 25)
        XCTAssertEqual(try parse(Array(sections[0...7]) + [customSection(spec, []), sections[9]]).specEntries.count, 0)
    }

    func testAnEntryThatDoesNotDecodeFailsWithItsOffset() throws {
        let sections = try tokenSections()
        let specEntries = try entryStream(SCSpecEntryXDR.self, content(spec, sections))

        // A doc holding the byte ff.
        var badDoc = try XDREncoder.encode(SCSpecEntryXDR.functionV0(SCSpecFunctionV0XDR(doc: "a", name: "f", inputs: [], outputs: [])))
        XCTAssertEqual(badDoc[4...8], [0x00, 0x00, 0x00, 0x01, 0x61])
        badDoc[8] = 0xff
        var docModule = sections
        docModule[8] = customSection(spec, Array(specEntries[0..<3].joined()) + badDoc + Array(specEntries[3...].joined()))
        assertInvalidEntry(docModule, spec, at: try contentOffset(8, docModule) + specEntries[0..<3].joined().count, "a string of length 1 is not valid UTF-8")

        // A meta value holding the byte ff.
        let metaEntries = try entryStream(SCMetaEntryXDR.self, content(meta, sections))
        var badValue = try XDREncoder.encode(SCMetaEntryXDR.v0(SCMetaV0XDR(key: "k", value: "v")))
        XCTAssertEqual(badValue[12...16], [0x00, 0x00, 0x00, 0x01, 0x76])
        badValue[16] = 0xff
        var metaModule = sections
        metaModule[10] = customSection(meta, metaEntries[0] + badValue + metaEntries[1])
        assertInvalidEntry(metaModule, meta, at: try contentOffset(10, metaModule) + metaEntries[0].count, "a string of length 1 is not valid UTF-8")

        // An unknown spec entry kind.
        var unknownKind = sections
        unknownKind[8] = customSection(spec, specEntries[0] + [0x00, 0x00, 0x00, 0x63] + Array(specEntries[1...].joined()))
        assertInvalidEntry(unknownKind, spec, at: try contentOffset(8, unknownKind) + specEntries[0].count, "Unknown SCSpecEntryXDR discriminant: 99")

        // Trailing bytes that do not form an entry.
        var trailing = sections
        trailing[8] = customSection(spec, try content(spec, sections) + [0x00, 0x00, 0x00])
        assertInvalidEntry(trailing, spec, at: try contentOffset(8, trailing) + specEntries.joined().count, "prematureEndOfData")
    }

    func testMalformedFramingFailsWithItsOffset() throws {
        let sections = try tokenSections()
        let specOffset = offset(8, sections)
        func module(_ parts: [[UInt8]]) -> [UInt8] { Self.wasmHeader + parts.joined() }
        let total = module(sections).count

        // A size that runs past the end of the input, before the spec section and after it.
        let pastEnd = module(Array(sections[0...7]) + [[0x00, 0xa0, 0x8d, 0x06]] + Array(sections[8...]))
        assertMalformed(pastEnd, at: specOffset + 1, "the section at offset \(specOffset) declares 100000 bytes, but \(total - specOffset) bytes follow its size")
        assertMalformed(module(sections + [[0x00, 0xa0, 0x8d, 0x06]]), at: total + 1, "the section at offset \(total) declares 100000 bytes, but 0 bytes follow its size")

        // A custom section name length cut by the end of its section, before the spec section.
        let cutName = module(Array(sections[0...7]) + [[0x00, 0x01, 0x80]] + Array(sections[8...]))
        assertMalformed(cutName, at: specOffset + 2, "the custom section name length at offset \(specOffset + 2) runs past offset \(specOffset + 3)")

        // The spec section itself with a size past the end, and with its size cut by the end.
        let specPayload = Array(sections[8][3...])
        XCTAssertEqual(Array(sections[8][1...2]), leb128(specPayload.count))
        let lastSpec = Array(sections[0...7]) + [sections[9], sections[10]]
        let lastOffset = module(lastSpec).count
        assertMalformed(module(lastSpec + [[0x00] + leb128(specPayload.count + 1) + specPayload]), at: lastOffset + 1,
                        "the section at offset \(lastOffset) declares \(specPayload.count + 1) bytes, but \(specPayload.count) bytes follow its size")
        assertMalformed(module(lastSpec + [[0x00, sections[8][1]]]), at: lastOffset + 1,
                        "the section size at offset \(lastOffset + 1) runs past offset \(lastOffset + 2)")

        // A name longer than its section.
        let longName = module(Array(sections[0...7]) + [[0x00, 0x03, 0x05, 0x61, 0x62]] + Array(sections[8...]))
        assertMalformed(longName, at: specOffset + 2, "the custom section at offset \(specOffset) declares a name of 5 bytes, but 2 bytes of the section follow its name length")

        // LEB128 sizes: the largest 32-bit value is read, a fifth byte above 4 bits and a sixth byte fail.
        let largest = module(Array(sections[0...7]) + [[0x00, 0xff, 0xff, 0xff, 0xff, 0x0f]] + Array(sections[8...]))
        assertMalformed(largest, at: specOffset + 1, "the section at offset \(specOffset) declares 4294967295 bytes, but \(total - specOffset) bytes follow its size")
        let overflow = module(Array(sections[0...7]) + [[0x00, 0xff, 0xff, 0xff, 0xff, 0x1f]] + Array(sections[8...]))
        assertMalformed(overflow, at: specOffset + 1, "the section size at offset \(specOffset + 1) exceeds 32 bits")
        let sixBytes = module(Array(sections[0...7]) + [[0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00]] + Array(sections[8...]))
        assertMalformed(sixBytes, at: specOffset + 1, "the section size at offset \(specOffset + 1) is longer than 5 bytes")

        // The header: fewer than 8 bytes, a wrong magic and a wrong version.
        assertMalformed([], at: 0, "the module has 0 bytes, fewer than the 8 bytes of the wasm header")
        assertMalformed(Array(Self.wasmHeader[0..<7]), at: 0, "the module has 7 bytes, fewer than the 8 bytes of the wasm header")
        var wrongMagic = module(sections)
        wrongMagic[1] = 0x62
        assertMalformed(wrongMagic, at: 0, "the module does not start with the wasm magic 00 61 73 6d")
        var wrongVersion = module(sections)
        wrongVersion[4] = 0x02
        assertMalformed(wrongVersion, at: 4, "the wasm version is not 01 00 00 00")
    }

    func testPaddedLEB128SizesAreRead() throws {
        let sections = try tokenSections()
        let specContent = try content(spec, sections)
        let padded = padded5(14) + Array(spec.utf8) + specContent
        var module = sections
        module[8] = [0x00] + padded5(padded.count) + padded
        module.insert([0x00, 0x05, 0x80, 0x80, 0x80, 0x80, 0x00], at: 8)
        XCTAssertEqual(try parse(module).specEntries.map(XDREncoder.encode), try entryStream(SCSpecEntryXDR.self, specContent))
    }

    func testEveryMetaSectionIsReadAndTheFirstSpecAndEnvMetaSection() throws {
        let sections = try tokenSections()
        let specEntries = try entryStream(SCSpecEntryXDR.self, content(spec, sections))
        let original = try parse(sections)
        let rsver = try XCTUnwrap(original.metaEntries["rsver"])
        let secondMeta = try [("rsver", "x"), ("extra", "y")].map {
            try XDREncoder.encode(SCMetaEntryXDR.v0(SCMetaV0XDR(key: $0.0, value: $0.1)))
        }
        let repeated = sections + [
            customSection(spec, Array(specEntries[0..<2].joined())),
            customSection(envMeta, try XDREncoder.encode(SCEnvMetaEntryXDR.interfaceVersion(SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: 99, preRelease: 7)))),
            customSection(meta, Array(secondMeta.joined())),
        ]
        let info = try parse(repeated)
        XCTAssertEqual(try info.specEntries.map(XDREncoder.encode), specEntries)
        XCTAssertEqual(info.envProtocolVersion, original.envProtocolVersion)
        XCTAssertEqual(info.envPreReleaseVersion, original.envPreReleaseVersion)
        // An empty first environment meta section counts, also when a later one holds the version.
        assertParse(Array(sections[0...8]) + [customSection(envMeta, []), sections[9], sections[10]], throws: .environmentMetaNotFound)

        // The entries of both meta sections are read in module order.
        var expectedMeta = original.metaEntries
        expectedMeta["rsver"] = rsver + ",x"
        expectedMeta["extra"] = "y"
        XCTAssertEqual(info.metaEntries, expectedMeta)

        // An entry cut by the end of the second meta section fails with its offset, also when the
        // next meta section holds the rest of its bytes.
        var cut = repeated
        cut[13] = customSection(meta, secondMeta[0] + secondMeta[1][0..<5])
        cut.append(customSection(meta, Array(secondMeta[1][5...])))
        assertInvalidEntry(cut, meta, at: try contentOffset(13, cut) + secondMeta[0].count, "prematureEndOfData")
    }

    func testSectionNameBytesInsideADataSegmentDoNotStartASection() throws {
        var sections = try tokenSections()
        XCTAssertEqual(sections[7][0], 11)
        var position = 1
        let size = readLEB128(sections[7], &position)
        XCTAssertEqual(position + size, sections[7].count)
        let segmentCount = readLEB128(sections[7], &position)
        let bytes = Array(spec.utf8) + [0x00, 0x00, 0x00, 0x63] + Array(envMeta.utf8) + [0x00, 0x00, 0x00, 0x63]
        let segment: [UInt8] = [0x00, 0x41, 0x00, 0x0b] + leb128(bytes.count) + bytes
        let payload = leb128(segmentCount + 1) + segment + Array(sections[7][position...])
        let original = try parse(sections)
        sections[7] = [11] + leb128(payload.count) + payload
        let info = try parse(sections)
        XCTAssertEqual(try info.specEntries.map(XDREncoder.encode), try original.specEntries.map(XDREncoder.encode))
        XCTAssertEqual(info.specEntries.count, 25)
        XCTAssertEqual(info.envProtocolVersion, original.envProtocolVersion)
    }

    /// The token contract wasm split into its sections, each from its id byte to its end.
    private func tokenSections() throws -> [[UInt8]] {
        let path = try XCTUnwrap(Bundle.module.path(forResource: "soroban_token_contract", ofType: "wasm"))
        let bytes = [UInt8](try XCTUnwrap(FileManager.default.contents(atPath: path)))
        XCTAssertEqual(Array(bytes[0..<8]), Self.wasmHeader)
        var sections: [[UInt8]] = []
        var position = 8
        while position < bytes.count {
            var cursor = position + 1
            let end = readLEB128(bytes, &cursor) + cursor
            sections.append(Array(bytes[position..<end]))
            position = end
        }
        return sections
    }

    private func readLEB128(_ bytes: [UInt8], _ position: inout Int) -> Int {
        var value = 0
        var shift = 0
        while true {
            let byte = bytes[position]
            position += 1
            value |= Int(byte & 0x7f) << shift
            if byte & 0x80 == 0 { return value }
            shift += 7
        }
    }

    private func leb128(_ value: Int) -> [UInt8] {
        var rest = value
        var bytes: [UInt8] = []
        repeat {
            let low = UInt8(rest & 0x7f)
            rest >>= 7
            bytes.append(rest == 0 ? low : low | 0x80)
        } while rest != 0
        return bytes
    }

    private func padded5(_ value: Int) -> [UInt8] {
        return (0..<4).map { UInt8((value >> (7 * $0)) & 0x7f) | 0x80 } + [UInt8(value >> 28)]
    }

    /// The name and the content after the name of a custom section, nil for another section.
    private func custom(_ section: [UInt8]) -> (name: String, content: [UInt8])? {
        guard section[0] == 0 else { return nil }
        var position = 1
        _ = readLEB128(section, &position)
        let nameLength = readLEB128(section, &position)
        let name = String(decoding: section[position..<position + nameLength], as: UTF8.self)
        return (name, Array(section[(position + nameLength)...]))
    }

    private func customSection(_ name: String, _ content: [UInt8]) -> [UInt8] {
        let payload = leb128(name.utf8.count) + Array(name.utf8) + content
        return [0x00] + leb128(payload.count) + payload
    }

    private func content(_ name: String, _ sections: [[UInt8]]) throws -> [UInt8] {
        return try XCTUnwrap(sections.compactMap(custom).first { $0.name == name }?.content)
    }

    /// The module offset of the section at the index.
    private func offset(_ index: Int, _ sections: [[UInt8]]) -> Int {
        return Self.wasmHeader.count + sections[..<index].joined().count
    }

    /// The module offset of the content of the custom section at the index.
    private func contentOffset(_ index: Int, _ sections: [[UInt8]]) throws -> Int {
        let section = sections[index]
        return offset(index, sections) + section.count - (try XCTUnwrap(custom(section))).content.count
    }

    /// Decodes section content entry by entry, independent of the parser.
    private func decodedStream<Entry: XDRCodable>(_ type: Entry.Type, _ content: [UInt8]) throws -> [Entry] {
        var entries: [Entry] = []
        var position = 0
        while position < content.count {
            let entry = try XDRDecoder.decode(Entry.self, data: Array(content[position...]))
            let encoded = try XDREncoder.encode(entry)
            XCTAssertEqual(encoded[...], content[position..<min(position + encoded.count, content.count)])
            entries.append(entry)
            position += encoded.count
        }
        return entries
    }

    /// The encoded entries of section content, each verified against the bytes it was decoded from.
    private func entryStream<Entry: XDRCodable>(_ type: Entry.Type, _ content: [UInt8]) throws -> [[UInt8]] {
        return try decodedStream(type, content).map(XDREncoder.encode)
    }

    private func parse(_ sections: [[UInt8]]) throws -> SorobanContractInfo {
        return try SorobanContractParser.parseContractByteCode(byteCode: Data(Self.wasmHeader + sections.joined()))
    }

    private func assertParse(_ sections: [[UInt8]], throws expected: SorobanContractParserError, line: UInt = #line) {
        XCTAssertThrowsError(try parse(sections), line: line) { error in
            XCTAssertEqual("\(error)", "\(expected)", line: line)
        }
    }

    private func assertMalformed(_ module: [UInt8], at offset: Int, _ message: String, line: UInt = #line) {
        XCTAssertThrowsError(try SorobanContractParser.parseContractByteCode(byteCode: Data(module)), line: line) { error in
            guard case SorobanContractParserError.malformedModule(let actualOffset, let actualMessage) = error else {
                return XCTFail("expected malformedModule, got \(error)", line: line)
            }
            XCTAssertEqual(actualOffset, offset, line: line)
            XCTAssertEqual(actualMessage, message, line: line)
        }
    }

    private func assertInvalidEntry(_ sections: [[UInt8]], _ section: String, at offset: Int, _ message: String, line: UInt = #line) {
        XCTAssertThrowsError(try parse(sections), line: line) { error in
            guard case SorobanContractParserError.invalidSectionEntry(let actualSection, let actualOffset, let actualMessage) = error else {
                return XCTFail("expected invalidSectionEntry, got \(error)", line: line)
            }
            XCTAssertEqual(actualSection, section, line: line)
            XCTAssertEqual(actualOffset, offset, line: line)
            XCTAssertEqual(actualMessage, message, line: line)
        }
    }
}
