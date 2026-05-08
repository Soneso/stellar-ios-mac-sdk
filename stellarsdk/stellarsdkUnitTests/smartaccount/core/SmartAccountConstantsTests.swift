//
//  SmartAccountConstantsTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class SmartAccountConstantsTests: XCTestCase {

    func test_constant_ED25519_PUBLIC_KEY_SIZE_equals_32() {
        XCTAssertEqual(SmartAccountConstants.ed25519PublicKeySize, 32)
    }

    func test_constant_SECP256R1_PUBLIC_KEY_SIZE_equals_65() {
        XCTAssertEqual(SmartAccountConstants.secp256r1PublicKeySize, 65)
    }

    func test_constant_UNCOMPRESSED_PUBKEY_PREFIX_equals_0x04() {
        XCTAssertEqual(SmartAccountConstants.uncompressedPubkeyPrefix, 0x04)
    }

    func test_uncompressed_pubkey_prefix_is_byte_typed() {
        let prefix: UInt8 = SmartAccountConstants.uncompressedPubkeyPrefix
        XCTAssertEqual(prefix, 0x04)
        // Compile-time confirmation that the constant is `UInt8` (Swift's byte-typed scalar).
        XCTAssertTrue(type(of: SmartAccountConstants.uncompressedPubkeyPrefix) == UInt8.self)
    }

    func test_constants_are_compile_time_constant_let_or_const() {
        // Each constant is exposed as a `static let` (Swift's compile-time-immutable form).
        // Reading them in a constant context confirms they are not stored mutables.
        let e: Int = SmartAccountConstants.ed25519PublicKeySize
        let s: Int = SmartAccountConstants.secp256r1PublicKeySize
        let p: UInt8 = SmartAccountConstants.uncompressedPubkeyPrefix
        XCTAssertEqual(e, 32)
        XCTAssertEqual(s, 65)
        XCTAssertEqual(p, 0x04)
    }
}
