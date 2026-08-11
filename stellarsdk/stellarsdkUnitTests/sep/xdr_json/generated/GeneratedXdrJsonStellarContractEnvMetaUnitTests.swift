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

final class GeneratedXdrJsonStellarContractEnvMetaUnitTests: XCTestCase {

    func test_SCEnvMetaEntryXDRInterfaceVersionXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SCEnvMetaEntryXDRInterfaceVersionXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SCEnvMetaEntryXDRInterfaceVersionXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SCEnvMetaEntryXDRInterfaceVersionXDR_roundTrip() throws {
        let original: SCEnvMetaEntryXDRInterfaceVersionXDR = SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: UInt32(42), preRelease: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCEnvMetaEntryXDRInterfaceVersionXDR.fromXdrJson(json)
        let viaValue = try SCEnvMetaEntryXDRInterfaceVersionXDR.fromXdrJsonValue(tree)
        let viaTree = try SCEnvMetaEntryXDRInterfaceVersionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCEnvMetaEntryXDRInterfaceVersionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCEnvMetaEntryXDRInterfaceVersionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCEnvMetaEntryXDRInterfaceVersionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCEnvMetaEntryXDRInterfaceVersionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCEnvMetaEntryXDRInterfaceVersionXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCEnvMetaEntryXDR_interfaceVersion_rejectsBareString() throws {
        XCTAssertThrowsError(try SCEnvMetaEntryXDR.fromXdrJson("\"sc_env_meta_kind_interface_version\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SCEnvMetaEntryXDR.sc_env_meta_kind_interface_version: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SCEnvMetaEntryXDR")
            XCTAssertEqual(key, "sc_env_meta_kind_interface_version",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SCEnvMetaEntryXDR_interfaceVersion_roundTrip() throws {
        let original: SCEnvMetaEntryXDR = .interfaceVersion(SCEnvMetaEntryXDRInterfaceVersionXDR(protocol: UInt32(42), preRelease: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SCEnvMetaEntryXDR.fromXdrJson(json)
        let viaValue = try SCEnvMetaEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SCEnvMetaEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SCEnvMetaEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SCEnvMetaEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SCEnvMetaEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SCEnvMetaEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SCEnvMetaEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SCEnvMetaEntryXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SCEnvMetaEntryXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SCEnvMetaEntryXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SCEnvMetaEntryXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SCEnvMetaKind_SC_ENV_META_KIND_INTERFACE_VERSION() throws {
        let value: SCEnvMetaKind = .interfaceVersion
        XCTAssertEqual(try value.toXdrJson(), "\"sc_env_meta_kind_interface_version\"",
                       "SCEnvMetaKind.interfaceVersion must render as sc_env_meta_kind_interface_version")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SCEnvMetaKind.interfaceVersion must keep its XDR value")
        XCTAssertEqual(try SCEnvMetaKind.fromXdrJson("\"sc_env_meta_kind_interface_version\""), value,
                       "sc_env_meta_kind_interface_version must read back as SCEnvMetaKind.interfaceVersion")
    }

    func test_SCEnvMetaKind_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SCEnvMetaKind.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SCEnvMetaKind: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SCEnvMetaKind")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }
}
