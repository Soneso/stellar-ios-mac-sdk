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

final class GeneratedXdrJsonStellarTransactionUnitTests: XCTestCase {

    func test_AccountMergeResultCode_ACCOUNT_MERGE_DEST_FULL() throws {
        let value: AccountMergeResultCode = .destFull
        XCTAssertEqual(try value.toXdrJson(), "\"dest_full\"",
                       "AccountMergeResultCode.destFull must render as dest_full")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "AccountMergeResultCode.destFull must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"dest_full\""), value,
                       "dest_full must read back as AccountMergeResultCode.destFull")
    }

    func test_AccountMergeResultCode_ACCOUNT_MERGE_HAS_SUB_ENTRIES() throws {
        let value: AccountMergeResultCode = .hasSubEntries
        XCTAssertEqual(try value.toXdrJson(), "\"has_sub_entries\"",
                       "AccountMergeResultCode.hasSubEntries must render as has_sub_entries")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "AccountMergeResultCode.hasSubEntries must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"has_sub_entries\""), value,
                       "has_sub_entries must read back as AccountMergeResultCode.hasSubEntries")
    }

    func test_AccountMergeResultCode_ACCOUNT_MERGE_IMMUTABLE_SET() throws {
        let value: AccountMergeResultCode = .immutableSet
        XCTAssertEqual(try value.toXdrJson(), "\"immutable_set\"",
                       "AccountMergeResultCode.immutableSet must render as immutable_set")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "AccountMergeResultCode.immutableSet must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"immutable_set\""), value,
                       "immutable_set must read back as AccountMergeResultCode.immutableSet")
    }

    func test_AccountMergeResultCode_ACCOUNT_MERGE_IS_SPONSOR() throws {
        let value: AccountMergeResultCode = .isSponsor
        XCTAssertEqual(try value.toXdrJson(), "\"is_sponsor\"",
                       "AccountMergeResultCode.isSponsor must render as is_sponsor")
        XCTAssertEqual(value.rawValue, Int32(-7),
                       "AccountMergeResultCode.isSponsor must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"is_sponsor\""), value,
                       "is_sponsor must read back as AccountMergeResultCode.isSponsor")
    }

    func test_AccountMergeResultCode_ACCOUNT_MERGE_MALFORMED() throws {
        let value: AccountMergeResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "AccountMergeResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "AccountMergeResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as AccountMergeResultCode.malformed")
    }

    func test_AccountMergeResultCode_ACCOUNT_MERGE_NO_ACCOUNT() throws {
        let value: AccountMergeResultCode = .noAccount
        XCTAssertEqual(try value.toXdrJson(), "\"no_account\"",
                       "AccountMergeResultCode.noAccount must render as no_account")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "AccountMergeResultCode.noAccount must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"no_account\""), value,
                       "no_account must read back as AccountMergeResultCode.noAccount")
    }

    func test_AccountMergeResultCode_ACCOUNT_MERGE_SEQNUM_TOO_FAR() throws {
        let value: AccountMergeResultCode = .seqnumTooFar
        XCTAssertEqual(try value.toXdrJson(), "\"seqnum_too_far\"",
                       "AccountMergeResultCode.seqnumTooFar must render as seqnum_too_far")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "AccountMergeResultCode.seqnumTooFar must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"seqnum_too_far\""), value,
                       "seqnum_too_far must read back as AccountMergeResultCode.seqnumTooFar")
    }

    func test_AccountMergeResultCode_ACCOUNT_MERGE_SUCCESS() throws {
        let value: AccountMergeResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "AccountMergeResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "AccountMergeResultCode.success must keep its XDR value")
        XCTAssertEqual(try AccountMergeResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as AccountMergeResultCode.success")
    }

    func test_AccountMergeResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try AccountMergeResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("AccountMergeResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "AccountMergeResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_AccountMergeResultXDR_destFull_roundTrip() throws {
        let original: AccountMergeResultXDR = .destFull
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountMergeResultXDR_hasSubEntries_roundTrip() throws {
        let original: AccountMergeResultXDR = .hasSubEntries
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountMergeResultXDR_immutableSet_roundTrip() throws {
        let original: AccountMergeResultXDR = .immutableSet
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountMergeResultXDR_isSponsor_roundTrip() throws {
        let original: AccountMergeResultXDR = .isSponsor
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountMergeResultXDR_malformed_roundTrip() throws {
        let original: AccountMergeResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountMergeResultXDR_noAccount_roundTrip() throws {
        let original: AccountMergeResultXDR = .noAccount
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountMergeResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try AccountMergeResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("AccountMergeResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "AccountMergeResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_AccountMergeResultXDR_seqnumTooFar_roundTrip() throws {
        let original: AccountMergeResultXDR = .seqnumTooFar
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AccountMergeResultXDR_sourceAccountBalance_rejectsBareString() throws {
        XCTAssertThrowsError(try AccountMergeResultXDR.fromXdrJson("\"success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("AccountMergeResultXDR.success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "AccountMergeResultXDR")
            XCTAssertEqual(key, "success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_AccountMergeResultXDR_sourceAccountBalance_roundTrip() throws {
        let original: AccountMergeResultXDR = .sourceAccountBalance(Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AccountMergeResultXDR.fromXdrJson(json)
        let viaValue = try AccountMergeResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AccountMergeResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AccountMergeResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AccountMergeResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AccountMergeResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AccountMergeResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AccountMergeResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AllowTrustOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AllowTrustOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AllowTrustOperationXDR_roundTrip() throws {
        let original: AllowTrustOperationXDR = AllowTrustOperationXDR(trustor: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .alphanum4(WrappedData4(Data(repeating: 0xAB, count: 4))), authorize: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustOperationXDR.fromXdrJson(json)
        let viaValue = try AllowTrustOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustResultCode_ALLOW_TRUST_CANT_REVOKE() throws {
        let value: AllowTrustResultCode = .cantRevoke
        XCTAssertEqual(try value.toXdrJson(), "\"cant_revoke\"",
                       "AllowTrustResultCode.cantRevoke must render as cant_revoke")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "AllowTrustResultCode.cantRevoke must keep its XDR value")
        XCTAssertEqual(try AllowTrustResultCode.fromXdrJson("\"cant_revoke\""), value,
                       "cant_revoke must read back as AllowTrustResultCode.cantRevoke")
    }

    func test_AllowTrustResultCode_ALLOW_TRUST_LOW_RESERVE() throws {
        let value: AllowTrustResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "AllowTrustResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "AllowTrustResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try AllowTrustResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as AllowTrustResultCode.lowReserve")
    }

    func test_AllowTrustResultCode_ALLOW_TRUST_MALFORMED() throws {
        let value: AllowTrustResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "AllowTrustResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "AllowTrustResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try AllowTrustResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as AllowTrustResultCode.malformed")
    }

    func test_AllowTrustResultCode_ALLOW_TRUST_NO_TRUST_LINE() throws {
        let value: AllowTrustResultCode = .noTrustLine
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust_line\"",
                       "AllowTrustResultCode.noTrustLine must render as no_trust_line")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "AllowTrustResultCode.noTrustLine must keep its XDR value")
        XCTAssertEqual(try AllowTrustResultCode.fromXdrJson("\"no_trust_line\""), value,
                       "no_trust_line must read back as AllowTrustResultCode.noTrustLine")
    }

    func test_AllowTrustResultCode_ALLOW_TRUST_SELF_NOT_ALLOWED() throws {
        let value: AllowTrustResultCode = .selfNotAllowed
        XCTAssertEqual(try value.toXdrJson(), "\"self_not_allowed\"",
                       "AllowTrustResultCode.selfNotAllowed must render as self_not_allowed")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "AllowTrustResultCode.selfNotAllowed must keep its XDR value")
        XCTAssertEqual(try AllowTrustResultCode.fromXdrJson("\"self_not_allowed\""), value,
                       "self_not_allowed must read back as AllowTrustResultCode.selfNotAllowed")
    }

    func test_AllowTrustResultCode_ALLOW_TRUST_SUCCESS() throws {
        let value: AllowTrustResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "AllowTrustResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "AllowTrustResultCode.success must keep its XDR value")
        XCTAssertEqual(try AllowTrustResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as AllowTrustResultCode.success")
    }

    func test_AllowTrustResultCode_ALLOW_TRUST_TRUST_NOT_REQUIRED() throws {
        let value: AllowTrustResultCode = .trustNotRequired
        XCTAssertEqual(try value.toXdrJson(), "\"trust_not_required\"",
                       "AllowTrustResultCode.trustNotRequired must render as trust_not_required")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "AllowTrustResultCode.trustNotRequired must keep its XDR value")
        XCTAssertEqual(try AllowTrustResultCode.fromXdrJson("\"trust_not_required\""), value,
                       "trust_not_required must read back as AllowTrustResultCode.trustNotRequired")
    }

    func test_AllowTrustResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try AllowTrustResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("AllowTrustResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "AllowTrustResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_AllowTrustResultXDR_cantRevoke_roundTrip() throws {
        let original: AllowTrustResultXDR = .cantRevoke
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustResultXDR.fromXdrJson(json)
        let viaValue = try AllowTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustResultXDR_lowReserve_roundTrip() throws {
        let original: AllowTrustResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustResultXDR.fromXdrJson(json)
        let viaValue = try AllowTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustResultXDR_malformed_roundTrip() throws {
        let original: AllowTrustResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustResultXDR.fromXdrJson(json)
        let viaValue = try AllowTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustResultXDR_noTrustLine_roundTrip() throws {
        let original: AllowTrustResultXDR = .noTrustLine
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustResultXDR.fromXdrJson(json)
        let viaValue = try AllowTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try AllowTrustResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("AllowTrustResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "AllowTrustResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_AllowTrustResultXDR_selfNotAllowed_roundTrip() throws {
        let original: AllowTrustResultXDR = .selfNotAllowed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustResultXDR.fromXdrJson(json)
        let viaValue = try AllowTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustResultXDR_success_roundTrip() throws {
        let original: AllowTrustResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustResultXDR.fromXdrJson(json)
        let viaValue = try AllowTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_AllowTrustResultXDR_trustNotRequired_roundTrip() throws {
        let original: AllowTrustResultXDR = .trustNotRequired
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AllowTrustResultXDR.fromXdrJson(json)
        let viaValue = try AllowTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try AllowTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AllowTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AllowTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AllowTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AllowTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AllowTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_BeginSponsoringFutureReservesOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try BeginSponsoringFutureReservesOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "BeginSponsoringFutureReservesOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_BeginSponsoringFutureReservesOpXDR_roundTrip() throws {
        let original: BeginSponsoringFutureReservesOpXDR = BeginSponsoringFutureReservesOpXDR(sponsoredId: try PublicKey([UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BeginSponsoringFutureReservesOpXDR.fromXdrJson(json)
        let viaValue = try BeginSponsoringFutureReservesOpXDR.fromXdrJsonValue(tree)
        let viaTree = try BeginSponsoringFutureReservesOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BeginSponsoringFutureReservesOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BeginSponsoringFutureReservesOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BeginSponsoringFutureReservesOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BeginSponsoringFutureReservesOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BeginSponsoringFutureReservesOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_BeginSponsoringFutureReservesResultCode_BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED() throws {
        let value: BeginSponsoringFutureReservesResultCode = .alreadySponsored
        XCTAssertEqual(try value.toXdrJson(), "\"already_sponsored\"",
                       "BeginSponsoringFutureReservesResultCode.alreadySponsored must render as already_sponsored")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "BeginSponsoringFutureReservesResultCode.alreadySponsored must keep its XDR value")
        XCTAssertEqual(try BeginSponsoringFutureReservesResultCode.fromXdrJson("\"already_sponsored\""), value,
                       "already_sponsored must read back as BeginSponsoringFutureReservesResultCode.alreadySponsored")
    }

    func test_BeginSponsoringFutureReservesResultCode_BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED() throws {
        let value: BeginSponsoringFutureReservesResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "BeginSponsoringFutureReservesResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "BeginSponsoringFutureReservesResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try BeginSponsoringFutureReservesResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as BeginSponsoringFutureReservesResultCode.malformed")
    }

    func test_BeginSponsoringFutureReservesResultCode_BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE() throws {
        let value: BeginSponsoringFutureReservesResultCode = .recursive
        XCTAssertEqual(try value.toXdrJson(), "\"recursive\"",
                       "BeginSponsoringFutureReservesResultCode.recursive must render as recursive")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "BeginSponsoringFutureReservesResultCode.recursive must keep its XDR value")
        XCTAssertEqual(try BeginSponsoringFutureReservesResultCode.fromXdrJson("\"recursive\""), value,
                       "recursive must read back as BeginSponsoringFutureReservesResultCode.recursive")
    }

    func test_BeginSponsoringFutureReservesResultCode_BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS() throws {
        let value: BeginSponsoringFutureReservesResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "BeginSponsoringFutureReservesResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "BeginSponsoringFutureReservesResultCode.success must keep its XDR value")
        XCTAssertEqual(try BeginSponsoringFutureReservesResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as BeginSponsoringFutureReservesResultCode.success")
    }

    func test_BeginSponsoringFutureReservesResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try BeginSponsoringFutureReservesResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("BeginSponsoringFutureReservesResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "BeginSponsoringFutureReservesResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_BeginSponsoringFutureReservesResultXDR_alreadySponsored_roundTrip() throws {
        let original: BeginSponsoringFutureReservesResultXDR = .alreadySponsored
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BeginSponsoringFutureReservesResultXDR.fromXdrJson(json)
        let viaValue = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonValue(tree)
        let viaTree = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BeginSponsoringFutureReservesResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BeginSponsoringFutureReservesResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_BeginSponsoringFutureReservesResultXDR_malformed_roundTrip() throws {
        let original: BeginSponsoringFutureReservesResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BeginSponsoringFutureReservesResultXDR.fromXdrJson(json)
        let viaValue = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonValue(tree)
        let viaTree = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BeginSponsoringFutureReservesResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BeginSponsoringFutureReservesResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_BeginSponsoringFutureReservesResultXDR_recursive_roundTrip() throws {
        let original: BeginSponsoringFutureReservesResultXDR = .recursive
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BeginSponsoringFutureReservesResultXDR.fromXdrJson(json)
        let viaValue = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonValue(tree)
        let viaTree = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BeginSponsoringFutureReservesResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BeginSponsoringFutureReservesResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_BeginSponsoringFutureReservesResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try BeginSponsoringFutureReservesResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("BeginSponsoringFutureReservesResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "BeginSponsoringFutureReservesResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_BeginSponsoringFutureReservesResultXDR_success_roundTrip() throws {
        let original: BeginSponsoringFutureReservesResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BeginSponsoringFutureReservesResultXDR.fromXdrJson(json)
        let viaValue = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonValue(tree)
        let viaTree = try BeginSponsoringFutureReservesResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BeginSponsoringFutureReservesResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BeginSponsoringFutureReservesResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BeginSponsoringFutureReservesResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_BumpSequenceOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try BumpSequenceOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "BumpSequenceOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_BumpSequenceOperationXDR_roundTrip() throws {
        let original: BumpSequenceOperationXDR = BumpSequenceOperationXDR(bumpTo: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BumpSequenceOperationXDR.fromXdrJson(json)
        let viaValue = try BumpSequenceOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try BumpSequenceOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BumpSequenceOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BumpSequenceOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BumpSequenceOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BumpSequenceOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BumpSequenceOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_BumpSequenceResultCode_BUMP_SEQUENCE_BAD_SEQ() throws {
        let value: BumpSequenceResultCode = .badSeq
        XCTAssertEqual(try value.toXdrJson(), "\"bad_seq\"",
                       "BumpSequenceResultCode.badSeq must render as bad_seq")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "BumpSequenceResultCode.badSeq must keep its XDR value")
        XCTAssertEqual(try BumpSequenceResultCode.fromXdrJson("\"bad_seq\""), value,
                       "bad_seq must read back as BumpSequenceResultCode.badSeq")
    }

    func test_BumpSequenceResultCode_BUMP_SEQUENCE_SUCCESS() throws {
        let value: BumpSequenceResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "BumpSequenceResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "BumpSequenceResultCode.success must keep its XDR value")
        XCTAssertEqual(try BumpSequenceResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as BumpSequenceResultCode.success")
    }

    func test_BumpSequenceResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try BumpSequenceResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("BumpSequenceResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "BumpSequenceResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_BumpSequenceResultXDR_badSeq_roundTrip() throws {
        let original: BumpSequenceResultXDR = .badSeq
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BumpSequenceResultXDR.fromXdrJson(json)
        let viaValue = try BumpSequenceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try BumpSequenceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BumpSequenceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BumpSequenceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BumpSequenceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BumpSequenceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BumpSequenceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_BumpSequenceResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try BumpSequenceResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("BumpSequenceResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "BumpSequenceResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_BumpSequenceResultXDR_success_roundTrip() throws {
        let original: BumpSequenceResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try BumpSequenceResultXDR.fromXdrJson(json)
        let viaValue = try BumpSequenceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try BumpSequenceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "BumpSequenceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "BumpSequenceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "BumpSequenceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "BumpSequenceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "BumpSequenceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustAssetXDR_alphanum12_rejectsBareString() throws {
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromXdrJson("\"credit_alphanum12\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ChangeTrustAssetXDR.credit_alphanum12: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ChangeTrustAssetXDR")
            XCTAssertEqual(key, "credit_alphanum12",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ChangeTrustAssetXDR_alphanum12_roundTrip() throws {
        let original: ChangeTrustAssetXDR = .alphanum12(Alpha12XDR(assetCode: WrappedData12(Data(repeating: 0xAB, count: 12)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustAssetXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustAssetXDR_alphanum4_rejectsBareString() throws {
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromXdrJson("\"credit_alphanum4\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ChangeTrustAssetXDR.credit_alphanum4: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ChangeTrustAssetXDR")
            XCTAssertEqual(key, "credit_alphanum4",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ChangeTrustAssetXDR_alphanum4_roundTrip() throws {
        let original: ChangeTrustAssetXDR = .alphanum4(Alpha4XDR(assetCode: WrappedData4(Data(repeating: 0xAB, count: 4)), issuer: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustAssetXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustAssetXDR_native_roundTrip() throws {
        let original: ChangeTrustAssetXDR = .native
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustAssetXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustAssetXDR_poolShare_rejectsBareString() throws {
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromXdrJson("\"pool_share\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ChangeTrustAssetXDR.pool_share: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ChangeTrustAssetXDR")
            XCTAssertEqual(key, "pool_share",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ChangeTrustAssetXDR_poolShare_roundTrip() throws {
        let original: ChangeTrustAssetXDR = .poolShare(.constantProduct(LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: Int32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustAssetXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustAssetXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustAssetXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustAssetXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustAssetXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustAssetXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustAssetXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustAssetXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ChangeTrustAssetXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ChangeTrustAssetXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ChangeTrustAssetXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ChangeTrustOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ChangeTrustOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ChangeTrustOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ChangeTrustOperationXDR_roundTrip() throws {
        let original: ChangeTrustOperationXDR = ChangeTrustOperationXDR(asset: .native, limit: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustOperationXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_CANNOT_DELETE() throws {
        let value: ChangeTrustResultCode = .cannotDelete
        XCTAssertEqual(try value.toXdrJson(), "\"cannot_delete\"",
                       "ChangeTrustResultCode.cannotDelete must render as cannot_delete")
        XCTAssertEqual(value.rawValue, Int32(-7),
                       "ChangeTrustResultCode.cannotDelete must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"cannot_delete\""), value,
                       "cannot_delete must read back as ChangeTrustResultCode.cannotDelete")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_INVALID_LIMIT() throws {
        let value: ChangeTrustResultCode = .invalidLimit
        XCTAssertEqual(try value.toXdrJson(), "\"invalid_limit\"",
                       "ChangeTrustResultCode.invalidLimit must render as invalid_limit")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "ChangeTrustResultCode.invalidLimit must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"invalid_limit\""), value,
                       "invalid_limit must read back as ChangeTrustResultCode.invalidLimit")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_LOW_RESERVE() throws {
        let value: ChangeTrustResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "ChangeTrustResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "ChangeTrustResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as ChangeTrustResultCode.lowReserve")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_MALFORMED() throws {
        let value: ChangeTrustResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "ChangeTrustResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "ChangeTrustResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as ChangeTrustResultCode.malformed")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES() throws {
        let value: ChangeTrustResultCode = .notAuthMaintainLiabilities
        XCTAssertEqual(try value.toXdrJson(), "\"not_auth_maintain_liabilities\"",
                       "ChangeTrustResultCode.notAuthMaintainLiabilities must render as not_auth_maintain_liabilities")
        XCTAssertEqual(value.rawValue, Int32(-8),
                       "ChangeTrustResultCode.notAuthMaintainLiabilities must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"not_auth_maintain_liabilities\""), value,
                       "not_auth_maintain_liabilities must read back as ChangeTrustResultCode.notAuthMaintainLiabilities")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_NO_ISSUER() throws {
        let value: ChangeTrustResultCode = .noIssuer
        XCTAssertEqual(try value.toXdrJson(), "\"no_issuer\"",
                       "ChangeTrustResultCode.noIssuer must render as no_issuer")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "ChangeTrustResultCode.noIssuer must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"no_issuer\""), value,
                       "no_issuer must read back as ChangeTrustResultCode.noIssuer")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_SELF_NOT_ALLOWED() throws {
        let value: ChangeTrustResultCode = .selfNotAllowed
        XCTAssertEqual(try value.toXdrJson(), "\"self_not_allowed\"",
                       "ChangeTrustResultCode.selfNotAllowed must render as self_not_allowed")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "ChangeTrustResultCode.selfNotAllowed must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"self_not_allowed\""), value,
                       "self_not_allowed must read back as ChangeTrustResultCode.selfNotAllowed")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_SUCCESS() throws {
        let value: ChangeTrustResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "ChangeTrustResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ChangeTrustResultCode.success must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as ChangeTrustResultCode.success")
    }

    func test_ChangeTrustResultCode_CHANGE_TRUST_TRUST_LINE_MISSING() throws {
        let value: ChangeTrustResultCode = .trustLineMissing
        XCTAssertEqual(try value.toXdrJson(), "\"trust_line_missing\"",
                       "ChangeTrustResultCode.trustLineMissing must render as trust_line_missing")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "ChangeTrustResultCode.trustLineMissing must keep its XDR value")
        XCTAssertEqual(try ChangeTrustResultCode.fromXdrJson("\"trust_line_missing\""), value,
                       "trust_line_missing must read back as ChangeTrustResultCode.trustLineMissing")
    }

    func test_ChangeTrustResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ChangeTrustResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ChangeTrustResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ChangeTrustResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ChangeTrustResultXDR_cannotDelete_roundTrip() throws {
        let original: ChangeTrustResultXDR = .cannotDelete
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_invalidLimit_roundTrip() throws {
        let original: ChangeTrustResultXDR = .invalidLimit
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_lowReserve_roundTrip() throws {
        let original: ChangeTrustResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_malformed_roundTrip() throws {
        let original: ChangeTrustResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_noIssuer_roundTrip() throws {
        let original: ChangeTrustResultXDR = .noIssuer
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_notAuthMaintainLiabilities_roundTrip() throws {
        let original: ChangeTrustResultXDR = .notAuthMaintainLiabilities
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ChangeTrustResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ChangeTrustResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ChangeTrustResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ChangeTrustResultXDR_selfNotAllowed_roundTrip() throws {
        let original: ChangeTrustResultXDR = .selfNotAllowed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_success_roundTrip() throws {
        let original: ChangeTrustResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ChangeTrustResultXDR_trustLineMissing_roundTrip() throws {
        let original: ChangeTrustResultXDR = .trustLineMissing
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ChangeTrustResultXDR.fromXdrJson(json)
        let viaValue = try ChangeTrustResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ChangeTrustResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ChangeTrustResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ChangeTrustResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ChangeTrustResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ChangeTrustResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimAtomType_CLAIM_ATOM_TYPE_LIQUIDITY_POOL() throws {
        let value: ClaimAtomType = .liquidityPool
        XCTAssertEqual(try value.toXdrJson(), "\"liquidity_pool\"",
                       "ClaimAtomType.liquidityPool must render as liquidity_pool")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ClaimAtomType.liquidityPool must keep its XDR value")
        XCTAssertEqual(try ClaimAtomType.fromXdrJson("\"liquidity_pool\""), value,
                       "liquidity_pool must read back as ClaimAtomType.liquidityPool")
    }

    func test_ClaimAtomType_CLAIM_ATOM_TYPE_ORDER_BOOK() throws {
        let value: ClaimAtomType = .orderBook
        XCTAssertEqual(try value.toXdrJson(), "\"order_book\"",
                       "ClaimAtomType.orderBook must render as order_book")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ClaimAtomType.orderBook must keep its XDR value")
        XCTAssertEqual(try ClaimAtomType.fromXdrJson("\"order_book\""), value,
                       "order_book must read back as ClaimAtomType.orderBook")
    }

    func test_ClaimAtomType_CLAIM_ATOM_TYPE_V0() throws {
        let value: ClaimAtomType = .v0
        XCTAssertEqual(try value.toXdrJson(), "\"v0\"",
                       "ClaimAtomType.v0 must render as v0")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ClaimAtomType.v0 must keep its XDR value")
        XCTAssertEqual(try ClaimAtomType.fromXdrJson("\"v0\""), value,
                       "v0 must read back as ClaimAtomType.v0")
    }

    func test_ClaimAtomType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClaimAtomType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClaimAtomType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimAtomType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClaimAtomXDR_liquidityPool_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimAtomXDR.fromXdrJson("\"liquidity_pool\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimAtomXDR.liquidity_pool: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimAtomXDR")
            XCTAssertEqual(key, "liquidity_pool",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimAtomXDR_liquidityPool_roundTrip() throws {
        let original: ClaimAtomXDR = .liquidityPool(ClaimLiquidityAtomXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimAtomXDR.fromXdrJson(json)
        let viaValue = try ClaimAtomXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimAtomXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimAtomXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimAtomXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimAtomXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimAtomXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimAtomXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimAtomXDR_orderBook_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimAtomXDR.fromXdrJson("\"order_book\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimAtomXDR.order_book: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimAtomXDR")
            XCTAssertEqual(key, "order_book",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimAtomXDR_orderBook_roundTrip() throws {
        let original: ClaimAtomXDR = .orderBook(ClaimOfferAtomXDR(sellerId: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerId: Int64(1234567), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimAtomXDR.fromXdrJson(json)
        let viaValue = try ClaimAtomXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimAtomXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimAtomXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimAtomXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimAtomXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimAtomXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimAtomXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimAtomXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClaimAtomXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClaimAtomXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClaimAtomXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ClaimAtomXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try ClaimAtomXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ClaimAtomXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimAtomXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ClaimAtomXDR_v0_roundTrip() throws {
        let original: ClaimAtomXDR = .v0(ClaimOfferAtomV0XDR(sellerEd25519: WrappedData32(Data(repeating: 0xAB, count: 32)), offerId: Int64(1234567), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimAtomXDR.fromXdrJson(json)
        let viaValue = try ClaimAtomXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimAtomXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimAtomXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimAtomXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimAtomXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimAtomXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimAtomXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimClaimableBalanceOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimClaimableBalanceOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClaimClaimableBalanceOpXDR_roundTrip() throws {
        let original: ClaimClaimableBalanceOpXDR = ClaimClaimableBalanceOpXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceOpXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceOpXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceResultCode_CLAIM_CLAIMABLE_BALANCE_CANNOT_CLAIM() throws {
        let value: ClaimClaimableBalanceResultCode = .cannotClaim
        XCTAssertEqual(try value.toXdrJson(), "\"cannot_claim\"",
                       "ClaimClaimableBalanceResultCode.cannotClaim must render as cannot_claim")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "ClaimClaimableBalanceResultCode.cannotClaim must keep its XDR value")
        XCTAssertEqual(try ClaimClaimableBalanceResultCode.fromXdrJson("\"cannot_claim\""), value,
                       "cannot_claim must read back as ClaimClaimableBalanceResultCode.cannotClaim")
    }

    func test_ClaimClaimableBalanceResultCode_CLAIM_CLAIMABLE_BALANCE_DOES_NOT_EXIST() throws {
        let value: ClaimClaimableBalanceResultCode = .doesNotExist
        XCTAssertEqual(try value.toXdrJson(), "\"does_not_exist\"",
                       "ClaimClaimableBalanceResultCode.doesNotExist must render as does_not_exist")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "ClaimClaimableBalanceResultCode.doesNotExist must keep its XDR value")
        XCTAssertEqual(try ClaimClaimableBalanceResultCode.fromXdrJson("\"does_not_exist\""), value,
                       "does_not_exist must read back as ClaimClaimableBalanceResultCode.doesNotExist")
    }

    func test_ClaimClaimableBalanceResultCode_CLAIM_CLAIMABLE_BALANCE_LINE_FULL() throws {
        let value: ClaimClaimableBalanceResultCode = .lineFull
        XCTAssertEqual(try value.toXdrJson(), "\"line_full\"",
                       "ClaimClaimableBalanceResultCode.lineFull must render as line_full")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "ClaimClaimableBalanceResultCode.lineFull must keep its XDR value")
        XCTAssertEqual(try ClaimClaimableBalanceResultCode.fromXdrJson("\"line_full\""), value,
                       "line_full must read back as ClaimClaimableBalanceResultCode.lineFull")
    }

    func test_ClaimClaimableBalanceResultCode_CLAIM_CLAIMABLE_BALANCE_NOT_AUTHORIZED() throws {
        let value: ClaimClaimableBalanceResultCode = .notAuthorized
        XCTAssertEqual(try value.toXdrJson(), "\"not_authorized\"",
                       "ClaimClaimableBalanceResultCode.notAuthorized must render as not_authorized")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "ClaimClaimableBalanceResultCode.notAuthorized must keep its XDR value")
        XCTAssertEqual(try ClaimClaimableBalanceResultCode.fromXdrJson("\"not_authorized\""), value,
                       "not_authorized must read back as ClaimClaimableBalanceResultCode.notAuthorized")
    }

    func test_ClaimClaimableBalanceResultCode_CLAIM_CLAIMABLE_BALANCE_NO_TRUST() throws {
        let value: ClaimClaimableBalanceResultCode = .noTrust
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust\"",
                       "ClaimClaimableBalanceResultCode.noTrust must render as no_trust")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "ClaimClaimableBalanceResultCode.noTrust must keep its XDR value")
        XCTAssertEqual(try ClaimClaimableBalanceResultCode.fromXdrJson("\"no_trust\""), value,
                       "no_trust must read back as ClaimClaimableBalanceResultCode.noTrust")
    }

    func test_ClaimClaimableBalanceResultCode_CLAIM_CLAIMABLE_BALANCE_SUCCESS() throws {
        let value: ClaimClaimableBalanceResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "ClaimClaimableBalanceResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ClaimClaimableBalanceResultCode.success must keep its XDR value")
        XCTAssertEqual(try ClaimClaimableBalanceResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as ClaimClaimableBalanceResultCode.success")
    }

    func test_ClaimClaimableBalanceResultCode_CLAIM_CLAIMABLE_BALANCE_TRUSTLINE_FROZEN() throws {
        let value: ClaimClaimableBalanceResultCode = .trustlineFrozen
        XCTAssertEqual(try value.toXdrJson(), "\"trustline_frozen\"",
                       "ClaimClaimableBalanceResultCode.trustlineFrozen must render as trustline_frozen")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "ClaimClaimableBalanceResultCode.trustlineFrozen must keep its XDR value")
        XCTAssertEqual(try ClaimClaimableBalanceResultCode.fromXdrJson("\"trustline_frozen\""), value,
                       "trustline_frozen must read back as ClaimClaimableBalanceResultCode.trustlineFrozen")
    }

    func test_ClaimClaimableBalanceResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClaimClaimableBalanceResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClaimClaimableBalanceResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimClaimableBalanceResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClaimClaimableBalanceResultXDR_cannotClaim_roundTrip() throws {
        let original: ClaimClaimableBalanceResultXDR = .cannotClaim
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceResultXDR_doesNotExist_roundTrip() throws {
        let original: ClaimClaimableBalanceResultXDR = .doesNotExist
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceResultXDR_lineFull_roundTrip() throws {
        let original: ClaimClaimableBalanceResultXDR = .lineFull
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceResultXDR_noTrust_roundTrip() throws {
        let original: ClaimClaimableBalanceResultXDR = .noTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceResultXDR_notAuthorized_roundTrip() throws {
        let original: ClaimClaimableBalanceResultXDR = .notAuthorized
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClaimClaimableBalanceResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClaimClaimableBalanceResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClaimClaimableBalanceResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ClaimClaimableBalanceResultXDR_success_roundTrip() throws {
        let original: ClaimClaimableBalanceResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimClaimableBalanceResultXDR_trustlineFrozen_roundTrip() throws {
        let original: ClaimClaimableBalanceResultXDR = .trustlineFrozen
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClaimClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimLiquidityAtomXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimLiquidityAtomXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimLiquidityAtomXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClaimLiquidityAtomXDR_roundTrip() throws {
        let original: ClaimLiquidityAtomXDR = ClaimLiquidityAtomXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimLiquidityAtomXDR.fromXdrJson(json)
        let viaValue = try ClaimLiquidityAtomXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimLiquidityAtomXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimLiquidityAtomXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimLiquidityAtomXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimLiquidityAtomXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimLiquidityAtomXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimLiquidityAtomXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimOfferAtomV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimOfferAtomV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimOfferAtomV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClaimOfferAtomV0XDR_roundTrip() throws {
        let original: ClaimOfferAtomV0XDR = ClaimOfferAtomV0XDR(sellerEd25519: WrappedData32(Data(repeating: 0xAB, count: 32)), offerId: Int64(1234567), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimOfferAtomV0XDR.fromXdrJson(json)
        let viaValue = try ClaimOfferAtomV0XDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimOfferAtomV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimOfferAtomV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimOfferAtomV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimOfferAtomV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimOfferAtomV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimOfferAtomV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimOfferAtomXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimOfferAtomXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimOfferAtomXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClaimOfferAtomXDR_roundTrip() throws {
        let original: ClaimOfferAtomXDR = ClaimOfferAtomXDR(sellerId: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerId: Int64(1234567), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimOfferAtomXDR.fromXdrJson(json)
        let viaValue = try ClaimOfferAtomXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimOfferAtomXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimOfferAtomXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimOfferAtomXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimOfferAtomXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimOfferAtomXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimOfferAtomXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackClaimableBalanceOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClawbackClaimableBalanceOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClawbackClaimableBalanceOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClawbackClaimableBalanceOpXDR_roundTrip() throws {
        let original: ClawbackClaimableBalanceOpXDR = ClawbackClaimableBalanceOpXDR(claimableBalanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackClaimableBalanceOpXDR.fromXdrJson(json)
        let viaValue = try ClawbackClaimableBalanceOpXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackClaimableBalanceOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackClaimableBalanceOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackClaimableBalanceOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackClaimableBalanceOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackClaimableBalanceOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackClaimableBalanceOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackClaimableBalanceResultCode_CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST() throws {
        let value: ClawbackClaimableBalanceResultCode = .doesNotExist
        XCTAssertEqual(try value.toXdrJson(), "\"does_not_exist\"",
                       "ClawbackClaimableBalanceResultCode.doesNotExist must render as does_not_exist")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "ClawbackClaimableBalanceResultCode.doesNotExist must keep its XDR value")
        XCTAssertEqual(try ClawbackClaimableBalanceResultCode.fromXdrJson("\"does_not_exist\""), value,
                       "does_not_exist must read back as ClawbackClaimableBalanceResultCode.doesNotExist")
    }

    func test_ClawbackClaimableBalanceResultCode_CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED() throws {
        let value: ClawbackClaimableBalanceResultCode = .notClawbackEnabled
        XCTAssertEqual(try value.toXdrJson(), "\"not_clawback_enabled\"",
                       "ClawbackClaimableBalanceResultCode.notClawbackEnabled must render as not_clawback_enabled")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "ClawbackClaimableBalanceResultCode.notClawbackEnabled must keep its XDR value")
        XCTAssertEqual(try ClawbackClaimableBalanceResultCode.fromXdrJson("\"not_clawback_enabled\""), value,
                       "not_clawback_enabled must read back as ClawbackClaimableBalanceResultCode.notClawbackEnabled")
    }

    func test_ClawbackClaimableBalanceResultCode_CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER() throws {
        let value: ClawbackClaimableBalanceResultCode = .notIssuer
        XCTAssertEqual(try value.toXdrJson(), "\"not_issuer\"",
                       "ClawbackClaimableBalanceResultCode.notIssuer must render as not_issuer")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "ClawbackClaimableBalanceResultCode.notIssuer must keep its XDR value")
        XCTAssertEqual(try ClawbackClaimableBalanceResultCode.fromXdrJson("\"not_issuer\""), value,
                       "not_issuer must read back as ClawbackClaimableBalanceResultCode.notIssuer")
    }

    func test_ClawbackClaimableBalanceResultCode_CLAWBACK_CLAIMABLE_BALANCE_SUCCESS() throws {
        let value: ClawbackClaimableBalanceResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "ClawbackClaimableBalanceResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ClawbackClaimableBalanceResultCode.success must keep its XDR value")
        XCTAssertEqual(try ClawbackClaimableBalanceResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as ClawbackClaimableBalanceResultCode.success")
    }

    func test_ClawbackClaimableBalanceResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClawbackClaimableBalanceResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClawbackClaimableBalanceResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClawbackClaimableBalanceResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClawbackClaimableBalanceResultXDR_doesNotExist_roundTrip() throws {
        let original: ClawbackClaimableBalanceResultXDR = .doesNotExist
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackClaimableBalanceResultXDR_notClawbackEnabled_roundTrip() throws {
        let original: ClawbackClaimableBalanceResultXDR = .notClawbackEnabled
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackClaimableBalanceResultXDR_notIssuer_roundTrip() throws {
        let original: ClawbackClaimableBalanceResultXDR = .notIssuer
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackClaimableBalanceResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClawbackClaimableBalanceResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClawbackClaimableBalanceResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClawbackClaimableBalanceResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ClawbackClaimableBalanceResultXDR_success_roundTrip() throws {
        let original: ClawbackClaimableBalanceResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClawbackOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClawbackOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ClawbackOpXDR_roundTrip() throws {
        let original: ClawbackOpXDR = ClawbackOpXDR(asset: .native, from: .ed25519([UInt8](repeating: 0xAB, count: 32)), amount: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackOpXDR.fromXdrJson(json)
        let viaValue = try ClawbackOpXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackResultCode_CLAWBACK_MALFORMED() throws {
        let value: ClawbackResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "ClawbackResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "ClawbackResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try ClawbackResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as ClawbackResultCode.malformed")
    }

    func test_ClawbackResultCode_CLAWBACK_NOT_CLAWBACK_ENABLED() throws {
        let value: ClawbackResultCode = .notClawbackEnabled
        XCTAssertEqual(try value.toXdrJson(), "\"not_clawback_enabled\"",
                       "ClawbackResultCode.notClawbackEnabled must render as not_clawback_enabled")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "ClawbackResultCode.notClawbackEnabled must keep its XDR value")
        XCTAssertEqual(try ClawbackResultCode.fromXdrJson("\"not_clawback_enabled\""), value,
                       "not_clawback_enabled must read back as ClawbackResultCode.notClawbackEnabled")
    }

    func test_ClawbackResultCode_CLAWBACK_NO_TRUST() throws {
        let value: ClawbackResultCode = .noTrust
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust\"",
                       "ClawbackResultCode.noTrust must render as no_trust")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "ClawbackResultCode.noTrust must keep its XDR value")
        XCTAssertEqual(try ClawbackResultCode.fromXdrJson("\"no_trust\""), value,
                       "no_trust must read back as ClawbackResultCode.noTrust")
    }

    func test_ClawbackResultCode_CLAWBACK_SUCCESS() throws {
        let value: ClawbackResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "ClawbackResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ClawbackResultCode.success must keep its XDR value")
        XCTAssertEqual(try ClawbackResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as ClawbackResultCode.success")
    }

    func test_ClawbackResultCode_CLAWBACK_UNDERFUNDED() throws {
        let value: ClawbackResultCode = .underfunded
        XCTAssertEqual(try value.toXdrJson(), "\"underfunded\"",
                       "ClawbackResultCode.underfunded must render as underfunded")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "ClawbackResultCode.underfunded must keep its XDR value")
        XCTAssertEqual(try ClawbackResultCode.fromXdrJson("\"underfunded\""), value,
                       "underfunded must read back as ClawbackResultCode.underfunded")
    }

    func test_ClawbackResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClawbackResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClawbackResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClawbackResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClawbackResultXDR_malformed_roundTrip() throws {
        let original: ClawbackResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackResultXDR_noTrust_roundTrip() throws {
        let original: ClawbackResultXDR = .noTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackResultXDR_notClawbackEnabled_roundTrip() throws {
        let original: ClawbackResultXDR = .notClawbackEnabled
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ClawbackResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ClawbackResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ClawbackResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ClawbackResultXDR_success_roundTrip() throws {
        let original: ClawbackResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClawbackResultXDR_underfunded_roundTrip() throws {
        let original: ClawbackResultXDR = .underfunded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClawbackResultXDR.fromXdrJson(json)
        let viaValue = try ClawbackResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ClawbackResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClawbackResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClawbackResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClawbackResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClawbackResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClawbackResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractIDPreimageFromAddressXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractIDPreimageFromAddressXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractIDPreimageFromAddressXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractIDPreimageFromAddressXDR_roundTrip() throws {
        let original: ContractIDPreimageFromAddressXDR = ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractIDPreimageFromAddressXDR.fromXdrJson(json)
        let viaValue = try ContractIDPreimageFromAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractIDPreimageFromAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractIDPreimageFromAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractIDPreimageFromAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractIDPreimageFromAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractIDPreimageFromAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractIDPreimageFromAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractIDPreimageType_CONTRACT_ID_PREIMAGE_FROM_ADDRESS() throws {
        let value: ContractIDPreimageType = .fromAddress
        XCTAssertEqual(try value.toXdrJson(), "\"address\"",
                       "ContractIDPreimageType.fromAddress must render as address")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ContractIDPreimageType.fromAddress must keep its XDR value")
        XCTAssertEqual(try ContractIDPreimageType.fromXdrJson("\"address\""), value,
                       "address must read back as ContractIDPreimageType.fromAddress")
    }

    func test_ContractIDPreimageType_CONTRACT_ID_PREIMAGE_FROM_ASSET() throws {
        let value: ContractIDPreimageType = .fromAsset
        XCTAssertEqual(try value.toXdrJson(), "\"asset\"",
                       "ContractIDPreimageType.fromAsset must render as asset")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ContractIDPreimageType.fromAsset must keep its XDR value")
        XCTAssertEqual(try ContractIDPreimageType.fromXdrJson("\"asset\""), value,
                       "asset must read back as ContractIDPreimageType.fromAsset")
    }

    func test_ContractIDPreimageType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ContractIDPreimageType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ContractIDPreimageType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractIDPreimageType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ContractIDPreimageXDR_fromAddress_rejectsBareString() throws {
        XCTAssertThrowsError(try ContractIDPreimageXDR.fromXdrJson("\"address\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ContractIDPreimageXDR.address: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractIDPreimageXDR")
            XCTAssertEqual(key, "address",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ContractIDPreimageXDR_fromAddress_roundTrip() throws {
        let original: ContractIDPreimageXDR = .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractIDPreimageXDR.fromXdrJson(json)
        let viaValue = try ContractIDPreimageXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractIDPreimageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractIDPreimageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractIDPreimageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractIDPreimageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractIDPreimageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractIDPreimageXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractIDPreimageXDR_fromAsset_rejectsBareString() throws {
        XCTAssertThrowsError(try ContractIDPreimageXDR.fromXdrJson("\"asset\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ContractIDPreimageXDR.asset: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ContractIDPreimageXDR")
            XCTAssertEqual(key, "asset",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ContractIDPreimageXDR_fromAsset_roundTrip() throws {
        let original: ContractIDPreimageXDR = .fromAsset(.native)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ContractIDPreimageXDR.fromXdrJson(json)
        let viaValue = try ContractIDPreimageXDR.fromXdrJsonValue(tree)
        let viaTree = try ContractIDPreimageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ContractIDPreimageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ContractIDPreimageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ContractIDPreimageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ContractIDPreimageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ContractIDPreimageXDR must reach the same bytes through JSON and XDR")
    }

    func test_ContractIDPreimageXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ContractIDPreimageXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ContractIDPreimageXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ContractIDPreimageXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_CreateAccountOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try CreateAccountOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "CreateAccountOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_CreateAccountOperationXDR_roundTrip() throws {
        let original: CreateAccountOperationXDR = CreateAccountOperationXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateAccountOperationXDR.fromXdrJson(json)
        let viaValue = try CreateAccountOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateAccountOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateAccountOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateAccountOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateAccountOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateAccountOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateAccountOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateAccountResultCode_CREATE_ACCOUNT_ALREADY_EXIST() throws {
        let value: CreateAccountResultCode = .alreadyExist
        XCTAssertEqual(try value.toXdrJson(), "\"already_exist\"",
                       "CreateAccountResultCode.alreadyExist must render as already_exist")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "CreateAccountResultCode.alreadyExist must keep its XDR value")
        XCTAssertEqual(try CreateAccountResultCode.fromXdrJson("\"already_exist\""), value,
                       "already_exist must read back as CreateAccountResultCode.alreadyExist")
    }

    func test_CreateAccountResultCode_CREATE_ACCOUNT_LOW_RESERVE() throws {
        let value: CreateAccountResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "CreateAccountResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "CreateAccountResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try CreateAccountResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as CreateAccountResultCode.lowReserve")
    }

    func test_CreateAccountResultCode_CREATE_ACCOUNT_MALFORMED() throws {
        let value: CreateAccountResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "CreateAccountResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "CreateAccountResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try CreateAccountResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as CreateAccountResultCode.malformed")
    }

    func test_CreateAccountResultCode_CREATE_ACCOUNT_SUCCESS() throws {
        let value: CreateAccountResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "CreateAccountResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "CreateAccountResultCode.success must keep its XDR value")
        XCTAssertEqual(try CreateAccountResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as CreateAccountResultCode.success")
    }

    func test_CreateAccountResultCode_CREATE_ACCOUNT_UNDERFUNDED() throws {
        let value: CreateAccountResultCode = .underfunded
        XCTAssertEqual(try value.toXdrJson(), "\"underfunded\"",
                       "CreateAccountResultCode.underfunded must render as underfunded")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "CreateAccountResultCode.underfunded must keep its XDR value")
        XCTAssertEqual(try CreateAccountResultCode.fromXdrJson("\"underfunded\""), value,
                       "underfunded must read back as CreateAccountResultCode.underfunded")
    }

    func test_CreateAccountResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try CreateAccountResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("CreateAccountResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "CreateAccountResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_CreateAccountResultXDR_alreadyExist_roundTrip() throws {
        let original: CreateAccountResultXDR = .alreadyExist
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateAccountResultXDR.fromXdrJson(json)
        let viaValue = try CreateAccountResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateAccountResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateAccountResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateAccountResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateAccountResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateAccountResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateAccountResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateAccountResultXDR_lowReserve_roundTrip() throws {
        let original: CreateAccountResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateAccountResultXDR.fromXdrJson(json)
        let viaValue = try CreateAccountResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateAccountResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateAccountResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateAccountResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateAccountResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateAccountResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateAccountResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateAccountResultXDR_malformed_roundTrip() throws {
        let original: CreateAccountResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateAccountResultXDR.fromXdrJson(json)
        let viaValue = try CreateAccountResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateAccountResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateAccountResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateAccountResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateAccountResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateAccountResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateAccountResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateAccountResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try CreateAccountResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("CreateAccountResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "CreateAccountResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_CreateAccountResultXDR_success_roundTrip() throws {
        let original: CreateAccountResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateAccountResultXDR.fromXdrJson(json)
        let viaValue = try CreateAccountResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateAccountResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateAccountResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateAccountResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateAccountResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateAccountResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateAccountResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateAccountResultXDR_underfunded_roundTrip() throws {
        let original: CreateAccountResultXDR = .underfunded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateAccountResultXDR.fromXdrJson(json)
        let viaValue = try CreateAccountResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateAccountResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateAccountResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateAccountResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateAccountResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateAccountResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateAccountResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateClaimableBalanceOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try CreateClaimableBalanceOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "CreateClaimableBalanceOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_CreateClaimableBalanceOpXDR_roundTrip() throws {
        let original: CreateClaimableBalanceOpXDR = CreateClaimableBalanceOpXDR(asset: .native, amount: Int64(1234567), claimants: [.claimantTypeV0(ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateClaimableBalanceOpXDR.fromXdrJson(json)
        let viaValue = try CreateClaimableBalanceOpXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateClaimableBalanceOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateClaimableBalanceOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateClaimableBalanceOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateClaimableBalanceOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateClaimableBalanceOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateClaimableBalanceOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateClaimableBalanceResultCode_CREATE_CLAIMABLE_BALANCE_LOW_RESERVE() throws {
        let value: CreateClaimableBalanceResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "CreateClaimableBalanceResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "CreateClaimableBalanceResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try CreateClaimableBalanceResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as CreateClaimableBalanceResultCode.lowReserve")
    }

    func test_CreateClaimableBalanceResultCode_CREATE_CLAIMABLE_BALANCE_MALFORMED() throws {
        let value: CreateClaimableBalanceResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "CreateClaimableBalanceResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "CreateClaimableBalanceResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try CreateClaimableBalanceResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as CreateClaimableBalanceResultCode.malformed")
    }

    func test_CreateClaimableBalanceResultCode_CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED() throws {
        let value: CreateClaimableBalanceResultCode = .notAuthorized
        XCTAssertEqual(try value.toXdrJson(), "\"not_authorized\"",
                       "CreateClaimableBalanceResultCode.notAuthorized must render as not_authorized")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "CreateClaimableBalanceResultCode.notAuthorized must keep its XDR value")
        XCTAssertEqual(try CreateClaimableBalanceResultCode.fromXdrJson("\"not_authorized\""), value,
                       "not_authorized must read back as CreateClaimableBalanceResultCode.notAuthorized")
    }

    func test_CreateClaimableBalanceResultCode_CREATE_CLAIMABLE_BALANCE_NO_TRUST() throws {
        let value: CreateClaimableBalanceResultCode = .noTrust
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust\"",
                       "CreateClaimableBalanceResultCode.noTrust must render as no_trust")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "CreateClaimableBalanceResultCode.noTrust must keep its XDR value")
        XCTAssertEqual(try CreateClaimableBalanceResultCode.fromXdrJson("\"no_trust\""), value,
                       "no_trust must read back as CreateClaimableBalanceResultCode.noTrust")
    }

    func test_CreateClaimableBalanceResultCode_CREATE_CLAIMABLE_BALANCE_SUCCESS() throws {
        let value: CreateClaimableBalanceResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "CreateClaimableBalanceResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "CreateClaimableBalanceResultCode.success must keep its XDR value")
        XCTAssertEqual(try CreateClaimableBalanceResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as CreateClaimableBalanceResultCode.success")
    }

    func test_CreateClaimableBalanceResultCode_CREATE_CLAIMABLE_BALANCE_UNDERFUNDED() throws {
        let value: CreateClaimableBalanceResultCode = .underfunded
        XCTAssertEqual(try value.toXdrJson(), "\"underfunded\"",
                       "CreateClaimableBalanceResultCode.underfunded must render as underfunded")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "CreateClaimableBalanceResultCode.underfunded must keep its XDR value")
        XCTAssertEqual(try CreateClaimableBalanceResultCode.fromXdrJson("\"underfunded\""), value,
                       "underfunded must read back as CreateClaimableBalanceResultCode.underfunded")
    }

    func test_CreateClaimableBalanceResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try CreateClaimableBalanceResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("CreateClaimableBalanceResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "CreateClaimableBalanceResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_CreateClaimableBalanceResultXDR_balanceID_rejectsBareString() throws {
        XCTAssertThrowsError(try CreateClaimableBalanceResultXDR.fromXdrJson("\"success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("CreateClaimableBalanceResultXDR.success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "CreateClaimableBalanceResultXDR")
            XCTAssertEqual(key, "success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_CreateClaimableBalanceResultXDR_balanceID_roundTrip() throws {
        let original: CreateClaimableBalanceResultXDR = .balanceID(.claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try CreateClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateClaimableBalanceResultXDR_lowReserve_roundTrip() throws {
        let original: CreateClaimableBalanceResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try CreateClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateClaimableBalanceResultXDR_malformed_roundTrip() throws {
        let original: CreateClaimableBalanceResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try CreateClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateClaimableBalanceResultXDR_noTrust_roundTrip() throws {
        let original: CreateClaimableBalanceResultXDR = .noTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try CreateClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateClaimableBalanceResultXDR_notAuthorized_roundTrip() throws {
        let original: CreateClaimableBalanceResultXDR = .notAuthorized
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try CreateClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateClaimableBalanceResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try CreateClaimableBalanceResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("CreateClaimableBalanceResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "CreateClaimableBalanceResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_CreateClaimableBalanceResultXDR_underfunded_roundTrip() throws {
        let original: CreateClaimableBalanceResultXDR = .underfunded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateClaimableBalanceResultXDR.fromXdrJson(json)
        let viaValue = try CreateClaimableBalanceResultXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateClaimableBalanceResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateClaimableBalanceResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateClaimableBalanceResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateClaimableBalanceResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateContractArgsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try CreateContractArgsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "CreateContractArgsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_CreateContractArgsXDR_roundTrip() throws {
        let original: CreateContractArgsXDR = CreateContractArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateContractArgsXDR.fromXdrJson(json)
        let viaValue = try CreateContractArgsXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateContractArgsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateContractArgsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateContractArgsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateContractArgsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateContractArgsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateContractArgsXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreateContractV2ArgsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try CreateContractV2ArgsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "CreateContractV2ArgsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_CreateContractV2ArgsXDR_roundTrip() throws {
        let original: CreateContractV2ArgsXDR = CreateContractV2ArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token, constructorArgs: [.void])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreateContractV2ArgsXDR.fromXdrJson(json)
        let viaValue = try CreateContractV2ArgsXDR.fromXdrJsonValue(tree)
        let viaTree = try CreateContractV2ArgsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreateContractV2ArgsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreateContractV2ArgsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreateContractV2ArgsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreateContractV2ArgsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreateContractV2ArgsXDR must reach the same bytes through JSON and XDR")
    }

    func test_CreatePassiveOfferOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try CreatePassiveOfferOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "CreatePassiveOfferOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_CreatePassiveOfferOperationXDR_roundTrip() throws {
        let original: CreatePassiveOfferOperationXDR = CreatePassiveOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try CreatePassiveOfferOperationXDR.fromXdrJson(json)
        let viaValue = try CreatePassiveOfferOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try CreatePassiveOfferOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "CreatePassiveOfferOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "CreatePassiveOfferOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "CreatePassiveOfferOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "CreatePassiveOfferOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "CreatePassiveOfferOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_DecoratedSignatureXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try DecoratedSignatureXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "DecoratedSignatureXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_DecoratedSignatureXDR_roundTrip() throws {
        let original: DecoratedSignatureXDR = DecoratedSignatureXDR(hint: WrappedData4(Data(repeating: 0xAB, count: 4)), signature: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try DecoratedSignatureXDR.fromXdrJson(json)
        let viaValue = try DecoratedSignatureXDR.fromXdrJsonValue(tree)
        let viaTree = try DecoratedSignatureXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "DecoratedSignatureXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "DecoratedSignatureXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "DecoratedSignatureXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "DecoratedSignatureXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "DecoratedSignatureXDR must reach the same bytes through JSON and XDR")
    }

    func test_EndSponsoringFutureReservesResultCode_END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED() throws {
        let value: EndSponsoringFutureReservesResultCode = .notSponsored
        XCTAssertEqual(try value.toXdrJson(), "\"not_sponsored\"",
                       "EndSponsoringFutureReservesResultCode.notSponsored must render as not_sponsored")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "EndSponsoringFutureReservesResultCode.notSponsored must keep its XDR value")
        XCTAssertEqual(try EndSponsoringFutureReservesResultCode.fromXdrJson("\"not_sponsored\""), value,
                       "not_sponsored must read back as EndSponsoringFutureReservesResultCode.notSponsored")
    }

    func test_EndSponsoringFutureReservesResultCode_END_SPONSORING_FUTURE_RESERVES_SUCCESS() throws {
        let value: EndSponsoringFutureReservesResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "EndSponsoringFutureReservesResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "EndSponsoringFutureReservesResultCode.success must keep its XDR value")
        XCTAssertEqual(try EndSponsoringFutureReservesResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as EndSponsoringFutureReservesResultCode.success")
    }

    func test_EndSponsoringFutureReservesResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try EndSponsoringFutureReservesResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("EndSponsoringFutureReservesResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "EndSponsoringFutureReservesResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_EndSponsoringFutureReservesResultXDR_notSponsored_roundTrip() throws {
        let original: EndSponsoringFutureReservesResultXDR = .notSponsored
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try EndSponsoringFutureReservesResultXDR.fromXdrJson(json)
        let viaValue = try EndSponsoringFutureReservesResultXDR.fromXdrJsonValue(tree)
        let viaTree = try EndSponsoringFutureReservesResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "EndSponsoringFutureReservesResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "EndSponsoringFutureReservesResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "EndSponsoringFutureReservesResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "EndSponsoringFutureReservesResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "EndSponsoringFutureReservesResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_EndSponsoringFutureReservesResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try EndSponsoringFutureReservesResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("EndSponsoringFutureReservesResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "EndSponsoringFutureReservesResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_EndSponsoringFutureReservesResultXDR_success_roundTrip() throws {
        let original: EndSponsoringFutureReservesResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try EndSponsoringFutureReservesResultXDR.fromXdrJson(json)
        let viaValue = try EndSponsoringFutureReservesResultXDR.fromXdrJsonValue(tree)
        let viaTree = try EndSponsoringFutureReservesResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "EndSponsoringFutureReservesResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "EndSponsoringFutureReservesResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "EndSponsoringFutureReservesResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "EndSponsoringFutureReservesResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "EndSponsoringFutureReservesResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ExtendFootprintTTLOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ExtendFootprintTTLOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ExtendFootprintTTLOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ExtendFootprintTTLOpXDR_roundTrip() throws {
        let original: ExtendFootprintTTLOpXDR = ExtendFootprintTTLOpXDR(ext: .void, extendTo: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ExtendFootprintTTLOpXDR.fromXdrJson(json)
        let viaValue = try ExtendFootprintTTLOpXDR.fromXdrJsonValue(tree)
        let viaTree = try ExtendFootprintTTLOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ExtendFootprintTTLOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ExtendFootprintTTLOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ExtendFootprintTTLOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ExtendFootprintTTLOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ExtendFootprintTTLOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_ExtendFootprintTTLResultCode_EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE() throws {
        let value: ExtendFootprintTTLResultCode = .insufficientRefundableFee
        XCTAssertEqual(try value.toXdrJson(), "\"insufficient_refundable_fee\"",
                       "ExtendFootprintTTLResultCode.insufficientRefundableFee must render as insufficient_refundable_fee")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "ExtendFootprintTTLResultCode.insufficientRefundableFee must keep its XDR value")
        XCTAssertEqual(try ExtendFootprintTTLResultCode.fromXdrJson("\"insufficient_refundable_fee\""), value,
                       "insufficient_refundable_fee must read back as ExtendFootprintTTLResultCode.insufficientRefundableFee")
    }

    func test_ExtendFootprintTTLResultCode_EXTEND_FOOTPRINT_TTL_MALFORMED() throws {
        let value: ExtendFootprintTTLResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "ExtendFootprintTTLResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "ExtendFootprintTTLResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try ExtendFootprintTTLResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as ExtendFootprintTTLResultCode.malformed")
    }

    func test_ExtendFootprintTTLResultCode_EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED() throws {
        let value: ExtendFootprintTTLResultCode = .resourceLimitExceeded
        XCTAssertEqual(try value.toXdrJson(), "\"resource_limit_exceeded\"",
                       "ExtendFootprintTTLResultCode.resourceLimitExceeded must render as resource_limit_exceeded")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "ExtendFootprintTTLResultCode.resourceLimitExceeded must keep its XDR value")
        XCTAssertEqual(try ExtendFootprintTTLResultCode.fromXdrJson("\"resource_limit_exceeded\""), value,
                       "resource_limit_exceeded must read back as ExtendFootprintTTLResultCode.resourceLimitExceeded")
    }

    func test_ExtendFootprintTTLResultCode_EXTEND_FOOTPRINT_TTL_SUCCESS() throws {
        let value: ExtendFootprintTTLResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "ExtendFootprintTTLResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ExtendFootprintTTLResultCode.success must keep its XDR value")
        XCTAssertEqual(try ExtendFootprintTTLResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as ExtendFootprintTTLResultCode.success")
    }

    func test_ExtendFootprintTTLResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ExtendFootprintTTLResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ExtendFootprintTTLResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ExtendFootprintTTLResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ExtendFootprintTTLResultXDR_insufficientRefundableFee_roundTrip() throws {
        let original: ExtendFootprintTTLResultXDR = .insufficientRefundableFee
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ExtendFootprintTTLResultXDR.fromXdrJson(json)
        let viaValue = try ExtendFootprintTTLResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ExtendFootprintTTLResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ExtendFootprintTTLResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ExtendFootprintTTLResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ExtendFootprintTTLResultXDR_malformed_roundTrip() throws {
        let original: ExtendFootprintTTLResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ExtendFootprintTTLResultXDR.fromXdrJson(json)
        let viaValue = try ExtendFootprintTTLResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ExtendFootprintTTLResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ExtendFootprintTTLResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ExtendFootprintTTLResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ExtendFootprintTTLResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ExtendFootprintTTLResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ExtendFootprintTTLResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ExtendFootprintTTLResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ExtendFootprintTTLResultXDR_resourceLimitExceeded_roundTrip() throws {
        let original: ExtendFootprintTTLResultXDR = .resourceLimitExceeded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ExtendFootprintTTLResultXDR.fromXdrJson(json)
        let viaValue = try ExtendFootprintTTLResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ExtendFootprintTTLResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ExtendFootprintTTLResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ExtendFootprintTTLResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ExtendFootprintTTLResultXDR_success_roundTrip() throws {
        let original: ExtendFootprintTTLResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ExtendFootprintTTLResultXDR.fromXdrJson(json)
        let viaValue = try ExtendFootprintTTLResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ExtendFootprintTTLResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ExtendFootprintTTLResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ExtendFootprintTTLResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ExtendFootprintTTLResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_FeeBumpTransactionEnvelopeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FeeBumpTransactionEnvelopeXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FeeBumpTransactionEnvelopeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FeeBumpTransactionEnvelopeXDR_roundTrip() throws {
        let original: FeeBumpTransactionEnvelopeXDR = FeeBumpTransactionEnvelopeXDR(tx: FeeBumpTransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), innerTx: .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])), fee: UInt64(2000)), signatures: [])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FeeBumpTransactionEnvelopeXDR.fromXdrJson(json)
        let viaValue = try FeeBumpTransactionEnvelopeXDR.fromXdrJsonValue(tree)
        let viaTree = try FeeBumpTransactionEnvelopeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FeeBumpTransactionEnvelopeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FeeBumpTransactionEnvelopeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FeeBumpTransactionEnvelopeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FeeBumpTransactionEnvelopeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FeeBumpTransactionEnvelopeXDR must reach the same bytes through JSON and XDR")
    }

    func test_FeeBumpTransactionXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try FeeBumpTransactionXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("FeeBumpTransactionXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "FeeBumpTransactionXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_FeeBumpTransactionXDRExtXDR_void_roundTrip() throws {
        let original: FeeBumpTransactionXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FeeBumpTransactionXDRExtXDR.fromXdrJson(json)
        let viaValue = try FeeBumpTransactionXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try FeeBumpTransactionXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FeeBumpTransactionXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FeeBumpTransactionXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FeeBumpTransactionXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FeeBumpTransactionXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FeeBumpTransactionXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_FeeBumpTransactionXDRInnerTxXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try FeeBumpTransactionXDRInnerTxXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("FeeBumpTransactionXDRInnerTxXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "FeeBumpTransactionXDRInnerTxXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_FeeBumpTransactionXDRInnerTxXDR_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try FeeBumpTransactionXDRInnerTxXDR.fromXdrJson("\"tx\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("FeeBumpTransactionXDRInnerTxXDR.tx: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "FeeBumpTransactionXDRInnerTxXDR")
            XCTAssertEqual(key, "tx",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_FeeBumpTransactionXDRInnerTxXDR_v1_roundTrip() throws {
        let original: FeeBumpTransactionXDRInnerTxXDR = .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: []))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FeeBumpTransactionXDRInnerTxXDR.fromXdrJson(json)
        let viaValue = try FeeBumpTransactionXDRInnerTxXDR.fromXdrJsonValue(tree)
        let viaTree = try FeeBumpTransactionXDRInnerTxXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FeeBumpTransactionXDRInnerTxXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FeeBumpTransactionXDRInnerTxXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FeeBumpTransactionXDRInnerTxXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FeeBumpTransactionXDRInnerTxXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FeeBumpTransactionXDRInnerTxXDR must reach the same bytes through JSON and XDR")
    }

    func test_FeeBumpTransactionXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FeeBumpTransactionXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FeeBumpTransactionXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FeeBumpTransactionXDR_roundTrip() throws {
        let original: FeeBumpTransactionXDR = FeeBumpTransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), innerTx: .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])), fee: UInt64(2000))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FeeBumpTransactionXDR.fromXdrJson(json)
        let viaValue = try FeeBumpTransactionXDR.fromXdrJsonValue(tree)
        let viaTree = try FeeBumpTransactionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FeeBumpTransactionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FeeBumpTransactionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FeeBumpTransactionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FeeBumpTransactionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FeeBumpTransactionXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageContractIDXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try HashIDPreimageContractIDXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "HashIDPreimageContractIDXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_HashIDPreimageContractIDXDR_roundTrip() throws {
        let original: HashIDPreimageContractIDXDR = HashIDPreimageContractIDXDR(networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageContractIDXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageContractIDXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageContractIDXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageContractIDXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageContractIDXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageContractIDXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageContractIDXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageContractIDXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageSorobanAuthorizationWithAddressXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try HashIDPreimageSorobanAuthorizationWithAddressXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "HashIDPreimageSorobanAuthorizationWithAddressXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_HashIDPreimageSorobanAuthorizationWithAddressXDR_roundTrip() throws {
        let original: HashIDPreimageSorobanAuthorizationWithAddressXDR = HashIDPreimageSorobanAuthorizationWithAddressXDR(networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), invocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: []))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageSorobanAuthorizationWithAddressXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageSorobanAuthorizationWithAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageSorobanAuthorizationWithAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageSorobanAuthorizationWithAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageSorobanAuthorizationWithAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageSorobanAuthorizationWithAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageSorobanAuthorizationWithAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageSorobanAuthorizationWithAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageSorobanAuthorizationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try HashIDPreimageSorobanAuthorizationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "HashIDPreimageSorobanAuthorizationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_HashIDPreimageSorobanAuthorizationXDR_roundTrip() throws {
        let original: HashIDPreimageSorobanAuthorizationXDR = HashIDPreimageSorobanAuthorizationXDR(networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), invocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: []))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageSorobanAuthorizationXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageSorobanAuthorizationXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageSorobanAuthorizationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageSorobanAuthorizationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageSorobanAuthorizationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageSorobanAuthorizationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageSorobanAuthorizationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageSorobanAuthorizationXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageXDR_contractID_rejectsBareString() throws {
        XCTAssertThrowsError(try HashIDPreimageXDR.fromXdrJson("\"contract_id\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HashIDPreimageXDR.contract_id: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HashIDPreimageXDR")
            XCTAssertEqual(key, "contract_id",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HashIDPreimageXDR_contractID_roundTrip() throws {
        let original: HashIDPreimageXDR = .contractID(HashIDPreimageContractIDXDR(networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32))))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageXDR_operationId_rejectsBareString() throws {
        XCTAssertThrowsError(try HashIDPreimageXDR.fromXdrJson("\"op_id\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HashIDPreimageXDR.op_id: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HashIDPreimageXDR")
            XCTAssertEqual(key, "op_id",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HashIDPreimageXDR_operationId_roundTrip() throws {
        let original: HashIDPreimageXDR = .operationId(OperationID(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(1234567), opNum: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try HashIDPreimageXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("HashIDPreimageXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "HashIDPreimageXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_HashIDPreimageXDR_revokeId_rejectsBareString() throws {
        XCTAssertThrowsError(try HashIDPreimageXDR.fromXdrJson("\"pool_revoke_op_id\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HashIDPreimageXDR.pool_revoke_op_id: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HashIDPreimageXDR")
            XCTAssertEqual(key, "pool_revoke_op_id",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HashIDPreimageXDR_revokeId_roundTrip() throws {
        let original: HashIDPreimageXDR = .revokeId(RevokeID(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(1234567), opNum: UInt32(42), liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), asset: .native))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageXDR_sorobanAuthorizationWithAddress_rejectsBareString() throws {
        XCTAssertThrowsError(try HashIDPreimageXDR.fromXdrJson("\"soroban_authorization_with_address\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HashIDPreimageXDR.soroban_authorization_with_address: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HashIDPreimageXDR")
            XCTAssertEqual(key, "soroban_authorization_with_address",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HashIDPreimageXDR_sorobanAuthorizationWithAddress_roundTrip() throws {
        let original: HashIDPreimageXDR = .sorobanAuthorizationWithAddress(HashIDPreimageSorobanAuthorizationWithAddressXDR(networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), invocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: [])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageXDR must reach the same bytes through JSON and XDR")
    }

    func test_HashIDPreimageXDR_sorobanAuthorization_rejectsBareString() throws {
        XCTAssertThrowsError(try HashIDPreimageXDR.fromXdrJson("\"soroban_authorization\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HashIDPreimageXDR.soroban_authorization: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HashIDPreimageXDR")
            XCTAssertEqual(key, "soroban_authorization",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HashIDPreimageXDR_sorobanAuthorization_roundTrip() throws {
        let original: HashIDPreimageXDR = .sorobanAuthorization(HashIDPreimageSorobanAuthorizationXDR(networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), invocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: [])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HashIDPreimageXDR.fromXdrJson(json)
        let viaValue = try HashIDPreimageXDR.fromXdrJsonValue(tree)
        let viaTree = try HashIDPreimageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HashIDPreimageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HashIDPreimageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HashIDPreimageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HashIDPreimageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HashIDPreimageXDR must reach the same bytes through JSON and XDR")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_CREATE_CONTRACT() throws {
        let value: HostFunctionType = .createContract
        XCTAssertEqual(try value.toXdrJson(), "\"create_contract\"",
                       "HostFunctionType.createContract must render as create_contract")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "HostFunctionType.createContract must keep its XDR value")
        XCTAssertEqual(try HostFunctionType.fromXdrJson("\"create_contract\""), value,
                       "create_contract must read back as HostFunctionType.createContract")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2() throws {
        let value: HostFunctionType = .createContractV2
        XCTAssertEqual(try value.toXdrJson(), "\"create_contract_v2\"",
                       "HostFunctionType.createContractV2 must render as create_contract_v2")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "HostFunctionType.createContractV2 must keep its XDR value")
        XCTAssertEqual(try HostFunctionType.fromXdrJson("\"create_contract_v2\""), value,
                       "create_contract_v2 must read back as HostFunctionType.createContractV2")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_INVOKE_CONTRACT() throws {
        let value: HostFunctionType = .invokeContract
        XCTAssertEqual(try value.toXdrJson(), "\"invoke_contract\"",
                       "HostFunctionType.invokeContract must render as invoke_contract")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "HostFunctionType.invokeContract must keep its XDR value")
        XCTAssertEqual(try HostFunctionType.fromXdrJson("\"invoke_contract\""), value,
                       "invoke_contract must read back as HostFunctionType.invokeContract")
    }

    func test_HostFunctionType_HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM() throws {
        let value: HostFunctionType = .uploadContractWasm
        XCTAssertEqual(try value.toXdrJson(), "\"upload_contract_wasm\"",
                       "HostFunctionType.uploadContractWasm must render as upload_contract_wasm")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "HostFunctionType.uploadContractWasm must keep its XDR value")
        XCTAssertEqual(try HostFunctionType.fromXdrJson("\"upload_contract_wasm\""), value,
                       "upload_contract_wasm must read back as HostFunctionType.uploadContractWasm")
    }

    func test_HostFunctionType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try HostFunctionType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("HostFunctionType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "HostFunctionType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_HostFunctionXDR_createContractV2_rejectsBareString() throws {
        XCTAssertThrowsError(try HostFunctionXDR.fromXdrJson("\"create_contract_v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HostFunctionXDR.create_contract_v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HostFunctionXDR")
            XCTAssertEqual(key, "create_contract_v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HostFunctionXDR_createContractV2_roundTrip() throws {
        let original: HostFunctionXDR = .createContractV2(CreateContractV2ArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token, constructorArgs: [.void]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HostFunctionXDR.fromXdrJson(json)
        let viaValue = try HostFunctionXDR.fromXdrJsonValue(tree)
        let viaTree = try HostFunctionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HostFunctionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HostFunctionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HostFunctionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HostFunctionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HostFunctionXDR must reach the same bytes through JSON and XDR")
    }

    func test_HostFunctionXDR_createContract_rejectsBareString() throws {
        XCTAssertThrowsError(try HostFunctionXDR.fromXdrJson("\"create_contract\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HostFunctionXDR.create_contract: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HostFunctionXDR")
            XCTAssertEqual(key, "create_contract",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HostFunctionXDR_createContract_roundTrip() throws {
        let original: HostFunctionXDR = .createContract(CreateContractArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HostFunctionXDR.fromXdrJson(json)
        let viaValue = try HostFunctionXDR.fromXdrJsonValue(tree)
        let viaTree = try HostFunctionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HostFunctionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HostFunctionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HostFunctionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HostFunctionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HostFunctionXDR must reach the same bytes through JSON and XDR")
    }

    func test_HostFunctionXDR_invokeContract_rejectsBareString() throws {
        XCTAssertThrowsError(try HostFunctionXDR.fromXdrJson("\"invoke_contract\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HostFunctionXDR.invoke_contract: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HostFunctionXDR")
            XCTAssertEqual(key, "invoke_contract",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HostFunctionXDR_invokeContract_roundTrip() throws {
        let original: HostFunctionXDR = .invokeContract(InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: [.void]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HostFunctionXDR.fromXdrJson(json)
        let viaValue = try HostFunctionXDR.fromXdrJsonValue(tree)
        let viaTree = try HostFunctionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HostFunctionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HostFunctionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HostFunctionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HostFunctionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HostFunctionXDR must reach the same bytes through JSON and XDR")
    }

    func test_HostFunctionXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try HostFunctionXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("HostFunctionXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "HostFunctionXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_HostFunctionXDR_uploadContractWasm_rejectsBareString() throws {
        XCTAssertThrowsError(try HostFunctionXDR.fromXdrJson("\"upload_contract_wasm\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("HostFunctionXDR.upload_contract_wasm: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "HostFunctionXDR")
            XCTAssertEqual(key, "upload_contract_wasm",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_HostFunctionXDR_uploadContractWasm_roundTrip() throws {
        let original: HostFunctionXDR = .uploadContractWasm(Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HostFunctionXDR.fromXdrJson(json)
        let viaValue = try HostFunctionXDR.fromXdrJsonValue(tree)
        let viaTree = try HostFunctionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HostFunctionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HostFunctionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HostFunctionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HostFunctionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HostFunctionXDR must reach the same bytes through JSON and XDR")
    }

    func test_InflationPayoutXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try InflationPayoutXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "InflationPayoutXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_InflationPayoutXDR_roundTrip() throws {
        let original: InflationPayoutXDR = InflationPayoutXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), amount: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InflationPayoutXDR.fromXdrJson(json)
        let viaValue = try InflationPayoutXDR.fromXdrJsonValue(tree)
        let viaTree = try InflationPayoutXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InflationPayoutXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InflationPayoutXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InflationPayoutXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InflationPayoutXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InflationPayoutXDR must reach the same bytes through JSON and XDR")
    }

    func test_InflationResultCode_INFLATION_NOT_TIME() throws {
        let value: InflationResultCode = .notTime
        XCTAssertEqual(try value.toXdrJson(), "\"not_time\"",
                       "InflationResultCode.notTime must render as not_time")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "InflationResultCode.notTime must keep its XDR value")
        XCTAssertEqual(try InflationResultCode.fromXdrJson("\"not_time\""), value,
                       "not_time must read back as InflationResultCode.notTime")
    }

    func test_InflationResultCode_INFLATION_SUCCESS() throws {
        let value: InflationResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "InflationResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "InflationResultCode.success must keep its XDR value")
        XCTAssertEqual(try InflationResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as InflationResultCode.success")
    }

    func test_InflationResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try InflationResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("InflationResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "InflationResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_InflationResultXDR_notTime_roundTrip() throws {
        let original: InflationResultXDR = .notTime
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InflationResultXDR.fromXdrJson(json)
        let viaValue = try InflationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InflationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InflationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InflationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InflationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InflationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InflationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InflationResultXDR_payouts_rejectsBareString() throws {
        XCTAssertThrowsError(try InflationResultXDR.fromXdrJson("\"success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("InflationResultXDR.success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "InflationResultXDR")
            XCTAssertEqual(key, "success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_InflationResultXDR_payouts_roundTrip() throws {
        let original: InflationResultXDR = .payouts([InflationPayoutXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), amount: Int64(1234567))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InflationResultXDR.fromXdrJson(json)
        let viaValue = try InflationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InflationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InflationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InflationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InflationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InflationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InflationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InflationResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try InflationResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("InflationResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "InflationResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_InnerTransactionResultBodyXDR_badAuthExtra_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .badAuthExtra
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_badAuth_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .badAuth
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_badMinSeqAgeOrGap_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .badMinSeqAgeOrGap
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_badSeq_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .badSeq
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_badSponsorship_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .badSponsorship
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_failed_rejectsBareString() throws {
        XCTAssertThrowsError(try InnerTransactionResultBodyXDR.fromXdrJson("\"tx_failed\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("InnerTransactionResultBodyXDR.tx_failed: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "InnerTransactionResultBodyXDR")
            XCTAssertEqual(key, "tx_failed",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_InnerTransactionResultBodyXDR_failed_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .failed([.badAuth])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_frozenKeyAccessed_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .frozenKeyAccessed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_insufficientBalance_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .insufficientBalance
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_insufficientFee_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .insufficientFee
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_internalError_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .internalError
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_malformed_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_missingOperation_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .missingOperation
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_noAccount_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .noAccount
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_notSupported_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .notSupported
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try InnerTransactionResultBodyXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("InnerTransactionResultBodyXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "InnerTransactionResultBodyXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_InnerTransactionResultBodyXDR_sorobanInvalid_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .sorobanInvalid
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_success_rejectsBareString() throws {
        XCTAssertThrowsError(try InnerTransactionResultBodyXDR.fromXdrJson("\"tx_success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("InnerTransactionResultBodyXDR.tx_success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "InnerTransactionResultBodyXDR")
            XCTAssertEqual(key, "tx_success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_InnerTransactionResultBodyXDR_success_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .success([.badAuth])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_tooEarly_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .tooEarly
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultBodyXDR_tooLate_roundTrip() throws {
        let original: InnerTransactionResultBodyXDR = .tooLate
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultPair_rejectsWrongShape() throws {
        XCTAssertThrowsError(try InnerTransactionResultPair.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "InnerTransactionResultPair must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_InnerTransactionResultPair_roundTrip() throws {
        let original: InnerTransactionResultPair = InnerTransactionResultPair(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: InnerTransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultPair.fromXdrJson(json)
        let viaValue = try InnerTransactionResultPair.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultPair.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultPair must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultPair must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultPair must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultPair must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultPair must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try InnerTransactionResultXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("InnerTransactionResultXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "InnerTransactionResultXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_InnerTransactionResultXDRExtXDR_void_roundTrip() throws {
        let original: InnerTransactionResultXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultXDRExtXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_InnerTransactionResultXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try InnerTransactionResultXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "InnerTransactionResultXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_InnerTransactionResultXDR_roundTrip() throws {
        let original: InnerTransactionResultXDR = InnerTransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InnerTransactionResultXDR.fromXdrJson(json)
        let viaValue = try InnerTransactionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InnerTransactionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InnerTransactionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InnerTransactionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InnerTransactionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InnerTransactionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InnerTransactionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeContractArgsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try InvokeContractArgsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "InvokeContractArgsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_InvokeContractArgsXDR_roundTrip() throws {
        let original: InvokeContractArgsXDR = InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: [.void])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeContractArgsXDR.fromXdrJson(json)
        let viaValue = try InvokeContractArgsXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeContractArgsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeContractArgsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeContractArgsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeContractArgsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeContractArgsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeContractArgsXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try InvokeHostFunctionOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "InvokeHostFunctionOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_InvokeHostFunctionOpXDR_roundTrip() throws {
        let original: InvokeHostFunctionOpXDR = InvokeHostFunctionOpXDR(hostFunction: .invokeContract(InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: [.void])), auth: [SorobanAuthorizationEntryXDR(credentials: .sourceAccount, rootInvocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionOpXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionOpXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionResultCode_INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED() throws {
        let value: InvokeHostFunctionResultCode = .entryArchived
        XCTAssertEqual(try value.toXdrJson(), "\"entry_archived\"",
                       "InvokeHostFunctionResultCode.entryArchived must render as entry_archived")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "InvokeHostFunctionResultCode.entryArchived must keep its XDR value")
        XCTAssertEqual(try InvokeHostFunctionResultCode.fromXdrJson("\"entry_archived\""), value,
                       "entry_archived must read back as InvokeHostFunctionResultCode.entryArchived")
    }

    func test_InvokeHostFunctionResultCode_INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE() throws {
        let value: InvokeHostFunctionResultCode = .insufficientRefundableFee
        XCTAssertEqual(try value.toXdrJson(), "\"insufficient_refundable_fee\"",
                       "InvokeHostFunctionResultCode.insufficientRefundableFee must render as insufficient_refundable_fee")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "InvokeHostFunctionResultCode.insufficientRefundableFee must keep its XDR value")
        XCTAssertEqual(try InvokeHostFunctionResultCode.fromXdrJson("\"insufficient_refundable_fee\""), value,
                       "insufficient_refundable_fee must read back as InvokeHostFunctionResultCode.insufficientRefundableFee")
    }

    func test_InvokeHostFunctionResultCode_INVOKE_HOST_FUNCTION_MALFORMED() throws {
        let value: InvokeHostFunctionResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "InvokeHostFunctionResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "InvokeHostFunctionResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try InvokeHostFunctionResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as InvokeHostFunctionResultCode.malformed")
    }

    func test_InvokeHostFunctionResultCode_INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED() throws {
        let value: InvokeHostFunctionResultCode = .resourceLimitExceeded
        XCTAssertEqual(try value.toXdrJson(), "\"resource_limit_exceeded\"",
                       "InvokeHostFunctionResultCode.resourceLimitExceeded must render as resource_limit_exceeded")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "InvokeHostFunctionResultCode.resourceLimitExceeded must keep its XDR value")
        XCTAssertEqual(try InvokeHostFunctionResultCode.fromXdrJson("\"resource_limit_exceeded\""), value,
                       "resource_limit_exceeded must read back as InvokeHostFunctionResultCode.resourceLimitExceeded")
    }

    func test_InvokeHostFunctionResultCode_INVOKE_HOST_FUNCTION_SUCCESS() throws {
        let value: InvokeHostFunctionResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "InvokeHostFunctionResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "InvokeHostFunctionResultCode.success must keep its XDR value")
        XCTAssertEqual(try InvokeHostFunctionResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as InvokeHostFunctionResultCode.success")
    }

    func test_InvokeHostFunctionResultCode_INVOKE_HOST_FUNCTION_TRAPPED() throws {
        let value: InvokeHostFunctionResultCode = .trapped
        XCTAssertEqual(try value.toXdrJson(), "\"trapped\"",
                       "InvokeHostFunctionResultCode.trapped must render as trapped")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "InvokeHostFunctionResultCode.trapped must keep its XDR value")
        XCTAssertEqual(try InvokeHostFunctionResultCode.fromXdrJson("\"trapped\""), value,
                       "trapped must read back as InvokeHostFunctionResultCode.trapped")
    }

    func test_InvokeHostFunctionResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try InvokeHostFunctionResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("InvokeHostFunctionResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "InvokeHostFunctionResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_InvokeHostFunctionResultXDR_entryArchived_roundTrip() throws {
        let original: InvokeHostFunctionResultXDR = .entryArchived
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionResultXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionResultXDR_insufficientRefundableFee_roundTrip() throws {
        let original: InvokeHostFunctionResultXDR = .insufficientRefundableFee
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionResultXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionResultXDR_malformed_roundTrip() throws {
        let original: InvokeHostFunctionResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionResultXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try InvokeHostFunctionResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("InvokeHostFunctionResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "InvokeHostFunctionResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_InvokeHostFunctionResultXDR_resourceLimitExceeded_roundTrip() throws {
        let original: InvokeHostFunctionResultXDR = .resourceLimitExceeded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionResultXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionResultXDR_success_rejectsBareString() throws {
        XCTAssertThrowsError(try InvokeHostFunctionResultXDR.fromXdrJson("\"success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("InvokeHostFunctionResultXDR.success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "InvokeHostFunctionResultXDR")
            XCTAssertEqual(key, "success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_InvokeHostFunctionResultXDR_success_roundTrip() throws {
        let original: InvokeHostFunctionResultXDR = .success(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionResultXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_InvokeHostFunctionResultXDR_trapped_roundTrip() throws {
        let original: InvokeHostFunctionResultXDR = .trapped
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try InvokeHostFunctionResultXDR.fromXdrJson(json)
        let viaValue = try InvokeHostFunctionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try InvokeHostFunctionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "InvokeHostFunctionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "InvokeHostFunctionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "InvokeHostFunctionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerBoundsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerBoundsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerBoundsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerBoundsXDR_roundTrip() throws {
        let original: LedgerBoundsXDR = LedgerBoundsXDR(minLedger: UInt32(42), maxLedger: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerBoundsXDR.fromXdrJson(json)
        let viaValue = try LedgerBoundsXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerBoundsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerBoundsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerBoundsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerBoundsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerBoundsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerBoundsXDR must reach the same bytes through JSON and XDR")
    }

    func test_LedgerFootprintXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LedgerFootprintXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LedgerFootprintXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LedgerFootprintXDR_roundTrip() throws {
        let original: LedgerFootprintXDR = LedgerFootprintXDR(readOnly: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))], readWrite: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LedgerFootprintXDR.fromXdrJson(json)
        let viaValue = try LedgerFootprintXDR.fromXdrJsonValue(tree)
        let viaTree = try LedgerFootprintXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LedgerFootprintXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LedgerFootprintXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LedgerFootprintXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LedgerFootprintXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LedgerFootprintXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LiquidityPoolDepositOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LiquidityPoolDepositOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LiquidityPoolDepositOpXDR_roundTrip() throws {
        let original: LiquidityPoolDepositOpXDR = LiquidityPoolDepositOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), maxAmountA: Int64(1234567), maxAmountB: Int64(1234567), minPrice: PriceXDR(n: Int32(42), d: Int32(42)), maxPrice: PriceXDR(n: Int32(42), d: Int32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositOpXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositOpXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_BAD_PRICE() throws {
        let value: LiquidityPoolDepositResulCode = .badPrice
        XCTAssertEqual(try value.toXdrJson(), "\"bad_price\"",
                       "LiquidityPoolDepositResulCode.badPrice must render as bad_price")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "LiquidityPoolDepositResulCode.badPrice must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"bad_price\""), value,
                       "bad_price must read back as LiquidityPoolDepositResulCode.badPrice")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_LINE_FULL() throws {
        let value: LiquidityPoolDepositResulCode = .lineFull
        XCTAssertEqual(try value.toXdrJson(), "\"line_full\"",
                       "LiquidityPoolDepositResulCode.lineFull must render as line_full")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "LiquidityPoolDepositResulCode.lineFull must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"line_full\""), value,
                       "line_full must read back as LiquidityPoolDepositResulCode.lineFull")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_MALFORMED() throws {
        let value: LiquidityPoolDepositResulCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "LiquidityPoolDepositResulCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "LiquidityPoolDepositResulCode.malformed must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as LiquidityPoolDepositResulCode.malformed")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_NOT_AUTHORIZED() throws {
        let value: LiquidityPoolDepositResulCode = .notAuthorized
        XCTAssertEqual(try value.toXdrJson(), "\"not_authorized\"",
                       "LiquidityPoolDepositResulCode.notAuthorized must render as not_authorized")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "LiquidityPoolDepositResulCode.notAuthorized must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"not_authorized\""), value,
                       "not_authorized must read back as LiquidityPoolDepositResulCode.notAuthorized")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_NO_TRUST() throws {
        let value: LiquidityPoolDepositResulCode = .noTrust
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust\"",
                       "LiquidityPoolDepositResulCode.noTrust must render as no_trust")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "LiquidityPoolDepositResulCode.noTrust must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"no_trust\""), value,
                       "no_trust must read back as LiquidityPoolDepositResulCode.noTrust")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_POOL_FULL() throws {
        let value: LiquidityPoolDepositResulCode = .poolFull
        XCTAssertEqual(try value.toXdrJson(), "\"pool_full\"",
                       "LiquidityPoolDepositResulCode.poolFull must render as pool_full")
        XCTAssertEqual(value.rawValue, Int32(-7),
                       "LiquidityPoolDepositResulCode.poolFull must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"pool_full\""), value,
                       "pool_full must read back as LiquidityPoolDepositResulCode.poolFull")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_SUCCESS() throws {
        let value: LiquidityPoolDepositResulCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "LiquidityPoolDepositResulCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "LiquidityPoolDepositResulCode.success must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"success\""), value,
                       "success must read back as LiquidityPoolDepositResulCode.success")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_TRUSTLINE_FROZEN() throws {
        let value: LiquidityPoolDepositResulCode = .trustlineFrozen
        XCTAssertEqual(try value.toXdrJson(), "\"trustline_frozen\"",
                       "LiquidityPoolDepositResulCode.trustlineFrozen must render as trustline_frozen")
        XCTAssertEqual(value.rawValue, Int32(-8),
                       "LiquidityPoolDepositResulCode.trustlineFrozen must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"trustline_frozen\""), value,
                       "trustline_frozen must read back as LiquidityPoolDepositResulCode.trustlineFrozen")
    }

    func test_LiquidityPoolDepositResulCode_LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED() throws {
        let value: LiquidityPoolDepositResulCode = .underfunded
        XCTAssertEqual(try value.toXdrJson(), "\"underfunded\"",
                       "LiquidityPoolDepositResulCode.underfunded must render as underfunded")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "LiquidityPoolDepositResulCode.underfunded must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolDepositResulCode.fromXdrJson("\"underfunded\""), value,
                       "underfunded must read back as LiquidityPoolDepositResulCode.underfunded")
    }

    func test_LiquidityPoolDepositResulCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try LiquidityPoolDepositResulCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("LiquidityPoolDepositResulCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolDepositResulCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_LiquidityPoolDepositResultXDR_badPrice_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .badPrice
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_lineFull_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .lineFull
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_malformed_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_noTrust_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .noTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_notAuthorized_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .notAuthorized
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_poolFull_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .poolFull
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LiquidityPoolDepositResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LiquidityPoolDepositResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolDepositResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LiquidityPoolDepositResultXDR_success_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_trustlineFrozen_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .trustlineFrozen
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolDepositResultXDR_underfunded_roundTrip() throws {
        let original: LiquidityPoolDepositResultXDR = .underfunded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolDepositResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolDepositResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolDepositResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolDepositResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolDepositResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolDepositResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolParametersXDR_constantProduct_rejectsBareString() throws {
        XCTAssertThrowsError(try LiquidityPoolParametersXDR.fromXdrJson("\"liquidity_pool_constant_product\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("LiquidityPoolParametersXDR.liquidity_pool_constant_product: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolParametersXDR")
            XCTAssertEqual(key, "liquidity_pool_constant_product",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_LiquidityPoolParametersXDR_constantProduct_roundTrip() throws {
        let original: LiquidityPoolParametersXDR = .constantProduct(LiquidityPoolConstantProductParametersXDR(assetA: .native, assetB: .native, fee: Int32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolParametersXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolParametersXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolParametersXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolParametersXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolParametersXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolParametersXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolParametersXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolParametersXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolParametersXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LiquidityPoolParametersXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LiquidityPoolParametersXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolParametersXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LiquidityPoolWithdrawOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try LiquidityPoolWithdrawOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "LiquidityPoolWithdrawOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_LiquidityPoolWithdrawOpXDR_roundTrip() throws {
        let original: LiquidityPoolWithdrawOpXDR = LiquidityPoolWithdrawOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), amount: Int64(1234567), minAmountA: Int64(1234567), minAmountB: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawOpXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawOpXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolWithdrawResulCode_LIQUIDITY_POOL_WITHDRAW_LINE_FULL() throws {
        let value: LiquidityPoolWithdrawResulCode = .lineFull
        XCTAssertEqual(try value.toXdrJson(), "\"line_full\"",
                       "LiquidityPoolWithdrawResulCode.lineFull must render as line_full")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "LiquidityPoolWithdrawResulCode.lineFull must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"line_full\""), value,
                       "line_full must read back as LiquidityPoolWithdrawResulCode.lineFull")
    }

    func test_LiquidityPoolWithdrawResulCode_LIQUIDITY_POOL_WITHDRAW_MALFORMED() throws {
        let value: LiquidityPoolWithdrawResulCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "LiquidityPoolWithdrawResulCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "LiquidityPoolWithdrawResulCode.malformed must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as LiquidityPoolWithdrawResulCode.malformed")
    }

    func test_LiquidityPoolWithdrawResulCode_LIQUIDITY_POOL_WITHDRAW_NO_TRUST() throws {
        let value: LiquidityPoolWithdrawResulCode = .noTrust
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust\"",
                       "LiquidityPoolWithdrawResulCode.noTrust must render as no_trust")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "LiquidityPoolWithdrawResulCode.noTrust must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"no_trust\""), value,
                       "no_trust must read back as LiquidityPoolWithdrawResulCode.noTrust")
    }

    func test_LiquidityPoolWithdrawResulCode_LIQUIDITY_POOL_WITHDRAW_SUCCESS() throws {
        let value: LiquidityPoolWithdrawResulCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "LiquidityPoolWithdrawResulCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "LiquidityPoolWithdrawResulCode.success must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"success\""), value,
                       "success must read back as LiquidityPoolWithdrawResulCode.success")
    }

    func test_LiquidityPoolWithdrawResulCode_LIQUIDITY_POOL_WITHDRAW_TRUSTLINE_FROZEN() throws {
        let value: LiquidityPoolWithdrawResulCode = .trustlineFrozen
        XCTAssertEqual(try value.toXdrJson(), "\"trustline_frozen\"",
                       "LiquidityPoolWithdrawResulCode.trustlineFrozen must render as trustline_frozen")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "LiquidityPoolWithdrawResulCode.trustlineFrozen must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"trustline_frozen\""), value,
                       "trustline_frozen must read back as LiquidityPoolWithdrawResulCode.trustlineFrozen")
    }

    func test_LiquidityPoolWithdrawResulCode_LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED() throws {
        let value: LiquidityPoolWithdrawResulCode = .underfunded
        XCTAssertEqual(try value.toXdrJson(), "\"underfunded\"",
                       "LiquidityPoolWithdrawResulCode.underfunded must render as underfunded")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "LiquidityPoolWithdrawResulCode.underfunded must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"underfunded\""), value,
                       "underfunded must read back as LiquidityPoolWithdrawResulCode.underfunded")
    }

    func test_LiquidityPoolWithdrawResulCode_LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM() throws {
        let value: LiquidityPoolWithdrawResulCode = .underMinimum
        XCTAssertEqual(try value.toXdrJson(), "\"under_minimum\"",
                       "LiquidityPoolWithdrawResulCode.underMinimum must render as under_minimum")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "LiquidityPoolWithdrawResulCode.underMinimum must keep its XDR value")
        XCTAssertEqual(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"under_minimum\""), value,
                       "under_minimum must read back as LiquidityPoolWithdrawResulCode.underMinimum")
    }

    func test_LiquidityPoolWithdrawResulCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try LiquidityPoolWithdrawResulCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("LiquidityPoolWithdrawResulCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolWithdrawResulCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_LiquidityPoolWithdrawResultXDR_lineFull_roundTrip() throws {
        let original: LiquidityPoolWithdrawResultXDR = .lineFull
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolWithdrawResultXDR_malformed_roundTrip() throws {
        let original: LiquidityPoolWithdrawResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolWithdrawResultXDR_noTrust_roundTrip() throws {
        let original: LiquidityPoolWithdrawResultXDR = .noTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolWithdrawResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try LiquidityPoolWithdrawResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("LiquidityPoolWithdrawResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "LiquidityPoolWithdrawResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_LiquidityPoolWithdrawResultXDR_success_roundTrip() throws {
        let original: LiquidityPoolWithdrawResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolWithdrawResultXDR_trustlineFrozen_roundTrip() throws {
        let original: LiquidityPoolWithdrawResultXDR = .trustlineFrozen
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolWithdrawResultXDR_underMinimum_roundTrip() throws {
        let original: LiquidityPoolWithdrawResultXDR = .underMinimum
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_LiquidityPoolWithdrawResultXDR_underfunded_roundTrip() throws {
        let original: LiquidityPoolWithdrawResultXDR = .underfunded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try LiquidityPoolWithdrawResultXDR.fromXdrJson(json)
        let viaValue = try LiquidityPoolWithdrawResultXDR.fromXdrJsonValue(tree)
        let viaTree = try LiquidityPoolWithdrawResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "LiquidityPoolWithdrawResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "LiquidityPoolWithdrawResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "LiquidityPoolWithdrawResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageDataOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ManageDataOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ManageDataOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ManageDataOperationXDR_roundTrip() throws {
        let original: ManageDataOperationXDR = ManageDataOperationXDR(dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageDataOperationXDR.fromXdrJson(json)
        let viaValue = try ManageDataOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageDataOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageDataOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageDataOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageDataOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageDataOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageDataOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageDataResultCode_MANAGE_DATA_INVALID_NAME() throws {
        let value: ManageDataResultCode = .invalidName
        XCTAssertEqual(try value.toXdrJson(), "\"invalid_name\"",
                       "ManageDataResultCode.invalidName must render as invalid_name")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "ManageDataResultCode.invalidName must keep its XDR value")
        XCTAssertEqual(try ManageDataResultCode.fromXdrJson("\"invalid_name\""), value,
                       "invalid_name must read back as ManageDataResultCode.invalidName")
    }

    func test_ManageDataResultCode_MANAGE_DATA_LOW_RESERVE() throws {
        let value: ManageDataResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "ManageDataResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "ManageDataResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try ManageDataResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as ManageDataResultCode.lowReserve")
    }

    func test_ManageDataResultCode_MANAGE_DATA_NAME_NOT_FOUND() throws {
        let value: ManageDataResultCode = .nameNotFound
        XCTAssertEqual(try value.toXdrJson(), "\"name_not_found\"",
                       "ManageDataResultCode.nameNotFound must render as name_not_found")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "ManageDataResultCode.nameNotFound must keep its XDR value")
        XCTAssertEqual(try ManageDataResultCode.fromXdrJson("\"name_not_found\""), value,
                       "name_not_found must read back as ManageDataResultCode.nameNotFound")
    }

    func test_ManageDataResultCode_MANAGE_DATA_NOT_SUPPORTED_YET() throws {
        let value: ManageDataResultCode = .notSupportedYet
        XCTAssertEqual(try value.toXdrJson(), "\"not_supported_yet\"",
                       "ManageDataResultCode.notSupportedYet must render as not_supported_yet")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "ManageDataResultCode.notSupportedYet must keep its XDR value")
        XCTAssertEqual(try ManageDataResultCode.fromXdrJson("\"not_supported_yet\""), value,
                       "not_supported_yet must read back as ManageDataResultCode.notSupportedYet")
    }

    func test_ManageDataResultCode_MANAGE_DATA_SUCCESS() throws {
        let value: ManageDataResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "ManageDataResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ManageDataResultCode.success must keep its XDR value")
        XCTAssertEqual(try ManageDataResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as ManageDataResultCode.success")
    }

    func test_ManageDataResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ManageDataResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ManageDataResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ManageDataResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ManageDataResultXDR_invalidName_roundTrip() throws {
        let original: ManageDataResultXDR = .invalidName
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageDataResultXDR.fromXdrJson(json)
        let viaValue = try ManageDataResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageDataResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageDataResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageDataResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageDataResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageDataResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageDataResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageDataResultXDR_lowReserve_roundTrip() throws {
        let original: ManageDataResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageDataResultXDR.fromXdrJson(json)
        let viaValue = try ManageDataResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageDataResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageDataResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageDataResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageDataResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageDataResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageDataResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageDataResultXDR_nameNotFound_roundTrip() throws {
        let original: ManageDataResultXDR = .nameNotFound
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageDataResultXDR.fromXdrJson(json)
        let viaValue = try ManageDataResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageDataResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageDataResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageDataResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageDataResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageDataResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageDataResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageDataResultXDR_notSupportedYet_roundTrip() throws {
        let original: ManageDataResultXDR = .notSupportedYet
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageDataResultXDR.fromXdrJson(json)
        let viaValue = try ManageDataResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageDataResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageDataResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageDataResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageDataResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageDataResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageDataResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageDataResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ManageDataResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ManageDataResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ManageDataResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ManageDataResultXDR_success_roundTrip() throws {
        let original: ManageDataResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageDataResultXDR.fromXdrJson(json)
        let viaValue = try ManageDataResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageDataResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageDataResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageDataResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageDataResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageDataResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageDataResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferEffect_MANAGE_OFFER_CREATED() throws {
        let value: ManageOfferEffect = .created
        XCTAssertEqual(try value.toXdrJson(), "\"created\"",
                       "ManageOfferEffect.created must render as created")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ManageOfferEffect.created must keep its XDR value")
        XCTAssertEqual(try ManageOfferEffect.fromXdrJson("\"created\""), value,
                       "created must read back as ManageOfferEffect.created")
    }

    func test_ManageOfferEffect_MANAGE_OFFER_DELETED() throws {
        let value: ManageOfferEffect = .deleted
        XCTAssertEqual(try value.toXdrJson(), "\"deleted\"",
                       "ManageOfferEffect.deleted must render as deleted")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ManageOfferEffect.deleted must keep its XDR value")
        XCTAssertEqual(try ManageOfferEffect.fromXdrJson("\"deleted\""), value,
                       "deleted must read back as ManageOfferEffect.deleted")
    }

    func test_ManageOfferEffect_MANAGE_OFFER_UPDATED() throws {
        let value: ManageOfferEffect = .updated
        XCTAssertEqual(try value.toXdrJson(), "\"updated\"",
                       "ManageOfferEffect.updated must render as updated")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ManageOfferEffect.updated must keep its XDR value")
        XCTAssertEqual(try ManageOfferEffect.fromXdrJson("\"updated\""), value,
                       "updated must read back as ManageOfferEffect.updated")
    }

    func test_ManageOfferEffect_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ManageOfferEffect.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ManageOfferEffect: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ManageOfferEffect")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_BUY_NOT_AUTHORIZED() throws {
        let value: ManageOfferResultCode = .buyNotAuthorized
        XCTAssertEqual(try value.toXdrJson(), "\"buy_not_authorized\"",
                       "ManageOfferResultCode.buyNotAuthorized must render as buy_not_authorized")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "ManageOfferResultCode.buyNotAuthorized must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"buy_not_authorized\""), value,
                       "buy_not_authorized must read back as ManageOfferResultCode.buyNotAuthorized")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_BUY_NO_ISSUER() throws {
        let value: ManageOfferResultCode = .buyNoIssuer
        XCTAssertEqual(try value.toXdrJson(), "\"buy_no_issuer\"",
                       "ManageOfferResultCode.buyNoIssuer must render as buy_no_issuer")
        XCTAssertEqual(value.rawValue, Int32(-10),
                       "ManageOfferResultCode.buyNoIssuer must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"buy_no_issuer\""), value,
                       "buy_no_issuer must read back as ManageOfferResultCode.buyNoIssuer")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_BUY_NO_TRUST() throws {
        let value: ManageOfferResultCode = .buyNoTrust
        XCTAssertEqual(try value.toXdrJson(), "\"buy_no_trust\"",
                       "ManageOfferResultCode.buyNoTrust must render as buy_no_trust")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "ManageOfferResultCode.buyNoTrust must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"buy_no_trust\""), value,
                       "buy_no_trust must read back as ManageOfferResultCode.buyNoTrust")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_CROSS_SELF() throws {
        let value: ManageOfferResultCode = .crossSelf
        XCTAssertEqual(try value.toXdrJson(), "\"cross_self\"",
                       "ManageOfferResultCode.crossSelf must render as cross_self")
        XCTAssertEqual(value.rawValue, Int32(-8),
                       "ManageOfferResultCode.crossSelf must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"cross_self\""), value,
                       "cross_self must read back as ManageOfferResultCode.crossSelf")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_LINE_FULL() throws {
        let value: ManageOfferResultCode = .lineFull
        XCTAssertEqual(try value.toXdrJson(), "\"line_full\"",
                       "ManageOfferResultCode.lineFull must render as line_full")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "ManageOfferResultCode.lineFull must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"line_full\""), value,
                       "line_full must read back as ManageOfferResultCode.lineFull")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_LOW_RESERVE() throws {
        let value: ManageOfferResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "ManageOfferResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-12),
                       "ManageOfferResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as ManageOfferResultCode.lowReserve")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_MALFORMED() throws {
        let value: ManageOfferResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "ManageOfferResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "ManageOfferResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as ManageOfferResultCode.malformed")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_NOT_FOUND() throws {
        let value: ManageOfferResultCode = .notFound
        XCTAssertEqual(try value.toXdrJson(), "\"not_found\"",
                       "ManageOfferResultCode.notFound must render as not_found")
        XCTAssertEqual(value.rawValue, Int32(-11),
                       "ManageOfferResultCode.notFound must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"not_found\""), value,
                       "not_found must read back as ManageOfferResultCode.notFound")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_SELL_NOT_AUTHORIZED() throws {
        let value: ManageOfferResultCode = .sellNotAuthorized
        XCTAssertEqual(try value.toXdrJson(), "\"sell_not_authorized\"",
                       "ManageOfferResultCode.sellNotAuthorized must render as sell_not_authorized")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "ManageOfferResultCode.sellNotAuthorized must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"sell_not_authorized\""), value,
                       "sell_not_authorized must read back as ManageOfferResultCode.sellNotAuthorized")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_SELL_NO_ISSUER() throws {
        let value: ManageOfferResultCode = .sellNoIssuer
        XCTAssertEqual(try value.toXdrJson(), "\"sell_no_issuer\"",
                       "ManageOfferResultCode.sellNoIssuer must render as sell_no_issuer")
        XCTAssertEqual(value.rawValue, Int32(-9),
                       "ManageOfferResultCode.sellNoIssuer must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"sell_no_issuer\""), value,
                       "sell_no_issuer must read back as ManageOfferResultCode.sellNoIssuer")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_SELL_NO_TRUST() throws {
        let value: ManageOfferResultCode = .sellNoTrust
        XCTAssertEqual(try value.toXdrJson(), "\"sell_no_trust\"",
                       "ManageOfferResultCode.sellNoTrust must render as sell_no_trust")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "ManageOfferResultCode.sellNoTrust must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"sell_no_trust\""), value,
                       "sell_no_trust must read back as ManageOfferResultCode.sellNoTrust")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_SUCCESS() throws {
        let value: ManageOfferResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "ManageOfferResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ManageOfferResultCode.success must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as ManageOfferResultCode.success")
    }

    func test_ManageOfferResultCode_MANAGE_SELL_OFFER_UNDERFUNDED() throws {
        let value: ManageOfferResultCode = .underfunded
        XCTAssertEqual(try value.toXdrJson(), "\"underfunded\"",
                       "ManageOfferResultCode.underfunded must render as underfunded")
        XCTAssertEqual(value.rawValue, Int32(-7),
                       "ManageOfferResultCode.underfunded must keep its XDR value")
        XCTAssertEqual(try ManageOfferResultCode.fromXdrJson("\"underfunded\""), value,
                       "underfunded must read back as ManageOfferResultCode.underfunded")
    }

    func test_ManageOfferResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ManageOfferResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ManageOfferResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ManageOfferResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ManageOfferResultXDR_buyNoIssuer_roundTrip() throws {
        let original: ManageOfferResultXDR = .buyNoIssuer
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_buyNoTrust_roundTrip() throws {
        let original: ManageOfferResultXDR = .buyNoTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_buyNotAuthorized_roundTrip() throws {
        let original: ManageOfferResultXDR = .buyNotAuthorized
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_crossSelf_roundTrip() throws {
        let original: ManageOfferResultXDR = .crossSelf
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_lineFull_roundTrip() throws {
        let original: ManageOfferResultXDR = .lineFull
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_lowReserve_roundTrip() throws {
        let original: ManageOfferResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_malformed_roundTrip() throws {
        let original: ManageOfferResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_notFound_roundTrip() throws {
        let original: ManageOfferResultXDR = .notFound
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ManageOfferResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ManageOfferResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ManageOfferResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ManageOfferResultXDR_sellNoIssuer_roundTrip() throws {
        let original: ManageOfferResultXDR = .sellNoIssuer
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_sellNoTrust_roundTrip() throws {
        let original: ManageOfferResultXDR = .sellNoTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_sellNotAuthorized_roundTrip() throws {
        let original: ManageOfferResultXDR = .sellNotAuthorized
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_success_rejectsBareString() throws {
        XCTAssertThrowsError(try ManageOfferResultXDR.fromXdrJson("\"success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ManageOfferResultXDR.success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ManageOfferResultXDR")
            XCTAssertEqual(key, "success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ManageOfferResultXDR_success_roundTrip() throws {
        let original: ManageOfferResultXDR = .success(ManageOfferSuccessResultXDR(offersClaimed: [.v0(ClaimOfferAtomV0XDR(sellerEd25519: WrappedData32(Data(repeating: 0xAB, count: 32)), offerId: Int64(1234567), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567)))], offer: .deleted))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferResultXDR_underfunded_roundTrip() throws {
        let original: ManageOfferResultXDR = .underfunded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferSuccessResultOfferXDR_created_rejectsBareString() throws {
        XCTAssertThrowsError(try ManageOfferSuccessResultOfferXDR.fromXdrJson("\"created\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ManageOfferSuccessResultOfferXDR.created: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ManageOfferSuccessResultOfferXDR")
            XCTAssertEqual(key, "created",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ManageOfferSuccessResultOfferXDR_created_roundTrip() throws {
        let original: ManageOfferSuccessResultOfferXDR = .created(OfferEntryXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: UInt64(1234567), selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42)), flags: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferSuccessResultOfferXDR.fromXdrJson(json)
        let viaValue = try ManageOfferSuccessResultOfferXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferSuccessResultOfferXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferSuccessResultOfferXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferSuccessResultOfferXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferSuccessResultOfferXDR_deleted_roundTrip() throws {
        let original: ManageOfferSuccessResultOfferXDR = .deleted
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferSuccessResultOfferXDR.fromXdrJson(json)
        let viaValue = try ManageOfferSuccessResultOfferXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferSuccessResultOfferXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferSuccessResultOfferXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferSuccessResultOfferXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferSuccessResultOfferXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ManageOfferSuccessResultOfferXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ManageOfferSuccessResultOfferXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ManageOfferSuccessResultOfferXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ManageOfferSuccessResultOfferXDR_updated_rejectsBareString() throws {
        XCTAssertThrowsError(try ManageOfferSuccessResultOfferXDR.fromXdrJson("\"updated\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("ManageOfferSuccessResultOfferXDR.updated: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "ManageOfferSuccessResultOfferXDR")
            XCTAssertEqual(key, "updated",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_ManageOfferSuccessResultOfferXDR_updated_roundTrip() throws {
        let original: ManageOfferSuccessResultOfferXDR = .updated(OfferEntryXDR(sellerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), offerID: UInt64(1234567), selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42)), flags: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferSuccessResultOfferXDR.fromXdrJson(json)
        let viaValue = try ManageOfferSuccessResultOfferXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferSuccessResultOfferXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferSuccessResultOfferXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferSuccessResultOfferXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferSuccessResultOfferXDR must reach the same bytes through JSON and XDR")
    }

    func test_ManageOfferSuccessResultXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ManageOfferSuccessResultXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ManageOfferSuccessResultXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ManageOfferSuccessResultXDR_roundTrip() throws {
        let original: ManageOfferSuccessResultXDR = ManageOfferSuccessResultXDR(offersClaimed: [.v0(ClaimOfferAtomV0XDR(sellerEd25519: WrappedData32(Data(repeating: 0xAB, count: 32)), offerId: Int64(1234567), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567)))], offer: .deleted)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ManageOfferSuccessResultXDR.fromXdrJson(json)
        let viaValue = try ManageOfferSuccessResultXDR.fromXdrJsonValue(tree)
        let viaTree = try ManageOfferSuccessResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ManageOfferSuccessResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ManageOfferSuccessResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ManageOfferSuccessResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ManageOfferSuccessResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ManageOfferSuccessResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_MemoType_MEMO_HASH() throws {
        let value: MemoType = .MEMO_TYPE_HASH
        XCTAssertEqual(try value.toXdrJson(), "\"hash\"",
                       "MemoType.MEMO_TYPE_HASH must render as hash")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "MemoType.MEMO_TYPE_HASH must keep its XDR value")
        XCTAssertEqual(try MemoType.fromXdrJson("\"hash\""), value,
                       "hash must read back as MemoType.MEMO_TYPE_HASH")
    }

    func test_MemoType_MEMO_ID() throws {
        let value: MemoType = .MEMO_TYPE_ID
        XCTAssertEqual(try value.toXdrJson(), "\"id\"",
                       "MemoType.MEMO_TYPE_ID must render as id")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "MemoType.MEMO_TYPE_ID must keep its XDR value")
        XCTAssertEqual(try MemoType.fromXdrJson("\"id\""), value,
                       "id must read back as MemoType.MEMO_TYPE_ID")
    }

    func test_MemoType_MEMO_NONE() throws {
        let value: MemoType = .MEMO_TYPE_NONE
        XCTAssertEqual(try value.toXdrJson(), "\"none\"",
                       "MemoType.MEMO_TYPE_NONE must render as none")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "MemoType.MEMO_TYPE_NONE must keep its XDR value")
        XCTAssertEqual(try MemoType.fromXdrJson("\"none\""), value,
                       "none must read back as MemoType.MEMO_TYPE_NONE")
    }

    func test_MemoType_MEMO_RETURN() throws {
        let value: MemoType = .MEMO_TYPE_RETURN
        XCTAssertEqual(try value.toXdrJson(), "\"return\"",
                       "MemoType.MEMO_TYPE_RETURN must render as return")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "MemoType.MEMO_TYPE_RETURN must keep its XDR value")
        XCTAssertEqual(try MemoType.fromXdrJson("\"return\""), value,
                       "return must read back as MemoType.MEMO_TYPE_RETURN")
    }

    func test_MemoType_MEMO_TEXT() throws {
        let value: MemoType = .MEMO_TYPE_TEXT
        XCTAssertEqual(try value.toXdrJson(), "\"text\"",
                       "MemoType.MEMO_TYPE_TEXT must render as text")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "MemoType.MEMO_TYPE_TEXT must keep its XDR value")
        XCTAssertEqual(try MemoType.fromXdrJson("\"text\""), value,
                       "text must read back as MemoType.MEMO_TYPE_TEXT")
    }

    func test_MemoType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try MemoType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("MemoType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "MemoType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_MemoXDR_hash_rejectsBareString() throws {
        XCTAssertThrowsError(try MemoXDR.fromXdrJson("\"hash\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("MemoXDR.hash: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "MemoXDR")
            XCTAssertEqual(key, "hash",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_MemoXDR_hash_roundTrip() throws {
        let original: MemoXDR = .hash(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MemoXDR.fromXdrJson(json)
        let viaValue = try MemoXDR.fromXdrJsonValue(tree)
        let viaTree = try MemoXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MemoXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MemoXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MemoXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MemoXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MemoXDR must reach the same bytes through JSON and XDR")
    }

    func test_MemoXDR_id_rejectsBareString() throws {
        XCTAssertThrowsError(try MemoXDR.fromXdrJson("\"id\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("MemoXDR.id: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "MemoXDR")
            XCTAssertEqual(key, "id",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_MemoXDR_id_roundTrip() throws {
        let original: MemoXDR = .id(UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MemoXDR.fromXdrJson(json)
        let viaValue = try MemoXDR.fromXdrJsonValue(tree)
        let viaTree = try MemoXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MemoXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MemoXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MemoXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MemoXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MemoXDR must reach the same bytes through JSON and XDR")
    }

    func test_MemoXDR_none_roundTrip() throws {
        let original: MemoXDR = .none
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MemoXDR.fromXdrJson(json)
        let viaValue = try MemoXDR.fromXdrJsonValue(tree)
        let viaTree = try MemoXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MemoXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MemoXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MemoXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MemoXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MemoXDR must reach the same bytes through JSON and XDR")
    }

    func test_MemoXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try MemoXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("MemoXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "MemoXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_MemoXDR_returnHash_rejectsBareString() throws {
        XCTAssertThrowsError(try MemoXDR.fromXdrJson("\"return\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("MemoXDR.return: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "MemoXDR")
            XCTAssertEqual(key, "return",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_MemoXDR_returnHash_roundTrip() throws {
        let original: MemoXDR = .returnHash(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MemoXDR.fromXdrJson(json)
        let viaValue = try MemoXDR.fromXdrJsonValue(tree)
        let viaTree = try MemoXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MemoXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MemoXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MemoXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MemoXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MemoXDR must reach the same bytes through JSON and XDR")
    }

    func test_MemoXDR_text_rejectsBareString() throws {
        XCTAssertThrowsError(try MemoXDR.fromXdrJson("\"text\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("MemoXDR.text: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "MemoXDR")
            XCTAssertEqual(key, "text",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_MemoXDR_text_roundTrip() throws {
        let original: MemoXDR = .text("test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MemoXDR.fromXdrJson(json)
        let viaValue = try MemoXDR.fromXdrJsonValue(tree)
        let viaTree = try MemoXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MemoXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MemoXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MemoXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MemoXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MemoXDR must reach the same bytes through JSON and XDR")
    }

    func test_MuxedAccountXDRMed25519XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try MuxedAccountXDRMed25519XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "MuxedAccountXDRMed25519XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_MuxedAccountXDRMed25519XDR_roundTrip() throws {
        let original: MuxedAccountXDRMed25519XDR = MuxedAccountXDRMed25519XDR(id: UInt64(1234567), ed25519: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MuxedAccountXDRMed25519XDR.fromXdrJson(json)
        let viaValue = try MuxedAccountXDRMed25519XDR.fromXdrJsonValue(tree)
        let viaTree = try MuxedAccountXDRMed25519XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MuxedAccountXDRMed25519XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MuxedAccountXDRMed25519XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MuxedAccountXDRMed25519XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MuxedAccountXDRMed25519XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MuxedAccountXDRMed25519XDR must reach the same bytes through JSON and XDR")
    }

    func test_MuxedAccountXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try MuxedAccountXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "MuxedAccountXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_MuxedAccountXDR_roundTrip() throws {
        let original: MuxedAccountXDR = .ed25519([UInt8](repeating: 0xAB, count: 32))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try MuxedAccountXDR.fromXdrJson(json)
        let viaValue = try MuxedAccountXDR.fromXdrJsonValue(tree)
        let viaTree = try MuxedAccountXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "MuxedAccountXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "MuxedAccountXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "MuxedAccountXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "MuxedAccountXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "MuxedAccountXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_accountMerge_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"account_merge\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.account_merge: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "account_merge",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_accountMerge_roundTrip() throws {
        let original: OperationBodyXDR = .accountMerge(.ed25519([UInt8](repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_allowTrustOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"allow_trust\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.allow_trust: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "allow_trust",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_allowTrustOp_roundTrip() throws {
        let original: OperationBodyXDR = .allowTrustOp(AllowTrustOperationXDR(trustor: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .alphanum4(WrappedData4(Data(repeating: 0xAB, count: 4))), authorize: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_beginSponsoringFutureReservesOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"begin_sponsoring_future_reserves\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.begin_sponsoring_future_reserves: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "begin_sponsoring_future_reserves",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_beginSponsoringFutureReservesOp_roundTrip() throws {
        let original: OperationBodyXDR = .beginSponsoringFutureReservesOp(BeginSponsoringFutureReservesOpXDR(sponsoredId: try PublicKey([UInt8](repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_bumpSequenceOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"bump_sequence\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.bump_sequence: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "bump_sequence",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_bumpSequenceOp_roundTrip() throws {
        let original: OperationBodyXDR = .bumpSequenceOp(BumpSequenceOperationXDR(bumpTo: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_changeTrustOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"change_trust\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.change_trust: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "change_trust",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_changeTrustOp_roundTrip() throws {
        let original: OperationBodyXDR = .changeTrustOp(ChangeTrustOperationXDR(asset: .native, limit: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_claimClaimableBalanceOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"claim_claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.claim_claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "claim_claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_claimClaimableBalanceOp_roundTrip() throws {
        let original: OperationBodyXDR = .claimClaimableBalanceOp(ClaimClaimableBalanceOpXDR(balanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_clawbackClaimableBalanceOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"clawback_claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.clawback_claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "clawback_claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_clawbackClaimableBalanceOp_roundTrip() throws {
        let original: OperationBodyXDR = .clawbackClaimableBalanceOp(ClawbackClaimableBalanceOpXDR(claimableBalanceID: .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_clawbackOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"clawback\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.clawback: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "clawback",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_clawbackOp_roundTrip() throws {
        let original: OperationBodyXDR = .clawbackOp(ClawbackOpXDR(asset: .native, from: .ed25519([UInt8](repeating: 0xAB, count: 32)), amount: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_createAccountOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"create_account\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.create_account: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "create_account",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_createAccountOp_roundTrip() throws {
        let original: OperationBodyXDR = .createAccountOp(CreateAccountOperationXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), balance: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_createClaimableBalanceOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"create_claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.create_claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "create_claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_createClaimableBalanceOp_roundTrip() throws {
        let original: OperationBodyXDR = .createClaimableBalanceOp(CreateClaimableBalanceOpXDR(asset: .native, amount: Int64(1234567), claimants: [.claimantTypeV0(ClaimantV0XDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), predicate: .claimPredicateUnconditional))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_createPassiveSellOfferOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"create_passive_sell_offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.create_passive_sell_offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "create_passive_sell_offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_createPassiveSellOfferOp_roundTrip() throws {
        let original: OperationBodyXDR = .createPassiveSellOfferOp(CreatePassiveOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_endSponsoringFutureReserves_roundTrip() throws {
        let original: OperationBodyXDR = .endSponsoringFutureReserves
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_extendFootprintTTLOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"extend_footprint_ttl\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.extend_footprint_ttl: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "extend_footprint_ttl",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_extendFootprintTTLOp_roundTrip() throws {
        let original: OperationBodyXDR = .extendFootprintTTLOp(ExtendFootprintTTLOpXDR(ext: .void, extendTo: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_inflation_roundTrip() throws {
        let original: OperationBodyXDR = .inflation
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_invokeHostFunctionOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"invoke_host_function\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.invoke_host_function: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "invoke_host_function",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_invokeHostFunctionOp_roundTrip() throws {
        let original: OperationBodyXDR = .invokeHostFunctionOp(InvokeHostFunctionOpXDR(hostFunction: .invokeContract(InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: [.void])), auth: [SorobanAuthorizationEntryXDR(credentials: .sourceAccount, rootInvocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: []))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_liquidityPoolDepositOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"liquidity_pool_deposit\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.liquidity_pool_deposit: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "liquidity_pool_deposit",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_liquidityPoolDepositOp_roundTrip() throws {
        let original: OperationBodyXDR = .liquidityPoolDepositOp(LiquidityPoolDepositOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), maxAmountA: Int64(1234567), maxAmountB: Int64(1234567), minPrice: PriceXDR(n: Int32(42), d: Int32(42)), maxPrice: PriceXDR(n: Int32(42), d: Int32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_liquidityPoolWithdrawOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"liquidity_pool_withdraw\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.liquidity_pool_withdraw: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "liquidity_pool_withdraw",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_liquidityPoolWithdrawOp_roundTrip() throws {
        let original: OperationBodyXDR = .liquidityPoolWithdrawOp(LiquidityPoolWithdrawOpXDR(liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), amount: Int64(1234567), minAmountA: Int64(1234567), minAmountB: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_manageBuyOfferOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"manage_buy_offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.manage_buy_offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "manage_buy_offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_manageBuyOfferOp_roundTrip() throws {
        let original: OperationBodyXDR = .manageBuyOfferOp(ManageOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42)), offerID: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_manageDataOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"manage_data\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.manage_data: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "manage_data",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_manageDataOp_roundTrip() throws {
        let original: OperationBodyXDR = .manageDataOp(ManageDataOperationXDR(dataName: "test_string", dataValue: Data([0x01, 0x02, 0x03])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_manageSellOfferOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"manage_sell_offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.manage_sell_offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "manage_sell_offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_manageSellOfferOp_roundTrip() throws {
        let original: OperationBodyXDR = .manageSellOfferOp(ManageOfferOperationXDR(selling: .native, buying: .native, amount: Int64(1234567), price: PriceXDR(n: Int32(42), d: Int32(42)), offerID: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_pathPaymentStrictReceiveOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"path_payment_strict_receive\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.path_payment_strict_receive: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "path_payment_strict_receive",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_pathPaymentStrictReceiveOp_roundTrip() throws {
        let original: OperationBodyXDR = .pathPaymentStrictReceiveOp(PathPaymentOperationXDR(sendAsset: .native, sendMax: Int64(1234567), destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), destinationAsset: .native, destinationAmount: Int64(1234567), path: [.native]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_pathPaymentStrictSendOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"path_payment_strict_send\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.path_payment_strict_send: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "path_payment_strict_send",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_pathPaymentStrictSendOp_roundTrip() throws {
        let original: OperationBodyXDR = .pathPaymentStrictSendOp(PathPaymentOperationXDR(sendAsset: .native, sendMax: Int64(1234567), destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), destinationAsset: .native, destinationAmount: Int64(1234567), path: [.native]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_paymentOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"payment\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.payment: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "payment",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_paymentOp_roundTrip() throws {
        let original: OperationBodyXDR = .paymentOp(PaymentOperationXDR(destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), asset: .native, amount: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("OperationBodyXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_OperationBodyXDR_restoreFootprintOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"restore_footprint\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.restore_footprint: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "restore_footprint",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_restoreFootprintOp_roundTrip() throws {
        let original: OperationBodyXDR = .restoreFootprintOp(RestoreFootprintOpXDR(ext: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_revokeSponsorshipOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"revoke_sponsorship\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.revoke_sponsorship: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "revoke_sponsorship",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_revokeSponsorshipOp_roundTrip() throws {
        let original: OperationBodyXDR = .revokeSponsorshipOp(.revokeSponsorshipLedgerEntry(.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_setOptionsOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"set_options\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.set_options: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "set_options",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_setOptionsOp_roundTrip() throws {
        let original: OperationBodyXDR = .setOptionsOp(SetOptionsOperationXDR(inflationDestination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), clearFlags: UInt32(42), setFlags: UInt32(42), masterWeight: UInt32(42), lowThreshold: UInt32(42), medThreshold: UInt32(42), highThreshold: UInt32(42), homeDomain: "test_string", signer: SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))), weight: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationBodyXDR_setTrustLineFlagsOp_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationBodyXDR.fromXdrJson("\"set_trust_line_flags\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationBodyXDR.set_trust_line_flags: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationBodyXDR")
            XCTAssertEqual(key, "set_trust_line_flags",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationBodyXDR_setTrustLineFlagsOp_roundTrip() throws {
        let original: OperationBodyXDR = .setTrustLineFlagsOp(SetTrustLineFlagsOpXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, setFlags: UInt32(42), clearFlags: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationBodyXDR.fromXdrJson(json)
        let viaValue = try OperationBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationID_rejectsWrongShape() throws {
        XCTAssertThrowsError(try OperationID.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "OperationID must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_OperationID_roundTrip() throws {
        let original: OperationID = OperationID(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(1234567), opNum: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationID.fromXdrJson(json)
        let viaValue = try OperationID.fromXdrJsonValue(tree)
        let viaTree = try OperationID.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationID must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationID must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationID must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationID must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationID must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultCode_opBAD_AUTH() throws {
        let value: OperationResultCode = .badAuth
        XCTAssertEqual(try value.toXdrJson(), "\"op_bad_auth\"",
                       "OperationResultCode.badAuth must render as op_bad_auth")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "OperationResultCode.badAuth must keep its XDR value")
        XCTAssertEqual(try OperationResultCode.fromXdrJson("\"op_bad_auth\""), value,
                       "op_bad_auth must read back as OperationResultCode.badAuth")
    }

    func test_OperationResultCode_opEXCEEDED_WORK_LIMIT() throws {
        let value: OperationResultCode = .exceededWorkLimit
        XCTAssertEqual(try value.toXdrJson(), "\"op_exceeded_work_limit\"",
                       "OperationResultCode.exceededWorkLimit must render as op_exceeded_work_limit")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "OperationResultCode.exceededWorkLimit must keep its XDR value")
        XCTAssertEqual(try OperationResultCode.fromXdrJson("\"op_exceeded_work_limit\""), value,
                       "op_exceeded_work_limit must read back as OperationResultCode.exceededWorkLimit")
    }

    func test_OperationResultCode_opINNER() throws {
        let value: OperationResultCode = .inner
        XCTAssertEqual(try value.toXdrJson(), "\"op_inner\"",
                       "OperationResultCode.inner must render as op_inner")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "OperationResultCode.inner must keep its XDR value")
        XCTAssertEqual(try OperationResultCode.fromXdrJson("\"op_inner\""), value,
                       "op_inner must read back as OperationResultCode.inner")
    }

    func test_OperationResultCode_opNOT_SUPPORTED() throws {
        let value: OperationResultCode = .notSupported
        XCTAssertEqual(try value.toXdrJson(), "\"op_not_supported\"",
                       "OperationResultCode.notSupported must render as op_not_supported")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "OperationResultCode.notSupported must keep its XDR value")
        XCTAssertEqual(try OperationResultCode.fromXdrJson("\"op_not_supported\""), value,
                       "op_not_supported must read back as OperationResultCode.notSupported")
    }

    func test_OperationResultCode_opNO_ACCOUNT() throws {
        let value: OperationResultCode = .noAccount
        XCTAssertEqual(try value.toXdrJson(), "\"op_no_account\"",
                       "OperationResultCode.noAccount must render as op_no_account")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "OperationResultCode.noAccount must keep its XDR value")
        XCTAssertEqual(try OperationResultCode.fromXdrJson("\"op_no_account\""), value,
                       "op_no_account must read back as OperationResultCode.noAccount")
    }

    func test_OperationResultCode_opTOO_MANY_SPONSORING() throws {
        let value: OperationResultCode = .tooManySponsoring
        XCTAssertEqual(try value.toXdrJson(), "\"op_too_many_sponsoring\"",
                       "OperationResultCode.tooManySponsoring must render as op_too_many_sponsoring")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "OperationResultCode.tooManySponsoring must keep its XDR value")
        XCTAssertEqual(try OperationResultCode.fromXdrJson("\"op_too_many_sponsoring\""), value,
                       "op_too_many_sponsoring must read back as OperationResultCode.tooManySponsoring")
    }

    func test_OperationResultCode_opTOO_MANY_SUBENTRIES() throws {
        let value: OperationResultCode = .tooManySubentries
        XCTAssertEqual(try value.toXdrJson(), "\"op_too_many_subentries\"",
                       "OperationResultCode.tooManySubentries must render as op_too_many_subentries")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "OperationResultCode.tooManySubentries must keep its XDR value")
        XCTAssertEqual(try OperationResultCode.fromXdrJson("\"op_too_many_subentries\""), value,
                       "op_too_many_subentries must read back as OperationResultCode.tooManySubentries")
    }

    func test_OperationResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try OperationResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("OperationResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_OperationResultXDRTrXDR_accountMergeResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"account_merge\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.account_merge: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "account_merge",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_accountMergeResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .accountMergeResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_allowTrustResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"allow_trust\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.allow_trust: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "allow_trust",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_allowTrustResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .allowTrustResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_beginSponsoringFutureReservesResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"begin_sponsoring_future_reserves\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.begin_sponsoring_future_reserves: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "begin_sponsoring_future_reserves",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_beginSponsoringFutureReservesResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .beginSponsoringFutureReservesResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_bumpSeqResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"bump_sequence\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.bump_sequence: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "bump_sequence",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_bumpSeqResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .bumpSeqResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_changeTrustResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"change_trust\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.change_trust: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "change_trust",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_changeTrustResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .changeTrustResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_claimClaimableBalanceResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"claim_claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.claim_claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "claim_claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_claimClaimableBalanceResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .claimClaimableBalanceResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_clawbackClaimableBalanceResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"clawback_claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.clawback_claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "clawback_claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_clawbackClaimableBalanceResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .clawbackClaimableBalanceResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_clawbackResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"clawback\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.clawback: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "clawback",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_clawbackResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .clawbackResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_createAccountResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"create_account\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.create_account: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "create_account",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_createAccountResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .createAccountResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_createClaimableBalanceResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"create_claimable_balance\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.create_claimable_balance: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "create_claimable_balance",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_createClaimableBalanceResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .createClaimableBalanceResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_createPassiveSellOfferResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"create_passive_sell_offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.create_passive_sell_offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "create_passive_sell_offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_createPassiveSellOfferResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .createPassiveSellOfferResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_endSponsoringFutureReservesResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"end_sponsoring_future_reserves\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.end_sponsoring_future_reserves: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "end_sponsoring_future_reserves",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_endSponsoringFutureReservesResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .endSponsoringFutureReservesResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_extendFootprintTTLResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"extend_footprint_ttl\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.extend_footprint_ttl: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "extend_footprint_ttl",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_extendFootprintTTLResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .extendFootprintTTLResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_inflationResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"inflation\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.inflation: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "inflation",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_inflationResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .inflationResult(.notTime)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_invokeHostFunctionResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"invoke_host_function\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.invoke_host_function: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "invoke_host_function",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_invokeHostFunctionResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .invokeHostFunctionResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_liquidityPoolDepositResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"liquidity_pool_deposit\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.liquidity_pool_deposit: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "liquidity_pool_deposit",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_liquidityPoolDepositResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .liquidityPoolDepositResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_liquidityPoolWithdrawResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"liquidity_pool_withdraw\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.liquidity_pool_withdraw: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "liquidity_pool_withdraw",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_liquidityPoolWithdrawResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .liquidityPoolWithdrawResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_manageBuyOfferResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"manage_buy_offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.manage_buy_offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "manage_buy_offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_manageBuyOfferResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .manageBuyOfferResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_manageDataResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"manage_data\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.manage_data: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "manage_data",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_manageDataResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .manageDataResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_manageSellOfferResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"manage_sell_offer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.manage_sell_offer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "manage_sell_offer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_manageSellOfferResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .manageSellOfferResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_pathPaymentStrictReceiveResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"path_payment_strict_receive\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.path_payment_strict_receive: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "path_payment_strict_receive",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_pathPaymentStrictReceiveResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .pathPaymentStrictReceiveResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_pathPaymentStrictSendResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"path_payment_strict_send\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.path_payment_strict_send: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "path_payment_strict_send",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_pathPaymentStrictSendResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .pathPaymentStrictSendResult(.malformed)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_paymentResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"payment\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.payment: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "payment",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_paymentResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .paymentResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("OperationResultXDRTrXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_OperationResultXDRTrXDR_restoreFootprintResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"restore_footprint\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.restore_footprint: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "restore_footprint",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_restoreFootprintResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .restoreFootprintResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_revokeSponsorshipResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"revoke_sponsorship\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.revoke_sponsorship: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "revoke_sponsorship",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_revokeSponsorshipResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .revokeSponsorshipResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_setOptionsResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"set_options\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.set_options: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "set_options",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_setOptionsResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .setOptionsResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDRTrXDR_setTrustLineFlagsResult_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDRTrXDR.fromXdrJson("\"set_trust_line_flags\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDRTrXDR.set_trust_line_flags: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDRTrXDR")
            XCTAssertEqual(key, "set_trust_line_flags",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDRTrXDR_setTrustLineFlagsResult_roundTrip() throws {
        let original: OperationResultXDRTrXDR = .setTrustLineFlagsResult(.success)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDRTrXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDRTrXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDRTrXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDRTrXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDRTrXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDRTrXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDRTrXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDR_badAuth_roundTrip() throws {
        let original: OperationResultXDR = .badAuth
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDR_exceededWorkLimit_roundTrip() throws {
        let original: OperationResultXDR = .exceededWorkLimit
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDR_noAccount_roundTrip() throws {
        let original: OperationResultXDR = .noAccount
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDR_notSupported_roundTrip() throws {
        let original: OperationResultXDR = .notSupported
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try OperationResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("OperationResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_OperationResultXDR_tooManySponsoring_roundTrip() throws {
        let original: OperationResultXDR = .tooManySponsoring
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDR_tooManySubentries_roundTrip() throws {
        let original: OperationResultXDR = .tooManySubentries
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationResultXDR_tr_rejectsBareString() throws {
        XCTAssertThrowsError(try OperationResultXDR.fromXdrJson("\"op_inner\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("OperationResultXDR.op_inner: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationResultXDR")
            XCTAssertEqual(key, "op_inner",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_OperationResultXDR_tr_roundTrip() throws {
        let original: OperationResultXDR = .tr(.createAccountResult(.success))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationResultXDR.fromXdrJson(json)
        let viaValue = try OperationResultXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_OperationType_ACCOUNT_MERGE() throws {
        let value: OperationType = .accountMerge
        XCTAssertEqual(try value.toXdrJson(), "\"account_merge\"",
                       "OperationType.accountMerge must render as account_merge")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "OperationType.accountMerge must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"account_merge\""), value,
                       "account_merge must read back as OperationType.accountMerge")
    }

    func test_OperationType_ALLOW_TRUST() throws {
        let value: OperationType = .allowTrust
        XCTAssertEqual(try value.toXdrJson(), "\"allow_trust\"",
                       "OperationType.allowTrust must render as allow_trust")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "OperationType.allowTrust must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"allow_trust\""), value,
                       "allow_trust must read back as OperationType.allowTrust")
    }

    func test_OperationType_BEGIN_SPONSORING_FUTURE_RESERVES() throws {
        let value: OperationType = .beginSponsoringFutureReserves
        XCTAssertEqual(try value.toXdrJson(), "\"begin_sponsoring_future_reserves\"",
                       "OperationType.beginSponsoringFutureReserves must render as begin_sponsoring_future_reserves")
        XCTAssertEqual(value.rawValue, Int32(16),
                       "OperationType.beginSponsoringFutureReserves must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"begin_sponsoring_future_reserves\""), value,
                       "begin_sponsoring_future_reserves must read back as OperationType.beginSponsoringFutureReserves")
    }

    func test_OperationType_BUMP_SEQUENCE() throws {
        let value: OperationType = .bumpSequence
        XCTAssertEqual(try value.toXdrJson(), "\"bump_sequence\"",
                       "OperationType.bumpSequence must render as bump_sequence")
        XCTAssertEqual(value.rawValue, Int32(11),
                       "OperationType.bumpSequence must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"bump_sequence\""), value,
                       "bump_sequence must read back as OperationType.bumpSequence")
    }

    func test_OperationType_CHANGE_TRUST() throws {
        let value: OperationType = .changeTrust
        XCTAssertEqual(try value.toXdrJson(), "\"change_trust\"",
                       "OperationType.changeTrust must render as change_trust")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "OperationType.changeTrust must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"change_trust\""), value,
                       "change_trust must read back as OperationType.changeTrust")
    }

    func test_OperationType_CLAIM_CLAIMABLE_BALANCE() throws {
        let value: OperationType = .claimClaimableBalance
        XCTAssertEqual(try value.toXdrJson(), "\"claim_claimable_balance\"",
                       "OperationType.claimClaimableBalance must render as claim_claimable_balance")
        XCTAssertEqual(value.rawValue, Int32(15),
                       "OperationType.claimClaimableBalance must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"claim_claimable_balance\""), value,
                       "claim_claimable_balance must read back as OperationType.claimClaimableBalance")
    }

    func test_OperationType_CLAWBACK() throws {
        let value: OperationType = .clawback
        XCTAssertEqual(try value.toXdrJson(), "\"clawback\"",
                       "OperationType.clawback must render as clawback")
        XCTAssertEqual(value.rawValue, Int32(19),
                       "OperationType.clawback must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"clawback\""), value,
                       "clawback must read back as OperationType.clawback")
    }

    func test_OperationType_CLAWBACK_CLAIMABLE_BALANCE() throws {
        let value: OperationType = .clawbackClaimableBalance
        XCTAssertEqual(try value.toXdrJson(), "\"clawback_claimable_balance\"",
                       "OperationType.clawbackClaimableBalance must render as clawback_claimable_balance")
        XCTAssertEqual(value.rawValue, Int32(20),
                       "OperationType.clawbackClaimableBalance must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"clawback_claimable_balance\""), value,
                       "clawback_claimable_balance must read back as OperationType.clawbackClaimableBalance")
    }

    func test_OperationType_CREATE_ACCOUNT() throws {
        let value: OperationType = .accountCreated
        XCTAssertEqual(try value.toXdrJson(), "\"create_account\"",
                       "OperationType.accountCreated must render as create_account")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "OperationType.accountCreated must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"create_account\""), value,
                       "create_account must read back as OperationType.accountCreated")
    }

    func test_OperationType_CREATE_CLAIMABLE_BALANCE() throws {
        let value: OperationType = .createClaimableBalance
        XCTAssertEqual(try value.toXdrJson(), "\"create_claimable_balance\"",
                       "OperationType.createClaimableBalance must render as create_claimable_balance")
        XCTAssertEqual(value.rawValue, Int32(14),
                       "OperationType.createClaimableBalance must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"create_claimable_balance\""), value,
                       "create_claimable_balance must read back as OperationType.createClaimableBalance")
    }

    func test_OperationType_CREATE_PASSIVE_SELL_OFFER() throws {
        let value: OperationType = .createPassiveSellOffer
        XCTAssertEqual(try value.toXdrJson(), "\"create_passive_sell_offer\"",
                       "OperationType.createPassiveSellOffer must render as create_passive_sell_offer")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "OperationType.createPassiveSellOffer must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"create_passive_sell_offer\""), value,
                       "create_passive_sell_offer must read back as OperationType.createPassiveSellOffer")
    }

    func test_OperationType_END_SPONSORING_FUTURE_RESERVES() throws {
        let value: OperationType = .endSponsoringFutureReserves
        XCTAssertEqual(try value.toXdrJson(), "\"end_sponsoring_future_reserves\"",
                       "OperationType.endSponsoringFutureReserves must render as end_sponsoring_future_reserves")
        XCTAssertEqual(value.rawValue, Int32(17),
                       "OperationType.endSponsoringFutureReserves must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"end_sponsoring_future_reserves\""), value,
                       "end_sponsoring_future_reserves must read back as OperationType.endSponsoringFutureReserves")
    }

    func test_OperationType_EXTEND_FOOTPRINT_TTL() throws {
        let value: OperationType = .extendFootprintTTL
        XCTAssertEqual(try value.toXdrJson(), "\"extend_footprint_ttl\"",
                       "OperationType.extendFootprintTTL must render as extend_footprint_ttl")
        XCTAssertEqual(value.rawValue, Int32(25),
                       "OperationType.extendFootprintTTL must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"extend_footprint_ttl\""), value,
                       "extend_footprint_ttl must read back as OperationType.extendFootprintTTL")
    }

    func test_OperationType_INFLATION() throws {
        let value: OperationType = .inflation
        XCTAssertEqual(try value.toXdrJson(), "\"inflation\"",
                       "OperationType.inflation must render as inflation")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "OperationType.inflation must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"inflation\""), value,
                       "inflation must read back as OperationType.inflation")
    }

    func test_OperationType_INVOKE_HOST_FUNCTION() throws {
        let value: OperationType = .invokeHostFunction
        XCTAssertEqual(try value.toXdrJson(), "\"invoke_host_function\"",
                       "OperationType.invokeHostFunction must render as invoke_host_function")
        XCTAssertEqual(value.rawValue, Int32(24),
                       "OperationType.invokeHostFunction must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"invoke_host_function\""), value,
                       "invoke_host_function must read back as OperationType.invokeHostFunction")
    }

    func test_OperationType_LIQUIDITY_POOL_DEPOSIT() throws {
        let value: OperationType = .liquidityPoolDeposit
        XCTAssertEqual(try value.toXdrJson(), "\"liquidity_pool_deposit\"",
                       "OperationType.liquidityPoolDeposit must render as liquidity_pool_deposit")
        XCTAssertEqual(value.rawValue, Int32(22),
                       "OperationType.liquidityPoolDeposit must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"liquidity_pool_deposit\""), value,
                       "liquidity_pool_deposit must read back as OperationType.liquidityPoolDeposit")
    }

    func test_OperationType_LIQUIDITY_POOL_WITHDRAW() throws {
        let value: OperationType = .liquidityPoolWithdraw
        XCTAssertEqual(try value.toXdrJson(), "\"liquidity_pool_withdraw\"",
                       "OperationType.liquidityPoolWithdraw must render as liquidity_pool_withdraw")
        XCTAssertEqual(value.rawValue, Int32(23),
                       "OperationType.liquidityPoolWithdraw must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"liquidity_pool_withdraw\""), value,
                       "liquidity_pool_withdraw must read back as OperationType.liquidityPoolWithdraw")
    }

    func test_OperationType_MANAGE_BUY_OFFER() throws {
        let value: OperationType = .manageBuyOffer
        XCTAssertEqual(try value.toXdrJson(), "\"manage_buy_offer\"",
                       "OperationType.manageBuyOffer must render as manage_buy_offer")
        XCTAssertEqual(value.rawValue, Int32(12),
                       "OperationType.manageBuyOffer must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"manage_buy_offer\""), value,
                       "manage_buy_offer must read back as OperationType.manageBuyOffer")
    }

    func test_OperationType_MANAGE_DATA() throws {
        let value: OperationType = .manageData
        XCTAssertEqual(try value.toXdrJson(), "\"manage_data\"",
                       "OperationType.manageData must render as manage_data")
        XCTAssertEqual(value.rawValue, Int32(10),
                       "OperationType.manageData must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"manage_data\""), value,
                       "manage_data must read back as OperationType.manageData")
    }

    func test_OperationType_MANAGE_SELL_OFFER() throws {
        let value: OperationType = .manageSellOffer
        XCTAssertEqual(try value.toXdrJson(), "\"manage_sell_offer\"",
                       "OperationType.manageSellOffer must render as manage_sell_offer")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "OperationType.manageSellOffer must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"manage_sell_offer\""), value,
                       "manage_sell_offer must read back as OperationType.manageSellOffer")
    }

    func test_OperationType_PATH_PAYMENT_STRICT_RECEIVE() throws {
        let value: OperationType = .pathPayment
        XCTAssertEqual(try value.toXdrJson(), "\"path_payment_strict_receive\"",
                       "OperationType.pathPayment must render as path_payment_strict_receive")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "OperationType.pathPayment must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"path_payment_strict_receive\""), value,
                       "path_payment_strict_receive must read back as OperationType.pathPayment")
    }

    func test_OperationType_PATH_PAYMENT_STRICT_SEND() throws {
        let value: OperationType = .pathPaymentStrictSend
        XCTAssertEqual(try value.toXdrJson(), "\"path_payment_strict_send\"",
                       "OperationType.pathPaymentStrictSend must render as path_payment_strict_send")
        XCTAssertEqual(value.rawValue, Int32(13),
                       "OperationType.pathPaymentStrictSend must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"path_payment_strict_send\""), value,
                       "path_payment_strict_send must read back as OperationType.pathPaymentStrictSend")
    }

    func test_OperationType_PAYMENT() throws {
        let value: OperationType = .payment
        XCTAssertEqual(try value.toXdrJson(), "\"payment\"",
                       "OperationType.payment must render as payment")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "OperationType.payment must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"payment\""), value,
                       "payment must read back as OperationType.payment")
    }

    func test_OperationType_RESTORE_FOOTPRINT() throws {
        let value: OperationType = .restoreFootprint
        XCTAssertEqual(try value.toXdrJson(), "\"restore_footprint\"",
                       "OperationType.restoreFootprint must render as restore_footprint")
        XCTAssertEqual(value.rawValue, Int32(26),
                       "OperationType.restoreFootprint must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"restore_footprint\""), value,
                       "restore_footprint must read back as OperationType.restoreFootprint")
    }

    func test_OperationType_REVOKE_SPONSORSHIP() throws {
        let value: OperationType = .revokeSponsorship
        XCTAssertEqual(try value.toXdrJson(), "\"revoke_sponsorship\"",
                       "OperationType.revokeSponsorship must render as revoke_sponsorship")
        XCTAssertEqual(value.rawValue, Int32(18),
                       "OperationType.revokeSponsorship must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"revoke_sponsorship\""), value,
                       "revoke_sponsorship must read back as OperationType.revokeSponsorship")
    }

    func test_OperationType_SET_OPTIONS() throws {
        let value: OperationType = .setOptions
        XCTAssertEqual(try value.toXdrJson(), "\"set_options\"",
                       "OperationType.setOptions must render as set_options")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "OperationType.setOptions must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"set_options\""), value,
                       "set_options must read back as OperationType.setOptions")
    }

    func test_OperationType_SET_TRUST_LINE_FLAGS() throws {
        let value: OperationType = .setTrustLineFlags
        XCTAssertEqual(try value.toXdrJson(), "\"set_trust_line_flags\"",
                       "OperationType.setTrustLineFlags must render as set_trust_line_flags")
        XCTAssertEqual(value.rawValue, Int32(21),
                       "OperationType.setTrustLineFlags must keep its XDR value")
        XCTAssertEqual(try OperationType.fromXdrJson("\"set_trust_line_flags\""), value,
                       "set_trust_line_flags must read back as OperationType.setTrustLineFlags")
    }

    func test_OperationType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try OperationType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("OperationType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "OperationType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_OperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try OperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "OperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_OperationXDR_roundTrip() throws {
        let original: OperationXDR = OperationXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), body: .inflation)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try OperationXDR.fromXdrJson(json)
        let viaValue = try OperationXDR.fromXdrJsonValue(tree)
        let viaTree = try OperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "OperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "OperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "OperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "OperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "OperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_PathPaymentResultXDRSuccessXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PathPaymentResultXDRSuccessXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PathPaymentResultXDRSuccessXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PathPaymentResultXDRSuccessXDR_roundTrip() throws {
        let original: PathPaymentResultXDRSuccessXDR = PathPaymentResultXDRSuccessXDR(offers: [.v0(ClaimOfferAtomV0XDR(sellerEd25519: WrappedData32(Data(repeating: 0xAB, count: 32)), offerId: Int64(1234567), assetSold: .native, amountSold: Int64(1234567), assetBought: .native, amountBought: Int64(1234567)))], last: SimplePaymentResultXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, amount: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PathPaymentResultXDRSuccessXDR.fromXdrJson(json)
        let viaValue = try PathPaymentResultXDRSuccessXDR.fromXdrJsonValue(tree)
        let viaTree = try PathPaymentResultXDRSuccessXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PathPaymentResultXDRSuccessXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PathPaymentResultXDRSuccessXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PathPaymentResultXDRSuccessXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PathPaymentResultXDRSuccessXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PathPaymentResultXDRSuccessXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PaymentOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PaymentOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PaymentOperationXDR_roundTrip() throws {
        let original: PaymentOperationXDR = PaymentOperationXDR(destination: .ed25519([UInt8](repeating: 0xAB, count: 32)), asset: .native, amount: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentOperationXDR.fromXdrJson(json)
        let viaValue = try PaymentOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultCode_PAYMENT_LINE_FULL() throws {
        let value: PaymentResultCode = .lineFull
        XCTAssertEqual(try value.toXdrJson(), "\"line_full\"",
                       "PaymentResultCode.lineFull must render as line_full")
        XCTAssertEqual(value.rawValue, Int32(-8),
                       "PaymentResultCode.lineFull must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"line_full\""), value,
                       "line_full must read back as PaymentResultCode.lineFull")
    }

    func test_PaymentResultCode_PAYMENT_MALFORMED() throws {
        let value: PaymentResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "PaymentResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "PaymentResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as PaymentResultCode.malformed")
    }

    func test_PaymentResultCode_PAYMENT_NOT_AUTHORIZED() throws {
        let value: PaymentResultCode = .notAuthorized
        XCTAssertEqual(try value.toXdrJson(), "\"not_authorized\"",
                       "PaymentResultCode.notAuthorized must render as not_authorized")
        XCTAssertEqual(value.rawValue, Int32(-7),
                       "PaymentResultCode.notAuthorized must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"not_authorized\""), value,
                       "not_authorized must read back as PaymentResultCode.notAuthorized")
    }

    func test_PaymentResultCode_PAYMENT_NO_DESTINATION() throws {
        let value: PaymentResultCode = .noDestination
        XCTAssertEqual(try value.toXdrJson(), "\"no_destination\"",
                       "PaymentResultCode.noDestination must render as no_destination")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "PaymentResultCode.noDestination must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"no_destination\""), value,
                       "no_destination must read back as PaymentResultCode.noDestination")
    }

    func test_PaymentResultCode_PAYMENT_NO_ISSUER() throws {
        let value: PaymentResultCode = .noIssuer
        XCTAssertEqual(try value.toXdrJson(), "\"no_issuer\"",
                       "PaymentResultCode.noIssuer must render as no_issuer")
        XCTAssertEqual(value.rawValue, Int32(-9),
                       "PaymentResultCode.noIssuer must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"no_issuer\""), value,
                       "no_issuer must read back as PaymentResultCode.noIssuer")
    }

    func test_PaymentResultCode_PAYMENT_NO_TRUST() throws {
        let value: PaymentResultCode = .noTrust
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust\"",
                       "PaymentResultCode.noTrust must render as no_trust")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "PaymentResultCode.noTrust must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"no_trust\""), value,
                       "no_trust must read back as PaymentResultCode.noTrust")
    }

    func test_PaymentResultCode_PAYMENT_SRC_NOT_AUTHORIZED() throws {
        let value: PaymentResultCode = .srcNotAuthorized
        XCTAssertEqual(try value.toXdrJson(), "\"src_not_authorized\"",
                       "PaymentResultCode.srcNotAuthorized must render as src_not_authorized")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "PaymentResultCode.srcNotAuthorized must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"src_not_authorized\""), value,
                       "src_not_authorized must read back as PaymentResultCode.srcNotAuthorized")
    }

    func test_PaymentResultCode_PAYMENT_SRC_NO_TRUST() throws {
        let value: PaymentResultCode = .srcNoTrust
        XCTAssertEqual(try value.toXdrJson(), "\"src_no_trust\"",
                       "PaymentResultCode.srcNoTrust must render as src_no_trust")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "PaymentResultCode.srcNoTrust must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"src_no_trust\""), value,
                       "src_no_trust must read back as PaymentResultCode.srcNoTrust")
    }

    func test_PaymentResultCode_PAYMENT_SUCCESS() throws {
        let value: PaymentResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "PaymentResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "PaymentResultCode.success must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as PaymentResultCode.success")
    }

    func test_PaymentResultCode_PAYMENT_UNDERFUNDED() throws {
        let value: PaymentResultCode = .underfunded
        XCTAssertEqual(try value.toXdrJson(), "\"underfunded\"",
                       "PaymentResultCode.underfunded must render as underfunded")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "PaymentResultCode.underfunded must keep its XDR value")
        XCTAssertEqual(try PaymentResultCode.fromXdrJson("\"underfunded\""), value,
                       "underfunded must read back as PaymentResultCode.underfunded")
    }

    func test_PaymentResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try PaymentResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("PaymentResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "PaymentResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_PaymentResultXDR_lineFull_roundTrip() throws {
        let original: PaymentResultXDR = .lineFull
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_malformed_roundTrip() throws {
        let original: PaymentResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_noDestination_roundTrip() throws {
        let original: PaymentResultXDR = .noDestination
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_noIssuer_roundTrip() throws {
        let original: PaymentResultXDR = .noIssuer
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_noTrust_roundTrip() throws {
        let original: PaymentResultXDR = .noTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_notAuthorized_roundTrip() throws {
        let original: PaymentResultXDR = .notAuthorized
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try PaymentResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("PaymentResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "PaymentResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_PaymentResultXDR_srcNoTrust_roundTrip() throws {
        let original: PaymentResultXDR = .srcNoTrust
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_srcNotAuthorized_roundTrip() throws {
        let original: PaymentResultXDR = .srcNotAuthorized
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_success_roundTrip() throws {
        let original: PaymentResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PaymentResultXDR_underfunded_roundTrip() throws {
        let original: PaymentResultXDR = .underfunded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PaymentResultXDR.fromXdrJson(json)
        let viaValue = try PaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try PaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_PreconditionType_PRECOND_NONE() throws {
        let value: PreconditionType = .none
        XCTAssertEqual(try value.toXdrJson(), "\"none\"",
                       "PreconditionType.none must render as none")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "PreconditionType.none must keep its XDR value")
        XCTAssertEqual(try PreconditionType.fromXdrJson("\"none\""), value,
                       "none must read back as PreconditionType.none")
    }

    func test_PreconditionType_PRECOND_TIME() throws {
        let value: PreconditionType = .time
        XCTAssertEqual(try value.toXdrJson(), "\"time\"",
                       "PreconditionType.time must render as time")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "PreconditionType.time must keep its XDR value")
        XCTAssertEqual(try PreconditionType.fromXdrJson("\"time\""), value,
                       "time must read back as PreconditionType.time")
    }

    func test_PreconditionType_PRECOND_V2() throws {
        let value: PreconditionType = .v2
        XCTAssertEqual(try value.toXdrJson(), "\"v2\"",
                       "PreconditionType.v2 must render as v2")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "PreconditionType.v2 must keep its XDR value")
        XCTAssertEqual(try PreconditionType.fromXdrJson("\"v2\""), value,
                       "v2 must read back as PreconditionType.v2")
    }

    func test_PreconditionType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try PreconditionType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("PreconditionType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "PreconditionType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_PreconditionsV2XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PreconditionsV2XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PreconditionsV2XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PreconditionsV2XDR_roundTrip() throws {
        let original: PreconditionsV2XDR = PreconditionsV2XDR(timeBounds: TimeBoundsXDR(minTime: UInt64(1234567), maxTime: UInt64(1234567)), ledgerBounds: LedgerBoundsXDR(minLedger: UInt32(42), maxLedger: UInt32(42)), sequenceNumber: Int64(1234567), minSeqAge: UInt64(1234567), minSeqLedgerGap: UInt32(42), extraSigners: [.ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PreconditionsV2XDR.fromXdrJson(json)
        let viaValue = try PreconditionsV2XDR.fromXdrJsonValue(tree)
        let viaTree = try PreconditionsV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PreconditionsV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PreconditionsV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PreconditionsV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PreconditionsV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PreconditionsV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_PreconditionsXDR_none_roundTrip() throws {
        let original: PreconditionsXDR = .none
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PreconditionsXDR.fromXdrJson(json)
        let viaValue = try PreconditionsXDR.fromXdrJsonValue(tree)
        let viaTree = try PreconditionsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PreconditionsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PreconditionsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PreconditionsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PreconditionsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PreconditionsXDR must reach the same bytes through JSON and XDR")
    }

    func test_PreconditionsXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try PreconditionsXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("PreconditionsXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "PreconditionsXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_PreconditionsXDR_time_rejectsBareString() throws {
        XCTAssertThrowsError(try PreconditionsXDR.fromXdrJson("\"time\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("PreconditionsXDR.time: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "PreconditionsXDR")
            XCTAssertEqual(key, "time",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_PreconditionsXDR_time_roundTrip() throws {
        let original: PreconditionsXDR = .time(TimeBoundsXDR(minTime: UInt64(1234567), maxTime: UInt64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PreconditionsXDR.fromXdrJson(json)
        let viaValue = try PreconditionsXDR.fromXdrJsonValue(tree)
        let viaTree = try PreconditionsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PreconditionsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PreconditionsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PreconditionsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PreconditionsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PreconditionsXDR must reach the same bytes through JSON and XDR")
    }

    func test_PreconditionsXDR_v2_rejectsBareString() throws {
        XCTAssertThrowsError(try PreconditionsXDR.fromXdrJson("\"v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("PreconditionsXDR.v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "PreconditionsXDR")
            XCTAssertEqual(key, "v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_PreconditionsXDR_v2_roundTrip() throws {
        let original: PreconditionsXDR = .v2(PreconditionsV2XDR(timeBounds: TimeBoundsXDR(minTime: UInt64(1234567), maxTime: UInt64(1234567)), ledgerBounds: LedgerBoundsXDR(minLedger: UInt32(42), maxLedger: UInt32(42)), sequenceNumber: Int64(1234567), minSeqAge: UInt64(1234567), minSeqLedgerGap: UInt32(42), extraSigners: [.ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PreconditionsXDR.fromXdrJson(json)
        let viaValue = try PreconditionsXDR.fromXdrJsonValue(tree)
        let viaTree = try PreconditionsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PreconditionsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PreconditionsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PreconditionsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PreconditionsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PreconditionsXDR must reach the same bytes through JSON and XDR")
    }

    func test_RestoreFootprintOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try RestoreFootprintOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "RestoreFootprintOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_RestoreFootprintOpXDR_roundTrip() throws {
        let original: RestoreFootprintOpXDR = RestoreFootprintOpXDR(ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RestoreFootprintOpXDR.fromXdrJson(json)
        let viaValue = try RestoreFootprintOpXDR.fromXdrJsonValue(tree)
        let viaTree = try RestoreFootprintOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RestoreFootprintOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RestoreFootprintOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RestoreFootprintOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RestoreFootprintOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RestoreFootprintOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_RestoreFootprintResultCode_RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE() throws {
        let value: RestoreFootprintResultCode = .insufficientRefundableFee
        XCTAssertEqual(try value.toXdrJson(), "\"insufficient_refundable_fee\"",
                       "RestoreFootprintResultCode.insufficientRefundableFee must render as insufficient_refundable_fee")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "RestoreFootprintResultCode.insufficientRefundableFee must keep its XDR value")
        XCTAssertEqual(try RestoreFootprintResultCode.fromXdrJson("\"insufficient_refundable_fee\""), value,
                       "insufficient_refundable_fee must read back as RestoreFootprintResultCode.insufficientRefundableFee")
    }

    func test_RestoreFootprintResultCode_RESTORE_FOOTPRINT_MALFORMED() throws {
        let value: RestoreFootprintResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "RestoreFootprintResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "RestoreFootprintResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try RestoreFootprintResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as RestoreFootprintResultCode.malformed")
    }

    func test_RestoreFootprintResultCode_RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED() throws {
        let value: RestoreFootprintResultCode = .resourceLimitExceeded
        XCTAssertEqual(try value.toXdrJson(), "\"resource_limit_exceeded\"",
                       "RestoreFootprintResultCode.resourceLimitExceeded must render as resource_limit_exceeded")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "RestoreFootprintResultCode.resourceLimitExceeded must keep its XDR value")
        XCTAssertEqual(try RestoreFootprintResultCode.fromXdrJson("\"resource_limit_exceeded\""), value,
                       "resource_limit_exceeded must read back as RestoreFootprintResultCode.resourceLimitExceeded")
    }

    func test_RestoreFootprintResultCode_RESTORE_FOOTPRINT_SUCCESS() throws {
        let value: RestoreFootprintResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "RestoreFootprintResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "RestoreFootprintResultCode.success must keep its XDR value")
        XCTAssertEqual(try RestoreFootprintResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as RestoreFootprintResultCode.success")
    }

    func test_RestoreFootprintResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try RestoreFootprintResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("RestoreFootprintResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "RestoreFootprintResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_RestoreFootprintResultXDR_insufficientRefundableFee_roundTrip() throws {
        let original: RestoreFootprintResultXDR = .insufficientRefundableFee
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RestoreFootprintResultXDR.fromXdrJson(json)
        let viaValue = try RestoreFootprintResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RestoreFootprintResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RestoreFootprintResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RestoreFootprintResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RestoreFootprintResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RestoreFootprintResultXDR_malformed_roundTrip() throws {
        let original: RestoreFootprintResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RestoreFootprintResultXDR.fromXdrJson(json)
        let viaValue = try RestoreFootprintResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RestoreFootprintResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RestoreFootprintResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RestoreFootprintResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RestoreFootprintResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RestoreFootprintResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try RestoreFootprintResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("RestoreFootprintResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "RestoreFootprintResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_RestoreFootprintResultXDR_resourceLimitExceeded_roundTrip() throws {
        let original: RestoreFootprintResultXDR = .resourceLimitExceeded
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RestoreFootprintResultXDR.fromXdrJson(json)
        let viaValue = try RestoreFootprintResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RestoreFootprintResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RestoreFootprintResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RestoreFootprintResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RestoreFootprintResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RestoreFootprintResultXDR_success_roundTrip() throws {
        let original: RestoreFootprintResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RestoreFootprintResultXDR.fromXdrJson(json)
        let viaValue = try RestoreFootprintResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RestoreFootprintResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RestoreFootprintResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RestoreFootprintResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RestoreFootprintResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RestoreFootprintResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeID_rejectsWrongShape() throws {
        XCTAssertThrowsError(try RevokeID.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "RevokeID must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_RevokeID_roundTrip() throws {
        let original: RevokeID = RevokeID(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(1234567), opNum: UInt32(42), liquidityPoolID: WrappedData32(Data(repeating: 0xAB, count: 32)), asset: .native)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeID.fromXdrJson(json)
        let viaValue = try RevokeID.fromXdrJsonValue(tree)
        let viaTree = try RevokeID.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeID must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeID must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeID must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeID must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeID must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipOpXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try RevokeSponsorshipOpXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("RevokeSponsorshipOpXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "RevokeSponsorshipOpXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_RevokeSponsorshipOpXDR_revokeSponsorshipLedgerEntry_rejectsBareString() throws {
        XCTAssertThrowsError(try RevokeSponsorshipOpXDR.fromXdrJson("\"ledger_entry\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("RevokeSponsorshipOpXDR.ledger_entry: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "RevokeSponsorshipOpXDR")
            XCTAssertEqual(key, "ledger_entry",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_RevokeSponsorshipOpXDR_revokeSponsorshipLedgerEntry_roundTrip() throws {
        let original: RevokeSponsorshipOpXDR = .revokeSponsorshipLedgerEntry(.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipOpXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipOpXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipOpXDR_revokeSponsorshipSignerEntry_rejectsBareString() throws {
        XCTAssertThrowsError(try RevokeSponsorshipOpXDR.fromXdrJson("\"signer\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("RevokeSponsorshipOpXDR.signer: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "RevokeSponsorshipOpXDR")
            XCTAssertEqual(key, "signer",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_RevokeSponsorshipOpXDR_revokeSponsorshipSignerEntry_roundTrip() throws {
        let original: RevokeSponsorshipOpXDR = .revokeSponsorshipSignerEntry(RevokeSponsorshipSignerXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signerKey: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipOpXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipOpXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipResultCode_REVOKE_SPONSORSHIP_DOES_NOT_EXIST() throws {
        let value: RevokeSponsorshipResultCode = .doesNotExist
        XCTAssertEqual(try value.toXdrJson(), "\"does_not_exist\"",
                       "RevokeSponsorshipResultCode.doesNotExist must render as does_not_exist")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "RevokeSponsorshipResultCode.doesNotExist must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipResultCode.fromXdrJson("\"does_not_exist\""), value,
                       "does_not_exist must read back as RevokeSponsorshipResultCode.doesNotExist")
    }

    func test_RevokeSponsorshipResultCode_REVOKE_SPONSORSHIP_LOW_RESERVE() throws {
        let value: RevokeSponsorshipResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "RevokeSponsorshipResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "RevokeSponsorshipResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as RevokeSponsorshipResultCode.lowReserve")
    }

    func test_RevokeSponsorshipResultCode_REVOKE_SPONSORSHIP_MALFORMED() throws {
        let value: RevokeSponsorshipResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "RevokeSponsorshipResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "RevokeSponsorshipResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as RevokeSponsorshipResultCode.malformed")
    }

    func test_RevokeSponsorshipResultCode_REVOKE_SPONSORSHIP_NOT_SPONSOR() throws {
        let value: RevokeSponsorshipResultCode = .notSponsor
        XCTAssertEqual(try value.toXdrJson(), "\"not_sponsor\"",
                       "RevokeSponsorshipResultCode.notSponsor must render as not_sponsor")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "RevokeSponsorshipResultCode.notSponsor must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipResultCode.fromXdrJson("\"not_sponsor\""), value,
                       "not_sponsor must read back as RevokeSponsorshipResultCode.notSponsor")
    }

    func test_RevokeSponsorshipResultCode_REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE() throws {
        let value: RevokeSponsorshipResultCode = .onlyTransferable
        XCTAssertEqual(try value.toXdrJson(), "\"only_transferable\"",
                       "RevokeSponsorshipResultCode.onlyTransferable must render as only_transferable")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "RevokeSponsorshipResultCode.onlyTransferable must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipResultCode.fromXdrJson("\"only_transferable\""), value,
                       "only_transferable must read back as RevokeSponsorshipResultCode.onlyTransferable")
    }

    func test_RevokeSponsorshipResultCode_REVOKE_SPONSORSHIP_SUCCESS() throws {
        let value: RevokeSponsorshipResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "RevokeSponsorshipResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "RevokeSponsorshipResultCode.success must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as RevokeSponsorshipResultCode.success")
    }

    func test_RevokeSponsorshipResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try RevokeSponsorshipResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("RevokeSponsorshipResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "RevokeSponsorshipResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_RevokeSponsorshipResultXDR_doesNotExist_roundTrip() throws {
        let original: RevokeSponsorshipResultXDR = .doesNotExist
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipResultXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipResultXDR_lowReserve_roundTrip() throws {
        let original: RevokeSponsorshipResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipResultXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipResultXDR_malformed_roundTrip() throws {
        let original: RevokeSponsorshipResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipResultXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipResultXDR_notSponsor_roundTrip() throws {
        let original: RevokeSponsorshipResultXDR = .notSponsor
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipResultXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipResultXDR_onlyTransferable_roundTrip() throws {
        let original: RevokeSponsorshipResultXDR = .onlyTransferable
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipResultXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try RevokeSponsorshipResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("RevokeSponsorshipResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "RevokeSponsorshipResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_RevokeSponsorshipResultXDR_success_roundTrip() throws {
        let original: RevokeSponsorshipResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipResultXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipResultXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipSignerXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try RevokeSponsorshipSignerXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "RevokeSponsorshipSignerXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_RevokeSponsorshipSignerXDR_roundTrip() throws {
        let original: RevokeSponsorshipSignerXDR = RevokeSponsorshipSignerXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), signerKey: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try RevokeSponsorshipSignerXDR.fromXdrJson(json)
        let viaValue = try RevokeSponsorshipSignerXDR.fromXdrJsonValue(tree)
        let viaTree = try RevokeSponsorshipSignerXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "RevokeSponsorshipSignerXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "RevokeSponsorshipSignerXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "RevokeSponsorshipSignerXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "RevokeSponsorshipSignerXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "RevokeSponsorshipSignerXDR must reach the same bytes through JSON and XDR")
    }

    func test_RevokeSponsorshipType_REVOKE_SPONSORSHIP_LEDGER_ENTRY() throws {
        let value: RevokeSponsorshipType = .revokeSponsorshipLedgerEntry
        XCTAssertEqual(try value.toXdrJson(), "\"ledger_entry\"",
                       "RevokeSponsorshipType.revokeSponsorshipLedgerEntry must render as ledger_entry")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "RevokeSponsorshipType.revokeSponsorshipLedgerEntry must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipType.fromXdrJson("\"ledger_entry\""), value,
                       "ledger_entry must read back as RevokeSponsorshipType.revokeSponsorshipLedgerEntry")
    }

    func test_RevokeSponsorshipType_REVOKE_SPONSORSHIP_SIGNER() throws {
        let value: RevokeSponsorshipType = .revokeSponsorshipSignerEntry
        XCTAssertEqual(try value.toXdrJson(), "\"signer\"",
                       "RevokeSponsorshipType.revokeSponsorshipSignerEntry must render as signer")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "RevokeSponsorshipType.revokeSponsorshipSignerEntry must keep its XDR value")
        XCTAssertEqual(try RevokeSponsorshipType.fromXdrJson("\"signer\""), value,
                       "signer must read back as RevokeSponsorshipType.revokeSponsorshipSignerEntry")
    }

    func test_RevokeSponsorshipType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try RevokeSponsorshipType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("RevokeSponsorshipType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "RevokeSponsorshipType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SetOptionsOperationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SetOptionsOperationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SetOptionsOperationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SetOptionsOperationXDR_roundTrip() throws {
        let original: SetOptionsOperationXDR = SetOptionsOperationXDR(inflationDestination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), clearFlags: UInt32(42), setFlags: UInt32(42), masterWeight: UInt32(42), lowThreshold: UInt32(42), medThreshold: UInt32(42), highThreshold: UInt32(42), homeDomain: "test_string", signer: SignerXDR(key: .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32))), weight: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsOperationXDR.fromXdrJson(json)
        let viaValue = try SetOptionsOperationXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsOperationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsOperationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsOperationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsOperationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsOperationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsOperationXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_AUTH_REVOCABLE_REQUIRED() throws {
        let value: SetOptionsResultCode = .authRevocableRequired
        XCTAssertEqual(try value.toXdrJson(), "\"auth_revocable_required\"",
                       "SetOptionsResultCode.authRevocableRequired must render as auth_revocable_required")
        XCTAssertEqual(value.rawValue, Int32(-10),
                       "SetOptionsResultCode.authRevocableRequired must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"auth_revocable_required\""), value,
                       "auth_revocable_required must read back as SetOptionsResultCode.authRevocableRequired")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_BAD_FLAGS() throws {
        let value: SetOptionsResultCode = .badFlags
        XCTAssertEqual(try value.toXdrJson(), "\"bad_flags\"",
                       "SetOptionsResultCode.badFlags must render as bad_flags")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "SetOptionsResultCode.badFlags must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"bad_flags\""), value,
                       "bad_flags must read back as SetOptionsResultCode.badFlags")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_BAD_SIGNER() throws {
        let value: SetOptionsResultCode = .badSigner
        XCTAssertEqual(try value.toXdrJson(), "\"bad_signer\"",
                       "SetOptionsResultCode.badSigner must render as bad_signer")
        XCTAssertEqual(value.rawValue, Int32(-8),
                       "SetOptionsResultCode.badSigner must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"bad_signer\""), value,
                       "bad_signer must read back as SetOptionsResultCode.badSigner")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_CANT_CHANGE() throws {
        let value: SetOptionsResultCode = .cantChange
        XCTAssertEqual(try value.toXdrJson(), "\"cant_change\"",
                       "SetOptionsResultCode.cantChange must render as cant_change")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "SetOptionsResultCode.cantChange must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"cant_change\""), value,
                       "cant_change must read back as SetOptionsResultCode.cantChange")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_INVALID_HOME_DOMAIN() throws {
        let value: SetOptionsResultCode = .invalidHomeDomain
        XCTAssertEqual(try value.toXdrJson(), "\"invalid_home_domain\"",
                       "SetOptionsResultCode.invalidHomeDomain must render as invalid_home_domain")
        XCTAssertEqual(value.rawValue, Int32(-9),
                       "SetOptionsResultCode.invalidHomeDomain must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"invalid_home_domain\""), value,
                       "invalid_home_domain must read back as SetOptionsResultCode.invalidHomeDomain")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_INVALID_INFLATION() throws {
        let value: SetOptionsResultCode = .invalidInflation
        XCTAssertEqual(try value.toXdrJson(), "\"invalid_inflation\"",
                       "SetOptionsResultCode.invalidInflation must render as invalid_inflation")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "SetOptionsResultCode.invalidInflation must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"invalid_inflation\""), value,
                       "invalid_inflation must read back as SetOptionsResultCode.invalidInflation")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_LOW_RESERVE() throws {
        let value: SetOptionsResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "SetOptionsResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "SetOptionsResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as SetOptionsResultCode.lowReserve")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_SUCCESS() throws {
        let value: SetOptionsResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "SetOptionsResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SetOptionsResultCode.success must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as SetOptionsResultCode.success")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_THRESHOLD_OUT_OF_RANGE() throws {
        let value: SetOptionsResultCode = .thresholdOutOfRange
        XCTAssertEqual(try value.toXdrJson(), "\"threshold_out_of_range\"",
                       "SetOptionsResultCode.thresholdOutOfRange must render as threshold_out_of_range")
        XCTAssertEqual(value.rawValue, Int32(-7),
                       "SetOptionsResultCode.thresholdOutOfRange must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"threshold_out_of_range\""), value,
                       "threshold_out_of_range must read back as SetOptionsResultCode.thresholdOutOfRange")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_TOO_MANY_SIGNERS() throws {
        let value: SetOptionsResultCode = .tooManySigners
        XCTAssertEqual(try value.toXdrJson(), "\"too_many_signers\"",
                       "SetOptionsResultCode.tooManySigners must render as too_many_signers")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "SetOptionsResultCode.tooManySigners must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"too_many_signers\""), value,
                       "too_many_signers must read back as SetOptionsResultCode.tooManySigners")
    }

    func test_SetOptionsResultCode_SET_OPTIONS_UNKNOWN_FLAG() throws {
        let value: SetOptionsResultCode = .unknownFlag
        XCTAssertEqual(try value.toXdrJson(), "\"unknown_flag\"",
                       "SetOptionsResultCode.unknownFlag must render as unknown_flag")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "SetOptionsResultCode.unknownFlag must keep its XDR value")
        XCTAssertEqual(try SetOptionsResultCode.fromXdrJson("\"unknown_flag\""), value,
                       "unknown_flag must read back as SetOptionsResultCode.unknownFlag")
    }

    func test_SetOptionsResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SetOptionsResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SetOptionsResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SetOptionsResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SetOptionsResultXDR_authRevocableRequired_roundTrip() throws {
        let original: SetOptionsResultXDR = .authRevocableRequired
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_badFlags_roundTrip() throws {
        let original: SetOptionsResultXDR = .badFlags
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_badSigner_roundTrip() throws {
        let original: SetOptionsResultXDR = .badSigner
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_cantChange_roundTrip() throws {
        let original: SetOptionsResultXDR = .cantChange
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_invalidHomeDomain_roundTrip() throws {
        let original: SetOptionsResultXDR = .invalidHomeDomain
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_invalidInflation_roundTrip() throws {
        let original: SetOptionsResultXDR = .invalidInflation
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_lowReserve_roundTrip() throws {
        let original: SetOptionsResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SetOptionsResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SetOptionsResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SetOptionsResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SetOptionsResultXDR_success_roundTrip() throws {
        let original: SetOptionsResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_thresholdOutOfRange_roundTrip() throws {
        let original: SetOptionsResultXDR = .thresholdOutOfRange
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_tooManySigners_roundTrip() throws {
        let original: SetOptionsResultXDR = .tooManySigners
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetOptionsResultXDR_unknownFlag_roundTrip() throws {
        let original: SetOptionsResultXDR = .unknownFlag
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetOptionsResultXDR.fromXdrJson(json)
        let viaValue = try SetOptionsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetOptionsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetOptionsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetOptionsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetOptionsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetOptionsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetOptionsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetTrustLineFlagsOpXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SetTrustLineFlagsOpXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SetTrustLineFlagsOpXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SetTrustLineFlagsOpXDR_roundTrip() throws {
        let original: SetTrustLineFlagsOpXDR = SetTrustLineFlagsOpXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, setFlags: UInt32(42), clearFlags: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetTrustLineFlagsOpXDR.fromXdrJson(json)
        let viaValue = try SetTrustLineFlagsOpXDR.fromXdrJsonValue(tree)
        let viaTree = try SetTrustLineFlagsOpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetTrustLineFlagsOpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetTrustLineFlagsOpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetTrustLineFlagsOpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetTrustLineFlagsOpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetTrustLineFlagsOpXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetTrustLineFlagsResultCode_SET_TRUST_LINE_FLAGS_CANT_REVOKE() throws {
        let value: SetTrustLineFlagsResultCode = .cantRevoke
        XCTAssertEqual(try value.toXdrJson(), "\"cant_revoke\"",
                       "SetTrustLineFlagsResultCode.cantRevoke must render as cant_revoke")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "SetTrustLineFlagsResultCode.cantRevoke must keep its XDR value")
        XCTAssertEqual(try SetTrustLineFlagsResultCode.fromXdrJson("\"cant_revoke\""), value,
                       "cant_revoke must read back as SetTrustLineFlagsResultCode.cantRevoke")
    }

    func test_SetTrustLineFlagsResultCode_SET_TRUST_LINE_FLAGS_INVALID_STATE() throws {
        let value: SetTrustLineFlagsResultCode = .invalidState
        XCTAssertEqual(try value.toXdrJson(), "\"invalid_state\"",
                       "SetTrustLineFlagsResultCode.invalidState must render as invalid_state")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "SetTrustLineFlagsResultCode.invalidState must keep its XDR value")
        XCTAssertEqual(try SetTrustLineFlagsResultCode.fromXdrJson("\"invalid_state\""), value,
                       "invalid_state must read back as SetTrustLineFlagsResultCode.invalidState")
    }

    func test_SetTrustLineFlagsResultCode_SET_TRUST_LINE_FLAGS_LOW_RESERVE() throws {
        let value: SetTrustLineFlagsResultCode = .lowReserve
        XCTAssertEqual(try value.toXdrJson(), "\"low_reserve\"",
                       "SetTrustLineFlagsResultCode.lowReserve must render as low_reserve")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "SetTrustLineFlagsResultCode.lowReserve must keep its XDR value")
        XCTAssertEqual(try SetTrustLineFlagsResultCode.fromXdrJson("\"low_reserve\""), value,
                       "low_reserve must read back as SetTrustLineFlagsResultCode.lowReserve")
    }

    func test_SetTrustLineFlagsResultCode_SET_TRUST_LINE_FLAGS_MALFORMED() throws {
        let value: SetTrustLineFlagsResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"malformed\"",
                       "SetTrustLineFlagsResultCode.malformed must render as malformed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "SetTrustLineFlagsResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try SetTrustLineFlagsResultCode.fromXdrJson("\"malformed\""), value,
                       "malformed must read back as SetTrustLineFlagsResultCode.malformed")
    }

    func test_SetTrustLineFlagsResultCode_SET_TRUST_LINE_FLAGS_NO_TRUST_LINE() throws {
        let value: SetTrustLineFlagsResultCode = .noTrustLine
        XCTAssertEqual(try value.toXdrJson(), "\"no_trust_line\"",
                       "SetTrustLineFlagsResultCode.noTrustLine must render as no_trust_line")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "SetTrustLineFlagsResultCode.noTrustLine must keep its XDR value")
        XCTAssertEqual(try SetTrustLineFlagsResultCode.fromXdrJson("\"no_trust_line\""), value,
                       "no_trust_line must read back as SetTrustLineFlagsResultCode.noTrustLine")
    }

    func test_SetTrustLineFlagsResultCode_SET_TRUST_LINE_FLAGS_SUCCESS() throws {
        let value: SetTrustLineFlagsResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"success\"",
                       "SetTrustLineFlagsResultCode.success must render as success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SetTrustLineFlagsResultCode.success must keep its XDR value")
        XCTAssertEqual(try SetTrustLineFlagsResultCode.fromXdrJson("\"success\""), value,
                       "success must read back as SetTrustLineFlagsResultCode.success")
    }

    func test_SetTrustLineFlagsResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SetTrustLineFlagsResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SetTrustLineFlagsResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SetTrustLineFlagsResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SetTrustLineFlagsResultXDR_cantRevoke_roundTrip() throws {
        let original: SetTrustLineFlagsResultXDR = .cantRevoke
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetTrustLineFlagsResultXDR.fromXdrJson(json)
        let viaValue = try SetTrustLineFlagsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetTrustLineFlagsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetTrustLineFlagsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetTrustLineFlagsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetTrustLineFlagsResultXDR_invalidState_roundTrip() throws {
        let original: SetTrustLineFlagsResultXDR = .invalidState
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetTrustLineFlagsResultXDR.fromXdrJson(json)
        let viaValue = try SetTrustLineFlagsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetTrustLineFlagsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetTrustLineFlagsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetTrustLineFlagsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetTrustLineFlagsResultXDR_lowReserve_roundTrip() throws {
        let original: SetTrustLineFlagsResultXDR = .lowReserve
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetTrustLineFlagsResultXDR.fromXdrJson(json)
        let viaValue = try SetTrustLineFlagsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetTrustLineFlagsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetTrustLineFlagsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetTrustLineFlagsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetTrustLineFlagsResultXDR_malformed_roundTrip() throws {
        let original: SetTrustLineFlagsResultXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetTrustLineFlagsResultXDR.fromXdrJson(json)
        let viaValue = try SetTrustLineFlagsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetTrustLineFlagsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetTrustLineFlagsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetTrustLineFlagsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetTrustLineFlagsResultXDR_noTrustLine_roundTrip() throws {
        let original: SetTrustLineFlagsResultXDR = .noTrustLine
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetTrustLineFlagsResultXDR.fromXdrJson(json)
        let viaValue = try SetTrustLineFlagsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetTrustLineFlagsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetTrustLineFlagsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetTrustLineFlagsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SetTrustLineFlagsResultXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SetTrustLineFlagsResultXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SetTrustLineFlagsResultXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SetTrustLineFlagsResultXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SetTrustLineFlagsResultXDR_success_roundTrip() throws {
        let original: SetTrustLineFlagsResultXDR = .success
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SetTrustLineFlagsResultXDR.fromXdrJson(json)
        let viaValue = try SetTrustLineFlagsResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SetTrustLineFlagsResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SetTrustLineFlagsResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SetTrustLineFlagsResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SetTrustLineFlagsResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SimplePaymentResultXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SimplePaymentResultXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SimplePaymentResultXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SimplePaymentResultXDR_roundTrip() throws {
        let original: SimplePaymentResultXDR = SimplePaymentResultXDR(destination: try PublicKey([UInt8](repeating: 0xAB, count: 32)), asset: .native, amount: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SimplePaymentResultXDR.fromXdrJson(json)
        let viaValue = try SimplePaymentResultXDR.fromXdrJsonValue(tree)
        let viaTree = try SimplePaymentResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SimplePaymentResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SimplePaymentResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SimplePaymentResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SimplePaymentResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SimplePaymentResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAddressCredentialsWithDelegatesXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanAddressCredentialsWithDelegatesXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanAddressCredentialsWithDelegatesXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanAddressCredentialsWithDelegatesXDR_roundTrip() throws {
        let original: SorobanAddressCredentialsWithDelegatesXDR = SorobanAddressCredentialsWithDelegatesXDR(addressCredentials: SorobanAddressCredentialsXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), signature: .void), delegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [])])])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAddressCredentialsWithDelegatesXDR.fromXdrJson(json)
        let viaValue = try SorobanAddressCredentialsWithDelegatesXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAddressCredentialsWithDelegatesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAddressCredentialsWithDelegatesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAddressCredentialsWithDelegatesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAddressCredentialsWithDelegatesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAddressCredentialsWithDelegatesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAddressCredentialsWithDelegatesXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAddressCredentialsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanAddressCredentialsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanAddressCredentialsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanAddressCredentialsXDR_roundTrip() throws {
        let original: SorobanAddressCredentialsXDR = SorobanAddressCredentialsXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), signature: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAddressCredentialsXDR.fromXdrJson(json)
        let viaValue = try SorobanAddressCredentialsXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAddressCredentialsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAddressCredentialsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAddressCredentialsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAddressCredentialsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAddressCredentialsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAddressCredentialsXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAuthorizationEntriesXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanAuthorizationEntriesXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanAuthorizationEntriesXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanAuthorizationEntriesXDR_roundTrip() throws {
        let original: SorobanAuthorizationEntriesXDR = SorobanAuthorizationEntriesXDR(wrapped: [SorobanAuthorizationEntryXDR(credentials: .sourceAccount, rootInvocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: []))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAuthorizationEntriesXDR.fromXdrJson(json)
        let viaValue = try SorobanAuthorizationEntriesXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAuthorizationEntriesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAuthorizationEntriesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAuthorizationEntriesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAuthorizationEntriesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAuthorizationEntriesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAuthorizationEntriesXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAuthorizationEntryXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanAuthorizationEntryXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanAuthorizationEntryXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanAuthorizationEntryXDR_roundTrip() throws {
        let original: SorobanAuthorizationEntryXDR = SorobanAuthorizationEntryXDR(credentials: .sourceAccount, rootInvocation: SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: []))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAuthorizationEntryXDR.fromXdrJson(json)
        let viaValue = try SorobanAuthorizationEntryXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAuthorizationEntryXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAuthorizationEntryXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAuthorizationEntryXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAuthorizationEntryXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAuthorizationEntryXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAuthorizationEntryXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAuthorizedFunctionType_SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN() throws {
        let value: SorobanAuthorizedFunctionType = .contractFn
        XCTAssertEqual(try value.toXdrJson(), "\"contract_fn\"",
                       "SorobanAuthorizedFunctionType.contractFn must render as contract_fn")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SorobanAuthorizedFunctionType.contractFn must keep its XDR value")
        XCTAssertEqual(try SorobanAuthorizedFunctionType.fromXdrJson("\"contract_fn\""), value,
                       "contract_fn must read back as SorobanAuthorizedFunctionType.contractFn")
    }

    func test_SorobanAuthorizedFunctionType_SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN() throws {
        let value: SorobanAuthorizedFunctionType = .createContractHostFn
        XCTAssertEqual(try value.toXdrJson(), "\"create_contract_host_fn\"",
                       "SorobanAuthorizedFunctionType.createContractHostFn must render as create_contract_host_fn")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SorobanAuthorizedFunctionType.createContractHostFn must keep its XDR value")
        XCTAssertEqual(try SorobanAuthorizedFunctionType.fromXdrJson("\"create_contract_host_fn\""), value,
                       "create_contract_host_fn must read back as SorobanAuthorizedFunctionType.createContractHostFn")
    }

    func test_SorobanAuthorizedFunctionType_SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN() throws {
        let value: SorobanAuthorizedFunctionType = .createContractV2HostFn
        XCTAssertEqual(try value.toXdrJson(), "\"create_contract_v2_host_fn\"",
                       "SorobanAuthorizedFunctionType.createContractV2HostFn must render as create_contract_v2_host_fn")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SorobanAuthorizedFunctionType.createContractV2HostFn must keep its XDR value")
        XCTAssertEqual(try SorobanAuthorizedFunctionType.fromXdrJson("\"create_contract_v2_host_fn\""), value,
                       "create_contract_v2_host_fn must read back as SorobanAuthorizedFunctionType.createContractV2HostFn")
    }

    func test_SorobanAuthorizedFunctionType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SorobanAuthorizedFunctionType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SorobanAuthorizedFunctionType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanAuthorizedFunctionType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SorobanAuthorizedFunctionXDR_contractFn_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanAuthorizedFunctionXDR.fromXdrJson("\"contract_fn\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanAuthorizedFunctionXDR.contract_fn: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanAuthorizedFunctionXDR")
            XCTAssertEqual(key, "contract_fn",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanAuthorizedFunctionXDR_contractFn_roundTrip() throws {
        let original: SorobanAuthorizedFunctionXDR = .contractFn(InvokeContractArgsXDR(contractAddress: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), functionName: "test_string", args: [.void]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAuthorizedFunctionXDR.fromXdrJson(json)
        let viaValue = try SorobanAuthorizedFunctionXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAuthorizedFunctionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAuthorizedFunctionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAuthorizedFunctionXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAuthorizedFunctionXDR_createContractHostFn_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanAuthorizedFunctionXDR.fromXdrJson("\"create_contract_host_fn\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanAuthorizedFunctionXDR.create_contract_host_fn: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanAuthorizedFunctionXDR")
            XCTAssertEqual(key, "create_contract_host_fn",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanAuthorizedFunctionXDR_createContractHostFn_roundTrip() throws {
        let original: SorobanAuthorizedFunctionXDR = .createContractHostFn(CreateContractArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAuthorizedFunctionXDR.fromXdrJson(json)
        let viaValue = try SorobanAuthorizedFunctionXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAuthorizedFunctionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAuthorizedFunctionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAuthorizedFunctionXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAuthorizedFunctionXDR_createContractV2HostFn_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanAuthorizedFunctionXDR.fromXdrJson("\"create_contract_v2_host_fn\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanAuthorizedFunctionXDR.create_contract_v2_host_fn: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanAuthorizedFunctionXDR")
            XCTAssertEqual(key, "create_contract_v2_host_fn",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanAuthorizedFunctionXDR_createContractV2HostFn_roundTrip() throws {
        let original: SorobanAuthorizedFunctionXDR = .createContractV2HostFn(CreateContractV2ArgsXDR(contractIDPreimage: .fromAddress(ContractIDPreimageFromAddressXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), salt: WrappedData32(Data(repeating: 0xAB, count: 32)))), executable: .token, constructorArgs: [.void]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAuthorizedFunctionXDR.fromXdrJson(json)
        let viaValue = try SorobanAuthorizedFunctionXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAuthorizedFunctionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAuthorizedFunctionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAuthorizedFunctionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAuthorizedFunctionXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanAuthorizedFunctionXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SorobanAuthorizedFunctionXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SorobanAuthorizedFunctionXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SorobanAuthorizedFunctionXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SorobanAuthorizedInvocationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanAuthorizedInvocationXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanAuthorizedInvocationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanAuthorizedInvocationXDR_roundTrip() throws {
        let original: SorobanAuthorizedInvocationXDR = SorobanAuthorizedInvocationXDR(function: .contractFn(InvokeContractArgsXDR(contractAddress: .contract(WrappedData32(Data(repeating: 0xAB, count: 32))), functionName: "fn", args: [])), subInvocations: [])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanAuthorizedInvocationXDR.fromXdrJson(json)
        let viaValue = try SorobanAuthorizedInvocationXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanAuthorizedInvocationXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanAuthorizedInvocationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanAuthorizedInvocationXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanAuthorizedInvocationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanAuthorizedInvocationXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanAuthorizedInvocationXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanCredentialsType_SOROBAN_CREDENTIALS_ADDRESS() throws {
        let value: SorobanCredentialsType = .address
        XCTAssertEqual(try value.toXdrJson(), "\"address\"",
                       "SorobanCredentialsType.address must render as address")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SorobanCredentialsType.address must keep its XDR value")
        XCTAssertEqual(try SorobanCredentialsType.fromXdrJson("\"address\""), value,
                       "address must read back as SorobanCredentialsType.address")
    }

    func test_SorobanCredentialsType_SOROBAN_CREDENTIALS_ADDRESS_V2() throws {
        let value: SorobanCredentialsType = .addressV2
        XCTAssertEqual(try value.toXdrJson(), "\"address_v2\"",
                       "SorobanCredentialsType.addressV2 must render as address_v2")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SorobanCredentialsType.addressV2 must keep its XDR value")
        XCTAssertEqual(try SorobanCredentialsType.fromXdrJson("\"address_v2\""), value,
                       "address_v2 must read back as SorobanCredentialsType.addressV2")
    }

    func test_SorobanCredentialsType_SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES() throws {
        let value: SorobanCredentialsType = .addressWithDelegates
        XCTAssertEqual(try value.toXdrJson(), "\"address_with_delegates\"",
                       "SorobanCredentialsType.addressWithDelegates must render as address_with_delegates")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SorobanCredentialsType.addressWithDelegates must keep its XDR value")
        XCTAssertEqual(try SorobanCredentialsType.fromXdrJson("\"address_with_delegates\""), value,
                       "address_with_delegates must read back as SorobanCredentialsType.addressWithDelegates")
    }

    func test_SorobanCredentialsType_SOROBAN_CREDENTIALS_SOURCE_ACCOUNT() throws {
        let value: SorobanCredentialsType = .sourceAccount
        XCTAssertEqual(try value.toXdrJson(), "\"source_account\"",
                       "SorobanCredentialsType.sourceAccount must render as source_account")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SorobanCredentialsType.sourceAccount must keep its XDR value")
        XCTAssertEqual(try SorobanCredentialsType.fromXdrJson("\"source_account\""), value,
                       "source_account must read back as SorobanCredentialsType.sourceAccount")
    }

    func test_SorobanCredentialsType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SorobanCredentialsType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SorobanCredentialsType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanCredentialsType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SorobanCredentialsXDR_addressV2_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanCredentialsXDR.fromXdrJson("\"address_v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanCredentialsXDR.address_v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanCredentialsXDR")
            XCTAssertEqual(key, "address_v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanCredentialsXDR_addressV2_roundTrip() throws {
        let original: SorobanCredentialsXDR = .addressV2(SorobanAddressCredentialsXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), signature: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanCredentialsXDR.fromXdrJson(json)
        let viaValue = try SorobanCredentialsXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanCredentialsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanCredentialsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanCredentialsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanCredentialsXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanCredentialsXDR_addressWithDelegates_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanCredentialsXDR.fromXdrJson("\"address_with_delegates\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanCredentialsXDR.address_with_delegates: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanCredentialsXDR")
            XCTAssertEqual(key, "address_with_delegates",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanCredentialsXDR_addressWithDelegates_roundTrip() throws {
        let original: SorobanCredentialsXDR = .addressWithDelegates(SorobanAddressCredentialsWithDelegatesXDR(addressCredentials: SorobanAddressCredentialsXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), signature: .void), delegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [])])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanCredentialsXDR.fromXdrJson(json)
        let viaValue = try SorobanCredentialsXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanCredentialsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanCredentialsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanCredentialsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanCredentialsXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanCredentialsXDR_address_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanCredentialsXDR.fromXdrJson("\"address\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanCredentialsXDR.address: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanCredentialsXDR")
            XCTAssertEqual(key, "address",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanCredentialsXDR_address_roundTrip() throws {
        let original: SorobanCredentialsXDR = .address(SorobanAddressCredentialsXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), nonce: Int64(1234567), signatureExpirationLedger: UInt32(42), signature: .void))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanCredentialsXDR.fromXdrJson(json)
        let viaValue = try SorobanCredentialsXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanCredentialsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanCredentialsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanCredentialsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanCredentialsXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanCredentialsXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SorobanCredentialsXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SorobanCredentialsXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SorobanCredentialsXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SorobanCredentialsXDR_sourceAccount_roundTrip() throws {
        let original: SorobanCredentialsXDR = .sourceAccount
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanCredentialsXDR.fromXdrJson(json)
        let viaValue = try SorobanCredentialsXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanCredentialsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanCredentialsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanCredentialsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanCredentialsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanCredentialsXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanDelegateSignatureXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanDelegateSignatureXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanDelegateSignatureXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanDelegateSignatureXDR_roundTrip() throws {
        let original: SorobanDelegateSignatureXDR = SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [SorobanDelegateSignatureXDR(address: .account(try PublicKey([UInt8](repeating: 0xAB, count: 32))), signature: .void, nestedDelegates: [])])])])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanDelegateSignatureXDR.fromXdrJson(json)
        let viaValue = try SorobanDelegateSignatureXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanDelegateSignatureXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanDelegateSignatureXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanDelegateSignatureXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanDelegateSignatureXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanDelegateSignatureXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanDelegateSignatureXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanResourcesExtV0_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanResourcesExtV0.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanResourcesExtV0 must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanResourcesExtV0_roundTrip() throws {
        let original: SorobanResourcesExtV0 = SorobanResourcesExtV0(archivedSorobanEntries: [UInt32(42)])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanResourcesExtV0.fromXdrJson(json)
        let viaValue = try SorobanResourcesExtV0.fromXdrJsonValue(tree)
        let viaTree = try SorobanResourcesExtV0.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanResourcesExtV0 must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanResourcesExtV0 must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanResourcesExtV0 must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanResourcesExtV0 must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanResourcesExtV0 must reach the same bytes through JSON and XDR")
    }

    func test_SorobanResourcesExt_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SorobanResourcesExt.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SorobanResourcesExt: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SorobanResourcesExt")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SorobanResourcesExt_resourceExt_rejectsBareString() throws {
        XCTAssertThrowsError(try SorobanResourcesExt.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SorobanResourcesExt.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SorobanResourcesExt")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SorobanResourcesExt_resourceExt_roundTrip() throws {
        let original: SorobanResourcesExt = .resourceExt(SorobanResourcesExtV0(archivedSorobanEntries: [UInt32(42)]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanResourcesExt.fromXdrJson(json)
        let viaValue = try SorobanResourcesExt.fromXdrJsonValue(tree)
        let viaTree = try SorobanResourcesExt.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanResourcesExt must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanResourcesExt must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanResourcesExt must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanResourcesExt must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanResourcesExt must reach the same bytes through JSON and XDR")
    }

    func test_SorobanResourcesExt_void_roundTrip() throws {
        let original: SorobanResourcesExt = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanResourcesExt.fromXdrJson(json)
        let viaValue = try SorobanResourcesExt.fromXdrJsonValue(tree)
        let viaTree = try SorobanResourcesExt.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanResourcesExt must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanResourcesExt must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanResourcesExt must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanResourcesExt must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanResourcesExt must reach the same bytes through JSON and XDR")
    }

    func test_SorobanResourcesXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanResourcesXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanResourcesXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanResourcesXDR_roundTrip() throws {
        let original: SorobanResourcesXDR = SorobanResourcesXDR(footprint: LedgerFootprintXDR(readOnly: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))], readWrite: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))]), instructions: UInt32(42), diskReadBytes: UInt32(42), writeBytes: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanResourcesXDR.fromXdrJson(json)
        let viaValue = try SorobanResourcesXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanResourcesXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanResourcesXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanResourcesXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanResourcesXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanResourcesXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanResourcesXDR must reach the same bytes through JSON and XDR")
    }

    func test_SorobanTransactionDataXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SorobanTransactionDataXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SorobanTransactionDataXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SorobanTransactionDataXDR_roundTrip() throws {
        let original: SorobanTransactionDataXDR = SorobanTransactionDataXDR(ext: .void, resources: SorobanResourcesXDR(footprint: LedgerFootprintXDR(readOnly: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))], readWrite: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))]), instructions: UInt32(42), diskReadBytes: UInt32(42), writeBytes: UInt32(42)), resourceFee: Int64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SorobanTransactionDataXDR.fromXdrJson(json)
        let viaValue = try SorobanTransactionDataXDR.fromXdrJsonValue(tree)
        let viaTree = try SorobanTransactionDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SorobanTransactionDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SorobanTransactionDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SorobanTransactionDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SorobanTransactionDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SorobanTransactionDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeBoundsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeBoundsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeBoundsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeBoundsXDR_roundTrip() throws {
        let original: TimeBoundsXDR = TimeBoundsXDR(minTime: UInt64(1234567), maxTime: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeBoundsXDR.fromXdrJson(json)
        let viaValue = try TimeBoundsXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeBoundsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeBoundsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeBoundsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeBoundsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeBoundsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeBoundsXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionEnvelopeXDR_feeBump_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionEnvelopeXDR.fromXdrJson("\"tx_fee_bump\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionEnvelopeXDR.tx_fee_bump: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionEnvelopeXDR")
            XCTAssertEqual(key, "tx_fee_bump",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionEnvelopeXDR_feeBump_roundTrip() throws {
        let original: TransactionEnvelopeXDR = .feeBump(FeeBumpTransactionEnvelopeXDR(tx: FeeBumpTransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), innerTx: .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])), fee: UInt64(2000)), signatures: []))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionEnvelopeXDR.fromXdrJson(json)
        let viaValue = try TransactionEnvelopeXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionEnvelopeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionEnvelopeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionEnvelopeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionEnvelopeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionEnvelopeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionEnvelopeXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionEnvelopeXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionEnvelopeXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionEnvelopeXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionEnvelopeXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionEnvelopeXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionEnvelopeXDR.fromXdrJson("\"tx_v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionEnvelopeXDR.tx_v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionEnvelopeXDR")
            XCTAssertEqual(key, "tx_v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionEnvelopeXDR_v0_roundTrip() throws {
        let original: TransactionEnvelopeXDR = .v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionEnvelopeXDR.fromXdrJson(json)
        let viaValue = try TransactionEnvelopeXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionEnvelopeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionEnvelopeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionEnvelopeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionEnvelopeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionEnvelopeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionEnvelopeXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionEnvelopeXDR_v1_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionEnvelopeXDR.fromXdrJson("\"tx\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionEnvelopeXDR.tx: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionEnvelopeXDR")
            XCTAssertEqual(key, "tx",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionEnvelopeXDR_v1_roundTrip() throws {
        let original: TransactionEnvelopeXDR = .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: []))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionEnvelopeXDR.fromXdrJson(json)
        let viaValue = try TransactionEnvelopeXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionEnvelopeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionEnvelopeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionEnvelopeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionEnvelopeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionEnvelopeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionEnvelopeXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionExtXDR_sorobanTransactionData_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionExtXDR.fromXdrJson("\"v1\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionExtXDR.v1: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionExtXDR")
            XCTAssertEqual(key, "v1",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionExtXDR_sorobanTransactionData_roundTrip() throws {
        let original: TransactionExtXDR = .sorobanTransactionData(SorobanTransactionDataXDR(ext: .void, resources: SorobanResourcesXDR(footprint: LedgerFootprintXDR(readOnly: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))], readWrite: [.account(LedgerKeyAccountXDR(accountID: try PublicKey([UInt8](repeating: 0xAB, count: 32))))]), instructions: UInt32(42), diskReadBytes: UInt32(42), writeBytes: UInt32(42)), resourceFee: Int64(1234567)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionExtXDR.fromXdrJson(json)
        let viaValue = try TransactionExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionExtXDR_void_roundTrip() throws {
        let original: TransactionExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionExtXDR.fromXdrJson(json)
        let viaValue = try TransactionExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_badAuthExtra_roundTrip() throws {
        let original: TransactionResultBodyXDR = .badAuthExtra
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_badAuth_roundTrip() throws {
        let original: TransactionResultBodyXDR = .badAuth
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_badMinSeqAgeOrGap_roundTrip() throws {
        let original: TransactionResultBodyXDR = .badMinSeqAgeOrGap
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_badSeq_roundTrip() throws {
        let original: TransactionResultBodyXDR = .badSeq
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_badSponsorship_roundTrip() throws {
        let original: TransactionResultBodyXDR = .badSponsorship
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_failed_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionResultBodyXDR.fromXdrJson("\"tx_failed\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionResultBodyXDR.tx_failed: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionResultBodyXDR")
            XCTAssertEqual(key, "tx_failed",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionResultBodyXDR_failed_roundTrip() throws {
        let original: TransactionResultBodyXDR = .failed([.badAuth])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_feeBumpInnerFailed_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionResultBodyXDR.fromXdrJson("\"tx_fee_bump_inner_failed\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionResultBodyXDR.tx_fee_bump_inner_failed: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionResultBodyXDR")
            XCTAssertEqual(key, "tx_fee_bump_inner_failed",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionResultBodyXDR_feeBumpInnerFailed_roundTrip() throws {
        let original: TransactionResultBodyXDR = .feeBumpInnerFailed(InnerTransactionResultPair(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: InnerTransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_feeBumpInnerSuccess_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionResultBodyXDR.fromXdrJson("\"tx_fee_bump_inner_success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionResultBodyXDR.tx_fee_bump_inner_success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionResultBodyXDR")
            XCTAssertEqual(key, "tx_fee_bump_inner_success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionResultBodyXDR_feeBumpInnerSuccess_roundTrip() throws {
        let original: TransactionResultBodyXDR = .feeBumpInnerSuccess(InnerTransactionResultPair(hash: WrappedData32(Data(repeating: 0xAB, count: 32)), result: InnerTransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_frozenKeyAccessed_roundTrip() throws {
        let original: TransactionResultBodyXDR = .frozenKeyAccessed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_insufficientBalance_roundTrip() throws {
        let original: TransactionResultBodyXDR = .insufficientBalance
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_insufficientFee_roundTrip() throws {
        let original: TransactionResultBodyXDR = .insufficientFee
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_internalError_roundTrip() throws {
        let original: TransactionResultBodyXDR = .internalError
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_malformed_roundTrip() throws {
        let original: TransactionResultBodyXDR = .malformed
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_missingOperation_roundTrip() throws {
        let original: TransactionResultBodyXDR = .missingOperation
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_noAccount_roundTrip() throws {
        let original: TransactionResultBodyXDR = .noAccount
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_notSupported_roundTrip() throws {
        let original: TransactionResultBodyXDR = .notSupported
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionResultBodyXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionResultBodyXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionResultBodyXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionResultBodyXDR_sorobanInvalid_roundTrip() throws {
        let original: TransactionResultBodyXDR = .sorobanInvalid
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_success_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionResultBodyXDR.fromXdrJson("\"tx_success\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionResultBodyXDR.tx_success: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionResultBodyXDR")
            XCTAssertEqual(key, "tx_success",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionResultBodyXDR_success_roundTrip() throws {
        let original: TransactionResultBodyXDR = .success([.badAuth])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_tooEarly_roundTrip() throws {
        let original: TransactionResultBodyXDR = .tooEarly
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultBodyXDR_tooLate_roundTrip() throws {
        let original: TransactionResultBodyXDR = .tooLate
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultBodyXDR.fromXdrJson(json)
        let viaValue = try TransactionResultBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultCode_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try TransactionResultCode.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("TransactionResultCode: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionResultCode")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_TransactionResultCode_txBAD_AUTH() throws {
        let value: TransactionResultCode = .badAuth
        XCTAssertEqual(try value.toXdrJson(), "\"tx_bad_auth\"",
                       "TransactionResultCode.badAuth must render as tx_bad_auth")
        XCTAssertEqual(value.rawValue, Int32(-6),
                       "TransactionResultCode.badAuth must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_bad_auth\""), value,
                       "tx_bad_auth must read back as TransactionResultCode.badAuth")
    }

    func test_TransactionResultCode_txBAD_AUTH_EXTRA() throws {
        let value: TransactionResultCode = .badAuthExtra
        XCTAssertEqual(try value.toXdrJson(), "\"tx_bad_auth_extra\"",
                       "TransactionResultCode.badAuthExtra must render as tx_bad_auth_extra")
        XCTAssertEqual(value.rawValue, Int32(-10),
                       "TransactionResultCode.badAuthExtra must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_bad_auth_extra\""), value,
                       "tx_bad_auth_extra must read back as TransactionResultCode.badAuthExtra")
    }

    func test_TransactionResultCode_txBAD_MIN_SEQ_AGE_OR_GAP() throws {
        let value: TransactionResultCode = .badMinSeqAgeOrGap
        XCTAssertEqual(try value.toXdrJson(), "\"tx_bad_min_seq_age_or_gap\"",
                       "TransactionResultCode.badMinSeqAgeOrGap must render as tx_bad_min_seq_age_or_gap")
        XCTAssertEqual(value.rawValue, Int32(-15),
                       "TransactionResultCode.badMinSeqAgeOrGap must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_bad_min_seq_age_or_gap\""), value,
                       "tx_bad_min_seq_age_or_gap must read back as TransactionResultCode.badMinSeqAgeOrGap")
    }

    func test_TransactionResultCode_txBAD_SEQ() throws {
        let value: TransactionResultCode = .badSeq
        XCTAssertEqual(try value.toXdrJson(), "\"tx_bad_seq\"",
                       "TransactionResultCode.badSeq must render as tx_bad_seq")
        XCTAssertEqual(value.rawValue, Int32(-5),
                       "TransactionResultCode.badSeq must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_bad_seq\""), value,
                       "tx_bad_seq must read back as TransactionResultCode.badSeq")
    }

    func test_TransactionResultCode_txBAD_SPONSORSHIP() throws {
        let value: TransactionResultCode = .badSponsorship
        XCTAssertEqual(try value.toXdrJson(), "\"tx_bad_sponsorship\"",
                       "TransactionResultCode.badSponsorship must render as tx_bad_sponsorship")
        XCTAssertEqual(value.rawValue, Int32(-14),
                       "TransactionResultCode.badSponsorship must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_bad_sponsorship\""), value,
                       "tx_bad_sponsorship must read back as TransactionResultCode.badSponsorship")
    }

    func test_TransactionResultCode_txFAILED() throws {
        let value: TransactionResultCode = .failed
        XCTAssertEqual(try value.toXdrJson(), "\"tx_failed\"",
                       "TransactionResultCode.failed must render as tx_failed")
        XCTAssertEqual(value.rawValue, Int32(-1),
                       "TransactionResultCode.failed must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_failed\""), value,
                       "tx_failed must read back as TransactionResultCode.failed")
    }

    func test_TransactionResultCode_txFEE_BUMP_INNER_FAILED() throws {
        let value: TransactionResultCode = .feeBumpInnerFailed
        XCTAssertEqual(try value.toXdrJson(), "\"tx_fee_bump_inner_failed\"",
                       "TransactionResultCode.feeBumpInnerFailed must render as tx_fee_bump_inner_failed")
        XCTAssertEqual(value.rawValue, Int32(-13),
                       "TransactionResultCode.feeBumpInnerFailed must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_fee_bump_inner_failed\""), value,
                       "tx_fee_bump_inner_failed must read back as TransactionResultCode.feeBumpInnerFailed")
    }

    func test_TransactionResultCode_txFEE_BUMP_INNER_SUCCESS() throws {
        let value: TransactionResultCode = .feeBumpInnerSuccess
        XCTAssertEqual(try value.toXdrJson(), "\"tx_fee_bump_inner_success\"",
                       "TransactionResultCode.feeBumpInnerSuccess must render as tx_fee_bump_inner_success")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "TransactionResultCode.feeBumpInnerSuccess must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_fee_bump_inner_success\""), value,
                       "tx_fee_bump_inner_success must read back as TransactionResultCode.feeBumpInnerSuccess")
    }

    func test_TransactionResultCode_txFROZEN_KEY_ACCESSED() throws {
        let value: TransactionResultCode = .frozenKeyAccessed
        XCTAssertEqual(try value.toXdrJson(), "\"tx_frozen_key_accessed\"",
                       "TransactionResultCode.frozenKeyAccessed must render as tx_frozen_key_accessed")
        XCTAssertEqual(value.rawValue, Int32(-18),
                       "TransactionResultCode.frozenKeyAccessed must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_frozen_key_accessed\""), value,
                       "tx_frozen_key_accessed must read back as TransactionResultCode.frozenKeyAccessed")
    }

    func test_TransactionResultCode_txINSUFFICIENT_BALANCE() throws {
        let value: TransactionResultCode = .insufficientBalance
        XCTAssertEqual(try value.toXdrJson(), "\"tx_insufficient_balance\"",
                       "TransactionResultCode.insufficientBalance must render as tx_insufficient_balance")
        XCTAssertEqual(value.rawValue, Int32(-7),
                       "TransactionResultCode.insufficientBalance must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_insufficient_balance\""), value,
                       "tx_insufficient_balance must read back as TransactionResultCode.insufficientBalance")
    }

    func test_TransactionResultCode_txINSUFFICIENT_FEE() throws {
        let value: TransactionResultCode = .insufficientFee
        XCTAssertEqual(try value.toXdrJson(), "\"tx_insufficient_fee\"",
                       "TransactionResultCode.insufficientFee must render as tx_insufficient_fee")
        XCTAssertEqual(value.rawValue, Int32(-9),
                       "TransactionResultCode.insufficientFee must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_insufficient_fee\""), value,
                       "tx_insufficient_fee must read back as TransactionResultCode.insufficientFee")
    }

    func test_TransactionResultCode_txINTERNAL_ERROR() throws {
        let value: TransactionResultCode = .internalError
        XCTAssertEqual(try value.toXdrJson(), "\"tx_internal_error\"",
                       "TransactionResultCode.internalError must render as tx_internal_error")
        XCTAssertEqual(value.rawValue, Int32(-11),
                       "TransactionResultCode.internalError must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_internal_error\""), value,
                       "tx_internal_error must read back as TransactionResultCode.internalError")
    }

    func test_TransactionResultCode_txMALFORMED() throws {
        let value: TransactionResultCode = .malformed
        XCTAssertEqual(try value.toXdrJson(), "\"tx_malformed\"",
                       "TransactionResultCode.malformed must render as tx_malformed")
        XCTAssertEqual(value.rawValue, Int32(-16),
                       "TransactionResultCode.malformed must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_malformed\""), value,
                       "tx_malformed must read back as TransactionResultCode.malformed")
    }

    func test_TransactionResultCode_txMISSING_OPERATION() throws {
        let value: TransactionResultCode = .missingOperation
        XCTAssertEqual(try value.toXdrJson(), "\"tx_missing_operation\"",
                       "TransactionResultCode.missingOperation must render as tx_missing_operation")
        XCTAssertEqual(value.rawValue, Int32(-4),
                       "TransactionResultCode.missingOperation must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_missing_operation\""), value,
                       "tx_missing_operation must read back as TransactionResultCode.missingOperation")
    }

    func test_TransactionResultCode_txNOT_SUPPORTED() throws {
        let value: TransactionResultCode = .notSupported
        XCTAssertEqual(try value.toXdrJson(), "\"tx_not_supported\"",
                       "TransactionResultCode.notSupported must render as tx_not_supported")
        XCTAssertEqual(value.rawValue, Int32(-12),
                       "TransactionResultCode.notSupported must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_not_supported\""), value,
                       "tx_not_supported must read back as TransactionResultCode.notSupported")
    }

    func test_TransactionResultCode_txNO_ACCOUNT() throws {
        let value: TransactionResultCode = .noAccount
        XCTAssertEqual(try value.toXdrJson(), "\"tx_no_account\"",
                       "TransactionResultCode.noAccount must render as tx_no_account")
        XCTAssertEqual(value.rawValue, Int32(-8),
                       "TransactionResultCode.noAccount must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_no_account\""), value,
                       "tx_no_account must read back as TransactionResultCode.noAccount")
    }

    func test_TransactionResultCode_txSOROBAN_INVALID() throws {
        let value: TransactionResultCode = .sorobanInvalid
        XCTAssertEqual(try value.toXdrJson(), "\"tx_soroban_invalid\"",
                       "TransactionResultCode.sorobanInvalid must render as tx_soroban_invalid")
        XCTAssertEqual(value.rawValue, Int32(-17),
                       "TransactionResultCode.sorobanInvalid must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_soroban_invalid\""), value,
                       "tx_soroban_invalid must read back as TransactionResultCode.sorobanInvalid")
    }

    func test_TransactionResultCode_txSUCCESS() throws {
        let value: TransactionResultCode = .success
        XCTAssertEqual(try value.toXdrJson(), "\"tx_success\"",
                       "TransactionResultCode.success must render as tx_success")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "TransactionResultCode.success must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_success\""), value,
                       "tx_success must read back as TransactionResultCode.success")
    }

    func test_TransactionResultCode_txTOO_EARLY() throws {
        let value: TransactionResultCode = .tooEarly
        XCTAssertEqual(try value.toXdrJson(), "\"tx_too_early\"",
                       "TransactionResultCode.tooEarly must render as tx_too_early")
        XCTAssertEqual(value.rawValue, Int32(-2),
                       "TransactionResultCode.tooEarly must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_too_early\""), value,
                       "tx_too_early must read back as TransactionResultCode.tooEarly")
    }

    func test_TransactionResultCode_txTOO_LATE() throws {
        let value: TransactionResultCode = .tooLate
        XCTAssertEqual(try value.toXdrJson(), "\"tx_too_late\"",
                       "TransactionResultCode.tooLate must render as tx_too_late")
        XCTAssertEqual(value.rawValue, Int32(-3),
                       "TransactionResultCode.tooLate must keep its XDR value")
        XCTAssertEqual(try TransactionResultCode.fromXdrJson("\"tx_too_late\""), value,
                       "tx_too_late must read back as TransactionResultCode.tooLate")
    }

    func test_TransactionResultXDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionResultXDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionResultXDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionResultXDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionResultXDRExtXDR_void_roundTrip() throws {
        let original: TransactionResultXDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultXDRExtXDR.fromXdrJson(json)
        let viaValue = try TransactionResultXDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultXDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultXDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultXDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultXDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultXDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultXDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionResultXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionResultXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionResultXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionResultXDR_roundTrip() throws {
        let original: TransactionResultXDR = TransactionResultXDR(feeCharged: Int64(1234567), result: .tooEarly, ext: .void)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionResultXDR.fromXdrJson(json)
        let viaValue = try TransactionResultXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionResultXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionResultXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionResultXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionResultXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionResultXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionResultXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionSignaturePayloadTaggedTransactionXDR_feeBump_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJson("\"tx_fee_bump\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionSignaturePayloadTaggedTransactionXDR.tx_fee_bump: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionSignaturePayloadTaggedTransactionXDR")
            XCTAssertEqual(key, "tx_fee_bump",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionSignaturePayloadTaggedTransactionXDR_feeBump_roundTrip() throws {
        let original: TransactionSignaturePayloadTaggedTransactionXDR = .feeBump(FeeBumpTransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), innerTx: .v1(TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])), fee: UInt64(2000)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJson(json)
        let viaValue = try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionSignaturePayloadTaggedTransactionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionSignaturePayloadTaggedTransactionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionSignaturePayloadTaggedTransactionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionSignaturePayloadTaggedTransactionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionSignaturePayloadTaggedTransactionXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionSignaturePayloadTaggedTransactionXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionSignaturePayloadTaggedTransactionXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionSignaturePayloadTaggedTransactionXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionSignaturePayloadTaggedTransactionXDR_tx_rejectsBareString() throws {
        XCTAssertThrowsError(try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJson("\"tx\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("TransactionSignaturePayloadTaggedTransactionXDR.tx: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "TransactionSignaturePayloadTaggedTransactionXDR")
            XCTAssertEqual(key, "tx",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_TransactionSignaturePayloadTaggedTransactionXDR_tx_roundTrip() throws {
        let original: TransactionSignaturePayloadTaggedTransactionXDR = .tx(TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJson(json)
        let viaValue = try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionSignaturePayloadTaggedTransactionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionSignaturePayloadTaggedTransactionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionSignaturePayloadTaggedTransactionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionSignaturePayloadTaggedTransactionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionSignaturePayloadTaggedTransactionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionSignaturePayloadTaggedTransactionXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionSignaturePayload_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionSignaturePayload.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionSignaturePayload must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionSignaturePayload_roundTrip() throws {
        let original: TransactionSignaturePayload = TransactionSignaturePayload(networkId: WrappedData32(Data(repeating: 0xAB, count: 32)), taggedTransaction: .tx(TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionSignaturePayload.fromXdrJson(json)
        let viaValue = try TransactionSignaturePayload.fromXdrJsonValue(tree)
        let viaTree = try TransactionSignaturePayload.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionSignaturePayload must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionSignaturePayload must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionSignaturePayload must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionSignaturePayload must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionSignaturePayload must reach the same bytes through JSON and XDR")
    }

    func test_TransactionV0EnvelopeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionV0EnvelopeXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionV0EnvelopeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionV0EnvelopeXDR_roundTrip() throws {
        let original: TransactionV0EnvelopeXDR = TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: [])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionV0EnvelopeXDR.fromXdrJson(json)
        let viaValue = try TransactionV0EnvelopeXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionV0EnvelopeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionV0EnvelopeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionV0EnvelopeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionV0EnvelopeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionV0EnvelopeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionV0EnvelopeXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionV0XDRExtXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try TransactionV0XDRExtXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("TransactionV0XDRExtXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "TransactionV0XDRExtXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_TransactionV0XDRExtXDR_void_roundTrip() throws {
        let original: TransactionV0XDRExtXDR = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionV0XDRExtXDR.fromXdrJson(json)
        let viaValue = try TransactionV0XDRExtXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionV0XDRExtXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionV0XDRExtXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionV0XDRExtXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionV0XDRExtXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionV0XDRExtXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionV0XDRExtXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionV0XDR_roundTrip() throws {
        let original: TransactionV0XDR = TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: [])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionV0XDR.fromXdrJson(json)
        let viaValue = try TransactionV0XDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionV1EnvelopeXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionV1EnvelopeXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionV1EnvelopeXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionV1EnvelopeXDR_roundTrip() throws {
        let original: TransactionV1EnvelopeXDR = TransactionV1EnvelopeXDR(tx: TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100)), signatures: [])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionV1EnvelopeXDR.fromXdrJson(json)
        let viaValue = try TransactionV1EnvelopeXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionV1EnvelopeXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionV1EnvelopeXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionV1EnvelopeXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionV1EnvelopeXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionV1EnvelopeXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionV1EnvelopeXDR must reach the same bytes through JSON and XDR")
    }

    func test_TransactionXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TransactionXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TransactionXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TransactionXDR_roundTrip() throws {
        let original: TransactionXDR = TransactionXDR(sourceAccount: .ed25519([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), cond: .none, memo: .none, operations: [], maxOperationFee: UInt32(100))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TransactionXDR.fromXdrJson(json)
        let viaValue = try TransactionXDR.fromXdrJsonValue(tree)
        let viaTree = try TransactionXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TransactionXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TransactionXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TransactionXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TransactionXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TransactionXDR must reach the same bytes through JSON and XDR")
    }
}
