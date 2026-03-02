//
//  ContractSpecXDRUnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso
//  Copyright (c) 2025 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class ContractSpecXDRUnitTests: XCTestCase {

    // MARK: - SCSpecTypeOptionXDR Tests

    func testSCSpecTypeOptionXDR() throws {
        let valueType = SCSpecTypeDefXDR.u32
        let option = SCSpecTypeOptionXDR(valueType: valueType)
        let encoded = try XDREncoder.encode(option)
        let decoded = try XDRDecoder.decode(SCSpecTypeOptionXDR.self, data: encoded)

        XCTAssertEqual(decoded.valueType.type(), SCSpecType.u32.rawValue)
    }

    // MARK: - SCSpecTypeResultXDR Tests

    func testSCSpecTypeResultXDR() throws {
        let okType = SCSpecTypeDefXDR.u32
        let errorType = SCSpecTypeDefXDR.error
        let result = SCSpecTypeResultXDR(okType: okType, errorType: errorType)
        let encoded = try XDREncoder.encode(result)
        let decoded = try XDRDecoder.decode(SCSpecTypeResultXDR.self, data: encoded)

        XCTAssertEqual(decoded.okType.type(), SCSpecType.u32.rawValue)
        XCTAssertEqual(decoded.errorType.type(), SCSpecType.error.rawValue)
    }

    // MARK: - SCSpecTypeVecXDR Tests

    func testSCSpecTypeVecXDR() throws {
        let elementType = SCSpecTypeDefXDR.string
        let vec = SCSpecTypeVecXDR(elementType: elementType)
        let encoded = try XDREncoder.encode(vec)
        let decoded = try XDRDecoder.decode(SCSpecTypeVecXDR.self, data: encoded)

        XCTAssertEqual(decoded.elementType.type(), SCSpecType.string.rawValue)
    }

    // MARK: - SCSpecTypeMapXDR Tests

    func testSCSpecTypeMapXDR() throws {
        let keyType = SCSpecTypeDefXDR.symbol
        let valueType = SCSpecTypeDefXDR.u64
        let map = SCSpecTypeMapXDR(keyType: keyType, valueType: valueType)
        let encoded = try XDREncoder.encode(map)
        let decoded = try XDRDecoder.decode(SCSpecTypeMapXDR.self, data: encoded)

        XCTAssertEqual(decoded.keyType.type(), SCSpecType.symbol.rawValue)
        XCTAssertEqual(decoded.valueType.type(), SCSpecType.u64.rawValue)
    }

    // MARK: - SCSpecTypeBytesNXDR Tests

    func testSCSpecTypeBytesNXDR() throws {
        let n: UInt32 = 64
        let bytesN = SCSpecTypeBytesNXDR(n: n)
        let encoded = try XDREncoder.encode(bytesN)
        let decoded = try XDRDecoder.decode(SCSpecTypeBytesNXDR.self, data: encoded)

        XCTAssertEqual(decoded.n, n)
    }

    // MARK: - SCSpecTypeTupleXDR Tests

    func testSCSpecTypeTupleXDR() throws {
        let valueTypes = [SCSpecTypeDefXDR.u32, SCSpecTypeDefXDR.string, SCSpecTypeDefXDR.bool]
        let tuple = SCSpecTypeTupleXDR(valueTypes: valueTypes)
        let encoded = try XDREncoder.encode(tuple)
        let decoded = try XDRDecoder.decode(SCSpecTypeTupleXDR.self, data: encoded)

        XCTAssertEqual(decoded.valueTypes.count, 3)
        XCTAssertEqual(decoded.valueTypes[0].type(), SCSpecType.u32.rawValue)
        XCTAssertEqual(decoded.valueTypes[1].type(), SCSpecType.string.rawValue)
        XCTAssertEqual(decoded.valueTypes[2].type(), SCSpecType.bool.rawValue)
    }

    func testSCSpecTypeTupleXDREmpty() throws {
        let tuple = SCSpecTypeTupleXDR(valueTypes: [])
        let encoded = try XDREncoder.encode(tuple)
        let decoded = try XDRDecoder.decode(SCSpecTypeTupleXDR.self, data: encoded)

        XCTAssertEqual(decoded.valueTypes.count, 0)
    }

    // MARK: - SCSpecTypeUDTXDR Tests

    func testSCSpecTypeUDTXDR() throws {
        let name = "MyCustomType"
        let udt = SCSpecTypeUDTXDR(name: name)
        let encoded = try XDREncoder.encode(udt)
        let decoded = try XDRDecoder.decode(SCSpecTypeUDTXDR.self, data: encoded)

        XCTAssertEqual(decoded.name, name)
    }

    // MARK: - SCSpecTypeDefXDR Tests

    func testSCSpecTypeDefXDRPrimitiveTypes() throws {
        let primitives: [SCSpecTypeDefXDR] = [
            .val, .bool, .void, .error, .u32, .i32, .u64, .i64,
            .timepoint, .duration, .u128, .i128, .u256, .i256,
            .bytes, .string, .symbol, .address, .muxedAddress
        ]

        for primitive in primitives {
            let encoded = try XDREncoder.encode(primitive)
            let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)
            XCTAssertEqual(decoded.type(), primitive.type())
        }
    }

    func testSCSpecTypeDefXDROption() throws {
        let valueType = SCSpecTypeDefXDR.u32
        let option = SCSpecTypeOptionXDR(valueType: valueType)
        let typeDef = SCSpecTypeDefXDR.option(option)
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        switch decoded {
        case .option(let decodedOption):
            XCTAssertEqual(decodedOption.valueType.type(), SCSpecType.u32.rawValue)
        default:
            XCTFail("Expected option type")
        }
    }

    func testSCSpecTypeDefXDRResult() throws {
        let okType = SCSpecTypeDefXDR.u32
        let errorType = SCSpecTypeDefXDR.error
        let result = SCSpecTypeResultXDR(okType: okType, errorType: errorType)
        let typeDef = SCSpecTypeDefXDR.result(result)
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        switch decoded {
        case .result(let decodedResult):
            XCTAssertEqual(decodedResult.okType.type(), SCSpecType.u32.rawValue)
            XCTAssertEqual(decodedResult.errorType.type(), SCSpecType.error.rawValue)
        default:
            XCTFail("Expected result type")
        }
    }

    func testSCSpecTypeDefXDRVec() throws {
        let elementType = SCSpecTypeDefXDR.string
        let vec = SCSpecTypeVecXDR(elementType: elementType)
        let typeDef = SCSpecTypeDefXDR.vec(vec)
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        switch decoded {
        case .vec(let decodedVec):
            XCTAssertEqual(decodedVec.elementType.type(), SCSpecType.string.rawValue)
        default:
            XCTFail("Expected vec type")
        }
    }

    func testSCSpecTypeDefXDRMap() throws {
        let keyType = SCSpecTypeDefXDR.symbol
        let valueType = SCSpecTypeDefXDR.u64
        let map = SCSpecTypeMapXDR(keyType: keyType, valueType: valueType)
        let typeDef = SCSpecTypeDefXDR.map(map)
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        switch decoded {
        case .map(let decodedMap):
            XCTAssertEqual(decodedMap.keyType.type(), SCSpecType.symbol.rawValue)
            XCTAssertEqual(decodedMap.valueType.type(), SCSpecType.u64.rawValue)
        default:
            XCTFail("Expected map type")
        }
    }

    func testSCSpecTypeDefXDRTuple() throws {
        let valueTypes = [SCSpecTypeDefXDR.u32, SCSpecTypeDefXDR.string]
        let tuple = SCSpecTypeTupleXDR(valueTypes: valueTypes)
        let typeDef = SCSpecTypeDefXDR.tuple(tuple)
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        switch decoded {
        case .tuple(let decodedTuple):
            XCTAssertEqual(decodedTuple.valueTypes.count, 2)
        default:
            XCTFail("Expected tuple type")
        }
    }

    func testSCSpecTypeDefXDRBytesN() throws {
        let bytesN = SCSpecTypeBytesNXDR(n: 32)
        let typeDef = SCSpecTypeDefXDR.bytesN(bytesN)
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        switch decoded {
        case .bytesN(let decodedBytesN):
            XCTAssertEqual(decodedBytesN.n, 32)
        default:
            XCTFail("Expected bytesN type")
        }
    }

    func testSCSpecTypeDefXDRUDT() throws {
        let udt = SCSpecTypeUDTXDR(name: "CustomStruct")
        let typeDef = SCSpecTypeDefXDR.udt(udt)
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        switch decoded {
        case .udt(let decodedUDT):
            XCTAssertEqual(decodedUDT.name, "CustomStruct")
        default:
            XCTFail("Expected udt type")
        }
    }

    // MARK: - SCSpecUDTStructFieldV0XDR Tests

    func testSCSpecUDTStructFieldV0XDR() throws {
        let field = SCSpecUDTStructFieldV0XDR(doc: "Field documentation", name: "amount", type: .u64)
        let encoded = try XDREncoder.encode(field)
        let decoded = try XDRDecoder.decode(SCSpecUDTStructFieldV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Field documentation")
        XCTAssertEqual(decoded.name, "amount")
        XCTAssertEqual(decoded.type.type(), SCSpecType.u64.rawValue)
    }

    // MARK: - SCSpecUDTStructV0XDR Tests

    func testSCSpecUDTStructV0XDR() throws {
        let field1 = SCSpecUDTStructFieldV0XDR(doc: "Name field", name: "name", type: .string)
        let field2 = SCSpecUDTStructFieldV0XDR(doc: "Amount field", name: "amount", type: .u64)
        let structDef = SCSpecUDTStructV0XDR(doc: "User struct", lib: "mylib", name: "User", fields: [field1, field2])

        let encoded = try XDREncoder.encode(structDef)
        let decoded = try XDRDecoder.decode(SCSpecUDTStructV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "User struct")
        XCTAssertEqual(decoded.lib, "mylib")
        XCTAssertEqual(decoded.name, "User")
        XCTAssertEqual(decoded.fields.count, 2)
        XCTAssertEqual(decoded.fields[0].name, "name")
        XCTAssertEqual(decoded.fields[1].name, "amount")
    }

    func testSCSpecUDTStructV0XDREmpty() throws {
        let structDef = SCSpecUDTStructV0XDR(doc: "", lib: "", name: "EmptyStruct", fields: [])
        let encoded = try XDREncoder.encode(structDef)
        let decoded = try XDRDecoder.decode(SCSpecUDTStructV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.fields.count, 0)
    }

    // MARK: - SCSpecUDTUnionCaseV0XDR Tests

    func testSCSpecUDTUnionCaseVoidV0XDR() throws {
        let voidCase = SCSpecUDTUnionCaseVoidV0XDR(doc: "None case", name: "None")
        let unionCase = SCSpecUDTUnionCaseV0XDR.voidV0(voidCase)
        let encoded = try XDREncoder.encode(unionCase)
        let decoded = try XDRDecoder.decode(SCSpecUDTUnionCaseV0XDR.self, data: encoded)

        switch decoded {
        case .voidV0(let decodedCase):
            XCTAssertEqual(decodedCase.doc, "None case")
            XCTAssertEqual(decodedCase.name, "None")
        default:
            XCTFail("Expected voidV0 case")
        }
    }

    func testSCSpecUDTUnionCaseTupleV0XDR() throws {
        let tupleCase = SCSpecUDTUnionCaseTupleV0XDR(doc: "Some case", name: "Some", type: [.u32])
        let unionCase = SCSpecUDTUnionCaseV0XDR.tupleV0(tupleCase)
        let encoded = try XDREncoder.encode(unionCase)
        let decoded = try XDRDecoder.decode(SCSpecUDTUnionCaseV0XDR.self, data: encoded)

        switch decoded {
        case .tupleV0(let decodedCase):
            XCTAssertEqual(decodedCase.doc, "Some case")
            XCTAssertEqual(decodedCase.name, "Some")
            XCTAssertEqual(decodedCase.type.count, 1)
        default:
            XCTFail("Expected tupleV0 case")
        }
    }

    // MARK: - SCSpecUDTUnionV0XDR Tests

    func testSCSpecUDTUnionV0XDR() throws {
        let voidCase = SCSpecUDTUnionCaseVoidV0XDR(doc: "None", name: "None")
        let tupleCase = SCSpecUDTUnionCaseTupleV0XDR(doc: "Some", name: "Some", type: [.u32])
        let cases = [SCSpecUDTUnionCaseV0XDR.voidV0(voidCase), SCSpecUDTUnionCaseV0XDR.tupleV0(tupleCase)]
        let unionDef = SCSpecUDTUnionV0XDR(doc: "Option union", lib: "std", name: "Option", cases: cases)

        let encoded = try XDREncoder.encode(unionDef)
        let decoded = try XDRDecoder.decode(SCSpecUDTUnionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Option union")
        XCTAssertEqual(decoded.lib, "std")
        XCTAssertEqual(decoded.name, "Option")
        XCTAssertEqual(decoded.cases.count, 2)
    }

    // MARK: - SCSpecUDTEnumCaseV0XDR Tests

    func testSCSpecUDTEnumCaseV0XDR() throws {
        let enumCase = SCSpecUDTEnumCaseV0XDR(doc: "Success case", name: "Success", value: 0)
        let encoded = try XDREncoder.encode(enumCase)
        let decoded = try XDRDecoder.decode(SCSpecUDTEnumCaseV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Success case")
        XCTAssertEqual(decoded.name, "Success")
        XCTAssertEqual(decoded.value, 0)
    }

    // MARK: - SCSpecUDTEnumV0XDR Tests

    func testSCSpecUDTEnumV0XDR() throws {
        let case1 = SCSpecUDTEnumCaseV0XDR(doc: "Success", name: "Success", value: 0)
        let case2 = SCSpecUDTEnumCaseV0XDR(doc: "Error", name: "Error", value: 1)
        let enumDef = SCSpecUDTEnumV0XDR(doc: "Status enum", lib: "mylib", name: "Status", cases: [case1, case2])

        let encoded = try XDREncoder.encode(enumDef)
        let decoded = try XDRDecoder.decode(SCSpecUDTEnumV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Status enum")
        XCTAssertEqual(decoded.lib, "mylib")
        XCTAssertEqual(decoded.name, "Status")
        XCTAssertEqual(decoded.cases.count, 2)
        XCTAssertEqual(decoded.cases[0].value, 0)
        XCTAssertEqual(decoded.cases[1].value, 1)
    }

    // MARK: - SCSpecUDTErrorEnumV0XDR Tests

    func testSCSpecUDTErrorEnumV0XDR() throws {
        let error1 = SCSpecUDTErrorEnumCaseV0XDR(doc: "Invalid input", name: "InvalidInput", value: 1)
        let error2 = SCSpecUDTErrorEnumCaseV0XDR(doc: "Not found", name: "NotFound", value: 2)
        let errorEnum = SCSpecUDTErrorEnumV0XDR(doc: "Error codes", lib: "errors", name: "ErrorCode", cases: [error1, error2])

        let encoded = try XDREncoder.encode(errorEnum)
        let decoded = try XDRDecoder.decode(SCSpecUDTErrorEnumV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Error codes")
        XCTAssertEqual(decoded.lib, "errors")
        XCTAssertEqual(decoded.name, "ErrorCode")
        XCTAssertEqual(decoded.cases.count, 2)
    }

    // MARK: - SCSpecFunctionInputV0XDR Tests

    func testSCSpecFunctionInputV0XDR() throws {
        let input = SCSpecFunctionInputV0XDR(doc: "User address", name: "user", type: .address)
        let encoded = try XDREncoder.encode(input)
        let decoded = try XDRDecoder.decode(SCSpecFunctionInputV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "User address")
        XCTAssertEqual(decoded.name, "user")
        XCTAssertEqual(decoded.type.type(), SCSpecType.address.rawValue)
    }

    // MARK: - SCSpecFunctionV0XDR Tests

    func testSCSpecFunctionV0XDR() throws {
        let input1 = SCSpecFunctionInputV0XDR(doc: "Amount", name: "amount", type: .u64)
        let input2 = SCSpecFunctionInputV0XDR(doc: "Recipient", name: "to", type: .address)
        let function = SCSpecFunctionV0XDR(doc: "Transfer function", name: "transfer", inputs: [input1, input2], outputs: [.bool])

        let encoded = try XDREncoder.encode(function)
        let decoded = try XDRDecoder.decode(SCSpecFunctionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Transfer function")
        XCTAssertEqual(decoded.name, "transfer")
        XCTAssertEqual(decoded.inputs.count, 2)
        XCTAssertEqual(decoded.outputs.count, 1)
        XCTAssertEqual(decoded.outputs[0].type(), SCSpecType.bool.rawValue)
    }

    func testSCSpecFunctionV0XDRNoInputs() throws {
        let function = SCSpecFunctionV0XDR(doc: "Get balance", name: "balance", inputs: [], outputs: [.u64])
        let encoded = try XDREncoder.encode(function)
        let decoded = try XDRDecoder.decode(SCSpecFunctionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.inputs.count, 0)
        XCTAssertEqual(decoded.outputs.count, 1)
    }

    func testSCSpecFunctionV0XDRNoOutputs() throws {
        let input = SCSpecFunctionInputV0XDR(doc: "Value", name: "value", type: .u32)
        let function = SCSpecFunctionV0XDR(doc: "Store value", name: "store", inputs: [input], outputs: [])
        let encoded = try XDREncoder.encode(function)
        let decoded = try XDRDecoder.decode(SCSpecFunctionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.inputs.count, 1)
        XCTAssertEqual(decoded.outputs.count, 0)
    }

    // MARK: - SCSpecEventParamV0XDR Tests

    func testSCSpecEventParamV0XDRDataLocation() throws {
        let param = SCSpecEventParamV0XDR(doc: "Event data", name: "data", type: .string, location: .data)
        let encoded = try XDREncoder.encode(param)
        let decoded = try XDRDecoder.decode(SCSpecEventParamV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Event data")
        XCTAssertEqual(decoded.name, "data")
        XCTAssertEqual(decoded.location, .data)
    }

    func testSCSpecEventParamV0XDRTopicLocation() throws {
        let param = SCSpecEventParamV0XDR(doc: "Event topic", name: "topic", type: .symbol, location: .topicList)
        let encoded = try XDREncoder.encode(param)
        let decoded = try XDRDecoder.decode(SCSpecEventParamV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.location, .topicList)
    }

    // MARK: - SCSpecEventV0XDR Tests

    func testSCSpecEventV0XDR() throws {
        let param = SCSpecEventParamV0XDR(doc: "Amount", name: "amount", type: .u64, location: .data)
        let event = SCSpecEventV0XDR(
            doc: "Transfer event",
            lib: "events",
            name: "Transfer",
            prefixTopics: ["transfer"],
            params: [param],
            dataFormat: .singleValue
        )

        let encoded = try XDREncoder.encode(event)
        let decoded = try XDRDecoder.decode(SCSpecEventV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Transfer event")
        XCTAssertEqual(decoded.lib, "events")
        XCTAssertEqual(decoded.name, "Transfer")
        XCTAssertEqual(decoded.prefixTopics.count, 1)
        XCTAssertEqual(decoded.params.count, 1)
        XCTAssertEqual(decoded.dataFormat, .singleValue)
    }

    func testSCSpecEventV0XDRVecFormat() throws {
        let event = SCSpecEventV0XDR(
            doc: "Batch event",
            lib: "events",
            name: "Batch",
            prefixTopics: [],
            params: [],
            dataFormat: .vec
        )

        let encoded = try XDREncoder.encode(event)
        let decoded = try XDRDecoder.decode(SCSpecEventV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.dataFormat, .vec)
    }

    func testSCSpecEventV0XDRMapFormat() throws {
        let event = SCSpecEventV0XDR(
            doc: "Map event",
            lib: "events",
            name: "MapEvent",
            prefixTopics: [],
            params: [],
            dataFormat: .map
        )

        let encoded = try XDREncoder.encode(event)
        let decoded = try XDRDecoder.decode(SCSpecEventV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.dataFormat, .map)
    }

    // MARK: - SCSpecEntryXDR Tests

    func testSCSpecEntryXDRFunctionV0() throws {
        let function = SCSpecFunctionV0XDR(doc: "Test function", name: "test", inputs: [], outputs: [])
        let entry = SCSpecEntryXDR.functionV0(function)
        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        switch decoded {
        case .functionV0(let decodedFunction):
            XCTAssertEqual(decodedFunction.name, "test")
        default:
            XCTFail("Expected functionV0")
        }
    }

    func testSCSpecEntryXDRStructV0() throws {
        let structDef = SCSpecUDTStructV0XDR(doc: "Test struct", lib: "lib", name: "TestStruct", fields: [])
        let entry = SCSpecEntryXDR.structV0(structDef)
        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        switch decoded {
        case .structV0(let decodedStruct):
            XCTAssertEqual(decodedStruct.name, "TestStruct")
        default:
            XCTFail("Expected structV0")
        }
    }

    func testSCSpecEntryXDRUnionV0() throws {
        let unionDef = SCSpecUDTUnionV0XDR(doc: "Test union", lib: "lib", name: "TestUnion", cases: [])
        let entry = SCSpecEntryXDR.unionV0(unionDef)
        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        switch decoded {
        case .unionV0(let decodedUnion):
            XCTAssertEqual(decodedUnion.name, "TestUnion")
        default:
            XCTFail("Expected unionV0")
        }
    }

    func testSCSpecEntryXDREnumV0() throws {
        let enumDef = SCSpecUDTEnumV0XDR(doc: "Test enum", lib: "lib", name: "TestEnum", cases: [])
        let entry = SCSpecEntryXDR.enumV0(enumDef)
        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        switch decoded {
        case .enumV0(let decodedEnum):
            XCTAssertEqual(decodedEnum.name, "TestEnum")
        default:
            XCTFail("Expected enumV0")
        }
    }

    func testSCSpecEntryXDRErrorEnumV0() throws {
        let errorEnum = SCSpecUDTErrorEnumV0XDR(doc: "Test error", lib: "lib", name: "TestError", cases: [])
        let entry = SCSpecEntryXDR.errorEnumV0(errorEnum)
        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        switch decoded {
        case .errorEnumV0(let decodedError):
            XCTAssertEqual(decodedError.name, "TestError")
        default:
            XCTFail("Expected errorEnumV0")
        }
    }

    func testSCSpecEntryXDREventV0() throws {
        let event = SCSpecEventV0XDR(doc: "Test event", lib: "lib", name: "TestEvent", prefixTopics: [], params: [], dataFormat: .singleValue)
        let entry = SCSpecEntryXDR.eventV0(event)
        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        switch decoded {
        case .eventV0(let decodedEvent):
            XCTAssertEqual(decodedEvent.name, "TestEvent")
        default:
            XCTFail("Expected eventV0")
        }
    }

    // MARK: - Enum Type Tests

    func testSCSpecTypeRawValues() {
        XCTAssertEqual(SCSpecType.val.rawValue, 0)
        XCTAssertEqual(SCSpecType.bool.rawValue, 1)
        XCTAssertEqual(SCSpecType.void.rawValue, 2)
        XCTAssertEqual(SCSpecType.error.rawValue, 3)
        XCTAssertEqual(SCSpecType.u32.rawValue, 4)
        XCTAssertEqual(SCSpecType.i32.rawValue, 5)
        XCTAssertEqual(SCSpecType.u64.rawValue, 6)
        XCTAssertEqual(SCSpecType.i64.rawValue, 7)
        XCTAssertEqual(SCSpecType.timepoint.rawValue, 8)
        XCTAssertEqual(SCSpecType.duration.rawValue, 9)
        XCTAssertEqual(SCSpecType.u128.rawValue, 10)
        XCTAssertEqual(SCSpecType.i128.rawValue, 11)
        XCTAssertEqual(SCSpecType.u256.rawValue, 12)
        XCTAssertEqual(SCSpecType.i256.rawValue, 13)
        XCTAssertEqual(SCSpecType.bytes.rawValue, 14)
        XCTAssertEqual(SCSpecType.string.rawValue, 16)
        XCTAssertEqual(SCSpecType.symbol.rawValue, 17)
        XCTAssertEqual(SCSpecType.address.rawValue, 19)
        XCTAssertEqual(SCSpecType.option.rawValue, 1000)
        XCTAssertEqual(SCSpecType.result.rawValue, 1001)
        XCTAssertEqual(SCSpecType.vec.rawValue, 1002)
        XCTAssertEqual(SCSpecType.map.rawValue, 1004)
        XCTAssertEqual(SCSpecType.tuple.rawValue, 1005)
        XCTAssertEqual(SCSpecType.bytesN.rawValue, 1006)
        XCTAssertEqual(SCSpecType.udt.rawValue, 2000)
    }

    func testSCSpecEventDataFormatRawValues() {
        XCTAssertEqual(SCSpecEventDataFormat.singleValue.rawValue, 0)
        XCTAssertEqual(SCSpecEventDataFormat.vec.rawValue, 1)
        XCTAssertEqual(SCSpecEventDataFormat.map.rawValue, 2)
    }

    func testSCSpecEventParamLocationV0RawValues() {
        XCTAssertEqual(SCSpecEventParamLocationV0.data.rawValue, 0)
        XCTAssertEqual(SCSpecEventParamLocationV0.topicList.rawValue, 1)
    }

    func testSCSpecEntryKindRawValues() {
        XCTAssertEqual(SCSpecEntryKind.functionV0.rawValue, 0)
        XCTAssertEqual(SCSpecEntryKind.structV0.rawValue, 1)
        XCTAssertEqual(SCSpecEntryKind.unionV0.rawValue, 2)
        XCTAssertEqual(SCSpecEntryKind.enumV0.rawValue, 3)
        XCTAssertEqual(SCSpecEntryKind.errorEnumV0.rawValue, 4)
        XCTAssertEqual(SCSpecEntryKind.entryEventV0.rawValue, 5)
    }

    // MARK: - SCMetaV0XDR Tests (from Stellar-contract-meta.x)

    func testSCMetaV0XDRRoundTrip() throws {
        let original = SCMetaV0XDR(key: "version", value: "1.2.3")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMetaV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.key, "version")
        XCTAssertEqual(decoded.value, "1.2.3")
    }

    func testSCMetaV0XDREmptyStrings() throws {
        let original = SCMetaV0XDR(key: "", value: "")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMetaV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.key, "")
        XCTAssertEqual(decoded.value, "")
    }

    func testSCMetaV0XDRLongValues() throws {
        let longKey = "contract_description_key"
        let longValue = "This is a longer metadata value that describes the contract behavior in detail"
        let original = SCMetaV0XDR(key: longKey, value: longValue)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMetaV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.key, longKey)
        XCTAssertEqual(decoded.value, longValue)
    }

    // MARK: - SCMetaKind Tests (from Stellar-contract-meta.x)

    func testSCMetaKindRoundTrip() throws {
        let original = SCMetaKind.v0
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMetaKind.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    func testSCMetaKindRawValues() {
        XCTAssertEqual(SCMetaKind.v0.rawValue, 0)
    }

    // MARK: - SCMetaEntryXDR Tests (from Stellar-contract-meta.x)

    func testSCMetaEntryXDRV0RoundTrip() throws {
        let meta = SCMetaV0XDR(key: "author", value: "stellar-team")
        let original = SCMetaEntryXDR.v0(meta)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMetaEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCMetaKind.v0.rawValue)
        if case .v0(let decodedMeta) = decoded {
            XCTAssertEqual(decodedMeta.key, "author")
            XCTAssertEqual(decodedMeta.value, "stellar-team")
        } else {
            XCTFail("Expected .v0 case")
        }
    }

    func testSCMetaEntryXDRV0EmptyMeta() throws {
        let meta = SCMetaV0XDR(key: "", value: "")
        let original = SCMetaEntryXDR.v0(meta)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCMetaEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCMetaKind.v0.rawValue)
        if case .v0(let decodedMeta) = decoded {
            XCTAssertEqual(decodedMeta.key, "")
            XCTAssertEqual(decodedMeta.value, "")
        } else {
            XCTFail("Expected .v0 case")
        }
    }

    // MARK: - SCEnvMetaEntryXDRInterfaceVersionXDR Tests (from Stellar-contract-env-meta.x)

    func testSCEnvMetaEntryXDRInterfaceVersionXDRRoundTrip() throws {
        let original = SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: 22, preRelease: 3)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCEnvMetaEntryXDRInterfaceVersionXDR.self, data: encoded)

        XCTAssertEqual(decoded.protocol, 22)
        XCTAssertEqual(decoded.preRelease, 3)
    }

    func testSCEnvMetaEntryXDRInterfaceVersionXDRZeroPreRelease() throws {
        let original = SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: 21, preRelease: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCEnvMetaEntryXDRInterfaceVersionXDR.self, data: encoded)

        XCTAssertEqual(decoded.protocol, 21)
        XCTAssertEqual(decoded.preRelease, 0)
    }

    func testSCEnvMetaEntryXDRInterfaceVersionXDRMaxValues() throws {
        let original = SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: UInt32.max, preRelease: UInt32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCEnvMetaEntryXDRInterfaceVersionXDR.self, data: encoded)

        XCTAssertEqual(decoded.protocol, UInt32.max)
        XCTAssertEqual(decoded.preRelease, UInt32.max)
    }

    // MARK: - SCEnvMetaKind Tests (from Stellar-contract-env-meta.x)

    func testSCEnvMetaKindRoundTrip() throws {
        let original = SCEnvMetaKind.interfaceVersion
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCEnvMetaKind.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - SCEnvMetaEntryXDR Tests (from Stellar-contract-env-meta.x)

    func testSCEnvMetaEntryXDRRoundTrip() throws {
        let iv = SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: 22, preRelease: 1)
        let original = SCEnvMetaEntryXDR.interfaceVersion(iv)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCEnvMetaEntryXDR.self, data: encoded)

        XCTAssertEqual(decoded.type(), SCEnvMetaKind.interfaceVersion.rawValue)
        if case .interfaceVersion(let decodedIV) = decoded {
            XCTAssertEqual(decodedIV.protocol, 22)
            XCTAssertEqual(decodedIV.preRelease, 1)
        } else {
            XCTFail("Expected .interfaceVersion case")
        }
    }

    // MARK: - SCSpecType Enum Round-Trip Tests

    func testSCSpecTypeEnumRoundTrip() throws {
        let allCases: [SCSpecType] = [
            .val, .bool, .void, .error, .u32, .i32, .u64, .i64,
            .timepoint, .duration, .u128, .i128, .u256, .i256,
            .bytes, .string, .symbol, .address, .muxedAddress,
            .option, .result, .vec, .map, .tuple, .bytesN, .udt
        ]

        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCSpecType.self, data: encoded)
            XCTAssertEqual(original, decoded, "Round-trip failed for SCSpecType.\(original)")
        }
    }

    // MARK: - SCSpecUDTUnionCaseV0Kind Tests

    func testSCSpecUDTUnionCaseV0KindRoundTrip() throws {
        let voidCase = SCSpecUDTUnionCaseV0Kind.voidV0
        let encoded1 = try XDREncoder.encode(voidCase)
        let decoded1 = try XDRDecoder.decode(SCSpecUDTUnionCaseV0Kind.self, data: encoded1)
        XCTAssertEqual(voidCase, decoded1)

        let tupleCase = SCSpecUDTUnionCaseV0Kind.tupleV0
        let encoded2 = try XDREncoder.encode(tupleCase)
        let decoded2 = try XDRDecoder.decode(SCSpecUDTUnionCaseV0Kind.self, data: encoded2)
        XCTAssertEqual(tupleCase, decoded2)
    }

    func testSCSpecUDTUnionCaseV0KindRawValues() {
        XCTAssertEqual(SCSpecUDTUnionCaseV0Kind.voidV0.rawValue, 0)
        XCTAssertEqual(SCSpecUDTUnionCaseV0Kind.tupleV0.rawValue, 1)
    }

    // MARK: - SCSpecUDTErrorEnumCaseV0XDR Standalone Tests

    func testSCSpecUDTErrorEnumCaseV0XDRStandalone() throws {
        let original = SCSpecUDTErrorEnumCaseV0XDR(doc: "Unauthorized access attempt", name: "Unauthorized", value: 403)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCSpecUDTErrorEnumCaseV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Unauthorized access attempt")
        XCTAssertEqual(decoded.name, "Unauthorized")
        XCTAssertEqual(decoded.value, 403)
    }

    func testSCSpecUDTErrorEnumCaseV0XDRZeroValue() throws {
        let original = SCSpecUDTErrorEnumCaseV0XDR(doc: "", name: "OK", value: 0)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCSpecUDTErrorEnumCaseV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "")
        XCTAssertEqual(decoded.name, "OK")
        XCTAssertEqual(decoded.value, 0)
    }

    func testSCSpecUDTErrorEnumCaseV0XDRMaxValue() throws {
        let original = SCSpecUDTErrorEnumCaseV0XDR(doc: "Max error", name: "MaxError", value: UInt32.max)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCSpecUDTErrorEnumCaseV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.value, UInt32.max)
    }

    // MARK: - SCSpecEventDataFormat Enum Round-Trip Tests

    func testSCSpecEventDataFormatRoundTrip() throws {
        let allCases: [SCSpecEventDataFormat] = [.singleValue, .vec, .map]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCSpecEventDataFormat.self, data: encoded)
            XCTAssertEqual(original, decoded, "Round-trip failed for SCSpecEventDataFormat.\(original)")
        }
    }

    // MARK: - SCSpecEventParamLocationV0 Enum Round-Trip Tests

    func testSCSpecEventParamLocationV0RoundTrip() throws {
        let allCases: [SCSpecEventParamLocationV0] = [.data, .topicList]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCSpecEventParamLocationV0.self, data: encoded)
            XCTAssertEqual(original, decoded, "Round-trip failed for SCSpecEventParamLocationV0.\(original)")
        }
    }

    // MARK: - SCSpecEntryKind Enum Round-Trip Tests

    func testSCSpecEntryKindRoundTrip() throws {
        let allCases: [SCSpecEntryKind] = [.functionV0, .structV0, .unionV0, .enumV0, .errorEnumV0, .entryEventV0]
        for original in allCases {
            let encoded = try XDREncoder.encode(original)
            let decoded = try XDRDecoder.decode(SCSpecEntryKind.self, data: encoded)
            XCTAssertEqual(original, decoded, "Round-trip failed for SCSpecEntryKind.\(original)")
        }
    }

    // MARK: - SCSpecTypeDefXDR Additional Tests (nested/complex)

    func testSCSpecTypeDefXDRNestedOption() throws {
        // Option containing a Vec of u32
        let innerVec = SCSpecTypeVecXDR(elementType: .u32)
        let vecDef = SCSpecTypeDefXDR.vec(innerVec)
        let option = SCSpecTypeOptionXDR(valueType: vecDef)
        let typeDef = SCSpecTypeDefXDR.option(option)

        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        if case .option(let decodedOption) = decoded {
            if case .vec(let decodedVec) = decodedOption.valueType {
                XCTAssertEqual(decodedVec.elementType.type(), SCSpecType.u32.rawValue)
            } else {
                XCTFail("Expected vec inside option")
            }
        } else {
            XCTFail("Expected option type")
        }
    }

    func testSCSpecTypeDefXDRNestedMap() throws {
        // Map from symbol to Option<u64>
        let innerOption = SCSpecTypeOptionXDR(valueType: .u64)
        let mapDef = SCSpecTypeMapXDR(keyType: .symbol, valueType: .option(innerOption))
        let typeDef = SCSpecTypeDefXDR.map(mapDef)

        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        if case .map(let decodedMap) = decoded {
            XCTAssertEqual(decodedMap.keyType.type(), SCSpecType.symbol.rawValue)
            if case .option(let decodedOption) = decodedMap.valueType {
                XCTAssertEqual(decodedOption.valueType.type(), SCSpecType.u64.rawValue)
            } else {
                XCTFail("Expected option as map value type")
            }
        } else {
            XCTFail("Expected map type")
        }
    }

    func testSCSpecTypeDefXDRResultWithUDT() throws {
        // Result<UDT, error>
        let udt = SCSpecTypeUDTXDR(name: "MyToken")
        let result = SCSpecTypeResultXDR(okType: .udt(udt), errorType: .error)
        let typeDef = SCSpecTypeDefXDR.result(result)

        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)

        if case .result(let decodedResult) = decoded {
            if case .udt(let decodedUDT) = decodedResult.okType {
                XCTAssertEqual(decodedUDT.name, "MyToken")
            } else {
                XCTFail("Expected udt as ok type")
            }
            XCTAssertEqual(decodedResult.errorType.type(), SCSpecType.error.rawValue)
        } else {
            XCTFail("Expected result type")
        }
    }

    func testSCSpecTypeTupleXDRMaxElements() throws {
        // Tuple with 12 elements (max per spec)
        let types: [SCSpecTypeDefXDR] = [
            .u32, .i32, .u64, .i64, .bool, .string,
            .symbol, .bytes, .address, .u128, .i128, .u256
        ]
        let tuple = SCSpecTypeTupleXDR(valueTypes: types)
        let encoded = try XDREncoder.encode(tuple)
        let decoded = try XDRDecoder.decode(SCSpecTypeTupleXDR.self, data: encoded)

        XCTAssertEqual(decoded.valueTypes.count, 12)
        XCTAssertEqual(decoded.valueTypes[0].type(), SCSpecType.u32.rawValue)
        XCTAssertEqual(decoded.valueTypes[11].type(), SCSpecType.u256.rawValue)
    }

    // MARK: - SCSpecUDTUnionCaseVoidV0XDR Standalone Tests

    func testSCSpecUDTUnionCaseVoidV0XDRStandalone() throws {
        let original = SCSpecUDTUnionCaseVoidV0XDR(doc: "Represents absence of value", name: "Nothing")
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCSpecUDTUnionCaseVoidV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Represents absence of value")
        XCTAssertEqual(decoded.name, "Nothing")
    }

    // MARK: - SCSpecUDTUnionCaseTupleV0XDR Standalone Tests

    func testSCSpecUDTUnionCaseTupleV0XDRMultipleTypes() throws {
        let types: [SCSpecTypeDefXDR] = [.address, .u64, .symbol]
        let original = SCSpecUDTUnionCaseTupleV0XDR(doc: "Transfer case", name: "Transfer", type: types)
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCSpecUDTUnionCaseTupleV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Transfer case")
        XCTAssertEqual(decoded.name, "Transfer")
        XCTAssertEqual(decoded.type.count, 3)
        XCTAssertEqual(decoded.type[0].type(), SCSpecType.address.rawValue)
        XCTAssertEqual(decoded.type[1].type(), SCSpecType.u64.rawValue)
        XCTAssertEqual(decoded.type[2].type(), SCSpecType.symbol.rawValue)
    }

    // MARK: - SCSpecFunctionV0XDR Complex Tests

    func testSCSpecFunctionV0XDRComplexFunction() throws {
        let input1 = SCSpecFunctionInputV0XDR(doc: "Source address", name: "from", type: .address)
        let input2 = SCSpecFunctionInputV0XDR(doc: "Destination address", name: "to", type: .address)
        let input3 = SCSpecFunctionInputV0XDR(doc: "Amount to transfer", name: "amount", type: .i128)
        let outputOption = SCSpecTypeOptionXDR(valueType: .u64)
        let function = SCSpecFunctionV0XDR(
            doc: "Transfer tokens between accounts",
            name: "transfer",
            inputs: [input1, input2, input3],
            outputs: [.option(outputOption)]
        )

        let encoded = try XDREncoder.encode(function)
        let decoded = try XDRDecoder.decode(SCSpecFunctionV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Transfer tokens between accounts")
        XCTAssertEqual(decoded.name, "transfer")
        XCTAssertEqual(decoded.inputs.count, 3)
        XCTAssertEqual(decoded.inputs[0].name, "from")
        XCTAssertEqual(decoded.inputs[1].name, "to")
        XCTAssertEqual(decoded.inputs[2].name, "amount")
        XCTAssertEqual(decoded.inputs[2].type.type(), SCSpecType.i128.rawValue)
        XCTAssertEqual(decoded.outputs.count, 1)
        if case .option(let decodedOutput) = decoded.outputs[0] {
            XCTAssertEqual(decodedOutput.valueType.type(), SCSpecType.u64.rawValue)
        } else {
            XCTFail("Expected option output type")
        }
    }

    // MARK: - SCSpecEventV0XDR Complex Tests

    func testSCSpecEventV0XDRMultipleParamsAndTopics() throws {
        let param1 = SCSpecEventParamV0XDR(doc: "Sender", name: "from", type: .address, location: .topicList)
        let param2 = SCSpecEventParamV0XDR(doc: "Receiver", name: "to", type: .address, location: .topicList)
        let param3 = SCSpecEventParamV0XDR(doc: "Amount", name: "amount", type: .i128, location: .data)
        let event = SCSpecEventV0XDR(
            doc: "Token transfer event",
            lib: "token",
            name: "transfer",
            prefixTopics: ["transfer", "token"],
            params: [param1, param2, param3],
            dataFormat: .singleValue
        )

        let encoded = try XDREncoder.encode(event)
        let decoded = try XDRDecoder.decode(SCSpecEventV0XDR.self, data: encoded)

        XCTAssertEqual(decoded.doc, "Token transfer event")
        XCTAssertEqual(decoded.lib, "token")
        XCTAssertEqual(decoded.name, "transfer")
        XCTAssertEqual(decoded.prefixTopics.count, 2)
        XCTAssertEqual(decoded.prefixTopics[0], "transfer")
        XCTAssertEqual(decoded.prefixTopics[1], "token")
        XCTAssertEqual(decoded.params.count, 3)
        XCTAssertEqual(decoded.params[0].location, .topicList)
        XCTAssertEqual(decoded.params[1].location, .topicList)
        XCTAssertEqual(decoded.params[2].location, .data)
        XCTAssertEqual(decoded.dataFormat, .singleValue)
    }

    // MARK: - SCSpecEntryXDR Complex Tests

    func testSCSpecEntryXDRFunctionWithComplexSpec() throws {
        // Full realistic function spec entry
        let input = SCSpecFunctionInputV0XDR(doc: "Token amount", name: "amount", type: .i128)
        let function = SCSpecFunctionV0XDR(doc: "Mint tokens", name: "mint", inputs: [input], outputs: [.bool])
        let entry = SCSpecEntryXDR.functionV0(function)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        if case .functionV0(let fn) = decoded {
            XCTAssertEqual(fn.doc, "Mint tokens")
            XCTAssertEqual(fn.name, "mint")
            XCTAssertEqual(fn.inputs.count, 1)
            XCTAssertEqual(fn.inputs[0].name, "amount")
            XCTAssertEqual(fn.outputs.count, 1)
        } else {
            XCTFail("Expected functionV0")
        }
    }

    func testSCSpecEntryXDRStructWithFields() throws {
        let field1 = SCSpecUDTStructFieldV0XDR(doc: "Token name", name: "name", type: .string)
        let field2 = SCSpecUDTStructFieldV0XDR(doc: "Token symbol", name: "symbol", type: .symbol)
        let field3 = SCSpecUDTStructFieldV0XDR(doc: "Decimals", name: "decimals", type: .u32)
        let structDef = SCSpecUDTStructV0XDR(doc: "Token metadata", lib: "token", name: "TokenInfo", fields: [field1, field2, field3])
        let entry = SCSpecEntryXDR.structV0(structDef)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        if case .structV0(let s) = decoded {
            XCTAssertEqual(s.name, "TokenInfo")
            XCTAssertEqual(s.fields.count, 3)
            XCTAssertEqual(s.fields[0].name, "name")
            XCTAssertEqual(s.fields[0].type.type(), SCSpecType.string.rawValue)
            XCTAssertEqual(s.fields[1].name, "symbol")
            XCTAssertEqual(s.fields[2].name, "decimals")
        } else {
            XCTFail("Expected structV0")
        }
    }

    func testSCSpecEntryXDRUnionWithMixedCases() throws {
        let voidCase = SCSpecUDTUnionCaseVoidV0XDR(doc: "No value", name: "None")
        let tupleCase = SCSpecUDTUnionCaseTupleV0XDR(doc: "Has value", name: "Some", type: [.u64, .address])
        let cases = [SCSpecUDTUnionCaseV0XDR.voidV0(voidCase), SCSpecUDTUnionCaseV0XDR.tupleV0(tupleCase)]
        let unionDef = SCSpecUDTUnionV0XDR(doc: "Optional value", lib: "core", name: "OptionalVal", cases: cases)
        let entry = SCSpecEntryXDR.unionV0(unionDef)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        if case .unionV0(let u) = decoded {
            XCTAssertEqual(u.name, "OptionalVal")
            XCTAssertEqual(u.lib, "core")
            XCTAssertEqual(u.cases.count, 2)
            if case .voidV0(let vc) = u.cases[0] {
                XCTAssertEqual(vc.name, "None")
            } else {
                XCTFail("Expected voidV0 for first case")
            }
            if case .tupleV0(let tc) = u.cases[1] {
                XCTAssertEqual(tc.name, "Some")
                XCTAssertEqual(tc.type.count, 2)
            } else {
                XCTFail("Expected tupleV0 for second case")
            }
        } else {
            XCTFail("Expected unionV0")
        }
    }

    func testSCSpecEntryXDREnumWithMultipleCases() throws {
        let case1 = SCSpecUDTEnumCaseV0XDR(doc: "Active status", name: "Active", value: 0)
        let case2 = SCSpecUDTEnumCaseV0XDR(doc: "Paused status", name: "Paused", value: 1)
        let case3 = SCSpecUDTEnumCaseV0XDR(doc: "Frozen status", name: "Frozen", value: 2)
        let enumDef = SCSpecUDTEnumV0XDR(doc: "Contract status", lib: "admin", name: "ContractStatus", cases: [case1, case2, case3])
        let entry = SCSpecEntryXDR.enumV0(enumDef)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        if case .enumV0(let e) = decoded {
            XCTAssertEqual(e.name, "ContractStatus")
            XCTAssertEqual(e.cases.count, 3)
            XCTAssertEqual(e.cases[0].name, "Active")
            XCTAssertEqual(e.cases[0].value, 0)
            XCTAssertEqual(e.cases[1].name, "Paused")
            XCTAssertEqual(e.cases[1].value, 1)
            XCTAssertEqual(e.cases[2].name, "Frozen")
            XCTAssertEqual(e.cases[2].value, 2)
        } else {
            XCTFail("Expected enumV0")
        }
    }

    func testSCSpecEntryXDRErrorEnumWithMultipleCases() throws {
        let err1 = SCSpecUDTErrorEnumCaseV0XDR(doc: "Balance too low", name: "InsufficientBalance", value: 1)
        let err2 = SCSpecUDTErrorEnumCaseV0XDR(doc: "Not authorized", name: "Unauthorized", value: 2)
        let err3 = SCSpecUDTErrorEnumCaseV0XDR(doc: "Contract is paused", name: "ContractPaused", value: 3)
        let errorEnum = SCSpecUDTErrorEnumV0XDR(doc: "Token errors", lib: "token", name: "TokenError", cases: [err1, err2, err3])
        let entry = SCSpecEntryXDR.errorEnumV0(errorEnum)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        if case .errorEnumV0(let ee) = decoded {
            XCTAssertEqual(ee.name, "TokenError")
            XCTAssertEqual(ee.cases.count, 3)
            XCTAssertEqual(ee.cases[0].name, "InsufficientBalance")
            XCTAssertEqual(ee.cases[0].value, 1)
            XCTAssertEqual(ee.cases[2].name, "ContractPaused")
            XCTAssertEqual(ee.cases[2].value, 3)
        } else {
            XCTFail("Expected errorEnumV0")
        }
    }

    func testSCSpecEntryXDREventWithParams() throws {
        let param = SCSpecEventParamV0XDR(doc: "Amount burned", name: "amount", type: .i128, location: .data)
        let event = SCSpecEventV0XDR(doc: "Burn event", lib: "token", name: "burn", prefixTopics: ["burn"], params: [param], dataFormat: .singleValue)
        let entry = SCSpecEntryXDR.eventV0(event)

        let encoded = try XDREncoder.encode(entry)
        let decoded = try XDRDecoder.decode(SCSpecEntryXDR.self, data: encoded)

        if case .eventV0(let ev) = decoded {
            XCTAssertEqual(ev.name, "burn")
            XCTAssertEqual(ev.params.count, 1)
            XCTAssertEqual(ev.params[0].name, "amount")
            XCTAssertEqual(ev.params[0].type.type(), SCSpecType.i128.rawValue)
            XCTAssertEqual(ev.prefixTopics.count, 1)
        } else {
            XCTFail("Expected eventV0")
        }
    }

    // MARK: - SCSpecType muxedAddress Test

    func testSCSpecTypeMuxedAddressRawValue() {
        XCTAssertEqual(SCSpecType.muxedAddress.rawValue, 20)
    }

    func testSCSpecTypeMuxedAddressRoundTrip() throws {
        let original = SCSpecType.muxedAddress
        let encoded = try XDREncoder.encode(original)
        let decoded = try XDRDecoder.decode(SCSpecType.self, data: encoded)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - SCSpecTypeDefXDR muxedAddress Test

    func testSCSpecTypeDefXDRMuxedAddress() throws {
        let typeDef = SCSpecTypeDefXDR.muxedAddress
        let encoded = try XDREncoder.encode(typeDef)
        let decoded = try XDRDecoder.decode(SCSpecTypeDefXDR.self, data: encoded)
        XCTAssertEqual(decoded.type(), SCSpecType.muxedAddress.rawValue)
    }
}
