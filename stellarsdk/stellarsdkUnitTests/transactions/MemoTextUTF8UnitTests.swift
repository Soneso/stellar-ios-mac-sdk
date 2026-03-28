//
//  MemoTextUTF8UnitTests.swift
//  stellarsdkTests
//
//  Created by Soneso on 28/03/26.
//  Copyright © 2026 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

/// Unit tests that verify `Memo(text:)` enforces the 28-byte UTF-8 limit correctly.
///
/// The security fix changed the guard from `text.count` (Swift Character count) to
/// `text.utf8.count` (byte count). These tests are designed so that they FAIL if
/// someone reverts `text.utf8.count` back to `text.count`.
///
/// Test strategy uses CJK Unified Ideographs, each of which encodes as exactly
/// 3 bytes in UTF-8 but counts as 1 Swift Character. This creates a clear divergence
/// between `.count` and `.utf8.count` that exposes any regression.
///
/// Character "一" (U+4E00): .count contribution = 1, .utf8.count contribution = 3.
class MemoTextUTF8UnitTests: XCTestCase {

    // MARK: - Multi-byte characters: overflow path

    /// 10 CJK characters: Swift .count == 10 (within 28), UTF-8 byte count == 30 (exceeds 28).
    /// With the buggy `.count` guard this would NOT throw; with the correct `.utf8.count`
    /// guard it MUST throw. This test fails if the guard is reverted to `.count`.
    func testMultibyteStringExceedingByteLimitThrows() {
        // 10 × U+4E00 = 10 Swift chars, 30 UTF-8 bytes
        let text = String(repeating: "\u{4E00}", count: 10)
        XCTAssertEqual(text.count, 10, "Precondition: 10 Swift Characters")
        XCTAssertEqual(text.utf8.count, 30, "Precondition: 30 UTF-8 bytes")

        XCTAssertThrowsError(try Memo(text: text)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument(let message):
                XCTAssertTrue(
                    message.contains("28"),
                    "Error message should reference the 28-byte limit; got: \(message)"
                )
                XCTAssertTrue(
                    message.contains("30"),
                    "Error message should include the actual byte count (30); got: \(message)"
                )
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    /// A shorter but still over-limit multi-byte string: 9 CJK chars + 2 ASCII = 29 bytes.
    /// Swift .count == 11 (within 28), UTF-8 byte count == 29 (exceeds 28).
    func testMixedStringJustAboveByteLimitThrows() {
        // 9 × U+4E00 (27 bytes) + "ab" (2 bytes) = 29 bytes, 11 Swift chars
        let text = String(repeating: "\u{4E00}", count: 9) + "ab"
        XCTAssertEqual(text.count, 11, "Precondition: 11 Swift Characters")
        XCTAssertEqual(text.utf8.count, 29, "Precondition: 29 UTF-8 bytes")

        XCTAssertThrowsError(try Memo(text: text)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument:
                break
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    // MARK: - Multi-byte characters: success path

    /// Exactly 28 UTF-8 bytes using multi-byte characters.
    /// 9 CJK chars (27 bytes) + 1 ASCII char (1 byte) = 28 bytes, 10 Swift chars.
    /// This MUST succeed: byte count equals the limit exactly.
    func testMultibyteStringAtExactByteLimitSucceeds() throws {
        // 9 × U+4E00 (27 bytes) + "a" (1 byte) = 28 bytes, 10 Swift chars
        let text = String(repeating: "\u{4E00}", count: 9) + "a"
        XCTAssertEqual(text.count, 10, "Precondition: 10 Swift Characters")
        XCTAssertEqual(text.utf8.count, 28, "Precondition: exactly 28 UTF-8 bytes")

        let memo = try XCTUnwrap(try Memo(text: text))
        switch memo {
        case .text(let value):
            XCTAssertEqual(value, text)
        default:
            XCTFail("Expected Memo.text")
        }
    }

    /// 9 CJK characters: 27 UTF-8 bytes, 9 Swift chars — one byte under the limit.
    func testMultibyteStringBelowByteLimitSucceeds() throws {
        // 9 × U+4E00 = 27 bytes, 9 Swift chars
        let text = String(repeating: "\u{4E00}", count: 9)
        XCTAssertEqual(text.count, 9, "Precondition: 9 Swift Characters")
        XCTAssertEqual(text.utf8.count, 27, "Precondition: 27 UTF-8 bytes")

        let memo = try XCTUnwrap(try Memo(text: text))
        switch memo {
        case .text(let value):
            XCTAssertEqual(value, text)
        default:
            XCTFail("Expected Memo.text")
        }
    }

    // MARK: - Two-byte UTF-8 characters (U+0080–U+07FF)

    /// Two-byte UTF-8 characters: U+00E9 ("é"). Each is 1 Swift char, 2 UTF-8 bytes.
    /// 15 × "é" = 15 Swift chars, 30 UTF-8 bytes — must throw.
    func testTwoByteCharactersExceedingLimitThrows() {
        let text = String(repeating: "\u{00E9}", count: 15)
        XCTAssertEqual(text.count, 15, "Precondition: 15 Swift Characters")
        XCTAssertEqual(text.utf8.count, 30, "Precondition: 30 UTF-8 bytes")

        XCTAssertThrowsError(try Memo(text: text)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument:
                break
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    /// 14 × "é" = 14 Swift chars, 28 UTF-8 bytes — must succeed (exactly at limit).
    func testTwoByteCharactersAtExactLimitSucceeds() throws {
        let text = String(repeating: "\u{00E9}", count: 14)
        XCTAssertEqual(text.count, 14, "Precondition: 14 Swift Characters")
        XCTAssertEqual(text.utf8.count, 28, "Precondition: exactly 28 UTF-8 bytes")

        let memo = try XCTUnwrap(try Memo(text: text))
        switch memo {
        case .text(let value):
            XCTAssertEqual(value, text)
        default:
            XCTFail("Expected Memo.text")
        }
    }

    // MARK: - ASCII: existing behaviour must be preserved

    /// 28 ASCII characters = 28 Swift chars, 28 UTF-8 bytes: must succeed.
    func testASCIIAtLimitSucceeds() throws {
        let text = String(repeating: "x", count: 28)
        XCTAssertEqual(text.count, 28)
        XCTAssertEqual(text.utf8.count, 28)

        let memo = try XCTUnwrap(try Memo(text: text))
        switch memo {
        case .text(let value):
            XCTAssertEqual(value, text)
        default:
            XCTFail("Expected Memo.text")
        }
    }

    /// 29 ASCII characters = 29 bytes: must throw.
    func testASCIIAboveLimitThrows() {
        let text = String(repeating: "x", count: 29)
        XCTAssertThrowsError(try Memo(text: text)) { error in
            guard let sdkError = error as? StellarSDKError else {
                XCTFail("Expected StellarSDKError, got \(type(of: error))")
                return
            }
            switch sdkError {
            case .invalidArgument:
                break
            default:
                XCTFail("Expected .invalidArgument, got \(sdkError)")
            }
        }
    }

    // MARK: - Empty string

    func testEmptyStringSucceeds() throws {
        let memo = try XCTUnwrap(try Memo(text: ""))
        switch memo {
        case .text(let value):
            XCTAssertEqual(value, "")
        default:
            XCTFail("Expected Memo.text")
        }
    }
}
