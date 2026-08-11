//
// GENERATED FILE - DO NOT EDIT
//
// This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It exercises
// the SEP-0051 (XDR-JSON) conversions of every type declared in one .x source. To
// regenerate, run:
//
//     make xdr-generate-tests
//
// Any manual edits will be overwritten on the next run.
//

import XCTest
import Foundation
import stellarsdk

final class GeneratedXdrJsonStellarContractSpecUnitTests: XCTestCase {

    func test_SCSpecEntryKind_SC_SPEC_ENTRY_EVENT_V0() throws {
        let value: SCSpecEntryKind = .entryEventV0
        XCTAssertEqual(try value.toXdrJson(), "\"event_v0\"",
                       "SCSpecEntryKind.entryEventV0 must render as event_v0")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "SCSpecEntryKind.entryEventV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecEntryKind.fromXdrJson("\"event_v0\""), value,
                       "event_v0 must read back as SCSpecEntryKind.entryEventV0")
    }

    func test_SCSpecEntryKind_SC_SPEC_ENTRY_FUNCTION_V0() throws {
        let value: SCSpecEntryKind = .functionV0
        XCTAssertEqual(try value.toXdrJson(), "\"function_v0\"",
                       "SCSpecEntryKind.functionV0 must render as function_v0")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCSpecEntryKind.functionV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecEntryKind.fromXdrJson("\"function_v0\""), value,
                       "function_v0 must read back as SCSpecEntryKind.functionV0")
    }

    func test_SCSpecEntryKind_SC_SPEC_ENTRY_UDT_ENUM_V0() throws {
        let value: SCSpecEntryKind = .enumV0
        XCTAssertEqual(try value.toXdrJson(), "\"udt_enum_v0\"",
                       "SCSpecEntryKind.enumV0 must render as udt_enum_v0")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SCSpecEntryKind.enumV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecEntryKind.fromXdrJson("\"udt_enum_v0\""), value,
                       "udt_enum_v0 must read back as SCSpecEntryKind.enumV0")
    }

    func test_SCSpecEntryKind_SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0() throws {
        let value: SCSpecEntryKind = .errorEnumV0
        XCTAssertEqual(try value.toXdrJson(), "\"udt_error_enum_v0\"",
                       "SCSpecEntryKind.errorEnumV0 must render as udt_error_enum_v0")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "SCSpecEntryKind.errorEnumV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecEntryKind.fromXdrJson("\"udt_error_enum_v0\""), value,
                       "udt_error_enum_v0 must read back as SCSpecEntryKind.errorEnumV0")
    }

    func test_SCSpecEntryKind_SC_SPEC_ENTRY_UDT_STRUCT_V0() throws {
        let value: SCSpecEntryKind = .structV0
        XCTAssertEqual(try value.toXdrJson(), "\"udt_struct_v0\"",
                       "SCSpecEntryKind.structV0 must render as udt_struct_v0")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCSpecEntryKind.structV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecEntryKind.fromXdrJson("\"udt_struct_v0\""), value,
                       "udt_struct_v0 must read back as SCSpecEntryKind.structV0")
    }

    func test_SCSpecEntryKind_SC_SPEC_ENTRY_UDT_UNION_V0() throws {
        let value: SCSpecEntryKind = .unionV0
        XCTAssertEqual(try value.toXdrJson(), "\"udt_union_v0\"",
                       "SCSpecEntryKind.unionV0 must render as udt_union_v0")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCSpecEntryKind.unionV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecEntryKind.fromXdrJson("\"udt_union_v0\""), value,
                       "udt_union_v0 must read back as SCSpecEntryKind.unionV0")
    }

    func test_SCSpecEntryKind_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCSpecEntryKind.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCSpecEntryKind: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryKind")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCSpecEntryXDR_enumV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecEntryXDR.fromXdrJson("\"udt_enum_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecEntryXDR.udt_enum_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryXDR")
            XCTAssertEqual(key, "udt_enum_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecEntryXDR_enumV0_roundTrip() throws {
        let original: SCSpecEntryXDR = .enumV0(SCSpecUDTEnumV0XDR(doc: "test_string", lib: "test_string", name: "test_string", cases: [SCSpecUDTEnumCaseV0XDR(doc: "test_string", name: "test_string", value: UInt32(42))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEntryXDR.fromXdrJson(json)
        let viaValue = try SCSpecEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecEntryXDR_errorEnumV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecEntryXDR.fromXdrJson("\"udt_error_enum_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecEntryXDR.udt_error_enum_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryXDR")
            XCTAssertEqual(key, "udt_error_enum_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecEntryXDR_errorEnumV0_roundTrip() throws {
        let original: SCSpecEntryXDR = .errorEnumV0(SCSpecUDTErrorEnumV0XDR(doc: "test_string", lib: "test_string", name: "test_string", cases: [SCSpecUDTErrorEnumCaseV0XDR(doc: "test_string", name: "test_string", value: UInt32(42))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEntryXDR.fromXdrJson(json)
        let viaValue = try SCSpecEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecEntryXDR_eventV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecEntryXDR.fromXdrJson("\"event_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecEntryXDR.event_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryXDR")
            XCTAssertEqual(key, "event_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecEntryXDR_eventV0_roundTrip() throws {
        let original: SCSpecEntryXDR = .eventV0(SCSpecEventV0XDR(doc: "test_string", lib: "test_string", name: "test_string", prefixTopics: ["test_string"], params: [SCSpecEventParamV0XDR(doc: "test_string", name: "test_string", type: .val, location: .data)], dataFormat: .singleValue))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEntryXDR.fromXdrJson(json)
        let viaValue = try SCSpecEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecEntryXDR_functionV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecEntryXDR.fromXdrJson("\"function_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecEntryXDR.function_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryXDR")
            XCTAssertEqual(key, "function_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecEntryXDR_functionV0_roundTrip() throws {
        let original: SCSpecEntryXDR = .functionV0(SCSpecFunctionV0XDR(doc: "test_string", name: "test_string", inputs: [SCSpecFunctionInputV0XDR(doc: "test_string", name: "test_string", type: .val)], outputs: [.val]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEntryXDR.fromXdrJson(json)
        let viaValue = try SCSpecEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecEntryXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCSpecEntryXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCSpecEntryXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCSpecEntryXDR_structV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecEntryXDR.fromXdrJson("\"udt_struct_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecEntryXDR.udt_struct_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryXDR")
            XCTAssertEqual(key, "udt_struct_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecEntryXDR_structV0_roundTrip() throws {
        let original: SCSpecEntryXDR = .structV0(SCSpecUDTStructV0XDR(doc: "test_string", lib: "test_string", name: "test_string", fields: [SCSpecUDTStructFieldV0XDR(doc: "test_string", name: "test_string", type: .val)]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEntryXDR.fromXdrJson(json)
        let viaValue = try SCSpecEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecEntryXDR_unionV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecEntryXDR.fromXdrJson("\"udt_union_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecEntryXDR.udt_union_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEntryXDR")
            XCTAssertEqual(key, "udt_union_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecEntryXDR_unionV0_roundTrip() throws {
        let original: SCSpecEntryXDR = .unionV0(SCSpecUDTUnionV0XDR(doc: "test_string", lib: "test_string", name: "test_string", cases: [.voidV0(SCSpecUDTUnionCaseVoidV0XDR(doc: "test_string", name: "test_string"))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEntryXDR.fromXdrJson(json)
        let viaValue = try SCSpecEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecEventDataFormat_SC_SPEC_EVENT_DATA_FORMAT_MAP() throws {
        let value: SCSpecEventDataFormat = .map
        XCTAssertEqual(try value.toXdrJson(), "\"map\"",
                       "SCSpecEventDataFormat.map must render as map")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCSpecEventDataFormat.map must keep its XDR value")
        XCTAssertEqual(try SCSpecEventDataFormat.fromXdrJson("\"map\""), value,
                       "map must read back as SCSpecEventDataFormat.map")
    }

    func test_SCSpecEventDataFormat_SC_SPEC_EVENT_DATA_FORMAT_SINGLE_VALUE() throws {
        let value: SCSpecEventDataFormat = .singleValue
        XCTAssertEqual(try value.toXdrJson(), "\"single_value\"",
                       "SCSpecEventDataFormat.singleValue must render as single_value")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCSpecEventDataFormat.singleValue must keep its XDR value")
        XCTAssertEqual(try SCSpecEventDataFormat.fromXdrJson("\"single_value\""), value,
                       "single_value must read back as SCSpecEventDataFormat.singleValue")
    }

    func test_SCSpecEventDataFormat_SC_SPEC_EVENT_DATA_FORMAT_VEC() throws {
        let value: SCSpecEventDataFormat = .vec
        XCTAssertEqual(try value.toXdrJson(), "\"vec\"",
                       "SCSpecEventDataFormat.vec must render as vec")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCSpecEventDataFormat.vec must keep its XDR value")
        XCTAssertEqual(try SCSpecEventDataFormat.fromXdrJson("\"vec\""), value,
                       "vec must read back as SCSpecEventDataFormat.vec")
    }

    func test_SCSpecEventDataFormat_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCSpecEventDataFormat.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCSpecEventDataFormat: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEventDataFormat")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCSpecEventParamLocationV0_SC_SPEC_EVENT_PARAM_LOCATION_DATA() throws {
        let value: SCSpecEventParamLocationV0 = .data
        XCTAssertEqual(try value.toXdrJson(), "\"data\"",
                       "SCSpecEventParamLocationV0.data must render as data")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCSpecEventParamLocationV0.data must keep its XDR value")
        XCTAssertEqual(try SCSpecEventParamLocationV0.fromXdrJson("\"data\""), value,
                       "data must read back as SCSpecEventParamLocationV0.data")
    }

    func test_SCSpecEventParamLocationV0_SC_SPEC_EVENT_PARAM_LOCATION_TOPIC_LIST() throws {
        let value: SCSpecEventParamLocationV0 = .topicList
        XCTAssertEqual(try value.toXdrJson(), "\"topic_list\"",
                       "SCSpecEventParamLocationV0.topicList must render as topic_list")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCSpecEventParamLocationV0.topicList must keep its XDR value")
        XCTAssertEqual(try SCSpecEventParamLocationV0.fromXdrJson("\"topic_list\""), value,
                       "topic_list must read back as SCSpecEventParamLocationV0.topicList")
    }

    func test_SCSpecEventParamLocationV0_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCSpecEventParamLocationV0.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCSpecEventParamLocationV0: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecEventParamLocationV0")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCSpecEventParamV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecEventParamV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecEventParamV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecEventParamV0XDR_roundTrip() throws {
        let original: SCSpecEventParamV0XDR = SCSpecEventParamV0XDR(doc: "test_string", name: "test_string", type: .val, location: .data)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEventParamV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecEventParamV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEventParamV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEventParamV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEventParamV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEventParamV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEventParamV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEventParamV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecEventV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecEventV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecEventV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecEventV0XDR_roundTrip() throws {
        let original: SCSpecEventV0XDR = SCSpecEventV0XDR(doc: "test_string", lib: "test_string", name: "test_string", prefixTopics: ["test_string"], params: [SCSpecEventParamV0XDR(doc: "test_string", name: "test_string", type: .val, location: .data)], dataFormat: .singleValue)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecEventV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecEventV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecEventV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecEventV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecEventV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecEventV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecEventV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecEventV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecFunctionInputV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecFunctionInputV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecFunctionInputV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecFunctionInputV0XDR_roundTrip() throws {
        let original: SCSpecFunctionInputV0XDR = SCSpecFunctionInputV0XDR(doc: "test_string", name: "test_string", type: .val)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecFunctionInputV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecFunctionInputV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecFunctionInputV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecFunctionInputV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecFunctionInputV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecFunctionInputV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecFunctionInputV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecFunctionInputV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecFunctionV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecFunctionV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecFunctionV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecFunctionV0XDR_roundTrip() throws {
        let original: SCSpecFunctionV0XDR = SCSpecFunctionV0XDR(doc: "test_string", name: "test_string", inputs: [SCSpecFunctionInputV0XDR(doc: "test_string", name: "test_string", type: .val)], outputs: [.val])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecFunctionV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecFunctionV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecFunctionV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecFunctionV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecFunctionV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecFunctionV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecFunctionV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecFunctionV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeBytesNXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecTypeBytesNXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecTypeBytesNXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecTypeBytesNXDR_roundTrip() throws {
        let original: SCSpecTypeBytesNXDR = SCSpecTypeBytesNXDR(n: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeBytesNXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeBytesNXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeBytesNXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeBytesNXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeBytesNXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeBytesNXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeBytesNXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeBytesNXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_address_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .address
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_bool_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .bool
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_bytesN_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"bytes_n\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecTypeDefXDR.bytes_n: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "bytes_n",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecTypeDefXDR_bytesN_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .bytesN(SCSpecTypeBytesNXDR(n: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_bytes_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .bytes
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_duration_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .duration
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_error_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .error
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_i128_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .i128
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_i256_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .i256
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_i32_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .i32
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_i64_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .i64
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_map_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"map\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecTypeDefXDR.map: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "map",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecTypeDefXDR_map_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .map(SCSpecTypeMapXDR(keyType: .val, valueType: .val))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_muxedAddress_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .muxedAddress
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_option_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"option\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecTypeDefXDR.option: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "option",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecTypeDefXDR_option_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .option(SCSpecTypeOptionXDR(valueType: .val))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCSpecTypeDefXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCSpecTypeDefXDR_result_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"result\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecTypeDefXDR.result: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "result",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecTypeDefXDR_result_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .result(SCSpecTypeResultXDR(okType: .val, errorType: .val))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_string_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .string
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_symbol_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .symbol
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_timepoint_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .timepoint
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_tuple_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"tuple\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecTypeDefXDR.tuple: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "tuple",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecTypeDefXDR_tuple_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .tuple(SCSpecTypeTupleXDR(valueTypes: [.val]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_u128_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .u128
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_u256_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .u256
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_u32_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .u32
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_u64_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .u64
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_udt_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"udt\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecTypeDefXDR.udt: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "udt",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecTypeDefXDR_udt_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .udt(SCSpecTypeUDTXDR(name: "test_string"))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_val_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .val
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_vec_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecTypeDefXDR.fromXdrJson("\"vec\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecTypeDefXDR.vec: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecTypeDefXDR")
            XCTAssertEqual(key, "vec",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecTypeDefXDR_vec_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .vec(SCSpecTypeVecXDR(elementType: .val))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeDefXDR_void_roundTrip() throws {
        let original: SCSpecTypeDefXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeDefXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeDefXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeDefXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeDefXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeDefXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeDefXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeDefXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeMapXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecTypeMapXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecTypeMapXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecTypeMapXDR_roundTrip() throws {
        let original: SCSpecTypeMapXDR = SCSpecTypeMapXDR(keyType: .val, valueType: .val)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeMapXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeMapXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeMapXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeMapXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeMapXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeMapXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeMapXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeMapXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeOptionXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecTypeOptionXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecTypeOptionXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecTypeOptionXDR_roundTrip() throws {
        let original: SCSpecTypeOptionXDR = SCSpecTypeOptionXDR(valueType: .val)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeOptionXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeOptionXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeOptionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeOptionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeOptionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeOptionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeOptionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeOptionXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeResultXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecTypeResultXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecTypeResultXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecTypeResultXDR_roundTrip() throws {
        let original: SCSpecTypeResultXDR = SCSpecTypeResultXDR(okType: .val, errorType: .val)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeResultXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeTupleXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecTypeTupleXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecTypeTupleXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecTypeTupleXDR_roundTrip() throws {
        let original: SCSpecTypeTupleXDR = SCSpecTypeTupleXDR(valueTypes: [.val])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeTupleXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeTupleXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeTupleXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeTupleXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeTupleXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeTupleXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeTupleXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeTupleXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeUDTXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecTypeUDTXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecTypeUDTXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecTypeUDTXDR_roundTrip() throws {
        let original: SCSpecTypeUDTXDR = SCSpecTypeUDTXDR(name: "test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeUDTXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeUDTXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeUDTXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeUDTXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeUDTXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeUDTXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeUDTXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeUDTXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecTypeVecXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecTypeVecXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecTypeVecXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecTypeVecXDR_roundTrip() throws {
        let original: SCSpecTypeVecXDR = SCSpecTypeVecXDR(elementType: .val)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecTypeVecXDR.fromXdrJson(json)
        let viaValue = try SCSpecTypeVecXDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecTypeVecXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecTypeVecXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecTypeVecXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecTypeVecXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecTypeVecXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecTypeVecXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecType_SC_SPEC_TYPE_ADDRESS() throws {
        let value: SCSpecType = .address
        XCTAssertEqual(try value.toXdrJson(), "\"address\"",
                       "SCSpecType.address must render as address")
        XCTAssertEqual(value.rawValue, Int32(19),
                       "SCSpecType.address must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"address\""), value,
                       "address must read back as SCSpecType.address")
    }

    func test_SCSpecType_SC_SPEC_TYPE_BOOL() throws {
        let value: SCSpecType = .bool
        XCTAssertEqual(try value.toXdrJson(), "\"bool\"",
                       "SCSpecType.bool must render as bool")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCSpecType.bool must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"bool\""), value,
                       "bool must read back as SCSpecType.bool")
    }

    func test_SCSpecType_SC_SPEC_TYPE_BYTES() throws {
        let value: SCSpecType = .bytes
        XCTAssertEqual(try value.toXdrJson(), "\"bytes\"",
                       "SCSpecType.bytes must render as bytes")
        XCTAssertEqual(value.rawValue, Int32(14),
                       "SCSpecType.bytes must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"bytes\""), value,
                       "bytes must read back as SCSpecType.bytes")
    }

    func test_SCSpecType_SC_SPEC_TYPE_BYTES_N() throws {
        let value: SCSpecType = .bytesN
        XCTAssertEqual(try value.toXdrJson(), "\"bytes_n\"",
                       "SCSpecType.bytesN must render as bytes_n")
        XCTAssertEqual(value.rawValue, Int32(1006),
                       "SCSpecType.bytesN must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"bytes_n\""), value,
                       "bytes_n must read back as SCSpecType.bytesN")
    }

    func test_SCSpecType_SC_SPEC_TYPE_DURATION() throws {
        let value: SCSpecType = .duration
        XCTAssertEqual(try value.toXdrJson(), "\"duration\"",
                       "SCSpecType.duration must render as duration")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "SCSpecType.duration must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"duration\""), value,
                       "duration must read back as SCSpecType.duration")
    }

    func test_SCSpecType_SC_SPEC_TYPE_ERROR() throws {
        let value: SCSpecType = .error
        XCTAssertEqual(try value.toXdrJson(), "\"error\"",
                       "SCSpecType.error must render as error")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SCSpecType.error must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"error\""), value,
                       "error must read back as SCSpecType.error")
    }

    func test_SCSpecType_SC_SPEC_TYPE_I128() throws {
        let value: SCSpecType = .i128
        XCTAssertEqual(try value.toXdrJson(), "\"i128\"",
                       "SCSpecType.i128 must render as i128")
        XCTAssertEqual(value.rawValue, Int32(11),
                       "SCSpecType.i128 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"i128\""), value,
                       "i128 must read back as SCSpecType.i128")
    }

    func test_SCSpecType_SC_SPEC_TYPE_I256() throws {
        let value: SCSpecType = .i256
        XCTAssertEqual(try value.toXdrJson(), "\"i256\"",
                       "SCSpecType.i256 must render as i256")
        XCTAssertEqual(value.rawValue, Int32(13),
                       "SCSpecType.i256 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"i256\""), value,
                       "i256 must read back as SCSpecType.i256")
    }

    func test_SCSpecType_SC_SPEC_TYPE_I32() throws {
        let value: SCSpecType = .i32
        XCTAssertEqual(try value.toXdrJson(), "\"i32\"",
                       "SCSpecType.i32 must render as i32")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "SCSpecType.i32 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"i32\""), value,
                       "i32 must read back as SCSpecType.i32")
    }

    func test_SCSpecType_SC_SPEC_TYPE_I64() throws {
        let value: SCSpecType = .i64
        XCTAssertEqual(try value.toXdrJson(), "\"i64\"",
                       "SCSpecType.i64 must render as i64")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "SCSpecType.i64 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"i64\""), value,
                       "i64 must read back as SCSpecType.i64")
    }

    func test_SCSpecType_SC_SPEC_TYPE_MAP() throws {
        let value: SCSpecType = .map
        XCTAssertEqual(try value.toXdrJson(), "\"map\"",
                       "SCSpecType.map must render as map")
        XCTAssertEqual(value.rawValue, Int32(1004),
                       "SCSpecType.map must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"map\""), value,
                       "map must read back as SCSpecType.map")
    }

    func test_SCSpecType_SC_SPEC_TYPE_MUXED_ADDRESS() throws {
        let value: SCSpecType = .muxedAddress
        XCTAssertEqual(try value.toXdrJson(), "\"muxed_address\"",
                       "SCSpecType.muxedAddress must render as muxed_address")
        XCTAssertEqual(value.rawValue, Int32(20),
                       "SCSpecType.muxedAddress must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"muxed_address\""), value,
                       "muxed_address must read back as SCSpecType.muxedAddress")
    }

    func test_SCSpecType_SC_SPEC_TYPE_OPTION() throws {
        let value: SCSpecType = .option
        XCTAssertEqual(try value.toXdrJson(), "\"option\"",
                       "SCSpecType.option must render as option")
        XCTAssertEqual(value.rawValue, Int32(1000),
                       "SCSpecType.option must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"option\""), value,
                       "option must read back as SCSpecType.option")
    }

    func test_SCSpecType_SC_SPEC_TYPE_RESULT() throws {
        let value: SCSpecType = .result
        XCTAssertEqual(try value.toXdrJson(), "\"result\"",
                       "SCSpecType.result must render as result")
        XCTAssertEqual(value.rawValue, Int32(1001),
                       "SCSpecType.result must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"result\""), value,
                       "result must read back as SCSpecType.result")
    }

    func test_SCSpecType_SC_SPEC_TYPE_STRING() throws {
        let value: SCSpecType = .string
        XCTAssertEqual(try value.toXdrJson(), "\"string\"",
                       "SCSpecType.string must render as string")
        XCTAssertEqual(value.rawValue, Int32(16),
                       "SCSpecType.string must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"string\""), value,
                       "string must read back as SCSpecType.string")
    }

    func test_SCSpecType_SC_SPEC_TYPE_SYMBOL() throws {
        let value: SCSpecType = .symbol
        XCTAssertEqual(try value.toXdrJson(), "\"symbol\"",
                       "SCSpecType.symbol must render as symbol")
        XCTAssertEqual(value.rawValue, Int32(17),
                       "SCSpecType.symbol must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"symbol\""), value,
                       "symbol must read back as SCSpecType.symbol")
    }

    func test_SCSpecType_SC_SPEC_TYPE_TIMEPOINT() throws {
        let value: SCSpecType = .timepoint
        XCTAssertEqual(try value.toXdrJson(), "\"timepoint\"",
                       "SCSpecType.timepoint must render as timepoint")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "SCSpecType.timepoint must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"timepoint\""), value,
                       "timepoint must read back as SCSpecType.timepoint")
    }

    func test_SCSpecType_SC_SPEC_TYPE_TUPLE() throws {
        let value: SCSpecType = .tuple
        XCTAssertEqual(try value.toXdrJson(), "\"tuple\"",
                       "SCSpecType.tuple must render as tuple")
        XCTAssertEqual(value.rawValue, Int32(1005),
                       "SCSpecType.tuple must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"tuple\""), value,
                       "tuple must read back as SCSpecType.tuple")
    }

    func test_SCSpecType_SC_SPEC_TYPE_U128() throws {
        let value: SCSpecType = .u128
        XCTAssertEqual(try value.toXdrJson(), "\"u128\"",
                       "SCSpecType.u128 must render as u128")
        XCTAssertEqual(value.rawValue, Int32(10),
                       "SCSpecType.u128 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"u128\""), value,
                       "u128 must read back as SCSpecType.u128")
    }

    func test_SCSpecType_SC_SPEC_TYPE_U256() throws {
        let value: SCSpecType = .u256
        XCTAssertEqual(try value.toXdrJson(), "\"u256\"",
                       "SCSpecType.u256 must render as u256")
        XCTAssertEqual(value.rawValue, Int32(12),
                       "SCSpecType.u256 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"u256\""), value,
                       "u256 must read back as SCSpecType.u256")
    }

    func test_SCSpecType_SC_SPEC_TYPE_U32() throws {
        let value: SCSpecType = .u32
        XCTAssertEqual(try value.toXdrJson(), "\"u32\"",
                       "SCSpecType.u32 must render as u32")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "SCSpecType.u32 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"u32\""), value,
                       "u32 must read back as SCSpecType.u32")
    }

    func test_SCSpecType_SC_SPEC_TYPE_U64() throws {
        let value: SCSpecType = .u64
        XCTAssertEqual(try value.toXdrJson(), "\"u64\"",
                       "SCSpecType.u64 must render as u64")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "SCSpecType.u64 must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"u64\""), value,
                       "u64 must read back as SCSpecType.u64")
    }

    func test_SCSpecType_SC_SPEC_TYPE_UDT() throws {
        let value: SCSpecType = .udt
        XCTAssertEqual(try value.toXdrJson(), "\"udt\"",
                       "SCSpecType.udt must render as udt")
        XCTAssertEqual(value.rawValue, Int32(2000),
                       "SCSpecType.udt must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"udt\""), value,
                       "udt must read back as SCSpecType.udt")
    }

    func test_SCSpecType_SC_SPEC_TYPE_VAL() throws {
        let value: SCSpecType = .val
        XCTAssertEqual(try value.toXdrJson(), "\"val\"",
                       "SCSpecType.val must render as val")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCSpecType.val must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"val\""), value,
                       "val must read back as SCSpecType.val")
    }

    func test_SCSpecType_SC_SPEC_TYPE_VEC() throws {
        let value: SCSpecType = .vec
        XCTAssertEqual(try value.toXdrJson(), "\"vec\"",
                       "SCSpecType.vec must render as vec")
        XCTAssertEqual(value.rawValue, Int32(1002),
                       "SCSpecType.vec must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"vec\""), value,
                       "vec must read back as SCSpecType.vec")
    }

    func test_SCSpecType_SC_SPEC_TYPE_VOID() throws {
        let value: SCSpecType = .void
        XCTAssertEqual(try value.toXdrJson(), "\"void\"",
                       "SCSpecType.void must render as void")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SCSpecType.void must keep its XDR value")
        XCTAssertEqual(try SCSpecType.fromXdrJson("\"void\""), value,
                       "void must read back as SCSpecType.void")
    }

    func test_SCSpecType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCSpecType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCSpecType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCSpecUDTEnumCaseV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTEnumCaseV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTEnumCaseV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTEnumCaseV0XDR_roundTrip() throws {
        let original: SCSpecUDTEnumCaseV0XDR = SCSpecUDTEnumCaseV0XDR(doc: "test_string", name: "test_string", value: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTEnumCaseV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTEnumCaseV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTEnumCaseV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTEnumCaseV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTEnumCaseV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTEnumCaseV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTEnumCaseV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTEnumCaseV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTEnumV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTEnumV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTEnumV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTEnumV0XDR_roundTrip() throws {
        let original: SCSpecUDTEnumV0XDR = SCSpecUDTEnumV0XDR(doc: "test_string", lib: "test_string", name: "test_string", cases: [SCSpecUDTEnumCaseV0XDR(doc: "test_string", name: "test_string", value: UInt32(42))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTEnumV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTEnumV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTEnumV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTEnumV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTEnumV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTEnumV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTEnumV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTEnumV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTErrorEnumCaseV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTErrorEnumCaseV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTErrorEnumCaseV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTErrorEnumCaseV0XDR_roundTrip() throws {
        let original: SCSpecUDTErrorEnumCaseV0XDR = SCSpecUDTErrorEnumCaseV0XDR(doc: "test_string", name: "test_string", value: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTErrorEnumCaseV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTErrorEnumCaseV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTErrorEnumCaseV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTErrorEnumCaseV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTErrorEnumCaseV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTErrorEnumCaseV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTErrorEnumCaseV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTErrorEnumCaseV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTErrorEnumV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTErrorEnumV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTErrorEnumV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTErrorEnumV0XDR_roundTrip() throws {
        let original: SCSpecUDTErrorEnumV0XDR = SCSpecUDTErrorEnumV0XDR(doc: "test_string", lib: "test_string", name: "test_string", cases: [SCSpecUDTErrorEnumCaseV0XDR(doc: "test_string", name: "test_string", value: UInt32(42))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTErrorEnumV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTErrorEnumV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTErrorEnumV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTErrorEnumV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTErrorEnumV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTErrorEnumV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTErrorEnumV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTErrorEnumV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTStructFieldV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTStructFieldV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTStructFieldV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTStructFieldV0XDR_roundTrip() throws {
        let original: SCSpecUDTStructFieldV0XDR = SCSpecUDTStructFieldV0XDR(doc: "test_string", name: "test_string", type: .val)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTStructFieldV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTStructFieldV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTStructFieldV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTStructFieldV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTStructFieldV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTStructFieldV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTStructFieldV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTStructFieldV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTStructV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTStructV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTStructV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTStructV0XDR_roundTrip() throws {
        let original: SCSpecUDTStructV0XDR = SCSpecUDTStructV0XDR(doc: "test_string", lib: "test_string", name: "test_string", fields: [SCSpecUDTStructFieldV0XDR(doc: "test_string", name: "test_string", type: .val)])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTStructV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTStructV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTStructV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTStructV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTStructV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTStructV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTStructV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTStructV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTUnionCaseTupleV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTUnionCaseTupleV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTUnionCaseTupleV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTUnionCaseTupleV0XDR_roundTrip() throws {
        let original: SCSpecUDTUnionCaseTupleV0XDR = SCSpecUDTUnionCaseTupleV0XDR(doc: "test_string", name: "test_string", type: [.val])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTUnionCaseTupleV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTUnionCaseTupleV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTUnionCaseTupleV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTUnionCaseTupleV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTUnionCaseTupleV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTUnionCaseTupleV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTUnionCaseTupleV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTUnionCaseTupleV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTUnionCaseV0Kind_SC_SPEC_UDT_UNION_CASE_TUPLE_V0() throws {
        let value: SCSpecUDTUnionCaseV0Kind = .tupleV0
        XCTAssertEqual(try value.toXdrJson(), "\"tuple_v0\"",
                       "SCSpecUDTUnionCaseV0Kind.tupleV0 must render as tuple_v0")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SCSpecUDTUnionCaseV0Kind.tupleV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecUDTUnionCaseV0Kind.fromXdrJson("\"tuple_v0\""), value,
                       "tuple_v0 must read back as SCSpecUDTUnionCaseV0Kind.tupleV0")
    }

    func test_SCSpecUDTUnionCaseV0Kind_SC_SPEC_UDT_UNION_CASE_VOID_V0() throws {
        let value: SCSpecUDTUnionCaseV0Kind = .voidV0
        XCTAssertEqual(try value.toXdrJson(), "\"void_v0\"",
                       "SCSpecUDTUnionCaseV0Kind.voidV0 must render as void_v0")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCSpecUDTUnionCaseV0Kind.voidV0 must keep its XDR value")
        XCTAssertEqual(try SCSpecUDTUnionCaseV0Kind.fromXdrJson("\"void_v0\""), value,
                       "void_v0 must read back as SCSpecUDTUnionCaseV0Kind.voidV0")
    }

    func test_SCSpecUDTUnionCaseV0Kind_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCSpecUDTUnionCaseV0Kind.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCSpecUDTUnionCaseV0Kind: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecUDTUnionCaseV0Kind")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCSpecUDTUnionCaseV0XDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCSpecUDTUnionCaseV0XDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCSpecUDTUnionCaseV0XDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecUDTUnionCaseV0XDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCSpecUDTUnionCaseV0XDR_tupleV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecUDTUnionCaseV0XDR.fromXdrJson("\"tuple_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecUDTUnionCaseV0XDR.tuple_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecUDTUnionCaseV0XDR")
            XCTAssertEqual(key, "tuple_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecUDTUnionCaseV0XDR_tupleV0_roundTrip() throws {
        let original: SCSpecUDTUnionCaseV0XDR = .tupleV0(SCSpecUDTUnionCaseTupleV0XDR(doc: "test_string", name: "test_string", type: [.val]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTUnionCaseV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTUnionCaseV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTUnionCaseV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTUnionCaseV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTUnionCaseV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTUnionCaseV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTUnionCaseV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTUnionCaseV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTUnionCaseV0XDR_voidV0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCSpecUDTUnionCaseV0XDR.fromXdrJson("\"void_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCSpecUDTUnionCaseV0XDR.void_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCSpecUDTUnionCaseV0XDR")
            XCTAssertEqual(key, "void_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCSpecUDTUnionCaseV0XDR_voidV0_roundTrip() throws {
        let original: SCSpecUDTUnionCaseV0XDR = .voidV0(SCSpecUDTUnionCaseVoidV0XDR(doc: "test_string", name: "test_string"))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTUnionCaseV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTUnionCaseV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTUnionCaseV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTUnionCaseV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTUnionCaseV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTUnionCaseV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTUnionCaseV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTUnionCaseV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTUnionCaseVoidV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTUnionCaseVoidV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTUnionCaseVoidV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTUnionCaseVoidV0XDR_roundTrip() throws {
        let original: SCSpecUDTUnionCaseVoidV0XDR = SCSpecUDTUnionCaseVoidV0XDR(doc: "test_string", name: "test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTUnionCaseVoidV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTUnionCaseVoidV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTUnionCaseVoidV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTUnionCaseVoidV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTUnionCaseVoidV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTUnionCaseVoidV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTUnionCaseVoidV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTUnionCaseVoidV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_SCSpecUDTUnionV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCSpecUDTUnionV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCSpecUDTUnionV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCSpecUDTUnionV0XDR_roundTrip() throws {
        let original: SCSpecUDTUnionV0XDR = SCSpecUDTUnionV0XDR(doc: "test_string", lib: "test_string", name: "test_string", cases: [.voidV0(SCSpecUDTUnionCaseVoidV0XDR(doc: "test_string", name: "test_string"))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCSpecUDTUnionV0XDR.fromXdrJson(json)
        let viaValue = try SCSpecUDTUnionV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCSpecUDTUnionV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCSpecUDTUnionV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCSpecUDTUnionV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCSpecUDTUnionV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCSpecUDTUnionV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCSpecUDTUnionV0XDR must reach the same bytes through JSON and XDR")
    }
}
