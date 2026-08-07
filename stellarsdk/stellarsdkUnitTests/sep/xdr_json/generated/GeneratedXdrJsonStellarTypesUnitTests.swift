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

final class GeneratedXdrJsonStellarTypesUnitTests: XCTestCase {

    func test_AccountIDXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AccountIDXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AccountIDXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AccountIDXDR_roundTrip() throws {
        let original: AccountIDXDR = try PublicKey([UInt8](repeating: 0xAB, count: 32))
        let tree = try AccountIDXDRJsonCodec.toXdrJsonValue(original)
        let json = try AccountIDXDRJsonCodec.toXdrJson(original)
        let decoded = try AccountIDXDRJsonCodec.fromXdrJson(json)
        let viaValue = try AccountIDXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try AccountIDXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try AccountIDXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "AccountIDXDR must produce the same tree after a round trip")
        XCTAssertEqual(try AccountIDXDRJsonCodec.toXdrJson(decoded), json,
                       "AccountIDXDR must produce the same text after a round trip")
        XCTAssertEqual(try AccountIDXDRJsonCodec.toXdrJson(viaValue), json,
                       "AccountIDXDR must read a tree the same way it reads text")
        XCTAssertEqual(try AccountIDXDRJsonCodec.toXdrJson(viaTree), json,
                       "AccountIDXDR must read a depth-checked tree the same way")
    }

    func test_BinaryFuseFilterTypeXDR_BINARY_FUSE_FILTER_16_BIT() throws {
        let value: BinaryFuseFilterTypeXDR = .sixteenBit
        XCTAssertEqual(try value.toXdrJson(), "\"b16_bit\"",
                       "BinaryFuseFilterTypeXDR.sixteenBit must render as b16_bit")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "BinaryFuseFilterTypeXDR.sixteenBit must keep its XDR value")
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.fromXdrJson("\"b16_bit\""), value,
                       "b16_bit must read back as BinaryFuseFilterTypeXDR.sixteenBit")
    }

    func test_BinaryFuseFilterTypeXDR_BINARY_FUSE_FILTER_32_BIT() throws {
        let value: BinaryFuseFilterTypeXDR = .thirtyTwoBit
        XCTAssertEqual(try value.toXdrJson(), "\"b32_bit\"",
                       "BinaryFuseFilterTypeXDR.thirtyTwoBit must render as b32_bit")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "BinaryFuseFilterTypeXDR.thirtyTwoBit must keep its XDR value")
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.fromXdrJson("\"b32_bit\""), value,
                       "b32_bit must read back as BinaryFuseFilterTypeXDR.thirtyTwoBit")
    }

    func test_BinaryFuseFilterTypeXDR_BINARY_FUSE_FILTER_8_BIT() throws {
        let value: BinaryFuseFilterTypeXDR = .eightBit
        XCTAssertEqual(try value.toXdrJson(), "\"b8_bit\"",
                       "BinaryFuseFilterTypeXDR.eightBit must render as b8_bit")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "BinaryFuseFilterTypeXDR.eightBit must keep its XDR value")
        XCTAssertEqual(try BinaryFuseFilterTypeXDR.fromXdrJson("\"b8_bit\""), value,
                       "b8_bit must read back as BinaryFuseFilterTypeXDR.eightBit")
    }

    func test_BinaryFuseFilterTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try BinaryFuseFilterTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("BinaryFuseFilterTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "BinaryFuseFilterTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClaimableBalanceIDType_CLAIMABLE_BALANCE_ID_TYPE_V0() throws {
        let value: ClaimableBalanceIDType = .claimableBalanceIDTypeV0
        XCTAssertEqual(try value.toXdrJson(), "\"claimable_balance_id_type_v0\"",
                       "ClaimableBalanceIDType.claimableBalanceIDTypeV0 must render as claimable_balance_id_type_v0")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ClaimableBalanceIDType.claimableBalanceIDTypeV0 must keep its XDR value")
        XCTAssertEqual(try ClaimableBalanceIDType.fromXdrJson("\"claimable_balance_id_type_v0\""), value,
                       "claimable_balance_id_type_v0 must read back as ClaimableBalanceIDType.claimableBalanceIDTypeV0")
    }

    func test_ClaimableBalanceIDType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ClaimableBalanceIDType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ClaimableBalanceIDType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ClaimableBalanceIDType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ClaimableBalanceIDXDR_claimableBalanceIDTypeV0_roundTrip() throws {
        let original: ClaimableBalanceIDXDR = .claimableBalanceIDTypeV0(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ClaimableBalanceIDXDR.fromXdrJson(json)
        let viaValue = try ClaimableBalanceIDXDR.fromXdrJsonValue(tree)
        let viaTree = try ClaimableBalanceIDXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ClaimableBalanceIDXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ClaimableBalanceIDXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ClaimableBalanceIDXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ClaimableBalanceIDXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ClaimableBalanceIDXDR must reach the same bytes through JSON and XDR")
    }

    func test_ClaimableBalanceIDXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ClaimableBalanceIDXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ClaimableBalanceIDXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractIDXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ContractIDXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ContractIDXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ContractIDXDR_roundTrip() throws {
        let original: ContractIDXDR = WrappedData32(Data(repeating: 0xAB, count: 32))
        let tree = try ContractIDXDRJsonCodec.toXdrJsonValue(original)
        let json = try ContractIDXDRJsonCodec.toXdrJson(original)
        let decoded = try ContractIDXDRJsonCodec.fromXdrJson(json)
        let viaValue = try ContractIDXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try ContractIDXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try ContractIDXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "ContractIDXDR must produce the same tree after a round trip")
        XCTAssertEqual(try ContractIDXDRJsonCodec.toXdrJson(decoded), json,
                       "ContractIDXDR must produce the same text after a round trip")
        XCTAssertEqual(try ContractIDXDRJsonCodec.toXdrJson(viaValue), json,
                       "ContractIDXDR must read a tree the same way it reads text")
        XCTAssertEqual(try ContractIDXDRJsonCodec.toXdrJson(viaTree), json,
                       "ContractIDXDR must read a depth-checked tree the same way")
    }

    func test_CryptoKeyType_KEY_TYPE_ED25519() throws {
        let value: CryptoKeyType = .ed25519
        XCTAssertEqual(try value.toXdrJson(), "\"ed25519\"",
                       "CryptoKeyType.ed25519 must render as ed25519")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "CryptoKeyType.ed25519 must keep its XDR value")
        XCTAssertEqual(try CryptoKeyType.fromXdrJson("\"ed25519\""), value,
                       "ed25519 must read back as CryptoKeyType.ed25519")
    }

    func test_CryptoKeyType_KEY_TYPE_ED25519_SIGNED_PAYLOAD() throws {
        let value: CryptoKeyType = .ed25519SignedPayload
        XCTAssertEqual(try value.toXdrJson(), "\"ed25519_signed_payload\"",
                       "CryptoKeyType.ed25519SignedPayload must render as ed25519_signed_payload")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "CryptoKeyType.ed25519SignedPayload must keep its XDR value")
        XCTAssertEqual(try CryptoKeyType.fromXdrJson("\"ed25519_signed_payload\""), value,
                       "ed25519_signed_payload must read back as CryptoKeyType.ed25519SignedPayload")
    }

    func test_CryptoKeyType_KEY_TYPE_HASH_X() throws {
        let value: CryptoKeyType = .hashX
        XCTAssertEqual(try value.toXdrJson(), "\"hash_x\"",
                       "CryptoKeyType.hashX must render as hash_x")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "CryptoKeyType.hashX must keep its XDR value")
        XCTAssertEqual(try CryptoKeyType.fromXdrJson("\"hash_x\""), value,
                       "hash_x must read back as CryptoKeyType.hashX")
    }

    func test_CryptoKeyType_KEY_TYPE_MUXED_ED25519() throws {
        let value: CryptoKeyType = .muxedEd25519
        XCTAssertEqual(try value.toXdrJson(), "\"muxed_ed25519\"",
                       "CryptoKeyType.muxedEd25519 must render as muxed_ed25519")
        XCTAssertEqual(value.rawValue, Int32(256),
                       "CryptoKeyType.muxedEd25519 must keep its XDR value")
        XCTAssertEqual(try CryptoKeyType.fromXdrJson("\"muxed_ed25519\""), value,
                       "muxed_ed25519 must read back as CryptoKeyType.muxedEd25519")
    }

    func test_CryptoKeyType_KEY_TYPE_PRE_AUTH_TX() throws {
        let value: CryptoKeyType = .preAuthTx
        XCTAssertEqual(try value.toXdrJson(), "\"pre_auth_tx\"",
                       "CryptoKeyType.preAuthTx must render as pre_auth_tx")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "CryptoKeyType.preAuthTx must keep its XDR value")
        XCTAssertEqual(try CryptoKeyType.fromXdrJson("\"pre_auth_tx\""), value,
                       "pre_auth_tx must read back as CryptoKeyType.preAuthTx")
    }

    func test_CryptoKeyType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try CryptoKeyType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("CryptoKeyType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "CryptoKeyType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_Curve25519PublicXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Curve25519PublicXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Curve25519PublicXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Curve25519PublicXDR_roundTrip() throws {
        let original: Curve25519PublicXDR = Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try Curve25519PublicXDR.fromXdrJson(json)
        let viaValue = try Curve25519PublicXDR.fromXdrJsonValue(tree)
        let viaTree = try Curve25519PublicXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "Curve25519PublicXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "Curve25519PublicXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "Curve25519PublicXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "Curve25519PublicXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "Curve25519PublicXDR must reach the same bytes through JSON and XDR")
    }

    func test_Curve25519SecretXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Curve25519SecretXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Curve25519SecretXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Curve25519SecretXDR_roundTrip() throws {
        let original: Curve25519SecretXDR = Curve25519SecretXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try Curve25519SecretXDR.fromXdrJson(json)
        let viaValue = try Curve25519SecretXDR.fromXdrJsonValue(tree)
        let viaTree = try Curve25519SecretXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "Curve25519SecretXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "Curve25519SecretXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "Curve25519SecretXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "Curve25519SecretXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "Curve25519SecretXDR must reach the same bytes through JSON and XDR")
    }

    func test_DurationXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try DurationXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "DurationXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_DurationXDR_roundTrip() throws {
        let original: DurationXDR = UInt64(1234567)
        let tree = try DurationXDRJsonCodec.toXdrJsonValue(original)
        let json = try DurationXDRJsonCodec.toXdrJson(original)
        let decoded = try DurationXDRJsonCodec.fromXdrJson(json)
        let viaValue = try DurationXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try DurationXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try DurationXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "DurationXDR must produce the same tree after a round trip")
        XCTAssertEqual(try DurationXDRJsonCodec.toXdrJson(decoded), json,
                       "DurationXDR must produce the same text after a round trip")
        XCTAssertEqual(try DurationXDRJsonCodec.toXdrJson(viaValue), json,
                       "DurationXDR must read a tree the same way it reads text")
        XCTAssertEqual(try DurationXDRJsonCodec.toXdrJson(viaTree), json,
                       "DurationXDR must read a depth-checked tree the same way")
    }

    func test_Ed25519SignedPayload_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Ed25519SignedPayload.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Ed25519SignedPayload must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Ed25519SignedPayload_roundTrip() throws {
        let original: Ed25519SignedPayload = Ed25519SignedPayload(ed25519: WrappedData32(Data(repeating: 0xAB, count: 32)), payload: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try Ed25519SignedPayload.fromXdrJson(json)
        let viaValue = try Ed25519SignedPayload.fromXdrJsonValue(tree)
        let viaTree = try Ed25519SignedPayload.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "Ed25519SignedPayload must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "Ed25519SignedPayload must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "Ed25519SignedPayload must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "Ed25519SignedPayload must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "Ed25519SignedPayload must reach the same bytes through JSON and XDR")
    }

    func test_ExtensionPoint_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try ExtensionPoint.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("ExtensionPoint: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "ExtensionPoint")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_ExtensionPoint_void_roundTrip() throws {
        let original: ExtensionPoint = .void
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ExtensionPoint.fromXdrJson(json)
        let viaValue = try ExtensionPoint.fromXdrJsonValue(tree)
        let viaTree = try ExtensionPoint.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ExtensionPoint must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ExtensionPoint must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ExtensionPoint must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ExtensionPoint must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ExtensionPoint must reach the same bytes through JSON and XDR")
    }

    func test_HashXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try HashXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "HashXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_HashXDR_roundTrip() throws {
        let original: HashXDR = WrappedData32(Data(repeating: 0xAB, count: 32))
        let tree = try HashXDRJsonCodec.toXdrJsonValue(original)
        let json = try HashXDRJsonCodec.toXdrJson(original)
        let decoded = try HashXDRJsonCodec.fromXdrJson(json)
        let viaValue = try HashXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try HashXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try HashXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "HashXDR must produce the same tree after a round trip")
        XCTAssertEqual(try HashXDRJsonCodec.toXdrJson(decoded), json,
                       "HashXDR must produce the same text after a round trip")
        XCTAssertEqual(try HashXDRJsonCodec.toXdrJson(viaValue), json,
                       "HashXDR must read a tree the same way it reads text")
        XCTAssertEqual(try HashXDRJsonCodec.toXdrJson(viaTree), json,
                       "HashXDR must read a depth-checked tree the same way")
    }

    func test_HmacSha256KeyXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try HmacSha256KeyXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "HmacSha256KeyXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_HmacSha256KeyXDR_roundTrip() throws {
        let original: HmacSha256KeyXDR = HmacSha256KeyXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HmacSha256KeyXDR.fromXdrJson(json)
        let viaValue = try HmacSha256KeyXDR.fromXdrJsonValue(tree)
        let viaTree = try HmacSha256KeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HmacSha256KeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HmacSha256KeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HmacSha256KeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HmacSha256KeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HmacSha256KeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_HmacSha256MacXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try HmacSha256MacXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "HmacSha256MacXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_HmacSha256MacXDR_roundTrip() throws {
        let original: HmacSha256MacXDR = HmacSha256MacXDR(mac: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HmacSha256MacXDR.fromXdrJson(json)
        let viaValue = try HmacSha256MacXDR.fromXdrJsonValue(tree)
        let viaTree = try HmacSha256MacXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HmacSha256MacXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HmacSha256MacXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HmacSha256MacXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HmacSha256MacXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HmacSha256MacXDR must reach the same bytes through JSON and XDR")
    }

    func test_Int32XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Int32XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Int32XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Int32XDR_roundTrip() throws {
        let original: Int32XDR = Int32(42)
        let tree = try Int32XDRJsonCodec.toXdrJsonValue(original)
        let json = try Int32XDRJsonCodec.toXdrJson(original)
        let decoded = try Int32XDRJsonCodec.fromXdrJson(json)
        let viaValue = try Int32XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try Int32XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try Int32XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "Int32XDR must produce the same tree after a round trip")
        XCTAssertEqual(try Int32XDRJsonCodec.toXdrJson(decoded), json,
                       "Int32XDR must produce the same text after a round trip")
        XCTAssertEqual(try Int32XDRJsonCodec.toXdrJson(viaValue), json,
                       "Int32XDR must read a tree the same way it reads text")
        XCTAssertEqual(try Int32XDRJsonCodec.toXdrJson(viaTree), json,
                       "Int32XDR must read a depth-checked tree the same way")
    }

    func test_Int64XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Int64XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Int64XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Int64XDR_roundTrip() throws {
        let original: Int64XDR = Int64(1234567)
        let tree = try Int64XDRJsonCodec.toXdrJsonValue(original)
        let json = try Int64XDRJsonCodec.toXdrJson(original)
        let decoded = try Int64XDRJsonCodec.fromXdrJson(json)
        let viaValue = try Int64XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try Int64XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try Int64XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "Int64XDR must produce the same tree after a round trip")
        XCTAssertEqual(try Int64XDRJsonCodec.toXdrJson(decoded), json,
                       "Int64XDR must produce the same text after a round trip")
        XCTAssertEqual(try Int64XDRJsonCodec.toXdrJson(viaValue), json,
                       "Int64XDR must read a tree the same way it reads text")
        XCTAssertEqual(try Int64XDRJsonCodec.toXdrJson(viaTree), json,
                       "Int64XDR must read a depth-checked tree the same way")
    }

    func test_NodeIDXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try NodeIDXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "NodeIDXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_NodeIDXDR_roundTrip() throws {
        let original: NodeIDXDR = try PublicKey([UInt8](repeating: 0xAB, count: 32))
        let tree = try NodeIDXDRJsonCodec.toXdrJsonValue(original)
        let json = try NodeIDXDRJsonCodec.toXdrJson(original)
        let decoded = try NodeIDXDRJsonCodec.fromXdrJson(json)
        let viaValue = try NodeIDXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try NodeIDXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try NodeIDXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "NodeIDXDR must produce the same tree after a round trip")
        XCTAssertEqual(try NodeIDXDRJsonCodec.toXdrJson(decoded), json,
                       "NodeIDXDR must produce the same text after a round trip")
        XCTAssertEqual(try NodeIDXDRJsonCodec.toXdrJson(viaValue), json,
                       "NodeIDXDR must read a tree the same way it reads text")
        XCTAssertEqual(try NodeIDXDRJsonCodec.toXdrJson(viaTree), json,
                       "NodeIDXDR must read a depth-checked tree the same way")
    }

    func test_PoolIDXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PoolIDXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PoolIDXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PoolIDXDR_roundTrip() throws {
        let original: PoolIDXDR = WrappedData32(Data(repeating: 0xAB, count: 32))
        let tree = try PoolIDXDRJsonCodec.toXdrJsonValue(original)
        let json = try PoolIDXDRJsonCodec.toXdrJson(original)
        let decoded = try PoolIDXDRJsonCodec.fromXdrJson(json)
        let viaValue = try PoolIDXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try PoolIDXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try PoolIDXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "PoolIDXDR must produce the same tree after a round trip")
        XCTAssertEqual(try PoolIDXDRJsonCodec.toXdrJson(decoded), json,
                       "PoolIDXDR must produce the same text after a round trip")
        XCTAssertEqual(try PoolIDXDRJsonCodec.toXdrJson(viaValue), json,
                       "PoolIDXDR must read a tree the same way it reads text")
        XCTAssertEqual(try PoolIDXDRJsonCodec.toXdrJson(viaTree), json,
                       "PoolIDXDR must read a depth-checked tree the same way")
    }

    func test_PublicKeyTypeXDR_PUBLIC_KEY_TYPE_ED25519() throws {
        let value: PublicKeyTypeXDR = .publicKeyTypeEd25519
        XCTAssertEqual(try value.toXdrJson(), "\"public_key_type_ed25519\"",
                       "PublicKeyTypeXDR.publicKeyTypeEd25519 must render as public_key_type_ed25519")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "PublicKeyTypeXDR.publicKeyTypeEd25519 must keep its XDR value")
        XCTAssertEqual(try PublicKeyTypeXDR.fromXdrJson("\"public_key_type_ed25519\""), value,
                       "public_key_type_ed25519 must read back as PublicKeyTypeXDR.publicKeyTypeEd25519")
    }

    func test_PublicKeyTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try PublicKeyTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("PublicKeyTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "PublicKeyTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_PublicKey_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PublicKey.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PublicKey must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PublicKey_roundTrip() throws {
        let original: PublicKey = try PublicKey([UInt8](repeating: 0xAB, count: 32))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PublicKey.fromXdrJson(json)
        let viaValue = try PublicKey.fromXdrJsonValue(tree)
        let viaTree = try PublicKey.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PublicKey must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PublicKey must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PublicKey must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PublicKey must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PublicKey must reach the same bytes through JSON and XDR")
    }

    func test_SerializedBinaryFuseFilterXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SerializedBinaryFuseFilterXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SerializedBinaryFuseFilterXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SerializedBinaryFuseFilterXDR_roundTrip() throws {
        let original: SerializedBinaryFuseFilterXDR = SerializedBinaryFuseFilterXDR(type: .eightBit, inputHashSeed: ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0xAB, count: 16))), filterSeed: ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0xAB, count: 16))), segmentLength: UInt32(42), segementLengthMask: UInt32(42), segmentCount: UInt32(42), segmentCountLength: UInt32(42), fingerprintLength: UInt32(42), fingerprints: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SerializedBinaryFuseFilterXDR.fromXdrJson(json)
        let viaValue = try SerializedBinaryFuseFilterXDR.fromXdrJsonValue(tree)
        let viaTree = try SerializedBinaryFuseFilterXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SerializedBinaryFuseFilterXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SerializedBinaryFuseFilterXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SerializedBinaryFuseFilterXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SerializedBinaryFuseFilterXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SerializedBinaryFuseFilterXDR must reach the same bytes through JSON and XDR")
    }

    func test_ShortHashSeedXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ShortHashSeedXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ShortHashSeedXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ShortHashSeedXDR_roundTrip() throws {
        let original: ShortHashSeedXDR = ShortHashSeedXDR(seed: WrappedData16(Data(repeating: 0xAB, count: 16)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ShortHashSeedXDR.fromXdrJson(json)
        let viaValue = try ShortHashSeedXDR.fromXdrJsonValue(tree)
        let viaTree = try ShortHashSeedXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ShortHashSeedXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ShortHashSeedXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ShortHashSeedXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ShortHashSeedXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ShortHashSeedXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignatureHintXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignatureHintXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignatureHintXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignatureHintXDR_roundTrip() throws {
        let original: SignatureHintXDR = WrappedData4(Data(repeating: 0xAB, count: 4))
        let tree = try SignatureHintXDRJsonCodec.toXdrJsonValue(original)
        let json = try SignatureHintXDRJsonCodec.toXdrJson(original)
        let decoded = try SignatureHintXDRJsonCodec.fromXdrJson(json)
        let viaValue = try SignatureHintXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try SignatureHintXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try SignatureHintXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "SignatureHintXDR must produce the same tree after a round trip")
        XCTAssertEqual(try SignatureHintXDRJsonCodec.toXdrJson(decoded), json,
                       "SignatureHintXDR must produce the same text after a round trip")
        XCTAssertEqual(try SignatureHintXDRJsonCodec.toXdrJson(viaValue), json,
                       "SignatureHintXDR must read a tree the same way it reads text")
        XCTAssertEqual(try SignatureHintXDRJsonCodec.toXdrJson(viaTree), json,
                       "SignatureHintXDR must read a depth-checked tree the same way")
    }

    func test_SignatureXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignatureXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignatureXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignatureXDR_roundTrip() throws {
        let original: SignatureXDR = Data([0x01, 0x02, 0x03])
        let tree = try SignatureXDRJsonCodec.toXdrJsonValue(original)
        let json = try SignatureXDRJsonCodec.toXdrJson(original)
        let decoded = try SignatureXDRJsonCodec.fromXdrJson(json)
        let viaValue = try SignatureXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try SignatureXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try SignatureXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "SignatureXDR must produce the same tree after a round trip")
        XCTAssertEqual(try SignatureXDRJsonCodec.toXdrJson(decoded), json,
                       "SignatureXDR must produce the same text after a round trip")
        XCTAssertEqual(try SignatureXDRJsonCodec.toXdrJson(viaValue), json,
                       "SignatureXDR must read a tree the same way it reads text")
        XCTAssertEqual(try SignatureXDRJsonCodec.toXdrJson(viaTree), json,
                       "SignatureXDR must read a depth-checked tree the same way")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_ED25519() throws {
        let value: SignerKeyType = .ed25519
        XCTAssertEqual(try value.toXdrJson(), "\"ed25519\"",
                       "SignerKeyType.ed25519 must render as ed25519")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "SignerKeyType.ed25519 must keep its XDR value")
        XCTAssertEqual(try SignerKeyType.fromXdrJson("\"ed25519\""), value,
                       "ed25519 must read back as SignerKeyType.ed25519")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD() throws {
        let value: SignerKeyType = .signedPayload
        XCTAssertEqual(try value.toXdrJson(), "\"ed25519_signed_payload\"",
                       "SignerKeyType.signedPayload must render as ed25519_signed_payload")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "SignerKeyType.signedPayload must keep its XDR value")
        XCTAssertEqual(try SignerKeyType.fromXdrJson("\"ed25519_signed_payload\""), value,
                       "ed25519_signed_payload must read back as SignerKeyType.signedPayload")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_HASH_X() throws {
        let value: SignerKeyType = .hashX
        XCTAssertEqual(try value.toXdrJson(), "\"hash_x\"",
                       "SignerKeyType.hashX must render as hash_x")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SignerKeyType.hashX must keep its XDR value")
        XCTAssertEqual(try SignerKeyType.fromXdrJson("\"hash_x\""), value,
                       "hash_x must read back as SignerKeyType.hashX")
    }

    func test_SignerKeyType_SIGNER_KEY_TYPE_PRE_AUTH_TX() throws {
        let value: SignerKeyType = .preAuthTx
        XCTAssertEqual(try value.toXdrJson(), "\"pre_auth_tx\"",
                       "SignerKeyType.preAuthTx must render as pre_auth_tx")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SignerKeyType.preAuthTx must keep its XDR value")
        XCTAssertEqual(try SignerKeyType.fromXdrJson("\"pre_auth_tx\""), value,
                       "pre_auth_tx must read back as SignerKeyType.preAuthTx")
    }

    func test_SignerKeyType_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SignerKeyType.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SignerKeyType: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SignerKeyType")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SignerKeyXDR_ed25519_roundTrip() throws {
        let original: SignerKeyXDR = .ed25519(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignerKeyXDR.fromXdrJson(json)
        let viaValue = try SignerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try SignerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignerKeyXDR_hashX_roundTrip() throws {
        let original: SignerKeyXDR = .hashX(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignerKeyXDR.fromXdrJson(json)
        let viaValue = try SignerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try SignerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignerKeyXDR_preAuthTx_roundTrip() throws {
        let original: SignerKeyXDR = .preAuthTx(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignerKeyXDR.fromXdrJson(json)
        let viaValue = try SignerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try SignerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignerKeyXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignerKeyXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignerKeyXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignerKeyXDR_signedPayload_roundTrip() throws {
        let original: SignerKeyXDR = .signedPayload(Ed25519SignedPayload(ed25519: WrappedData32(Data(repeating: 0xAB, count: 32)), payload: Data([0x01, 0x02, 0x03])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignerKeyXDR.fromXdrJson(json)
        let viaValue = try SignerKeyXDR.fromXdrJsonValue(tree)
        let viaTree = try SignerKeyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignerKeyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignerKeyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignerKeyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignerKeyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignerKeyXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimePointXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimePointXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimePointXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimePointXDR_roundTrip() throws {
        let original: TimePointXDR = UInt64(1234567)
        let tree = try TimePointXDRJsonCodec.toXdrJsonValue(original)
        let json = try TimePointXDRJsonCodec.toXdrJson(original)
        let decoded = try TimePointXDRJsonCodec.fromXdrJson(json)
        let viaValue = try TimePointXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try TimePointXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try TimePointXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "TimePointXDR must produce the same tree after a round trip")
        XCTAssertEqual(try TimePointXDRJsonCodec.toXdrJson(decoded), json,
                       "TimePointXDR must produce the same text after a round trip")
        XCTAssertEqual(try TimePointXDRJsonCodec.toXdrJson(viaValue), json,
                       "TimePointXDR must read a tree the same way it reads text")
        XCTAssertEqual(try TimePointXDRJsonCodec.toXdrJson(viaTree), json,
                       "TimePointXDR must read a depth-checked tree the same way")
    }

    func test_Uint256XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Uint256XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Uint256XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Uint256XDR_roundTrip() throws {
        let original: Uint256XDR = WrappedData32(Data(repeating: 0xAB, count: 32))
        let tree = try Uint256XDRJsonCodec.toXdrJsonValue(original)
        let json = try Uint256XDRJsonCodec.toXdrJson(original)
        let decoded = try Uint256XDRJsonCodec.fromXdrJson(json)
        let viaValue = try Uint256XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try Uint256XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try Uint256XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "Uint256XDR must produce the same tree after a round trip")
        XCTAssertEqual(try Uint256XDRJsonCodec.toXdrJson(decoded), json,
                       "Uint256XDR must produce the same text after a round trip")
        XCTAssertEqual(try Uint256XDRJsonCodec.toXdrJson(viaValue), json,
                       "Uint256XDR must read a tree the same way it reads text")
        XCTAssertEqual(try Uint256XDRJsonCodec.toXdrJson(viaTree), json,
                       "Uint256XDR must read a depth-checked tree the same way")
    }

    func test_Uint32XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Uint32XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Uint32XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Uint32XDR_roundTrip() throws {
        let original: Uint32XDR = UInt32(42)
        let tree = try Uint32XDRJsonCodec.toXdrJsonValue(original)
        let json = try Uint32XDRJsonCodec.toXdrJson(original)
        let decoded = try Uint32XDRJsonCodec.fromXdrJson(json)
        let viaValue = try Uint32XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try Uint32XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try Uint32XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "Uint32XDR must produce the same tree after a round trip")
        XCTAssertEqual(try Uint32XDRJsonCodec.toXdrJson(decoded), json,
                       "Uint32XDR must produce the same text after a round trip")
        XCTAssertEqual(try Uint32XDRJsonCodec.toXdrJson(viaValue), json,
                       "Uint32XDR must read a tree the same way it reads text")
        XCTAssertEqual(try Uint32XDRJsonCodec.toXdrJson(viaTree), json,
                       "Uint32XDR must read a depth-checked tree the same way")
    }

    func test_Uint64XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try Uint64XDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "Uint64XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_Uint64XDR_roundTrip() throws {
        let original: Uint64XDR = UInt64(1234567)
        let tree = try Uint64XDRJsonCodec.toXdrJsonValue(original)
        let json = try Uint64XDRJsonCodec.toXdrJson(original)
        let decoded = try Uint64XDRJsonCodec.fromXdrJson(json)
        let viaValue = try Uint64XDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try Uint64XDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try Uint64XDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "Uint64XDR must produce the same tree after a round trip")
        XCTAssertEqual(try Uint64XDRJsonCodec.toXdrJson(decoded), json,
                       "Uint64XDR must produce the same text after a round trip")
        XCTAssertEqual(try Uint64XDRJsonCodec.toXdrJson(viaValue), json,
                       "Uint64XDR must read a tree the same way it reads text")
        XCTAssertEqual(try Uint64XDRJsonCodec.toXdrJson(viaTree), json,
                       "Uint64XDR must read a depth-checked tree the same way")
    }
}
