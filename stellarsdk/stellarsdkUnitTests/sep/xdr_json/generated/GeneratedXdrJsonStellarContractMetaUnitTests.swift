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

final class GeneratedXdrJsonStellarContractMetaUnitTests: XCTestCase {

    func test_SCMetaEntryXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCMetaEntryXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCMetaEntryXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCMetaEntryXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCMetaEntryXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try SCMetaEntryXDR.fromXdrJson("\"sc_meta_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCMetaEntryXDR.sc_meta_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCMetaEntryXDR")
            XCTAssertEqual(key, "sc_meta_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCMetaEntryXDR_v0_roundTrip() throws {
        let original: SCMetaEntryXDR = .v0(SCMetaV0XDR(key: "test_string", value: "test_string"))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCMetaEntryXDR.fromXdrJson(json)
        let viaValue = try SCMetaEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCMetaEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCMetaEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCMetaEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCMetaEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCMetaEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCMetaEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCMetaKind_SC_META_V0() throws {
        let value: SCMetaKind = .v0
        XCTAssertEqual(try value.toXdrJson(), "\"sc_meta_v0\"",
                       "SCMetaKind.v0 must render as sc_meta_v0")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCMetaKind.v0 must keep its XDR value")
        XCTAssertEqual(try SCMetaKind.fromXdrJson("\"sc_meta_v0\""), value,
                       "sc_meta_v0 must read back as SCMetaKind.v0")
    }

    func test_SCMetaKind_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCMetaKind.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCMetaKind: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCMetaKind")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SCMetaV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCMetaV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCMetaV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCMetaV0XDR_roundTrip() throws {
        let original: SCMetaV0XDR = SCMetaV0XDR(key: "test_string", value: "test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCMetaV0XDR.fromXdrJson(json)
        let viaValue = try SCMetaV0XDR.fromXdrJsonValue(tree)
        let viaTree = try SCMetaV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCMetaV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCMetaV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCMetaV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCMetaV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCMetaV0XDR must reach the same bytes through JSON and XDR")
    }
}
