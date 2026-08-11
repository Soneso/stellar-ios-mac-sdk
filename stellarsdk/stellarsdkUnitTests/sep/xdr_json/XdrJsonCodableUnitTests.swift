//
//  XdrJsonCodableUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

/// A minimal conforming type standing in for a generated XDR struct: two 64-bit fields,
/// emitted in declaration order, read back through the shared runtime.
private struct ProbeXDR: XdrJsonCodable, Equatable {
    let minTime: UInt64
    let maxTime: UInt64

    func toXdrJsonValue() throws -> XdrJsonValue {
        var members: [XdrJsonMember] = []
        members.append(XdrJsonMember(key: "min_time", value: XdrJson.uint64(minTime)))
        members.append(XdrJsonMember(key: "max_time", value: XdrJson.uint64(maxTime)))
        return .object(members)
    }

    static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> ProbeXDR {
        let members = try XdrJson.object(value, type: "ProbeXDR", keys: ["min_time", "max_time"])
        let minTime = try XdrJson.uint64(
            try XdrJson.field(members, key: "min_time", type: "ProbeXDR"),
            type: "ProbeXDR", key: "min_time")
        let maxTime = try XdrJson.uint64(
            try XdrJson.field(members, key: "max_time", type: "ProbeXDR"),
            type: "ProbeXDR", key: "max_time")
        return ProbeXDR(minTime: minTime, maxTime: maxTime)
    }
}

/// A self-referential conforming type, standing in for the XDR types that nest without a
/// fixed bound. Its `fromXdrJsonValue` recurses exactly the way generated code does, which
/// is what makes the guarded and unguarded tree entry points behave differently.
private indirect enum NestedProbeXDR: XdrJsonCodable, Equatable {
    case leaf(Int32)
    case wrap(NestedProbeXDR)

    func toXdrJsonValue() throws -> XdrJsonValue {
        switch self {
        case .leaf(let value):
            return XdrJson.int32(value)
        case .wrap(let inner):
            return .object([XdrJsonMember(key: "inner", value: try inner.toXdrJsonValue())])
        }
    }

    static func fromXdrJsonValue(_ value: XdrJsonValue) throws -> NestedProbeXDR {
        if case .number = value {
            return .leaf(try XdrJson.int32(value, type: "NestedProbeXDR"))
        }
        let members = try XdrJson.object(value, type: "NestedProbeXDR", keys: ["inner"])
        let inner = try XdrJson.field(members, key: "inner", type: "NestedProbeXDR")
        return .wrap(try fromXdrJsonValue(inner))
    }

    /// `depth` wrappers around a leaf, so the tree holds exactly `depth` containers.
    static func nested(depth: Int) -> NestedProbeXDR {
        var value = NestedProbeXDR.leaf(1)
        for _ in 0..<depth { value = .wrap(value) }
        return value
    }

    static func nestedText(depth: Int) -> String {
        String(repeating: "{\"inner\":", count: depth) + "1" + String(repeating: "}", count: depth)
    }
}

final class XdrJsonCodableUnitTests: XCTestCase {

    // MARK: - toXdrJson

    func testToXdrJsonRendersTheTreeTheRequirementProduces() throws {
        let probe = ProbeXDR(minTime: 0, maxTime: 1)
        XCTAssertEqual(try probe.toXdrJson(), "{\"min_time\":\"0\",\"max_time\":\"1\"}")
    }

    func testToXdrJsonKeepsDeclarationOrderRatherThanSortingKeys() throws {
        let probe = ProbeXDR(minTime: 9, maxTime: 2)
        XCTAssertEqual(try probe.toXdrJson(), "{\"min_time\":\"9\",\"max_time\":\"2\"}")
    }

    func testToXdrJsonPropagatesTheWritersDepthLimit() {
        let value = NestedProbeXDR.nested(depth: XdrJson.maxDepth + 1)
        XCTAssertThrowsError(try value.toXdrJson()) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, XdrJson.maxDepth)
        }
    }

    func testToXdrJsonWritesATreeAtTheDepthLimit() {
        XCTAssertNoThrow(try NestedProbeXDR.nested(depth: XdrJson.maxDepth).toXdrJson())
    }

    // MARK: - fromXdrJson

    func testFromXdrJsonParsesTextAndDelegatesToTheRequirement() throws {
        let probe = try ProbeXDR.fromXdrJson("{\"min_time\":\"0\",\"max_time\":\"1\"}")
        XCTAssertEqual(probe, ProbeXDR(minTime: 0, maxTime: 1))
    }

    func testFromXdrJsonAndToXdrJsonRoundTrip() throws {
        let original = ProbeXDR(minTime: 1_700_000_000, maxTime: UInt64.max)
        let text = try original.toXdrJson()
        XCTAssertEqual(try ProbeXDR.fromXdrJson(text), original)
        XCTAssertEqual(try ProbeXDR.fromXdrJson(text).toXdrJson(), text)
    }

    func testFromXdrJsonAcceptsAndStripsTheSchemaProperty() throws {
        let text = "{\"$schema\":\"https://example.com/s.json\",\"min_time\":\"0\",\"max_time\":\"1\"}"
        let probe = try ProbeXDR.fromXdrJson(text)
        XCTAssertEqual(probe, ProbeXDR(minTime: 0, maxTime: 1))
        XCTAssertEqual(try probe.toXdrJson(), "{\"min_time\":\"0\",\"max_time\":\"1\"}")
    }

    func testFromXdrJsonRejectsAnUndeclaredKey() {
        let text = "{\"min_time\":\"0\",\"max_time\":\"1\",\"foo\":1}"
        XCTAssertThrowsError(try ProbeXDR.fromXdrJson(text)) { error in
            guard case XdrJsonError.unknownField(let type, let keys, let declared) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "ProbeXDR")
            XCTAssertEqual(keys, ["foo"])
            XCTAssertEqual(declared, ["min_time", "max_time"])
        }
    }

    /// The check belongs to every struct entry point, not only the document root, matching
    /// the reference implementation, which reports a nested offender by path.
    func testAnUndeclaredKeyIsRejectedInsideANestedObjectToo() {
        XCTAssertThrowsError(try NestedProbeXDR.fromXdrJson("{\"inner\":{\"inner\":1,\"bogus\":2}}")) { error in
            guard case XdrJsonError.unknownField(let type, let keys, let declared) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "NestedProbeXDR")
            XCTAssertEqual(keys, ["bogus"])
            XCTAssertEqual(declared, ["inner"])
        }
    }

    func testFromXdrJsonSurfacesAParseFailure() {
        XCTAssertThrowsError(try ProbeXDR.fromXdrJson("{\"min_time\":")) { error in
            guard case XdrJsonError.malformedJson = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    func testFromXdrJsonSurfacesAConversionFailure() {
        XCTAssertThrowsError(try ProbeXDR.fromXdrJson("{\"min_time\":\"0\"}")) { error in
            guard case XdrJsonError.missingField(let type, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(type, "ProbeXDR")
            XCTAssertEqual(key, "max_time")
        }
    }

    func testFromXdrJsonIsBoundedByTheParsersDepthLimit() {
        let text = NestedProbeXDR.nestedText(depth: XdrJson.maxDepth + 1)
        XCTAssertThrowsError(try NestedProbeXDR.fromXdrJson(text)) { error in
            guard case XdrJsonError.recursionLimitExceeded = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    func testFromXdrJsonReadsTextAtTheDepthLimit() throws {
        let text = NestedProbeXDR.nestedText(depth: XdrJson.maxDepth)
        XCTAssertEqual(try NestedProbeXDR.fromXdrJson(text),
                       NestedProbeXDR.nested(depth: XdrJson.maxDepth))
    }

    // MARK: - fromXdrJsonTree

    func testFromXdrJsonTreeReadsATreeAtTheDepthLimit() throws {
        let expected = NestedProbeXDR.nested(depth: XdrJson.maxDepth)
        let tree = try expected.toXdrJsonValue()
        XCTAssertEqual(try NestedProbeXDR.fromXdrJsonTree(tree), expected)
    }

    func testFromXdrJsonTreeRejectsATreeBeyondTheDepthLimit() throws {
        let tree = try Self.overDeepTree()
        XCTAssertThrowsError(try NestedProbeXDR.fromXdrJsonTree(tree)) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, XdrJson.maxDepth)
        }
    }

    /// The whole reason the guarded entry point exists: the same hand-built tree that
    /// `fromXdrJsonTree` refuses is read without complaint by the unguarded requirement,
    /// because that one deliberately does not re-walk the tree.
    func testUnguardedEntryPointDoesNotApplyTheDepthLimit() throws {
        let tree = try Self.overDeepTree()
        let value = try NestedProbeXDR.fromXdrJsonValue(tree)
        XCTAssertEqual(value, NestedProbeXDR.nested(depth: XdrJson.maxDepth + 1))
        XCTAssertThrowsError(try NestedProbeXDR.fromXdrJsonTree(tree))
    }

    func testFromXdrJsonTreeSurfacesAConversionFailure() {
        let tree = XdrJsonValue.object([XdrJsonMember(key: "min_time", value: .string("0"))])
        XCTAssertThrowsError(try ProbeXDR.fromXdrJsonTree(tree)) { error in
            guard case XdrJsonError.missingField(_, let key) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(key, "max_time")
        }
    }

    func testFromXdrJsonTreeAcceptsAnOrdinaryTree() throws {
        let tree = try ProbeXDR(minTime: 3, maxTime: 4).toXdrJsonValue()
        XCTAssertEqual(try ProbeXDR.fromXdrJsonTree(tree), ProbeXDR(minTime: 3, maxTime: 4))
    }

    /// Built without the writer, which would reject it, so the tree reaches both entry
    /// points intact.
    private static func overDeepTree() throws -> XdrJsonValue {
        var tree = XdrJsonValue.number("1")
        for _ in 0..<(XdrJson.maxDepth + 1) {
            tree = .object([XdrJsonMember(key: "inner", value: tree)])
        }
        return tree
    }
}
