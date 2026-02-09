//
//  MemoTestCase.swift
//  stellarsdk
//
//  Created by Soneso on 2/3/26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class MemoTestCase: XCTestCase {

    func testMemoNone() throws {
        let memo = Memo.none

        XCTAssertEqual(memo.type(), MemoTypeAsString.NONE)

        // Test equality
        let memo2 = Memo.none
        XCTAssertEqual(memo, memo2)

        // Test XDR conversion
        let xdr = memo.toXDR()
        switch xdr {
        case .none:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected MemoXDR.none")
        }

        // Test init from XDR
        let memoFromXDR = try XCTUnwrap(Memo(memoXDR: xdr))
        XCTAssertEqual(memo, memoFromXDR)
    }

    func testMemoText() throws {
        let text = "Hello Stellar"
        let memo = try XCTUnwrap(try Memo(text: text))

        switch memo {
        case .text(let value):
            XCTAssertEqual(value, text)
        default:
            XCTFail("Expected Memo.text")
        }

        XCTAssertEqual(memo.type(), MemoTypeAsString.TEXT)

        // Test equality
        let memo2 = try XCTUnwrap(try Memo(text: text))
        XCTAssertEqual(memo, memo2)

        // Test XDR conversion
        let xdr = memo.toXDR()
        switch xdr {
        case .text(let value):
            XCTAssertEqual(value, text)
        default:
            XCTFail("Expected MemoXDR.text")
        }

        // Test init from XDR
        let memoFromXDR = try XCTUnwrap(Memo(memoXDR: xdr))
        XCTAssertEqual(memo, memoFromXDR)
    }

    func testMemoTextEmpty() throws {
        let memo = try XCTUnwrap(try Memo(text: ""))

        switch memo {
        case .text(let value):
            XCTAssertEqual(value, "")
        default:
            XCTFail("Expected Memo.text")
        }

        XCTAssertEqual(memo.type(), MemoTypeAsString.TEXT)

        // Test XDR roundtrip
        let xdr = memo.toXDR()
        let memoFromXDR = try XCTUnwrap(Memo(memoXDR: xdr))
        XCTAssertEqual(memo, memoFromXDR)
    }

    func testMemoTextMaxLength() throws {
        // Create a text memo at exactly 28 bytes
        let text = String(repeating: "a", count: 28)
        let memo = try XCTUnwrap(try Memo(text: text))

        switch memo {
        case .text(let value):
            XCTAssertEqual(value, text)
            XCTAssertEqual(value.count, 28)
        default:
            XCTFail("Expected Memo.text")
        }

        XCTAssertEqual(memo.type(), MemoTypeAsString.TEXT)

        // Test XDR roundtrip
        let xdr = memo.toXDR()
        let memoFromXDR = try XCTUnwrap(Memo(memoXDR: xdr))
        XCTAssertEqual(memo, memoFromXDR)
    }

    func testMemoTextTooLongThrows() {
        // Create a text memo that is too long (29 bytes)
        let text = String(repeating: "a", count: 29)

        XCTAssertThrowsError(try Memo(text: text)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError")
                return
            }

            switch sdkError {
            case .invalidArgument(let message):
                XCTAssertTrue(message.contains("28"))
                XCTAssertTrue(message.contains("29"))
            default:
                XCTFail("Expected invalidArgument error")
            }
        }
    }

    func testMemoId() throws {
        let id: UInt64 = 123456789
        let memo = Memo.id(id)

        switch memo {
        case .id(let value):
            XCTAssertEqual(value, id)
        default:
            XCTFail("Expected Memo.id")
        }

        XCTAssertEqual(memo.type(), MemoTypeAsString.ID)

        // Test equality
        let memo2 = Memo.id(id)
        XCTAssertEqual(memo, memo2)

        // Test XDR conversion
        let xdr = memo.toXDR()
        switch xdr {
        case .id(let value):
            XCTAssertEqual(value, id)
        default:
            XCTFail("Expected MemoXDR.id")
        }

        // Test init from XDR
        let memoFromXDR = try XCTUnwrap(Memo(memoXDR: xdr))
        XCTAssertEqual(memo, memoFromXDR)
    }

    func testMemoIdBoundaries() throws {
        // Test zero
        let memoZero = Memo.id(0)
        switch memoZero {
        case .id(let value):
            XCTAssertEqual(value, 0)
        default:
            XCTFail("Expected Memo.id")
        }

        // Test XDR roundtrip for zero
        let xdrZero = memoZero.toXDR()
        let memoZeroFromXDR = try XCTUnwrap(Memo(memoXDR: xdrZero))
        XCTAssertEqual(memoZero, memoZeroFromXDR)

        // Test max
        let memoMax = Memo.id(UInt64.max)
        switch memoMax {
        case .id(let value):
            XCTAssertEqual(value, UInt64.max)
        default:
            XCTFail("Expected Memo.id")
        }

        // Test XDR roundtrip for max
        let xdrMax = memoMax.toXDR()
        let memoMaxFromXDR = try XCTUnwrap(Memo(memoXDR: xdrMax))
        XCTAssertEqual(memoMax, memoMaxFromXDR)
    }

    func testMemoHash() throws {
        // Create 32 bytes of data
        let hashData = Data(repeating: 0xAB, count: 32)
        let memo = try XCTUnwrap(try Memo(hash: hashData))

        switch memo {
        case .hash(let value):
            XCTAssertEqual(value, hashData)
            XCTAssertEqual(value.count, 32)
        default:
            XCTFail("Expected Memo.hash")
        }

        XCTAssertEqual(memo.type(), MemoTypeAsString.HASH)

        // Test equality
        let memo2 = try XCTUnwrap(try Memo(hash: hashData))
        XCTAssertEqual(memo, memo2)

        // Test hex value
        let hexValue = try memo.hexValue()
        XCTAssertEqual(hexValue.count, 64) // 32 bytes = 64 hex characters

        // Test XDR conversion
        let xdr = memo.toXDR()
        switch xdr {
        case .hash(let wrapped):
            XCTAssertEqual(wrapped.wrapped, hashData)
        default:
            XCTFail("Expected MemoXDR.hash")
        }

        // Test init from XDR
        let memoFromXDR = try XCTUnwrap(Memo(memoXDR: xdr))
        XCTAssertEqual(memo, memoFromXDR)

        // Test that hash too large throws error
        let tooLargeHash = Data(repeating: 0xFF, count: 33)
        XCTAssertThrowsError(try Memo(hash: tooLargeHash)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError")
                return
            }

            switch sdkError {
            case .invalidArgument(let message):
                XCTAssertTrue(message.contains("32"))
            default:
                XCTFail("Expected invalidArgument error")
            }
        }
    }

    func testMemoHashShorterThan32Bytes() throws {
        // Test 16 byte hash - XDR pads to 32 bytes
        let hash16 = Data(repeating: 0x12, count: 16)
        let memo16 = try XCTUnwrap(try Memo(hash: hash16))

        switch memo16 {
        case .hash(let value):
            XCTAssertEqual(value, hash16)
            XCTAssertEqual(value.count, 16)
        default:
            XCTFail("Expected Memo.hash")
        }

        // Test XDR roundtrip - note that XDR pads to 32 bytes
        let xdr16 = memo16.toXDR()
        let memo16FromXDR = try XCTUnwrap(Memo(memoXDR: xdr16))
        switch memo16FromXDR {
        case .hash(let value):
            // XDR pads with zeros to 32 bytes
            XCTAssertEqual(value.count, 32)
            // First 16 bytes should match original
            XCTAssertEqual(value.prefix(16), hash16)
            // Remaining bytes should be zero
            XCTAssertEqual(value.suffix(16), Data(repeating: 0x00, count: 16))
        default:
            XCTFail("Expected Memo.hash")
        }

        // Test 1 byte hash - XDR pads to 32 bytes
        let hash1 = Data(repeating: 0xFF, count: 1)
        let memo1 = try XCTUnwrap(try Memo(hash: hash1))

        switch memo1 {
        case .hash(let value):
            XCTAssertEqual(value, hash1)
            XCTAssertEqual(value.count, 1)
        default:
            XCTFail("Expected Memo.hash")
        }

        // Test XDR roundtrip - note that XDR pads to 32 bytes
        let xdr1 = memo1.toXDR()
        let memo1FromXDR = try XCTUnwrap(Memo(memoXDR: xdr1))
        switch memo1FromXDR {
        case .hash(let value):
            // XDR pads with zeros to 32 bytes
            XCTAssertEqual(value.count, 32)
            // First byte should match original
            XCTAssertEqual(value.prefix(1), hash1)
            // Remaining bytes should be zero
            XCTAssertEqual(value.suffix(31), Data(repeating: 0x00, count: 31))
        default:
            XCTFail("Expected Memo.hash")
        }
    }

    func testMemoReturn() throws {
        // Create 32 bytes of data
        let returnHashData = Data(repeating: 0xCD, count: 32)
        let memo = try XCTUnwrap(try Memo(returnHash: returnHashData))

        switch memo {
        case .returnHash(let value):
            XCTAssertEqual(value, returnHashData)
            XCTAssertEqual(value.count, 32)
        default:
            XCTFail("Expected Memo.returnHash")
        }

        XCTAssertEqual(memo.type(), MemoTypeAsString.RETURN)

        // Test equality
        let memo2 = try XCTUnwrap(try Memo(returnHash: returnHashData))
        XCTAssertEqual(memo, memo2)

        // Test hex value
        let hexValue = try memo.hexValue()
        XCTAssertEqual(hexValue.count, 64) // 32 bytes = 64 hex characters

        // Test XDR conversion
        let xdr = memo.toXDR()
        switch xdr {
        case .returnHash(let wrapped):
            XCTAssertEqual(wrapped.wrapped, returnHashData)
        default:
            XCTFail("Expected MemoXDR.returnHash")
        }

        // Test init from XDR
        let memoFromXDR = try XCTUnwrap(Memo(memoXDR: xdr))
        XCTAssertEqual(memo, memoFromXDR)

        // Test that return hash too large throws error
        let tooLargeReturnHash = Data(repeating: 0xFF, count: 33)
        XCTAssertThrowsError(try Memo(returnHash: tooLargeReturnHash)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError")
                return
            }

            switch sdkError {
            case .invalidArgument(let message):
                XCTAssertTrue(message.contains("32"))
            default:
                XCTFail("Expected invalidArgument error")
            }
        }
    }

    func testMemoXDRRoundtrip() throws {
        // Test roundtrip for all memo types

        // None
        let memoNone = Memo.none
        let xdrNone = memoNone.toXDR()
        let memoNoneFromXDR = try XCTUnwrap(Memo(memoXDR: xdrNone))
        XCTAssertEqual(memoNone, memoNoneFromXDR)

        // Text
        let memoText = try XCTUnwrap(try Memo(text: "Test Memo"))
        let xdrText = memoText.toXDR()
        let memoTextFromXDR = try XCTUnwrap(Memo(memoXDR: xdrText))
        XCTAssertEqual(memoText, memoTextFromXDR)

        // ID
        let memoId = Memo.id(987654321)
        let xdrId = memoId.toXDR()
        let memoIdFromXDR = try XCTUnwrap(Memo(memoXDR: xdrId))
        XCTAssertEqual(memoId, memoIdFromXDR)

        // Hash
        let memoHash = try XCTUnwrap(try Memo(hash: Data(repeating: 0x12, count: 32)))
        let xdrHash = memoHash.toXDR()
        let memoHashFromXDR = try XCTUnwrap(Memo(memoXDR: xdrHash))
        XCTAssertEqual(memoHash, memoHashFromXDR)

        // Return
        let memoReturn = try XCTUnwrap(try Memo(returnHash: Data(repeating: 0x34, count: 32)))
        let xdrReturn = memoReturn.toXDR()
        let memoReturnFromXDR = try XCTUnwrap(Memo(memoXDR: xdrReturn))
        XCTAssertEqual(memoReturn, memoReturnFromXDR)
    }

    func testMemoHashHexValueErrors() {
        // Test that hexValue() throws error for non-hash memo types
        let memoNone = Memo.none
        XCTAssertThrowsError(try memoNone.hexValue()) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError")
                return
            }

            switch sdkError {
            case .invalidArgument(let message):
                XCTAssertTrue(message.contains("hash"))
            default:
                XCTFail("Expected invalidArgument error")
            }
        }

        let memoText = Memo.text("test")
        XCTAssertThrowsError(try memoText.hexValue())

        let memoId = Memo.id(123)
        XCTAssertThrowsError(try memoId.hexValue())
    }
}
