//
// GENERATED FILE - DO NOT EDIT
//
// This file was produced by tools/xdr-generator/test/emit_json_tests.rb. It exercises
// the SEP-0051 (XDR-JSON) conversions of every type declared in one .x source. To
// regenerate, run:
//
//     make xdr-generate-tests
//
// Any manual edits will be overwritten on the next run.
//

import XCTest
import Foundation
import stellarsdk

final class GeneratedXdrJsonStellarLedgerEntriesUnitTests: XCTestCase {

    func test_AccountEntryExtV1XDR_accountEntryExtensionV2_rejectsBareString() throws {
        XCTAssertThrowsError(try AccountEntryExtV1XDR.fromXdrJson("\"v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("AccountEntryExtV1XDR.v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "AccountEntryExtV1XDR")
            XCTAssertEqual(key, "v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_AccountEntryExtV1XDR_accountEntryExtensionV2_roundTrip() throws {
        let original: AccountEntryExtV1XDR = .accountEntryExtensionV2(AccountEntryExtensionV2(numSponsored: UInt32(42), numSponsoring: UInt32(42), signerSponsoringIDs: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtV1XDR.fromXdrJson(json)
        let viaValue = try AccountEntryExtV1XDR.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtV1XDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try AccountEntryExtV1XDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("AccountEntryExtV1XDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "AccountEntryExtV1XDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_AccountEntryExtV1XDR_void_roundTrip() throws {
        let original: AccountEntryExtV1XDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtV1XDR.fromXdrJson(json)
        let viaValue = try AccountEntryExtV1XDR.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtV2XDR_accountEntryExtensionV3_rejectsBareString() throws {
        XCTAssertThrowsError(try AccountEntryExtV2XDR.fromXdrJson("\"v3\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("AccountEntryExtV2XDR.v3: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "AccountEntryExtV2XDR")
            XCTAssertEqual(key, "v3",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_AccountEntryExtV2XDR_accountEntryExtensionV3_roundTrip() throws {
        let original: AccountEntryExtV2XDR = .accountEntryExtensionV3(AccountEntryExtensionV3(ext: .void, seqLedger: UInt32(42), seqTime: UInt64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtV2XDR.fromXdrJson(json)
        let viaValue = try AccountEntryExtV2XDR.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtV2XDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try AccountEntryExtV2XDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("AccountEntryExtV2XDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "AccountEntryExtV2XDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_AccountEntryExtV2XDR_void_roundTrip() throws {
        let original: AccountEntryExtV2XDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtV2XDR.fromXdrJson(json)
        let viaValue = try AccountEntryExtV2XDR.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtXDR_accountEntryExtensionV1_rejectsBareString() throws {
        XCTAssertThrowsError(try AccountEntryExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("AccountEntryExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "AccountEntryExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_AccountEntryExtXDR_accountEntryExtensionV1_roundTrip() throws {
        let original: AccountEntryExtXDR = .accountEntryExtensionV1(AccountEntryExtensionV1(liabilities: LiabilitiesXDR(buying: Int64(1234567), selling: Int64(1234567)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtXDR.fromXdrJson(json)
        let viaValue = try AccountEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try AccountEntryExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("AccountEntryExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "AccountEntryExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_AccountEntryExtXDR_void_roundTrip() throws {
        let original: AccountEntryExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtXDR.fromXdrJson(json)
        let viaValue = try AccountEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtensionV1_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AccountEntryExtensionV1.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AccountEntryExtensionV1 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AccountEntryExtensionV1_roundTrip() throws {
        let original: AccountEntryExtensionV1 = AccountEntryExtensionV1(liabilities: LiabilitiesXDR(buying: Int64(1234567), selling: Int64(1234567)), reserved: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtensionV1.fromXdrJson(json)
        let viaValue = try AccountEntryExtensionV1.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtensionV1.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtensionV1 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtensionV1 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtensionV1 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtensionV1 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtensionV1 must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtensionV2_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AccountEntryExtensionV2.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AccountEntryExtensionV2 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AccountEntryExtensionV2_roundTrip() throws {
        let original: AccountEntryExtensionV2 = AccountEntryExtensionV2(numSponsored: UInt32(42), numSponsoring: UInt32(42), signerSponsoringIDs: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], reserved: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtensionV2.fromXdrJson(json)
        let viaValue = try AccountEntryExtensionV2.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtensionV2.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtensionV2 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtensionV2 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtensionV2 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtensionV2 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtensionV2 must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryExtensionV3_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AccountEntryExtensionV3.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AccountEntryExtensionV3 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AccountEntryExtensionV3_roundTrip() throws {
        let original: AccountEntryExtensionV3 = AccountEntryExtensionV3(ext: .void, seqLedger: UInt32(42), seqTime: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryExtensionV3.fromXdrJson(json)
        let viaValue = try AccountEntryExtensionV3.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryExtensionV3.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryExtensionV3 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryExtensionV3 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryExtensionV3 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryExtensionV3 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryExtensionV3 must reach the same bytes through JSON and XDR")
    }

    func test_AccountEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AccountEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AccountEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AccountEntryXDR_roundTrip() throws {
        let original: AccountEntryXDR = AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))), weight: UInt32(42))], ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountEntryXDR.fromXdrJson(json)
        let viaValue = try AccountEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountFlags_AUTH_CLAWBACK_ENABLED_FLAG() throws {
        let value: AccountFlags = .clawbackEnabledFlag
        XCTAssertEqual(try value.toXdrJson(), "\"clawback_enabled_flag\"",
                       "AccountFlags.clawbackEnabledFlag must render as clawback_enabled_flag")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "AccountFlags.clawbackEnabledFlag must keep its XDR value")
        XCTAssertEqual(try AccountFlags.fromXdrJson("\"clawback_enabled_flag\""), value,
                       "clawback_enabled_flag must read back as AccountFlags.clawbackEnabledFlag")
    }

    func test_AccountFlags_AUTH_IMMUTABLE_FLAG() throws {
        let value: AccountFlags = .immutableFlag
        XCTAssertEqual(try value.toXdrJson(), "\"immutable_flag\"",
                       "AccountFlags.immutableFlag must render as immutable_flag")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "AccountFlags.immutableFlag must keep its XDR value")
        XCTAssertEqual(try AccountFlags.fromXdrJson("\"immutable_flag\""), value,
                       "immutable_flag must read back as AccountFlags.immutableFlag")
    }

    func test_AccountFlags_AUTH_REQUIRED_FLAG() throws {
        let value: AccountFlags = .requiredFlag
        XCTAssertEqual(try value.toXdrJson(), "\"required_flag\"",
                       "AccountFlags.requiredFlag must render as required_flag")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "AccountFlags.requiredFlag must keep its XDR value")
        XCTAssertEqual(try AccountFlags.fromXdrJson("\"required_flag\""), value,
                       "required_flag must read back as AccountFlags.requiredFlag")
    }

    func test_AccountFlags_AUTH_REVOCABLE_FLAG() throws {
        let value: AccountFlags = .revocableFlag
        XCTAssertEqual(try value.toXdrJson(), "\"revocable_flag\"",
                       "AccountFlags.revocableFlag must render as revocable_flag")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "AccountFlags.revocableFlag must keep its XDR value")
        XCTAssertEqual(try AccountFlags.fromXdrJson("\"revocable_flag\""), value,
                       "revocable_flag must read back as AccountFlags.revocableFlag")
    }

    func test_AccountFlags_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try AccountFlags.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("AccountFlags: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "AccountFlags")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_AllowTrustOpAssetXDR_alphanum12_roundTrip() throws {
        let original: AllowTrustOpAssetXDR = .alphanum12(WrappedData12(Data(repeating: 0xAB, count: 12)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustOpAssetXDR.fromXdrJson(json)
        let viaValue = try AllowTrustOpAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustOpAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustOpAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustOpAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustOpAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustOpAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustOpAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustOpAssetXDR_alphanum4_roundTrip() throws {
        let original: AllowTrustOpAssetXDR = .alphanum4(WrappedData4(Data(repeating: 0xAB, count: 4)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustOpAssetXDR.fromXdrJson(json)
        let viaValue = try AllowTrustOpAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustOpAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustOpAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustOpAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustOpAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustOpAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustOpAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustOpAssetXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AllowTrustOpAssetXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AllowTrustOpAssetXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Alpha12XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Alpha12XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Alpha12XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Alpha12XDR_roundTrip() throws {
        let original: Alpha12XDR = Alpha12XDR(assetCode: WrappedData12(Data(repeating: 0xAB, count: 12)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try Alpha12XDR.fromXdrJson(json)
        let viaValue = try Alpha12XDR.fromXdrJsonValue(tree)
        let viaTree = try Alpha12XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "Alpha12XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "Alpha12XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "Alpha12XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "Alpha12XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "Alpha12XDR must reach the same bytes through JSON and XDR")
    }

    func test_Alpha4XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Alpha4XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Alpha4XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Alpha4XDR_roundTrip() throws {
        let original: Alpha4XDR = Alpha4XDR(assetCode: WrappedData4(Data(repeating: 0xAB, count: 4)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try Alpha4XDR.fromXdrJson(json)
        let viaValue = try Alpha4XDR.fromXdrJsonValue(tree)
        let viaTree = try Alpha4XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "Alpha4XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "Alpha4XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "Alpha4XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "Alpha4XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "Alpha4XDR must reach the same bytes through JSON and XDR")
    }

    func test_AssetCode12XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AssetCode12XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AssetCode12XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AssetCode12XDR_roundTrip() throws {
        let original: AssetCode12XDR = WrappedData12(Data(repeating: 0xAB, count: 12))
        let tree = try AssetCode12XDRJsonCodec.toXdrJsonValue(original)
        let json = try AssetCode12XDRJsonCodec.toXdrJson(original)
        let decoded = try AssetCode12XDRJsonCodec.fromXdrJson(json)
        let viaValue = try AssetCode12XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try AssetCode12XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "AssetCode12XDR must produce the same tree after a round trip")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(decoded), json,
                       "AssetCode12XDR must produce the same text after a round trip")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(viaValue), json,
                       "AssetCode12XDR must read a tree the same way it reads text")
        XCTAssertEqual(try AssetCode12XDRJsonCodec.toXdrJson(viaTree), json,
                       "AssetCode12XDR must read a depth-checked tree the same way")
    }

    func test_AssetCode4XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AssetCode4XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AssetCode4XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AssetCode4XDR_roundTrip() throws {
        let original: AssetCode4XDR = WrappedData4(Data(repeating: 0xAB, count: 4))
        let tree = try AssetCode4XDRJsonCodec.toXdrJsonValue(original)
        let json = try AssetCode4XDRJsonCodec.toXdrJson(original)
        let decoded = try AssetCode4XDRJsonCodec.fromXdrJson(json)
        let viaValue = try AssetCode4XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try AssetCode4XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try AssetCode4XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "AssetCode4XDR must produce the same tree after a round trip")
        XCTAssertEqual(try AssetCode4XDRJsonCodec.toXdrJson(decoded), json,
                       "AssetCode4XDR must produce the same text after a round trip")
        XCTAssertEqual(try AssetCode4XDRJsonCodec.toXdrJson(viaValue), json,
                       "AssetCode4XDR must read a tree the same way it reads text")
        XCTAssertEqual(try AssetCode4XDRJsonCodec.toXdrJson(viaTree), json,
                       "AssetCode4XDR must read a depth-checked tree the same way")
    }

    func test_AssetType_ASSET_TYPE_CREDIT_ALPHANUM12() throws {
        let value: AssetType = .creditAlphanum12
        XCTAssertEqual(try value.toXdrJson(), "\"credit_alphanum12\"",
                       "AssetType.creditAlphanum12 must render as credit_alphanum12")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "AssetType.creditAlphanum12 must keep its XDR value")
        XCTAssertEqual(try AssetType.fromXdrJson("\"credit_alphanum12\""), value,
                       "credit_alphanum12 must read back as AssetType.creditAlphanum12")
    }

    func test_AssetType_ASSET_TYPE_CREDIT_ALPHANUM4() throws {
        let value: AssetType = .creditAlphanum4
        XCTAssertEqual(try value.toXdrJson(), "\"credit_alphanum4\"",
                       "AssetType.creditAlphanum4 must render as credit_alphanum4")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "AssetType.creditAlphanum4 must keep its XDR value")
        XCTAssertEqual(try AssetType.fromXdrJson("\"credit_alphanum4\""), value,
                       "credit_alphanum4 must read back as AssetType.creditAlphanum4")
    }

    func test_AssetType_ASSET_TYPE_NATIVE() throws {
        let value: AssetType = .native
        XCTAssertEqual(try value.toXdrJson(), "\"native\"",
                       "AssetType.native must render as native")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "AssetType.native must keep its XDR value")
        XCTAssertEqual(try AssetType.fromXdrJson("\"native\""), value,
                       "native must read back as AssetType.native")
    }

    func test_AssetType_ASSET_TYPE_POOL_SHARE() throws {
        let value: AssetType = .poolShare
        XCTAssertEqual(try value.toXdrJson(), "\"pool_share\"",
                       "AssetType.poolShare must render as pool_share")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "AssetType.poolShare must keep its XDR value")
        XCTAssertEqual(try AssetType.fromXdrJson("\"pool_share\""), value,
                       "pool_share must read back as AssetType.poolShare")
    }

    func test_AssetType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try AssetType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("AssetType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "AssetType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_AssetXDR_alphanum12_rejectsBareString() throws {
        XCTAssertThrowsError(try AssetXDR.fromXdrJson("\"credit_alphanum12\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("AssetXDR.credit_alphanum12: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "AssetXDR")
            XCTAssertEqual(key, "credit_alphanum12",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_AssetXDR_alphanum12_roundTrip() throws {
        let original: AssetXDR = .alphanum12(Alpha12XDR(assetCode: WrappedData12(Data(repeating: 0xAB, count: 12)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AssetXDR.fromXdrJson(json)
        let viaValue = try AssetXDR.fromXdrJsonValue(tree)
        let viaTree = try AssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_AssetXDR_alphanum4_rejectsBareString() throws {
        XCTAssertThrowsError(try AssetXDR.fromXdrJson("\"credit_alphanum4\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("AssetXDR.credit_alphanum4: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "AssetXDR")
            XCTAssertEqual(key, "credit_alphanum4",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_AssetXDR_alphanum4_roundTrip() throws {
        let original: AssetXDR = .alphanum4(Alpha4XDR(assetCode: WrappedData4(Data(repeating: 0xAB, count: 4)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AssetXDR.fromXdrJson(json)
        let viaValue = try AssetXDR.fromXdrJsonValue(tree)
        let viaTree = try AssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_AssetXDR_native_roundTrip() throws {
        let original: AssetXDR = .native
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AssetXDR.fromXdrJson(json)
        let viaValue = try AssetXDR.fromXdrJsonValue(tree)
        let viaTree = try AssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_AssetXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try AssetXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("AssetXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "AssetXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_BucketEntryTypeXDR_DEADENTRY() throws {
        let value: BucketEntryTypeXDR = .deadentry
        XCTAssertEqual(try value.toXdrJson(), "\"deadentry\"",
                       "BucketEntryTypeXDR.deadentry must render as deadentry")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "BucketEntryTypeXDR.deadentry must keep its XDR value")
        XCTAssertEqual(try BucketEntryTypeXDR.fromXdrJson("\"deadentry\""), value,
                       "deadentry must read back as BucketEntryTypeXDR.deadentry")
    }

    func test_BucketEntryTypeXDR_INITENTRY() throws {
        let value: BucketEntryTypeXDR = .initentry
        XCTAssertEqual(try value.toXdrJson(), "\"initentry\"",
                       "BucketEntryTypeXDR.initentry must render as initentry")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "BucketEntryTypeXDR.initentry must keep its XDR value")
        XCTAssertEqual(try BucketEntryTypeXDR.fromXdrJson("\"initentry\""), value,
                       "initentry must read back as BucketEntryTypeXDR.initentry")
    }

    func test_BucketEntryTypeXDR_LIVEENTRY() throws {
        let value: BucketEntryTypeXDR = .liveentry
        XCTAssertEqual(try value.toXdrJson(), "\"liveentry\"",
                       "BucketEntryTypeXDR.liveentry must render as liveentry")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "BucketEntryTypeXDR.liveentry must keep its XDR value")
        XCTAssertEqual(try BucketEntryTypeXDR.fromXdrJson("\"liveentry\""), value,
                       "liveentry must read back as BucketEntryTypeXDR.liveentry")
    }

    func test_BucketEntryTypeXDR_METAENTRY() throws {
        let value: BucketEntryTypeXDR = .metaentry
        XCTAssertEqual(try value.toXdrJson(), "\"metaentry\"",
                       "BucketEntryTypeXDR.metaentry must render as metaentry")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "BucketEntryTypeXDR.metaentry must keep its XDR value")
        XCTAssertEqual(try BucketEntryTypeXDR.fromXdrJson("\"metaentry\""), value,
                       "metaentry must read back as BucketEntryTypeXDR.metaentry")
    }

    func test_BucketEntryTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try BucketEntryTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("BucketEntryTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "BucketEntryTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_BucketEntryXDR_deadEntry_rejectsBareString() throws {
        XCTAssertThrowsError(try BucketEntryXDR.fromXdrJson("\"deadentry\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("BucketEntryXDR.deadentry: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "BucketEntryXDR")
            XCTAssertEqual(key, "deadentry",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_BucketEntryXDR_deadEntry_roundTrip() throws {
        let original: BucketEntryXDR = .deadEntry(.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BucketEntryXDR.fromXdrJson(json)
        let viaValue = try BucketEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try BucketEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BucketEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BucketEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BucketEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BucketEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BucketEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_BucketEntryXDR_initentry_rejectsBareString() throws {
        XCTAssertThrowsError(try BucketEntryXDR.fromXdrJson("\"initentry\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("BucketEntryXDR.initentry: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "BucketEntryXDR")
            XCTAssertEqual(key, "initentry",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_BucketEntryXDR_initentry_roundTrip() throws {
        let original: BucketEntryXDR = .initentry(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BucketEntryXDR.fromXdrJson(json)
        let viaValue = try BucketEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try BucketEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BucketEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BucketEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BucketEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BucketEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BucketEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_BucketEntryXDR_liveentry_rejectsBareString() throws {
        XCTAssertThrowsError(try BucketEntryXDR.fromXdrJson("\"liveentry\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("BucketEntryXDR.liveentry: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "BucketEntryXDR")
            XCTAssertEqual(key, "liveentry",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_BucketEntryXDR_liveentry_roundTrip() throws {
        let original: BucketEntryXDR = .liveentry(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BucketEntryXDR.fromXdrJson(json)
        let viaValue = try BucketEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try BucketEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BucketEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BucketEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BucketEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BucketEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BucketEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_BucketEntryXDR_metaEntry_rejectsBareString() throws {
        XCTAssertThrowsError(try BucketEntryXDR.fromXdrJson("\"metaentry\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("BucketEntryXDR.metaentry: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "BucketEntryXDR")
            XCTAssertEqual(key, "metaentry",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_BucketEntryXDR_metaEntry_roundTrip() throws {
        let original: BucketEntryXDR = .metaEntry(BucketMetadataXDR(ledgerVersion: UInt32(42), ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BucketEntryXDR.fromXdrJson(json)
        let viaValue = try BucketEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try BucketEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BucketEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BucketEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BucketEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BucketEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BucketEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_BucketEntryXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try BucketEntryXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("BucketEntryXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "BucketEntryXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_BucketListTypeXDR_HOT_ARCHIVE() throws {
        let value: BucketListTypeXDR = .hotArchive
        XCTAssertEqual(try value.toXdrJson(), "\"hot_archive\"",
                       "BucketListTypeXDR.hotArchive must render as hot_archive")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "BucketListTypeXDR.hotArchive must keep its XDR value")
        XCTAssertEqual(try BucketListTypeXDR.fromXdrJson("\"hot_archive\""), value,
                       "hot_archive must read back as BucketListTypeXDR.hotArchive")
    }

    func test_BucketListTypeXDR_LIVE() throws {
        let value: BucketListTypeXDR = .live
        XCTAssertEqual(try value.toXdrJson(), "\"live\"",
                       "BucketListTypeXDR.live must render as live")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "BucketListTypeXDR.live must keep its XDR value")
        XCTAssertEqual(try BucketListTypeXDR.fromXdrJson("\"live\""), value,
                       "live must read back as BucketListTypeXDR.live")
    }

    func test_BucketListTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try BucketListTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("BucketListTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "BucketListTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_BucketMetadataXDRExtXDR_bucketListType_rejectsBareString() throws {
        XCTAssertThrowsError(try BucketMetadataXDRExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("BucketMetadataXDRExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "BucketMetadataXDRExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_BucketMetadataXDRExtXDR_bucketListType_roundTrip() throws {
        let original: BucketMetadataXDRExtXDR = .bucketListType(.live)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BucketMetadataXDRExtXDR.fromXdrJson(json)
        let viaValue = try BucketMetadataXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try BucketMetadataXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BucketMetadataXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BucketMetadataXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BucketMetadataXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BucketMetadataXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BucketMetadataXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_BucketMetadataXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try BucketMetadataXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("BucketMetadataXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "BucketMetadataXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_BucketMetadataXDRExtXDR_void_roundTrip() throws {
        let original: BucketMetadataXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BucketMetadataXDRExtXDR.fromXdrJson(json)
        let viaValue = try BucketMetadataXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try BucketMetadataXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BucketMetadataXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BucketMetadataXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BucketMetadataXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BucketMetadataXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BucketMetadataXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_BucketMetadataXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try BucketMetadataXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "BucketMetadataXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_BucketMetadataXDR_roundTrip() throws {
        let original: BucketMetadataXDR = BucketMetadataXDR(ledgerVersion: UInt32(42), ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BucketMetadataXDR.fromXdrJson(json)
        let viaValue = try BucketMetadataXDR.fromXdrJsonValue(tree)
        let viaTree = try BucketMetadataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BucketMetadataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BucketMetadataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BucketMetadataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BucketMetadataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BucketMetadataXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_AND() throws {
        let value: ClaimPredicateType = .claimPredicateAnd
        XCTAssertEqual(try value.toXdrJson(), "\"and\"",
                       "ClaimPredicateType.claimPredicateAnd must render as and")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ClaimPredicateType.claimPredicateAnd must keep its XDR value")
        XCTAssertEqual(try ClaimPredicateType.fromXdrJson("\"and\""), value,
                       "and must read back as ClaimPredicateType.claimPredicateAnd")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME() throws {
        let value: ClaimPredicateType = .claimPredicateBeforeAbsTime
        XCTAssertEqual(try value.toXdrJson(), "\"before_absolute_time\"",
                       "ClaimPredicateType.claimPredicateBeforeAbsTime must render as before_absolute_time")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "ClaimPredicateType.claimPredicateBeforeAbsTime must keep its XDR value")
        XCTAssertEqual(try ClaimPredicateType.fromXdrJson("\"before_absolute_time\""), value,
                       "before_absolute_time must read back as ClaimPredicateType.claimPredicateBeforeAbsTime")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_BEFORE_RELATIVE_TIME() throws {
        let value: ClaimPredicateType = .claimPredicateBeforeRelTime
        XCTAssertEqual(try value.toXdrJson(), "\"before_relative_time\"",
                       "ClaimPredicateType.claimPredicateBeforeRelTime must render as before_relative_time")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "ClaimPredicateType.claimPredicateBeforeRelTime must keep its XDR value")
        XCTAssertEqual(try ClaimPredicateType.fromXdrJson("\"before_relative_time\""), value,
                       "before_relative_time must read back as ClaimPredicateType.claimPredicateBeforeRelTime")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_NOT() throws {
        let value: ClaimPredicateType = .claimPredicateNot
        XCTAssertEqual(try value.toXdrJson(), "\"not\"",
                       "ClaimPredicateType.claimPredicateNot must render as not")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "ClaimPredicateType.claimPredicateNot must keep its XDR value")
        XCTAssertEqual(try ClaimPredicateType.fromXdrJson("\"not\""), value,
                       "not must read back as ClaimPredicateType.claimPredicateNot")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_OR() throws {
        let value: ClaimPredicateType = .claimPredicateOr
        XCTAssertEqual(try value.toXdrJson(), "\"or\"",
                       "ClaimPredicateType.claimPredicateOr must render as or")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ClaimPredicateType.claimPredicateOr must keep its XDR value")
        XCTAssertEqual(try ClaimPredicateType.fromXdrJson("\"or\""), value,
                       "or must read back as ClaimPredicateType.claimPredicateOr")
    }

    func test_ClaimPredicateType_CLAIM_PREDICATE_UNCONDITIONAL() throws {
        let value: ClaimPredicateType = .claimPredicateUnconditional
        XCTAssertEqual(try value.toXdrJson(), "\"unconditional\"",
                       "ClaimPredicateType.claimPredicateUnconditional must render as unconditional")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ClaimPredicateType.claimPredicateUnconditional must keep its XDR value")
        XCTAssertEqual(try ClaimPredicateType.fromXdrJson("\"unconditional\""), value,
                       "unconditional must read back as ClaimPredicateType.claimPredicateUnconditional")
    }

    func test_ClaimPredicateType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClaimPredicateType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClaimPredicateType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimPredicateType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClaimPredicateXDR_claimPredicateAnd_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimPredicateXDR.fromXdrJson("\"and\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimPredicateXDR.and: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimPredicateXDR")
            XCTAssertEqual(key, "and",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimPredicateXDR_claimPredicateAnd_roundTrip() throws {
        let original: ClaimPredicateXDR = .claimPredicateAnd([.claimPredicateUnconditional])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimPredicateXDR.fromXdrJson(json)
        let viaValue = try ClaimPredicateXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimPredicateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimPredicateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimPredicateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimPredicateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimPredicateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimPredicateXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimPredicateXDR_claimPredicateBeforeAbsTime_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimPredicateXDR.fromXdrJson("\"before_absolute_time\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimPredicateXDR.before_absolute_time: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimPredicateXDR")
            XCTAssertEqual(key, "before_absolute_time",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimPredicateXDR_claimPredicateBeforeAbsTime_roundTrip() throws {
        let original: ClaimPredicateXDR = .claimPredicateBeforeAbsTime(Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimPredicateXDR.fromXdrJson(json)
        let viaValue = try ClaimPredicateXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimPredicateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimPredicateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimPredicateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimPredicateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimPredicateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimPredicateXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimPredicateXDR_claimPredicateBeforeRelTime_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimPredicateXDR.fromXdrJson("\"before_relative_time\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimPredicateXDR.before_relative_time: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimPredicateXDR")
            XCTAssertEqual(key, "before_relative_time",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimPredicateXDR_claimPredicateBeforeRelTime_roundTrip() throws {
        let original: ClaimPredicateXDR = .claimPredicateBeforeRelTime(Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimPredicateXDR.fromXdrJson(json)
        let viaValue = try ClaimPredicateXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimPredicateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimPredicateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimPredicateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimPredicateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimPredicateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimPredicateXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimPredicateXDR_claimPredicateNot_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimPredicateXDR.fromXdrJson("\"not\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimPredicateXDR.not: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimPredicateXDR")
            XCTAssertEqual(key, "not",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimPredicateXDR_claimPredicateNot_roundTrip() throws {
        let original: ClaimPredicateXDR = .claimPredicateNot(.claimPredicateUnconditional)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimPredicateXDR.fromXdrJson(json)
        let viaValue = try ClaimPredicateXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimPredicateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimPredicateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimPredicateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimPredicateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimPredicateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimPredicateXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimPredicateXDR_claimPredicateOr_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimPredicateXDR.fromXdrJson("\"or\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimPredicateXDR.or: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimPredicateXDR")
            XCTAssertEqual(key, "or",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimPredicateXDR_claimPredicateOr_roundTrip() throws {
        let original: ClaimPredicateXDR = .claimPredicateOr([.claimPredicateUnconditional])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimPredicateXDR.fromXdrJson(json)
        let viaValue = try ClaimPredicateXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimPredicateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimPredicateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimPredicateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimPredicateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimPredicateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimPredicateXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimPredicateXDR_claimPredicateUnconditional_roundTrip() throws {
        let original: ClaimPredicateXDR = .claimPredicateUnconditional
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimPredicateXDR.fromXdrJson(json)
        let viaValue = try ClaimPredicateXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimPredicateXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimPredicateXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimPredicateXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimPredicateXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimPredicateXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimPredicateXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimPredicateXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClaimPredicateXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClaimPredicateXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClaimPredicateXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ClaimableBalanceEntryExtXDR_claimableBalanceEntryExtensionV1_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimableBalanceEntryExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimableBalanceEntryExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimableBalanceEntryExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimableBalanceEntryExtXDR_claimableBalanceEntryExtensionV1_roundTrip() throws {
        let original: ClaimableBalanceEntryExtXDR = .claimableBalanceEntryExtensionV1(ClaimableBalanceEntryExtensionV1(flags: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimableBalanceEntryExtXDR.fromXdrJson(json)
        let viaValue = try ClaimableBalanceEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimableBalanceEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimableBalanceEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimableBalanceEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimableBalanceEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimableBalanceEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimableBalanceEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimableBalanceEntryExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClaimableBalanceEntryExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClaimableBalanceEntryExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClaimableBalanceEntryExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ClaimableBalanceEntryExtXDR_void_roundTrip() throws {
        let original: ClaimableBalanceEntryExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimableBalanceEntryExtXDR.fromXdrJson(json)
        let viaValue = try ClaimableBalanceEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimableBalanceEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimableBalanceEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimableBalanceEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimableBalanceEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimableBalanceEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimableBalanceEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimableBalanceEntryExtensionV1ExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClaimableBalanceEntryExtensionV1ExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClaimableBalanceEntryExtensionV1ExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClaimableBalanceEntryExtensionV1ExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ClaimableBalanceEntryExtensionV1ExtXDR_void_roundTrip() throws {
        let original: ClaimableBalanceEntryExtensionV1ExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimableBalanceEntryExtensionV1ExtXDR.fromXdrJson(json)
        let viaValue = try ClaimableBalanceEntryExtensionV1ExtXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimableBalanceEntryExtensionV1ExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimableBalanceEntryExtensionV1ExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimableBalanceEntryExtensionV1ExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimableBalanceEntryExtensionV1ExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimableBalanceEntryExtensionV1ExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimableBalanceEntryExtensionV1ExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimableBalanceEntryExtensionV1_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimableBalanceEntryExtensionV1.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimableBalanceEntryExtensionV1 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClaimableBalanceEntryExtensionV1_roundTrip() throws {
        let original: ClaimableBalanceEntryExtensionV1 = ClaimableBalanceEntryExtensionV1(flags: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimableBalanceEntryExtensionV1.fromXdrJson(json)
        let viaValue = try ClaimableBalanceEntryExtensionV1.fromXdrJsonValue(tree)
        let viaTree = try ClaimableBalanceEntryExtensionV1.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimableBalanceEntryExtensionV1 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimableBalanceEntryExtensionV1 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimableBalanceEntryExtensionV1 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimableBalanceEntryExtensionV1 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimableBalanceEntryExtensionV1 must reach the same bytes through JSON and XDR")
    }

    func test_ClaimableBalanceEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimableBalanceEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimableBalanceEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClaimableBalanceEntryXDR_roundTrip() throws {
        let original: ClaimableBalanceEntryXDR = ClaimableBalanceEntryXDR(claimableBalanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))), claimants: [.claimantTypeV0(ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional))], asset: .native, amount: Int64(1234567), ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimableBalanceEntryXDR.fromXdrJson(json)
        let viaValue = try ClaimableBalanceEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimableBalanceEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimableBalanceEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimableBalanceEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimableBalanceEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimableBalanceEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimableBalanceEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimableBalanceFlags_CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG() throws {
        let value: ClaimableBalanceFlags = .claimableBalanceClawbackEnabledFlag
        XCTAssertEqual(try value.toXdrJson(), "\"claimable_balance_clawback_enabled_flag\"",
                       "ClaimableBalanceFlags.claimableBalanceClawbackEnabledFlag must render as claimable_balance_clawback_enabled_flag")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ClaimableBalanceFlags.claimableBalanceClawbackEnabledFlag must keep its XDR value")
        XCTAssertEqual(try ClaimableBalanceFlags.fromXdrJson("\"claimable_balance_clawback_enabled_flag\""), value,
                       "claimable_balance_clawback_enabled_flag must read back as ClaimableBalanceFlags.claimableBalanceClawbackEnabledFlag")
    }

    func test_ClaimableBalanceFlags_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClaimableBalanceFlags.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClaimableBalanceFlags: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimableBalanceFlags")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClaimantType_CLAIMANT_TYPE_V0() throws {
        let value: ClaimantType = .claimantTypeV0
        XCTAssertEqual(try value.toXdrJson(), "\"claimant_type_v0\"",
                       "ClaimantType.claimantTypeV0 must render as claimant_type_v0")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ClaimantType.claimantTypeV0 must keep its XDR value")
        XCTAssertEqual(try ClaimantType.fromXdrJson("\"claimant_type_v0\""), value,
                       "claimant_type_v0 must read back as ClaimantType.claimantTypeV0")
    }

    func test_ClaimantType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClaimantType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClaimantType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimantType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClaimantV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimantV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimantV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClaimantV0XDR_roundTrip() throws {
        let original: ClaimantV0XDR = ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimantV0XDR.fromXdrJson(json)
        let viaValue = try ClaimantV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimantV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimantV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimantV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimantV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimantV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimantV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimantXDR_claimantTypeV0_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimantXDR.fromXdrJson("\"claimant_type_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimantXDR.claimant_type_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimantXDR")
            XCTAssertEqual(key, "claimant_type_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimantXDR_claimantTypeV0_roundTrip() throws {
        let original: ClaimantXDR = .claimantTypeV0(ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimantXDR.fromXdrJson(json)
        let viaValue = try ClaimantXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimantXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimantXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimantXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimantXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimantXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimantXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimantXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClaimantXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClaimantXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClaimantXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ConstantProductXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ConstantProductXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ConstantProductXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ConstantProductXDR_roundTrip() throws {
        let original: ConstantProductXDR = ConstantProductXDR(params: LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: Int32(42)), reserveA: Int64(1234567), reserveB: Int64(1234567), totalPoolShares: Int64(1234567), poolSharesTrustLineCount: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ConstantProductXDR.fromXdrJson(json)
        let viaValue = try ConstantProductXDR.fromXdrJsonValue(tree)
        let viaTree = try ConstantProductXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ConstantProductXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ConstantProductXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ConstantProductXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ConstantProductXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ConstantProductXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractCodeCostInputsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractCodeCostInputsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractCodeCostInputsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractCodeCostInputsXDR_roundTrip() throws {
        let original: ContractCodeCostInputsXDR = ContractCodeCostInputsXDR(ext: .void, nInstructions: UInt32(42), nFunctions: UInt32(42), nGlobals: UInt32(42), nTableEntries: UInt32(42), nTypes: UInt32(42), nDataSegments: UInt32(42), nElemSegments: UInt32(42), nImports: UInt32(42), nExports: UInt32(42), nDataSegmentBytes: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractCodeCostInputsXDR.fromXdrJson(json)
        let viaValue = try ContractCodeCostInputsXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractCodeCostInputsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractCodeCostInputsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractCodeCostInputsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractCodeCostInputsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractCodeCostInputsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractCodeCostInputsXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractCodeEntryExtV1_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractCodeEntryExtV1.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractCodeEntryExtV1 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractCodeEntryExtV1_roundTrip() throws {
        let original: ContractCodeEntryExtV1 = ContractCodeEntryExtV1(ext: .void, costInputs: ContractCodeCostInputsXDR(ext: .void, nInstructions: UInt32(42), nFunctions: UInt32(42), nGlobals: UInt32(42), nTableEntries: UInt32(42), nTypes: UInt32(42), nDataSegments: UInt32(42), nElemSegments: UInt32(42), nImports: UInt32(42), nExports: UInt32(42), nDataSegmentBytes: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractCodeEntryExtV1.fromXdrJson(json)
        let viaValue = try ContractCodeEntryExtV1.fromXdrJsonValue(tree)
        let viaTree = try ContractCodeEntryExtV1.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractCodeEntryExtV1 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractCodeEntryExtV1 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractCodeEntryExtV1 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractCodeEntryExtV1 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractCodeEntryExtV1 must reach the same bytes through JSON and XDR")
    }

    func test_ContractCodeEntryExt_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ContractCodeEntryExt.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ContractCodeEntryExt: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ContractCodeEntryExt")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ContractCodeEntryExt_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try ContractCodeEntryExt.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ContractCodeEntryExt.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractCodeEntryExt")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ContractCodeEntryExt_v1_roundTrip() throws {
        let original: ContractCodeEntryExt = .v1(ContractCodeEntryExtV1(ext: .void, costInputs: ContractCodeCostInputsXDR(ext: .void, nInstructions: UInt32(42), nFunctions: UInt32(42), nGlobals: UInt32(42), nTableEntries: UInt32(42), nTypes: UInt32(42), nDataSegments: UInt32(42), nElemSegments: UInt32(42), nImports: UInt32(42), nExports: UInt32(42), nDataSegmentBytes: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractCodeEntryExt.fromXdrJson(json)
        let viaValue = try ContractCodeEntryExt.fromXdrJsonValue(tree)
        let viaTree = try ContractCodeEntryExt.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractCodeEntryExt must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractCodeEntryExt must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractCodeEntryExt must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractCodeEntryExt must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractCodeEntryExt must reach the same bytes through JSON and XDR")
    }

    func test_ContractCodeEntryExt_void_roundTrip() throws {
        let original: ContractCodeEntryExt = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractCodeEntryExt.fromXdrJson(json)
        let viaValue = try ContractCodeEntryExt.fromXdrJsonValue(tree)
        let viaTree = try ContractCodeEntryExt.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractCodeEntryExt must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractCodeEntryExt must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractCodeEntryExt must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractCodeEntryExt must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractCodeEntryExt must reach the same bytes through JSON and XDR")
    }

    func test_ContractCodeEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractCodeEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractCodeEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractCodeEntryXDR_roundTrip() throws {
        let original: ContractCodeEntryXDR = ContractCodeEntryXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), code: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractCodeEntryXDR.fromXdrJson(json)
        let viaValue = try ContractCodeEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractCodeEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractCodeEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractCodeEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractCodeEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractCodeEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractCodeEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractDataDurability_PERSISTENT() throws {
        let value: ContractDataDurability = .persistent
        XCTAssertEqual(try value.toXdrJson(), "\"persistent\"",
                       "ContractDataDurability.persistent must render as persistent")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ContractDataDurability.persistent must keep its XDR value")
        XCTAssertEqual(try ContractDataDurability.fromXdrJson("\"persistent\""), value,
                       "persistent must read back as ContractDataDurability.persistent")
    }

    func test_ContractDataDurability_TEMPORARY() throws {
        let value: ContractDataDurability = .temporary
        XCTAssertEqual(try value.toXdrJson(), "\"temporary\"",
                       "ContractDataDurability.temporary must render as temporary")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ContractDataDurability.temporary must keep its XDR value")
        XCTAssertEqual(try ContractDataDurability.fromXdrJson("\"temporary\""), value,
                       "temporary must read back as ContractDataDurability.temporary")
    }

    func test_ContractDataDurability_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ContractDataDurability.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ContractDataDurability: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractDataDurability")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ContractDataEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractDataEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractDataEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractDataEntryXDR_roundTrip() throws {
        let original: ContractDataEntryXDR = ContractDataEntryXDR(ext: .void, contract: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), key: .void, durability: .temporary, val: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractDataEntryXDR.fromXdrJson(json)
        let viaValue = try ContractDataEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractDataEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractDataEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractDataEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractDataEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractDataEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractDataEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_DataEntryXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try DataEntryXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("DataEntryXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "DataEntryXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_DataEntryXDRExtXDR_void_roundTrip() throws {
        let original: DataEntryXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try DataEntryXDRExtXDR.fromXdrJson(json)
        let viaValue = try DataEntryXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try DataEntryXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "DataEntryXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "DataEntryXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "DataEntryXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "DataEntryXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "DataEntryXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_DataEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try DataEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "DataEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_DataEntryXDR_roundTrip() throws {
        let original: DataEntryXDR = DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try DataEntryXDR.fromXdrJson(json)
        let viaValue = try DataEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try DataEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "DataEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "DataEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "DataEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "DataEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "DataEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_DataValueXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try DataValueXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "DataValueXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_DataValueXDR_roundTrip() throws {
        let original: DataValueXDR = Data([0x01, 0x02, 0x03])
        let tree = try DataValueXDRJsonCodec.toXdrJsonValue(original)
        let json = try DataValueXDRJsonCodec.toXdrJson(original)
        let decoded = try DataValueXDRJsonCodec.fromXdrJson(json)
        let viaValue = try DataValueXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try DataValueXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try DataValueXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "DataValueXDR must produce the same tree after a round trip")
        XCTAssertEqual(try DataValueXDRJsonCodec.toXdrJson(decoded), json,
                       "DataValueXDR must produce the same text after a round trip")
        XCTAssertEqual(try DataValueXDRJsonCodec.toXdrJson(viaValue), json,
                       "DataValueXDR must read a tree the same way it reads text")
        XCTAssertEqual(try DataValueXDRJsonCodec.toXdrJson(viaTree), json,
                       "DataValueXDR must read a depth-checked tree the same way")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_AUTH() throws {
        let value: EnvelopeType = .auth
        XCTAssertEqual(try value.toXdrJson(), "\"auth\"",
                       "EnvelopeType.auth must render as auth")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "EnvelopeType.auth must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"auth\""), value,
                       "auth must read back as EnvelopeType.auth")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_CONTRACT_ID() throws {
        let value: EnvelopeType = .contractId
        XCTAssertEqual(try value.toXdrJson(), "\"contract_id\"",
                       "EnvelopeType.contractId must render as contract_id")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "EnvelopeType.contractId must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"contract_id\""), value,
                       "contract_id must read back as EnvelopeType.contractId")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_OP_ID() throws {
        let value: EnvelopeType = .opId
        XCTAssertEqual(try value.toXdrJson(), "\"op_id\"",
                       "EnvelopeType.opId must render as op_id")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "EnvelopeType.opId must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"op_id\""), value,
                       "op_id must read back as EnvelopeType.opId")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_POOL_REVOKE_OP_ID() throws {
        let value: EnvelopeType = .poolRevokeOpId
        XCTAssertEqual(try value.toXdrJson(), "\"pool_revoke_op_id\"",
                       "EnvelopeType.poolRevokeOpId must render as pool_revoke_op_id")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "EnvelopeType.poolRevokeOpId must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"pool_revoke_op_id\""), value,
                       "pool_revoke_op_id must read back as EnvelopeType.poolRevokeOpId")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_SCP() throws {
        let value: EnvelopeType = .scp
        XCTAssertEqual(try value.toXdrJson(), "\"scp\"",
                       "EnvelopeType.scp must render as scp")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "EnvelopeType.scp must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"scp\""), value,
                       "scp must read back as EnvelopeType.scp")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_SCPVALUE() throws {
        let value: EnvelopeType = .scpvalue
        XCTAssertEqual(try value.toXdrJson(), "\"scpvalue\"",
                       "EnvelopeType.scpvalue must render as scpvalue")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "EnvelopeType.scpvalue must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"scpvalue\""), value,
                       "scpvalue must read back as EnvelopeType.scpvalue")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_SOROBAN_AUTHORIZATION() throws {
        let value: EnvelopeType = .sorobanAuthorization
        XCTAssertEqual(try value.toXdrJson(), "\"soroban_authorization\"",
                       "EnvelopeType.sorobanAuthorization must render as soroban_authorization")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "EnvelopeType.sorobanAuthorization must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"soroban_authorization\""), value,
                       "soroban_authorization must read back as EnvelopeType.sorobanAuthorization")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS() throws {
        let value: EnvelopeType = .sorobanAuthorizationWithAddress
        XCTAssertEqual(try value.toXdrJson(), "\"soroban_authorization_with_address\"",
                       "EnvelopeType.sorobanAuthorizationWithAddress must render as soroban_authorization_with_address")
        XCTAssertEqual(value.rawValue, Int32(10),
                       "EnvelopeType.sorobanAuthorizationWithAddress must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"soroban_authorization_with_address\""), value,
                       "soroban_authorization_with_address must read back as EnvelopeType.sorobanAuthorizationWithAddress")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_TX() throws {
        let value: EnvelopeType = .tx
        XCTAssertEqual(try value.toXdrJson(), "\"tx\"",
                       "EnvelopeType.tx must render as tx")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "EnvelopeType.tx must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"tx\""), value,
                       "tx must read back as EnvelopeType.tx")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_TX_FEE_BUMP() throws {
        let value: EnvelopeType = .txFeeBump
        XCTAssertEqual(try value.toXdrJson(), "\"tx_fee_bump\"",
                       "EnvelopeType.txFeeBump must render as tx_fee_bump")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "EnvelopeType.txFeeBump must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"tx_fee_bump\""), value,
                       "tx_fee_bump must read back as EnvelopeType.txFeeBump")
    }

    func test_EnvelopeType_ENVELOPE_TYPE_TX_V0() throws {
        let value: EnvelopeType = .txV0
        XCTAssertEqual(try value.toXdrJson(), "\"tx_v0\"",
                       "EnvelopeType.txV0 must render as tx_v0")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "EnvelopeType.txV0 must keep its XDR value")
        XCTAssertEqual(try EnvelopeType.fromXdrJson("\"tx_v0\""), value,
                       "tx_v0 must read back as EnvelopeType.txV0")
    }

    func test_EnvelopeType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try EnvelopeType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("EnvelopeType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "EnvelopeType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_HotArchiveBucketEntryTypeXDR_HOT_ARCHIVE_ARCHIVED() throws {
        let value: HotArchiveBucketEntryTypeXDR = .archived
        XCTAssertEqual(try value.toXdrJson(), "\"archived\"",
                       "HotArchiveBucketEntryTypeXDR.archived must render as archived")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "HotArchiveBucketEntryTypeXDR.archived must keep its XDR value")
        XCTAssertEqual(try HotArchiveBucketEntryTypeXDR.fromXdrJson("\"archived\""), value,
                       "archived must read back as HotArchiveBucketEntryTypeXDR.archived")
    }

    func test_HotArchiveBucketEntryTypeXDR_HOT_ARCHIVE_LIVE() throws {
        let value: HotArchiveBucketEntryTypeXDR = .live
        XCTAssertEqual(try value.toXdrJson(), "\"live\"",
                       "HotArchiveBucketEntryTypeXDR.live must render as live")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "HotArchiveBucketEntryTypeXDR.live must keep its XDR value")
        XCTAssertEqual(try HotArchiveBucketEntryTypeXDR.fromXdrJson("\"live\""), value,
                       "live must read back as HotArchiveBucketEntryTypeXDR.live")
    }

    func test_HotArchiveBucketEntryTypeXDR_HOT_ARCHIVE_METAENTRY() throws {
        let value: HotArchiveBucketEntryTypeXDR = .metaentry
        XCTAssertEqual(try value.toXdrJson(), "\"metaentry\"",
                       "HotArchiveBucketEntryTypeXDR.metaentry must render as metaentry")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "HotArchiveBucketEntryTypeXDR.metaentry must keep its XDR value")
        XCTAssertEqual(try HotArchiveBucketEntryTypeXDR.fromXdrJson("\"metaentry\""), value,
                       "metaentry must read back as HotArchiveBucketEntryTypeXDR.metaentry")
    }

    func test_HotArchiveBucketEntryTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try HotArchiveBucketEntryTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("HotArchiveBucketEntryTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "HotArchiveBucketEntryTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_HotArchiveBucketEntryXDR_archivedEntry_rejectsBareString() throws {
        XCTAssertThrowsError(try HotArchiveBucketEntryXDR.fromXdrJson("\"archived\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HotArchiveBucketEntryXDR.archived: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HotArchiveBucketEntryXDR")
            XCTAssertEqual(key, "archived",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HotArchiveBucketEntryXDR_archivedEntry_roundTrip() throws {
        let original: HotArchiveBucketEntryXDR = .archivedEntry(LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [], ext: .void)), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HotArchiveBucketEntryXDR.fromXdrJson(json)
        let viaValue = try HotArchiveBucketEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try HotArchiveBucketEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HotArchiveBucketEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HotArchiveBucketEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_HotArchiveBucketEntryXDR_key_rejectsBareString() throws {
        XCTAssertThrowsError(try HotArchiveBucketEntryXDR.fromXdrJson("\"live\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HotArchiveBucketEntryXDR.live: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HotArchiveBucketEntryXDR")
            XCTAssertEqual(key, "live",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HotArchiveBucketEntryXDR_key_roundTrip() throws {
        let original: HotArchiveBucketEntryXDR = .key(.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HotArchiveBucketEntryXDR.fromXdrJson(json)
        let viaValue = try HotArchiveBucketEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try HotArchiveBucketEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HotArchiveBucketEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HotArchiveBucketEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_HotArchiveBucketEntryXDR_metaEntry_rejectsBareString() throws {
        XCTAssertThrowsError(try HotArchiveBucketEntryXDR.fromXdrJson("\"metaentry\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HotArchiveBucketEntryXDR.metaentry: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HotArchiveBucketEntryXDR")
            XCTAssertEqual(key, "metaentry",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HotArchiveBucketEntryXDR_metaEntry_roundTrip() throws {
        let original: HotArchiveBucketEntryXDR = .metaEntry(BucketMetadataXDR(ledgerVersion: UInt32(42), ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HotArchiveBucketEntryXDR.fromXdrJson(json)
        let viaValue = try HotArchiveBucketEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try HotArchiveBucketEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HotArchiveBucketEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HotArchiveBucketEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HotArchiveBucketEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_HotArchiveBucketEntryXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try HotArchiveBucketEntryXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("HotArchiveBucketEntryXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "HotArchiveBucketEntryXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerEntryDataXDR_account_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"account\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.account: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "account",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_account_roundTrip() throws {
        let original: LedgerEntryDataXDR = .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))), weight: UInt32(42))], ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_claimableBalance_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_claimableBalance_roundTrip() throws {
        let original: LedgerEntryDataXDR = .claimableBalance(ClaimableBalanceEntryXDR(claimableBalanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))), claimants: [.claimantTypeV0(ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional))], asset: .native, amount: Int64(1234567), ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_configSetting_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"config_setting\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.config_setting: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "config_setting",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_configSetting_roundTrip() throws {
        let original: LedgerEntryDataXDR = .configSetting(.contractMaxSizeBytes(UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_contractCode_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"contract_code\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.contract_code: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "contract_code",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_contractCode_roundTrip() throws {
        let original: LedgerEntryDataXDR = .contractCode(ContractCodeEntryXDR(ext: .void, hash: WrappedData32(Data(repeating: 0xAB, count: 32)), code: Data([0x01, 0x02, 0x03])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_contractData_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"contract_data\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.contract_data: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "contract_data",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_contractData_roundTrip() throws {
        let original: LedgerEntryDataXDR = .contractData(ContractDataEntryXDR(ext: .void, contract: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), key: .void, durability: .temporary, val: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_data_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"data\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.data: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "data",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_data_roundTrip() throws {
        let original: LedgerEntryDataXDR = .data(DataEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_liquidityPool_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"liquidity_pool\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.liquidity_pool: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "liquidity_pool",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_liquidityPool_roundTrip() throws {
        let original: LedgerEntryDataXDR = .liquidityPool(LiquidityPoolEntryXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), body: .constantProduct(ConstantProductXDR(params: LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: Int32(42)), reserveA: Int64(1234567), reserveB: Int64(1234567), totalPoolShares: Int64(1234567), poolSharesTrustLineCount: Int64(1234567)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_offer_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_offer_roundTrip() throws {
        let original: LedgerEntryDataXDR = .offer(OfferEntryXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: UInt64(1234567), selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42)), flags: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerEntryDataXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerEntryDataXDR_trustline_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"trustline\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.trustline: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "trustline",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_trustline_roundTrip() throws {
        let original: LedgerEntryDataXDR = .trustline(TrustlineEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, balance: Int64(1234567), limit: Int64(1234567), flags: UInt32(42), reserved: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryDataXDR_ttl_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryDataXDR.fromXdrJson("\"ttl\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryDataXDR.ttl: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryDataXDR")
            XCTAssertEqual(key, "ttl",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryDataXDR_ttl_roundTrip() throws {
        let original: LedgerEntryDataXDR = .ttl(TTLEntryXDR(keyHash: WrappedData32(Data(repeating: 0xAB, count: 32)), liveUntilLedgerSeq: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryDataXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryExtXDR_ledgerEntryExtensionV1_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerEntryExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerEntryExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerEntryExtXDR_ledgerEntryExtensionV1_roundTrip() throws {
        let original: LedgerEntryExtXDR = .ledgerEntryExtensionV1(LedgerEntryExtensionV1(signerSponsoringID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryExtXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerEntryExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerEntryExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerEntryExtXDR_void_roundTrip() throws {
        let original: LedgerEntryExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryExtXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryExtensionV1ExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerEntryExtensionV1ExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerEntryExtensionV1ExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryExtensionV1ExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerEntryExtensionV1ExtXDR_void_roundTrip() throws {
        let original: LedgerEntryExtensionV1ExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryExtensionV1ExtXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryExtensionV1ExtXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryExtensionV1ExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryExtensionV1ExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryExtensionV1ExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryExtensionV1ExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryExtensionV1ExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryExtensionV1ExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryExtensionV1_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerEntryExtensionV1.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerEntryExtensionV1 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerEntryExtensionV1_roundTrip() throws {
        let original: LedgerEntryExtensionV1 = LedgerEntryExtensionV1(signerSponsoringID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryExtensionV1.fromXdrJson(json)
        let viaValue = try LedgerEntryExtensionV1.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryExtensionV1.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryExtensionV1 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryExtensionV1 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryExtensionV1 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryExtensionV1 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryExtensionV1 must reach the same bytes through JSON and XDR")
    }

    func test_LedgerEntryType_ACCOUNT() throws {
        let value: LedgerEntryType = .account
        XCTAssertEqual(try value.toXdrJson(), "\"account\"",
                       "LedgerEntryType.account must render as account")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "LedgerEntryType.account must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"account\""), value,
                       "account must read back as LedgerEntryType.account")
    }

    func test_LedgerEntryType_CLAIMABLE_BALANCE() throws {
        let value: LedgerEntryType = .claimableBalance
        XCTAssertEqual(try value.toXdrJson(), "\"claimable_balance\"",
                       "LedgerEntryType.claimableBalance must render as claimable_balance")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "LedgerEntryType.claimableBalance must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"claimable_balance\""), value,
                       "claimable_balance must read back as LedgerEntryType.claimableBalance")
    }

    func test_LedgerEntryType_CONFIG_SETTING() throws {
        let value: LedgerEntryType = .configSetting
        XCTAssertEqual(try value.toXdrJson(), "\"config_setting\"",
                       "LedgerEntryType.configSetting must render as config_setting")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "LedgerEntryType.configSetting must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"config_setting\""), value,
                       "config_setting must read back as LedgerEntryType.configSetting")
    }

    func test_LedgerEntryType_CONTRACT_CODE() throws {
        let value: LedgerEntryType = .contractCode
        XCTAssertEqual(try value.toXdrJson(), "\"contract_code\"",
                       "LedgerEntryType.contractCode must render as contract_code")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "LedgerEntryType.contractCode must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"contract_code\""), value,
                       "contract_code must read back as LedgerEntryType.contractCode")
    }

    func test_LedgerEntryType_CONTRACT_DATA() throws {
        let value: LedgerEntryType = .contractData
        XCTAssertEqual(try value.toXdrJson(), "\"contract_data\"",
                       "LedgerEntryType.contractData must render as contract_data")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "LedgerEntryType.contractData must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"contract_data\""), value,
                       "contract_data must read back as LedgerEntryType.contractData")
    }

    func test_LedgerEntryType_DATA() throws {
        let value: LedgerEntryType = .data
        XCTAssertEqual(try value.toXdrJson(), "\"data\"",
                       "LedgerEntryType.data must render as data")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "LedgerEntryType.data must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"data\""), value,
                       "data must read back as LedgerEntryType.data")
    }

    func test_LedgerEntryType_LIQUIDITY_POOL() throws {
        let value: LedgerEntryType = .liquidityPool
        XCTAssertEqual(try value.toXdrJson(), "\"liquidity_pool\"",
                       "LedgerEntryType.liquidityPool must render as liquidity_pool")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "LedgerEntryType.liquidityPool must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"liquidity_pool\""), value,
                       "liquidity_pool must read back as LedgerEntryType.liquidityPool")
    }

    func test_LedgerEntryType_OFFER() throws {
        let value: LedgerEntryType = .offer
        XCTAssertEqual(try value.toXdrJson(), "\"offer\"",
                       "LedgerEntryType.offer must render as offer")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "LedgerEntryType.offer must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"offer\""), value,
                       "offer must read back as LedgerEntryType.offer")
    }

    func test_LedgerEntryType_TRUSTLINE() throws {
        let value: LedgerEntryType = .trustline
        XCTAssertEqual(try value.toXdrJson(), "\"trustline\"",
                       "LedgerEntryType.trustline must render as trustline")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "LedgerEntryType.trustline must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"trustline\""), value,
                       "trustline must read back as LedgerEntryType.trustline")
    }

    func test_LedgerEntryType_TTL() throws {
        let value: LedgerEntryType = .ttl
        XCTAssertEqual(try value.toXdrJson(), "\"ttl\"",
                       "LedgerEntryType.ttl must render as ttl")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "LedgerEntryType.ttl must keep its XDR value")
        XCTAssertEqual(try LedgerEntryType.fromXdrJson("\"ttl\""), value,
                       "ttl must read back as LedgerEntryType.ttl")
    }

    func test_LedgerEntryType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try LedgerEntryType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("LedgerEntryType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerEntryType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_LedgerEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerEntryXDR_roundTrip() throws {
        let original: LedgerEntryXDR = LedgerEntryXDR(lastModifiedLedgerSeq: UInt32(42), data: .account(AccountEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567), sequenceNumber: Int64(1234567), numSubEntries: UInt32(42), inflationDest: try PublicKey([UInt8](repeating: 0xAB, count: 32)), flags: UInt32(42), homeDomain: "test_string", thresholds: WrappedData4(Data(repeating: 0xAB, count: 4)), signers: [SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))), weight: UInt32(42))], ext: .void)), reserved: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerEntryXDR.fromXdrJson(json)
        let viaValue = try LedgerEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyAccountXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyAccountXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyAccountXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyAccountXDR_roundTrip() throws {
        let original: LedgerKeyAccountXDR = LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyAccountXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyAccountXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyAccountXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyAccountXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyAccountXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyAccountXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyAccountXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyAccountXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyClaimableBalanceXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyClaimableBalanceXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyClaimableBalanceXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyClaimableBalanceXDR_roundTrip() throws {
        let original: LedgerKeyClaimableBalanceXDR = LedgerKeyClaimableBalanceXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyClaimableBalanceXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyClaimableBalanceXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyClaimableBalanceXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyClaimableBalanceXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyClaimableBalanceXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyClaimableBalanceXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyClaimableBalanceXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyClaimableBalanceXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyConfigSettingXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyConfigSettingXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyConfigSettingXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyConfigSettingXDR_roundTrip() throws {
        let original: LedgerKeyConfigSettingXDR = LedgerKeyConfigSettingXDR(configSettingID: Int32(0))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyConfigSettingXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyConfigSettingXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyConfigSettingXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyConfigSettingXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyConfigSettingXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyConfigSettingXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyConfigSettingXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyConfigSettingXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyContractCodeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyContractCodeXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyContractCodeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyContractCodeXDR_roundTrip() throws {
        let original: LedgerKeyContractCodeXDR = LedgerKeyContractCodeXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyContractCodeXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyContractCodeXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyContractCodeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyContractCodeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyContractCodeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyContractCodeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyContractCodeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyContractCodeXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyContractDataXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyContractDataXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyContractDataXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyContractDataXDR_roundTrip() throws {
        let original: LedgerKeyContractDataXDR = LedgerKeyContractDataXDR(contract: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), key: .void, durability: .temporary)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyContractDataXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyContractDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyContractDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyContractDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyContractDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyContractDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyContractDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyContractDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyDataXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyDataXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyDataXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyDataXDR_roundTrip() throws {
        let original: LedgerKeyDataXDR = LedgerKeyDataXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyDataXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyDataXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyLiquidityPoolXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyLiquidityPoolXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyLiquidityPoolXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyLiquidityPoolXDR_roundTrip() throws {
        let original: LedgerKeyLiquidityPoolXDR = LedgerKeyLiquidityPoolXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyLiquidityPoolXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyLiquidityPoolXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyLiquidityPoolXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyLiquidityPoolXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyLiquidityPoolXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyLiquidityPoolXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyLiquidityPoolXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyLiquidityPoolXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyOfferXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyOfferXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyOfferXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyOfferXDR_roundTrip() throws {
        let original: LedgerKeyOfferXDR = LedgerKeyOfferXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyOfferXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyOfferXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyOfferXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyOfferXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyOfferXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyOfferXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyOfferXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyOfferXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyTTLXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyTTLXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyTTLXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyTTLXDR_roundTrip() throws {
        let original: LedgerKeyTTLXDR = LedgerKeyTTLXDR(keyHash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyTTLXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyTTLXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyTTLXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyTTLXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyTTLXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyTTLXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyTTLXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyTTLXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyTrustLineXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerKeyTrustLineXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerKeyTrustLineXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerKeyTrustLineXDR_roundTrip() throws {
        let original: LedgerKeyTrustLineXDR = LedgerKeyTrustLineXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyTrustLineXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyTrustLineXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyTrustLineXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyTrustLineXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyTrustLineXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyTrustLineXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyTrustLineXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyTrustLineXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_account_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"account\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.account: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "account",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_account_roundTrip() throws {
        let original: LedgerKeyXDR = .account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_claimableBalance_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_claimableBalance_roundTrip() throws {
        let original: LedgerKeyXDR = .claimableBalance(LedgerKeyClaimableBalanceXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_configSetting_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"config_setting\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.config_setting: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "config_setting",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_configSetting_roundTrip() throws {
        let original: LedgerKeyXDR = .configSetting(LedgerKeyConfigSettingXDR(configSettingID: Int32(0)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_contractCode_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"contract_code\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.contract_code: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "contract_code",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_contractCode_roundTrip() throws {
        let original: LedgerKeyXDR = .contractCode(LedgerKeyContractCodeXDR(hash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_contractData_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"contract_data\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.contract_data: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "contract_data",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_contractData_roundTrip() throws {
        let original: LedgerKeyXDR = .contractData(LedgerKeyContractDataXDR(contract: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), key: .void, durability: .temporary))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_data_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"data\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.data: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "data",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_data_roundTrip() throws {
        let original: LedgerKeyXDR = .data(LedgerKeyDataXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), dataName: "test_string"))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_liquidityPool_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"liquidity_pool\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.liquidity_pool: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "liquidity_pool",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_liquidityPool_roundTrip() throws {
        let original: LedgerKeyXDR = .liquidityPool(LedgerKeyLiquidityPoolXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_offer_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_offer_roundTrip() throws {
        let original: LedgerKeyXDR = .offer(LedgerKeyOfferXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LedgerKeyXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LedgerKeyXDR_trustline_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"trustline\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.trustline: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "trustline",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_trustline_roundTrip() throws {
        let original: LedgerKeyXDR = .trustline(LedgerKeyTrustLineXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerKeyXDR_ttl_rejectsBareString() throws {
        XCTAssertThrowsError(try LedgerKeyXDR.fromXdrJson("\"ttl\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LedgerKeyXDR.ttl: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LedgerKeyXDR")
            XCTAssertEqual(key, "ttl",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LedgerKeyXDR_ttl_roundTrip() throws {
        let original: LedgerKeyXDR = .ttl(LedgerKeyTTLXDR(keyHash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerKeyXDR.fromXdrJson(json)
        let viaValue = try LedgerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiabilitiesXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LiabilitiesXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LiabilitiesXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LiabilitiesXDR_roundTrip() throws {
        let original: LiabilitiesXDR = LiabilitiesXDR(buying: Int64(1234567), selling: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiabilitiesXDR.fromXdrJson(json)
        let viaValue = try LiabilitiesXDR.fromXdrJsonValue(tree)
        let viaTree = try LiabilitiesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiabilitiesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiabilitiesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiabilitiesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiabilitiesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiabilitiesXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolBodyXDR_constantProduct_rejectsBareString() throws {
        XCTAssertThrowsError(try LiquidityPoolBodyXDR.fromXdrJson("\"liquidity_pool_constant_product\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LiquidityPoolBodyXDR.liquidity_pool_constant_product: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolBodyXDR")
            XCTAssertEqual(key, "liquidity_pool_constant_product",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LiquidityPoolBodyXDR_constantProduct_roundTrip() throws {
        let original: LiquidityPoolBodyXDR = .constantProduct(ConstantProductXDR(params: LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: Int32(42)), reserveA: Int64(1234567), reserveB: Int64(1234567), totalPoolShares: Int64(1234567), poolSharesTrustLineCount: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolBodyXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolBodyXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LiquidityPoolBodyXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LiquidityPoolBodyXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolBodyXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LiquidityPoolConstantProductParametersXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LiquidityPoolConstantProductParametersXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LiquidityPoolConstantProductParametersXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LiquidityPoolConstantProductParametersXDR_roundTrip() throws {
        let original: LiquidityPoolConstantProductParametersXDR = LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: Int32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolConstantProductParametersXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolConstantProductParametersXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolConstantProductParametersXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolConstantProductParametersXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolConstantProductParametersXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolConstantProductParametersXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolConstantProductParametersXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolConstantProductParametersXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LiquidityPoolEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LiquidityPoolEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LiquidityPoolEntryXDR_roundTrip() throws {
        let original: LiquidityPoolEntryXDR = LiquidityPoolEntryXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), body: .constantProduct(ConstantProductXDR(params: LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: Int32(42)), reserveA: Int64(1234567), reserveB: Int64(1234567), totalPoolShares: Int64(1234567), poolSharesTrustLineCount: Int64(1234567))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolEntryXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolType_LIQUIDITY_POOL_CONSTANT_PRODUCT() throws {
        let value: LiquidityPoolType = .constantProduct
        XCTAssertEqual(try value.toXdrJson(), "\"liquidity_pool_constant_product\"",
                       "LiquidityPoolType.constantProduct must render as liquidity_pool_constant_product")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "LiquidityPoolType.constantProduct must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolType.fromXdrJson("\"liquidity_pool_constant_product\""), value,
                       "liquidity_pool_constant_product must read back as LiquidityPoolType.constantProduct")
    }

    func test_LiquidityPoolType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try LiquidityPoolType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("LiquidityPoolType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_OfferEntryFlagsXDR_PASSIVE_FLAG() throws {
        let value: OfferEntryFlagsXDR = .passiveFlag
        XCTAssertEqual(try value.toXdrJson(), "\"passive_flag\"",
                       "OfferEntryFlagsXDR.passiveFlag must render as passive_flag")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "OfferEntryFlagsXDR.passiveFlag must keep its XDR value")
        XCTAssertEqual(try OfferEntryFlagsXDR.fromXdrJson("\"passive_flag\""), value,
                       "passive_flag must read back as OfferEntryFlagsXDR.passiveFlag")
    }

    func test_OfferEntryFlagsXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try OfferEntryFlagsXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("OfferEntryFlagsXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "OfferEntryFlagsXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_OfferEntryXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try OfferEntryXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("OfferEntryXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "OfferEntryXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_OfferEntryXDRExtXDR_void_roundTrip() throws {
        let original: OfferEntryXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OfferEntryXDRExtXDR.fromXdrJson(json)
        let viaValue = try OfferEntryXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try OfferEntryXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OfferEntryXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OfferEntryXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OfferEntryXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OfferEntryXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OfferEntryXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_OfferEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try OfferEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "OfferEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_OfferEntryXDR_roundTrip() throws {
        let original: OfferEntryXDR = OfferEntryXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: UInt64(1234567), selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42)), flags: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OfferEntryXDR.fromXdrJson(json)
        let viaValue = try OfferEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try OfferEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OfferEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OfferEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OfferEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OfferEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OfferEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_PriceXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PriceXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PriceXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PriceXDR_roundTrip() throws {
        let original: PriceXDR = PriceXDR(n: Int32(42), d: Int32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PriceXDR.fromXdrJson(json)
        let viaValue = try PriceXDR.fromXdrJsonValue(tree)
        let viaTree = try PriceXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PriceXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PriceXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PriceXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PriceXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PriceXDR must reach the same bytes through JSON and XDR")
    }

    func test_SequenceNumberXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SequenceNumberXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SequenceNumberXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SequenceNumberXDR_roundTrip() throws {
        let original: SequenceNumberXDR = Int64(1234567)
        let tree = try SequenceNumberXDRJsonCodec.toXdrJsonValue(original)
        let json = try SequenceNumberXDRJsonCodec.toXdrJson(original)
        let decoded = try SequenceNumberXDRJsonCodec.fromXdrJson(json)
        let viaValue = try SequenceNumberXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try SequenceNumberXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try SequenceNumberXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "SequenceNumberXDR must produce the same tree after a round trip")
        XCTAssertEqual(try SequenceNumberXDRJsonCodec.toXdrJson(decoded), json,
                       "SequenceNumberXDR must produce the same text after a round trip")
        XCTAssertEqual(try SequenceNumberXDRJsonCodec.toXdrJson(viaValue), json,
                       "SequenceNumberXDR must read a tree the same way it reads text")
        XCTAssertEqual(try SequenceNumberXDRJsonCodec.toXdrJson(viaTree), json,
                       "SequenceNumberXDR must read a depth-checked tree the same way")
    }

    func test_SignerXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignerXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignerXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignerXDR_roundTrip() throws {
        let original: SignerXDR = SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))), weight: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignerXDR.fromXdrJson(json)
        let viaValue = try SignerXDR.fromXdrJsonValue(tree)
        let viaTree = try SignerXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignerXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignerXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignerXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignerXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignerXDR must reach the same bytes through JSON and XDR")
    }

    func test_SponsorshipDescriptorXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SponsorshipDescriptorXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SponsorshipDescriptorXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SponsorshipDescriptorXDR_roundTrip() throws {
        let original: SponsorshipDescriptorXDR = try PublicKey([UInt8](repeating: 0xAB, count: 32))
        let tree = try SponsorshipDescriptorXDRJsonCodec.toXdrJsonValue(original)
        let json = try SponsorshipDescriptorXDRJsonCodec.toXdrJson(original)
        let decoded = try SponsorshipDescriptorXDRJsonCodec.fromXdrJson(json)
        let viaValue = try SponsorshipDescriptorXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try SponsorshipDescriptorXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try SponsorshipDescriptorXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "SponsorshipDescriptorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try SponsorshipDescriptorXDRJsonCodec.toXdrJson(decoded), json,
                       "SponsorshipDescriptorXDR must produce the same text after a round trip")
        XCTAssertEqual(try SponsorshipDescriptorXDRJsonCodec.toXdrJson(viaValue), json,
                       "SponsorshipDescriptorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try SponsorshipDescriptorXDRJsonCodec.toXdrJson(viaTree), json,
                       "SponsorshipDescriptorXDR must read a depth-checked tree the same way")
    }

    func test_String32XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try String32XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "String32XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_String32XDR_roundTrip() throws {
        let original: String32XDR = "test_string"
        let tree = try String32XDRJsonCodec.toXdrJsonValue(original)
        let json = try String32XDRJsonCodec.toXdrJson(original)
        let decoded = try String32XDRJsonCodec.fromXdrJson(json)
        let viaValue = try String32XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try String32XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try String32XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "String32XDR must produce the same tree after a round trip")
        XCTAssertEqual(try String32XDRJsonCodec.toXdrJson(decoded), json,
                       "String32XDR must produce the same text after a round trip")
        XCTAssertEqual(try String32XDRJsonCodec.toXdrJson(viaValue), json,
                       "String32XDR must read a tree the same way it reads text")
        XCTAssertEqual(try String32XDRJsonCodec.toXdrJson(viaTree), json,
                       "String32XDR must read a depth-checked tree the same way")
    }

    func test_String64XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try String64XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "String64XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_String64XDR_roundTrip() throws {
        let original: String64XDR = "test_string"
        let tree = try String64XDRJsonCodec.toXdrJsonValue(original)
        let json = try String64XDRJsonCodec.toXdrJson(original)
        let decoded = try String64XDRJsonCodec.fromXdrJson(json)
        let viaValue = try String64XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try String64XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try String64XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "String64XDR must produce the same tree after a round trip")
        XCTAssertEqual(try String64XDRJsonCodec.toXdrJson(decoded), json,
                       "String64XDR must produce the same text after a round trip")
        XCTAssertEqual(try String64XDRJsonCodec.toXdrJson(viaValue), json,
                       "String64XDR must read a tree the same way it reads text")
        XCTAssertEqual(try String64XDRJsonCodec.toXdrJson(viaTree), json,
                       "String64XDR must read a depth-checked tree the same way")
    }

    func test_TTLEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TTLEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TTLEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TTLEntryXDR_roundTrip() throws {
        let original: TTLEntryXDR = TTLEntryXDR(keyHash: WrappedData32(Data(repeating: 0xAB, count: 32)), liveUntilLedgerSeq: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TTLEntryXDR.fromXdrJson(json)
        let viaValue = try TTLEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try TTLEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TTLEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TTLEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TTLEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TTLEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TTLEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_ThresholdIndexesXDR_THRESHOLD_HIGH() throws {
        let value: ThresholdIndexesXDR = .high
        XCTAssertEqual(try value.toXdrJson(), "\"high\"",
                       "ThresholdIndexesXDR.high must render as high")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "ThresholdIndexesXDR.high must keep its XDR value")
        XCTAssertEqual(try ThresholdIndexesXDR.fromXdrJson("\"high\""), value,
                       "high must read back as ThresholdIndexesXDR.high")
    }

    func test_ThresholdIndexesXDR_THRESHOLD_LOW() throws {
        let value: ThresholdIndexesXDR = .low
        XCTAssertEqual(try value.toXdrJson(), "\"low\"",
                       "ThresholdIndexesXDR.low must render as low")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ThresholdIndexesXDR.low must keep its XDR value")
        XCTAssertEqual(try ThresholdIndexesXDR.fromXdrJson("\"low\""), value,
                       "low must read back as ThresholdIndexesXDR.low")
    }

    func test_ThresholdIndexesXDR_THRESHOLD_MASTER_WEIGHT() throws {
        let value: ThresholdIndexesXDR = .masterWeight
        XCTAssertEqual(try value.toXdrJson(), "\"master_weight\"",
                       "ThresholdIndexesXDR.masterWeight must render as master_weight")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ThresholdIndexesXDR.masterWeight must keep its XDR value")
        XCTAssertEqual(try ThresholdIndexesXDR.fromXdrJson("\"master_weight\""), value,
                       "master_weight must read back as ThresholdIndexesXDR.masterWeight")
    }

    func test_ThresholdIndexesXDR_THRESHOLD_MED() throws {
        let value: ThresholdIndexesXDR = .med
        XCTAssertEqual(try value.toXdrJson(), "\"med\"",
                       "ThresholdIndexesXDR.med must render as med")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ThresholdIndexesXDR.med must keep its XDR value")
        XCTAssertEqual(try ThresholdIndexesXDR.fromXdrJson("\"med\""), value,
                       "med must read back as ThresholdIndexesXDR.med")
    }

    func test_ThresholdIndexesXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ThresholdIndexesXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ThresholdIndexesXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ThresholdIndexesXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ThresholdsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ThresholdsXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ThresholdsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ThresholdsXDR_roundTrip() throws {
        let original: ThresholdsXDR = WrappedData4(Data(repeating: 0xAB, count: 4))
        let tree = try ThresholdsXDRJsonCodec.toXdrJsonValue(original)
        let json = try ThresholdsXDRJsonCodec.toXdrJson(original)
        let decoded = try ThresholdsXDRJsonCodec.fromXdrJson(json)
        let viaValue = try ThresholdsXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try ThresholdsXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try ThresholdsXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "ThresholdsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try ThresholdsXDRJsonCodec.toXdrJson(decoded), json,
                       "ThresholdsXDR must produce the same text after a round trip")
        XCTAssertEqual(try ThresholdsXDRJsonCodec.toXdrJson(viaValue), json,
                       "ThresholdsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try ThresholdsXDRJsonCodec.toXdrJson(viaTree), json,
                       "ThresholdsXDR must read a depth-checked tree the same way")
    }

    func test_TrustLineFlags_AUTHORIZED_FLAG() throws {
        let value: TrustLineFlags = .authorizedFlag
        XCTAssertEqual(try value.toXdrJson(), "\"authorized_flag\"",
                       "TrustLineFlags.authorizedFlag must render as authorized_flag")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "TrustLineFlags.authorizedFlag must keep its XDR value")
        XCTAssertEqual(try TrustLineFlags.fromXdrJson("\"authorized_flag\""), value,
                       "authorized_flag must read back as TrustLineFlags.authorizedFlag")
    }

    func test_TrustLineFlags_AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG() throws {
        let value: TrustLineFlags = .authorizedToMaintainLiabilitiesFlag
        XCTAssertEqual(try value.toXdrJson(), "\"authorized_to_maintain_liabilities_flag\"",
                       "TrustLineFlags.authorizedToMaintainLiabilitiesFlag must render as authorized_to_maintain_liabilities_flag")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "TrustLineFlags.authorizedToMaintainLiabilitiesFlag must keep its XDR value")
        XCTAssertEqual(try TrustLineFlags.fromXdrJson("\"authorized_to_maintain_liabilities_flag\""), value,
                       "authorized_to_maintain_liabilities_flag must read back as TrustLineFlags.authorizedToMaintainLiabilitiesFlag")
    }

    func test_TrustLineFlags_TRUSTLINE_CLAWBACK_ENABLED_FLAG() throws {
        let value: TrustLineFlags = .trustlineClawbackEnabledFlag
        XCTAssertEqual(try value.toXdrJson(), "\"trustline_clawback_enabled_flag\"",
                       "TrustLineFlags.trustlineClawbackEnabledFlag must render as trustline_clawback_enabled_flag")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "TrustLineFlags.trustlineClawbackEnabledFlag must keep its XDR value")
        XCTAssertEqual(try TrustLineFlags.fromXdrJson("\"trustline_clawback_enabled_flag\""), value,
                       "trustline_clawback_enabled_flag must read back as TrustLineFlags.trustlineClawbackEnabledFlag")
    }

    func test_TrustLineFlags_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try TrustLineFlags.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("TrustLineFlags: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "TrustLineFlags")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_TrustlineAssetXDR_alphanum12_rejectsBareString() throws {
        XCTAssertThrowsError(try TrustlineAssetXDR.fromXdrJson("\"credit_alphanum12\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TrustlineAssetXDR.credit_alphanum12: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineAssetXDR")
            XCTAssertEqual(key, "credit_alphanum12",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TrustlineAssetXDR_alphanum12_roundTrip() throws {
        let original: TrustlineAssetXDR = .alphanum12(Alpha12XDR(assetCode: WrappedData12(Data(repeating: 0xAB, count: 12)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineAssetXDR.fromXdrJson(json)
        let viaValue = try TrustlineAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineAssetXDR_alphanum4_rejectsBareString() throws {
        XCTAssertThrowsError(try TrustlineAssetXDR.fromXdrJson("\"credit_alphanum4\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TrustlineAssetXDR.credit_alphanum4: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineAssetXDR")
            XCTAssertEqual(key, "credit_alphanum4",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TrustlineAssetXDR_alphanum4_roundTrip() throws {
        let original: TrustlineAssetXDR = .alphanum4(Alpha4XDR(assetCode: WrappedData4(Data(repeating: 0xAB, count: 4)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineAssetXDR.fromXdrJson(json)
        let viaValue = try TrustlineAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineAssetXDR_native_roundTrip() throws {
        let original: TrustlineAssetXDR = .native
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineAssetXDR.fromXdrJson(json)
        let viaValue = try TrustlineAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineAssetXDR_poolShare_rejectsBareString() throws {
        XCTAssertThrowsError(try TrustlineAssetXDR.fromXdrJson("\"pool_share\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TrustlineAssetXDR.pool_share: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineAssetXDR")
            XCTAssertEqual(key, "pool_share",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TrustlineAssetXDR_poolShare_roundTrip() throws {
        let original: TrustlineAssetXDR = .poolShare(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineAssetXDR.fromXdrJson(json)
        let viaValue = try TrustlineAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineAssetXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TrustlineAssetXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TrustlineAssetXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineAssetXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TrustlineEntryExtV1XDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TrustlineEntryExtV1XDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TrustlineEntryExtV1XDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineEntryExtV1XDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TrustlineEntryExtV1XDR_trustlineEntryExtensionV2_rejectsBareString() throws {
        XCTAssertThrowsError(try TrustlineEntryExtV1XDR.fromXdrJson("\"v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TrustlineEntryExtV1XDR.v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineEntryExtV1XDR")
            XCTAssertEqual(key, "v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TrustlineEntryExtV1XDR_trustlineEntryExtensionV2_roundTrip() throws {
        let original: TrustlineEntryExtV1XDR = .trustlineEntryExtensionV2(TrustlineEntryExtensionV2(liquidityPoolUseCount: Int32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryExtV1XDR.fromXdrJson(json)
        let viaValue = try TrustlineEntryExtV1XDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryExtV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryExtV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryExtV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryExtV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryExtV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryExtV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineEntryExtV1XDR_void_roundTrip() throws {
        let original: TrustlineEntryExtV1XDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryExtV1XDR.fromXdrJson(json)
        let viaValue = try TrustlineEntryExtV1XDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryExtV1XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryExtV1XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryExtV1XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryExtV1XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryExtV1XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryExtV1XDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineEntryExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TrustlineEntryExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TrustlineEntryExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineEntryExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TrustlineEntryExtXDR_trustlineEntryExtensionV1_rejectsBareString() throws {
        XCTAssertThrowsError(try TrustlineEntryExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TrustlineEntryExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineEntryExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TrustlineEntryExtXDR_trustlineEntryExtensionV1_roundTrip() throws {
        let original: TrustlineEntryExtXDR = .trustlineEntryExtensionV1(TrustlineEntryExtensionV1(liabilities: LiabilitiesXDR(buying: Int64(1234567), selling: Int64(1234567)), ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryExtXDR.fromXdrJson(json)
        let viaValue = try TrustlineEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineEntryExtXDR_void_roundTrip() throws {
        let original: TrustlineEntryExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryExtXDR.fromXdrJson(json)
        let viaValue = try TrustlineEntryExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineEntryExtensionV1_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TrustlineEntryExtensionV1.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TrustlineEntryExtensionV1 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TrustlineEntryExtensionV1_roundTrip() throws {
        let original: TrustlineEntryExtensionV1 = TrustlineEntryExtensionV1(liabilities: LiabilitiesXDR(buying: Int64(1234567), selling: Int64(1234567)), ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryExtensionV1.fromXdrJson(json)
        let viaValue = try TrustlineEntryExtensionV1.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryExtensionV1.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryExtensionV1 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryExtensionV1 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryExtensionV1 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryExtensionV1 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryExtensionV1 must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineEntryExtensionV2ExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TrustlineEntryExtensionV2ExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TrustlineEntryExtensionV2ExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TrustlineEntryExtensionV2ExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TrustlineEntryExtensionV2ExtXDR_void_roundTrip() throws {
        let original: TrustlineEntryExtensionV2ExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryExtensionV2ExtXDR.fromXdrJson(json)
        let viaValue = try TrustlineEntryExtensionV2ExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryExtensionV2ExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryExtensionV2ExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryExtensionV2ExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryExtensionV2ExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryExtensionV2ExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryExtensionV2ExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineEntryExtensionV2_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TrustlineEntryExtensionV2.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TrustlineEntryExtensionV2 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TrustlineEntryExtensionV2_roundTrip() throws {
        let original: TrustlineEntryExtensionV2 = TrustlineEntryExtensionV2(liquidityPoolUseCount: Int32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryExtensionV2.fromXdrJson(json)
        let viaValue = try TrustlineEntryExtensionV2.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryExtensionV2.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryExtensionV2 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryExtensionV2 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryExtensionV2 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryExtensionV2 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryExtensionV2 must reach the same bytes through JSON and XDR")
    }

    func test_TrustlineEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TrustlineEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TrustlineEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TrustlineEntryXDR_roundTrip() throws {
        let original: TrustlineEntryXDR = TrustlineEntryXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, balance: Int64(1234567), limit: Int64(1234567), flags: UInt32(42), reserved: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TrustlineEntryXDR.fromXdrJson(json)
        let viaValue = try TrustlineEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try TrustlineEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TrustlineEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TrustlineEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TrustlineEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TrustlineEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TrustlineEntryXDR must reach the same bytes through JSON and XDR")
    }
}
