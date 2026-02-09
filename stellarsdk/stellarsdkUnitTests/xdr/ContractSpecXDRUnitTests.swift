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
        let error1 = SCSpecUDTEnumCaseV0XDR(doc: "Invalid input", name: "InvalidInput", value: 1)
        let error2 = SCSpecUDTEnumCaseV0XDR(doc: "Not found", name: "NotFound", value: 2)
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
}
