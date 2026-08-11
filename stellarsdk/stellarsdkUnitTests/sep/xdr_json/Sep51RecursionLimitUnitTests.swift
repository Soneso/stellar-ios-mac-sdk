//
//  Sep51RecursionLimitUnitTests.swift
//  stellarsdk
//
//  Created by Christian Rogobete on 06.08.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// The nesting cap, pinned on both sides of its boundary through a real XDR type.
///
/// A conversion walks a document a caller supplies, so an attacker-supplied document could
/// otherwise drive it as deep as it likes. The cap is 128 containers, matching what the binary
/// decoder allows, and only arrays and objects count towards it: 128 nested containers are
/// converted and 129 are refused.
///
/// `SCVal` is the type that can nest without bound, because its vector arm holds `SCVal`
/// again. Each level of `{"vec":[…]}` is two containers, one object and one array, so a
/// document of 64 levels around an empty vector is exactly 128 and the same 64 levels around
/// one more object is exactly 129. That pairing is what lets the boundary be pinned to the
/// single container rather than to the level.
///
/// The cap is enforced in three places and all three are asserted: the text parser, the tree
/// validator that guards ``XdrJsonCodable/fromXdrJsonTree(_:)``, and the writer. A limit
/// enforced in two of the three would leave one entry point unbounded.
final class Sep51RecursionLimitUnitTests: XCTestCase {

    /// The documented cap. Written out rather than read from the runtime, so a change to the
    /// constant is reported here instead of being followed silently.
    private static let containerLimit = 128

    // MARK: - Text

    func testTextNestingAtTheLimitIsAccepted() throws {
        let document = Self.nestedText(levels: 64, innermost: nil)
        XCTAssertEqual(Self.containerCount(document), Self.containerLimit)

        let value = try SCValXDR.fromXdrJson(document)
        XCTAssertEqual(try value.toXdrJson(), document)
    }

    func testTextNestingOneContainerBeyondTheLimitIsRejected() {
        let document = Self.nestedText(levels: 64, innermost: "{\"u32\":1}")
        XCTAssertEqual(Self.containerCount(document), Self.containerLimit + 1)

        XCTAssertThrowsError(try SCValXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, Self.containerLimit)
        }
    }

    func testTextNestingOneContainerBelowTheLimitIsAccepted() throws {
        let document = Self.nestedText(levels: 63, innermost: "{\"u32\":1}")
        XCTAssertEqual(Self.containerCount(document), Self.containerLimit - 1)

        XCTAssertNoThrow(try SCValXDR.fromXdrJson(document))
    }

    func testTextNestingTwoContainersBeyondTheLimitIsRejected() {
        let document = Self.nestedText(levels: 65, innermost: nil)
        XCTAssertEqual(Self.containerCount(document), Self.containerLimit + 2)

        XCTAssertThrowsError(try SCValXDR.fromXdrJson(document)) { error in
            guard case XdrJsonError.recursionLimitExceeded = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    // MARK: - Trees built by hand

    func testTreeNestingAtTheLimitIsAccepted() throws {
        let tree = Self.nestedTree(levels: 64, innermost: nil)
        XCTAssertNoThrow(try SCValXDR.fromXdrJsonTree(tree))
    }

    func testTreeNestingOneContainerBeyondTheLimitIsRejected() {
        let innermost = XdrJsonValue.object([XdrJsonMember(key: "u32", value: .number("1"))])
        let tree = Self.nestedTree(levels: 64, innermost: innermost)

        XCTAssertThrowsError(try SCValXDR.fromXdrJsonTree(tree)) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, Self.containerLimit)
        }
    }

    func testTreeNestingOneContainerBelowTheLimitIsAccepted() {
        let innermost = XdrJsonValue.object([XdrJsonMember(key: "u32", value: .number("1"))])
        XCTAssertNoThrow(try SCValXDR.fromXdrJsonTree(Self.nestedTree(levels: 63,
                                                                     innermost: innermost)))
    }

    func testTreeNestingTwoContainersBeyondTheLimitIsRejected() {
        XCTAssertThrowsError(try SCValXDR.fromXdrJsonTree(Self.nestedTree(levels: 65,
                                                                         innermost: nil))) { error in
            guard case XdrJsonError.recursionLimitExceeded = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    // MARK: - Emission

    func testValueNestingAtTheLimitIsWritten() throws {
        let value = Self.nestedValue(levels: 64, innermost: nil)
        let text = try value.toXdrJson()

        XCTAssertEqual(Self.containerCount(text), Self.containerLimit)
    }

    func testValueNestingOneContainerBeyondTheLimitIsRefused() {
        let value = Self.nestedValue(levels: 64, innermost: .u32(1))

        XCTAssertThrowsError(try value.toXdrJson()) { error in
            guard case XdrJsonError.recursionLimitExceeded(let limit) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(limit, Self.containerLimit)
        }
    }

    // MARK: - Construction

    private static func nestedText(levels: Int, innermost: String?) -> String {
        String(repeating: "{\"vec\":[", count: levels)
            + (innermost ?? "")
            + String(repeating: "]}", count: levels)
    }

    private static func nestedTree(levels: Int, innermost: XdrJsonValue?) -> XdrJsonValue {
        var value = XdrJsonValue.object([
            XdrJsonMember(key: "vec", value: .array(innermost.map { [$0] } ?? []))
        ])
        for _ in 1..<levels {
            value = .object([XdrJsonMember(key: "vec", value: .array([value]))])
        }
        return value
    }

    private static func nestedValue(levels: Int, innermost: SCValXDR?) -> SCValXDR {
        var value = SCValXDR.vec(innermost.map { [$0] } ?? [])
        for _ in 1..<levels {
            value = .vec([value])
        }
        return value
    }

    private static func containerCount(_ text: String) -> Int {
        text.filter { $0 == "{" || $0 == "[" }.count
    }
}
