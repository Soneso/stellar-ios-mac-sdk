//
//  Data+ConstantTimeTests.swift
//  stellarsdkUnitTests
//
//  Copyright © Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class DataConstantTimeTests: XCTestCase {

    func testEqualArrays_returnsTrue() {
        let a = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let b = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        XCTAssertTrue(a.constantTimeEquals(b))
    }

    func testUnequalArrays_returnsFalse() {
        let a = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let b = Data([0x01, 0x02, 0x03, 0x04, 0x06])
        XCTAssertFalse(a.constantTimeEquals(b))
    }

    func testDifferentLengths_returnsFalse() {
        XCTAssertFalse(Data([0x01]).constantTimeEquals(Data([0x01, 0x02])))
    }

    func testEmptyArrays_returnsTrue() {
        XCTAssertTrue(Data().constantTimeEquals(Data()))
    }

    func testFirstByteMatches_differentLengths_returnsFalse() {
        let a = Data([0xAA, 0xBB, 0xCC])
        let b = Data([0xAA])
        XCTAssertFalse(a.constantTimeEquals(b))
        XCTAssertFalse(b.constantTimeEquals(a))
    }

    func testAllZeroesEqualLength_returnsTrue() {
        let a = Data(repeating: 0x00, count: 32)
        let b = Data(repeating: 0x00, count: 32)
        XCTAssertTrue(a.constantTimeEquals(b))
    }

    func testAllZeroesVsAllOnes_returnsFalse() {
        let a = Data(repeating: 0x00, count: 32)
        let b = Data(repeating: 0xFF, count: 32)
        XCTAssertFalse(a.constantTimeEquals(b))
    }

    func testSymmetry() {
        let a = Data([0x01, 0x02])
        let b = Data([0x01, 0x03])
        XCTAssertEqual(a.constantTimeEquals(b), b.constantTimeEquals(a))
    }

    func testSingleByteMatch() {
        XCTAssertTrue(Data([0xFF]).constantTimeEquals(Data([0xFF])))
    }

    func testSingleByteMismatch() {
        XCTAssertFalse(Data([0xFF]).constantTimeEquals(Data([0xFE])))
    }
}
