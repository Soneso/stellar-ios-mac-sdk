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

final class GeneratedXdrJsonStellarOverlayUnitTests: XCTestCase {

    func test_AuthCertXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AuthCertXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AuthCertXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AuthCertXDR_roundTrip() throws {
        let original: AuthCertXDR = AuthCertXDR(pubkey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32))), expiration: UInt64(1234567), sig: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AuthCertXDR.fromXdrJson(json)
        let viaValue = try AuthCertXDR.fromXdrJsonValue(tree)
        let viaTree = try AuthCertXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AuthCertXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AuthCertXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AuthCertXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AuthCertXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AuthCertXDR must reach the same bytes through JSON and XDR")
    }

    func test_AuthXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AuthXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AuthXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AuthXDR_roundTrip() throws {
        let original: AuthXDR = AuthXDR(flags: Int32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AuthXDR.fromXdrJson(json)
        let viaValue = try AuthXDR.fromXdrJsonValue(tree)
        let viaTree = try AuthXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AuthXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AuthXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AuthXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AuthXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AuthXDR must reach the same bytes through JSON and XDR")
    }

    func test_AuthenticatedMessageXDRV0XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try AuthenticatedMessageXDRV0XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "AuthenticatedMessageXDRV0XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_AuthenticatedMessageXDRV0XDR_roundTrip() throws {
        let original: AuthenticatedMessageXDRV0XDR = AuthenticatedMessageXDRV0XDR(sequence: UInt64(1234567), message: .error(ErrorXDR(code: .misc, msg: "test_string")), mac: HmacSha256MacXDR(mac: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AuthenticatedMessageXDRV0XDR.fromXdrJson(json)
        let viaValue = try AuthenticatedMessageXDRV0XDR.fromXdrJsonValue(tree)
        let viaTree = try AuthenticatedMessageXDRV0XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AuthenticatedMessageXDRV0XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AuthenticatedMessageXDRV0XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AuthenticatedMessageXDRV0XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AuthenticatedMessageXDRV0XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AuthenticatedMessageXDRV0XDR must reach the same bytes through JSON and XDR")
    }

    func test_AuthenticatedMessageXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try AuthenticatedMessageXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("AuthenticatedMessageXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "AuthenticatedMessageXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_AuthenticatedMessageXDR_v0_rejectsBareString() throws {
        XCTAssertThrowsError(try AuthenticatedMessageXDR.fromXdrJson("\"v0\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("AuthenticatedMessageXDR.v0: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "AuthenticatedMessageXDR")
            XCTAssertEqual(key, "v0",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_AuthenticatedMessageXDR_v0_roundTrip() throws {
        let original: AuthenticatedMessageXDR = .v0(AuthenticatedMessageXDRV0XDR(sequence: UInt64(1234567), message: .error(ErrorXDR(code: .misc, msg: "test_string")), mac: HmacSha256MacXDR(mac: WrappedData32(Data(repeating: 0xAB, count: 32)))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try AuthenticatedMessageXDR.fromXdrJson(json)
        let viaValue = try AuthenticatedMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try AuthenticatedMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "AuthenticatedMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "AuthenticatedMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "AuthenticatedMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "AuthenticatedMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "AuthenticatedMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_DontHaveXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try DontHaveXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "DontHaveXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_DontHaveXDR_roundTrip() throws {
        let original: DontHaveXDR = DontHaveXDR(type: .errorMsg, reqHash: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try DontHaveXDR.fromXdrJson(json)
        let viaValue = try DontHaveXDR.fromXdrJsonValue(tree)
        let viaTree = try DontHaveXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "DontHaveXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "DontHaveXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "DontHaveXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "DontHaveXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "DontHaveXDR must reach the same bytes through JSON and XDR")
    }

    func test_EncryptedBodyXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try EncryptedBodyXDRJsonCodec.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "EncryptedBodyXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_EncryptedBodyXDR_roundTrip() throws {
        let original: EncryptedBodyXDR = Data([0x01, 0x02, 0x03])
        let tree = try EncryptedBodyXDRJsonCodec.toXdrJsonValue(original)
        let json = try EncryptedBodyXDRJsonCodec.toXdrJson(original)
        let decoded = try EncryptedBodyXDRJsonCodec.fromXdrJson(json)
        let viaValue = try EncryptedBodyXDRJsonCodec.fromXdrJsonValue(tree)
        let viaTree = try EncryptedBodyXDRJsonCodec.fromXdrJsonTree(tree)
        XCTAssertEqual(try EncryptedBodyXDRJsonCodec.toXdrJsonValue(decoded), tree,
                       "EncryptedBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try EncryptedBodyXDRJsonCodec.toXdrJson(decoded), json,
                       "EncryptedBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try EncryptedBodyXDRJsonCodec.toXdrJson(viaValue), json,
                       "EncryptedBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try EncryptedBodyXDRJsonCodec.toXdrJson(viaTree), json,
                       "EncryptedBodyXDR must read a depth-checked tree the same way")
    }

    func test_ErrorCodeXDR_ERR_AUTH() throws {
        let value: ErrorCodeXDR = .auth
        XCTAssertEqual(try value.toXdrJson(), "\"auth\"",
                       "ErrorCodeXDR.auth must render as auth")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "ErrorCodeXDR.auth must keep its XDR value")
        XCTAssertEqual(try ErrorCodeXDR.fromXdrJson("\"auth\""), value,
                       "auth must read back as ErrorCodeXDR.auth")
    }

    func test_ErrorCodeXDR_ERR_CONF() throws {
        let value: ErrorCodeXDR = .conf
        XCTAssertEqual(try value.toXdrJson(), "\"conf\"",
                       "ErrorCodeXDR.conf must render as conf")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "ErrorCodeXDR.conf must keep its XDR value")
        XCTAssertEqual(try ErrorCodeXDR.fromXdrJson("\"conf\""), value,
                       "conf must read back as ErrorCodeXDR.conf")
    }

    func test_ErrorCodeXDR_ERR_DATA() throws {
        let value: ErrorCodeXDR = .data
        XCTAssertEqual(try value.toXdrJson(), "\"data\"",
                       "ErrorCodeXDR.data must render as data")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "ErrorCodeXDR.data must keep its XDR value")
        XCTAssertEqual(try ErrorCodeXDR.fromXdrJson("\"data\""), value,
                       "data must read back as ErrorCodeXDR.data")
    }

    func test_ErrorCodeXDR_ERR_LOAD() throws {
        let value: ErrorCodeXDR = .load
        XCTAssertEqual(try value.toXdrJson(), "\"load\"",
                       "ErrorCodeXDR.load must render as load")
        XCTAssertEqual(value.rawValue, Int32(4),
                       "ErrorCodeXDR.load must keep its XDR value")
        XCTAssertEqual(try ErrorCodeXDR.fromXdrJson("\"load\""), value,
                       "load must read back as ErrorCodeXDR.load")
    }

    func test_ErrorCodeXDR_ERR_MISC() throws {
        let value: ErrorCodeXDR = .misc
        XCTAssertEqual(try value.toXdrJson(), "\"misc\"",
                       "ErrorCodeXDR.misc must render as misc")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "ErrorCodeXDR.misc must keep its XDR value")
        XCTAssertEqual(try ErrorCodeXDR.fromXdrJson("\"misc\""), value,
                       "misc must read back as ErrorCodeXDR.misc")
    }

    func test_ErrorCodeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try ErrorCodeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("ErrorCodeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "ErrorCodeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_ErrorXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try ErrorXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "ErrorXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_ErrorXDR_roundTrip() throws {
        let original: ErrorXDR = ErrorXDR(code: .misc, msg: "test_string")
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try ErrorXDR.fromXdrJson(json)
        let viaValue = try ErrorXDR.fromXdrJsonValue(tree)
        let viaTree = try ErrorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "ErrorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "ErrorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "ErrorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "ErrorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "ErrorXDR must reach the same bytes through JSON and XDR")
    }

    func test_FloodAdvertXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FloodAdvertXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FloodAdvertXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FloodAdvertXDR_roundTrip() throws {
        let original: FloodAdvertXDR = FloodAdvertXDR(txHashes: TxAdvertVectorXDR(wrapped: [WrappedData32(Data(repeating: 0xAB, count: 32))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FloodAdvertXDR.fromXdrJson(json)
        let viaValue = try FloodAdvertXDR.fromXdrJsonValue(tree)
        let viaTree = try FloodAdvertXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FloodAdvertXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FloodAdvertXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FloodAdvertXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FloodAdvertXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FloodAdvertXDR must reach the same bytes through JSON and XDR")
    }

    func test_FloodDemandXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try FloodDemandXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "FloodDemandXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_FloodDemandXDR_roundTrip() throws {
        let original: FloodDemandXDR = FloodDemandXDR(txHashes: TxDemandVectorXDR(wrapped: [WrappedData32(Data(repeating: 0xAB, count: 32))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try FloodDemandXDR.fromXdrJson(json)
        let viaValue = try FloodDemandXDR.fromXdrJsonValue(tree)
        let viaTree = try FloodDemandXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "FloodDemandXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "FloodDemandXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "FloodDemandXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "FloodDemandXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "FloodDemandXDR must reach the same bytes through JSON and XDR")
    }

    func test_HelloXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try HelloXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "HelloXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_HelloXDR_roundTrip() throws {
        let original: HelloXDR = HelloXDR(ledgerVersion: UInt32(42), overlayVersion: UInt32(42), overlayMinVersion: UInt32(42), networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), versionStr: "test_string", listeningPort: Int32(42), peerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), cert: AuthCertXDR(pubkey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32))), expiration: UInt64(1234567), sig: Data([0x01, 0x02, 0x03])), nonce: WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try HelloXDR.fromXdrJson(json)
        let viaValue = try HelloXDR.fromXdrJsonValue(tree)
        let viaTree = try HelloXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "HelloXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "HelloXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "HelloXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "HelloXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "HelloXDR must reach the same bytes through JSON and XDR")
    }

    func test_IPAddrTypeXDR_IPv4() throws {
        let value: IPAddrTypeXDR = .pv4
        XCTAssertEqual(try value.toXdrJson(), "\"i_pv4\"",
                       "IPAddrTypeXDR.pv4 must render as i_pv4")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "IPAddrTypeXDR.pv4 must keep its XDR value")
        XCTAssertEqual(try IPAddrTypeXDR.fromXdrJson("\"i_pv4\""), value,
                       "i_pv4 must read back as IPAddrTypeXDR.pv4")
    }

    func test_IPAddrTypeXDR_IPv6() throws {
        let value: IPAddrTypeXDR = .pv6
        XCTAssertEqual(try value.toXdrJson(), "\"i_pv6\"",
                       "IPAddrTypeXDR.pv6 must render as i_pv6")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "IPAddrTypeXDR.pv6 must keep its XDR value")
        XCTAssertEqual(try IPAddrTypeXDR.fromXdrJson("\"i_pv6\""), value,
                       "i_pv6 must read back as IPAddrTypeXDR.pv6")
    }

    func test_IPAddrTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try IPAddrTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("IPAddrTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "IPAddrTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_MessageTypeXDR_AUTH() throws {
        let value: MessageTypeXDR = .auth
        XCTAssertEqual(try value.toXdrJson(), "\"auth\"",
                       "MessageTypeXDR.auth must render as auth")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "MessageTypeXDR.auth must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"auth\""), value,
                       "auth must read back as MessageTypeXDR.auth")
    }

    func test_MessageTypeXDR_DONT_HAVE() throws {
        let value: MessageTypeXDR = .dontHave
        XCTAssertEqual(try value.toXdrJson(), "\"dont_have\"",
                       "MessageTypeXDR.dontHave must render as dont_have")
        XCTAssertEqual(value.rawValue, Int32(3),
                       "MessageTypeXDR.dontHave must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"dont_have\""), value,
                       "dont_have must read back as MessageTypeXDR.dontHave")
    }

    func test_MessageTypeXDR_ERROR_MSG() throws {
        let value: MessageTypeXDR = .errorMsg
        XCTAssertEqual(try value.toXdrJson(), "\"error_msg\"",
                       "MessageTypeXDR.errorMsg must render as error_msg")
        XCTAssertEqual(value.rawValue, Int32(0),
                       "MessageTypeXDR.errorMsg must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"error_msg\""), value,
                       "error_msg must read back as MessageTypeXDR.errorMsg")
    }

    func test_MessageTypeXDR_FLOOD_ADVERT() throws {
        let value: MessageTypeXDR = .floodAdvert
        XCTAssertEqual(try value.toXdrJson(), "\"flood_advert\"",
                       "MessageTypeXDR.floodAdvert must render as flood_advert")
        XCTAssertEqual(value.rawValue, Int32(18),
                       "MessageTypeXDR.floodAdvert must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"flood_advert\""), value,
                       "flood_advert must read back as MessageTypeXDR.floodAdvert")
    }

    func test_MessageTypeXDR_FLOOD_DEMAND() throws {
        let value: MessageTypeXDR = .floodDemand
        XCTAssertEqual(try value.toXdrJson(), "\"flood_demand\"",
                       "MessageTypeXDR.floodDemand must render as flood_demand")
        XCTAssertEqual(value.rawValue, Int32(19),
                       "MessageTypeXDR.floodDemand must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"flood_demand\""), value,
                       "flood_demand must read back as MessageTypeXDR.floodDemand")
    }

    func test_MessageTypeXDR_GENERALIZED_TX_SET() throws {
        let value: MessageTypeXDR = .generalizedTxSet
        XCTAssertEqual(try value.toXdrJson(), "\"generalized_tx_set\"",
                       "MessageTypeXDR.generalizedTxSet must render as generalized_tx_set")
        XCTAssertEqual(value.rawValue, Int32(17),
                       "MessageTypeXDR.generalizedTxSet must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"generalized_tx_set\""), value,
                       "generalized_tx_set must read back as MessageTypeXDR.generalizedTxSet")
    }

    func test_MessageTypeXDR_GET_SCP_QUORUMSET() throws {
        let value: MessageTypeXDR = .getScpQuorumset
        XCTAssertEqual(try value.toXdrJson(), "\"get_scp_quorumset\"",
                       "MessageTypeXDR.getScpQuorumset must render as get_scp_quorumset")
        XCTAssertEqual(value.rawValue, Int32(9),
                       "MessageTypeXDR.getScpQuorumset must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"get_scp_quorumset\""), value,
                       "get_scp_quorumset must read back as MessageTypeXDR.getScpQuorumset")
    }

    func test_MessageTypeXDR_GET_SCP_STATE() throws {
        let value: MessageTypeXDR = .getScpState
        XCTAssertEqual(try value.toXdrJson(), "\"get_scp_state\"",
                       "MessageTypeXDR.getScpState must render as get_scp_state")
        XCTAssertEqual(value.rawValue, Int32(12),
                       "MessageTypeXDR.getScpState must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"get_scp_state\""), value,
                       "get_scp_state must read back as MessageTypeXDR.getScpState")
    }

    func test_MessageTypeXDR_GET_TX_SET() throws {
        let value: MessageTypeXDR = .getTxSet
        XCTAssertEqual(try value.toXdrJson(), "\"get_tx_set\"",
                       "MessageTypeXDR.getTxSet must render as get_tx_set")
        XCTAssertEqual(value.rawValue, Int32(6),
                       "MessageTypeXDR.getTxSet must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"get_tx_set\""), value,
                       "get_tx_set must read back as MessageTypeXDR.getTxSet")
    }

    func test_MessageTypeXDR_HELLO() throws {
        let value: MessageTypeXDR = .hello
        XCTAssertEqual(try value.toXdrJson(), "\"hello\"",
                       "MessageTypeXDR.hello must render as hello")
        XCTAssertEqual(value.rawValue, Int32(13),
                       "MessageTypeXDR.hello must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"hello\""), value,
                       "hello must read back as MessageTypeXDR.hello")
    }

    func test_MessageTypeXDR_PEERS() throws {
        let value: MessageTypeXDR = .peers
        XCTAssertEqual(try value.toXdrJson(), "\"peers\"",
                       "MessageTypeXDR.peers must render as peers")
        XCTAssertEqual(value.rawValue, Int32(5),
                       "MessageTypeXDR.peers must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"peers\""), value,
                       "peers must read back as MessageTypeXDR.peers")
    }

    func test_MessageTypeXDR_SCP_MESSAGE() throws {
        let value: MessageTypeXDR = .scpMessage
        XCTAssertEqual(try value.toXdrJson(), "\"scp_message\"",
                       "MessageTypeXDR.scpMessage must render as scp_message")
        XCTAssertEqual(value.rawValue, Int32(11),
                       "MessageTypeXDR.scpMessage must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"scp_message\""), value,
                       "scp_message must read back as MessageTypeXDR.scpMessage")
    }

    func test_MessageTypeXDR_SCP_QUORUMSET() throws {
        let value: MessageTypeXDR = .scpQuorumset
        XCTAssertEqual(try value.toXdrJson(), "\"scp_quorumset\"",
                       "MessageTypeXDR.scpQuorumset must render as scp_quorumset")
        XCTAssertEqual(value.rawValue, Int32(10),
                       "MessageTypeXDR.scpQuorumset must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"scp_quorumset\""), value,
                       "scp_quorumset must read back as MessageTypeXDR.scpQuorumset")
    }

    func test_MessageTypeXDR_SEND_MORE() throws {
        let value: MessageTypeXDR = .sendMore
        XCTAssertEqual(try value.toXdrJson(), "\"send_more\"",
                       "MessageTypeXDR.sendMore must render as send_more")
        XCTAssertEqual(value.rawValue, Int32(16),
                       "MessageTypeXDR.sendMore must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"send_more\""), value,
                       "send_more must read back as MessageTypeXDR.sendMore")
    }

    func test_MessageTypeXDR_SEND_MORE_EXTENDED() throws {
        let value: MessageTypeXDR = .sendMoreExtended
        XCTAssertEqual(try value.toXdrJson(), "\"send_more_extended\"",
                       "MessageTypeXDR.sendMoreExtended must render as send_more_extended")
        XCTAssertEqual(value.rawValue, Int32(20),
                       "MessageTypeXDR.sendMoreExtended must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"send_more_extended\""), value,
                       "send_more_extended must read back as MessageTypeXDR.sendMoreExtended")
    }

    func test_MessageTypeXDR_TIME_SLICED_SURVEY_REQUEST() throws {
        let value: MessageTypeXDR = .timeSlicedSurveyRequest
        XCTAssertEqual(try value.toXdrJson(), "\"time_sliced_survey_request\"",
                       "MessageTypeXDR.timeSlicedSurveyRequest must render as time_sliced_survey_request")
        XCTAssertEqual(value.rawValue, Int32(21),
                       "MessageTypeXDR.timeSlicedSurveyRequest must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"time_sliced_survey_request\""), value,
                       "time_sliced_survey_request must read back as MessageTypeXDR.timeSlicedSurveyRequest")
    }

    func test_MessageTypeXDR_TIME_SLICED_SURVEY_RESPONSE() throws {
        let value: MessageTypeXDR = .timeSlicedSurveyResponse
        XCTAssertEqual(try value.toXdrJson(), "\"time_sliced_survey_response\"",
                       "MessageTypeXDR.timeSlicedSurveyResponse must render as time_sliced_survey_response")
        XCTAssertEqual(value.rawValue, Int32(22),
                       "MessageTypeXDR.timeSlicedSurveyResponse must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"time_sliced_survey_response\""), value,
                       "time_sliced_survey_response must read back as MessageTypeXDR.timeSlicedSurveyResponse")
    }

    func test_MessageTypeXDR_TIME_SLICED_SURVEY_START_COLLECTING() throws {
        let value: MessageTypeXDR = .timeSlicedSurveyStartCollecting
        XCTAssertEqual(try value.toXdrJson(), "\"time_sliced_survey_start_collecting\"",
                       "MessageTypeXDR.timeSlicedSurveyStartCollecting must render as time_sliced_survey_start_collecting")
        XCTAssertEqual(value.rawValue, Int32(23),
                       "MessageTypeXDR.timeSlicedSurveyStartCollecting must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"time_sliced_survey_start_collecting\""), value,
                       "time_sliced_survey_start_collecting must read back as MessageTypeXDR.timeSlicedSurveyStartCollecting")
    }

    func test_MessageTypeXDR_TIME_SLICED_SURVEY_STOP_COLLECTING() throws {
        let value: MessageTypeXDR = .timeSlicedSurveyStopCollecting
        XCTAssertEqual(try value.toXdrJson(), "\"time_sliced_survey_stop_collecting\"",
                       "MessageTypeXDR.timeSlicedSurveyStopCollecting must render as time_sliced_survey_stop_collecting")
        XCTAssertEqual(value.rawValue, Int32(24),
                       "MessageTypeXDR.timeSlicedSurveyStopCollecting must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"time_sliced_survey_stop_collecting\""), value,
                       "time_sliced_survey_stop_collecting must read back as MessageTypeXDR.timeSlicedSurveyStopCollecting")
    }

    func test_MessageTypeXDR_TRANSACTION() throws {
        let value: MessageTypeXDR = .transaction
        XCTAssertEqual(try value.toXdrJson(), "\"transaction\"",
                       "MessageTypeXDR.transaction must render as transaction")
        XCTAssertEqual(value.rawValue, Int32(8),
                       "MessageTypeXDR.transaction must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"transaction\""), value,
                       "transaction must read back as MessageTypeXDR.transaction")
    }

    func test_MessageTypeXDR_TX_SET() throws {
        let value: MessageTypeXDR = .txSet
        XCTAssertEqual(try value.toXdrJson(), "\"tx_set\"",
                       "MessageTypeXDR.txSet must render as tx_set")
        XCTAssertEqual(value.rawValue, Int32(7),
                       "MessageTypeXDR.txSet must keep its XDR value")
        XCTAssertEqual(try MessageTypeXDR.fromXdrJson("\"tx_set\""), value,
                       "tx_set must read back as MessageTypeXDR.txSet")
    }

    func test_MessageTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try MessageTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("MessageTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "MessageTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_PeerAddressXDRIpXDR_ipv4_rejectsBareString() throws {
        XCTAssertThrowsError(try PeerAddressXDRIpXDR.fromXdrJson("\"i_pv4\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("PeerAddressXDRIpXDR.i_pv4: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "PeerAddressXDRIpXDR")
            XCTAssertEqual(key, "i_pv4",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_PeerAddressXDRIpXDR_ipv4_roundTrip() throws {
        let original: PeerAddressXDRIpXDR = .ipv4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PeerAddressXDRIpXDR.fromXdrJson(json)
        let viaValue = try PeerAddressXDRIpXDR.fromXdrJsonValue(tree)
        let viaTree = try PeerAddressXDRIpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PeerAddressXDRIpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PeerAddressXDRIpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PeerAddressXDRIpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PeerAddressXDRIpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PeerAddressXDRIpXDR must reach the same bytes through JSON and XDR")
    }

    func test_PeerAddressXDRIpXDR_ipv6_rejectsBareString() throws {
        XCTAssertThrowsError(try PeerAddressXDRIpXDR.fromXdrJson("\"i_pv6\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("PeerAddressXDRIpXDR.i_pv6: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "PeerAddressXDRIpXDR")
            XCTAssertEqual(key, "i_pv6",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_PeerAddressXDRIpXDR_ipv6_roundTrip() throws {
        let original: PeerAddressXDRIpXDR = .ipv6(WrappedData16(Data(repeating: 0xAB, count: 16)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PeerAddressXDRIpXDR.fromXdrJson(json)
        let viaValue = try PeerAddressXDRIpXDR.fromXdrJsonValue(tree)
        let viaTree = try PeerAddressXDRIpXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PeerAddressXDRIpXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PeerAddressXDRIpXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PeerAddressXDRIpXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PeerAddressXDRIpXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PeerAddressXDRIpXDR must reach the same bytes through JSON and XDR")
    }

    func test_PeerAddressXDRIpXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try PeerAddressXDRIpXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("PeerAddressXDRIpXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "PeerAddressXDRIpXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_PeerAddressXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PeerAddressXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PeerAddressXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PeerAddressXDR_roundTrip() throws {
        let original: PeerAddressXDR = PeerAddressXDR(ip: .ipv4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00]))), port: UInt32(42), numFailures: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PeerAddressXDR.fromXdrJson(json)
        let viaValue = try PeerAddressXDR.fromXdrJsonValue(tree)
        let viaTree = try PeerAddressXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PeerAddressXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PeerAddressXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PeerAddressXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PeerAddressXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PeerAddressXDR must reach the same bytes through JSON and XDR")
    }

    func test_PeerStatsXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try PeerStatsXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "PeerStatsXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_PeerStatsXDR_roundTrip() throws {
        let original: PeerStatsXDR = PeerStatsXDR(id: try PublicKey([UInt8](repeating: 0xAB, count: 32)), versionStr: "test_string", messagesRead: UInt64(1234567), messagesWritten: UInt64(1234567), bytesRead: UInt64(1234567), bytesWritten: UInt64(1234567), secondsConnected: UInt64(1234567), uniqueFloodBytesRecv: UInt64(1234567), duplicateFloodBytesRecv: UInt64(1234567), uniqueFetchBytesRecv: UInt64(1234567), duplicateFetchBytesRecv: UInt64(1234567), uniqueFloodMessageRecv: UInt64(1234567), duplicateFloodMessageRecv: UInt64(1234567), uniqueFetchMessageRecv: UInt64(1234567), duplicateFetchMessageRecv: UInt64(1234567))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try PeerStatsXDR.fromXdrJson(json)
        let viaValue = try PeerStatsXDR.fromXdrJsonValue(tree)
        let viaTree = try PeerStatsXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "PeerStatsXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "PeerStatsXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "PeerStatsXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "PeerStatsXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "PeerStatsXDR must reach the same bytes through JSON and XDR")
    }

    func test_SendMoreExtendedXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SendMoreExtendedXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SendMoreExtendedXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SendMoreExtendedXDR_roundTrip() throws {
        let original: SendMoreExtendedXDR = SendMoreExtendedXDR(numMessages: UInt32(42), numBytes: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SendMoreExtendedXDR.fromXdrJson(json)
        let viaValue = try SendMoreExtendedXDR.fromXdrJsonValue(tree)
        let viaTree = try SendMoreExtendedXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SendMoreExtendedXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SendMoreExtendedXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SendMoreExtendedXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SendMoreExtendedXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SendMoreExtendedXDR must reach the same bytes through JSON and XDR")
    }

    func test_SendMoreXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SendMoreXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SendMoreXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SendMoreXDR_roundTrip() throws {
        let original: SendMoreXDR = SendMoreXDR(numMessages: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SendMoreXDR.fromXdrJson(json)
        let viaValue = try SendMoreXDR.fromXdrJsonValue(tree)
        let viaTree = try SendMoreXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SendMoreXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SendMoreXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SendMoreXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SendMoreXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SendMoreXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignedTimeSlicedSurveyRequestMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignedTimeSlicedSurveyRequestMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignedTimeSlicedSurveyRequestMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignedTimeSlicedSurveyRequestMessageXDR_roundTrip() throws {
        let original: SignedTimeSlicedSurveyRequestMessageXDR = SignedTimeSlicedSurveyRequestMessageXDR(requestSignature: Data([0x01, 0x02, 0x03]), request: TimeSlicedSurveyRequestMessageXDR(request: SurveyRequestMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), encryptionKey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32))), commandType: .timeSlicedSurveyTopology), nonce: UInt32(42), inboundPeersIndex: UInt32(42), outboundPeersIndex: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignedTimeSlicedSurveyRequestMessageXDR.fromXdrJson(json)
        let viaValue = try SignedTimeSlicedSurveyRequestMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try SignedTimeSlicedSurveyRequestMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignedTimeSlicedSurveyRequestMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignedTimeSlicedSurveyRequestMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignedTimeSlicedSurveyRequestMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignedTimeSlicedSurveyRequestMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignedTimeSlicedSurveyRequestMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignedTimeSlicedSurveyResponseMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignedTimeSlicedSurveyResponseMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignedTimeSlicedSurveyResponseMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignedTimeSlicedSurveyResponseMessageXDR_roundTrip() throws {
        let original: SignedTimeSlicedSurveyResponseMessageXDR = SignedTimeSlicedSurveyResponseMessageXDR(responseSignature: Data([0x01, 0x02, 0x03]), response: TimeSlicedSurveyResponseMessageXDR(response: SurveyResponseMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), commandType: .timeSlicedSurveyTopology, encryptedBody: Data([0x01, 0x02, 0x03])), nonce: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignedTimeSlicedSurveyResponseMessageXDR.fromXdrJson(json)
        let viaValue = try SignedTimeSlicedSurveyResponseMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try SignedTimeSlicedSurveyResponseMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignedTimeSlicedSurveyResponseMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignedTimeSlicedSurveyResponseMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignedTimeSlicedSurveyResponseMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignedTimeSlicedSurveyResponseMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignedTimeSlicedSurveyResponseMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignedTimeSlicedSurveyStartCollectingMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignedTimeSlicedSurveyStartCollectingMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignedTimeSlicedSurveyStartCollectingMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignedTimeSlicedSurveyStartCollectingMessageXDR_roundTrip() throws {
        let original: SignedTimeSlicedSurveyStartCollectingMessageXDR = SignedTimeSlicedSurveyStartCollectingMessageXDR(signature: Data([0x01, 0x02, 0x03]), startCollecting: TimeSlicedSurveyStartCollectingMessageXDR(surveyorID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), nonce: UInt32(42), ledgerNum: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignedTimeSlicedSurveyStartCollectingMessageXDR.fromXdrJson(json)
        let viaValue = try SignedTimeSlicedSurveyStartCollectingMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try SignedTimeSlicedSurveyStartCollectingMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignedTimeSlicedSurveyStartCollectingMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignedTimeSlicedSurveyStartCollectingMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignedTimeSlicedSurveyStartCollectingMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignedTimeSlicedSurveyStartCollectingMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignedTimeSlicedSurveyStartCollectingMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_SignedTimeSlicedSurveyStopCollectingMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SignedTimeSlicedSurveyStopCollectingMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SignedTimeSlicedSurveyStopCollectingMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SignedTimeSlicedSurveyStopCollectingMessageXDR_roundTrip() throws {
        let original: SignedTimeSlicedSurveyStopCollectingMessageXDR = SignedTimeSlicedSurveyStopCollectingMessageXDR(signature: Data([0x01, 0x02, 0x03]), stopCollecting: TimeSlicedSurveyStopCollectingMessageXDR(surveyorID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), nonce: UInt32(42), ledgerNum: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SignedTimeSlicedSurveyStopCollectingMessageXDR.fromXdrJson(json)
        let viaValue = try SignedTimeSlicedSurveyStopCollectingMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try SignedTimeSlicedSurveyStopCollectingMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SignedTimeSlicedSurveyStopCollectingMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SignedTimeSlicedSurveyStopCollectingMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SignedTimeSlicedSurveyStopCollectingMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SignedTimeSlicedSurveyStopCollectingMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SignedTimeSlicedSurveyStopCollectingMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_auth_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"auth\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.auth: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "auth",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_auth_roundTrip() throws {
        let original: StellarMessageXDR = .auth(AuthXDR(flags: Int32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_dontHave_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"dont_have\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.dont_have: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "dont_have",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_dontHave_roundTrip() throws {
        let original: StellarMessageXDR = .dontHave(DontHaveXDR(type: .errorMsg, reqHash: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_envelope_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"scp_message\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.scp_message: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "scp_message",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_envelope_roundTrip() throws {
        let original: StellarMessageXDR = .envelope(SCPEnvelopeXDR(statement: SCPStatementXDR(nodeID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), slotIndex: UInt64(1234567), pledges: .prepare(SCPStatementXDRPrepareXDR(quorumSetHash: WrappedData32(Data(repeating: 0xAB, count: 32)), ballot: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), prepared: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), preparedPrime: SCPBallotXDR(counter: UInt32(42), value: Data([0x01, 0x02, 0x03])), nC: UInt32(42), nH: UInt32(42)))), signature: Data([0x01, 0x02, 0x03])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_error_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"error_msg\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.error_msg: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "error_msg",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_error_roundTrip() throws {
        let original: StellarMessageXDR = .error(ErrorXDR(code: .misc, msg: "test_string"))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_floodAdvert_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"flood_advert\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.flood_advert: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "flood_advert",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_floodAdvert_roundTrip() throws {
        let original: StellarMessageXDR = .floodAdvert(FloodAdvertXDR(txHashes: TxAdvertVectorXDR(wrapped: [WrappedData32(Data(repeating: 0xAB, count: 32))])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_floodDemand_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"flood_demand\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.flood_demand: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "flood_demand",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_floodDemand_roundTrip() throws {
        let original: StellarMessageXDR = .floodDemand(FloodDemandXDR(txHashes: TxDemandVectorXDR(wrapped: [WrappedData32(Data(repeating: 0xAB, count: 32))])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_generalizedTxSet_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"generalized_tx_set\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.generalized_tx_set: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "generalized_tx_set",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_generalizedTxSet_roundTrip() throws {
        let original: StellarMessageXDR = .generalizedTxSet(.v1TxSet(TransactionSetV1XDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), phases: [.v0Components([])])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_getSCPLedgerSeq_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"get_scp_state\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.get_scp_state: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "get_scp_state",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_getSCPLedgerSeq_roundTrip() throws {
        let original: StellarMessageXDR = .getSCPLedgerSeq(UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_hello_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"hello\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.hello: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "hello",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_hello_roundTrip() throws {
        let original: StellarMessageXDR = .hello(HelloXDR(ledgerVersion: UInt32(42), overlayVersion: UInt32(42), overlayMinVersion: UInt32(42), networkID: WrappedData32(Data(repeating: 0xAB, count: 32)), versionStr: "test_string", listeningPort: Int32(42), peerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), cert: AuthCertXDR(pubkey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32))), expiration: UInt64(1234567), sig: Data([0x01, 0x02, 0x03])), nonce: WrappedData32(Data(repeating: 0xAB, count: 32))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_peers_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"peers\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.peers: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "peers",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_peers_roundTrip() throws {
        let original: StellarMessageXDR = .peers([PeerAddressXDR(ip: .ipv4(WrappedData4(Data([0x55, 0x53, 0x44, 0x00]))), port: UInt32(42), numFailures: UInt32(42))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_qSetHash_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"get_scp_quorumset\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.get_scp_quorumset: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "get_scp_quorumset",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_qSetHash_roundTrip() throws {
        let original: StellarMessageXDR = .qSetHash(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_qSet_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"scp_quorumset\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.scp_quorumset: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "scp_quorumset",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_qSet_roundTrip() throws {
        let original: StellarMessageXDR = .qSet(SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [try PublicKey([UInt8](repeating: 0xAB, count: 32))], innerSets: [SCPQuorumSetXDR(threshold: UInt32(42), validators: [], innerSets: [])])])]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("StellarMessageXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_StellarMessageXDR_sendMoreExtendedMessage_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"send_more_extended\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.send_more_extended: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "send_more_extended",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_sendMoreExtendedMessage_roundTrip() throws {
        let original: StellarMessageXDR = .sendMoreExtendedMessage(SendMoreExtendedXDR(numMessages: UInt32(42), numBytes: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_sendMoreMessage_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"send_more\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.send_more: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "send_more",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_sendMoreMessage_roundTrip() throws {
        let original: StellarMessageXDR = .sendMoreMessage(SendMoreXDR(numMessages: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyRequestMessage_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"time_sliced_survey_request\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.time_sliced_survey_request: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "time_sliced_survey_request",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyRequestMessage_roundTrip() throws {
        let original: StellarMessageXDR = .signedTimeSlicedSurveyRequestMessage(SignedTimeSlicedSurveyRequestMessageXDR(requestSignature: Data([0x01, 0x02, 0x03]), request: TimeSlicedSurveyRequestMessageXDR(request: SurveyRequestMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), encryptionKey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32))), commandType: .timeSlicedSurveyTopology), nonce: UInt32(42), inboundPeersIndex: UInt32(42), outboundPeersIndex: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyResponseMessage_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"time_sliced_survey_response\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.time_sliced_survey_response: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "time_sliced_survey_response",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyResponseMessage_roundTrip() throws {
        let original: StellarMessageXDR = .signedTimeSlicedSurveyResponseMessage(SignedTimeSlicedSurveyResponseMessageXDR(responseSignature: Data([0x01, 0x02, 0x03]), response: TimeSlicedSurveyResponseMessageXDR(response: SurveyResponseMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), commandType: .timeSlicedSurveyTopology, encryptedBody: Data([0x01, 0x02, 0x03])), nonce: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyStartCollectingMessage_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"time_sliced_survey_start_collecting\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.time_sliced_survey_start_collecting: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "time_sliced_survey_start_collecting",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyStartCollectingMessage_roundTrip() throws {
        let original: StellarMessageXDR = .signedTimeSlicedSurveyStartCollectingMessage(SignedTimeSlicedSurveyStartCollectingMessageXDR(signature: Data([0x01, 0x02, 0x03]), startCollecting: TimeSlicedSurveyStartCollectingMessageXDR(surveyorID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), nonce: UInt32(42), ledgerNum: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyStopCollectingMessage_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"time_sliced_survey_stop_collecting\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.time_sliced_survey_stop_collecting: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "time_sliced_survey_stop_collecting",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_signedTimeSlicedSurveyStopCollectingMessage_roundTrip() throws {
        let original: StellarMessageXDR = .signedTimeSlicedSurveyStopCollectingMessage(SignedTimeSlicedSurveyStopCollectingMessageXDR(signature: Data([0x01, 0x02, 0x03]), stopCollecting: TimeSlicedSurveyStopCollectingMessageXDR(surveyorID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), nonce: UInt32(42), ledgerNum: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_transaction_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"transaction\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.transaction: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "transaction",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_transaction_roundTrip() throws {
        let original: StellarMessageXDR = .transaction(.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: [])))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_txSetHash_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"get_tx_set\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.get_tx_set: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "get_tx_set",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_txSetHash_roundTrip() throws {
        let original: StellarMessageXDR = .txSetHash(WrappedData32(Data(repeating: 0xAB, count: 32)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_StellarMessageXDR_txSet_rejectsBareString() throws {
        XCTAssertThrowsError(try StellarMessageXDR.fromXdrJson("\"tx_set\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("StellarMessageXDR.tx_set: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "StellarMessageXDR")
            XCTAssertEqual(key, "tx_set",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_StellarMessageXDR_txSet_roundTrip() throws {
        let original: StellarMessageXDR = .txSet(TransactionSetXDR(previousLedgerHash: WrappedData32(Data(repeating: 0xAB, count: 32)), txs: [.v0(TransactionV0EnvelopeXDR(tx: TransactionV0XDR(sourceAccount: try PublicKey([UInt8](repeating: 0xAB, count: 32)), seqNum: Int64(100), timeBounds: nil, memo: .none, operations: []), signatures: []))]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try StellarMessageXDR.fromXdrJson(json)
        let viaValue = try StellarMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try StellarMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "StellarMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "StellarMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "StellarMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "StellarMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "StellarMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_SurveyMessageCommandTypeXDR_TIME_SLICED_SURVEY_TOPOLOGY() throws {
        let value: SurveyMessageCommandTypeXDR = .timeSlicedSurveyTopology
        XCTAssertEqual(try value.toXdrJson(), "\"time_sliced_survey_topology\"",
                       "SurveyMessageCommandTypeXDR.timeSlicedSurveyTopology must render as time_sliced_survey_topology")
        XCTAssertEqual(value.rawValue, Int32(1),
                       "SurveyMessageCommandTypeXDR.timeSlicedSurveyTopology must keep its XDR value")
        XCTAssertEqual(try SurveyMessageCommandTypeXDR.fromXdrJson("\"time_sliced_survey_topology\""), value,
                       "time_sliced_survey_topology must read back as SurveyMessageCommandTypeXDR.timeSlicedSurveyTopology")
    }

    func test_SurveyMessageCommandTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SurveyMessageCommandTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SurveyMessageCommandTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SurveyMessageCommandTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SurveyMessageResponseTypeXDR_SURVEY_TOPOLOGY_RESPONSE_V2() throws {
        let value: SurveyMessageResponseTypeXDR = .surveyTopologyResponseV2
        XCTAssertEqual(try value.toXdrJson(), "\"survey_topology_response_v2\"",
                       "SurveyMessageResponseTypeXDR.surveyTopologyResponseV2 must render as survey_topology_response_v2")
        XCTAssertEqual(value.rawValue, Int32(2),
                       "SurveyMessageResponseTypeXDR.surveyTopologyResponseV2 must keep its XDR value")
        XCTAssertEqual(try SurveyMessageResponseTypeXDR.fromXdrJson("\"survey_topology_response_v2\""), value,
                       "survey_topology_response_v2 must read back as SurveyMessageResponseTypeXDR.surveyTopologyResponseV2")
    }

    func test_SurveyMessageResponseTypeXDR_rejectsUndeclaredValue() throws {
        XCTAssertThrowsError(try SurveyMessageResponseTypeXDR.fromXdrJson("\"not_a_declared_member\"")) { error in
            guard case XdrJsonError.unknownEnumValue(let type, let value) = error else {
                return XCTFail("SurveyMessageResponseTypeXDR: expected unknownEnumValue, got \(error)")
            }
            XCTAssertEqual(type, "SurveyMessageResponseTypeXDR")
            XCTAssertEqual(value, "not_a_declared_member")
        }
    }

    func test_SurveyRequestMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SurveyRequestMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SurveyRequestMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SurveyRequestMessageXDR_roundTrip() throws {
        let original: SurveyRequestMessageXDR = SurveyRequestMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), encryptionKey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32))), commandType: .timeSlicedSurveyTopology)
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SurveyRequestMessageXDR.fromXdrJson(json)
        let viaValue = try SurveyRequestMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try SurveyRequestMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SurveyRequestMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SurveyRequestMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SurveyRequestMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SurveyRequestMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SurveyRequestMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_SurveyResponseBodyXDR_rejectsUndeclaredArm() throws {
        XCTAssertThrowsError(try SurveyResponseBodyXDR.fromXdrJson("\"not_a_declared_arm\"")) { error in
            guard case XdrJsonError.unknownUnionArm(let type, let key) = error else {
                return XCTFail("SurveyResponseBodyXDR: expected unknownUnionArm, got \(error)")
            }
            XCTAssertEqual(type, "SurveyResponseBodyXDR")
            XCTAssertEqual(key, "not_a_declared_arm")
        }
    }

    func test_SurveyResponseBodyXDR_topologyResponseBodyV2_rejectsBareString() throws {
        XCTAssertThrowsError(try SurveyResponseBodyXDR.fromXdrJson("\"survey_topology_response_v2\"")) { error in
            guard case XdrJsonError.invalidValue(let type, let key, _) = error else {
                return XCTFail("SurveyResponseBodyXDR.survey_topology_response_v2: expected invalidValue, got \(error)")
            }
            XCTAssertEqual(type, "SurveyResponseBodyXDR")
            XCTAssertEqual(key, "survey_topology_response_v2",
                           "the failure must name the arm rather than the catch-all")
        }
    }

    func test_SurveyResponseBodyXDR_topologyResponseBodyV2_roundTrip() throws {
        let original: SurveyResponseBodyXDR = .topologyResponseBodyV2(TopologyResponseBodyV2XDR(inboundPeers: TimeSlicedPeerDataListXDR(wrapped: [TimeSlicedPeerDataXDR(peerStats: PeerStatsXDR(id: try PublicKey([UInt8](repeating: 0xAB, count: 32)), versionStr: "test_string", messagesRead: UInt64(1234567), messagesWritten: UInt64(1234567), bytesRead: UInt64(1234567), bytesWritten: UInt64(1234567), secondsConnected: UInt64(1234567), uniqueFloodBytesRecv: UInt64(1234567), duplicateFloodBytesRecv: UInt64(1234567), uniqueFetchBytesRecv: UInt64(1234567), duplicateFetchBytesRecv: UInt64(1234567), uniqueFloodMessageRecv: UInt64(1234567), duplicateFloodMessageRecv: UInt64(1234567), uniqueFetchMessageRecv: UInt64(1234567), duplicateFetchMessageRecv: UInt64(1234567)), averageLatencyMs: UInt32(42))]), outboundPeers: TimeSlicedPeerDataListXDR(wrapped: [TimeSlicedPeerDataXDR(peerStats: PeerStatsXDR(id: try PublicKey([UInt8](repeating: 0xAB, count: 32)), versionStr: "test_string", messagesRead: UInt64(1234567), messagesWritten: UInt64(1234567), bytesRead: UInt64(1234567), bytesWritten: UInt64(1234567), secondsConnected: UInt64(1234567), uniqueFloodBytesRecv: UInt64(1234567), duplicateFloodBytesRecv: UInt64(1234567), uniqueFetchBytesRecv: UInt64(1234567), duplicateFetchBytesRecv: UInt64(1234567), uniqueFloodMessageRecv: UInt64(1234567), duplicateFloodMessageRecv: UInt64(1234567), uniqueFetchMessageRecv: UInt64(1234567), duplicateFetchMessageRecv: UInt64(1234567)), averageLatencyMs: UInt32(42))]), nodeData: TimeSlicedNodeDataXDR(addedAuthenticatedPeers: UInt32(42), droppedAuthenticatedPeers: UInt32(42), totalInboundPeerCount: UInt32(42), totalOutboundPeerCount: UInt32(42), p75SCPFirstToSelfLatencyMs: UInt32(42), p75SCPSelfToOtherLatencyMs: UInt32(42), lostSyncCount: UInt32(42), isValidator: true, maxInboundPeerCount: UInt32(42), maxOutboundPeerCount: UInt32(42))))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SurveyResponseBodyXDR.fromXdrJson(json)
        let viaValue = try SurveyResponseBodyXDR.fromXdrJsonValue(tree)
        let viaTree = try SurveyResponseBodyXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SurveyResponseBodyXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SurveyResponseBodyXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SurveyResponseBodyXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SurveyResponseBodyXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SurveyResponseBodyXDR must reach the same bytes through JSON and XDR")
    }

    func test_SurveyResponseMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try SurveyResponseMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "SurveyResponseMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_SurveyResponseMessageXDR_roundTrip() throws {
        let original: SurveyResponseMessageXDR = SurveyResponseMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), commandType: .timeSlicedSurveyTopology, encryptedBody: Data([0x01, 0x02, 0x03]))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try SurveyResponseMessageXDR.fromXdrJson(json)
        let viaValue = try SurveyResponseMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try SurveyResponseMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "SurveyResponseMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "SurveyResponseMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "SurveyResponseMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "SurveyResponseMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "SurveyResponseMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeSlicedNodeDataXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeSlicedNodeDataXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeSlicedNodeDataXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeSlicedNodeDataXDR_roundTrip() throws {
        let original: TimeSlicedNodeDataXDR = TimeSlicedNodeDataXDR(addedAuthenticatedPeers: UInt32(42), droppedAuthenticatedPeers: UInt32(42), totalInboundPeerCount: UInt32(42), totalOutboundPeerCount: UInt32(42), p75SCPFirstToSelfLatencyMs: UInt32(42), p75SCPSelfToOtherLatencyMs: UInt32(42), lostSyncCount: UInt32(42), isValidator: true, maxInboundPeerCount: UInt32(42), maxOutboundPeerCount: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeSlicedNodeDataXDR.fromXdrJson(json)
        let viaValue = try TimeSlicedNodeDataXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeSlicedNodeDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeSlicedNodeDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeSlicedNodeDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeSlicedNodeDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeSlicedNodeDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeSlicedNodeDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeSlicedPeerDataListXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeSlicedPeerDataListXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeSlicedPeerDataListXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeSlicedPeerDataListXDR_roundTrip() throws {
        let original: TimeSlicedPeerDataListXDR = TimeSlicedPeerDataListXDR(wrapped: [TimeSlicedPeerDataXDR(peerStats: PeerStatsXDR(id: try PublicKey([UInt8](repeating: 0xAB, count: 32)), versionStr: "test_string", messagesRead: UInt64(1234567), messagesWritten: UInt64(1234567), bytesRead: UInt64(1234567), bytesWritten: UInt64(1234567), secondsConnected: UInt64(1234567), uniqueFloodBytesRecv: UInt64(1234567), duplicateFloodBytesRecv: UInt64(1234567), uniqueFetchBytesRecv: UInt64(1234567), duplicateFetchBytesRecv: UInt64(1234567), uniqueFloodMessageRecv: UInt64(1234567), duplicateFloodMessageRecv: UInt64(1234567), uniqueFetchMessageRecv: UInt64(1234567), duplicateFetchMessageRecv: UInt64(1234567)), averageLatencyMs: UInt32(42))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeSlicedPeerDataListXDR.fromXdrJson(json)
        let viaValue = try TimeSlicedPeerDataListXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeSlicedPeerDataListXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeSlicedPeerDataListXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeSlicedPeerDataListXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeSlicedPeerDataListXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeSlicedPeerDataListXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeSlicedPeerDataListXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeSlicedPeerDataXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeSlicedPeerDataXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeSlicedPeerDataXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeSlicedPeerDataXDR_roundTrip() throws {
        let original: TimeSlicedPeerDataXDR = TimeSlicedPeerDataXDR(peerStats: PeerStatsXDR(id: try PublicKey([UInt8](repeating: 0xAB, count: 32)), versionStr: "test_string", messagesRead: UInt64(1234567), messagesWritten: UInt64(1234567), bytesRead: UInt64(1234567), bytesWritten: UInt64(1234567), secondsConnected: UInt64(1234567), uniqueFloodBytesRecv: UInt64(1234567), duplicateFloodBytesRecv: UInt64(1234567), uniqueFetchBytesRecv: UInt64(1234567), duplicateFetchBytesRecv: UInt64(1234567), uniqueFloodMessageRecv: UInt64(1234567), duplicateFloodMessageRecv: UInt64(1234567), uniqueFetchMessageRecv: UInt64(1234567), duplicateFetchMessageRecv: UInt64(1234567)), averageLatencyMs: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeSlicedPeerDataXDR.fromXdrJson(json)
        let viaValue = try TimeSlicedPeerDataXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeSlicedPeerDataXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeSlicedPeerDataXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeSlicedPeerDataXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeSlicedPeerDataXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeSlicedPeerDataXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeSlicedPeerDataXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeSlicedSurveyRequestMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeSlicedSurveyRequestMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeSlicedSurveyRequestMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeSlicedSurveyRequestMessageXDR_roundTrip() throws {
        let original: TimeSlicedSurveyRequestMessageXDR = TimeSlicedSurveyRequestMessageXDR(request: SurveyRequestMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), encryptionKey: Curve25519PublicXDR(key: WrappedData32(Data(repeating: 0xAB, count: 32))), commandType: .timeSlicedSurveyTopology), nonce: UInt32(42), inboundPeersIndex: UInt32(42), outboundPeersIndex: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeSlicedSurveyRequestMessageXDR.fromXdrJson(json)
        let viaValue = try TimeSlicedSurveyRequestMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeSlicedSurveyRequestMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeSlicedSurveyRequestMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeSlicedSurveyRequestMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeSlicedSurveyRequestMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeSlicedSurveyRequestMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeSlicedSurveyRequestMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeSlicedSurveyResponseMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeSlicedSurveyResponseMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeSlicedSurveyResponseMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeSlicedSurveyResponseMessageXDR_roundTrip() throws {
        let original: TimeSlicedSurveyResponseMessageXDR = TimeSlicedSurveyResponseMessageXDR(response: SurveyResponseMessageXDR(surveyorPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), surveyedPeerID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), ledgerNum: UInt32(42), commandType: .timeSlicedSurveyTopology, encryptedBody: Data([0x01, 0x02, 0x03])), nonce: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeSlicedSurveyResponseMessageXDR.fromXdrJson(json)
        let viaValue = try TimeSlicedSurveyResponseMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeSlicedSurveyResponseMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeSlicedSurveyResponseMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeSlicedSurveyResponseMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeSlicedSurveyResponseMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeSlicedSurveyResponseMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeSlicedSurveyResponseMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeSlicedSurveyStartCollectingMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeSlicedSurveyStartCollectingMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeSlicedSurveyStartCollectingMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeSlicedSurveyStartCollectingMessageXDR_roundTrip() throws {
        let original: TimeSlicedSurveyStartCollectingMessageXDR = TimeSlicedSurveyStartCollectingMessageXDR(surveyorID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), nonce: UInt32(42), ledgerNum: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeSlicedSurveyStartCollectingMessageXDR.fromXdrJson(json)
        let viaValue = try TimeSlicedSurveyStartCollectingMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeSlicedSurveyStartCollectingMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeSlicedSurveyStartCollectingMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeSlicedSurveyStartCollectingMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeSlicedSurveyStartCollectingMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeSlicedSurveyStartCollectingMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeSlicedSurveyStartCollectingMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_TimeSlicedSurveyStopCollectingMessageXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TimeSlicedSurveyStopCollectingMessageXDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TimeSlicedSurveyStopCollectingMessageXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TimeSlicedSurveyStopCollectingMessageXDR_roundTrip() throws {
        let original: TimeSlicedSurveyStopCollectingMessageXDR = TimeSlicedSurveyStopCollectingMessageXDR(surveyorID: try PublicKey([UInt8](repeating: 0xAB, count: 32)), nonce: UInt32(42), ledgerNum: UInt32(42))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TimeSlicedSurveyStopCollectingMessageXDR.fromXdrJson(json)
        let viaValue = try TimeSlicedSurveyStopCollectingMessageXDR.fromXdrJsonValue(tree)
        let viaTree = try TimeSlicedSurveyStopCollectingMessageXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TimeSlicedSurveyStopCollectingMessageXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TimeSlicedSurveyStopCollectingMessageXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TimeSlicedSurveyStopCollectingMessageXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TimeSlicedSurveyStopCollectingMessageXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TimeSlicedSurveyStopCollectingMessageXDR must reach the same bytes through JSON and XDR")
    }

    func test_TopologyResponseBodyV2XDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TopologyResponseBodyV2XDR.fromXdrJson("[]")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TopologyResponseBodyV2XDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TopologyResponseBodyV2XDR_roundTrip() throws {
        let original: TopologyResponseBodyV2XDR = TopologyResponseBodyV2XDR(inboundPeers: TimeSlicedPeerDataListXDR(wrapped: [TimeSlicedPeerDataXDR(peerStats: PeerStatsXDR(id: try PublicKey([UInt8](repeating: 0xAB, count: 32)), versionStr: "test_string", messagesRead: UInt64(1234567), messagesWritten: UInt64(1234567), bytesRead: UInt64(1234567), bytesWritten: UInt64(1234567), secondsConnected: UInt64(1234567), uniqueFloodBytesRecv: UInt64(1234567), duplicateFloodBytesRecv: UInt64(1234567), uniqueFetchBytesRecv: UInt64(1234567), duplicateFetchBytesRecv: UInt64(1234567), uniqueFloodMessageRecv: UInt64(1234567), duplicateFloodMessageRecv: UInt64(1234567), uniqueFetchMessageRecv: UInt64(1234567), duplicateFetchMessageRecv: UInt64(1234567)), averageLatencyMs: UInt32(42))]), outboundPeers: TimeSlicedPeerDataListXDR(wrapped: [TimeSlicedPeerDataXDR(peerStats: PeerStatsXDR(id: try PublicKey([UInt8](repeating: 0xAB, count: 32)), versionStr: "test_string", messagesRead: UInt64(1234567), messagesWritten: UInt64(1234567), bytesRead: UInt64(1234567), bytesWritten: UInt64(1234567), secondsConnected: UInt64(1234567), uniqueFloodBytesRecv: UInt64(1234567), duplicateFloodBytesRecv: UInt64(1234567), uniqueFetchBytesRecv: UInt64(1234567), duplicateFetchBytesRecv: UInt64(1234567), uniqueFloodMessageRecv: UInt64(1234567), duplicateFloodMessageRecv: UInt64(1234567), uniqueFetchMessageRecv: UInt64(1234567), duplicateFetchMessageRecv: UInt64(1234567)), averageLatencyMs: UInt32(42))]), nodeData: TimeSlicedNodeDataXDR(addedAuthenticatedPeers: UInt32(42), droppedAuthenticatedPeers: UInt32(42), totalInboundPeerCount: UInt32(42), totalOutboundPeerCount: UInt32(42), p75SCPFirstToSelfLatencyMs: UInt32(42), p75SCPSelfToOtherLatencyMs: UInt32(42), lostSyncCount: UInt32(42), isValidator: true, maxInboundPeerCount: UInt32(42), maxOutboundPeerCount: UInt32(42)))
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TopologyResponseBodyV2XDR.fromXdrJson(json)
        let viaValue = try TopologyResponseBodyV2XDR.fromXdrJsonValue(tree)
        let viaTree = try TopologyResponseBodyV2XDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TopologyResponseBodyV2XDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TopologyResponseBodyV2XDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TopologyResponseBodyV2XDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TopologyResponseBodyV2XDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TopologyResponseBodyV2XDR must reach the same bytes through JSON and XDR")
    }

    func test_TxAdvertVectorXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TxAdvertVectorXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TxAdvertVectorXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TxAdvertVectorXDR_roundTrip() throws {
        let original: TxAdvertVectorXDR = TxAdvertVectorXDR(wrapped: [WrappedData32(Data(repeating: 0xAB, count: 32))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TxAdvertVectorXDR.fromXdrJson(json)
        let viaValue = try TxAdvertVectorXDR.fromXdrJsonValue(tree)
        let viaTree = try TxAdvertVectorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TxAdvertVectorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TxAdvertVectorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TxAdvertVectorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TxAdvertVectorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TxAdvertVectorXDR must reach the same bytes through JSON and XDR")
    }

    func test_TxDemandVectorXDR_rejectsWrongShape() throws {
        XCTAssertThrowsError(try TxDemandVectorXDR.fromXdrJson("\"not_an_array\"")) { error in
            XCTAssertTrue(error is XdrJsonError,
                          "TxDemandVectorXDR must report a shape it cannot read as an XdrJsonError")
        }
    }

    func test_TxDemandVectorXDR_roundTrip() throws {
        let original: TxDemandVectorXDR = TxDemandVectorXDR(wrapped: [WrappedData32(Data(repeating: 0xAB, count: 32))])
        let tree = try original.toXdrJsonValue()
        let json = try original.toXdrJson()
        let decoded = try TxDemandVectorXDR.fromXdrJson(json)
        let viaValue = try TxDemandVectorXDR.fromXdrJsonValue(tree)
        let viaTree = try TxDemandVectorXDR.fromXdrJsonTree(tree)
        XCTAssertEqual(try decoded.toXdrJsonValue(), tree,
                       "TxDemandVectorXDR must produce the same tree after a round trip")
        XCTAssertEqual(try decoded.toXdrJson(), json,
                       "TxDemandVectorXDR must produce the same text after a round trip")
        XCTAssertEqual(try viaValue.toXdrJson(), json,
                       "TxDemandVectorXDR must read a tree the same way it reads text")
        XCTAssertEqual(try viaTree.toXdrJson(), json,
                       "TxDemandVectorXDR must read a depth-checked tree the same way")
        let originalBase64 = try Data(XDREncoder.encode(original)).base64EncodedString()
        XCTAssertEqual(try Data(XDREncoder.encode(decoded)).base64EncodedString(),
                       originalBase64,
                       "TxDemandVectorXDR must reach the same bytes through JSON and XDR")
    }
}
