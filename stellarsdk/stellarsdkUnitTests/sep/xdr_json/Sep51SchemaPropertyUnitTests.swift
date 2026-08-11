//
//  Sep51SchemaPropertyUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// The `$schema` property of SEP-0051 §JSON Schema.
///
/// The specification says every JSON object should allow, but not require, a `$schema`
/// property naming the schema document for the type. Three rules follow and all three are
/// pinned here: it is accepted wherever an object appears, it is removed before the object is
/// read as an XDR value, and it is never written.
///
/// The fourth rule is the boundary case. `$schema` is not a member of the type, so an object
/// carrying nothing else carries no value at all and is rejected rather than read as an empty
/// struct or an armless union.
///
/// This is the one property this SDK accepts on input that the reference implementation
/// refuses, so the assertions below follow the specification text rather than any observed
/// reference behaviour.
final class Sep51SchemaPropertyUnitTests: XCTestCase {

    private static let schemaUrl = "https://stellar.org/schema/xdr-json/main/TimeBounds.json"

    // MARK: - Structs

    func testStructAcceptsAndStripsTheSchemaProperty() throws {
        let document = "{\"$schema\":\"\(Self.schemaUrl)\",\"min_time\":\"0\",\"max_time\":\"1\"}"
        let bounds = try TimeBoundsXDR.fromXdrJson(document)

        XCTAssertEqual(bounds.minTime, 0)
        XCTAssertEqual(bounds.maxTime, 1)
    }

    func testSchemaPropertyIsAcceptedWhereverItAppearsInTheDocument() throws {
        let document = """
        {"$schema":"https://stellar.org/schema/xdr-json/main/AccountEntryExtensionV2.json",\
        "num_sponsored":1,"num_sponsoring":2,"signer_sponsoring_i_ds":[],\
        "ext":{"$schema":"https://stellar.org/schema/xdr-json/main/ExtensionPoint.json","v3":\
        {"$schema":"https://stellar.org/schema/xdr-json/main/AccountEntryExtensionV3.json",\
        "ext":"v0","seq_ledger":3,"seq_time":"4"}}}
        """
        let extensionV2 = try AccountEntryExtensionV2.fromXdrJson(document)

        XCTAssertEqual(extensionV2.numSponsored, 1)
        XCTAssertEqual(extensionV2.numSponsoring, 2)
        XCTAssertFalse(try extensionV2.toXdrJson().contains("$schema"))
    }

    func testStructNeverEmitsTheSchemaProperty() throws {
        let document = "{\"$schema\":\"\(Self.schemaUrl)\",\"min_time\":\"0\",\"max_time\":\"1\"}"
        let bounds = try TimeBoundsXDR.fromXdrJson(document)

        XCTAssertEqual(try bounds.toXdrJson(), "{\"min_time\":\"0\",\"max_time\":\"1\"}")
    }

    func testSchemaPropertyDoesNotSatisfyARequiredKey() {
        let document = "{\"$schema\":\"\(Self.schemaUrl)\",\"min_time\":\"0\"}"

        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.missingField(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertEqual(key, "max_time")
        }
    }

    func testSchemaPropertyIsNotReportedAmongUndeclaredKeys() {
        let document = "{\"$schema\":\"\(Self.schemaUrl)\",\"min_time\":\"0\",\"max_time\":\"1\",\"bogus\":2}"

        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.unknownField(let type, let keys, _) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertEqual(keys, ["bogus"])
        }
    }

    // MARK: - Unions

    /// The document SEP-0051 §JSON Schema prints, for a union rather than a struct.
    func testUnionAcceptsAndStripsTheSchemaProperty() throws {
        let document = "{\"$schema\":\"https://stellar.org/schema/xdr-json/main/Asset.json\","
            + "\"credit_alphanum4\":{\"asset_code\":\"ABCD\","
            + "\"issuer\":\"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF\"}}"

        let asset = try AssetXDR.fromXdrJson(document)
        guard case .alphanum4(let alphanum) = asset else {
            return XCTFail("the document did not read back as a four-character asset")
        }
        XCTAssertEqual(alphanum.assetCode.wrapped, Data("ABCD".utf8))
    }

    func testUnionNeverEmitsTheSchemaProperty() throws {
        let document = "{\"$schema\":\"https://stellar.org/schema/xdr-json/main/ScVal.json\","
            + "\"u32\":7}"
        let value = try SCValXDR.fromXdrJson(document)

        XCTAssertEqual(try value.toXdrJson(), "{\"u32\":7}")
    }

    func testSchemaPropertyDoesNotCountTowardsAUnionsSingleArm() throws {
        let document = "{\"$schema\":\"https://stellar.org/schema/xdr-json/main/ScVal.json\","
            + "\"bool\":true}"
        let value = try SCValXDR.fromXdrJson(document)

        guard case .bool(let flag) = value else {
            return XCTFail("the document did not read back as a boolean")
        }
        XCTAssertTrue(flag)
    }

    // MARK: - An object carrying nothing else

    func testStructOfNothingButTheSchemaPropertyIsRejected() {
        let document = "{\"$schema\":\"\(Self.schemaUrl)\"}"

        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertTrue(message.contains("$schema"), message)
        }
    }

    func testUnionOfNothingButTheSchemaPropertyIsRejected() {
        let document = "{\"$schema\":\"https://stellar.org/schema/xdr-json/main/ScVal.json\"}"

        XCTAssertThrowsError(try SCValXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "SCValXDR")
            XCTAssertTrue(message.contains("$schema"), message)
        }
    }

    func testEmptyObjectIsRejectedWithADifferentReasonThanASchemaOnlyObject() {
        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson("{}")) { error in
            guard case XdrJsonError.invalidValue(let type, _, let message) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "TimeBoundsXDR")
            XCTAssertFalse(message.contains("$schema"), message)
        }
    }
}
