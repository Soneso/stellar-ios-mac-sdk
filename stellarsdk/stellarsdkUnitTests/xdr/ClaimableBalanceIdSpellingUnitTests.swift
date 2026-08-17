//
//  ClaimableBalanceIdSpellingUnitTests.swift
//  stellarsdkUnitTests
//
//  Created by Christian Rogobete.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// The spellings a claimable balance id may hold and the hexadecimal Horizon serves.
final class ClaimableBalanceIdSpellingUnitTests: XCTestCase {

    private let hashHex = "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a"
    private let strKey = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"

    /// The hash behind the one byte type discriminant.
    private var bodyHex: String { "00" + hashHex }

    /// The hash behind the four byte XDR union discriminant, the id Horizon serves.
    private var horizonHex: String { "00000000" + hashHex }

    private func assertEncodingError(_ claimableBalanceId: String,
                                     message expected: String,
                                     line: UInt = #line) {
        XCTAssertThrowsError(try ClaimableBalanceIDXDR(claimableBalanceId: claimableBalanceId), line: line) { error in
            guard case StellarSDKError.encodingError(let message) = error else {
                XCTFail("expected an encoding error, got \(error)", line: line)
                return
            }
            XCTAssertEqual(message, expected, line: line)
        }
    }

    func testEverySpellingNamesTheSameId() throws {
        for spelling in [strKey, hashHex, bodyHex, horizonHex] {
            let id = try ClaimableBalanceIDXDR(claimableBalanceId: spelling)
            XCTAssertEqual(id.claimableBalanceIdString, bodyHex, "spelling: \(spelling)")
            XCTAssertEqual(id.paddedBalanceIdHex, horizonHex, "spelling: \(spelling)")
        }
    }

    func testHexIsReadInEitherCase() throws {
        for spelling in [hashHex.uppercased(), bodyHex.uppercased(), horizonHex.uppercased()] {
            let id = try ClaimableBalanceIDXDR(claimableBalanceId: spelling)
            XCTAssertEqual(id.paddedBalanceIdHex, horizonHex, "spelling: \(spelling)")
        }
    }

    /// Only a string as long as a strkey is read as one, so a hash whose hexadecimal opens
    /// with "B" names a claimable balance id like any other.
    func testHexBeginningWithBIsReadAsHex() throws {
        let hashBeginningWithB = "b582697b67cbec7f9ce64f4dc67bfb2bfd26318bb9f964f4d70e3f41f650b1e6"
        for spelling in [hashBeginningWithB, hashBeginningWithB.uppercased()] {
            let id = try ClaimableBalanceIDXDR(claimableBalanceId: spelling)
            XCTAssertEqual(id.paddedBalanceIdHex, "00000000" + hashBeginningWithB, "spelling: \(spelling)")
        }
    }

    func testStrKeyLengthWithoutTheBPrefixIsRejected() {
        let notAStrKey = "C" + strKey.dropFirst()
        XCTAssertEqual(notAStrKey.count, 58)
        assertEncodingError(notAStrKey,
                            message: "a 58 character claimable balance id must be a strkey beginning with \"B\"")
    }

    /// The two ways a 58 character strkey can be malformed, each reported as what it is.
    ///
    /// The final symbol carries the low three bits of the checksum and two bits the encoding
    /// leaves unused. A final "A" keeps those unused bits zero, so the string is canonical
    /// base32 and only the checksum is wrong; a final "T" sets them, so the canonical
    /// re-encode rejects the string before the checksum is compared.
    func testMalformedStrKeyIsRejected() {
        XCTAssertThrowsError(try ClaimableBalanceIDXDR(claimableBalanceId: String(strKey.dropLast() + "A"))) { error in
            guard case KeyUtilsError.invalidChecksum = error else {
                return XCTFail("expected an invalid checksum error, got \(error)")
            }
        }
        XCTAssertThrowsError(try ClaimableBalanceIDXDR(claimableBalanceId: String(strKey.dropLast() + "T"))) { error in
            guard case KeyUtilsError.invalidEncodedString = error else {
                return XCTFail("expected an invalid encoded string error, got \(error)")
            }
        }
    }

    func testDiscriminantNamingNoTypeIsRejectedInEitherWidth() {
        assertEncodingError("01" + hashHex,
                            message: "claimable balance id carries the discriminant 1, which names no claimable balance id type")
        assertEncodingError("00000001" + hashHex,
                            message: "claimable balance id carries the discriminant 1, which names no claimable balance id type")
        assertEncodingError("ff000000" + hashHex,
                            message: "claimable balance id carries the discriminant -16777216, which names no claimable balance id type")
    }

    func testHexOfAnyOtherWidthIsRejected() {
        let spellings = "claimable balance id must be a 58 character strkey (B...), or hex of the bare id (64 characters), which a discriminant may prefix to 66 or 72 characters"
        assertEncodingError(String(hashHex.dropFirst(2)), message: spellings + "; 62 characters given")
        assertEncodingError(horizonHex + "00", message: spellings + "; 74 characters given")
        assertEncodingError("", message: spellings + "; 0 characters given")
        assertEncodingError("not hex at all", message: spellings + "; 14 characters given")
    }
}
