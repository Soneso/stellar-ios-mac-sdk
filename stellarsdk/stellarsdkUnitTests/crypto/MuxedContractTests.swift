//
//  MuxedContractTests.swift
//  stellarsdkUnitTests
//
//  Created by Christian Rogobete on 08.10.26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

final class MuxedContractTests: XCTestCase {

    let contractId = "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA"
    let muxedIdZero = "WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC"
    let muxedIdHighBit = "WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAACWJY"
    let otherContractId = "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"
    let otherMuxed = "WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG"

    func testFromMuxedContractAddress() throws {
        let vectors: [(String, String, UInt64)] = [
            (muxedIdZero, contractId, 0),
            (muxedIdHighBit, contractId, 9223372036854775808),
            (otherMuxed, otherContractId, 123456),
        ]
        for (address, contract, id) in vectors {
            let muxed = try MuxedContract(address: address)
            XCTAssertEqual(muxed.contractId, contract)
            XCTAssertEqual(muxed.id, id)
            XCTAssertEqual(muxed.address, address)
        }
    }

    func testFromContractIdAndId() throws {
        XCTAssertEqual(try MuxedContract(contractId: contractId, id: 0).address, muxedIdZero)
        XCTAssertEqual(try MuxedContract(contractId: contractId, id: 9223372036854775808).address, muxedIdHighBit)
        XCTAssertEqual(try MuxedContract(contractId: otherContractId, id: 123456).address, otherMuxed)

        let max = try MuxedContract(contractId: contractId, id: UInt64.max)
        let reparsed = try MuxedContract(address: max.address)
        XCTAssertEqual(reparsed.id, UInt64.max)
        XCTAssertEqual(reparsed, max)
        XCTAssertNotEqual(reparsed, try MuxedContract(contractId: contractId, id: UInt64.max - 1))
    }

    func testFromContractAddressLeavesIdNil() throws {
        let plain = try MuxedContract(address: contractId)
        XCTAssertNil(plain.id)
        XCTAssertEqual(plain.contractId, contractId)
        XCTAssertEqual(plain.address, contractId)
        guard case .contract(let hash) = plain.toSCAddress() else {
            return XCTFail("Expected the contract arm, got \(plain.toSCAddress())")
        }
        XCTAssertEqual(hash.wrapped, try contractId.decodeContractId())
    }

    func testSCAddressConversions() throws {
        let muxed = try MuxedContract(address: otherMuxed)
        let scAddress = muxed.toSCAddress()
        guard case .muxedContract(let xdr) = scAddress else {
            return XCTFail("Expected the muxed contract arm, got \(scAddress)")
        }
        XCTAssertEqual(xdr.id, 123456)
        XCTAssertEqual(xdr.contractId.wrapped, try otherContractId.decodeContractId())
        XCTAssertEqual(try scAddress.toStrKey(), otherMuxed)
        XCTAssertEqual(try MuxedContract(scAddress: scAddress), muxed)
        XCTAssertEqual(try MuxedContract(scAddress: SCAddressXDR(contractId: contractId)).address, contractId)

        let account = try SCAddressXDR(accountId: "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ")
        assertInvalidArgument(try MuxedContract(scAddress: account),
                              "expected a contract or muxed contract address, got SC_ADDRESS_TYPE_ACCOUNT")
    }

    func testRejectedInputsNameTheValue() {
        let muxedAccount = "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK"
        for address in [muxedAccount, "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ",
                        "WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWA"] {
            assertInvalidArgument(try MuxedContract(address: address),
                                  "not a contract (C...) or muxed contract (W...) address: \(address)")
        }
        assertInvalidArgument(try MuxedContract(contractId: muxedIdZero, id: 1),
                              "not a contract id (C...): \(muxedIdZero)")
    }

    private func assertInvalidArgument<T>(_ expression: @autoclosure () throws -> T, _ expected: String,
                                          file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard case StellarSDKError.invalidArgument(let message) = error else {
                return XCTFail("Expected invalidArgument, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(message, expected, file: file, line: line)
        }
    }
}
