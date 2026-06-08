//
//  WebAuthnAllowCredentialTests.swift
//  stellarsdkUnitTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import XCTest
@testable import stellarsdk

final class WebAuthnAllowCredentialTests: XCTestCase {

    // MARK: - Construction

    func test_allow_credential_construction_with_id_only() {
        let id = Data([0x01, 0x02, 0x03])
        let credential = WebAuthnAllowCredential(id: id)

        XCTAssertEqual(credential.id, id)
        XCTAssertNil(credential.transports)
    }

    func test_allow_credential_construction_with_id_and_transports() {
        let id = Data([0x0A, 0x0B, 0x0C])
        let transports = ["internal", "hybrid"]
        let credential = WebAuthnAllowCredential(id: id, transports: transports)

        XCTAssertEqual(credential.id, id)
        XCTAssertEqual(credential.transports, transports)
    }

    func test_allow_credential_construction_with_explicit_null_transports() {
        let id = Data([0x10, 0x20])
        let credential = WebAuthnAllowCredential(id: id, transports: nil)

        XCTAssertEqual(credential.id, id)
        XCTAssertNil(credential.transports)
    }

    // MARK: - Equality

    func test_allow_credential_equals_same_byte_content() {
        // Independently allocated buffers with the same byte content must compare equal.
        let id1 = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let id2 = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let transports = ["internal"]

        let credential1 = WebAuthnAllowCredential(id: id1, transports: transports)
        let credential2 = WebAuthnAllowCredential(id: id2, transports: transports)

        XCTAssertEqual(credential1, credential2)
    }

    func test_allow_credential_equals_with_null_transports() {
        let credential1 = WebAuthnAllowCredential(id: Data([0x01, 0x02]), transports: nil)
        let credential2 = WebAuthnAllowCredential(id: Data([0x01, 0x02]), transports: nil)

        XCTAssertEqual(credential1, credential2)
    }

    func test_allow_credential_not_equal_when_ids_differ() {
        let credential1 = WebAuthnAllowCredential(id: Data([0x01, 0x02]))
        let credential2 = WebAuthnAllowCredential(id: Data([0x01, 0x03]))

        XCTAssertNotEqual(credential1, credential2)
    }

    func test_allow_credential_not_equal_when_transports_differ() {
        let id = Data([0x01, 0x02])
        let credential1 = WebAuthnAllowCredential(id: id, transports: ["internal"])
        let credential2 = WebAuthnAllowCredential(id: id, transports: ["usb"])

        XCTAssertNotEqual(credential1, credential2)
    }

    func test_allow_credential_not_equal_null_transports_vs_empty_list() {
        let id = Data([0x01, 0x02])
        let withNull = WebAuthnAllowCredential(id: id, transports: nil)
        let withEmpty = WebAuthnAllowCredential(id: id, transports: [])

        XCTAssertNotEqual(withNull, withEmpty)
    }

    func test_allow_credential_not_equal_one_null_other_non_null_transports() {
        let id = Data([0x01, 0x02])
        let withNull = WebAuthnAllowCredential(id: id, transports: nil)
        let withValue = WebAuthnAllowCredential(id: id, transports: ["hybrid"])

        XCTAssertNotEqual(withNull, withValue)
        XCTAssertNotEqual(withValue, withNull)
    }

    func test_allow_credential_equals_with_self() {
        let credential = WebAuthnAllowCredential(
            id: Data([0x01, 0x02, 0x03]),
            transports: ["internal"]
        )

        XCTAssertEqual(credential, credential)
    }

    // MARK: - Hash code

    func test_allow_credential_hashcode_consistency() {
        let id1 = Data([0x11, 0x22, 0x33])
        let id2 = Data([0x11, 0x22, 0x33])
        let transports = ["internal", "usb"]

        let credential1 = WebAuthnAllowCredential(id: id1, transports: transports)
        let credential2 = WebAuthnAllowCredential(id: id2, transports: transports)

        XCTAssertEqual(credential1, credential2)
        XCTAssertEqual(credential1.hashValue, credential2.hashValue)
    }

    func test_allow_credential_hashcode_differs_for_different_objects() {
        let credential1 = WebAuthnAllowCredential(id: Data([0x01]), transports: ["internal"])
        let credential2 = WebAuthnAllowCredential(id: Data([0x02]), transports: ["internal"])

        // Hash collisions are theoretically possible but practically impossible for this
        // simple case; the test asserts the obvious well-distributed behavior.
        XCTAssertNotEqual(credential1.hashValue, credential2.hashValue)
    }

    func test_allow_credential_hashcode_null_vs_non_null_transports_differs() {
        let id = Data([0x01, 0x02])
        let withNull = WebAuthnAllowCredential(id: id, transports: nil)
        let withValue = WebAuthnAllowCredential(id: id, transports: ["internal"])

        XCTAssertNotEqual(withNull.hashValue, withValue.hashValue)
    }

    // MARK: - fromId factory

    func test_allow_credential_from_id_creates_credential_with_null_transports() {
        let id = Data([0xAB, 0xCD])
        let credential = WebAuthnAllowCredential.fromId(id)

        XCTAssertEqual(credential.id, id)
        XCTAssertNil(credential.transports)
    }

    func test_allow_credential_from_id_equivalent_to_direct_construction() {
        let id = Data([0x01, 0x02, 0x03, 0x04])
        let fromFactory = WebAuthnAllowCredential.fromId(id)
        let direct = WebAuthnAllowCredential(id: id)

        XCTAssertEqual(fromFactory, direct)
    }

    // MARK: - fromIds factory

    func test_allow_credential_from_ids_creates_list_with_all_null_transports() {
        let ids: [Data] = [
            Data([0x01]),
            Data([0x02, 0x03]),
            Data([0x04, 0x05, 0x06])
        ]

        let credentials = WebAuthnAllowCredential.fromIds(ids)

        XCTAssertEqual(credentials.count, ids.count)
        for (index, id) in ids.enumerated() {
            XCTAssertEqual(credentials[index].id, id)
            XCTAssertNil(credentials[index].transports)
        }
    }

    func test_allow_credential_from_ids_empty_list_returns_empty_list() {
        let credentials = WebAuthnAllowCredential.fromIds([])
        XCTAssertTrue(credentials.isEmpty)
    }

    func test_allow_credential_from_ids_single_element_list() {
        let id = Data([0xFF, 0x00])
        let credentials = WebAuthnAllowCredential.fromIds([id])

        XCTAssertEqual(credentials.count, 1)
        XCTAssertEqual(credentials[0].id, id)
        XCTAssertNil(credentials[0].transports)
    }

    // MARK: - Transport values

    func test_allow_credential_common_transport_values_preserved() {
        let id = Data([0x01])
        let transports = ["internal", "hybrid", "usb", "ble", "nfc"]
        let credential = WebAuthnAllowCredential(id: id, transports: transports)

        XCTAssertEqual(credential.transports, transports)
        XCTAssertEqual(credential.transports?.count, 5)
        XCTAssertTrue(credential.transports?.contains("internal") ?? false)
        XCTAssertTrue(credential.transports?.contains("hybrid") ?? false)
        XCTAssertTrue(credential.transports?.contains("usb") ?? false)
        XCTAssertTrue(credential.transports?.contains("ble") ?? false)
        XCTAssertTrue(credential.transports?.contains("nfc") ?? false)
    }

    func test_allow_credential_transport_order_preserved() {
        let id = Data([0x01])
        let transports = ["nfc", "usb", "internal"]
        let credential = WebAuthnAllowCredential(id: id, transports: transports)

        XCTAssertEqual(credential.transports?[0], "nfc")
        XCTAssertEqual(credential.transports?[1], "usb")
        XCTAssertEqual(credential.transports?[2], "internal")
    }

    // MARK: - Byte storage semantics

    func test_allow_credential_id_stored_by_reference_not_copied() {
        // Swift's `Data` is a value type with copy-on-write semantics. The struct stores the
        // value passed at construction time; mutating the original `var` after construction
        // does NOT propagate into the stored field because `Data`'s assignment creates an
        // independent value-copy on first mutation.
        var originalId = Data([0x01, 0x02, 0x03])
        let credential = WebAuthnAllowCredential(id: originalId)

        XCTAssertEqual(credential.id, Data([0x01, 0x02, 0x03]))

        originalId[0] = 0xFF

        // The stored id is unaffected because Data is a value type and the mutation copied.
        XCTAssertEqual(credential.id[0], 0x01)
    }

    func test_allow_credential_copy_of_id_is_independent() {
        // Even when callers explicitly copy, the behavior is identical to the value-type
        // semantics above: mutations on the source array do not propagate.
        var originalId = Data([0x01, 0x02, 0x03])
        let credential = WebAuthnAllowCredential(id: Data(originalId))

        originalId[0] = 0xFF

        XCTAssertEqual(credential.id[0], 0x01)
    }
}
